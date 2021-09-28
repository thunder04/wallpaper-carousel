# 🎠 wallpaper-carousel
Automatically downloads wallpapers from Reddit to be set as desktop background. Windows only.

## 📝 Requirements
- [PowerShell 7.x](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.1) (needs to be added to PATH)

## 🎆 Installation
1. `git clone https://github.com/thunder04/wallpaper-carousel` or [Download the archive](https://github.com/thunder04/wallpaper-carousel/archive/refs/heads/main.zip)
2. Move the folder somewhere safe — to not get deleted by accident.
3. Run the `carousel.ps1` script using PowerShell 7 and follow the "[instructions](https://github.com/thunder04/wallpaper-carousel/blob/main/README.md#parameters)".
4. Open Windows Settings and go to `Personalization -> Background`
5. Change Background type to "Slideshow"
6. Choose the folder you chose during step 3

*<sup>Trust me it's more simple than it looks like</sup>*

## 📐 Parameters
- `-WallpaperFolder [string]`: The path where new wallpapers are going to be stored.
- `-Subreddits [array]`: The list of the subreddits where the script will fetch images from (It filters out NSFW posts)
- `-Interval [TimeSpan]`: How quickly it will fetch new wallpapers.

For example, this invocation — `pwsh.exe .\carousel.ps1 -WallpaperFolder "\Wallpapers" -Subreddits wallpapers,SkyPorn,FoodPorn -Interval (New-TimeSpan -Days 1)` — will:
- __Create a folder__ in `\Wallpapers` (Usually `C:\Wallpapers`)
- __Pick a subreddit__ randomly from `wallpapers`, `SkyPorn` and `FoodPorn` and fetch 5 SFW images __every 1 day__.

## 🗑 Uninstallation
- Open a new PowerShell window.
- Run this command `Unregister-ScheduledTask WallpaperCarousel -Confirm:$false`.

## 💡 TODO
- Add wallpaper sweeping.
- Filter Vertical wallpapers.
- Raise the concurrent wallpaper fetching (5 currently) and make it customizable.
