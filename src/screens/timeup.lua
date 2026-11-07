-- Time is up.
local ui = require("ui")

local timeup = {}

function timeup.enter(app) end

local BTN = { x = 285, y = 250, w = 150, h = 54 }

function timeup.action(app, name, x, y)
  if name == "tap" then
    if x >= BTN.x and x <= BTN.x + BTN.w and y >= BTN.y and y <= BTN.y + BTN.h then
      app.startRound()
    end
  elseif name == "select" then
    app.startRound()
  elseif name == "back" then
    app.switch("home")
  end
end

function timeup.draw(app)
  ui.printc("Temps écoulé", app.fonts.title, 0, 120, ui.W, "pink")
  ui.button("Rejouer", app.fonts.button, BTN.x, BTN.y, BTN.w, BTN.h, true)
  ui.printc("B : retour à l'accueil", app.fonts.small, 0, 436, ui.W, "grey")
end

return timeup
