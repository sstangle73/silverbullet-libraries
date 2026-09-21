------------------------------------------------------------------ GM Bestiary

local STRANGLER = "World/Monsters/Strangler"
local CREEPER = "World/Monsters/Creeper"
local CROW = "World/Monsters/Crow"

local function unescapeRef(s)
  return (s:gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&quot;", '"'):gsub("&amp;", "&"))
end
local function seen(w)
  assert(type(w.html) == "string", "a GM Bestiary widget's html should be text")
  return unescapeRef((w.html:gsub("<[^>]*>", "")))
end
local function href(w)
  return unescapeRef(w.html:match(' href="([^"]*)"') or "")
end

test("bestiary: loads in Adventure and in DM", "adventure", function()
  ok(bestiary and bestiary.ref and bestiary.creature, "no GM Bestiary in the Adventure space")
  eq(config.get("gmBestiary.type"), nil, "the defaults need no campaign settings")
end)

test("bestiary: a creature page says what to run it as", "adventure", function()
  local c = bestiary.creature(STRANGLER)
  eq(c.page, STRANGLER)
  eq(c.title, "Strangler")
  eq(c.statblock, "Vine Blight")
  eq(c.entry, "Blights")
  eq(c.source, "Monster Manual")
  eq(c.cr, "1/2")
  eq(c.url, "https://www.dndbeyond.com/monsters/5195252-vine-blight")
end)

test("bestiary: the reference links on the page and cites in print", "adventure", function()
  local w = bestiary.ref(STRANGLER)
  eq(seen(w), "Vine Blight — Monster Manual, Blights")
  eq(href(w), "https://www.dndbeyond.com/monsters/5195252-vine-blight")
  has(w.html, "<em>Blights</em>", "the HTML face is not Markdown, so the entry is an element")
  hasnt(w.html, "*", "and never raw asterisks")
  eq(w.markdown, "[Vine Blight](https://www.dndbeyond.com/monsters/5195252-vine-blight)" ..
     " — Monster Manual, *Blights*")
  eq(bestiary.printed.ref(STRANGLER), "Vine Blight — Monster Manual, *Blights*", "print carries no URL")
end)

test("bestiary: an entry that only repeats the stat block's name is left off", "adventure", function()
  H.pages["World/Monsters/Wight"] =
    "---\ntype: monster\nstatblock: Wight\nentry: Wight\nsource: Monster Manual\n---\n\n# Wight\n"
  bestiary.refresh()
  eq(bestiary.printed.ref("World/Monsters/Wight"), "Wight — Monster Manual")
  eq(bestiary.printed.ref(CROW), "Raven — Monster Manual, *Animals*",
     "a crow runs as a raven, which is filed under Animals, not under its own name")
end)

test("bestiary: a creature with no official match is original to the book", "adventure", function()
  H.pages["World/Monsters/Rootling"] = "---\ntype: monster\n---\n\n# Rootling\n"
  bestiary.refresh()
  eq(bestiary.printed.ref("World/Monsters/Rootling"), "*Original to this book.*")
  eq(bestiary.cite(bestiary.creature("World/Monsters/Rootling"), "rootling"), "original to this book")
end)

test("bestiary: a page it can't find says so rather than printing", "adventure", function()
  has(seen(bestiary.ref("World/Monsters/Nothing")), "No creature page for World/Monsters/Nothing.")
  eq(bestiary.printed.ref("World/Monsters/Nothing"), nil,
     "a build leaves a broken reference in as code and names the page")
end)

test("bestiary: the reference reads the page it is on, and the one being printed", "adventure", function()
  H.current = STRANGLER
  eq(bestiary.ref().markdown, bestiary.ref(STRANGLER).markdown)
  gmbook.printing = CROW
  eq(bestiary.printed.ref(), "Raven — Monster Manual, *Animals*")
  gmbook.printing = nil
end)

test("bestiary: a path written for Adventure finds the page from DM", "dm", function()
  eq(bestiary.find(STRANGLER).name, "Adventure/" .. STRANGLER)
  eq(bestiary.find("Adventure/" .. STRANGLER).name, "Adventure/" .. STRANGLER)
  eq(bestiary.printed.ref(STRANGLER), "Vine Blight — Monster Manual, *Blights*")
end)

test("bestiary: a tail two creature pages share finds neither", "dm", function()
  H.pages["Author/World/Monsters/Strangler"] =
    "---\ntype: monster\nstatblock: Wrong\n---\n\n# Strangler\n"
  bestiary.refresh()
  eq(bestiary.find("Monsters/Strangler"), nil)
  eq(bestiary.find("Adventure/" .. STRANGLER).name, "Adventure/" .. STRANGLER, "the full path still works")
end)

------------------------------------------------------------------ fights that name a page

-- Scene 3's fight, as the scene writes it.
local ORCHARD = { "The old orchard", level = 1, difficulty = "low",
  { 1, "strangler", cr = "1/2", page = STRANGLER },
  { 6, "creeper", cr = "1/8", step = 2, min = 2, page = CREEPER },
}
local FIVE = { 1, 1, 1, 1, 1 }

test("party: a fight's creatures print with the citation from their pages", "adventure", function()
  local printed = party.fightPrint(ORCHARD)
  has(printed, "**The creatures.** Strangler — Monster Manual, *Blights* (vine blight). " ..
      "Creeper — Monster Manual, *Blights* (twig blight).")
  ok(printed:find("**The old orchard.**", 1, true) < printed:find("**The creatures.**", 1, true),
     "the creatures come after the fight")
  ok(printed:find("**The creatures.**", 1, true) < printed:find("**Adjusting the Encounter.**", 1, true),
     "and before Adjusting the Encounter")
end)

test("party: a fight whose creatures have no page prints as it always did", "adventure", function()
  hasnt(party.fightPrint({ "Drill site", level = 3, { 1, "wight", cr = 3 } }), "The creatures.")
end)

test("party: on the page each creature links to its own", "adventure", function()
  local w = party.fight(ORCHARD)
  has(w.html, "The creatures: ")
  has(w.html, 'href="https://wiki.example.org/adventure/World/Monsters/Strangler"')
  has(w.html, ">Strangler<")
  has(w.html, ">Creeper<")
  -- the link is the page's name as the browser writes it, so a space in
  -- one is encoded: the fixture's creatures are one word each, so this one
  -- is two
  H.pages["World/Monsters/Old Strangler"] = FIXTURES.adventure[STRANGLER]
  bestiary.refresh()
  local old = party.fight { "The old orchard", level = 1,
    { 1, "old strangler", cr = "1/2", page = "World/Monsters/Old Strangler" } }
  has(old.html, 'href="https://wiki.example.org/adventure/World/Monsters/Old%20Strangler"')
end)

test("party: a creature whose page isn't there is flagged, not linked", "adventure", function()
  local gone = { "Gone", level = 1, { 1, "rootling", cr = "1/4", page = "World/Monsters/Nope" } }
  local w = party.fight(gone)
  has(w.html, "Rootling (no page)")
  hasnt(w.html, "href=")
  has(list(party.warnings(gone, party.roster(gone, 5), FIVE, "low")),
      "The rootling names a page that isn't there: World/Monsters/Nope.")
  hasnt(party.fightPrint(gone), "The creatures.")
end)

test("party: a CR that disagrees with the creature's page is flagged", "adventure", function()
  local wrong = { "Wrong CR", level = 1, { 1, "strangler", cr = 1, page = STRANGLER } }
  has(list(party.warnings(wrong, party.roster(wrong, 5), FIVE, "low")),
      "The strangler is CR 1 here, and CR 1/2 on Strangler.")
  -- the wording of that warning, which "disagree" never was
  hasnt(list(party.warnings(ORCHARD, party.roster(ORCHARD, 5), FIVE, "low")), " here, and CR ",
        "Scene 3's fight gives each creature the CR on its page")
end)

test("party: with no library to cite them, a page is linked and nothing prints", "adventure", function()
  local was = party.creatureRef
  party.creatureRef = nil
  has(party.fight(ORCHARD).html, "The creatures: ")
  hasnt(party.fightPrint(ORCHARD), "The creatures.")
  party.creatureRef = was
end)

------------------------------------------------------------------ the Bestiary in the book

test("bestiary: the Bestiary is one chapter with a section per creature", "adventure", function()
  local rows = __liq(function() return index.pages() end,
    function(p) return p.type == "monster" end,
    { { fn = function(p) return p.book_order end, desc = false } }, nil, nil)
  eq(#rows, 3)
  eq(rows[1].name, STRANGLER)
  eq(rows[3].name, CROW)
  for _, p in ipairs(rows) do
    eq(p.book_section, true, p.name .. " must be a section of the Bestiary chapter")
    ok(p.book_order > 79 and p.book_order < 80, p.name .. " belongs under 79")
    ok(p.statblock and p.source and p.ddb, p.name .. " is missing part of its citation")
    has(H.pages[p.name], "\n## Run it as\n")
    has(H.pages[p.name], "\n### Where it turns up\n")
  end
  eq(FIXTURES.adventure["World/Monsters"]:match("book_order: (%d+)"), "79")
end)

test("bestiary: the Bestiary compiles into one chapter, not one each", "adventure", function()
  gmbook.compile({ "dm", "player" })
  local dm = H.pages["Build/Book DM"]
  has(dm, "\n# Bestiary\n")
  has(dm, "\n## Strangler\n")
  has(dm, "\n### Run it as\n\nVine Blight — Monster Manual, *Blights*\n")
  eq(count(dm:sub(dm:find("# Bestiary", 1, true)), "\\page"), 0, "no page break inside the Bestiary")
  hasnt(dm, "${bestiary")
  hasnt(dm, "dndbeyond.com/monsters", "no URL reaches the printed book")
  hasnt(H.pages["Build/Book Player"], "dndbeyond.com/monsters")
end)

test("bestiary: the players' edition keeps the secrets off the contents too", "adventure", function()
  -- no creature in the fixture keeps a secret, so the crow is given one
  local secret = "Every crow that flies home tells the Warden who crossed the ford."
  H.pages[CROW] = FIXTURES.adventure[CROW] .. "\n## DM Only\n\n" .. secret .. "\n"
  gmbook.compile({ "dm", "player" })
  has(H.pages["Build/Book DM"], secret, "the DM's edition says what the crows are for")
  local player = H.pages["Build/Book Player"]
  has(player, "\n# Bestiary\n")
  hasnt(player, secret, "and the players' does not")
end)

test("bestiary: Scene 3 links to the pages instead of saying what to run", "adventure", function()
  local scene = FIXTURES.adventure["Campaign/Act I/Scene 3"]
  hasnt(scene, "as a vine blight")
  hasnt(scene, "as twig blights")
  has(scene, 'page = "World/Monsters/Strangler"')
  has(scene, 'page = "World/Monsters/Creeper"')
  -- and its prose links to them rather than saying what to run them as
  has(scene, "[strangler](<../../World/Monsters/Strangler>)")
  has(scene, "[creepers](<../../World/Monsters/Creeper>)")
  has(FIXTURES.adventure["Campaign/Act I/Scene 1"], "[crow](<../../World/Monsters/Crow>)")
end)
