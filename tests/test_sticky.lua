local sticky = require("sticky")

local function near(a, b) return math.abs(a - b) < 1e-6 end

local function area(poly)
  local s, n = 0, #poly / 2
  for i = 1, n do
    local j = i % n + 1
    s = s + poly[2 * i - 1] * poly[2 * j] - poly[2 * j - 1] * poly[2 * i]
  end
  return math.abs(s) / 2
end

return {
  test_sticky_drop_then_stuck = function()
    local n = sticky.new(100, 100, 200, 150)
    T.eq(n.state, "drop")
    T.ok(n:blocking())
    n:update(0.1)
    T.eq(n.state, "drop")
    n:update(0.2)
    T.eq(n.state, "stuck")
  end,

  test_sticky_contains_rotated = function()
    local n = sticky.new(100, 100, 200, 100, 0.3, "stuck")
    T.ok(n:contains(100, 100))
    T.ok(not n:contains(100, 170))
    T.ok(not n:contains(300, 100))
  end,

  test_sticky_grab_side = function()
    local n = sticky.new(100, 100, 200, 100, 0, "stuck")
    T.ok(not n:grab(400, 100), "missed")
    T.ok(n:grab(60, 120))
    T.eq(n.side, "left")
    local m = sticky.new(100, 100, 200, 100, 0, "stuck")
    m:grab(150, 120)
    T.eq(m.side, "right")
  end,

  test_sticky_no_grab_while_dropping = function()
    local n = sticky.new(100, 100, 200, 100)
    T.ok(not n:grab(100, 100))
  end,

  test_sticky_sticks_back_below_threshold = function()
    local n = sticky.new(0, 0, 200, 100, 0, "stuck")
    n:grab(50, 0)
    n:drag(30)
    T.eq(n.fold, 30)
    T.eq(n:release(30, 100), "back")
    T.ok(n:blocking())
    n:update(0.2)
    T.eq(n.state, "stuck")
    T.eq(n.fold, 0)
  end,

  test_sticky_peels_past_threshold = function()
    local n = sticky.new(0, 0, 200, 100, 0, "stuck")
    n:grab(50, 0)
    T.eq(n:release(40, 0), "fly")
    T.ok(not n:blocking())
    T.eq(n:update(0.1), nil)
    T.eq(n:update(0.25), "gone")
  end,

  test_sticky_flick_peels = function()
    local n = sticky.new(0, 0, 200, 100, 0, "stuck")
    n:grab(50, 0)
    T.eq(n:release(25, 900), "fly")
    local m = sticky.new(0, 0, 200, 100, 0, "stuck")
    m:grab(50, 0)
    T.eq(m:release(10, 900), "back") -- too short to count
  end,

  test_sticky_fold_keeps_area = function()
    local poly = { -50, -50, 50, -50, 50, 50, -50, 50 }
    local main, flap = sticky.fold(poly, 50, 50, 50, 10)
    T.ok(flap, "something folded")
    T.ok(near(area(main) + area(flap), area(poly)))
    -- the corner lands where the finger is
    local found = false
    for i = 1, #flap, 2 do
      if near(flap[i], 50) and near(flap[i + 1], 10) then found = true end
    end
    T.ok(found, "corner moved onto the fold point")
  end,

  test_sticky_no_fold = function()
    local poly = { -50, -50, 50, -50, 50, 50, -50, 50 }
    local main, flap = sticky.fold(poly, 50, 50, 50, 50)
    T.eq(main, poly)
    T.eq(flap, nil)
  end,

  test_sticky_left_corner = function()
    local n = sticky.new(0, 0, 200, 100, 0, "stuck")
    n:grab(-50, 0)
    n:drag(30)
    local cx, cy, px, py = n:corner()
    T.eq(cx, -100); T.eq(cy, 50)
    T.ok(px > cx and py < cy)
    local main, flap = n:geometry()
    T.ok(flap ~= nil)
    T.ok(#main >= 6)
  end,
}
