-- "Sûr ?" over the screen that asked (app.confirm = { from, yes }).
local ui = require("ui")

local confirm = {}

local YES = { x = 200, y = 300, w = 140, h = 54 }
local NO = { x = 380, y = 300, w = 140, h = 54 }

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
  elseif name == "tap" and app.touched then
    if hit(YES, x, y) then answer(app, true) elseif hit(NO, x, y) then answer(app, false) end
  end
end

function confirm.draw(app)
  app.screens[app.confirm.from].draw(app)
  ui.set("backdrop")
  love.graphics.rectangle("fill", 0, 0, ui.W, ui.H)
  ui.printc("Sûr ?", app.fonts.title, 0, 170, ui.W, "pink")
  if app.touched then
    ui.button("Oui", app.fonts.button, YES.x, YES.y, YES.w, YES.h)
    ui.box(NO.x, NO.y, NO.w, NO.h, nil, "outline")
    ui.printc("Non", app.fonts.button, NO.x, NO.y + (NO.h - app.fonts.button:getHeight()) / 2, NO.w, "text")
  else
    ui.printc("A : oui · B : non", app.fonts.small, 0, 436, ui.W, "grey")
  end
end

return confirm
