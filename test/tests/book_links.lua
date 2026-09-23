------------------------------------------------ GM Book: links the player edition can't follow

-- The book prints a link to a page as its label. In the player edition that
-- label can name a page the players have nothing of: one kept back for the
-- DM whole, one only the DM may see, one not in the book at all. That may
-- be meant, so a build says so and no more.

local NL = string.char(10)

local function build()
  H.current = "index"
  return gmbook.build({ "dm", "player" })
end

local function named(report)
  local out = {}
  for _, m in ipairs(report.missingLinks) do out[#out + 1] = m.page .. " <- " .. m.label .. " (" .. m.from .. ")" end
  return list(out)
end

test("book: the campaign's own player edition names no page it lacks", "adventure", function()
  local report = build()
  eq(#report.missingLinks, 0)
  hasnt(lastNotification().message, "doesn't contain")
end)

test("book: links to pages the player edition has nothing of are named", "adventure", function()
  -- kept back whole: the stretch opens above the title
  H.pages["World/Secrets/Plot"] = "---\nbook_order: 81\n---\n\n<!--#dm-->\n\n# The Plot\n\nThe crown is tin.\n"
  H.pages["Notes/Aside"] = "# Aside\n\nNot in the book.\n"
  H.pages["Campaign/Crossroads"] = table.concat({
    "---", "book_order: 14", "---", "",
    "# Crossroads", "",
    "Signs point to [the Warden's plan](<../World/Secrets/Plot>), to [the orchard](<../World/Maps/The Old Orchard>),",
    "to [[World/People/Nobody]], to [[Notes/Aside|an aside]] and to the [Lantern](<../World/Items/Lantern>),",
    "which [[Items/Lantern|the book has]], as it has [the market](<../Campaign/Act I/Scene 2#The Market>).", "",
    "Code keeps its own: `[[World/People/Somebody]]`.", "",
    "```", "[[World/People/Anybody]]", "```", "",
    "![A sketch](<../World/Maps/sketch.png>), [a site](https://example.org), [a note](<../Notes/Aside.pdf>).", "",
    "> **dm** Between us",
    "> The [plot](<../World/Secrets/Plot>) is the DM's.",
  }, NL)
  local report = build()
  eq(#report.written, 2, "the book is written all the same")
  eq(named(report), "World/Secrets/Plot <- the Warden's plan (Campaign/Crossroads) | " ..
    "World/Maps/The Old Orchard <- the orchard (Campaign/Crossroads) | " ..
    "World/People/Nobody <- Nobody (Campaign/Crossroads) | " ..
    "Notes/Aside <- an aside (Campaign/Crossroads)")
  local n = lastNotification()
  has(n.message, " The player edition names 4 pages it doesn't contain: World/Secrets/Plot (“the Warden's plan”), " ..
    "World/Maps/The Old Orchard (“the orchard”), World/People/Nobody (“Nobody”) and 1 more. That may be meant.")
  -- what the edition prints of them is still the label alone
  has(H.pages["Build/Book Player"], "Signs point to the Warden's plan, to the orchard,")
end)

test("book: a link in a section printed in place names the page it did where it was written", "adventure", function()
  H.pages["Notes/Town/Rumour"] = "# Rumour\n\n## Heard\n\nAsk about [the lantern](<../../World/Items/Lantern>), " ..
    "or listen to [the gossip](<../Gossip>).\n"
  H.pages["Notes/Gossip"] = "# Gossip\n\nIdle talk.\n"
  H.pages["Campaign/Tavern"] = "---\nbook_order: 14\n---\n\n# Tavern\n\n![[Notes/Town/Rumour#Heard]]\n"
  local report = build()
  eq(named(report), "Notes/Gossip <- the gossip (Campaign/Tavern)",
    "read from Notes/Town, not from the Campaign page it is printed in")
  has(H.pages["Build/Book Player"], "Ask about the lantern, or listen to the gossip.")
end)

test("book: from the DM space the links name the adventure's pages", "dm", function()
  H.pages["Adventure/Campaign/Clearing"] = "---\nbook_order: 14\n---\n\n# Clearing\n\n" ..
    "The fight is on [the map](<../World/Maps/The Old Orchard>), by the [Lantern](<../World/Items/Lantern>).\n"
  H.current = "index"
  local report = gmbook.build({ "dm", "player" })
  eq(named(report), "World/Maps/The Old Orchard <- the map (Campaign/Clearing)")
  local n = lastNotification()
  eq(n.kind, "info", "it may be meant, so it is said, not warned of")
  has(n.message, " The player edition names a page it doesn't contain: World/Maps/The Old Orchard (“the map”). " ..
    "That may be meant.")
end)

test("book: a player edition kept back names no links", "adventure", function()
  H.pages["Campaign/Stray"] = "---\nbook_order: 70\n---\n\n# Stray\n\n[[World/People/Nobody]]. <!--/dm-->\n"
  local report = build()
  eq(#report.kept, 1)
  eq(#report.missingLinks, 0, "nothing was written to name them in")
end)
