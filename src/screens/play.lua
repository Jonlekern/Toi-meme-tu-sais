-- Play: one big word, optional countdown.
local ui = require("ui")
local textfit = require("textfit")

local play = {}

local SIZES = { 120, 96, 72, 56, 40, 32, 26, 22 }

local function hit(r, x, y)
  return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

function play.enter(app)
  app.round:next()
  app.fit = nil
end

function play.update(app, dt)
  if app.round:update(dt) == "timeup" then
    app.round:finish()
    app.switch("timeup")
  end
end

-- Geometry for the current layout mode, shared by drawing and hit tests:
-- BOX = word area, BACK = "‹ Retour" (top-left), PASS = "Passer" (bottom-centre).
-- Landscape: "Passer" fitted to its label and "‹ Retour" to its text (same placement
-- as the editor lists' back button), both shown after a touch only.
local function layout(app)
  local g = {}
  if ui.portrait then
    local bf = app.fonts.small
    g.back_font = bf
    g.BACK = { x = 10, y = 14, w = 10 + bf:getWidth("‹ Retour") + 10, h = 48 }
    g.top_y = 24 -- "‹ Retour" and timer line
    g.BOX = { x = 20, y = 120, w = ui.W - 40, h = 430 }
    local pw = math.max(app.fonts.button:getWidth("Passer") + 48, 220)
    g.PASS = { x = (ui.W - pw) / 2, y = 662, w = pw, h = 66 }
  else
    g.back_font = app.fonts.hint
    g.BACK = { x = 10, y = 10, w = 10 + app.fonts.hint:getWidth("‹ Retour") + 10, h = 44 }
    g.top_y = 24
    g.BOX = { x = 20, y = 90, w = 680, h = 300 }
    local pw = app.fonts.button:getWidth("Passer") + 48
    g.PASS = { x = (ui.W - pw) / 2, y = 424, w = pw, h = 44 }
  end
  return g
end

-- Back and skip buttons: always in portrait, after a touch in landscape.
local function buttons(app) return ui.portrait or app.touched end

function play.action(app, name, x, y)
  local g = layout(app)
  if name == "tap" then
    if buttons(app) and hit(g.BACK, x, y) then return play.action(app, "back") end
    if buttons(app) and hit(g.PASS, x, y) then return play.action(app, "skip") end
    return play.action(app, "select")
  elseif name == "skip" then
    app.round:skip()
    app.fit = nil
  elseif name == "select" then
    app.round:next()
    app.fit = nil
  elseif name == "back" then
    app.round:finish()
    app.switch("home")
  end
end

local function fmt(sec)
  sec = math.ceil(sec)
  return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

function play.draw(app)
  local g = layout(app)
  local BOX, BACK, PASS = g.BOX, g.BACK, g.PASS
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
    if not app.fit or app.fit.word ~= r.word or app.fit.w ~= BOX.w or app.fit.h ~= BOX.h then
      local size, lines = textfit.fit(r.word, BOX.w, BOX.h, SIZES, function(text, s)
        local f = app.fonts.word(s)
        return f:getWidth(text), f:getHeight()
      end)
      app.fit = { word = r.word, w = BOX.w, h = BOX.h, size = size, lines = lines }
    end
    local f = app.fonts.word(app.fit.size)
    local lh = f:getHeight()
    local y = BOX.y + (BOX.h - lh * #app.fit.lines) / 2
    for _, line in ipairs(app.fit.lines) do
      ui.printc(line, f, BOX.x, y, BOX.w, "text")
      y = y + lh
    end
  else
    ui.printc("Aucun mot", app.fonts.word(56), BOX.x, BOX.y + BOX.h / 2 - 40, BOX.w, "grey")
  end

  if ui.portrait then
    ui.printc("Touche : mot suivant", app.fonts.small, 0, 604, ui.W, "grey")
    ui.button("Passer", app.fonts.button, PASS.x, PASS.y, PASS.w, PASS.h)
  elseif app.touched then
    ui.button("Passer", app.fonts.button, PASS.x, PASS.y, PASS.w, PASS.h)
  else
    local hint = app.console and "A : suivant · X : passer · clapet : suivant"
      or "Clic : suivant · P : passer"
    ui.printc(hint, app.fonts.small, 0, 436, ui.W, "grey")
  end
end

return play
