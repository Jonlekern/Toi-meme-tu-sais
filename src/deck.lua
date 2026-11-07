-- Word deck: shuffled bags plus a hidden die that decides when a
-- category word comes up. Pure Lua; rng(a, b) returns an integer in [a, b].
local deck = {}

local Bag = {}
Bag.__index = Bag

local function shuffle(t, rng)
  for i = #t, 2, -1 do
    local j = rng(1, i)
    t[i], t[j] = t[j], t[i]
  end
end

function deck.bag(items, rng)
  local self = setmetatable({ items = items, rng = rng, order = {}, pos = 1, last = nil }, Bag)
  self.n = #items
  return self
end

function Bag:refill()
  local order = {}
  for i = 1, self.n do order[i] = self.items[i] end
  shuffle(order, self.rng)
  -- Do not start with the item that just came out.
  if self.n > 1 and self.last ~= nil and order[1] == self.last then
    local j = self.rng(2, self.n)
    order[1], order[j] = order[j], order[1]
  end
  self.order, self.pos = order, 1
end

function Bag:draw()
  if self.n == 0 then return nil end
  if self.pos > #self.order then self:refill() end
  local item = self.order[self.pos]
  self.pos = self.pos + 1
  self.last = item
  return item
end

local Deck = {}
Deck.__index = Deck

function deck.new(lists, checked, rng)
  local self = setmetatable({ rng = rng }, Deck)
  self.melange = deck.bag(lists.melange or {}, rng)

  local pool = {}
  for _, cat in ipairs(lists.categories or {}) do
    if checked and checked[cat.id] then
      local category = { id = cat.id, label = cat.label }
      for _, w in ipairs(cat.words) do
        pool[#pool + 1] = { word = w, category = category }
      end
    end
  end
  self.pool = #pool > 0 and deck.bag(pool, rng) or nil
  self.hasMelange = #(lists.melange or {}) > 0
  self.wait = rng(2, 4)
  return self
end

-- Identifies the ticked categories (order-independent) so a deck is rebuilt
-- only when they change; false/nil entries do not count.
function deck.signature(checked)
  local ids = {}
  for id, on in pairs(checked or {}) do
    if on then ids[#ids + 1] = id end
  end
  table.sort(ids)
  return table.concat(ids, "\n")
end

-- Returns word, category ({id, label} or nil for melange words);
-- nil when there is nothing to draw.
function Deck:next()
  if self.pool and not self.hasMelange then
    local e = self.pool:draw()
    return e.word, e.category
  end
  if self.pool then
    if self.wait == 1 then
      self.wait = self.rng(2, 4)
      local e = self.pool:draw()
      return e.word, e.category
    end
    self.wait = self.wait - 1
  end
  if not self.hasMelange then return nil end
  return self.melange:draw(), nil
end

return deck
