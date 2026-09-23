------------------------------------------------ GM Book: what each edition gets

local function build()
  H.current = "index"
  local report = gmbook.compile({ "dm", "player" })
  return H.pages["Build/Book DM"], H.pages["Build/Book Player"], report
end

------------------------------------------------ a section shown from another page

-- Three pages that keep a section's secret in three ways: the Crown is the
-- DM's from above its title, the Ring keeps its rules under DM Only, and
-- the Brooch keeps its secret in a callout inside the section. A scene that
-- shows each one's rules must not bring any secret into the player edition.
local function vault()
  H.pages["World/Items/Crown"] = "<!--#dm-->\n\n# Crown\n\n## Rules\n\nSECRET-A: the crown is tin.\n"
  H.pages["World/Items/Ring"] = "# Ring\n\nA plain ring.\n\n## DM Only\n\n### Rules\n\n" ..
    "SECRET-B: the ring opens the ford.\n"
  H.pages["World/Items/Brooch"] = "# Brooch\n\n## Rules\n\nIt pins a cloak.\n\n" ..
    "> **dm** Whose\n> SECRET-C: it was Mara's.\n"
  H.pages["Campaign/The Vault"] = "---\nbook_order: 49\n---\n\n# The Vault\n\nThree things on a shelf.\n\n" ..
    "![[World/Items/Crown#Rules]]\n\n![[World/Items/Ring#Rules]]\n\n![[World/Items/Brooch#Rules]]\n\n" ..
    "Nothing else.\n"
end

local function vaultHolds(dm, player, report)
  for _, secret in ipairs({ "SECRET-A", "SECRET-B", "SECRET-C" }) do
    hasnt(player, secret, "the player edition")
    has(dm, secret, "the DM's edition")
  end
  has(player, "Three things on a shelf.\n\n## Rules\n\nIt pins a cloak.\n\nNothing else.",
    "what the players may see of a section still prints")
  eq(list(report.missing), "", "a section kept from the players is not missing")
  eq(#report.kept, 0, "and nothing is kept back")
end

test("book: a section shown from a page is filtered as the whole page is", "adventure", function()
  vault()
  vaultHolds(build())
end)

test("book: a section printed in place is filtered as the whole page is", "adventure", function()
  -- in the book as well, but printed in place all the same
  vault()
  for _, item in ipairs({ "Crown", "Ring", "Brooch" }) do
    H.pages["World/Items/" .. item] = "---\nbook_order: 71\n---\n\n" .. H.pages["World/Items/" .. item]
  end
  config.set("gmBook.transclusions", "inline")
  vaultHolds(build())
end)

test("book: DM-only text an expression prints in a section shown in place is left out", "adventure", function()
  gmbook.printers.mylib = { told = function() return 'Told. <span class="dm">SECRET-D: he lied.</span>' end }
  H.pages["Notes/Rumour"] = "# Rumour\n\n## Heard\n\n${mylib.told()}\n"
  H.pages["Campaign/Tavern"] = "---\nbook_order: 49\n---\n\n# Tavern\n\n![[Notes/Rumour#Heard]]\n"
  local dm, player = build()
  has(dm, "Told. SECRET-D: he lied.")
  has(player, "## Heard\n\nTold.")
  hasnt(player, "SECRET-D")
end)

test("book: a pointer to a section the players don't get stays out of their edition", "adventure", function()
  vault()
  for _, item in ipairs({ "Crown", "Ring", "Brooch" }) do
    H.pages["World/Items/" .. item] = "---\nbook_order: 71\n---\n\n" .. H.pages["World/Items/" .. item]
  end
  local dm, player, report = build()
  has(dm, "Three things on a shelf.\n\n*See Crown: Rules.*\n\n*See Ring: Rules.*\n\n*See Brooch: Rules.*\n\nNothing else.")
  has(player, "Three things on a shelf.\n\n*See Brooch: Rules.*\n\nNothing else.")
  eq(list(report.missing), "")
end)

------------------------------------------------ a pointer's words

test("book: a pointer to a page the players don't get stays out of their edition", "adventure", function()
  H.pages["Campaign/Twist"] = "---\nbook_order: 90\n---\n\n<!--#dm-->\n\n" ..
    "# The Warden Is Mara's Father\n\nHe gave her the ferry, and took it back.\n"
  H.pages["Campaign/Reunion"] = "---\nbook_order: 89\n---\n\n# Reunion\n\nThey meet at the ford.\n\n" ..
    "![[Campaign/Twist]]\n\nThe end.\n"
  local dm, player, report = build()
  has(dm, "They meet at the ford.\n\n*See The Warden Is Mara's Father.*\n\nThe end.")
  has(player, "They meet at the ford.\n\nThe end.")
  hasnt(player, "Mara's Father")
  eq(list(report.missing), "")
end)

test("book: a pointer names its page as the edition prints it", "adventure", function()
  H.pages["World/Items/Ring"] = "---\nbook_order: 72\n---\n\n" ..
    "# The Ring <span class=\"dm\">of the Drowned Warden</span>\n\nA plain ring.\n"
  H.pages["World/Items/Lamps"] = "---\nbook_order: 73\n---\n\n# ${party.N()} Lamps\n\nOne each.\n"
  H.pages["Campaign/Market Day"] = "---\nbook_order: 14\n---\n\n# Market Day\n\n" ..
    "![[World/Items/Ring]]\n\n![[World/Items/Lamps#Lamps]]\n\n![[World/Items/Lamps]]\n"
  H.pages["World/Items/Lamps"] = H.pages["World/Items/Lamps"] .. "\n## Lamps\n\nTin.\n"
  local dm, player, report = build()
  has(dm, "# Market Day\n\n*See The Ring of the Drowned Warden.*\n\n*See Five Lamps: Lamps.*\n\n*See Five Lamps.*")
  has(player, "# Market Day\n\n*See The Ring.*\n\n*See Five Lamps: Lamps.*\n\n*See Five Lamps.*")
  hasnt(player, "Drowned")
  hasnt(dm, "${", "no expression reaches the DM's edition")
  hasnt(player, "${", "or the player edition")
  eq(#report.kept, 0)
end)

------------------------------------------------ a page only the DM may see

-- A map's page is the DM's layer written out: its map block names every
-- creature and trapdoor, and nothing on it is marked DM-only because all of
-- it is. The players get a map where a page of theirs draws it, clean.
local ORCHARD = "World/Maps/The Old Orchard"

local function inTheBook(page, order)
  H.pages[page] = (H.pages[page]:gsub("^%-%-%-\n", "---\nbook_order: " .. order .. "\n", 1))
end

test("book: a map page given a book_order stays out of the player edition", "adventure", function()
  inTheBook(ORCHARD, 90)
  local dm, player, report = build()
  has(dm, "# The Old Orchard", "the DM's edition has the maps appendix")
  has(dm, "S token strangler", "with its map block, the DM's layer written out")
  hasnt(player, "# The Old Orchard", "the player edition has no such chapter")
  hasnt(player, "token strangler")
  hasnt(player, "The clearing at the middle of the old orchard")
  eq(#report.kept, 0)
end)

test("book: a map page shown on a page the players get prints nothing there", "adventure", function()
  H.pages["Campaign/Clearing"] = "---\nbook_order: 49\n---\n\n# Clearing\n\nBefore.\n\n" ..
    "![[World/Maps/The Old Orchard]]\n\nAfter.\n"
  local dm, player, report = build()
  has(dm, "# Clearing\n\nBefore.\n\n## The Old Orchard", "the DM's edition prints it in place")
  has(dm, "S token strangler")
  has(player, "# Clearing\n\nBefore.\n\nAfter.", "the player edition leaves it out")
  hasnt(player, "token strangler")
  eq(list(report.missing), "", "a page kept from the players isn't missing")
  -- in the book as well: the DM's edition points to it, the players' has nothing
  inTheBook(ORCHARD, 90)
  dm, player = build()
  has(dm, "# Clearing\n\nBefore.\n\n*See The Old Orchard.*\n\nAfter.")
  has(player, "# Clearing\n\nBefore.\n\nAfter.")
end)

test("book: pages of a type set private, and GM Maps' own type, stay out too", "adventure", function()
  config.set("gmBook.privateTypes", { "secret" })
  config.set("gmMaps.type", "plan")
  H.pages["Campaign/Plot"] = "---\nbook_order: 91\ntype: secret\n---\n\n# The Plot\n\nThe Warden hid the crown.\n"
  H.pages["World/Maps/Ford"] = "---\nbook_order: 92\ntype: \"plan\"\n---\n\n# The Ford Plan\n\nStepping stones.\n"
  H.pages["Campaign/Crossing"] = "---\nbook_order: 49\n---\n\n# Crossing\n\n![[World/Maps/Ford]]\n\n" ..
    "![[Campaign/Plot]]\n\nOver.\n"
  local dm, player = build()
  has(dm, "# The Plot")
  has(dm, "# The Ford Plan")
  has(dm, "# Crossing\n\n*See The Ford Plan.*\n\n*See The Plot.*\n\nOver.")
  hasnt(player, "The Plot")
  hasnt(player, "Ford Plan")
  has(player, "# Crossing\n\nOver.")
end)

------------------------------------------------ comments

-- A comment doesn't show when the brew renders, but anyone who opens the
-- brew reads it. The player edition leaves comments out; code keeps its own.
test("book: HTML comments stay out of the player edition", "adventure", function()
  H.pages["Campaign/Notes"] = table.concat({
    "---", "book_order: 49", "---", "",
    "# Notes", "",
    "The ford is shallow. <!-- SECRET-E: not at night --> It is cold.", "",
    "<!--", "SECRET-F: the Warden set the fire.", "-->", "",
    "The market opens at dawn.<!-- SECRET-G -->", "",
    "Code keeps its own: `<!-- shown -->`.", "",
    "```", "<!-- also shown -->", "```", "",
    "The end.", "",
  }, "\n")
  local dm, player = build()
  for _, secret in ipairs({ "SECRET-E", "SECRET-F", "SECRET-G" }) do
    hasnt(player, secret, "the player edition")
    has(dm, secret, "the DM's edition keeps its comments")
  end
  has(player, "# Notes\n\nThe ford is shallow. It is cold.\n\nThe market opens at dawn.\n\n" ..
    "Code keeps its own: `<!-- shown -->`.\n\n```\n<!-- also shown -->\n```\n\nThe end.")
end)

test("book: a comment never closed hides the rest of the player edition's page", "adventure", function()
  H.pages["Campaign/Notes"] = "---\nbook_order: 49\n---\n\n# Notes\n\nShown.\n\n<!-- SECRET-H\n\nStill hidden.\n"
  local _, player = build()
  has(player, "# Notes\n\nShown.")
  hasnt(player, "SECRET-H")
  hasnt(player, "Still hidden.")
end)

test("book: a pointer to a page whose title the players don't get names nothing", "adventure", function()
  H.pages["Campaign/Road"] = "---\nbook_order: 60\n---\n\n# The Road\n\nA stranger waits.\n\n![[World/People/Hob]]\n\nOn they go.\n"
  -- the name is the secret: the title sits in a stretch, the rest is public
  H.pages["World/People/Hob"] = "---\nbook_order: 61\n---\n\n<!--#dm-->\n# Hob\n<!--/dm-->\n\nA stranger in a grey hood.\n"
  gmbook.compile({ "dm", "player" })
  local dm, player = H.pages["Build/Book DM"], H.pages["Build/Book Player"]
  has(dm, "*See Hob.*")
  has(player, "A stranger waits.\n\nOn they go.")
  hasnt(player, "Hob")
end)
