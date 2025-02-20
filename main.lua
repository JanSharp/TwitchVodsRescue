
local linq = require("linq")
local config = require("config")
local Path = require("path")
local arg_parser = require("arg_parser")

local args = arg_parser.parse_and_print_on_error_or_help({...}, {
  options = {

  },
})
if not args then return end

local urls_file = config.urls_list
local details_file = config.details_list
local collection_files = config.collections

local kilo = 1000
local mega = kilo * 1000
local giga = mega * 1000
local terra = giga * 1000

---@param name string
---@return string
local function read_file(name)
  local file = io.open(name, "r")
  if not file then error("Could not open file "..name) end
  local content = file:read("*a")
  file:close()
  return content
end

local urls_str = read_file(urls_file)
local details_str = read_file(details_file)
local collection_strs = linq(collection_files)
  :select(function(value, i) return read_file(value) end)
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
    -- print(string.format("%.3f  %s", detail.length / 60 / 60, detail.title))
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

local b

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

-- print("downloading 828418665")
-- local command = string.format(
--   "%s videodownload --id %d -o %s %s",
--   config.downloader_cli,
--   828418665,
--   (Path.new(config.output_directory) / "828418665.mp4"):str(),
--   config.downloader_cli_args
-- )
-- print(command)
-- local success = os.execute(command)
-- print() -- TwitchDownloaderCLI does not write a trailing newline to stdout before existing
-- print("result: ", tostring(success))
-- if not success then
--   print("fail")
--   os.exit(1)
-- end
-- print("success")

local b
