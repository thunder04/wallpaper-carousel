param (
    [Parameter(Position = 0, Mandatory = $true)]
    [string]   $WallpaperFolder,
    [switch]   $DontUpdateSchedule,

    [TimeSpan] $Interval = (New-TimeSpan -Hours 1),
    [string]   $Timeframe = 'week',
    [string]   $Listing = 'top',
    [int]      $FetchLimit = 10,
    [array]    $Subreddits = (
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
    [int] $Height,
    [int] $Width
) {
    if (($Width -lt $MinW ) -or ($Height -lt $MinH)) { Write-Debug "$filename's image resolution is too small for this screen. Skipping..."; return $false }
    elseif ($Height -gt $Width) { Write-Debug "$Filename seems to be a mobile wallpaper. Skipping..."; return $false }
    return $true
}

if (-not $DontUpdateSchedule) {
    if (Get-ScheduledTask WallpaperCarousel -ErrorAction Ignore) {
        Unregister-ScheduledTask WallpaperCarousel -Confirm:$false
    }

    $action = New-ScheduledTaskAction "pwsh.exe" -Argument (
        (
            "-WindowStyle Hidden",
            "-Command $PSCommandPath",
            "-Subreddits $($Subreddits -join ',')",
            "-WallpaperFolder $WallpaperFolder",
            "-Timeframe $Timeframe",
            "-DontUpdateSchedule",
            "-Listing $Listing"
        ) -join ' '
    )

    Register-ScheduledTask WallpaperCarousel `
        -Trigger (New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval $Interval) `
        -Settings (New-ScheduledTaskSettingsSet -DontStopIfGoingOnBatteries -Priority 6) `
        -Action $action -Force | Out-Null

    Write-Host "Added Task Schedule. Remove it by running `"Unregister-ScheduledTask WallpaperCarousel -Confirm:`$false`""
    exit
}

$SubredditData = Invoke-WebRequest -Uri "https://www.reddit.com/r/$($Subreddits | Get-Random).json?listing=$Listing&t=$Timeframe&limit=$FetchLimit"
$SubredditPosts = (ConvertFrom-Json $SubredditData.content).data.children | ForEach-Object { $_.data } | Where-Object {
    -not $_.banned_by -and -not $_.removed_by -and -not $_.over_18 `
        -and -not $_.is_video -and -not $_.spoiler -and $_.url `
        -and $FileTypes.Contains($_.url.Split('.')[-1])
}

New-Item $WallpaperFolder -ItemType Directory -Force | Out-Null
$ExistingFiles = Get-ChildItem $WallpaperFolder -Name

foreach ($post in $SubredditPosts) {
    $Filename = Split-Path $post.url -Leaf

    if ($ExistingFiles -and $ExistingFiles.Contains($Filename)) {
        Write-Debug "$WallpaperFolder\$filename already exists. Skipping..."
        Continue
    }

    if ($post.title -imatch $ResPattern -and -not (ValidateImage $Filename -Height $Matches.Height -Width $Matches.Width)) { Continue }

    try { $Image = New-Object System.Drawing.Bitmap ((Invoke-WebRequest $post.url).RawContentStream) }
    catch { Write-Error "An error occurred while processing $filename from $($post.url)"; Continue }

    if (-not (ValidateImage $Filename -Height $Image.Height -Width $Image.Width)) { Continue }

    $Image.Save("$WallpaperFolder\$Filename")
    Write-Debug "Saved $WallpaperFolder\$filename ($($post.subreddit))"
}
