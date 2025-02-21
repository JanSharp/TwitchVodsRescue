
# Usage

## Setup

- Download this repo using the button at the top. Download the zip if you don't have git
- Open the [config.lua](config.lua) file and follow instructions for how to setup and configure the `downloader_cli` variable
- Open [configuration/readme.md](configuration/readme.md) and follow the steps there to setup the `configuration` folder

With that the script is setup to obtain nearly all metadata of your vods, as well as which collection each vod is apart of

## Executing

- Open a command line / terminal
- Change directory into the root of this project, the same folder this readme is in
  - use the `cd C:\path\to\this\folder` command on windows
  - on linux just right click open terminal here, pretty sure most file explorers have that, dolphin does anyway
- Run the command `./lua -- main.lua --help`

# External Resources

I don't know who wrote this unfortunately, but here: [Bulk Downloading Guide.pdf](<Bulk Downloading Guide.pdf>)
Download tool: https://github.com/lay295/TwitchDownloader

# Libraries, Dependencies and Licenses

This project itself is licensed under the MIT License, see [LICENSE.txt](LICENSE.txt).

<!-- cSpell:ignore Mischak, justarandomgeek, justchen1369 -->

- [Lua](https://www.lua.org/home.html) MIT License, Copyright (c) 1994–2021 Lua.org, PUC-Rio.
- [LuaFileSystem](https://keplerproject.github.io/luafilesystem/) MIT License, Copyright (c) 2003 - 2020 Kepler Project.
- [LuaArgParser](https://github.com/JanSharp/LuaArgParser) MIT License, Copyright (c) 2021-2022 Jan Mischak
- [LuaPath](https://github.com/JanSharp/LuaPath) The Unlicense
- [phobos](https://github.com/JanSharp/phobos), Copyright (c) 2021-2023 Jan Mischak, justarandomgeek, Claude Metz, justchen1369
- [LuaPath](https://github.com/JanSharp/LuaPath) The Unlicense

For license details see the [LICENSE_THIRD_PARTY.txt](LICENSE_THIRD_PARTY.txt) file and or the linked repositories above.
