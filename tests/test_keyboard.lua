local keyboard = require("keyboard")

local function go(kb, ...)
  for _, d in ipairs({ ... }) do kb:move(d) end
end

return {
  test_keyboard_edges = function()
    local kb = keyboard.new()
    go(kb, "left", "up")
    local r = kb:press()
    T.eq(r.type, "char"); T.eq(r.char, "a")
    go(kb, "down", "down", "down", "right", "right", "right", "right", "right", "right", "right", "right", "right")
    go(kb, "right")
    T.eq(kb:press().type, "ok")
  end,
  test_keyboard_shift = function()
    local kb = keyboard.new()
    go(kb, "down", "down", "down")
    T.eq(kb:press().type, "shift")
    T.ok(kb.shift)
    go(kb, "up", "up", "up")
    T.eq(kb:press().char, "A")
    T.ok(not kb.shift)
    T.eq(kb:press().char, "a")
  end,
  test_keyboard_rows = function()
    local kb = keyboard.new()
    go(kb, "down", "down")
    go(kb, "right", "right", "right", "right", "right", "right", "right", "right", "right")
    T.eq(kb:press().char, "ç")
    kb:move("down")
    T.eq(kb:press().type, "ok")
    kb:move("up")
    T.eq(kb:press().char, "ç")
  end,
  test_keyboard_space_erase = function()
    local kb = keyboard.new()
    go(kb, "down", "down", "down", "right")
    T.eq(kb:press().type, "space")
    kb:move("right")
    T.eq(kb:press().type, "erase")
  end,
  test_keyboard_accent_shift = function()
    local kb = keyboard.new()
    go(kb, "down", "down", "down", "up", "right", "right", "right", "right", "right", "right", "right", "right", "right")
    go(kb, "down")
    T.eq(kb:press().type, "ok")
    go(kb, "up", "left")
    T.eq(kb:press().char, "à")
  end,
}
