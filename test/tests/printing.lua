------------------------------------------------------------------ Printing

test("book: prints text, numbers and Markdown faces, and leaves the rest", "adventure", function()
  local src = table.concat({
    "---", "book_order: 99", "---", "",
    "# Printing", "",
    "The lantern holds ${party.count{\"wick\", plus = 1}}: enough.",
    "A boat for ${party.n()}. ${party.N()} oars. Sum ${1 + 2}, text ${\"hi\"}.",
    "",
    "${party.each(5, \"find\")}",
    "",
    "Code `${party.n()}` stays, and so does",
    "",
    "```",
    "${party.n()}",
    "```",
    "",
    "and ${ {a = 1} } has nothing to print.",
  }, "\n")
  local out, left = gmbook.print(src)
  has(out, "The lantern holds one more wick than the party has members, six for a party of five: enough.")
  has(out, "A boat for five. Five oars. Sum 3, text hi.\n\nCode `${party.n()}` stays")
  has(out, "```\n${party.n()}\n```")
  has(out, "and ${ {a = 1} } has nothing to print.")
  eq(#left, 1)
  eq(left[1], " {a = 1} ")
  eq(gmbook.print("No expressions here."), "No expressions here.")
end)

test("book: Act I prints the adventure's numbers, not code", "adventure", function()
  -- Act I's scenes hold a number opening a sentence, a count, a hint and a
  -- fight. A fourth scene puts numbers in the other places a scene has them:
  -- a heading, a table cell and bold text.
  H.pages["Campaign/Act I/Scene 4"] = table.concat({
    "---", "book_order: 14", "type: scene", "---", "",
    "# Scene 4 — The Crossing", "",
    "## The boat — ${party.n()} places, one each", "",
    "| Where | What |", "|---|---|",
    "| **The bank** | A boat for ${party.n()}. ${party.N()} oars, ${party.n()} benches. |", "",
    "**${party.N()} travellers in one boat is a crowd, and the river knows it.**", "",
  }, "\n")
  gmbook.compile({ "dm", "player" })
  local dm, player = H.pages["Build/Book DM"], H.pages["Build/Book Player"]
  hasnt(dm, "${")
  hasnt(player, "${")
  has(dm, "Five travellers reach the ford at dusk.")
  has(dm, "The lantern holds one more wick than the party has members, six for a party of five: " ..
    "enough for one to burn tonight and one for every traveller after.")
  has(dm, "**The old orchard.** A strangler and six creepers: " ..
    "a low-difficulty encounter for five level 1 characters (250 XP).")
  has(dm, "## The boat — five places, one each")
  has(dm, "| **The bank** | A boat for five. Five oars, five benches. |")
  has(dm, "**Five travellers in one boat is a crowd, and the river knows it.**")
  -- the hint under Scene 1's clues prints nothing, and its line goes
  has(dm, "A crow watches from each post.\n\nThree clues wait on the bank")
  hasnt(dm, "here: use the first")
  hasnt(dm, "one clue each")
  hasnt(dm, "shared by two")
end)

local builtForFive
test("book: a build is the same whatever the live party", "adventure", function()
  gmbook.compile({ "dm", "player" })
  builtForFive = { dm = H.pages["Build/Book DM"], player = H.pages["Build/Book Player"] }
end)
test("book: (a party of six, two away, in DM)", "dm", function()
  useParty(6, 4, 2)
  gmbook.compile({ "dm", "player" })
  eq(H.pages["Adventure/Build/Book DM"], builtForFive.dm, "the DM edition changed with the party")
  eq(H.pages["Adventure/Build/Book Player"], builtForFive.player, "the player edition changed with the party")
end)

test("kit: publishing puts in Markdown faces and leaves other expressions live", "dm", function()
  H.pages["Adventure/World/Things/Wick Tin"] = "# Wick Tin\n\nIt holds ${party.count{\"wick\", plus = 1}}. " ..
    "Found by ${party.n()} of them. Listed: ${query[[from p = index.pages()]]}. Sum ${1 + 2}.\n\n" ..
    "${party.each(5, \"find\")}\n\n## DM Only\n\n${party.n(1)}\n"
  gm.writeRevealed({ "Adventure/World/Things/Wick Tin" })
  H.confirms = { true }
  gm.publish()
  local copy = H.pages["Player/World/Things/Wick Tin"]
  has(copy, "It holds six wicks. Found by five of them.", "players get their own party's numbers")
  has(copy, "Listed: ${query[[from p = index.pages()]]}.", "a query stays live for the Player space")
  has(copy, "Sum ${1 + 2}.", "plain values stay live too")
  hasnt(copy, "DM Only")
  hasnt(copy, "here:", "a hint stays out of players' copies")
end)
