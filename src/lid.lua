-- Lid switch (SW_LID) support: pure Lua so it can be tested without LÖVE.
local lid = {}

local EV_SW, SW_LID = 5, 0

-- First block of /proc/bus/input/devices whose "B: SW=" has the SW_LID bit.
function lid.find_device(text)
  if not text then return nil end
  for block in (text .. "\n\n"):gmatch("(.-)\n%s*\n") do
    local sw = block:match("B: SW=([%x ]+)")
    local handler = block:match("H: Handlers=[^\n]*(event%d+)")
    if sw and handler then
      local last = sw:match("(%x+)%s*$")
      local low = last and tonumber(last, 16)
      if low and low % 2 == 1 then return "/dev/input/" .. handler end
    end
  end
  return nil
end

local function u16(s, i) return s:byte(i) + s:byte(i + 1) * 256 end

-- input_event on aarch64: timeval (16 bytes), u16 type, u16 code, s32 value, little-endian.
function lid.decode(bytes)
  if not bytes or #bytes < 24 then return nil end
  local v = u16(bytes, 21) + u16(bytes, 23) * 65536
  if v >= 2 ^ 31 then v = v - 2 ^ 32 end
  return { type = u16(bytes, 17), code = u16(bytes, 19), value = v }
end

function lid.lid_state(ev)
  if ev and ev.type == EV_SW and ev.code == SW_LID then
    return ev.value ~= 0 and "closed" or "open"
  end
  return nil
end

local Tracker = {}
Tracker.__index = Tracker

-- true only when "open" follows "closed".
function Tracker:feed(state)
  local reopened = state == "open" and self.last == "closed"
  self.last = state
  return reopened or nil
end

function lid.tracker() return setmetatable({}, Tracker) end

return lid
