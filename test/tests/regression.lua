------------------------------------------------------------------ Regressions (the 2026-09-21 review)
-- A test for each bug the review found and GM Kit 3.2, GM Book 1.8.2,
-- GM Maps 1.2.2 and GM Bestiary 1.0.1 fixed, named in its section's comment.
-- Each fails on the code before its fix, with two exceptions: "undoing a
-- scene start that began the log takes the log away again" pins behaviour
-- the Undo rewrite kept, and "a path with . or .. in it names no page"
-- pins a guard against an error only SilverBullet raises, not these mocks.

local R_WARDEN = "Adventure/World/People/The Warden"
local R_SCENE1 = "Adventure/Campaign/Act I/Scene 1"
local R_SCENE2 = "Adventure/Campaign/Act I/Scene 2"
local R_LANTERN = "Adventure/World/Items/Lantern"
local R_ORCHARD = "Adventure/World/Maps/The Old Orchard"
local R_STRANGLER = "Adventure/World/Monsters/Strangler"
local R_NL = string.char(10)

------------------------------------------------ a page's existence (KIT-1)

test("kit: only a page of exactly that name exists", "dm", function()
  ok(space.pageExists("World/Items/Lantern"), "SilverBullet's own answer: any path that ends so")
  ok(not gm.exists("World/Items/Lantern"))
  ok(gm.exists(R_LANTERN))
  ok(not gm.exists("State/People/Nobody"))
end)

test("kit: a second mark keeps the first, though the file list lags behind", "dm", function()
  freezeFileList()
  ok(gm.mark(R_WARDEN, "met"))
  ok(gm.mark(R_WARDEN, "dead"))
  local state = gm.readState(R_WARDEN)
  eq(state.met, "true", "the met mark survives the second write")
  eq(state.status, "dead")
  local record = H.pages["State/People/The Warden"]
  has(record, ": met\n")
  has(record, ": died\n")
end)

test("kit: a decision logged straight after a scene starts keeps the scene's line", "dm", function()
  freezeFileList()
  ok(gm.mark(R_SCENE1, "started"))
  H.prompts = { "Took the deal" }
  ok(gm.logDecision())
  local log = H.pages["Sessions/Session 1"]
  has(log, "- Started: [[" .. R_SCENE1 .. "|")
  has(log, "- Took the deal\n")
end)

------------------------------------------------ Undo takes back its own action (KIT-4)

test("kit: undoing a mark keeps a later mark on the same page", "dm", function()
  gm.mark(R_WARDEN, "met")
  local met = lastNotification()
  gm.mark(R_WARDEN, "dead")
  runAction(met, "Undo")
  local state = gm.readState(R_WARDEN)
  eq(state.met, nil, "the met mark is gone")
  eq(state.met_session, nil)
  eq(state.status, "dead", "the death marked after it stays")
  local record = H.pages["State/People/The Warden"]
  hasnt(record, ": met\n")
  has(record, ": died\n")
  ok(not gm.isRevealed(R_WARDEN), "the reveal the met mark made goes with it")
end)

test("kit: undoing a scene start keeps a decision logged after it", "dm", function()
  gm.mark(R_SCENE1, "started")
  local started = lastNotification()
  H.prompts = { "Took the deal" }
  gm.logDecision()
  runAction(started, "Undo")
  local log = H.pages["Sessions/Session 1"]
  ok(log, "the log stays: it holds a decision")
  hasnt(log, "Started:")
  has(log, "## Decisions\n\n- Took the deal\n")
  eq(gm.readState(R_SCENE1).started, nil)
end)

test("kit: undoing a scene start that began the log takes the log away again", "dm", function()
  gm.mark(R_SCENE1, "started")
  runAction(lastNotification(), "Undo")
  eq(H.pages["Sessions/Session 1"], nil)
  eq(H.pages["State/Scenes/Act I/Scene 1"], nil)
end)

test("kit: undoing an earlier use keeps a later one", "dm", function()
  -- Scene 2 hands the lantern out with six wicks: one more than the party of five
  gm.markFound(R_LANTERN, R_SCENE2)
  gm.spend(R_LANTERN, -1)
  local first = lastNotification()
  gm.spend(R_LANTERN, -1)
  eq(gm.readState(R_LANTERN).uses, "4")
  runAction(first, "Undo")
  eq(gm.readState(R_LANTERN).uses, "5", "one wick back, and the later use still made")
  local record = H.pages["State/Items/Lantern"]
  hasnt(record, "a wick used, 5 left", "the undone use's line goes")
  has(record, "a wick used, 4 left", "the later one's stays")
end)

test("kit: undoing an unmark keeps a mark made after it", "dm", function()
  gm.mark(R_WARDEN, "met")
  gm.unmark(R_WARDEN, "met")
  local unmarked = lastNotification()
  gm.mark(R_WARDEN, "dead")
  runAction(unmarked, "Undo")
  local state = gm.readState(R_WARDEN)
  eq(state.met, "true", "met again")
  eq(state.met_session, "1")
  eq(state.status, "dead", "and the death since stays")
  hasnt(H.pages["State/People/The Warden"], "not met after all")
end)

------------------------------------------------ a map page stays the DM's (PM-1)

test("kit: a map page is never revealed, and its bar says so", "dm", function()
  H.current = R_ORCHARD
  local bar = gm.bar()
  has(textOf(bar.html), "⊘ Only for the DM: never revealed")
  for _, label in ipairs(buttonsOf(bar.html)) do
    ok(label ~= "Reveal", "no Reveal on a map page's bar")
  end
  eq(gm.reveal(R_ORCHARD), false)
  has(lastNotification().message, "never revealed or published")
  ok(not gm.isRevealed(R_ORCHARD))
end)

test("kit: publishing leaves out a map page on the revealed list, and names it", "dm", function()
  gm.setRevealed(R_ORCHARD, true) -- as a list from before 3.2 may hold it
  gm.setRevealed(R_WARDEN, true)
  H.confirms = { true }
  ok(gm.publish())
  eq(H.pages["Player/World/Maps/The Old Orchard"], nil, "the map's source never reaches the players")
  ok(H.pages["Player/World/People/The Warden"], "the rest publishes as before")
  local n = lastNotification()
  eq(n.kind, "warning")
  has(n.message, "Left out, as only the DM may see them: " .. R_ORCHARD)
  hasnt(n.message, "still have a copy", "the players never had it")
end)

test("kit: publishing names a map page the players still have a copy of", "dm", function()
  H.pages["Player/World/Maps/The Old Orchard"] = H.pages[R_ORCHARD] -- sent before 3.2
  gm.setRevealed(R_WARDEN, true)
  H.confirms = { true }
  ok(gm.publish())
  local n = lastNotification()
  eq(n.kind, "warning")
  has(n.message, "The players still have a copy of " .. R_ORCHARD)
  has(n.message, "Delete their copy")
end)

test("kit: with only map pages revealed there is nothing to publish, and it says why", "dm", function()
  gm.writeRevealed({ R_ORCHARD })
  eq(gm.publish(), false)
  local n = lastNotification()
  has(n.message, "Nothing to publish. Left out, as only the DM may see them: " .. R_ORCHARD)
  hasnt(n.message, "Nothing is revealed yet")
end)

test("kit: a map page is private however YAML writes its type", "dm", function()
  local text = H.pages[R_ORCHARD]
  for _, t in ipairs({ "'map'", '"map"', "map # the clearing", '"map" # quoted, with a note' }) do
    local typed, n = text:gsub("\ntype: map\n", "\ntype: " .. t .. "\n", 1)
    eq(n, 1, "the orchard's page is typed map to begin with")
    H.pages[R_ORCHARD] = typed
    ok(gm.isPrivate(R_ORCHARD), "type: " .. t)
    eq(gm.reveal(R_ORCHARD), false, "type: " .. t)
  end
end)

test("kit: a map page GM Maps is told to type differently is private too", "dm", function()
  config.set("gmMaps", { type = "encounter" })
  local typed, n = H.pages[R_ORCHARD]:gsub("\ntype: map\n", "\ntype: encounter\n", 1)
  eq(n, 1, "the orchard's page is typed map to begin with")
  H.pages[R_ORCHARD] = typed
  ok(gm.isPrivate(R_ORCHARD))
  eq(gm.reveal(R_ORCHARD), false)
end)

test("kit: taking a map page's copy back has no Undo that would send it again", "dm", function()
  H.current = R_ORCHARD
  H.pages["Player/World/Maps/The Old Orchard"] = H.pages[R_ORCHARD]
  click(gm.bar(), "Delete their copy")
  local n = lastNotification()
  eq(H.pages["Player/World/Maps/The Old Orchard"], nil)
  eq((n.options or {}).actions, nil, "no Undo on it")
end)

test("kit: the reveal picker leaves map pages out", "dm", function()
  H.current = "Session Table"
  H.picks = { NIL }
  H.commands["GM: Reveal Page"].run()
  local names = {}
  for _, o in ipairs(H.filterBoxes[#H.filterBoxes].options) do names[#names + 1] = o.name end
  hasnt(list(names), "World/Maps/The Old Orchard")
  has(list(names), "World/People/The Warden")
end)

test("kit: a map page's copy from before can be taken back from its bar", "dm", function()
  H.current = R_ORCHARD
  H.pages["Player/World/Maps/The Old Orchard"] = H.pages[R_ORCHARD]
  local bar = gm.bar()
  has(textOf(bar.html), "◐ Only for the DM, but the players have a copy")
  click(bar, "Delete their copy")
  eq(H.pages["Player/World/Maps/The Old Orchard"], nil)
end)

------------------------------------------------ a players' copy keeps only type and tags (KIT-7)

test("kit: publishing keeps only a page's type and tags", "dm", function()
  local tinker = "Adventure/World/People/The Tinker"
  -- a key left empty goes as well as one with a value
  local text, n = H.pages[tinker]:gsub(R_NL .. "status: stub" .. R_NL,
    R_NL .. "price: " .. R_NL .. "status: stub" .. R_NL, 1)
  eq(n, 1, "the Tinker's page has a status")
  H.pages[tinker] = text
  gm.setRevealed(tinker, true)
  H.confirms = { true }
  gm.publish()
  local copy = H.pages["Player/World/People/The Tinker"]
  ok(copy, "published")
  eq(copy:match("^%-%-%-\n(.-)\n%-%-%-"), "type: npc", "only the page's type")
  for _, key in ipairs({ "role:", "faction:", "region:", "status:", "book_order:", "price:" }) do
    hasnt(copy, key)
  end
end)

test("kit: a players' copy keeps a tags list whole, and loses frontmatter with nothing to keep", "dm", function()
  local text = "---" .. R_NL .. "role: villain" .. R_NL .. "tags:" .. R_NL .. "  - court" .. R_NL ..
               "  - ford" .. R_NL .. "status: draft" .. R_NL .. "---" .. R_NL .. R_NL .. "# The Warden" .. R_NL
  eq(gm.publicFrontmatter(text),
     "---" .. R_NL .. "tags:" .. R_NL .. "  - court" .. R_NL .. "  - ford" .. R_NL .. "---" .. R_NL .. R_NL .. "# The Warden" .. R_NL)
  eq(gm.publicFrontmatter("---" .. R_NL .. "role: villain" .. R_NL .. "---" .. R_NL .. R_NL .. "# The Warden" .. R_NL),
     "# The Warden" .. R_NL)
end)

------------------------------------------------ a published page reads itself (BOOK-3)

test("kit: a published page's own expressions read that page, not the one open", "dm", function()
  H.current = "Session Table"
  gm.setRevealed(R_STRANGLER, true)
  H.confirms = { true }
  gm.publish()
  local copy = H.pages["Player/World/Monsters/Strangler"]
  ok(copy, "published")
  hasnt(copy, "No creature page for")
  -- the printed reference itself: "Vine Blight" alone is in the page's frontmatter
  has(copy, "[Vine Blight](https://www.dndbeyond.com/monsters/5195252-vine-blight)")
  eq(gm.printing, nil, "and the page it was printing is forgotten again")
end)

------------------------------------------------ copies don't hide their pages (PM-2, BOOK-4)

test("bestiary: a copy of a creature page elsewhere doesn't hide it in DM", "dm", function()
  H.pages["Player/World/Monsters/Strangler"] = H.pages[R_STRANGLER] -- as publishing leaves it
  bestiary.refresh()
  local c = bestiary.creature("World/Monsters/Strangler")
  ok(c, "still found")
  eq(c.page, R_STRANGLER)
end)

test("maps: a copy of a map page elsewhere doesn't hide it in DM", "dm", function()
  H.pages["Player/World/Maps/The Old Orchard"] = H.pages[R_ORCHARD] -- as a publish before 3.2 left it
  maps.refresh()
  local p = maps.find("World/Maps/The Old Orchard")
  ok(p, "still found")
  eq(p.name, R_ORCHARD)
  hasnt(maps.draw("World/Maps/The Old Orchard").html, "No map page")
end)

------------------------------------------------ doors on a growing map (MAPS-1)

local function rowsOf(m)
  local out = {}
  for _, row in ipairs((maps.grid(m))) do out[#out + 1] = table.concat(row) end
  return table.concat(out, "/")
end

local function howMany(s, ch)
  local n = 0
  for _ in s:gmatch(ch) do n = n + 1 end
  return n
end

test("maps: growing a map never copies a door or a thing in its wall", "adventure", function()
  local door = maps.parse(table.concat({ "##D##", "#...#", "#...#", "#...#", "#####", "",
    "grow to 7", "# wall wall", ". floor floor", "D door the hatch" }, R_NL))
  eq(howMany(rowsOf(door), "D"), 1, "one door before, one after: " .. rowsOf(door))
  local cart = maps.parse(table.concat({ "##O##", "#...#", "#...#", "#...#", "#####", "",
    "grow to 7", "# wall wall", ". floor floor", "O object [cart] a cart" }, R_NL))
  eq(howMany(rowsOf(cart), "O"), 1, "one cart: " .. rowsOf(cart))
end)

test("maps: shrinking a map never takes its only door", "adventure", function()
  local m = maps.parse(table.concat({ "###D###", "#.....#", "#.....#", "#.....#", "#.....#", "#.....#",
    "#######", "", "grow to 4", "# wall wall", ". floor floor", "D door the hatch" }, R_NL))
  eq(howMany(rowsOf(m), "D"), 1, "the only way in is kept: " .. rowsOf(m))
end)

------------------------------------------------ the book (FID-1, FID-2)

test("book: a transclusion named by the end of its path builds", "adventure", function()
  local scene = "Campaign/Act I/Scene 2"
  local text = H.pages[scene]
  local s, e = text:find("![[World/Items/Lantern#Rules]]", 1, true)
  ok(s, "Scene 2 shows the lantern's rules")
  H.pages[scene] = text:sub(1, s - 1) .. "![[Lantern#Rules]]" .. text:sub(e + 1)
  gmbook.compile({ "dm", "player" })
  has(H.pages["Build/Book DM"], "*See Lantern: Rules.*")
end)

test("book: a page at book_order 0 is in the book", "adventure", function()
  H.pages["Cover"] = "---" .. R_NL .. "book_order: 0" .. R_NL .. "---" .. R_NL .. R_NL ..
                     "# Cover" .. R_NL .. R_NL .. "The first page." .. R_NL
  local first = gmbook.pages("")[1]
  ok(first, "the book has pages")
  eq(first.name, "Cover")
end)

------------------------------------------------ the fix review's findings on 3.2 itself
-- The code before these fixes is 3.2's first draft, which this repository's
-- history doesn't hold. Two of them pass on 3.1, which never had the bug:
-- its bar asks the server nothing, and its Undo of an unmark writes the
-- whole record back.

test("kit: a bar asks the server about no page that isn't there", "dm", function()
  -- a look for a missing page goes to the server in SilverBullet; what a
  -- bar shows reads the client's own list for those
  H.metaMisses = 0
  gm.bar(R_SCENE2)
  gm.bar(R_WARDEN)
  eq(H.metaMisses, 0)
end)

test("kit: a mark whose session log can't be read writes nothing", "dm", function()
  H.pages["Session Table"] = (H.pages["Session Table"]:gsub("\nsession: 1\n", "\nsession: 2\n", 1))
  H.failMeta = { ["Sessions/Session 2"] = "Offline" }
  local good = pcall(gm.mark, R_SCENE1, "started")
  ok(not good, "the mark fails")
  eq(H.pages["State/Scenes/Act I/Scene 1"], nil, "and leaves no half of itself behind")
end)

test("kit: undoing an unmark brings back a record deleted since", "dm", function()
  gm.mark(R_WARDEN, "met")
  gm.unmark(R_WARDEN, "met")
  local unmarked = lastNotification()
  space.deletePage("State/People/The Warden")
  runAction(unmarked, "Undo")
  eq(gm.readState(R_WARDEN, true).met, "true", "met again, as the notification says")
end)

test("kit: undoing out of order leaves no empty session log", "dm", function()
  gm.mark(R_SCENE1, "started")
  local started = lastNotification()
  gm.mark(R_SCENE2, "planned")
  local planned = lastNotification()
  runAction(started, "Undo")
  ok(H.pages["Sessions/Session 1"], "the planned line keeps the log")
  runAction(planned, "Undo")
  eq(H.pages["Sessions/Session 1"], nil, "a log with nothing in it goes")
end)

test("kit and book: a path with . or .. in it names no page", "dm", function()
  ok(not gm.exists("../Adventure/index"))
  ok(not gm.exists("Adventure/../index"))
  ok(not gmbook.exists("./Adventure/index"))
  ok(not gmbook.exists("Adventure/World/.."))
  ok(gmbook.exists("Adventure/index"))
end)
