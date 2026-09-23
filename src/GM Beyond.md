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

**Does:** fetches a public character's raw data and works out the sheet from it, the way D&D Beyond's own sheet does: ability scores, Armor Class, Hit Points, saving throws, skills, passives, initiative, attacks, spell save DC and attack bonus, spell slots, the spells, features, traits and feats with their rules, resources, proficiencies, languages and equipment, and what the player chose along the way, such as a warlock's invocations or a Battle Master's maneuvers. The page it writes is in [GM Sheets](<GM Sheets>)' shape, so GM Sheets draws it. A refresh shows what it would change before it writes, and one command refreshes the whole party.

**Doesn't:** embed sheets. D&D Beyond sends frame-blocking headers, so an iframe will not work, ever. Anyone offering you a D&D Beyond "embed" means a link.

**Doesn't track play.** Current Hit Points, spent slots and conditions change at the table; the page holds the sheet, not the state of the fight.

**Works it out, so check it.** The endpoint returns raw data, not the numbers D&D Beyond's sheet shows, so the import reimplements the rules those numbers come from: the modifiers each species, class, feat and item grants, armor and its limits, unarmored defenses, proficiency, and spell slots across classes. It matches D&D Beyond's own sheet on the characters it has been checked against, and a character built from something it doesn't know — a homebrew item with an unusual bonus, say — can come out wrong. Import, then compare the page with the character on D&D Beyond once. A number that differs can be written on the page by hand, and it wins; the next refresh names it before it writes over it, and a key the page's `keep` lists it leaves alone.

## How it works

`net.proxyFetch` runs server-side, so there's no CORS wall between your space and D&D Beyond's character service — the same unofficial endpoint Beyond20, Avrae and ddb-importer all use. Characters must have privacy set to **public**. It's undocumented and does break occasionally; failures degrade to an italic placeholder or a notification rather than erroring the page, and the notification says which failure it was: the character is private or deleted (D&D Beyond's 403 or 404), D&D Beyond is taking too many requests just now (429, so try again shortly), something is wrong at D&D Beyond (a 5xx), the server couldn't reach D&D Beyond at all, or what came back wasn't a character.

## Importing a character

`GM: Import Character` asks for the character's D&D Beyond link, or just its number, and writes a page for it: `Characters/Tamsin Reed`, with the sheet in its frontmatter, then the name, the sheet drawn with `${sheets.draw()}`, and a plain link back to D&D Beyond. The notification opens the page, and has *Undo*, which takes the page away again as long as it holds only what the import wrote. The page's name leaves out what SilverBullet's links can't carry, `@ # $ | < > [ ] ^ / \`, and an ending it would take for a file's extension: `Zed <the Bold>` is `Characters/Zed the Bold`, and `Dr.Who` is `Characters/Dr Who`. A character D&D Beyond sends without a class isn't written at all, since it would come out as a level 1 character with every score 10.

To put a button for it on a page of your own, such as the party's:

    ${widgets.commandButton("Import a character", "GM: Import Character")}

**Refreshing.** An imported page has a bar across its top with *Refresh from D&D Beyond*, or run `GM: Refresh Character` on it. A refresh fetches the character again and rewrites every key the import writes, and nothing else: the page's text, and any key the import doesn't write, such as `player`, `away`, `kit`, `pb` or a campaign's own, stay as they are, and so does any other line of the frontmatter, a comment or a key with a space or quotes in its name. If the page is open, what has been typed into it is saved first.

Before it writes, a refresh says what it would change, and asks. First the level, Hit Points, Armor Class and spell save DC, then every other number that moves, a score, a save, a skill, a slot, an attack's bonus or damage; the features, traits, feats, spells and equipment it adds and takes away; the other keys it rewrites; and, by name, each key you changed by hand since the import last wrote it, which it would write over:

> Refresh Characters/Bram Holloway from D&D Beyond? Level 5→6, HP 68→80, Str 15→17, Longsword +5→+6 to hit and 1d8+2→1d8+3 Slashing. Adds Ability Score Improvement, Potion of Healing (2). Takes away Dagger. Writes over what you changed by hand: hp (you wrote 99).

It tells your changes from D&D Beyond's by `ddb_written`, the import's record of what it wrote: a short checksum of each of its keys, as the import last wrote it. A page imported before GM Beyond kept that record can't tell yet, and says so; from its next refresh on, it can. A refresh that finds nothing new asks nothing and writes only the day. Turn the question off with the `ask` setting; a refresh that would lower the character's level asks even so. Afterwards the notification says in one line what changed, *Bram Holloway 5→6, HP 68→80, +Ability Score Improvement, −Dagger*, and has *Undo*, which puts the page back as it was while it still holds what the refresh wrote; anything changed since is kept.

**Keeping a key as you wrote it.** List the keys a refresh must leave alone in the page's own `keep`:

```yaml
keep: [ac, hp]
```

A kept key stays as you wrote it, in its place among the import's, and a kept key you took out stays out. The refresh still says what D&D Beyond has for it: *Leaves as you wrote them, as keep says: ac (D&D Beyond has 17)*. `keep` is yours, so no refresh touches it, and it can be a list or a line of names with commas, `keep: ac, hp`.

Importing a character whose page already exists refreshes that page, found by the character's number in its `ddb` among the pages in the folder, so a character renamed on D&D Beyond keeps its page: the notification says the name has changed, and the page keeps its own. Failing that, a page of the character's name is refreshed if it is that character's. If SilverBullet can't tell whether that page exists, or can't read it, nothing is written.

**Refreshing the party.** `GM: Refresh the Party` refreshes every imported character in the folder, each by the number in its `ddb`, one after another. It asks once, naming them, and then nothing more; when it's done, one notification says what changed for each, and has *Undo* for all of them:

> Bram Holloway 5→6, HP 68→76, +Ability Score Improvement; Cass Ironwood couldn't be fetched: private or deleted; Ilse Marrow, HP 35→36; Wren Ashdown unchanged.

A character that can't be fetched, sent with no class, or whose page can't be read is left as it is, and the rest go on. So is one whose level would drop, which only its own refresh, with its question, will write.

    ${widgets.commandButton("Refresh the party", "GM: Refresh the Party")}

**What the page holds.** The keys are [GM Sheets](<GM Sheets>)', and the import writes a number only where it isn't the sheet's own sum, the way you would by hand: a Stone of Good Luck's bonus to every check, a magic item's bonus to spell attacks. `jack_of_all_trades` says whether the character has Jack of All Trades, `true` or `false`, so GM Sheets adds its half to the skills without proficiency, and works out nothing about it for itself. Features, traits and feats carry their rules in full, from D&D Beyond's own text, so **keep the pages private**: that text is licensed to the account that owns the books, not yours to publish. A wizard's spellbook comes in as `spellbook`, the spells in it not prepared. Every spell, cantrips included, comes with how it is cast: its casting time and range, and whether it needs concentration, a ritual or a material. Last come the import's own two: `ddb_refreshed`, the day it last wrote or checked the page, `"2026-09-23"`, and `ddb_written`, its record.

**What the player chose.** An option chosen on D&D Beyond is a feature of its own, with its rules, right after the feature it was chosen for: a warlock's *Eldritch Invocations: Agonizing Blast*, a sorcerer's *Metamagic: Quickened Spell*, a Battle Master's *Combat Superiority: Riposte*, a fighting style's *Fighting Style: Archery*, and a species' or a feat's the same way, *Draconic Ancestry: Red* or *Elemental Adept: Fire*. A choice the page already shows under a key of its own, a skill, a language, a tool, a weapon mastery, a spell, a feat or the subclass, isn't said again, and an option waits for the level of the feature it belongs to, with anything it grants. Where an option changes a number the import works out, the number has it: Agonizing Blast adds Charisma to Eldritch Blast's damage, or to the cantrip the 2024 invocation names, and Devil's Sight is a sense of its own, *Devil's Sight 120 ft.*, beside the character's darkvision. What the player adds by hand on D&D Beyond comes in too: a sense's range or a speed they set, a language, a tool or a kind of armor or weapon, and a skill of their own, which the sheet has no row for, among the tools with its ability and bonus, *Riverlore (Wis +5)*. A language picked from D&D Beyond's list comes in when it is one of the Player's Handbook's.

**Every spell, whatever the class.** A class that casts nothing itself can still have spells: an Eldritch Knight's or an Arcane Trickster's come through the subclass, with its spellcasting ability and its slots, a third caster's own table or its share of the multiclass one. The spells a species, a feat such as Magic Initiate (which the 2024 Acolyte, Guide and Sage backgrounds grant), a background, a class feature or an item gives come in too, cantrips as cantrips and the rest as always prepared; an item's while it is equipped, and attuned where it must be, with the item's name in its notes. Each spell is cast with its own ability, the one D&D Beyond gives it or its class's: `spellcasting` is the first class's own, or else a subclass's, or else the one those spells use, and a spell cast with another says so in its notes, with its save DC and attack bonus. A damaging cantrip's attack is rolled with its own ability too.

**What a player writes stays words.** Everything on a D&D Beyond character is written by its player, homebrew rules text and every name included, so none of it reaches your page as markup. Each name is one line, however it was written. Rules text comes in as Markdown with any tag, link, image, hashtag or `${...}` written in it escaped, so it shows as written: `&lt;form&gt;` in D&D Beyond's text is the words `<form>` on the page, never a form. In the frontmatter a name's `<` and `>` are written as YAML's `\x3C` and `\x3E`, which every YAML reader turns back into the characters, and the page's heading and the live roster escape each name as they show it.

## A tab behind its space

A tab reads GM Beyond when it opens. If the space's copy changes after that, from another tab, a sync or `Library: Install`, the tab would go on importing and refreshing with the one it read. `gmb.stale()` says so, nothing while they agree, and otherwise

    This tab runs GM Beyond 2.1.0, but the space has 2.2.0: reload it (System: Reload, Ctrl-Alt-R) first.

It reads the `version` of every page named `Library/Storie/GM Beyond`, at any depth, from the index, and it never fails. While it says so, nothing GM Beyond writes is written, an import, a refresh or an *Undo*: each shows that line instead, and an imported page's bar starts with *⟳ Reload this tab* and the two versions.

## Settings

    config.set("gmBeyond", { folder = "Party/", ask = false })

`folder` is where imported characters' pages go, `Characters/` unless you say otherwise, and where `GM: Refresh the Party` looks for them. `ask = false` refreshes a character without showing what changes first; a level that would drop is asked about even so.

## The live roster

A summary of a character, from the page the import wrote for it, anywhere:

    ${gmb.summary(147258369)}

Or across a roster, handing each page to the summary so it needn't look for it:

    ${query[[
      from p = index.pages()
      where p.type == "pc" and p.ddb
      select gmb.summary(p)
    ]]}

A summary is the character's name, species, classes and level, and the day the import last refreshed it, *Bram Holloway — Hill Dwarf Fighter 3 / Wizard 2, level 5, refreshed 2026-09-23*, as Markdown with each name in it escaped, since the character's player wrote them. It reads the imported page, not D&D Beyond, so a roster no longer fetches every character's whole sheet each time it is shown: refresh the characters, or the party, to bring it up to date.

A character with no imported page, only its number on a page of your own, such as

```yaml
---
type: pc
player: Sam
ddb: 147258369
---
```

is fetched from D&D Beyond as the roster is shown, as before, and so is any character with `${gmb.liveSummary(147258369)}`. One that can't be fetched shows as *(private or unreachable)*, whatever D&D Beyond answered. Always keep a plain link too, so the page stays useful when the fetch doesn't:

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
gmb.version = "2.1.0"

gmb.endpoint = "https://character-service.dndbeyond.com/character/v5/character/"
gmb.sheetLink = "https://www.dndbeyond.com/characters/"

gmb.config = {
  folder = "Characters/",  -- where an imported character's page goes
  ask = true,              -- show what a refresh changes, and ask, before it writes
}

function gmb.setting(key)
  local value = config.get("gmBeyond." .. key, nil)
  if value == nil then value = gmb.config[key] end
  return value
end

-- "a, b and c"
local function andList(items)
  local out = ""
  for i, s in ipairs(items) do
    if i == 1 then out = s
    elseif i == #items then out = out .. " and " .. s
    else out = out .. ", " .. s end
  end
  return out
end

-- A version as a page writes it: "2.1.0", or the number YAML reads 2 as.
local function versionText(v)
  if type(v) == "number" then
    if v == math.floor(v) then return tostring(math.floor(v)) end
    return tostring(v)
  end
  if type(v) ~= "string" then return nil end
  local s = v:match("^%s*(.-)%s*$")
  if s == nil or s == "" then return nil end
  return s
end

-- Versions in order, by the numbers in them: 2.9.0 before 2.10.0.
local function versionLess(a, b)
  local x, y = {}, {}
  for n in a:gmatch("%d+") do x[#x + 1] = tonumber(n) end
  for n in b:gmatch("%d+") do y[#y + 1] = tonumber(n) end
  for i = 1, math.max(#x, #y) do
    if (x[i] or -1) ~= (y[i] or -1) then return (x[i] or -1) < (y[i] or -1) end
  end
  return a < b
end

-- The versions of GM Beyond the space holds other than the one this tab
-- runs: the frontmatter version of every page named Library/Storie/GM
-- Beyond, at any depth, from the index's page objects, lowest first.
-- index.pages() is SilverBullet 2.11's collection of the objects tagged
-- page, the same as index.tag("page").
local function othersInSpace()
  local own = "Library/Storie/GM Beyond"
  local tail = "/" .. own
  local pages = query[[
    from p = index.pages()
    where p.name == own or p.name:endsWith(tail)
    order by p.name
  ]]
  local out, seen = {}, {}
  for _, p in ipairs(pages) do
    local v = versionText(p.version)
    if v and v ~= gmb.version and not seen[v] then
      seen[v] = true
      out[#out + 1] = v
    end
  end
  table.sort(out, versionLess)
  return out
end

-- Why this tab mustn't write: it runs another GM Beyond than the space now
-- holds, as a tab left open across an update does. Nil when every copy in
-- the space matches, or when the index can't say; it never fails.
function gmb.stale()
  local ok, others = pcall(othersInSpace)
  if not ok or type(others) ~= "table" or #others == 0 then return nil end
  return "This tab runs GM Beyond " .. gmb.version .. ", but the space has " .. andList(others) ..
    ": reload it (System: Reload, Ctrl-Alt-R) first."
end

-- The same, as the line the bar starts with; nil while this tab is current.
local function staleLine()
  local ok, others = pcall(othersInSpace)
  if not ok or type(others) ~= "table" or #others == 0 then return nil end
  return "⟳ Reload this tab: it runs GM Beyond " .. gmb.version .. ", and the space has " ..
    andList(others) .. " (System: Reload, Ctrl-Alt-R)."
end

-- True when this tab may write; otherwise says why, and false.
local function current()
  local why = gmb.stale()
  if not why then return true end
  editor.flashNotification(why, "warning")
  return false
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
-- The second value says it in a few words, for a report on the party.
function gmb.refusal(res)
  local status = whole(res and res.status)
  if status == 401 or status == 403 or status == 404 then
    return "D&D Beyond answered " .. tostring(status) ..
      ": the character is private, or has been deleted. Its privacy must be Public", "private or deleted"
  elseif status == 429 then
    return "D&D Beyond answered 429: too many requests just now, so try again shortly",
      "D&D Beyond asked to wait (429)"
  elseif res and res.ok == false then
    local said = type(res.body) == "string" and gmb.line(res.body) or ""
    if #said > 120 then said = said:sub(1, 120) .. "…" end
    return "the server couldn't reach D&D Beyond (it answered " .. tostring(status or "nothing") ..
      (said ~= "" and (": " .. said) or "") .. ")", "the server couldn't reach D&D Beyond"
  elseif status and status >= 500 then
    return "D&D Beyond answered " .. tostring(status) .. ": something is wrong at D&D Beyond, so try again later",
      "trouble at D&D Beyond (" .. tostring(status) .. ")"
  elseif status == 200 then
    return "D&D Beyond's answer wasn't a character's data", "D&D Beyond's answer wasn't a character"
  end
  local said = "D&D Beyond answered " .. tostring(status or "nothing")
  return said, said
end

--- Fetch a public DDB character. Returns nil and a reason when private or
--- unreachable, and the reason in a few words.
function gmb.fetch(id)
  local url = gmb.endpoint .. tostring(id)
  -- Asked for as JSON, which net.proxyFetch then parses whatever the
  -- answer's Content-Type says. An answer that isn't JSON, such as an error
  -- page, makes it throw, so that is asked for again as it comes, for its
  -- status; a second throw is the server failing to fetch at all.
  local ok, res = pcall(net.proxyFetch, url, { responseEncoding = "application/json" })
  if not ok then
    local again, plain = pcall(net.proxyFetch, url)
    if not again then
      return nil, "couldn't reach D&D Beyond through the server: " .. gmb.line(plain),
        "the server couldn't reach D&D Beyond"
    end
    res = plain
  end
  if type(res) ~= "table" then
    return nil, "couldn't reach D&D Beyond through the server", "the server couldn't reach D&D Beyond"
  end
  if whole(res.status) ~= 200 then return nil, gmb.refusal(res) end
  local body = res.body
  local data = type(body) == "table" and body.data or nil
  if type(data) ~= "table" then return nil, gmb.refusal(res) end
  return data
end

--- "Brin — Half-Elf Rogue 4 / Warlock 2", fetched from D&D Beyond as it is
--- now, as Markdown: every name escaped, since a player writes them.
function gmb.liveSummary(id)
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

-- The page imported for character id, from the index: one that holds what
-- the import writes, in the folder if there is one there. Nil for none.
local function importedPage(id)
  if id == nil then return nil end
  local folder = tostring(gmb.setting("folder") or "")
  local ok, rows = pcall(function()
    return query[[
      from p = index.pages()
      where p.ddb == id and p.class ~= nil
      order by p.name
      select p
    ]]
  end)
  if not ok or type(rows) ~= "table" then return nil end
  local best
  for _, p in ipairs(rows) do
    if best == nil or (tostring(p.name):startsWith(folder) and not tostring(best.name):startsWith(folder)) then
      best = p
    end
  end
  return best
end

-- An imported page as a line of the roster: its name, species, classes and
-- level, and the day it was last refreshed, each escaped for Markdown.
local function rosterLine(p)
  local name = tostring(p.name or ""):match("([^/]+)$") or "?"
  local classes = gmb.line(p.class) or "?"
  local level = whole(p.level)
  if level and not classes:find("%d") then
    classes = classes .. " " .. tostring(level)
  elseif level then
    classes = classes .. ", level " .. tostring(level)
  end
  local out = gmb.inline(name) .. " — " .. gmb.inline(p.species or "") .. " " .. gmb.inline(classes)
  local refreshed = type(p.ddb_refreshed) == "string" and gmb.line(p.ddb_refreshed) or ""
  if refreshed ~= "" then out = out .. ", refreshed " .. gmb.inline(refreshed) end
  return out
end

--- A character in the live roster, from the page the import wrote for it:
--- "Brin — Half-Elf Rogue 4 / Warlock 2, level 6, refreshed 2026-09-23",
--- escaped for Markdown. Takes the character's number, or a page from a
--- query. A character with no imported page is fetched from D&D Beyond.
function gmb.summary(ref)
  local p = type(ref) == "table" and ref or nil
  local id = num(p and p.ddb or ref)
  if p == nil or p.class == nil then p = importedPage(id) or p end
  if p and p.class ~= nil then return rosterLine(p) end
  if id == nil then return "_(private or unreachable)_" end
  return gmb.liveSummary(id)
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

-- And the kinds of thing a player adds by hand on D&D Beyond, each an entry
-- of the character's characterValues, 3 meaning proficient: a language
-- (typeId 35) by its number, a kind of armor (typeId 32: 1 light, 2 medium,
-- 3 heavy, 4 shields) or a kind of weapon (typeId 33: 1 simple, 2 martial,
-- 3 firearms).
local LANGUAGE, ARMOR_KIND, WEAPON_KIND = 906033267, 174869515, 660121713

-- D&D Beyond's numbers for the Player's Handbook's languages. A language
-- picked from its list that isn't one of these isn't written.
local LANGUAGES = {
  [1] = "Common", [2] = "Dwarvish", [3] = "Elvish", [4] = "Giant", [5] = "Gnomish", [6] = "Goblin",
  [7] = "Halfling", [8] = "Orc", [9] = "Abyssal", [10] = "Celestial", [11] = "Draconic",
  [12] = "Deep Speech", [13] = "Infernal", [14] = "Primordial", [15] = "Sylvan", [16] = "Undercommon",
  [18] = "Telepathy", [19] = "Aquan", [20] = "Auran", [21] = "Ignan", [22] = "Terran", [23] = "Druidic",
  [46] = "Thieves' Cant", [127] = "Common Sign Language", [137] = "Thieves' Cant",
}

-- D&D Beyond's numbers for a sense and a way of moving, as a custom sense
-- or speed the player sets names them.
local SENSES = { [1] = "blindsight", [2] = "darkvision", [3] = "tremorsense", [4] = "truesight" }
local MOVEMENTS = { [1] = "walk", [2] = "burrow", [3] = "climb", [4] = "fly", [5] = "swim" }

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

-- D&D Beyond's kind of thing an option a player chose is: an invocation, a
-- metamagic, a maneuver, a fighting style. A modifier with this kind comes
-- from the option whose id it names.
local OPTION = 258900837

-- The class features the character has, by id: every one, and those they
-- have reached, with the class each belongs to.
local function featuresOf(c)
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
  return reached, every
end

-- Every modifier that counts, from the species, classes, background, feats
-- and items, each as a plain table: a class's only once the character has
-- reached the feature it comes with, or the feature an option it comes with
-- was chosen for, and a class's own proficiencies only for the class they
-- started in.
function gmb.modifiers(c)
  local out = {}
  local reached, every = featuresOf(c)
  -- the feature each class option was chosen for, by the option's id
  local optionFor = {}
  for _, o in ipairs(list(c.options and c.options.class)) do
    local def = o.definition
    if def and def.id ~= nil then optionFor[tostring(def.id)] = tostring(o.componentId) end
  end
  local function add(m, source, item)
    out[#out + 1] = {
      type = m.type, subType = m.subType, value = num(m.value) or num(m.fixedValue),
      statId = num(m.statId), entityId = num(m.entityId), entityTypeId = num(m.entityTypeId),
      restriction = m.restriction, componentId = tostring(m.componentId), source = source,
      componentTypeId = num(m.componentTypeId), friendly = m.friendlySubtypeName, item = item,
    }
  end
  local mods = c.modifiers or {}
  for _, source in ipairs({ "race", "background", "feat", "condition" }) do
    for _, m in ipairs(list(mods[source])) do add(m, source) end
  end
  for _, m in ipairs(list(mods.class)) do
    local id = tostring(m.componentId)
    local feature = num(m.componentTypeId) == OPTION and optionFor[id] or nil
    if feature then
      if not every[feature] or reached[feature] then add(m, "class") end
    else
      local cl = reached[id]
      if not every[id] or cl then
        if not (cl and m.availableToMulticlass == false and cl.isStartingClass ~= true) then
          add(m, "class")
        end
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

-- What the player chose on D&D Beyond for a class feature, a species trait
-- or a feat (source "class", "race" or "feat"), each { parent = the id of
-- what it was chosen for, name, html = its rules }: every option chosen,
-- such as an invocation, a metamagic or a maneuver, which D&D Beyond sends
-- in `options` with its rules, and every other choice made, which it sends
-- in `choices` as the option's label, and its rules where it has some,
-- from `choices.choiceDefinitions`, keyed "<componentTypeId>-<type>".
local function choicesOf(c, source)
  local out, isOption = {}, {}
  for _, o in ipairs(list(c.options and c.options[source])) do
    local def = o.definition or {}
    local name = gmb.line(def.name)
    if name and name ~= "" then
      out[#out + 1] = { parent = tostring(o.componentId), name = name, html = def.description, id = tostring(def.id) }
      if def.id ~= nil then isOption[tostring(def.id)] = true end
    end
  end
  local choices = c.choices or {}
  local defs = {}
  for _, d in ipairs(list(choices.choiceDefinitions)) do
    if d.id ~= nil then defs[tostring(d.id)] = d end
  end
  for _, ch in ipairs(list(choices[source])) do
    local value = ch.optionValue
    if value ~= nil and not isOption[tostring(value)] then
      local def = defs[tostring(ch.componentTypeId) .. "-" .. tostring(ch.type)]
      for _, o in ipairs(list(def and def.options)) do
        local name = gmb.line(o.label)
        if tostring(o.id) == tostring(value) and name and name ~= "" then
          out[#out + 1] = { parent = tostring(ch.componentId), name = name, html = o.description, id = tostring(o.id) }
        end
      end
    end
  end
  return out
end

-- A name as a choice's label is compared: in lower case, without a score's
-- "+1" or "Score" or a saving throw's words, so "+1 Strength Score" is
-- strength.
local function looks(s)
  local k = tostring(s or ""):lower()
  k = (k:gsub("^%s+", ""))
  k = (k:gsub("%s+$", ""))
  k = (k:gsub("^[%+%-]?%d+%s+", ""))
  k = (k:gsub("%s+score$", ""))
  k = (k:gsub("%s+saving throws?$", ""))
  return k
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
  -- whether the sheet adds Jack of All Trades' half to a skill without
  -- proficiency, said either way, so GM Sheets needn't work it out from the
  -- class and the features
  put("jack_of_all_trades", jack)

  -- the numbers the sums don't give, written under their own names: the
  -- sheet's sums, with Jack of All Trades' half where the page says so
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
    local sum = m[ABILITY[ab]] + p * pb + ((p == 0 and jack) and math.floor(pb / 2) or 0)
    if skillTotals[key] ~= sum then put(key, skillTotals[key]) end
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

  -- what the player chose on D&D Beyond, options and choices: a class's for
  -- the features reached, a species trait's and a feat's
  local reached, every = featuresOf(c)
  local chosen = {}
  for _, source in ipairs({ "class", "race", "feat" }) do
    chosen[source] = {}
    for _, e in ipairs(choicesOf(c, source)) do
      if source ~= "class" or not every[e.parent] or reached[e.parent] then
        table.insert(chosen[source], e)
      end
    end
  end
  -- an option's name, by its id, for what it grants
  local optionName = {}
  for _, source in ipairs({ "class", "race", "feat" }) do
    for _, o in ipairs(list(c.options and c.options[source])) do
      local def = o.definition
      if def and def.id ~= nil then optionName[tostring(def.id)] = gmb.line(def.name) end
    end
  end

  -- speed, and the other ways they move; a speed the player set on D&D
  -- Beyond is the speed
  local customSpeed = {}
  for _, s in ipairs(list(c.customSpeeds)) do
    local which, far = MOVEMENTS[num(s.movementId) or 0], whole(s.distance)
    if which and far and far > 0 then customSpeed[which] = far end
  end
  local speeds = (race.weightSpeeds and race.weightSpeeds.normal) or {}
  local walk = (num(speeds.walk) or 30) + total(find(mods, "bonus", "speed"))
  local armored = false
  for _, it in ipairs(list(c.inventory)) do
    local def = it.definition or {}
    if it.equipped == true and def.filterType == "Armor" then armored = true end
  end
  if not armored then walk = walk + total(find(mods, "bonus", "unarmored-movement")) end
  if customSpeed.walk then walk = customSpeed.walk end
  local others = {}
  for _, mode in ipairs({ { "fly", "flying", "Fly" }, { "swim", "swimming", "Swim" }, { "climb", "climbing", "Climb" }, { "burrow", "burrowing", "Burrow" } }) do
    local value = num(speeds[mode[1]]) or 0
    for _, x in ipairs(find(mods, "set", "innate-speed-" .. mode[2])) do
      local v = x.value or walk
      if v > value then value = v end
    end
    if customSpeed[mode[1]] then value = customSpeed[mode[1]] end
    if value > 0 then others[#others + 1] = mode[3] .. " " .. tostring(math.floor(value)) .. " ft." end
  end
  if #others == 0 then put("speed", walk)
  else put("speed", tostring(walk) .. " ft., " .. table.concat(others, ", ")) end

  -- senses: each at its best range, a custom range the player set on D&D
  -- Beyond among them; then one that comes with a condition, as Devil's
  -- Sight's darkvision does, as a sense of its own, under the name of the
  -- option that grants it, or with the condition
  local customSense = {}
  for _, s in ipairs(list(c.customSenses)) do
    local which, far = SENSES[num(s.senseId) or 0], whole(s.distance)
    if which and far and far > (customSense[which] or 0) then customSense[which] = far end
  end
  local senses, special, seenSense = {}, {}, {}
  for _, sense in ipairs({ "darkvision", "blindsight", "tremorsense", "truesight" }) do
    local range = customSense[sense] or 0
    for _, x in ipairs(find(mods, "set-base", sense)) do
      if (x.value or 0) > range then range = x.value end
    end
    if range > 0 then senses[#senses + 1] = capital(sense) .. " " .. tostring(math.floor(range)) .. " ft." end
    for _, x in ipairs(find(mods, "set-base", sense, true)) do
      if not unrestricted(x) and (x.value or 0) > 0 then
        local far = tostring(math.floor(x.value)) .. " ft."
        local from = x.componentTypeId == OPTION and optionName[x.componentId] or nil
        local text
        if from and from ~= "" then text = from .. " " .. far
        else text = capital(sense) .. " " .. far .. " (" .. (gmb.line(x.restriction) or "") .. ")" end
        if not seenSense[text] then
          seenSense[text] = true
          special[#special + 1] = text
        end
      end
    end
  end
  for _, s in ipairs(special) do senses[#senses + 1] = s end
  put("senses", senses)
  local function names(kind, test)
    local seen, out = {}, {}
    for _, x in ipairs(mods) do
      -- a choice not yet made on D&D Beyond is a modifier "choose-a-language"
      local unmade = tostring(x.subType or ""):find("^choose") ~= nil
      if x.type == kind and test(x) and not unmade then
        local n = gmb.line(x.friendly or capital((tostring(x.subType):gsub("%-", " "))))
        if not seen[n] then seen[n] = true; out[#out + 1] = n end
      end
    end
    table.sort(out)
    return out
  end
  -- a name added to a list once, whatever its case
  local function adding(out, n)
    n = gmb.line(n)
    if not n or n == "" then return end
    local low = n:lower()
    for _, x in ipairs(out) do
      if x:lower() == low then return end
    end
    out[#out + 1] = n
  end
  -- languages, with those the player added on D&D Beyond: written in by
  -- hand, or picked from its list
  local languages = names("language", function() return true end)
  for _, p in ipairs(list(c.customProficiencies)) do
    if num(p.type) == 3 then adding(languages, p.name) end
  end
  for _, v in ipairs(characterValues(c, 35)) do
    if num(v.value) == 3 and num(v.valueTypeId) == LANGUAGE then adding(languages, LANGUAGES[num(v.valueId) or 0]) end
  end
  table.sort(languages)
  put("languages", languages)
  -- tools, with those the player wrote in on D&D Beyond, and a skill of
  -- their own, which the sheet has no row for, with its ability and bonus
  local tools = names("proficiency", function(x) return x.entityTypeId == TOOL end)
  for _, p in ipairs(list(c.customProficiencies)) do
    local kind, at, ab = num(p.type), num(p.proficiencyLevel), num(p.statId)
    local name = gmb.line(p.name) or ""
    if name ~= "" and kind == 2 and (at == nil or at >= 3) then
      adding(tools, at == 4 and (name .. " (Expertise)") or name)
    elseif name ~= "" and kind == 1 and ab and ABILITY[ab] then
      local bonus = whole(p.override)
      if bonus == nil then
        local share = 0
        if at == 2 then share = math.floor(pb / 2) elseif at == 3 then share = pb elseif at == 4 then share = 2 * pb end
        bonus = m[ABILITY[ab]] + share + (whole(p.magicBonus) or 0) + (whole(p.miscBonus) or 0)
      end
      adding(tools, name .. " (" .. SHORT[ab] .. " " .. signed(bonus) .. ")")
    end
  end
  table.sort(tools)
  put("tools", tools)
  -- armor and weapons by kind, with a kind the player added on D&D Beyond
  local addedArmor, addedWeapons = {}, {}
  for _, v in ipairs(characterValues(c, 32)) do
    if num(v.value) == 3 and num(v.valueTypeId) == ARMOR_KIND then addedArmor[num(v.valueId) or 0] = true end
  end
  for _, v in ipairs(characterValues(c, 33)) do
    if num(v.value) == 3 and num(v.valueTypeId) == WEAPON_KIND then addedWeapons[num(v.valueId) or 0] = true end
  end
  local armor = {}
  for i, a in ipairs({ { "light-armor", "light" }, { "medium-armor", "medium" }, { "heavy-armor", "heavy" }, { "shields", "shields" } }) do
    if has(mods, "proficiency", a[1], true) or addedArmor[i] then armor[#armor + 1] = a[2] end
  end
  put("armor_training", armor)
  local simple = has(mods, "proficiency", "simple-weapons", true) or addedWeapons[1] == true
  local martial = has(mods, "proficiency", "martial-weapons", true) or addedWeapons[2] == true
  local weapons = {}
  if simple then weapons[#weapons + 1] = "Simple" end
  if martial then weapons[#weapons + 1] = "Martial" end
  if addedWeapons[3] then weapons[#weapons + 1] = "Firearms" end
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
    if category == 1 and simple then return true end
    if category == 2 and martial then return true end
    if category == 3 and addedWeapons[3] then return true end
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

  -- Agonizing Blast adds Charisma to a cantrip's damage: Eldritch Blast's,
  -- or the cantrip the 2024 invocation is chosen for, which D&D Beyond
  -- names after it, "Agonizing Blast (Eldritch Blast)"
  local agonizing = {}
  for _, e in ipairs(chosen.class) do
    if e.name:find("^Agonizing Blast") then
      local target = e.name:match("%((.-)%)")
      agonizing[target and gmb.line(target) or "Eldritch Blast"] = true
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
        if d then
          damage = withBonus(d, agonizing[cd.name] and m.cha or 0) .. " " ..
            gmb.line(x.friendlySubtypeName or capital(x.subType))
        end
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

  -- what the page shows under keys of its own, which a choice made on D&D
  -- Beyond needn't say again as a feature. `named` holds its names: a
  -- mastery, a spell, a feat, a class or subclass, the species, the
  -- background. `shown` holds those and its proficiencies besides: a skill,
  -- an ability, a language, a tool, training, a size, all of which a pick
  -- with no rules of its own, such as a skill's, can be; a pick with rules,
  -- such as a tiefling's Infernal legacy, is no language.
  local shown, named = {}, {}
  local function showing(s)
    if s ~= nil then shown[looks(s)] = true end
  end
  local function naming(s)
    if s ~= nil then
      shown[looks(s)] = true
      named[looks(s)] = true
    end
  end
  for _, s in ipairs(SKILLS) do showing((s[1]:gsub("%-", " "))) end
  for i = 1, 6 do
    showing(LONG[i])
    showing(SHORT[i])
  end
  for _, l in ipairs({ languages, tools, weapons, SIZES,
      { "Light Armor", "Medium Armor", "Heavy Armor", "Shields", "Shield", "Feat",
        "Ability Score Improvement", "Ability Score Increase" } }) do
    for _, x in pairs(l) do showing(x) end
  end
  for _, x in ipairs(masteries) do
    -- "Sap (Longsword)", which a choice may name as "Longsword (Sap)"
    naming(x)
    local property, weapon = x:match("^(.-)%s*%((.-)%)$")
    if property then
      naming(weapon)
      naming(weapon .. " (" .. property .. ")")
    end
  end
  for _, x in ipairs(subs) do naming(x) end
  for _, cl in ipairs(classes) do naming(gmb.line(cl.definition and cl.definition.name)) end
  for _, e in ipairs(cantrips) do naming(e.name) end
  for _, map in ipairs({ prepared, always, book }) do
    for _, l in pairs(map) do
      for _, e in ipairs(l) do naming(e.name) end
    end
  end
  for _, f in ipairs(list(c.feats)) do naming(gmb.line(f.definition and f.definition.name)) end
  naming(gmb.line(race.fullName))
  naming(gmb.line(bgName))

  -- A list of features, traits or feats, { id, name, text } in order, each
  -- followed by what was chosen for it, named after it: "Eldritch
  -- Invocations: Agonizing Blast". What was chosen for something the list
  -- doesn't hold comes last, under the name of what it was chosen for.
  local function withChoices(items, picks, parents, once)
    local out, used, seen = {}, {}, {}
    -- an item once, where the list has each name once, and a choice once
    local function emit(e, choice)
      if seen[e.name] and (choice or once) then return end
      seen[e.name] = true
      out[#out + 1] = e
    end
    local function pick(e, parent)
      local k = looks(e.name)
      local text = gmb.markdown(e.html)
      -- a pick with rules of its own is only taken for one of the page's
      -- names; one without, for any of its proficiencies as well
      local said = text ~= "" and named or shown
      if k == "" or k:find("^choose") or said[k] then return end
      local name = e.name
      local p = parent and looks(parent) or ""
      if p == k then return end
      local starts = k:sub(1, #p) == p
      if p ~= "" and not starts then name = parent .. ": " .. name end
      emit({ name = name, text = text }, true)
    end
    for _, it in ipairs(items) do
      emit({ name = it.name, text = it.text })
      for i, e in ipairs(picks) do
        if not used[i] and it.id ~= nil and e.parent == it.id then
          used[i] = true
          pick(e, it.name)
        end
      end
    end
    for i, e in ipairs(picks) do
      if not used[i] then pick(e, parents[e.parent]) end
    end
    return out
  end

  -- features, traits and feats, with their rules
  local featureItems, featureNames = {}, {}
  for _, cl in ipairs(classes) do
    local fs = {}
    for _, f in ipairs(list(cl.classFeatures)) do
      local def = f.definition
      if def then featureNames[tostring(def.id)] = gmb.line(def.name) end
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
      featureItems[#featureItems + 1] = { id = tostring(def.id), name = gmb.line(def.name) or "",
        text = gmb.markdown(def.description) }
    end
  end
  local features = withChoices(featureItems, chosen.class, featureNames, true)
  local featureName = gmb.line(bg.definition and bg.definition.featureName)
  if featureName and featureName ~= "" then
    features[#features + 1] = { name = featureName, text = gmb.markdown(bg.definition.featureDescription) }
  end
  put("features", features)
  local traitItems, traitNames = {}, {}
  for _, t in ipairs(list(race.racialTraits)) do
    local def = t.definition
    if def and def.id ~= nil then traitNames[tostring(def.id)] = gmb.line(def.name) end
    if def and def.hideInSheet ~= true then
      traitItems[#traitItems + 1] = { id = def.id ~= nil and tostring(def.id) or nil,
        name = gmb.line(def.name) or "", text = gmb.markdown(def.description) }
    end
  end
  put("traits", withChoices(traitItems, chosen.race, traitNames, false))
  local featItems, featNames = {}, {}
  for _, f in ipairs(list(c.feats)) do
    local def = f.definition
    if def and def.name then
      local id = def.id ~= nil and tostring(def.id) or nil
      if id then featNames[id] = gmb.line(def.name) end
      featItems[#featItems + 1] = { id = id, name = gmb.line(def.name), text = gmb.markdown(def.description) }
    end
  end
  put("feats", withChoices(featItems, chosen.feat, featNames, false))

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
  return gmb.stamp(entries)
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
-- The last two are the import's own record: the day it last wrote the page,
-- and a checksum of each key as it wrote it.
local OWNED = { "ddb", "level", "class", "subclass", "species", "background", "creature_size",
  "str", "dex", "con", "int", "wis", "cha", "saves", "skills", "expertise", "advantage",
  "jack_of_all_trades", "initiative", "str_save", "dex_save", "con_save", "int_save", "wis_save", "cha_save",
  "passive_perception", "passive_insight", "passive_investigation", "spell_dc", "spell_attack",
  "ac", "hp", "hit_dice", "speed", "senses", "languages", "tools", "armor_training", "weapons",
  "masteries", "attacks", "resources", "spellcasting", "slots", "pact_slots", "pact_level",
  "cantrips", "spells", "always_prepared", "spellbook", "features", "traits", "feats",
  "equipment", "attuned", "coins", "ddb_refreshed", "ddb_written" }
for _, s in ipairs(SKILLS) do OWNED[#OWNED + 1] = (s[1]:gsub("%-", "_")) end
gmb.owned = {}
for _, k in ipairs(OWNED) do gmb.owned[k] = true end

-- The keys that are the import's record of itself, not the character's.
local RECORD = { ddb_refreshed = true, ddb_written = true }

-- Today, as a refresh records it: 2026-09-23.
function gmb.today()
  return os.date("%Y-%m-%d")
end

-- The kind of checksum this runtime writes: SHA-256, as SilverBullet has it,
-- or a plain sum where there is none.
local function sumKind()
  if type(crypto) == "table" and crypto.sha256 then return "sha256" end
  return "sum"
end

local DIGITS = "0123456789abcdefghijklmnopqrstuvwxyz"

-- A short checksum of a key's lines: the first six hex digits of their
-- SHA-256, or six base-36 digits of a plain sum of them.
function gmb.checksum(text)
  local s = tostring(text or "")
  if sumKind() == "sha256" then
    local ok, h = pcall(crypto.sha256, s)
    if ok and type(h) == "string" then return h:sub(1, 6) end
  end
  local h = 5381
  for i = 1, #s do h = (h * 33 + s:byte(i)) % 2176782336 end
  local out = {}
  for _ = 1, 6 do
    local d = h % 36
    out[#out + 1] = DIGITS:sub(d + 1, d + 1)
    h = math.floor(h / 36)
  end
  return table.concat(out)
end

-- The sheet's keys, and after them the import's record: the day, and each
-- key's checksum as written, "sha256 ddb:1a2b3c level:...", by which a
-- later refresh tells a key the GM changed by hand from one D&D Beyond did.
function gmb.stamp(entries)
  local out, sums = {}, { sumKind() }
  for _, e in ipairs(entries) do
    if not RECORD[e[1]] then
      out[#out + 1] = e
      sums[#sums + 1] = e[1] .. ":" .. gmb.checksum(yamlEntry(e[1], e[2]))
    end
  end
  out[#out + 1] = { "ddb_refreshed", gmb.today() }
  out[#out + 1] = { "ddb_written", table.concat(sums, " ") }
  return out
end

-- The checksums a page's ddb_written records, by key. Nil for a page with
-- none, or with another kind than this runtime writes.
local function recordOf(s)
  if type(s) ~= "string" then return nil end
  local kind = s:match("^(%S+)")
  if kind ~= sumKind() then return nil end
  local out = {}
  for k, v in s:gmatch("([%w_]+):(%w+)") do out[k] = v end
  return out
end

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

-- The keys a page's keep lists, which a refresh leaves as the GM wrote
-- them: `keep: [ac, hp]`, a list a line to each, or `keep: ac, hp`. Read
-- from the lines themselves, so a frontmatter that doesn't parse as YAML
-- still keeps them.
local function keepOf(text)
  local out = {}
  for _, e in ipairs(entriesOf(text) or {}) do
    if e.key == "keep" then
      local joined = table.concat(e.lines, "\n")
      local value = (joined:match("^[^:]*:(.*)$")) or ""
      value = (value:gsub("#[^\n]*", ""))
      value = (value:gsub("[%[%]\n\"']", ","))
      value = (value:gsub("%-[ \t]", ","))
      for part in (value .. ","):gmatch("([^,]*),") do
        local k = part:lower()
        k = (k:gsub("^%s+", ""))
        k = (k:gsub("%s+$", ""))
        k = (k:gsub("[%s%-]+", "_"))
        if k ~= "" then out[k] = true end
      end
    end
  end
  return out
end
gmb.keepOf = keepOf

-- A character's page brought up to date: the import's keys rewritten but
-- those its keep lists, which stay as the GM wrote them, or out if the GM
-- took them out; and every other key and all the text after the
-- frontmatter as they were.
function gmb.merge(text, entries)
  local keep = keepOf(text)
  local old, body = entriesOf(text)
  local head, mine = {}, {}
  for _, e in ipairs(old or {}) do
    local lines = table.concat(e.lines, "\n")
    if e.key and gmb.owned[e.key] then
      if keep[e.key] and not RECORD[e.key] and mine[e.key] == nil then mine[e.key] = lines end
    else
      head[#head + 1] = lines
    end
  end
  local out, placed = {}, {}
  for _, e in ipairs(entries) do
    local k = e[1]
    if keep[k] and not RECORD[k] then
      if mine[k] and not placed[k] then
        out[#out + 1] = mine[k]
        placed[k] = true
      end
    else
      out[#out + 1] = yamlEntry(k, e[2])
    end
  end
  -- a key kept that the import doesn't write this time stays as well
  for _, e in ipairs(old or {}) do
    local k = e.key
    if k and mine[k] and not placed[k] then
      out[#out + 1] = mine[k]
      placed[k] = true
    end
  end
  local fresh = table.concat(out, "\n")
  local kept = table.concat(head, "\n")
  if kept ~= "" then fresh = kept .. "\n" .. fresh end
  return "---\n" .. fresh .. "\n---\n" .. (body or "")
end

------------------------------------------------------------------ what a refresh changes

-- Each skill's key and its name as the sheet gives it: sleight_of_hand,
-- Sleight of Hand.
local SKILL_NAME = {}
for _, s in ipairs(SKILLS) do
  local words = {}
  for w in s[1]:gmatch("[^%-]+") do words[#words + 1] = w == "of" and w or capital(w) end
  SKILL_NAME[(s[1]:gsub("%-", "_"))] = table.concat(words, " ")
end

-- A number's name where a refresh says what it changes, and whether it is
-- a bonus, which is shown with its sign.
local function label(key)
  if key == "hp" then return "HP" end
  if key == "ac" then return "AC" end
  if key == "spell_dc" then return "spell DC" end
  if key == "spell_attack" then return "spell attack", true end
  if key == "initiative" then return "initiative", true end
  if key == "pact_slots" then return "pact slots" end
  if key == "pact_level" then return "pact slot level" end
  for i = 1, 6 do
    if key == ABILITY[i] then return SHORT[i] end
    if key == ABILITY[i] .. "_save" then return SHORT[i] .. " save", true end
  end
  if SKILL_NAME[key] then return SKILL_NAME[key], true end
  local passive = key:match("^passive_(.+)$")
  if passive then return "passive " .. capital(passive) end
  return (key:gsub("_", " "))
end

-- A value as a refresh shows it: a whole number, a bonus with its sign,
-- text on one line, or "none".
local function say(v, bonus)
  if type(v) == "number" then
    local n = math.floor(v)
    return bonus and signed(n) or tostring(n)
  end
  if type(v) == "string" then return gmb.line(v) end
  return "none"
end

-- The names a page gives as a list: [str, con] or "str, con", each as a
-- key, lower case with _ for a space; a save named in full or by its
-- ability, str_save or str, as both.
local function nameSet(v)
  local out, items = {}, {}
  if type(v) == "string" then
    for part in (v .. ","):gmatch("([^,]*),") do items[#items + 1] = part end
  elseif type(v) == "table" then
    for _, x in ipairs(v) do items[#items + 1] = x end
  end
  for _, x in ipairs(items) do
    local k = tostring(x):lower()
    k = (k:gsub("^%s+", ""))
    k = (k:gsub("%s+$", ""))
    k = (k:gsub("[%s%-]+", "_"))
    out[k] = true
    local ab = k:match("^(%a+)_saves?$")
    if ab then out[ab] = true end
  end
  return out
end

-- Every name in a list of names, or of tables with a name, added to out.
local function namesIn(v, out)
  out = out or {}
  if type(v) == "table" then
    for _, e in ipairs(v) do
      local n = type(e) == "table" and e.name or e
      if n ~= nil then out[#out + 1] = gmb.line(n) end
    end
  elseif type(v) == "string" then
    out[#out + 1] = gmb.line(v)
  end
  return out
end

-- A character's level in a class named in lower case, "bard", as GM Sheets
-- reads it: the number beside it in "Monk 2 / Bard 3" or "Bard 3, Fighter
-- 2", or the level where it is the only class.
local function classLevel(d, class)
  if type(d.class) ~= "string" then return nil end
  local parts = {}
  for part in (d.class .. "/"):gmatch("([^/,]*)[/,]") do
    local s = (part:gsub("^%s+", ""))
    s = (s:gsub("%s+$", ""))
    if s ~= "" then parts[#parts + 1] = s end
  end
  for _, part in ipairs(parts) do
    local rest = part:lower():match("^" .. class .. "(.*)$")
    if rest and not rest:match("^%a") then
      local n = rest:match("(%d+)")
      if n then return tonumber(n) end
      if #parts == 1 then return whole(d.level) end
      return nil
    end
  end
  return nil
end

-- Whether the sheet adds Jack of All Trades to a skill, as GM Sheets works
-- it out: the page's jack_of_all_trades, or else a feature, trait or feat of
-- that name, or else Bard at level 2 or more.
local function jackOf(d)
  if d.jack_of_all_trades == true or d.jack_of_all_trades == false then return d.jack_of_all_trades end
  for _, what in ipairs({ "features", "traits", "feats" }) do
    for _, n in ipairs(namesIn(d[what])) do
      local k = n:lower()
      k = (k:gsub("^%s+", ""))
      k = (k:gsub("%s+$", ""))
      k = (k:gsub("[%s%-]+", "_"))
      if k == "jack_of_all_trades" then return true end
    end
  end
  return (classLevel(d, "bard") or 0) >= 2
end

-- A number as the page gives it, or as the sheet works it out where the
-- page doesn't: a save, a skill, a passive, initiative, spell DC or attack.
local function effective(d, key)
  local written = whole(d[key])
  if written ~= nil then return written end
  local level = whole(d.level) or 1
  if level < 1 then level = 1 end
  local pb = whole(d.pb) or (2 + math.floor((level - 1) / 4))
  local function modOf(ab)
    local score = whole(d[ab])
    return score and math.floor((score - 10) / 2) or nil
  end
  if key == "initiative" then return modOf("dex") end
  local ab = key:match("^(%a+)_save$")
  if ab then
    local m = modOf(ab)
    return m and (m + (nameSet(d.saves)[ab] and pb or 0)) or nil
  end
  for _, s in ipairs(SKILLS) do
    if (s[1]:gsub("%-", "_")) == key then
      local m = modOf(ABILITY[s[2]])
      if m == nil then return nil end
      local p = nameSet(d.expertise)[key] and 2 or (nameSet(d.skills)[key] and 1 or 0)
      return m + p * pb + ((p == 0 and jackOf(d)) and math.floor(pb / 2) or 0)
    end
  end
  local passive = key:match("^passive_(.+)$")
  if passive then
    local skill = effective(d, passive)
    if skill == nil then return nil end
    return 10 + skill + (nameSet(d.advantage)[passive] and 5 or 0) - (nameSet(d.disadvantage)[passive] and 5 or 0)
  end
  if key == "spell_dc" or key == "spell_attack" then
    local cast = tostring(d.spellcasting or ""):lower()
    for i = 1, 6 do
      if cast == LONG[i] then cast = ABILITY[i] end
    end
    local m = modOf(cast)
    if m == nil then return nil end
    return key == "spell_dc" and (8 + pb + m) or (pb + m)
  end
  return nil
end

-- What one list holds and the other doesn't, each name once, in order.
local function missing(from, other)
  local have, out, seen = {}, {}, {}
  for _, n in ipairs(other) do have[n] = true end
  for _, n in ipairs(from) do
    if not have[n] and not seen[n] then
      seen[n] = true
      out[#out + 1] = n
    end
  end
  return out
end

-- What a page carries, each thing once with how many: "Arrows (20)" is 20
-- Arrows. And the names in the order they come.
local function stock(v)
  local out, order = {}, {}
  for _, n in ipairs(namesIn(v)) do
    local base, qty = n:match("^(.-) %((%d+)%)$")
    if not base then base, qty = n, "1" end
    if out[base] == nil then order[#order + 1] = base end
    out[base] = (out[base] or 0) + (tonumber(qty) or 1)
  end
  return out, order
end

-- The numbers a refresh reports when they move, after HP, AC and spell DC,
-- in this order; a derived one, which the sheet works out where the page
-- doesn't write it, is compared as the sheet shows it.
local NUMBERS, DERIVED = { "str", "dex", "con", "int", "wis", "cha", "initiative" }, { initiative = true }
for i = 1, 6 do
  NUMBERS[#NUMBERS + 1] = ABILITY[i] .. "_save"
  DERIVED[ABILITY[i] .. "_save"] = true
end
for _, s in ipairs(SKILLS) do
  local k = (s[1]:gsub("%-", "_"))
  NUMBERS[#NUMBERS + 1] = k
  DERIVED[k] = true
end
for _, k in ipairs({ "passive_perception", "passive_insight", "passive_investigation", "spell_attack" }) do
  NUMBERS[#NUMBERS + 1] = k
  DERIVED[k] = true
end
for _, k in ipairs({ "speed", "pact_slots", "pact_level" }) do NUMBERS[#NUMBERS + 1] = k end

-- What a refresh changes on a page, from its text before and after:
--   unchanged    nothing but the import's record changes
--   level        { was, now }, when the level moves
--   headline     HP, AC and spell DC where they move: "HP 38→45"
--   numbers      each other number that moves: "Str 15→16"
--   added        the features, traits, feats, spells and equipment it adds
--   removed      and those it takes away
--   others       the other keys it rewrites
--   overwritten  the keys the GM changed by hand since the import last
--                wrote them, which it writes over: "hp (you wrote 99)"
--   kept         the keys the page's keep holds back where D&D Beyond has
--                something else
--   recorded     whether the page has the import's record to tell by
--   unparsed     the frontmatter doesn't parse, so nothing is described
-- entries are the import's keys, as gmb.sheet gives them.
function gmb.changes(before, after, entries)
  local out = { headline = {}, numbers = {}, added = {}, removed = {}, others = {}, overwritten = {}, kept = {} }
  local function texts(text)
    local t = {}
    for _, e in ipairs(entriesOf(text) or {}) do
      if e.key and gmb.owned[e.key] and t[e.key] == nil then t[e.key] = table.concat(e.lines, "\n") end
    end
    return t
  end
  local was, now = texts(before), texts(after)
  local changed = {}
  for _, k in ipairs(OWNED) do
    if not RECORD[k] and was[k] ~= now[k] then changed[k] = true end
  end
  out.unchanged = next(changed) == nil
  if out.unchanged then return out end
  local okA, a = pcall(yaml.parse, frontmatter(before) or "")
  local okB, b = pcall(yaml.parse, frontmatter(after) or "")
  if not okA or type(a) ~= "table" or not okB or type(b) ~= "table" then
    out.unparsed = true
    for _, k in ipairs(OWNED) do
      if changed[k] then out.others[#out.others + 1] = (k:gsub("_", " ")) end
    end
    return out
  end
  local covered = {}
  local function number(key, old, new, into)
    if old == new then return end
    local name, bonus = label(key)
    into = into or out.numbers
    into[#into + 1] = name .. " " .. say(old, bonus) .. "→" .. say(new, bonus)
  end
  local function plain(v)
    if type(v) == "number" or type(v) == "string" then return v end
    return nil
  end
  if changed.level then
    covered.level = true
    local lo, ln = whole(a.level), whole(b.level)
    if lo ~= ln then out.level = { lo, ln } end
  end
  for _, k in ipairs({ "hp", "ac" }) do
    if changed[k] then
      covered[k] = true
      number(k, plain(a[k]), plain(b[k]), out.headline)
    end
  end
  covered.spell_dc = changed.spell_dc
  number("spell_dc", effective(a, "spell_dc"), effective(b, "spell_dc"), out.headline)
  for _, k in ipairs(NUMBERS) do
    if changed[k] then
      covered[k] = true
      if DERIVED[k] then number(k, effective(a, k), effective(b, k))
      else number(k, plain(a[k]), plain(b[k])) end
    end
  end
  if changed.slots then
    covered.slots = true
    local function row(v)
      local t = {}
      if type(v) == "table" then
        for _, n in ipairs(v) do t[#t + 1] = say(whole(n) or n) end
      end
      return #t > 0 and table.concat(t, "/") or "none"
    end
    local ra, rb = row(a.slots), row(b.slots)
    if ra ~= rb then out.numbers[#out.numbers + 1] = "slots " .. ra .. "→" .. rb end
  end
  -- a resource's uses, and an attack's to hit and damage, where both have it
  local function byName(v)
    local t, order = {}, {}
    if type(v) == "table" then
      for _, x in ipairs(v) do
        local n = type(x) == "table" and gmb.line(x.name) or nil
        if n and t[n] == nil then
          t[n] = x
          order[#order + 1] = n
        end
      end
    end
    return t, order
  end
  if changed.resources then
    local ra = byName(a.resources)
    local rb, order = byName(b.resources)
    for _, n in ipairs(order) do
      local u, v = ra[n] and whole(ra[n].uses), whole(rb[n].uses)
      if u ~= nil and v ~= nil and u ~= v then
        out.numbers[#out.numbers + 1] = n .. " uses " .. say(u) .. "→" .. say(v)
        covered.resources = true
      end
    end
  end
  if changed.attacks then
    local ra = byName(a.attacks)
    local rb, order = byName(b.attacks)
    for _, n in ipairs(order) do
      local x, y = ra[n], rb[n]
      if x then
        -- "Longsword +5→+6 to hit and 1d8+2→1d8+3 Slashing"
        local said = {}
        if plain(x.hit) ~= plain(y.hit) then
          said[#said + 1] = say(plain(x.hit), true) .. "→" .. say(plain(y.hit), true) .. " to hit"
        end
        if plain(x.damage) ~= plain(y.damage) then
          local from, to = say(plain(x.damage)), say(plain(y.damage))
          local d1, kind1 = from:match("^(%S+) (.+)$")
          local d2, kind2 = to:match("^(%S+) (.+)$")
          if d1 and d2 and kind1 == kind2 then said[#said + 1] = d1 .. "→" .. d2 .. " " .. kind1
          else said[#said + 1] = from .. "→" .. to end
        end
        if #said > 0 then
          out.numbers[#out.numbers + 1] = n .. " " .. table.concat(said, " and ")
          covered.attacks = true
        end
      end
    end
  end
  -- features, traits and feats, then spells, then equipment, added and taken away
  for _, k in ipairs({ "features", "traits", "feats" }) do
    if changed[k] then
      local na, nb = namesIn(a[k]), namesIn(b[k])
      local plus, minus = missing(nb, na), missing(na, nb)
      for _, n in ipairs(plus) do out.added[#out.added + 1] = n end
      for _, n in ipairs(minus) do out.removed[#out.removed + 1] = n end
      if #plus > 0 or #minus > 0 then covered[k] = true end
    end
  end
  local SPELLS = { "cantrips", "spells", "always_prepared", "spellbook" }
  local function spellNames(d)
    local names = {}
    for _, k in ipairs(SPELLS) do
      local v = d[k]
      if k == "cantrips" or type(v) ~= "table" then namesIn(v, names)
      else
        for _, l in pairs(v) do namesIn(l, names) end
      end
    end
    return names
  end
  local sa, sb = spellNames(a), spellNames(b)
  local plus, minus = missing(sb, sa), missing(sa, sb)
  table.sort(plus)
  table.sort(minus)
  for _, n in ipairs(plus) do out.added[#out.added + 1] = n end
  for _, n in ipairs(minus) do out.removed[#out.removed + 1] = n end
  if #plus > 0 or #minus > 0 then
    for _, k in ipairs(SPELLS) do covered[k] = true end
  end
  if changed.equipment then
    local ea, oa = stock(a.equipment)
    local eb, ob = stock(b.equipment)
    for _, n in ipairs(ob) do
      if ea[n] == nil then
        out.added[#out.added + 1] = eb[n] > 1 and (n .. " (" .. say(eb[n]) .. ")") or n
      elseif ea[n] ~= eb[n] then
        out.numbers[#out.numbers + 1] = n .. " " .. say(ea[n]) .. "→" .. say(eb[n])
      end
    end
    for _, n in ipairs(oa) do
      if eb[n] == nil then out.removed[#out.removed + 1] = n end
    end
    covered.equipment = true
  end
  for _, k in ipairs(OWNED) do
    if changed[k] and not covered[k] then out.others[#out.others + 1] = (k:gsub("_", " ")) end
  end
  -- what the GM changed by hand since the import last wrote it, by the
  -- checksums it recorded then, which the refresh would write over
  local record = recordOf(a.ddb_written)
  out.recorded = record ~= nil
  if record then
    for _, k in ipairs(OWNED) do
      if changed[k] then
        local mine = was[k] and gmb.checksum(was[k]) or nil
        if mine ~= record[k] then
          local v = a[k]
          if was[k] == nil then out.overwritten[#out.overwritten + 1] = k .. " (you took it out)"
          elseif plain(v) ~= nil then out.overwritten[#out.overwritten + 1] = k .. " (you wrote " .. say(plain(v)) .. ")"
          else out.overwritten[#out.overwritten + 1] = k end
        end
      end
    end
  end
  -- what keep holds back, where D&D Beyond has something else
  local keep = keepOf(before)
  for _, e in ipairs(entries or {}) do
    local k = e[1]
    if keep[k] and not RECORD[k] and yamlEntry(k, e[2]) ~= was[k] then
      local v = plain(e[2])
      out.kept[#out.kept + 1] = k .. (v ~= nil and (" (D&D Beyond has " .. say(v) .. ")") or "")
    end
  end
  return out
end

-- At most `most` of a list's entries, with a count of the rest.
local function listed(items, most)
  most = most or 10
  local t = {}
  for i = 1, math.min(#items, most) do t[i] = items[i] end
  if #items > most then t[#t + 1] = "and " .. tostring(#items - most) .. " more" end
  return table.concat(t, ", ")
end

--- What a refresh changed, on one line, for a notification or a report:
--- "Bram Holloway 4→5, HP 38→45, +Extra Attack": the level, HP, AC and
--- spell DC, what it adds and takes away, and then the other numbers.
function gmb.changeLine(who, diff)
  if diff.unchanged then return who .. " unchanged" end
  local parts = {}
  for _, n in ipairs(diff.headline or {}) do parts[#parts + 1] = n end
  for _, n in ipairs(diff.added) do parts[#parts + 1] = "+" .. n end
  for _, n in ipairs(diff.removed) do parts[#parts + 1] = "−" .. n end
  for _, n in ipairs(diff.numbers) do parts[#parts + 1] = n end
  if #diff.others > 0 then parts[#parts + 1] = table.concat(diff.others, ", ") .. " rewritten" end
  local head = who
  if diff.level then head = head .. " " .. say(diff.level[1]) .. "→" .. say(diff.level[2]) end
  if #parts == 0 then return head end
  return head .. ", " .. listed(parts, 6)
end

--- What a refresh asks before it writes: everything it changes.
function gmb.changeQuestion(page, who, diff, drop)
  local s = { "Refresh " .. page .. " from D&D Beyond?" }
  if drop then
    s[#s + 1] = "D&D Beyond has " .. who .. " at level " .. say(drop.now) .. ", and " .. page ..
      " says level " .. say(drop.was) .. "."
  end
  local numbers = {}
  if diff.level then numbers[1] = "level " .. say(diff.level[1]) .. "→" .. say(diff.level[2]) end
  for _, n in ipairs(diff.headline or {}) do numbers[#numbers + 1] = n end
  for _, n in ipairs(diff.numbers) do numbers[#numbers + 1] = n end
  if #numbers > 0 then s[#s + 1] = capital(listed(numbers, 12)) .. "." end
  if #diff.added > 0 then s[#s + 1] = "Adds " .. listed(diff.added) .. "." end
  if #diff.removed > 0 then s[#s + 1] = "Takes away " .. listed(diff.removed) .. "." end
  if #diff.others > 0 then s[#s + 1] = "Rewrites " .. listed(diff.others) .. "." end
  if #diff.overwritten > 0 then
    s[#s + 1] = "Writes over what you changed by hand: " .. listed(diff.overwritten) .. "."
  end
  if #diff.kept > 0 then s[#s + 1] = "Leaves as you wrote them, as keep says: " .. listed(diff.kept) .. "." end
  if diff.unparsed then
    s[#s + 1] = "(The page's frontmatter doesn't parse as YAML, so only the keys it rewrites are named.)"
  elseif not diff.recorded then
    s[#s + 1] = "(The page has no record yet of what GM Beyond wrote, so it can't tell what you changed by " ..
      "hand from what D&D Beyond did; from this refresh on, it can.)"
  end
  return table.concat(s, " ")
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
    if not current() then return end
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

-- Undo for a refresh of the party: each page as it was, while it still
-- holds what was written. Anything changed since stays.
local function undoAll(writes)
  return function()
    if not current() then return end
    local done, left = 0, {}
    for _, w in ipairs(writes) do
      flush(w.page)
      if readPage(w.page) == w.after then
        space.writePage(w.page, w.before)
        reload(w.page)
        done = done + 1
      else
        left[#left + 1] = w.page
      end
    end
    local said = done == 1 and "Undone: 1 page is as it was." or
      ("Undone: " .. tostring(done) .. " pages are as they were.")
    if #left > 0 then
      said = said .. " " .. andList(left) .. (#left == 1 and " has" or " have") ..
        " changed since, so Undo left " .. (#left == 1 and "it" or "them") .. " as " ..
        (#left == 1 and "it is." or "they are.")
    end
    editor.flashNotification(said, #left > 0 and "error" or "info")
  end
end

function gmb.levelOf(entries)
  for _, e in ipairs(entries) do if e[1] == "level" then return e[2] end end
  return nil
end

-- The name on a character's page: the last part of its path.
local function sheetName(page)
  return tostring(page):match("([^/]+)$") or tostring(page)
end

-- A character's page brought up to date with what D&D Beyond sent, once
-- what is typed into it is saved, and once the GM has seen what changes and
-- said to, unless the ask setting is off; a level that would drop is asked
-- about even so. opts.open adds Open to the notification, and opts.note a
-- sentence. opts.party is a refresh of the whole party, which was asked
-- about once already: it asks nothing and notifies nothing, and leaves a
-- page whose level would drop. Returns the page, or nil when nothing was
-- written, and what happened, for a report: { line, failed, undo }.
local function update(page, id, c, entries, opts)
  local name = gmb.line(c.name) or "?"
  local who = opts.who or name
  local function refuse(message, brief)
    if not opts.party then editor.flashNotification("GM Beyond: " .. message, "error") end
    return nil, { line = who .. " " .. brief, failed = true }
  end
  local saved, err = flush(page)
  if not saved then
    return refuse("couldn't save what is typed into " .. page .. " first (" .. tostring(err) ..
      "), so it wasn't refreshed.", "wasn't refreshed: what is typed into it couldn't be saved first")
  end
  local text = readPage(page)
  if not text then return refuse("couldn't read " .. page .. ", so it wasn't refreshed.", "couldn't be read") end
  if ddbOf(text) ~= id then
    return refuse(page .. " isn't character " .. tostring(id) .. "'s page any more, so it wasn't refreshed.",
      "isn't that character's page any more")
  end
  local open = opts.open and { name = "Open", run = function() editor.navigate(page) end } or nil
  local after = gmb.merge(text, entries)
  local diff = gmb.changes(text, after, entries)
  if diff.unchanged then
    -- nothing of the character's changed: only the day it was checked is
    -- written, if that has moved on
    if after ~= text then
      space.writePage(page, after)
      reload(page)
    end
    if not opts.party then
      editor.flashNotification(page .. " is already up to date with D&D Beyond." .. (opts.note or ""), "info",
        open and { actions = { open } } or nil)
    end
    return page, { line = gmb.changeLine(who, diff) }
  end
  local was, now = levelIn(text), levelIn(after)
  local drops = was ~= nil and now ~= nil and now < was
  if opts.party then
    if drops then
      return nil, { line = who .. " would go from level " .. tostring(was) .. " to " .. tostring(now) ..
        ", so it was left as it is (refresh it on its own to take the lower level)", failed = true }
    end
  else
    local question
    if gmb.setting("ask") ~= false then
      question = gmb.changeQuestion(page, name, diff, drops and { was = was, now = now } or nil)
    elseif drops then
      question = "D&D Beyond has " .. name .. " at level " .. tostring(now) .. ", and " .. page ..
        " says level " .. tostring(was) .. ". Refresh the page to level " .. tostring(now) .. "?"
    end
    if question and not editor.confirm(question) then
      editor.flashNotification(page .. (drops and (" is left at level " .. tostring(was) .. ".") or
        " is left as it was."), "info")
      return nil, { line = who .. " left as it was", failed = true }
    end
    -- what reached the page while the question was open stays
    if question then
      local again = readPage(page)
      if not again then return refuse("couldn't read " .. page .. ", so it wasn't refreshed.", "couldn't be read") end
      if again ~= text then
        if ddbOf(again) ~= id then
          return refuse(page .. " isn't character " .. tostring(id) .. "'s page any more, so it wasn't refreshed.",
            "isn't that character's page any more")
        end
        text, after = again, gmb.merge(again, entries)
      end
    end
  end
  space.writePage(page, after)
  reload(page)
  local line = gmb.changeLine(who, diff)
  if not opts.party then
    local actions = {}
    if open then actions[#actions + 1] = open end
    actions[#actions + 1] = { name = "Undo", run = undoTo(page, text, after) }
    editor.flashNotification("Refreshed " .. page .. " from D&D Beyond: " .. line .. "." .. (opts.note or ""),
      "info", { actions = actions, timeout = 10000 })
  end
  if #diff.overwritten > 0 then
    local keys = {}
    for _, o in ipairs(diff.overwritten) do keys[#keys + 1] = (o:match("^(%S+)")) end
    line = line .. " (over what you wrote in " .. andList(keys) .. ")"
  end
  return page, { line = line, undo = { page = page, before = text, after = after } }
end

-- Import a character from a link to it, or refresh its page if it has one:
-- the page with its number in the folder, whatever it is called now, or
-- else the one named for it.
function gmb.import(link)
  if not current() then return end
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
    return (update(page, id, c, entries, { open = true, note = note }))
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
  if not current() then return end
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
  return (update(page, id, c, gmb.sheet(c), {}))
end

-- The pages in the folder imported from D&D Beyond, by name, each with its
-- character's number, as the index has them.
local function partyPages()
  local folder = tostring(gmb.setting("folder") or "")
  local ok, rows = pcall(function()
    return query[[
      from p = index.pages()
      where p.ddb ~= nil and p.name:startsWith(folder)
      order by p.name
      select { name = p.name, ddb = p.ddb }
    ]]
  end)
  local out = {}
  if not ok or type(rows) ~= "table" then return out, folder end
  for _, r in ipairs(rows) do
    local id = num(r.ddb)
    if id and type(r.name) == "string" then out[#out + 1] = { name = r.name, id = id } end
  end
  return out, folder
end

--- Refresh every character imported into the folder from D&D Beyond, one
--- after another, having asked once; one that can't be fetched or written
--- is skipped, and the notification says what changed for each: "Bram
--- Holloway 4→5, +Extra Attack; Ilse Marrow unchanged; Cass Ironwood
--- couldn't be fetched: private or deleted". Returns that report's lines.
function gmb.refreshParty()
  if not current() then return end
  local pages, folder = partyPages()
  if #pages == 0 then
    editor.flashNotification("GM Beyond: no page in " .. (folder ~= "" and folder or "the space") ..
      " has a D&D Beyond character to refresh.", "info")
    return
  end
  local names = {}
  for _, p in ipairs(pages) do names[#names + 1] = sheetName(p.name) end
  if not editor.confirm("Refresh " .. (#pages == 1 and "1 character" or (tostring(#pages) .. " characters")) ..
      " from D&D Beyond: " .. listed(names, 12) .. "? Each page's keys from D&D Beyond are rewritten, and " ..
      "nothing else: its text, the keys you added and those its keep lists stay as they are.") then
    return
  end
  local fetched, report, writes, failed = {}, {}, {}, false
  for _, p in ipairs(pages) do
    local who = sheetName(p.name)
    local got = fetched[p.id]
    if got == nil then
      local ok, c, _, brief = pcall(gmb.fetch, p.id)
      got = { c = ok and c or nil, brief = ok and brief or "the server couldn't reach D&D Beyond" }
      fetched[p.id] = got
    end
    local line
    if not got.c then
      line = who .. " couldn't be fetched: " .. tostring(got.brief)
      failed = true
    elseif #list(got.c.classes) == 0 then
      line = who .. " was left as it is: D&D Beyond sent it with no class"
      failed = true
    else
      local ok, written, result = pcall(function()
        return update(p.name, p.id, got.c, gmb.sheet(got.c), { party = true, who = who })
      end)
      if not ok then
        line = who .. " wasn't refreshed: " .. (gmb.line(written) or "?")
        failed = true
      else
        line = result.line
        if result.failed then failed = true end
        if result.undo then writes[#writes + 1] = result.undo end
      end
    end
    report[#report + 1] = line
  end
  local options = { timeout = 30000 }
  if #writes > 0 then options.actions = { { name = "Undo", run = undoAll(writes) } } end
  editor.flashNotification(table.concat(report, "; ") .. ".", failed and "warning" or "info", options)
  return report
end

------------------------------------------------------------------ the bar

-- A bar across an imported character's page: a refresh, and the character
-- on D&D Beyond; and first, when this tab runs another GM Beyond than the
-- space holds, a line that says to reload it.
function gmb.bar(page)
  page = page or editor.getCurrentPage()
  local id = ddbOf(readPage(page))
  if not id then return nil end
  local bar = { class = "gmb-bar" }
  local stale = staleLine()
  if stale then bar[#bar + 1] = dom.span { class = "gmb-stale", __rawText = stale } end
  bar[#bar + 1] = dom.strong { __rawText = "D&D Beyond" }
  bar[#bar + 1] = dom.button {
    class = "sb-button",
    onclick = function()
      local ok, err = pcall(gmb.refresh, page)
      if not ok then editor.flashNotification("GM Beyond: " .. tostring(err), "error") end
    end,
    __rawText = "Refresh from D&D Beyond",
  }
  bar[#bar + 1] = dom.a { href = gmb.sheetLink .. tostring(id), target = "_blank", __rawText = "Open on D&D Beyond" }
  return widget.new {
    html = dom.div(bar),
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

command.define {
  name = "GM: Refresh the Party",
  run = function() gmb.refreshParty() end,
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

/* A tab behind its space: a line of its own, in words, over the rest. */
.gmb-bar .gmb-stale {
  flex-basis: 100%;
  font-weight: bold;
}

/* The widget's own Copy and Reload overlay would cover the bar's buttons. */
.sb-lua-top-widget:has(.gmb-bar) .button-bar {
  display: none !important;
}
```
