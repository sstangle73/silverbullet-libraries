------------------------------------------------------------------ Items

local SCENE2 = "Adventure/Campaign/Act I/Scene 2"
local LANTERN = "Adventure/World/Items/Lantern"
local RECORD = "State/Items/Lantern"

test("party: value gives the number behind a count or a story number", "dm", function()
  eq(party.value { "wick", plus = 1 }, 6)
  eq(party.value({ "wick", plus = 1 }, 7), 8)
  eq(party.value { "wick", per = 1 / 2 }, 3)
  eq(party.value { "wick", plus = -9 }, 0, "a count is never below none")
  eq(party.value(1), 6)
  eq(party.value(), 5)
  eq(party.value { times = 2, plus = -1 }, 9)
  useParty(6, 1)
  eq(party.value { "wick", plus = 1 }, 7)
end)

test("party: naming an item changes nothing on the page or in print", "dm", function()
  local plain = party.count { "wick", plus = 1 }
  local tagged = party.count { "wick", plus = 1, item = "World/Items/Lantern" }
  eq(tagged.html, plain.html)
  eq(tagged.markdown, plain.markdown)
  eq(party.printed.count { "wick", plus = 1, item = "World/Items/Lantern" },
     party.printed.count { "wick", plus = 1 })
end)

test("book: Scene 2 points to the Lantern's rules instead of printing them twice", "adventure", function()
  gmbook.compile({ "dm", "player" })
  local dm, player = H.pages["Build/Book DM"], H.pages["Build/Book Player"]
  has(dm, "one for every traveller after.\n\n*See Lantern: Rules.*\n\n## DM Only\n\nThe tinker reports")
  hasnt(dm, "![[")
  hasnt(dm, "!Lantern")
  eq(count(dm, "**Wicks.**"), 1, "the rules print once, on the Lantern's page")
  has(dm, "## DM Only\n\n**Where the party finds it.** On the tinker's stall")
  has(player, "one for every traveller after.\n\n*See Lantern: Rules.*",
    "outside Scene 2's DM Only, the pointer is in the player edition too")
  hasnt(player, "Where the party finds it")
  has(player, "- **Out.** Snuffing it early wastes the wick.")
  -- kept under Scene 2's DM Only instead, the pointer stays out of the player edition
  local scene, rules = "Campaign/Act I/Scene 2", "\n![[World/Items/Lantern#Rules]]\n"
  local s, e = H.pages[scene]:find(rules, 1, true)
  H.pages[scene] = H.pages[scene]:sub(1, s - 1) .. H.pages[scene]:sub(e + 1) .. rules
  gmbook.compile({ "dm", "player" })
  has(H.pages["Build/Book DM"], "who bought the lantern.\n\n*See Lantern: Rules.*")
  hasnt(H.pages["Build/Book Player"], "See Lantern")
end)

test("book: a page the book prints is shown as a pointer to it", "adventure", function()
  H.pages["World/Items/Lamp"] = "---\nbook_order: 111\n---\n\n# The Lamp\n\nIt glows.\n\n" ..
    "## Rules\n\n- It lights.\n\n## DM Only\n\nIt was Mara's.\n"
  H.pages["Campaign/Lamp Scene"] = "---\nbook_order: 19\n---\n\n# Lamp Scene\n\nThey find it.\n" ..
    "![[World/Items/Lamp#Rules]]\nThen they leave.\n\n![[World/Items/Lamp|the lamp]]\n\n" ..
    "![[World/Items/Lamp#DM Only]]\n\nEnd.\n"
  gmbook.compile({ "dm", "player" })
  local dm, player = H.pages["Build/Book DM"], H.pages["Build/Book Player"]
  has(dm, "They find it.\n\n*See The Lamp: Rules.*\n\nThen they leave.\n\n*See The Lamp.*\n\n" ..
    "*See The Lamp: DM Only.*\n\nEnd.")
  has(player, "They find it.\n\n*See The Lamp: Rules.*\n\nThen they leave.\n\n*See The Lamp.*\n\nEnd.",
    "the player edition has no DM Only section to point to")
end)

test("book: a page the book doesn't print is printed in place", "adventure", function()
  H.pages["Notes/Lamp"] = "---\ntype: notes\n---\n\n# Lamp notes\n\n## Rules\n\n" ..
    "It holds ${party.count{\"wick\"}}.\n\n### Refills\n\n- Oil.\n\n## DM Only\n\nSecret wick.\n"
  H.pages["Campaign/Lamp Scene"] = "---\nbook_order: 19\n---\n\n# Lamp Scene\n\n## Finding it\n\n" ..
    "![[Notes/Lamp#Rules]]\n\n## After\n\n![[Notes/Lamp]]\n"
  gmbook.compile({ "dm", "player" })
  local dm, player = H.pages["Build/Book DM"], H.pages["Build/Book Player"]
  has(dm, "## Finding it\n\n### Rules\n\nIt holds as many wicks as the party has members, five for a " ..
    "party of five.\n\n#### Refills\n\n- Oil.\n\n## After\n\n### Lamp notes\n\n#### Rules\n\n")
  has(dm, "##### Refills\n\n- Oil.\n\n#### DM Only\n\nSecret wick.")
  hasnt(player, "Secret wick")
  has(player, "### Lamp notes")
  hasnt(dm, "${", "its expressions print")
end)

test("book: a page or section that isn't there prints nothing, and the build says so", "adventure", function()
  H.pages["Campaign/Lamp Scene"] = "---\nbook_order: 19\n---\n\n# Lamp Scene\n\nBefore.\n\n" ..
    "![[World/Items/Nowhere#Rules]]\n\n![[World/Items/Lantern#Nothing]]\n\nAfter.\n"
  H.current = "index"
  gmbook.build({ "dm", "player" })
  has(H.pages["Build/Book DM"], "# Lamp Scene\n\nBefore.\n\nAfter.")
  local n = lastNotification()
  eq(n.kind, "warning")
  has(n.message, "2 transclusions name pages or sections that can't be found, so they print nothing: " ..
    "Campaign/Lamp Scene (World/Items/Lantern#Nothing), Campaign/Lamp Scene (World/Items/Nowhere#Rules).")
end)

test("book: settings print every page in place, or word the pointer", "adventure", function()
  config.set("gmBook.see", "*For more, see %s.*")
  gmbook.compile({ "dm" })
  has(H.pages["Build/Book DM"], "every traveller after.\n\n*For more, see Lantern: Rules.*\n\n")
  config.set("gmBook.transclusions", "inline")
  gmbook.compile({ "dm" })
  local dm = H.pages["Build/Book DM"]
  hasnt(dm, "see Lantern")
  eq(count(dm, "**Wicks.**"), 2, "the rules print in the scene and on the Lantern's page")
  has(dm, "every traveller after.\n\n## Rules\n\n- **Wicks.**", "under Scene 2's title, a section in print")
end)

test("book: a link to a section prints as the page", "adventure", function()
  eq(gmbook.delink("See [[World/Items/Lantern#Rules]], [[World/Items/Lantern#Rules|its rules]] " ..
    "and [[#Rules]]."), "See Lantern, its rules and Rules.")
end)

test("book: images and anchors are not pages to point to", "adventure", function()
  H.pages["Campaign/Lamp Scene"] = "---\nbook_order: 19\n---\n\n# Lamp Scene\n\n![[map.png]]\n\n![[$lamp]]\n"
  local report = gmbook.compile({ "dm" })
  eq(#report.missing, 0)
end)

test("kit: registers the item commands", "dm", function()
  for _, c in ipairs({ "GM: Mark Found", "GM: Spend Use", "GM: Refund Use" }) do
    ok(H.commands[c], "missing command " .. c)
  end
end)

test("kit: Scene 2 hands out the Lantern, six wicks for The Party's five", "dm", function()
  local h = gm.handouts(SCENE2)
  eq(#h, 1)
  eq(h[1].item, LANTERN)
  eq(h[1].count, 6)
  eq(h[1].text, "six wicks")
  eq(h[1].unit, "wick")
  eq(h[1].units, "wicks")
  local items, given = gm.itemsOn(SCENE2)
  eq(list(items), LANTERN)
  eq(given[LANTERN].count, 6)
  eq(#(gm.itemsOn(LANTERN)), 0, "an item's own page has no row for itself")
end)

test("kit: Scene 2's bar has a row for the lantern", "dm", function()
  local bar = gm.bar(SCENE2)
  eq(list(buttonsOf(bar.html)), "Reveal | Mark planned | Mark started | Mark found")
  has(textOf(bar.html), "six wicks here")
  has(textOf(bar.html), "**[[" .. LANTERN .. "|Lantern]]**")
  local plain = gm.bar("Adventure/Campaign/Act I/Scene 1")
  eq(list(buttonsOf(plain.html)), "Reveal | Mark planned | Mark started", "a scene with no items has no rows")
end)

test("kit: found in the scene, the lantern holds six wicks and its page stays hidden", "dm", function()
  H.current = SCENE2
  click(gm.bar(), "Mark found")
  local state = H.pages[RECORD]
  ok(state, "no state record")
  has(state, "type: state-record")
  has(state, 'subject: "[[' .. LANTERN .. ']]"')
  has(state, 'found: true\nfound_in: "[[' .. SCENE2 .. ']]"\nfound_session: 1\n' ..
    "unit: wick\nunits: wicks\nuses: 6\nuses_found: 6\n")
  has(state, "## Log\n\n- [[Sessions/Session 1|Session 1]]: found in [[" .. SCENE2 .. "]], with six wicks\n")
  ok(not gm.isRevealed(LANTERN), "finding shouldn't reveal")
  local n = lastNotification()
  eq(n.message, "Lantern: found in session 1, with six wicks.")
  local bar = gm.bar()
  eq(list(buttonsOf(bar.html)), "Reveal | Mark planned | Mark started | Use a wick | Unmark found | Reveal")
  has(textOf(bar.html), "✓ Found in [[Sessions/Session 1|session 1]]")
  has(textOf(bar.html), "●●●●●● 6 of 6 wicks left")
  has(textOf(bar.html), "○ Hidden from players")
  runAction(n, "Reveal")
  ok(gm.isRevealed(LANTERN), "Reveal from the notification")
  eq(list(buttonsOf(gm.bar().html)), "Reveal | Mark planned | Mark started | Use a wick | Unmark found")
  local q = __liq(function() return index.pages() end,
    function(p) return p.type == "state-record" and p.found == true end, {},
    function(p) return { What = p.subject, Session = p.found_session, Left = gm.usesText(p) } end, nil)
  eq(#q, 1, "the Session Table's Found query wouldn't see it")
  eq(q[1].Left, "●●●●●● 6 of 6 wicks left")
  eq(q[1].Session, 1)
end)

test("kit: undo a find", "dm", function()
  H.current = SCENE2
  click(gm.bar(), "Mark found")
  runAction(lastNotification(), "Undo")
  eq(H.pages[RECORD], nil)
  eq(list(buttonsOf(gm.bar().html)), "Reveal | Mark planned | Mark started | Mark found")
  has(lastNotification().message, "Undone: Lantern is no longer marked found")
end)

test("kit: using and refunding wicks, each with undo", "dm", function()
  gm.markFound(LANTERN, SCENE2)
  H.current = LANTERN
  eq(list(buttonsOf(gm.bar().html)), "Reveal | Reveal part… | Use a wick | Unmark found")
  click(gm.bar(), "Use a wick")
  local n = lastNotification()
  eq(n.message, "Lantern: a wick used. 5 of 6 wicks left.")
  has(H.pages[RECORD], "\nuses: 5\n")
  has(H.pages[RECORD], "- [[Sessions/Session 1|Session 1]]: a wick used, 5 left\n")
  eq(list(buttonsOf(gm.bar().html)), "Reveal | Reveal part… | Use a wick | Refund a wick | Unmark found")
  has(textOf(gm.bar().html), "●●●●●○ 5 of 6 wicks left")
  runAction(n, "Undo")
  has(H.pages[RECORD], "\nuses: 6\n")
  hasnt(H.pages[RECORD], "a wick used")
  eq(lastNotification().message, "Undone: Lantern is back to 6 of 6 wicks left")
  for _ = 1, 6 do ok(gm.spend(LANTERN, -1), "a wick to use") end
  eq(gm.spend(LANTERN, -1), false)
  eq(lastNotification().message, "Lantern: no wicks left")
  eq(list(buttonsOf(gm.bar().html)), "Reveal | Reveal part… | Refund a wick | Unmark found")
  has(textOf(gm.bar().html), "○○○○○○ 0 of 6 wicks left")
  click(gm.bar(), "Refund a wick")
  eq(lastNotification().message, "Lantern: a wick refunded. 1 of 6 wicks left.")
  has(H.pages[RECORD], "- [[Sessions/Session 1|Session 1]]: a wick refunded, 1 left\n")
  for _ = 1, 5 do ok(gm.spend(LANTERN, 1), "a wick to refund") end
  eq(gm.spend(LANTERN, 1), false)
  eq(lastNotification().message, "Lantern: all 6 wicks are there already")
end)

test("kit: found on its own page, the lantern takes the count from the page that hands it out", "dm", function()
  H.current = LANTERN
  local bar = gm.bar()
  eq(list(buttonsOf(bar.html)), "Reveal | Reveal part… | Mark found")
  click(bar, "Mark found")
  has(H.pages[RECORD], "\nuses: 6\n")
  has(H.pages[RECORD], 'found_in: "[[' .. SCENE2 .. ']]"')
  has(textOf(gm.bar().html), "[[" .. RECORD .. "|Play state]]")
end)

test("kit: when several pages hand an item out, finding it asks where", "dm", function()
  H.pages["Adventure/Campaign/Act II/Scene 1"] = "---\ntype: scene\n---\n\n# Later\n\n" ..
    "Another lantern, with ${party.count{\"wick\", item = \"Lantern\"}}.\n"
  useParty(7, 1)
  H.current = LANTERN
  H.picks = { "Campaign/Act II/Scene 1" }
  gm.markFound(LANTERN)
  local box = H.filterBoxes[#H.filterBoxes]
  eq(box.help, "Where did the party find Lantern?")
  eq(list(names(box.options)), "Campaign/Act I/Scene 2 | Campaign/Act II/Scene 1")
  eq(box.options[1].description, "eight wicks")
  has(H.pages[RECORD], "\nuses: 7\n")
  eq(lastNotification().message, "Lantern: found in session 1, with seven wicks.")
  H.pages[RECORD] = nil
  H.picks = { NIL }
  eq(gm.markFound(LANTERN), false, "cancelling the picker records nothing")
  eq(H.pages[RECORD], nil)
end)

test("kit: the count follows the party as it is when the lantern is found, not after", "dm", function()
  useParty(3, 1)
  gm.markFound(LANTERN, SCENE2)
  has(H.pages[RECORD], "\nuses: 4\n")
  useParty(7, 1)
  eq(gm.usesText(gm.readState(LANTERN)), "●●●● 4 of 4 wicks left")
end)

test("kit: an item nothing hands out is found without uses", "dm", function()
  H.pages["Adventure/World/Items/Key"] = "---\ntype: item\n---\n\n# Key\n"
  H.current = "Adventure/World/Items/Key"
  eq(list(buttonsOf(gm.bar().html)), "Reveal | Mark found")
  click(gm.bar(), "Mark found")
  local state = H.pages["State/Items/Key"]
  has(state, "found: true\nfound_session: 1\n")
  hasnt(state, "uses")
  eq(lastNotification().message, "Key: found in session 1.")
  eq(list(buttonsOf(gm.bar().html)), "Reveal | Unmark found")
  eq(gm.spend("Adventure/World/Items/Key", -1), false)
  eq(lastNotification().message, "Key has no uses to count")
end)

test("kit: a page that shows an item's rules gets a row for it", "dm", function()
  local scene3 = "Adventure/Campaign/Act I/Scene 3"
  H.pages[scene3] = "---\ntype: scene\n---\n\n# Scene 3\n\nThe tinker explains.\n\n![[World/Items/Lantern#Rules]]\n\n" ..
    "```\n![[World/Items/Key#Rules]]\n```\n\nWrite `![[World/Items/Key#Rules]]` to show the key's.\n"
  H.pages["Adventure/World/Items/Key"] = "---\ntype: item\n---\n\n# Key\n"
  local bar = gm.bar(scene3)
  eq(list(buttonsOf(bar.html)), "Reveal | Mark planned | Mark started | Mark found",
     "one row, and none for code or inline code")
  hasnt(textOf(bar.html), "wicks here", "Scene 3 doesn't hand it out")
  H.current = scene3
  click(bar, "Mark found")
  has(H.pages[RECORD], "\nuses: 6\n", "Scene 2's count")
  has(H.pages[RECORD], 'found_in: "[[' .. SCENE2 .. ']]"')
  eq(list(buttonsOf(gm.bar().html)), "Reveal | Mark planned | Mark started | Use a wick | Unmark found | Reveal")
end)

test("kit: the item commands act on the page's one item, or ask", "dm", function()
  H.current = "Session Table"
  H.commands["GM: Spend Use"].run()
  eq(lastNotification().message, "Nothing the party found has a use left")
  H.commands["GM: Refund Use"].run()
  eq(lastNotification().message, "Nothing the party found is missing a use")
  H.current = SCENE2
  H.commands["GM: Mark Found"].run()
  has(H.pages[RECORD], "\nuses: 6\n", "acts at once on the scene's one item")
  H.commands["GM: Spend Use"].run()
  has(H.pages[RECORD], "\nuses: 5\n")
  H.current = "Session Table"
  H.picks = { "World/Items/Lantern" }
  H.commands["GM: Refund Use"].run()
  has(H.pages[RECORD], "\nuses: 6\n")
  eq(H.filterBoxes[#H.filterBoxes].options[1].description, "5 of 6 wicks left")
  -- an item not found yet, whose name sorts after the lantern's
  H.pages["Adventure/World/Items/Rope"] = "---\ntype: item\n---\n\n# Rope\n"
  H.picks = { "World/Items/Lantern" }
  H.commands["GM: Mark Found"].run()
  local box = H.filterBoxes[#H.filterBoxes]
  eq(list(names(box.options)), "World/Items/Rope | World/Items/Lantern", "found items go last")
  eq(box.options[#box.options].description, "Found in session 1")
  eq(lastNotification().message, "Lantern: already recorded. Found in session 1.")
end)

test("kit: uses read the same everywhere, with pips only for small counts", "dm", function()
  local wicks = { uses = "4", uses_found = "6", unit = "wick", units = "wicks" }
  eq(gm.usesText(wicks), "●●●●○○ 4 of 6 wicks left")
  eq(gm.usesText(wicks, true), "4 of 6 wicks left")
  eq(gm.usesText({ uses = 1, uses_found = 1, unit = "charge", units = "charges" }), "● 1 of 1 charge left")
  eq(gm.usesText({ uses = 13, uses_found = 20, unit = "arrow", units = "arrows" }), "13 of 20 arrows left")
  eq(gm.usesText({ uses = 2 }), "2 uses left")
  eq(gm.usesText({}), "")
end)

test("kit: buttons and notifications name the use with the right article", "dm", function()
  local function state(unit, units)
    H.pages["State/Items/Thing"] = "---\ntype: state-record\nfound: true\nfound_session: 1\nuses: 2\n" ..
      "uses_found: 3\n" .. (unit and ("unit: " .. unit .. "\nunits: " .. units .. "\n") or "") ..
      "---\n\n# Thing\n\n## Log\n\n"
  end
  H.pages["Adventure/World/Items/Thing"] = "---\ntype: item\n---\n\n# Thing\n"
  for _, c in ipairs({ { "arrow", "arrows", "Use an arrow | Refund an arrow | Unmark found" },
                       { "use", "uses", "Use a use | Refund a use | Unmark found" },
                       { "umbrella", "umbrellas", "Use an umbrella | Refund an umbrella | Unmark found" },
                       { nil, nil, "Use a use | Refund a use | Unmark found" } }) do
    state(c[1], c[2])
    eq(list(buttonsOf(gm.bar("Adventure/World/Items/Thing").html)), "Reveal | " .. c[3])
  end
  gm.spend("Adventure/World/Items/Thing", -1)
  eq(lastNotification().message, "Thing: a use used. 1 of 3 uses left.")
end)

test("kit: the Session Table and The Party list what was found", "dm", function()
  for _, page in ipairs({ "Session Table", "The Party" }) do
    has(H.pages[page], "p.found == true", page)
    has(H.pages[page], "gm.usesText(p)", page)
  end
  -- and so does any other page that lists play state, such as the DM index
  has(H.pages["index"], "Found = p.found")
  for name, text in pairs(H.pages) do
    if text:find('p.type == "state-record"', 1, true) then has(text, "p.found", name) end
  end
end)
