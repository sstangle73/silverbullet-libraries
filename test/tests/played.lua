------------------------------------------------------------------ Scenes played

local ACT = "Adventure/Campaign/Act I"
local S1, S2, S3 = ACT .. "/Scene 1", ACT .. "/Scene 2", ACT .. "/Scene 3"
local ST1, ST2, ST3 = "State/Scenes/Act I/Scene 1", "State/Scenes/Act I/Scene 2",
                      "State/Scenes/Act I/Scene 3"
local LOG1, LOG2 = "Sessions/Session 1", "Sessions/Session 2"
local T1 = "Scene 1 — The Ford"
local T2 = "Scene 2 — The Market"
local T3 = "Scene 3 — The Old Orchard"

test("kit: a scene is a kind of its own, and its state keeps its act", "dm", function()
  eq(gm.kind(S1), "Scenes")
  eq(gm.statePath(S1), ST1, "the act comes too, so two Scene 3s stay apart")
  eq(gm.kind("Adventure/World/People/The Warden"), "People", "the folders still decide")
  eq(gm.statePath("Adventure/World/People/The Warden"), "State/People/The Warden")
  eq(gm.kind("Adventure/Campaign/Premise"), nil, "a campaign page is not a scene")
  eq(gm.sceneTitle(S2), T2)
  eq(gm.sceneTitle("Adventure/Campaign/Premise"), "Premise", "no title, just the name")
  local bar = gm.bar(S1)
  eq(list(buttonsOf(bar.html)), "Reveal | Mark planned | Mark started")
  hasnt(textOf(bar.html), "Played in")
end)

test("kit: planned, started and finished, all in one session", "dm", function()
  H.current = S2
  click(gm.bar(), "Mark planned")
  has(H.pages[ST2], "planned: true\n")
  has(H.pages[ST2], "planned_session: 1\n")
  eq(lastNotification().message, "Scene 2: planned for session 1.")
  has(textOf(gm.bar().html), "◇ Planned for [[Sessions/Session 1|session 1]]")
  eq(list(buttonsOf(gm.bar().html)), "Reveal | Mark started | Unmark planned | Mark found")

  click(gm.bar(), "Mark started")
  has(textOf(gm.bar().html), "▶ Started in [[Sessions/Session 1|session 1]], still going")
  eq(list(buttonsOf(gm.bar().html)), "Reveal | Mark finished | Unmark started | Mark found")

  click(gm.bar(), "Mark finished")
  has(textOf(gm.bar().html), "✓ Played in [[Sessions/Session 1|session 1]]")
  eq(list(buttonsOf(gm.bar().html)), "Reveal | Unmark finished | Mark found",
     "and Scene 2 still hands out the lantern")

  has(H.pages[LOG1], "## Scenes\n\n- Planned: [[" .. S2 .. "|" .. T2 .. "]]\n" ..
      "- Started: [[" .. S2 .. "|" .. T2 .. "]]\n" ..
      "- Finished: [[" .. S2 .. "|" .. T2 .. "]]\n")
  ok(not gm.isRevealed(S2), "playing a scene is no reason to reveal it")
end)

test("kit: a scene that runs long finishes in the session after", "dm", function()
  H.current = S3
  click(gm.bar(), "Mark started")
  gm.patch("Session Table", "session", 2)
  click(gm.bar(), "Mark finished")
  has(H.pages[ST3], "started_session: 1\n")
  has(H.pages[ST3], "finished_session: 2\n")
  has(textOf(gm.bar().html),
      "✓ Played in sessions [[Sessions/Session 1|1]]–[[Sessions/Session 2|2]]")
  has(H.pages[LOG1], "- Started: [[" .. S3 .. "|" .. T3 .. "]]\n")
  hasnt(H.pages[LOG1], "Finished", "session 1 never saw it end")
  has(H.pages[LOG2], "- Finished: [[" .. S3 .. "|" .. T3 .. "]]\n")
  hasnt(H.pages[LOG2], "Started")
end)

test("kit: a scene can't be finished before it is started", "dm", function()
  eq(gm.mark(S1, "finished"), false)
  eq(lastNotification().message, "Scene 1 hasn't been marked started yet.")
  eq(H.pages[ST1], nil, "and nothing was written")
  H.current = "Session Table"
  H.commands["GM: Mark Scene Finished"].run()
  eq(lastNotification().message, "No scene is open. Mark one started first.")
  eq(H.pages[LOG1], nil)
end)

test("kit: unmarking a start takes the finish with it, and the log says so", "dm", function()
  H.current = S2
  click(gm.bar(), "Mark started")
  click(gm.bar(), "Mark finished")
  gm.unmark(S2, "started")
  hasnt(H.pages[ST2], "started:")
  hasnt(H.pages[ST2], "finished:")
  hasnt(H.pages[ST2], "finished_session:")
  has(H.pages[ST2], "- [[Sessions/Session 1|Session 1]]: not started after all\n")
  eq(lastNotification().message,
     "Scene 2: no longer marked started, and its finish with it.")
  has(H.pages[LOG1], "- Not started after all: [[" .. S2 .. "|" .. T2 .. "]]\n")
  eq(list(buttonsOf(gm.bar().html)), "Reveal | Mark planned | Mark started | Mark found")
  runAction(lastNotification(), "Undo")
  has(H.pages[ST2], "finished: true")
  hasnt(H.pages[LOG1], "Not started after all", "undo takes its line back too")
end)

test("kit: undo takes back the line a mark wrote, and a log it brought into being", "dm", function()
  eq(H.pages[LOG1], nil)
  H.current = S1
  click(gm.bar(), "Mark started")
  ok(H.pages[LOG1], "the mark should have made the log")
  runAction(lastNotification(), "Undo")
  eq(H.pages[LOG1], nil, "and undo should take it away again")
  eq(H.pages[ST1], nil)

  H.prompts = { "Took Mara's deal" }
  H.commands["GM: Log Decision"].run()
  click(gm.bar(), "Mark started")
  has(H.pages[LOG1], "- Started: [[" .. S1 .. "|" .. T1 .. "]]\n")
  runAction(lastNotification(), "Undo")
  has(H.pages[LOG1], "- Took Mara's deal\n", "a log that was already there keeps what it had")
  hasnt(H.pages[LOG1], "Started:")
end)

test("kit: scenes and decisions keep to their own sections", "dm", function()
  H.current = S1
  click(gm.bar(), "Mark started")
  H.prompts = { "Waded the ford at dusk" }
  H.commands["GM: Log Decision"].run()
  click(gm.bar(), "Mark finished")
  H.prompts = { "Burned the map" }
  H.commands["GM: Log Decision"].run()
  eq(H.pages[LOG1], "---\ntype: session\nsession: 1\n---\n\n# Session 1\n\n## Scenes\n\n" ..
     "- Started: [[" .. S1 .. "|" .. T1 .. "]]\n" ..
     "- Finished: [[" .. S1 .. "|" .. T1 .. "]]\n\n" ..
     "## Decisions\n\n- Waded the ford at dusk\n- Burned the map\n")
end)

test("kit: a section that isn't there yet is made at the end", "dm", function()
  eq(gm.appendUnder("# S\n\n## Decisions\n\n- Took the deal\n", "Scenes", "Started: x"),
     "# S\n\n## Decisions\n\n- Took the deal\n\n## Scenes\n\n- Started: x\n")
  eq(gm.appendUnder("# S\n", "Scenes", "a"), "# S\n\n## Scenes\n\n- a\n")
  eq(gm.appendUnder("# S\n\n\n", "Scenes", "a"), "# S\n\n## Scenes\n\n- a\n",
     "no run of blank lines where the page already ended in one")
  eq(gm.appendUnder("# S\n\n## Scenes\n\n## Decisions\n", "Scenes", "a"),
     "# S\n\n## Scenes\n\n- a\n\n## Decisions\n", "an empty section is filled, not skipped")
  eq(gm.appendUnder("# S\n\n## Scenes\n\n- a\n\n## Decisions\n\n- d\n", "Scenes", "b"),
     "# S\n\n## Scenes\n\n- a\n- b\n\n## Decisions\n\n- d\n")
  eq(gm.appendUnder("# S\n\n## Scenes\n\n- a\n", "Scenes", "b"),
     "# S\n\n## Scenes\n\n- a\n- b\n", "the last section keeps its end")
  eq(gm.appendUnder("# S\n\n## Scenes\n\n- a\n\n### Later\n\nmore\n", "Scenes", "b"),
     "# S\n\n## Scenes\n\n- a\n\n### Later\n\nmore\n- b\n",
     "a deeper heading belongs to the section, so the line goes after it")
end)

test("kit: scenes numbered alike in two acts keep their own state", "dm", function()
  local other = "Adventure/Campaign/Act II/Scene 1"
  H.pages[other] = "---\ntype: scene\nscene: 1\nscene_title: The Gate\nbook_order: 21\n---\n\n# Scene 1\n"
  eq(gm.statePath(other), "State/Scenes/Act II/Scene 1")
  gm.mark(S1, "started")
  gm.mark(other, "started")
  ok(H.pages[ST1], "Act I's")
  ok(H.pages["State/Scenes/Act II/Scene 1"], "Act II's")
  local all = gm.scenes()
  eq(all[1] .. " | " .. all[2] .. " | " .. all[3], S1 .. " | " .. S2 .. " | " .. S3)
  eq(all[#all], other, "book_order runs the acts in order, so Act II's comes last")
end)

test("kit: a session's notes link the scene before, the scene, and the one after", "dm", function()
  eq(gm.sessionBar(LOG1), nil, "no log yet, no bar")
  H.current = S2
  click(gm.bar(), "Mark started")
  eq(textOf(gm.sessionBar(LOG1).html),
     "[[" .. S1 .. "|← " .. T1 .. "]] · **[[" .. S2 .. "|" .. T2 .. "]]** · " ..
     "[[" .. S3 .. "|" .. T3 .. " →]]")
  eq(gm.sessionBar(S2), nil, "an adventure page keeps the bar it had")
  ok(gm.bar(S2), "and still has it")

  gm.unmark(S2, "started")
  local all = gm.scenes()
  local last = all[#all]
  H.current = last
  click(gm.bar(), "Mark started")
  local nav = textOf(gm.sessionBar(LOG1).html)
  has(nav, "**[[" .. last .. "|" .. gm.sceneTitle(last) .. "]]**")
  has(nav, "[[" .. all[#all - 1] .. "|← " .. gm.sceneTitle(all[#all - 1]) .. "]]")
  hasnt(nav, "→", "the last scene of the adventure has nothing after it")
end)

test("kit: before play the session sits on the first scene planned for it", "dm", function()
  H.current = S3
  click(gm.bar(), "Mark planned")
  H.current = S2
  click(gm.bar(), "Mark planned")
  eq(gm.sessionScene(1), S2, "the first in the adventure's order, not the last marked")
  has(textOf(gm.sessionBar(LOG1).html), "**[[" .. S2 .. "|" .. T2 .. "]]**")

  -- once a session is running, where they actually are wins over the plan
  H.current = S3
  click(gm.bar(), "Mark started")
  eq(gm.sessionScene(1), S3)
end)

test("kit: a session with nothing of its own picks up where the last left off", "dm", function()
  gm.mark(S1, "started")
  gm.mark(S1, "finished")
  gm.patch("Session Table", "session", 2)
  eq(gm.sessionScene(2), S1, "session 2 opens where session 1 stopped")
  H.pages[LOG2] = "---\ntype: session\nsession: 2\n---\n\n# Session 2\n"
  has(textOf(gm.sessionBar(LOG2).html), "**[[" .. S1 .. "|" .. T1 .. "]]**")
  has(textOf(gm.sessionBar(LOG2).html), "[[" .. S2 .. "|" .. T2 .. " →]]")
  eq(gm.sessionScene(3), S1, "and so does a session further out")
end)

test("kit: the Session Table's scenes say where each one stands", "dm", function()
  H.current = S1
  click(gm.bar(), "Mark started")
  click(gm.bar(), "Mark finished")
  H.current = S2
  click(gm.bar(), "Mark planned")
  local rows = __liq(function() return index.pages() end,
    function(p) return p.type == "scene" end, nil,
    function(p) return { name = p.name, Played = gm.playedText(gm.readState(p.name)) } end, nil)
  local said = {}
  for _, r in ipairs(rows) do said[r.name] = r.Played end
  eq(said[S1], "Played in [[Sessions/Session 1|session 1]]")
  eq(said[S2], "Planned for [[Sessions/Session 1|session 1]]")
  eq(said[S3], "", "a scene nobody has marked says nothing")
  has(H.pages["Session Table"], "gm.playedText(gm.readState(p.name))")
end)

test("kit: the scene commands ask, and act on the scene you are on", "dm", function()
  H.current = "Session Table"
  H.picks = { "Campaign/Act I/Scene 2" }
  H.commands["GM: Mark Scene Planned"].run()
  has(H.pages[ST2], "planned: true\n")

  H.current = S2
  H.picks = {}
  H.commands["GM: Mark Scene Started"].run()
  has(H.pages[ST2], "started: true\n", "on a scene page it doesn't ask")
  H.commands["GM: Mark Scene Finished"].run()
  has(H.pages[ST2], "finished: true\n")

  H.picks = { "finished" }
  H.commands["GM: Unmark"].run()
  hasnt(H.pages[ST2], "finished: true", "the mark it was asked for")
  has(H.pages[ST2], "started: true", "and only that one")
end)
