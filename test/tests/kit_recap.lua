------------------------------------------------------------------ The players' recap
-- GM: Draft Recap drafts a session's recap for the players from what GM
-- Kit recorded in it, naming only what they may know; the DM edits it, and
-- GM: Publish Recap sends it to Player/Sessions/Session N.

local C_POOL = "Adventure/Campaign/Act I/Scene 4"
local C_MARA = "Adventure/World/People/Mara"
local C_WARDEN = "Adventure/World/People/The Warden"
local C_WREN = "Adventure/World/People/Wren"
local C_TAM = "Adventure/World/People/Old Tam"
local C_FORD = "Adventure/World/Places/Fordtown"
local C_LANTERN = "Adventure/World/Items/Lantern"
local C_SCENE2 = "Adventure/Campaign/Act I/Scene 2"
local C_DRAFT1, C_DRAFT2 = "Sessions/Session 1 Recap", "Sessions/Session 2 Recap"
local C_COPY1, C_COPY2 = "Player/Sessions/Session 1", "Player/Sessions/Session 2"
local C_LOG1 = "Sessions/Session 1"
local C_NL = string.char(10)

-- A scene that sets a ladder, whose top rung comes back later, with a
-- link on its first rung and DM-only words on its second, and a DC check.
local C_POOL_TEXT = table.concat({
  "---", "type: scene", "scene: 4", "scene_title: The Mill Pool", "book_order: 14", "---", "",
  "# Scene 4 — The Mill Pool", "",
  "## The bank", "",
  "**Wisdom (Perception)** — what the bank gives you.", "",
  "| | |", "|---|---|",
  "| **Any roll** | Bootprints in the mud, heading for [Fordtown](<../../World/Places/Fordtown>) |",
  "| **10** | One set is a child's <span class=\"dm\">(Wren's)</span> |",
  "| **20** | The child was running |", "",
  "If nobody reaches the 20, it is late, not lost. The next time they cross the ford, it comes back.", "",
  "## The sluice", "",
  "**Then: Strength (Athletics), DC 13.** The gate gives, or it doesn't.", "",
}, C_NL)

local function cPublish()
  H.confirms = { true }
  return gm.publish()
end

-- Session 1 as the table played it: Mara met and published, the Warden
-- met but not published yet, Wren met without learning who she is,
-- Fordtown visited, the lantern found and used, two rolls and three
-- decisions, one of them the DM's alone.
local function playSession()
  H.pages[C_POOL] = C_POOL_TEXT
  H.pages[C_WREN] = H.pages[C_WREN]:gsub("status: stub\n", "status: stub\nreveal_first: none\n", 1)
  ok(gm.mark(C_MARA, "met"))
  ok(gm.mark(C_FORD, "visited"))
  ok(gm.markFound(C_LANTERN, C_SCENE2))
  ok(gm.reveal(C_LANTERN))
  cPublish()
  ok(gm.mark(C_WARDEN, "met"))
  ok(gm.mark(C_WREN, "met"))
  ok(gm.spend(C_LANTERN, -1))
  H.picks = { "Wisdom (Perception)", "10 to 19" }
  ok(gm.logRoll(C_POOL))
  H.picks = { "Another roll…", "Wisdom saving throw" }
  H.prompts = { "a 17, and shrugged it off" }
  ok(gm.logRoll(C_POOL))
  H.prompts = { "Took [[" .. C_MARA .. "|Mara]]'s deal" }
  ok(gm.logDecision())
  H.prompts = { "Burned the map <span class=\"dm\">(the Warden's copy)</span>" }
  ok(gm.logDecision())
  H.prompts = { "<!--#dm--> Told the Warden everything" }
  ok(gm.logDecision())
end

local C_DRAFT_TEXT = table.concat({
  "---", "type: recap-draft", "session: 1", "---", "",
  "# Session 1", "",
  "## Met", "",
  "- [Mara](<../Player/World/People/Mara>)",
  "- The Warden", "",
  "## Visited", "",
  "- [Fordtown](<../Player/World/Places/Fordtown>)", "",
  "## Found", "",
  "- [Lantern](<../Player/World/Items/Lantern>): 5 of 6 wicks left", "",
  "## Rolls", "",
  "- Wisdom (Perception), 10 to 19:",
  "  - Bootprints in the mud, heading for [Fordtown](<../Player/World/Places/Fordtown>)",
  "  - One set is a child's",
  "- Wisdom saving throw: a 17, and shrugged it off", "",
  "## Decisions", "",
  "- Took [Mara](<../Player/World/People/Mara>)'s deal",
  "- Burned the map", "",
}, C_NL)

test("recap: drafted from what the session recorded, naming only what the players may know", "dm", function()
  playSession()
  ok(gm.draftRecap(1))
  eq(H.pages[C_DRAFT1], C_DRAFT_TEXT)
  eq(H.current, C_DRAFT1, "and opened, to edit")
  local n = lastNotification()
  eq(n.message, "Drafted the players' recap of session 1: 2 met, 1 visited, 1 found, 2 rolls, 2 decisions. " ..
     "Edit it, then publish it from its bar. Left unnamed: 1 page the players may not know by name.")
  for name in pairs(H.pages) do
    ok(name == C_DRAFT1 or not name:find("Recap"), "only the draft: " .. name)
  end
  eq(H.pages[C_COPY1], nil, "nothing goes to the players until it is published")
end)

test("recap: a page the players may not know stays out, however it was marked", "dm", function()
  local heir = "Adventure/World/People/The Heir"
  H.pages[heir] = "---\ntype: npc\n---\n\n<!--#dm-->\n# The Heir\n<!--/dm-->\n\nThe Warden's son.\n"
  gm.mark(heir, "met")
  gm.markFound(C_LANTERN, C_SCENE2)
  gm.mark(C_TAM, "met")
  gm.draftRecap(1)
  local draft = H.pages[C_DRAFT1]
  hasnt(draft, "Heir", "a name that is DM-only")
  hasnt(draft, "Lantern", "an item found but not revealed: the party may not know what it is")
  has(draft, "## Met\n\n- Old Tam\n", "revealed by name, not published yet: words")
  has(lastNotification().message, "Left unnamed: 2 pages the players may not know by name.")
end)

test("recap: rolls keep their words, not what is owed, a roll that got nothing, or one taken back", "dm", function()
  H.pages[C_POOL] = C_POOL_TEXT
  H.picks = { "Wisdom (Perception)", "10 to 19" }
  gm.logRoll(C_POOL)
  H.picks = { "Wisdom (Perception)", "Under 10" }
  gm.logRoll(C_POOL)
  H.picks = { "Strength (Athletics), DC 13", "Passed" }
  gm.logRoll(C_POOL)
  H.picks = { "Strength (Athletics), DC 13" }
  gm.pickUnlog(C_POOL)
  H.picks = { "Strength (Athletics), DC 13", "Failed" }
  gm.logRoll(C_POOL)
  local log = H.pages[C_LOG1]
  has(log, "Wisdom (Perception), under 10: nothing new")
  has(log, "Owed: the 20")
  has(log, "Strength (Athletics), DC 13: not rolled after all")
  gm.draftRecap(1)
  has(H.pages[C_DRAFT1], table.concat({
    "## Rolls", "",
    "- Wisdom (Perception), 10 to 19:",
    "  - Bootprints in the mud, heading for Fordtown",
    "  - One set is a child's",
    "- Strength (Athletics), DC 13: failed", "",
  }, C_NL), "Fordtown is words: the players have no copy of it")
  hasnt(H.pages[C_DRAFT1], "passed")
  hasnt(H.pages[C_DRAFT1], "Owed")
  hasnt(H.pages[C_DRAFT1], "Scene 4", "the scene's name is the DM's")
end)

test("recap: DM-only text never enters, and a mark it can't take out keeps the line out", "dm", function()
  H.prompts = { "Crossed at dusk <span class=\"dm\">(the Warden saw them)</span>" }
  gm.logDecision()
  H.prompts = { "> **dm** The Warden saw them" }
  gm.logDecision()
  H.prompts = { "Paid the ferry <span class=\"dm\" the rest is broken" }
  gm.logDecision()
  H.prompts = { "Swore to find the crown" }
  gm.logDecision()
  gm.draftRecap(1)
  local draft = H.pages[C_DRAFT1]
  has(draft, "## Decisions\n\n- Crossed at dusk\n- Swore to find the crown\n")
  hasnt(draft, "Warden")
  hasnt(draft, "ferry", "the tag the scanner can't read fails closed")
  eq(#gm.dmMarks(draft), 0)
  has(lastNotification().message, "Left out: 1 line with a DM-only mark.")
end)

test("recap: a session with nothing recorded gets a draft to write in", "dm", function()
  ok(gm.draftRecap(1))
  eq(H.pages[C_DRAFT1], "---\ntype: recap-draft\nsession: 1\n---\n\n# Session 1\n")
  eq(lastNotification().message, "Drafted the players' recap of session 1, with nothing in it: GM Kit recorded " ..
     "nothing the players may know in it. Write it yourself, then publish it from its bar.")
end)

test("recap: only what the session itself recorded", "dm", function()
  gm.mark(C_MARA, "met")
  H.prompts = { "Took Mara's deal" }
  gm.logDecision()
  H.confirms = { true }
  gm.nextSession()
  gm.mark(C_FORD, "visited")
  H.prompts = { "Rested in Fordtown" }
  gm.logDecision()
  gm.draftRecap(2)
  local draft = H.pages[C_DRAFT2]
  has(draft, "---\ntype: recap-draft\nsession: 2\n---\n\n# Session 2\n")
  has(draft, "## Visited\n\n- Fordtown\n")
  has(draft, "## Decisions\n\n- Rested in Fordtown\n")
  hasnt(draft, "Mara")
  ok(gm.draftRecap(1))
  has(H.pages[C_DRAFT1], "## Met\n\n- Mara\n")
  has(H.pages[C_DRAFT1], "## Decisions\n\n- Took Mara's deal\n")
end)

test("recap: drafting again asks before it replaces the draft, and Undo puts it back", "dm", function()
  gm.mark(C_MARA, "met")
  gm.draftRecap(1)
  local fresh = H.pages[C_DRAFT1]
  local writes = #H.writes
  eq(gm.draftRecap(1), false)
  eq(#H.writes, writes, "nothing new: nothing written")
  eq(lastNotification().message, "The recap of session 1 is drafted already, and nothing recorded since changes it.")
  local edited = fresh .. "\nThe party slept badly.\n"
  H.pages[C_DRAFT1] = edited
  H.confirms = { false }
  eq(gm.draftRecap(1), false)
  eq(H.confirmsAsked[#H.confirmsAsked], "Draft the recap of session 1 afresh? It replaces " ..
     "Sessions/Session 1 Recap, and any change you made to it.")
  eq(H.pages[C_DRAFT1], edited, "declined, the edits stay")
  H.confirms = { true }
  ok(gm.draftRecap(1))
  eq(H.pages[C_DRAFT1], fresh)
  runAction(lastNotification(), "Undo")
  eq(H.pages[C_DRAFT1], edited, "Undo puts the edited draft back")
  H.pages[C_DRAFT1] = nil
  gm.draftRecap(1)
  runAction(lastNotification(), "Undo")
  eq(H.pages[C_DRAFT1], nil, "and takes a new draft away")
end)

test("recap: published as the players' page, with only its type, and links that work from there", "dm", function()
  playSession()
  gm.draftRecap(1)
  H.confirms = { true }
  ok(gm.publishRecap(C_DRAFT1))
  eq(H.confirmsAsked[#H.confirmsAsked], "Publish the recap of session 1 to the players, as " ..
     "Player/Sessions/Session 1?")
  eq(H.pages[C_COPY1], table.concat({
    "---", "type: recap", "---", "",
    "# Session 1", "",
    "## Met", "",
    "- [Mara](<../World/People/Mara>)",
    "- The Warden", "",
    "## Visited", "",
    "- [Fordtown](<../World/Places/Fordtown>)", "",
    "## Found", "",
    "- [Lantern](<../World/Items/Lantern>): 5 of 6 wicks left", "",
    "## Rolls", "",
    "- Wisdom (Perception), 10 to 19:",
    "  - Bootprints in the mud, heading for [Fordtown](<../World/Places/Fordtown>)",
    "  - One set is a child's",
    "- Wisdom saving throw: a 17, and shrugged it off", "",
    "## Decisions", "",
    "- Took [Mara](<../World/People/Mara>)'s deal",
    "- Burned the map", "",
  }, C_NL))
  eq(lastNotification().message, "Published the recap of session 1 to the players, as Player/Sessions/Session 1.")
  eq(H.pages[C_DRAFT1], C_DRAFT_TEXT, "the draft stays as it was")
end)

test("recap: what the DM writes into the draft goes as the players can follow it", "dm", function()
  gm.writeRevealed({ C_MARA })
  cPublish()
  H.pages[C_DRAFT1] = table.concat({
    "---", "type: recap-draft", "session: 1", "---", "",
    "# Session 1", "",
    "The ${party.n()} of them met [Mara](<../Player/World/People/Mara>) and [[" .. C_MARA .. "|the ferrywoman]],",
    "saw [the Warden](<../Adventure/World/People/The Warden>) and [[Old Tam]], read [[Sessions/Session 1|the log]],",
    "and looked at [the map](https://example.org/map).",
    "",
    "![[" .. C_WARDEN .. "]]",
    "",
    "`[[Old Tam]]` stays code.",
  }, C_NL)
  H.confirms = { true }
  ok(gm.publishRecap(C_DRAFT1))
  eq(H.pages[C_COPY1], table.concat({
    "---", "type: recap", "---", "",
    "# Session 1", "",
    "The five of them met [Mara](<../World/People/Mara>) and [the ferrywoman](<../World/People/Mara>),",
    "saw the Warden and Old Tam, read the log,",
    "and looked at [the map](https://example.org/map).",
    "",
    "`[[Old Tam]]` stays code.", "",
  }, C_NL))
end)

test("recap: a draft with a DM-only mark isn't published", "dm", function()
  H.pages[C_DRAFT1] = "---\ntype: recap-draft\nsession: 1\n---\n\n# Session 1\n\n" ..
    "> **dm** Don't tell them\n> The Warden was watching.\n\nThey crossed at dusk.\n"
  H.current = C_DRAFT1
  local bar = gm.sessionBar()
  has(textOf(bar.html), "⚠ Has DM-only marks, so it can't be published: a dm callout")
  eq(list(buttonsOf(bar.html)), "")
  local writes = #H.writes
  eq(gm.publishRecap(C_DRAFT1), false)
  eq(#H.writes, writes)
  eq(H.pages[C_COPY1], nil)
  eq(#H.confirmsAsked, 0)
  local n = lastNotification()
  eq(n.kind, "warning")
  eq(n.message, "Not published: the recap still has DM-only marks (a dm callout). Take them out of " ..
     "Sessions/Session 1 Recap, then publish it.")
  H.pages[C_DRAFT1] = "---\ntype: recap-draft\nsession: 1\n---\n\n# Session 1\n\n<div class='dm'>\n\nThe Warden.\n"
  eq(gm.publishRecap(C_DRAFT1), false)
  has(lastNotification().message, "(an element of class dm)")
end)

test("recap: a live value that prints a DM-only mark keeps the recap back too", "dm", function()
  -- nothing in the draft as written says dm: only what the expression prints does
  H.pages[C_DRAFT1] = "---\ntype: recap-draft\nsession: 1\n---\n\n# Session 1\n\n" ..
    "They met ${widget.markdown(\"<span cl\" .. \"ass='dm'>the heir</span>\")}.\n"
  eq(#gm.dmMarks(H.pages[C_DRAFT1]), 0, "the draft as written holds no mark")
  has(textOf(gm.sessionBar(C_DRAFT1).html), "⚠ Has DM-only marks, so it can't be published: an element of class dm")
  eq(gm.publishRecap(C_DRAFT1), false)
  eq(H.pages[C_COPY1], nil)
  has(lastNotification().message, "Not published: the recap still has DM-only marks (an element of class dm)")
end)

test("recap: Undo takes the players' copy away, or puts back the one they had", "dm", function()
  H.pages[C_DRAFT1] = "---\ntype: recap-draft\nsession: 1\n---\n\n# Session 1\n\nThey crossed at dusk.\n"
  H.confirms = { true }
  gm.publishRecap(C_DRAFT1)
  local first = H.pages[C_COPY1]
  runAction(lastNotification(), "Undo")
  eq(H.pages[C_COPY1], nil)
  eq(lastNotification().message, "Undone: the players' recap is gone again")
  H.confirms = { true }
  gm.publishRecap(C_DRAFT1)
  H.pages[C_DRAFT1] = H.pages[C_DRAFT1] .. "\nThey slept in the mill.\n"
  H.confirms = { true }
  gm.publishRecap(C_DRAFT1)
  has(H.confirmsAsked[#H.confirmsAsked], "It replaces the one they have.")
  has(H.pages[C_COPY1], "They slept in the mill.")
  runAction(lastNotification(), "Undo")
  eq(H.pages[C_COPY1], first)
  eq(lastNotification().message, "Undone: the players have the recap they had before")
  local writes = #H.writes
  H.pages[C_DRAFT1] = (H.pages[C_DRAFT1]:gsub("\nThey slept in the mill.\n", ""))
  eq(gm.publishRecap(C_DRAFT1), false)
  eq(#H.writes, writes)
  eq(lastNotification().message, "The players have this recap already, as it stands, at Player/Sessions/Session 1.")
end)

test("recap: the draft's bar says whether the players have it as it stands", "dm", function()
  H.pages[C_DRAFT1] = "---\ntype: recap-draft\nsession: 1\n---\n\n# Session 1\n\nThey crossed at dusk.\n"
  H.current = C_DRAFT1
  local bar = gm.sessionBar()
  eq(textOf(bar.html), "Recap of session 1 ○ Not published yet Publish recap")
  H.confirms = { true }
  click(bar, "Publish recap")
  ok(H.pages[C_COPY1])
  bar = gm.sessionBar()
  eq(textOf(bar.html), "Recap of session 1 ◉ Published to players [[Player/Sessions/Session 1|The players' copy]]")
  eq(list(buttonsOf(bar.html)), "")
  H.pages[C_DRAFT1] = H.pages[C_DRAFT1] .. "\nThey slept in the mill.\n"
  bar = gm.sessionBar()
  has(textOf(bar.html), "◐ Changed since publishing")
  eq(list(buttonsOf(bar.html)), "Publish again")
  eq(#dispatch("hooks:renderTopWidgets"), 1, "it is the page's top widget")
  H.pages[C_DRAFT1] = "---\ntype: recap-draft\n---\n\n# Notes\n"
  H.pages["Sessions/Session Notes Recap"] = H.pages[C_DRAFT1]
  H.current = "Sessions/Session Notes Recap"
  has(textOf(gm.sessionBar().html), "⚠ Which session is this the recap of?")
  eq(gm.publishRecap("Sessions/Session Notes Recap"), false)
  has(lastNotification().message, "doesn't say which session it is the recap of")
end)

test("recap: the commands act on the session's own pages, and ask elsewhere", "dm", function()
  H.confirms = { true, true }
  gm.nextSession()
  gm.nextSession()
  eq(gm.currentSession(), 3)
  H.current = "Session Table"
  H.picks = { "Session 2" }
  H.commands["GM: Draft Recap"].run()
  local box = H.filterBoxes[#H.filterBoxes]
  eq(list(names(box.options)), "Session 3 | Session 2 | Session 1", "the one being played first")
  eq(box.options[1].description, "This session")
  ok(H.pages[C_DRAFT2], "the one picked")
  H.pages[C_LOG1] = "---\ntype: session\nsession: 1\n---\n\n# Session 1\n\n## Decisions\n\n- Took the deal\n"
  H.current = C_LOG1
  local boxes = #H.filterBoxes
  H.commands["GM: Draft Recap"].run()
  eq(#H.filterBoxes, boxes, "on a session's log, that session's, without asking")
  has(H.pages[C_DRAFT1], "- Took the deal")
  H.current = C_DRAFT2
  H.confirms = { true }
  H.commands["GM: Publish Recap"].run()
  ok(H.pages[C_COPY2], "on a draft, that draft")
  H.current = "Session Table"
  H.picks = { "Sessions/Session 1 Recap" }
  H.confirms = { true }
  H.commands["GM: Publish Recap"].run()
  eq(list(names(H.filterBoxes[#H.filterBoxes].options)), "Sessions/Session 2 Recap | Sessions/Session 1 Recap")
  ok(H.pages[C_COPY1], "elsewhere, the one picked")
end)

test("recap: with one draft, or none, Publish Recap doesn't ask which", "dm", function()
  H.current = "Session Table"
  H.commands["GM: Publish Recap"].run()
  eq(lastNotification().message, "No recap is drafted yet: GM: Draft Recap drafts one from what GM Kit recorded.")
  H.pages[C_DRAFT1] = "---\ntype: recap-draft\nsession: 1\n---\n\n# Session 1\n\nThey crossed at dusk.\n"
  H.confirms = { true }
  H.commands["GM: Publish Recap"].run()
  eq(#H.filterBoxes, 0)
  ok(H.pages[C_COPY1])
end)

test("recap: the players' Sessions folder is theirs: never a copy to delete, nor to publish over", "dm", function()
  H.pages[C_COPY1] = "---\ntype: recap\n---\n\n# Session 1\n\nThey crossed at dusk.\n"
  H.pages["Player/Sessions/Our notes"] = "# Our notes\n"
  eq(list(gm.orphanCopies(select(2, gm.reveals()))), "", "no adventure page makes them, and neither is an orphan")
  gm.previewPublish()
  hasnt(H.pages["State/Publish Preview"], "Sessions/")
  cPublish()
  eq(#H.confirmsAsked, 1, "the publish's question, and none of deleting")
  ok(H.pages[C_COPY1])
  ok(H.pages["Player/Sessions/Our notes"])
  -- an adventure page of the same name is never published over a recap
  H.pages["Adventure/Sessions/Session 1"] = "---\ntype: rules\n---\n\n# Session 1\n\nHow a session runs.\n"
  eq(gm.playerCopy("Adventure/Sessions/Session 1"), nil)
  gm.setRevealed("Adventure/Sessions/Session 1", true)
  cPublish()
  has(H.pages[C_COPY1], "They crossed at dusk.")
  eq(gm.recapPage(1), "Player/" .. gm.config.recapFolder .. "Session 1", "the one setting names both")
end)

test("recap: what it quotes can't run: no live value, no fenced code", "dm", function()
  H.prompts = { "Read the note: ${gm.version} and ${party.n()}" }
  gm.logDecision()
  H.prompts = { "```space-lua" }
  gm.logDecision()
  gm.draftRecap(1)
  local draft = H.pages[C_DRAFT1]
  has(draft, "- Read the note: $\\{gm.version} and $\\{party.n()}\n")
  has(draft, "- \\```space-lua\n")
  hasnt(draft, "${")
  eq(#markdown.parseMarkdown(draft).children, 0, "nothing live")
  H.confirms = { true }
  gm.publishRecap(C_DRAFT1)
  hasnt(H.pages[C_COPY1], "${")
  has(H.pages[C_COPY1], "- Read the note: $\\{gm.version} and $\\{party.n()}\n")
end)
