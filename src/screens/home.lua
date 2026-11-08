-- Home: choose categories and timer, then play.
local ui = require("ui")
local scroll = require("scroll")

local home = {}

local TIMERS = { 0, 30, 60, 90 }
local PAD, GAP, ROW_H = 20, 12, 40

-- Screen geometry for the current layout mode (ui.portrait), shared by drawing and hit tests.
-- BTN = "Jouer"; CATS = "Mes catégories" button (touch-only in landscape, always in portrait);
-- AREA = scrolling pills area; HELP = "?" circle, top-right.
local function geom(app)
  local g = {}
  if ui.portrait then
    g.title_y = 76
    g.AREA = { x = 0, y = 196, w = ui.W, h = 236 }
    g.chrono_label_y = 456
    g.chrono_y = 490
    g.CATS = { x = 30, y = 572, w = ui.W - 60, h = 54 }
    g.BTN = { x = 30, y = 646, w = ui.W - 60, h = 62 }
    g.HELP = { cx = ui.W - 30 - 15, cy = 40, r = 15, hit = 64, corner = 130 } -- big touch target
  else
    g.title_y = 24
    g.AREA = { x = 0, y = 142, w = ui.W, h = 164 }
    g.chrono_y = 330
    -- "Jouer" fitted to its label, right edge at 690
    local bw = app.fonts.button:getWidth("Jouer") + 48
    g.BTN = { x = 690 - bw, y = 400, w = bw, h = 54 }
    g.CATS = { x = 30, y = 424, w = app.fonts.hint:getWidth("Mes catégories") + 32, h = 40 }
    g.HELP = { cx = ui.W - 30 - 11, cy = 35, r = 11, hit = 50, corner = 110 } -- big touch target
  end
  g.top = g.AREA.y + 8 -- first pill row
  return g
end

-- The "Mes catégories" button is always there in portrait, after a touch in landscape.
local function cats_button(app) return ui.portrait or app.touched end

-- Pill rectangles, computed from the fonts so draw and navigation agree.
local function pills(app, g)
  local font, out = app.fonts.ui, {}
  local x, y = 30, g.top
  for i, cat in ipairs(app.lists.categories) do
    local w = math.min(font:getWidth(cat.label) + PAD * 2, ui.W - 60)
    if x + w > ui.W - 30 and x > 30 then x, y = 30, y + ROW_H + GAP end
    out[i] = { x = x, y = y, w = w, h = ROW_H, cat = cat }
    x = x + w + GAP
  end
  return out, y + ROW_H
end

-- Keep the focused pill inside the area; returns the current offset.
local function follow(app, g, list, bottom)
  local off = app.pill_scroll or 0
  local p = list[app.focus]
  local top = g.top
  if p then
    off = scroll.follow(off, p.y - top - 6, p.y - top + p.h + 6, g.AREA.h - 8, bottom - top)
  else -- keep the offset, only clamped (the area height changes with the orientation)
    off = math.max(0, math.min(off, bottom - top - (g.AREA.h - 8)))
  end
  app.pill_scroll = off
  return off
end

-- Timer line layout: parts with x positions; value parts carry their timer.
-- Landscape: "Chrono : aucun · 30 · 60 · 90 s" on one line; portrait: the values only
-- (the "Chrono" label is drawn above them).
local function chrono_layout(app, g)
  local font, y = app.fonts.ui, g.chrono_y
  local x = 30
  local parts = {}
  if not ui.portrait then parts[1] = { text = "Chrono : ", color = "text" } end
  for i, t in ipairs(TIMERS) do
    parts[#parts + 1] = { text = t == 0 and "aucun" or tostring(t), timer = t,
      color = app.settings.timer == t and "pink" or "grey" }
    if i < #TIMERS then parts[#parts + 1] = { text = " · ", color = "grey" } end
  end
  parts[#parts + 1] = { text = " s", color = "grey" }
  local total = 0
  for _, p in ipairs(parts) do
    p.x, p.w = x + total, font:getWidth(p.text)
    total = total + p.w
  end
  return parts, x, y, total
end

local function inside(r, x, y)
  return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

function home.enter(app)
  app.focus = app.focus or 1
end

local function cycle(app, dir)
  local cur = 1
  for i, t in ipairs(TIMERS) do if t == app.settings.timer then cur = i end end
  cur = math.max(1, math.min(#TIMERS, cur + dir))
  if TIMERS[cur] ~= app.settings.timer then
    app.settings.timer = TIMERS[cur]
    app.save()
  end
end

function home.action(app, name, x, y)
  local g = geom(app)
  local list = pills(app, g)
  local AREA, BTN, CATS, HELP = g.AREA, g.BTN, g.CATS, g.HELP
  local n = #list
  local chrono, jouer = n + 1, n + 2
  -- the pill count can change (custom categories): keep the focus on something that exists
  app.focus = math.max(1, math.min(jouer, app.focus or 1))
  local f = app.focus
  if name == "rules" then
    return app.switch("rules")
  elseif name == "mycats" then
    return app.switch("mycats")
  elseif name == "tap" then
    if cats_button(app) and inside(CATS, x, y) then return app.switch("mycats") end
    -- "?": its circle, or anywhere in the top-right corner (easy with a thumb)
    local dx, dy = x - HELP.cx, y - HELP.cy
    if dx * dx + dy * dy <= HELP.hit * HELP.hit then return app.switch("rules") end
    if x >= ui.W - HELP.corner and y <= HELP.cy + HELP.hit then return app.switch("rules") end
    local off = app.pill_scroll or 0
    for i, p in ipairs(list) do
      if y >= AREA.y and y <= AREA.y + AREA.h and inside({ x = p.x, y = p.y - off, w = p.w, h = p.h }, x, y) then
        app.focus = i
        return home.action(app, "select")
      end
    end
    local parts, _, cy = chrono_layout(app, g)
    local fh = app.fonts.ui:getHeight()
    for _, p in ipairs(parts) do
      if p.timer and inside({ x = p.x, y = cy - 6, w = p.w, h = fh + 12 }, x, y) then
        app.focus = chrono
        if app.settings.timer ~= p.timer then
          app.settings.timer = p.timer
          app.save()
        end
        return
      end
    end
    if inside(BTN, x, y) then
      app.focus = jouer
      return home.action(app, "select")
    end
  elseif name == "select" then
    if f <= n then
      local id = list[f].cat.id
      app.settings.categories[id] = not app.settings.categories[id] or nil
      app.save()
    elseif f == jouer then
      app.startRound()
    end
  elseif name == "left" or name == "right" then
    local dir = name == "left" and -1 or 1
    if f <= n then
      app.focus = math.max(1, math.min(n, f + dir))
    elseif f == chrono then
      cycle(app, dir)
    end
  elseif name == "down" or name == "up" then
    local dir = name == "down" and 1 or -1
    if f <= n then
      -- nearest pill on the next row, else leave the pills
      local cur, best, bd = list[f], nil, math.huge
      for i, p in ipairs(list) do
        if (p.y - cur.y) * dir > 0 then
          local d = math.abs(p.y - cur.y) * 1000 + math.abs(p.x - cur.x)
          if d < bd then best, bd = i, d end
        end
      end
      if best then app.focus = best elseif dir > 0 then app.focus = chrono end
    elseif f == chrono then
      if dir > 0 then app.focus = jouer elseif n > 0 then app.focus = n end
    else
      app.focus = dir > 0 and jouer or chrono
    end
  end
end

local function fit(font, text, w)
  if font:getWidth(text) <= w then return text end
  while #text > 1 and font:getWidth(text .. "…") > w do
    text = text:gsub("[%z\1-\127\194-\244][\128-\191]*$", "")
  end
  return text .. "…"
end

function home.draw(app)
  local g = geom(app)
  local AREA, BTN, CATS, HELP = g.AREA, g.BTN, g.CATS, g.HELP
  local list, bottom = pills(app, g)
  local n = #list
  app.focus = math.max(1, math.min(n + 2, app.focus or 1))
  ui.print("Toi-même", app.fonts.title, 30, g.title_y)
  ui.print("tu sais", app.fonts.title, 30, g.title_y + 46, "pink")

  local off = follow(app, g, list, bottom)
  ui.clip(AREA.x, AREA.y, AREA.w, AREA.h)
  for i, p in ipairs(list) do
    local on, py = app.settings.categories[p.cat.id], p.y - off
    ui.box(p.x, py, p.w, p.h, on and "pink" or nil, (not on) and "outline" or nil, app.focus == i)
    ui.printc(fit(app.fonts.ui, p.cat.label, p.w - 16), app.fonts.ui, p.x,
      py + (p.h - app.fonts.ui:getHeight()) / 2, p.w, on and "bg" or "grey")
  end
  ui.unclip()
  ui.set("grey")
  local at, ab = AREA.y, AREA.y + AREA.h
  if off > 0 then
    love.graphics.polygon("fill", ui.W - 14, at - 14, ui.W - 8, at - 4, ui.W - 20, at - 4)
  end
  if off < bottom - g.top - (AREA.h - 8) then
    love.graphics.polygon("fill", ui.W - 14, ab + 10, ui.W - 8, ab, ui.W - 20, ab)
  end

  -- Timer: "Chrono : aucun · 30 · 60 · 90 s" (portrait: "Chrono" above the values)
  local font = app.fonts.ui
  local parts, x, y, total = chrono_layout(app, g)
  if ui.portrait then ui.print("Chrono", font, 30, g.chrono_label_y, "text") end
  if app.focus == n + 1 then
    ui.box(x - 12, y - 6, total + 24, font:getHeight() + 12, nil, nil, true)
  end
  for _, p in ipairs(parts) do ui.print(p.text, font, p.x, y, p.color) end

  -- "?" opens the rules
  ui.set("pink")
  love.graphics.setLineWidth(ui.portrait and 2 or 1.5)
  love.graphics.circle("line", HELP.cx, HELP.cy, HELP.r)
  local qf = ui.portrait and app.fonts.ui or app.fonts.small
  ui.printc("?", qf, HELP.cx - HELP.r, HELP.cy - qf:getHeight() / 2, HELP.r * 2, "pink")

  if ui.portrait then
    ui.box(CATS.x, CATS.y, CATS.w, CATS.h, nil, "outline")
    ui.printc("Mes catégories", app.fonts.button, CATS.x,
      CATS.y + (CATS.h - app.fonts.button:getHeight()) / 2, CATS.w, "grey")
  elseif app.touched then
    ui.box(CATS.x, CATS.y, CATS.w, CATS.h, nil, "outline")
    ui.printc("Mes catégories", app.fonts.hint, CATS.x,
      CATS.y + (CATS.h - app.fonts.hint:getHeight()) / 2, CATS.w, "grey")
  else
    local hf, room = app.fonts.hint, BTN.x - 30 - 20
    local hint = "SELECT : règles · Y : mes catégories"
    if hf:getWidth(hint) > room then hint = "SELECT : règles · Y : catégories" end
    if not app.console then hint = "? : règles · C : catégories" end
    ui.print(hint, hf, 30, BTN.y + (BTN.h - hf:getHeight()) / 2, "grey")
  end

  ui.button("Jouer", app.fonts.button, BTN.x, BTN.y, BTN.w, BTN.h, app.focus == n + 2)
end

return home
