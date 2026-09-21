------------------------------------------------------------------ Revealing part of a page (GM Kit 3.4)
-- A page can be revealed a section at a time, and marking someone met or
-- a place visited reveals only what the page says the players see first.

local WARDEN = "Adventure/World/People/The Warden"     -- has a First Impressions section
local MARA = "Adventure/World/People/Mara"             -- reveal_first: [Who They Are]
local TAM = "Adventure/World/People/Old Tam"           -- says nothing: its name alone
local FORDTOWN = "Adventure/World/Places/Fordtown"     -- reveal_first: all
local WARDEN_COPY = "Player/World/People/The Warden"
local NL = string.char(10)

-- The revealed list's entries for one page: the fixture reveals others.
local function entries(page) return list(gm.revealEntries(page)) end
local function partNames(p)
  local out = {}
  for _, part in ipairs(p.parts) do out[#out + 1] = part.name end
  return list(out)
end
local function publish()
  H.confirms = { true }
  gm.publish()
end

-------------------------------------------------------------- a page's parts

test("parts: a page's parts are its ## sections, with its DM-only text gone", "dm", function()
  local p = gm.parts(WARDEN)
  eq(p.name, "The Warden")
  eq(p.title, "# The Warden")
  eq(partNames(p), "First Impressions | Who They Are | What They Want | At the Table",
     "a DM Only section is never a part")
end)

test("parts: fenced code holds no headings, and a page without a title goes by its name", "dm", function()
  H.pages["Adventure/World/Items/Note"] = table.concat({
    "---", "type: item", "---", "", "A folded note.", "",
    "## Front", "", "Words.", "", "```", "## Not a heading", "```", "",
    "## Back", "", "More.", "",
  }, NL)
  local p = gm.parts("Adventure/World/Items/Note")
  eq(p.title, nil)
  eq(p.name, "Note")
  eq(partNames(p), "Front | Back")
  has(table.concat(p.parts[1].lines, NL), "## Not a heading", "the fence stays in the part it sits in")
  eq(table.concat(p.opening, NL), NL .. "A folded note." .. NL, "the opening is kept apart")
end)

test("parts: a heading inside a DM stretch or callout is no part", "dm", function()
  H.pages["Adventure/World/Places/Cellar"] = table.concat({
    "---", "type: place", "---", "", "# Cellar", "",
    "## Stairs", "", "Steep.", "",
    "<!--#dm-->", "", "## The Hoard", "", "Gold under the flags.", "", "<!--/dm-->", "",
    "## Door", "", "Oak.", "",
    "> **dm** Who keeps it", "> The miller.", "",
  }, NL)
  eq(partNames(gm.parts("Adventure/World/Places/Cellar")), "Stairs | Door")
end)

test("parts: a frontmatter list reads in each YAML form", "dm", function()
  local function read(value)
    return list(gm.frontmatterList("---" .. NL .. value .. NL .. "type: npc" .. NL .. "---" .. NL, "reveal_first"))
  end
  eq(read("reveal_first: Who They Are"), "Who They Are")
  eq(read("reveal_first: [Who They Are, 'At the Table']"), "Who They Are | At the Table")
  eq(read("reveal_first:" .. NL .. "  - Who They Are" .. NL .. '  - "At the Table"'), "Who They Are | At the Table")
  eq(read("other: x"), "")
end)

-------------------------------------------------------------- revealing a part

test("reveal part: the list names the section, and the bar says what the players can see", "dm", function()
  H.current = WARDEN
  local bar = gm.bar()
  eq(list(buttonsOf(bar.html)), "Reveal | Reveal part… | Mark met | Mark dead…")
  H.picks = { "What They Want" }
  click(bar, "Reveal part…")
  eq(entries(WARDEN), WARDEN .. "#What They Want")
  has(H.pages["State/Revealed"], "- [[" .. WARDEN .. "#What They Want]]" .. NL)
  eq(lastNotification().message, "Revealed “What They Want” of The Warden. The players see it once you publish.")
  ok(gm.isRevealed(WARDEN), "revealed in part is revealed")
  eq(list(gm.revealedPart(WARDEN)), "What They Want")
  bar = gm.bar()
  has(textOf(bar.html), "◔ Revealed in part, not published yet: What They Want")
  eq(list(buttonsOf(bar.html)), "Reveal all | Reveal part… | Unreveal | Mark met | Mark dead…")
  publish()
  has(textOf(gm.bar().html), "◔ Revealed in part: What They Want")
end)

test("reveal part: the picker offers what isn't revealed yet, and Undo takes back only its own", "dm", function()
  gm.revealPart(WARDEN, "Who They Are")
  H.current = WARDEN
  H.picks = { "At the Table" }
  H.commands["GM: Reveal Part"].run()
  eq(list(names(H.filterBoxes[#H.filterBoxes].options)), "First Impressions | What They Want | At the Table")
  eq(list(gm.revealedPart(WARDEN)), "At the Table | Who They Are", "in the list's order")
  runAction(lastNotification(), "Undo")
  eq(entries(WARDEN), WARDEN .. "#Who They Are", "the part revealed before stays")
end)

test("reveal part: off a page, the command asks which page and then which part", "dm", function()
  H.current = "Session Table"
  H.picks = { "World/People/Mara", "What They Want" }
  H.commands["GM: Reveal Part"].run()
  eq(entries(MARA), MARA .. "#What They Want")
end)

test("reveal part: once every part is out, the bar stops offering one", "dm", function()
  for _, part in ipairs({ "First Impressions", "Who They Are", "What They Want", "At the Table" }) do
    gm.revealPart(WARDEN, part)
  end
  local buttons = list(buttonsOf(gm.bar(WARDEN).html))
  hasnt(buttons, "Reveal part…")
  has(buttons, "Reveal all", "a section added later stays hidden until the whole page is revealed")
  H.current = WARDEN
  H.commands["GM: Reveal Part"].run()
  eq(lastNotification().message, "Every part of The Warden is revealed already")
end)

test("reveal part: a page only the DM may see is refused", "dm", function()
  local map = "Adventure/World/Maps/The Old Orchard"
  eq(gm.revealPart(map, "Anything"), false)
  eq(lastNotification().kind, "warning")
  eq(entries(map), "")
end)

test("reveal part: a page revealed whole has no parts to reveal", "dm", function()
  gm.reveal(WARDEN)
  eq(gm.revealPart(WARDEN, "Who They Are"), false)
  eq(lastNotification().message, "The Warden is revealed whole already")
end)

-------------------------------------------------------------- whole and back again

test("reveal all: a page revealed in part is revealed whole, and Undo puts the parts back", "dm", function()
  gm.revealPart(WARDEN, "Who They Are")
  H.current = WARDEN
  click(gm.bar(), "Reveal all")
  eq(entries(WARDEN), WARDEN, "the whole page, in place of its parts")
  runAction(lastNotification(), "Undo")
  eq(entries(WARDEN), WARDEN .. "#Who They Are")
end)

test("unreveal: every part comes back, the copy goes, and Undo returns both", "dm", function()
  gm.revealPart(WARDEN, "Who They Are")
  gm.revealPart(WARDEN, "At the Table")
  publish()
  local copy = H.pages[WARDEN_COPY]
  ok(copy, "published")
  H.current = WARDEN
  click(gm.bar(), "Unreveal")
  eq(entries(WARDEN), "")
  eq(H.pages[WARDEN_COPY], nil)
  runAction(lastNotification(), "Undo")
  eq(entries(WARDEN), WARDEN .. "#At the Table | " .. WARDEN .. "#Who They Are")
  eq(H.pages[WARDEN_COPY], copy)
end)

-------------------------------------------------------------- publishing

test("publish: a page revealed in part sends its title and those parts, in the page's order", "dm", function()
  gm.writeRevealed({})
  gm.revealPart(WARDEN, "At the Table")
  gm.revealPart(WARDEN, "First Impressions")
  publish()
  eq(H.pages[WARDEN_COPY], table.concat({
    "---", "type: npc", "---", "",
    "# The Warden", "",
    "## First Impressions", "",
    "A tall figure in a grey coat, with the keys of the ford on a chain.", "",
    "## At the Table", "",
    "Polite, tired, and never in a hurry. The Warden answers a question with a question.", "",
  }, NL))
  has(lastNotification().message, "Published to players: 1 new, 0 updated, 0 unchanged.")
end)

test("publish: a part keeps its DM-only text back, and nothing says there is more", "dm", function()
  H.pages["Adventure/World/Places/Cellar"] = table.concat({
    "---", "type: place", "---", "", "# Cellar", "",
    "The DM's summary: the miller hides his gold here.", "",
    "## Stairs", "", "Steep. <span class=\"dm\">The third one creaks.</span>", "",
    "> **dm** Who comes down", "> The miller, at midnight.", "",
    "## Door", "", "Oak.", "",
  }, NL)
  gm.revealPart("Adventure/World/Places/Cellar", "Stairs")
  publish()
  local copy = H.pages["Player/World/Places/Cellar"]
  eq(copy, "---" .. NL .. "type: place" .. NL .. "---" .. NL .. NL .. "# Cellar" .. NL .. NL ..
           "## Stairs" .. NL .. NL .. "Steep." .. NL)
  hasnt(copy, "summary", "the opening goes only with the whole page")
end)

test("publish: a revealed part the page no longer has is named", "dm", function()
  gm.writeRevealed({ WARDEN .. "#Old Heading", WARDEN .. "#Who They Are" })
  publish()
  local n = lastNotification()
  has(n.message, "Revealed but no longer there: " .. WARDEN .. "#Old Heading.")
  eq(n.kind, "warning")
  has(H.pages[WARDEN_COPY], "## Who They Are")
end)

test("publish: a page revealed by name alone sends its title and nothing else", "dm", function()
  gm.writeRevealed({ TAM .. "#Old Tam" })
  publish()
  eq(H.pages["Player/World/People/Old Tam"], "---" .. NL .. "type: npc" .. NL .. "---" .. NL .. NL .. "# Old Tam" .. NL)
end)

-------------------------------------------------------------- marks reveal what a page shows first

test("mark met: reveals the page's First Impressions, not the whole page", "dm", function()
  H.current = WARDEN
  click(gm.bar(), "Mark met")
  eq(lastNotification().message, "The Warden: met in session 1, and revealed “First Impressions”.")
  eq(entries(WARDEN), WARDEN .. "#First Impressions")
  publish()
  local copy = H.pages[WARDEN_COPY]
  has(copy, "## First Impressions")
  for _, rest in ipairs({ "Who They Are", "What They Want", "At the Table", "crown" }) do
    hasnt(copy, rest, "only what the players see first")
  end
end)

test("mark met: the sections a page names under reveal_first", "dm", function()
  gm.mark(MARA, "met")
  eq(lastNotification().message, "Mara: met in session 1, and revealed “Who They Are”.")
  eq(entries(MARA), MARA .. "#Who They Are")
end)

test("mark met: several sections, named in a list", "dm", function()
  H.pages[MARA] = H.pages[MARA]:gsub("reveal_first: %[Who They Are%]",
    "reveal_first:" .. NL .. "  - Who They Are" .. NL .. "  - What They Want")
  gm.mark(MARA, "met")
  eq(lastNotification().message, "Mara: met in session 1, and revealed “Who They Are” and “What They Want”.")
  eq(entries(MARA), MARA .. "#What They Want | " .. MARA .. "#Who They Are")
end)

test("mark met: a page that says nothing is revealed by its name alone", "dm", function()
  gm.mark(TAM, "met")
  eq(lastNotification().message, "Old Tam: met in session 1, and revealed by name.")
  eq(entries(TAM), TAM .. "#Old Tam")
  local bar = gm.bar(TAM)
  has(textOf(bar.html), "◔ Revealed by name only, not published yet")
  has(list(buttonsOf(bar.html)), "Reveal all | Reveal part… | Unreveal")
end)

test("mark met: sections named that the page lacks reveal its name alone", "dm", function()
  H.pages[MARA] = H.pages[MARA]:gsub("%[Who They Are%]", "[Nowhere]")
  gm.mark(MARA, "met")
  eq(lastNotification().message, "Mara: met in session 1, and revealed by name.")
end)

test("mark visited: reveal_first: all reveals the whole page", "dm", function()
  gm.mark(FORDTOWN, "visited")
  eq(lastNotification().message, "Fordtown: visited in session 1, and revealed.")
  eq(entries(FORDTOWN), FORDTOWN)
end)

test("mark met: a page revealed whole stays whole, and says nothing of it", "dm", function()
  gm.reveal(WARDEN)
  gm.mark(WARDEN, "met")
  eq(lastNotification().message, "The Warden: met in session 1.")
  eq(entries(WARDEN), WARDEN)
end)

test("mark met: a page revealed in part gains what it shows first, and Undo takes back only that", "dm", function()
  gm.revealPart(WARDEN, "At the Table")
  gm.mark(WARDEN, "met")
  eq(lastNotification().message, "The Warden: met in session 1, and revealed “First Impressions”.")
  eq(list(gm.revealedPart(WARDEN)), "At the Table | First Impressions")
  runAction(lastNotification(), "Undo")
  eq(entries(WARDEN), WARDEN .. "#At the Table")
  eq(gm.readState(WARDEN, true).met, nil)
end)

test("mark met: a page already revealed by some part isn't revealed by name as well", "dm", function()
  gm.revealPart(TAM, "Who They Are")
  gm.mark(TAM, "met")
  eq(lastNotification().message, "Old Tam: met in session 1.")
  eq(entries(TAM), TAM .. "#Who They Are")
end)

-------------------------------------------------------------- pickers

test("pickers: Reveal Page offers a page revealed in part, and Unreveal lists pages, not parts", "dm", function()
  gm.revealPart(WARDEN, "Who They Are")
  gm.revealPart(WARDEN, "At the Table")
  H.current = "Session Table"
  H.picks = { NIL }
  H.commands["GM: Reveal Page"].run()
  local box = H.filterBoxes[#H.filterBoxes]
  local found
  for _, o in ipairs(box.options) do
    if o.name == "World/People/The Warden" then found = o end
  end
  ok(found, "a page revealed in part can still be revealed whole")
  eq(found.description, "Revealed in part")
  H.picks = { NIL }
  H.commands["GM: Unreveal Page"].run()
  box = H.filterBoxes[#H.filterBoxes]
  local warden = 0
  for _, o in ipairs(box.options) do
    if o.name == "World/People/The Warden" then
      warden = warden + 1
      eq(o.description, "Revealed in part, not published yet")
    end
    hasnt(o.name, "#", "a page, not one of its parts")
  end
  eq(warden, 1)
end)
