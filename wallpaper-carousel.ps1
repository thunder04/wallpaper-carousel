param (
    [Parameter(Position = 0, Mandatory = $true)]
    [string]   $WFolder,
    [switch]   $NoSDL,

    [TimeSpan] $Interval = (New-TimeSpan -Hours 1),
    [string]   $Timeframe = 'week',
    [string]   $Listing = 'top',
    [int]      $FetchLimit = 10,
    [array]    $Subs = (
        "Amoledbackgrounds",
        "VillagePorn",
        "wallpapers",
        "EarthPorn",
        "wallpaper",
        "BeachPorn",
        "WaterPorn",
        "CityPorn",
        "LakePorn",
        "SkyPorn"
    )
)

$ListingTypes = ('controversial', 'best', 'hot', 'new', 'random', 'rising', 'top')
$ResPattern = '[[({]\s*(?<Width>\d+)\s*x\s*(?<Height>\d+)\s*[\])}]'
$TimeframeTypes = ('hour', 'day', 'week', 'month', 'year', 'all')
$FileTypes = ('jpg', 'jpeg', 'webp', 'png', 'bmp')
$ProgressPreference = "SilentlyContinue"

if ( -not $TimeframeTypes.Contains($Timeframe)) { throw "Unknown option $Timeframe for Timeframe. Available timeframe types: $($TimeframeTypes -join ', ')" }
if ( -not $ListingTypes.Contains($Listing)) { throw "Unknown option $Listing for Listing. Available listing types: $($ListingTypes -join ', ')" }

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ScreenRes = ([System.Windows.Forms.Screen]::PrimaryScreen).Bounds
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

if (-not $NoSDL) {
    if (Get-ScheduledTask WallpaperCarousel -ErrorAction Ignore) {
        Unregister-ScheduledTask WallpaperCarousel -Confirm:$false
    }

    $Arg = (
        "-WindowStyle Hidden",
        "-Command .\$(Split-Path $PSCommandPath -Leaf)",
        $WFolder,
        "-NoSDL",
        "-Listing $Listing",
        "-Timeframe $Timeframe",
        "-Subs $($Subs -join ',')"
    ) -join ' '

    Register-ScheduledTask WallpaperCarousel `
        -Settings (New-ScheduledTaskSettingsSet -DontStopIfGoingOnBatteries -Priority 6 -RunOnlyIfIdle -IdleDuration 00:00:01 -RunOnlyIfNetworkAvailable) `
        -Action (New-ScheduledTaskAction "pwsh.exe" -Argument $Arg -WorkingDirectory $PSScriptRoot) `
        -Trigger (New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval $Interval) `
        -Force | Out-Null

    Write-Host "Added Task Schedule. Remove it by running `"Unregister-ScheduledTask WallpaperCarousel -Confirm:`$false`""
    exit
}

$SubredditData = Invoke-WebRequest -Uri "https://www.reddit.com/r/$($Subs | Get-Random).json?listing=$Listing&t=$Timeframe&limit=$FetchLimit"
$SubredditPosts = (ConvertFrom-Json $SubredditData.content).data.children | ForEach-Object { $_.data } | Where-Object {
    -not $_.banned_by -and -not $_.removed_by -and -not $_.over_18 `
        -and -not $_.is_video -and -not $_.spoiler -and $_.url `
        -and $FileTypes.Contains($_.url.Split('.')[-1])
}

New-Item $WFolder -ItemType Directory -Force | Out-Null
$Existing = Get-ChildItem $WFolder -Name

foreach ($Post in $SubredditPosts) {
    $Filename = Split-Path $Post.url -Leaf

    if ($Existing -and $Existing.Contains($Filename)) {
        Write-Debug "$WFolder\$filename already exists. Skipping..."
        continue
    }

    if ($Post.title -imatch $ResPattern -and -not (ValidateImage $Filename -H $Matches.Height -W $Matches.Width)) { continue }

    try { $Image = New-Object System.Drawing.Bitmap ((Invoke-WebRequest $Post.url).RawContentStream) }
    catch { Write-Error "An error occurred while processing $filename from $($Post.url)"; continue }

    if (-not (ValidateImage $Filename -H $Image.Height -W $Image.Width)) { continue }

    $Image.Save("$WFolder\$Filename")
    Write-Debug "Saved $WFolder\$filename ($($Post.subreddit))"
}
