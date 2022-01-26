# 🎠 wallpaper-carousel

Automatically downloads wallpapers from Reddit to be set as desktop background. Windows only (because I can't test it on other platforms)

## ✨ Features

- Automatic wallpaper sweeping
- Multiple subreddits support
- Mobile wallpaper filtering
- Small wallpaper filtering
- NSFW wallpaper support [**Disabled by default**]
- [Advanced Customization](https://github.com/thunder04/wallpaper-carousel/blob/main/README.md#-parameters)

## 📝 Requirements

- [PowerShell 7.x](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.1) (needs to be added to PATH)

## 🎆 Installation

1. `git clone https://github.com/thunder04/wallpaper-carousel` or [Download the archive](https://github.com/thunder04/wallpaper-carousel/archive/refs/heads/main.zip)
2. Move the script or the folder somewhere safe — to not get deleted by accident.
3. Run the `carousel.ps1` script using PowerShell 7 and follow the "[instructions](https://github.com/thunder04/wallpaper-carousel/blob/main/README.md#-parameters)".
4. Open Windows Settings and go to `Personalization -> Background`
5. Change Background type to "Slideshow"
6. Choose the folder you chose during step 3

## 📐 Parameters

- `-Dir [string]`: The path where new wallpapers are going to be saved.
- `-Subs [array]`: The list of subreddits where the script will fetch images from. [Default: [Click me](https://github.com/thunder04/wallpaper-carousel/blob/main/wallpaper-carousel.ps1#L7-L16)]
- `-Interval [TimeSpan]`: The interval between script execution. [Default: `1 day`]
- `-SweepInterval [TimeSpan]`: The interval between sweeping. [Default: `7 days`]
- `-TTL [TimeSpan]`: The maximum age of a wallpaper. [Default: `7 days`]
- `-Listing [controversial|best|hot|new|random|rising|top]`: The ordering type of the posts. [Default: `top`]
- `-Timeframe [hour|day|week|month|year|all]`: The time frame of the subreddit's posts. [Default: `month`]
- `-Limit [int]`: The number of posts the script will fetch from. [Default: `10`]
- `-NSFW [Switch]`: If included, it allows NSFW posts to be used as wallpaper. [Default: `false`]

For example, this command:

```bash
pwsh.exe .\wallpaper-carousel.ps1 C:\Wallpapers wallpapers,SkyPorn -Interval (New-TimeSpan -Days 2)
```

Will create a folder in `C:\Wallpapers` and fetch 10 posts from r/wallpapers or r/SkyPorn every 2 days.

## 🚨 The PowerShell window flashes, what can I do?

[Nothing](https://github.com/PowerShell/PowerShell/issues/3028#issuecomment-275212445), yet, hopefully. Try to disable the animations/effects from the System Settings ¯\\\_(ツ)\_/¯
