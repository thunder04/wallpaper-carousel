# 🎠 wallpaper-carousel
Automatically downloads wallpapers from Reddit to be set as desktop background. Windows only <sup>(because I can't test it on other platforms)</sup>.

## 📝 Requirements
- [PowerShell 7.x](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.1) (needs to be added to PATH)

## 🎆 Installation
1. `git clone https://github.com/thunder04/wallpaper-carousel` or [Download the archive](https://github.com/thunder04/wallpaper-carousel/archive/refs/heads/main.zip)
2. Move the folder somewhere safe — to not get deleted by accident.
3. Run the `carousel.ps1` script using PowerShell 7 and follow the "[instructions](https://github.com/thunder04/wallpaper-carousel/blob/main/README.md#-parameters)".
4. Open Windows Settings and go to `Personalization -> Background`
5. Change Background type to "Slideshow"
6. Choose the folder you chose during step 3

*<sup>Trust me it's more simple than it looks like</sup>*

## 📐 Parameters
- `-WFolder [string]`: The path where new wallpapers are going to be stored.
- `-Subs [array]`: The list of the subreddits where the script will fetch images from (It filters out NSFW posts) [Default: [Click me](https://github.com/thunder04/wallpaper-carousel/blob/main/wallpaper-carousel.ps1#L10-L22)]
- `-Interval [TimeSpan]`: How quickly it will fetch new wallpapers. [Default: `1 day`]
- `-Timeframe [hour|day|week|month|year|all]`: The time frame of the subreddit's posts. [Default: `week`]
- `-Listing [controversial|best|hot|new|random|rising|top]`: The ordering type of the posts. [Default: `top`]
- `-FetchLimit [int]`: The number of posts it will fetch from. [Default: `10`]

For example, this invocation — `pwsh.exe .\carousel.ps1 \Wallpapers -Subs wallpapers,SkyPorn,FoodPorn -Interval (New-TimeSpan -Days 1)` — will:
- __Create a folder__ in `\Wallpapers` (Also known as `C:\Wallpapers`)
- __Pick a subreddit__ randomly from `wallpapers`, `SkyPorn` and `FoodPorn` and fetch 10 SFW images __every 1 day__.

## 💡 TODO
- Add wallpaper sweeping.
