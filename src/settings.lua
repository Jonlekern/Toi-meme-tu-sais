local categories = require("categories")

local M = {}

local TIMERS = { [0] = true, [30] = true, [60] = true, [90] = true }

function M.default()
  return { categories = {}, timer = 0 }
end

function M.parse(text, known)
  local s = M.default()
  if type(text) ~= "string" then return s end
  known = known or {}
  for line in (text .. "\n"):gmatch("(.-)\r?\n") do
    local key, value = line:match("^(%a+)=(.*)$")
    if key == "timer" then
      local n = tonumber(value)
      if n and TIMERS[n] then s.timer = n end
    elseif key == "categories" then
      local set = {}
      for id in (value .. ","):gmatch("(.-),") do
        if known[id] then set[id] = true end
      end
      s.categories = set
    end
  end
  return s
end

function M.serialize(s)
  local ids, builtin = {}, {}
  for _, c in ipairs(categories.LIST) do
    builtin[c.id] = true
    if s.categories[c.id] then ids[#ids + 1] = c.id end
  end
  local others = {}
  for id, on in pairs(s.categories) do
    if on and not builtin[id] then others[#others + 1] = id end
  end
  table.sort(others)
  for _, id in ipairs(others) do ids[#ids + 1] = id end
  return "timer=" .. tostring(s.timer or 0) .. "\ncategories=" .. table.concat(ids, ",") .. "\n"
end

return M
