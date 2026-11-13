local dual = require("dual")

return {
  test_dual_state_playing = function()
    local s = dual.state({ playing = true, remaining = 41.2, total = 60, paused = false, word = 7, timer = 60 })
    T.eq(s, "playing=1\nremaining=42\ntotal=60\npaused=0\nword=7\ntimer=60\n")
  end,
  test_dual_state_idle = function()
    local s = dual.state({ playing = false, timer = 30 })
    T.eq(s, "playing=0\nremaining=-1\ntotal=0\npaused=0\nword=0\ntimer=30\n")
  end,
  test_dual_state_playing_without_timer = function()
    local s = dual.state({ playing = true, word = 2, timer = 0 })
    T.eq(s, "playing=1\nremaining=-1\ntotal=0\npaused=0\nword=2\ntimer=0\n")
  end,
  test_dual_command = function()
    T.eq(dual.command("pause\n").name, "pause")
    T.eq(dual.command("resume").name, "resume")
    T.eq(dual.command("restart").name, "restart")
    local c = dual.command("timer 90\n")
    T.eq(c.name, "timer")
    T.eq(c.seconds, 90)
    T.eq(dual.command("dual 1").on, true)
    T.eq(dual.command("dual 0").on, false)
  end,
  test_dual_command_rejects_junk = function()
    T.eq(dual.command("timer 45"), nil)
    T.eq(dual.command("timer"), nil)
    T.eq(dual.command(""), nil)
    T.eq(dual.command(nil), nil)
    T.eq(dual.command("rm -rf"), nil)
  end,
}
