local seen = require("seen")

return {
  test_seen_roundtrip_accents = function()
    local s = seen.new()
    s:mark("éléphant")
    s:mark("Où ça ?")
    local back = seen.parse(s:serialize())
    T.ok(back:has("éléphant"))
    T.ok(back:has("Où ça ?"))
    T.ok(not back:has("zèbre"))
  end,

  test_seen_damaged_lines_ignored = function()
    local s = seen.parse("a\n\n   \nb\0c\r\nd\r\n")
    T.ok(s:has("a"))
    T.ok(s:has("d"))
    T.ok(not s:has("b\0c"))
    T.ok(not s:has(""))
    T.ok(not seen.parse(nil):has("a"))
    T.ok(not seen.parse(42):has("a"))
  end,

  test_seen_reset = function()
    local s = seen.new()
    s:mark("a") s:mark("b")
    s:reset({ "a" })
    T.ok(not s:has("a"))
    T.ok(s:has("b"))
  end,
}
