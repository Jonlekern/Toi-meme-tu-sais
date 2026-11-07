-- Pick the largest font size at which a word or phrase fits a box. Pure Lua.
-- Tries 1, 2 or 3 lines broken at spaces; a word too long for any of those is
-- broken between characters as a last resort, so the text never leaves the box.
local textfit = {}

local function words_of(text)
  local out = {}
  for w in text:gmatch("[^ ]+") do out[#out + 1] = w end
  return out
end

local function join(ws, a, b) return table.concat(ws, " ", a, b) end

local function widest(lines, size, measure)
  local m = 0
  for _, l in ipairs(lines) do m = math.max(m, (measure(l, size))) end
  return m
end

-- Line breakings of the words into n lines (n = 1..3), keeping the most balanced one
-- (smallest widest line) at this size; nil when there are fewer than n words.
local function best_split(ws, n, size, measure)
  local k = #ws
  if k < n then return nil end
  if n == 1 then return { join(ws, 1, k) } end
  local best, best_w
  local function try(lines)
    local w = widest(lines, size, measure)
    if not best_w or w < best_w then best, best_w = lines, w end
  end
  if n == 2 then
    for i = 1, k - 1 do try({ join(ws, 1, i), join(ws, i + 1, k) }) end
  else
    for i = 1, k - 2 do
      for j = i + 1, k - 1 do try({ join(ws, 1, i), join(ws, i + 1, j), join(ws, j + 1, k) }) end
    end
  end
  return best
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

-- Greedy break between UTF-8 characters (spaces kept as break points too).
local function char_break(text, size, box_w, measure)
  local lines, cur = {}, ""
  for ch in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    local next_line = cur .. ch
    if cur ~= "" and measure(next_line, size) > box_w then
      lines[#lines + 1] = (cur:gsub(" $", ""))
      cur = ch == " " and "" or ch
    else
      cur = next_line
    end
  end
  if cur ~= "" then lines[#lines + 1] = cur end
  return lines
end

function textfit.fit(text, box_w, box_h, sizes, measure)
  text = text:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
  local ws = words_of(text)
  for _, size in ipairs(sizes) do
    for n = 1, 3 do
      local lines = best_split(ws, n, size, measure)
      if lines and fits(lines, size, box_w, box_h, measure) then return size, lines end
    end
  end
  for _, size in ipairs(sizes) do
    local lines = char_break(text, size, box_w, measure)
    if fits(lines, size, box_w, box_h, measure) then return size, lines end
  end
  local last = sizes[#sizes]
  return last, char_break(text, last, box_w, measure)
end

return textfit
