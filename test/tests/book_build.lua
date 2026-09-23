------------------------------------------------ GM Book: a build, start to end

-- Every syscall a build makes yields to the browser, so a second click, or
-- Build again beside the header's printer, lands while the first build is
-- still running. A page read stands in for that yield here: hook runs at
-- each read the build makes, and the build carries on after it.
local function whileReading(hook, fn)
  local real, busy = space.readPage, false
  space.readPage = function(name)
    if not busy then
      busy = true
      local fine, err = pcall(hook, name)
      busy = false
      if not fine then
        space.readPage = real
        error(err, 0)
      end
    end
    return real(name)
  end
  local fine, result = pcall(fn)
  space.readPage = real
  if not fine then error(result, 0) end
  return result
end

------------------------------------------------ one build at a time

test("book: a build asked for while one runs is refused, and the first finishes", "adventure", function()
  H.current = "index"
  local asked, second = false, nil
  local report = whileReading(function()
    if not asked then
      asked = true
      second = { gmbook.build({ "dm", "player" }) }
    end
  end, function() return gmbook.build({ "dm", "player" }) end)
  ok(asked, "the build read no page")
  eq(second[1], nil, "a second build started over the first")
  local refused = {}
  for _, n in ipairs(H.notifications) do
    if n.message:find("already", 1, true) then refused[#refused + 1] = n end
  end
  eq(#refused, 1, "the second click is told why nothing happened")
  eq(refused[1].kind, "warning")
  eq(#report.written, 2, "the first build writes both editions")
  eq(lastNotification().kind, "info", "and says so, with no false diagnosis")
  has(lastNotification().message, "Built the DM edition")
  eq(gmbook.printing, nil, "nothing is left printing")
  eq(#gmbook.build({ "dm", "player" }).written, 2, "and the next build starts")
end)

test("book: a build that fails lets the next one start, and clears the ring", "adventure", function()
  H.current = "index"
  local real = space.writePage
  space.writePage = function() error("the disk is full") end
  local fine, err = pcall(gmbook.build, { "dm", "player" })
  space.writePage = real
  ok(not fine, "the build should have failed")
  has(tostring(err), "the disk is full")
  eq(H.progress[#H.progress].percentage, nil, "the ring is cleared")
  eq(gmbook.printing, nil)
  eq(#gmbook.build({ "dm", "player" }).written, 2, "the next build runs")
end)

------------------------------------------------ the page being printed

test("book: gmbook.printing is put back however a print ends", "adventure", function()
  -- stopped where it stands, as a stop from the user stops a script: pcall
  -- passes that on rather than catching it
  gmbook.printers.mylib = { wait = function() coroutine.yield() return "done" end }
  local co = coroutine.create(function() return gmbook.print("${mylib.wait()}", "Campaign/Live") end)
  assert(coroutine.resume(co))
  eq(gmbook.printing, "Campaign/Live", "while its expression runs, the page is the one printing")
  coroutine.close(co)
  eq(gmbook.printing, nil, "and once the print is stopped it is put back")
end)

test("book: a value that can't even be looked at is unprintable, not a failed build", "adventure", function()
  gmbook.printers.mylib = {
    odd = function() return setmetatable({}, { __index = function() error("no such field") end }) end,
  }
  local out, left = gmbook.print("A ${mylib.odd()} B", "Campaign/Live")
  eq(out, "A ${mylib.odd()} B")
  eq(list(left), "mylib.odd()")
  eq(gmbook.printing, nil)
end)

------------------------------------------------ an edition kept back says why

local function page(name, order, body)
  H.pages[name] = "---\nbook_order: " .. order .. "\n---\n\n# " .. name:match("([^/]+)$") .. "\n\n" .. body .. "\n"
end

test("book: an expression that fails is named with its error, not a reload", "adventure", function()
  page("Campaign/Typo", 14, "A boat for ${party.nn()}.")
  H.current = "index"
  local report = gmbook.build({ "dm", "player" })
  eq(#report.written, 0, "the editions are kept back")
  eq(list(report.live), "Campaign/Typo")
  eq(#report.unprinted, 1, "one expression, reported once for both editions")
  local u = report.unprinted[1]
  eq(u.page, "Campaign/Typo")
  eq(u.expression, "party.nn()")
  eq(u.unloaded, false, "party is loaded")
  has(u.error, "nn", "the error the expression raised")
  local n = lastNotification()
  eq(n.kind, "warning")
  has(n.message, "Campaign/Typo, ${party.nn()}: " .. u.error)
  hasnt(n.message, "System: Reload", "a typo is not a stale tab")
  hasnt(n.message, "Baked Sections")
end)

test("book: an expression whose library isn't loaded says to reload", "adventure", function()
  page("Campaign/Drawn", 14, "${mylib.draw()}")
  H.current = "index"
  local report = gmbook.build({ "dm", "player" })
  eq(report.unprinted[1].unloaded, true)
  local n = lastNotification()
  has(n.message, "Campaign/Drawn, ${mylib.draw()}: its library isn't loaded in this tab.")
  has(n.message, "System: Reload")
  hasnt(n.message, "Baked Sections")
end)

test("book: an expression with nothing to print says to bake it", "adventure", function()
  gmbook.printers.mylib = { rows = function() return { { a = 1 } } end }
  page("Campaign/Table", 14, "${mylib.rows()}")
  H.current = "index"
  local report = gmbook.build({ "dm", "player" })
  local u = report.unprinted[1]
  eq(u.error, nil)
  eq(u.unloaded, false)
  local n = lastNotification()
  has(n.message, "Campaign/Table, ${mylib.rows()}: it gives nothing to print.")
  has(n.message, "Baked Sections: Update")
  hasnt(n.message, "System: Reload")
end)

test("book: an expression on a page shown in another is named from both", "adventure", function()
  H.pages["Notes/Rumour"] = "# Rumour\n\n## Heard\n\n${mylib.told()}\n"
  page("Campaign/Tavern", 14, "![[Notes/Rumour#Heard]]")
  local report = gmbook.compile({ "dm", "player" })
  eq(list(report.live), "Campaign/Tavern")
  eq(report.unprinted[1].page, "Campaign/Tavern")
  eq(report.unprinted[1].from, "Notes/Rumour")
  eq(report.unprinted[1].expression, "mylib.told()")
end)

test("book: a notification about many expressions still fits a phone", "adventure", function()
  for i = 1, 6 do
    page("Campaign/Broken " .. i, 14 + i / 100, "${mylib.draw" .. i .. "({ size = \"a long list of options " ..
      "that goes on and on, as a fight's does\" })}")
  end
  H.current = "index"
  local report = gmbook.build({ "dm", "player" })
  eq(#report.unprinted, 6)
  local n = lastNotification().message
  has(n, "Campaign/Broken 1, ")
  has(n, "Campaign/Broken 3, ")
  hasnt(n, "Campaign/Broken 4", "three are named")
  has(n, "; and 3 more.", "and the rest counted")
  hasnt(n, "as a fight's does", "a long expression is cut short")
  ok(#n < 800, "the whole message is short enough to read on a phone: " .. #n)
end)

------------------------------------------------ the same book in every Lua

-- SilverBullet's index promises no order, and a sort need not keep one
-- either: pages that share a book_order go in by their names.
test("book: pages that share a book_order go in by name, whatever order the index gives", "adventure", function()
  for _, name in ipairs({ "Campaign/Tie C", "Campaign/Tie A", "Campaign/Tie B" }) do
    H.pages[name] = "---\nbook_order: 14\n---\n\n# " .. name:match("Tie %a") .. "\n\nText.\n"
  end
  local real = index.pages
  index.pages = function()
    local out = real()
    table.sort(out, function(a, b) return a.name > b.name end)  -- names backwards
    return out
  end
  local fine, err = pcall(gmbook.compile, { "dm" })
  index.pages = real
  assert(fine, err)
  local dm = H.pages["Build/Book DM"]
  local a, b, c = dm:find("# Tie A", 1, true), dm:find("# Tie B", 1, true), dm:find("# Tie C", 1, true)
  ok(a and b and c, "all three are in the book")
  ok(a < b and b < c, "in the order of their names")
end)

-- 10/4*4 is 10 in SilverBullet's Lua, whose numbers are JavaScript's, and
-- 10.0 in stock Lua; 2^53 prints whole in one and as 9.007199254741e+15 in
-- the other. The book prints a whole number without a point and anything
-- else to 14 figures, the same in both, and something that isn't a number
-- at all, such as 0/0, not at all.
test("book: a number prints the same in every Lua", "adventure", function()
  gmbook.printers.mylib = {
    ten = function() return 10 / 4 * 4 end, half = function() return 5 / 2 end,
    third = function() return 1 / 3 end, big = function() return 2 ^ 53 end,
    none = function() return 0 / 0 end,
  }
  local out, left = gmbook.print("${mylib.ten()} ${mylib.half()} ${mylib.third()} ${mylib.big()} " ..
    "${mylib.none()}", "Campaign/Live")
  eq(out, "10 2.5 0.33333333333333 9007199254740992 ${mylib.none()}")
  eq(list(left), "mylib.none()")
end)

------------------------------------------------ copies of GM Book

-- A build reads from the folder GM Book is installed under, the shortest of
-- any copy. A Library: Update All run in a space that holds others can
-- leave a copy at the top as well, and the build silently moves to the
-- whole space.
test("book: copies of GM Book at different depths are named when the book builds", "dm", function()
  H.pages["Library/Storie/GM Book"] = H.pages["Adventure/Library/Storie/GM Book"]
  H.current = "index"
  local report = gmbook.build({ "dm", "player" })
  eq(list(report.copies), "Library/Storie/GM Book | Adventure/Library/Storie/GM Book", "shallowest first")
  local n = lastNotification()
  eq(n.kind, "warning")
  has(n.message, "GM Book is installed at more than one depth, Library/Storie/GM Book and " ..
    "Adventure/Library/Storie/GM Book, so the build read the whole space.")
  has(n.message, "gmBook.root")
  eq(count(n.message, "more than one depth"), 1, "said once for the build")
end)

test("book: one copy of GM Book, or a root set in the config, says nothing of copies", "dm", function()
  H.current = "index"
  local report = gmbook.build({ "dm", "player" })
  eq(#report.copies, 0)
  eq(lastNotification().kind, "info")
  -- a second copy, but the root set by hand
  H.pages["Library/Storie/GM Book"] = H.pages["Adventure/Library/Storie/GM Book"]
  config.set("gmBook.root", "Adventure/")
  report = gmbook.build({ "dm", "player" })
  eq(#report.copies, 0, "the config chose")
  hasnt(lastNotification().message, "depth")
end)
