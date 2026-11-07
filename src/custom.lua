-- Custom categories: file format and naming rules. Pure Lua.
local categories = require("categories")

local M = {}

M.MAX_NAME, M.MAX_WORD = 24, 40

local UPPER = { ["É"] = "é", ["È"] = "è", ["Ê"] = "ê", ["Ë"] = "ë", ["À"] = "à", ["Â"] = "â",
  ["Î"] = "î", ["Ï"] = "ï", ["Ô"] = "ô", ["Û"] = "û", ["Ù"] = "ù", ["Ü"] = "ü", ["Ç"] = "ç",
  ["Œ"] = "œ", ["Æ"] = "æ" }

local function fold(s)
  return (s:gsub("[\195\197][\128-\191]", UPPER):lower())
end

local function length(s)
  return #s:gsub("[\128-\191]", "")
end

-- Trim, collapse inner spaces; commas (settings separator) and a leading "[" are not kept.
local function clean(s, is_name)
  s = (s or ""):gsub("%s+", " "):match("^ ?(.-) ?$")
  if is_name then s = s:gsub(",", " "):gsub("%s+", " ") else s = s:gsub("^%[+", "") end
  return (s:match("^ ?(.-) ?$"))
end

local parse_valid_name -- set below (needs valid_name)

function M.parse(text)
  local out, cur = {}, nil
  if type(text) ~= "string" then return out end
  if text:sub(1, 3) == "\239\187\191" then text = text:sub(4) end
  for line in (text .. "\n"):gmatch("(.-)\r?\n") do
    local name = line:match("^%[(.+)%]%s*$")
    if name then
      name = clean(name, true)
      cur = nil
      if name ~= "" and parse_valid_name(out, name) then
        cur = { name = name, words = {} }
        out[#out + 1] = cur
      end
    elseif cur and not line:match("^%s*%[") then
      local w = clean(line)
      if w ~= "" then cur.words[#cur.words + 1] = w end
    end
  end
  return out
end

function M.serialize(cats)
  local parts = {}
  for _, c in ipairs(cats) do
    parts[#parts + 1] = "[" .. c.name .. "]\n"
    for _, w in ipairs(c.words) do parts[#parts + 1] = w .. "\n" end
  end
  return table.concat(parts)
end

function M.valid_name(cats, name, ignore_index)
  name = clean(name, true)
  if name == "" then return nil, "vide" end
  if length(name) > M.MAX_NAME then return nil, "trop long" end
  local f = fold(name)
  for _, b in ipairs(categories.LIST) do
    if fold(b.label) == f then return nil, "réservé" end
  end
  for i, c in ipairs(cats) do
    if i ~= ignore_index and fold(c.name) == f then return nil, "existe" end
  end
  return true
end

parse_valid_name = M.valid_name

function M.clean_name(name) return clean(name, true) end

local function check_word(cat, word, ignore_index)
  word = clean(word)
  if word == "" then return nil, "vide" end
  if length(word) > M.MAX_WORD then return nil, "trop long" end
  local f = fold(word)
  for i, w in ipairs(cat.words) do
    if i ~= ignore_index and fold(w) == f then return nil, "existe" end
  end
  return word
end

-- Same rules as add_word/set_word, without changing anything.
function M.valid_word(cat, word, ignore_index)
  local w, why = check_word(cat, word, ignore_index)
  if not w then return nil, why end
  return true
end

function M.add_word(cat, word)
  local w, why = check_word(cat, word)
  if not w then return nil, why end
  cat.words[#cat.words + 1] = w
  return true
end

function M.set_word(cat, index, word)
  local w, why = check_word(cat, word, index)
  if not w then return nil, why end
  cat.words[index] = w
  return true
end

function M.as_categories(cats)
  local out = {}
  for _, c in ipairs(cats) do
    if #c.words > 0 then
      local words = {}
      for i, w in ipairs(c.words) do words[i] = w end
      out[#out + 1] = { id = "perso:" .. c.name, label = c.name, words = words }
    end
  end
  return out
end

return M
