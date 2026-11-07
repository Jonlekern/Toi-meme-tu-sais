local categories = require("categories")

local M = {}

local BOM = "\239\187\191"

-- Split text into cleaned lines: trimmed, no blanks, no "#" comments, no duplicates.
function M.parse(text)
  local out, seen = {}, {}
  if text:sub(1, 3) == BOM then text = text:sub(4) end
  for line in (text .. "\n"):gmatch("(.-)\r?\n") do
    line = line:gsub("\r", ""):match("^%s*(.-)%s*$")
    if line ~= "" and line:sub(1, 1) ~= "#" and not seen[line] then
      seen[line] = true
      out[#out + 1] = line
    end
  end
  return out
end

-- read(path) returns file text or nil.
function M.load(read)
  local result = { melange = {}, categories = {} }
  local text = read("words/melange.txt")
  if text then result.melange = M.parse(text) end
  for _, c in ipairs(categories.LIST) do
    local t = read("words/" .. c.id .. ".txt")
    if t then
      local list = M.parse(t)
      if #list > 0 then
        result.categories[#result.categories + 1] = { id = c.id, label = c.label, words = list }
      end
    end
  end
  return result
end

return M
