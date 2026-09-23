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

-------------------------------------------------------------- headings told apart (GM Kit 3.8)

local CELLAR = "Adventure/World/Places/Cellar"

local function useCellar()
  H.pages[CELLAR] = table.concat({
    "---", "type: place", "---", "", "# Cellar", "",
    "## Notes", "", "Damp.", "",
    "## The [Hidden] Door", "", "Behind the barrels.", "",
    "## Notes", "", "The miller keeps his ledger here.", "",
  }, NL)
end

test("parts: two sections under one heading are told apart, and only the one revealed goes", "dm", function()
  useCellar()
  eq(partNames(gm.parts(CELLAR)), "Notes | The [Hidden] Door | Notes (2)")
  H.current = CELLAR
  H.picks = { "Notes (2)" }
  click(gm.bar(), "Reveal part…")
  eq(list(names(H.filterBoxes[#H.filterBoxes].options)), "Notes | The [Hidden] Door | Notes (2)")
  eq(list(gm.revealedPart(CELLAR)), "Notes (2)")
  publish()
  local copy = H.pages["Player/World/Places/Cellar"]
  has(copy, "## Notes" .. NL .. NL .. "The miller keeps his ledger here.")
  hasnt(copy, "Damp.", "the first Notes stays hidden")
end)

test("parts: a heading with brackets in it is revealed, listed and published", "dm", function()
  useCellar()
  ok(gm.revealPart(CELLAR, "The [Hidden] Door"))
  has(H.pages["State/Revealed"], "- [[" .. CELLAR .. "#The %5BHidden%5D Door]]" .. NL)
  eq(list(gm.revealedPart(CELLAR)), "The [Hidden] Door")
  has(textOf(gm.bar(CELLAR).html), "◔ Revealed in part, not published yet: The [Hidden] Door")
  publish()
  has(H.pages["Player/World/Places/Cellar"], "## The [Hidden] Door" .. NL .. NL .. "Behind the barrels.")
  -- one written into the list by hand reads as it is written
  gm.writeRevealed({})
  H.pages["State/Revealed"] = H.pages["State/Revealed"] .. "- [[" .. CELLAR .. "#The [Hidden] Door]]" .. NL
  eq(list(gm.revealedPart(CELLAR)), "The [Hidden] Door")
end)

-------------------------------------------------------------- Undo takes back its own (GM Kit 3.8)

test("undo: undoing a part leaves a part revealed after it", "dm", function()
  gm.revealPart(WARDEN, "Who They Are")
  local first = lastNotification()
  gm.revealPart(WARDEN, "At the Table")
  runAction(first, "Undo")
  eq(entries(WARDEN), WARDEN .. "#At the Table")
end)

test("undo: undoing a mark leaves a part revealed after it", "dm", function()
  gm.mark(WARDEN, "met")
  local met = lastNotification()
  gm.revealPart(WARDEN, "What They Want")
  runAction(met, "Undo")
  eq(entries(WARDEN), WARDEN .. "#What They Want")
  eq(gm.readState(WARDEN, true).met, nil, "and the mark itself is gone")
end)

test("undo: undoing a part the whole page has been revealed over leaves it whole", "dm", function()
  gm.revealPart(WARDEN, "Who They Are")
  local part = lastNotification()
  gm.reveal(WARDEN)
  runAction(part, "Undo")
  eq(entries(WARDEN), WARDEN)
end)

test("undo: undoing an unreveal brings its parts back, and keeps one revealed since", "dm", function()
  gm.revealPart(WARDEN, "Who They Are")
  gm.unreveal(WARDEN)
  local unrevealed = lastNotification()
  gm.revealPart(WARDEN, "At the Table")
  runAction(unrevealed, "Undo")
  eq(entries(WARDEN), WARDEN .. "#At the Table | " .. WARDEN .. "#Who They Are")
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

test("mark met: reveal_first: none marks without revealing anything", "dm", function()
  H.pages[TAM] = H.pages[TAM]:gsub("\nstatus: stub\n", "\nstatus: stub\nreveal_first: none\n")
  gm.mark(TAM, "met")
  eq(lastNotification().message, "Old Tam: met in session 1.")
  eq(entries(TAM), "")
  eq(gm.readState(TAM, true).met, "true")
end)

-------------------------------------------------------------- a name the party mustn't know (GM Kit 3.8)

-- A stranger whose title sits in a stretch above it: the party meet him
-- before they know who he is.
local HEIR = "Adventure/World/People/The Heir"
local HEIR_COPY = "Player/World/People/The Heir"

local function useHeir()
  H.pages[HEIR] = table.concat({
    "---", "type: npc", "---", "",
    "<!--#dm-->", "", "# The Heir", "", "The Warden's son, though nobody has told him yet.", "", "<!--/dm-->", "",
    "## First Impressions", "", "A boy in a borrowed coat, asking about the ford.", "",
  }, NL)
end

test("hidden name: a title in DM-only text hides the page's name, and so does a page with nothing left", "dm", function()
  useHeir()
  ok(gm.hidesName(HEIR), "a title in a stretch")
  ok(not gm.hidesName(WARDEN), "a title of its own")
  ok(not gm.hidesName("Adventure/World/People/Nobody"), "a page that isn't there")
  local page = "Adventure/World/People/Stranger"
  H.pages[page] = "---\ntype: npc\n---\n\n# The <span class=\"dm\">Heir</span>\n\nA boy.\n"
  ok(gm.hidesName(page), "a title part DM-only, and the page's name no longer in it")
  local tinker = "Adventure/World/People/The Tinker"
  H.pages[tinker] = "---\ntype: npc\n---\n\n# The Tinker <span class=\"dm\">(the Warden's spy)</span>\n\nSells lanterns.\n"
  ok(not gm.hidesName(tinker), "a title part DM-only, its page's name still in it")
  H.pages[page] = "---\ntype: npc\n---\n\n<!--#dm-->\n\nThe Warden's son.\n"
  ok(gm.hidesName(page), "no title, and nothing once the DM-only text is out")
  H.pages[page] = "---\ntype: npc\n---\n\nA boy in a borrowed coat.\n"
  ok(not gm.hidesName(page), "no title, and something for the players: its file name is its name")
end)

test("hidden name: marking met records it, reveals nothing, and says why", "dm", function()
  useHeir()
  H.current = HEIR
  click(gm.bar(), "Mark met")
  eq(lastNotification().message, "The Heir: met in session 1. Not revealed: the page's name is DM-only.")
  eq(entries(HEIR), "", "not even its First Impressions")
  eq(gm.readState(HEIR, true).met, "true")
  has(textOf(gm.bar().html), "✓ Met in [[Sessions/Session 1|session 1]]")
  runAction(lastNotification(), "Undo")
  eq(gm.readState(HEIR, true).met, nil)
end)

test("hidden name: the bar says it won't be published, and offers no reveal", "dm", function()
  useHeir()
  local bar = gm.bar(HEIR)
  has(textOf(bar.html), "⊘ Name is DM-only: not published")
  eq(list(buttonsOf(bar.html)), "Mark met | Mark dead…")
  eq(gm.reveal(HEIR), false)
  eq(lastNotification().kind, "warning")
  has(lastNotification().message, "The Heir's name is DM-only")
  eq(gm.revealPart(HEIR, "First Impressions"), false)
  eq(entries(HEIR), "")
end)

test("hidden name: publishing keeps it back, even on the revealed list, and names it", "dm", function()
  useHeir()
  gm.writeRevealed({ HEIR .. "#First Impressions", WARDEN })
  publish()
  eq(H.pages[HEIR_COPY], nil, "no copy at a path that names him")
  ok(H.pages[WARDEN_COPY], "the rest publishes")
  local n = lastNotification()
  eq(n.kind, "warning")
  has(n.message, "Kept back: " .. HEIR .. " hides its name in DM-only text.")
  has(textOf(gm.bar(HEIR).html), "⊘ Name is DM-only: not published, though on the revealed list")
end)

test("hidden name: a copy sent before is named, and its bar takes it back for good", "dm", function()
  useHeir()
  gm.writeRevealed({ HEIR })
  H.pages[HEIR_COPY] = "# The Heir\n\nThe Warden's son.\n"
  publish()
  has(lastNotification().message, "The players still have a copy of " .. HEIR .. ", which gives them its name")
  H.current = HEIR
  local bar = gm.bar()
  has(textOf(bar.html), "◐ Name is DM-only, but the players have a copy")
  click(bar, "Delete their copy")
  eq(H.pages[HEIR_COPY], nil)
  eq(entries(HEIR), "")
  eq((lastNotification().options or {}).actions, nil, "no Undo to send it again")
end)

test("hidden name: a copy with nothing in it is kept back", "dm", function()
  local page = "Adventure/World/Places/Nowhere"
  H.pages[page] = "---\ntype: place\n---\n\n${widget.markdown(\"\")}\n"
  gm.writeRevealed({ page, WARDEN })
  publish()
  eq(H.pages["Player/World/Places/Nowhere"], nil)
  has(lastNotification().message, "Kept back: " .. page .. " would be empty.")
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
