param (
    [Parameter(Position = 0, Mandatory = $true)]
    [string]   $WallpaperFolder,

    [array]    $Subreddits = ("Amoledbackgrounds", "wallpapers", "wallpaper"),
    [TimeSpan] $Interval = (New-TimeSpan -Hours 1),
    [switch]   $DontUpdateSchedule,
    [string]   $Timeframe = 'all',
    [string]   $Listing = 'hot',
    [int]      $FetchLimit = 7
)

$ListingTypes = ('controversial', 'best', 'hot', 'new', 'random', 'rising', 'top')
$TimeframeTypes = ('hour', 'day', 'week', 'month', 'year', 'all')
$ValidFileTypes = ('jpg', 'jpeg', 'webp', 'png', 'bmp')

if ( -not $TimeframeTypes.Contains($Timeframe)) { throw "Unknown option $Timeframe for Timeframe. Available timeframe types: $($TimeframeTypes -join ', ')" }
if ( -not $ListingTypes.Contains($Listing)) { throw "Unknown option $Listing for Listing. Available listing types: $($ListingTypes -join ', ')" }

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
        -and $ValidFileTypes.Contains($_.url.Split('.')[-1])
}

New-Item $WallpaperFolder -ItemType Directory -Force | Out-Null
$ExistingFiles = Get-ChildItem $WallpaperFolder -Name

foreach ($post in $SubredditPosts) {
    $Filename = Split-Path $post.url -Leaf

    if ($ExistingFiles.Contains($Filename)) {
        Write-Debug "Found $Filename in $WallpaperFolder, skipping..."
        Continue
    }

    try { 
        Invoke-WebRequest $post.url -OutFile $WallpaperFolder\$Filename
        Write-Debug "Downloaded $wikWallpaperFolder/$filename"
    }

    catch { Write-Error "An error occurred while downloading $filename from $($post.url)" }
}
