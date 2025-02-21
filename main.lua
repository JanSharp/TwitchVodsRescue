
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
---@field help boolean

-- ---@field no_warn_on_missing_metadata boolean
-- ---@field no_warn_on_missing_chat boolean

local args = arg_parser.parse_and_print_on_error_or_help({...}, {
  options = {
    -- {
    --   field = "no_warn_on_missing_metadata",
    --   long = "no-warn-on-missing-metadata",
    --   description = "If a video exists without an associated metadata file, the program \n\z
    --     generates a warning because that video may not have finished \n\z
    --     downloading correctly. By ignoring this warning it will \n\z
    --     simply generate the missing metadata file.",
    --   flag = true,
    -- },
    -- {
    --   field = "no_warn_on_missing_chat",
    --   long = "no-warn-on-missing-chat",
    --   description = "Same as --no-warn-on-missing-metadata, except \n\z
    --     that when the file is missing it will start a download for \n\z
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
      description = "Download chat history into a json file. The TwitchDownloader CLI and \n\z
        GUI can render a video from this, which is a separate video from the \n\z
        main one, so that in particular is only useful for you locally.",
      flag = true,
    },
    {
      field = "time_limit",
      long = "time-limit",
      description = "Automatically stop once more this amount of minutes have passed. \n\z
        Zero or less means no limit. Do note however that when closing \n\z
        or killing the process while it is running will most likely result in \n\z
        unfinished downloads in the output directory. Make sure to delete \n\z
        those files.",
      type = "number",
      optional = true,
      default_value = 0,
      single_param = true,
    },
  },
})--[[@as Args]]
if not args or args.help then return end

local urls_file = config.urls_list
local details_file = config.details_list
local collection_files = config.collections

local kilo = 1000
local mega = kilo * 1000
local giga = mega * 1000
local terra = giga * 1000

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
    local title = read_line()
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
    and (Path.new(config.output_directory) / detail.collection_entries[1])
    or Path.new(config.output_directory)
end

---@param detail Detail
local function download_video(detail)
  local filename = get_video_filename(detail)
  print("downloading "..filename)
  local command = string.format(
    "%s videodownload --id %d -o %s %s",
    config.downloader_cli,
    detail.id,
    shell_util.escape_arg((get_output_path(detail) / filename):str()),
    config.downloader_cli_args
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
    "%s chatdownload --embed-images --id %d -o %s %s",
    config.downloader_cli,
    detail.id,
    shell_util.escape_arg((get_output_path(detail) / filename):str()),
    config.downloader_cli_args
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
  local output_path = get_output_path(detail)
  if detail.collection_entries[1] then
    output_path = output_path / detail.collection_entries[1].collection_title
  end

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

local start_time = os.time()
for detail in linq(details):reverse():iterate() do
  process_downloads(detail)
  if args.time_limit > 0 and (os.time() - start_time) > (args.time_limit * 60) then
    break
  end
end
