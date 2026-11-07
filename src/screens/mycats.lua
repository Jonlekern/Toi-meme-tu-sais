-- Mes catégories: list of the user's own categories.
local ui = require("ui")
local custom = require("custom")
local listview = require("listview")

local mycats = {}

local function items(app)
  local out = {}
  for i, c in ipairs(app.custom) do
    out[i] = { left = c.name, right = #c.words .. (#c.words == 1 and " mot" or " mots") }
  end
  out[#out + 1] = { left = "Nouvelle catégorie", add = true, accent = true }
  return out
end

function mycats.enter(app)
  listview.clamp(app.ed.cats, #app.custom + 1)
end

local function open(app)
  local sel = app.ed.cats.sel
  if sel <= #app.custom then
    app.ed.cat = sel
    app.ed.words.sel, app.ed.words.scroll = 1, 0
    app.switch("catwords")
  else
    app.openTyping({
      title = "Nouvelle catégorie", noun = "nom", from = "mycats",
      validate = function(t) return custom.valid_name(app.custom, t) end,
      commit = function(t)
        app.custom[#app.custom + 1] = { name = custom.clean_name(t), words = {} }
        app.ed.cats.sel = #app.custom
        app.customChanged()
        app.ed.cat = #app.custom
        app.ed.words.sel, app.ed.words.scroll = 1, 0
        return "catwords"
      end,
    })
  end
end

local function delete(app)
  local i = app.ed.cats.sel
  if i > #app.custom then return end
  app.confirmThen("mycats", function()
    table.remove(app.custom, i)
    app.customChanged()
    listview.clamp(app.ed.cats, #app.custom + 1)
  end)
end

function mycats.action(app, name, x, y)
  local st, n = app.ed.cats, #app.custom + 1
  if listview.nav(st, name, n) then return end
  if name == "select" then
    open(app)
  elseif name == "delete" or (name == "mycats" and app.console) then
    -- Suppr on a computer, Y on the console (C must not delete on a computer)
    delete(app)
  elseif name == "back" then
    app.focus = 1
    app.switch("home")
  elseif name == "tap" then
    if app.touched and listview.back_hit(x, y) then return mycats.action(app, "back") end
    if app.touched and st.sel <= #app.custom and listview.del_hit(st, x, y) then return delete(app) end
    local idx = listview.row_at(st, x, y, n)
    if idx then
      st.sel = idx
      open(app)
    end
  end
end

function mycats.draw(app)
  local deletable = function(i) return i <= #app.custom end
  local hint = app.console and "A : ouvrir · Y : supprimer · B : retour"
    or { "Entrée : ouvrir · Suppr : supprimer · Échap : retour", "Entrée : ouvrir · Suppr : supprimer" }
  listview.draw(app, "Mes catégories", items(app), app.ed.cats, hint, deletable)
end

return mycats
