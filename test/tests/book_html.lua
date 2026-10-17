------------------------------------------------ GM Book: inline HTML is a paragraph (1.14.1)

-- Homebrewery reads raw HTML as CommonMark does: a line that starts with
-- "<" opens an HTML block only by one of seven start conditions, and any
-- other, such as a credit in <small> under a boxed quote, is a paragraph
-- that holds inline HTML. Before 1.14.1 the page model took every such line
-- for raw HTML, measured it at nothing, and pages full of credits spilled.

local NL = string.char(10)

-- { what, text, the layout: each block placed as kind@line=height, then
-- each note as !line:what }. tests/spacelua runs the same cases in
-- SilverBullet's own Lua, read from this file.
local HTML_CASES = {
  { "a credit in <small> under a boxed quote is a paragraph",
    "> \"The ford runs shallow in summer.\"\n\n<small>— *The Tin Crown*, ch. 10, without *truly*</small>\n\nThen the miller.",
    "quote@1=16.06 p@3=16.73 p@5=16.06" },
  { "a paragraph that opens with a span is measured as one",
    "<span class=\"aside\">The ford</span> runs shallow in summer, and the miller's boy wades it twice a day.",
    "p@1=32.13" },
  { "a line of inline HTML under a paragraph's line joins it",
    "The ford runs shallow\n<small>in summer</small>",
    "p@1=16.06" },
  { "a tag alone on its line doesn't end a paragraph",
    "Words before\n<span>\nwords after\n</span>",
    "p@1=16.06" },
  { "a block-level tag ends a paragraph, and what it holds is raw HTML",
    "Words before\n<div>\ninside\n</div>",
    "p@1=16.06 !2:raw HTML without a declared height" },
  { "a wrapper alone on its lines takes no room",
    "<div class=\"sidebar\">\n\nWords the model measures as usual.\n\n</div>",
    "p@3=16.06" },
  { "a comment ends at -->, and the words under it are a paragraph",
    "<!-- a note to self -->\nThe mill wheel turns.",
    "p@2=16.06" },
  { "a comment ends a paragraph",
    "Words.\n<!-- a note -->\nMore words.",
    "p@1=16.06 p@3=16.06" },
  { "a comment across a blank line is one block",
    "<!-- a longer note\n\nthat runs on past a blank line -->\n\nThe mill.",
    "p@5=16.06" },
  { "<pre> runs to its close, blank lines and all",
    "<pre>\nline\n\nmore\n</pre>\nAfter the pre.",
    "p@6=16.06 !1:raw HTML without a declared height" },
  { "<? doesn't end a paragraph in Homebrewery's Markdown",
    "Words\n<?x y?>",
    "p@1=16.06" },
  { "a drawing is measured at its height, even straight under words",
    "Words.\n<svg width=\"100\" height=\"40\" style=\"display:block\"></svg>\n\nAfter.",
    "p@1=16.06 drawn@2=40.00 p@4=16.06" },
  { "an image among a paragraph's words is named",
    "<img src=\"ford.png\"> The ford from the bank.",
    "p@1=16.06 !1:an image without a declared height" },
  { "a video among a paragraph's words is named",
    "<video src=\"ford.mp4\"></video> The ford from the bank.",
    "p@1=16.06 !1:raw HTML without a declared height" },
  { "a tag in inline code is words, not an element",
    "Write `<video>` round it.",
    "p@1=18.06" },
}

-- A text's layout as the cases give it.
local function htmlLayout(text)
  local trace = {}
  local _, _, info = gmbook.paginate(text, trace)
  local out = {}
  for _, t in ipairs(trace) do out[#out + 1] = t.kind .. "@" .. t.line .. "=" .. string.format("%.2f", t.h) end
  for _, n in ipairs(info.notes) do out[#out + 1] = "!" .. n.line .. ":" .. n.what end
  return table.concat(out, " ")
end

for _, c in ipairs(HTML_CASES) do
  test("book: " .. c[1], "adventure", function()
    eq(htmlLayout(c[2]), c[3])
  end)
end

------------------------------------------------ <small> is the body's size

-- Each line a credit and a quote, as a scene that boxes every line it reads
-- aloud: so many that they fill pages.
local function credits(n, small)
  local out = {}
  for i = 1, n do
    out[#out + 1] = "> \"Line " .. i .. " of the ferryman's, which he says once and then again, slower.\""
    out[#out + 1] = ""
    local credit = "— *The Tin Crown*, ch. " .. i .. ", without *truly* and a few more words"
    out[#out + 1] = small and "<small>" .. credit .. "</small>" or credit
    out[#out + 1] = ""
  end
  return table.concat(out, NL)
end

test("book: credits in <small> break the pages where the same words without it do", "adventure", function()
  local small, smallPages = gmbook.paginate(credits(60, true))
  local plain, plainPages = gmbook.paginate(credits(60, false))
  ok(plainPages > 2, "enough credits to fill pages: " .. plainPages)
  eq(smallPages, plainPages)
  eq((small:gsub("</?small>", "")), plain, "the breaks fall at the same lines")
end)

test("book: a page of credits counts every credit", "adventure", function()
  local trace = {}
  local _, pages = gmbook.paginate(credits(60, true), trace)
  local credited = 0
  for _, t in ipairs(trace) do
    if t.kind == "p" then
      credited = credited + 1
      ok(t.h > 16, "a credit takes a line at least: " .. t.h)
    end
  end
  eq(credited, 60, "each credit is a paragraph the page holds")
  -- before 1.14.1 the credits took no room, so the quotes alone set the pages
  local quotes = {}
  for i = 1, 60 do
    quotes[#quotes + 1] = "> \"Line " .. i .. " of the ferryman's, which he says once and then again, slower.\""
    quotes[#quotes + 1] = ""
  end
  local _, fewer = gmbook.paginate(table.concat(quotes, NL))
  ok(pages > fewer, "credits take pages of their own: " .. pages .. " against " .. fewer)
end)

test("book: a long paragraph in <small> wraps as its words do", "adventure", function()
  local words = "A long credit that runs on for several lines, so that the model has to wrap it " ..
    "as Homebrewery does, at the body's own size, which is the size the theme sets small text at."
  eq(htmlLayout("<small>" .. words .. "</small>"), htmlLayout(words))
  eq(htmlLayout("<span class=\"dm\">" .. words .. "</span>"), htmlLayout(words))
end)

test("book: an autolink's address takes room, as Homebrewery shows it", "adventure", function()
  local link = "<https://example.org/the/ford/and/the/mill/and/the/long/road/past/them/both>"
  eq(htmlLayout(link .. " " .. link .. " " .. link), htmlLayout((link .. " " .. link .. " " .. link):gsub("[<>]", "")))
end)

test("book: a paragraph that ends in a colon inside a tag keeps with what follows", "adventure", function()
  -- a page holds 58 lines in column one and 57 in column two, so the colon
  -- line is the last that fits, and the quote under it isn't
  local fill = {}
  for i = 1, 114 do fill[#fill + 1] = "Line " .. i .. "." end
  local function breaks(colon)
    local text = table.concat(fill, NL .. NL) .. NL .. NL .. colon .. NL .. NL ..
      "> \"Over the ford, and mind the third stone.\""
    local out = gmbook.paginate(text)
    return out:find("\\page", 1, true), out:find(colon, 1, true)
  end
  local brk, at = breaks("Then he says:")
  ok(brk and brk < at, "a colon line goes over with the quote it opens")
  brk, at = breaks("<small>Then he says:</small>")
  ok(brk and brk < at, "and so does one in a tag")
end)
