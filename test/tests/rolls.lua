------------------------------------------------------------------ Rolls (GM Kit 3.5)

-- A scene that sets a check each way a scene can write one: a ladder in a
-- table, a ladder in paragraphs, one whose own paragraph is what any roll
-- gets, a group check against a DC, a table of finds, and a check that is
-- only mentioned.
local MILL = "Adventure/Campaign/Act I/Scene 4"
local MILL_STATE = "State/Scenes/Act I/Scene 4"
local LOG1, LOG2 = "Sessions/Session 1", "Sessions/Session 2"
local MILL_TEXT = [==[---
type: scene
scene: 4
scene_title: The Mill Race
book_order: 14
status: draft
---

# Scene 4 — The Mill Race

## The bank

**Wisdom (Perception)** — what the bank gives you from the water.

| | |
|---|---|
| **Any roll** | Bootprints in the mud, heading for [Fordtown](<../../World/Places/Fordtown>) |
| **10** | One set is a child's |
| **15** | The child was running, and the bigger prints were following |
| **20** | Whoever followed stopped at the water, and went back |

**Intelligence (Investigation)** — what the wheel tells you.

| | |
|---|---|
| **10** | The wheel has been jammed on purpose |
| **15** | With a crowbar from the mill's own rack |

## The miller

**Wisdom (Insight), on the miller** — and this one pays out backwards.

**Whatever they roll, he comes back honest, because he is.** He saw nothing, and says so.

At **20**, he is frightened of somebody, and it isn't them.

**If somebody reads the ledger.** Intelligence (History) says the last ${party.n()} pages are torn out.

**At 15**, the last entry is in a different hand.

## Getting away

**Then: group Dexterity (Stealth), DC 12.** Half of them succeeding carries it.

Don't call for Wisdom (Survival) to follow the prints: they lead to the town.

## The loft

Each of them rolls **Intelligence (Investigation)** for what they turn up.

| They find | Any roll | 10 or better also gets |
|---|---|---|
| **The sack** | Flour, gone grey | A key sewn into the hem |
| **The lamp** | Cold, but lit today | |
]==]

local function useMill()
  H.pages[MILL] = MILL_TEXT
  H.current = MILL
end

local function checkNamed(name)
  for _, c in ipairs(gm.checks(MILL)) do
    if c.name == name then return c end
  end
  error("no check " .. name .. " in: " .. list(names(gm.checks(MILL))))
end

local PERCEPTION = "Wisdom (Perception)"
local WHEEL = "Intelligence (Investigation) · The bank"
local LOFT = "Intelligence (Investigation) · The loft"
local INSIGHT = "Wisdom (Insight)"
local HISTORY = "Intelligence (History)"
local STEALTH = "Dexterity (Stealth), group, DC 12"

local BANK = "[[" .. MILL .. "#The bank|Scene 4]]"

test("rolls: a scene's checks are read the way it writes them", "dm", function()
  useMill()
  local checks = gm.checks(MILL)
  eq(list(names(checks)), list({ PERCEPTION, WHEEL, INSIGHT, HISTORY, STEALTH, LOFT }),
     "page order, the two Investigations told apart by section, and Survival only mentioned")
  local p = checkNamed(PERCEPTION)
  eq(p.kind, "ladder")
  eq(p.short, "Perception")
  eq(p.section, "The bank")
  eq(p.sentence, "Wisdom (Perception) — what the bank gives you from the water.")
  eq(#p.rungs, 4)
  eq(p.rungs[1].at, 0)
  eq(p.rungs[4].text, "Whoever followed stopped at the water, and went back")
  local wheel = checkNamed(WHEEL)
  eq(wheel.rungs[1].at, 10, "a table with no floor has none")
  eq(wheel.id, "intelligence_investigation")
  eq(checkNamed(LOFT).id, "intelligence_investigation_2")
end)

test("rolls: a ladder in paragraphs gives any roll what comes before its first rung", "dm", function()
  useMill()
  local insight = checkNamed(INSIGHT)
  eq(insight.kind, "ladder")
  eq(#insight.rungs, 2)
  eq(insight.rungs[1].text,
     "**Whatever they roll, he comes back honest, because he is.** He saw nothing, and says so.")
  eq(insight.rungs[2].at, 20)
  eq(insight.rungs[2].text, "He is frightened of somebody, and it isn't them.", "with a capital")
  -- nothing between the check and its rung: the check's own paragraph is it
  local history = checkNamed(HISTORY)
  has(history.rungs[1].text, "**If somebody reads the ledger.** Intelligence (History) says")
  eq(history.rungs[2].at, 15)
  eq(history.rungs[2].text, "The last entry is in a different hand.")
end)

test("rolls: a DC with nothing under it is passed or failed, and a group check says so", "dm", function()
  useMill()
  local stealth = checkNamed(STEALTH)
  eq(stealth.kind, "dc")
  eq(stealth.dc, 12)
  eq(stealth.group, true)
  eq(checkNamed(PERCEPTION).group, false)
end)

test("rolls: a table with a column for each rung is one roll a row", "dm", function()
  useMill()
  local loft = checkNamed(LOFT)
  eq(loft.kind, "finds")
  eq(#loft.rows, 2)
  eq(loft.rows[1].name, "The sack")
  eq(loft.rows[1].key, "the_sack")
  eq(#loft.rows[1].rungs, 2)
  eq(loft.rows[1].rungs[2].at, 10)
  eq(#loft.rows[2].rungs, 1, "an empty cell is no rung")
end)

test("rolls: the bands a ladder makes", "dm", function()
  local function labels(rungs)
    local out = {}
    for _, b in ipairs(gm.bands(rungs)) do out[#out + 1] = b.label .. "=" .. #b.adds end
    return list(out)
  end
  eq(labels({ { at = 0 }, { at = 10 }, { at = 15 }, { at = 20 } }),
     "Under 10=1 | 10 to 14=1 | 15 to 19=1 | 20 or more=1")
  eq(labels({ { at = 10 }, { at = 15 } }), "Under 10=0 | 10 to 14=1 | 15 or more=1",
     "no floor rung: the lowest band gets nothing")
  eq(labels({ { at = 0 }, { at = 20 } }), "Under 20=1 | 20 or more=1")
  eq(labels({ { at = 0 }, { at = 0 } }), "Any roll=2")
end)

test("rolls: fenced code and HTML comments hold no checks, and a DM callout can", "dm", function()
  local page = "Adventure/World/Places/The Mill"
  H.pages[page] = "---\ntype: place\n---\n\n# The Mill\n\n```\n**Wisdom (Perception)**\n\n" ..
    "| **10** | not a rung |\n```\n\n<!-- Wisdom (Insight) DC 10 -->\n\n" ..
    "> **dm** The trapdoor\n> Intelligence (Investigation), DC 14, finds it under the flour.\n"
  local checks = gm.checks(page)
  eq(list(names(checks)), "Intelligence (Investigation), DC 14")
  eq(#gm.checks("Adventure/Campaign/Act I/Scene 1"), 0, "the fixture's Ford sets no check")
end)

test("rolls: a roll logs the words of every rung it reached, under Rolls", "dm", function()
  useMill()
  H.picks = { PERCEPTION, "15 to 19" }
  H.commands["GM: Log Roll"].run()
  eq(H.pages[LOG1], "---\ntype: session\nsession: 1\n---\n\n# Session 1\n\n## Scenes\n\n## Rolls\n\n" ..
     "- " .. BANK .. " · Wisdom (Perception), 15 to 19:\n" ..
     "  - Bootprints in the mud, heading for [[Adventure/World/Places/Fordtown|Fordtown]]\n" ..
     "  - One set is a child's\n" ..
     "  - The child was running, and the bigger prints were following\n\n## Decisions\n")
  has(H.pages[MILL_STATE], "roll_wisdom_perception: 15\nroll_wisdom_perception_session: 1\n")
  has(H.pages[MILL_STATE], "- [[Sessions/Session 1|Session 1]]: Wisdom (Perception), 15 to 19\n")
  eq(lastNotification().message,
     "Wisdom (Perception), 15 to 19: three things they know, logged to session 1.")
  eq(H.pages[MILL], MILL_TEXT, "and the scene itself is never touched")
  eq(H.filterBoxes[1].label, "Log a roll")
  eq(H.filterBoxes[1].help, "Scene 4 — The Mill Race: which check?")
  eq(list(names(H.filterBoxes[1].options)), list({ PERCEPTION, WHEEL, INSIGHT, HISTORY, STEALTH, LOFT, "Another roll…" }))
  eq(list(names(H.filterBoxes[2].options)), "Under 10 | 10 to 14 | 15 to 19 | 20 or more")
  eq(H.filterBoxes[2].options[1].description, "Bootprints in the mud, heading for Fordtown")
  eq(H.filterBoxes[2].options[2].description, "+ One set is a child's")
end)

test("rolls: a better roll logs only what is new, and a worse one nothing", "dm", function()
  useMill()
  H.picks = { PERCEPTION, "10 to 14" }
  gm.logRoll()
  gm.patch("Session Table", "session", 2)
  H.picks = { PERCEPTION, "20 or more" }
  gm.logRoll()
  eq(lastNotification().message,
     "Wisdom (Perception), now 20 or more: two more things they know, logged to session 2.")
  has(H.pages[LOG2], "- " .. BANK .. " · Wisdom (Perception), now 20 or more:\n" ..
      "  - The child was running, and the bigger prints were following\n" ..
      "  - Whoever followed stopped at the water, and went back\n")
  hasnt(H.pages[LOG2], "One set is a child's", "session 1 already has that")
  H.picks = { PERCEPTION, "15 to 19" }
  gm.logRoll()
  has(H.pages[LOG2], "- " .. BANK .. " · Wisdom (Perception), 15 to 19: nothing new\n")
  eq(lastNotification().message, "Wisdom (Perception), 15 to 19: nothing new, logged to session 2.")
  has(H.pages[MILL_STATE], "roll_wisdom_perception: 20\nroll_wisdom_perception_session: 2\n",
      "the state keeps the best, from the session that reached it")
  has(H.pages[MILL_STATE], "- [[Sessions/Session 2|Session 2]]: Wisdom (Perception), 15 to 19, nothing new\n")
end)

test("rolls: a band with nothing on it says so", "dm", function()
  useMill()
  H.picks = { WHEEL, "Under 10" }
  gm.logRoll()
  has(H.pages[LOG1], "- " .. BANK .. " · Intelligence (Investigation) · The bank, under 10: nothing from this check\n")
  eq(H.filterBoxes[2].options[1].description, "Nothing from this check")
end)

test("rolls: undo takes back the roll, its Rolls heading and a log it began", "dm", function()
  useMill()
  H.picks = { PERCEPTION, "Under 10" }
  gm.logRoll()
  ok(H.pages[LOG1], "the roll should have begun the log")
  runAction(lastNotification(), "Undo")
  eq(H.pages[LOG1], nil, "and undo should take it away again")
  eq(H.pages[MILL_STATE], nil, "with the play state it began")
  eq(lastNotification().message, "Undone: Wisdom (Perception), under 10 is no longer logged")

  H.prompts = { "Waded across" }
  H.commands["GM: Log Decision"].run()
  H.picks = { PERCEPTION, "Under 10" }
  gm.logRoll()
  runAction(lastNotification(), "Undo")
  eq(H.pages[LOG1], "---\ntype: session\nsession: 1\n---\n\n# Session 1\n\n## Scenes\n\n" ..
     "## Decisions\n\n- Waded across\n", "a log that was there keeps what it had, and no empty Rolls")
end)

test("rolls: undo of a later roll leaves the one before it", "dm", function()
  useMill()
  H.picks = { PERCEPTION, "10 to 14" }
  gm.logRoll()
  H.picks = { PERCEPTION, "20 or more" }
  gm.logRoll()
  runAction(lastNotification(), "Undo")
  has(H.pages[MILL_STATE], "roll_wisdom_perception: 10\n")
  has(H.pages[LOG1], "One set is a child's")
  hasnt(H.pages[LOG1], "now 20 or more")
end)

test("rolls: rolls, scenes and decisions keep to their own sections", "dm", function()
  useMill()
  gm.mark(MILL, "started")
  H.picks = { STEALTH, "Failed" }
  gm.logRoll()
  H.prompts = { "Ran for the town" }
  H.commands["GM: Log Decision"].run()
  H.picks = { INSIGHT, "Under 20" }
  gm.logRoll()
  eq(H.pages[LOG1], "---\ntype: session\nsession: 1\n---\n\n# Session 1\n\n## Scenes\n\n" ..
     "- Started: [[" .. MILL .. "|Scene 4 — The Mill Race]]\n\n## Rolls\n\n" ..
     "- [[" .. MILL .. "#Getting away|Scene 4]] · Dexterity (Stealth), group, DC 12: failed\n" ..
     "- [[" .. MILL .. "#The miller|Scene 4]] · Wisdom (Insight), under 20:\n" ..
     "  - **Whatever they roll, he comes back honest, because he is.** He saw nothing, and says so.\n\n" ..
     "## Decisions\n\n- Ran for the town\n")
end)

test("rolls: a DC check is passed or failed, and the bar says which", "dm", function()
  useMill()
  H.picks = { STEALTH, "Failed" }
  gm.logRoll()
  eq(lastNotification().message, "Dexterity (Stealth), group, DC 12: failed, logged to session 1.")
  has(H.pages[MILL_STATE], "roll_dexterity_stealth: failed\n")
  has(H.pages[MILL_STATE], "- [[Sessions/Session 1|Session 1]]: Dexterity (Stealth), group, DC 12, failed\n")
  eq(list(names(H.filterBoxes[2].options)), "Passed | Failed")
  eq(H.filterBoxes[2].options[1].description, "Half of them or more made it")
  has(textOf(gm.bar().html), "✗ Stealth: [[Sessions/Session 1|failed]]")
  H.picks = { STEALTH, "Passed" }
  gm.logRoll()
  has(H.pages[MILL_STATE], "roll_dexterity_stealth: passed\n", "a DC keeps the latest, not the best")
  has(textOf(gm.bar().html), "✓ Stealth: [[Sessions/Session 1|passed]]")
end)

test("rolls: a table of finds asks which thing, then how high", "dm", function()
  useMill()
  H.picks = { LOFT, "The sack", "10 or more" }
  gm.logRoll()
  has(H.pages[LOG1], "- [[" .. MILL .. "#The loft|Scene 4]] · Intelligence (Investigation) · The loft, " ..
      "The sack, 10 or more:\n  - Flour, gone grey\n  - A key sewn into the hem\n")
  has(H.pages[MILL_STATE], "roll_intelligence_investigation_2_the_sack: 10\n")
  eq(list(names(H.filterBoxes[2].options)), "The sack | The lamp")
  eq(list(names(H.filterBoxes[3].options)), "Under 10 | 10 or more")
  has(textOf(gm.bar().html), "✓ Investigation: 1 of 2 found")
  H.picks = { LOFT, "The lamp", "Any roll" }
  gm.logRoll()
  has(H.pages[LOG1], "The loft, The lamp, any roll:\n  - Cold, but lit today\n")
  eq(list(names(H.filterBoxes[#H.filterBoxes].options)), "Any roll", "one rung, one band")
  has(textOf(gm.bar().html), "✓ Investigation: 2 of 2 found")
end)

test("rolls: live values print, and a ladder's own paragraph gets any roll", "dm", function()
  useMill()
  H.picks = { HISTORY, "15 or more" }
  gm.logRoll()
  local log = H.pages[LOG1]
  has(log, "- [[" .. MILL .. "#The miller|Scene 4]] · Intelligence (History), 15 or more:\n")
  has(log, "  - **If somebody reads the ledger.** Intelligence (History) says the last five pages are torn out.\n")
  has(log, "  - The last entry is in a different hand.\n")
  hasnt(log, "${", "a live value goes in as it reads")
end)

test("rolls: who rolled is asked once there are characters, the party first", "dm", function()
  useMill()
  useParty(3, 1, 1)
  H.picks = { PERCEPTION, "15 to 19", "PC 03" }
  gm.logRoll()
  local who = H.filterBoxes[3]
  eq(who.label, "Who rolled?")
  eq(list(names(who.options)), "The party | PC 02 | PC 03", "the one away tonight can't roll")
  has(H.pages[LOG1], "· Wisdom (Perception), 15 to 19, PC 03:\n")
  eq(lastNotification().message,
     "Wisdom (Perception), 15 to 19, PC 03: three things they know, logged to session 1.")
  H.picks = { INSIGHT, "20 or more", "The party" }
  gm.logRoll()
  has(H.pages[LOG1], "· Wisdom (Insight), 20 or more, the party:\n")
  -- a group check is everybody's, so nobody is asked
  local asked = #H.filterBoxes
  H.picks = { STEALTH, "Passed" }
  gm.logRoll()
  eq(#H.filterBoxes, asked + 2)
end)

test("rolls: no character pages, nobody is asked who", "dm", function()
  useMill()
  eq(#gm.rollers(), 0)
  H.picks = { PERCEPTION, "Under 10" }
  gm.logRoll()
  eq(#H.filterBoxes, 2)
  eq(#H.picks, 0)
end)

test("rolls: cancelling any question logs nothing", "dm", function()
  useMill()
  H.picks = { PERCEPTION, NIL }
  eq(gm.logRoll(), false)
  H.picks = { NIL }
  eq(gm.logRoll(), false)
  useParty(2, 1)
  H.picks = { PERCEPTION, "10 to 14", NIL }
  eq(gm.logRoll(), false)
  eq(H.pages[LOG1], nil)
  eq(H.pages[MILL_STATE], nil)
end)

test("rolls: another roll is any skill or save, and what they got in their words", "dm", function()
  useMill()
  H.picks = { "Another roll…", "Wisdom (Survival)" }
  H.prompts = { "14: the prints are a day old" }
  gm.logRoll()
  has(H.pages[LOG1], "## Rolls\n\n- [[" .. MILL .. "|Scene 4]] · Wisdom (Survival): 14: the prints are a day old\n")
  eq(H.promptsAsked[1], "Wisdom (Survival): what did they get? (session 1)")
  eq(lastNotification().message, "Wisdom (Survival): logged to session 1.")
  eq(H.pages[MILL_STATE], nil, "a roll the page doesn't set has no state to keep")
  local all = names(H.filterBoxes[2].options)
  eq(#all, 30, "eighteen skills, six saves and six ability checks")
  eq(all[19], "Strength saving throw")
  eq(all[30], "Charisma check")
  runAction(lastNotification(), "Undo")
  eq(H.pages[LOG1], nil)
  H.picks = { "Another roll…", "Wisdom (Survival)" }
  H.prompts = { "  " }
  eq(gm.logRoll(), false, "nothing said, nothing logged")
end)

test("rolls: from the Session Table, the scene the session is on", "dm", function()
  useMill()
  gm.mark(MILL, "started")
  H.current = "Session Table"
  H.picks = { STEALTH, "Passed" }
  H.commands["GM: Log Roll"].run()
  has(H.pages[LOG1], "Dexterity (Stealth), group, DC 12: passed")
  -- a person's page mid-scene is still the scene's roll
  H.current = "Adventure/World/People/Mara"
  H.picks = { PERCEPTION, "Under 10" }
  gm.logRoll()
  has(H.pages[LOG1], BANK .. " · Wisdom (Perception), under 10:")
end)

test("rolls: a scene that sets no check goes straight to another roll", "dm", function()
  H.current = "Adventure/Campaign/Act I/Scene 1"
  H.picks = { "Charisma (Persuasion)" }
  H.prompts = { "The ferryman lets them cross for free" }
  gm.logRoll()
  eq(H.filterBoxes[1].label, "Another roll")
  has(H.pages[LOG1], "- [[Adventure/Campaign/Act I/Scene 1|Scene 1]] · Charisma (Persuasion): " ..
      "The ferryman lets them cross for free\n")
  -- with no scene anywhere, the line names none
  H.current = "Session Table"
  H.picks = { "Dexterity saving throw" }
  H.prompts = { "Failed, and fell in" }
  gm.logRoll()
  has(H.pages[LOG1], "- Dexterity saving throw: Failed, and fell in\n")
end)

test("rolls: a page's bar has a row for its checks", "dm", function()
  useMill()
  local text = textOf(gm.bar().html)
  has(text, "**Checks**")
  has(text, "○ Perception")
  has(text, "○ Investigation")
  has(text, "○ Stealth")
  eq(list(buttonsOf(gm.bar().html)), "Reveal | Reveal part… | Mark planned | Mark started | Log a roll…")
  H.picks = { PERCEPTION, "15 to 19" }
  click(gm.bar(), "Log a roll…")
  text = textOf(gm.bar().html)
  has(text, "✓ Perception: [[Sessions/Session 1|15 to 19]]")
  eq(list(buttonsOf(gm.bar().html)),
     "Reveal | Reveal part… | Mark planned | Mark started | Log a roll… | Unlog a roll…")
  -- the picker says how each check stands
  H.picks = { NIL }
  gm.logRoll()
  local hints = H.filterBoxes[#H.filterBoxes].options
  eq(hints[1].hint, "✓ 15 to 19, session 1")
  eq(hints[2].hint, nil)
  -- and a page that sets none has no row
  hasnt(textOf(gm.bar("Adventure/Campaign/Act I/Scene 1").html), "Checks")
end)

test("rolls: unlog takes a roll off, the logs say so, and undo puts it back", "dm", function()
  useMill()
  H.picks = { PERCEPTION, "20 or more" }
  gm.logRoll()
  gm.patch("Session Table", "session", 2)
  H.picks = { PERCEPTION }
  click(gm.bar(), "Unlog a roll…")
  local picker = H.filterBoxes[#H.filterBoxes]
  eq(picker.label, "Unlog a roll")
  eq(picker.options[1].description, "20 or more, session 1")
  hasnt(H.pages[MILL_STATE], "roll_wisdom_perception")
  has(H.pages[MILL_STATE], "- [[Sessions/Session 2|Session 2]]: Wisdom (Perception), not rolled after all\n")
  has(H.pages[LOG2], "## Rolls\n\n- " .. BANK .. " · Wisdom (Perception): not rolled after all\n")
  has(H.pages[LOG1], "Whoever followed stopped at the water", "the session it was rolled in keeps what it said")
  eq(lastNotification().message, "Wisdom (Perception): no longer logged.")
  eq(list(buttonsOf(gm.bar().html)), "Reveal | Reveal part… | Mark planned | Mark started | Log a roll…")
  runAction(lastNotification(), "Undo")
  has(H.pages[MILL_STATE], "roll_wisdom_perception: 20\nroll_wisdom_perception_session: 1\n")
  hasnt(H.pages[MILL_STATE], "not rolled after all")
  eq(H.pages[LOG2], nil, "undo takes back the log the unlog began")
  -- rolled again after an unlog, it counts afresh
  H.picks = { PERCEPTION }
  gm.pickUnlog(MILL)
  H.picks = { PERCEPTION, "10 to 14" }
  gm.logRoll()
  has(H.pages[LOG2], "· Wisdom (Perception), 10 to 14:\n  - Bootprints")
end)

test("rolls: nothing to unlog says so", "dm", function()
  useMill()
  eq(gm.pickUnlog(MILL), false)
  eq(lastNotification().message, "Scene 4: no rolls logged to take back")
  H.current = "Session Table"
  H.commands["GM: Unlog Roll"].run()
  eq(lastNotification().message, "There is no page here with rolls to take back")
end)

test("rolls: the command, its key and the header button", "dm", function()
  eq(H.commands["GM: Log Roll"].key, "Ctrl-Alt-k", "Ctrl-Alt-r is SilverBullet's System: Reload")
  ok(H.commands["GM: Unlog Roll"])
  local found
  for _, b in ipairs(config.get("actionButtons")) do
    if b.command == "GM: Log Roll" then found = b end
  end
  ok(found, "a header button logs a roll")
  eq(found.icon, "hexagon")
  eq(found.description, "Log a roll")
end)

test("rolls: a section goes in ahead of the one named, and comes out again when empty", "dm", function()
  local t = gm.sessionTemplate(3)
  local one = gm.appendUnder(t, "Rolls", "a:\n  - b", "Decisions")
  eq(one, "---\ntype: session\nsession: 3\n---\n\n# Session 3\n\n## Scenes\n\n## Rolls\n\n- a:\n  - b\n\n## Decisions\n")
  local two = gm.appendUnder(one, "Rolls", "c", "Decisions")
  has(two, "## Rolls\n\n- a:\n  - b\n- c\n\n## Decisions\n")
  eq(gm.dropEmptySection(one, "Rolls"), one, "a section with a line in it stays")
  eq(gm.dropEmptySection((gm.removeItem(one, "a:\n  - b")), "Rolls"), t)
  eq(gm.appendUnder("# X\n", "Rolls", "a", "Decisions"), "# X\n\n## Rolls\n\n- a\n", "no Decisions: at the end")
end)

test("rolls: a rung's links still go where they went, from the log", "dm", function()
  eq(gm.rollText(MILL, "See [the map](https://example.org/map), ![a](<x.png>) and [Fordtown](<../../World/Places/Fordtown>)"),
     "See [the map](https://example.org/map), ![a](<x.png>) and [[Adventure/World/Places/Fordtown|Fordtown]]")
  eq(gm.rollText(MILL, "[the Warden](<../../World/People/The Warden#At the Table>)"),
     "[[Adventure/World/People/The Warden#At the Table|the Warden]]", "a section comes too")
  eq(gm.rollText(MILL, "[notes](Notes/Here) and [top](</World/Items/Lantern>)"),
     "[[Adventure/Campaign/Act I/Notes/Here|notes]] and [[World/Items/Lantern|top]]",
     "a link from the page's own folder, and one from the space's root")
end)

------------------------------------------------------------------ Late, not lost (GM Kit 3.6)

local WEIR = "Adventure/Campaign/Act I/Scene 5"
local WEIR_TEXT = [==[---
type: scene
scene: 5
scene_title: The Weir
book_order: 15
---

# Scene 5 — The Weir

## The weir

**Intelligence (Arcana)**, on the weir, only for a character with magic of their own.

| | |
|---|---|
| **No roll** | Something old holds the water back |
| **10** | It was made, not grown |
| **20** | Whoever made it is still paying for it |

**If nobody reaches the 20, it is late, not lost.** The next time that character crosses running water, it comes back to them.

**Wisdom (Perception)** — the far bank.

| | |
|---|---|
| **Any roll** | A path |
| **15** | Somebody walked it today |

## The keeper

**Wisdom (Insight)**, on the keeper.

**If nobody reaches the 15, it is late and not lost:** they see it the next time he lies.

At **15**, he has been paid to keep them here.
]==]
local WEIR_WATER = "[[" .. WEIR .. "#The weir|Scene 5]]"
local ARCANA = "Intelligence (Arcana)"

local function useWeir()
  H.pages[WEIR] = WEIR_TEXT
  H.current = WEIR
end

test("rolls: a page that calls its top rung late, not lost says when it comes back", "dm", function()
  useWeir()
  local checks = gm.checks(WEIR)
  eq(list(names(checks)), "Intelligence (Arcana) | Wisdom (Perception) | Wisdom (Insight)")
  eq(checks[1].late, "The next time that character crosses running water, it comes back to them.")
  eq(checks[2].late, nil, "the bank's ladder says nothing of it")
  eq(checks[3].late, "they see it the next time he lies.", "said in the middle of a sentence")
  eq(checks[3].rungs[1].text, "**Wisdom (Insight)**, on the keeper.",
     "and the sentence that says so is not what any roll gets")
end)

test("rolls: a roll below a late rung logs it owed, and a roll that reaches it clears it", "dm", function()
  useWeir()
  eq(gm.owed().markdown, "Nothing is owed.", "nothing rolled, nothing owed")
  H.picks = { ARCANA, "10 to 19" }
  gm.logRoll()
  has(H.pages[LOG1], "- " .. WEIR_WATER .. " · Intelligence (Arcana), 10 to 19:\n" ..
      "  - Something old holds the water back\n  - It was made, not grown\n" ..
      "  - Owed: the 20, late, not lost. The next time that character crosses running water, it comes back to them.\n")
  eq(lastNotification().message,
     "Intelligence (Arcana), 10 to 19: two things they know, the 20 owed, logged to session 1.")
  has(textOf(gm.bar().html), "✓ Arcana: [[Sessions/Session 1|10 to 19]] · 20 owed")
  eq(gm.owed().markdown, "- " .. WEIR_WATER .. " · Intelligence (Arcana): the 20, owed since " ..
     "[[Sessions/Session 1|session 1]]. The next time that character crosses running water, it comes back to them.")
  eq(gm.owed().display, "block")
  -- the picker says so, on the check and on the band
  gm.patch("Session Table", "session", 2)
  H.picks = { ARCANA, "20 or more" }
  gm.logRoll()
  local checks, bands = H.filterBoxes[#H.filterBoxes - 1], H.filterBoxes[#H.filterBoxes]
  eq(checks.options[1].hint, "✓ 10 to 19, session 1, 20 owed")
  eq(bands.options[2].hint, "✓ so far")
  eq(bands.options[3].hint, "owed")
  has(H.pages[LOG2], "- " .. WEIR_WATER .. " · Intelligence (Arcana), now 20 or more:\n" ..
      "  - Whoever made it is still paying for it\n")
  hasnt(H.pages[LOG2], "Owed:", "reached, so owed no more")
  eq(gm.owed().markdown, "Nothing is owed.")
  hasnt(textOf(gm.bar().html), "owed")
end)

test("rolls: only a late check's top rung is owed, and a roll that adds nothing repeats nothing", "dm", function()
  useWeir()
  H.picks = { "Wisdom (Perception)", "Under 15" }
  gm.logRoll()
  hasnt(H.pages[LOG1], "Owed:", "the bank's ladder isn't late, not lost")
  H.picks = { ARCANA, "Under 10" }
  gm.logRoll()
  has(H.pages[LOG1], "Intelligence (Arcana), under 10:\n  - Something old holds the water back\n" ..
      "  - Owed: the 20, late, not lost.")
  H.picks = { ARCANA, "Under 10" }
  gm.logRoll()
  has(H.pages[LOG1], "Intelligence (Arcana), under 10: nothing new\n")
  eq(count(H.pages[LOG1], "Owed:"), 1, "said once")
  eq(#gm.owedRungs(), 1)
end)

test("rolls: unlogging a roll takes what it owed with it, and undo brings it back", "dm", function()
  useWeir()
  H.picks = { ARCANA, "10 to 19" }
  gm.logRoll()
  H.picks = { ARCANA }
  gm.pickUnlog(WEIR)
  eq(gm.owed().markdown, "Nothing is owed.")
  runAction(lastNotification(), "Undo")
  eq(#gm.owedRungs(), 1)
  eq(gm.owedRungs()[1].at, 20)
  eq(gm.owedRungs()[1].since, "1")
end)

test("rolls: the owed list runs in the adventure's order, across its pages", "dm", function()
  useMill()
  useWeir()
  H.pages[MILL] = MILL_TEXT .. "\n## The mark\n\n**Intelligence (Arcana)** — the mark on the wheel.\n\n" ..
    "| | |\n|---|---|\n| **Any roll** | It is fresh |\n| **15** | It is a warning |\n\n" ..
    "**If nobody reaches it, it is late and not lost.**\n"
  H.picks = { ARCANA, "10 to 19" }
  gm.logRoll(WEIR)
  H.picks = { "Intelligence (Arcana)", "Under 15" }
  gm.logRoll(MILL)
  local owed = gm.owedRungs()
  eq(#owed, 2)
  eq(owed[1].page, MILL, "Scene 4 before Scene 5")
  eq(owed[2].page, WEIR)
  eq(owed[1].when, "", "a page that says only that it is late")
  local lines = gm.owed().markdown
  has(lines, "· Intelligence (Arcana): the 15, owed since [[Sessions/Session 1|session 1]]\n- ")
  has(H.pages["Session Table"], "${gm.owed()}", "the session table lists them")
end)
