-- Play: one big word, optional countdown.
local ui = require("ui")
local textfit = require("textfit")
local sticky = require("sticky")

local play = {}

local SIZES = { 120, 96, 72, 56, 40, 32, 26, 22 }

local function hit(r, x, y)
  return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

function play.enter(app)
  app.round:next()
  app.fit = nil
  app.note, app.swipe_dx = nil, nil
end

-- Leaving the screen (back, time up) removes the sticky note.
function play.leave(app)
  app.note, app.swipe_dx = nil, nil
end

-- A sticky note on the word (web) keeps it from changing until peeled off.
local function locked(app)
  return app.note ~= nil and app.note:blocking()
end

function play.update(app, dt)
  if app.note and app.note:update(dt) == "gone" then app.note = nil end
  if app.round:update(dt) == "timeup" then
    app.round:finish()
    app.switch("timeup")
  end
end

-- Geometry for the current layout mode, shared by drawing and hit tests:
-- BOX = word area, BACK = "‹ Retour" (top-left). There is no "Passer" button: on the web
-- skipping is the same as next (swipe right), on the console X skips. Landscape: "‹ Retour"
-- is fitted to its text (same placement as the editor lists' back button), after a touch only.
local function layout(app)
  local g = {}
  if ui.portrait then
    local bf = app.fonts.small
    g.back_font = bf
    g.BACK = { x = 10, y = 14, w = 10 + bf:getWidth("‹ Retour") + 10, h = 48 }
    g.top_y = 24 -- "‹ Retour" and timer line
    g.BOX = { x = 20, y = 120, w = ui.W - 40, h = 430 }
  else
    g.back_font = app.fonts.hint
    g.BACK = { x = 10, y = 10, w = 10 + app.fonts.hint:getWidth("‹ Retour") + 10, h = 44 }
    g.top_y = 24
    g.BOX = { x = 20, y = 90, w = 680, h = 300 }
  end
  return g
end

-- Back button: always in portrait, after a touch in landscape.
local function buttons(app) return ui.portrait or app.touched end

function play.action(app, name, x, y)
  local g = layout(app)
  if name == "tap" then
    if buttons(app) and hit(g.BACK, x, y) then return play.action(app, "back") end
    return play.action(app, "select")
  elseif locked(app) then
    if name == "back" then return play.action_back(app) end
  elseif name == "skip" then
    app.round:skip()
    app.fit = nil
  elseif name == "select" then
    app.round:next()
    app.fit = nil
  elseif name == "previous" then
    app.round:previous()
    app.fit = nil
  elseif name == "back" then
    play.action_back(app)
  end
end

function play.action_back(app)
  app.round:finish()
  app.switch("home")
end

-- Word layout in BOX (cached in app.fit): font size and lines.
local function word_fit(app, BOX)
  local word = app.round.word
  if not app.fit or app.fit.word ~= word or app.fit.w ~= BOX.w or app.fit.h ~= BOX.h then
    local size, lines = textfit.fit(word, BOX.w, BOX.h, SIZES, function(text, s)
      local f = app.fonts.word(s)
      return f:getWidth(text), f:getHeight()
    end)
    app.fit = { word = word, w = BOX.w, h = BOX.h, size = size, lines = lines }
  end
  return app.fit
end

-- Sticky note sized to cover the word, slightly turned.
local function new_note(app, state)
  local g = layout(app)
  local BOX = g.BOX
  local fit = word_fit(app, BOX)
  local f = app.fonts.word(fit.size)
  local ww = 0
  for _, line in ipairs(fit.lines) do ww = math.max(ww, f:getWidth(line)) end
  local wh = f:getHeight() * #fit.lines
  local w = math.min(math.max(ww + 60, 320), BOX.w - 10)
  local h = ui.portrait and math.min(math.max(wh + 60, w * 0.62), BOX.h)
    or math.min(math.max(wh + 20, w * 0.45), BOX.h - 10) -- clear of the hint below
  local rot = (love.math.random() < 0.5 and -1 or 1) * (0.02 + 0.025 * love.math.random())
  local n = sticky.new(BOX.x + BOX.w / 2, BOX.y + BOX.h / 2, w, h, rot, state)
  n.portrait = ui.portrait
  return n
end

-- Gestures (web only, see main.lua): swipes change the word, a long press drops
-- the sticky note, dragging up peels it off.
function play.gesture(app, name, info)
  local note = app.note
  if name == "long_press" then
    local g = layout(app)
    if note or not app.round.word then return end
    if buttons(app) and hit(g.BACK, info.x, info.y) then return end
    app.note = new_note(app, "drop")
  elseif name == "drag_up" then
    if note then
      if note.state ~= "peel" then note:grab(info.x0, info.y0) end
      note:drag(info.up)
    elseif math.abs(info.dx) > math.abs(info.dy) then
      app.swipe_dx = info.dx
    else
      app.swipe_dx = nil
    end
  else -- the finger left: swipe_right, swipe_left, drag_end
    app.swipe_dx = nil
    if note then
      if note.state == "peel" then note:release(info.up, name == "drag_end" and info.vy or 0) end
      return
    end
    if name == "swipe_right" then play.action(app, "select")
    elseif name == "swipe_left" then play.action(app, "previous") end
  end
end

local function fmt(sec)
  sec = math.ceil(sec)
  return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

function play.draw(app)
  local g = layout(app)
  local BOX, BACK = g.BOX, g.BACK
  local r = app.round
  local uf = app.fonts.ui
  if ui.portrait then
    local bf = g.back_font
    ui.print("‹ Retour", bf, BACK.x + 10, g.top_y + (uf:getHeight() - bf:getHeight()) / 2, "grey")
    if r.category then ui.printc(r.category.label, app.fonts.small, 0, 74, ui.W, "grey") end
  else
    local labelX = 30
    if app.touched then
      local hf = app.fonts.hint
      ui.print("‹ Retour", hf, BACK.x + 10, 24 + (uf:getHeight() - hf:getHeight()) / 2, "grey")
      labelX = BACK.x + 10 + hf:getWidth("‹ Retour") + 20
    end
    if r.category then ui.print(r.category.label, uf, labelX, 24, "grey") end
  end
  if r.remaining then
    local text = fmt(r.remaining)
    ui.print(text, uf, ui.W - 30 - uf:getWidth(text), g.top_y, "pink")
  end

  if r.word then
    local fit = word_fit(app, BOX)
    local f = app.fonts.word(fit.size)
    local lh = f:getHeight()
    local y = BOX.y + (BOX.h - lh * #fit.lines) / 2
    -- a horizontal drag nudges the word and shows where it goes
    local sx = app.swipe_dx and math.max(-50, math.min(50, app.swipe_dx * 0.35)) or 0
    for _, line in ipairs(fit.lines) do
      ui.printc(line, f, BOX.x + sx, y, BOX.w, "text")
      y = y + lh
    end
    if app.swipe_dx and (app.swipe_dx > 0 or r.pos > 1) then
      local a = math.min(math.abs(app.swipe_dx) / 60, 1)
      local cf = app.fonts.title
      -- above the word, at the side it goes (as on the mockup)
      local cy = math.max(BOX.y + (BOX.h - lh * #fit.lines) / 2 - cf:getHeight() - 6,
        ui.portrait and 98 or 56) -- below the category / back line
      local c = ui.color.pink
      love.graphics.setColor(c[1], c[2], c[3], a)
      love.graphics.setFont(cf)
      if app.swipe_dx > 0 then
        love.graphics.print("›", BOX.x + BOX.w - cf:getWidth("›"), cy)
      else
        love.graphics.print("‹", BOX.x, cy)
      end
    end
  else
    ui.printc("Aucun mot", app.fonts.word(56), BOX.x, BOX.y + BOX.h / 2 - 40, BOX.w, "grey")
  end

  if app.note then
    if app.note.portrait ~= ui.portrait then app.note = new_note(app, "stuck") end
    app.note:draw(app.fonts.note)
  end

  -- web hints: swipes, or how to peel the note off
  local gesture_hint
  if not app.console then
    if locked(app) then gesture_hint = "Glisse vers le haut pour décoller"
    elseif app.touched then
      gesture_hint = ui.portrait and "Glisse › mot suivant\n‹ mot précédent" or "Glisse › suivant · ‹ précédent"
    end
  end
  if ui.portrait then
    ui.printc(gesture_hint or "Touche : mot suivant", app.fonts.small, 0, 650, ui.W, "grey")
  elseif app.touched then
    if gesture_hint then ui.printc(gesture_hint, app.fonts.hint, 0, 436, ui.W, "grey") end
  else
    local hint = app.console and "A : suivant · X : passer · clapet : suivant"
      or gesture_hint or "Clic : suivant · P : passer"
    ui.printc(hint, app.fonts.small, 0, 436, ui.W, "grey")
  end
end

return play
