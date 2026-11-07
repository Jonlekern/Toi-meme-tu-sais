-- Pink sticky note that hides the word (web, long press) and is peeled off by
-- dragging up: the bottom corner on the finger's side folds back along a line
-- that follows the finger. Geometry and states are pure Lua; only draw() uses LÖVE.
local sticky = {}
sticky.__index = sticky

sticky.DROP = 0.25    -- s, falling onto the word
sticky.FLY = 0.3      -- s, peeled off and flying away
sticky.BACK = 0.15    -- s, sticking back
sticky.PEEL = 0.35    -- fraction of the height past which it peels off
sticky.FLICK = 700    -- px/s upward: a quick flick peels it off too
sticky.FLICK_MIN = 20 -- px the flick must at least travel
sticky.RADIUS = 5     -- rounded corners

local function ease_out(k) return 1 - (1 - k) ^ 3 end
local function ease_in(k) return k * k end

-- Note centred on (cx, cy), w x h, resting at angle rot (radians).
-- state "drop" plays the falling animation, "stuck" starts at rest.
function sticky.new(cx, cy, w, h, rot, state)
  return setmetatable({
    cx = cx, cy = cy, w = w, h = h, rot = rot or -0.05,
    state = state or "drop", t = 0,
    fold = 0, side = "right",
  }, sticky)
end

-- Whether the word must stay as it is: everything but flying away.
function sticky:blocking()
  return self.state ~= "fly"
end

-- Point (x, y) in note coordinates (centre at 0, 0, unrotated).
function sticky:to_local(x, y)
  local dx, dy = x - self.cx, y - self.cy
  local c, s = math.cos(-self.rot), math.sin(-self.rot)
  return dx * c - dy * s, dx * s + dy * c
end

function sticky:contains(x, y)
  local lx, ly = self:to_local(x, y)
  return math.abs(lx) <= self.w / 2 and math.abs(ly) <= self.h / 2
end

-- Start peeling from a press at (x, y): returns false if the press missed the note
-- or the note is not at rest.
function sticky:grab(x, y)
  if (self.state ~= "stuck" and self.state ~= "back") or not self:contains(x, y) then return false end
  local lx = self:to_local(x, y)
  self.side = lx < 0 and "left" or "right"
  self.state = "peel"
  return true
end

-- Finger moved: up = how far above the press it is (px).
function sticky:drag(up)
  if self.state ~= "peel" then return end
  self.fold = math.min(math.max(up, 0), self.h * 1.1)
end

-- Finger lifted: peel off past the threshold or on a quick flick, else stick back.
-- Returns the new state.
function sticky:release(up, vy)
  if self.state ~= "peel" then return self.state end
  self:drag(up)
  self.t = 0
  if up >= self.h * sticky.PEEL or ((vy or 0) >= sticky.FLICK and up >= sticky.FLICK_MIN) then
    self.state = "fly"
    self.fly_fold = self.fold
  else
    self.state = "back"
    self.back_fold = self.fold
  end
  return self.state
end

-- Advance the animations; returns "gone" once it flew away.
function sticky:update(dt)
  self.t = self.t + dt
  if self.state == "drop" and self.t >= sticky.DROP then
    self.state, self.t = "stuck", 0
  elseif self.state == "back" then
    local k = math.min(self.t / sticky.BACK, 1)
    self.fold = self.back_fold * (1 - ease_out(k))
    if k >= 1 then self.state, self.t, self.fold = "stuck", 0, 0 end
  elseif self.state == "fly" then
    local k = math.min(self.t / sticky.FLY, 1)
    self.fold = self.fly_fold + (self.h * 0.6 - self.fly_fold) * ease_out(k)
    if k >= 1 then return "gone" end
  end
  return nil
end

-- Pose for drawing: offset (dx, dy), angle, scale, lift (0 = flat, 1 = high).
function sticky:pose()
  if self.state == "drop" then
    local e = ease_out(math.min(self.t / sticky.DROP, 1))
    return 0, -70 * (1 - e), self.rot - 0.2 * (1 - e), 1 + 0.12 * (1 - e), 1 - e
  elseif self.state == "fly" then
    local e = ease_in(math.min(self.t / sticky.FLY, 1))
    local turn = self.side == "right" and -1 or 1
    return 40 * turn * -e, -1000 * e, self.rot + turn * 0.7 * e, 1 + 0.08 * e, e
  end
  return 0, 0, self.rot, 1, 0
end

-- Rectangle w x h centred on the origin with rounded corners, as a flat
-- clockwise (screen y down) point list; convex.
function sticky.shape(w, h, r)
  local pts = {}
  local corners = {
    { w / 2 - r, -h / 2 + r, -math.pi / 2 }, -- top right
    { w / 2 - r, h / 2 - r, 0 },             -- bottom right
    { -w / 2 + r, h / 2 - r, math.pi / 2 },  -- bottom left
    { -w / 2 + r, -h / 2 + r, math.pi },     -- top left
  }
  for _, c in ipairs(corners) do
    for i = 0, 4 do
      local a = c[3] + i / 4 * math.pi / 2
      pts[#pts + 1] = c[1] + r * math.cos(a)
      pts[#pts + 1] = c[2] + r * math.sin(a)
    end
  end
  return pts
end

-- Fold a convex polygon (flat list) so that corner point c lands on p: the part
-- on c's side of the perpendicular bisector of c-p is cut off (main keeps the
-- rest) and mirrored across that line (flap). Returns main, flap (flap nil when
-- nothing is folded).
function sticky.fold(poly, cx, cy, px, py)
  local nx, ny = cx - px, cy - py
  local len = math.sqrt(nx * nx + ny * ny)
  if len < 1e-6 then return poly, nil end
  nx, ny = nx / len, ny / len
  local mx, my = (cx + px) / 2, (cy + py) / 2
  local function side(x, y) return (x - mx) * nx + (y - my) * ny end
  local keep, cut = {}, {}
  local n = #poly / 2
  for i = 1, n do
    local x1, y1 = poly[2 * i - 1], poly[2 * i]
    local j = i % n + 1
    local x2, y2 = poly[2 * j - 1], poly[2 * j]
    local s1, s2 = side(x1, y1), side(x2, y2)
    if s1 <= 0 then keep[#keep + 1] = x1; keep[#keep + 1] = y1 end
    if s1 > 0 then cut[#cut + 1] = x1; cut[#cut + 1] = y1 end
    if (s1 <= 0) ~= (s2 <= 0) then
      local k = s1 / (s1 - s2)
      local ix, iy = x1 + (x2 - x1) * k, y1 + (y2 - y1) * k
      keep[#keep + 1] = ix; keep[#keep + 1] = iy
      cut[#cut + 1] = ix; cut[#cut + 1] = iy
    end
  end
  if #cut < 6 then return poly, nil end
  local flap = {}
  for i = 1, #cut / 2 do
    local x, y = cut[2 * i - 1], cut[2 * i]
    local d = 2 * side(x, y)
    flap[#flap + 1] = x - d * nx
    flap[#flap + 1] = y - d * ny
  end
  return keep, flap
end

-- Where the folded corner sits for the current fold amount (note coordinates).
function sticky:corner()
  local sx = self.side == "left" and -1 or 1
  local cx, cy = sx * self.w / 2, self.h / 2
  return cx, cy, cx - sx * 0.35 * self.fold, cy - self.fold
end

-- Main part and flap of the note for the current fold.
function sticky:geometry()
  local poly = sticky.shape(self.w, self.h, sticky.RADIUS)
  if self.fold < 0.5 then return poly, nil end
  return sticky.fold(poly, self:corner())
end

local PINK = { 0xF2 / 255, 0x6E / 255, 0xF2 / 255 }
local FLAP = { 0xF8 / 255, 0xA8 / 255, 0xF8 / 255 }
local INK = { 0x1a / 255, 0x1a / 255, 0x1a / 255 }

local function offset(poly, dx, dy)
  local out = {}
  for i = 1, #poly, 2 do
    out[i], out[i + 1] = poly[i] + dx, poly[i + 1] + dy
  end
  return out
end

-- Draw at the note's place (logical coordinates); fonts: candidates for
-- « Toi-même tu sais », largest first (the first that fits is used).
function sticky:draw(fonts)
  local g = love.graphics
  local dx, dy, rot, sc, lift = self:pose()
  local main, flap = self:geometry()
  g.push()
  g.translate(self.cx + dx, self.cy + dy)
  g.rotate(rot)
  g.scale(sc, sc)

  -- drop shadow, softer and further when the note is higher
  local sh = 5 + 14 * lift
  g.setColor(0, 0, 0, 0.22)
  g.polygon("fill", offset(main, sh * 0.4, sh * 1.2))
  g.setColor(0, 0, 0, 0.18)
  g.polygon("fill", offset(main, sh * 0.8, sh * 2))

  g.setColor(PINK)
  g.polygon("fill", main)

  -- text, clipped to the part still flat
  g.stencil(function() g.polygon("fill", main) end, "replace", 1)
  g.setStencilTest("greater", 0)
  g.setColor(INK)
  local tw = self.w - 44
  local font = fonts[#fonts]
  for _, f in ipairs(fonts) do
    if f:getWidth("Toi-même") <= tw then font = f; break end
  end
  g.setFont(font)
  local th = 2 * font:getHeight()
  g.printf("Toi-même\ntu sais", -tw / 2, -th / 2 + 8, tw, "left")
  g.setStencilTest()

  -- translucent tape across the top edge
  g.push()
  g.translate(0, -self.h / 2)
  g.rotate(0.04)
  local tw2, th2 = math.min(self.w * 0.38, 150), 30
  g.setColor(1, 1, 1, 0.42)
  g.rectangle("fill", -tw2 / 2, -th2 / 2, tw2, th2)
  g.setColor(1, 1, 1, 0.25)
  g.rectangle("fill", -tw2 / 2, -th2 / 2, tw2, 3)
  g.pop()

  if flap then
    -- the lifted flap casts a shadow on the note, then shows its lighter back
    g.setColor(0, 0, 0, 0.25)
    g.polygon("fill", offset(flap, 3, 5))
    g.setColor(FLAP)
    g.polygon("fill", flap)
    g.setColor(0xD9 / 255, 0x55 / 255, 0xD9 / 255, 0.8)
    g.setLineWidth(1.5)
    g.polygon("line", flap)
  end
  g.pop()
end

return sticky
