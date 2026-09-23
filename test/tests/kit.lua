------------------------------------------------------------------ GM Kit

-- How many pages the fixture's State/Revealed lists: one "- [[...]]" line
-- each, and the button line above them isn't one.
local REVEALED = count(FIXTURES.dm["State/Revealed"], "\n- [[")

test("kit: registers commands, header buttons and a top widget", "dm", function()
  for _, c in ipairs({ "GM: Session Table", "GM: Reveal Page", "GM: Unreveal Page", "GM: Hide Page",
      "GM: Publish to Players", "GM: Preview Publish", "GM: Mark Met", "GM: Mark Dead", "GM: Mark Visited",
      "GM: Log Decision", "GM: Next Session", "GM: Draft Recap", "GM: Publish Recap" }) do
    ok(H.commands[c], "missing command " .. c)
  end
  eq(H.commands["GM: Hide Page"].hide, true, "the old name stays out of the palette")
  eq(H.commands["GM: Unreveal Page"].hide, nil)
  eq(H.commands["GM: Mark Met"].key, "Ctrl-Alt-m")
  eq(H.commands["GM: Log Decision"].key, "Ctrl-Alt-d")
  local icons = {}
  for _, b in ipairs(config.get("actionButtons")) do
    for k in pairs(b) do ok(ALLOWED_BUTTON_KEYS[k], "action button key not in the 2.11 schema: " .. k) end
    if b.command then ok(H.commands[b.command] or b.command:find("^Navigate") or b.command:find("^Open"),
                         "button runs a missing command " .. b.command) end
    icons[b.icon] = b.priority
  end
  for _, icon in ipairs({ "clipboard", "edit-3", "eye", "send", "printer" }) do
    ok(icons[icon], "no " .. icon .. " button")
    ok(icons[icon] < 1 and icons[icon] > 0, icon .. " should sit after the built-in buttons")
  end
  -- GM Kit's bar, GM Book's on a built edition, and GM Beyond's on an imported character
  eq(#H.listeners["hooks:renderTopWidgets"], 3)
end)

test("kit: the bar appears on adventure pages only", "dm", function()
  for _, page in ipairs({ "Session Table", "index", "Adventure/index", "Adventure/Library/Storie/GM Book",
                          "Adventure/Build/Book DM", "Book/People/Ada", "State/Revealed" }) do
    eq(gm.bar(page), nil, page)
  end
  ok(gm.bar("Adventure/World/People/The Warden"))
  ok(gm.bar("Adventure/Campaign/Act I"))
end)

test("kit: bar for a person, a place, a faction and a campaign page", "dm", function()
  local warden = gm.bar("Adventure/World/People/The Warden")
  eq(list(buttonsOf(warden.html)), "Reveal | Reveal part… | Mark met | Mark dead…")
  has(textOf(warden.html), "Session 1")
  has(textOf(warden.html), "○ Hidden from players")
  eq(list(buttonsOf(gm.bar("Adventure/World/Places/The Low Country").html)), "Reveal | Mark visited")
  local guild = gm.bar("Adventure/World/Factions/The Guild")
  eq(list(buttonsOf(guild.html)), "Unreveal | Mark met")
  has(textOf(guild.html), "◉ Revealed, not published yet")
  eq(list(buttonsOf(gm.bar("Adventure/Campaign/Act I").html)), "Reveal")
end)

test("kit: the committed State/Revealed parses", "dm", function()
  eq(list(gm.readRevealed()), "Adventure/Campaign/Session Zero | Adventure/Rules/House Rules | " ..
    "Adventure/Rules/Travel | Adventure/World/Factions/The Guild")
end)

-- As SilverBullet can write the list back after a rename, with
-- linkWriteFormat: shortest-suffix, once a page of the same name is made
-- elsewhere (GM Kit 3.8).
test("kit: an entry without the adventure folder is the adventure page it ends", "dm", function()
  H.pages["State/Revealed"] = "---\ntype: state\n---\n\n# Revealed to players\n\n" ..
    "- [[World/People/Mara]]\n- [[Old Tam#Who They Are]]\n- [[World/People/Nobody]]\n"
  eq(list(gm.readRevealed()), "Adventure/World/People/Mara | Adventure/World/People/Old Tam#Who They Are | " ..
    "Adventure/World/People/Nobody")
  H.confirms = { true }
  gm.publish()
  ok(H.pages["Player/World/People/Mara"], "Mara is published")
  has(H.pages["Player/World/People/Old Tam"], "## Who They Are")
  has(lastNotification().message, "Revealed but no longer there: Adventure/World/People/Nobody.")
  gm.revealPart("Adventure/World/People/The Warden", "Who They Are")
  has(H.pages["State/Revealed"], "- [[Adventure/World/People/Mara]]\n", "the next change writes it in full")
end)

test("kit: reveal from the bar, with undo", "dm", function()
  H.current = "Adventure/World/People/The Warden"
  click(gm.bar(), "Reveal")
  ok(gm.isRevealed(H.current))
  local text = H.pages["State/Revealed"]
  has(text, "- [[Adventure/World/People/The Warden]]")
  has(text, '${widgets.commandButton("Publish to players", "GM: Publish to Players")}')
  eq(#gm.readRevealed(), REVEALED + 1)
  ok(H.refreshes > 0, "no refresh")
  local n = lastNotification()
  has(n.message, "Revealed The Warden.")
  eq(list(buttonsOf(gm.bar().html)), "Unreveal | Mark met | Mark dead…")
  runAction(n, "Undo")
  ok(not gm.isRevealed(H.current))
  eq(#gm.readRevealed(), REVEALED)
end)

test("kit: reveal offers to publish", "dm", function()
  H.current = "Adventure/World/People/The Warden"
  click(gm.bar(), "Reveal")
  H.confirms = { true }
  runAction(lastNotification(), "Publish now")
  ok(H.pages["Player/World/People/The Warden"], "not published")
  has(lastNotification().message, "Published to players: " .. (REVEALED + 1) .. " new")
end)

test("kit: the revealed list keeps order and the button line", "dm", function()
  gm.setRevealed("Adventure/Campaign/Act I", true)
  local text = H.pages["State/Revealed"]
  local first = text:find("- [[", 1, true)
  ok(text:find("${widgets.commandButton", 1, true) < first, "buttons should come before the list")
  eq(gm.readRevealed()[1], "Adventure/Campaign/Act I")
  eq(gm.setRevealed("Adventure/Campaign/Act I", true), false, "a second reveal changed the list")
end)

test("kit: mark met from the bar", "dm", function()
  H.current = "Adventure/World/People/The Warden"
  click(gm.bar(), "Mark met")
  local state = H.pages["State/People/The Warden"]
  ok(state, "no state record")
  has(state, "type: state-record")
  has(state, 'subject: "[[Adventure/World/People/The Warden]]"')
  has(state, "met: true\nmet_session: 1\n")
  has(state, "## Log\n\n- [[Sessions/Session 1|Session 1]]: met\n")
  ok(gm.isRevealed(H.current), "met should reveal")
  eq(list(gm.revealedPart(H.current)), "First Impressions", "only what the players see first")
  has(lastNotification().message, "The Warden: met in session 1, and revealed “First Impressions”.")
  local bar = gm.bar()
  eq(list(buttonsOf(bar.html)), "Reveal all | Reveal part… | Unreveal | Mark dead… | Unmark met")
  has(textOf(bar.html), "✓ Met in [[Sessions/Session 1|session 1]]")
  has(textOf(bar.html), "[[State/People/The Warden|Play state]]")
  local q = __liq(function() return index.pages() end,
    function(p) return p.type == "state-record" and p.met == true end, {}, nil, nil)
  eq(#q, 1, "the Session Table's Met query wouldn't see it")
end)

test("kit: undo a mark", "dm", function()
  H.current = "Adventure/World/People/The Warden"
  click(gm.bar(), "Mark met")
  runAction(lastNotification(), "Undo")
  eq(H.pages["State/People/The Warden"], nil)
  ok(not gm.isRevealed(H.current))
  has(lastNotification().message, "Undone")
end)

test("kit: undo keeps what was recorded before", "dm", function()
  H.current = "Adventure/World/People/The Warden"
  H.prompts = { "Drowned" }
  click(gm.bar(), "Mark dead…")
  local afterDeath = H.pages["State/People/The Warden"]
  click(gm.bar(), "Mark met")
  runAction(lastNotification(), "Undo")
  eq(H.pages["State/People/The Warden"], afterDeath)
end)

test("kit: marking twice keeps the first session", "dm", function()
  H.current = "Adventure/World/People/The Warden"
  gm.mark(H.current, "met")
  gm.patch("Session Table", "session", 4)
  eq(gm.currentSession(), 4)
  eq(gm.mark(H.current, "met"), false)
  has(lastNotification().message, "already recorded. Met in session 1.")
  has(H.pages["State/People/The Warden"], "met_session: 1\n")
end)

test("kit: mark dead asks how, and can be cancelled", "dm", function()
  H.current = "Adventure/World/People/The Warden"
  H.prompts = { NIL }
  click(gm.bar(), "Mark dead…")
  eq(H.pages["State/People/The Warden"], nil)
  H.prompts = { "  Swept away at the ford  " }
  click(gm.bar(), "Mark dead…")
  local state = H.pages["State/People/The Warden"]
  has(state, "died_session: 1\nstatus: dead\n")
  has(state, "- [[Sessions/Session 1|Session 1]]: died - Swept away at the ford")
  ok(not gm.isRevealed(H.current), "a death shouldn't reveal")
  has(textOf(gm.bar().html), "† Died in [[Sessions/Session 1|session 1]]")
end)

test("kit: Mark Met from the session table asks who", "dm", function()
  H.current = "Session Table"
  H.picks = { "World/People/Mara" }
  H.commands["GM: Mark Met"].run()
  local box = H.filterBoxes[1]
  eq(box.label, "Met")
  has(box.help, "Recorded for session 1.")
  local opts = list(names(box.options))
  has(opts, "World/People/The Warden")
  has(opts, "World/Factions/The Guild")
  hasnt(opts, "Places/")
  hasnt(opts, "Campaign/")
  hasnt(opts, "Library/")
  hasnt(opts, "index")
  ok(H.pages["State/People/Mara"], "Mara not recorded")
  eq(H.current, "Session Table", "shouldn't navigate")
end)

-- Mara is the first person by name, so it is the picker, not the alphabet,
-- that puts her last once she is met.
test("kit: the picker puts people already met last", "dm", function()
  gm.mark("Adventure/World/People/Mara", "met")
  H.current = "Session Table"
  H.picks = { NIL }
  local writes = #H.writes
  H.commands["GM: Mark Met"].run()
  local opts = H.filterBoxes[1].options
  eq(opts[#opts].name, "World/People/Mara")
  eq(opts[#opts].description, "Met in session 1")
  eq(opts[1].description, nil)
  eq(#H.writes, writes, "a dismissed picker wrote something")
end)

test("kit: on the right page the command acts at once; on the wrong one it asks", "dm", function()
  H.current = "Adventure/World/People/The Warden"
  H.commands["GM: Mark Met"].run()
  eq(#H.filterBoxes, 0)
  ok(H.pages["State/People/The Warden"])
  H.current = "Adventure/World/Places/The Low Country"
  H.picks = { "World/People/The Tinker" }
  H.commands["GM: Mark Met"].run()
  eq(#H.filterBoxes, 1)
  ok(H.pages["State/People/The Tinker"])
  eq(H.pages["State/Places/The Low Country"], nil)
end)

test("kit: Mark Visited lists places", "dm", function()
  H.current = "Session Table"
  H.picks = { "World/Places/The High Country" }
  H.commands["GM: Mark Visited"].run()
  local opts = list(names(H.filterBoxes[1].options))
  hasnt(opts, "People/")
  has(opts, "World/Places/Fordtown")
  has(H.pages["State/Places/The High Country"], "visited: true\nvisited_session: 1\n")
  ok(gm.isRevealed("Adventure/World/Places/The High Country"))
end)

test("kit: Mark Dead lists people only", "dm", function()
  H.current = "index"
  H.picks = { "World/People/Old Tam" }
  H.prompts = { "" }
  H.commands["GM: Mark Dead"].run()
  hasnt(list(names(H.filterBoxes[1].options)), "Factions/")
  has(H.pages["State/People/Old Tam"], "## Log\n\n- [[Sessions/Session 1|Session 1]]: died\n") -- no detail
  eq(H.pages["State/People/Old Tam"]:sub(-1), "\n", "records should end with a newline")
end)

test("kit: records written by 2.0, without a final newline, still append cleanly", "dm", function()
  H.pages["State/People/The Warden"] = "---\ntype: state-record\nmet: true\nmet_session: 1\n---\n\n# The Warden\n\n## Log\n\n- Session 1: met"
  H.prompts = { "Drowned" }
  gm.markDead("Adventure/World/People/The Warden")
  has(H.pages["State/People/The Warden"], "- Session 1: met\n- [[Sessions/Session 1|Session 1]]: died - Drowned\n")
end)

test("kit: Reveal Page off Adventure picks from hidden pages", "dm", function()
  H.current = "Session Table"
  H.picks = { "Campaign/Act I" }
  H.commands["GM: Reveal Page"].run()
  local opts = list(names(H.filterBoxes[1].options))
  hasnt(opts, "Rules/House Rules")
  ok(gm.isRevealed("Adventure/Campaign/Act I"))
end)

test("kit: Unreveal Page off Adventure picks from what the players can see", "dm", function()
  H.current = "State/Revealed"
  H.picks = { "Rules/House Rules" }
  local reloads = H.reloads
  H.commands["GM: Unreveal Page"].run()
  eq(H.filterBoxes[1].label, "Unreveal")
  eq(#H.filterBoxes[1].options, REVEALED)
  eq(H.filterBoxes[1].options[1].description, "Revealed, not published yet")
  ok(not gm.isRevealed("Adventure/Rules/House Rules"))
  ok(H.reloads > reloads, "State/Revealed was open and should have reloaded")
end)

test("kit: Reveal and Unreveal on an Adventure page act on it", "dm", function()
  H.current = "Adventure/Rules/House Rules"
  H.commands["GM: Reveal Page"].run()
  has(lastNotification().message, "already revealed")
  H.commands["GM: Unreveal Page"].run()
  ok(not gm.isRevealed(H.current))
  eq(#H.filterBoxes, 0)
end)

test("kit: publish asks, then reports", "dm", function()
  H.confirms = { false }
  eq(gm.publish(), false)
  eq(H.pages["Player/Rules/House Rules"], nil)
  has(H.confirmsAsked[1], "Publish " .. REVEALED .. " revealed pages to the players?")
  H.confirms = { true }
  gm.publish()
  has(lastNotification().message, "Published to players: " .. REVEALED .. " new, 0 updated, 0 unchanged.")
  for _, page in ipairs(gm.readRevealed()) do
    local copy = "Player/" .. page:sub(#"Adventure/" + 1)
    ok(H.pages[copy], "missing " .. copy)
    hasnt(H.pages[copy], "## DM Only", copy)
  end
  eq(H.pages["Player/index"], FIXTURES.dm["Player/index"], "Player/index was touched")
  eq(H.pages["Player/Notes/index"], FIXTURES.dm["Player/Notes/index"], "Notes were touched")
  local writes = #H.writes
  H.confirms = { true }
  gm.publish()
  has(lastNotification().message, "0 new, 0 updated, " .. REVEALED .. " unchanged.")
  eq(#H.writes, writes, "an unchanged publish rewrote pages")
  H.pages["Adventure/Rules/Travel"] = H.pages["Adventure/Rules/Travel"] .. "\nMore.\n"
  H.confirms = { true }
  gm.publish()
  has(lastNotification().message, "0 new, 1 updated, " .. (REVEALED - 1) .. " unchanged.")
end)

test("kit: publish warns about revealed pages that are gone", "dm", function()
  gm.writeRevealed({ "Adventure/Rules/House Rules", "Adventure/Gone" })
  H.confirms = { true }
  gm.publish()
  eq(lastNotification().kind, "warning")
  has(lastNotification().message, "Revealed but no longer there: Adventure/Gone.")
  has(H.confirmsAsked[1], "Publish 1 revealed page to")
end)

test("kit: publishing with nothing revealed", "dm", function()
  gm.writeRevealed({})
  eq(gm.publish(), false)
  eq(#H.confirmsAsked, 0)
  eq(lastNotification().kind, "warning")
end)

test("kit: publish skips the index and Notes", "dm", function()
  eq(gm.playerCopy("Adventure/index"), nil)
  eq(gm.playerCopy("Adventure/Notes/Secret"), nil)
  eq(gm.playerCopy("Book/People/Ada"), nil)
  eq(gm.playerCopy("Adventure/Rules/Travel"), "Player/Rules/Travel")
end)

test("kit: unrevealing a published page deletes the players' copy, with undo", "dm", function()
  H.confirms = { true }
  gm.publish()
  H.current = "Adventure/Rules/House Rules"
  local copy = H.pages["Player/Rules/House Rules"]
  ok(copy, "not published")
  has(textOf(gm.bar().html), "◉ Revealed to players")
  click(gm.bar(), "Unreveal")
  eq(H.pages["Player/Rules/House Rules"], nil, "their copy should be gone")
  ok(not gm.isRevealed(H.current))
  local n = lastNotification()
  has(n.message, "Unrevealed House Rules: it's off the revealed list, and the players' copy is deleted.")
  has(textOf(gm.bar().html), "○ Hidden from players")
  runAction(n, "Undo")
  eq(H.pages["Player/Rules/House Rules"], copy, "undo should put their copy back as it was")
  ok(gm.isRevealed(H.current))
  has(lastNotification().message, "Undone: House Rules is back with the players")
  H.current = "Adventure/World/People/The Warden"
  gm.setRevealed(H.current, true)
  click(gm.bar(), "Unreveal")
  has(lastNotification().message, "It was never published, so the players never had it.")
end)

test("kit: next session asks, then counts up, with undo", "dm", function()
  H.confirms = { false }
  eq(gm.nextSession(), false)
  eq(gm.currentSession(), 1)
  H.current = "Session Table"
  H.confirms = { true }
  H.commands["GM: Next Session"].run()
  eq(gm.currentSession(), 2)
  has(H.pages["Session Table"], "\nsession: 2\n")
  has(H.pages["Session Table"], "# Session Table")
  ok(H.saves > 0 and H.reloads > 0, "the open session table should be saved first and reloaded after")
  runAction(lastNotification(), "Undo")
  eq(gm.currentSession(), 1)
end)

test("kit: next session without a session page makes one", "dm", function()
  H.pages["Session Table"] = nil
  eq(gm.currentSession(), 1)
  H.confirms = { true }
  gm.nextSession()
  eq(gm.currentSession(), 2)
  has(H.pages["Session Table"], "---\nsession: 2\n---\n")
end)

test("kit: log a decision", "dm", function()
  H.prompts = { "  Took Mara's deal  " }
  H.commands["GM: Log Decision"].run()
  eq(H.pages["Sessions/Session 1"], "---\ntype: session\nsession: 1\n---\n\n# Session 1\n\n" ..
     "## Scenes\n\n## Decisions\n\n- Took Mara's deal\n")
  runAction(lastNotification(), "Open log")
  eq(H.current, "Sessions/Session 1")
  H.prompts = { "Burned the map" }
  local reloads = H.reloads
  H.commands["GM: Log Decision"].run()
  has(H.pages["Sessions/Session 1"], "- Took Mara's deal\n- Burned the map\n")
  ok(H.saves > 0 and H.reloads > reloads, "the open log should be saved first and reloaded after")
  local before = H.pages["Sessions/Session 1"]
  H.prompts = { "   " }
  eq(gm.logDecision(), false)
  H.prompts = { NIL }
  eq(gm.logDecision(), false)
  eq(H.pages["Sessions/Session 1"], before)
end)

test("kit: frontmatter handling", "dm", function()
  local t = "---\ntype: state\n---\n\nmet: in the body\n"
  eq(gm.setFrontmatter(t, "met", true), "---\ntype: state\nmet: true\n---\n\nmet: in the body\n")
  eq(gm.setFrontmatter("---\nmet: false\nx: 1\n---\nbody", "met", true), "---\nmet: true\nx: 1\n---\nbody")
  eq(gm.setFrontmatter("---\n---\nbody", "a", 1), "---\na: 1\n---\nbody")
  eq(gm.setFrontmatter("# Title\n", "a", 1), "---\na: 1\n---\n\n# Title\n")
  eq(gm.setFrontmatter("---\na: 1\n---", "b", 2), "---\na: 1\nb: 2\n---\n")
  local fm = gm.frontmatter('---\nsubject: "[[X]]"\nsession:  3 \n---\n\nsession: 9\n')
  eq(fm.subject, "[[X]]")
  eq(fm.session, "3")
  eq(gm.frontmatter("no frontmatter").session, nil)
end)

test("kit: stripSecrets", "dm", function()
  eq(gm.stripSecrets("# A\nopen\n## DM Only\nsecret\n### deeper\nstill secret\n## Next\nopen again"),
     "# A\nopen\n## Next\nopen again")
end)

test("kit: top widget listener", "dm", function()
  H.current = "Adventure/World/People/The Warden"
  eq(#dispatch("hooks:renderTopWidgets"), 1)
  H.current = "Adventure/Build/Book DM"
  eq(#dispatch("hooks:renderTopWidgets"), 1, "only GM Book's bar")
  H.current = "Session Table"
  eq(#dispatch("hooks:renderTopWidgets"), 0)
  gm.bar = function() error("kaboom") end
  H.current = "Adventure/World/People/The Warden"
  eq(#dispatch("hooks:renderTopWidgets"), 0)
  has(takePrinted()[1], "kaboom")
end)

test("kit: a failing bar button reports instead of vanishing", "dm", function()
  H.current = "Adventure/World/People/The Warden"
  local bar = gm.bar()
  gm.reveal = function() error("disk full") end
  click(bar, "Reveal")
  eq(lastNotification().kind, "error")
  has(lastNotification().message, "GM Kit:")
  has(lastNotification().message, "disk full")
end)

test("kit: an Adventure folder without People, Places or Factions", "dm", function()
  for name in pairs(FIXTURES.dm) do
    if name:find("/People/") or name:find("/Places/") or name:find("/Factions/") then H.pages[name] = nil end
  end
  local pages = gm.markable("met")
  has(list(pages), "Adventure/Campaign/Act I")
  H.current = "Adventure/Campaign/Act I"
  H.commands["GM: Mark Met"].run()
  eq(#H.filterBoxes, 0)
  ok(H.pages["State/Other/Act I"])
end)
