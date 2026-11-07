-- LÖVE thread: reads lid events from an evdev device and pushes
-- "open" / "closed" (or "error:...") on the "lid" channel.
require("love.thread")
require("love.filesystem")
love.filesystem.setRequirePath("src/?.lua;" .. love.filesystem.getRequirePath())
local lid = require("lid")

local device = ...
local channel = love.thread.getChannel("lid")
local f = io.open(device, "rb")
if not f then
  channel:push("error:open " .. tostring(device))
  return
end
while true do
  local bytes = f:read(24)
  if not bytes then
    channel:push("error:read " .. device)
    break
  end
  local state = lid.lid_state(lid.decode(bytes))
  if state then channel:push(state) end
end
f:close()
