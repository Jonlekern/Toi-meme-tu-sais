-- Play: one big word, optional countdown.
local ui = require("ui")
local textfit = require("textfit")

local play = {}

local BOX = { x = 20, y = 90, w = 680, h = 300 }
local SIZES = { 120, 96, 72, 56, 40, 32, 26, 22 }
local BACK = { x = 10, y = 10, w = 100, h = 44 } -- w recomputed from the label in layout
local PASS = { x = 290, y = 424, w = 140, h = 44 }

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

-- Fit the "Passer" button to its label, centered, and "‹ Retour" to its text
-- (same placement as the editor lists' back button).
local function layout_pass(app)
  PASS.w = app.fonts.button:getWidth("Passer") + 48
  PASS.x = (ui.W - PASS.w) / 2
  BACK.w = 10 + app.fonts.hint:getWidth("‹ Retour") + 10
end

function play.action(app, name, x, y)
  layout_pass(app)
  if name == "tap" then
    if app.touched and hit(BACK, x, y) then return play.action(app, "back") end
    if app.touched and hit(PASS, x, y) then return play.action(app, "skip") end
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
  layout_pass(app)
  local r = app.round
  local labelX = 30
  if app.touched then
    local hf = app.fonts.hint
    ui.print("‹ Retour", hf, BACK.x + 10, 24 + (app.fonts.ui:getHeight() - hf:getHeight()) / 2, "grey")
    labelX = BACK.x + 10 + hf:getWidth("‹ Retour") + 20
  end
  if r.category then ui.print(r.category.label, app.fonts.ui, labelX, 24, "grey") end
  if r.remaining then
    local text = fmt(r.remaining)
    ui.print(text, app.fonts.ui, ui.W - 30 - app.fonts.ui:getWidth(text), 24, "pink")
  end

  if r.word then
    if not app.fit or app.fit.word ~= r.word then
      local size, lines = textfit.fit(r.word, BOX.w, BOX.h, SIZES, function(text, s)
        local f = app.fonts.word(s)
        return f:getWidth(text), f:getHeight()
      end)
      app.fit = { word = r.word, size = size, lines = lines }
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

  if app.touched then
    ui.button("Passer", app.fonts.button, PASS.x, PASS.y, PASS.w, PASS.h)
  else
    local hint = app.console and "A : suivant · X : passer · clapet : suivant"
      or "Clic : suivant · P : passer"
    ui.printc(hint, app.fonts.small, 0, 436, ui.W, "grey")
  end
end

return play
