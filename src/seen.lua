-- Memory of the words already shown, kept across rounds and launches.
-- Pure Lua: one word per line in the saved text. Words are identified by
-- their text. `on_change`, when set, is called after the memory changed.
local seen = {}
seen.__index = seen

function seen.new()
  return setmetatable({ set = {} }, seen)
end

function seen.parse(text)
  local s = seen.new()
  if type(text) ~= "string" then return s end
  for line in (text .. "\n"):gmatch("(.-)\r?\n") do
    -- damaged lines (blank, control characters) are ignored
    if line:match("%S") and not line:find("[%z\1-\31]") then s.set[line] = true end
  end
  return s
end

function seen:serialize()
  local words = {}
  for w in pairs(self.set) do words[#words + 1] = w end
  table.sort(words)
  if #words == 0 then return "" end
  return table.concat(words, "\n") .. "\n"
end

function seen:mark(word) self.set[word] = true end

function seen:has(word) return self.set[word] == true end

function seen:reset(words)
  for _, w in ipairs(words) do self.set[w] = nil end
end

function seen:changed()
  if self.on_change then self.on_change(self) end
end

return seen
