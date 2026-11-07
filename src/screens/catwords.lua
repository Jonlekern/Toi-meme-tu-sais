-- Words of one custom category.
local custom = require("custom")
local listview = require("listview")

local catwords = {}

local function cat(app) return app.custom[app.ed.cat] end

local function items(app)
  local out = { { left = "Ajouter un mot", add = true, accent = true } }
  for _, w in ipairs(cat(app).words) do out[#out + 1] = { left = w } end
  return out
end

function catwords.enter(app)
  listview.clamp(app.ed.words, #cat(app).words + 1)
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
  else
    local i = st.sel - 1
    app.openTyping({
      title = "Modifier le mot", noun = "mot", from = "catwords", text = c.words[i],
      validate = function(t) return custom.valid_word(c, t, i) end,
      commit = function(t)
        custom.set_word(c, i, t)
        app.customChanged()
      end,
    })
  end
end

local function delete(app)
  local c, st = cat(app), app.ed.words
  if st.sel == 1 then return end
  local i = st.sel - 1
  app.confirmThen("catwords", function()
    table.remove(c.words, i)
    app.customChanged()
    listview.clamp(st, #c.words + 1)
  end)
end

function catwords.action(app, name, x, y)
  local st, n = app.ed.words, #cat(app).words + 1
  if listview.nav(st, name, n) then return end
  if name == "select" then
    open(app)
  elseif name == "mycats" then
    delete(app)
  elseif name == "back" then
    app.switch("mycats")
  elseif name == "tap" then
    if app.touched and listview.back_hit(x, y) then return catwords.action(app, "back") end
    if app.touched and st.sel > 1 and listview.del_hit(st, x, y) then return delete(app) end
    local idx = listview.row_at(st, x, y, n)
    if idx then
      st.sel = idx
      open(app)
    end
  end
end

function catwords.draw(app)
  listview.draw(app, cat(app).name, items(app), app.ed.words,
    "A : modifier · Y : supprimer · B : retour", function(i) return i > 1 end)
end

return catwords
