---
tags: meta/library
name: "Library/Storie/GM Beyond"
description: "D&D Beyond characters in SilverBullet: a live roster from public character data, and an import that turns a character's link into a full character page, with every number on the sheet worked out from D&D Beyond's raw data, ready for GM Sheets to draw."
author: "Steven Storie"
version: "2.1.0"
---

# GM Beyond

Bring D&D Beyond characters into SilverBullet: a live roster of the party, and an import that writes a character's whole sheet into a page of its own.

## What this does and doesn't do

**Does:** fetches a public character's raw data and works out the sheet from it, the way D&D Beyond's own sheet does: ability scores, Armor Class, Hit Points, saving throws, skills, passives, initiative, attacks, spell save DC and attack bonus, spell slots, the spells, features, traits and feats with their rules, resources, proficiencies, languages and equipment. The page it writes is in [GM Sheets](<GM Sheets>)' shape, so GM Sheets draws it.

**Doesn't:** embed sheets. D&D Beyond sends frame-blocking headers, so an iframe will not work, ever. Anyone offering you a D&D Beyond "embed" means a link.

**Doesn't track play.** Current Hit Points, spent slots and conditions change at the table; the page holds the sheet, not the state of the fight.

**Works it out, so check it.** The endpoint returns raw data, not the numbers D&D Beyond's sheet shows, so the import reimplements the rules those numbers come from: the modifiers each species, class, feat and item grants, armor and its limits, unarmored defenses, proficiency, and spell slots across classes. It matches D&D Beyond's own sheet on the characters it has been checked against, and a character built from something it doesn't know — a homebrew item with an unusual bonus, say — can come out wrong. Import, then compare the page with the character on D&D Beyond once. A number that differs can be written on the page by hand, and it wins, until the next refresh.

## How it works

`net.proxyFetch` runs server-side, so there's no CORS wall between your space and D&D Beyond's character service — the same unofficial endpoint Beyond20, Avrae and ddb-importer all use. Characters must have privacy set to **public**. It's undocumented and does break occasionally; failures degrade to an italic placeholder or a notification rather than erroring the page, and the notification says which failure it was: the character is private or deleted (D&D Beyond's 403 or 404), D&D Beyond is taking too many requests just now (429, so try again shortly), something is wrong at D&D Beyond (a 5xx), the server couldn't reach D&D Beyond at all, or what came back wasn't a character.

## Importing a character

`GM: Import Character` asks for the character's D&D Beyond link, or just its number, and writes a page for it: `Characters/Tamsin Reed`, with the sheet in its frontmatter, then the name, the sheet drawn with `${sheets.draw()}`, and a plain link back to D&D Beyond. The notification opens the page, and has *Undo*, which takes the page away again as long as it holds only what the import wrote. The page's name leaves out what SilverBullet's links can't carry, `@ # $ | < > [ ] ^ / \`, and an ending it would take for a file's extension: `Zed <the Bold>` is `Characters/Zed the Bold`, and `Dr.Who` is `Characters/Dr Who`. A character D&D Beyond sends without a class isn't written at all, since it would come out as a level 1 character with every score 10.

To put a button for it on a page of your own, such as the party's:

    ${widgets.commandButton("Import a character", "GM: Import Character")}

**Refreshing.** An imported page has a bar across its top with *Refresh from D&D Beyond*, or run `GM: Refresh Character` on it. A refresh fetches the character again and rewrites every key the import writes, and nothing else: the page's text, and any key the import doesn't write, such as `player`, `away`, `kit`, `pb` or a campaign's own, stay as they are, and so does any other line of the frontmatter, a comment or a key with a space or quotes in its name. If the page is open, what has been typed into it is saved first. A refresh that would lower the character's level asks before it writes. Its notification has *Undo* too, which puts the page back as it was while it still holds what the refresh wrote; anything changed since is kept.

Importing a character whose page already exists refreshes that page, found by the character's number in its `ddb` among the pages in the folder, so a character renamed on D&D Beyond keeps its page: the notification says the name has changed, and the page keeps its own. Failing that, a page of the character's name is refreshed if it is that character's. If SilverBullet can't tell whether that page exists, or can't read it, nothing is written.

**What the page holds.** The keys are [GM Sheets](<GM Sheets>)', and the import writes a number only where it isn't the SRD's sum, the way you would by hand: a Stone of Good Luck's bonus to every check, Jack of All Trades on the skills without proficiency, a magic item's bonus to spell attacks. Features, traits and feats carry their rules in full, from D&D Beyond's own text, so **keep the pages private**: that text is licensed to the account that owns the books, not yours to publish. A wizard's spellbook comes in as `spellbook`, the spells in it not prepared. Every spell, cantrips included, comes with how it is cast: its casting time and range, and whether it needs concentration, a ritual or a material.

**Every spell, whatever the class.** A class that casts nothing itself can still have spells: an Eldritch Knight's or an Arcane Trickster's come through the subclass, with its spellcasting ability and its slots, a third caster's own table or its share of the multiclass one. The spells a species, a feat such as Magic Initiate (which the 2024 Acolyte, Guide and Sage backgrounds grant), a background, a class feature or an item gives come in too, cantrips as cantrips and the rest as always prepared; an item's while it is equipped, and attuned where it must be, with the item's name in its notes. Each spell is cast with its own ability, the one D&D Beyond gives it or its class's: `spellcasting` is the first class's own, or else a subclass's, or else the one those spells use, and a spell cast with another says so in its notes, with its save DC and attack bonus. A damaging cantrip's attack is rolled with its own ability too.

**What a player writes stays words.** Everything on a D&D Beyond character is written by its player, homebrew rules text and every name included, so none of it reaches your page as markup. Each name is one line, however it was written. Rules text comes in as Markdown with any tag, link, image, hashtag or `${...}` written in it escaped, so it shows as written: `&lt;form&gt;` in D&D Beyond's text is the words `<form>` on the page, never a form. In the frontmatter a name's `<` and `>` are written as YAML's `\x3C` and `\x3E`, which every YAML reader turns back into the characters, and the page's heading and the live roster escape each name as they show it.

## Settings

    config.set("gmBeyond", { folder = "Party/" })

`folder` is where imported characters' pages go, `Characters/` unless you say otherwise.

## The live roster

Put the numeric character id in frontmatter:

```yaml
---
type: pc
player: Sam
ddb: 147258369
---
```

Then anywhere:

    ${gmb.summary(147258369)}

Or across a roster:

    ${query[[
      from p = index.pages()
      where p.type == "pc" and p.ddb
      select gmb.summary(p.ddb)
    ]]}

A summary is Markdown with each name in it escaped, since the character's player wrote them, and a character that can't be fetched shows as *(private or unreachable)*, whatever D&D Beyond answered. Always keep a plain link too, so the page stays useful when the fetch doesn't:

    [Sheet](https://www.dndbeyond.com/characters/147258369)

## Licensing note

Link to monsters and rules content in anything you publish; don't mirror it. SRD material is open, the rest isn't. The import copies a character's rules text into your own space for your own table, which is why its pages belong in a space only you can read.

## Changes in 2.1

**What a player writes stays words.** Every name is one line and escaped for Markdown, rules text comes in with any tag, link or `${...}` in it escaped, and a frontmatter value never holds a line break or a raw `<` or `>`. See *Importing a character*.

**Every spell, whatever the class.** A subclass that casts, such as an Eldritch Knight or an Arcane Trickster, gets its slots and spells, and spells from a species, a background, a feat or an item are written whatever the class, each with its own spellcasting ability.

**A refresh keeps what the GM added.** `kit` and `pb` are yours now, and so is any other line of the frontmatter the import doesn't write. A character renamed on D&D Beyond refreshes the page it already has, found by its `ddb` number. An error reading the page stops the import rather than writing over it, *Undo* takes back only what the import wrote, the page open in the editor is saved first, a character with no classes is refused, and a refresh that would lower the level asks first.

**Each refusal says why**: a private or deleted character, D&D Beyond asking you to wait, trouble at D&D Beyond, or the server not reaching it. Unarmored Defense counts a negative Dexterity against you, and a character's name is cleaned of what SilverBullet's links can't carry before it names a page.

## Implementation

```space-lua
-- priority: 10
gmb = gmb or {}

gmb.endpoint = "https://character-service.dndbeyond.com/character/v5/character/"
gmb.sheetLink = "https://www.dndbeyond.com/characters/"

gmb.config = {
  folder = "Characters/",  -- where an imported character's page goes
}

function gmb.setting(key)
  local value = config.get("gmBeyond." .. key, nil)
  if value == nil then value = gmb.config[key] end
  return value
end

------------------------------------------------------------------ text

-- A JavaScript array or a Lua list as a Lua list; nothing as an empty one.
local function list(v)
  local out = {}
  if v == nil then return out end
  for _, x in ipairs(v) do out[#out + 1] = x end
  return out
end

local function num(v)
  if type(v) == "number" then return v end
  if type(v) == "string" then return tonumber(v) end
  return nil
end

local function whole(v)
  local n = num(v)
  if n == nil then return nil end
  return math.floor(n)
end

-- A value from D&D Beyond as one line of text: control characters, a
-- newline among them, and Unicode's line and paragraph separators as
-- spaces, and a run of spaces as one. Everything a player can name on D&D
-- Beyond passes through here before it reaches a page, so no name can end
-- the frontmatter or start a line of the page's own.
function gmb.line(v)
  if v == nil then return nil end
  local s = tostring(v)
  s = (s:gsub("%c", " "))
  s = (s:gsub("\u{85}", " "))
  s = (s:gsub("\u{2028}", " "))
  s = (s:gsub("\u{2029}", " "))
  s = (s:gsub("%s+", " "))
  s = (s:gsub("^ ", ""))
  return (s:gsub(" $", ""))
end

-- The characters Markdown, and SilverBullet's own syntax, read as markup: a
-- tag or a comment, a link, an image or a transclusion, an expression ${...},
-- a hashtag, emphasis, code, a table's cell, and the backslash that escapes
-- the rest.
local MARKUP = "[\\`*_{}%[%]<>#|$]"

-- Text as Markdown that shows it as it is, on one line: each character that
-- would be read as markup escaped with a backslash, and an & that would
-- start an entity too, so a tag, a link or an expression in a name stays
-- words. SilverBullet renders a backslash escape as the character, where it
-- shows an entity such as &lt; as written.
function gmb.inline(v)
  local s = gmb.line(v) or ""
  s = (s:gsub(MARKUP, "\\%0"))
  return (s:gsub("&(#?%w+;)", "\\&%1"))
end

------------------------------------------------------------------ fetching

-- Why D&D Beyond's answer holds no character, for a notification: the
-- status D&D Beyond gave, or the server's own failure to reach it. The
-- server's proxy answers 200 with D&D Beyond's status whenever D&D Beyond
-- answered at all, so `ok` false with a status of its own is the server's.
function gmb.refusal(res)
  local status = whole(res and res.status)
  if status == 401 or status == 403 or status == 404 then
    return "D&D Beyond answered " .. tostring(status) ..
      ": the character is private, or has been deleted. Its privacy must be Public"
  elseif status == 429 then
    return "D&D Beyond answered 429: too many requests just now, so try again shortly"
  elseif res and res.ok == false then
    local said = type(res.body) == "string" and gmb.line(res.body) or ""
    if #said > 120 then said = said:sub(1, 120) .. "…" end
    return "the server couldn't reach D&D Beyond (it answered " .. tostring(status or "nothing") ..
      (said ~= "" and (": " .. said) or "") .. ")"
  elseif status and status >= 500 then
    return "D&D Beyond answered " .. tostring(status) .. ": something is wrong at D&D Beyond, so try again later"
  elseif status == 200 then
    return "D&D Beyond's answer wasn't a character's data"
  end
  return "D&D Beyond answered " .. tostring(status or "nothing")
end

--- Fetch a public DDB character. Returns nil and a reason when private or unreachable.
function gmb.fetch(id)
  local url = gmb.endpoint .. tostring(id)
  -- Asked for as JSON, which net.proxyFetch then parses whatever the
  -- answer's Content-Type says. An answer that isn't JSON, such as an error
  -- page, makes it throw, so that is asked for again as it comes, for its
  -- status; a second throw is the server failing to fetch at all.
  local ok, res = pcall(net.proxyFetch, url, { responseEncoding = "application/json" })
  if not ok then
    local again, plain = pcall(net.proxyFetch, url)
    if not again then return nil, "couldn't reach D&D Beyond through the server: " .. gmb.line(plain) end
    res = plain
  end
  if type(res) ~= "table" then return nil, "couldn't reach D&D Beyond through the server" end
  if whole(res.status) ~= 200 then return nil, gmb.refusal(res) end
  local body = res.body
  local data = type(body) == "table" and body.data or nil
  if type(data) ~= "table" then return nil, gmb.refusal(res) end
  return data
end

--- "Brin — Half-Elf Rogue 4 / Warlock 2", as Markdown: every name escaped,
--- since a player writes them.
function gmb.summary(id)
  local ok, c = pcall(gmb.fetch, id)
  if not ok or type(c) ~= "table" then return "_(private or unreachable)_" end
  local classes = {}
  for _, cl in ipairs(list(c.classes)) do
    local level = whole(cl.level)
    classes[#classes + 1] = gmb.inline(cl.definition and cl.definition.name or "?") .. " " ..
      (level and tostring(level) or "?")
  end
  local race = c.race and c.race.fullName or ""
  return gmb.inline(c.name or "?") .. " — " .. gmb.inline(race) .. " " .. table.concat(classes, " / ")
end

--- Total level across all classes.
function gmb.level(id)
  local c = gmb.fetch(id)
  if not c then return nil end
  local total = 0
  for _, cl in ipairs(list(c.classes)) do total = total + (whole(cl.level) or 0) end
  return total
end

-- The character's number in a link to it, or the number itself:
-- dndbeyond.com/characters/147258369, .../147258369/AbCd, or 147258369.
function gmb.idOf(link)
  local s = tostring(link or "")
  local id = s:match("characters/(%d+)") or s:match("^%s*(%d+)%s*$")
  return id and tonumber(id) or nil
end

------------------------------------------------------------------ the data

local ABILITY = { "str", "dex", "con", "int", "wis", "cha" }
local LONG = { "strength", "dexterity", "constitution", "intelligence", "wisdom", "charisma" }
local SHORT = { "Str", "Dex", "Con", "Int", "Wis", "Cha" }

-- D&D Beyond's skills, by its slug, with the ability each uses.
local SKILLS = {
  { "acrobatics", 2 }, { "animal-handling", 5 }, { "arcana", 4 }, { "athletics", 1 },
  { "deception", 6 }, { "history", 4 }, { "insight", 5 }, { "intimidation", 6 },
  { "investigation", 4 }, { "medicine", 5 }, { "nature", 4 }, { "perception", 5 },
  { "performance", 6 }, { "persuasion", 6 }, { "religion", 4 }, { "sleight-of-hand", 2 },
  { "stealth", 2 }, { "survival", 5 },
}

-- The SRD's slots for a multiclassed spellcaster, by caster level.
local SLOTS = {
  { 2 }, { 3 }, { 4, 2 }, { 4, 3 }, { 4, 3, 2 }, { 4, 3, 3 }, { 4, 3, 3, 1 }, { 4, 3, 3, 2 },
  { 4, 3, 3, 3, 1 }, { 4, 3, 3, 3, 2 }, { 4, 3, 3, 3, 2, 1 }, { 4, 3, 3, 3, 2, 1 },
  { 4, 3, 3, 3, 2, 1, 1 }, { 4, 3, 3, 3, 2, 1, 1 }, { 4, 3, 3, 3, 2, 1, 1, 1 },
  { 4, 3, 3, 3, 2, 1, 1, 1 }, { 4, 3, 3, 3, 2, 1, 1, 1, 1 }, { 4, 3, 3, 3, 3, 1, 1, 1, 1 },
  { 4, 3, 3, 3, 3, 2, 1, 1, 1 }, { 4, 3, 3, 3, 3, 2, 2, 1, 1 },
}

local SIZES = { [2] = "Tiny", [3] = "Small", [4] = "Medium", [5] = "Large", [6] = "Huge", [7] = "Gargantuan" }
local RESETS = { [1] = "Short Rest", [2] = "Long Rest", [3] = "Dawn" }

-- Class features every class has, which say nothing a sheet doesn't.
local BOILERPLATE = { ["Hit Points"] = true, ["Proficiencies"] = true, ["Equipment"] = true }

-- D&D Beyond's kinds of thing a proficiency is for.
local TOOL, WEAPON = 2103445194, 1782728300

local function mod(score) return math.floor(((score or 10) - 10) / 2) end

local function signed(n)
  if n >= 0 then return "+" .. tostring(n) end
  return "-" .. tostring(-n)
end

-- "Crossbow, Light" as D&D Beyond's slug, crossbow-light.
local function slug(s)
  local out = tostring(s or ""):lower()
  out = (out:gsub("[^%w]+", "-"))
  out = (out:gsub("^%-+", ""))
  return (out:gsub("%-+$", ""))
end

local function capital(s)
  s = tostring(s or "")
  return s:sub(1, 1):upper() .. s:sub(2)
end

-- An item the character has on, and attuned to where it must be: its
-- modifiers count.
local function active(it)
  local def = it.definition or {}
  if it.isAttuned == true and (it.equipped == true or def.canEquip ~= true) then return true end
  if def.canAttune ~= true and it.equipped == true then return true end
  if def.canEquip ~= true and def.canAttune ~= true and def.isConsumable ~= true then return true end
  return false
end

-- Every modifier that counts, from the species, classes, background, feats
-- and items, each as a plain table: a class's only once the character has
-- reached the feature it comes with, and a class's own proficiencies only
-- for the class they started in.
function gmb.modifiers(c)
  local out = {}
  local reached, every = {}, {}
  for _, cl in ipairs(list(c.classes)) do
    local level = num(cl.level) or 0
    for _, f in ipairs(list(cl.classFeatures)) do
      local def = f.definition
      if def then
        local id = tostring(def.id)
        every[id] = true
        if (num(def.requiredLevel) or 0) <= level then reached[id] = cl end
      end
    end
  end
  local function add(m, source, item)
    out[#out + 1] = {
      type = m.type, subType = m.subType, value = num(m.value) or num(m.fixedValue),
      statId = num(m.statId), entityId = num(m.entityId), entityTypeId = num(m.entityTypeId),
      restriction = m.restriction, componentId = tostring(m.componentId), source = source,
      friendly = m.friendlySubtypeName, item = item,
    }
  end
  local mods = c.modifiers or {}
  for _, source in ipairs({ "race", "background", "feat", "condition" }) do
    for _, m in ipairs(list(mods[source])) do add(m, source) end
  end
  for _, m in ipairs(list(mods.class)) do
    local id = tostring(m.componentId)
    local cl = reached[id]
    if not every[id] or cl then
      if not (cl and m.availableToMulticlass == false and cl.isStartingClass ~= true) then
        add(m, "class")
      end
    end
  end
  for _, it in ipairs(list(c.inventory)) do
    if active(it) then
      for _, m in ipairs(list((it.definition or {}).grantedModifiers)) do add(m, "item", it) end
    end
  end
  return out
end

local function unrestricted(m) return m.restriction == nil or m.restriction == "" end

-- The modifiers of a type and subtype that always apply; `any` takes the
-- ones with a restriction too.
local function find(mods, kind, sub, any)
  local out = {}
  for _, m in ipairs(mods) do
    if m.type == kind and (sub == nil or m.subType == sub) and (any or unrestricted(m)) then
      out[#out + 1] = m
    end
  end
  return out
end

local function total(ms)
  local t = 0
  for _, m in ipairs(ms) do t = t + (m.value or 0) end
  return t
end

local function has(mods, kind, sub, any) return #find(mods, kind, sub, any) > 0 end

-- A stat by its id in D&D Beyond's list of six.
local function stat(stats, id)
  for _, s in ipairs(list(stats)) do
    if num(s.id) == id then return num(s.value) end
  end
  return nil
end

-- Restrictions on an ability score bonus that don't stop it counting.
local PLAIN_BONUS = {
  ["+2 to score maximum"] = true, ["+4 to score maximum"] = true,
  ["+2 to maximum score"] = true, ["+4 to maximum score"] = true,
  ["Can't be an Ability Score you already increased with this trait."] = true,
  ["That you do not have Saving Throw Proficiency in."] = true,
}

-- Whether a 2024 background gives the ability score increases, as a feat,
-- in which case the species' own don't count.
local function backgroundScores(c)
  local def = c.background and c.background.definition
  for _, f in ipairs(list(def and def.grantedFeats)) do
    if tostring(f.name or ""):find("Ability Score", 1, true) then return true end
  end
  return false
end

-- The six ability scores, as D&D Beyond's sheet works them out.
function gmb.scores(c, mods)
  local skipSpecies = backgroundScores(c)
  local out = {}
  for i = 1, 6 do
    local sub = LONG[i] .. "-score"
    local base = stat(c.stats, i) or 10
    local bonus, capped, cap = 0, 0, 20
    for _, m in ipairs(mods) do
      if m.type == "bonus" and m.subType == "ability-score-maximum" and m.statId == i and unrestricted(m) then
        cap = cap + (m.value or 0)
      end
    end
    local set = 0
    for _, m in ipairs(mods) do
      if m.subType == sub and m.value and not (m.source == "race" and skipSpecies) then
        local r = m.restriction
        if m.type == "bonus" then
          if r == nil or r == "" or PLAIN_BONUS[r] then
            bonus = bonus + m.value
          else
            local max = tostring(r):match("[Mm]aximum is now (%d+)") or tostring(r):match("[Mm]aximum of (%d+)")
            if max then
              capped = capped + m.value
              if tonumber(max) > cap then cap = tonumber(max) end
            end
          end
        elseif m.type == "set" and (r == nil or r == "" or r == "if not already higher") then
          if m.value > set then set = m.value end
        end
      end
    end
    local score = math.min(cap, base + bonus + capped) + (stat(c.bonusStats, i) or 0)
    if set > score then score = set end
    local override = stat(c.overrideStats, i)
    if override and override ~= 0 then score = override end
    out[ABILITY[i]] = math.floor(score)
  end
  return out
end

local function characterValues(c, typeId)
  local out = {}
  for _, v in ipairs(list(c.characterValues)) do
    if num(v.typeId) == typeId then out[#out + 1] = v end
  end
  return out
end

-- The class each class feature belongs to, by the feature's id.
local function featureClass(c, componentId)
  for _, cl in ipairs(list(c.classes)) do
    for _, f in ipairs(list(cl.classFeatures)) do
      if f.definition and tostring(f.definition.id) == componentId then return cl end
    end
  end
  return nil
end

------------------------------------------------------------------ the sheet

-- Armor Class, as D&D Beyond works it out: the best of each armor worn and,
-- with none on, of the unarmored defenses the character has, plus a shield,
-- and bonuses from items, features and the sheet's own settings.
function gmb.armorClass(c, mods, m)
  local override = characterValues(c, 1)[1]
  if override and num(override.value) then return math.floor(num(override.value)) end
  local function itemBonus(it)
    local def, b = it.definition or {}, 0
    if def.canAttune == true and it.isAttuned ~= true then return 0 end
    for _, g in ipairs(list(def.grantedModifiers)) do
      if g.type == "bonus" and g.subType == "armor-class" then b = b + (num(g.value) or 0) end
    end
    return b
  end
  local armors, shield, gear = {}, 0, 0
  for _, it in ipairs(list(c.inventory)) do
    local def = it.definition or {}
    if it.equipped == true then
      local kind = num(def.armorTypeId)
      if def.filterType == "Armor" and kind == 4 then
        local s = (num(def.armorClass) or 0) + itemBonus(it)
        if s > shield then shield = s end
      elseif def.filterType == "Armor" and kind and kind >= 1 and kind <= 3 then
        armors[#armors + 1] = { kind = kind, ac = (num(def.armorClass) or 0) + itemBonus(it) }
      else
        gear = gear + itemBonus(it)
      end
    end
  end
  local misc = 0
  for _, x in ipairs(find(mods, "bonus", "armor-class")) do
    if x.source ~= "item" then misc = misc + (x.value or 0) end
  end
  for _, id in ipairs({ 2, 3 }) do
    for _, v in ipairs(characterValues(c, id)) do misc = misc + (num(v.value) or 0) end
  end
  local dex = m.dex
  local best
  if #armors > 0 then
    local maxMedium = 2
    for _, x in ipairs(find(mods, "set", "ac-max-dex-armored-modifier")) do
      if (x.value or 0) > maxMedium then maxMedium = x.value end
    end
    local armored = total(find(mods, "bonus", "armored-armor-class"))
    for _, a in ipairs(armors) do
      local value = a.ac
      if a.kind == 1 then value = value + dex
      elseif a.kind == 2 then value = value + math.min(dex, maxMedium) end
      value = value + armored
      if not best or value > best then best = value end
    end
  else
    local bonus = total(find(mods, "bonus", "unarmored-armor-class"))
    local maxDex = 20
    for _, x in ipairs(find(mods, "set", "ac-max-dex-modifier")) do
      if (x.value or 20) < maxDex then maxDex = x.value end
    end
    best = 10 + dex + bonus
    -- a negative Dexterity counts against an unarmored defense as it does
    -- against no armor at all; only a maximum of 0 leaves Dexterity out
    local dexPart = math.min(dex, maxDex)
    if maxDex == 0 then dexPart = math.max(0, dexPart) end
    for _, x in ipairs(find(mods, "set", "unarmored-armor-class", true)) do
      local value = 10 + dexPart + bonus
      if x.statId and ABILITY[x.statId] then value = value + m[ABILITY[x.statId]] end
      if x.value then value = value + x.value end
      if value > best then best = value end
    end
  end
  return best + shield + gear + misc
end

-- Hit Points, as D&D Beyond works them out.
function gmb.hitPoints(c, mods, m, level)
  local override = num(c.overrideHitPoints) or 0
  if override > 0 then return math.floor(override) end
  local hp = (num(c.baseHitPoints) or 0) + m.con * level + (num(c.bonusHitPoints) or 0)
  for _, x in ipairs(find(mods, "bonus", "hit-points-per-level")) do
    local cl = x.source == "class" and featureClass(c, x.componentId) or nil
    hp = hp + (x.value or 0) * (cl and (num(cl.level) or level) or level)
  end
  return math.floor(hp + total(find(mods, "bonus", "hit-points")))
end

-- A spell's casting time as the SRD words it.
local function castingTime(def)
  local a = def.activation or {}
  local kind, n = num(a.activationType), num(a.activationTime) or 1
  if kind == 1 then return "Action" end
  if kind == 3 then return "Bonus Action" end
  if kind == 4 then return "Reaction" end
  if kind == 6 then return tostring(n) .. (n == 1 and " minute" or " minutes") end
  if kind == 7 then return tostring(n) .. (n == 1 and " hour" or " hours") end
  if kind == 5 then return "No action" end
  return nil
end

local function distance(feet)
  feet = num(feet)
  if not feet then return nil end
  if feet >= 5280 and feet % 5280 == 0 then
    local miles = math.floor(feet / 5280)
    return tostring(miles) .. (miles == 1 and " mile" or " miles")
  end
  return tostring(math.floor(feet)) .. " ft."
end

local function spellRange(def)
  local r = def.range or {}
  local origin = gmb.line(r.origin)
  local text
  if origin == "Ranged" then text = distance(r.rangeValue) or "Ranged"
  elseif origin and origin ~= "" then text = origin end
  if r.aoeType and num(r.aoeValue) then
    local area = tostring(math.floor(num(r.aoeValue))) .. " ft. " .. gmb.line(r.aoeType)
    text = text and (text .. " (" .. area .. ")") or area
  end
  return text
end

-- A spell as the sheet's key holds it: its name, with how it is cast.
local function spellEntry(s, note)
  local def = s.definition or {}
  local e = { name = gmb.line(def.name) }
  e.time = castingTime(def)
  e.range = spellRange(def)
  if def.concentration == true then e.concentration = true end
  if def.ritual == true then e.ritual = true end
  for _, comp in ipairs(list(def.components)) do
    if num(comp) == 3 then
      local words = gmb.line(def.componentsDescription) or ""
      e.material = words ~= "" and words or true
    end
  end
  if note then e.notes = note end
  return e
end

-- The dice a cantrip's damage scales to at a character level.
local function cantripDice(m, level)
  local dice = m.die and m.die.diceString
  local best = 0
  local higher = m.atHigherLevels and m.atHigherLevels.higherLevelDefinitions
  for _, h in ipairs(list(higher)) do
    local at = num(h.level)
    if at and at <= level and at > best and h.dice and h.dice.diceString then
      best, dice = at, h.dice.diceString
    end
  end
  return dice
end

-- "1d8" and 3 as "1d8+3", and 0 as the dice alone.
local function withBonus(dice, bonus)
  if not dice or dice == "" then return tostring(math.max(0, bonus)) end
  if bonus == 0 then return dice end
  return dice .. signed(bonus)
end

-- How a class casts: the ability, and the rules its spell slots follow.
-- D&D Beyond gives both on the class's definition, or for a class that
-- casts nothing itself, on its subclass's, as an Eldritch Knight's.
local function castingOf(cl)
  local def, sub = cl.definition or {}, cl.subclassDefinition or {}
  local ability = num(def.spellCastingAbilityId)
  if not (ability and ABILITY[ability]) then ability = num(sub.spellCastingAbilityId) end
  if not (ability and ABILITY[ability]) then ability = nil end
  local rules
  if def.canCastSpells == true and def.spellRules and def.spellRules.levelSpellSlots then
    rules = def.spellRules
  elseif sub.canCastSpells == true and sub.spellRules and sub.spellRules.levelSpellSlots then
    rules = sub.spellRules
  end
  return ability, rules
end

-- D&D Beyond's lists of the spells something other than a class's own
-- spellcasting grants, in the order their ability is looked for.
local GRANTED = { "race", "background", "feat", "class", "item" }

-- The whole sheet, as the keys of a character's page, in the order they
-- are written: a list of { key, value }.
function gmb.sheet(c)
  local mods = gmb.modifiers(c)
  local scores = gmb.scores(c, mods)
  local m = {}
  for i = 1, 6 do m[ABILITY[i]] = mod(scores[ABILITY[i]]) end
  local classes = list(c.classes)
  table.sort(classes, function(a, b)
    if (a.isStartingClass == true) ~= (b.isStartingClass == true) then return a.isStartingClass == true end
    return (num(a.level) or 0) > (num(b.level) or 0)
  end)
  local level = 0
  for _, cl in ipairs(classes) do level = level + (num(cl.level) or 0) end
  if level < 1 then level = 1 end
  local pb = 2 + math.floor((level - 1) / 4)
  local entries = {}
  local function put(key, value)
    -- a key the import writes and gmb.owned doesn't list would be written
    -- again beside itself by every refresh
    if not gmb.owned[key] then error("GM Beyond: " .. tostring(key) .. " isn't in gmb.owned") end
    if value == nil then return end
    if type(value) == "table" and #value == 0 and next(value) == nil then return end
    entries[#entries + 1] = { key, value }
  end

  put("ddb", whole(c.id))
  put("level", level)
  local names, subs = {}, {}
  for _, cl in ipairs(classes) do
    local name = gmb.line(cl.definition and cl.definition.name) or "?"
    names[#names + 1] = #classes > 1 and (name .. " " .. tostring(whole(cl.level) or 0)) or name
    local sub = gmb.line(cl.subclassDefinition and cl.subclassDefinition.name)
    if sub and sub ~= "" then subs[#subs + 1] = sub end
  end
  put("class", table.concat(names, " / "))
  if #subs > 0 then put("subclass", table.concat(subs, " / ")) end
  local race = c.race or {}
  put("species", gmb.line(race.fullName))
  local bg = c.background or {}
  local bgName = bg.definition and bg.definition.name or (bg.customBackground and bg.customBackground.name)
  put("background", gmb.line(bgName))
  put("creature_size", SIZES[num(race.sizeId) or 4])
  for i = 1, 6 do put(ABILITY[i], scores[ABILITY[i]]) end

  -- proficiencies, Expertise and Advantage
  local saves, skills, expertise, advantage = {}, {}, {}, {}
  local saveTotals, skillTotals = {}, {}
  local customProf = {}
  for _, v in ipairs(characterValues(c, 41)) do customProf[num(v.valueId) or 0] = num(v.value) end
  local customSave = {}
  for _, id in ipairs({ 39, 40 }) do
    for _, v in ipairs(characterValues(c, id)) do
      local at = num(v.valueId) or 0
      customSave[at] = (customSave[at] or 0) + (num(v.value) or 0)
    end
  end
  for i = 1, 6 do
    local sub = LONG[i] .. "-saving-throws"
    local prof = has(mods, "proficiency", sub, true)
    if customProf[i] then prof = customProf[i] ~= 1 end
    if prof then saves[#saves + 1] = ABILITY[i] end
    if has(mods, "advantage", sub) then advantage[#advantage + 1] = ABILITY[i] .. "_save" end
    saveTotals[i] = m[ABILITY[i]] + (prof and pb or 0) + total(find(mods, "bonus", "saving-throws")) +
      total(find(mods, "bonus", sub)) + (customSave[i] or 0)
  end
  local jack = has(mods, "half-proficiency", "ability-checks", true)
  local allChecks = total(find(mods, "bonus", "ability-checks"))
  for _, s in ipairs(SKILLS) do
    local key, ab = (s[1]:gsub("%-", "_")), s[2]
    local expert = has(mods, "expertise", s[1], true)
    local prof = expert or has(mods, "proficiency", s[1], true)
    local half = jack or has(mods, "half-proficiency", s[1], true) or
      has(mods, "half-proficiency", LONG[ab] .. "-ability-checks", true)
    local halfUp = has(mods, "half-proficiency-round-up", s[1], true) or
      has(mods, "half-proficiency-round-up", LONG[ab] .. "-ability-checks", true) or
      has(mods, "half-proficiency-round-up", "ability-checks", true)
    local p = 0
    if expert then p = 2 * pb
    elseif prof then p = pb
    elseif halfUp then p = math.floor((pb + 1) / 2)
    elseif half then p = math.floor(pb / 2) end
    if expert then expertise[#expertise + 1] = key elseif prof then skills[#skills + 1] = key end
    if has(mods, "advantage", s[1]) then advantage[#advantage + 1] = key end
    skillTotals[key] = m[ABILITY[ab]] + p + total(find(mods, "bonus", s[1])) + allChecks +
      total(find(mods, "bonus", LONG[ab] .. "-ability-checks"))
  end
  local initiative = m.dex + total(find(mods, "bonus", "initiative")) + allChecks +
    total(find(mods, "bonus", "dexterity-ability-checks"))
  if has(mods, "proficiency", "initiative", true) then initiative = initiative + pb
  elseif jack or has(mods, "half-proficiency", "initiative", true) or
      has(mods, "half-proficiency", "dexterity-ability-checks", true) then
    initiative = initiative + math.floor(pb / 2)
  end
  if has(mods, "advantage", "initiative") then advantage[#advantage + 1] = "initiative" end
  put("saves", saves)
  put("skills", skills)
  put("expertise", expertise)
  put("advantage", advantage)

  -- the numbers the sums don't give, written under their own names
  local adv = {}
  for _, a in ipairs(advantage) do adv[a] = true end
  if initiative ~= m.dex then put("initiative", initiative) end
  for i = 1, 6 do
    local proficient = false
    for _, s in ipairs(saves) do if s == ABILITY[i] then proficient = true end end
    local sum = m[ABILITY[i]] + (proficient and pb or 0)
    if saveTotals[i] ~= sum then put(ABILITY[i] .. "_save", saveTotals[i]) end
  end
  for _, s in ipairs(SKILLS) do
    local key, ab = (s[1]:gsub("%-", "_")), s[2]
    local p = 0
    for _, e in ipairs(expertise) do if e == key then p = 2 end end
    if p == 0 then for _, e in ipairs(skills) do if e == key then p = 1 end end end
    if skillTotals[key] ~= m[ABILITY[ab]] + p * pb then put(key, skillTotals[key]) end
  end
  for _, which in ipairs({ "perception", "insight", "investigation" }) do
    local passive = 10 + skillTotals[which] + total(find(mods, "bonus", "passive-" .. which))
    local sum = 10 + skillTotals[which] + (adv[which] and 5 or 0)
    if passive ~= sum then put("passive_" .. which, passive) end
  end

  -- spellcasting: the first class's own ability; where no class casts
  -- itself, a subclass's, as an Eldritch Knight's or an Arcane Trickster's;
  -- failing both, the one chosen for spells a species, background, feat,
  -- class feature or item grants. Each spell is still cast with its own.
  local castAbility
  for _, cl in ipairs(classes) do
    local own = num((cl.definition or {}).spellCastingAbilityId)
    if not castAbility and own and ABILITY[own] then castAbility = own end
  end
  for _, cl in ipairs(classes) do
    if not castAbility then castAbility = (castingOf(cl)) end
  end
  for _, source in ipairs(GRANTED) do
    for _, s in ipairs(list(c.spells and c.spells[source])) do
      local own = num(s.spellCastingAbilityId)
      if not castAbility and own and ABILITY[own] then castAbility = own end
    end
  end
  local dcBonus = total(find(mods, "bonus", "spell-save-dc"))
  local attackBonus = total(find(mods, "bonus", "spell-attacks"))
  local spellDC, spellAttack
  if castAbility then
    local cm = m[ABILITY[castAbility]]
    spellDC = 8 + pb + cm + dcBonus
    spellAttack = pb + cm + attackBonus
    if spellDC ~= 8 + pb + cm then put("spell_dc", spellDC) end
    if spellAttack ~= pb + cm then put("spell_attack", spellAttack) end
  end

  put("ac", gmb.armorClass(c, mods, m))
  put("hp", gmb.hitPoints(c, mods, m, level))
  local dice = {}
  for _, cl in ipairs(classes) do
    dice[#dice + 1] = tostring(num(cl.level) or 0) .. "d" .. tostring(num(cl.definition and cl.definition.hitDice) or 8)
  end
  put("hit_dice", table.concat(dice, " + "))

  -- speed, and the other ways they move
  local speeds = (race.weightSpeeds and race.weightSpeeds.normal) or {}
  local walk = (num(speeds.walk) or 30) + total(find(mods, "bonus", "speed"))
  local armored = false
  for _, it in ipairs(list(c.inventory)) do
    local def = it.definition or {}
    if it.equipped == true and def.filterType == "Armor" then armored = true end
  end
  if not armored then walk = walk + total(find(mods, "bonus", "unarmored-movement")) end
  local others = {}
  for _, mode in ipairs({ { "fly", "flying", "Fly" }, { "swim", "swimming", "Swim" }, { "climb", "climbing", "Climb" }, { "burrow", "burrowing", "Burrow" } }) do
    local value = num(speeds[mode[1]]) or 0
    for _, x in ipairs(find(mods, "set", "innate-speed-" .. mode[2])) do
      local v = x.value or walk
      if v > value then value = v end
    end
    if value > 0 then others[#others + 1] = mode[3] .. " " .. tostring(math.floor(value)) .. " ft." end
  end
  if #others == 0 then put("speed", walk)
  else put("speed", tostring(walk) .. " ft., " .. table.concat(others, ", ")) end

  -- senses, languages and training
  local senses = {}
  for _, sense in ipairs({ "darkvision", "blindsight", "tremorsense", "truesight" }) do
    local range = 0
    for _, x in ipairs(find(mods, "set-base", sense, true)) do
      if (x.value or 0) > range then range = x.value end
    end
    if range > 0 then senses[#senses + 1] = capital(sense) .. " " .. tostring(range) .. " ft." end
  end
  put("senses", senses)
  local function names(kind, test)
    local seen, out = {}, {}
    for _, x in ipairs(mods) do
      if x.type == kind and test(x) then
        local n = gmb.line(x.friendly or capital((tostring(x.subType):gsub("%-", " "))))
        if not seen[n] then seen[n] = true; out[#out + 1] = n end
      end
    end
    table.sort(out)
    return out
  end
  put("languages", names("language", function() return true end))
  put("tools", names("proficiency", function(x) return x.entityTypeId == TOOL end))
  local armor = {}
  for _, a in ipairs({ { "light-armor", "light" }, { "medium-armor", "medium" }, { "heavy-armor", "heavy" }, { "shields", "shields" } }) do
    if has(mods, "proficiency", a[1], true) then armor[#armor + 1] = a[2] end
  end
  put("armor_training", armor)
  local weapons = {}
  if has(mods, "proficiency", "simple-weapons", true) then weapons[#weapons + 1] = "Simple" end
  if has(mods, "proficiency", "martial-weapons", true) then weapons[#weapons + 1] = "Martial" end
  for _, n in ipairs(names("proficiency", function(x) return x.entityTypeId == WEAPON end)) do weapons[#weapons + 1] = n end
  put("weapons", weapons)
  local masteries = {}
  for _, x in ipairs(mods) do
    if x.type == "weapon-mastery" then
      masteries[#masteries + 1] = gmb.line(x.friendly or capital((tostring(x.subType):gsub("%-", " "))))
    end
  end
  put("masteries", masteries)

  -- attacks: the weapons they have in hand, their damaging cantrips, and an unarmed strike
  local attacks = {}
  local martialArts
  for _, cl in ipairs(classes) do
    for _, f in ipairs(list(cl.classFeatures)) do
      local def = f.definition
      if def and def.name == "Martial Arts" and (num(def.requiredLevel) or 0) <= (num(cl.level) or 0) then
        martialArts = (f.levelScale and f.levelScale.dice and f.levelScale.dice.diceString) or "1d4"
      end
    end
  end
  local function proficientWith(def)
    local category = num(def.categoryId)
    if category == 1 and has(mods, "proficiency", "simple-weapons", true) then return true end
    if category == 2 and has(mods, "proficiency", "martial-weapons", true) then return true end
    return has(mods, "proficiency", slug(def.type), true) or has(mods, "proficiency", slug(def.name), true)
  end
  for _, it in ipairs(list(c.inventory)) do
    local def = it.definition or {}
    if it.equipped == true and def.filterType == "Weapon" then
      local props, finesse, versatile = {}, false, nil
      for _, p in ipairs(list(def.properties)) do
        props[#props + 1] = gmb.line(p.name)
        if p.name == "Finesse" then finesse = true end
        if p.name == "Versatile" and p.notes then versatile = gmb.line(p.notes) end
      end
      local ranged = num(def.attackType) == 2
      local ability = ranged and m.dex or m.str
      if finesse or (martialArts and def.isMonkWeapon == true) then ability = math.max(m.str, m.dex) end
      local magic = 0
      for _, g in ipairs(list(def.grantedModifiers)) do
        if g.type == "bonus" and g.subType == "magic" then magic = magic + (num(g.value) or 0) end
      end
      local extra = total(find(mods, "bonus", ranged and "ranged-weapon-attacks" or "melee-weapon-attacks"))
      local hit = ability + (proficientWith(def) and pb or 0) + magic + extra
      local die = def.damage and def.damage.diceString or nil
      if martialArts and def.isMonkWeapon == true and die then
        -- a monk weapon rolls the Martial Arts die where that is bigger
        local a, b = tonumber(die:match("d(%d+)")), tonumber(martialArts:match("d(%d+)"))
        if a and b and b > a then die = martialArts end
      end
      local damage = withBonus(die or (def.fixedDamage and tostring(def.fixedDamage)), ability + magic)
      if def.damageType then damage = damage .. " " .. gmb.line(def.damageType) end
      local notes = table.concat(props, ", ")
      if versatile then
        -- a function, so a % in the notes is never read as a capture
        notes = (notes:gsub("Versatile", function() return "Versatile (" .. versatile .. ")" end))
      end
      local range = num(def.range)
      if range and (ranged or notes:find("Thrown", 1, true)) then
        local reach = tostring(math.floor(range))
        if num(def.longRange) then reach = reach .. "/" .. tostring(math.floor(num(def.longRange))) end
        notes = notes .. (notes ~= "" and "; " or "") .. reach .. " ft."
      end
      local attack = { name = gmb.line(def.name), hit = hit, damage = damage }
      if notes ~= "" then attack.notes = notes end
      attacks[#attacks + 1] = attack
    end
  end

  -- the spells: each class's, then those a species, background, feat, class
  -- feature or item grants, whatever the class, each with the ability it is
  -- cast with: its own where D&D Beyond gives one, else its class's
  local cantrips, prepared, always, book = {}, {}, {}, {}
  local cantripSeen = {}
  local cantripDefs = {}
  local function addTo(map, level, e)
    map[level] = map[level] or {}
    for _, x in ipairs(map[level]) do if x.name == e.name then return end end
    table.insert(map[level], e)
  end
  -- a spell cast with another ability than the sheet's says so, with the
  -- save DC and attack bonus it has, and an item's names the item
  local function entryOf(s, ability, from)
    local notes = {}
    if from then notes[#notes + 1] = from end
    if ability and ability ~= castAbility then
      local cm = m[ABILITY[ability]]
      notes[#notes + 1] = SHORT[ability] .. ": DC " .. tostring(8 + pb + cm + dcBonus) .. ", " ..
        signed(pb + cm + attackBonus) .. " to hit"
    end
    return spellEntry(s, #notes > 0 and table.concat(notes, "; ") or nil)
  end
  local function addCantrip(s, ability, from)
    local def = s.definition or {}
    local e = entryOf(s, ability, from)
    if e.name and not cantripSeen[e.name] then
      cantripSeen[e.name] = true
      cantrips[#cantrips + 1] = e
      cantripDefs[#cantripDefs + 1] = { def = def, name = e.name, ability = ability }
    end
  end
  local classById = {}
  for _, cl in ipairs(classes) do classById[tostring(cl.id)] = cl end
  for _, entry in ipairs(list(c.classSpells)) do
    local cl = classById[tostring(entry.characterClassId)]
    local classAbility = cl and (castingOf(cl)) or nil
    local spells = list(entry.spells)
    local prepares = false
    for _, s in ipairs(spells) do if s.prepared == true then prepares = true end end
    for _, s in ipairs(spells) do
      local def = s.definition or {}
      local lvl = whole(def.level) or 0
      local own = num(s.spellCastingAbilityId)
      local ability = (own and ABILITY[own]) and own or classAbility or castAbility
      if lvl == 0 then addCantrip(s, ability)
      elseif s.alwaysPrepared == true then addTo(always, lvl, entryOf(s, ability))
      elseif s.prepared == true or not prepares then addTo(prepared, lvl, entryOf(s, ability))
      else addTo(book, lvl, entryOf(s, ability)) end
    end
  end
  -- an item's spells while it is on, and attuned where it must be
  local items = {}
  for _, it in ipairs(list(c.inventory)) do
    local def = it.definition or {}
    if def.id ~= nil then items[tostring(def.id)] = it end
    if it.id ~= nil then items[tostring(it.id)] = it end
  end
  for _, source in ipairs(GRANTED) do
    for _, s in ipairs(list(c.spells and c.spells[source])) do
      local def = s.definition or {}
      local lvl = whole(def.level) or 0
      local own = num(s.spellCastingAbilityId)
      local ability = (own and ABILITY[own]) and own or nil
      if not ability and source == "class" then
        local cl = featureClass(c, tostring(s.componentId))
        ability = cl and (castingOf(cl)) or nil
      end
      ability = ability or castAbility
      local it = source == "item" and items[tostring(s.componentId)] or nil
      local from = it and gmb.line(it.definition and it.definition.name) or nil
      if from == "" then from = nil end
      if from then from = "from " .. from end
      if not (it and not active(it)) then
        if lvl == 0 then addCantrip(s, ability, from)
        else addTo(always, lvl, entryOf(s, ability, from)) end
      end
    end
  end

  -- damaging cantrips are attacks too, by their name, each rolled with the
  -- ability it is cast with
  table.sort(cantripDefs, function(a, b) return a.name < b.name end)
  for _, cd in ipairs(cantripDefs) do
    local def = cd.def
    local damage
    for _, x in ipairs(list(def.modifiers)) do
      if not damage and x.type == "damage" then
        local d = cantripDice(x, level)
        if d then damage = d .. " " .. gmb.line(x.friendlySubtypeName or capital(x.subType)) end
      end
    end
    if damage and cd.ability then
      local cm = m[ABILITY[cd.ability]]
      local hit
      if def.requiresAttackRoll == true then hit = pb + cm + attackBonus
      elseif def.requiresSavingThrow == true and SHORT[num(def.saveDcAbilityId) or 0] then
        hit = "DC " .. tostring(8 + pb + cm + dcBonus) .. " " .. SHORT[num(def.saveDcAbilityId)]
      end
      if hit then
        local attack = { name = cd.name, hit = hit, damage = damage }
        local range = spellRange(def)
        if range then attack.notes = range end
        attacks[#attacks + 1] = attack
      end
    end
  end
  if not c.preferences or c.preferences.showUnarmedStrike ~= false then
    local ability = martialArts and math.max(m.str, m.dex) or m.str
    local damage = martialArts and withBonus(martialArts, ability) or tostring(math.max(0, 1 + m.str))
    attacks[#attacks + 1] = { name = "Unarmed Strike", hit = ability + pb, damage = damage .. " Bludgeoning" }
  end
  put("attacks", attacks)

  -- what runs out
  local resources, seenResource = {}, {}
  local actions = c.actions or {}
  for _, source in ipairs({ "class", "race", "feat" }) do
    for _, a in ipairs(list(actions[source])) do
      local lu = a.limitedUse
      local name = gmb.line(a.name)
      if lu and name and name ~= "" and not seenResource[name] then
        local uses = num(lu.maxUses) or 0
        local by = num(lu.statModifierUsesId)
        if by and ABILITY[by] then uses = uses + math.max(1, m[ABILITY[by]]) end
        if lu.useProficiencyBonus == true then
          if num(lu.proficiencyBonusOperator) == 2 and uses > 0 then uses = uses * pb else uses = uses + pb end
        end
        if uses > 0 then
          seenResource[name] = true
          local r = { name = name, uses = math.floor(uses) }
          r.reset = RESETS[num(lu.resetType) or 0]
          resources[#resources + 1] = r
        end
      end
    end
  end
  put("resources", resources)

  -- spell slots: a class's own table, or its subclass's for a class that
  -- casts through its subclass, the multiclass table for more than one,
  -- and Pact Magic apart
  if castAbility then put("spellcasting", ABILITY[castAbility]) end
  local casting, casterLevel, pact = {}, 0, nil
  for _, cl in ipairs(classes) do
    local _, rules = castingOf(cl)
    if rules then
      local classLevel = whole(cl.level) or 0
      local row = list(rules.levelSpellSlots[classLevel + 1])
      if (cl.definition or {}).name == "Warlock" then
        for i, n in ipairs(row) do
          if (whole(n) or 0) > 0 then pact = { slots = whole(n), level = i } end
        end
      else
        casting[#casting + 1] = { row = row }
        local divisor = num(rules.multiClassSpellSlotDivisor) or 1
        if divisor < 1 then divisor = 1 end
        local share = classLevel / divisor
        if num(rules.multiClassSpellSlotRounding) == 2 then share = math.ceil(share) else share = math.floor(share) end
        casterLevel = casterLevel + share
      end
    end
  end
  local slots = {}
  if #casting == 1 then
    for _, n in ipairs(casting[1].row) do slots[#slots + 1] = whole(n) or 0 end
  elseif #casting > 1 and casterLevel > 0 then
    for _, n in ipairs(SLOTS[math.min(20, casterLevel)]) do slots[#slots + 1] = n end
  end
  while #slots > 0 and slots[#slots] == 0 do slots[#slots] = nil end
  put("slots", slots)
  if pact then
    put("pact_slots", pact.slots)
    put("pact_level", pact.level)
  end
  -- the spells, whatever the class: a fighter's Magic Initiate, say, or a
  -- rogue's elven cantrip
  put("cantrips", cantrips)
  local function byLevel(map)
    local out = {}
    for lvl, l in pairs(map) do
      table.sort(l, function(a, b) return tostring(a.name) < tostring(b.name) end)
      out[lvl] = l
    end
    return out
  end
  if next(prepared) then put("spells", byLevel(prepared)) end
  if next(always) then put("always_prepared", byLevel(always)) end
  if next(book) then put("spellbook", byLevel(book)) end

  -- features, traits and feats, with their rules
  local features, seenFeature = {}, {}
  for _, cl in ipairs(classes) do
    local fs = {}
    for _, f in ipairs(list(cl.classFeatures)) do
      local def = f.definition
      if def and (num(def.requiredLevel) or 0) <= (num(cl.level) or 0) and def.hideInSheet ~= true
          and not BOILERPLATE[def.name] then
        fs[#fs + 1] = def
      end
    end
    table.sort(fs, function(a, b)
      local la, lb = num(a.requiredLevel) or 0, num(b.requiredLevel) or 0
      if la ~= lb then return la < lb end
      local da, db = num(a.displayOrder) or 0, num(b.displayOrder) or 0
      if da ~= db then return da < db end
      return tostring(a.name) < tostring(b.name)
    end)
    for _, def in ipairs(fs) do
      local name = gmb.line(def.name) or ""
      if not seenFeature[name] then
        seenFeature[name] = true
        features[#features + 1] = { name = name, text = gmb.markdown(def.description) }
      end
    end
  end
  local featureName = gmb.line(bg.definition and bg.definition.featureName)
  if featureName and featureName ~= "" then
    features[#features + 1] = { name = featureName, text = gmb.markdown(bg.definition.featureDescription) }
  end
  put("features", features)
  local traits = {}
  for _, t in ipairs(list(race.racialTraits)) do
    local def = t.definition
    if def and def.hideInSheet ~= true then
      traits[#traits + 1] = { name = gmb.line(def.name) or "", text = gmb.markdown(def.description) }
    end
  end
  put("traits", traits)
  local feats = {}
  for _, f in ipairs(list(c.feats)) do
    local def = f.definition
    if def and def.name then feats[#feats + 1] = { name = gmb.line(def.name), text = gmb.markdown(def.description) } end
  end
  put("feats", feats)

  -- what they carry
  local equipment, attuned = {}, {}
  for _, it in ipairs(list(c.inventory)) do
    local def = it.definition or {}
    local qty = num(it.quantity) or 1
    local name = gmb.line(def.name)
    if name then
      equipment[#equipment + 1] = qty > 1 and (name .. " (" .. tostring(math.floor(qty)) .. ")") or name
      if it.isAttuned == true then attuned[#attuned + 1] = name end
    end
  end
  for _, it in ipairs(list(c.customItems)) do
    local qty = num(it.quantity) or 1
    local name = gmb.line(it.name)
    if name then
      equipment[#equipment + 1] = qty > 1 and (name .. " (" .. tostring(math.floor(qty)) .. ")") or name
    end
  end
  put("equipment", equipment)
  put("attuned", attuned)
  local coins = {}
  local cur = c.currencies or {}
  for _, k in ipairs({ "cp", "sp", "ep", "gp", "pp" }) do
    local n = num(cur[k])
    if n and n ~= 0 then coins[#coins + 1] = { k, math.floor(n) } end
  end
  if #coins > 0 then put("coins", { _pairs = coins }) end
  return entries
end

------------------------------------------------------------------ rules text

local ENTITIES = {
  nbsp = " ", amp = "&", lt = "<", gt = ">", quot = '"', apos = "'", rsquo = "’", lsquo = "‘",
  rdquo = "”", ldquo = "“", ndash = "–", mdash = "—", hellip = "…", times = "×", minus = "-",
  frac12 = "½", frac14 = "¼", frac34 = "¾", deg = "°", bull = "•", eacute = "é",
}
local NUMERIC = {
  [160] = " ", [8217] = "’", [8216] = "‘", [8220] = "“", [8221] = "”", [8211] = "–",
  [8212] = "—", [8230] = "…", [215] = "×", [189] = "½", [8226] = "•", [176] = "°",
}

local function entity(e)
  local n, h = e:match("^#(%d+)$"), e:match("^#[xX](%x+)$")
  local k = n and tonumber(n) or (h and tonumber(h, 16)) or nil
  if k then
    if NUMERIC[k] then return NUMERIC[k] end
    if k >= 32 and k < 127 then return string.char(k) end
    return "&" .. e .. ";"
  end
  return ENTITIES[e] or ("&" .. e .. ";")
end

-- The marks a < and a > in the words stand as until the tags are gone.
local SENTINEL = { ["<"] = "\x01", [">"] = "\x02" }

-- Words from between the tags as Markdown text: entities decoded, and each
-- character Markdown would read as markup escaped, so that what D&D Beyond
-- shows as words, &lt;b&gt; or ${...} say, stays words.
local function words(text)
  text = (text:gsub("&(#?%w+);", entity))
  text = (text:gsub(MARKUP, function(ch) return SENTINEL[ch] or ("\\" .. ch) end))
  return (text:gsub("&(#?%w+;)", "\\&%1"))
end

-- D&D Beyond's rules text, which is HTML, as Markdown: a paragraph to a
-- line, lists as lists, a table as a table, and bold and italic kept. Only
-- D&D Beyond's own tags become markup: the words between them are escaped
-- first, so text written on D&D Beyond never becomes a tag, a link or an
-- expression on the page.
function gmb.markdown(html)
  if html == nil then return "" end
  local s = tostring(html)
  s = (s:gsub("\r", ""))
  s = (s:gsub("\n", " "))
  s = (s:gsub("%c", " "))
  -- a hard space would end up inside bold's markers, where it breaks them
  s = (s:gsub("&nbsp;", " "))
  s = (s:gsub("&#160;", " "))
  -- what a browser never shows: comments, scripts and styles
  s = (s:gsub("<!%-%-.-%-%->", ""))
  s = (s:gsub("<[Ss][Cc][Rr][Ii][Pp][Tt][^>]*>.-</[Ss][Cc][Rr][Ii][Pp][Tt]%s*>", ""))
  s = (s:gsub("<[Ss][Tt][Yy][Ll][Ee][^>]*>.-</[Ss][Tt][Yy][Ll][Ee]%s*>", ""))
  -- the words between the tags, escaped: a tag opens with a letter, a / or
  -- a !, as a browser reads one, so a < b stays words
  local parts, at = {}, 1
  while at <= #s do
    local a, b = s:find("<[%a/!?][^<>]*>", at)
    parts[#parts + 1] = words(s:sub(at, (a or (#s + 1)) - 1))
    if not a then break end
    parts[#parts + 1] = s:sub(a, b)
    at = b + 1
  end
  s = table.concat(parts)
  -- a table's rows as Markdown rows, with the rule after the first
  s = (s:gsub("<table[^>]*>(.-)</table>", function(inner)
    local rows = {}
    for row in inner:gmatch("<tr[^>]*>(.-)</tr>") do
      local cells = {}
      for cell in row:gmatch("<t[hd][^>]*>(.-)</t[hd]>") do
        local text = (cell:gsub("<[^>]+>", ""))
        -- a | would end the cell
        text = (text:gsub("\\?|", "/"))
        text = (text:gsub("%s+", " "))
        text = (text:gsub("^%s+", ""))
        cells[#cells + 1] = (text:gsub("%s+$", ""))
      end
      if #cells > 0 then rows[#rows + 1] = "| " .. table.concat(cells, " | ") .. " |" end
      if #rows == 1 then
        local rule = {}
        for _ in ipairs(cells) do rule[#rule + 1] = "---" end
        rows[#rows + 1] = "|" .. table.concat(rule, "|") .. "|"
      end
    end
    return "\n" .. table.concat(rows, "\n") .. "\n"
  end))
  -- inline tags that only style or link go first, so a space inside one
  -- doesn't end up inside bold's markers
  s = (s:gsub("</?span[^>]*>", ""))
  s = (s:gsub("<a[%s>][^>]*>", ""))
  s = (s:gsub("<a>", ""))
  s = (s:gsub("</a>", ""))
  s = (s:gsub("<br%s*/?>", "\n"))
  s = (s:gsub("<li[^>]*>", "\n- "))
  s = (s:gsub("</?[uo]l[^>]*>", "\n"))
  s = (s:gsub("</?p[^>]*>", "\n"))
  s = (s:gsub("</?div[^>]*>", "\n"))
  s = (s:gsub("</?d[ltd][^>]*>", "\n"))
  s = (s:gsub("<h%d[^>]*>(.-)</h%d>", "\n**%1**\n"))
  -- bold and italic, with any space inside a tag moved out past its marker
  for _, tag in ipairs({ { "strong", "**" }, { "b", "**" }, { "em", "*" }, { "i", "*" } }) do
    local mark = tag[2]
    local function wrap(inner)
      local lead, core, trail = inner:match("^(%s*)(.-)(%s*)$")
      if core == "" then return inner end
      return lead .. mark .. core .. mark .. trail
    end
    s = (s:gsub("<" .. tag[1] .. ">(.-)</" .. tag[1] .. ">", wrap))
    s = (s:gsub("<" .. tag[1] .. "%s[^>]*>(.-)</" .. tag[1] .. ">", wrap))
  end
  -- every tag left goes, and then the words' own < and > come back escaped
  s = (s:gsub("<[^>]*>", ""))
  s = (s:gsub("<", ""))
  s = (s:gsub("\x01", "\\<"))
  s = (s:gsub("\x02", "\\>"))
  local out = {}
  for line in (s .. "\n"):gmatch("([^\n]*)\n") do
    local l = (line:gsub("%s+", " "))
    l = (l:gsub("^%s+", ""))
    l = (l:gsub("%s+$", ""))
    -- a bold run that closes where the next opens reads as one
    l = (l:gsub("%*%*%*%*", ""))
    if l ~= "" and l ~= "-" then out[#out + 1] = l end
  end
  return table.concat(out, "\n")
end

------------------------------------------------------------------ writing YAML

local RESERVED = { ["true"] = true, ["false"] = true, yes = true, no = true, on = true, off = true,
  null = true, y = true, n = true }

-- A scalar as YAML: plain where that can't be misread, quoted otherwise.
-- Always one line, so no value can end the frontmatter; and in quotes, a <
-- or a > as YAML's escape for it, which every reader turns back into the
-- character, so no name puts a tag, a comment or a baked section's marker
-- into the page's text.
local function scalar(v, flow)
  if type(v) == "number" then
    if v == math.floor(v) then return tostring(math.floor(v)) end
    return tostring(v)
  end
  if type(v) == "boolean" then return v and "true" or "false" end
  local s = gmb.line(v) or ""
  local plain = s:match("^[%w][%w _%.'%-%(%)/+&]*$") and not s:match("%s$") and not RESERVED[s:lower()]
  -- nothing YAML would read as a number or a date: 16d6 is text, 1_000 isn't
  if plain and s:match("^%d") and (tonumber(s) or s:find("_", 1, true) or s:match("^%d+%-%d")) then
    plain = false
  end
  if plain and flow and s:find(",", 1, true) then plain = false end
  if plain then return s end
  s = (s:gsub("\\", "\\\\"))
  s = (s:gsub('"', '\\"'))
  s = (s:gsub("<", "\\x3C"))
  s = (s:gsub(">", "\\x3E"))
  return '"' .. s .. '"'
end

local function flowList(l)
  local out = {}
  for _, x in ipairs(l) do out[#out + 1] = type(x) == "table" and nil or scalar(x, true) end
  return "[" .. table.concat(out, ", ") .. "]"
end

-- A table of named values as a flow map, in the given key order.
local function flowMap(t, order)
  local out = {}
  for _, k in ipairs(order) do
    if t[k] ~= nil then out[#out + 1] = k .. ": " .. scalar(t[k], true) end
  end
  return "{" .. table.concat(out, ", ") .. "}"
end

local SPELL_KEYS = { "name", "time", "range", "concentration", "ritual", "material", "notes" }

local function spellList(l)
  local out = {}
  for _, e in ipairs(l) do
    if type(e) == "table" then
      local only = true
      for k in pairs(e) do if k ~= "name" then only = false end end
      out[#out + 1] = only and scalar(e.name, true) or flowMap(e, SPELL_KEYS)
    else
      out[#out + 1] = scalar(e, true)
    end
  end
  return "[" .. table.concat(out, ", ") .. "]"
end

-- One key of a character's page as YAML lines.
local function yamlEntry(key, value)
  local lines = {}
  if key == "attacks" then
    lines[1] = "attacks:"
    for _, a in ipairs(value) do lines[#lines + 1] = "  - " .. flowMap(a, { "name", "hit", "damage", "notes" }) end
  elseif key == "resources" then
    lines[1] = "resources:"
    for _, r in ipairs(value) do lines[#lines + 1] = "  - " .. flowMap(r, { "name", "uses", "reset" }) end
  elseif key == "features" or key == "traits" or key == "feats" then
    lines[1] = key .. ":"
    for _, f in ipairs(value) do
      lines[#lines + 1] = "  - name: " .. scalar(f.name)
      if f.text and f.text ~= "" then
        lines[#lines + 1] = "    text: |"
        for l in (f.text .. "\n"):gmatch("([^\n]*)\n") do lines[#lines + 1] = "      " .. l end
      end
    end
  elseif key == "cantrips" then
    lines[1] = "cantrips: " .. spellList(value)
  elseif key == "spells" or key == "always_prepared" or key == "spellbook" then
    lines[1] = key .. ":"
    local levels = {}
    for lvl in pairs(value) do levels[#levels + 1] = lvl end
    table.sort(levels)
    for _, lvl in ipairs(levels) do lines[#lines + 1] = "  " .. tostring(lvl) .. ": " .. spellList(value[lvl]) end
  elseif key == "coins" then
    local parts = {}
    for _, p in ipairs(value._pairs) do parts[#parts + 1] = p[1] .. ": " .. tostring(p[2]) end
    lines[1] = "coins: {" .. table.concat(parts, ", ") .. "}"
  elseif type(value) == "table" then
    lines[1] = key .. ": " .. flowList(value)
  else
    lines[1] = key .. ": " .. scalar(value)
  end
  return table.concat(lines, "\n")
end

-- The keys the import writes, and so a refresh replaces: everything but
-- what a person adds by hand. gmb.sheet refuses to write a key not here.
gmb.owned = {}
for _, k in ipairs({ "ddb", "level", "class", "subclass", "species", "background", "creature_size",
    "str", "dex", "con", "int", "wis", "cha", "saves", "skills", "expertise", "advantage",
    "initiative", "str_save", "dex_save", "con_save", "int_save", "wis_save", "cha_save",
    "passive_perception", "passive_insight", "passive_investigation", "spell_dc", "spell_attack",
    "ac", "hp", "hit_dice", "speed", "senses", "languages", "tools", "armor_training", "weapons",
    "masteries", "attacks", "resources", "spellcasting", "slots", "pact_slots", "pact_level",
    "cantrips", "spells", "always_prepared", "spellbook", "features", "traits", "feats",
    "equipment", "attuned", "coins" }) do
  gmb.owned[k] = true
end
for _, s in ipairs(SKILLS) do gmb.owned[(s[1]:gsub("%-", "_"))] = true end

-- The frontmatter for the sheet's keys.
function gmb.yaml(entries)
  local out = {}
  for _, e in ipairs(entries) do out[#out + 1] = yamlEntry(e[1], e[2]) end
  return table.concat(out, "\n")
end

-- A page's frontmatter and the text after it, as SilverBullet reads them:
-- the lines between a first line of --- and the next line that is --- and
-- nothing else. Nil and the whole text for a page without.
local function frontmatter(text)
  if type(text) ~= "string" then return nil, text end
  local head, body = text:match("^%-%-%-\n(.-)\n%-%-%-\n(.*)$")
  if head then return head, body end
  head = text:match("^%-%-%-\n(.-)\n%-%-%-$")
  if head then return head, "" end
  return nil, text
end

-- The key a line at the frontmatter's left edge gives: ddb for `ddb: 1`,
-- real name for `real name: Bram`, shadow hook for `"shadow hook": ...`.
local function keyOf(line)
  return line:match('^"([^"]*)"[ \t]*:') or line:match("^'([^']*)'[ \t]*:") or
    line:match("^([^%s#:][^:]-)[ \t]*:[ \t]") or line:match("^([^%s#:][^:]-)[ \t]*:$")
end

-- A line that goes on with the entry above it: indented, one of a list's
-- items at the left edge, or blank.
local function continues(line)
  return line:match("^[ \t]") ~= nil or line:match("^%-[ \t]") ~= nil or line == "-" or not line:match("%S")
end

-- A page's frontmatter split into its entries, each with its lines, and the
-- text after it. An entry starts at every line at the left edge that doesn't
-- go on with the one above: a key, or anything else, such as a comment or a
-- key YAML reads with quotes or with spaces in it, which is kept as it is. A
-- comment belongs to the entry around it when the lines after it go on with
-- that entry.
local function entriesOf(text)
  local head, body = frontmatter(text)
  if not head then return nil, text end
  local lines = {}
  for line in (head .. "\n"):gmatch("([^\n]*)\n") do lines[#lines + 1] = line end
  local entries, current = {}, nil
  for i, line in ipairs(lines) do
    local under = current ~= nil and continues(line)
    if current ~= nil and line:match("^#") then
      local j = i + 1
      while lines[j] and (lines[j]:match("^#") or not lines[j]:match("%S")) do j = j + 1 end
      under = lines[j] ~= nil and continues(lines[j])
    end
    if under then
      table.insert(current.lines, line)
    else
      current = { key = (not line:match("^#")) and keyOf(line) or nil, lines = { line } }
      entries[#entries + 1] = current
    end
  end
  return entries, body
end

-- A character's page brought up to date: the import's keys rewritten, and
-- every other key and all the text after the frontmatter as they were.
function gmb.merge(text, entries)
  local old, body = entriesOf(text)
  local kept = {}
  for _, e in ipairs(old or {}) do
    if not (e.key and gmb.owned[e.key]) then kept[#kept + 1] = table.concat(e.lines, "\n") end
  end
  local head = table.concat(kept, "\n")
  local fresh = gmb.yaml(entries)
  if head ~= "" then fresh = head .. "\n" .. fresh end
  return "---\n" .. fresh .. "\n---\n" .. (body or "")
end

-- A new character's page, under a heading of the character's name that
-- shows it as words, whatever it holds.
function gmb.page(c, entries)
  local extras = {}
  local ok, list2 = pcall(config.get, "gmSheets.extras", nil)
  for _, e in ipairs(list(ok and list2 or nil)) do
    if e.key then extras[#extras + 1] = tostring(e.key) .. ":" end
  end
  local head = "type: pc\n" .. (#extras > 0 and (table.concat(extras, "\n") .. "\n") or "") .. gmb.yaml(entries)
  local title = gmb.inline(c.name)
  if title == "" then title = "Unnamed" end
  return "---\n" .. head .. "\n---\n\n# " .. title .. "\n\n${sheets.draw()}\n\n" ..
    "[The character on D&D Beyond](" .. gmb.sheetLink .. tostring(whole(c.id) or "") .. ")\n"
end

------------------------------------------------------------------ import and refresh

-- A page name from a character's name, as one SilverBullet 2.11 can open
-- and link to: without the characters its link grammar reads as something
-- else (a position after @, a header after #, an anchor after $, an alias
-- after |, a tag's < and >, a link's brackets, a folder's /, a \ and a ^),
-- and without an ending it would take for a file's extension: Dr.Who is
-- Dr Who.
local function pageName(name)
  local s = gmb.line(name) or ""
  s = (s:gsub("[%[%]#|%^/\\@$<>]", " "))
  s = (s:gsub("%.(%w+)$", " %1"))
  s = (s:gsub("%s+", " "))
  s = (s:gsub("^[%s%.]+", ""))
  s = (s:gsub("%s+$", ""))
  if s == "" then s = "Unnamed" end
  return tostring(gmb.setting("folder") or "") .. s
end

local function readPage(name)
  local ok, text = pcall(space.readPage, name)
  if ok and type(text) == "string" then return text end
  return nil
end

-- Whether a page exists: true or false, or nil and why when that can't be
-- told, as when the server can't be reached. Only "Not found" is no page.
local function exists(name)
  local ok, err = pcall(space.getPageMeta, name)
  if ok then return true end
  local why = tostring(err)
  if why:find("Not found", 1, true) or why:find("not found", 1, true) then return false end
  return nil, why
end

local function ddbOf(text)
  local head = frontmatter(text)
  return head and tonumber(("\n" .. head):match("\nddb:[ \t]*(%d+)")) or nil
end

local function levelIn(text)
  local head = frontmatter(text)
  return head and tonumber(("\n" .. head):match("\nlevel:[ \t]*(%d+)")) or nil
end

-- The page in the folder that is character id's, by the ddb number in its
-- frontmatter, which the index gives and the page itself confirms: the one
-- named for the character if there are two. Nil if there is none.
local function pageFor(id, name)
  local folder = tostring(gmb.setting("folder") or "")
  local ok, rows = pcall(function()
    return query[[
      from p = index.pages()
      where p.ddb ~= nil and p.name:startsWith(folder)
      select { name = p.name, ddb = p.ddb }
    ]]
  end)
  if not ok or type(rows) ~= "table" then return nil end
  local found = {}
  for _, r in ipairs(rows) do
    if num(r.ddb) == id and type(r.name) == "string" and ddbOf(readPage(r.name)) == id then
      found[#found + 1] = r.name
    end
  end
  table.sort(found)
  for _, n in ipairs(found) do
    if n == name then return n end
  end
  return found[1]
end

-- What is typed into a page open in the editor, saved before the page is
-- read for a write: SilverBullet 2.11's editor.reloadPage drops an autosave
-- still to come, and a write from here would lose an edit not yet saved.
-- True, or false and why when it couldn't be saved.
local function flush(page)
  if editor.getCurrentPage() ~= page or not editor.save then return true end
  local ok, err = pcall(editor.save)
  if ok then return true end
  return false, tostring(err)
end

local function reload(page)
  if editor.getCurrentPage() == page and editor.reloadPage then pcall(editor.reloadPage) end
end

-- Undo for a write: the page as it was, or gone again if the import made
-- it, while it still holds what was written. Anything changed since stays.
local function undoTo(name, before, written)
  return function()
    flush(name)
    if readPage(name) ~= written then
      editor.flashNotification("GM Beyond: " .. name .. " has changed since, so Undo left it as it is.", "error")
      return
    end
    if before then
      space.writePage(name, before)
      reload(name)
    else
      pcall(space.deletePage, name)
    end
    editor.flashNotification("Undone: " .. name .. " is as it was.", "info")
  end
end

function gmb.levelOf(entries)
  for _, e in ipairs(entries) do if e[1] == "level" then return e[2] end end
  return nil
end

-- A character's page brought up to date with what D&D Beyond sent, once
-- what is typed into it is saved and, if the level would drop, the GM has
-- said to. Returns the page, or nil when nothing was written.
local function update(page, id, c, entries, opts)
  local saved, err = flush(page)
  if not saved then
    editor.flashNotification("GM Beyond: couldn't save what is typed into " .. page .. " first (" ..
      tostring(err) .. "), so it wasn't refreshed.", "error")
    return nil
  end
  local text = readPage(page)
  if not text then
    editor.flashNotification("GM Beyond: couldn't read " .. page .. ", so it wasn't refreshed.", "error")
    return nil
  end
  if ddbOf(text) ~= id then
    editor.flashNotification("GM Beyond: " .. page .. " isn't character " .. tostring(id) ..
      "'s page any more, so it wasn't refreshed.", "error")
    return nil
  end
  local name = gmb.line(c.name) or "?"
  local was, now = levelIn(text), gmb.levelOf(entries)
  if was and now and now < was and not editor.confirm("D&D Beyond has " .. name .. " at level " ..
      tostring(now) .. ", and " .. page .. " says level " .. tostring(was) .. ". Refresh the page to level " ..
      tostring(now) .. "?") then
    editor.flashNotification(page .. " is left at level " .. tostring(was) .. ".", "info")
    return nil
  end
  local open = opts.open and { name = "Open", run = function() editor.navigate(page) end } or nil
  local after = gmb.merge(text, entries)
  if after == text then
    editor.flashNotification(page .. " is already up to date with D&D Beyond." .. (opts.note or ""), "info",
      open and { actions = { open } } or nil)
    return page
  end
  space.writePage(page, after)
  reload(page)
  local actions = {}
  if open then actions[#actions + 1] = open end
  actions[#actions + 1] = { name = "Undo", run = undoTo(page, text, after) }
  editor.flashNotification("Refreshed " .. page .. " from D&D Beyond: " .. name .. ", level " ..
    tostring(now) .. "." .. (opts.note or ""), "info", { actions = actions })
  return page
end

-- Import a character from a link to it, or refresh its page if it has one:
-- the page with its number in the folder, whatever it is called now, or
-- else the one named for it.
function gmb.import(link)
  if link == nil then
    link = editor.prompt("D&D Beyond character link, or its number", "")
    if not link or link == "" then return end
  end
  local id = gmb.idOf(link)
  if not id then
    editor.flashNotification("GM Beyond: that isn't a link to a D&D Beyond character.", "error")
    return
  end
  local c, why = gmb.fetch(id)
  if not c then
    editor.flashNotification("GM Beyond: couldn't import character " .. tostring(id) .. ": " .. tostring(why) .. ".", "error")
    return
  end
  if #list(c.classes) == 0 then
    editor.flashNotification("GM Beyond: D&D Beyond sent character " .. tostring(id) ..
      " with no class, so nothing was written.", "error")
    return
  end
  local name = pageName(c.name)
  local entries = gmb.sheet(c)
  local page = pageFor(id, name)
  if not page then
    local there, err = exists(name)
    if there == nil then
      editor.flashNotification("GM Beyond: couldn't tell whether " .. name .. " exists (" .. tostring(err) ..
        "), so nothing was written.", "error")
      return
    end
    if there then
      local text = readPage(name)
      if not text then
        editor.flashNotification("GM Beyond: couldn't read " .. name .. ", so nothing was written.", "error")
        return
      end
      if ddbOf(text) ~= id then
        editor.flashNotification("GM Beyond: " .. name .. " is another character's page. Rename it, or the import, first.", "error")
        return
      end
      page = name
    end
  end
  if page then
    local note = page ~= name and " The name has changed on D&D Beyond; the page keeps its own." or nil
    return update(page, id, c, entries, { open = true, note = note })
  end
  local text = gmb.page(c, entries)
  space.writePage(name, text)
  editor.flashNotification("Imported " .. name .. " from D&D Beyond: " .. (gmb.line(c.name) or "?") ..
    ", level " .. tostring(gmb.levelOf(entries)) .. ".", "info", {
      actions = {
        { name = "Open", run = function() editor.navigate(name) end },
        { name = "Undo", run = undoTo(name, nil, text) },
      },
    })
  return name
end

-- Fetch an imported character again and rewrite its sheet's keys.
function gmb.refresh(page)
  page = page or editor.getCurrentPage()
  local text = readPage(page)
  if not text then
    editor.flashNotification("GM Beyond: couldn't read " .. tostring(page) .. " to refresh it.", "error")
    return
  end
  local id = ddbOf(text)
  if not id then
    editor.flashNotification("GM Beyond: " .. tostring(page) .. " has no ddb number to refresh from.", "error")
    return
  end
  local c, why = gmb.fetch(id)
  if not c then
    editor.flashNotification("GM Beyond: couldn't refresh " .. tostring(page) .. ": " .. tostring(why) .. ".", "error")
    return
  end
  if #list(c.classes) == 0 then
    editor.flashNotification("GM Beyond: D&D Beyond sent " .. tostring(page) ..
      "'s character with no class, so the page is left as it is.", "error")
    return
  end
  return update(page, id, c, gmb.sheet(c), {})
end

------------------------------------------------------------------ the bar

-- A bar across an imported character's page: a refresh, and the character
-- on D&D Beyond.
function gmb.bar(page)
  page = page or editor.getCurrentPage()
  local id = ddbOf(readPage(page))
  if not id then return nil end
  return widget.new {
    html = dom.div {
      class = "gmb-bar",
      dom.strong { __rawText = "D&D Beyond" },
      dom.button {
        class = "sb-button",
        onclick = function()
          local ok, err = pcall(gmb.refresh, page)
          if not ok then editor.flashNotification("GM Beyond: " .. tostring(err), "error") end
        end,
        __rawText = "Refresh from D&D Beyond",
      },
      dom.a { href = gmb.sheetLink .. tostring(id), target = "_blank", __rawText = "Open on D&D Beyond" },
    },
    display = "block",
  }
end

command.define {
  name = "GM: Import Character",
  run = function() gmb.import() end,
}

command.define {
  name = "GM: Refresh Character",
  run = function() gmb.refresh() end,
}

event.listen {
  name = "hooks:renderTopWidgets",
  run = function()
    local ok, bar = pcall(gmb.bar)
    if ok then return bar end
    print("GM Beyond: " .. tostring(bar))
  end,
}
```

```space-style
.gmb-bar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px 10px;
}

/* The widget's own Copy and Reload overlay would cover the bar's buttons. */
.sb-lua-top-widget:has(.gmb-bar) .button-bar {
  display: none !important;
}
```
