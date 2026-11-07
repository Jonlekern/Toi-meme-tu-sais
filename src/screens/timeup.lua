-- Time is up.
local ui = require("ui")

local timeup = {}

function timeup.enter(app) end

local BTN = { x = 285, y = 250, w = 150, h = 54 } -- x/w recomputed from the label in layout
local BACK = { x = 10, y = 10, w = 100, h = 44 } -- touch "‹ Retour", w from the label

local function hit(r, x, y)
  return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

-- Fit "Rejouer" and "‹ Retour" to their labels so drawing and hit tests agree.
local function layout(app)
  BTN.w = app.fonts.button:getWidth("Rejouer") + 48
  BTN.x = (ui.W - BTN.w) / 2
  BTN.y = ui.H / 2 + 10
  BACK.w = 10 + app.fonts.hint:getWidth("‹ Retour") + 10
end

function timeup.action(app, name, x, y)
  layout(app)
  if name == "tap" then
    if app.touched and hit(BACK, x, y) then return timeup.action(app, "back") end
    if hit(BTN, x, y) then app.startRound() end
  elseif name == "select" then
    app.startRound()
  elseif name == "back" then
    app.switch("home")
  end
end

function timeup.draw(app)
  layout(app)
  if app.touched then
    local hf = app.fonts.hint
    ui.print("‹ Retour", hf, BACK.x + 10, 24 + (app.fonts.title:getHeight() - hf:getHeight()) / 2, "grey")
  end
  local tf = app.fonts.title
  if tf:getWidth("Temps écoulé") > ui.W - 40 then tf = app.fonts.head end -- one line on narrow screens
  ui.printc("Temps écoulé", tf, 0, ui.H / 2 - 120, ui.W, "pink")
  ui.button("Rejouer", app.fonts.button, BTN.x, BTN.y, BTN.w, BTN.h, true)
  if not app.touched then
    local hint = app.console and "B : retour à l'accueil" or "Échap : retour à l'accueil"
    ui.printc(hint, app.fonts.small, 0, ui.H - 44, ui.W, "grey")
  end
end

return timeup
