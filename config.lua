
return {
  -- On Linux you can follow this: https://github.com/lay295/TwitchDownloader?tab=readme-ov-file#linux--getting-started
  --   Though if you're on Arch you can also just run 'yay -S twitch-downloader-bin' and keep "TwitchDownloaderCLI", since it'll be in PATH
  --   Otherwise use: "/directory/containing/TwitchDownloaderCLI/TwitchDownloaderCLI"
  --
  -- On Windows you'd follow these steps, except for step 5: https://github.com/lay295/TwitchDownloader?tab=readme-ov-file#windows---getting-started
  --   Then use this: "C:\folder\containing\TwitchDownloaderCLI\TwitchDownloaderCLI.exe"
  downloader_cli = "TwitchDownloaderCLI", -- See comments above
  downloader_cli_args = "--temp-path /mnt/big",
  urls_list = "configuration/vods_filtered_2025-02-19_20-39-36.csv", -- Use forward slashes.
  details_list = "configuration/details.txt", -- Use forward slashes.
  collections = { -- Use forward slashes.
    "configuration/collections/Anno 2070.txt",
    "configuration/collections/Ascension Academy Dev.txt",
    "configuration/collections/Baba Is You.txt",
    "configuration/collections/Car Engineer.txt",
    "configuration/collections/Chrono Ark.txt",
    "configuration/collections/Factorio AnyPercent Speedrun.txt",
    "configuration/collections/GuiGlue Dev.txt",
    "configuration/collections/Gui Plus Framework Dev.txt",
    "configuration/collections/LuaLS Plugin Dev.txt",
    "configuration/collections/Misc Games.txt",
    "configuration/collections/Misc Programming.txt",
    "configuration/collections/Misc.txt",
    "configuration/collections/Nullius Modded Run.txt",
    "configuration/collections/One Life Ori and the Blind Forest.txt",
    "configuration/collections/Ori and the Will of the Wisps.txt",
    "configuration/collections/Phobos.txt",
    "configuration/collections/Puzzletory.txt",
    "configuration/collections/Radar Equipment Dev.txt",
    "configuration/collections/Satisfactory.txt",
    "configuration/collections/Talks.txt",
    "configuration/collections/TrackMania Canyon WTC.txt",
    "configuration/collections/TrackMania.txt",
    "configuration/collections/Udon And Unity Programming.txt",
    "configuration/collections/Wave Defense Speedrun.txt",
  },
  -- output_directory = "downloads",
  output_directory = "/mnt/big/temp",
}
