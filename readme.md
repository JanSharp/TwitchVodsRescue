
# Usage

## Setup

- Download this repo using the button at the top. Download the zip if you don't have git
- Open the [config.lua](config.lua) file
- For the [details.txt](configuration/details.txt) file
  - go to https://twitch-tools.rootonline.de/vod_manager.php
  - log in
  - let it load
  - control A
  - control C
  - open the [details.txt](configuration/details.txt) file
  - control A
  - control V
  - remove the header at the top, including the "Found ### videos." line
- For the [vods_filtered_2025-02-19_20-39-36.csv](configuration/vods_filtered_2025-02-19_20-39-36.csv) file
  - go to https://twitch-tools.rootonline.de/vod_manager.php
  - log in
  - let it load
  - press "Export video URL list"
  - save the file
  - either overwrite the existing [vods_filtered_2025-02-19_20-39-36.csv](configuration/vods_filtered_2025-02-19_20-39-36.csv) file, which requires you renaming your new file
  - or put the file in the `configuration` folder and edit the `urls_list` variable in the [config.lua](config.lua) file to match your file name
- For collections
  - Go to https://dashboard.twitch.tv/u/jansharp/content/collections
  - click on a collection
  - control A
  - control C
  - create a file in `configuration/collections`, the file name will be treated as the collection name (doesn't have to match the one you have on twitch)
  - open it
  - control V
  - remove the header, including the "## of 100 videos added to collection" line
  - update the `collections` list in the [config.lua](config.lua) file to include your collections file name
  - (remove the example file of course, since that's just my data)
  - repeat that for each collection

With that the script is setup to obtain nearly all metadata of your vods, as well as which collection each vod is apart of

## Executing

- Open a command line / terminal
- Change directory into the root of this project, the same folder this readme is in
  - use the `cd C:\path\to\this\folder` command on windows
  - on linux just right click open terminal here, pretty sure most file explorers have that, dolphin does anyway
- Run the command `./lua -- main.lua`

# External Resources

I don't know who wrote this unfortunately, but here: [Bulk Downloading Guide.pdf](<Bulk Downloading Guide.pdf>)
Download tool: https://github.com/lay295/TwitchDownloader

# Libraries, Dependencies and Licenses

This project itself is licensed under the MIT License, see [LICENSE.txt](LICENSE.txt).

<!-- cSpell:ignore Mischak, justarandomgeek, justchen1369 -->

- [Lua](https://www.lua.org/home.html) MIT License, Copyright (c) 1994–2021 Lua.org, PUC-Rio.
- [LuaArgParser](https://github.com/JanSharp/LuaArgParser) MIT License, Copyright (c) 2021-2022 Jan Mischak
- [LuaPath](https://github.com/JanSharp/LuaPath) The Unlicense
- [phobos](https://github.com/JanSharp/phobos), Copyright (c) 2021-2023 Jan Mischak, justarandomgeek, Claude Metz, justchen1369
- [LuaPath](https://github.com/JanSharp/LuaPath) The Unlicense

For license details see the [LICENSE_THIRD_PARTY.txt](LICENSE_THIRD_PARTY.txt) file and or the linked repositories above.
