-- Word statistics line. Pure Lua.
local stats = {}

-- date is already formatted "YYYY-MM-DD HH:MM".
function stats.line(entry, date)
  return string.format("%s · %s · %s · %s\n", date,
    entry.category_label or "Mélange", entry.word, entry.result)
end

return stats
