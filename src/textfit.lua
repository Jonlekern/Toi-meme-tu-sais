-- Pick the largest font size at which a word or phrase fits a box. Pure Lua.
local textfit = {}

-- Split at the space closest to the middle; nil if there is none.
local function split_central(text)
  local best, best_dist
  local mid = #text / 2
  for i = 1, #text do
    if text:sub(i, i) == " " then
      local d = math.abs(i - mid)
      if not best_dist or d < best_dist then best, best_dist = i, d end
    end
  end
  if not best then return nil end
  return { text:sub(1, best - 1), text:sub(best + 1) }
end

local function fits(lines, size, box_w, box_h, measure)
  local total_h = 0
  for _, l in ipairs(lines) do
    local w, h = measure(l, size)
    if w > box_w then return false end
    total_h = total_h + h
  end
  return total_h <= box_h
end

function textfit.fit(text, box_w, box_h, sizes, measure)
  text = text:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
  local two = split_central(text)
  for _, size in ipairs(sizes) do
    if fits({ text }, size, box_w, box_h, measure) then return size, { text } end
    if two and fits(two, size, box_w, box_h, measure) then return size, two end
  end
  return sizes[#sizes], two or { text }
end

return textfit
