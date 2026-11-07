local lid = require("lid")

local DEVICES = [[
I: Bus=0019 Vendor=0001 Product=0001 Version=0100
N: Name="gamepad"
P: Phys=
S: Sysfs=/devices/platform/gamepad/input/input1
H: Handlers=js0 event2
B: PROP=0
B: EV=1b
B: KEY=ffff0000 0 0 0 0 0 0 0 0

I: Bus=0019 Vendor=0000 Product=0005 Version=0000
N: Name="gpio-keys-lid"
P: Phys=gpio-keys/input0
S: Sysfs=/devices/platform/gpio-keys-lid/input/input2
H: Handlers=event3
B: PROP=0
B: EV=21
B: SW=1

I: Bus=0019 Vendor=0000 Product=0001 Version=0000
N: Name="rk805 pwrkey"
P: Phys=rk805-pwrkey/input0
S: Sysfs=/devices/platform/pwrkey/input/input3
H: Handlers=kbd event4
B: PROP=0
B: EV=3
B: KEY=10000000000000 0
]]

local function event(t, c, v)
  local function u16(n) return string.char(n % 256, math.floor(n / 256) % 256) end
  local function s32(n)
    if n < 0 then n = n + 2 ^ 32 end
    return u16(n % 65536) .. u16(math.floor(n / 65536))
  end
  return string.rep("\0", 16) .. u16(t) .. u16(c) .. s32(v)
end

return {
  test_lid_find_device = function()
    T.eq(lid.find_device(DEVICES), "/dev/input/event3")
    T.eq(lid.find_device(DEVICES:gsub("B: SW=1\n", "")), nil)
    T.eq(lid.find_device(nil), nil)
  end,
  test_lid_decode = function()
    local ev = lid.decode(event(5, 0, 1))
    T.eq(ev.type, 5); T.eq(ev.code, 0); T.eq(ev.value, 1)
    T.eq(lid.decode(string.rep("\0", 10)), nil)
    T.eq(lid.decode(event(5, 0, -1)).value, -1)
  end,
  test_lid_state = function()
    T.eq(lid.lid_state(lid.decode(event(5, 0, 1))), "closed")
    T.eq(lid.lid_state(lid.decode(event(5, 0, 0))), "open")
    T.eq(lid.lid_state(lid.decode(event(1, 30, 1))), nil)
  end,
  test_lid_tracker_bounces = function()
    local t = lid.tracker()
    T.eq(t:feed("open"), nil)
    T.eq(t:feed("closed"), nil)
    T.eq(t:feed("closed"), nil)
    T.eq(t:feed("open"), true)
    T.eq(t:feed("open"), nil)
  end,
}
