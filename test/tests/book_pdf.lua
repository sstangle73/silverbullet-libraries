------------------------------------------------ GM Book: what the PDF's printer says of it

-- A campaign's printing script leaves <edition>.pdf.json beside each PDF it
-- prints: how many pages, when, with which Homebrewery, and the pages whose
-- text ran past their foot. The bar says so beside Open PDF.

-- mocks.lua has no space.readFile yet. SilverBullet 2.11's reads any file
-- in the space as bytes, a Uint8Array that encoding.utf8Decode makes text;
-- here a file's H.files[path].data is its text, or { bytes = text } for
-- bytes, which the encoding stand-in reads.
if not space.readFile then
  function space.readFile(name)
    if H.failMeta and H.failMeta[name] then error(H.failMeta[name]) end
    local f = H.files[name]
    if f == nil or f.data == nil then error("Not found: " .. name) end
    return f.data
  end
end
if not encoding then
  encoding = { utf8Decode = function(data)
    assert(type(data) == "table" and type(data.bytes) == "string", "utf8Decode needs bytes")
    return data.bytes
  end }
end

local PRINTED = '{"edition": "dm", "pages": 83, "spills": [[14, "The ford is knee deep"], [31, "and the rest"]], ' ..
  '"printed_at": "2026-09-22T14:03:11Z", "chrome": "140.0.7339.80", "sandbox": true, ' ..
  '"homebrewery": {"version": "3.23.0", "hash": "4f2a9c1"}}'

local function printed(page, json)
  H.files[page .. ".pdf"] = { lastModified = 2000, contentType = "application/pdf" }
  H.files[page .. ".pdf.json"] = json and { lastModified = 2000, contentType = "application/json", data = json }
end

-- The bar's parts in order, each a button's label or a span's words.
local function barParts(page)
  local out = {}
  for _, c in ipairs(gmbook.bar(page).html.children) do out[#out + 1] = textOf(c) end
  return out
end

test("book: the bar says what the PDF's printer says of it", "adventure", function()
  gmbook.compile({ "dm", "player" })
  printed("Build/Book DM", PRINTED)
  local parts = barParts("Build/Book DM")
  eq(parts[3], "Open PDF")
  eq(parts[4], "83 pages · printed 22 Sep · Homebrewery 3.23.0", "beside Open PDF")
  eq(parts[5], "⚠ 2 pages spill: p. 14, p. 31", "and the pages that spill, with a glyph and words")
  eq(list(buttonsOf(gmbook.bar("Build/Book DM").html)),
    "Build again | Open PDF | Copy for Homebrewery | Open Homebrewery", "its buttons as ever")
  -- the player edition's PDF has no such file
  printed("Build/Book Player", nil)
  hasnt(textOf(gmbook.bar("Build/Book Player").html), "pages ·")
end)

test("book: a PDF that doesn't spill says nothing of spilling", "adventure", function()
  gmbook.compile({ "dm" })
  printed("Build/Book DM", '{"pages": 1, "spills": [], "printed_at": "2026-01-05T09:00:00Z"}')
  local text = textOf(gmbook.bar("Build/Book DM").html)
  has(text, "1 page · printed 5 Jan")
  hasnt(text, "⚠")
  printed("Build/Book DM", '{"spills": [[7, "a"], [7, "b"], [9, "c"]]}')
  eq(barParts("Build/Book DM")[4], "⚠ 2 pages spill: p. 7, p. 9", "each page once, and no line of nothing")
  local many = {}
  for p = 1, 8 do many[#many + 1] = "[" .. p * 10 .. ", \"x\"]" end
  printed("Build/Book DM", '{"spills": [' .. table.concat(many, ", ") .. "]}")
  eq(barParts("Build/Book DM")[4], "⚠ 8 pages spill: p. 10, p. 20, p. 30, p. 40, p. 50, and 3 more")
  printed("Build/Book DM", '{"spills": [[3, "only"]]}')
  eq(barParts("Build/Book DM")[4], "⚠ 1 page spills: p. 3")
end)

test("book: a malformed provenance never breaks the bar", "adventure", function()
  gmbook.compile({ "dm" })
  local want = "Build again | Open PDF | Copy for Homebrewery | Open Homebrewery"
  for _, json in ipairs({ "{not json at all", '"just words"', "[1, 2, 3]", "",
                          '{"pages": "many", "printed_at": 5, "homebrewery": "3", "spills": "lots"}',
                          '{"pages": 2.5, "printed_at": "yesterday", "spills": [["14", "x"], [-1, "y"], null]}',
                          '{"printed_at": "2026-13-40T00:00:00Z"}', '{"printed_at": "2026-09-00T00:00:00Z"}' }) do
    printed("Build/Book DM", json)
    local fine, bar = pcall(gmbook.bar, "Build/Book DM")
    ok(fine, "the bar draws over " .. json)
    eq(list(buttonsOf(bar.html)), want, json)
    eq(#bar.html.children, 5, "and says nothing of it: " .. json)
  end
  -- a file the client can't read
  printed("Build/Book DM", PRINTED)
  H.failMeta = { ["Build/Book DM.pdf.json"] = "offline" }
  eq(#gmbook.bar("Build/Book DM").html.children, 5)
  H.failMeta = nil
  local real = space.readFile
  space.readFile = function() error("the server is restarting") end
  local fine, bar = pcall(gmbook.bar, "Build/Book DM")
  space.readFile = real
  ok(fine, "a read that fails is no reason not to draw")
  eq(#bar.html.children, 5)
end)

test("book: a provenance without its PDF says nothing, and one read as bytes says it all", "adventure", function()
  gmbook.compile({ "dm" })
  H.files["Build/Book DM.pdf.json"] = { lastModified = 2000, data = PRINTED }
  hasnt(textOf(gmbook.bar("Build/Book DM").html), "83 pages", "no PDF, so nothing to say it of")
  printed("Build/Book DM", { bytes = PRINTED })
  eq(barParts("Build/Book DM")[4], "83 pages · printed 22 Sep · Homebrewery 3.23.0")
end)

test("book: in the DM space the provenance is the one beside Adventure/Build", "dm", function()
  gmbook.compile({ "dm" })
  printed("Build/Book DM", PRINTED)
  hasnt(textOf(gmbook.bar("Adventure/Build/Book DM").html), "83 pages")
  printed("Adventure/Build/Book DM", PRINTED)
  has(textOf(gmbook.bar("Adventure/Build/Book DM").html), "83 pages · printed 22 Sep")
end)

test("book: a Homebrewery version can't put markup on the bar", "adventure", function()
  gmbook.compile({ "dm" })
  printed("Build/Book DM", '{"homebrewery": {"version": "<b>${party.n()}</b> [x](y)"}}')
  local line = barParts("Build/Book DM")[4]
  hasnt(line, "<b>", "a tag is escaped")
  has(line, "\\<b\\>\\$\\{party.n()\\}", "and an expression")
end)
