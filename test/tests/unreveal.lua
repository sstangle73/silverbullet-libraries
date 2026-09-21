------------------------------------------------------------------ Unreveal (GM Kit 2.4)

local U_WARDEN = "Adventure/World/People/The Warden"
local U_WARDEN_COPY = "Player/World/People/The Warden"
local U_SCENE2 = "Adventure/Campaign/Act I/Scene 2"
local U_LANTERN = "Adventure/World/Items/Lantern"
local U_LANTERN_COPY = "Player/World/Items/Lantern"

-- How many pages the fixture's State/Revealed lists: one "- [[...]]" line
-- each, and the button line above them isn't one.
local U_REVEALED = count(FIXTURES.dm["State/Revealed"], "\n- [[")

local function itemRowOf(root)
  root = root.html or root
  local function find(node)
    if type(node) ~= "table" then return nil end
    if node.attrs and node.attrs.class == "gmkit-item" then return node end
    for _, c in ipairs(node.children or {}) do
      local f = find(c)
      if f then return f end
    end
  end
  return find(root)
end

test("unreveal: visibility follows the list and the players' copy", "dm", function()
  eq(gm.visibility(U_WARDEN), "hidden")
  gm.setRevealed(U_WARDEN, true)
  eq(gm.visibility(U_WARDEN), "revealed")
  H.pages[U_WARDEN_COPY] = "# The Warden\n"
  eq(gm.visibility(U_WARDEN), "published")
  gm.setRevealed(U_WARDEN, false)
  eq(gm.visibility(U_WARDEN), "stale")
  eq(gm.visibility("Adventure/index"), "hidden", "a page publishing skips has no copy")
end)

test("unreveal: a copy left behind shows on the bar and goes, with undo", "dm", function()
  H.current = U_WARDEN
  H.pages[U_WARDEN_COPY] = "# The Warden\n\nAn old copy.\n"
  local bar = gm.bar()
  has(textOf(bar.html), "◐ Not revealed, but the players still have a copy")
  hasnt(textOf(bar.html), "○ Hidden from players")
  eq(list(buttonsOf(bar.html)), "Delete their copy | Reveal | Mark met | Mark dead…")
  click(bar, "Delete their copy")
  eq(H.pages[U_WARDEN_COPY], nil)
  ok(not gm.isRevealed(U_WARDEN), "deleting a copy must not reveal")
  local n = lastNotification()
  eq(n.message, "Deleted the players' copy of The Warden, which wasn't revealed any more.")
  has(textOf(gm.bar().html), "○ Hidden from players")
  runAction(n, "Undo")
  eq(H.pages[U_WARDEN_COPY], "# The Warden\n\nAn old copy.\n")
  ok(not gm.isRevealed(U_WARDEN), "undo must not reveal either")
  eq(lastNotification().message, "Undone: The Warden is back with the players")
end)

test("unreveal: nothing to take back does nothing", "dm", function()
  local writes = #H.writes
  eq(gm.unreveal(U_WARDEN), false)
  eq(lastNotification().message, "The Warden isn't revealed, and the players have no copy of it")
  eq(#H.writes, writes)
  eq(#H.deleted, 0)
end)

test("unreveal: a revealed page that was never published, with undo", "dm", function()
  local page = "Adventure/World/Factions/The Guild"
  H.current = page
  click(gm.bar(), "Unreveal")
  ok(not gm.isRevealed(page))
  eq(#H.deleted, 0, "there was no copy to delete")
  eq(lastNotification().message,
     "Unrevealed The Guild. It was never published, so the players never had it.")
  runAction(lastNotification(), "Undo")
  ok(gm.isRevealed(page))
  eq(lastNotification().message, "Undone: The Guild is revealed again")
end)

-- Everything revealed and published, one more revealed since, and a copy
-- the players kept of a page that came off the list.
test("unreveal: the picker lists what the players can see or still have", "dm", function()
  H.confirms = { true }
  gm.publish()
  gm.setRevealed("Adventure/World/Places/Fordtown", true)
  H.pages[U_WARDEN_COPY] = "left behind"
  H.current = "Session Table"
  H.picks = { "World/People/The Warden" }
  H.commands["GM: Unreveal Page"].run()
  local box = H.filterBoxes[1]
  eq(box.help, "Which page should the players lose?")
  local notes = {}
  for _, o in ipairs(box.options) do notes[o.name] = o.description end
  eq(notes["Rules/House Rules"], "Published")
  eq(notes["World/Places/Fordtown"], "Revealed, not published yet")
  eq(notes["World/People/The Warden"], "Not revealed, but the players still have a copy")
  eq(notes["World/People/Mara"], nil, "a hidden page has nothing to take back")
  eq(#box.options, U_REVEALED + 2)
  eq(box.options[#box.options].name, "World/People/The Warden", "copies left behind come last")
  eq(H.pages[U_WARDEN_COPY], nil)
  eq(H.current, "Session Table", "shouldn't navigate")
end)

test("unreveal: the old Hide Page command and gm.hide unreveal too", "dm", function()
  H.confirms = { true }
  gm.publish()
  H.current = "Adventure/Rules/Travel"
  ok(H.pages["Player/Rules/Travel"], "Travel should have been published")
  H.commands["GM: Hide Page"].run()
  ok(not gm.isRevealed(H.current))
  eq(H.pages["Player/Rules/Travel"], nil)
  ok(gm.hide("Adventure/Rules/House Rules"))
  eq(H.pages["Player/Rules/House Rules"], nil)
end)

test("unreveal: the revealed list's own button unreveals", "dm", function()
  gm.setRevealed("Adventure/Campaign/Act I", true)
  has(H.pages["State/Revealed"], '${widgets.commandButton("Unreveal a page…", "GM: Unreveal Page")}')
  hasnt(H.pages["State/Revealed"], "GM: Hide Page")
  eq(#gm.readRevealed(), U_REVEALED + 1, "the button line mustn't read as a revealed page")
end)

test("unreveal: unrevealing while the revealed list is open reloads it", "dm", function()
  H.current = "State/Revealed"
  H.picks = { "Rules/House Rules" }
  local reloads = H.reloads
  H.commands["GM: Unreveal Page"].run()
  ok(H.reloads > reloads)
end)

test("unreveal: an item's row stays quiet while the players can see it", "dm", function()
  gm.markFound(U_LANTERN, U_SCENE2)
  H.current = U_SCENE2
  local row = itemRowOf(gm.bar())
  ok(row, "no row for the lantern")
  has(textOf(row), "○ Hidden from players")
  eq(list(buttonsOf(row)), "Use a wick | Unmark found | Reveal")
  gm.setRevealed(U_LANTERN, true)
  row = itemRowOf(gm.bar())
  hasnt(textOf(row), "Hidden")
  hasnt(textOf(row), "Revealed")
  eq(list(buttonsOf(row)), "Use a wick | Unmark found")
  gm.setRevealed(U_LANTERN, false)
  H.pages[U_LANTERN_COPY] = "# Lantern\n"
  row = itemRowOf(gm.bar())
  has(textOf(row), "◐ Not revealed, but the players still have a copy")
  eq(list(buttonsOf(row)), "Use a wick | Unmark found | Delete their copy | Reveal")
  click(row, "Delete their copy")
  eq(H.pages[U_LANTERN_COPY], nil)
end)

test("unreveal: tonight's mistake, a found item revealed and published, taken back", "dm", function()
  gm.markFound(U_LANTERN, U_SCENE2)
  H.current = U_LANTERN
  click(gm.bar(), "Reveal")
  H.confirms = { true }
  gm.publish()
  ok(H.pages[U_LANTERN_COPY], "the lantern should have been published")
  has(textOf(gm.bar().html), "◉ Revealed to players")
  click(gm.bar(), "Unreveal")
  eq(H.pages[U_LANTERN_COPY], nil, "the players' copy should be gone")
  ok(not gm.isRevealed(U_LANTERN))
  ok(H.pages["State/Items/Lantern"], "unrevealing must leave the play state alone")
  has(H.pages["State/Items/Lantern"], "found: true")
  eq(list(buttonsOf(gm.bar().html)), "Reveal | Use a wick | Unmark found")
  H.confirms = { true }
  gm.publish()
  eq(H.pages[U_LANTERN_COPY], nil, "a later publish mustn't bring it back")
end)

test("unreveal: a space's CONFIG is never published over, nor taken back", "dm", function()
  ok(H.pages["Adventure/CONFIG"] and H.pages["Player/CONFIG"], "the fixture has both CONFIG pages")
  eq(gm.playerCopy("Adventure/CONFIG"), nil)
  eq(gm.playerCopy("Adventure/Library/Storie/GM Book"), nil)
  eq(gm.visibility("Adventure/CONFIG"), "hidden")
  eq(gm.bar("Adventure/CONFIG"), nil, "no bar on a settings page")
  for _, n in ipairs(gm.adventurePages()) do ok(n ~= "Adventure/CONFIG", "CONFIG offered as an adventure page") end
  local before = H.pages["Player/CONFIG"]
  gm.setRevealed("Adventure/CONFIG", true)
  H.confirms = { true }
  gm.publish()
  eq(H.pages["Player/CONFIG"], before, "publishing overwrote the Player space's CONFIG")
  ok(gm.unreveal("Adventure/CONFIG"), "it still comes off the list")
  eq(H.pages["Player/CONFIG"], before, "unrevealing deleted the Player space's CONFIG")
end)
