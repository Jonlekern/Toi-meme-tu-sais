love.filesystem.setRequirePath("src/?.lua;src/?/init.lua;" .. love.filesystem.getRequirePath())

local words = require("words")
local settings = require("settings")
local deck = require("deck")
local round = require("round")
local ui = require("ui")
local input = require("input")
local lid = require("lid")
local stats = require("stats")
local custom = require("custom")
local listview = require("listview")

local screens = {
  home = require("screens.home"),
  play = require("screens.play"),
  rules = require("screens.rules"),
  timeup = require("screens.timeup"),
  mycats = require("screens.mycats"),
  catwords = require("screens.catwords"),
  typing = require("screens.typing"),
  confirm = require("screens.confirm"),
}

local app = { touched = false, focus = 1, screens = screens, custom = {} }
local current

local inp = input.new()
local lidTracker = lid.tracker()
local lidChannel

local function dispatch(name, x, y)
  if name then current.action(app, name, x, y) end
end

function app.switch(name)
  if current and current.leave then current.leave(app) end
  current = screens[name]
  current.enter(app)
end

-- Fonts are rasterized at the size they are shown on screen (logical size x
-- screen scale x DPI scale, in steps of 1/4) so text stays sharp when the
-- logical screen is scaled up; their metrics stay in logical units.
local function font_scale()
  local s = ui.getScale() * love.graphics.getDPIScale()
  return math.max(1, math.ceil(s * 4 - 0.01) / 4)
end

local function load_fonts(dpi)
  if app.fonts and app.fonts.dpi == dpi then return end
  local function font(path, size)
    return love.graphics.newFont("assets/fonts/" .. path, size, "normal", dpi)
  end
  local cache = {}
  app.fonts = {
    dpi = dpi,
    title = font("Calebard-Bold.ttf", 38),
    button = font("Calebard-Bold.ttf", 22),
    hint = font("Calebard-Regular.ttf", 14),
    head = font("Calebard-Bold.ttf", 28),
    ui = font("Calebard-Regular.ttf", 22),
    small = font("Calebard-Regular.ttf", 18),
    word = function(size)
      cache[size] = cache[size] or font("Clebard-Tall.ttf", size)
      return cache[size]
    end,
  }
  app.fit = nil -- word layout depends on the font metrics
end

function app.save()
  love.filesystem.write("settings.txt", settings.serialize(app.settings))
end

-- Built-in categories followed by the user's non-empty ones; returns the set of known ids.
local function rebuild()
  local lists = { melange = app.lists.melange, categories = {} }
  for _, c in ipairs(app.builtin) do lists.categories[#lists.categories + 1] = c end
  for _, c in ipairs(custom.as_categories(app.custom)) do lists.categories[#lists.categories + 1] = c end
  app.lists = lists
  local known = {}
  for _, c in ipairs(lists.categories) do known[c.id] = true end
  return known
end

-- Called after any change to the custom categories: refresh, drop dead ticks, persist.
function app.customChanged()
  local known = rebuild()
  app.deck = nil -- word lists changed: next round builds a fresh deck
  for id in pairs(app.settings.categories) do
    if not known[id] then app.settings.categories[id] = nil end
  end
  love.filesystem.write("mes-mots.txt", custom.serialize(app.custom))
  app.save()
end

function app.openTyping(t)
  app.typing = t
  app.switch("typing")
end

function app.confirmThen(from, yes)
  app.confirm = { from = from, yes = yes }
  app.switch("confirm")
end

-- The deck lives across rounds so no word repeats before its bag is empty;
-- it is rebuilt only on first play, when the ticked categories change, or
-- after the custom categories changed (app.customChanged clears it).
function app.startRound()
  local sig = deck.signature(app.settings.categories)
  if not app.deck or app.deckSig ~= sig then
    app.deck = deck.new(app.lists, app.settings.categories, love.math.random)
    app.deckSig = sig
  end
  local on_done
  if app.console then
    on_done = function(entry)
      local line = stats.line(entry, os.date("%Y-%m-%d %H:%M"))
      local ok, err = pcall(love.filesystem.append, "stats.txt", line)
      if not ok then print("stats: " .. tostring(err)) end
    end
  end
  app.round = round.new(app.deck, app.settings.timer, on_done)
  app.switch("play")
end

-- Missing files must give nil (the web runtime raises an error instead).
local function read_file(path)
  if not love.filesystem.getInfo(path, "file") then return nil end
  return (love.filesystem.read(path))
end

-- A failing lid thread must never take the game down.
function love.threaderror(t, e)
  print("lid: " .. tostring(e))
  lidChannel = nil
end

function love.load()
  io.stdout:setvbuf("line")
  app.console = love.system.getOS() == "Linux"
  love.graphics.setBackgroundColor(ui.color.bg)
  pcall(function() love.window.setIcon(love.image.newImageData("assets/logo/logo-192.png")) end)
  love.math.setRandomSeed(os.time())

  app.lists = words.load(read_file)
  app.builtin = app.lists.categories
  app.custom = custom.parse(read_file("mes-mots.txt"))
  app.ed = { cats = listview.new(), words = listview.new(), cat = 1 }
  local known = rebuild()
  app.settings = settings.parse(read_file("settings.txt"), known)

  app.relayout(love.graphics.getDimensions())
  app.switch("home")

  -- Lid switch (RG SP): closing then reopening it = next word.
  if app.console then
    local f = io.open("/proc/bus/input/devices", "r")
    local text = f and f:read("*a")
    if f then f:close() end
    local device = lid.find_device(text)
    if device then
      lidChannel = love.thread.getChannel("lid")
      love.thread.newThread("src/lid_thread.lua"):start(device)
    else
      print("lid: no lid switch device found")
    end
  end
end

function love.update(dt)
  if lidChannel then
    while true do
      local msg = lidChannel:pop()
      if not msg then break end
      if msg == "open" or msg == "closed" then
        if lidTracker:feed(msg) and current == screens.play then dispatch("select") end
      else
        print("lid: " .. tostring(msg))
        lidChannel = nil
        break
      end
    end
  end
  if current.update then current.update(app, dt) end
end

-- Window size changed (phone turned, window resized): pick the layout mode again;
-- on a mode change, drop cached layouts (the round and deck are kept).
function app.relayout(w, h)
  if ui.setWindow(w, h) then
    app.fit = nil
    app.pill_scroll = 0
  end
  load_fonts(font_scale())
end

function love.resize(w, h)
  app.relayout(w, h)
end

function love.draw()
  -- some runtimes (web) can change the canvas size without a resize event
  app.relayout(love.graphics.getDimensions())
  ui.begin()
  current.draw(app)
  ui.finish()
end

function love.keypressed(key)
  -- typing screens get spaces through love.textinput; Space must not validate there
  if current.wants_text and key == "space" then return end
  dispatch(inp:key(key))
end

function love.gamepadpressed(_, button)
  dispatch(inp:button(button))
end

function love.touchpressed(_, x, y)
  local lx, ly = ui.toLogical(x, y)
  dispatch(inp:touch(lx, ly, love.timer.getTime()))
  app.touched = true -- after dispatch: the back button only counts once it was visible
end

function love.mousepressed(x, y, button, istouch)
  local lx, ly = ui.toLogical(x, y)
  dispatch(inp:mouse(lx, ly, button, istouch, love.timer.getTime()))
end

-- "?" is layout-dependent, so it comes from text input (not keypressed),
-- except on screens that type text themselves.
function love.textinput(t)
  if current.wants_text then
    if current.text then current.text(app, t) end
    return
  end
  dispatch(inp:text(t))
end
