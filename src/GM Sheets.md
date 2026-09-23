---
tags: meta/library
name: "Library/Storie/GM Sheets"
description: "Character sheets drawn from a character page's frontmatter: a page drawn like a sheet, on the wiki and as a page of its own in the printed book, then the features, spells and equipment in full. The page gives the choices, and the sheet does the SRD's sums."
author: "Steven Storie"
version: "1.3.0"
---

# GM Sheets

Write a character once, as the choices their player made, and let the wiki and the book draw the sheet. A character's page keeps everything in its frontmatter: the scores, the proficiencies, and the numbers only the rules' tables give, such as Armor Class and Hit Points. GM Sheets works out the rest, the way the SRD 5.2.1 does the sums, and draws the sheet.

| On the page | In print |
|---|---|
| A page drawn like a character sheet, then the features, spells and equipment in full | The same page, on a page of the book to itself, then the same text as book text |

The drawn page is a sheet a table could print and play from: boxes for the Hit Points and Hit Point Dice spent, circles for death saves, spell slots and each use of a resource. Its labels are the SRD's terms, and its layout is its own.

## A character's page

    ---
    type: pc
    player: Sam
    level: 3
    class: Ranger
    subclass: Hunter
    species: Human
    background: Guide
    creature_size: Medium
    str: 12
    dex: 16
    con: 14
    int: 10
    wis: 14
    cha: 8
    saves: [str, dex]
    skills: [athletics, nature, perception, stealth, survival]
    expertise: [survival]
    ac: 15
    hp: 28
    hit_dice: 3d10
    speed: 30
    attacks:
      - {name: Longbow, hit: 7, damage: 1d8+3 Piercing, notes: "150/600 ft.; Slow"}
    spellcasting: wis
    slots: [3]
    spells: {1: [Cure Wounds, Goodberry]}
    always_prepared: {1: [Hunter's Mark]}
    features:
      - name: Favored Enemy
        text: |
          You always have Hunter's Mark prepared, and can cast it twice without a spell slot.
    ---

    # Tamsin Reed

    ${sheets.draw()}

`${sheets.draw()}` reads the page it is on, and in print the page being printed; on the wiki it reads its own page even while a build is running. Everywhere else, name the page: `${sheets.draw("Party/Tamsin Reed")}`. A path written for an adventure folder, `Rules/Sample Characters/Tamsin Reed`, also finds its page in a space that holds that folder, such as a DM space holding the adventure. The name on the sheet is the page's own, the last part of its path.

Any kind of page can hold a sheet. What `type` a character's page has is the campaign's to decide, and a type the party is counted from, such as GM Party's `pc`, is one way to keep a book's sample characters out of the party.

## The keys

**Who they are:** `level`, the total character level; `class` and `subclass`, where a multiclassed `class` names each class with its level, `Wizard 3 / Fighter 2`; `species`, `background`, and `creature_size`, since SilverBullet keeps `size` for a page's size in bytes; and `player`.

**Scores and proficiencies:**

| Key | Values |
|---|---|
| `str` `dex` `con` `int` `wis` `cha` | The six ability scores |
| `saves` | Proficient saving throws: `[str, con]` |
| `skills` | Proficient skills: `[athletics, sleight_of_hand]`. A skill can be named as the sheet names it, too, `Sleight of Hand` |
| `expertise` | Skills with Expertise |
| `advantage` | What they roll with Advantage, which the sheet marks: `initiative`, a skill, or a saving throw as `str_save` |

Each of these, and `armor_training`, can be a list or a line of names with commas between them: `saves: str, con`. A name the sheet doesn't know, such as `perceptoin`, would leave that skill off without a word, so the page says so over the sheet, naming it. That line is for you: it never prints.

**Worked out unless written.** GM Sheets works these out. Write one only where a feature or an item changes it, and the number written is the one shown:

| Key | Worked out as |
|---|---|
| `pb` | The Proficiency Bonus for `level` |
| `initiative` | The Dexterity modifier |
| `str_save` to `cha_save` | The ability's modifier, plus `pb` if proficient |
| A skill's own name, `athletics` to `survival` | Its ability's modifier, plus `pb` if proficient, or twice `pb` with Expertise |
| `passive_perception`, `passive_insight`, `passive_investigation` | 10 plus the skill, and 5 more with Advantage on it |
| `spell_dc`, `spell_attack` | 8 plus `pb` plus the spellcasting ability's modifier; `pb` plus that modifier |

**Written as the rules give them:**

| Key | Values |
|---|---|
| `ac` | Armor Class |
| `hp` | The Hit Point maximum |
| `hit_dice` | `3d10`, or `3d6 + 2d10` multiclassed |
| `speed` | In feet, `30`, or as text: `30 ft., Fly 30 ft.` |
| `senses`, `languages`, `tools` | Lists |
| `armor_training` | `[light, medium, heavy, shields]` |
| `weapons` | Weapon proficiencies: `[Simple, Martial]` |
| `masteries` | Weapon Mastery: `[Longbow (Slow)]` |
| `attacks` | A list, each with `name`, `hit` (a number, or a saving throw as text: `DC 13 Dex`), `damage` (`1d8+3 Piercing`) and `notes` |
| `resources` | What runs out, each with `name`, `uses` and `reset`: `{name: Second Wind, uses: 2, reset: Short Rest}` |
| `features`, `traits`, `feats` | Class features, species traits and feats, each with `name` and `text`, the rules in full |
| `equipment`, `attuned` | Lists |
| `coins` | `{gp: 15, sp: 3}` |
| `kit` | A second loadout, drawn on the same sheet under its `label`, with any of `ac`, `attacks` and `equipment`: a character who starts with nothing, and the gear they are given later |

**Spellcasting:** `spellcasting`, the ability (`int`, `wis` or `cha`); `slots`, spell slots by level, `[4, 3, 2]` or `{1: 4, 2: 3}`; `pact_slots` and `pact_level` for Pact Magic; `cantrips`, a list; `spells`, prepared spells by level, `{1: [Bless], 2: [Aid]}`; and `always_prepared`, the same, for spells always prepared; and `spellbook`, the same again, for a wizard's spells in the book and not prepared today. A spell is its name, or a name with more: `{name: Bless, time: Action, range: 30 ft., concentration: true}`, with `ritual`, `material` and `notes` the same way. A `material` can be the words for it: `material: a diamond worth 300+ GP`.

A list of spells with no levels, `spells: [Bless, Aid]`, is given as a list, and its places are never read as levels. A level that isn't one, such as `{first: [Bless]}`, an entry that isn't a spell, and slots that aren't numbers are named over the sheet, as unknown names are.

Quote any text in a list or `{...}` that holds a comma or a colon: `notes: "Versatile (1d10), Sap"`.

## What it draws

The page, top to bottom: the name and level; the class, subclass, species and background; the six abilities with their saving throws; Armor Class, Hit Points, Hit Point Dice and death saves; initiative, speed, size, Proficiency Bonus and passive Perception; the skills beside the attacks, the second loadout and the resources; spellcasting and its slots; training and languages; and the names of the features and the equipment.

On a screen narrower than the page it shrinks to fit, but on one 600px wide or less, such as a phone's, it keeps the size it is drawn at, so its labels stay readable, and scrolls sideways in its own frame.

**Nothing on it means anything by its colour.** A proficient save or skill has a filled circle, one with Expertise a filled diamond, one without an empty circle, and the skills' heading carries that key. Advantage is the word *ADV* beside the number. Armor training is a filled square or an empty one, with its name. The page is drawn in one ink and reads the same in grayscale.

Whatever doesn't fit on the page is counted, "and 4 more", or cut short with an ellipsis, and is always in the text after it: every feature with its rules, every spell by level, with its details, all the equipment, and any attack, resource or proficiency the page had to cut short. So is any single value it cut short, such as a long subclass, or an Armor Class with a note: `ac: 12 (15 with mage armor)` draws as much as the shield holds, and the text gives all of it.

## How it prints

The drawn page is two columns wide, so [GM Book](<GM Book>) 1.10 or later gives it a page to itself: a page break before it, unless it already starts a page, and one after it. The text follows as book text: the features under their headings, then the spells and the equipment. The widget's Markdown face is that page and that text, so GM Kit's copies for the players carry it too.

Everything the page says goes in as text. An `&`, `<` or `>` in a name, a feature's rules or anything else shows as itself and is never read as HTML, so a character whose text came from somewhere else, such as a player's own on D&D Beyond, can't put a form or a redirect in front of you. A feature's rules keep their Markdown: lists, tables, bold and italics.

A sheet's page break falls where the expression sits, so put `${sheets.draw()}` after whatever should stay on the page before it: a character's introduction reads well above it, and a heading alone at the foot of the page before it doesn't.

A sheet that can't be drawn, from a page that isn't there or whose frontmatter doesn't parse, says why on the wiki and prints nothing: GM Book 1.11 or later keeps that edition back and names the page, so the book never goes out with the message where the sheet should be.

## A printable handout

`tools/handout.py`, beside this library in its repository, fills Wizards of the Coast's 2024 character sheet from a character's page, with the same numbers the drawn page shows:

    python tools/handout.py <your space's folder> "Party/Tamsin Reed"

It writes `Handouts/Tamsin Reed.pdf` in the space's folder: the sheet's two pages with the character written in, then plain pages for everything that outgrew a box, the features, traits and feats with their rules first. With no page named, it fills every page of `type: pc`, or of the type `--type` names. `--extras want:Want` writes a campaign's own key into the sheet's Backstory & Personality box.

The sheet is Wizards of the Coast's, and its only terms are that you may print and photocopy it for personal use. So the script doesn't carry it: the first run fetches it from D&D Beyond into `~/.cache/gm-sheets`, and a filled copy is for your own table. **Keep `Handouts/` out of version control**, and out of anything you publish. It needs `pip install pypdf pyyaml`.

## Settings

    config.set("gmSheets", {
      extras = { { key = "oath", label = "Oath" } },
    })

`extras` are more keys to show beside the class and species, each with the label to draw over it. `width` is the drawn page's width in px, both columns of a book page, and `height` the most it may be.

## Changes in 1.3

**Nothing on a character's page reaches the browser as HTML.** Names, features, spells and equipment are escaped before the sheet's text is drawn, since an imported character's words are its player's.

**Frontmatter written a plausible way reads the way it looks.** `skills: athletics, perception` and `saves: str, con` are lists; `slots` can be a map of level to count, like `spells`; a spell list with no levels prints as **Prepared.** rather than as levels 1, 2, 3; and a ⚠ above the sheet, on the page only, names any save, skill or spell shape it can't read.

**What the sheet cuts short is given whole** in the text after it, and Armor Class and Hit Points shrink to fit their boxes. `sheets.draw` finds a page by its path in the adventure folder from any space.

**In print, a sheet it can't draw prints nothing and says why**, so the book is kept back with the reason rather than printing a note where a character should be. On a phone the sheet scrolls at a size you can read, and a sheet drawn on the page while the book builds is drawn for that page.

## Implementation

```space-lua
-- priority: 10
sheets = sheets or {}

sheets.config = {
  extras = {},     -- more keys to show beside the class and species
  width  = 672,    -- both columns of a book page, in px
  height = 918,    -- the most the drawn page may be: a book page less its margins
}

function sheets.setting(key)
  local value = config.get("gmSheets." .. key, nil)
  if value == nil then value = sheets.config[key] end
  return value
end

local ABILITIES = {
  { key = "str", name = "Strength" },
  { key = "dex", name = "Dexterity" },
  { key = "con", name = "Constitution" },
  { key = "int", name = "Intelligence" },
  { key = "wis", name = "Wisdom" },
  { key = "cha", name = "Charisma" },
}

local SKILLS = {
  { key = "acrobatics",      name = "Acrobatics",      ability = "dex" },
  { key = "animal_handling", name = "Animal Handling", ability = "wis" },
  { key = "arcana",          name = "Arcana",          ability = "int" },
  { key = "athletics",       name = "Athletics",       ability = "str" },
  { key = "deception",       name = "Deception",       ability = "cha" },
  { key = "history",         name = "History",         ability = "int" },
  { key = "insight",         name = "Insight",         ability = "wis" },
  { key = "intimidation",    name = "Intimidation",    ability = "cha" },
  { key = "investigation",   name = "Investigation",   ability = "int" },
  { key = "medicine",        name = "Medicine",        ability = "wis" },
  { key = "nature",          name = "Nature",          ability = "int" },
  { key = "perception",      name = "Perception",      ability = "wis" },
  { key = "performance",     name = "Performance",     ability = "cha" },
  { key = "persuasion",      name = "Persuasion",      ability = "cha" },
  { key = "religion",        name = "Religion",        ability = "int" },
  { key = "sleight_of_hand", name = "Sleight of Hand", ability = "dex" },
  { key = "stealth",         name = "Stealth",         ability = "dex" },
  { key = "survival",        name = "Survival",        ability = "wis" },
}

sheets.abilities, sheets.skills = ABILITIES, SKILLS

------------------------------------------------------------------ the page

-- The page a sheet reads with no page named: in print, the one a build is
-- printing; otherwise the one being printed for the players, or the one
-- open. A build takes a while and yields at every call, so a sheet drawn on
-- the page meanwhile would otherwise draw the page being printed: only the
-- printer passes printing.
function sheets.here(printing)
  if printing and gmbook and gmbook.printing then return gmbook.printing end
  return (gm and gm.printing) or editor.getCurrentPage()
end

-- The name on the sheet: the last part of the page's path.
function sheets.nameOf(page)
  return tostring(page):match("([^/]+)$") or tostring(page)
end

-- A character's page as data: its frontmatter, parsed. Nil and why, for a
-- page that can't be read or whose frontmatter doesn't parse.
function sheets.read(page)
  local ok, text = pcall(space.readPage, page)
  if not ok or type(text) ~= "string" then return nil, "No page " .. tostring(page) .. "." end
  local head = text:match("^%-%-%-\r?\n(.-)\r?\n%-%-%-")
  if not head then return nil, tostring(page) .. " has no frontmatter to draw a sheet from." end
  local parsed, data = pcall(yaml.parse, head)
  if not parsed or type(data) ~= "table" then
    return nil, "The frontmatter of " .. tostring(page) .. " doesn't parse as YAML."
  end
  return data
end

-- The page a sheet names, as GM Bestiary finds a creature's: the page of
-- that name; or else the one page whose path ends in it; or, where more
-- than one does, the one in the adventure's folder. So a path written for
-- the adventure, "Rules/Sample Characters/Tam", finds its page in a space
-- that holds that folder, such as the DM's. Nil for none.
function sheets.find(ref)
  if type(ref) ~= "string" or ref == "" then return nil end
  -- getPageMeta asks for the page itself; pageExists is link resolution
  local function exists(name) return (pcall(space.getPageMeta, name)) end
  if exists(ref) then return ref end
  local tail = "/" .. ref
  local found = query[[
    from p = index.pages()
    where p.name:endsWith(tail)
    select p.name
  ]]
  local n, only = 0, nil
  for _, name in ipairs(found) do n, only = n + 1, name end
  if n == 1 then return only end
  local root = gmbook and gmbook.root and gmbook.root() or ""
  if root ~= "" and exists(root .. ref) then return root .. ref end
  return nil
end

------------------------------------------------------------------ the sums

-- A number from a page: 5, "5" or "+5". Nil for anything else.
local function number(v)
  if type(v) == "number" then return v end
  if type(v) == "string" then
    local s = (v:gsub("^%s*%+", ""))
    s = (s:gsub("%s+$", ""))
    return tonumber(s)
  end
  return nil
end

-- A whole number from a page, or nil.
local function whole(v)
  local n = number(v)
  if n == nil then return nil end
  return math.floor(n)
end

-- A list from a page as its entries: a list, one entry, or none.
local function items(v)
  if v == nil then return {} end
  if type(v) ~= "table" then return { v } end
  local out = {}
  for _, e in ipairs(v) do out[#out + 1] = e end
  return out
end

-- Whether a value from the page is a map, {1: 4} or {name: Bless}, and not
-- a list. YAML keys a map by text, even a number, so a key that is text
-- says so; and pairs is the only safe look, since # fails on a map that
-- comes straight from yaml.parse in SilverBullet.
local function isMap(v)
  if type(v) ~= "table" then return false end
  for k in pairs(v) do
    if type(k) == "string" then return true end
  end
  return false
end

-- A list of names from the page, such as the skills: its entries, with one
-- written as a line of text, "athletics, perception", split at its commas.
-- A map is no list of names, and gives none.
local function names(v)
  if isMap(v) then return {} end
  local out = {}
  for _, e in ipairs(items(v)) do
    if type(e) == "string" then
      for part in (e .. ","):gmatch("([^,]*),") do
        local s = (part:gsub("^%s+", ""))
        s = (s:gsub("%s+$", ""))
        if s ~= "" then out[#out + 1] = s end
      end
    else
      out[#out + 1] = e
    end
  end
  return out
end

-- A level from a map's key, "1" or 1: a whole number from lo to hi, or nil.
local function levelKey(k, lo, hi)
  local n = tonumber(k)
  if n == nil or n ~= math.floor(n) or n < lo or n > hi then return nil end
  return math.floor(n)
end

-- A name as a key: "Sleight of Hand" and "sleight-of-hand" are sleight_of_hand.
local function key(v)
  local s = tostring(v):lower()
  s = (s:gsub("^%s+", ""))
  s = (s:gsub("%s+$", ""))
  return (s:gsub("[%s%-]+", "_"))
end

-- An ability as its key: "Strength", "STR" and "str" are all str.
local function abilityKey(v)
  if v == nil then return nil end
  local k = key(v)
  for _, a in ipairs(ABILITIES) do
    if k == a.key or k == a.name:lower() then return a.key end
  end
  return nil
end

local function set(v)
  local out = {}
  for _, e in ipairs(names(v)) do
    local k = key(e)
    out[k] = true
    -- a saving throw can be named by its ability alone, or in full
    local ab = abilityKey((k:gsub("_saves?$", "")))
    if ab then out[ab .. "_save"] = true end
  end
  return out
end

function sheets.modifier(score)
  local s = whole(score)
  if s == nil then return nil end
  return math.floor((s - 10) / 2)
end

function sheets.proficiency(level)
  local l = whole(level) or 1
  if l < 1 then l = 1 end
  return 2 + math.floor((l - 1) / 4)
end

-- Every number the sheet shows, from the page: a number the page writes,
-- or else the SRD's sum for it.
function sheets.values(d)
  local v = {
    scores = {}, mods = {}, saves = {}, saveProf = {}, skills = {}, skillProf = {},
    adv = set(d.advantage), level = whole(d.level),
  }
  v.pb = whole(d.pb) or sheets.proficiency(d.level)
  local saves, skills, expert = set(d.saves), set(d.skills), set(d.expertise)
  for _, a in ipairs(ABILITIES) do
    local score = whole(d[a.key])
    local m = sheets.modifier(score)
    v.scores[a.key], v.mods[a.key] = score, m
    local prof = saves[a.key .. "_save"] == true
    v.saveProf[a.key] = prof
    v.saves[a.key] = whole(d[a.key .. "_save"]) or (m and (m + (prof and v.pb or 0)))
  end
  for _, s in ipairs(SKILLS) do
    local m = v.mods[s.ability]
    local p = expert[s.key] and 2 or (skills[s.key] and 1 or 0)
    v.skillProf[s.key] = p
    v.skills[s.key] = whole(d[s.key]) or (m and (m + p * v.pb))
  end
  v.initiative = whole(d.initiative) or v.mods.dex
  v.passive = {}
  for _, s in ipairs({ "perception", "insight", "investigation" }) do
    local skill = v.skills[s]
    v.passive[s] = whole(d["passive_" .. s]) or (skill and (10 + skill + (v.adv[s] and 5 or 0)))
  end
  v.casting = abilityKey(d.spellcasting)
  local cm = v.casting and v.mods[v.casting]
  v.spellDC = whole(d.spell_dc) or (cm and (8 + v.pb + cm))
  v.spellAttack = whole(d.spell_attack) or (cm and (v.pb + cm))
  return v
end

------------------------------------------------------------------ words

local function signed(n)
  if n == nil then return "" end
  if n >= 0 then return "+" .. tostring(n) end
  return "-" .. tostring(-n)
end
sheets.signed = signed

local function str(v)
  if v == nil then return "" end
  if type(v) == "number" then
    if v == math.floor(v) then return tostring(math.floor(v)) end
    return tostring(v)
  end
  return tostring(v)
end

-- Text from the page, as the Markdown after the drawn page carries it: an
-- &, < or > in it shows as itself and is never read as HTML. A character
-- imported from D&D Beyond is a player's own text, and SilverBullet keeps
-- a form or a meta tag in what it renders. The library's own Markdown, its
-- bold, headings and lists, goes round this, so it still works.
local function safe(v)
  local s = str(v)
  s = (s:gsub("&", "&amp;"))
  s = (s:gsub("<", "&lt;"))
  return (s:gsub(">", "&gt;"))
end

-- An entry of a list that may be a name or a table with one.
local function nameOf(e)
  if type(e) == "table" then return str(e.name) end
  return str(e)
end

-- "8" as "+8" and a text as it stands: an attack's to-hit.
local function hitText(v)
  local n = type(v) == "number" and v or nil
  if n then return signed(math.floor(n)) end
  return str(v)
end

local function speedText(v)
  if type(v) == "number" then return str(v) .. " ft." end
  return str(v)
end

local ORDINAL = { "1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th", "9th" }

-- Spells from the page under one key, `what`: by level, a map such as
-- {1: [Bless], 2: [Aid]}, which YAML keys by text, as sorted pairs
-- { {level, list}, ... }; or a list with no levels, [Bless, Aid], kept as a
-- list and never read by its places as levels 1, 2, 3. Returns the levels,
-- that list, and what it couldn't read, for the page to flag.
local function spellLists(v, what)
  local levels, plain, odd = {}, {}, {}
  -- a spell is its name, or a map with one; a single spell with its
  -- details stands for a list of one
  local function entries(list, where)
    local out = {}
    if isMap(list) then list = { list } end
    for _, e in ipairs(items(list)) do
      if type(e) == "table" and not (isMap(e) and e.name ~= nil) then
        odd[#odd + 1] = what .. where .. ": an entry with no spell's name"
      else
        out[#out + 1] = e
      end
    end
    return out
  end
  if v == nil then return levels, plain, odd end
  if isMap(v) then
    for k, list in pairs(v) do
      local l = levelKey(k, 0, 9)
      if l then
        levels[#levels + 1] = { level = l, list = entries(list, " at level " .. tostring(l)) }
      else
        odd[#odd + 1] = what .. " under “" .. tostring(k) .. "”, which isn't a spell level"
      end
    end
    table.sort(levels, function(a, b) return a.level < b.level end)
  elseif type(v) == "table" or type(v) == "string" then
    plain = entries(v, "")
  else
    odd[#odd + 1] = what .. ": " .. str(v) .. ", which is no list of spells"
  end
  return levels, plain, odd
end

-- Spell slots from the page, by level: a list, [4, 3, 2], or a map keyed by
-- level, {1: 4, 2: 3}. Returns a count for every level up to the highest
-- given, and what it couldn't read, for the page to flag.
local function slotCounts(v)
  local out, odd = {}, {}
  local function count(n, l)
    local c = whole(n)
    if c == nil then
      odd[#odd + 1] = "slots at level " .. tostring(l) .. ": “" .. str(n) .. "”, which is no number"
    end
    return c or 0
  end
  if not isMap(v) then
    for i, n in ipairs(items(v)) do out[i] = count(n, i) end
    return out, odd
  end
  local top = 0
  for k, n in pairs(v) do
    local l = levelKey(k, 1, 9)
    if l then
      out[l] = count(n, l)
      if l > top then top = l end
    else
      odd[#odd + 1] = "slots under “" .. tostring(k) .. "”, which isn't a spell level"
    end
  end
  for l = 1, top do out[l] = out[l] or 0 end
  return out, odd
end

local SKILL = {}
for _, s in ipairs(SKILLS) do SKILL[s.key] = true end

-- What the page gives that the sheet can't use: names it doesn't know in
-- the saves, skills, Expertise, Advantage and armor training, which would
-- otherwise make nothing proficient without a word, and spells or slots in
-- a shape it can't read. For a line over the sheet on the page; never
-- printed.
function sheets.problems(d)
  local out = {}
  local function save(k) return abilityKey((k:gsub("_saves?$", ""))) ~= nil end
  local function skill(k) return SKILL[k] == true end
  local kinds = {
    { "saves", save },
    { "skills", skill },
    { "expertise", skill },
    { "advantage", function(k) return k == "initiative" or skill(k) or save(k) end },
    { "armor_training", function(k) return k == "light" or k == "medium" or k == "heavy" or k == "shields" end },
  }
  for _, kind in ipairs(kinds) do
    local v = d[kind[1]]
    if isMap(v) then
      out[#out + 1] = kind[1] .. ", a map where a list of names goes"
    else
      local unknown = {}
      for _, e in ipairs(names(v)) do
        if type(e) == "table" then unknown[#unknown + 1] = "{…}"
        elseif not kind[2](key(e)) then unknown[#unknown + 1] = str(e) end
      end
      if #unknown > 0 then out[#out + 1] = kind[1] .. " " .. table.concat(unknown, ", ") end
    end
  end
  for _, what in ipairs({ "spells", "always_prepared", "spellbook" }) do
    local _, _, odd = spellLists(d[what], what)
    for _, o in ipairs(odd) do out[#out + 1] = o end
  end
  local _, odd = slotCounts(d.slots)
  for _, o in ipairs(odd) do out[#out + 1] = o end
  return out
end

-- A spell's name and its details in brackets: "Bless (Action, 30 ft.;
-- concentration, material: a sprig of mistletoe)".
local function spellText(e)
  if type(e) ~= "table" then return safe(e) end
  local where, flags = {}, {}
  if e.time ~= nil then where[#where + 1] = safe(e.time) end
  if e.range ~= nil then where[#where + 1] = safe(e.range) end
  if e.concentration == true then flags[#flags + 1] = "concentration" end
  if e.ritual == true then flags[#flags + 1] = "ritual" end
  if e.material == true then flags[#flags + 1] = "material"
  elseif e.material ~= nil and e.material ~= false then flags[#flags + 1] = "material: " .. safe(e.material) end
  if e.notes ~= nil then flags[#flags + 1] = safe(e.notes) end
  local parts = {}
  if #where > 0 then parts[#parts + 1] = table.concat(where, ", ") end
  if #flags > 0 then parts[#parts + 1] = table.concat(flags, ", ") end
  if #parts == 0 then return safe(e.name) end
  return safe(e.name) .. " (" .. table.concat(parts, "; ") .. ")"
end

------------------------------------------------------------------ measuring

-- SilverBullet's strings are UTF-16 and stock Lua's are UTF-8 bytes, so a
-- character past ASCII is counted once either way.
local WIDE = #"—" == 1

-- Helvetica's widths, ASCII 32 to 126, in thousandths of an em: wider than
-- the book's own sans, so a line measured by them fits in either.
local HELV = {
  278, 278, 355, 556, 556, 889, 667, 191, 333, 333, 389, 584, 278, 333, 278, 278,
  556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 584, 584, 584, 556, 1015,
  667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556, 833, 722, 778, 667, 778,
  722, 667, 611, 722, 667, 944, 667, 667, 611, 278, 278, 278, 469, 556, 333,
  556, 556, 500, 556, 556, 278, 556, 556, 222, 222, 500, 222, 833, 556, 556, 556, 556,
  333, 500, 278, 556, 500, 722, 500, 500, 500, 334, 260, 334, 584,
}

local function textWidth(s, size, bold)
  local total = 0
  for i = 1, #s do
    local b = s:byte(i)
    if b >= 32 and b <= 126 then total = total + HELV[b - 31]
    elseif b >= 128 and (WIDE or b >= 192) then total = total + 600
    end
  end
  return total * size / 1000 * (bold and 1.08 or 1)
end
sheets.textWidth = textWidth

-- The size, no larger than asked and no smaller than min, at which a line
-- fits in width; and the line itself, cut short with an ellipsis if it
-- won't fit even at min.
local function fitted(s, width, size, min, bold)
  local at = size
  while at > min and textWidth(s, at, bold) > width do at = at - 0.5 end
  if textWidth(s, at, bold) <= width then return s, at end
  local cut = s
  while #cut > 1 and textWidth(cut .. "…", at, bold) > width do cut = sheets.dropLast(cut) end
  return cut .. "…", at
end

-- The text less its last character: one UTF-16 unit in SilverBullet, and in
-- stock Lua the bytes of one UTF-8 character, so a cut never splits one.
function sheets.dropLast(s)
  if WIDE then return s:sub(1, #s - 1) end
  local n = #s
  while n > 0 do
    local b = s:byte(n)
    n = n - 1
    if b < 128 or b >= 192 then break end
  end
  return s:sub(1, n)
end

-- Words wrapped into lines no wider than width.
local function wrapped(s, width, size, bold)
  local lines, line = {}, ""
  for word in s:gmatch("%S+") do
    local try = line == "" and word or (line .. " " .. word)
    if line ~= "" and textWidth(try, size, bold) > width then
      lines[#lines + 1] = line
      line = word
    else
      line = try
    end
  end
  if line ~= "" then lines[#lines + 1] = line end
  return lines
end

------------------------------------------------------------------ drawing

local INK = "#2a2521"
local FAINT = "#8a8178"
local FONT = "ScalySansRemake, 'Scaly Sans', Helvetica, Arial, sans-serif"

local function esc(s)
  s = str(s)
  s = (s:gsub("&", "&amp;"))
  s = (s:gsub("<", "&lt;"))
  s = (s:gsub(">", "&gt;"))
  return (s:gsub('"', "&quot;"))
end

-- A coordinate as text, whole or to a tenth, built from whole numbers: a
-- float reaching tostring prints "12.0" in one Lua and "12" in the other.
local function px(n)
  local t = math.floor(n * 10 + 0.5)
  local w, tenth = math.floor(t / 10), t % 10
  if tenth == 0 then return tostring(w) end
  return tostring(w) .. "." .. tostring(tenth)
end

-- The drawing, one element at a time.
local function canvas()
  local c = { out = {} }
  function c.add(s) c.out[#c.out + 1] = s end
  function c.text(x, y, s, size, o)
    o = o or {}
    local a = { '<text x="', px(x), '" y="', px(y), '" font-size="', px(size), '"' }
    if o.bold then a[#a + 1] = ' font-weight="bold"' end
    if o.italic then a[#a + 1] = ' font-style="italic"' end
    if o.anchor then a[#a + 1] = ' text-anchor="' .. o.anchor .. '"' end
    if o.spacing then a[#a + 1] = ' letter-spacing="' .. px(o.spacing) .. '"' end
    if o.faint then a[#a + 1] = ' fill="' .. FAINT .. '"' end
    -- on one line, as SVG shows it anyway: a blank line in a value would
    -- end the HTML block the drawing prints in, and the rest would be read
    -- as Markdown
    a[#a + 1] = ">" .. esc((str(s):gsub("%s+", " "))) .. "</text>"
    c.add(table.concat(a))
  end
  function c.label(x, y, s, o)
    o = o or {}
    c.text(x, y, tostring(s):upper(), o.size or 6.5, { bold = true, spacing = 0.6, anchor = o.anchor })
  end
  function c.box(x, y, w, h, o)
    o = o or {}
    c.add('<rect x="' .. px(x) .. '" y="' .. px(y) .. '" width="' .. px(w) .. '" height="' .. px(h) ..
      '" rx="' .. px(o.r or 4) .. '" fill="none" stroke="' .. INK .. '" stroke-width="' .. px(o.weight or 1) .. '"/>')
  end
  function c.line(x1, y1, x2, y2, o)
    o = o or {}
    c.add('<line x1="' .. px(x1) .. '" y1="' .. px(y1) .. '" x2="' .. px(x2) .. '" y2="' .. px(y2) ..
      '" stroke="' .. (o.faint and FAINT or INK) .. '" stroke-width="' .. px(o.weight or 0.8) .. '"/>')
  end
  -- a mark: a circle, filled or not, or a filled diamond
  function c.mark(cx, cy, kind)
    if kind == "diamond" then
      c.add('<path d="M' .. px(cx) .. " " .. px(cy - 4) .. " L" .. px(cx + 4) .. " " .. px(cy) ..
        " L" .. px(cx) .. " " .. px(cy + 4) .. " L" .. px(cx - 4) .. " " .. px(cy) .. ' Z" fill="' .. INK .. '"/>')
    elseif kind == "square" or kind == "open square" then
      c.add('<rect x="' .. px(cx - 3.5) .. '" y="' .. px(cy - 3.5) .. '" width="7" height="7" fill="' ..
        (kind == "square" and INK or "none") .. '" stroke="' .. INK .. '" stroke-width="1"/>')
    else
      c.add('<circle cx="' .. px(cx) .. '" cy="' .. px(cy) .. '" r="3.3" fill="' ..
        (kind == "filled" and INK or "none") .. '" stroke="' .. INK .. '" stroke-width="1"/>')
    end
  end
  -- n circles to tick, in a row from x; returns where the row ends
  function c.ticks(x, cy, n, gap)
    gap = gap or 10
    for i = 0, n - 1 do c.mark(x + 4 + i * gap, cy, "open") end
    return x + n * gap
  end
  -- a field: its value over a rule, its label under it; true when the
  -- value had to be cut short
  function c.field(x, y, w, label, value)
    local s, size = fitted(str(value), w - 4, 12, 7.5)
    if s ~= "" then c.text(x + 2, y + 14, s, size) end
    c.line(x, y + 18, x + w, y + 18)
    c.label(x + 2, y + 26, label)
    return s ~= str(value)
  end
  return c
end

local function proficiencyMark(p)
  if p == 2 then return "diamond" end
  if p == 1 then return "filled" end
  return "open"
end

-- Lines wrapped to width, no more than most of them: the last one shown
-- ends in an ellipsis when some are left over. Returns the lines, and
-- whether any were.
local function lines(s, width, size, most)
  local all = wrapped(s, width, size)
  if #all <= most then return all, false end
  local out = {}
  for i = 1, most do out[i] = all[i] end
  local last = out[most]
  while #last > 1 and textWidth(last .. "…", size) > width do last = sheets.dropLast(last) end
  out[most] = last .. "…"
  return out, true
end

-- Where each column of the attack table starts, across width w from x.
local function attackCols(x, w)
  return { name = x + 6, hit = x + w * 0.3, damage = x + w * 0.43, notes = x + w * 0.63, right = x + w - 6 }
end

-- The attack table's rows, from y; returns where they end, how many were
-- shown, and the attacks the page had to cut short or leave out.
local function attackRows(c, x, y, w, attacks, limit, cut)
  local cols = attackCols(x, w)
  local shown = 0
  for _, a in ipairs(attacks) do
    if y + 12 > limit then
      cut[#cut + 1] = a
    else
      local name = nameOf(a)
      local hit = type(a) == "table" and hitText(a.hit) or ""
      local damage = type(a) == "table" and str(a.damage) or ""
      local notes = type(a) == "table" and str(a.notes) or ""
      local n, nsize = fitted(name, cols.hit - cols.name - 4, 9.5, 7.5, true)
      c.text(cols.name, y + 9, n, nsize, { bold = true })
      local hl, hcut = lines(hit, cols.damage - cols.hit - 4, 9, 2)
      local dl, dcut = lines(damage, cols.notes - cols.damage - 4, 9, 2)
      local nl, ncut = lines(notes, cols.right - cols.notes, 7.5, 3)
      for i, l in ipairs(hl) do c.text(cols.hit, y + 9 + (i - 1) * 9, l, 9) end
      for i, l in ipairs(dl) do c.text(cols.damage, y + 9 + (i - 1) * 9, l, 9) end
      for i, l in ipairs(nl) do c.text(cols.notes, y + 8.5 + (i - 1) * 8.5, l, 7.5) end
      if n ~= name or hcut or dcut or ncut then cut[#cut + 1] = a end
      local rows = math.max(1, #hl, #dl, math.ceil(#nl * 8.5 / 9))
      y = y + 6 + rows * 9
      shown = shown + 1
    end
  end
  return y, shown
end

-- The page drawn like a character sheet, as SVG text; its height; and what
-- it had to cut short or leave out, which the text after it gives in full.
function sheets.svg(d, v, page)
  local W = sheets.setting("width")
  local maxH = sheets.setting("height")
  local c = canvas()
  local gap = 8
  -- what the page had to cut short or leave out, for the text after it
  local cut = { attacks = {}, kit = {}, resources = {}, lines = {}, fields = {} }
  -- a single value fitted to its room, and noted when it had to be cut
  -- short, so the text after the page gives it whole
  local function fit(label, value, width, size, min, bold)
    local s = str(value)
    local shown, at = fitted(s, width, size, min, bold)
    if shown ~= s then cut.fields[#cut.fields + 1] = { label, s } end
    return shown, at
  end

  -- the name and level
  local name = sheets.nameOf(page or "")
  local nm, nsize = fit("Name", name, W - 96, 24, 14, true)
  c.text(0, 24, nm, nsize, { bold = true })
  c.line(0, 31, W - 84, 31, { weight = 1.2 })
  c.box(W - 76, 0, 76, 36)
  c.label(W - 38, 10, "Level", { anchor = "middle" })
  c.text(W - 38, 30, str(v.level), 18, { bold = true, anchor = "middle" })

  -- the class line: class, subclass, species, background, and the extras
  local fields = {
    { "Class", d.class }, { "Subclass", d.subclass }, { "Species", d.species },
    { "Background", d.background },
  }
  for _, e in ipairs(items(sheets.setting("extras"))) do
    if type(e) == "table" and e.key then fields[#fields + 1] = { e.label or e.key, d[e.key] } end
  end
  if d.player ~= nil then fields[#fields + 1] = { "Player", d.player } end
  local fw = (W - gap * (#fields - 1)) / #fields
  for i, f in ipairs(fields) do
    if c.field((i - 1) * (fw + gap), 40, fw, f[1], f[2]) then cut.fields[#cut.fields + 1] = { f[1], str(f[2]) } end
  end

  -- the six abilities, each with its saving throw under it
  local y = 76
  local tw = (W - gap * 5) / 6
  for i, a in ipairs(ABILITIES) do
    local x = (i - 1) * (tw + gap)
    c.box(x, y, tw, 70, { r = 6 })
    c.label(x + tw / 2, y + 12, a.name, { anchor = "middle" })
    c.text(x + tw / 2, y + 42, signed(v.mods[a.key]), 24, { bold = true, anchor = "middle" })
    c.add('<ellipse cx="' .. px(x + tw / 2) .. '" cy="' .. px(y + 58) .. '" rx="15" ry="8" fill="none" stroke="' ..
      INK .. '" stroke-width="1"/>')
    c.text(x + tw / 2, y + 61.5, str(v.scores[a.key]), 10, { anchor = "middle" })
    c.mark(x + 7, y + 81, v.saveProf[a.key] and "filled" or "open")
    c.label(x + 14, y + 83.5, "Save")
    if v.adv[a.key .. "_save"] then c.label(x + tw - 30, y + 83.5, "Adv", { anchor = "end" }) end
    c.text(x + tw - 4, y + 84.5, signed(v.saves[a.key]), 11, { bold = true, anchor = "end" })
  end

  -- Armor Class, Hit Points, Hit Point Dice, death saves, Heroic Inspiration
  y = 172
  local widths = { 78, 196, 110, 140 }
  local rest = W - gap * 4
  for _, n in ipairs(widths) do rest = rest - n end
  widths[#widths + 1] = rest
  local x = 0
  local function tile(n) local at = x; x = x + widths[n] + gap; return at, widths[n] end
  local ax, aw = tile(1)
  -- a shield's outline round the Armor Class
  c.add('<path d="M' .. px(ax + 4) .. " " .. px(y + 2) .. " H" .. px(ax + aw - 4) .. " V" .. px(y + 34) ..
    " Q" .. px(ax + aw - 4) .. " " .. px(y + 52) .. " " .. px(ax + aw / 2) .. " " .. px(y + 60) ..
    " Q" .. px(ax + 4) .. " " .. px(y + 52) .. " " .. px(ax + 4) .. " " .. px(y + 34) ..
    ' Z" fill="none" stroke="' .. INK .. '" stroke-width="1.2"/>')
  c.label(ax + aw / 2, y + 12, "Armor", { anchor = "middle" })
  c.label(ax + aw / 2, y + 20, "Class", { anchor = "middle" })
  -- inside the shield where it narrows, at the line the number sits on
  local ac, acsize = fit("Armor Class", d.ac, aw - 20, 20, 8, true)
  c.text(ax + aw / 2, y + 43, ac, acsize, { bold = true, anchor = "middle" })
  local hx, hw = tile(2)
  c.box(hx, y, hw, 60)
  c.label(hx + 6, y + 11, "Hit Points")
  -- between the box's edge and the Current box
  local hp, hpsize = fit("Hit Points", d.hp, 68, 22, 9, true)
  c.text(hx + 40, y + 42, hp, hpsize, { bold = true, anchor = "middle" })
  c.label(hx + 40, y + 54, "Maximum", { anchor = "middle" })
  c.box(hx + 76, y + 18, 54, 28, { r = 2, weight = 0.8 })
  c.label(hx + 103, y + 54, "Current", { anchor = "middle" })
  c.box(hx + 136, y + 18, 54, 28, { r = 2, weight = 0.8 })
  c.label(hx + 163, y + 54, "Temporary", { anchor = "middle" })
  local dx, dw = tile(3)
  c.box(dx, y, dw, 60)
  c.label(dx + 6, y + 11, "Hit Point Dice")
  local hd, hdsize = fit("Hit Point Dice", d.hit_dice, dw - 12, 16, 9, true)
  c.text(dx + dw / 2, y + 34, hd, hdsize, { bold = true, anchor = "middle" })
  c.label(dx + 6, y + 53, "Spent")
  c.line(dx + 34, y + 53, dx + dw - 8, y + 53, { weight = 0.8 })
  local sx, sw = tile(4)
  c.box(sx, y, sw, 60)
  c.label(sx + 6, y + 11, "Death Saves")
  c.label(sx + 6, y + 31, "Successes")
  c.ticks(sx + 66, y + 28, 3, 12)
  c.label(sx + 6, y + 49, "Failures")
  c.ticks(sx + 66, y + 46, 3, 12)
  local ix, iw = tile(5)
  c.box(ix, y, iw, 60)
  c.label(ix + iw / 2, y + 11, "Heroic", { anchor = "middle" })
  c.label(ix + iw / 2, y + 19, "Inspiration", { anchor = "middle" })
  c.add('<rect x="' .. px(ix + iw / 2 - 11) .. '" y="' .. px(y + 27) .. '" width="22" height="22" rx="2" ' ..
    'fill="none" stroke="' .. INK .. '" stroke-width="1" transform="rotate(45 ' .. px(ix + iw / 2) .. " " ..
    px(y + 38) .. ')"/>')

  -- initiative, speed, size, Proficiency Bonus, passive Perception
  y = 240
  local strip = {
    { "Initiative", signed(v.initiative), v.adv.initiative },
    { "Speed", speedText(d.speed) },
    { "Size", str(d.creature_size) },
    { "Proficiency Bonus", signed(v.pb) },
    { "Passive Perception", str(v.passive.perception), v.adv.perception },
  }
  local pw = (W - gap * (#strip - 1)) / #strip
  for i, s in ipairs(strip) do
    local px0 = (i - 1) * (pw + gap)
    c.box(px0, y, pw, 26, { r = 13 })
    c.label(px0 + 12, y + 16, s[1])
    local val, vsize = fit(s[1], s[2], pw * 0.42, 13, 8, true)
    c.text(px0 + pw - 12, y + 18, val, vsize, { bold = true, anchor = "end" })
    if s[3] then c.label(px0 + pw - 12 - textWidth(val, vsize, true) - 4, y + 16, "Adv", { anchor = "end" }) end
  end

  -- the skills, the key to their marks in the heading, and two passives
  y = 276
  local leftW, leftH = 206, 314
  c.box(0, y, leftW, leftH, { r = 6 })
  c.label(8, y + 13, "Skills")
  local kx = 58
  for _, k in ipairs({ { "filled", "proficient" }, { "diamond", "expertise" }, { "open", "neither" } }) do
    c.mark(kx + 3, y + 10.5, k[1])
    c.text(kx + 9, y + 13, k[2], 6.5, { faint = true })
    kx = kx + 12 + textWidth(k[2], 6.5) + 6
  end
  local sy = y + 30
  for _, s in ipairs(SKILLS) do
    c.mark(10, sy - 3.5, proficiencyMark(v.skillProf[s.key]))
    c.text(19, sy, s.name, 9.5)
    local abbr = s.ability:sub(1, 1):upper() .. s.ability:sub(2)
    c.text(128, sy, abbr, 7, { faint = true })
    if v.adv[s.key] then c.label(leftW - 34, sy - 0.5, "Adv", { anchor = "end" }) end
    c.text(leftW - 8, sy, signed(v.skills[s.key]), 10, { bold = true, anchor = "end" })
    sy = sy + 14.5
  end
  c.text(8, sy + 2, "Passive Insight", 8.5)
  c.text(leftW - 8, sy + 2, str(v.passive.insight), 9, { bold = true, anchor = "end" })
  c.text(8, sy + 15, "Passive Investigation", 8.5)
  c.text(leftW - 8, sy + 15, str(v.passive.investigation), 9, { bold = true, anchor = "end" })
  local leftBottom = y + leftH

  -- beside them the attacks, the second loadout and the resources
  local rx = leftW + gap
  local rw = W - rx
  local ry = y
  local attacks = items(d.attacks)
  local kit = type(d.kit) == "table" and d.kit or nil
  local resources = items(d.resources)
  local function header(top, title)
    local cols = attackCols(rx, rw)
    c.label(rx + 8, top + 13, title)
    c.label(cols.hit, top + 13, "Hit or DC")
    c.label(cols.damage, top + 13, "Damage")
    c.label(cols.notes, top + 13, "Notes")
    return top + 22
  end
  local function moreLine(yy, n)
    c.text(rx + 8, yy + 8, "and " .. tostring(n) .. " more, after this page", 7.5, { italic = true })
    return yy + 12
  end
  -- room for each: the attacks first, then the loadout, then the resources
  local kitRoom = kit and 70 or 0
  local resRoom = #resources > 0 and (26 + 15 * math.min(#resources, 6)) or 0
  local attackTop = ry
  local ay = header(attackTop, "Attacks")
  local shown
  ay, shown = attackRows(c, rx, ay, rw, attacks, leftBottom - kitRoom - resRoom - 12, cut.attacks)
  if #attacks == 0 then
    c.text(rx + 8, ay + 9, "None", 9, { faint = true })
    ay = ay + 14
  end
  if shown < #attacks then ay = moreLine(ay, #attacks - shown) end
  c.box(rx, attackTop, rw, ay - attackTop + 4, { r = 6 })
  ry = ay + 4 + gap

  if kit then
    local kitTop = ry
    local label = kit.label ~= nil and str(kit.label) or "Another loadout"
    local kl, ksize = fit("Loadout", label, rw - 110, 9.5, 7.5, true)
    c.text(rx + 8, kitTop + 13, kl, ksize, { bold = true, italic = true })
    if kit.ac ~= nil then
      c.label(rx + rw - 40, kitTop + 12, "Armor Class", { anchor = "end" })
      -- between its label and the box's edge
      local kac, kacsize = fit(label .. ": Armor Class", kit.ac, 26, 13, 8, true)
      c.text(rx + rw - 10, kitTop + 14, kac, kacsize, { bold = true, anchor = "end" })
    end
    local ky = kitTop + 20
    local kitAttacks = items(kit.attacks)
    local kshown
    ky, kshown = attackRows(c, rx, ky, rw, kitAttacks, leftBottom - resRoom - 12, cut.kit)
    if kshown < #kitAttacks then ky = moreLine(ky, #kitAttacks - kshown) end
    c.box(rx, kitTop, rw, ky - kitTop + 4, { r = 6 })
    ry = ky + 4 + gap
  end

  if #resources > 0 then
    local resTop = ry
    local yy = resTop + 13
    local useX, resetX = rx + rw * 0.4, rx + rw * 0.66
    c.label(rx + 8, yy, "Resources")
    c.label(resetX, yy, "Back after")
    yy = yy + 13
    local rshown = 0
    for _, r in ipairs(resources) do
      if yy + 4 > leftBottom - 14 then
        cut.resources[#cut.resources + 1] = r
      else
        local name = nameOf(r)
        local rn, rsize = fitted(name, useX - rx - 12, 9.5, 7.5, true)
        c.text(rx + 8, yy, rn, rsize, { bold = true })
        local uses = type(r) == "table" and whole(r.uses) or nil
        if uses and uses >= 1 and uses <= 10 then
          c.ticks(useX, yy - 3.5, uses, 10)
        elseif uses then
          c.text(useX, yy, str(uses), 9.5, { bold = true })
          c.box(useX + 24, yy - 10, 44, 13, { r = 2, weight = 0.8 })
        end
        local reset = type(r) == "table" and str(r.reset) or ""
        local rl, rlsize = fitted(reset, rx + rw - 8 - resetX, 8.5, 7)
        c.text(resetX, yy, rl, rlsize)
        if rn ~= name or rl ~= reset then cut.resources[#cut.resources + 1] = r end
        yy = yy + 15
        rshown = rshown + 1
      end
    end
    if rshown < #resources then yy = moreLine(yy - 8, #resources - rshown) + 8 end
    c.box(rx, resTop, rw, yy - resTop - 6, { r = 6 })
    ry = yy - 6 + gap
  end
  y = math.max(leftBottom, ry - gap) + gap

  -- spellcasting and its slots
  local slots = slotCounts(d.slots)
  local pact = whole(d.pact_slots)
  if v.casting or #slots > 0 or pact then
    local top = y
    c.label(8, top + 13, "Spellcasting")
    local ab = ""
    for _, a in ipairs(ABILITIES) do if a.key == v.casting then ab = a.name end end
    local fx = 90
    local function spellField(label, value, w)
      c.label(fx, top + 13, label)
      c.text(fx + textWidth(label:upper(), 6.5, true) + 4 + 0.6 * #label, top + 14, value, 11, { bold = true })
      fx = fx + w
    end
    spellField("Ability", ab, 130)
    spellField("Spell Save DC", str(v.spellDC), 120)
    spellField("Spell Attack Bonus", signed(v.spellAttack), 150)
    local sx, syy = 8, top + 34
    c.label(sx, syy, "Slots")
    sx = sx + 34
    local drawn = 0
    for level, n in ipairs(slots) do
      local count = whole(n) or 0
      if count > 0 then
        if sx + 20 + count * 10 > W - 8 then sx, syy = 42, syy + 16 end
        c.text(sx, syy + 0.5, ORDINAL[level] or tostring(level), 8.5, { bold = true })
        sx = c.ticks(sx + 20, syy - 3, count, 10) + 12
        drawn = drawn + 1
      end
    end
    if pact then
      local pl = whole(d.pact_level)
      local what = "Pact Magic" .. (pl and (", " .. (ORDINAL[pl] or tostring(pl)) .. " level") or "")
      if sx + textWidth(what, 8.5, true) + 20 + pact * 10 > W - 8 then sx, syy = 42, syy + 16 end
      c.text(sx, syy + 0.5, what, 8.5, { bold = true })
      sx = c.ticks(sx + textWidth(what, 8.5, true) + 6, syy - 3, pact, 10) + 12
    end
    if drawn == 0 and not pact then c.text(sx, syy + 0.5, "None", 8.5, { faint = true }) end
    local cantrips = items(d.cantrips)
    if #cantrips > 0 then
      syy = syy + 16
      c.label(8, syy, "Cantrips")
      local names = {}
      for _, e in ipairs(cantrips) do names[#names + 1] = nameOf(e) end
      local line, lsize = fitted(table.concat(names, ", "), W - 70, 9, 7.5)
      c.text(58, syy + 0.5, line, lsize)
    end
    c.box(0, top, W, syy - top + 10, { r = 6 })
    y = syy + 10 + gap
  end

  -- training and languages: two to a row where they fit, a row to one that doesn't
  local top = y
  c.label(8, top + 13, "Armor Training")
  local trained = set(d.armor_training)
  local tx = 90
  for _, t in ipairs({ "Light", "Medium", "Heavy", "Shields" }) do
    c.mark(tx + 3.5, top + 10, trained[key(t)] and "square" or "open square")
    c.text(tx + 11, top + 13, t, 9)
    tx = tx + 16 + textWidth(t, 9) + 8
  end
  local half = W / 2
  local ly, col = top + 13, 0
  for _, l in ipairs({ { "Weapons", d.weapons }, { "Masteries", d.masteries }, { "Tools", d.tools },
      { "Languages", d.languages }, { "Senses", d.senses } }) do
    local names = {}
    for _, e in ipairs(items(l[2])) do names[#names + 1] = nameOf(e) end
    if #names > 0 then
      local text = table.concat(names, ", ")
      if textWidth(text, 9) <= half - 80 then
        local lx = col == 0 and 8 or (half + 8)
        if col == 0 then ly = ly + 14 end
        c.label(lx, ly, l[1])
        c.text(lx + 64, ly + 0.5, text, 9)
        col = 1 - col
      else
        ly = ly + 14
        c.label(8, ly, l[1])
        local ls, over = lines(text, W - 80, 9, 2)
        for i, s in ipairs(ls) do c.text(72, ly + 0.5 + (i - 1) * 11, s, 9) end
        ly = ly + (#ls - 1) * 11
        if over then cut.lines[#cut.lines + 1] = { l[1], text } end
        col = 0
      end
    end
  end
  c.box(0, top, W, ly - top + 8, { r = 6 })
  y = ly + 8 + gap

  -- the features by name, and the equipment
  top = y
  local bottom = maxH - 10
  local groups = { { "Class Features", items(d.features) }, { "Species Traits", items(d.traits) }, { "Feats", items(d.feats) } }
  local fxw = W * 0.58
  local fy = top + 13
  c.label(8, fy, "Features and Traits")
  c.text(fxw - 8, fy, "in full after this page", 7, { italic = true, faint = true, anchor = "end" })
  fy = fy + 4
  local colW = (fxw - 16) / 2
  local fcol, fstart = 0, fy
  local fmax = fy
  local hidden = 0
  for _, g in ipairs(groups) do
    if #g[2] > 0 then
      local entries = { { g[1], true } }
      for _, e in ipairs(g[2]) do entries[#entries + 1] = { nameOf(e), false } end
      for _, e in ipairs(entries) do
        if fy + 12 > bottom - 18 and fcol == 0 then fcol, fy = 1, fstart end
        if fy + 12 <= bottom - 18 then
          fy = fy + (e[2] and 13 or 11)
          local lx = 8 + fcol * colW
          if e[2] then
            c.label(lx, fy, e[1])
          else
            local fn, fsize = fitted(e[1], colW - 10, 8.5, 7)
            c.text(lx + 4, fy, fn, fsize)
          end
          if fy > fmax then fmax = fy end
        elseif not e[2] then
          hidden = hidden + 1
        end
      end
    end
  end
  if hidden > 0 then
    fmax = fmax + 11
    c.text(8, fmax, "and " .. tostring(hidden) .. " more", 7.5, { italic = true })
  end

  local ex = fxw + gap
  local ew = W - ex
  local ey = top + 13
  c.label(ex + 8, ey, "Equipment")
  local equipment = items(d.equipment)
  local eshown = 0
  for _, e in ipairs(equipment) do
    if ey + 11 > bottom - 56 then break end
    ey = ey + 11
    local en, esize = fitted(nameOf(e), ew - 18, 8.5, 7)
    c.text(ex + 10, ey, en, esize)
    eshown = eshown + 1
  end
  if #equipment == 0 then
    ey = ey + 11
    c.text(ex + 10, ey, "None", 8.5, { faint = true })
  end
  if eshown < #equipment then
    ey = ey + 11
    c.text(ex + 10, ey, "and " .. tostring(#equipment - eshown) .. " more, after this page", 7.5, { italic = true })
  end
  -- the coins, one box to each
  ey = ey + 12
  local coins = type(d.coins) == "table" and d.coins or {}
  local cw = (ew - 16 - 4 * 4) / 5
  for i, coin in ipairs({ "cp", "sp", "ep", "gp", "pp" }) do
    local cx = ex + 8 + (i - 1) * (cw + 4)
    c.box(cx, ey, cw, 22, { r = 3, weight = 0.8 })
    c.label(cx + cw / 2, ey + 8, coin, { anchor = "middle" })
    local n = whole(coins[coin])
    if n and n ~= 0 then c.text(cx + cw / 2, ey + 19, str(n), 9, { bold = true, anchor = "middle" }) end
  end
  ey = ey + 22
  local ebottom = math.min(math.max(fmax + 8, ey + 8), maxH - 1)
  c.box(0, top, fxw, ebottom - top, { r = 6 })
  c.box(ex, top, ew, ebottom - top, { r = 6 })
  local H = math.min(math.floor(ebottom + 1), maxH)

  local svg = '<svg xmlns="http://www.w3.org/2000/svg" width="' .. px(W) .. '" height="' .. px(H) ..
    '" viewBox="0 0 ' .. px(W) .. " " .. px(H) .. '" style="display:block" role="img" aria-label="' ..
    esc("Character sheet: " .. name) .. '" font-family="' .. FONT .. '" fill="' .. INK .. '">' ..
    table.concat(c.out) .. "</svg>"
  return svg, H, cut
end

------------------------------------------------------------------ the text

-- A line that opens with a short title of its own, "Initiative Swap. When
-- you ...", with that title set as a bold italic lead.
local MINOR = { a = true, an = true, the = true, of = true, ["and"] = true, ["or"] = true,
  to = true, ["in"] = true, on = true, ["for"] = true, with = true, from = true, at = true, by = true }
local function lead(line)
  if line:match("^[%*_#>|%-]") then return line end
  local title, rest = line:match("^([^%.]+)%.%s+(%S.*)$")
  if not title or #title > 40 then return line end
  local words = 0
  for word in title:gmatch("%S+") do
    words = words + 1
    local first = word:sub(1, 1)
    if not (first:match("%u") or MINOR[word]) or word:match("[^%a'’%-]") then return line end
  end
  if words == 0 or words > 5 then return line end
  return "***" .. title .. ".*** " .. rest
end

-- A feature's text as paragraphs: one to a line, with a list's items kept
-- together.
local function paragraphs(text)
  local out = {}
  for line in (str(text) .. "\n"):gmatch("([^\n]*)\n") do
    local l = (line:gsub("%s+$", ""))
    if l:match("%S") then out[#out + 1] = l end
  end
  return out
end

local function isItem(l) return l:match("^%s*[-*+]%s") or l:match("^%s*%d+[.)]%s") end
local function isRow(l) return l:match("^%s*|") ~= nil end

local function entryText(e)
  if type(e) == "table" then return str(e.name), e.text end
  return str(e), nil
end

-- A sentence ends in its own stop, or gets one.
local function stopped(s)
  if s:match("[%.!?]$") then return s end
  return s .. "."
end

-- An attack in words, as the text after the page gives one it cut short:
-- "***Grapple.*** DC 14 Str or Dex, Grappled. A free hand needed."
local function attackLine(a, label)
  if type(a) ~= "table" then return "***" .. safe(a) .. ".***" end
  local parts = {}
  if type(a.hit) == "number" then parts[#parts + 1] = signed(math.floor(a.hit)) .. " to hit"
  elseif a.hit ~= nil then parts[#parts + 1] = safe(a.hit) end
  if a.damage ~= nil then parts[#parts + 1] = safe(a.damage) end
  local s = "***" .. safe(a.name) .. ".*** " .. (label and (safe(label) .. ": ") or "") ..
    stopped(table.concat(parts, ", "))
  if a.notes ~= nil and str(a.notes) ~= "" then s = s .. " " .. stopped(safe(a.notes)) end
  return s
end

-- Everything after the drawn page, as Markdown: what the page had to cut
-- short, then the features, traits and feats in full under their headings,
-- then the spells and the equipment.
function sheets.text(d, v, cut)
  cut = cut or {}
  local out = {}
  local function add(s)
    out[#out + 1] = s
  end
  local function block(lines)
    for i, l in ipairs(lines) do
      local together = (isItem(l) and isItem(lines[i - 1] or "")) or (isRow(l) and isRow(lines[i - 1] or ""))
      if i > 1 and not together then add("") end
      add(l)
    end
    add("")
  end
  local function group(title, list)
    list = items(list)
    if #list == 0 then return end
    add("## " .. title)
    add("")
    for _, e in ipairs(list) do
      local name, text = entryText(e)
      add("### " .. safe(name))
      add("")
      local ps = paragraphs(text)
      for i, p in ipairs(ps) do ps[i] = lead(safe(p)) end
      if #ps > 0 then block(ps) end
    end
  end
  -- what the drawn page cut short or left out, in full: single values
  -- first, a subclass or an Armor Class with a note, each under its label
  for _, f in ipairs(items(cut.fields)) do
    add("**" .. safe(f[1]) .. ".** " .. stopped(safe(f[2])))
    add("")
  end
  local cutAttacks, cutKit = items(cut.attacks), items(cut.kit)
  if #cutAttacks > 0 or #cutKit > 0 then
    add("## Attacks")
    add("")
    for _, a in ipairs(cutAttacks) do
      add(attackLine(a))
      add("")
    end
    local kit = type(d.kit) == "table" and d.kit or {}
    local label = kit.label ~= nil and str(kit.label) or "Another loadout"
    for _, a in ipairs(cutKit) do
      add(attackLine(a, label))
      add("")
    end
  end
  local cutResources = items(cut.resources)
  if #cutResources > 0 then
    add("## Resources")
    add("")
    for _, r in ipairs(cutResources) do
      local s = "***" .. safe(nameOf(r)) .. ".***"
      if type(r) == "table" then
        if r.uses ~= nil then s = s .. " " .. safe(r.uses) .. (r.reset ~= nil and ";" or ".") end
        if r.reset ~= nil then s = s .. " back after " .. stopped(safe(r.reset)) end
      end
      add(s)
      add("")
    end
  end
  local cutLines = items(cut.lines)
  if #cutLines > 0 then
    add("## Proficiencies")
    add("")
    for _, l in ipairs(cutLines) do
      add("**" .. l[1] .. ".** " .. stopped(safe(l[2])))
      add("")
    end
  end

  group("Class Features", d.features)
  group("Species Traits", d.traits)
  group("Feats", d.feats)

  -- the spells, a paragraph for each level, then any listed with no level
  local cantrips = items(d.cantrips)
  local levels, mineList = spellLists(d.spells, "spells")
  local always, alwaysList = spellLists(d.always_prepared, "always_prepared")
  local book, bookList = spellLists(d.spellbook, "spellbook")
  local unlevelled = {
    { "Prepared", mineList }, { "Always prepared", alwaysList }, { "In the spellbook, not prepared", bookList },
  }
  local any = #cantrips > 0 or #levels > 0 or #always > 0 or #book > 0
  for _, u in ipairs(unlevelled) do any = any or #u[2] > 0 end
  if any then
    add("## Spells")
    add("")
    local ab = ""
    for _, a in ipairs(ABILITIES) do if a.key == v.casting then ab = a.name end end
    if ab ~= "" then
      add("**Spellcasting ability** " .. ab .. " · **Spell save DC** " .. str(v.spellDC) ..
        " · **Spell attack bonus** " .. signed(v.spellAttack))
      add("")
    end
    local function listed(list)
      local t = {}
      for _, e in ipairs(list) do t[#t + 1] = spellText(e) end
      return table.concat(t, ", ")
    end
    if #cantrips > 0 then
      add("**Cantrips.** " .. listed(cantrips) .. ".")
      add("")
    end
    local slots = slotCounts(d.slots)
    local all = {}
    for _, l in ipairs(levels) do all[l.level] = { mine = l.list } end
    for _, l in ipairs(always) do
      all[l.level] = all[l.level] or {}
      all[l.level].always = l.list
    end
    for _, l in ipairs(book) do
      all[l.level] = all[l.level] or {}
      all[l.level].book = l.list
    end
    local order = {}
    for level in pairs(all) do order[#order + 1] = level end
    table.sort(order)
    for _, level in ipairs(order) do
      local e = all[level]
      local head = "**Level " .. tostring(level)
      local n = whole(slots[level])
      if n and n > 0 then head = head .. " (" .. tostring(n) .. (n == 1 and " slot" or " slots") .. ")" end
      local parts = {}
      if e.mine and #e.mine > 0 then parts[#parts + 1] = listed(e.mine) end
      if e.always and #e.always > 0 then parts[#parts + 1] = "always prepared: " .. listed(e.always) end
      if e.book and #e.book > 0 then parts[#parts + 1] = "in the spellbook, not prepared: " .. listed(e.book) end
      if #parts > 0 then
        add(head .. ".** " .. table.concat(parts, "; ") .. ".")
        add("")
      end
    end
    -- a list written with no levels is given as it is written
    for _, u in ipairs(unlevelled) do
      if #u[2] > 0 then
        add("**" .. u[1] .. ".** " .. listed(u[2]) .. ".")
        add("")
      end
    end
    local pact = whole(d.pact_slots)
    if pact then
      local pl = whole(d.pact_level)
      add("**Pact Magic.** " .. tostring(pact) .. (pact == 1 and " slot" or " slots") ..
        (pl and (" of level " .. tostring(pl)) or "") .. ", back after a Short or Long Rest.")
      add("")
    end
  end

  -- the equipment, the coins and the second loadout's gear
  local equipment = items(d.equipment)
  local kit = type(d.kit) == "table" and d.kit or nil
  local attuned = items(d.attuned)
  local coins = type(d.coins) == "table" and d.coins or {}
  local coinText = {}
  for _, coin in ipairs({ "pp", "gp", "ep", "sp", "cp" }) do
    local n = whole(coins[coin])
    if n and n ~= 0 then coinText[#coinText + 1] = tostring(n) .. " " .. coin:upper() end
  end
  local kitGear = kit and items(kit.equipment) or {}
  if #equipment > 0 or #attuned > 0 or #coinText > 0 or #kitGear > 0 then
    add("## Equipment")
    add("")
    local function list(t)
      local names = {}
      for _, e in ipairs(t) do names[#names + 1] = safe(nameOf(e)) end
      return table.concat(names, "; ")
    end
    if #equipment > 0 then
      add(list(equipment) .. ".")
      add("")
    end
    if #coinText > 0 then
      add("**Coins.** " .. table.concat(coinText, ", ") .. ".")
      add("")
    end
    if #attuned > 0 then
      add("**Attuned.** " .. list(attuned) .. ".")
      add("")
    end
    if #kitGear > 0 then
      local label = kit.label ~= nil and safe(kit.label) or "Another loadout"
      add("**" .. label .. ".** " .. list(kitGear) .. ".")
      add("")
    end
  end

  while #out > 0 and out[#out] == "" do out[#out] = nil end
  return table.concat(out, "\n")
end

------------------------------------------------------------------ drawing one

local function missing(text)
  return widget.new {
    html = '<em class="gmsheets-missing">' .. esc(text) .. "</em>",
    markdown = "*" .. safe(text) .. "*",
    display = "block",
  }
end

-- A sheet from a page: its frontmatter, the drawing and the text after it.
-- Nil, and why, for a page it can't be drawn from. `printing` for the
-- printer alone, which reads the page a build is printing.
local function drawn(ref, printing)
  local page = ref or sheets.here(printing)
  if not page then return nil, "No page to draw a sheet from." end
  page = sheets.find(page) or page
  local d, why = sheets.read(page)
  if not d then return nil, why end
  local v = sheets.values(d)
  local svg, _, cut = sheets.svg(d, v, page)
  return { data = d, svg = svg, text = sheets.text(d, v, cut) }
end

-- The Markdown face: the drawing in a block two columns wide, which GM
-- Book gives a page of its own, then the text.
local function printedFace(s)
  local out = '<div class="gmsheets-page" style="column-span:all">\n' .. s.svg .. "\n</div>"
  if s.text ~= "" then out = out .. "\n\n" .. s.text end
  return out
end

-- The sheet on the page and in print: the drawn page, then the text after
-- it. A page it can't be drawn from shows why.
function sheets.draw(ref, opts)
  if type(ref) == "table" and opts == nil then ref, opts = nil, ref end
  opts = opts or {}
  local s, why = drawn(ref)
  if not s then return missing(why) end
  local html = '<div class="gmsheets">'
  -- what the sheet leaves out because it can't read it, for the DM: on the
  -- page only, never in the Markdown face that prints and goes to players
  local problems = sheets.problems(s.data)
  if #problems > 0 then
    html = html .. '<p class="gmsheets-warn">' .. esc("⚠ Left off the sheet, since it can't read them: " ..
      table.concat(problems, "; ") .. ".") .. "</p>"
  end
  html = html .. '<div class="gmsheets-page">' .. s.svg .. "</div>"
  if s.text ~= "" then
    html = html .. '<div class="gmsheets-text">' .. markdown.markdownToHtml(s.text) .. "</div>"
  end
  html = html .. "</div>"
  return widget.new { html = html, markdown = printedFace(s), display = "block" }
end

------------------------------------------------------------------ in print

-- What a sheet prints as: the widget's Markdown face. GM Book evaluates an
-- expression with sheets standing for this table. A sheet that can't be
-- drawn prints nothing at all, not the page's message: it raises the reason,
-- GM Book then keeps the edition back and names the page with that reason,
-- so a book never goes out with a note where a character should be.
sheets.printed = setmetatable({
  draw = function(ref, opts)
    if type(ref) == "table" and opts == nil then ref = nil end
    local s, why = drawn(ref, true)
    if not s then error(why or "No sheet to draw.", 0) end
    return printedFace(s)
  end,
}, { __index = sheets })

gmbook = gmbook or {}
gmbook.printers = gmbook.printers or {}
gmbook.printers.sheets = sheets.printed
```

```space-style
/* The sheet draws in one dark ink, which a dark theme would swallow, so on
   the page it sits on paper of its own. Its padding counts in its width:
   SilverBullet sets border-box only on its standalone pages, and without
   it a sheet at full width would run 12px past its frame. Its width is the
   one it is drawn at, not its width attribute taken as the whole box. */
.gmsheets-page svg {
  box-sizing: border-box;
  width: auto;
  max-width: 100%;
  height: auto;
  background: #faf7f0;
  border-radius: 2px;
  padding: 6px;
}

.gmsheets-page {
  overflow-x: auto;
}

/* On a phone the sheet would shrink to half its size and its labels to
   three pixels. There it keeps the size it is drawn at, as on a wider
   screen, and scrolls sideways in its own frame. Printing is left as it
   is. */
@media screen and (max-width: 600px) {
  .gmsheets-page svg {
    max-width: none;
  }
}

.gmsheets-missing {
  color: var(--subtle-color);
}

.gmsheets-warn {
  margin: 0 0 6px;
}

.gmsheets-missing::before {
  content: "⚠ ";
  font-style: normal;
}
```
