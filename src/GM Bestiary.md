---
tags: meta/library
name: "Library/Storie/GM Bestiary"
description: "Creature pages that point at official stat blocks: the reference links to a compendium on the page, and cites the book and its entry in print. Wires those pages to GM Party's fights."
author: "Steven Storie"
version: "1.3.0"
---

# GM Bestiary

Describe a creature once, on a page of its own, and say there which published stat block to run it with. On the page the reference is a link to the compendium you run from. In print it is a citation: the book and the entry that holds it, and never a URL.

Copying a stat block into your space is a licensing problem and a maintenance one at the same time. Naming it is what published adventures do, and it is enough: a monster book is alphabetical, so the book and the entry find it.

| On the page | In print |
|---|---|
| [Vine Blight](https://www.dndbeyond.com/monsters/5195252-vine-blight) — Monster Manual, *Blights* | Vine Blight — Monster Manual, *Blights* |

## A creature's page

A page with `type: monster` describes one creature. What it is and how it behaves is yours to write; the frontmatter says what to run it as.

    ---
    type: monster
    statblock: Vine Blight
    entry: Blights
    source: Monster Manual
    cr: "1/2"
    ddb: https://www.dndbeyond.com/monsters/5195252-vine-blight
    ---

| Key | Means |
|---|---|
| `statblock` | The published stat block to run it with. Leave it out for a creature with no official match |
| `entry` | The entry in the book that holds that stat block, where the book files it under another name: a vine blight is under *Blights*, a raven under *Animals* |
| `source` | The book it is in. The settings give the one to assume |
| `cr` | Its Challenge Rating, which a fight that uses it is checked against, by value: `0.125` and `"1/8"` are the same CR. A creature with a stat block for each of several levels lists them all: `cr: ["3", "5"]` |
| `ddb` | A link to it, for running from a screen: a web address, or its D&D Beyond id alone, `5195252`, which links to its page there. Anything else isn't linked, and the page says so |

Then, wherever the reference belongs on the page:

    ## Run it as

    ${bestiary.ref()}

`bestiary.ref()` reads the page it is on, and in print the page being printed. On the wiki it reads its own page even while a build is running. `bestiary.ref("World/Monsters/Strangler")` reads another, named as a link in the adventure would write it: a path written for an adventure folder also finds the page in a space that holds that folder.

**A creature with no official match** carries no `statblock`, and its reference reads *Original to this book.* Its stat block belongs on its own page.

## In a fight

GM Party 1.2 or later lets a creature in a fight name its page, and this library tells it what to print:

    ${party.fight { "The old orchard", level = 1, difficulty = "low",
      {1, "strangler", cr = "1/2", page = "World/Monsters/Strangler"},
      {6, "creeper", cr = "1/8", step = 2, min = 2, page = "World/Monsters/Creeper"},
    }}

The fight then carries a line of its own: links on the page, citations in print.

    **The creatures.** Strangler — Monster Manual, *Blights* (vine blight). Creeper — Monster Manual, *Blights* (twig blight).

The stat block's name comes after the citation when the fight calls the creature something else, which is the usual case for a creature the adventure has renamed. A fight whose `cr` disagrees with the one on the creature's page is flagged on the page, and so is a creature whose page isn't there.

**A creature at several levels.** GM Party 1.3 or later writes a fight in versions for the party's level, and a creature can be in more than one of them, stronger in each, like a lieutenant the party might meet early or late. Its page carries a stat block for each level, and its `cr` lists every CR it runs at:

    cr: ["3", "5"]

A fight that gives it any of those is fine. One that gives it another is flagged: "The barrow lord is CR 4 here, and CR 3 or 5 on Barrow Lord."

## Settings

    config.set("gmBestiary", {
      type = "monster",
      source = "Monster Manual",
      original = "original to this book",
      lowercase = true,
    })

`source` is the book to assume for a page that names none. `original` is what a creature with no official stat block reads as. `lowercase` writes a stat block's name in lower case where it appears inside a sentence, which suits creatures named as common nouns; set it false for a book whose creatures are named individuals.

## How it prints

The reference on the page is a widget: HTML with the compendium link, and a Markdown face with the same link, so a table, Copy, Baked Sections and GM Kit's publishing all keep it. GM Book 1.6.3 or later evaluates each expression with `bestiary` standing for `bestiary.printed`, which gives the citation without the URL. This library puts `bestiary.printed` in `gmbook.printers`, where GM Book looks for it, and sets `party.creatureRef`, where GM Party looks.

## A tab behind its space

A tab reads its libraries when it opens. If the space's GM Bestiary changes after that, from another tab, a sync or `Library: Install`, the tab goes on running the one it read. `bestiary.stale()` says so: nothing while the two agree, and otherwise

    This tab runs GM Bestiary 1.3.0, but the space has 1.4.0: reload it (System: Reload, Ctrl-Alt-R).

It reads the `version` of every page named `Library/Storie/GM Bestiary`, at any depth, from the index, and it never fails. GM Book asks before it builds. A reference on the page shows a line of its own over it, *⟳ Reload this tab*, with the two versions: on the page only, never in print or in the players' copies.

## Changes in 1.3

**A tab behind its space says so.** `bestiary.version` and `bestiary.stale()` say when the tab runs another GM Bestiary than the space holds, and a reference says so on a line of its own over it, on the page alone, never in print. See *A tab behind its space*.

## Changes in 1.2

**CRs are compared by value**, so a page's `cr: 0.125` agrees with a fight's `"1/8"`, and a warning writes a CR as the rules do. A `ddb` that is D&D Beyond's number for a monster links to its page there; anything else that isn't a web address gets no link, and a ⚠ on the page says so. A creature's reference drawn on the page while the book builds is drawn for that page, not the one being printed.

## Changes in 1.1

A creature page's `cr` can list several CRs, for a creature with a stat block for each of several levels, and a fight is checked against all of them.

## Implementation

```space-lua
-- priority: 10
bestiary = bestiary or {}
bestiary.version = "1.3.0"

bestiary.config = {
  type      = "monster",              -- the page type that describes a creature
  source    = "Monster Manual",       -- the book assumed for a page that names none
  original  = "original to this book",-- a creature with no official stat block
  lowercase = true,                   -- a stat block's name inside a sentence
}

function bestiary.setting(key)
  local value = config.get("gmBestiary." .. key, nil)
  if value == nil then value = bestiary.config[key] end
  return value
end

local function lower(s)
  if bestiary.setting("lowercase") then return s:lower() end
  return s
end

local function capital(s)
  return s:sub(1, 1):upper() .. s:sub(2)
end

------------------------------------------------------------------ this tab

-- A version as a page writes it: "1.2.0", or the number YAML reads 2 as.
local function versionText(v)
  if type(v) == "number" then
    if v == math.floor(v) then return string.format("%d", v) end
    return tostring(v)
  end
  if type(v) ~= "string" then return nil end
  local s = v:match("^%s*(.-)%s*$")
  if s == "" then return nil end
  return s
end

-- Versions in order, by the numbers in them: 1.9.0 before 1.10.0.
local function versionLess(a, b)
  local x, y = {}, {}
  for n in a:gmatch("%d+") do x[#x + 1] = tonumber(n) end
  for n in b:gmatch("%d+") do y[#y + 1] = tonumber(n) end
  for i = 1, math.max(#x, #y) do
    if (x[i] or -1) ~= (y[i] or -1) then return (x[i] or -1) < (y[i] or -1) end
  end
  return a < b
end

-- "a, b and c"
local function andList(list)
  local out = ""
  for i, s in ipairs(list) do
    if i == 1 then out = s
    elseif i == #list then out = out .. " and " .. s
    else out = out .. ", " .. s end
  end
  return out
end

-- The versions of GM Bestiary the space holds other than the one this tab
-- runs, older or newer: the frontmatter of every page named
-- Library/Storie/GM Bestiary, at any depth, as the index has it, lowest
-- first. Read at most every two seconds, as the creature pages are.
local staleCache
local function othersInSpace()
  local now = os.time()
  if staleCache and now - staleCache.at < 2 then return staleCache.value end
  local own = "Library/Storie/GM Bestiary"
  local tail = "/" .. own
  local pages = query[[
    from p = index.pages()
    where p.name == own or p.name:endsWith(tail)
    order by p.name
  ]]
  local out, seen = {}, {}
  for _, p in ipairs(pages) do
    local v = versionText(p.version)
    if v and v ~= bestiary.version and not seen[v] then
      seen[v] = true
      out[#out + 1] = v
    end
  end
  table.sort(out, versionLess)
  staleCache = { at = now, value = out }
  return out
end

-- Nil while this tab runs the GM Bestiary the space holds; else what to do.
-- A tab reads its Lua when it opens, so a library updated since, from
-- another tab or by a sync, is on disk and in the index but not running
-- here. GM Book asks before it builds. It never fails: a look that can't be
-- made says nothing.
function bestiary.stale()
  local ok, others = pcall(othersInSpace)
  if not ok or type(others) ~= "table" or #others == 0 then return nil end
  return "This tab runs GM Bestiary " .. bestiary.version .. ", but the space has " ..
    andList(others) .. ": reload it (System: Reload, Ctrl-Alt-R)."
end

-- The same, as a line over a reference on the page: HTML, so never in print
-- nor in the Markdown face. The reference sits in a sentence's place, so the
-- line is a block of its own above it. "" when this tab is current.
local function staleNote()
  local ok, others = pcall(othersInSpace)
  if not ok or type(others) ~= "table" or #others == 0 then return "" end
  return dom.span { class = "gmbestiary-stale", __rawText = "⟳ Reload this tab: it runs GM Bestiary " ..
    bestiary.version .. ", and the space has " .. andList(others) .. " (System: Reload, Ctrl-Alt-R)." }.outerHTML
end

------------------------------------------------------------------ the pages

-- Every creature page in the space, by name and by the tail of its path, so
-- a path written for an adventure folder finds the page in a space that
-- holds that folder. Read at most once every two seconds.
function bestiary.all()
  local now = os.time()
  if bestiary.cached and now - bestiary.cached.at < 2 then return bestiary.cached.value end
  local kind = bestiary.setting("type")
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
  bestiary.cached = { at = now, value = value }
  return value
end

-- Forget the pages read last, and whether this tab is behind its space, so
-- the next reference reads them again.
function bestiary.refresh()
  bestiary.cached = nil
  staleCache = nil
end

-- The creature page a path names, or nil. A path written for the
-- adventure's folder finds its page there when the path alone is ambiguous,
-- so a copy of the page elsewhere, such as one published to the players,
-- can't hide it.
function bestiary.find(ref)
  if type(ref) ~= "string" or ref == "" then return nil end
  local all = bestiary.all()
  local found = all.byName[ref] or all.byTail[ref]
  if found then return found end
  return all.root ~= "" and all.byName[all.root .. ref] or nil
end

-- The compendium link a page's ddb gives: a web address as it stands, and
-- a bare number, the shape a character page's ddb takes, as the creature's
-- page on D&D Beyond. Anything else is no link, and the second value is
-- what was there, for the page to flag.
function bestiary.link(ddb)
  if ddb == nil or ddb == "" then return nil end
  if type(ddb) == "number" then
    if ddb >= 1 and ddb == math.floor(ddb) then
      return "https://www.dndbeyond.com/monsters/" .. string.format("%d", ddb)
    end
    return nil, tostring(ddb)
  end
  local s = tostring(ddb)
  local trimmed = s:match("^%s*(.-)%s*$")
  if trimmed:match("^%d+$") then return "https://www.dndbeyond.com/monsters/" .. trimmed end
  if trimmed:lower():match("^https?://%S+$") then return trimmed end
  return nil, s
end

-- What a creature page says: its page, its title, and the stat block to run
-- it with. Nil for a page that isn't there or isn't a creature.
function bestiary.creature(ref)
  local p = bestiary.find(ref)
  if not p then return nil end
  local url, unlinked = bestiary.link(p.ddb)
  return {
    page = p.name,
    title = p.name:match("([^/]+)$") or p.name,
    statblock = p.statblock,
    entry = p.entry,
    source = p.source or bestiary.setting("source"),
    cr = p.cr,
    url = url,
    unlinked = unlinked,
  }
end

------------------------------------------------------------------ the citation

-- "Monster Manual, *Blights*": the book, and the entry that holds the stat
-- block when the book files it under another name.
function bestiary.where(c)
  if not c.statblock then return nil end
  local out = c.source
  if c.entry and c.entry ~= c.statblock then out = out .. ", *" .. c.entry .. "*" end
  return out
end

-- The citation for a creature a fight calls something of its own: the book
-- and entry, then the stat block's name where that isn't what the fight
-- calls it. "Monster Manual, *Blights* (vine blight)".
function bestiary.cite(c, called)
  local where = bestiary.where(c)
  if not where then return bestiary.setting("original") end
  if called and c.statblock:lower() ~= called:lower() then
    where = where .. " (" .. lower(c.statblock) .. ")"
  end
  return where
end

-- The reference as the page shows it and as it prints: the stat block's
-- name, linked to the compendium on the page only, then where to find it.
local function forms(c)
  if not c.statblock then
    local text = capital(bestiary.setting("original")) .. "."
    return dom.em { __rawText = text }.outerHTML, "*" .. text .. "*", "*" .. text .. "*"
  end
  local where = bestiary.where(c)
  local tail = where and (" — " .. where) or ""
  local name
  if c.url then
    name = dom.a { href = c.url, target = "_blank", rel = "noopener", __rawText = c.statblock }
  else
    name = dom.strong { __rawText = c.statblock }
  end
  -- the HTML face is not Markdown, so the entry is italicised as an element
  local said = { class = "gmbestiary-where" }
  if c.entry and c.entry ~= c.statblock then
    said[1] = dom.span { __rawText = " — " .. c.source .. ", " }
    said[2] = dom.em { __rawText = c.entry }
  else
    said[1] = dom.span { __rawText = tail }
  end
  local parts = { class = "gmbestiary-ref", name, dom.span(said) }
  -- a ddb that is no link, flagged on the page alone: the Markdown face
  -- goes to tables and the players' copies
  if c.unlinked then
    parts[#parts + 1] = dom.span { class = "gmbestiary-unlinked",
      __rawText = " ⚠ Not linked: ddb is " .. c.unlinked .. ", not a web address or a D&D Beyond id." }
  end
  local html = dom.span(parts).outerHTML
  local markdown = c.url and ("[" .. c.statblock .. "](" .. c.url .. ")" .. tail)
    or ("**" .. c.statblock .. "**" .. tail)
  return html, markdown, c.statblock .. tail
end

-- The page a reference reads with no page of its own: in print, the one a
-- build is printing; otherwise the one being printed for the players, or
-- the one open. A build takes a while and yields at every call, so a
-- reference drawn on the page meanwhile would otherwise read the page being
-- printed as its own: only the printer passes printing.
function bestiary.here(printing)
  if printing and gmbook and gmbook.printing then return gmbook.printing end
  return (gm and gm.printing) or editor.getCurrentPage()
end

local function missing(ref)
  local text = "No creature page for " .. tostring(ref) .. "."
  return widget.new {
    html = staleNote() .. dom.em { class = "gmbestiary-missing", __rawText = text }.outerHTML,
    markdown = "*" .. text .. "*",
    display = "inline",
  }
end

-- A creature's reference: the stat block to run it with, linked on the page
-- and cited in print. With no page, the page it is on.
function bestiary.ref(ref)
  local c = bestiary.creature(ref or bestiary.here())
  if not c then return missing(ref or bestiary.here()) end
  local html, markdown = forms(c)
  -- a tab behind its space says so over the reference, on the page alone
  return widget.new { html = staleNote() .. html, markdown = markdown, display = "inline" }
end

------------------------------------------------------------------ in print

-- What a reference prints as: the citation, with no URL in it. GM Book
-- evaluates an expression with bestiary standing for this table, and finds
-- it in gmbook.printers.
bestiary.printed = setmetatable({
  ref = function(ref)
    local c = bestiary.creature(ref or bestiary.here(true))
    if not c then return nil end
    return (select(3, forms(c)))
  end,
}, { __index = bestiary })

gmbook = gmbook or {}
gmbook.printers = gmbook.printers or {}
gmbook.printers.bestiary = bestiary.printed

------------------------------------------------------------------ in a fight

-- Whether a fight's CR and a page's are the same: by what they are worth,
-- as GM Party reads a CR, so 0.125 and "1/8" agree; as written where GM
-- Party isn't loaded or can't read one of them.
local function sameCR(a, b)
  if party and party.xp then
    local x, y = party.xp(a), party.xp(b)
    if x and y then return x == y end
  end
  local function norm(v) return (tostring(v):gsub("%s", "")) end
  return norm(a) == norm(b)
end

-- A CR as the SRD writes it: 0.125 as "1/8", and a whole number with no
-- decimals, however the page's YAML gave it.
local function crText(v)
  if type(v) == "number" then
    if v == 0.125 then return "1/8" end
    if v == 0.25 then return "1/4" end
    if v == 0.5 then return "1/2" end
    if v == math.floor(v) then return string.format("%d", v) end
  end
  return tostring(v)
end

-- A CR a fight gives a creature that its page disagrees with. A fight
-- writes the CR it spends XP on, and the page writes the stat block's, so
-- the two drifting apart is worth catching. A page with a stat block for
-- each of several levels lists every CR it runs at.
local function crWarning(c, called, cr)
  if cr == nil or c.cr == nil then return nil end
  local listed = type(c.cr) == "table" and c.cr or { c.cr }
  local named = {}
  for _, v in ipairs(listed) do
    if sameCR(v, cr) then return nil end
    named[#named + 1] = crText(v)
  end
  local list = ""
  for i, v in ipairs(named) do
    if i == 1 then list = v
    elseif i == #named then list = list .. " or " .. v
    else list = list .. ", " .. v end
  end
  return "The " .. called .. " is CR " .. crText(cr) .. " here, and CR " ..
    list .. " on " .. c.title .. "."
end

-- What GM Party shows and prints for a creature that names a page: the page
-- itself, its citation, and a CR here that disagrees with the page's. The
-- table isn't replaced: GM Party sorts after this page and shares it.
party = party or {}
function party.creatureRef(ref, called, cr)
  local c = bestiary.creature(ref)
  if not c then return nil end
  return { page = c.page, cite = bestiary.cite(c, called), warn = crWarning(c, called, cr) }
end
```

```space-style
.gmbestiary-where {
  color: var(--subtle-color);
}

.gmbestiary-missing {
  color: var(--subtle-color);
}

.gmbestiary-unlinked {
  font-style: italic;
  color: var(--subtle-color);
}

.gmbestiary-missing::before {
  content: "⚠ ";
  font-style: normal;
}

/* A tab behind its space: a line of its own over the reference, in words. */
.gmbestiary-stale {
  display: block;
  font-weight: bold;
}
```
