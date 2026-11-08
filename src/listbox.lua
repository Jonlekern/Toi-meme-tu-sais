-- Web only: a real text box (in index.html) to paste or edit a whole word list.
-- Lua asks through stdout (Module.print), the page answers with a file in the
-- save directory. Plain Lua apart from love.filesystem.
local M = {}

local SEP, WORD = "\31", "\30"
local REPLY = "liste-retour.txt"

-- mode: "paste" (box starts empty, words are added), "edit" (box holds the list)
-- or "line" (one line of text: words = { text }). opts: del (show "Supprimer"),
-- error (message shown above the box).
function M.open(mode, title, words, opts)
  opts = opts or {}
  love.filesystem.write(REPLY, "") -- makes sure the save directory exists
  love.filesystem.remove(REPLY)
  print(table.concat({ "TTMS-LIST", mode, title, love.filesystem.getSaveDirectory(),
    REPLY, table.concat(words or {}, WORD), opts.del and "1" or "", opts.error or "" }, SEP))
end

-- The page's answer once there is one: mode ("paste", "edit", "line", "delete"
-- or "cancel") and text.
function M.poll()
  if not love.filesystem.getInfo(REPLY) then return nil end
  local data = love.filesystem.read(REPLY) or ""
  love.filesystem.remove(REPLY)
  local mode, text = data:match("^([^\n]*)\n?(.*)$")
  return mode, text
end

return M
