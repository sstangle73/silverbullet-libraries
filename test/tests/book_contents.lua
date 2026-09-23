------------------------------------------------ GM Book: page numbers

-- gmBook.contents puts a contents page at the front of each edition, and
-- gmBook.pageRefs gives each pointer the page it points to. Both are off
-- by default, so a campaign's committed book doesn't change on upgrade.
-- Every number is held here to Homebrewery's own count: a brew is split
-- into pages at each \page line, so a line is on one more page than the
-- \page lines above it.

local NL = string.char(10)

local function lines(text)
  local out = {}
  for line in (text .. NL):gmatch("([^" .. NL .. "]*)" .. NL) do out[#out + 1] = line end
  return out
end

-- The Homebrewery page the first line reading exactly `want` is on, at or
-- after line `from`, and that line's number.
local function sheetOf(book, want, from)
  local n = 1
  for i, line in ipairs(lines(book)) do
    if line == "\\page" then n = n + 1 end
    if i >= (from or 1) and line == want then return n, i end
  end
  error("not in the book: " .. want)
end

-- The contents table's rows, from its title to the first chapter's: each
-- title, the page it links to and the page it gives.
local function contentsRows(book)
  local rows = {}
  for i, line in ipairs(lines(book)) do
    if i > 1 and line:match("^# ") then break end
    local title, link, page = line:match("^| %[(.-)%]%(#p(%d+)%) | (%d+) |$")
    if title then rows[#rows + 1] = { title = title, link = tonumber(link), page = tonumber(page) } end
  end
  return rows
end

-- Every contents row names the page its chapter starts on, as Homebrewery
-- counts pages, and links to that page.
local function holdsContents(book, what)
  local rows = contentsRows(book)
  ok(#rows > 0, what .. ": no contents")
  for _, r in ipairs(rows) do
    local title = r.title:gsub("\\(.)", "%1")
    eq(r.link, r.page, what .. ": " .. title .. " links to its own page")
    eq(r.page, (sheetOf(book, "# " .. title)), what .. ": " .. title .. " starts on the page it gives")
  end
  return rows
end

local function build()
  H.current = "index"
  return gmbook.build({ "dm", "player" })
end

------------------------------------------------ off by default

test("book: with the defaults there is no contents page and a pointer has no page", "adventure", function()
  eq(config.get("gmBook.contents"), nil)
  eq(config.get("gmBook.pageRefs"), nil)
  build()
  local dm = H.pages["Build/Book DM"]
  ok(dm:match("^%s*# Premise" .. NL), "the book starts with its first chapter")
  has(dm, "*See Lantern: Rules.*")
end)

------------------------------------------------ the contents

test("book: a contents page gives the page Homebrewery starts each chapter on", "adventure", function()
  config.set("gmBook.contents", true)
  local report = build()
  local dm, player = H.pages["Build/Book DM"], H.pages["Build/Book Player"]
  eq(dm:sub(1, 11), "# Contents" .. NL)
  has(dm, "| Chapter | Page |" .. NL .. "|:--|--:|" .. NL .. "| [Premise](#p2) | 2 |")
  local rows = holdsContents(dm, "the DM edition")
  eq(#rows, 21, "every chapter, and no section")
  eq(rows[#rows].title, "Bestiary")
  holdsContents(player, "the player edition")
  eq(report.written[1].sheets, (sheetOf(dm, "- Act I, Scene 2: over the market")), "the pages the build says")
  eq(#report.warnings, 0)
end)

test("book: a contents longer than a page takes the pages it needs, and the numbers allow for it", "adventure", function()
  for i = 1, 150 do
    H.pages[string.format("World/Gazetteer/Place %03d", i)] = "---\nbook_order: " .. (100 + i) .. "\n---\n\n" ..
      string.format("# Place %03d, a town on the long road north of the ford", i) .. "\n\nA town.\n"
  end
  config.set("gmBook.contents", true)
  local report = build()
  local dm = H.pages["Build/Book DM"]
  local rows = holdsContents(dm, "the DM edition")
  eq(#rows, 171)
  local first = sheetOf(dm, "# Premise")
  ok(first >= 3, "the contents takes more than one page: Premise is on page " .. first)
  eq(rows[1].page, first)
  -- each table of it fits a column, as the page breaks measure it
  local contents = dm:sub(1, dm:find(NL .. "# Premise", 1, true))
  local _, _, info = gmbook.paginate((contents:gsub("\\page", "")))
  eq(#info.notes, 0, "no table of the contents is taller than a column")
  eq(#report.warnings, 0)
  holdsContents(H.pages["Build/Book Player"], "the player edition")
end)

test("book: the contents' title and headings can be a campaign's own", "adventure", function()
  config.set("gmBook.contents", "Table of Contents")
  H.pages["Campaign/Odds"] = "---\nbook_order: 3\n---\n\n# Odds | Ends [draft]\n\nText.\n"
  build()
  local dm = H.pages["Build/Book DM"]
  eq(dm:sub(1, 20), "# Table of Contents" .. NL)
  has(dm, "| [Odds \\| Ends \\[draft\\]](#p4) | 4 |", "a title's | and [ ] can't break the table")
  config.set("gmBook.contents", { title = "Inhalt", chapter = "Kapitel", page = "Seite" })
  build()
  dm = H.pages["Build/Book DM"]
  has(dm, "# Inhalt" .. NL .. NL .. "| Kapitel | Seite |")
end)

test("book: with paginate off the numbers count only the page breaks", "adventure", function()
  gmbook.config.paginate = false
  config.set("gmBook.contents", true)
  config.set("gmBook.pageRefs", true)
  H.pages["World/Items/Lantern"] = H.pages["World/Items/Lantern"] .. "\n\\page\n\n## Care\n\nKeep it dry.\n"
  -- shown in the scene, above its DM Only section
  H.pages["Campaign/Act I/Scene 2"] = H.pages["Campaign/Act I/Scene 2"]:gsub("(!%[%[World/Items/Lantern#Rules%]%])",
    "%1\n\n![[World/Items/Lantern#Care]]")
  build()
  local dm = H.pages["Build/Book DM"]
  holdsContents(dm, "the DM edition")
  local _, at = sheetOf(dm, "# Lantern")
  local care = sheetOf(dm, "## Care", at)
  has(dm, "*See Lantern: Care (p. " .. care .. ").*", "the page the section is on, past its chapter's break")
end)

------------------------------------------------ a pointer's page

test("book: a pointer gives the page its section is on", "adventure", function()
  config.set("gmBook.pageRefs", true)
  -- a chapter long enough that its last section starts a page after it does
  local body = {}
  for i = 1, 40 do
    body[#body + 1] = "The tome goes on about the ford, the road, the crown and the warden, page after page, " ..
      "for no reason anyone at the table will thank it for. " .. i
  end
  H.pages["World/Items/Tome"] = "---\nbook_order: 71\n---\n\n# Tome\n\n" .. table.concat(body, "\n\n") ..
    "\n\n## Late\n\nThe last word.\n"
  -- shown in the scene, above its DM Only section
  H.pages["Campaign/Act I/Scene 2"] = H.pages["Campaign/Act I/Scene 2"]:gsub("(!%[%[World/Items/Lantern#Rules%]%])",
    "%1\n\n![[World/Items/Tome#Late]]\n\n![[World/Items/Tome]]")
  build()
  for _, page in ipairs({ "Build/Book DM", "Build/Book Player" }) do
    local book = H.pages[page]
    local _, at = sheetOf(book, "# Lantern")
    local rules = sheetOf(book, "## Rules", at)
    has(book, "*See Lantern: Rules (p. " .. rules .. ").*", page)
    local tome, tomeAt = sheetOf(book, "# Tome")
    local late = sheetOf(book, "## Late", tomeAt)
    ok(late > tome, "the section starts a page after its chapter")
    has(book, "*See Tome: Late (p. " .. late .. ").*", page .. ": the section's own page")
    has(book, "*See Tome (p. " .. tome .. ").*", page .. ": a whole page's first page")
  end
end)

test("book: pointers and the contents together count the contents' pages", "adventure", function()
  config.set("gmBook.contents", true)
  config.set("gmBook.pageRefs", true)
  build()
  local dm = H.pages["Build/Book DM"]
  holdsContents(dm, "the DM edition")
  local _, at = sheetOf(dm, "# Lantern")
  local rules = sheetOf(dm, "## Rules", at)
  eq(rules, 21, "the Lantern's page, one on for the contents")
  has(dm, "*See Lantern: Rules (p. 21).*")
end)
