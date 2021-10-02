param (
    [Parameter(Position = 0, Mandatory = $true)]
    [string]   $Dir,

    [Parameter(Position = 1, Mandatory = $false)]
    [array]    $Subs = (
        "Amoledbackgrounds",
        "wallpaperdump",
        "VillagePorn",
        "EarthPorn",
        "wallpaper",
        "BeachPorn",
        "WaterPorn",
        "CityPorn",
        "LakePorn",
        "SkyPorn"
    ),

    [Parameter(Position = 2, Mandatory = $false)]
    [int]      $Mode = 0, # 0: Schedule, 1: Fetch, 2: Sweep

    [TimeSpan] $SweepInterval = (New-TimeSpan -Days 7),
    [TimeSpan] $Interval = (New-TimeSpan -Days 1),
    [TimeSpan] $TTL = (New-TimeSpan -Days 7),

    [string]   $Timeframe = 'month',
    [string]   $Listing = 'top',
    [int]      $Limit = 10,
    [Switch]   $NSFW
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ProgressPreference = "SilentlyContinue"

$ListingOptions = ('controversial', 'best', 'hot', 'new', 'random', 'rising', 'top')
$TimeframeOptions = ('hour', 'day', 'week', 'month', 'year', 'all')

if ( -not $TimeframeOptions.Contains($Timeframe)) { throw "Unknown option $Timeframe for Timeframe. Available timeframe types: $($TimeframeOptions -join ', ')" }
if ( -not $ListingOptions.Contains($Listing)) { throw "Unknown option $Listing for Listing. Available listing types: $($ListingOptions -join ', ')" }

$ResPattern = '[[({]\s*(?<Width>\d+)\s*x\s*(?<Height>\d+)\s*[\])}]'
$ScreenRes = ([System.Windows.Forms.Screen]::PrimaryScreen).Bounds
$FileTypes = ('.jpg', '.jpeg', '.webp', '.png', '.bmp')

$MinH = if ($ScreenRes.Height -gt 720) { $ScreenRes.Height - ($ScreenRes.Height * 0.15) } else { $ScreenRes.Height }
$MinW = if ($ScreenRes.Width -gt 1280) { $ScreenRes.Width - ($ScreenRes.Width * 0.10) } else { $ScreenRes.Width }

function ValidateImage(
    [Parameter(Position = 0)] [string] $Filename,
    [int] $H,
    [int] $W
) {
    if (($W -lt $MinW) -or ($H -lt $MinH)) { Write-Debug "$filename's image resolution is too small for this screen. Skipping..."; return $false }
    elseif ($H -gt $W) { Write-Debug "$Filename seems to be a mobile wallpaper. Skipping..."; return $false }
    return $true
}

if ($Mode -eq 0) {
    Unregister-ScheduledTask WallpaperCarouselSweeper -Confirm:$false -ErrorAction Ignore
    Unregister-ScheduledTask WallpaperCarousel -Confirm:$false -ErrorAction Ignore

    $Settings = New-ScheduledTaskSettingsSet -DontStopIfGoingOnBatteries -Priority 6 -RunOnlyIfNetworkAvailable

    $Arguments = (
        "-WindowStyle Hidden",
        "-Command .\$(Split-Path $PSCommandPath -Leaf)",

        $Dir, ($Subs -join ','), 1,
        "-Timeframe $Timeframe",
        "-Listing $Listing"
    )

    $SweeperArguments = $Arguments[0..1] + ($Dir, "-Mode 2")

    Register-ScheduledTask WallpaperCarousel `
        -Action (New-ScheduledTaskAction "pwsh.exe" -Argument ($Arguments -join ' ') -WorkingDirectory $PSScriptRoot) `
        -Trigger (New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval $Interval) `
        -Settings $Settings -Force | Out-Null
        
    Register-ScheduledTask WallpaperCarouselSweeper `
        -Action (New-ScheduledTaskAction "pwsh.exe" -Argument ($SweeperArguments -join ' ') -WorkingDirectory $PSScriptRoot) `
        -Trigger (New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval $SweepInterval) `
        -Settings $Settings -Force | Out-Null

    Write-Host "Added Task Schedule. Remove it by running `"Unregister-ScheduledTask WallpaperCarousel,WallpaperCarouselSweeper -Confirm:`$false`""
}

elseif ($Mode -eq 1) {
    $SubredditData = Invoke-WebRequest -Uri "https://www.reddit.com/r/$($Subs | Get-Random).json?listing=$Listing&t=$Timeframe&limit=$Limit"
    $SubredditPosts = (ConvertFrom-Json $SubredditData.content).data.children | ForEach-Object { $_.data } | Where-Object {
        -not $_.is_video -and -not $_.spoiler -and $_.url `
            -and -not $_.banned_by -and -not $_.removed_by `
            -and $FileTypes.Contains('.' + $_.url.Split('.')[-1])
    }

    New-Item $Dir -ItemType Directory -Force | Out-Null
    $Existing = Get-ChildItem $Dir -Name

    foreach ($Post in $SubredditPosts) {
        if (-not $NSFW -and $Post.over_18) {
            continue
        }

        $Filename = Split-Path $Post.url -Leaf

        if ($Existing -and $Existing.Contains($Filename)) {
            Write-Debug "$Dir\$filename already exists. Skipping..."
            continue
        }

        if ($Post.title -imatch $ResPattern -and -not (ValidateImage $Filename -H $Matches.Height -W $Matches.Width)) { continue }

        try { $Image = New-Object System.Drawing.Bitmap ((Invoke-WebRequest $Post.url).RawContentStream) }
        catch { Write-Error "An error occurred while processing $filename from $($Post.url)"; continue }

        if (-not (ValidateImage $Filename -H $Image.Height -W $Image.Width)) { continue }

        $Image.Save("$Dir\$Filename")
        Write-Debug "Saved $Dir\$filename ($($Post.subreddit))"
    }
}

elseif ($Mode -eq 2) {
    if (-not (Test-Path -Path $Dir)) {
        exit
    }

    $DateTTL = (Get-Date).Add(-$TTL)

    $Files = Get-ChildItem $Dir
    | Where-Object { ($FileTypes.Contains($_.Extension)) -and ($_.CreationTime -lt $DateTTL) }
    | ForEach-Object { $_.FullName }
    
    Remove-Item $Files -Confirm:$false
    Write-Debug "Deleted $($Files.Length) file$(if ($Files.Length -cne 1) { 's' })"
}