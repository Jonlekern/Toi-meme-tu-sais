local stats = require("stats")

return {
  test_stats_line = function()
    local e = { word = "Suçon", category_label = "Soirée", result = "passé" }
    T.eq(stats.line(e, "2026-11-08 23:14"), "2026-11-08 23:14 · Soirée · Suçon · passé\n")
    e.category_label = nil
    T.eq(stats.line(e, "2026-11-08 23:14"), "2026-11-08 23:14 · Mélange · Suçon · passé\n")
  end,
}
