------------------------------------------------ GM Book: what a build writes all the same

-- The page breaks are a model of Homebrewery's layout, and some blocks are
-- beyond it: one taller than a column spills wherever it goes, raw HTML and
-- images have no height the model can read, and Homebrewery breaks the page
-- at a \page line even inside code. A build names each, with its page, and
-- writes the book all the same. So it does for book_order problems.

local NL = string.char(10)

local function page(name, order, body, extra)
  H.pages[name] = "---" .. NL .. "book_order: " .. order .. NL .. (extra or "") .. "---" .. NL .. NL ..
    "# " .. name:match("([^/]+)$") .. NL .. NL .. body .. NL
end

-- The Homebrewery page a line of a written edition is on: one more than the
-- \page lines above it, which is how Homebrewery splits a brew.
local function sheetOf(book, needle)
  local at = book:find(needle, 1, true)
  assert(at, "not in the book: " .. needle)
  local n = 1
  for line in (book:sub(1, at - 1) .. NL):gmatch("([^" .. NL .. "]*)" .. NL) do
    if line == "\\page" then n = n + 1 end
  end
  return n
end

local function build()
  H.current = "index"
  return gmbook.build({ "dm", "player" })
end

local function warnings(report, kind)
  local out = {}
  for _, w in ipairs(report.warnings) do
    if w.kind == kind then out[#out + 1] = w end
  end
  return out
end

------------------------------------------------ nothing to say

test("book: the campaign's own book has nothing to warn of", "adventure", function()
  local report = build()
  eq(#report.warnings, 0)
  eq(lastNotification().kind, "info")
  hasnt(lastNotification().message, "may spill")
  hasnt(lastNotification().message, "Book order")
end)

------------------------------------------------ what the page breaks can't allow for

test("book: a table taller than a column is named with the page it spills on", "adventure", function()
  local rows = { "| Roll | Loot |", "|---|---|" }
  for r = 1, 70 do rows[#rows + 1] = "| " .. r .. " | A handful of tin buttons |" end
  page("Rules/Loot", 33, table.concat(rows, NL))
  local report = build()
  eq(#report.written, 2, "the book is written all the same")
  local found = warnings(report, "layout")
  eq(#found, 2, "once in each edition")
  eq(found[1].edition, "dm")
  eq(found[1].page, "Rules/Loot", "named by the book's page it is on")
  eq(found[1].text, "a table taller than a column")
  eq(found[1].sheet, sheetOf(H.pages["Build/Book DM"], "| Roll | Loot |"), "and the Homebrewery page")
  eq(found[2].edition, "player")
  eq(found[2].sheet, sheetOf(H.pages["Build/Book Player"], "| Roll | Loot |"))
  local n = lastNotification()
  eq(n.kind, "warning")
  has(n.message, "The page breaks can't allow for one block, so its page may spill: Rules/Loot: " ..
    "a table taller than a column (DM edition p. " .. found[1].sheet .. ", player edition p. " ..
    found[2].sheet .. "). See Page breaks in GM Book's docs.")
end)

test("book: a long code block, and a \\page inside code, are named", "adventure", function()
  local code = { "```" }
  for r = 1, 90 do code[#code + 1] = "line " .. r end
  code[#code + 1] = "```"
  page("Rules/Script", 34, table.concat(code, NL))
  page("Rules/Breaks", 35, "Write a page break as" .. NL .. NL .. "```" .. NL .. "\\page" .. NL .. "```" ..
    NL .. NL .. "and Homebrewery does the rest.")
  local report = build()
  eq(#report.written, 2)
  local texts = {}
  for _, w in ipairs(warnings(report, "layout")) do
    if w.edition == "dm" then texts[#texts + 1] = w.page .. ": " .. w.text end
  end
  eq(list(texts), "Rules/Script: a code block taller than a column | Rules/Breaks: a \\page line " ..
    "inside a code block, where Homebrewery breaks the page all the same")
  has(lastNotification().message, "can't allow for 2 blocks, so their pages may spill")
end)

test("book: an image or raw HTML with no height is named, a comment or a wrapper isn't", "adventure", function()
  page("World/Places/Ashford", 68, table.concat({
    "The town from the ford.", "",
    "![Ashford from the ford](ashford.png)", "",
    "<iframe src=\"https://example.org/ford\"></iframe>",
  }, NL))
  page("World/Places/Rookery", 69, "- Crows:" .. NL .. "  - one with a picture: ![a crow](crow.png)")
  -- pages whose HTML takes no room of its own, or declares its height: each
  -- on a page of its own, since one page's notes of a kind are named once
  page("World/Places/Sidebar", 69.1, table.concat({
    "<div class=\"sidebar\">", "", "Words the model measures as usual.", "", "</div>",
  }, NL))
  page("World/Places/Notes", 69.2, "<!-- a note to self -->" .. NL .. NL .. "Notes.")
  page("World/Places/Mill", 69.3, "<!-- a longer note" .. NL .. NL .. "that runs on past a blank line -->" ..
    NL .. NL .. "The mill.")
  page("World/Places/Ford", 69.4, "<img src=\"ford.png\" width=\"200\" height=\"120\" style=\"display:block\">")
  local report = build()
  local texts = {}
  for _, w in ipairs(warnings(report, "layout")) do
    if w.edition == "dm" then texts[#texts + 1] = w.page .. ": " .. w.text end
  end
  eq(list(texts), "World/Places/Ashford: an image without a declared height | " ..
    "World/Places/Ashford: raw HTML without a declared height | " ..
    "World/Places/Rookery: an image without a declared height",
    "the image, the frame and the nested item's image, and nothing else")
  eq(#report.written, 2)
end)

test("book: the page model reports what it can't fit, and the page of every block", "adventure", function()
  local text = table.concat({
    "# Chapter", "", "Words.", "",
    "```", "\\pagebreak", "\\page {hbtemplate:plain}", "\\pages are not breaks", "  \\page", "```", "",
    "\\page", "", "More words.",
  }, NL)
  local out, sheets, info = gmbook.paginate(text)
  eq(sheets, 2)
  eq(#info.notes, 1, "one note for the code block, however many breaks it holds")
  eq(info.notes[1].line, 5)
  eq(info.notes[1].page, 1)
  has(info.notes[1].what, "a \\page line inside a code block")
  eq(gmbook.pageAt(info, 1), 1)
  eq(gmbook.pageAt(info, 14), 2, "the text after the break is on the second page")
  eq(gmbook.pageAt(info, 99), 2, "a line past the end is on the last page")
  -- a book with paginate off breaks only where it says so, code included
  local _, count, plain = gmbook.explicitPages(text)
  eq(count, 4, "Homebrewery splits at both breaks in the code and the one outside it")
  eq(gmbook.pageAt(plain, 14), 4)
  eq(out:find("\\page", 1, true) ~= nil, true)
end)

------------------------------------------------ book_order problems

test("book: pages sharing a book_order, and one that isn't a number, are named", "adventure", function()
  for _, name in ipairs({ "Campaign/Tie C", "Campaign/Tie A", "Campaign/Tie B" }) do page(name, 14, "Text.") end
  page("Campaign/Someday", "soon", "Text.")
  page("Campaign/Twenty", "\"20\"", "A number written as text orders as that number.")
  local report = build()
  eq(#report.written, 2, "the book is written all the same")
  local dm = H.pages["Build/Book DM"]
  local at = {}
  for _, t in ipairs({ "# Scene 3", "# Tie A", "# Tie B", "# Tie C", "# Twenty", "# House Rules", "## Crow",
                       "# Someday" }) do
    at[#at + 1] = dm:find(t, 1, true)
    ok(at[#at], t .. " is in the book")
  end
  for k = 2, #at do ok(at[k - 1] < at[k], "in order at " .. k) end
  local texts = {}
  for _, w in ipairs(warnings(report, "order")) do texts[#texts + 1] = w.text end
  eq(list(texts), "Campaign/Tie A, Campaign/Tie B and Campaign/Tie C share book_order 14, so they go " ..
    "in by name | Campaign/Someday's book_order, \"soon\", isn't a number, so it goes at the end of the book")
  local n = lastNotification()
  eq(n.kind, "warning")
  has(n.message, " Book order: Campaign/Tie A, Campaign/Tie B and Campaign/Tie C share book_order 14, " ..
    "so they go in by name; Campaign/Someday's book_order, \"soon\", isn't a number")
end)

test("book: a section whose chapter an edition leaves out is named, once", "adventure", function()
  -- a chapter the players don't get, with two sections they do
  H.pages["World/Secrets"] = "---\nbook_order: 80\n---\n\n<!--#dm-->\n\n# Secrets\n\nThe crown is tin.\n"
  page("World/Secrets/Rumours", 80.01, "The crown is gold, they say.", "book_section: true\n")
  page("World/Secrets/More Rumours", 80.02, "It was never here.", "book_section: true\n")
  -- and a section with nothing before it at all
  page("Campaign/Foreword", 0.5, "Read this first.", "book_section: true\n")
  local report = build()
  local texts = {}
  for _, w in ipairs(warnings(report, "order")) do texts[#texts + 1] = w.text end
  eq(list(texts), "Campaign/Foreword is a book_section with no chapter before it | " ..
    "World/Secrets/Rumours is a book_section, but its chapter, World/Secrets, isn't in the player edition")
  eq(#report.written, 2)
end)

test("book: a notification with many warnings still fits a phone", "adventure", function()
  for i = 1, 6 do
    local rows = { "| Roll | Loot |", "|---|---|" }
    for r = 1, 70 do rows[#rows + 1] = "| " .. r .. " | Tin |" end
    page("Rules/Loot " .. i, 33 + i / 100, table.concat(rows, NL))
  end
  for i = 1, 5 do page("Campaign/Tie " .. i, 14 + (i > 3 and 1 or 0), "Text.") end
  build()
  local n = lastNotification().message
  has(n, "can't allow for 6 blocks")
  has(n, "; and 3 more. See Page breaks")
  hasnt(n, "Rules/Loot 4", "three are named")
  ok(#n < 800, "short enough to read on a phone: " .. #n)
end)
