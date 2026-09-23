------------------------------------------------ GM Book: a tab behind its libraries

-- Space Lua is read when a client boots and not again, so a tab left open
-- over a Library: Update runs the old code over the new pages. A build from
-- it would print the book with code the pages weren't written for, and
-- write that over the book on the page. The index has the pages' own
-- versions; the tab's Lua has its own.

-- A library page as a newer release would leave it: the same page with
-- another version in its frontmatter.
local function release(page, version)
  H.pages[page] = (H.pages[page]:gsub('\nversion: "[^"\n]*"\n', '\nversion: "' .. version .. '"\n', 1))
end

local function frontmatterVersion(lib)
  return SRC[lib]:match('\nversion: "([^"\n]+)"\n')
end

test("book: gmbook.version is the page's own version", "adventure", function()
  ok(frontmatterVersion("GM Book"), "the page gives a version")
  eq(gmbook.version, frontmatterVersion("GM Book"), "the Lua and the frontmatter agree")
  eq(maps.version, frontmatterVersion("GM Maps"), "and GM Maps' too")
end)

test("book: a tab running the space's libraries is not stale", "adventure", function()
  eq(gmbook.stale(), nil)
  eq(maps.stale(), nil)
  eq(#gmbook.staleLibraries(), 0)
end)

test("book: a tab behind the space's GM Book builds nothing, and says why", "adventure", function()
  H.current = "index"
  gmbook.compile({ "dm", "player" })
  local before = { dm = H.pages["Build/Book DM"], player = H.pages["Build/Book Player"] }
  release("Library/Storie/GM Book", "9.9.9")
  H.writes = {}
  local report = gmbook.build({ "dm", "player" })
  eq(report, nil, "no build ran")
  eq(#H.writes, 0, "nothing written")
  eq(H.pages["Build/Book DM"], before.dm, "the editions on the page are left as they were")
  eq(#H.progress, 0, "and no ring was started")
  local n = lastNotification()
  eq(n.kind, "warning")
  has(n.message, "The book wasn't built. This tab runs GM Book " .. gmbook.version ..
    ", but the space has 9.9.9: reload it (System: Reload, Ctrl-Alt-R) before building.")
  ok(not gmbook.building, "and the next build isn't blocked by this one")
  -- System: Reload is a tap away, since a phone has no Ctrl-Alt-R
  local reloads = 0
  H.commands["System: Reload"] = { name = "System: Reload", run = function() reloads = reloads + 1 end }
  runAction(n, "Reload")
  eq(reloads, 1, "the notification reloads the tab")

  -- the bar says so first, with a glyph and words, not a colour alone
  local bar = gmbook.bar("Build/Book DM").html
  eq(bar.children[1].attrs.class, "gmbook-bar-stale", "the first thing on the bar")
  has(textOf(bar.children[1]), "⟳ **Reload this tab:** This tab runs GM Book " .. gmbook.version ..
    ", but the space has 9.9.9")
  eq(list(buttonsOf(bar)), "Reload | Build again | Copy for Homebrewery | Open Homebrewery",
    "a Reload beside it, and its buttons as ever")
  click(bar, "Reload")
  eq(reloads, 2, "and so does the bar")

  -- reloaded, which here means the page and the tab agree again
  release("Library/Storie/GM Book", gmbook.version)
  eq(gmbook.stale(), nil)
  hasnt(textOf(gmbook.bar("Build/Book DM").html), "Reload this tab")
  eq(#gmbook.build({ "dm", "player" }).written, 2, "and it builds")
end)

test("book: a library the book prints with that is behind refuses the build, named", "adventure", function()
  H.current = "index"
  release("Library/Storie/GM Maps", "2.0.0")
  gmbook.printers.mylib = { stale = function() return "This tab runs My Lib 1, but the space has 2." end }
  local report = gmbook.build({ "dm", "player" })
  eq(report, nil)
  local n = lastNotification().message
  has(n, "This tab runs GM Maps " .. maps.version .. ", but the space has 2.0.0")
  has(n, "This tab runs My Lib 1, but the space has 2.")
  hasnt(n, "GM Book " .. gmbook.version .. ",", "GM Book itself is current")
  ok(n:find("GM Maps", 1, true) < n:find("My Lib", 1, true), "in the order of their printers' names")
  gmbook.printers.mylib = nil
  release("Library/Storie/GM Maps", maps.version)
  eq(#gmbook.build({ "dm", "player" }).written, 2)
end)

test("book: a stale check that fails, or a library without one, never stops a build", "adventure", function()
  H.current = "index"
  gmbook.printers.mylib = { stale = function() error("boom") end }
  gmbook.printers.other = { draw = function() return "x" end }
  local real = index.pages
  index.pages = function() error("the index is rebuilding") end
  local fine, got = pcall(gmbook.stale)
  index.pages = real
  ok(fine, "gmbook.stale never raises")
  eq(got, nil, "and says nothing when it can't tell")
  eq(#gmbook.staleLibraries(), 0)
  eq(#gmbook.build({ "dm", "player" }).written, 2)
end)

test("book: a copy of GM Book at another depth with another version is named", "dm", function()
  H.pages["Library/Storie/GM Book"] = H.pages["Adventure/Library/Storie/GM Book"]
  release("Library/Storie/GM Book", "1.0.0")
  local stale = gmbook.stale()
  ok(stale, "a copy at another version is stale")
  has(stale, "This tab runs GM Book " .. gmbook.version .. ", but Library/Storie/GM Book has 1.0.0")
  has(stale, "remove the copy you don't use")
  -- the same version at two depths is no stale tab
  release("Library/Storie/GM Book", gmbook.version)
  eq(gmbook.stale(), nil)
end)

test("book: a version that isn't text is no reason to refuse", "adventure", function()
  -- version: 1.14 unquoted is a number to YAML; nothing to compare it with
  H.pages["Library/Storie/GM Book"] = (H.pages["Library/Storie/GM Book"]:gsub(
    '\nversion: "[^"\n]*"\n', "\nversion: 1.14\n", 1))
  eq(gmbook.stale(), nil)
end)
