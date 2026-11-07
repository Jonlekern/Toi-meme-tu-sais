local input = require("input")

return {
  test_input_keys = function()
    local i = input.new()
    T.eq(i:key("return"), "select")
    T.eq(i:key("space"), "select")
    T.eq(i:key("escape"), "back")
    T.eq(i:key("up"), "up")
    T.eq(i:key("right"), "right")
    T.eq(i:key("p"), "skip")
    T.eq(i:key("c"), "mycats")
    T.eq(i:key("?"), nil)
    T.eq(i:text("?"), "rules")
    T.eq(i:text("a"), nil)
    T.eq(i:key("backspace"), "erase")
    T.eq(i:key("z"), nil)
  end,

  test_input_pad = function()
    local i = input.new()
    T.eq(i:button("a"), "select")
    T.eq(i:button("b"), "back")
    T.eq(i:button("dpdown"), "down")
    T.eq(i:button("dpup"), "up")
    T.eq(i:button("dpleft"), "left")
    T.eq(i:button("dpright"), "right")
    T.eq(i:button("x"), "skip")
    T.eq(i:button("y"), "mycats")
    T.eq(i:button("back"), "rules")
    T.eq(i:button("start"), "ok")
    T.eq(i:button("guide"), nil)
  end,

  test_input_touch_no_double = function()
    local i = input.new()
    local a, x, y = i:touch(10, 20, 5.00)
    T.eq(a, "tap"); T.eq(x, 10); T.eq(y, 20)
    T.eq(i:mouse(10, 10, 1, true, 5.01), nil)
    T.eq(i:mouse(10, 10, 1, false, 6), "tap")
  end,

  test_input_mouse_button = function()
    local i = input.new()
    T.eq(i:mouse(1, 2, 2, false, 1), nil)
    local a, x, y = i:mouse(3, 4, 1, false, 1)
    T.eq(a, "tap"); T.eq(x, 3); T.eq(y, 4)
    T.eq(i:mouse(3, 4, 1, true, 10), "tap") -- no recent touch
  end,
}
