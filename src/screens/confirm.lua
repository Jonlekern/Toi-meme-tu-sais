-- "Sûr ?" over the screen that asked (app.confirm = { from, yes }).
local ui = require("ui")

local confirm = {}

local YES = { x = 200, y = 300, w = 140, h = 54 }
local NO = { x = 380, y = 300, w = 140, h = 54 }

-- Centred under "Sûr ?" for the current screen size.
local function layout()
  YES.x, YES.y = ui.W / 2 - 160, ui.H / 2 + 60
  NO.x, NO.y = ui.W / 2 + 20, ui.H / 2 + 60
end

local function hit(r, x, y)
  return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

function confirm.enter(app) end

local function answer(app, yes)
  local c = app.confirm
  app.confirm = nil
  if yes then c.yes() end
  app.switch(c.from)
end

function confirm.action(app, name, x, y)
  if name == "select" then
    answer(app, true)
  elseif name == "back" then
    answer(app, false)
  elseif name == "tap" and (app.touched or not app.console) then
    layout()
    if hit(YES, x, y) then answer(app, true) elseif hit(NO, x, y) then answer(app, false) end
  end
end

function confirm.draw(app)
  app.screens[app.confirm.from].draw(app)
  ui.set("backdrop")
  love.graphics.rectangle("fill", 0, 0, ui.W, ui.H)
  layout()
  ui.printc("Sûr ?", app.fonts.title, 0, ui.H / 2 - 70, ui.W, "pink")
  -- buttons for touch and for the mouse (web/computer); the console uses A/B
  if app.touched or not app.console then
    ui.button("Oui", app.fonts.button, YES.x, YES.y, YES.w, YES.h)
    ui.box(NO.x, NO.y, NO.w, NO.h, nil, "outline")
    ui.printc("Non", app.fonts.button, NO.x, NO.y + (NO.h - app.fonts.button:getHeight()) / 2, NO.w, "text")
  end
  if not app.touched then
    local hint = app.pads and "A : oui · B : non" or "Entrée : oui · Échap : non"
    ui.printc(hint, app.fonts.small, 0, ui.H - 44, ui.W, "grey")
  end
end

return confirm
