local scroll = require("scroll")

return {
  test_scroll_follow = function()
    T.eq(scroll.follow(0, 0, 40, 160, 400), 0)
    T.eq(scroll.follow(0, 200, 240, 160, 400), 80)
    T.eq(scroll.follow(80, 20, 60, 160, 400), 20)
    T.eq(scroll.follow(0, 360, 400, 160, 400), 240)
    T.eq(scroll.follow(50, 60, 100, 160, 100), 0)
  end,
}
