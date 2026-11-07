-- Input mapping: keys, gamepad buttons and touch/mouse to abstract actions.
-- Pure Lua; coordinates passed to touch/mouse are already logical.
local input = {}
input.__index = input

local KEYS = {
  ["return"] = "select", space = "select", escape = "back",
  up = "up", down = "down", left = "left", right = "right",
  p = "skip", c = "mycats", backspace = "erase",
}

local PAD = {
  dpup = "up", dpdown = "down", dpleft = "left", dpright = "right",
  a = "select", b = "back", x = "skip", y = "mycats",
  back = "rules", start = "ok",
}

local DOUBLE_WINDOW = 0.3

function input.new()
  return setmetatable({ lastTouch = nil }, input)
end

function input:key(k)
  return KEYS[k]
end

-- Text typed by the user; "?" opens the rules whatever the keyboard layout.
function input:text(t)
  if t == "?" then return "rules" end
end

function input:button(b)
  return PAD[b]
end

function input:touch(x, y, t)
  self.lastTouch = t
  return "tap", x, y
end

function input:mouse(x, y, button, istouch, t)
  if button ~= 1 then return nil end
  if istouch and self.lastTouch and t - self.lastTouch < DOUBLE_WINDOW then
    return nil
  end
  return "tap", x, y
end

return input
