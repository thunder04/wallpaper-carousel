param (
    [string] $WallpaperFolder,
    [array] $Subreddits = ("Amoledbackgrounds", "wallpapers", "wallpaper"),
    [TimeSpan] $Interval = (New-TimeSpan -Hours 1),
    [bool] $UpdateSchedule = $true,
    [string] $Timeframe = 'all',
    [string] $Listing = 'hot'
)

$ListingTypes = ('controversial', 'best', 'hot', 'new', 'random', 'rising', 'top')
$TimeframeTypes = ('hour', 'day', 'week', 'month', 'year', 'all')

if ( -not $WallpaperFolder ) { throw 'Parameter WallpaperFolder is required' }
if ( -not $ListingTypes.Contains($Listing)) { throw "Unknown option $($Listing) for Listing. Available listing types: $($ListingTypes -join ', ')" }
if ( -not $TimeframeTypes.Contains($Timeframe)) { throw "Unknown option $($Timeframe) for Timeframe. Available timeframe types: $($TimeframeTypes -join ', ')" }

if ($UpdateSchedule) {
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
            "-Listing $Listing",
            "-UpdateSchedule 0"
        ) -join ' '
    )
            
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval $Interval
    $settings = New-ScheduledTaskSettingsSet -DontStopIfGoingOnBatteries -Priority 6
            
    Register-ScheduledTask WallpaperCarousel -Trigger $trigger -Action $action -Settings $settings | Out-Null
    Write-Host "Updated the Task Schedule."
    exit
}

$SubredditData = Invoke-WebRequest -Uri "https://www.reddit.com/r/$($Subreddits | Get-Random).json?listing=$Listing&t=$Timeframe&limit=1"
$SubredditPosts = (ConvertFrom-Json $SubredditData.content).data.children 
<# #> | ForEach-Object { $_.data } 
<# #> | Where-Object { -not $_.banned_by -and -not $_.removed_by -and -not $_.over_18 -and -not $_.spoiler -and $_.url }
<# #> | Select-Object url, created

Write-Host $SubredditPosts

# Call it before you save the images
# New-Item $WallpaperFolder -ItemType Directory -Force | Out-Null