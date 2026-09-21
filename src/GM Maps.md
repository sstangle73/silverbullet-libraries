---
tags: meta/library
name: "Library/Storie/GM Maps"
description: "Encounter maps written as a grid of characters with a legend under it: drawn as a scaled plan with a key of its own, on the wiki and in the book, and sized to the party. Terrain, ways through and things are told apart by pattern and silhouette, so a map reads in one ink and in grayscale."
author: "Steven Storie"
version: "1.2.3"
---

# GM Maps

Write an encounter area once, as a picture you can read in the source, and let the wiki and the book draw it. A map is a grid of characters with a legend under it. What each character means, the legend says; how big the grid is, the party decides.

| On the page | In print |
|---|---|
| A plan at five feet to a square, with the creatures on it, each linked to its Bestiary entry | The same plan, the creatures left off |

This is for the ground a fight happens on, not for dungeons. A map here is one room, one clearing, one yard: the walls, the floor, the ways out, and where the creatures start.

## A map's page

A page with `type: map` holds one map, in a fenced `map` block.

    ---
    type: map
    ---

    # The Old Orchard

    ${maps.draw()}

    ```map
    #####^##
    #,,,,,,#
    #,c,,c,#
    #,,S,,,#
    #,,,,,,#
    #,c,,c,#
    #,,,,,,#
    ##v#####

    grow to ${party.value{"square", plus = 3}}

    # wall briar, ten feet high
    , rough bramble and root - difficult terrain
    . floor bare path, a square wide
    ^ exit the way on
    v exit the way back
    S token strangler = World/Monsters/Strangler
    c token creeper = World/Monsters/Creeper
    ```

`${maps.draw()}` reads the page it is on. Everywhere else, name the page as a link in the adventure would write it: `${maps.draw("World/Maps/The Old Orchard")}`. A path written for an adventure folder also finds the page in a space that holds that folder, the way a Bestiary reference does.

The block holds the grid first, then a blank line, then one declaration to a line. Keep the grid to ASCII: one character is one square.

## The legend

A legend line is a single character, then what kind of square it is, then what it is:

    , rough bramble and root - difficult terrain

**The character is for you, not for the reader.** It says which squares of the grid this line is about, and it is nowhere on the drawing: a wall is hatching, difficult ground is a stipple, a way out is an arrow. So the map draws its own key, and each row of it is the square as the map draws it — the swatch with its own pattern, the arrow pointing the way it points on that grid, the thing in its own silhouette with its own letter. Nothing asks the reader to match a symbol they cannot see, and the key lists only what this map actually draws.

There are twelve kinds, in four families. **Terrain** fills a square, **a way through** is a mark in a gap in the wall, and **a thing** is its letter in a silhouette — the silhouette is what tells one thing from another, so they stay apart in one ink and in grayscale.

| Kind | Drawn as | For |
|---|---|---|
| `wall` | close diagonal hatching | Something that blocks: rock, briar, a building's side |
| `floor` | open | Ground that costs nothing to cross |
| `rough` | fine dots | Difficult terrain |
| `water` | waves | Water, deep or shallow — say which in the label |
| `pit` | an open diagonal mesh | A hole, a shaft, a drop |
| `exit` | an arrow out through the gap | A way out of the area |
| `door` | a bar across the gap | A way through that can be shut |
| `token` | a letter in a **circle** | A creature, at the square it starts on |
| `object` | a letter in a **square** | A thing that is there: a crate, a cart, a rig |
| `control` | a letter in a **diamond** | A thing you work: a lever, a button, a handle, a valve |
| `treasure` | a letter in a **triangle** | A thing worth taking: a chest, a prize, a strongbox |
| `hidden` | a letter in a **broken square** | A thing the players do not see. Say what it is in the label |

Every thing also carries a short label, drawn beside it: see *A thing is named on the map* below.

Nothing else is a kind. A character in the grid with no legend line is drawn as open floor, and the map says so under it.

A `token`, and any other thing, can name a page after an `=`, and the map then links to it the way a fight does:

    S token strangler = World/Monsters/Strangler

**A thing is named on the map.** Beside each one, the drawing writes what it is, so a reader is not sent to the key to find out what `C` was. The words come from the start of the line, up to its first comma or dash, and the key keeps the whole of it:

    C treasure a strongbox, iron-bound and too heavy to carry full

draws **a strongbox** beside the triangle, and prints *a strongbox, iron-bound and too heavy to carry full* in the key.

A square holds about twelve characters at five feet to a square, so a label is at most two words and that long. Where the start of the line is longer, name it in brackets:

    O object [powder] a crate of blasting powder, and nobody has checked it

**A thing with nothing short enough to write beside it is a warning, not a bare letter.** That is the point of the rule: the map asks to be told what each thing is, in a few words a reader can take in at the table, and the key asks for the rest. A map is only worth what is written for it.

Labels come off a map drawn too small to carry them, and the key still names everything.

**A thing stands on the ground, and the ground comes from its neighbours.** A crate in the water is drawn on water and a crate on the floor on floor, so taking the DM's layer off leaves no square looking different from the ones around it.

**`token` and `hidden` are the DM's layer.** They are on the map you keep and off the map the players get. Everything else is on both: a crate and a lever are in plain sight, and a trapdoor under the straw is what `hidden` is for.

## The characters

Any of the **94 printable ASCII characters**, `!` to `~`, can be a legend key, and they are case-sensitive, so `T` and `t` are two different keys. Pick whatever draws legibly in the source; there is no reserved set.

**Keep the grid to ASCII.** This is a correctness rule, not a preference. `s:sub(i, i)` is bytes in stock Lua and UTF-16 units in SilverBullet's, so a box-drawing character would draw on the wiki and corrupt a build of the same page.

Two things a grid cannot hold:

- **A space.** Short rows are padded with them, so a space is how the library says "nothing here". Write an explicit character for an empty square instead.
- **Nothing before the grid.** The block is the grid, then a blank line, then the declarations. A declaration above the grid discards it, and says so.

## Sizing to the party

`grow to <squares>` says how many squares the grid runs across, and takes a number, so [GM Party](<GM Party>)'s `party.value` can give it:

    grow to ${party.value{"square", plus = 3}}

Eight for a party of five: an area one square wider than the party has members, plus a wall to each side. Write the grid at the size the adventure is written for, and the map grows or shrinks to the number the line gives.

On the page that number is your table's. In print it is the adventure's, because a build evaluates the line with GM Party 1.2.1's `party.printed`, so the book is drawn for the party it is written for whoever is playing tonight.

**The map grows around its middle.** Rows and columns are added either side of the centre, copied from the nearest row or column that is all one character and nothing but ground from wall to wall, so what sits at the centre stays near it and what sits against a wall stays against it. Shrinking takes those same rows and columns away. A row or column with a way through or a thing anywhere along it, its walls included, is never copied or taken, so growing never adds a second door or chest and shrinking never takes the only one. A map with nothing uniform to copy is left at the size it was drawn, and says so.

Leave the line out and the map is the size you drew it.

## Colour

Nothing here carries meaning by colour. Terrain is told apart by pattern — hatching, dots, waves, a mesh, nothing at all — and a thing by silhouette: a ring, a box, a diamond, a triangle, a broken box. The map draws in one ink and reads the same in grayscale, which is the point: a reader who cannot tell two hues apart, or who prints in black and white, loses nothing.

**That is also the ceiling on new kinds.** Patterns and silhouettes have to stay apart at a square's size, and these twelve use up the ones that do. Another kind would mean a mark too close to one already here, so the next distinction belongs in a label — `object` covers a cart and a cauldron alike — rather than in a thirteenth kind.

## How it prints

The map on the page is a widget: an SVG plan with the DM's layer on it, each thing that names a page a link to it, and a Markdown face that is the same plan with that layer left off. The key is inside the drawing either way, so there is one figure to place and nothing to keep in step with it.

That Markdown face is what [GM Book](<GM Book>) puts in both editions, and what GM Kit publishes to the players. So **a map the players can be handed is what a map prints anyway**, in the book and on their own wiki, with nothing having to be stripped out of it. The map's own page is the exception: its map block is the DM's layer written out, so GM Kit 3.2 keeps a map page to the DM, and the players get the map where a page of theirs draws it. Every thing's square is drawn as the ground around it, so that map has no square left looking different where a creature or a trapdoor was.

**A scene wants the map twice.** An expression prints the same in both editions, so an edition can't have a map of its own; DM-only text is what tells the two apart. Draw the map where the scene describes the ground, and draw it again with the DM's layer on it in a DM callout right under it:

    ## The ground

    ${maps.draw("World/Maps/The Old Orchard")}

    > **dm** Where they start
    > ${maps.draw("World/Maps/The Old Orchard", { dm = true })}

GM Kit 3.1 and GM Book 1.8 leave a DM callout out of everything the players get. With older versions, put the second map under a `## DM Only` heading at the foot of the page instead.

The DM's edition then carries both: the map to run the fight from, and the clean one to turn round and show the table. The players' edition and their wiki carry only the clean one, and whether they ever see it is a decision, not something the library makes for you.

The SVG declares its own width and height, key included, so GM Book 1.7 or later measures it and breaks the page around it. A map is never taller than a column; one drawn larger is scaled down to fit. `maps.legendMarkdown` gives the same lines as text for a page that wants to say them in words as well.

| Option | Means |
|---|---|
| `dm` | The DM's layer — creatures and hidden things — in the printed map as well as on the page. Off by default. `tokens` was this option's name in 1.1, and still works |
| `legend` | The key inside the map. On by default |
| `width` | The map's width in px, for a map that should print narrower than a column |

## Settings

    config.set("gmMaps", {
      type = "map",
      scale = 5,
      units = "ft",
      width = 319,
    })

`type` is the page type that holds a map. `scale` is how many feet a square is, and `units` what to call them. `width` is a column of the book in px, which is what a map is drawn to fit.

## Implementation

```space-lua
-- priority: 10
maps = maps or {}

maps.config = {
  type  = "map",   -- the page type that holds a map
  scale = 5,       -- feet to a square
  units = "ft",    -- what to call them
  width = 319,     -- a column of the book, in px
}

function maps.setting(key)
  local value = config.get("gmMaps." .. key, nil)
  if value == nil then value = maps.config[key] end
  return value
end

------------------------------------------------------------------ the pages

-- Every map page in the space, by name and by the tail of its path, so a
-- path written for an adventure folder finds the page in a space that holds
-- that folder. Read at most once every two seconds.
function maps.all()
  local now = os.time()
  if maps.cached and now - maps.cached.at < 2 then return maps.cached.value end
  local kind = maps.setting("type")
  local pages = query[[
    from p = index.pages()
    where p.type == kind
    order by p.name
  ]]
  local byName, byTail = {}, {}
  for _, p in ipairs(pages) do
    byName[p.name] = p
    -- a tail two pages share is no use for finding either
    local parts = {}
    for part in p.name:gmatch("[^/]+") do parts[#parts + 1] = part end
    local tail = ""
    for i = #parts, 1, -1 do
      tail = parts[i] .. (tail == "" and "" or ("/" .. tail))
      byTail[tail] = byTail[tail] == nil and p or false
    end
  end
  -- the adventure's folder, for a path a copy elsewhere makes ambiguous:
  -- worked out here, once, rather than on every look that misses
  local root = gmbook and gmbook.root and gmbook.root() or ""
  local value = { byName = byName, byTail = byTail, root = root }
  maps.cached = { at = now, value = value }
  return value
end

-- Forget the pages read last, so the next map reads them again.
function maps.refresh()
  maps.cached = nil
end

-- The map page a path names, or nil. A path written for the adventure's
-- folder finds its page there first, so a copy of the page elsewhere, such
-- as one published to the players, can't make the path ambiguous.
function maps.find(ref)
  if type(ref) ~= "string" or ref == "" then return nil end
  local all = maps.all()
  local found = all.byName[ref] or all.byTail[ref]
  if found then return found end
  return all.root ~= "" and all.byName[all.root .. ref] or nil
end

-- The page a map reads with no page of its own: the one being printed
-- during a build or for the players, or the one open.
function maps.here()
  return (gmbook and gmbook.printing) or (gm and gm.printing) or editor.getCurrentPage()
end

------------------------------------------------------------------ the source

-- Every ${...} in a map's source evaluated, so a grow line can take its
-- number from GM Party. Anything that doesn't evaluate is left as it stands.
local function expand(text, printing)
  if not text:find("${", 1, true) then return text end
  local out, i = {}, 1
  while true do
    local s = text:find("${", i, true)
    if not s then break end
    local depth, j, e = 0, s + 1, nil
    while j <= #text do
      local c = text:sub(j, j)
      if c == "{" then
        depth = depth + 1
      elseif c == "}" then
        depth = depth - 1
        if depth == 0 then
          e = j
          break
        end
      end
      j = j + 1
    end
    if not e then break end
    out[#out + 1] = text:sub(i, s - 1)
    local src = text:sub(s + 2, e - 1)
    -- during a build the printers stand in, so a grow line that asks GM
    -- Party for a number gets the adventure's and not tonight's table's
    local aug = (printing or (gmbook and gmbook.printing)) and gmbook and gmbook.printers or nil
    local ok, value = pcall(function()
      return spacelua.evalExpression(spacelua.parseExpression(src), aug)
    end)
    if ok and (type(value) == "string" or type(value) == "number") then
      out[#out + 1] = tostring(value)
    else
      out[#out + 1] = text:sub(s, e)
    end
    i = e + 1
  end
  out[#out + 1] = text:sub(i)
  return table.concat(out)
end

-- The map block out of a page: the first fenced block marked "map".
local function block(text)
  return text:match("\n```map\n(.-)\n```") or text:match("^```map\n(.-)\n```")
end

-- Every kind of square, in four families. Terrain fills a square; a way
-- through is a mark in a gap in a wall; a thing is its legend letter in a
-- silhouette, and the silhouette is what tells one from another, so they
-- stay apart in one ink and in grayscale.
local KINDS = {
  wall = true, floor = true, rough = true, water = true, pit = true,  -- terrain
  exit = true, door = true,                                           -- ways through
  token = true, object = true, control = true, treasure = true,       -- things
  hidden = true,
}

-- What only the DM sees: a map drawn without its DM layer is one the
-- players can be handed.
local SECRET = { token = true, hidden = true }

-- A thing stands on ground, so the ground is drawn under it, and a thing is
-- never what the ground of a map is taken to be.
local THING = {
  token = true, object = true, control = true, treasure = true, hidden = true,
}

local KEYWORDS = { grow = true, scale = true, units = true, title = true }

-- Whether a line is a declaration rather than a row of the grid. A blank
-- line is what really separates the two, and this only decides a block
-- written without one, so it is strict on purpose: a keyword and its
-- argument, or a character and a kind this library knows. Anything else is
-- part of the picture. A looser rule read a grid row with a space in its
-- second column, or one that happened to spell "grow", as a declaration,
-- and threw away the rest of the map.
local function declares(l)
  local word = l:match("^(%a+)%s")
  if word and KEYWORDS[word] then return true end
  local kind = l:match("^%S%s+(%a+)%s")
  return kind ~= nil and KINDS[kind:lower()] == true
end

-- The few words that go beside a thing on the map, so the drawing says what
-- something is instead of sending the reader to the key for it. Taken from
-- the start of the line, up to the first comma or dash, and only when that
-- is short enough to draw; a longer one is named in brackets or left off.
-- Counted in words, never in characters: a character count is bytes in one
-- Lua and UTF-16 units in the other, and the two would draw differently.
local function shortLabel(text, given)
  local head = given
  if not head then
    head = text
    for _, mark in ipairs({ ",", " — ", " - " }) do
      local at = head:find(mark, 1, true)
      if at then head = head:sub(1, at - 1) end
    end
  end
  head = (head:gsub("^%s+", ""))
  head = (head:gsub("%s+$", ""))
  -- It has to fit inside a square, which at five feet to a square is about
  -- twelve characters of it. The pattern admits only ASCII, which is what
  -- makes the length safe to count: bytes and UTF-16 units agree there,
  -- and a label that measured differently in the two Luas would draw
  -- differently in a build than on the wiki.
  if not head:match("^[%w][%w%s%-'%.]*$") then return nil end
  if #head > 12 then return nil end
  local words = 0
  for _ in head:gmatch("%S+") do words = words + 1 end
  if words == 0 or words > 2 then return nil end
  return head
end

-- A legend line is a single character, then its kind, then an optional
-- label for the map in brackets, then what it is, and a page after the
-- last " = ".
local function legendLine(char, rest)
  local kind, text = rest:match("^(%a+)%s+(.*)$")
  local warn
  if kind and KINDS[kind:lower()] then
    kind = kind:lower()
  else
    kind, text = "floor", rest
    warn = "No kind for " .. char .. ", so it is drawn as open floor."
  end
  local given = text and text:match("^%[([^%]]*)%]%s*")
  if given then
    text = (text:gsub("^%[[^%]]*%]%s*", ""))
    if given == "" then given = nil end
  end
  local page, cut, at = nil, nil, 1
  while true do
    local s = text:find(" = ", at, true)
    if not s then break end
    cut, at = s, s + 1
  end
  if cut then
    page = (text:sub(cut + 3):gsub("%s+$", ""))
    text = (text:sub(1, cut - 1):gsub("%s+$", ""))
  end
  local label = THING[kind] and shortLabel(text, given) or nil
  -- A thing on the map is named on the map. Where the line does not start
  -- with something short enough to draw, say so rather than quietly
  -- leaving the square as a bare letter: what a map is worth depends on
  -- what is written for it, so this is the place to ask for it.
  if THING[kind] and not label and not warn then
    warn = "Nothing short enough to write beside " .. char ..
      " on the map. Give it a label in brackets: " .. char .. " " .. kind .. " [a name] ..."
  end
  return { char = char, kind = kind, text = text, page = page, label = label }, warn
end

-- A map's source read: its grid as rows of characters, the legend by
-- character, the order it was written in, and what else it was told.
function maps.parse(source, printing)
  local rows, legend, order, warn = {}, {}, {}, {}
  local grow, title = nil, nil
  local scale, units = maps.setting("scale"), maps.setting("units")
  local inGrid = true
  for line in (expand(source or "", printing) .. "\n"):gmatch("([^\n]*)\n") do
    local l = (line:gsub("%s+$", ""))
    l = (l:gsub("^%s+", ""))
    if l == "" then
      if #rows > 0 then inGrid = false end
    elseif inGrid and not declares(l) then
      rows[#rows + 1] = l
    else
      inGrid = false
      local word = l:match("^(%a+)%s")
      local char, rest = l:match("^(%S)%s+(.*)$")
      if word == "grow" then
        grow = tonumber(l:match("to%s+(%-?%d+)"))
        if not grow then
          warn[#warn + 1] = "A grow line needs a number of squares across: " .. l
        end
      elseif word == "scale" then
        scale = tonumber(l:match("^scale%s+(%d+%.?%d*)")) or scale
      elseif word == "units" then
        units = l:match("^units%s+(%S+)") or units
      elseif word == "title" then
        title = l:match("^title%s+(.*)$")
      elseif char and rest then
        local entry, w = legendLine(char, rest)
        if w then warn[#warn + 1] = w end
        if legend[char] then
          warn[#warn + 1] = "Two legend lines for " .. char .. "; the last one wins."
        else
          order[#order + 1] = char
        end
        legend[char] = entry
      else
        warn[#warn + 1] = "Not a legend line: " .. l
      end
    end
  end
  return { rows = rows, legend = legend, order = order, grow = grow,
           scale = scale, units = units, title = title, warn = warn }
end

------------------------------------------------------------------ the size

-- The grid as a rectangle of characters, every row padded to the longest.
local function rectangle(rows)
  local width = 0
  for _, r in ipairs(rows) do if #r > width then width = #r end end
  local grid = {}
  for i, r in ipairs(rows) do
    local row = {}
    for c = 1, width do
      local ch = r:sub(c, c)
      row[c] = ch == "" and " " or ch
    end
    grid[i] = row
  end
  return grid, width
end

-- Whether a square is plain ground, and so safe to copy or to take away with
-- its row or column. Only terrain is: growing a map must not put a second of
-- a creature on it, or a second door, lever or chest, and shrinking one must
-- not take the only one away.
local function plain(m, ch)
  local e = m.legend[ch]
  local kind = e and e.kind or "floor"
  return not THING[kind] and kind ~= "exit" and kind ~= "door"
end

-- A row is safe to copy or to drop when its squares inside the walls are
-- all the same, and nothing anywhere along it is a creature or a way out.
-- The ends matter as much as the middle: a column whose interior is plain
-- floor can still carry the gap in the wall at its top, so copying it would
-- put a second way out on the map, and dropping it would wall the party in.
-- Leaving a creature's row out of this keeps growing a map from putting a
-- second one of that creature on it.
local function uniformRow(m, grid, r)
  local w = #grid[1]
  if r <= 1 or r >= #grid or w < 3 then return false end
  for c = 1, w do
    if not plain(m, grid[r][c]) then return false end
  end
  for c = 3, w - 1 do
    if grid[r][c] ~= grid[r][2] then return false end
  end
  return true
end

local function uniformCol(m, grid, c)
  local w = #grid[1]
  if c <= 1 or c >= w or #grid < 3 then return false end
  for r = 1, #grid do
    if not plain(m, grid[r][c]) then return false end
  end
  for r = 3, #grid - 1 do
    if grid[r][c] ~= grid[2][c] then return false end
  end
  return true
end

-- The uniform interior row or column nearest the middle, or nil.
local function nearestRow(m, grid)
  local mid, best = (#grid + 1) / 2, nil
  for r = 2, #grid - 1 do
    if uniformRow(m, grid, r) and (not best or math.abs(r - mid) < math.abs(best - mid)) then
      best = r
    end
  end
  return best
end

local function nearestCol(m, grid)
  local mid, best = (#grid[1] + 1) / 2, nil
  for c = 2, #grid[1] - 1 do
    if uniformCol(m, grid, c) and (not best or math.abs(c - mid) < math.abs(best - mid)) then
      best = c
    end
  end
  return best
end

-- Grows or shrinks the grid to width squares across, around its middle, by
-- copying the nearest uniform row and column or taking them away. A copy is
-- laid in at the middle, one above it and the next below, so whatever sits
-- at the centre stays there and whatever sits against a wall stays against
-- it. Returns the grid and whether it reached the size asked for.
function maps.resize(m, grid, width)
  local ok = true
  local above = true
  while #grid < width do
    local f = nearestRow(m, grid)
    if not f then
      ok = false
      break
    end
    local copy = {}
    for i, ch in ipairs(grid[f]) do copy[i] = ch end
    local centre = math.floor((#grid + 1) / 2)
    table.insert(grid, above and centre or centre + 1, copy)
    above = not above
  end
  while #grid > width do
    local f = nearestRow(m, grid)
    if not f then
      ok = false
      break
    end
    table.remove(grid, f)
  end
  above = true
  while #grid[1] < width do
    local f = nearestCol(m, grid)
    if not f then
      ok = false
      break
    end
    local centre = math.floor((#grid[1] + 1) / 2)
    local at = above and centre or centre + 1
    for _, row in ipairs(grid) do table.insert(row, at, row[f]) end
    above = not above
  end
  while #grid[1] > width do
    local f = nearestCol(m, grid)
    if not f then
      ok = false
      break
    end
    for _, row in ipairs(grid) do table.remove(row, f) end
  end
  return grid, ok
end

-- The map's grid at the size it should be drawn, with a note when it could
-- not reach the size asked for.
function maps.grid(m)
  local grid = (rectangle(m.rows))
  if #grid == 0 then return grid, nil end
  if not m.grow then return grid, nil end
  local target = math.max(3, math.floor(m.grow))
  local sized, ok = maps.resize(m, grid, target)
  if ok then return sized, nil end
  return sized, "The map has no uniform row or column left to grow by, so it stays as drawn."
end

------------------------------------------------------------------ the drawing

local function esc(s)
  s = tostring(s):gsub("&", "&amp;")
  s = s:gsub("<", "&lt;")
  s = s:gsub(">", "&gt;")
  s = s:gsub('"', "&quot;")
  return s
end

-- A number for the SVG, written the same by every Lua. SilverBullet's
-- numbers are JavaScript's and print 274, stock Lua's print 274.0, and a
-- built edition has to come out byte for byte the same either way, so the
-- text is built out of integers rather than left to tostring.
local function round(n)
  local neg = n < 0
  local scaled = math.floor(math.abs(n) * 100 + 0.5)
  local whole = math.floor(scaled / 100)
  local frac = scaled - whole * 100
  local out = tostring(math.floor(whole))
  if frac > 0 then
    if frac % 10 == 0 then
      out = out .. "." .. tostring(math.floor(frac / 10))
    elseif frac < 10 then
      out = out .. ".0" .. tostring(math.floor(frac))
    else
      out = out .. "." .. tostring(math.floor(frac))
    end
  end
  return (neg and out ~= "0") and ("-" .. out) or out
end

-- The ground a creature stands on: the commonest square in the map that is
-- not a creature or a way out. A token's square is drawn as this and the
-- creature on top of it, so the map without its creatures has no bare
-- squares left where they were standing.
local function ground(m, grid)
  local count = {}
  for _, row in ipairs(grid) do
    for _, ch in ipairs(row) do
      local e = m.legend[ch]
      local kind = e and e.kind or "floor"
      -- a wall is never it: nothing stands on a wall, and on a map with a
      -- thick frame the wall is the commonest square there is
      if not THING[kind] and kind ~= "exit" and kind ~= "door" and kind ~= "wall" then
        count[ch] = (count[ch] or 0) + 1
      end
    end
  end
  -- the legend's order first, then the rest in order, so a tie always
  -- breaks the same way and the same map always draws the same
  local order, seen = {}, {}
  for _, ch in ipairs(m.order) do
    if count[ch] and not seen[ch] then
      order[#order + 1] = ch
      seen[ch] = true
    end
  end
  local rest = {}
  for ch in pairs(count) do
    if not seen[ch] then rest[#rest + 1] = ch end
  end
  table.sort(rest)
  for _, ch in ipairs(rest) do order[#order + 1] = ch end
  local best, most = nil, 0
  for _, ch in ipairs(order) do
    if count[ch] > most then best, most = ch, count[ch] end
  end
  return best
end

-- The ground under one thing: what lies around it. A crate in the water
-- stands on water and a crate on the floor stands on floor, so the square
-- is drawn from its neighbours rather than from the map as a whole, and a
-- map without its DM layer has nothing out of place where a thing was.
local function groundAt(m, grid, r, c, fallback)
  local count = {}
  local function look(rr, cc)
    local row = grid[rr]
    local ch = row and row[cc]
    if not ch then return end
    local e = m.legend[ch]
    local kind = e and e.kind or "floor"
    if THING[kind] or kind == "exit" or kind == "door" or kind == "wall" then return end
    count[ch] = (count[ch] or 0) + 1
  end
  look(r - 1, c)
  look(r + 1, c)
  look(r, c - 1)
  look(r, c + 1)
  local best, most = nil, 0
  for _, ch in ipairs(m.order) do          -- the legend's order breaks a tie
    if (count[ch] or 0) > most then best, most = ch, count[ch] end
  end
  return best or fallback
end

-- A name for this map's patterns, unique on a page that carries two maps.
-- An id in SVG is document-wide, so two maps sharing one would draw the
-- second with the first's patterns. Taken from the grid and the legend's
-- keys, which are ASCII, so the same map always gets the same id and a
-- built edition stays byte for byte what it was.
local function patternId(m, grid, tokens)
  local h = 5381
  local function feed(s)
    for i = 1, #s do
      h = (h * 33 + s:byte(i)) % 4294967296
    end
  end
  for _, row in ipairs(grid) do feed(table.concat(row)) end
  for _, ch in ipairs(m.order) do
    feed(ch)
    feed(m.legend[ch].kind)
  end
  feed(tokens and "t" or "-")
  return string.format("gmm%x", h)
end

-- Where a token's Bestiary page lives, and its URL on this wiki.
local function tokenPage(page)
  if not page then return nil, nil end
  local name = page
  if bestiary and bestiary.creature then
    local ok, c = pcall(function() return bestiary.creature(page) end)
    if ok and c then name = c.page end
  end
  local ok, url = pcall(function()
    local prefix = system.getURLPrefix() or "/"
    local encoded = js.window.encodeURIComponent(name)
    return prefix .. (encoded:gsub("%%2F", "/"))
  end)
  return name, ok and url or nil
end

-- The patterns that tell one kind of square from another without colour: a
-- hatch for walls, a stipple for difficult ground.
-- One pair of patterns at the scale of a square, and a second at the scale
-- of a key swatch, so a swatch a few px across still shows enough hatching
-- and enough dots to read as the squares it stands for.
local function patterns(size, ink, id, suffix)
  local h = round(size / 4)
  local m = size / 2.6                  -- the mesh a pit is drawn with
  local w = size / 2.2                  -- one wave of water
  return table.concat {
    -- a wall: close diagonal lines, the densest mark on the map
    '<pattern id="', id, '-hatch', suffix, '" width="', h, '" height="', h,
      '" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">',
      '<line x1="0" y1="0" x2="0" y2="', h, '" stroke="', ink,
      '" stroke-width="', round(size / 11), '"/></pattern>',
    -- difficult ground: fine dots
    '<pattern id="', id, '-stipple', suffix, '" width="', round(size / 3),
      '" height="', round(size / 3), '" patternUnits="userSpaceOnUse">',
      '<circle cx="', round(size / 6), '" cy="', round(size / 6), '" r="',
      round(size / 20), '" fill="', ink, '" opacity="0.6"/></pattern>',
    -- a pit: the same diagonal crossed, and drawn open and thin, so it
    -- reads as a mesh you could fall through against a wall's solid hatch
    '<pattern id="', id, '-cross', suffix, '" width="', round(m), '" height="', round(m),
      '" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">',
      '<line x1="0" y1="0" x2="0" y2="', round(m), '" stroke="', ink,
      '" stroke-width="', round(size / 26), '"/>',
      '<line x1="0" y1="0" x2="', round(m), '" y2="0" stroke="', ink,
      '" stroke-width="', round(size / 26), '"/></pattern>',
    -- water: waves across, which no other mark here looks like
    '<pattern id="', id, '-wave', suffix, '" width="', round(w), '" height="', round(w / 2),
      '" patternUnits="userSpaceOnUse">',
      '<path d="M0,', round(w / 4), ' Q', round(w / 4), ',0 ', round(w / 2), ',', round(w / 4),
      ' T', round(w), ',', round(w / 4), '" fill="none" stroke="', ink,
      '" stroke-width="', round(size / 24), '" opacity="0.85"/></pattern>',
  }
end

local function defs(cell, key, ink, id)
  return table.concat {
    "<defs>", patterns(cell, ink, id, ""), patterns(key, ink, id, "k"), "</defs>",
  }
end

-- An exit's arrow, pointing out of the map through the wall it sits in.
-- An arrow through a square, pointing the way dx, dy says.
local function arrowAt(cx, cy, s, dx, dy, ink, weight)
  local tx, ty = cx + dx * s, cy + dy * s
  local bx, by = cx - dx * s, cy - dy * s
  local px, py = -dy * s * 0.8, dx * s * 0.8
  local nx, ny = tx - dx * s * 0.8, ty - dy * s * 0.8
  return table.concat {
    '<line x1="', round(bx), '" y1="', round(by), '" x2="', round(tx), '" y2="', round(ty),
      '" stroke="', ink, '" stroke-width="', round(weight), '" stroke-linecap="round"/>',
    '<polygon points="', round(tx), ",", round(ty), " ", round(nx + px), ",", round(ny + py),
      " ", round(nx - px), ",", round(ny - py), '" fill="', ink, '"/>',
  }
end

-- Which way a way out leads: out through the wall it sits in.
local function exitDir(r, c, rows, cols)
  if r == rows then return 0, 1 end
  if c == 1 then return -1, 0 end
  if c == cols then return 1, 0 end
  return 0, -1
end

-- A creature: its legend letter in a ring, the same at any size, so the key
-- shows exactly what stands on the map.
local function ringed(cx, cy, size, ch, ink)
  return table.concat {
    '<circle cx="', round(cx), '" cy="', round(cy), '" r="', round(size * 0.33),
      '" fill="#ffffff" stroke="', ink, '" stroke-width="', round(size / 13), '"/>',
    '<text x="', round(cx), '" y="', round(cy + size * 0.14), '" text-anchor="middle" fill="', ink,
      '" font-family="Georgia, serif" font-size="', round(size * 0.44), '">', esc(ch), "</text>",
  }
end

-- A thing rather than a creature: the same letter in a box. Shape is what
-- tells the two apart, so they stay apart in grayscale. A hidden one is
-- drawn with a broken edge, which reads as not-apparent without needing a
-- second colour or a second shape.
local function boxed(cx, cy, size, ch, ink, dashed)
  local s = size * 0.62
  return table.concat {
    '<rect x="', round(cx - s / 2), '" y="', round(cy - s / 2), '" width="', round(s),
      '" height="', round(s), '" fill="#ffffff" stroke="', ink,
      '" stroke-width="', round(size / 13), '"',
      dashed and (' stroke-dasharray="' .. round(size / 7) .. " " .. round(size / 11) .. '"') or "",
      "/>",
    '<text x="', round(cx), '" y="', round(cy + size * 0.14), '" text-anchor="middle" fill="', ink,
      '" font-family="Georgia, serif" font-size="', round(size * 0.44), '">', esc(ch), "</text>",
  }
end

-- A thing worth taking: a chest, a prize, a strongbox. A triangle, the
-- last silhouette in this set that is unmistakable at a square's size; the
-- letter sits low in it, where a triangle has room for one.
local function wedge(cx, cy, size, ch, ink)
  local s = size * 0.3
  return table.concat {
    '<polygon points="', round(cx), ",", round(cy - s * 1.15), " ",
      round(cx + s * 1.1), ",", round(cy + s * 0.8), " ",
      round(cx - s * 1.1), ",", round(cy + s * 0.8),
      '" fill="#ffffff" stroke="', ink, '" stroke-width="', round(size / 13), '"/>',
    -- a triangle is widest at its foot, so the letter sits low, and smaller
    '<text x="', round(cx), '" y="', round(cy + size * 0.19), '" text-anchor="middle" fill="', ink,
      '" font-family="Georgia, serif" font-size="', round(size * 0.29), '">', esc(ch), "</text>",
  }
end

-- A thing you work rather than a thing that is there: a lever, a button, a
-- handle, a valve. A diamond, because a silhouette tells itself apart from
-- a ring and a box at any size and in any ink.
local function diamond(cx, cy, size, ch, ink)
  local s = size * 0.33
  return table.concat {
    '<polygon points="', round(cx), ",", round(cy - s), " ", round(cx + s), ",", round(cy),
      " ", round(cx), ",", round(cy + s), " ", round(cx - s), ",", round(cy),
      '" fill="#ffffff" stroke="', ink, '" stroke-width="', round(size / 13), '"/>',
    -- a diamond narrows away from its centre, so the letter sits smaller
    '<text x="', round(cx), '" y="', round(cy + size * 0.12), '" text-anchor="middle" fill="', ink,
      '" font-family="Georgia, serif" font-size="', round(size * 0.33), '">', esc(ch), "</text>",
  }
end

-- Which pattern fills each kind of terrain. Open floor fills with nothing.
local FILL = {
  wall = "-hatch", rough = "-stipple", pit = "-cross", water = "-wave",
}

-- A thing, in the silhouette its kind is drawn with. Every one of them is
-- drawn inside the same box, so a silhouette fits wherever another does --
-- in a square of the grid, and in a swatch of the key.
local function thing(kind, cx, cy, size, ch, ink)
  if kind == "token" then return ringed(cx, cy, size, ch, ink) end
  if kind == "control" then return diamond(cx, cy, size, ch, ink) end
  if kind == "treasure" then return wedge(cx, cy, size, ch, ink) end
  return boxed(cx, cy, size, ch, ink, kind == "hidden")
end

-- A door: a bar across the gap, athwart the way through, so it reads as a
-- way that can be shut rather than a way out.
local function doorBar(cx, cy, s, dx, dy, ink, weight)
  local px, py = -dy * s, dx * s
  return table.concat {
    '<line x1="', round(cx - px), '" y1="', round(cy - py), '" x2="', round(cx + px),
      '" y2="', round(cy + py), '" stroke="', ink, '" stroke-width="', round(weight),
      '" stroke-linecap="round"/>',
  }
end

-- A label broken to fit, at about this font's average character width. An
-- estimate is enough: it only decides where a long line wraps, and it comes
-- out the same under every Lua, which is what a built edition needs.
local function wrapLabel(text, room, size)
  local per = math.max(8, math.floor(room / (size * 0.47)))
  if #text <= per then return { text } end
  local lines, line = {}, ""
  for word in text:gmatch("%S+") do
    if line == "" then
      line = word
    elseif #line + 1 + #word <= per then
      line = line .. " " .. word
    else
      lines[#lines + 1] = line
      line = word
    end
  end
  if line ~= "" then lines[#lines + 1] = line end
  return lines
end

-- The map as an SVG plan: the squares, the creatures if they are wanted, a
-- scale bar, and a key drawn with the same ink and the same patterns as the
-- squares it explains. Returns the SVG, its height and any note.
function maps.svg(m, opts)
  opts = opts or {}
  local grid, note = maps.grid(m)
  local rows = #grid
  local cols = rows > 0 and #grid[1] or 0
  if rows == 0 or cols == 0 then return nil, 0, note end
  local ink = opts.ink or "#111111"
  -- the DM's layer: creatures, and anything hidden. "tokens" was its name
  -- in 1.1, when creatures were the only thing it covered.
  local dm = opts.dm == true or opts.tokens == true
  local id = opts.id or patternId(m, grid, dm)
  local width = opts.width or maps.setting("width")
  local pad, foot = 1, 24
  local KEY_ROW, KEY_SWATCH, KEY_SIZE = 17, 15, 10.5

  -- what the key explains: every square the map actually draws, in the
  -- order the legend was written, with the creatures only where they show
  local keys = {}
  if opts.legend ~= false then
    local drawn = {}
    for r = 1, rows do
      for c = 1, cols do drawn[grid[r][c]] = true end
    end
    for _, ch in ipairs(m.order) do
      local e = m.legend[ch]
      if e and drawn[ch] and (dm or not SECRET[e.kind]) then
        keys[#keys + 1] = e
      end
    end
  end

  -- a whole number of px to a square, so every line in the drawing lands on
  -- an integer and the text of it is the same in any Lua
  local cell = math.min(34, math.floor((width - pad * 2) / cols))
  local max = opts.maxHeight or 860
  local function extra(n) return pad * 2 + foot + n * KEY_ROW end
  if cell * rows + extra(#keys) > max then
    cell = math.floor((max - extra(#keys)) / rows)
  end
  if cell < 6 then cell = 6 end
  local gw, gh = cell * cols, cell * rows
  -- the key gets the whole column to write in, however narrow the grid is
  local canvas = #keys > 0 and math.max(gw + pad * 2, width) or (gw + pad * 2)
  local out = {}
  local function put(...) out[#out + 1] = table.concat({...}) end
  local svgAt = #out + 1
  put("")  -- the opening tag, once the key has said how tall this is
  put(defs(cell, KEY_SWATCH, ink, id))
  local under = ground(m, grid)
  for r = 1, rows do
    for c = 1, cols do
      local ch = grid[r][c]
      local e = m.legend[ch]
      local kind = e and e.kind or "floor"
      -- a thing stands on the ground, so draw the ground under it: without
      -- this the map drawn without its DM layer has a bare square exactly
      -- where the thing was
      if THING[kind] then
        local g = m.legend[groundAt(m, grid, r, c, under)]
        kind = g and g.kind or "floor"
      end
      local x, y = round(pad + (c - 1) * cell), round(pad + (r - 1) * cell)
      local fill = FILL[kind]
      if fill then
        put('<rect x="', x, '" y="', y, '" width="', round(cell), '" height="', round(cell),
            '" fill="url(#', id, fill, ')"/>')
      end
    end
  end
  put('<g stroke="', ink, '" stroke-width="0.4" opacity="0.4">')
  for c = 0, cols do
    put('<line x1="', round(pad + c * cell), '" y1="', round(pad), '" x2="', round(pad + c * cell),
        '" y2="', round(pad + gh), '"/>')
  end
  for r = 0, rows do
    put('<line x1="', round(pad), '" y1="', round(pad + r * cell), '" x2="', round(pad + gw),
        '" y2="', round(pad + r * cell), '"/>')
  end
  put("</g>")
  for r = 1, rows do
    for c = 1, cols do
      local ch = grid[r][c]
      local e = m.legend[ch]
      local kind = e and e.kind or "floor"
      local x, y = pad + (c - 1) * cell, pad + (r - 1) * cell
      if kind == "exit" or kind == "door" then
        local dx, dy = exitDir(r, c, rows, cols)
        local cx, cy = x + cell / 2, y + cell / 2
        if kind == "exit" then
          put(arrowAt(cx, cy, cell * 0.32, dx, dy, ink, cell / 11))
        else
          put(doorBar(cx, cy, cell * 0.34, dx, dy, ink, cell / 9))
        end
      elseif THING[kind] and (dm or not SECRET[kind]) then
        local body = thing(kind, x + cell / 2, y + cell / 2, cell, ch, ink)
        -- and what it is, under it, so the drawing says so itself. Only
        -- where a square is big enough to carry the words.
        if e.label and cell >= 22 then
          body = body .. table.concat {
            '<text class="gmm-label" x="', round(x + cell / 2), '" y="', round(y + cell * 0.97),
              '" text-anchor="middle" fill="', ink,
              '" font-family="Georgia, serif" font-size="', round(cell * 0.23),
              '" opacity="0.9">', esc(e.label), "</text>",
          }
        end
        local _, url = tokenPage(e.page)
        if url and opts.link then
          put('<a href="', esc(url), '"><title>', esc(e.text), "</title>", body, "</a>")
        else
          put("<g><title>", esc(e.text), "</title>", body, "</g>")
        end
      end
    end
  end
  put('<rect x="', round(pad), '" y="', round(pad), '" width="', round(gw), '" height="', round(gh),
      '" fill="none" stroke="', ink, '" stroke-width="1.2"/>')
  local by, bx = pad + gh + 14, pad
  put('<g stroke="', ink, '" stroke-width="1">')
  put('<line x1="', round(bx), '" y1="', round(by), '" x2="', round(bx + cell),
      '" y2="', round(by), '"/>')
  put('<line x1="', round(bx), '" y1="', round(by - 3), '" x2="', round(bx),
      '" y2="', round(by + 3), '"/>')
  put('<line x1="', round(bx + cell), '" y1="', round(by - 3), '" x2="', round(bx + cell),
      '" y2="', round(by + 3), '"/>')
  put("</g>")
  put('<text x="', round(bx + cell + 5), '" y="', round(by + 4), '" fill="', ink,
      '" font-family="Georgia, serif" font-size="9.5">',
      esc(round(m.scale) .. " " .. m.units .. " to a square"), "</text>")
  put('<text x="', round(pad + gw), '" y="', round(by + 4), '" text-anchor="end" fill="', ink,
      '" font-family="Georgia, serif" font-size="9.5">',
      esc(round(cols * m.scale) .. " " .. m.units .. " across"), "</text>")

  -- The key. Each row shows the square as the map draws it, because the
  -- character in the source is not on the drawing: a hatched swatch for a
  -- wall, a stippled one for difficult ground, the arrow for a way out, the
  -- creature's own ring and letter. Nothing here asks the reader to match a
  -- symbol they cannot see.
  local y = pad + gh + foot
  for _, e in ipairs(keys) do
    local cy = y + KEY_SWATCH / 2
    local swatch
    local function box(fill)
      return table.concat {
        fill and table.concat {
          '<rect x="', round(pad), '" y="', round(y), '" width="', round(KEY_SWATCH),
            '" height="', round(KEY_SWATCH), '" fill="url(#', id, fill, 'k)"/>',
        } or "",
        '<rect x="', round(pad), '" y="', round(y), '" width="', round(KEY_SWATCH),
          '" height="', round(KEY_SWATCH), '" fill="none" stroke="', ink,
          '" stroke-width="0.6" opacity="0.5"/>',
      }
    end
    if FILL[e.kind] then
      swatch = box(FILL[e.kind])
    elseif e.kind == "exit" or e.kind == "door" then
      -- the arrow points the way this map's own gap points
      local dx, dy = 0, -1
      for r = 1, rows do
        for c = 1, cols do
          if grid[r][c] == e.char then dx, dy = exitDir(r, c, rows, cols) end
        end
      end
      if e.kind == "exit" then
        swatch = arrowAt(pad + KEY_SWATCH / 2, cy, KEY_SWATCH * 0.36, dx, dy, ink, 1.6)
      else
        swatch = doorBar(pad + KEY_SWATCH / 2, cy, KEY_SWATCH * 0.38, dx, dy, ink, 1.9)
      end
    elseif THING[e.kind] then
      swatch = thing(e.kind, pad + KEY_SWATCH / 2, cy, KEY_SWATCH * 1.45, e.char, ink)
    else
      swatch = box(nil)
    end
    local left = pad + KEY_SWATCH + 6
    local lines = wrapLabel(e.text, canvas - left - pad, KEY_SIZE)
    local label = {}
    for i, line in ipairs(lines) do
      label[#label + 1] = table.concat {
        '<text class="gmm-key" x="', round(left),
          '" y="', round(cy + 3.5 + (i - 1) * (KEY_SIZE + 1.5)),
          '" fill="', ink, '" font-family="Georgia, serif" font-size="', round(KEY_SIZE), '">',
          esc(line), "</text>",
      }
    end
    label = table.concat(label)
    if e.kind == "token" and opts.link then
      local _, href = tokenPage(e.page)
      if href then
        put('<a href="', esc(href), '">', swatch, label, "</a>")
      else
        put(swatch, label)
      end
    else
      put(swatch, label)
    end
    y = y + KEY_ROW + (#lines - 1) * (KEY_SIZE + 1.5)
  end

  local height = #keys > 0 and (y + pad) or (gh + pad * 2 + foot)
  out[svgAt] = table.concat {
    '<svg xmlns="http://www.w3.org/2000/svg" width="', round(canvas),
    '" height="', round(height), '" viewBox="0 0 ', round(canvas), " ", round(height),
    '" style="display:block" role="img" aria-label="', esc(m.title or "Encounter map"), '">',
  }
  put("</svg>")
  return table.concat(out), round(height), note
end

------------------------------------------------------------------ the legend

-- The legend as text, for a page that wants to say in words what the key
-- shows in ink: what each kind of square is, without the source character,
-- which is not on the drawing. The map itself no longer needs this.
function maps.legendMarkdown(m, opts)
  opts = opts or {}
  local lines = {}
  for _, ch in ipairs(m.order) do
    local e = m.legend[ch]
    if e and (opts.dm or opts.tokens or not SECRET[e.kind]) then
      lines[#lines + 1] = "- " .. e.text
    end
  end
  return table.concat(lines, "\n")
end

------------------------------------------------------------------ drawing one

local function missing(ref)
  local text = "No map page for " .. tostring(ref) .. "."
  return widget.new {
    html = '<em class="gmmaps-missing">' .. esc(text) .. "</em>",
    markdown = "*" .. text .. "*",
    display = "block",
  }
end

-- A map's source, read from its page: the block, and the page it came from.
function maps.source(ref)
  local name = ref or maps.here()
  if not name then return nil, nil end
  local page = maps.find(name)
  local text
  if page then
    text = space.readPage(page.name)
  else
    -- read it outright: space.pageExists would say yes to a page whose path
    -- only ends in the name, which space.readPage can't read
    local ok, t = pcall(space.readPage, name)
    text = ok and t or nil
  end
  if not text then return nil, nil end
  return block(text), (page and page.name) or name
end

-- The map on the page and in print, one drawing either way, with its key
-- inside it. On the page the creatures are on it and linked to their
-- Bestiary entries; in print they are left off unless the map is asked for
-- them, and a link would have nowhere to go.
function maps.draw(ref, opts)
  if type(ref) == "table" and opts == nil then ref, opts = nil, ref end
  opts = opts or {}
  local source = maps.source(ref)
  if not source then return missing(ref or maps.here()) end
  local m = maps.parse(source, opts.printing)
  local live, _, note = maps.svg(m, {
    dm = true, link = true, width = opts.width, legend = opts.legend,
  })
  if not live then return missing(ref or maps.here()) end
  local printed = (maps.svg(m, {
    dm = opts.dm == true or opts.tokens == true,
    link = false, width = opts.width, legend = opts.legend,
  }))

  local html = { '<div class="gmmaps">', live }
  for _, w in ipairs(m.warn) do
    html[#html + 1] = '<div class="gmmaps-warn">' .. esc(w) .. "</div>"
  end
  if note then html[#html + 1] = '<div class="gmmaps-warn">' .. esc(note) .. "</div>" end
  html[#html + 1] = "</div>"

  return widget.new {
    html = table.concat(html),
    markdown = printed,
    display = "block",
  }
end

------------------------------------------------------------------ in print

-- What a map prints as: the plan, without the creatures unless it is asked
-- for them, and its legend. GM Book evaluates an expression with maps
-- standing for this table, and finds it in gmbook.printers.
maps.printed = setmetatable({
  draw = function(ref, opts)
    local ask = { printing = true }
    for k, v in pairs(opts or {}) do ask[k] = v end
    local w = maps.draw(ref, ask)
    if type(w) == "table" and type(w.markdown) == "string" then return w.markdown end
    return nil
  end,
}, { __index = maps })

gmbook = gmbook or {}
gmbook.printers = gmbook.printers or {}
gmbook.printers.maps = maps.printed
```

```space-style
/* The map draws in one dark ink, which a dark theme would swallow, so on
   the page it sits on paper of its own. In print it stays transparent and
   the book's own page shows through. */
.gmmaps svg {
  max-width: 100%;
  height: auto;
  background: #faf7f0;
  border-radius: 2px;
  padding: 4px;
}

.gmmaps-legend {
  list-style: none;
  padding-left: 0;
  margin: 0.4em 0 0 0;
  font-size: 0.9em;
}

.gmmaps-legend li {
  margin: 0.1em 0;
}

.gmmaps-key {
  display: inline-block;
  min-width: 1.4em;
  font-family: var(--editor-code-font);
}

.gmmaps-warn,
.gmmaps-missing {
  color: var(--subtle-color);
}

.gmmaps-warn::before,
.gmmaps-missing::before {
  content: "⚠ ";
  font-style: normal;
}
```
