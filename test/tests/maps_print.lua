------------------------------------------------------ GM Maps: on the page and in print

local ORCHARD = "World/Maps/The Old Orchard"

-- A map widget the browser draws while a build prints some other page is
-- on the page, not in print: it reads the page it is on, and tonight's
-- party. A page read inside the build stands in for the yield it happens in.
test("maps: a map drawn on the page while a build prints draws as it does on the page", "adventure", function()
  useParty(7, 1)       -- tonight's table is bigger than the adventure's five
  maps.refresh()
  H.current = ORCHARD
  local here, named = maps.draw(), maps.draw(ORCHARD)
  has(here.html, "<svg", "the page's own map draws")
  local duringHere, duringNamed
  local real, busy = space.readPage, false
  space.readPage = function(name)
    if gmbook.printing and not busy and not duringHere then
      busy = true
      duringHere, duringNamed = maps.draw(), maps.draw(ORCHARD)
      busy = false
    end
    return real(name)
  end
  local fine, err = pcall(gmbook.compile, { "dm" })
  space.readPage = real
  assert(fine, err)
  ok(duringHere, "nothing was drawn while a page printed")
  eq(duringHere.html, here.html, "the open page's own map, drawn for tonight's party")
  eq(duringNamed.html, named.html, "a map named on the page, drawn for tonight's party")
end)

test("maps: in print, a map with no page named draws the page being printed", "adventure", function()
  gmbook.printing = ORCHARD
  local plain = maps.printed.draw()
  local dm = maps.printed.draw({ dm = true })
  gmbook.printing = nil
  has(plain, "<svg", "the page being printed has the map")
  hasnt(plain, ">S<", "without its creatures")
  has(dm, ">S<", "and with them when asked, the options given alone")
end)

-- A message printed in place of a map would go into the book as if it were
-- the map. Printing nothing, the build keeps the edition back and names the
-- page; the widget on the page says which map it looked for.
test("maps: a map page that can't be found keeps the edition back", "adventure", function()
  eq(maps.printed.draw("World/Maps/Nowhere"), nil, "in print it gives nothing")
  has(maps.draw("World/Maps/Nowhere").html, "No map page for World/Maps/Nowhere",
    "on the page it says what it looked for")
  H.pages["Campaign/Clearing"] = "---\nbook_order: 14\n---\n\n# Clearing\n\n" ..
    "${maps.draw(\"World/Maps/Nowhere\")}\n"
  local before = H.pages["Build/Book DM"]
  H.current = "index"
  local report = gmbook.build({ "dm", "player" })
  eq(#report.written, 0, "nothing written")
  eq(H.pages["Build/Book DM"], before, "the edition on the page is left as it was")
  has(lastNotification().message, "Campaign/Clearing, ${maps.draw(\"World/Maps/Nowhere\")}")
end)
