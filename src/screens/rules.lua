-- Rules card shown over the home screen.
local ui = require("ui")
local home = require("screens.home")

local rules = {}

local CARD_W, PAD = 576, 26

local function layout(app)
  local pink, text = ui.color.pink, ui.color.text
  local lines = {
    { text, "1. Jouez à deux. L'autre équipe écoute et peut aussi deviner." },
    { text, "2. Un mot s'affiche : un seul le voit." },
    { text, "3. Fais-le deviner ", pink, "avec un souvenir", text, " que vous avez vécu ensemble." },
    { text, "4. Trouvé : mot suivant. Trop dur : passe." },
  }
  local font, inner = app.fonts.ui, CARD_W - PAD * 2
  local y = PAD + app.fonts.head:getHeight() + 12
  local rows = {}
  for i, l in ipairs(lines) do
    local _, wrapped = font:getWrap(l, inner)
    rows[i] = { l = l, y = y }
    y = y + #wrapped * font:getHeight() + 10
  end
  local footer_y = y + 6
  local h = footer_y + app.fonts.small:getHeight() + PAD
  return { x = (ui.W - CARD_W) / 2, y = (ui.H - h) / 2, w = CARD_W, h = h, rows = rows,
    footer_y = footer_y, inner = inner }
end

function rules.enter(app) end

function rules.action(app, name, x, y)
  if name == "back" or name == "rules" then
    app.switch("home")
  elseif name == "tap" then
    local c = layout(app)
    if x < c.x or x > c.x + c.w or y < c.y or y > c.y + c.h then app.switch("home") end
  end
end

function rules.draw(app)
  home.draw(app)
  ui.set("backdrop")
  love.graphics.rectangle("fill", 0, 0, ui.W, ui.H)
  local c = layout(app)
  ui.set("card")
  love.graphics.rectangle("fill", c.x, c.y, c.w, c.h, 12, 12)
  ui.set("pink")
  love.graphics.setLineWidth(1.5)
  love.graphics.rectangle("line", c.x, c.y, c.w, c.h, 12, 12)

  ui.print("Comment on joue", app.fonts.head, c.x + PAD, c.y + PAD, "pink")
  love.graphics.setFont(app.fonts.ui)
  love.graphics.setColor(1, 1, 1)
  for _, r in ipairs(c.rows) do
    love.graphics.printf(r.l, c.x + PAD, c.y + r.y, c.inner, "left")
  end
  ui.set("grey")
  love.graphics.setFont(app.fonts.small)
  love.graphics.printf(app.console and "B : fermer" or "Échap : fermer", c.x + PAD, c.y + c.footer_y, c.inner, "right")
end

return rules
