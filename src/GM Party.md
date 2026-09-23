---
tags: meta/library
name: "Library/Storie/GM Party"
description: "Numbers, hand-outs, fights and DCs that follow the party's size and level: live for your table in SilverBullet, and as general rules when the adventure is printed. Encounter math from the 2024 rules in the SRD 5.2.1."
author: "Steven Storie"
version: "1.5.0"
---

# GM Party

Write an adventure once, for the party size you design it for, and let its numbers follow the table that plays it. In SilverBullet a number that scales shows your party's value. In print it shows the rule, so the book works for any table.

| On the page, for a party of six at level 9 | In print |
|---|---|
| It holds seven arrows | It holds one more arrow than the party has members, six for a party of five |
| A camp with room for six | A camp with room for five |
| Six here: all five finds, with one find shared by two | Nothing: the text itself says how finds are shared |
| The fight for this party: its creatures, XP and difficulty | The fight for five, and an *Adjusting the Encounter* note with a table for three to seven characters |
| A fight in versions: the one written for the level nearest theirs, and how the others would go | Every version, each for five characters at its own level, with its own *Adjusting the Encounter* |
| DC 17 | DC 15, as written for levels 1 to 4 |

The page side needs nothing else. For print, GM Book 1.5 or later prints each of these in its general form, and GM Kit 2.2 or later puts your party's numbers into the copies it publishes to players.

## Where the party comes from

The most specific source wins:

1. **Character pages.** Every page with `type: pc` is a member, at its own `level`. `away: true` sits a character out of tonight's fights and hand-outs. `retired: true` takes a character out of the party altogether.
2. **A party page.** Before the characters exist, a page with `type: party` gives `characters` and `level`. Its `level` also stands in for a character page that has none. The count can't be called `size`: SilverBullet keeps that name for a page's size in bytes, and a page's own attributes win over its frontmatter.
3. **The adventure's party.** With neither, as in an adventure space on its own, the party is the one the adventure is written for: five, unless the settings say otherwise.

A party page's frontmatter:

    ---
    type: party
    characters: 5
    level: 1
    ---

Counts and story numbers follow everyone in the party. Fights and one-each hand-outs follow the characters here tonight.

**Away and retired.** A character who is `away` misses tonight, and is still in the party: the story numbers and counts include them, since the camp still has room for them and the quiver still holds their arrow, and the summary lists them, marked away. Fights, one-each hand-outs and the party's level follow only the characters here. A character who is `retired` has left the party for good, and counts nowhere: not in the story numbers, counts, fights, hand-outs, level or DCs, as if the page were no character's. The summary names them on a line of their own, so a page marked retired by mistake is seen. When every character page is retired, the party page, or the adventure's party, stands in again, as it does before there are any.

| On a `type: pc` page | Story numbers and counts | Fights, hand-outs, level and DCs | The summary |
|---|---|---|---|
| Neither | Counted | Counted | Listed |
| `away: true` | Counted | Left out | Listed, marked away |
| `retired: true` | Left out | Left out | Named as retired, and counted nowhere |

**The party's level** is the average level of the characters here tonight, rounded to the nearest. It picks a fight's version and sets a DC. Before the character pages exist, it is the party page's `level`: change that when everyone levels up. In an adventure space on its own there is no level, so a fight shows every version as written, and a DC shows as written. `party.level()` gives it, or nil.

On a DM page, `${party.summary()}` shows the party, who is here, and what a fight for them can spend.

## Numbers

**A number in the story** that follows the party: `party.n()` is its size, `party.n(1)` one more, `party.n{times = 2}` twice as many. `party.N` is the same with a capital, to start a sentence. In print, each is the number for the adventure's party.

    A camp with room for ${party.n()}. ${party.N()} bedrolls, ${party.n()} packs.

These work anywhere a sentence does, table cells included.

**A count that follows a rule**: `party.count` takes the thing counted and the rule. On the page it shows the count for your party. In print it shows the rule, then the count for the adventure's party.

    It holds ${party.count{"arrow", plus = 1}}: enough for everyone.

| Rule | Prints |
|---|---|
| `{"arrow"}` | as many arrows as the party has members, five for a party of five |
| `{"arrow", plus = 1}` | one more arrow than the party has members, six for a party of five |
| `{"arrow", plus = -1}` | one fewer arrow than the party has members, four for a party of five |
| `{"arrow", per = 2}` | two arrows for each member of the party, ten for a party of five |
| `{"arrow", per = 1/2}` | one arrow for every two members of the party, rounding up, three for a party of five |

`min` and `max` bound a count, `round = "down"` rounds a fraction down, and `example = false` leaves off the count for the adventure's party. A second name is the plural where adding an s won't do: `{"wolf", "wolves"}`. `cap = true` starts it with a capital.

Hover over a number on the page to see its rule and what it prints. On a phone, which has no hover, tap it: the note shows in a box across the foot of the screen until you tap elsewhere. A number can take focus from the keyboard too, and shows its note under it while it has it.

**A count that is an item's uses** can name the item, as a link in the adventure would: `item = "World/Items/Quiver"`. It changes nothing on the page or in print. GM Kit 2.3 or later reads it: when the party finds the item there, its uses start at this count for the party at that moment.

    It holds ${party.count{"arrow", plus = 1, item = "World/Items/Quiver"}}.

**The number itself**, for a library that needs it: `party.value{"arrow", plus = 1}` is 6 for a party of five, and `party.value(1)` is the party's size plus one. A second argument asks for another size: `party.value({"arrow"}, 7)` is 7.

## One each

`party.each(5, "find")` goes under a list of five things handed out one per character, most important first. It says which to use for the characters here tonight: "Four here: use the first four finds", or "Six here: all five finds, with one find shared by two". It prints nothing, so say in the text itself how a smaller or larger party shares them.

## Fights

Write each fight for the adventure's party, at the level it expects the characters to be:

    ${party.fight { "The barrow", level = 3, difficulty = "moderate",
      {1, "wight", cr = 3},
      {1, "warhorse skeleton", cr = "1/2"},
      {6, "skeleton", cr = "1/4", step = 4},
    }}

Each creature is `{count, name, cr = ...}`, with its count for the adventure's party. `xp` can stand in for a CR. How a creature scales:

| Key | Means |
|---|---|
| `step = 4` | Four more for each character over the adventure's party, four fewer for each under |
| `min`, `max` | Never fewer, never more |
| `from = 6` | Only with six or more characters |
| `upto = 4` | Only with four or fewer |
| `plural` | The plural, where adding an s won't do |
| `page` | The page that describes this creature, as a link in the adventure would write it |

**A creature's own page.** `page = "World/Monsters/Strangler"` names it, and the fight gets a line of its own listing the creatures that have one:

    ${party.fight { "The old orchard", level = 1, difficulty = "low",
      {1, "strangler", cr = "1/2", page = "World/Monsters/Strangler"},
      {6, "creeper", cr = "1/8", step = 2, min = 2, page = "World/Monsters/Creeper"},
    }}

On the page each creature is a link to its own, and one whose page isn't there is flagged. In print the line carries whatever a library that reads those pages gives it, and without one it doesn't print at all. To let a library decide, set `party.creatureRef`: it takes the page a creature names, the creature's name and its CR, and gives back `{ page = <the page it found>, cite = <what to print for it>, warn = <something to flag> }`. GM Bestiary 1.0 or later does this, so a creature prints with the book and entry its page cites, and a CR here that disagrees with the one on the page is flagged.

That fight prints its creatures between the encounter and *Adjusting the Encounter*:

    **The creatures.** Strangler — Monster Manual, *Blights* (vine blight). Creeper — Monster Manual, *Blights* (twig blight).

`creatures` names that line, which is *The creatures* by default.

For the whole fight, `difficulty` is what it is meant to be: low, moderate or high. `note` adds a sentence to *Adjusting the Encounter*, `table = false` leaves the table out of print, and `size` writes the fight for a party other than the adventure's.

**On the page** it shows the fight for the characters here tonight, at their levels: the creatures, their XP, the difficulty against the Low, Moderate and High budgets, and a table of other party sizes with yours marked ▶. Your row is the difficulty above it, each character at their own level; another size spends what your characters spend each, on average, so where their levels differ the table still agrees with the fight. It flags what the SRD's troubleshooting advice flags: more than two creatures per character, a creature whose CR is above the party's level (their average level, rounded, not the highest), more than three stat blocks, and a lone creature. It also flags a fight that has drifted from its intended difficulty. Difficulty always shows as pips and a word, ●○○ Low, ●●○ Moderate, ●●● High and ●●●+ Above High, with colour only as a third cue. On a phone, a table too wide for the fight's box scrolls sideways inside it.

**In print** it gives the fight for the adventure's party with its difficulty and XP. Then comes *Adjusting the Encounter*: a sentence for each rule, and a table for three to seven characters at the written level.

    **The barrow.** A wight, a warhorse skeleton and six skeletons: a moderate-difficulty encounter for five level 3 characters (1,100 XP).

    **Adjusting the Encounter.** For each character fewer than five, remove four skeletons; for each one more, add four.

    | Characters | Skeletons | XP | Difficulty |
    |---|---|---|---|
    | 3 | 0 | 800 | High |
    | 4 | 2 | 900 | Moderate |
    | 5 | 6 | 1,100 | Moderate |
    | 6 | 10 | 1,300 | Moderate |
    | 7 | 14 | 1,500 | Moderate |

Put a fight on a line of its own, since it prints as paragraphs and a table.

## Fights by level

A fight the party might reach at more than one level, as in an adventure whose parts can be played in any order, can come in versions, one for each level it might be met at. More of the same creatures only goes so far: past a point, a crowd of weak creatures only gives the party more targets. So each version names the creatures that belong at its level.

    ${party.fight { "The barrow", difficulty = "moderate",
      { level = 3,
        {1, "wight", cr = 3},
        {1, "warhorse skeleton", cr = "1/2"},
        {6, "skeleton", cr = "1/4", step = 4},
      },
      { level = 6,
        {1, "wraith", cr = 5},
        {2, "wight", cr = 3, step = 1, min = 1},
        {4, "skeleton", cr = "1/4"},
      },
    }}

Each version is `{ level = ..., creatures }`, with its creatures written as in any fight, counts for the adventure's party and all. The fight's name and settings are every version's, and a version can give its own `difficulty` and `note`. The creatures go inside the versions: a fight has versions or creatures of its own, not both.

**A creature in more than one version** can be stronger in each, like a lieutenant the party might meet at any of several levels. Give it the CR it has in that version. Its page then carries a stat block for each level, and lists every CR it runs at: GM Bestiary 1.1 or later reads `cr: ["3", "5"]` and flags only a CR that isn't there.

**On the page** it runs the version written for the level nearest the party's, the lower of two as near, and shows it as it shows any fight, for the characters here tonight. The others follow, each with its creatures, its XP and its difficulty for your party, so you can see what running another would do. With no party level, as in an adventure space on its own, it shows every version as written.

**In print** the general rule comes first, then each version as any fight prints: its creatures, difficulty and XP for the adventure's party at its level, then its own *Adjusting the Encounter* and table.

    **The barrow.** Two versions, for level 3 and level 6 characters: run the one nearest your party's level.

    **Level 3.** A wight, a warhorse skeleton and six skeletons: a moderate-difficulty encounter for five level 3 characters (1,100 XP).

    **Adjusting the Encounter.** For each character fewer than five, remove four skeletons; for each one more, add four.

    | Characters | Skeletons | XP | Difficulty |
    |---|---|---|---|
    | 3 | 0 | 800 | High |
    | 4 | 2 | 900 | Moderate |
    | 5 | 6 | 1,100 | Moderate |
    | 6 | 10 | 1,300 | Moderate |
    | 7 | 14 | 1,500 | Moderate |

    **Level 6.** A wraith, two wights and four skeletons: a moderate-difficulty encounter for five level 6 characters (3,400 XP).

    **Adjusting the Encounter.** For each character fewer than five, remove a wight; for each one more, add one. Keep at least one wight.

    | Characters | Wights | XP | Difficulty |
    |---|---|---|---|
    | 3 | 1 | 2,700 | Moderate |
    | 4 | 1 | 2,700 | Moderate |
    | 5 | 2 | 3,400 | Moderate |
    | 6 | 3 | 4,100 | Moderate |
    | 7 | 4 | 4,800 | Moderate |

The line of creatures with pages of their own comes after the rule, once for every version. A fight with one version is a fight at that level.

## DCs by level

A check the party can meet at any level can keep its odds as they grow. `party.dc(15)` is a DC written for characters of levels 1 to 4. It rises by one at levels 5, 9, 13 and 17, where the proficiency bonus does, so a character proficient in the check has the same chance of it at any level.

    **Wisdom (Perception)**, DC ${party.dc(15)}, to see the tripwire before someone finds it.

| Level | 1–4 | 5–8 | 9–12 | 13–16 | 17–20 |
|---|---|---|---|---|---|
| `party.dc(10)` | 10 | 11 | 12 | 13 | 14 |
| `party.dc(15)` | 15 | 16 | 17 | 18 | 19 |
| `party.dc(20)` | 20 | 21 | 22 | 23 | 24 |

On the page it shows your party's DC, 17 at level 9, and in print the DC as written, 15. A book that uses it says once, with its rules, that its DCs rise with the proficiency bonus. With no party level, as in an adventure space on its own, it shows the DC as written. Hover over it, or tap it on a phone, to see both.

A rung of a check can be written the same way, `**${party.dc(15)}**`, and GM Kit 3.7 or later reads it as the 15 rung and shows the party's DC when it asks how high they rolled. `party.dcRise()` is how far this party's DCs rise, and `party.dcRise(9)` how far they rise at level 9.

## The rules it uses

The 2024 encounter rules: choose a difficulty, look up the XP budget per character for each character's level, add them up, and spend that on creatures at their XP. There are no multipliers. Where the characters' levels differ, each is looked up at its own level, which is the rule as written when they are all the same. For a party of another size, as in the table of sizes, each character spends what yours spend on average: three characters from a party at levels 3, 3, 2 and 2 have three quarters of its budget.

`party.budget(levels, "moderate")` and `party.rate(xp, levels)` do the sums, and `party.xp("1/4")` looks up a CR. `party.budgets()` and `party.xpTable()` print the two tables, for a rules page.

## How it prints

On the page each of these is a widget: HTML with its note, as a tooltip and as the box a tap shows, and the same text, without the note, as its Markdown face. SilverBullet draws a table from the Markdown faces of the expressions in it, and its Copy button and Baked Sections use them too, so all of those get your party's numbers. GM Kit 2.2 puts the Markdown face into the copies it publishes, so players see their own party's numbers. A hint from `party.each` has an empty Markdown face, so it never reaches them. A fight's Markdown face is the fight as printed.

GM Book 1.5 evaluates each expression with `party` standing for `party.printed`, which gives the rule, the adventure's number, nothing for a hint, the fight for the adventure's party, every version of a fight in versions, and a DC as written. The party it knows is the one the adventure is written for, whoever is playing tonight: `party.get()` is that party, `party.level()` gives nil, as in an adventure space on its own, so GM Book names a page that prints it, `party.dcRise()` gives 0, and `party.summary()` a line saying who the adventure is written for. This library puts `party.printed` in `gmbook.printers`, where GM Book looks for it.

Baked Sections alone couldn't do this: they bake whole blocks, never a number in the middle of a sentence.

## A tab behind its space

A tab reads its libraries when it opens. If the space's GM Party changes after that, from another tab, a sync or `Library: Install`, the tab goes on running the one it read. `party.stale()` says so: nothing while the two agree, and otherwise

    This tab runs GM Party 1.5.0, but the space has 1.6.0: reload it (System: Reload, Ctrl-Alt-R).

It reads the `version` of every page named `Library/Storie/GM Party`, at any depth, from the index, so a copy in a space the DM space holds counts too, and it never fails. GM Book asks before it builds. A fight on the page shows a line over its box, *⟳ Reload this tab*, with the two versions; it is HTML, so it never prints and never reaches the players' copies.

## Settings

    config.set("gmParty", { book = 5, smallest = 3, largest = 7 })

`book` is the size of the party the adventure is written for. `smallest` and `largest` bound the tables in print, and a fight whose `size` is outside them gets a row for that size as well.

## Rules text

The XP Budget per Character and Experience Points by Challenge Rating tables below come from the SRD 5.2.1. A book that prints them carries the same statement:

This work includes material from the System Reference Document 5.2.1 ("SRD 5.2.1") by Wizards of the Coast LLC, available at https://www.dndbeyond.com/srd. The SRD 5.2.1 is licensed under the Creative Commons Attribution 4.0 International License, available at https://creativecommons.org/licenses/by/4.0/legalcode.

## Changes in 1.5

**`retired: true` takes a character out of the party altogether**: out of the count, the level, the fights and the hand-outs, and named as retired in the summary, so a page marked by mistake is seen. `away: true` still only sits a character out of tonight.

**A number's note on a tap.** The note a number carries shows on a tap as well as a hover, since a phone has no hover.

**A tab behind its space says so.** `party.version` and `party.stale()` say when the tab runs another GM Party than the space holds, and a fight says so over its box, on the page alone, never in print. See *A tab behind its space*.

## Changes in 1.4

**A mixed-level party's fight agrees with itself.** The row for your party's size in a fight's table is rated at each character's own level, as the difficulty above it is, and the other sizes spend the party's average budget for each character. A creature is flagged as above the party's level against `party.level()`, not the highest level in the party.

**Print gives the adventure's party throughout.** In print `party.dcRise()` is 0, `party.summary()` describes the party the adventure is written for, and `party.level()` prints nothing, which keeps a book edition back rather than printing one table's level. A fight written for a size outside three to seven gets a row for that size.

**A fight's table fits a phone**: it scrolls inside its frame rather than running off it.

## Changes in 1.3

**The party's level.** A fight can come in versions, each with its own creatures for one level: the page runs the version nearest the party's level and shows how the others would go, and print gives every version with the rule for choosing one. `party.dc` gives a DC that rises with the party's level, as the proficiency bonus does. `party.level()` is the party's level, and The Party's summary says how far its DCs rise.

## Changes in 1.2.2

New examples in these docs, of arrows and a barrow.

## Changes in 1.2.1

`party.printed.value` gives the adventure's number where `party.value` gives this table's, so a library that draws to a number — [GM Maps](<GM Maps>) sizes a battle map by one — prints the adventure's and shows yours.

## Changes in 1.2

A creature in a fight can name the page that describes it. The fight lists those creatures, as links on the page and with whatever `party.creatureRef` gives them in print.

## Changes in 1.1

A count can name the item whose uses it is, and `party.value` gives the number behind a count or a story number.

## Implementation

```space-lua
-- priority: 10
party = party or {}
party.version = "1.5.0"

party.config = {
  book     = 5,  -- the size of the party the adventure is written for
  smallest = 3,  -- a fight's table in print runs from this many characters
  largest  = 7,  -- to this many
}

-- A setting, which config.set("gmParty", { ... }) overrides.
function party.setting(key)
  local value = config.get("gmParty." .. key, nil)
  if value == nil then value = party.config[key] end
  return value
end

-- From the SRD 5.2.1: XP Budget per Character, Low, Moderate and High for
-- each level (p. 202), and Experience Points by Challenge Rating (p. 256).
-- CR 0 is worth 0 or 10 XP; 10 here, and xp = 0 for the harmless kind.
party.srd = {
  budget = {
    { 50, 75, 100 }, { 100, 150, 200 }, { 150, 225, 400 }, { 250, 375, 500 },
    { 500, 750, 1100 }, { 600, 1000, 1400 }, { 750, 1300, 1700 },
    { 1000, 1700, 2100 }, { 1300, 2000, 2600 }, { 1600, 2300, 3100 },
    { 1900, 2900, 4100 }, { 2200, 3700, 4700 }, { 2600, 4200, 5400 },
    { 2900, 4900, 6200 }, { 3300, 5400, 7800 }, { 3800, 6100, 9800 },
    { 4500, 7200, 11700 }, { 5000, 8700, 14200 }, { 5500, 10700, 17200 },
    { 6400, 13200, 22000 },
  },
  crs = {
    "0", "1/8", "1/4", "1/2", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10",
    "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23",
    "24", "25", "26", "27", "28", "29", "30",
  },
  xp = {
    10, 25, 50, 100, 200, 450, 700, 1100, 1800, 2300, 2900, 3900, 5000, 5900,
    7200, 8400, 10000, 11500, 13000, 15000, 18000, 20000, 22000, 25000, 33000,
    41000, 50000, 62000, 75000, 90000, 105000, 120000, 135000, 155000,
  },
}

party.difficulties = { "low", "moderate", "high" }
local COLUMN = { low = 1, moderate = 2, high = 3 }
local LABEL = { low = "Low", moderate = "Moderate", high = "High", above = "Above High" }
local PIPS = { low = "●○○", moderate = "●●○", high = "●●●", above = "●●●+" }

------------------------------------------------------------------ words

local WORDS = {
  "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
  "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen",
  "eighteen", "nineteen", "twenty",
}

-- 1100 as "1,100".
function party.digits(n)
  local out = string.format("%d", math.floor(n))
  while true do
    local grouped, found = out:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
    out = grouped
    if found == 0 then return out end
  end
end

-- 5 as "five": words to twenty, digits after, and "no" for none.
function party.word(n)
  n = math.floor(n)
  if n == 0 then return "no" end
  return WORDS[n] or party.digits(n)
end

local function capital(s)
  return (s:gsub("^%l", string.upper))
end

-- The plural of a noun, where adding an s, es or ies will do.
function party.plural(noun)
  if noun:match("[sxz]$") or noun:match("[cs]h$") then return noun .. "es" end
  if noun:match("[^aeiou]y$") then return noun:sub(1, -2) .. "ies" end
  return noun .. "s"
end

-- "six arrows", "one arrow", "no arrows"; with article, "a wight".
local function counted(n, one, many, article)
  if n == 1 then
    if article then return (one:match("^[aeiouAEIOU]") and "an " or "a ") .. one end
    return "one " .. one
  end
  return party.word(n) .. " " .. many
end

-- "a, b and c"
local function andList(items)
  local out = ""
  for i, item in ipairs(items) do
    if i == 1 then out = item
    elseif i == #items then out = out .. " and " .. item
    else out = out .. ", " .. item end
  end
  return out
end

local function num(v)
  if v == nil then return nil end
  return tonumber(v)
end

------------------------------------------------------------------ this tab

-- A version as a page writes it: "1.4.0", or the number YAML reads 2 as.
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

-- The versions of GM Party the space holds other than the one this tab
-- runs, older or newer: the frontmatter of every page named
-- Library/Storie/GM Party, at any depth, as the index has it, lowest first.
-- Read at most every two seconds, as the party is, since every fight on a
-- page asks.
local staleCache
local function othersInSpace()
  local now = os.time()
  if staleCache and now - staleCache.at < 2 then return staleCache.value end
  local own = "Library/Storie/GM Party"
  local tail = "/" .. own
  local pages = query[[
    from p = index.pages()
    where p.name == own or p.name:endsWith(tail)
    order by p.name
  ]]
  local out, seen = {}, {}
  for _, p in ipairs(pages) do
    local v = versionText(p.version)
    if v and v ~= party.version and not seen[v] then
      seen[v] = true
      out[#out + 1] = v
    end
  end
  table.sort(out, versionLess)
  staleCache = { at = now, value = out }
  return out
end

-- Nil while this tab runs the GM Party the space holds; else what to do. A
-- tab reads its Lua when it opens, so a library updated since, from another
-- tab or by a sync, is on disk and in the index but not running here. GM
-- Book asks before it builds. It never fails: a look that can't be made
-- says nothing.
function party.stale()
  local ok, others = pcall(othersInSpace)
  if not ok or type(others) ~= "table" or #others == 0 then return nil end
  return "This tab runs GM Party " .. party.version .. ", but the space has " ..
    andList(others) .. ": reload it (System: Reload, Ctrl-Alt-R)."
end

-- The same, as a line over a widget on the page: HTML, so never in print
-- nor in the Markdown face. "" when this tab is current.
local function staleNote()
  local ok, others = pcall(othersInSpace)
  if not ok or type(others) ~= "table" or #others == 0 then return "" end
  return dom.div { class = "gmparty-stale", __rawText = "⟳ Reload this tab: it runs GM Party " ..
    party.version .. ", and the space has " .. andList(others) .. " (System: Reload, Ctrl-Alt-R)." }.outerHTML
end

------------------------------------------------------------------ the party

-- The party, from the most specific source there is: the character pages
-- (type: pc), then a page describing the party (type: party, with characters
-- and level), then the party the adventure is written for. Read again at most
-- every two seconds, since every number on a page asks for it. A page's own
-- size, in bytes, would shadow a frontmatter "size", hence "characters".
-- A retired character (retired: true) is in none of it, as if its page were
-- no character's; `retired` lists them, for the summary to name.
function party.get()
  local now = os.time()
  if party.cached and now - party.cached.at < 2 then return party.cached.value end
  local pages = query[[
    from p = index.pages()
    where p.type == "pc" or p.type == "party"
    order by p.name
  ]]
  local pcs, home, retired = {}, nil, {}
  for _, p in ipairs(pages) do
    if p.type == "pc" then
      if p.retired == true then
        retired[#retired + 1] = { name = p.name:match("([^/]+)$") or p.name, page = p.name }
      else
        pcs[#pcs + 1] = p
      end
    elseif not home then
      home = p
    end
  end
  local level = home and num(home.level) or nil
  local members, source = {}, "book"
  if #pcs > 0 then
    source = "characters"
    for _, p in ipairs(pcs) do
      members[#members + 1] = {
        name = p.name:match("([^/]+)$") or p.name,
        page = p.name,
        level = num(p.level) or level,
        away = p.away == true,
      }
    end
  else
    local size = party.setting("book")
    if home and num(home.characters) then
      source = "party"
      size = math.floor(num(home.characters))
    end
    for i = 1, size do members[i] = { level = level } end
  end
  local here = {}
  for _, m in ipairs(members) do
    if not m.away then here[#here + 1] = m end
  end
  local value = {
    size = #members, members = members, here = here, source = source,
    page = home and home.name or nil, retired = retired,
  }
  party.cached = { at = now, value = value }
  return value
end

-- Forget the party read last, and whether this tab is behind its space, so
-- the next number reads the pages again.
function party.refresh()
  party.cached = nil
  staleCache = nil
end

-- The average of some levels, rounded to the nearest: the party's level,
-- for characters at these levels. Nil for none.
local function averageLevel(levels)
  local sum = 0
  for _, l in ipairs(levels) do sum = sum + l end
  if #levels == 0 then return nil end
  return math.floor(sum / #levels + 0.5)
end

-- The party's level: the average level of the characters here tonight, or
-- of everyone when nobody is, rounded to the nearest. Nil when nobody has
-- a level, as in an adventure space on its own.
function party.level(p)
  p = p or party.get()
  local function levelsOf(members)
    local out = {}
    for _, m in ipairs(members) do
      if m.level then out[#out + 1] = m.level end
    end
    return out
  end
  return averageLevel(levelsOf(p.here)) or averageLevel(levelsOf(p.members))
end

local function whence(p)
  if p.source == "characters" then return "counted from the character pages" end
  if p.source == "party" then return "from " .. p.page end
  return "the party the adventure is written for"
end

-- Where the party's level comes from, for a note.
local function levelWhence(p)
  if p.source == "characters" then return "from the character pages" end
  if p.source == "party" then return "from " .. p.page end
  return "as written"
end

-- A value on the page: the HTML with its note, and the same text as the
-- Markdown face, which is what a table, Copy, Baked Sections and GM Kit's
-- publishing use. A hint passes "" as its Markdown, so it stays on the page.
-- The HTML goes as text, not an element: SilverBullet shares one result
-- between identical expressions on a page, and an element can only be in
-- one place, so the second copy would take it from the first.
--
-- The note is the value's tooltip, for a mouse, and a box of its own that
-- shows while the value has focus, since a phone shows no tooltip: the value
-- takes focus from a tap or the keyboard, and the style shows the box. A
-- screen reader has the tooltip, so the box is hidden from it.
local function face(live, note, class, markdown)
  return widget.new {
    html = dom.span {
      class = class or "gmparty-n", title = note, tabindex = "0",
      dom.span { __rawText = live },
      dom.span { class = "gmparty-notebox", ["aria-hidden"] = "true", __rawText = note },
    }.outerHTML,
    markdown = markdown or live,
    display = "inline",
  }
end

------------------------------------------------------------------ numbers

-- A number in the story that follows the party: its size, plus more, or
-- times as many. Returns this party's, the adventure's for print, and a note.
local function numberForms(spec, cap)
  if type(spec) == "number" then spec = { plus = spec } end
  spec = spec or {}
  local plus, times = spec.plus or 0, spec.times or 1
  local p, book = party.get(), party.setting("book")
  local live = party.word(times * p.size + plus)
  local printed = party.word(times * book + plus)
  if cap or spec.cap then live, printed = capital(live), capital(printed) end
  local rule
  if times ~= 1 then
    rule = (times == 2 and "Twice" or capital(party.word(times)) .. " times") .. " the party's size"
    if plus > 0 then rule = rule .. ", plus " .. party.word(plus)
    elseif plus < 0 then rule = rule .. ", less " .. party.word(-plus) end
  elseif plus > 0 then
    rule = capital(party.word(plus)) .. " more than the party has members"
  elseif plus < 0 then
    rule = capital(party.word(-plus)) .. " fewer than the party has members"
  else
    rule = "The party's size"
  end
  return live, printed, rule .. ": " .. live:lower() .. " for this party of " ..
    party.word(p.size) .. ", " .. whence(p) .. ". Prints as “" .. printed .. "”."
end

function party.number(spec, cap)
  local live, _, note = numberForms(spec, cap)
  return face(live, note)
end

function party.n(spec) return party.number(spec, false) end
function party.N(spec) return party.number(spec, true) end

local function countFor(spec, size)
  local per, plus = spec.per or 1, spec.plus or 0
  local v
  if per >= 1 then
    v = math.floor(per) * size
  else
    local every = math.floor(1 / per + 0.5)
    if spec.round == "down" then v = math.floor(size / every)
    else v = math.floor((size + every - 1) / every) end
  end
  v = v + plus
  if spec.min and v < spec.min then v = spec.min end
  if spec.max and v > spec.max then v = spec.max end
  if v < 0 then v = 0 end
  return v
end

-- The rule behind a count, as a phrase: "one more arrow than the party has
-- members".
function party.rule(spec)
  local one = spec[1]
  local many = spec[2] or party.plural(one)
  local per, plus = spec.per or 1, spec.plus or 0
  local members = "the party has members"
  local s
  if per == 1 then
    if plus == 0 then
      s = "as many " .. many .. " as " .. members
    elseif plus > 0 then
      s = party.word(plus) .. " more " .. (plus == 1 and one or many) .. " than " .. members
    else
      s = party.word(-plus) .. " fewer " .. (plus == -1 and one or many) .. " than " .. members
    end
  else
    if per > 1 then
      s = party.word(per) .. " " .. many .. " for each member of the party"
    else
      s = "one " .. one .. " for every " .. party.word(math.floor(1 / per + 0.5)) ..
          " members of the party, rounding " .. (spec.round == "down" and "down" or "up")
    end
    if plus > 0 then s = s .. ", and " .. party.word(plus) .. " more"
    elseif plus < 0 then s = s .. ", less " .. party.word(-plus) end
  end
  if spec.min then s = s .. ", but no fewer than " .. party.word(spec.min) end
  if spec.max then s = s .. ", but no more than " .. party.word(spec.max) end
  return s
end

-- A count that follows a rule. Returns this party's count, "seven arrows",
-- the rule for print, "one more arrow than the party has members, six for a
-- party of five", and a note.
local function countForms(spec)
  if type(spec) ~= "table" or type(spec[1]) ~= "string" then
    error('party.count takes the thing counted and its rule: {"arrow", plus = 1}')
  end
  local one = spec[1]
  local many = spec[2] or party.plural(one)
  local p, book = party.get(), party.setting("book")
  local live = counted(countFor(spec, p.size), one, many)
  local rule = party.rule(spec)
  local printed = rule
  if spec.example ~= false then
    local n = countFor(spec, book)
    printed = printed .. ", " .. (n == 0 and "none" or party.word(n)) ..
      " for a party of " .. party.word(book)
  end
  if spec.cap then live, printed = capital(live), capital(printed) end
  return live, printed, capital(rule) .. ": " .. live:lower() .. " for this party of " ..
    party.word(p.size) .. ", " .. whence(p) .. ". Prints as “" .. printed .. "”."
end

function party.count(spec)
  local live, _, note = countForms(spec)
  return face(live, note)
end

-- The number behind a count or a story number, for this party or for size
-- characters: party.value{"arrow", plus = 1} is 6 for a party of five.
function party.value(spec, size)
  size = size or party.get().size
  if type(spec) == "table" and type(spec[1]) == "string" then return countFor(spec, size) end
  if type(spec) == "number" then spec = { plus = spec } end
  spec = spec or {}
  return (spec.times or 1) * size + (spec.plus or 0)
end

local function eachArgs(count, one, many)
  if type(count) == "table" then count, one, many = count[1], count[2], count[3] end
  if type(count) ~= "number" or type(one) ~= "string" then
    error('party.each takes how many there are and what they are: party.each(5, "find")')
  end
  return count, one, many or party.plural(one)
end

-- One each: which of count things, handed out from the top of a list, to
-- use for the characters here tonight. It shows on the page only, so the
-- text itself should say how a smaller or larger party shares them.
function party.each(count, one, many)
  count, one, many = eachArgs(count, one, many)
  local p = party.get()
  local n = #p.here
  local text
  if n == 0 then
    text = "Nobody here tonight."
  elseif n < count then
    text = capital(party.word(n)) .. " here: use the first " ..
      (n == 1 and one or (party.word(n) .. " " .. many)) .. "."
  elseif n == count then
    text = capital(party.word(n)) .. " here: one " .. one .. " each."
  else
    local shared = n - count
    text = capital(party.word(n)) .. " here: all " .. counted(count, one, many) ..
      ", with " .. counted(math.min(shared, count), one, many) .. " shared by two" ..
      (shared > count and " or more" or "") .. "."
  end
  return face(text, "One " .. one .. " for each character here tonight, from the top of the list. " ..
    "Party of " .. party.word(p.size) .. ", " .. whence(p) .. ". Prints nothing.", "gmparty-each", "")
end

------------------------------------------------------------------ DCs

-- How far a DC written for levels 1 to 4 rises at a level: one for each
-- step the proficiency bonus takes, at levels 5, 9, 13 and 17. With no
-- level given, the party's; with no party level, none.
function party.dcRise(level)
  if level == nil then level = party.level() end
  if type(level) ~= "number" then return 0 end
  level = math.max(1, math.min(20, math.floor(level)))
  return math.floor((level - 1) / 4)
end

-- A DC that follows the party's level. Returns this party's DC, the DC as
-- written, which is what prints, and a note.
local function dcForms(spec)
  local written = spec
  if type(spec) == "table" then written = spec[1] end
  if type(written) ~= "number" or written ~= math.floor(written) then
    error("party.dc takes the DC as written for levels 1 to 4: party.dc(15)")
  end
  local p = party.get()
  local level = party.level(p)
  local printed = string.format("%d", written)
  local live = string.format("%d", written + party.dcRise(level))
  local note = "DC " .. printed .. " as written, for levels 1 to 4, one more at levels 5, 9, 13 and 17"
  if level then
    note = note .. ": " .. live .. " for this party at level " .. string.format("%d", level) ..
      ", " .. levelWhence(p)
  end
  return live, printed, note .. ". Prints as “" .. printed .. "”."
end

function party.dc(spec)
  local live, _, note = dcForms(spec)
  return face(live, note)
end

------------------------------------------------------------------ the rules

-- XP for a Challenge Rating: 3, 0.25 and "1/4" all work.
function party.xp(cr)
  if cr == nil then return nil end
  local key = cr
  if type(cr) == "number" then
    if cr == 0.125 then key = "1/8"
    elseif cr == 0.25 then key = "1/4"
    elseif cr == 0.5 then key = "1/2"
    elseif cr == math.floor(cr) then key = string.format("%d", cr)
    else return nil end
  end
  key = tostring(key):gsub("%s", "")
  for i, k in ipairs(party.srd.crs) do
    if k == key then return party.srd.xp[i] end
  end
  return nil
end

local function crValue(cr)
  if type(cr) == "number" then return cr end
  if type(cr) ~= "string" then return nil end
  local a, b = cr:match("^%s*(%d+)%s*/%s*(%d+)%s*$")
  if a then return tonumber(a) / tonumber(b) end
  return tonumber(cr)
end

-- The XP budget for characters at these levels, at a difficulty.
function party.budget(levels, difficulty)
  local column = COLUMN[difficulty]
  if not column then error("party.budget: the difficulty is low, moderate or high") end
  local total = 0
  for _, level in ipairs(levels) do
    local row = party.srd.budget[math.max(1, math.min(20, math.floor(level)))]
    total = total + row[column]
  end
  return total
end

-- How hard creatures worth xp are for characters at these levels: "low",
-- "moderate", "high", or "above" when they overspend even High.
function party.rate(xp, levels)
  for _, difficulty in ipairs(party.difficulties) do
    if xp <= party.budget(levels, difficulty) then return difficulty end
  end
  return "above"
end

local function levelsFor(n, level)
  local out = {}
  for i = 1, n do out[i] = level end
  return out
end

-- How hard creatures worth xp are for a party of size characters, spending
-- what the characters at these levels spend each, on average: for as many
-- characters as there are levels, exactly what party.rate gives for them.
-- In whole numbers, xp against size times the budget over the count, so no
-- fraction of a budget is ever made.
local function rateFor(xp, levels, size)
  for _, difficulty in ipairs(party.difficulties) do
    if xp * #levels <= party.budget(levels, difficulty) * size then return difficulty end
  end
  return "above"
end

local function levelText(levels)
  local lo, hi
  for _, l in ipairs(levels) do
    if not lo or l < lo then lo = l end
    if not hi or l > hi then hi = l end
  end
  if not lo then return "" end
  if lo == hi then return "level " .. string.format("%d", lo) end
  return "levels " .. string.format("%d", lo) .. "–" .. string.format("%d", hi)
end

-- The SRD's XP Budget per Character table, for a rules page.
function party.budgets()
  local lines = { "| Level | Low | Moderate | High |", "|---|---|---|---|" }
  for level, row in ipairs(party.srd.budget) do
    lines[#lines + 1] = "| " .. string.format("%d", level) .. " | " .. party.digits(row[1]) ..
      " | " .. party.digits(row[2]) .. " | " .. party.digits(row[3]) .. " |"
  end
  return widget.new { markdown = table.concat(lines, "\n"), display = "block" }
end

-- The SRD's Experience Points by Challenge Rating table, in two pairs of
-- columns, for a rules page.
function party.xpTable()
  local crs, xp = party.srd.crs, party.srd.xp
  local half = math.floor((#crs + 1) / 2)
  local lines = { "| CR | XP | CR | XP |", "|---|---|---|---|" }
  for i = 1, half do
    local j = i + half
    lines[#lines + 1] = "| " .. crs[i] .. " | " .. (i == 1 and "0 or 10" or party.digits(xp[i])) ..
      " | " .. (crs[j] or "") .. " | " .. (xp[j] and party.digits(xp[j]) or "") .. " |"
  end
  return widget.new { markdown = table.concat(lines, "\n"), display = "block" }
end

------------------------------------------------------------------ fights

-- A fight's creatures, checked: count, names, XP each, and how they scale.
function party.creatures(spec)
  local out = {}
  for _, c in ipairs(spec) do
    if type(c) == "table" then
      local one = c[2]
      if type(c[1]) ~= "number" or type(one) ~= "string" then
        error('party.fight: each creature is {count, name, cr = ...}, like {6, "skeleton", cr = "1/4"}')
      end
      local xp = c.xp
      if xp == nil then
        xp = party.xp(c.cr)
        if not xp then error("party.fight: no XP for " .. one .. ": give it a cr or an xp") end
      end
      out[#out + 1] = {
        count = c[1], one = one, many = c.plural or party.plural(one), xp = xp, cr = c.cr,
        step = c.step or 0, min = c.min, max = c.max, from = c.from, upto = c.upto,
        page = c.page,
      }
    end
  end
  return out
end

local function titleOf(spec)
  if spec.title then return spec.title end
  for _, v in ipairs(spec) do
    if type(v) == "string" then return v end
  end
end

local function writtenFor(spec)
  return spec.size or party.setting("book")
end

-- The party size a creature's count is written for: the adventure's, or,
-- for one that isn't there at that size, the size it joins or leaves at.
local function baseSize(c, written)
  if c.from and c.from > written then return c.from end
  if c.upto and c.upto < written then return c.upto end
  return written
end

-- The fight for n characters: each creature, and how many of it.
function party.roster(spec, n)
  local written = writtenFor(spec)
  local out = {}
  for _, c in ipairs(party.creatures(spec)) do
    local k = 0
    if not (c.from and n < c.from) and not (c.upto and n > c.upto) then
      k = c.count + c.step * (n - baseSize(c, written))
      if c.min and k < c.min then k = c.min end
      if c.max and k > c.max then k = c.max end
      if k < 0 then k = 0 end
    end
    out[#out + 1] = { creature = c, count = k }
  end
  return out
end

local function totalXP(roster)
  local xp = 0
  for _, r in ipairs(roster) do xp = xp + r.count * r.creature.xp end
  return xp
end

local function rosterText(roster, article)
  local items = {}
  for _, r in ipairs(roster) do
    if r.count > 0 then
      items[#items + 1] = counted(r.count, r.creature.one, r.creature.many, article)
    end
  end
  if #items == 0 then return "no creatures" end
  return andList(items)
end

-- The party sizes a table covers: smallest to largest, and one more row for
-- a party outside that range.
local function tableSizes(extra)
  local sizes = {}
  if extra and extra < party.setting("smallest") then sizes[1] = extra end
  for n = party.setting("smallest"), party.setting("largest") do sizes[#sizes + 1] = n end
  if extra and extra > party.setting("largest") then sizes[#sizes + 1] = extra end
  return sizes
end

-- Party sizes for characters at these levels: the column heads for the
-- creatures whose number changes, and a row per size with those numbers,
-- the XP and the difficulty. A size that is theirs is rated at their own
-- levels, as the fight is; any other spends what they spend each, on
-- average, so a table for characters at one level is rated at that level.
local function sizeRows(spec, levels, sizes)
  local rosters = {}
  for _, n in ipairs(sizes) do rosters[n] = party.roster(spec, n) end
  local columns, heads = {}, {}
  for i, r in ipairs(rosters[sizes[1]]) do
    for _, n in ipairs(sizes) do
      if rosters[n][i].count ~= r.count then
        columns[#columns + 1] = i
        heads[#heads + 1] = capital(r.creature.many)
        break
      end
    end
  end
  local rows = {}
  for _, n in ipairs(sizes) do
    local counts = {}
    for _, i in ipairs(columns) do counts[#counts + 1] = rosters[n][i].count end
    local xp = totalXP(rosters[n])
    rows[#rows + 1] = { size = n, counts = counts, xp = xp, rated = rateFor(xp, levels, n) }
  end
  return heads, rows
end

-- The rules for other party sizes, as sentences.
function party.adjustments(spec)
  local written = writtenFor(spec)
  local creatures = party.creatures(spec)
  local out = {}
  for _, sign in ipairs({ 1, -1 }) do
    local items, steps = {}, {}
    for _, c in ipairs(creatures) do
      if c.step * sign > 0 then
        items[#items + 1] = counted(math.abs(c.step), c.one, c.many, true)
        steps[#steps + 1] = math.abs(c.step)
      end
    end
    if #items > 0 then
      local fewer, more = sign > 0 and "remove" or "add", sign > 0 and "add" or "remove"
      local again = andList(items)
      if #items == 1 then again = steps[1] == 1 and "one" or party.word(steps[1]) end
      out[#out + 1] = "For each character fewer than " .. party.word(written) .. ", " ..
        fewer .. " " .. andList(items) .. "; for each one more, " .. more .. " " .. again .. "."
    end
  end
  for _, c in ipairs(creatures) do
    if c.step ~= 0 and c.min and c.min > 0 then
      out[#out + 1] = "Keep at least " .. counted(c.min, c.one, c.many) .. "."
    end
    if c.step ~= 0 and c.max then out[#out + 1] = "Use no more than " .. counted(c.max, c.one, c.many) .. "." end
  end
  for _, c in ipairs(creatures) do
    local named = c.count == 1 and c.one or c.many
    if c.from then
      if c.from > written then
        out[#out + 1] = "With " .. party.word(c.from) .. " or more characters, add " ..
          counted(c.count, c.one, c.many, true) .. "."
      else
        out[#out + 1] = "With fewer than " .. party.word(c.from) .. " characters, leave out the " .. named .. "."
      end
    end
    if c.upto then
      if c.upto >= written then
        out[#out + 1] = "With more than " .. party.word(c.upto) .. " characters, leave out the " .. named .. "."
      else
        out[#out + 1] = "With " .. party.word(c.upto) .. " or fewer characters, add " ..
          counted(c.count, c.one, c.many, true) .. "."
      end
    end
  end
  if spec.note then out[#out + 1] = spec.note end
  if #out == 0 then return "The fight stays the same whatever the party's size." end
  return table.concat(out, " ")
end

------------------------------------------------------------------ creatures with a page

local function text(s, class)
  return dom.span { class = class, __rawText = s }
end

-- The creatures of a fight that name a page, each with the page found for it,
-- its citation and anything to flag.
--
-- party.creatureRef is where a library that reads those pages says what they
-- hold. It takes the page a creature names, as a link in the adventure would
-- write it, the creature's name and its CR, and gives back
-- { page = ..., cite = ..., warn = ... }. Without one, a creature's page is
-- linked if a page of that name is there, and nothing is printed for it. It
-- is never set to nil here: a library that sets it may have loaded first, and
-- every block shares the one table.
local function referenced(spec)
  local out = {}
  for _, c in ipairs(party.creatures(spec)) do
    if c.page then
      local ref
      if party.creatureRef then ref = party.creatureRef(c.page, c.one, c.cr) or {}
      else ref = { page = space.pageExists(c.page) and c.page or nil } end
      out[#out + 1] = { creature = c, page = ref.page, cite = ref.cite, warn = ref.warn }
    end
  end
  return out
end

-- A page's address, the way SilverBullet writes it: the space's base URI and
-- the page name encoded as the browser encodes it, with the slashes put back.
-- A Lua encoder would get non-ASCII names wrong, since Space Lua strings are
-- JavaScript strings, not bytes.
local function pageURL(page)
  local base = system.getBaseURI()
  if not base:endsWith("/") then base = base .. "/" end
  return base .. (js.window.encodeURIComponent(page):gsub("%%2F", "/"))
end

local function creaturesTitle(spec)
  return spec.creatures or "The creatures"
end

-- The line of citations, for print. Nothing without a library to write them.
local function creaturesPrint(spec)
  local parts = {}
  for _, r in ipairs(referenced(spec)) do
    if r.cite then parts[#parts + 1] = capital(r.creature.one) .. " — " .. r.cite .. "." end
  end
  if #parts == 0 then return nil end
  return "**" .. creaturesTitle(spec) .. ".** " .. table.concat(parts, " ")
end

-- The same line on the page: each creature a link to its own page.
local function creaturesLive(spec)
  local refs = referenced(spec)
  if #refs == 0 then return nil end
  local parts = { class = "gmparty-creatures" }
  parts[#parts + 1] = text(creaturesTitle(spec) .. ": ", "gmparty-note")
  for i, r in ipairs(refs) do
    if i > 1 then parts[#parts + 1] = text(" · ", "gmparty-note") end
    local label = capital(r.creature.one)
    if r.page then
      parts[#parts + 1] = dom.a { href = pageURL(r.page), __rawText = label }
    else
      parts[#parts + 1] = text(label .. " (no page)", "gmparty-nopage")
    end
  end
  return dom.div(parts)
end

------------------------------------------------------------------ versions by level

-- Whether an entry in a fight's list is a version, { level = 6, ... }, and
-- not a creature, {count, name, ...}.
local function isVersion(v)
  return type(v) == "table" and v.level ~= nil and type(v[1]) ~= "number"
end

-- A fight's versions, lowest level first, each a fight of its own at one
-- level: the fight's name and settings, with the version's level and
-- creatures, and its own difficulty and note where it gives them. A fight
-- written without versions is its own only version, and the second value
-- says whether it has versions.
function party.versions(spec)
  local out = {}
  for _, v in ipairs(spec) do
    if isVersion(v) then
      local one = {
        title = titleOf(spec), level = v.level,
        difficulty = v.difficulty or spec.difficulty, note = v.note or spec.note,
        table = spec.table, size = spec.size, creatures = spec.creatures,
      }
      for _, c in ipairs(v) do one[#one + 1] = c end
      out[#out + 1] = one
    end
  end
  if #out == 0 then return { spec }, false end
  table.sort(out, function(a, b) return a.level < b.level end)
  return out, true
end

-- The version written for the level nearest this one: the lower of two as
-- near, since the versions come lowest first.
local function nearest(versions, level)
  local best
  for _, v in ipairs(versions) do
    if not best or math.abs(v.level - level) < math.abs(best.level - level) then best = v end
  end
  return best
end

-- "level 3 and level 6"
local function levelList(versions)
  local items = {}
  for i, v in ipairs(versions) do items[i] = "level " .. string.format("%d", v.level) end
  return andList(items)
end

-- The creatures of every version that name a page, each page once, for the
-- one line of creatures a fight in versions prints.
local function everyCreature(spec, versions)
  local all, seen = { creatures = spec.creatures }, {}
  for _, v in ipairs(versions) do
    for _, c in ipairs(v) do
      if type(c) == "table" and c.page and not seen[c.page] then
        seen[c.page] = true
        all[#all + 1] = c
      end
    end
  end
  return all
end

-- One fight at one level as printed, for the adventure's party, as lines:
-- `head` is the name it opens with, and `withCreatures` whether the line of
-- creatures with pages of their own comes next.
local function printOne(spec, head, withCreatures)
  local written, level = writtenFor(spec), spec.level
  local roster = party.roster(spec, written)
  local xp = totalXP(roster)
  local rated = party.rate(xp, levelsFor(written, level))
  local what = rated == "above" and "an encounter beyond high difficulty" or
    ("a " .. rated .. "-difficulty encounter")
  local lines = {
    "**" .. head .. ".** " .. capital(rosterText(roster, true)) ..
      ": " .. what .. " for " .. party.word(written) .. " level " .. string.format("%d", level) ..
      " characters (" .. party.digits(xp) .. " XP).",
  }
  if withCreatures then
    local creatures = creaturesPrint(spec)
    if creatures then
      lines[#lines + 1] = ""
      lines[#lines + 1] = creatures
    end
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "**Adjusting the Encounter.** " .. party.adjustments(spec)
  if spec.table ~= false then
    local heads, rows = sizeRows(spec, levelsFor(written, level), tableSizes(written))
    local head, rule = { "Characters" }, {}
    for _, h in ipairs(heads) do head[#head + 1] = h end
    head[#head + 1] = "XP"
    head[#head + 1] = "Difficulty"
    for i = 1, #head do rule[i] = "---" end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "| " .. table.concat(head, " | ") .. " |"
    lines[#lines + 1] = "|" .. table.concat(rule, "|") .. "|"
    for _, r in ipairs(rows) do
      local cells = { party.digits(r.size) }
      for _, c in ipairs(r.counts) do cells[#cells + 1] = party.digits(c) end
      cells[#cells + 1] = party.digits(r.xp)
      cells[#cells + 1] = LABEL[r.rated]
      lines[#lines + 1] = "| " .. table.concat(cells, " | ") .. " |"
    end
  end
  return lines
end

-- The fight as printed: for the adventure's party, then how to adjust it.
-- A fight in versions gives the rule for choosing one, the creatures with
-- pages of their own, then each version in turn.
function party.fightPrint(spec)
  local versions, many = party.versions(spec)
  local title = titleOf(spec) or "Creatures"
  if not many or #versions == 1 then
    return table.concat(printOne(versions[1], title, true), "\n")
  end
  local lines = {
    "**" .. title .. ".** " .. capital(party.word(#versions)) .. " versions, for " ..
      levelList(versions) .. " characters: run the one nearest your party's level.",
  }
  local creatures = creaturesPrint(everyCreature(spec, versions))
  if creatures then
    lines[#lines + 1] = ""
    lines[#lines + 1] = creatures
  end
  for _, v in ipairs(versions) do
    lines[#lines + 1] = ""
    for _, line in ipairs(printOne(v, "Level " .. string.format("%d", v.level), false)) do
      lines[#lines + 1] = line
    end
  end
  return table.concat(lines, "\n")
end

-- What to watch for, after the SRD's troubleshooting advice, for
-- characters at these levels. A CR is held to the party's level, their
-- average, as party.level reads it: one strong character doesn't make a
-- creature safe for the rest.
function party.warnings(spec, roster, levels, rated)
  local out = {}
  local creatures, blocks = 0, 0
  local level = averageLevel(levels) or 0
  for _, r in ipairs(roster) do
    if r.count > 0 then
      creatures = creatures + r.count
      blocks = blocks + 1
      local cr = crValue(r.creature.cr)
      if cr and cr > level then
        out[#out + 1] = "The " .. r.creature.one .. "'s CR " .. tostring(r.creature.cr) ..
          " is above the party's level: one of its actions can take a character out."
      end
    end
  end
  if creatures > 2 * #levels then
    out[#out + 1] = "More than two creatures per character: make them fragile, so they fall fast."
  end
  if blocks > 3 then
    out[#out + 1] = capital(party.word(blocks)) .. " stat blocks to run at once."
  end
  if creatures == 1 then
    out[#out + 1] = "A lone creature: one whose CR equals the party's level is a Low fight for four characters."
  end
  if spec.difficulty and rated ~= spec.difficulty then
    out[#out + 1] = "Meant to be " .. LABEL[spec.difficulty] .. ", but for this party it is " .. LABEL[rated] .. "."
  end
  for _, r in ipairs(referenced(spec)) do
    if not r.page then
      out[#out + 1] = "The " .. r.creature.one .. " names a page that isn't there: " .. r.creature.page .. "."
    elseif r.warn then
      out[#out + 1] = r.warn
    end
  end
  return out
end

local function chip(rated)
  return dom.span { class = "gmparty-diff gmparty-diff-" .. rated, __rawText = PIPS[rated] .. " " .. LABEL[rated] }
end

-- The head of a fight's box: its name, then a note.
local function liveHead(spec, note)
  return dom.div {
    class = "gmparty-fight-head",
    dom.strong { __rawText = titleOf(spec) or "Encounter" },
    text(note, "gmparty-note"),
  }
end

-- What a fight at one level shows for characters at these levels, added
-- with add: who and the creatures, with their XP; the difficulty against
-- the budgets; the creatures' pages; what to watch for; and a table of
-- other party sizes.
local function liveBody(spec, p, levels, add)
  local n = #levels
  local roster = party.roster(spec, n)
  local xp = totalXP(roster)
  local rated = party.rate(xp, levels)
  local who = p.source == "book" and "The adventure's party, " or ""
  add(dom.div {
    text(capital(who .. party.word(n) .. (p.source == "book" and "" or " here") .. " at " ..
      levelText(levels) .. ": " .. rosterText(roster, true) .. ", " .. party.digits(xp) .. " XP.")),
  })
  add(dom.div {
    chip(rated),
    text("  Low " .. party.digits(party.budget(levels, "low")) .. " · Moderate " ..
      party.digits(party.budget(levels, "moderate")) .. " · High " ..
      party.digits(party.budget(levels, "high")) .. " XP", "gmparty-note"),
  })
  local creatures = creaturesLive(spec)
  if creatures then add(creatures) end
  local warnings = party.warnings(spec, roster, levels, rated)
  if #warnings > 0 then
    local items = { class = "gmparty-warn" }
    for _, w in ipairs(warnings) do items[#items + 1] = dom.li { __rawText = w } end
    add(dom.ul(items))
  end
  local heads, rows = sizeRows(spec, levels, tableSizes(n))
  local headCells = { dom.th { __rawText = "Characters" } }
  for _, h in ipairs(heads) do headCells[#headCells + 1] = dom.th { __rawText = h } end
  headCells[#headCells + 1] = dom.th { __rawText = "XP" }
  headCells[#headCells + 1] = dom.th { __rawText = "Difficulty" }
  local body = {}
  for _, r in ipairs(rows) do
    local cells = { dom.td { __rawText = (r.size == n and "▶ " or "") .. party.digits(r.size) } }
    for _, c in ipairs(r.counts) do cells[#cells + 1] = dom.td { __rawText = party.digits(c) } end
    cells[#cells + 1] = dom.td { __rawText = party.digits(r.xp) }
    cells[#cells + 1] = dom.td { chip(r.rated) }
    if r.size == n then cells.class = "gmparty-here" end
    body[#body + 1] = dom.tr(cells)
  end
  -- in a frame of its own, which scrolls sideways where the table is wider
  -- than the fight's box, as it is on a phone with several creatures
  add(dom.div { class = "gmparty-table", dom.table { dom.thead { dom.tr(headCells) }, dom.tbody(body) } })
end

-- A fight at one level on the page, for the characters here tonight, as
-- the parts of its box.
local function liveOne(spec, p)
  local written = writtenFor(spec)
  local levels = {}
  for i, m in ipairs(p.here) do levels[i] = m.level or spec.level end
  local parts = { class = "gmparty-fight" }
  local function add(node) parts[#parts + 1] = node end
  add(liveHead(spec, " · " .. (spec.difficulty and ("a " .. spec.difficulty .. " fight ") or "") .. "for " ..
    party.word(written) .. " level " .. string.format("%d", spec.level) .. " characters, as written"))
  if #levels == 0 then
    add(dom.div { text("Nobody here tonight.") })
  else
    liveBody(spec, p, levels, add)
  end
  return parts
end

-- A fight in versions on the page: the version for the level nearest the
-- party's, for the characters here tonight, then how each of the others
-- would go for them. With no party level, every version as written.
local function liveVersions(spec, versions, p)
  local parts = { class = "gmparty-fight" }
  local function add(node) parts[#parts + 1] = node end
  add(liveHead(spec, " · " .. (spec.difficulty and ("a " .. spec.difficulty .. " fight, ") or "") ..
    "in versions for " .. levelList(versions) .. " characters"))
  if #p.here == 0 then
    add(dom.div { text("Nobody here tonight.") })
    return parts
  end
  local level = party.level(p)
  if not level then
    if p.source ~= "book" then
      add(dom.div { text("Give the party a level to see the version for it. Each as written:", "gmparty-note") })
    end
    for _, v in ipairs(versions) do
      add(dom.div { class = "gmparty-version", dom.strong { __rawText = "Level " .. string.format("%d", v.level) } })
      liveBody(v, p, levelsFor(#p.here, v.level), add)
    end
    return parts
  end
  local chosen = nearest(versions, level)
  local levels = {}
  for i, m in ipairs(p.here) do levels[i] = m.level or level end
  add(dom.div {
    class = "gmparty-version",
    dom.strong { __rawText = "▶ Level " .. string.format("%d", chosen.level) },
    text(chosen.level == level and ", your party's level" or
      (", the nearest to your party's level " .. string.format("%d", level)), "gmparty-note"),
  })
  liveBody(chosen, p, levels, add)
  local others = { class = "gmparty-others" }
  for _, v in ipairs(versions) do
    if v ~= chosen then
      local roster = party.roster(v, #levels)
      local xp = totalXP(roster)
      others[#others + 1] = dom.li {
        dom.strong { __rawText = "Level " .. string.format("%d", v.level) },
        text(": " .. rosterText(roster, true) .. ", " .. party.digits(xp) .. " XP, "),
        chip(party.rate(xp, levels)),
        text(" for your party", "gmparty-note"),
      }
    end
  end
  add(dom.div { class = "gmparty-version", text("The other versions", "gmparty-note") })
  add(dom.ul(others))
  return parts
end

-- The fight as the page shows it: for the characters here tonight.
function party.fightLive(spec)
  local p = party.get()
  local versions, many = party.versions(spec)
  local parts
  if not many or #versions == 1 then
    parts = liveOne(versions[1], p)
  else
    parts = liveVersions(spec, versions, p)
  end
  -- As text, like face(): identical fights on a page share one result. A
  -- tab behind its space says so over the fight, on the page alone.
  return widget.new {
    html = staleNote() .. dom.div(parts).outerHTML, markdown = party.fightPrint(spec), display = "block",
  }
end

local function checkFight(spec)
  if type(spec) ~= "table" then
    error('party.fight takes a table: { level = 3, {6, "skeleton", cr = "1/4"} }')
  end
  local given = 0
  for _, v in ipairs(spec) do
    if isVersion(v) then given = given + 1 end
  end
  if given == 0 then
    if type(spec.level) ~= "number" then
      error("party.fight: give the level the fight is written for, like level = 3")
    end
    if spec.difficulty and not COLUMN[spec.difficulty] then
      error("party.fight: the difficulty is low, moderate or high")
    end
    party.creatures(spec)
    return
  end
  if spec.level ~= nil then
    error("party.fight: a fight in versions gives each version its own level, not the fight: { level = 6, ... }")
  end
  local seen = {}
  for _, v in ipairs(spec) do
    if type(v) == "table" then
      if not isVersion(v) then
        error('party.fight: in a fight with versions, every creature goes inside a version: ' ..
          '{ level = 6, {1, "wight", cr = 3} }')
      end
      if type(v.level) ~= "number" or v.level ~= math.floor(v.level) then
        error("party.fight: give each version the level it is written for, like level = 6")
      end
      local key = string.format("%d", v.level)
      if seen[key] then error("party.fight: two versions for level " .. key) end
      seen[key] = true
      local difficulty = v.difficulty or spec.difficulty
      if difficulty and not COLUMN[difficulty] then
        error("party.fight: the difficulty is low, moderate or high")
      end
    end
  end
  for _, v in ipairs(party.versions(spec)) do
    if #party.creatures(v) == 0 then
      error("party.fight: the level " .. string.format("%d", v.level) .. " version has no creatures")
    end
  end
end

-- A fight, written for the adventure's party. See "Fights" above. Its
-- Markdown face is the fight as printed.
function party.fight(spec)
  checkFight(spec)
  return party.fightLive(spec)
end

------------------------------------------------------------------ in print

-- The party the adventure is written for, as a book knows it: its size,
-- all of them here, and no level, since a book is played at every level.
local function bookParty()
  local members = {}
  for i = 1, party.setting("book") do members[i] = {} end
  return { size = #members, members = members, here = members, source = "book" }
end

-- What each of these prints as: the adventure's number, the rule, nothing
-- for a hint, and the fight for the adventure's party. GM Book evaluates an
-- expression with party standing for this table, and finds it in
-- gmbook.printers. Nothing here reads the table playing tonight: what isn't
-- given its own print falls through to party, so the party itself, its
-- level, its DCs' rise and its summary are the adventure's.
party.printed = setmetatable({
  get = function() return bookParty() end,
  -- no party level, as in an adventure space on its own: GM Book names a
  -- page that prints one, since the book has none to give
  level = function() return nil end,
  -- a DC prints as written, so it rises by nothing; at a level asked for,
  -- by what the rule says
  dcRise = function(level)
    if level == nil then return 0 end
    return party.dcRise(level)
  end,
  summary = function()
    local book = party.setting("book")
    return "**" .. capital(party.word(book)) .. (book == 1 and " character" or " characters") ..
      ",** the party the adventure is written for."
  end,
  number = function(spec, cap) return (select(2, numberForms(spec, cap))) end,
  -- the adventure's number, for a library that draws to it: a map printed
  -- in the book is the size the adventure is written for, not tonight's
  value = function(spec) return party.value(spec, party.setting("book")) end,
  n = function(spec) return (select(2, numberForms(spec, false))) end,
  N = function(spec) return (select(2, numberForms(spec, true))) end,
  count = function(spec) return (select(2, countForms(spec))) end,
  each = function(count, one, many)
    eachArgs(count, one, many)
    return ""
  end,
  fight = function(spec)
    checkFight(spec)
    return party.fightPrint(spec)
  end,
  -- a DC as written, for levels 1 to 4: the book says once how they rise
  dc = function(spec) return (select(2, dcForms(spec))) end,
}, { __index = party })

gmbook = gmbook or {}
gmbook.printers = gmbook.printers or {}
gmbook.printers.party = party.printed

------------------------------------------------------------------ the party page

-- The party at a glance, for a DM's page: who is in it, at what level, who
-- is here tonight, and what a fight for them can spend.
function party.summary()
  local p = party.get()
  local levels, known = {}, true
  for _, m in ipairs(p.here) do
    if m.level then levels[#levels + 1] = m.level else known = false end
  end
  local all = {}
  for _, m in ipairs(p.members) do
    if m.level then all[#all + 1] = m.level end
  end
  local lines = {}
  local count = capital(party.word(p.size)) .. (p.size == 1 and " character" or " characters")
  if p.source == "characters" then
    local names = {}
    for _, m in ipairs(p.members) do
      names[#names + 1] = "[[" .. m.page .. "|" .. m.name .. "]]" ..
        (m.level and (" (" .. string.format("%d", m.level) .. ")") or "") .. (m.away and ", away" or "")
    end
    lines[#lines + 1] = "**" .. count .. ":** " .. table.concat(names, ", ") .. "."
  elseif p.source == "party" then
    lines[#lines + 1] = "**" .. count .. (#all > 0 and (", " .. levelText(all)) or "") ..
      ",** from `characters` and `level` on [[" .. p.page .. "]], until there are character pages."
  else
    lines[#lines + 1] = "**" .. count .. ",** the party the adventure is written for. " ..
      "A page with `type: party`, `characters` and `level`, or the character pages, would say otherwise."
  end
  if #p.here < p.size then
    lines[#lines + 1] = capital(party.word(#p.here)) .. " here tonight."
  end
  -- a retired character counts nowhere, but is named, so a page marked
  -- retired by mistake is seen
  if p.retired and #p.retired > 0 then
    local names = {}
    for _, r in ipairs(p.retired) do names[#names + 1] = "[[" .. r.page .. "|" .. r.name .. "]]" end
    lines[#lines + 1] = "Retired, and counted nowhere: " .. table.concat(names, ", ") .. "."
  end
  if known and #levels > 0 then
    lines[#lines + 1] = "A fight for them can spend " .. party.digits(party.budget(levels, "low")) ..
      " XP at Low, " .. party.digits(party.budget(levels, "moderate")) .. " at Moderate, or " ..
      party.digits(party.budget(levels, "high")) .. " at High."
  elseif not known then
    lines[#lines + 1] = "Give every character a level to see what a fight for them can spend."
  end
  local rise = party.dcRise(party.level(p))
  if rise > 0 then
    lines[#lines + 1] = "At level " .. string.format("%d", party.level(p)) .. ", a DC from `party.dc` is " ..
      party.word(rise) .. " more than written."
  end
  return widget.new { markdown = table.concat(lines, "\n\n"), display = "block" }
end
```

```space-style
.gmparty-n {
  text-decoration: underline dotted;
  text-decoration-thickness: 1px;
  text-underline-offset: 0.2em;
  cursor: help;
}

.gmparty-each {
  font-style: italic;
  color: var(--subtle-color);
  cursor: help;
}

.gmparty-each::before {
  content: "▸ ";
  font-style: normal;
}

/* A number's note: its rule and what it prints. A mouse has it as the
   number's tooltip, but a phone shows no tooltip, so a tap on the number,
   which gives it focus, shows the note in a box of its own; so does the
   keyboard. It stays until focus moves on. */
.gmparty-n,
.gmparty-each {
  position: relative;
}

.gmparty-n:focus,
.gmparty-each:focus {
  outline: none;
}

.gmparty-n:focus-visible,
.gmparty-each:focus-visible {
  outline: 2px solid currentColor;
  outline-offset: 2px;
}

.gmparty-notebox {
  display: none;
  position: absolute;
  left: 0;
  top: calc(100% + 4px);
  z-index: 20;
  width: max-content;
  max-width: min(24em, calc(100vw - 32px));
  padding: 6px 8px;
  border: 1px solid var(--modal-border-color, #d8dce1);
  border-radius: 4px;
  background: var(--modal-background-color, #fff);
  color: var(--root-color, inherit);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
  font-size: 0.85em;
  font-style: normal;
  font-weight: normal;
  line-height: 1.4;
  text-align: left;
  white-space: normal;
  cursor: auto;
}

.gmparty-n:focus > .gmparty-notebox,
.gmparty-each:focus > .gmparty-notebox {
  display: block;
}

/* A touch screen with no hover, where a tap may not give a span focus:
   the tap's hover shows the note as well. */
@media (hover: none) {
  .gmparty-n:hover > .gmparty-notebox,
  .gmparty-each:hover > .gmparty-notebox {
    display: block;
  }
}

/* On a phone the box sits across the foot of the screen, inside a 16px
   margin, rather than under the number, where it could run off the edge. */
@media screen and (max-width: 600px) {
  .gmparty-notebox {
    position: fixed;
    left: 16px;
    right: 16px;
    top: auto;
    bottom: 16px;
    width: auto;
    max-width: none;
    max-height: 40vh;
    overflow-y: auto;
  }
}

/* A tab behind its space: a line over what it draws, in words. */
.gmparty-stale {
  font-weight: bold;
  margin-bottom: 4px;
}

.gmparty-fight {
  border: 1px solid var(--subtle-background-color);
  border-left: 3px solid var(--subtle-color);
  border-radius: 4px;
  padding: 6px 10px;
}

.gmparty-fight > div + div,
.gmparty-fight > ul {
  margin-top: 4px;
}

/* A table of sizes wider than the fight's box, as one with several
   creatures is on a phone, scrolls sideways inside the box instead of
   running past its edge. */
.gmparty-table {
  overflow-x: auto;
}

.gmparty-note {
  color: var(--subtle-color);
}

.gmparty-nopage {
  font-style: italic;
  color: var(--subtle-color);
}

.gmparty-warn {
  margin: 4px 0;
  padding-left: 1.4em;
}

.gmparty-warn li::marker {
  content: "⚠ ";
}

/* A fight in versions: a rule above each version's part of the box. */
.gmparty-fight > .gmparty-version {
  margin-top: 8px;
  padding-top: 6px;
  border-top: 1px solid var(--subtle-background-color);
}

.gmparty-others {
  margin: 4px 0;
  padding-left: 1.4em;
}

.gmparty-fight table {
  border-collapse: collapse;
}

.gmparty-fight th,
.gmparty-fight td {
  padding: 1px 10px 1px 0;
  text-align: left;
}

.gmparty-fight tr.gmparty-here td {
  font-weight: bold;
}

/* Difficulty: pips and a word carry it; colour only backs them up. */
.gmparty-diff {
  font-weight: bold;
  white-space: nowrap;
}

/* In a narrow table, "Above High" may wrap rather than run off the edge. */
.gmparty-fight table .gmparty-diff {
  white-space: normal;
}

.gmparty-diff-low { color: #2b6cb0; }
.gmparty-diff-moderate { color: #946200; }
.gmparty-diff-high { color: #c2410c; }
.gmparty-diff-above { color: #a21caf; }

html[data-theme="dark"] .gmparty-diff-low { color: #8ab4f8; }
html[data-theme="dark"] .gmparty-diff-moderate { color: #f5c542; }
html[data-theme="dark"] .gmparty-diff-high { color: #fb923c; }
html[data-theme="dark"] .gmparty-diff-above { color: #f0abfc; }

@media (prefers-color-scheme: dark) {
  html:not([data-theme="light"]) .gmparty-diff-low { color: #8ab4f8; }
  html:not([data-theme="light"]) .gmparty-diff-moderate { color: #f5c542; }
  html:not([data-theme="light"]) .gmparty-diff-high { color: #fb923c; }
  html:not([data-theme="light"]) .gmparty-diff-above { color: #f0abfc; }
}
```
