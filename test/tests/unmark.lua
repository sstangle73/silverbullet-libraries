------------------------------------------------------------------ Unmark

local WARDEN = "Adventure/World/People/The Warden"
local LOW_COUNTRY = "Adventure/World/Places/The Low Country"
-- Scene 2 hands out the lantern: ${party.count{"wick", plus = 1, item = ...}}
local SCENE2 = "Adventure/Campaign/Act I/Scene 2"
local LANTERN = "Adventure/World/Items/Lantern"
local LANTERN_STATE = "State/Items/Lantern"

test("kit: a session is named and linked, and says so when there isn't one", "dm", function()
  eq(gm.sessionLink(3), "[[Sessions/Session 3|session 3]]")
  eq(gm.sessionLink(3, true), "[[Sessions/Session 3|Session 3]]")
  eq(gm.sessionLink("1"), "[[Sessions/Session 1|session 1]]")
  eq(gm.sessionLink(nil), "session ?")
  eq(gm.sessionLink(nil, true), "Session ?")
  gm.config.sessionsFolder = "Nights/"
  eq(gm.sessionLink(2), "[[Nights/Session 2|session 2]]")
  gm.config.sessionsFolder = "Sessions/"
end)

test("kit: unmark takes a find back, uses and all, with undo", "dm", function()
  H.current = SCENE2
  click(gm.bar(), "Mark found")
  gm.spend(LANTERN, -1)
  H.current = LANTERN
  click(gm.bar(), "Unmark found")
  local state = H.pages[LANTERN_STATE]
  ok(state, "the record itself should stay, for its log")
  has(state, "type: state-record")
  hasnt(state, "found:")
  hasnt(state, "uses")
  hasnt(state, "unit")
  has(state, "- [[Sessions/Session 1|Session 1]]: found in")
  has(state, "- [[Sessions/Session 1|Session 1]]: a wick used, 5 left")
  has(state, "- [[Sessions/Session 1|Session 1]]: not found after all\n")
  eq(lastNotification().message, "Lantern: no longer marked found, and its uses with it.")
  eq(list(buttonsOf(gm.bar().html)), "Reveal | Mark found")
  local q = __liq(function() return index.pages() end,
    function(p) return p.type == "state-record" and p.found == true end, {}, nil, nil)
  eq(#q, 0, "the Session Table's Found list should let it go")
  runAction(lastNotification(), "Undo")
  has(H.pages[LANTERN_STATE], "\nuses: 5\n")
  has(H.pages[LANTERN_STATE], "found: true")
  eq(lastNotification().message, "Undone: Lantern is marked found again")
  eq(list(buttonsOf(gm.bar().html)), "Reveal | Use a wick | Refund a wick | Unmark found")
end)

test("kit: found again after an unmark counts the uses afresh", "dm", function()
  useParty(3, 1)
  gm.markFound(LANTERN, SCENE2)
  has(H.pages[LANTERN_STATE], "\nuses: 4\n")
  gm.spend(LANTERN, -1)
  gm.unmark(LANTERN, "found")
  useParty(7, 1)
  gm.markFound(LANTERN, SCENE2)
  has(H.pages[LANTERN_STATE], "\nuses: 8\n")
  has(H.pages[LANTERN_STATE], "uses_found: 8")
end)

test("kit: unmark met and visited, from the bar", "dm", function()
  H.current = WARDEN
  click(gm.bar(), "Mark met")
  ok(gm.isRevealed(WARDEN))
  click(gm.bar(), "Unmark met")
  local state = H.pages["State/People/The Warden"]
  hasnt(state, "met:")
  hasnt(state, "met_session")
  has(state, "- [[Sessions/Session 1|Session 1]]: not met after all\n")
  eq(lastNotification().message, "The Warden: no longer marked met.")
  ok(gm.isRevealed(WARDEN), "unmarking says nothing about what the players can see")
  eq(list(buttonsOf(gm.bar().html)), "Unreveal | Mark met | Mark dead…")
  H.current = LOW_COUNTRY
  click(gm.bar(), "Mark visited")
  click(gm.bar(), "Unmark visited")
  hasnt(H.pages["State/Places/The Low Country"], "visited:")
  eq(list(buttonsOf(gm.bar().html)), "Unreveal | Mark visited")
end)

test("kit: a mark that was never made can't come off", "dm", function()
  eq(gm.unmark(WARDEN, "met"), false)
  eq(lastNotification().message, "The Warden isn't marked met")
  gm.mark(WARDEN, "met")
  eq(gm.unmark(WARDEN, "dead"), false)
  eq(lastNotification().message, "The Warden isn't marked dead")
end)

test("kit: the Unmark command asks which page, and which mark when there are two", "dm", function()
  H.current = "Session Table"
  H.commands["GM: Unmark"].run()
  eq(lastNotification().message, "Nothing is marked yet")
  gm.mark(WARDEN, "met")
  H.prompts = { "Drowned" }
  gm.markDead(WARDEN)
  gm.mark(LOW_COUNTRY, "visited")
  H.picks = { "World/People/The Warden", "dead" }
  H.commands["GM: Unmark"].run()
  local who = H.filterBoxes[#H.filterBoxes - 1]
  eq(who.help, "What was marked by mistake?")
  eq(list(names(who.options)), "World/People/The Warden | World/Places/The Low Country")
  eq(who.options[1].description, "Met in session 1, Died in session 1")
  local which = H.filterBoxes[#H.filterBoxes]
  eq(which.help, "Which mark comes off The Warden?")
  eq(list(names(which.options)), "met | dead")
  hasnt(H.pages["State/People/The Warden"], "status: dead")
  has(H.pages["State/People/The Warden"], "met: true")
  eq(lastNotification().message, "The Warden: no longer marked dead.")
  H.current = LOW_COUNTRY
  H.commands["GM: Unmark"].run()
  hasnt(H.pages["State/Places/The Low Country"], "visited:")
end)

test("kit: the DM's own pages link each session they name", "dm", function()
  for _, page in ipairs({ "Session Table", "The Party" }) do
    has(H.pages[page], "gm.sessionLink(p.", page)
  end
  has(H.pages["Session Table"], '${widgets.commandButton("Unmark…", "GM: Unmark")}')
  gm.markFound(LANTERN, SCENE2)
  local rows = __liq(function() return index.pages() end,
    function(p) return p.type == "state-record" and p.found == true end, {},
    function(p) return { Session = gm.sessionLink(p.found_session, true) } end, nil)
  eq(rows[1].Session, "[[Sessions/Session 1|Session 1]]")
end)
