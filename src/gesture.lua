-- Gesture recognizer for one finger (or the mouse): feed it press / move /
-- release with logical coordinates and a time in seconds, and update(t)
-- while the finger is down. Pure Lua.
--
-- Events (returned as name, info):
--   "long_press"  from update(), once, when held still long enough
--   "drag_up"     from move(), once the finger left the tap zone;
--                 info.up = upward distance (>= 0), info.side = start side
--   "swipe_right" / "swipe_left"  from release(), quick mostly-horizontal move
--   "drag_end"    from release(), any other move; info.up, info.vy (upward px/s)
--   "tap"         from release(), short press without moving
-- info always holds x, y (current), x0, y0 (start) and side ("left" or
-- "right" of the mid line given to press, or of the start point).
local gesture = {}
gesture.__index = gesture

gesture.SLOP = 12          -- px a tap or long press may move
gesture.LONG = 0.5         -- s held still for a long press
gesture.SWIPE_DIST = 60    -- px horizontal for a swipe
gesture.SWIPE_TIME = 0.6   -- s at most for a swipe
gesture.SWIPE_RATIO = 1.5  -- |dx| must exceed |dy| this many times
gesture.VELOCITY_SPAN = 0.1 -- s of recent movement used for the speed

function gesture.new()
  return setmetatable({ down = false }, gesture)
end

function gesture:info(x, y)
  return {
    x = x, y = y, x0 = self.x0, y0 = self.y0,
    dx = x - self.x0, dy = y - self.y0,
    up = math.max(0, self.y0 - y),
    side = self.side,
  }
end

-- mid: optional x of the line splitting "left" from "right" (e.g. a note's centre).
function gesture:press(x, y, t, mid)
  self.down = true
  self.x0, self.y0, self.t0 = x, y, t
  self.x, self.y = x, y
  self.moved = false
  self.long = false
  self.side = (mid and x < mid) and "left" or "right"
  self.samples = { { x = x, y = y, t = t } }
end

function gesture:cancel()
  self.down = false
end

function gesture:update(t)
  if not self.down or self.moved or self.long then return nil end
  if t - self.t0 >= gesture.LONG then
    self.long = true
    return "long_press", self:info(self.x, self.y)
  end
  return nil
end

function gesture:move(x, y, t)
  if not self.down then return nil end
  self.x, self.y = x, y
  local s = self.samples
  s[#s + 1] = { x = x, y = y, t = t }
  -- keep only what the speed needs
  while #s > 2 and t - s[2].t >= gesture.VELOCITY_SPAN do table.remove(s, 1) end
  if self.long then return nil end
  if not self.moved then
    local dx, dy = x - self.x0, y - self.y0
    if dx * dx + dy * dy < gesture.SLOP * gesture.SLOP then return nil end
    self.moved = true
  end
  return "drag_up", self:info(x, y)
end

function gesture:release(x, y, t)
  if not self.down then return nil end
  local _, info = self:move(x, y, t)
  self.down = false
  if self.long then return nil end
  info = info or self:info(x, y)
  if not self.moved then
    -- held long enough but update() missed it: still a long press
    if t - self.t0 >= gesture.LONG then return "long_press", info end
    return "tap", info
  end
  local dx, dy = info.dx, info.dy
  if math.abs(dx) >= gesture.SWIPE_DIST and math.abs(dx) > gesture.SWIPE_RATIO * math.abs(dy)
    and t - self.t0 < gesture.SWIPE_TIME then
    return dx > 0 and "swipe_right" or "swipe_left", info
  end
  local first = self.samples[1]
  local span = t - first.t
  info.vy = span > 0 and (first.y - y) / span or 0
  return "drag_end", info
end

return gesture
