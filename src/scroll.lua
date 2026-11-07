-- Vertical scroll offset helper. Pure Lua.
local M = {}

-- Smallest change to `offset` that makes [top, bottom] fit in a view of height view_h
-- (all in content coordinates, offset >= 0, never past content_h - view_h).
function M.follow(offset, top, bottom, view_h, content_h)
  if top < offset then offset = top end
  if bottom > offset + view_h then offset = bottom - view_h end
  local max = math.max(0, content_h - view_h)
  return math.max(0, math.min(max, offset))
end

return M
