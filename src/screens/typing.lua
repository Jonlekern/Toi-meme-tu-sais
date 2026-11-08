-- Typing: on-screen AZERTY keyboard on the console, system text input elsewhere.
-- app.typing = { title, noun, text, from, validate(text) -> true|nil, reason, commit(text) -> next screen name or nil,
--   delete() optional: offers "Supprimer" (web) }
-- On the web the text is typed in a real text box of the page (listbox), so phones
-- show their keyboard; this screen only waits for the answer.
local ui = require("ui")
local keyboard = require("keyboard")
local listbox = require("listbox")

local typing = {}
typing.wants_text = true

local LINE_Y, KEYS_Y, KEY_H, KEY_STEP, UNIT = 138, 196, 46, 54, 66
local X0 = 30
local BACK = { x = 10, y = 10, w = 100, h = 44 }
local OKBTN = { x = 590, y = 10, w = 100, h = 44 } -- x follows the screen width (layout)

local function layout() OKBTN.x = ui.W - 130 end
local MAX_LEN = 48
local had_text_input -- state to restore on leave (desktop has it on by default)

local MESSAGES = {
  vide = "Vide", ["trop long"] = "Trop long", ["réservé"] = "Nom réservé",
}

local function hit(r, x, y)
  return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

function typing.enter(app)
  local t = app.typing
  t.text = t.text or ""
  t.error = nil
  app.kb = keyboard.new()
  if app.web then
    listbox.open("line", t.title, { t.text }, { del = t.delete ~= nil })
  elseif not app.console then
    had_text_input = love.keyboard.hasTextInput()
    love.keyboard.setTextInput(true)
  end
end

function typing.leave(app)
  if not app.console and had_text_input ~= nil then
    love.keyboard.setTextInput(had_text_input)
    had_text_input = nil
  end
end

local function erase(t)
  t.text = t.text:gsub("[%z\1-\127\194-\244][\128-\191]*$", "")
  t.error = nil
end

local function add(t, s)
  if #t.text + #s <= MAX_LEN * 2 then t.text = t.text .. s end
  t.error = nil
end

function typing.text(app, s)
  if s:find("%c") then return end
  add(app.typing, s)
end

local function submit(app)
  local t = app.typing
  local ok, why = t.validate(t.text)
  if not ok then
    t.error = why == "existe" and ("Ce " .. t.noun .. " existe déjà") or MESSAGES[why] or why
    return
  end
  local from = t.from
  app.typing = nil
  app.switch(t.commit(t.text) or from)
end

local function cancel(app)
  local from = app.typing.from
  app.typing = nil
  app.switch(from)
end

-- Web: the text box's answer.
function typing.update(app)
  local t = app.typing
  if not app.web or not t then return end
  local mode, text = listbox.poll()
  if not mode then return end
  if mode == "cancel" then return cancel(app) end
  if mode == "delete" and t.delete then
    local from = t.from
    t.delete()
    app.typing = nil
    return app.switch(from)
  end
  t.text = (text or ""):gsub("[\r\n]", " ")
  submit(app)
  if app.typing == t and t.error then -- not accepted: ask again, saying why
    listbox.open("line", t.title, { t.text }, { del = t.delete ~= nil, error = t.error })
  end
end

function typing.action(app, name, x, y)
  local t = app.typing
  if name == "back" then
    return cancel(app)
  elseif name == "ok" then
    return submit(app)
  elseif name == "erase" then
    return erase(t)
  elseif name == "tap" then
    layout()
    if app.touched and hit(BACK, x, y) then return cancel(app) end
    if app.touched and hit(OKBTN, x, y) then return submit(app) end
    if not app.console then love.keyboard.setTextInput(true) end -- bring a dismissed phone keyboard back
  elseif app.console then
    if name == "skip" then
      erase(t)
    elseif name == "up" or name == "down" or name == "left" or name == "right" then
      app.kb:move(name)
    elseif name == "select" then
      local k = app.kb:press()
      if k.type == "char" then add(t, k.char)
      elseif k.type == "space" then add(t, " ")
      elseif k.type == "erase" then erase(t)
      elseif k.type == "ok" then submit(app) end
    end
  elseif name == "select" then
    submit(app)
  end
end

local function draw_keys(app)
  local kb, f = app.kb, app.fonts.ui
  for r, row in ipairs(kb.rows) do
    local y = KEYS_Y + (r - 1) * KEY_STEP
    for i, k in ipairs(row) do
      local x, w = X0 + k.x * UNIT, k.span * UNIT - 8
      local focus = kb.row == r and kb.idx == i
      local label = kb:label(k)
      local line = k.type == "ok" and "pink" or "outline"
      local color = "text"
      if k.type == "ok" then color = "pink" end
      if k.type == "shift" and kb.shift then line, color = "pink", "pink" end
      if focus then
        ui.set("pink")
        love.graphics.rectangle("fill", x, y, w, KEY_H, 10, 10)
        color = "bg"
      else
        ui.set(line)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x, y, w, KEY_H, 10, 10)
      end
      if k.type == "erase" then
        -- the font has no backspace glyph: draw it
        local cx, cy = x + w / 2, y + KEY_H / 2
        ui.set(color)
        love.graphics.setLineWidth(2)
        love.graphics.polygon("line", cx - 16, cy, cx - 6, cy - 10, cx + 16, cy - 10, cx + 16, cy + 10, cx - 6, cy + 10)
        love.graphics.line(cx - 2, cy - 4, cx + 8, cy + 4)
        love.graphics.line(cx - 2, cy + 4, cx + 8, cy - 4)
      else
        ui.printc(label, f, x, y + (KEY_H - f:getHeight()) / 2, w, color)
      end
    end
  end
end

function typing.draw(app)
  if app.web then return end -- the page's text box is shown instead
  layout()
  local t, f, W = app.typing, app.fonts.button, ui.W - 2 * X0
  local tx = 30
  if app.touched then
    local hf = app.fonts.hint
    ui.print("‹ Retour", hf, BACK.x + 10, 24 + (app.fonts.title:getHeight() - hf:getHeight()) / 2, "grey")
    ui.button("OK", app.fonts.button, OKBTN.x, OKBTN.y, OKBTN.w, OKBTN.h)
    tx = BACK.x + 10 + hf:getWidth("‹ Retour") + 20
  end
  local tf, line_y = app.fonts.title, LINE_Y
  if ui.portrait then
    -- narrow screen: the title gets its own line under "‹ Retour" and "OK"
    local ty = app.touched and 66 or 24
    if tf:getWidth(t.title) > ui.W - 60 then tf = app.fonts.head end
    if tf:getWidth(t.title) > ui.W - 60 then tf = app.fonts.button end
    ui.print(t.title, tf, 30, ty, "pink")
    line_y = ty + 114
  else
    -- smaller font when the title would run under "OK" (touch) or off the screen
    local room = app.touched and OKBTN.x - 10 - tx or ui.W - 30 - tx
    if tf:getWidth(t.title) > room then tf = app.fonts.head end
    if tf:getWidth(t.title) > room then tf = app.fonts.button end
    ui.print(t.title, tf, tx, tf == app.fonts.title and 24 or 29, "pink")
  end
  local LINE_Y = line_y

  -- input line: show the end of the text if it is too wide
  local shown = t.text
  while #shown > 0 and f:getWidth(shown .. "|") > W do
    shown = shown:gsub("^[%z\1-\127\194-\244][\128-\191]*", "")
  end
  ui.print(shown, f, X0, LINE_Y - f:getHeight() - 6, "text")
  ui.print("|", f, X0 + f:getWidth(shown), LINE_Y - f:getHeight() - 6, "pink")
  ui.set("pink")
  love.graphics.setLineWidth(1.5)
  love.graphics.line(X0, LINE_Y, X0 + W, LINE_Y)
  if t.error then ui.print(t.error, app.fonts.ui, X0, LINE_Y + 10, "pink") end

  -- the on-screen keyboard grid is laid out for the console's landscape screen only
  if app.console and not ui.portrait then
    draw_keys(app)
    ui.printc("A : lettre · X : effacer · START : OK", app.fonts.small, 0, ui.H - 44, ui.W, "grey")
  elseif not app.touched then
    ui.printc("Entrée : OK · Échap : annuler", app.fonts.small, 0, ui.H - 44, ui.W, "grey")
  end
end

return typing
