-- AYN Thor bottom screen: the Android side shows the timer there and talks to
-- the game through small files in the save directory. Pure Lua.
--   thor/state.txt   written by the game: what the bottom screen shows
--   thor/cmd-*.txt   written by Android, one command each, read then removed
--                    ("lid": the lid was closed then reopened, or the screen woke up)
local dual = {}

dual.DIR = "thor"
dual.STATE = "thor/state.txt"

local TIMERS = { [0] = true, [30] = true, [60] = true, [90] = true }

-- s = { playing, remaining (seconds or nil), total, paused, word (number), timer (setting) }
function dual.state(s)
  local rem = s.playing and s.remaining and math.ceil(s.remaining) or -1
  return table.concat({
    "playing=" .. (s.playing and 1 or 0),
    "remaining=" .. rem,
    "total=" .. ((s.playing and s.remaining and s.total) or 0),
    "paused=" .. (s.paused and 1 or 0),
    "word=" .. (s.playing and s.word or 0),
    "timer=" .. (s.timer or 0),
  }, "\n") .. "\n"
end

-- One command file's text -> { name = ..., seconds = n | on = bool }, or nil.
function dual.command(text)
  if type(text) ~= "string" then return nil end
  local name, arg = text:match("^%s*(%a+)%s*(%d*)%s*$")
  if name == "pause" or name == "resume" or name == "restart" or name == "lid" then return { name = name } end
  if name == "timer" then
    local n = tonumber(arg)
    if n and TIMERS[n] then return { name = name, seconds = n } end
  elseif name == "dual" and (arg == "0" or arg == "1") then
    return { name = name, on = arg == "1" }
  end
  return nil
end

return dual
