---
tags: meta/library
name: "Library/Storie/GM Party"
description: "Numbers, hand-outs and fights that follow the party's size: live for your table in SilverBullet, and as general rules when the adventure is printed. Encounter math from the 2024 rules in the SRD 5.2.1."
author: "Steven Storie"
version: "1.0.2"
---

# GM Party

Write an adventure once, for the party size you design it for, and let its numbers follow the table that plays it. In SilverBullet a number that scales shows your party's value. In print it shows the rule, so the book works for any table.

| On the page, for a party of six | In print |
|---|---|
| It holds seven grins | It holds one more grin than the party has members, six for a party of five |
| A table laid for six | A table laid for five |
| Six here: all five finds, with one find shared by two | Nothing: the text itself says how finds are shared |
| The fight for this party: its creatures, XP and difficulty | The fight for five, and an *Adjusting the Encounter* note with a table for three to seven characters |

The page side needs nothing else. For print, GM Book 1.5 or later prints each of these in its general form, and GM Kit 2.2 or later puts your party's numbers into the copies it publishes to players.

## Where the party comes from

The most specific source wins:

1. **Character pages.** Every page with `type: pc` is a member, at its own `level`. `away: true` sits a character out of tonight's fights and hand-outs.
2. **A party page.** Before the characters exist, a page with `type: party` gives `characters` and `level`. Its `level` also stands in for a character page that has none. The count can't be called `size`: SilverBullet keeps that name for a page's size in bytes, and a page's own attributes win over its frontmatter.
3. **The adventure's party.** With neither, as in an adventure space on its own, the party is the one the adventure is written for: five, unless the settings say otherwise.

A party page's frontmatter:

    ---
    type: party
    characters: 5
    level: 1
    ---

Counts and story numbers follow everyone in the party. Fights and one-each hand-outs follow the characters here tonight.

On a DM page, `${party.summary()}` shows the party, who is here, and what a fight for them can spend.

## Numbers

**A number in the story** that follows the party: `party.n()` is its size, `party.n(1)` one more, `party.n{times = 2}` twice as many. `party.N` is the same with a capital, to start a sentence. In print, each is the number for the adventure's party.

    A kitchen table still laid for ${party.n()}. ${party.N()} plates, ${party.n()} chairs.

These work anywhere a sentence does, table cells included.

**A count that follows a rule**: `party.count` takes the thing counted and the rule. On the page it shows the count for your party. In print it shows the rule, then the count for the adventure's party.

    It holds ${party.count{"grin", plus = 1}}: enough for everyone.

| Rule | Prints |
|---|---|
| `{"grin"}` | as many grins as the party has members, five for a party of five |
| `{"grin", plus = 1}` | one more grin than the party has members, six for a party of five |
| `{"grin", plus = -1}` | one fewer grin than the party has members, four for a party of five |
| `{"grin", per = 2}` | two grins for each member of the party, ten for a party of five |
| `{"grin", per = 1/2}` | one grin for every two members of the party, rounding up, three for a party of five |

`min` and `max` bound a count, `round = "down"` rounds a fraction down, and `example = false` leaves off the count for the adventure's party. A second name is the plural where adding an s won't do: `{"wolf", "wolves"}`. `cap = true` starts it with a capital.

Hover over a number on the page to see its rule and what it prints.

## One each

`party.each(5, "find")` goes under a list of five things handed out one per character, most important first. It says which to use for the characters here tonight: "Four here: use the first four finds", or "Six here: all five finds, with one find shared by two". It prints nothing, so say in the text itself how a smaller or larger party shares them.

## Fights

Write each fight for the adventure's party, at the level it expects the characters to be:

    ${party.fight { "Drill site", level = 3, difficulty = "moderate",
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

For the whole fight, `difficulty` is what it is meant to be: low, moderate or high. `note` adds a sentence to *Adjusting the Encounter*, `table = false` leaves the table out of print, and `size` writes the fight for a party other than the adventure's.

**On the page** it shows the fight for the characters here tonight, at their levels: the creatures, their XP, the difficulty against the Low, Moderate and High budgets, and a table of other party sizes with yours marked ▶. It flags what the SRD's troubleshooting advice flags: more than two creatures per character, a creature whose CR is above the party's level, more than three stat blocks, and a lone creature. It also flags a fight that has drifted from its intended difficulty. Difficulty always shows as pips and a word, ●○○ Low, ●●○ Moderate, ●●● High and ●●●+ Above High, with colour only as a third cue.

**In print** it gives the fight for the adventure's party with its difficulty and XP. Then comes *Adjusting the Encounter*: a sentence for each rule, and a table for three to seven characters at the written level.

    **Drill site.** A wight, a warhorse skeleton and six skeletons: a moderate-difficulty encounter for five level 3 characters (1,100 XP).

    **Adjusting the Encounter.** For each character fewer than five, remove four skeletons; for each one more, add four.

    | Characters | Skeletons | XP | Difficulty |
    |---|---|---|---|
    | 3 | 0 | 800 | High |
    | 4 | 2 | 900 | Moderate |
    | 5 | 6 | 1,100 | Moderate |
    | 6 | 10 | 1,300 | Moderate |
    | 7 | 14 | 1,500 | Moderate |

Put a fight on a line of its own, since it prints as paragraphs and a table.

## The rules it uses

The 2024 encounter rules: choose a difficulty, look up the XP budget per character for each character's level, add them up, and spend that on creatures at their XP. There are no multipliers. Where the characters' levels differ, each is looked up at its own level, which is the rule as written when they are all the same.

`party.budget(levels, "moderate")` and `party.rate(xp, levels)` do the sums, and `party.xp("1/4")` looks up a CR. `party.budgets()` and `party.xpTable()` print the two tables, for a rules page.

## How it prints

On the page each of these is a widget: HTML with its tooltip, and the same text as its Markdown face. SilverBullet draws a table from the Markdown faces of the expressions in it, and its Copy button and Baked Sections use them too, so all of those get your party's numbers. GM Kit 2.2 puts the Markdown face into the copies it publishes, so players see their own party's numbers. A hint from `party.each` has an empty Markdown face, so it never reaches them. A fight's Markdown face is the fight as printed.

GM Book 1.5 evaluates each expression with `party` standing for `party.printed`, which gives the rule, the adventure's number, nothing for a hint, and the fight for the adventure's party. This library puts `party.printed` in `gmbook.printers`, where GM Book looks for it.

Baked Sections alone couldn't do this: they bake whole blocks, never a number in the middle of a sentence.

## Settings

    config.set("gmParty", { book = 5, smallest = 3, largest = 7 })

`book` is the size of the party the adventure is written for. `smallest` and `largest` bound the tables in print.

## Rules text

The XP Budget per Character and Experience Points by Challenge Rating tables below come from the SRD 5.2.1. A book that prints them carries the same statement:

This work includes material from the System Reference Document 5.2.1 ("SRD 5.2.1") by Wizards of the Coast LLC, available at https://www.dndbeyond.com/srd. The SRD 5.2.1 is licensed under the Creative Commons Attribution 4.0 International License, available at https://creativecommons.org/licenses/by/4.0/legalcode.

## Implementation

```space-lua
-- priority: 10
party = party or {}

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

-- "six grins", "one grin", "no grins"; with article, "a wight".
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

------------------------------------------------------------------ the party

-- The party, from the most specific source there is: the character pages
-- (type: pc), then a page describing the party (type: party, with characters
-- and level), then the party the adventure is written for. Read again at most
-- every two seconds, since every number on a page asks for it. A page's own
-- size, in bytes, would shadow a frontmatter "size", hence "characters".
function party.get()
  local now = os.time()
  if party.cached and now - party.cached.at < 2 then return party.cached.value end
  local pages = query[[
    from p = index.pages()
    where p.type == "pc" or p.type == "party"
    order by p.name
  ]]
  local pcs, home = {}, nil
  for _, p in ipairs(pages) do
    if p.type == "pc" then pcs[#pcs + 1] = p elseif not home then home = p end
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
    page = home and home.name or nil,
  }
  party.cached = { at = now, value = value }
  return value
end

-- Forget the party read last, so the next number reads the pages again.
function party.refresh()
  party.cached = nil
end

local function whence(p)
  if p.source == "characters" then return "counted from the character pages" end
  if p.source == "party" then return "from " .. p.page end
  return "the party the adventure is written for"
end

-- A value on the page: the HTML with its tooltip, and the same text as the
-- Markdown face, which is what a table, Copy, Baked Sections and GM Kit's
-- publishing use. A hint passes "" as its Markdown, so it stays on the page.
-- The HTML goes as text, not an element: SilverBullet shares one result
-- between identical expressions on a page, and an element can only be in
-- one place, so the second copy would take it from the first.
local function face(live, note, class, markdown)
  return widget.new {
    html = dom.span { class = class or "gmparty-n", title = note, __rawText = live }.outerHTML,
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

-- The rule behind a count, as a phrase: "one more grin than the party has
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

-- A count that follows a rule. Returns this party's count, "seven grins",
-- the rule for print, "one more grin than the party has members, six for a
-- party of five", and a note.
local function countForms(spec)
  if type(spec) ~= "table" or type(spec[1]) ~= "string" then
    error('party.count takes the thing counted and its rule: {"grin", plus = 1}')
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

-- Party sizes at one level: the column heads for the creatures whose number
-- changes, and a row per size with those numbers, the XP and the difficulty.
local function sizeRows(spec, level, sizes)
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
    rows[#rows + 1] = { size = n, counts = counts, xp = xp, rated = party.rate(xp, levelsFor(n, level)) }
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

-- The fight as printed: for the adventure's party, then how to adjust it.
function party.fightPrint(spec)
  local written, level = writtenFor(spec), spec.level
  local roster = party.roster(spec, written)
  local xp = totalXP(roster)
  local rated = party.rate(xp, levelsFor(written, level))
  local what = rated == "above" and "an encounter beyond high difficulty" or
    ("a " .. rated .. "-difficulty encounter")
  local lines = {
    "**" .. (titleOf(spec) or "Creatures") .. ".** " .. capital(rosterText(roster, true)) ..
      ": " .. what .. " for " .. party.word(written) .. " level " .. string.format("%d", level) ..
      " characters (" .. party.digits(xp) .. " XP).",
    "",
    "**Adjusting the Encounter.** " .. party.adjustments(spec),
  }
  if spec.table ~= false then
    local heads, rows = sizeRows(spec, level, tableSizes())
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
  return table.concat(lines, "\n")
end

-- What to watch for, after the SRD's troubleshooting advice.
function party.warnings(spec, roster, levels, rated)
  local out = {}
  local creatures, blocks, top = 0, 0, 0
  for _, l in ipairs(levels) do
    if l > top then top = l end
  end
  for _, r in ipairs(roster) do
    if r.count > 0 then
      creatures = creatures + r.count
      blocks = blocks + 1
      local cr = crValue(r.creature.cr)
      if cr and cr > top then
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
  return out
end

local function chip(rated)
  return dom.span { class = "gmparty-diff gmparty-diff-" .. rated, __rawText = PIPS[rated] .. " " .. LABEL[rated] }
end

local function text(s, class)
  return dom.span { class = class, __rawText = s }
end

-- The fight as the page shows it: for the characters here tonight.
function party.fightLive(spec)
  local p = party.get()
  local written = writtenFor(spec)
  local levels = {}
  for i, m in ipairs(p.here) do levels[i] = m.level or spec.level end
  local n = #levels
  local parts = { class = "gmparty-fight" }
  local function add(node) parts[#parts + 1] = node end
  add(dom.div {
    class = "gmparty-fight-head",
    dom.strong { __rawText = titleOf(spec) or "Encounter" },
    text(" · " .. (spec.difficulty and ("a " .. spec.difficulty .. " fight ") or "") .. "for " ..
      party.word(written) .. " level " .. string.format("%d", spec.level) .. " characters, as written",
      "gmparty-note"),
  })
  if n == 0 then
    add(dom.div { text("Nobody here tonight.") })
    return widget.new { html = dom.div(parts).outerHTML, markdown = party.fightPrint(spec), display = "block" }
  end
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
  local warnings = party.warnings(spec, roster, levels, rated)
  if #warnings > 0 then
    local items = { class = "gmparty-warn" }
    for _, w in ipairs(warnings) do items[#items + 1] = dom.li { __rawText = w } end
    add(dom.ul(items))
  end
  local sum = 0
  for _, l in ipairs(levels) do sum = sum + l end
  local heads, rows = sizeRows(spec, math.floor(sum / n + 0.5), tableSizes(n))
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
  add(dom.table { dom.thead { dom.tr(headCells) }, dom.tbody(body) })
  -- As text, like face(): identical fights on a page share one result.
  return widget.new { html = dom.div(parts).outerHTML, markdown = party.fightPrint(spec), display = "block" }
end

local function checkFight(spec)
  if type(spec) ~= "table" then
    error('party.fight takes a table: { level = 3, {6, "skeleton", cr = "1/4"} }')
  end
  if type(spec.level) ~= "number" then
    error("party.fight: give the level the fight is written for, like level = 3")
  end
  if spec.difficulty and not COLUMN[spec.difficulty] then
    error("party.fight: the difficulty is low, moderate or high")
  end
  party.creatures(spec)
end

-- A fight, written for the adventure's party. See "Fights" above. Its
-- Markdown face is the fight as printed.
function party.fight(spec)
  checkFight(spec)
  return party.fightLive(spec)
end

------------------------------------------------------------------ in print

-- What each of these prints as: the adventure's number, the rule, nothing
-- for a hint, and the fight for the adventure's party. GM Book evaluates an
-- expression with party standing for this table, and finds it in
-- gmbook.printers.
party.printed = setmetatable({
  number = function(spec, cap) return (select(2, numberForms(spec, cap))) end,
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
  if known and #levels > 0 then
    lines[#lines + 1] = "A fight for them can spend " .. party.digits(party.budget(levels, "low")) ..
      " XP at Low, " .. party.digits(party.budget(levels, "moderate")) .. " at Moderate, or " ..
      party.digits(party.budget(levels, "high")) .. " at High."
  elseif not known then
    lines[#lines + 1] = "Give every character a level to see what a fight for them can spend."
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

.gmparty-fight {
  border: 1px solid var(--subtle-background-color);
  border-left: 3px solid var(--subtle-color);
  border-radius: 4px;
  padding: 6px 10px;
}

.gmparty-fight > div + div,
.gmparty-fight > ul,
.gmparty-fight > table {
  margin-top: 4px;
}

.gmparty-note {
  color: var(--subtle-color);
}

.gmparty-warn {
  margin: 4px 0;
  padding-left: 1.4em;
}

.gmparty-warn li::marker {
  content: "⚠ ";
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
