-- Words of one custom category.
local custom = require("custom")
local listview = require("listview")
local listbox = require("listbox")
local ui = require("ui")

local catwords = {}

local function cat(app) return app.custom[app.ed.cat] end

-- Action rows above the words: "Ajouter un mot", and on the web the text box ones.
local function head(app) return app.web and 3 or 1 end

local function items(app)
  local out = { { left = "Ajouter un mot", add = true, accent = true } }
  if app.web then
    out[2] = { left = "Coller une liste", add = true, accent = true }
    out[3] = { left = "Modifier la liste", add = true, accent = true }
  end
  for _, w in ipairs(cat(app).words) do out[#out + 1] = { left = w } end
  return out
end

local function count(app) return #cat(app).words + head(app) end

function catwords.enter(app)
  listview.clamp(app.ed.words, count(app))
end

local function open(app)
  local c, st = cat(app), app.ed.words
  if st.sel == 1 then
    app.openTyping({
      title = "Nouveau mot", noun = "mot", from = "catwords",
      validate = function(t) return custom.valid_word(c, t) end,
      commit = function(t)
        custom.add_word(c, t)
        app.customChanged()
        st.sel = 1
      end,
    })
  elseif st.sel == 2 and app.web then
    listbox.open("paste", c.name)
  elseif st.sel == 3 and app.web then
    listbox.open("edit", c.name, c.words)
  else
    local i = st.sel - head(app)
    app.openTyping({
      title = "Modifier le mot", noun = "mot", from = "catwords", text = c.words[i],
      validate = function(t) return custom.valid_word(c, t, i) end,
      commit = function(t)
        custom.set_word(c, i, t)
        app.customChanged()
      end,
      delete = function()
        table.remove(c.words, i)
        app.customChanged()
        listview.clamp(st, count(app))
      end,
    })
  end
end

local function delete(app)
  local c, st = cat(app), app.ed.words
  if st.sel <= head(app) then return end
  local i = st.sel - head(app)
  app.confirmThen("catwords", function()
    table.remove(c.words, i)
    app.customChanged()
    listview.clamp(st, count(app))
  end)
end

local function plural(n, word) return n .. " " .. word .. (n > 1 and "s" or "") end

-- The text box's answer: add or replace the words, then say what happened.
function catwords.update(app, dt)
  local t = app.ed.toast
  if t then
    t.left = t.left - dt
    if t.left <= 0 then app.ed.toast = nil end
  end
  if not app.web then return end
  local mode, text = listbox.poll()
  if not mode or mode == "cancel" then return end
  local c, words = cat(app), custom.split_list(text)
  local n, skipped
  if mode == "edit" then
    n, skipped = custom.set_words(c, words)
  else
    n, skipped = custom.add_words(c, words)
  end
  app.customChanged()
  listview.clamp(app.ed.words, count(app))
  local msg = mode == "edit" and plural(#c.words, "mot") .. " dans la liste"
    or plural(n, "mot") .. (n > 1 and " ajoutés" or " ajouté")
  if skipped > 0 then msg = msg .. " · " .. skipped .. (skipped > 1 and " ignorés" or " ignoré") end
  app.ed.toast = { text = msg, left = 3 }
end

-- Web: drag the list with a finger (taps come as actions).
function catwords.gesture(app, name, info)
  listview.drag(app.ed.words, name, info, count(app))
end

function catwords.action(app, name, x, y)
  local st, n = app.ed.words, count(app)
  if listview.nav(st, name, n) then return end
  if name == "select" then
    open(app)
  elseif name == "delete" or (name == "mycats" and app.console) then
    -- Suppr on a computer, Y on the console (C must not delete on a computer)
    delete(app)
  elseif name == "back" then
    app.switch("mycats")
  elseif name == "tap" then
    if app.touched and listview.back_hit(x, y) then return catwords.action(app, "back") end
    if app.touched and not app.web and st.sel > head(app) and listview.del_hit(st, x, y) then return delete(app) end
    local idx = listview.row_at(st, x, y, n)
    if idx then
      st.sel = idx
      open(app)
    end
  end
end

function catwords.draw(app)
  local hint = app.console and "A : modifier · Y : supprimer · B : retour"
    or { "Entrée : modifier · Suppr : supprimer · Échap : retour", "Entrée : modifier · Suppr : supprimer" }
  local h = head(app)
  -- web: a tapped word opens its box, which has "Supprimer ce mot"
  listview.draw(app, cat(app).name, items(app), app.ed.words, hint, function(i) return i > h and not app.web end)
  local t = app.ed.toast
  if t then
    local f = app.fonts.small
    if f:getWidth(t.text) + 40 > ui.W - 40 then f = app.fonts.hint end
    local w = math.min(ui.W - 40, f:getWidth(t.text) + 40)
    local y = ui.H - 120
    ui.box((ui.W - w) / 2, y, w, 46, "pink")
    ui.printc(t.text, f, (ui.W - w) / 2, y + (46 - f:getHeight()) / 2, w, "bg")
  end
end

return catwords
