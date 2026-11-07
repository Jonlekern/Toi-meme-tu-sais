-- On-screen AZERTY keyboard model (cursor + shift). Pure Lua.
local M = {}
M.__index = M

local function letters(s)
  local out = {}
  for ch in s:gmatch("[%z\1-\127\194-\244][\128-\191]*") do out[#out + 1] = { label = ch, char = ch, span = 1 } end
  return out
end

local UPPER = { ["é"] = "É", ["è"] = "È", ["à"] = "À", ["ç"] = "Ç" }

function M.new()
  local rows = {
    letters("azertyuiop"), letters("qsdfghjklm"), letters("wxcvbnéèàç"),
    {
      { label = "Maj", type = "shift", span = 2 },
      { label = "espace", type = "space", span = 4 },
      { label = "⌫", type = "erase", span = 2 },
      { label = "OK", type = "ok", span = 2 },
    },
  }
  for _, row in ipairs(rows) do
    local x = 0
    for _, k in ipairs(row) do k.x = x; x = x + k.span end
  end
  return setmetatable({ rows = rows, row = 1, idx = 1, cx = 0.5, shift = false }, M)
end

function M:focused() return self.rows[self.row][self.idx] end

local function center(k) return k.x + k.span / 2 end

function M:move(dir)
  if dir == "left" or dir == "right" then
    local n = self.idx + (dir == "left" and -1 or 1)
    if self.rows[self.row][n] then
      self.idx = n
      self.cx = center(self:focused())
    end
  elseif dir == "up" or dir == "down" then
    local r = self.row + (dir == "up" and -1 or 1)
    local row = self.rows[r]
    if not row then return end
    for i, k in ipairs(row) do
      if self.cx >= k.x and self.cx < k.x + k.span then self.row, self.idx = r, i end
    end
  end
end

-- Label to draw for a key, honouring shift.
function M:label(k)
  if k.char and self.shift then return UPPER[k.char] or k.char:upper() end
  return k.label
end

function M:press()
  local k = self:focused()
  if k.char then
    local c = k.char
    if self.shift then
      c = UPPER[c] or c:upper()
      self.shift = false
    end
    return { type = "char", char = c }
  elseif k.type == "shift" then
    self.shift = not self.shift
  end
  return { type = k.type }
end

return M
