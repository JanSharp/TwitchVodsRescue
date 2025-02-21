
local util = require("util")
local linq = require("linq")
local config = require("config")
local Path = require("path")
local arg_parser = require("arg_parser")
local shell_util = require("shell_util")
local lfs = require("lfs")--[[@as LFS]]
local io_util = require("io_util")
local json = require("json_util")

---@class Args
---@field download_video boolean
---@field download_chat boolean
---@field time_limit number
---@field collections string[]
---@field non_collections boolean
---@field list_collections boolean
---@field output_dir string
---@field config_dir string
---@field temp_dir string
---@field dry_run boolean
---@field help boolean

-- ---@field no_warn_on_missing_metadata boolean
-- ---@field no_warn_on_missing_chat boolean

local args = arg_parser.parse_and_print_on_error_or_help({...}, {
  options = {
    -- {
    --   field = "no_warn_on_missing_metadata",
    --   long = "no-warn-on-missing-metadata",
    --   description = "If a video exists without an associated metadata file, the program\n\z
    --     generates a warning because that video may not have finished\n\z
    --     downloading correctly. By ignoring this warning it will\n\z
    --     simply generate the missing metadata file.",
    --   flag = true,
    -- },
    -- {
    --   field = "no_warn_on_missing_chat",
    --   long = "no-warn-on-missing-chat",
    --   description = "Same as --no-warn-on-missing-metadata, except\n\z
    --     that when the file is missing it will start a download for\n\z
    --     the video's chat history.",
    --   flag = true,
    -- },
    {
      field = "download_video",
      long = "download-video",
      description = "Download the highest quality video and audio available.",
      flag = true,
    },
    {
      field = "download_chat",
      long = "download-chat",
      description = "Download chat history into a json file. The TwitchDownloader CLI and\n\z
        GUI can render a video from this, which is a separate video from the\n\z
        main one, so that in particular is only useful for you locally.",
      flag = true,
    },
    {
      field = "time_limit",
      long = "time-limit",
      description = "Automatically stop once more this amount of minutes have passed.\n\z
        Zero or less means no limit. Do note however that when closing\n\z
        or killing the process while it is running will most likely result in\n\z
        unfinished downloads in the output directory. Make sure to delete\n\z
        those files.",
      type = "number",
      optional = true,
      default_value = 0,
      single_param = true,
    },
    {
      field = "collections",
      long = "collections",
      description = "Only process videos in the given collections.",
      type = "string",
      optional = true,
      min_params = 1,
    },
    {
      field = "non_collections",
      long = "non-collections",
      description = "Only process videos which are not part of a collection.",
      flag = true,
    },
    {
      field = "list_collections",
      long = "list-collections",
      description = "List all names of collections",
      flag = true,
    },
    {
      field = "output_dir",
      long = "output-dir",
      short = "o",
      description = "The directory to save downloaded files to. Use forward slashes.",
      default_value = "downloads",
      type = "string",
      single_param = true,
    },
    {
      field = "config_dir",
      long = "config-dir",
      short = "c",
      description = "The directory containing details.txt, one urls csv file, and\n\z
        optionally a 'collections' folder.",
      default_value = "configuration",
      type = "string",
      single_param = true,
    },
    {
      field = "temp_dir",
      long = "temp-dir",
      description = "The temp directory the TwitchDownloaderCLI uses.",
      type = "string",
      optional = true,
      single_param = true,
    },
    {
      field = "dry_run",
      long = "dry-run",
      description = "Tries to give an idea of what the current command would do, without\n\z
        actually downloading anything or writing any files.",
      flag = true;
    },
  },
})--[[@as Args]]
if not args or args.help then return end

local config_path = Path.new(args.config_dir)
if not config_path:exists() then
  util.abort("No such config directory "..config_path:str())
end

local details_file = Path.new(args.config_dir) / "details.txt"

local urls_file
for entry in Path.new(args.config_dir):enumerate() do
  if (config_path / entry):attr("mode") == "file" and Path.new(entry):extension() == ".csv" then
    if urls_file then
      util.abort("There must only be one csv file in the config directory "..config_path:str())
    end
    urls_file = config_path / entry
  end
end

local collection_files = {}

if (config_path / "collections"):exists() then
  for entry in (config_path / "collections"):enumerate() do
    collection_files[#collection_files+1] = config_path / "collections" / entry
  end
end

if args.list_collections then
  for _, collection in ipairs(collection_files) do
    print(Path.new(collection):filename())
  end
  return
end

local urls_str = io_util.read_file(urls_file)
local details_str = io_util.read_file(details_file)
local collection_strs = linq(collection_files)
  :select(function(value, i) return io_util.read_file(value) end)
  :to_array()

local urls = {}

for line in urls_str:gmatch("[^\r\n]+") do
  urls[#urls+1] = line
end

---@class CollectionEntry
---@field collection_title string
---@field index integer
---@field title string
---@field date string
---@field length string
---@field seconds integer
---@field detail Detail

---@type CollectionEntry[][]
local collections = {}

--[[
1
[H] [Part 1] Phobos | Implementing code => AST => code, so basically a Lua formatter | Streaming because maybe it'll help me focus
[H] [Part 1] Phobos | Implementing code => AST => code, so basically a Lua formatter | Streaming because maybe it'll help me focus
July 4, 2021

1:52:24
3
Highlight
]]

for collection_index, collection_str in ipairs(collection_strs) do
  local i = collection_str:match("%s*()")

  local function read_line()
    local line, new_index = collection_str:match("([^\r\n]+)[\r\n]*()", i)
    i = new_index
    return line
  end

  ---@type CollectionEntry[]
  local entries = {}
  collections[collection_index] = entries

  local function parse_timestamp(timestamp)
    local a, b, c = timestamp:match("(%d+):(%d+):?(%d*)")
    local seconds
    if c == "" then
      seconds = tonumber(a) * 60 + tonumber(b)
    else
      seconds = tonumber(a) * 60 * 60 + tonumber(b) * 60 + tonumber(c)
    end
    return seconds
  end

  local collection_title = Path.new(collection_files[collection_index]):filename()

  while i <= #collection_str do
    read_line()
    local title = read_line():match("^%s*(.-)%s*$")
    read_line()
    local date = read_line()
    local length = read_line()
    read_line()
    read_line()
    local index = #entries + 1
    entries[index] = {
      collection_title = collection_title,
      index = index,
      title = title,
      date = date,
      length = length,
      seconds = parse_timestamp(length),
      detail = (nil)--[[@as Detail]],
    }
  end
end

---@class Detail
---@field title string
---@field description string
---@field broadcast_type string
---@field viewable string
---@field views integer
---@field length integer
---@field created_at string
---@field url string
---@field id integer
---@field size integer
---@field collection_entries CollectionEntry[]

---@type Detail[]
local details = {}
local estimated_average_bytes_per_second = 6500 * 1000 / 8

--[[
Title: Amity: Making Sense | Aether Chronicles RP
Description:
Broadcast type: highlight
Viewable: public
Views: 65
Length: 14465 seconds
Created at: 2025-02-18 03:22:14
]]

do
  local i = details_str:match("%s*()")

  local function read_line()
    local line, new_index = details_str:match("[^:]*: *([^\r\n]*)[\r\n]*()", i)
    i = new_index
    return line
  end

  while i <= #details_str do
    local index = #details + 1
    local detail = {
      title = read_line(),
      description = read_line(),
      broadcast_type = read_line(),
      viewable = read_line(),
      views = tonumber(read_line()),
      length = tonumber(read_line():match("%d*")),
      created_at = read_line(),
      url = urls[index],
      id = tonumber(urls[index]:match("%d+$")),
      collection_entries = {},
    }
    details[index] = detail
    detail.bytes = detail.length * estimated_average_bytes_per_second
  end
end

for _, collection in ipairs(collections) do
  for pair in linq(collection)
    :join(linq(details),
      function(outer, index) return outer.seconds.." "..outer.title end,
      function(inner, index) return inner.length.." "..inner.title end,
      function(outer, inner, index) return {entry = outer, detail = inner} end)
    :iterate()--[[@as fun(): {entry: CollectionEntry, detail: Detail}]]
  do
    pair.entry.detail = pair.detail
    pair.detail.collection_entries[#pair.detail.collection_entries+1] = pair.entry
  end
end

do
  local invalid = false
  for _, detail in ipairs(details) do
    if detail.collection_entries[2] then
      io.stderr:write(string.format("The '%s' video is in multiple collections. \z
        For simplicity of this script, as well as the fact that youtube can only have each video in one \z
        official playlist, this is not supported.\n\z
        Collections:\n%s\n",
        detail.title,
        table.concat(linq(detail.collection_entries):select(function(e) return e.collection_title end):to_array(), "\n"))
      ):flush()
      invalid = true
    end
  end
  if invalid then os.exit(1) end
end

-- print("duplicate titles:")
-- for group in linq(details)
--   :group_by(function(value, index) return value.title end)
--   :where(function(value, i) return value.count > 1 end)
--   :iterate()
-- do
--   for _, detail in ipairs(group) do
--     print(group.count, detail.title, detail.created_at)
--   end
-- end

---@param detail Detail
local function add_collection_index_prefix(detail, filename)
  if not detail.collection_entries[1] then
    return filename
  end
  return string.format("%03d  %s", detail.collection_entries[1].index, filename)
end

---@param detail Detail
local function get_video_filename(detail)
  return add_collection_index_prefix(
    detail,
    string.format("%s  %s.mp4", detail.created_at, detail.title)
  )
end

---@param detail Detail
local function get_metadata_filename(detail)
  return add_collection_index_prefix(
    detail,
    string.format("%s  metadata.json", detail.created_at)
  )
end

---@param detail Detail
local function get_chat_filename(detail)
  return add_collection_index_prefix(
    detail,
    string.format("%s  chat.json", detail.created_at)
  )
end

---@param detail Detail
local function get_output_path(detail)
  return detail.collection_entries[1]
    and (Path.new(args.output_dir) / detail.collection_entries[1].collection_title)
    or Path.new(args.output_dir)
end

---@param detail Detail
local function download_video(detail)
  local filename = get_video_filename(detail)
  print("downloading "..filename)
  local command = string.format(
    "%s videodownload --id %d -o %s%s",
    config.downloader_cli,
    detail.id,
    shell_util.escape_arg((get_output_path(detail) / filename):str()),
    args.temp_dir and (" --temp-path "..shell_util.escape_arg(args.temp_dir)) or ""
  )
  print(command)
  local success = os.execute(command)
  print() -- TwitchDownloaderCLI does not write a trailing newline to stdout before existing
  if not success then os.exit(1) end
end

---@param detail Detail
local function download_chat(detail)
  local filename = get_chat_filename(detail)
  print("downloading "..filename)
  local command = string.format(
    "%s chatdownload --embed-images --id %d -o %s%s",
    config.downloader_cli,
    detail.id,
    shell_util.escape_arg((get_output_path(detail) / filename):str()),
    args.temp_dir and (" --temp-path "..shell_util.escape_arg(args.temp_dir)) or ""
  )
  print(command)
  local success = os.execute(command)
  print() -- TwitchDownloaderCLI does not write a trailing newline to stdout before existing
  if not success then os.exit(1) end
end

---@param detail Detail
local function get_metadata_file_contents(detail)
  local metadata_json = {
    title = detail.title,
    description = detail.description,
    broadcast_type = detail.broadcast_type,
    viewable = detail.viewable,
    views = detail.views,
    seconds = detail.length,
    created_at = detail.created_at,
    url = detail.url,
    id = detail.id,
    collection_index = detail.collection_entries[1] and detail.collection_entries[1].index or -1,
    collection_title = detail.collection_entries[1] and detail.collection_entries[1].collection_title or "",
  }
  return json.to_json(metadata_json, {indent = "  "})
end

---@param detail Detail
local function process_downloads(detail)
  if args.dry_run then
    print(detail.title)
    return
  end

  local output_path = get_output_path(detail)

  local metadata_path = output_path / get_metadata_filename(detail)
  if not metadata_path:exists() then
    io_util.write_file(
      metadata_path,
      get_metadata_file_contents(detail)
    )
  end

  local video_path = output_path / get_video_filename(detail)
  if args.download_video and not video_path:exists() then
    download_video(detail)
  end

  local chat_path = output_path / get_chat_filename(detail)
  if args.download_chat and not chat_path:exists() then
    download_chat(detail)
  end
end

-- local missing_files = false

-- ---@param detail Detail
-- ---@param bypass_warning_checks boolean?
-- local function add_extra_info_for_video_file(detail, bypass_warning_checks)
--   local output_path = get_output_path(detail)
--   if not (output_path / get_video_filename(detail)):exists() then return end

--   local metadata_path = output_path / get_metadata_filename(detail)
--   if not metadata_path:exists() then
--     if not bypass_warning_checks and not args.no_warn_on_missing_metadata then
--       io.stderr:write("Missing metadata file for the video file '"..metadata_path:str()
--         .."', make sure the video finished downloading successfully. If it did then \z
--         use the --no-warn-on-missing-metadata option to make it generate a new \z
--         metadata file instead of aborting."):flush()
--       missing_files = true
--     end
--     io_util.write_file(
--       metadata_path,
--       get_metadata_file_contents(detail)
--     )
--   end

--   local chat_path = output_path / get_chat_filename(detail)
--   if not chat_path:exists() then
--     if not bypass_warning_checks and not args.no_warn_on_missing_chat then
--       io.stderr:write("Missing chat file for the video file '"..chat_path:str()
--         .."', make sure the video finished downloading successfully. If it did then \z
--         use the --no-warn-on-missing-chat option to make it download chat history \z
--         instead of aborting."):flush()
--       missing_files = true
--     end
--     download_chat(detail)
--   end
-- end

-- for _, detail in ipairs(details) do
--   add_extra_info_for_video_file(detail)
-- end

-- if missing_files then
--   util.abort()
-- end

---@param detail Detail
local function should_process(detail)
  if args.non_collections then
    return not detail.collection_entries[1]
  end
  if args.collections then
    return detail.collection_entries[1]
      and linq(args.collections):contains(detail.collection_entries[1].collection_title)
  end
  return true
end

local start_time = os.time()
for detail in linq(details):reverse():iterate() do
  if should_process(detail) then
    process_downloads(detail)
  end
  if args.time_limit > 0 and (os.time() - start_time) > (args.time_limit * 60) then
    break
  end
end
