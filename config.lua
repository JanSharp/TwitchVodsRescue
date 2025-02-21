
return {
  -- On Linux you can follow this: https://github.com/lay295/TwitchDownloader?tab=readme-ov-file#linux--getting-started
  --   Though if you're on Arch you can also just run 'yay -S twitch-downloader-bin' and keep "TwitchDownloaderCLI", since it'll be in PATH
  --   Otherwise use: "/directory/containing/TwitchDownloaderCLI/TwitchDownloaderCLI"
  --
  -- On Windows you'd follow these steps, except for step 5: https://github.com/lay295/TwitchDownloader?tab=readme-ov-file#windows---getting-started
  --   Then use this: "C:\folder\containing\TwitchDownloaderCLI\TwitchDownloaderCLI.exe"
  downloader_cli = "TwitchDownloaderCLI", -- This path should not contain any white spaces, or otherwise weird characters.
}
