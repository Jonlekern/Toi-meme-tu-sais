-- Shared drawing helpers: logical screen scaled to the window, 720x480
-- ("landscape") or 480x800 when the window is taller than wide ("portrait").
local ui = {}

ui.W, ui.H, ui.portrait = 720, 480, false

local function hex(r, g, b) return { r / 255, g / 255, b / 255 } end
ui.color = {
  bg = hex(0x1a, 0x1a, 0x1a),
  pink = hex(0xF2, 0x6E, 0xF2),
  text = hex(0xf4, 0xf4, 0xf4),
  grey = hex(0x88, 0x88, 0x88),
  outline = hex(0x55, 0x55, 0x55),
  backdrop = hex(0x11, 0x11, 0x11),
  card = hex(0x1a, 0x1a, 0x1a),
}

local scale, ox, oy = 1, 0, 0
local known -- whether setWindow ran yet

-- Logical size and mode for a window size. Pure.
function ui.mode(w, h)
  if h > w then return 480, 800, true end
  return 720, 480, false
end

-- Pick the layout mode for the window size; returns true when the mode changed.
function ui.setWindow(w, h)
  local lw, lh, portrait = ui.mode(w, h)
  local changed = not known or portrait ~= ui.portrait
  known = true
  ui.W, ui.H, ui.portrait = lw, lh, portrait
  ui.layout(w, h)
  return changed
end

function ui.layout(w, h)
  scale = math.min(w / ui.W, h / ui.H)
  ox = (w - ui.W * scale) / 2
  oy = (h - ui.H * scale) / 2
end

-- Window units per logical unit.
function ui.getScale() return scale end

-- Logical space left empty beside (x) and above/below (y) the logical screen.
function ui.margins() return ox / scale, oy / scale end

function ui.toLogical(x, y)
  return (x - ox) / scale, (y - oy) / scale
end

function ui.begin()
  ui.layout(love.graphics.getDimensions())
  love.graphics.push()
  love.graphics.translate(ox, oy)
  love.graphics.scale(scale, scale)
  love.graphics.setScissor() -- the margins can be drawn on too (phone edges)
end

function ui.finish()
  love.graphics.setScissor()
  love.graphics.pop()
end

-- Clip drawing to a logical rectangle (setScissor ignores transforms); ui.unclip restores.
function ui.clip(x, y, w, h)
  love.graphics.setScissor(ox + x * scale, oy + y * scale, w * scale, h * scale)
end

function ui.unclip()
  love.graphics.setScissor()
end

function ui.set(name) love.graphics.setColor(ui.color[name]) end

-- Text with its top-left at (x, y).
function ui.print(text, font, x, y, color)
  ui.set(color or "text")
  love.graphics.setFont(font)
  love.graphics.print(text, x, y)
end

-- Text centered horizontally in [x, x + w].
function ui.printc(text, font, x, y, w, color)
  ui.set(color or "text")
  love.graphics.setFont(font)
  love.graphics.printf(text, x, y, w, "center")
end

-- Rounded box; fill = color name or nil, line = color name or nil.
function ui.box(x, y, w, h, fill, line, focus)
  local r = h / 2
  if fill then
    ui.set(fill)
    love.graphics.rectangle("fill", x, y, w, h, r, r)
  end
  if line then
    ui.set(line)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, r, r)
  end
  if focus then
    ui.set("pink")
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", x - 5, y - 5, w + 10, h + 10, r + 5, r + 5)
  end
end

-- Pink button with dark text.
function ui.button(label, font, x, y, w, h, focus)
  ui.box(x, y, w, h, "pink", nil, focus)
  ui.set("bg")
  love.graphics.setFont(font)
  love.graphics.printf(label, x, y + (h - font:getHeight()) / 2, w, "center")
end

return ui
