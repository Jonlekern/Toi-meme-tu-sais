local gesture = require("gesture")

-- Press at (x, y, t0), move through the given points {x, y, t}, release at the last one.
local function run(x, y, t0, points)
  local g = gesture.new()
  g:press(x, y, t0)
  for i = 1, #points - 1 do
    local p = points[i]
    g:move(p[1], p[2], p[3])
  end
  local last = points[#points]
  return g:release(last[1], last[2], last[3])
end

return {
  test_gesture_tap = function()
    local name, info = run(100, 100, 0, { { 103, 102, 0.1 } })
    T.eq(name, "tap")
    T.eq(info.x, 103); T.eq(info.y, 102)
  end,

  test_gesture_swipe_right = function()
    T.eq(run(100, 300, 0, { { 140, 302, 0.1 }, { 180, 305, 0.2 } }), "swipe_right")
  end,

  test_gesture_swipe_left = function()
    T.eq(run(300, 300, 0, { { 260, 298, 0.1 }, { 220, 295, 0.2 } }), "swipe_left")
  end,

  test_gesture_short_horizontal_is_not_swipe = function()
    T.eq(run(100, 300, 0, { { 150, 300, 0.2 } }), "drag_end")
  end,

  test_gesture_slow_horizontal_is_not_swipe = function()
    T.eq(run(100, 300, 0, { { 150, 300, 0.4 }, { 200, 300, 0.8 } }), "drag_end")
  end,

  test_gesture_diagonal_is_not_swipe = function()
    T.eq(run(100, 300, 0, { { 180, 240, 0.2 } }), "drag_end")
  end,

  test_gesture_long_press = function()
    local g = gesture.new()
    g:press(100, 100, 0)
    T.eq(g:update(0.3), nil)
    g:move(105, 104, 0.4) -- inside the slop
    T.eq(g:update(0.5), "long_press")
    T.eq(g:update(0.7), nil) -- once
    T.eq(g:release(105, 104, 1.0), nil) -- no tap after a long press
  end,

  test_gesture_drag_after_long_press = function()
    -- a finger that rests on the note before pulling it must still drag
    local g = gesture.new()
    g:press(100, 100, 0)
    T.eq(g:update(0.6), "long_press")
    local name, info = g:move(100, 60, 0.8)
    T.eq(name, "drag_up")
    T.eq(info.up, 40)
    local name2, info2 = g:release(100, 20, 0.9)
    T.eq(name2, "drag_end")
    T.eq(info2.up, 80)
  end,
  test_gesture_no_swipe_after_long_press = function()
    local g = gesture.new()
    g:press(100, 100, 0)
    g:update(0.6)
    T.eq(g:release(300, 100, 0.7), "drag_end")
  end,
  test_gesture_long_press_needs_stillness = function()
    local g = gesture.new()
    g:press(100, 100, 0)
    g:move(100, 80, 0.2)
    T.eq(g:update(0.8), nil)
  end,

  test_gesture_long_press_without_update = function()
    local g = gesture.new()
    g:press(100, 100, 0)
    T.eq(g:release(100, 100, 0.7), "long_press")
  end,

  test_gesture_drag_up_progress_and_side = function()
    local g = gesture.new()
    g:press(300, 400, 0, 240)
    T.eq(g:move(302, 395, 0.05), nil) -- still in the slop
    local name, info = g:move(305, 340, 0.1)
    T.eq(name, "drag_up")
    T.eq(info.up, 60)
    T.eq(info.side, "right")
    local _, down = g:move(305, 420, 0.2)
    T.eq(down.up, 0) -- never negative

    local h = gesture.new()
    h:press(100, 400, 0, 240)
    local _, left = h:move(100, 300, 0.1)
    T.eq(left.side, "left")
  end,

  test_gesture_drag_end_speed = function()
    local g = gesture.new()
    g:press(200, 400, 0)
    g:move(200, 380, 0.02)
    g:move(200, 300, 0.12)
    local name, info = g:release(200, 250, 0.15)
    T.eq(name, "drag_end")
    T.eq(info.up, 150)
    T.ok(info.vy > 800, "fast upward flick")
  end,

  test_gesture_release_without_press = function()
    local g = gesture.new()
    T.eq(g:release(1, 1, 1), nil)
    T.eq(g:move(1, 1, 1), nil)
    T.eq(g:update(5), nil)
  end,

  test_gesture_cancel = function()
    local g = gesture.new()
    g:press(1, 1, 0)
    g:cancel()
    T.eq(g:update(2), nil)
    T.eq(g:release(1, 1, 2), nil)
  end,
}
