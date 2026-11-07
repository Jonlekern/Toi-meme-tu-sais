-- Scrolling list used by the category editor screens (drawing + hit tests).
local ui = require("ui")

local lv = {}

local ROW, STEP = 44, 50
local X, TOP = 30, 96

-- Full-width rows; as many visible rows as fit above the hint line
-- (6 on the 720x480 screen, 12 on the 480x800 one, where the title gets its own line).
local function sync()
  if ui.portrait then X, TOP = 16, 132 else X, TOP = 30, 96 end
end
local function width() return ui.W - 2 * X end
local function vis() return math.floor((ui.H - 60 - TOP + STEP - ROW) / STEP) end
local BACK = { x = 10, y = 10, w = 100, h = 44 }

local function hit(r, x, y)
  return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

function lv.new() return { sel = 1, scroll = 0 } end

function lv.clamp(st, n)
  sync()
  local VIS = vis()
  st.sel = math.max(1, math.min(n, st.sel))
  if st.sel <= st.scroll then st.scroll = st.sel - 1 end
  if st.sel > st.scroll + VIS then st.scroll = st.sel - VIS end
  st.scroll = math.max(0, math.min(math.max(0, n - VIS), st.scroll))
end

-- Handles up/down; returns true when the name was a navigation action.
function lv.nav(st, name, n)
  if name ~= "up" and name ~= "down" then return false end
  st.sel = st.sel + (name == "down" and 1 or -1)
  lv.clamp(st, n)
  return true
end

function lv.row_at(st, x, y, n)
  sync()
  local W, VIS = width(), vis()
  if x < X or x > X + W or y < TOP then return nil end
  local i = math.floor((y - TOP) / STEP) + 1
  if i > VIS or (y - TOP) - (i - 1) * STEP > ROW then return nil end
  local idx = st.scroll + i
  return idx <= n and idx or nil
end

local function del_rect(st)
  sync()
  local W = width()
  return { x = X + W - 168, y = TOP + (st.sel - st.scroll - 1) * STEP + 4, w = 160, h = ROW - 8 }
end

function lv.del_hit(st, x, y) return hit(del_rect(st), x, y) end
function lv.back_hit(x, y) return hit(BACK, x, y) end

local function fit(font, text, w)
  if font:getWidth(text) <= w then return text end
  while #text > 1 and font:getWidth(text .. "…") > w do
    text = text:gsub("[%z\1-\127\194-\244][\128-\191]*$", "")
  end
  return text .. "…"
end

-- items: { {left, right, accent, add} }; hint: string or list of variants; deletable(idx) says whether the touch delete button applies.
function lv.draw(app, title, items, st, hint, deletable)
  lv.clamp(st, #items) -- the visible row count changes with the screen orientation
  local f, W, VIS = app.fonts.ui, width(), vis()
  local tx = 30
  if app.touched then
    local hf = app.fonts.hint
    ui.print("‹ Retour", hf, BACK.x + 10, 24 + (app.fonts.title:getHeight() - hf:getHeight()) / 2, "grey")
    tx = BACK.x + 10 + hf:getWidth("‹ Retour") + 20
  end
  local ty = 24
  if ui.portrait then -- the title gets its own line under "‹ Retour"
    tx, ty = 30, app.touched and 66 or 24
  end
  local tf = app.fonts.title
  if tf:getWidth(title) > ui.W - tx - 30 then tf = app.fonts.head end
  if ui.portrait and tf:getWidth(title) > ui.W - tx - 30 then tf = app.fonts.button end
  ui.print(fit(tf, title, ui.W - tx - 30), tf, tx, ty, "pink")

  for i = 1, VIS do
    local idx, it = st.scroll + i, items[st.scroll + i]
    if not it then break end
    local y, on = TOP + (i - 1) * STEP, st.scroll + i == st.sel
    if on then
      ui.set("pink")
      love.graphics.rectangle("fill", X, y, W, ROW, 12, 12)
    end
    local fy = y + (ROW - f:getHeight()) / 2
    local right = it.right
    local rw = right and f:getWidth(right) or 0
    local btn = on and app.touched and deletable and deletable(idx)
    if btn then
      local r = del_rect(st)
      ui.box(r.x, r.y, r.w, r.h, nil, "bg")
      ui.printc("Supprimer", app.fonts.hint, r.x, r.y + (r.h - app.fonts.hint:getHeight()) / 2, r.w, "bg")
    elseif right then
      ui.print(right, f, X + W - 16 - rw, fy, on and "bg" or "grey")
    end
    local room = W - 32 - (btn and 178 or rw + 16)
    local col = on and "bg" or (it.accent and "pink" or "text")
    local left, lx = it.left, X + 16
    if it.add then -- the font's "+" glyph is tiny: draw it as lines
      local s, cx, cy = f:getHeight() * 0.5, lx + f:getHeight() * 0.3, y + ROW / 2
      ui.set(col)
      love.graphics.setLineWidth(2.5)
      love.graphics.line(cx - s / 2, cy, cx + s / 2, cy)
      love.graphics.line(cx, cy - s / 2, cx, cy + s / 2)
      lx, room = lx + f:getHeight() * 1.1, room - f:getHeight() * 1.1
    end
    local lf = f
    if ui.portrait and f:getWidth(left) > room then -- narrow screen: smaller text before cutting it
      lf = app.fonts.small
    end
    ui.print(fit(lf, left, room), lf, lx, y + (ROW - lf:getHeight()) / 2, col)
  end

  ui.set("grey")
  if st.scroll > 0 then
    love.graphics.polygon("fill", ui.W - 14, TOP - 24, ui.W - 8, TOP - 14, ui.W - 20, TOP - 14)
  end
  if st.scroll + VIS < #items then
    local by = ui.H - 50
    love.graphics.polygon("fill", ui.W - 14, by, ui.W - 8, by - 10, ui.W - 20, by - 10)
  end
  if hint and not app.touched then
    -- one line only: hint is a string or a list of variants, longest first;
    -- the first variant that fits wins, in the normal font, else the smaller one
    local variants = type(hint) == "table" and hint or { hint }
    local text, hf = variants[#variants], app.fonts.hint
    for _, v in ipairs(variants) do
      if app.fonts.small:getWidth(v) <= ui.W - 40 then text, hf = v, app.fonts.small break end
      if app.fonts.hint:getWidth(v) <= ui.W - 40 then text, hf = v, app.fonts.hint break end
    end
    ui.printc(text, hf, 0, ui.H - 44 + (app.fonts.small:getHeight() - hf:getHeight()) / 2, ui.W, "grey")
  end
end

return lv
