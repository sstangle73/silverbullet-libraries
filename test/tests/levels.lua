------------------------------------------------------------------ The party's level (GM Party 1.3)

-- Fights in versions for the level the party reaches them at, DCs that
-- rise with it, a creature page that lists every CR it runs at, and GM
-- Kit reading a check whose rungs are written through party.dc.

local function unescape(s)
  return (s:gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&quot;", '"'):gsub("&amp;", "&"))
end
-- The visible text, less the note a number shows only while it has focus.
local function live(w)
  assert(type(w.html) == "string", "a GM Party widget's html should be text")
  local shown = (w.html:gsub('<span[^>]- class="gmparty%-notebox"[^>]*>.-</span>', ""))
  return unescape((shown:gsub("<[^>]*>", "")))
end
local function attr(w, name)
  return unescape(w.html:match(" " .. name .. '="([^"]*)"') or "")
end

-- GM Party's own example, as its docs write it.
local BARROW_LEVELS = { "The barrow", difficulty = "moderate",
  { level = 3,
    { 1, "wight", cr = 3 },
    { 1, "warhorse skeleton", cr = "1/2" },
    { 6, "skeleton", cr = "1/4", step = 4 },
  },
  { level = 6,
    { 1, "wraith", cr = 5 },
    { 2, "wight", cr = 3, step = 1, min = 1 },
    { 4, "skeleton", cr = "1/4" },
  },
}

local BARROW_LEVELS_PRINTED = table.concat({
  "**The barrow.** Two versions, for level 3 and level 6 characters: run the one nearest your party's level.",
  "",
  "**Level 3.** A wight, a warhorse skeleton and six skeletons: a moderate-difficulty encounter for five level 3 characters (1,100 XP).",
  "",
  "**Adjusting the Encounter.** For each character fewer than five, remove four skeletons; for each one more, add four.",
  "",
  "| Characters | Skeletons | XP | Difficulty |",
  "|---|---|---|---|",
  "| 3 | 0 | 800 | High |",
  "| 4 | 2 | 900 | Moderate |",
  "| 5 | 6 | 1,100 | Moderate |",
  "| 6 | 10 | 1,300 | Moderate |",
  "| 7 | 14 | 1,500 | Moderate |",
  "",
  "**Level 6.** A wraith, two wights and four skeletons: a moderate-difficulty encounter for five level 6 characters (3,400 XP).",
  "",
  "**Adjusting the Encounter.** For each character fewer than five, remove a wight; for each one more, add one. Keep at least one wight.",
  "",
  "| Characters | Wights | XP | Difficulty |",
  "|---|---|---|---|",
  "| 3 | 1 | 2,700 | Moderate |",
  "| 4 | 1 | 2,700 | Moderate |",
  "| 5 | 2 | 3,400 | Moderate |",
  "| 6 | 3 | 4,100 | Moderate |",
  "| 7 | 4 | 4,800 | Moderate |",
}, "\n")

------------------------------------------------------------------ the party's level

test("levels: the party's level is the average of who is here, rounded", "dm", function()
  eq(party.level(), 1, "The Party's level, until there are character pages")
  H.pages["Party/Ann"] = pcPage(3)
  H.pages["Party/Ben"] = pcPage(4)
  party.refresh()
  eq(party.level(), 4, "3 and 4 average 3.5, which rounds up")
  H.pages["Party/Cal"] = pcPage(10, "away: true\n")
  party.refresh()
  eq(party.level(), 4, "a character away tonight doesn't count")
  useParty(2, 7, 2)
  eq(party.level(), 7, "with everyone away, everyone's")
end)

test("levels: an adventure space on its own has no party level", "adventure", function()
  eq(party.level(), nil)
end)

------------------------------------------------------------------ DCs

test("levels: a DC rises by one at levels 5, 9, 13 and 17", "adventure", function()
  local rises = {}
  for level = 1, 20 do rises[level] = string.format("%d", party.dcRise(level)) end
  eq(table.concat(rises, " "), "0 0 0 0 1 1 1 1 2 2 2 2 3 3 3 3 4 4 4 4")
  eq(party.dcRise(0), 0)
  eq(party.dcRise(30), 4, "past 20, as at 20")
  eq(party.dcRise(), 0, "no party level, no rise")
end)

test("levels: a DC shows this party's and prints as written", "dm", function()
  useParty(5, 9)
  local w = party.dc(15)
  eq(live(w), "17")
  eq(w.markdown, "17", "the Markdown face is this party's too, for tables and the players' copies")
  eq(w.display, "inline")
  eq(attr(w, "class"), "gmparty-n")
  eq(attr(w, "title"), "DC 15 as written, for levels 1 to 4, one more at levels 5, 9, 13 and 17: " ..
    "17 for this party at level 9, from the character pages. Prints as “15”.")
  eq(party.printed.dc(15), "15")
  eq(live(party.dc { 15 }), "17")
  useParty(5, 4)
  eq(live(party.dc(15)), "15")
  useParty(5, 17)
  eq(live(party.dc(20)), "24")
  H.pages["The Party"] = "---\ntype: party\ncharacters: 5\nlevel: 5\n---\n\n# The Party\n"
  useParty(0)
  eq(live(party.dc(10)), "11")
  has(attr(party.dc(10), "title"), "11 for this party at level 5, from The Party.")
end)

test("levels: a DC in an adventure space on its own shows as written", "adventure", function()
  local w = party.dc(15)
  eq(live(w), "15")
  eq(attr(w, "title"), "DC 15 as written, for levels 1 to 4, one more at levels 5, 9, 13 and 17. Prints as “15”.")
end)

test("levels: a DC that isn't a whole number says what to write", "adventure", function()
  for _, bad in ipairs({ "15", 15.5, {} }) do
    local good, err = pcall(party.dc, bad)
    ok(not good)
    has(err, "party.dc takes the DC as written for levels 1 to 4")
  end
end)

test("levels: The Party's summary says how far DCs rise", "dm", function()
  hasnt(party.summary().markdown, "party.dc", "not at level 1, where they don't")
  useParty(3, 9)
  has(party.summary().markdown, "At level 9, a DC from `party.dc` is two more than written.")
end)

-- party.printed once fell through to the live party for these, so a book
-- built in a space whose party was at level 9 printed 9 and 2 beside the
-- five and the DC 15 it printed for the adventure's.
test("levels: print gives the adventure's party, not the one playing tonight", "dm", function()
  useParty(4, 9)
  eq(party.level(), 9)
  eq(party.dcRise(), 2)
  eq(party.printed.level(), nil, "a book is played at every level")
  eq(party.printed.dcRise(), 0, "its DCs print as written")
  eq(party.printed.dcRise(9), 2, "and the rule at a level asked for still holds")
  eq(party.printed.dc(15), "15")
  local p = party.printed.get()
  eq(p.size, 5)
  eq(#p.here, 5)
  eq(p.source, "book")
  eq(party.printed.summary(), "**Five characters,** the party the adventure is written for.")
  -- as GM Book prints a page: what has no book value is left for it to name
  local text, left = gmbook.print("Rise ${party.dcRise()}, for ${party.n()}.\n\n${party.summary()}\n\n" ..
    "At level ${party.level()}.\n", "Adventure/Campaign/Premise")
  has(text, "Rise 0, for five.\n\n**Five characters,** the party the adventure is written for.\n\n")
  hasnt(text, "PC 01")
  eq(list(left), "party.level()")
end)

------------------------------------------------------------------ fights in versions

test("levels: a fight in versions prints the rule, then each version", "adventure", function()
  eq(party.fightPrint(BARROW_LEVELS), BARROW_LEVELS_PRINTED)
  eq(party.printed.fight(BARROW_LEVELS), BARROW_LEVELS_PRINTED)
  eq(party.fight(BARROW_LEVELS).markdown, BARROW_LEVELS_PRINTED, "the Markdown face is the fight as printed")
end)

test("levels: GM Party's docs print their example as they say", "adventure", function()
  local docs = SRC["GM Party"]
  local from = docs:find("    **The barrow.** Two versions", 1, true)
  ok(from, "the docs' printed example is missing")
  local block = {}
  for line in docs:sub(from):gmatch("([^\n]*)\n") do
    if line ~= "" and not line:find("^    ") then break end
    block[#block + 1] = line:sub(5)
  end
  while block[#block] == "" do block[#block] = nil end
  eq(table.concat(block, "\n"), BARROW_LEVELS_PRINTED)
end)

test("levels: the page runs the version nearest the party's level", "dm", function()
  useParty(5, 5)
  local t = live(party.fight(BARROW_LEVELS))
  has(t, "The barrow · a moderate fight, in versions for level 3 and level 6 characters")
  has(t, "▶ Level 6, the nearest to your party's level 5")
  has(t, "Five here at level 5: a wraith, two wights and four skeletons, 3,400 XP.")
  has(t, "●●○ Moderate  Low 2,500 · Moderate 3,750 · High 5,500 XP")
  has(t, "The other versions")
  has(t, "Level 3: a wight, a warhorse skeleton and six skeletons, 1,100 XP, ●○○ Low for your party")
  hasnt(t, "Meant to be", "the version for their level is the difficulty it means to be")
  ok(t:find("▶ Level 6", 1, true) < t:find("The other versions", 1, true), "the version to run comes first")
  useParty(5, 4)
  has(live(party.fight(BARROW_LEVELS)), "▶ Level 3, the nearest to your party's level 4")
  useParty(5, 6)
  has(live(party.fight(BARROW_LEVELS)), "▶ Level 6, your party's level")
  useParty(4, 9)
  t = live(party.fight(BARROW_LEVELS))
  has(t, "▶ Level 6, the nearest to your party's level 9")
  has(t, "Four here at level 9: a wraith, a wight and four skeletons, 2,700 XP.")
  has(t, "Meant to be Moderate, but for this party it is Low.")
end)

test("levels: two versions as near go to the lower", "dm", function()
  local spec = { "Near", difficulty = "low",
    { level = 5, { 1, "ogre", cr = 2 } },
    { level = 3, { 1, "bugbear warrior", cr = 1 } },
  }
  useParty(5, 4)
  local t = live(party.fight(spec))
  has(t, "▶ Level 3, the nearest to your party's level 4", "the versions are read lowest first, whatever the order written")
  has(party.fightPrint(spec), "Two versions, for level 3 and level 5 characters")
end)

test("levels: characters at different levels meet the version for their average", "dm", function()
  H.pages["Party/Ann"] = pcPage(4)
  H.pages["Party/Ben"] = pcPage(5)
  H.pages["Party/Cal"] = pcPage(5)
  party.refresh()
  local t = live(party.fight(BARROW_LEVELS))
  has(t, "▶ Level 6, the nearest to your party's level 5")
  has(t, "Three here at levels 4–5: a wraith, a wight and four skeletons, 2,700 XP.")
end)

test("levels: an adventure space on its own shows every version as written", "adventure", function()
  local t = live(party.fight(BARROW_LEVELS))
  has(t, "The adventure's party, five at level 3: a wight, a warhorse skeleton and six skeletons, 1,100 XP.")
  has(t, "The adventure's party, five at level 6: a wraith, two wights and four skeletons, 3,400 XP.")
  ok(t:find("five at level 3", 1, true) < t:find("five at level 6", 1, true), "lowest first")
  hasnt(t, "▶ Level")
  hasnt(t, "Meant to be")
  hasnt(t, "Give the party a level")
end)

test("levels: a DM space with no party level shows every version and asks for one", "dm", function()
  H.pages["The Party"] = "---\ntype: party\ncharacters: 4\n---\n\n# The Party\n"
  party.refresh()
  local t = live(party.fight(BARROW_LEVELS))
  has(t, "Give the party a level to see the version for it. Each as written:")
  has(t, "Four here at level 3: a wight, a warhorse skeleton and two skeletons, 900 XP.")
  has(t, "Four here at level 6: a wraith, a wight and four skeletons, 2,700 XP.")
end)

test("levels: nobody here tonight", "dm", function()
  useParty(2, 5, 2)
  eq(live(party.fight(BARROW_LEVELS)):match("characters(.*)$"), "Nobody here tonight.")
  useParty(0)
  H.pages["The Party"] = "---\ntype: party\ncharacters: 0\nlevel: 5\n---\n\n# The Party\n"
  party.refresh()
  has(live(party.fight(BARROW_LEVELS)), "Nobody here tonight.")
end)

test("levels: a fight with one version is a fight at that level", "adventure", function()
  local one = { "The barrow", difficulty = "moderate",
    { level = 3,
      { 1, "wight", cr = 3 },
      { 1, "warhorse skeleton", cr = "1/2" },
      { 6, "skeleton", cr = "1/4", step = 4 },
    },
  }
  local plain = { "The barrow", level = 3, difficulty = "moderate",
    { 1, "wight", cr = 3 },
    { 1, "warhorse skeleton", cr = "1/2" },
    { 6, "skeleton", cr = "1/4", step = 4 },
  }
  eq(party.fightPrint(one), party.fightPrint(plain))
  eq(party.fight(one).html, party.fight(plain).html)
end)

test("levels: a version can give its own difficulty and note", "dm", function()
  local spec = { "The barrow", difficulty = "moderate",
    { level = 3, note = "The skeletons stay down once they fall.",
      { 1, "wight", cr = 3 },
      { 6, "skeleton", cr = "1/4", step = 4 },
    },
    { level = 6, difficulty = "high",
      { 1, "wraith", cr = 5 },
      { 3, "wight", cr = 3, step = 1 },
    },
  }
  local printed = party.fightPrint(spec)
  has(printed, "for each one more, add four. The skeletons stay down once they fall.")
  eq(count(printed, "stay down"), 1, "the note is its version's own")
  useParty(5, 6)
  local t = live(party.fight(spec))
  has(t, "Five here at level 6: a wraith and three wights, 3,900 XP.")
  has(t, "Meant to be High, but for this party it is Moderate.", "the version's difficulty is the one it means to be")
end)

test("levels: mistakes in a fight in versions say what to write", "adventure", function()
  local cases = {
    { { "X", { level = 3, { 1, "wight", cr = 3 } }, { 1, "ghoul", cr = 1 } },
      "every creature goes inside a version" },
    { { "X", level = 3, { level = 3, { 1, "wight", cr = 3 } } },
      "a fight in versions gives each version its own level" },
    { { "X", { level = "three", { 1, "wight", cr = 3 } } }, "give each version the level it is written for" },
    { { "X", { level = 3.5, { 1, "wight", cr = 3 } } }, "give each version the level it is written for" },
    { { "X", { level = 3, { 1, "wight", cr = 3 } }, { level = 3, { 1, "ghoul", cr = 1 } } },
      "two versions for level 3" },
    { { "X", { level = 3 }, { level = 6, { 1, "wight", cr = 3 } } }, "the level 3 version has no creatures" },
    { { "X", { level = 3, difficulty = "deadly", { 1, "wight", cr = 3 } } }, "low, moderate or high" },
    { { "X", { level = 3, { "wight", 1 } } }, "each creature is {count, name, cr = ...}" },
    { { "X", { level = 3, { 1, "thing", cr = 99 } } }, "no XP for thing" },
  }
  for _, c in ipairs(cases) do
    local good, err = pcall(party.fight, c[1])
    ok(not good, "should fail: " .. c[2])
    has(err, c[2])
    good, err = pcall(party.printed.fight, c[1])
    ok(not good, "should fail in print too: " .. c[2])
  end
end)

------------------------------------------------------------------ creatures in more than one version

local LORD = "World/Monsters/Barrow Lord"
local LORD_PAGE = '---\ntype: monster\ncr: ["3", "5"]\n---\n\n# Barrow Lord\n\n## At level 3 (CR 3)\n\n## At level 6 (CR 5)\n'

local function lordFight(lateCR)
  return { "The barrow", difficulty = "moderate",
    { level = 3,
      { 1, "barrow lord", cr = 3, page = LORD },
      { 6, "skeleton", cr = "1/4", step = 4 },
    },
    { level = 6,
      { 1, "barrow lord", cr = lateCR or 5, page = LORD },
      { 2, "wight", cr = 3, step = 1, min = 1 },
    },
  }
end

test("levels: a creature page lists every CR it runs at", "adventure", function()
  H.pages[LORD] = LORD_PAGE
  bestiary.refresh()
  for _, v in ipairs(party.versions(lordFight())) do
    local levels = { v.level, v.level, v.level, v.level, v.level }
    local roster = party.roster(v, 5)
    hasnt(list(party.warnings(v, roster, levels, "moderate")), " here, and CR ",
      "CR " .. tostring(v[1].cr) .. " is on the page's list")
  end
  local late = party.versions(lordFight(4))[2]
  has(list(party.warnings(late, party.roster(late, 5), { 6, 6, 6, 6, 6 }, "moderate")),
    "The barrow lord is CR 4 here, and CR 3 or 5 on Barrow Lord.")
  -- a single CR still reads as one
  local wrong = { "Wrong", level = 1, { 1, "strangler", cr = 1, page = "World/Monsters/Strangler" } }
  has(list(party.warnings(wrong, party.roster(wrong, 5), { 1, 1, 1, 1, 1 }, "low")),
    "The strangler is CR 1 here, and CR 1/2 on Strangler.")
end)

test("levels: the creatures of every version print once, after the rule", "adventure", function()
  H.pages[LORD] = LORD_PAGE
  bestiary.refresh()
  local printed = party.fightPrint(lordFight())
  has(printed, "**The barrow.** Two versions, for level 3 and level 6 characters: " ..
    "run the one nearest your party's level.\n\n**The creatures.** Barrow lord — original to this book.\n\n**Level 3.**")
  eq(count(printed, "**The creatures.**"), 1)
  eq(count(printed, "Barrow lord —"), 1, "a creature in both versions is cited once")
  -- on the page, the version run links to its creature
  local t = party.fight(lordFight()).html
  has(t, 'href="https://wiki.example.org/adventure/World/Monsters/Barrow%20Lord"')
end)

------------------------------------------------------------------ GM Kit reads a DC written through GM Party

local VAULT = "Adventure/Campaign/Act I/Scene 6"
local VAULT_TEXT = [==[---
type: scene
scene: 6
scene_title: The Vault
book_order: 16
status: draft
---

# Scene 6 — The Vault

## The door

**Wisdom (Perception)** — what the door gives up.

| | |
|---|---|
| **Any roll** | The door is newer than the wall |
| **${party.dc(10)}** | Scratches round the lock |
| **${party.dc(15)}** | A second keyhole, under the plate: DC ${party.dc(20)} to pick |

**Strength (Athletics)**, DC ${party.dc(15)}, to force the grate.

**Intelligence (Arcana)**, on the ward.

At **${party.dc(15)}**, it was cast by someone who wanted to be caught.

**If nobody reaches the ${party.dc(15)}, it is late, not lost.** The next time they see the caster, they know.

**Wisdom (Insight)**, on the clerk.

**At ${party.dc(20)}**, she is lying about the key.

## Getting in

**Then: group Dexterity (Stealth), DC ${party.dc(12)}.** Half of them succeeding carries it.

## The shelves

Each of them rolls **Intelligence (Investigation)** for what they turn up.

| They find | Any roll | ${party.dc(10)} or better also gets |
|---|---|---|
| **The ledger** | Accounts, years of them | A name crossed out on every page |

## The yard

**Wisdom (Survival)**, DC 15, to find the way they came.
]==]

-- The vault, and a party at this level from The Party, so there are no
-- character pages to ask who rolled.
local function useVault(level)
  H.pages[VAULT] = VAULT_TEXT
  H.current = VAULT
  H.pages["The Party"] = "---\ntype: party\ncharacters: 5\nlevel: " .. level .. "\n---\n\n# The Party\n"
  party.refresh()
end

local function vaultCheck(start)
  for _, c in ipairs(gm.checks(VAULT)) do
    if c.name:find(start, 1, true) == 1 then return c end
  end
  error("no check " .. start .. " in: " .. list(names(gm.checks(VAULT))))
end

local function bandNames(check, rungs)
  local out = {}
  for _, b in ipairs(gm.bands(rungs or check.rungs, check.rise)) do out[#out + 1] = b.label end
  return list(out)
end

test("levels: a check written through party.dc reads the rung it is written as", "dm", function()
  useVault(9)
  eq(list(names(gm.checks(VAULT))), list({
    "Wisdom (Perception)", "Strength (Athletics), DC 17", "Intelligence (Arcana)", "Wisdom (Insight)",
    "Dexterity (Stealth), group, DC 14", "Intelligence (Investigation)", "Wisdom (Survival), DC 15",
  }), "a DC names the party's, and one written as a number stays as written")
  local perception = vaultCheck("Wisdom (Perception)")
  eq(perception.rise, 2)
  eq(perception.rungs[2].at, 10, "the rung as written")
  eq(perception.rungs[3].at, 15)
  eq(bandNames(perception), "Under 12 | 12 to 16 | 17 or more")
  eq(vaultCheck("Strength (Athletics)").dc, 15)
  eq(bandNames(vaultCheck("Intelligence (Arcana)")), "Under 17 | 17 or more")
  eq(vaultCheck("Intelligence (Arcana)").late, "The next time they see the caster, they know.")
  eq(bandNames(vaultCheck("Wisdom (Insight)")), "Under 22 | 22 or more", "**At ${party.dc(20)}**, too")
  local ledger = vaultCheck("Intelligence (Investigation)")
  eq(ledger.kind, "finds")
  eq(bandNames(ledger, ledger.rows[1].rungs), "Under 12 | 12 or more", "and a table's column heads")
  eq(vaultCheck("Wisdom (Survival)").rise, 0, "a check whose numbers are written as numbers doesn't rise")
end)

test("levels: at levels 1 to 4 a check written through party.dc reads as written", "dm", function()
  useVault(3)
  eq(bandNames(vaultCheck("Wisdom (Perception)")), "Under 10 | 10 to 14 | 15 or more")
  has(list(names(gm.checks(VAULT))), "Dexterity (Stealth), group, DC 12")
end)

test("levels: a roll against a DC that rises logs the party's numbers and keeps the rung", "dm", function()
  useVault(9)
  H.picks = { "Wisdom (Perception)", "17 or more" }
  gm.logRoll()
  eq(list(names(H.filterBoxes[2].options)), "Under 12 | 12 to 16 | 17 or more")
  has(H.pages["Sessions/Session 1"], "· Wisdom (Perception), 17 or more:\n" ..
    "  - The door is newer than the wall\n" ..
    "  - Scratches round the lock\n" ..
    "  - A second keyhole, under the plate: DC 22 to pick\n",
    "the words print their own DCs as the page shows them")
  has(H.pages["State/Scenes/Act I/Scene 6"], "roll_wisdom_perception: 15\n", "the play state keeps the rung as written")
  eq(lastNotification().message, "Wisdom (Perception), 17 or more: three things they know, logged to session 1.")
  has(gm.rollStanding(vaultCheck("Wisdom (Perception)"), gm.readState(VAULT, true)), "✓ Perception: [[Sessions/Session 1|17 or more]]")
  -- a level later, the same roll reads at the new level's numbers
  useVault(13)
  has(gm.rollStanding(vaultCheck("Wisdom (Perception)"), gm.readState(VAULT, true)), "|18 or more]]")

  useVault(9)
  H.picks = { "Strength (Athletics), DC 17", "Passed" }
  gm.logRoll()
  eq(H.filterBoxes[#H.filterBoxes].options[1].description, "They met or beat DC 17")
  eq(H.filterBoxes[#H.filterBoxes].options[2].description, "They rolled under DC 17")
  has(H.pages["Sessions/Session 1"], "· Strength (Athletics), DC 17: passed\n")
end)

test("levels: a rung owed on a DC that rises is owed at the party's number", "dm", function()
  useVault(9)
  H.picks = { "Intelligence (Arcana)", "Under 17" }
  gm.logRoll()
  eq(lastNotification().message,
    "Intelligence (Arcana), under 17: one thing they know, the 17 owed, logged to session 1.")
  has(H.pages["Sessions/Session 1"],
    "  - Owed: the 17, late, not lost. The next time they see the caster, they know.\n")
  has(gm.owed().markdown, "Intelligence (Arcana): the 17, owed since")
  has(gm.rollStanding(vaultCheck("Intelligence (Arcana)"), gm.readState(VAULT, true)), " · 17 owed")
  has(H.pages["State/Scenes/Act I/Scene 6"], "roll_intelligence_arcana: 0\n")
end)
