local ui = require("ui")

return {
  test_ui_mode_from_dimensions = function()
    T.eq(select(3, ui.mode(720, 480)), false)
    T.eq(select(3, ui.mode(390, 844)), true)
    T.eq(select(3, ui.mode(600, 600)), false, "square stays landscape")
    local w, h = ui.mode(1280, 720)
    T.eq(w, 720) T.eq(h, 480)
    w, h = ui.mode(390, 844)
    T.eq(w, 480) T.eq(h, 800)
  end,
  test_ui_set_window_switches_and_reports_change = function()
    T.eq(ui.setWindow(720, 480), true, "first call reports a change")
    T.eq(ui.portrait, false)
    T.eq(ui.setWindow(1440, 960), false)
    T.eq(ui.setWindow(390, 844), true)
    T.eq(ui.portrait, true)
    T.eq(ui.W, 480) T.eq(ui.H, 800)
    ui.setWindow(720, 480)
    T.eq(ui.W, 720) T.eq(ui.H, 480)
  end,
  test_ui_to_logical_portrait = function()
    ui.setWindow(480, 800)
    local x, y = ui.toLogical(240, 400)
    T.eq(x, 240) T.eq(y, 400)
    -- 390x844: scale 390/480, logical screen 650 px tall centred (97 px bars)
    ui.setWindow(390, 844)
    x, y = ui.toLogical(195, 422)
    T.ok(math.abs(x - 240) < 1e-9) T.ok(math.abs(y - 400) < 1e-9)
    x, y = ui.toLogical(0, 97)
    T.ok(math.abs(x) < 1e-9) T.ok(math.abs(y) < 1e-9)
    ui.setWindow(720, 480)
  end,
  test_ui_to_logical_landscape_letterbox = function()
    ui.setWindow(1080, 480) -- 180 px bars left and right
    local x, y = ui.toLogical(180, 0)
    T.eq(x, 0) T.eq(y, 0)
    ui.setWindow(720, 480)
  end,
}
