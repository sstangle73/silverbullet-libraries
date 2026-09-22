------------------------------------------------------------------ GM Book

-- Adventure's pages that start a chapter in the book: those with a
-- book_order, less the sections, which carry on the chapter before them.
local function chapterCount()
  local n = 0
  for _, text in pairs(FIXTURES.adventure) do
    local head = text:match("^%-%-%-\n(.-\n)%-%-%-")
    if head and ("\n" .. head):find("\nbook_order:")
        and not ("\n" .. head):find("\nbook_section:%s*true") then
      n = n + 1
    end
  end
  return n
end

test("book: registers commands, a header button and a top widget", "adventure", function()
  for _, c in ipairs({ "GM: Build Book", "GM: Build Book (DM)", "GM: Build Book (Player)",
                       "GM: Copy Book for Homebrewery" }) do
    ok(H.commands[c], "missing command " .. c)
  end
  local printer
  for _, b in ipairs(config.get("actionButtons")) do
    for k in pairs(b) do ok(ALLOWED_BUTTON_KEYS[k], "action button key not in the 2.11 schema: " .. k) end
    if b.icon == "printer" then printer = b end
  end
  ok(printer, "no printer button")
  ok(H.commands[printer.command], "printer runs a missing command")
  eq(#H.listeners["hooks:renderTopWidgets"], 1)
end)

test("book: root is the whole Adventure space", "adventure", function()
  eq(gmbook.root(), "")
end)

test("book: root is Adventure/ from the DM space", "dm", function()
  eq(gmbook.root(), "Adventure/")
end)

test("book: config overrides the root", "dm", function()
  config.set("gmBook", { root = "Elsewhere/" })
  eq(gmbook.root(), "Elsewhere/")
end)

test("book: GM: Build Book writes both editions and offers to open them", "adventure", function()
  H.current = "index"
  H.commands["GM: Build Book"].run()
  ok(H.pages["Build/Book DM"], "no DM edition")
  ok(H.pages["Build/Book Player"], "no player edition")
  local n = lastNotification()
  has(n.message, "Built the DM edition")
  has(n.message, "the player edition")
  has(n.message, "from " .. bookPageCount() .. " pages.")
  runAction(n, "Open DM edition")
  eq(H.current, "Build/Book DM")
  runAction(n, "Open player edition")
  eq(H.current, "Build/Book Player")
  -- a break before every chapter but the first, and more where a page fills up
  ok(count(H.pages["Build/Book DM"], "\\page") >= chapterCount() - 1, "page breaks")
end)

test("book: single editions", "adventure", function()
  H.current = "index"
  H.commands["GM: Build Book (Player)"].run()
  ok(H.pages["Build/Book Player"])
  ok(not H.pages["Build/Book DM"] or H.pages["Build/Book DM"] == FIXTURES.adventure["Build/Book DM"],
     "a player build touched the DM edition")
  has(lastNotification().message, "Built the player edition")
  hasnt(lastNotification().message, "DM edition")
end)

local builtInAdventure
test("book: a build from DM matches a build from Adventure", "adventure", function()
  H.current = "index"
  gmbook.compile({ "dm", "player" })
  builtInAdventure = { dm = H.pages["Build/Book DM"], player = H.pages["Build/Book Player"] }
end)
test("book: (DM side of the comparison)", "dm", function()
  H.current = "index"
  local report = gmbook.compile({ "dm", "player" })
  eq(report.pages, bookPageCount())
  ok(H.pages["Adventure/Build/Book DM"], "DM build didn't write Adventure/Build/Book DM")
  ok(not H.pages["Build/Book DM"], "DM build wrote a stray Build/ at the DM root")
  eq(H.pages["Adventure/Build/Book DM"], builtInAdventure.dm, "DM editions differ")
  eq(H.pages["Adventure/Build/Book Player"], builtInAdventure.player, "player editions differ")
end)

test("book: the player edition drops DM Only sections", "adventure", function()
  gmbook.compile({ "dm", "player" })
  local dm, player = H.pages["Build/Book DM"], H.pages["Build/Book Player"]
  local withSecrets = 0
  for name, text in pairs(FIXTURES.adventure) do
    if text:find("\n## DM Only", 1, true) and text:find("\nbook_order:", 1, true) then
      withSecrets = withSecrets + 1
    end
  end
  hasnt(player, "## DM Only")
  if withSecrets > 0 then has(dm, "## DM Only") end
  ok(#player <= #dm)
end)

test("book: matches the committed build apart from pages changed since", "adventure", function()
  gmbook.compile({ "dm" })
  local sep = "\n\n\\page\n\n"
  local function split(s)
    local parts, i = {}, 1
    while true do
      local a, b = s:find(sep, i, true)
      if not a then parts[#parts + 1] = s:sub(i); return parts end
      parts[#parts + 1] = s:sub(i, a - 1)
      i = b + 1
    end
  end
  local new, old = split(H.pages["Build/Book DM"]), split(FIXTURES.adventure["Build/Book DM"])
  eq(#new, #old, "chapter count")
  local changed = {}
  for i = 1, #new do
    if new[i] ~= old[i] then changed[#changed + 1] = (new[i]:match("\n?# ([^\n]+)") or ("#" .. i)) end
  end
  REPORT[#REPORT + 1] = "chapters that differ from the committed Book DM: " .. (#changed > 0 and list(changed) or "none")
end)

-- A build takes tens of seconds, and before 1.12 nothing on the screen moved
-- while it ran. Every syscall the build makes yields to the browser, so the
-- ring drawn from these calls actually animates.
test("book: a build drives the progress ring and clears it at the end", "adventure", function()
  H.current = "index"
  gmbook.build({ "dm", "player" })
  local p = H.progress
  ok(#p >= 4, "progress reported: " .. #p)
  eq(p[1].kind, "sync", "the ring it borrows")
  local prev = -1
  for i = 1, #p - 1 do
    eq(p[i].kind, "sync", "every call names the same ring")
    ok(p[i].percentage ~= nil, "call " .. i .. " carries a percentage")
    ok(p[i].percentage >= prev, "the percentage never goes backwards")
    ok(p[i].percentage <= 100, "the percentage never passes 100")
    prev = p[i].percentage
  end
  eq(p[#p - 1].percentage, 100, "it reaches 100")
  eq(p[#p].percentage, nil, "the last call clears the ring")
end)

test("book: an edition kept back still leaves the ring cleared", "adventure", function()
  H.pages["Campaign/Live"] = "---\nbook_order: 11\n---\n\n# Live\n\n${query[[from p = index.pages()]]}\n"
  H.current = "index"
  gmbook.build({ "dm", "player" })
  local p = H.progress
  eq(p[#p - 1].percentage, 100, "it still reaches 100")
  eq(p[#p].percentage, nil, "and the ring is cleared")
end)

test("book: gmBook.progress false leaves the ring alone", "adventure", function()
  config.set("gmBook.progress", false)
  H.current = "index"
  gmbook.build({ "dm", "player" })
  eq(#H.progress, 0, "no progress calls")
end)

test("book: keeps back an edition holding an expression with nothing to print", "adventure", function()
  local before = H.pages["Build/Book DM"]
  H.pages["Campaign/Live"] = "---\nbook_order: 11\n---\n\n# Live\n\n${query[[from p = index.pages()]]}\n"
  H.current = "index"
  local report = gmbook.build({ "dm", "player" })
  local n = lastNotification()
  eq(n.kind, "warning")
  has(n.message, "Kept back the DM edition and the player edition, unchanged")
  has(n.message, "Campaign/Live")
  eq(#report.written, 0, "nothing written")
  eq(#report.kept, 2, "both editions kept back")
  eq(H.pages["Build/Book DM"], before, "the edition on the page is left as it was")
  hasnt(H.pages["Build/Book DM"], "${query", "the query never reached the book")
end)

-- The 2026-09-22 loss: a library installed while a client was running is on
-- disk and in its index but not in its Lua, so every expression that calls it
-- fails and GM Book leaves it in as code. Writing that edition would take what
-- the library draws out of the book, and a wiki that commits the book would
-- push the loss. Standing in for the missing library: its printer is gone.
test("book: a library missing from the client keeps its edition back", "adventure", function()
  local before = { dm = H.pages["Build/Book DM"], player = H.pages["Build/Book Player"] }
  H.pages["Campaign/Drawn"] = "---\nbook_order: 12\n---\n\n# Drawn\n\n${mylib.draw()}\n"
  gmbook.printers.mylib = { draw = function() return "DRAWN" end }
  H.current = "index"
  local ok1 = gmbook.compile({ "dm", "player" })
  eq(#ok1.written, 2, "with the library, both editions are written")
  has(H.pages["Build/Book DM"], "DRAWN", "what the library draws is in the book")

  gmbook.printers.mylib = nil          -- the client never loaded it
  local report = gmbook.compile({ "dm", "player" })
  eq(#report.written, 0, "without it, nothing is written")
  eq(#report.kept, 2, "both editions kept back")
  eq(list(report.live), "Campaign/Drawn", "the page that lost its expression")
  has(H.pages["Build/Book DM"], "DRAWN", "the edition on the page still has it")
  hasnt(H.pages["Build/Book DM"], "${mylib.draw()}", "the raw expression never reached the book")

  H.pages["Build/Book DM"], H.pages["Build/Book Player"] = before.dm, before.player
  H.pages["Campaign/Drawn"] = nil
end)

test("book: nothing to build", "adventure", function()
  for name, text in pairs(H.pages) do
    H.pages[name] = text:gsub("\nbook_order:[^\n]*", "")
  end
  gmbook.build({ "dm", "player" })
  eq(lastNotification().kind, "warning")
  has(lastNotification().message, "nothing to build")
  ok(not H.writes[1], "wrote something")
end)

test("book: bar on built pages only", "adventure", function()
  gmbook.compile({ "dm", "player" })
  eq(gmbook.bar("Campaign/Premise"), nil)
  eq(gmbook.bar("index"), nil)
  local bar = gmbook.bar("Build/Book DM")
  ok(bar and bar._isWidget, "no bar on the DM edition")
  eq(list(buttonsOf(bar.html)), "Build again | Copy for Homebrewery | Open Homebrewery")
  has(textOf(bar.html), "**DM edition**")
  has(textOf(gmbook.bar("Build/Book Player").html), "**Player edition**")
end)

test("book: bar in the DM space sits on Adventure/Build", "dm", function()
  eq(gmbook.bar("Build/Book DM"), nil)
  ok(gmbook.bar("Adventure/Build/Book DM"), "no bar on Adventure/Build/Book DM")
end)

test("book: the bar opens a PDF printed beside its edition", "adventure", function()
  gmbook.compile({ "dm", "player" })
  H.files["Build/Book DM.pdf"] = { lastModified = 2000, contentType = "application/pdf" }
  local bar = gmbook.bar("Build/Book DM")
  eq(list(buttonsOf(bar.html)), "Build again | Open PDF | Copy for Homebrewery | Open Homebrewery")
  click(bar, "Open PDF")
  eq(H.opened[#H.opened], "https://wiki.example.org/adventure/.fs/Build/Book%20DM.pdf")
  -- the player edition has no PDF of its own yet
  eq(list(buttonsOf(gmbook.bar("Build/Book Player").html)),
    "Build again | Copy for Homebrewery | Open Homebrewery")
end)

test("book: a PDF older than its edition says so", "adventure", function()
  gmbook.compile({ "dm", "player" })
  H.modified["Build/Book Player.md"] = 1000
  H.files["Build/Book Player.pdf"] = { lastModified = 999 }
  eq(list(buttonsOf(gmbook.bar("Build/Book Player").html)),
    "Build again | Open PDF (older) | Copy for Homebrewery | Open Homebrewery")
  -- printed from the edition as it is, it carries the edition's own time
  H.files["Build/Book Player.pdf"].lastModified = 1000
  has(list(buttonsOf(gmbook.bar("Build/Book Player").html)), " | Open PDF | ")
end)

test("book: in the DM space the PDF is the one beside Adventure/Build", "dm", function()
  gmbook.compile({ "dm", "player" })
  H.files["Build/Book DM.pdf"] = { lastModified = 2000 }
  hasnt(list(buttonsOf(gmbook.bar("Adventure/Build/Book DM").html)), "Open PDF")
  H.files["Adventure/Build/Book DM.pdf"] = { lastModified = 2000 }
  click(gmbook.bar("Adventure/Build/Book DM"), "Open PDF")
  eq(H.opened[#H.opened], "https://wiki.example.org/dm/.fs/Adventure/Build/Book%20DM.pdf")
end)

test("book: a file the client can't ask about leaves the bar as it was", "adventure", function()
  gmbook.compile({ "dm", "player" })
  H.files["Build/Book DM.pdf"] = { lastModified = 2000 }
  H.failMeta = { ["Build/Book DM.pdf"] = "offline" }
  eq(list(buttonsOf(gmbook.bar("Build/Book DM").html)),
    "Build again | Copy for Homebrewery | Open Homebrewery")
end)

test("book: bar buttons copy, open Homebrewery and rebuild", "adventure", function()
  gmbook.compile({ "dm", "player" })
  H.current = "Build/Book Player"
  local bar = gmbook.bar()
  click(bar, "Copy for Homebrewery")
  eq(H.clipboard, H.pages["Build/Book Player"])
  runAction(lastNotification(), "Open Homebrewery")
  eq(H.opened[1], "https://homebrewery.naturalcrit.com/new")
  click(bar, "Open Homebrewery")
  eq(#H.opened, 2)
  local reloads = H.reloads
  click(bar, "Build again")
  ok(H.reloads > reloads, "the open edition wasn't reloaded after rebuilding it")
  has(lastNotification().message, "Built the DM edition")
  has(lastNotification().message, "the player edition")
end)

test("book: a failed copy says what to do", "adventure", function()
  gmbook.compile({ "dm" })
  H.clipboardFails = true
  eq(gmbook.copy("dm"), false)
  eq(lastNotification().kind, "error")
  has(lastNotification().message, "copy it by hand")
end)

test("book: copying before a build", "adventure", function()
  H.pages["Build/Book DM"] = nil
  eq(gmbook.copy("dm"), false)
  has(lastNotification().message, "Build the book first")
end)

test("book: copy command picks an edition off the built pages", "adventure", function()
  gmbook.compile({ "dm", "player" })
  H.current = "index"
  H.picks = { "Player edition" }
  H.commands["GM: Copy Book for Homebrewery"].run()
  eq(H.clipboard, H.pages["Build/Book Player"])
  H.current = "Build/Book DM"
  H.commands["GM: Copy Book for Homebrewery"].run()
  eq(H.clipboard, H.pages["Build/Book DM"], "didn't copy the open edition")
  H.current = "index"
  H.picks = { NIL }
  H.commands["GM: Copy Book for Homebrewery"].run()
end)

test("book: top widget listener", "adventure", function()
  gmbook.compile({ "dm" })
  H.current = "Build/Book DM"
  eq(#dispatch("hooks:renderTopWidgets"), 1)
  H.current = "Campaign/Premise"
  eq(#dispatch("hooks:renderTopWidgets"), 0)
  gmbook.bar = function() error("boom") end
  eq(#dispatch("hooks:renderTopWidgets"), 0)
  has(H.printed[1], "boom")
end)
