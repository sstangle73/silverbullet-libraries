------------------------------------------------------------------ GM Party

-- Transcribed by script from the SRD 5.2.1 text: XP Budget per Character (p. 202)
-- and Experience Points by Challenge Rating (pp. 255-256).
local SRD_BUDGET = {
  "1 50 75 100",
  "2 100 150 200",
  "3 150 225 400",
  "4 250 375 500",
  "5 500 750 1,100",
  "6 600 1,000 1,400",
  "7 750 1,300 1,700",
  "8 1,000 1,700 2,100",
  "9 1,300 2,000 2,600",
  "10 1,600 2,300 3,100",
  "11 1,900 2,900 4,100",
  "12 2,200 3,700 4,700",
  "13 2,600 4,200 5,400",
  "14 2,900 4,900 6,200",
  "15 3,300 5,400 7,800",
  "16 3,800 6,100 9,800",
  "17 4,500 7,200 11,700",
  "18 5,000 8,700 14,200",
  "19 5,500 10,700 17,200",
  "20 6,400 13,200 22,000",
}
local SRD_XP = {
  { "0", "0 or 10" },
  { "1/8", "25" },
  { "1/4", "50" },
  { "1/2", "100" },
  { "1", "200" },
  { "2", "450" },
  { "3", "700" },
  { "4", "1,100" },
  { "5", "1,800" },
  { "6", "2,300" },
  { "7", "2,900" },
  { "8", "3,900" },
  { "9", "5,000" },
  { "10", "5,900" },
  { "11", "7,200" },
  { "12", "8,400" },
  { "13", "10,000" },
  { "14", "11,500" },
  { "15", "13,000" },
  { "16", "15,000" },
  { "17", "18,000" },
  { "18", "20,000" },
  { "19", "22,000" },
  { "20", "25,000" },
  { "21", "33,000" },
  { "22", "41,000" },
  { "23", "50,000" },
  { "24", "62,000" },
  { "25", "75,000" },
  { "26", "90,000" },
  { "27", "105,000" },
  { "28", "120,000" },
  { "29", "135,000" },
  { "30", "155,000" },
}

local function unescape(s)
  return (s:gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&quot;", '"'):gsub("&amp;", "&"))
end

-- A party widget's HTML is text, so identical expressions on a page don't
-- fight over one element: its visible text, less the note a number shows
-- only while it has focus, and one of its attributes.
local function live(w)
  assert(type(w.html) == "string", "a GM Party widget's html should be text")
  local shown = (w.html:gsub('<span[^>]- class="gmparty%-tip"[^>]*>.-</span>', ""))
  return unescape((shown:gsub("<[^>]*>", "")))
end
-- The note a number shows while it has focus, as text.
local function tip(w)
  return unescape(w.html:match('<span[^>]- class="gmparty%-tip"[^>]*>(.-)</span>') or "")
end
local function attr(w, name)
  return unescape(w.html:match(" " .. name .. '="([^"]*)"') or "")
end

local BARROW = { "The barrow", level = 3, difficulty = "moderate",
  { 1, "wight", cr = 3 },
  { 1, "warhorse skeleton", cr = "1/2" },
  { 6, "skeleton", cr = "1/4", step = 4 },
}

test("party: loads in Adventure and in DM", "adventure", function()
  ok(party and party.get and party.fight, "no GM Party in the Adventure space")
end)

test("party: Adventure on its own reads the adventure's party", "adventure", function()
  local p = party.get()
  eq(p.source, "book")
  eq(p.size, 5)
  eq(#p.here, 5)
  eq(p.members[1].level, nil)
end)

test("party: DM reads The Party until there are character pages", "dm", function()
  local p = party.get()
  eq(p.source, "party")
  eq(p.page, "The Party")
  eq(p.size, 5)
  eq(p.members[5].level, 1)
end)

test("party: a party page's count is characters, since SilverBullet keeps size for bytes", "dm", function()
  H.pages["The Party"] = "---\ntype: party\nsize: 6\nlevel: 2\n---\n\n# The Party\n"
  party.refresh()
  local p = party.get()
  eq(p.source, "book", "a frontmatter size is the page's byte count, so it must not be read")
  eq(p.size, 5)
  H.pages["The Party"] = "---\ntype: party\ncharacters: 6\nlevel: 2\n---\n\n# The Party\n"
  party.refresh()
  p = party.get()
  eq(p.source, "party")
  eq(p.size, 6)
  eq(p.members[6].level, 2)
end)

test("party: a party outside three to seven gets one row of its own", "dm", function()
  local function sizes(n)
    useParty(n, 3)
    local out = {}
    for row in party.fight(BARROW).html:gmatch("<tr[^>]*>(.-)</tr>") do
      local first = row:match("^<td[^>]*>(.-)</td>")
      if first then out[#out + 1] = (first:gsub("▶ ", "")) end
    end
    return table.concat(out, " ")
  end
  eq(sizes(5), "3 4 5 6 7")
  eq(sizes(2), "2 3 4 5 6 7")
  eq(sizes(9), "3 4 5 6 7 9")
  eq(sizes(40), "3 4 5 6 7 40")
end)

test("party: widgets hand SilverBullet HTML text, which it parses afresh for each copy", "dm", function()
  -- SilverBullet caches one result per expression and page, so two ${party.N()}
  -- on a page share it; an element would end up in only one of them.
  for _, w in ipairs({ party.n(), party.N(), party.count { "wick" }, party.each(5, "find"), party.fight(BARROW) }) do
    eq(type(w.html), "string")
  end
  has(party.n().html, '<span class="gmparty-n" tabindex="0" title="The party')
end)

-- A phone has no hover and never shows a tooltip, so a number's note was
-- out of reach there: the title was the only place it lived.
test("party: a number's note shows on a tap or from the keyboard, not only on hover", "dm", function()
  useParty(6, 9)
  for _, w in ipairs({ party.n(), party.N(1), party.count { "wick", plus = 1 }, party.dc(15), party.each(5, "find") }) do
    has(w.html, ' tabindex="0"', "the number takes focus, from a tap or the keyboard")
    ok(tip(w) ~= "", "a box for the note: " .. w.html)
    eq(tip(w), attr(w, "title"), "the same note as the tooltip a mouse shows")
    has(w.html, '<span aria-hidden="true" class="gmparty-tip">', "a screen reader has the tooltip, not the box as well")
  end
  eq(tip(party.n()), "The party's size: six for this party of six, counted from the character pages. Prints as “five”.")
  eq(live(party.n()), "six", "the box isn't part of the number")
  eq(party.n().markdown, "six", "nor of what tables, Copy and the players' copies get")
  local style = SRC["GM Party"]:match("```space%-style\n(.-)\n```")
  local box = style:match("\n%.gmparty%-tip%s*(%b{})")
  ok(box, "a rule for the note's box")
  has(box, "display: none;", "hidden until the number has focus")
  has(box, "position: absolute;", "over the text, not pushing it aside")
  has(box, "max-width: min(24em, calc(100vw - 32px));", "never wider than the screen")
  local shown = style:match("%.gmparty%-n:focus > %.gmparty%-tip,%s*%.gmparty%-each:focus > %.gmparty%-tip%s*(%b{})")
  ok(shown, "the box shows while the number has focus")
  has(shown, "display: block;")
  local touch = style:match("@media %(hover: none%)%s*(%b{})")
  ok(touch and touch:find(".gmparty-n:hover > .gmparty-tip", 1, true), "and on a tap's hover, where a tap gives no focus")
  -- at 375px the box sits across the foot of the screen inside a 16px margin
  local phone = style:match("@media screen and %(max%-width: 600px%)%s*(%b{})")
  ok(phone, "a rule for a phone")
  local fixed = phone:match("%.gmparty%-tip%s*(%b{})")
  ok(fixed, "for the note's box")
  for _, want in ipairs({ "position: fixed;", "left: 16px;", "right: 16px;", "bottom: 16px;", "max-width: none;" }) do
    has(fixed, want)
  end
  has(style:match("\n%.gmparty%-n:focus%-visible,%s*%.gmparty%-each:focus%-visible%s*(%b{})") or "", "outline:",
    "the keyboard's focus is seen")
end)

test("party: character pages count, at their levels, with who is away", "dm", function()
  H.pages["Party/Ann"] = pcPage(3)
  H.pages["Party/Ben"] = pcPage(nil)
  H.pages["Party/Cal"] = pcPage(2, "away: true\n")
  party.refresh()
  local p = party.get()
  eq(p.source, "characters")
  eq(p.size, 3)
  eq(#p.here, 2)
  eq(p.members[1].name, "Ann")
  eq(p.members[1].level, 3)
  eq(p.members[2].level, 1, "a character with no level takes The Party's")
  eq(p.members[3].away, true)
end)

-- fn run with os.time, which GM Party reads to keep the party two seconds,
-- giving what the clock says: the test sets clock.now, and the wall clock
-- never decides what it sees. The real one is put back however fn ends.
local function withClock(fn)
  local real = os.time
  local clock = { now = 1000000 }
  os.time = function() return clock.now end
  local good, err = pcall(fn, clock)
  os.time = real
  if not good then error(err, 0) end
end

test("party: the party is read again after a refresh, not before", "dm", function()
  withClock(function(clock)
    party.refresh()
    eq(party.get().size, 5)
    H.pages["Party/Ann"] = pcPage(3)
    clock.now = clock.now + 1
    eq(party.get().size, 5, "kept for two seconds")
    party.refresh()
    eq(party.get().size, 1, "read again after a refresh")
    H.pages["Party/Ben"] = pcPage(3)
    clock.now = clock.now + 1
    eq(party.get().size, 1, "and kept again")
    clock.now = clock.now + 1
    eq(party.get().size, 2, "until two seconds have passed")
  end)
end)

test("party: settings change the adventure's party", "adventure", function()
  config.set("gmParty", { book = 4 })
  party.refresh()
  eq(party.get().size, 4)
  eq(party.n().markdown, "four")
  eq(party.printed.n(), "four")
end)

test("party: words, digits and plurals", "adventure", function()
  eq(party.word(5), "five")
  eq(party.word(20), "twenty")
  eq(party.word(21), "21")
  eq(party.word(0), "no")
  eq(party.digits(50), "50")
  eq(party.digits(1100), "1,100")
  eq(party.digits(155000), "155,000")
  eq(party.digits(1234567), "1,234,567")
  eq(party.plural("wick"), "wicks")
  eq(party.plural("torch"), "torches")
  eq(party.plural("box"), "boxes")
  eq(party.plural("harpy"), "harpies")
  eq(party.plural("key"), "keys")
end)

test("party: story numbers show this party's and print the adventure's", "dm", function()
  useParty(6, 3)
  local w = party.n()
  eq(live(w), "six")
  eq(w.markdown, "six", "the Markdown face is this party's too, for tables and Copy")
  eq(party.printed.n(), "five")
  eq(w.display, "inline")
  eq(attr(w, "class"), "gmparty-n")
  has(attr(w, "title"), "The party's size: six for this party of six, counted from the character pages. Prints as “five”.")
  w = party.N()
  eq(live(w), "Six")
  eq(party.printed.N(), "Five")
  w = party.n(1)
  eq(live(w), "seven")
  eq(w.markdown, "seven")
  eq(party.printed.n(1), "six")
  has(attr(w, "title"), "One more than the party has members")
  w = party.n(-1)
  eq(live(w), "five")
  eq(party.printed.n(-1), "four")
  w = party.n { times = 2 }
  eq(live(w), "twelve")
  eq(party.printed.n { times = 2 }, "ten")
  has(attr(w, "title"), "Twice the party's size")
end)

test("party: a count shows this party's and prints its rule", "dm", function()
  useParty(6, 1)
  local w = party.count { "wick", plus = 1 }
  eq(live(w), "seven wicks")
  eq(w.markdown, "seven wicks")
  eq(party.printed.count { "wick", plus = 1 }, "one more wick than the party has members, six for a party of five")
  has(attr(w, "title"), "One more wick than the party has members: seven wicks for this party of six")
  local cases = {
    { { "wick" }, "six wicks", "as many wicks as the party has members, five for a party of five" },
    { { "wick", plus = -1 }, "five wicks", "one fewer wick than the party has members, four for a party of five" },
    { { "wick", plus = 2 }, "eight wicks", "two more wicks than the party has members, seven for a party of five" },
    { { "wick", per = 2 }, "twelve wicks", "two wicks for each member of the party, ten for a party of five" },
    { { "wick", per = 2, plus = 1 }, "thirteen wicks",
      "two wicks for each member of the party, and one more, eleven for a party of five" },
    { { "wick", per = 1 / 2 }, "three wicks",
      "one wick for every two members of the party, rounding up, three for a party of five" },
    { { "wick", per = 1 / 2, round = "down" }, "three wicks",
      "one wick for every two members of the party, rounding down, two for a party of five" },
    { { "wick", min = 8 }, "eight wicks",
      "as many wicks as the party has members, but no fewer than eight, eight for a party of five" },
    { { "wolf", "wolves" }, "six wolves", "as many wolves as the party has members, five for a party of five" },
    { { "wick", plus = 1, example = false }, "seven wicks", "one more wick than the party has members" },
    { { "wick", plus = 1, cap = true }, "Seven wicks", "One more wick than the party has members, six for a party of five" },
    { { "wick", plus = -6 }, "no wicks", "six fewer wicks than the party has members, none for a party of five" },
  }
  for _, c in ipairs(cases) do
    local w2 = party.count(c[1])
    eq(live(w2), c[2])
    eq(w2.markdown, c[2])
    eq(party.printed.count(c[1]), c[3])
  end
end)

test("party: one each says which to use for who is here, and prints nothing", "dm", function()
  local function hint(n, away)
    useParty(n, 1, away)
    local w = party.each(5, "find")
    eq(w.markdown, "", "a hint has no Markdown face, so it stays on the page")
    eq(party.printed.each(5, "find"), "", "a hint prints nothing")
    eq(attr(w, "class"), "gmparty-each")
    return live(w)
  end
  eq(hint(3), "Three here: use the first three finds.")
  eq(hint(5), "Five here: one find each.")
  eq(hint(6), "Six here: all five finds, with one find shared by two.")
  eq(hint(7), "Seven here: all five finds, with two finds shared by two.")
  eq(hint(6, 2), "Four here: use the first four finds.")
  eq(hint(1), "One here: use the first find.")
  eq(live(party.each { 5, "find" }), "One here: use the first find.")
  eq(hint(2, 2), "Nobody here tonight.")
end)

test("party: the budget and XP tables match the SRD 5.2.1", "adventure", function()
  eq(#party.srd.budget, #SRD_BUDGET)
  for level, line in ipairs(SRD_BUDGET) do
    local row = party.srd.budget[level]
    eq(level .. " " .. party.digits(row[1]) .. " " .. party.digits(row[2]) .. " " .. party.digits(row[3]),
       line, "XP budget, level " .. level)
  end
  eq(#party.srd.crs, #SRD_XP)
  for i, pair in ipairs(SRD_XP) do
    eq(party.srd.crs[i], pair[1])
    if pair[1] == "0" then
      eq(pair[2], "0 or 10")
      eq(party.xp("0"), 10)
    else
      eq(party.digits(party.xp(pair[1])), pair[2], "XP for CR " .. pair[1])
    end
  end
  eq(party.xp(0.25), 50)
  eq(party.xp(3), 700)
  eq(party.xp("1 / 2"), 100)
  eq(party.xp(31), nil)
  eq(party.xp(2.5), nil)
end)

test("party: the SRD's three worked examples come out as the SRD says", "adventure", function()
  -- Example 1: low for four level 1 characters is 200 XP.
  local four1 = { 1, 1, 1, 1 }
  eq(party.budget(four1, "low"), 200)
  eq(party.rate(party.xp(1), four1), "low")             -- a bugbear warrior
  eq(party.rate(2 * party.xp("1/2"), four1), "low")     -- two giant wasps
  eq(party.rate(6 * party.xp("1/8"), four1), "low")     -- six giant rats
  -- Example 2: moderate for five level 3 characters is 1,125 XP.
  local five3 = { 3, 3, 3, 3, 3 }
  eq(party.budget(five3, "moderate"), 1125)
  eq(2 * party.xp(2) + 9 * party.xp("1/8"), 1125)       -- two druids, nine stirges
  eq(party.rate(1125, five3), "moderate")
  local xp = 0
  for _, r in ipairs(party.roster(BARROW, 5)) do xp = xp + r.count * r.creature.xp end
  eq(xp, 1100, "a wight, a warhorse skeleton and six skeletons")
  eq(party.rate(xp, five3), "moderate")
  -- Example 3: high for six level 15 characters is 46,800 XP.
  local six15 = { 15, 15, 15, 15, 15, 15 }
  eq(party.budget(six15, "high"), 46800)
  eq(2 * party.xp(17) + 2 * party.xp(9), 46000)         -- two adult red dragons, two fire giants
  eq(party.rate(46000, six15), "high")
  eq(party.rate(46801, six15), "above")
  -- Mixed levels: each character's budget at its own level.
  eq(party.budget({ 2, 3 }, "moderate"), 150 + 225)
end)

test("party: a fight prints for the adventure's party, then how to adjust it", "adventure", function()
  eq(party.fightPrint(BARROW), table.concat({
    "**The barrow.** A wight, a warhorse skeleton and six skeletons: a moderate-difficulty encounter for five level 3 characters (1,100 XP).",
    "",
    "**Adjusting the Encounter.** For each character fewer than five, remove four skeletons; for each one more, add four.",
    "",
    "| Characters | Skeletons | XP | Difficulty |",
    "|---|---|---|---|",
    "| 3 | 0 | 800 | High |",
    "| 4 | 2 | 900 | Moderate |",
    "| 5 | 6 | 1,100 | Moderate |",
    "| 6 | 10 | 1,300 | Moderate |",
    "| 7 | 14 | 1,500 | Moderate |",
  }, "\n"))
  local w = party.fight(BARROW)
  eq(w.markdown, party.fightPrint(BARROW))
  eq(party.printed.fight(BARROW), party.fightPrint(BARROW))
  eq(w.display, "block")
  local plain = { level = 1, table = false, { 1, "bugbear warrior", cr = 1 } }
  eq(party.fightPrint(plain), table.concat({
    "**Creatures.** A bugbear warrior: a low-difficulty encounter for five level 1 characters (200 XP).",
    "",
    "**Adjusting the Encounter.** The fight stays the same whatever the party's size.",
  }, "\n"))
end)

test("party: a fight on the page is for who is here, at their levels", "dm", function()
  useParty(4, 2)
  local t = live(party.fight(BARROW))
  has(t, "The barrow")
  has(t, "a moderate fight for five level 3 characters, as written")
  has(t, "Four here at level 2: a wight, a warhorse skeleton and two skeletons, 900 XP.")
  has(t, "●●●+ Above High")
  has(t, "Low 400 · Moderate 600 · High 800 XP")
  has(t, "The wight's CR 3 is above the party's level")
  has(t, "Meant to be Moderate, but for this party it is Above High.")
  has(t, "▶ 4")
  -- the characters' own levels, mixed
  H.pages["Party/PC 01"] = pcPage(3)
  H.pages["Party/PC 02"] = pcPage(3)
  party.refresh()
  t = live(party.fight(BARROW))
  has(t, "Four here at levels 2–3: a wight, a warhorse skeleton and two skeletons, 900 XP.")
  has(t, "Low 500 · Moderate 750 · High 1,200 XP")
  has(t, "●●● High")
end)

-- A fight's table of sizes on the page, a row at a time: the size, with
-- the ▶ on the party's own, and the difficulty's word.
local function sizeTable(w)
  local out = {}
  for row in w.html:gmatch("<tr[^>]*>(.-)</tr>") do
    local first = row:match("^<td[^>]*>(.-)</td>")
    if first then
      out[#out + 1] = first .. " " .. (row:match('gmparty%-diff%-%a+">[^<]- ([%a ]+)</span>') or "?")
    end
  end
  return table.concat(out, " | ")
end

-- Characters at these levels, one page each, all here tonight.
local function levelsParty(levels)
  useParty(0)
  for i, l in ipairs(levels) do H.pages[string.format("Party/PC %02d", i)] = pcPage(l) end
  party.refresh()
end

test("party: at mixed levels the table of sizes agrees with the fight", "dm", function()
  -- levels 3, 3, 2 and 2: 900 XP is High against their own budgets, so the
  -- ▶ row, which is their fight, says High too, and the other sizes spend
  -- what they spend each, on average (125, 187.5 and 300 XP)
  levelsParty({ 3, 3, 2, 2 })
  local w = party.fight(BARROW)
  has(live(w), "●●● High  Low 500")
  eq(sizeTable(w), "3 High | ▶ 4 High | 5 High | 6 High | 7 High")
  -- at one level the table is rated at that level, as it always was
  useParty(4, 2)
  eq(sizeTable(party.fight(BARROW)), "3 Above High | ▶ 4 Above High | 5 Above High | 6 Above High | 7 Above High")
  useParty(5, 3)
  eq(sizeTable(party.fight(BARROW)), "3 High | 4 Moderate | ▶ 5 Moderate | 6 Moderate | 7 Moderate")
end)

test("party: a CR is held to the party's level, not its highest", "dm", function()
  local ford = { "The ford", level = 2, { 1, "wight", cr = 3 }, { 2, "zombie", cr = "1/4" } }
  -- levels 1, 1, 1 and 5 are a level 2 party: a CR 3 wight can take one out
  levelsParty({ 1, 1, 1, 5 })
  has(live(party.fight(ford)), "The wight's CR 3 is above the party's level")
  eq(party.level(), 2)
  -- levels 2 and 3 round to 3, and a CR 3 wight is at it, not above it
  levelsParty({ 2, 3 })
  hasnt(live(party.fight(ford)), "CR 3 is above")
  eq(list(party.warnings(ford, party.roster(ford, 4), { 5, 1, 1, 1 }, "high")),
    "The wight's CR 3 is above the party's level: one of its actions can take a character out.")
end)

test("party: a fight in Adventure on its own shows the adventure's party", "adventure", function()
  local t = live(party.fight(BARROW))
  has(t, "The adventure's party, five at level 3: a wight, a warhorse skeleton and six skeletons, 1,100 XP.")
  has(t, "●●○ Moderate")
  hasnt(t, "Meant to be")
end)

test("party: the SRD's cautions show on the page", "dm", function()
  useParty(2, 1)
  local t = live(party.fight { level = 1,
    { 1, "ogre", cr = 2 }, { 3, "goblin", cr = "1/4" }, { 1, "wolf", plural = "wolves", cr = "1/4" },
    { 1, "bandit", cr = "1/8" } })
  has(t, "The ogre's CR 2 is above the party's level")
  has(t, "More than two creatures per character")
  has(t, "Four stat blocks to run at once.")
  t = live(party.fight { level = 1, { 1, "bugbear warrior", cr = 1 } })
  has(t, "A lone creature")
end)

-- Measured at 375px in SilverBullet 2.11's widget frame, whose table cells
-- never wrap: a fight with four creatures whose number changes draws a table
-- 500 to 760px wide, depending on the font, whose XP and Difficulty columns
-- ran past the fight's box. It scrolls in a frame of its own inside the box.
test("party: a fight's table scrolls in its own frame, never past the fight's box", "dm", function()
  local w = party.fight { "The gatehouse", level = 5,
    { 1, "guard sergeant", cr = 2 }, { 4, "guard", cr = "1/2", step = 2, min = 2 },
    { 2, "hound", cr = "1/4", step = 1, max = 4 }, { 1, "guard lieutenant", cr = 3, from = 6 },
    { 1, "wolf", plural = "wolves", cr = "1/4", upto = 4 } }
  has(w.html, '<div class="gmparty-table"><table><thead><tr><th>Characters</th><th>Guards</th>')
  local style = SRC["GM Party"]:match("```space%-style\n(.-)\n```")
  local frame = style:match("\n%.gmparty%-table%s*(%b{})")
  ok(frame, "a rule for the table's frame")
  has(frame, "overflow-x: auto;")
end)

test("party: fight rules read as sentences", "adventure", function()
  local spec = { level = 5, note = "With three characters, the sergeant fights alone.",
    { 1, "guard sergeant", cr = 2 },
    { 4, "guard", cr = "1/2", step = 2, min = 2 },
    { 2, "hound", cr = "1/4", step = 1, max = 4 },
    { 1, "guard lieutenant", cr = 3, from = 6 },
    { 1, "wolf", plural = "wolves", cr = "1/4", upto = 4 },
  }
  eq(party.adjustments(spec), "For each character fewer than five, remove two guards and a hound; " ..
    "for each one more, add two guards and a hound. Keep at least two guards. " ..
    "Use no more than four hounds. With six or more characters, add a guard lieutenant. " ..
    "With four or fewer characters, add a wolf. With three characters, the sergeant fights alone.")
  local function counts(n)
    local out = {}
    for _, r in ipairs(party.roster(spec, n)) do out[#out + 1] = r.count end
    return table.concat(out, " ")
  end
  eq(counts(3), "1 2 0 0 1")
  eq(counts(4), "1 2 1 0 1")
  eq(counts(5), "1 4 2 0 0")
  eq(counts(6), "1 6 3 1 0")
  eq(counts(7), "1 8 4 1 0")
  has(party.fightPrint(spec), "| Characters | Guards | Hounds | Guard lieutenants | Wolves | XP | Difficulty |")
  eq(party.adjustments { level = 5, { 1, "shade", cr = 1, step = -1 } },
    "For each character fewer than five, add a shade; for each one more, remove one.")
end)

test("party: a fight written for a size outside the table prints that size's row", "adventure", function()
  local big = { "The mill race", level = 3, size = 8, { 8, "skeleton", cr = "1/4", step = 1 } }
  local printed = party.fightPrint(big)
  has(printed, "a low-difficulty encounter for eight level 3 characters (400 XP).")
  has(printed, "| 7 | 7 | 350 | Low |")
  has(printed, "| 8 | 8 | 400 | Low |", "the size it is written for")
  local small = { "The mill race", level = 3, size = 2, { 2, "skeleton", cr = "1/4", step = 1 } }
  local rows = {}
  for size in party.fightPrint(small):gmatch("\n| (%d+) |") do rows[#rows + 1] = size end
  eq(table.concat(rows, " "), "2 3 4 5 6 7")
end)

test("party: fight mistakes say what to write", "adventure", function()
  local good, err = pcall(party.fight, { { 1, "wight", cr = 3 } })
  ok(not good)
  has(err, "give the level the fight is written for")
  good, err = pcall(party.fight, { level = 3, { 1, "thing", cr = 99 } })
  ok(not good)
  has(err, "no XP for thing")
  good, err = pcall(party.fight, { level = 3, difficulty = "deadly", { 1, "wight", cr = 3 } })
  ok(not good)
  has(err, "low, moderate or high")
  good, err = pcall(party.fight, { level = 3, { "wight", 1 } })
  ok(not good)
  has(err, "each creature is {count, name, cr = ...}")
  good, err = pcall(party.count, { plus = 1 })
  ok(not good)
  has(err, "party.count takes")
  good, err = pcall(party.each, "find")
  ok(not good)
  has(err, "party.each takes")
end)

test("party: the summary on The Party", "dm", function()
  ok(H.pages["The Party"]:find("${party.summary()}", 1, true), "The Party shows no summary")
  local md = party.summary().markdown
  has(md, "**Five characters, level 1,** from `characters` and `level` on [[The Party]], until there are character pages.")
  has(md, "A fight for them can spend 250 XP at Low, 375 at Moderate, or 500 at High.")
  H.pages["Party/Ann"] = pcPage(3)
  H.pages["Party/Cal"] = pcPage(2, "away: true\n")
  party.refresh()
  md = party.summary().markdown
  has(md, "**Two characters:** [[Party/Ann|Ann]] (3), [[Party/Cal|Cal]] (2), away.")
  has(md, "One here tonight.")
  has(md, "A fight for them can spend 150 XP at Low, 225 at Moderate, or 400 at High.")
end)

test("party: the rules tables print for a rules page", "adventure", function()
  local budgets = party.budgets().markdown
  has(budgets, "| Level | Low | Moderate | High |\n|---|---|---|---|\n| 1 | 50 | 75 | 100 |")
  has(budgets, "| 20 | 6,400 | 13,200 | 22,000 |")
  local xp = party.xpTable().markdown
  has(xp, "| CR | XP | CR | XP |\n|---|---|---|---|\n| 0 | 0 or 10 | 14 | 11,500 |")
  has(xp, "| 13 | 10,000 | 30 | 155,000 |")
end)

------------------------------------------------------------------ retired

test("party: a retired character counts nowhere, where one away still counts in the story", "dm", function()
  H.pages["Party/Ann"] = pcPage(3)
  H.pages["Party/Ben"] = pcPage(9, "retired: true\n")
  H.pages["Party/Cal"] = pcPage(2, "away: true\n")
  party.refresh()
  local p = party.get()
  eq(p.source, "characters")
  eq(p.size, 2, "Ann, and Cal, who is away: not Ben")
  eq(#p.here, 1, "Ann")
  eq(list(names(p.members)), "Ann | Cal")
  eq(list(names(p.retired)), "Ben")
  -- the story numbers and counts: Cal is in them, Ben isn't
  eq(live(party.n()), "two")
  eq(live(party.count { "arrow", plus = 1 }), "three arrows")
  eq(party.value(1), 3)
  -- the hand-outs, the level, the DCs and the fights: Ann alone
  eq(live(party.each(3, "find")), "One here: use the first find.")
  eq(party.level(), 3, "Ben's level 9 is in no average")
  eq(live(party.dc(15)), "15")
  has(live(party.fight(BARROW)), "One here at level 3:")
  -- the summary names him, apart
  local md = party.summary().markdown
  has(md, "**Two characters:** [[Party/Ann|Ann]] (3), [[Party/Cal|Cal]] (2), away.")
  has(md, "Retired, and counted nowhere: [[Party/Ben|Ben]].")
  has(md, "A fight for them can spend 150 XP at Low, 225 at Moderate, or 400 at High.")
  hasnt(md, "At level", "no DC rise from Ben's level")
  -- print never knew the table's party
  eq(party.printed.n(), "five")
end)

test("party: with every character retired, the party page stands in again", "dm", function()
  H.pages["Party/Ann"] = pcPage(7, "retired: true\n")
  H.pages["Party/Ben"] = pcPage(8, "retired: true\n")
  party.refresh()
  local p = party.get()
  eq(p.source, "party", "as before there were character pages")
  eq(p.size, 5)
  eq(party.level(), 1, "The Party's level, not theirs")
  local md = party.summary().markdown
  has(md, "**Five characters, level 1,** from `characters` and `level` on [[The Party]]")
  has(md, "Retired, and counted nowhere: [[Party/Ann|Ann]], [[Party/Ben|Ben]].")
  -- only true retires a character, as only true sits one out
  H.pages["Party/Ann"] = pcPage(7, "retired: false\n")
  party.refresh()
  eq(party.get().size, 1)
  eq(list(names(party.get().retired)), "Ben")
end)

test("party: with no one retired the summary says nothing of it", "dm", function()
  useParty(4, 2)
  hasnt(party.summary().markdown, "Retired")
  eq(#party.get().retired, 0)
end)

------------------------------------------------------------------ a tab behind its space

local OWN = "Library/Storie/GM Party"

-- The library's page as the space holds it, at another version.
local function atVersion(page, version)
  H.pages[page] = (SRC["GM Party"]:gsub('\nversion: "[^"]*"\n', '\nversion: "' .. version .. '"\n', 1))
  party.refresh()
end

test("party: the version this tab runs is its page's", "adventure", function()
  local page = SRC["GM Party"]:match('^%-%-%-\n.-\nversion: "([^"]+)"\n.-%-%-%-\n')
  ok(page, "a version in GM Party's frontmatter")
  eq(party.version, page)
  eq(party.stale(), nil, "a space that holds the same says nothing")
  hasnt(party.fight(BARROW).html, "Reload this tab")
end)

test("party: a tab behind its space says so, and how to catch up", "adventure", function()
  atVersion(OWN, "1.5.0")
  eq(party.stale(), "This tab runs GM Party " .. party.version .. ", but the space has 1.5.0: " ..
    "reload it (System: Reload, Ctrl-Alt-R).")
  -- a fight says so over its box, on the page alone
  local w = party.fight(BARROW)
  ok(w.html:find('<div class="gmparty-stale">', 1, true) == 1, "first, over the fight: " .. w.html:sub(1, 80))
  has(live(w), "⟳ Reload this tab: it runs GM Party " .. party.version .. ", and the space has 1.5.0 " ..
    "(System: Reload, Ctrl-Alt-R).")
  eq(w.markdown, party.fightPrint(BARROW), "never in the Markdown face, which tables and the players' copies take")
  eq(party.printed.fight(BARROW), party.fightPrint(BARROW), "nor in print")
  hasnt(party.n().html, "Reload", "a number in a sentence stays as it is")
  -- an older copy is a different one as well: whichever way, the tab and the space disagree
  atVersion(OWN, "1.3.0")
  has(party.stale(), "but the space has 1.3.0:")
end)

test("party: every copy of the library in the space counts, at any depth, and nothing else", "dm", function()
  local installed = "Adventure/" .. OWN
  ok(H.pages[installed], "GM Party where install.json puts it")
  eq(party.stale(), nil)
  atVersion("Author/" .. OWN, "1.10.0")
  atVersion("Old/Spaces/Library/Storie/GM Party", "1.9.0")
  atVersion("Player/Library/Storie/GM Party", "1.10.0")
  has(party.stale(), "but the space has 1.9.0 and 1.10.0:", "each version once, lowest first")
  -- a page whose name only looks like it
  for _, name in ipairs({ "Author/" .. OWN, "Old/Spaces/Library/Storie/GM Party", "Player/" .. OWN }) do
    H.pages[name] = nil
  end
  atVersion("MyLibrary/Storie/GM Party", "9.0.0")
  atVersion(OWN .. " Notes", "9.0.0")
  atVersion("Library/Storie/GM Party/Old", "9.0.0")
  eq(party.stale(), nil, "only a page named for the library, after a slash or as the whole name")
  -- a copy that gives no version can't be held to this one
  H.pages[installed] = (SRC["GM Party"]:gsub('\nversion: "[^"]*"\n', "\n", 1))
  party.refresh()
  eq(party.stale(), nil)
end)

test("party: whether the tab is behind is read at most every two seconds", "adventure", function()
  withClock(function(clock)
    party.refresh()
    eq(party.stale(), nil)
    H.pages[OWN] = (SRC["GM Party"]:gsub('\nversion: "[^"]*"\n', '\nversion: "1.5.0"\n', 1))
    clock.now = clock.now + 1
    eq(party.stale(), nil, "kept for two seconds")
    clock.now = clock.now + 1
    has(party.stale(), "1.5.0", "then read again")
    H.pages[OWN] = SRC["GM Party"]
    party.refresh()
    eq(party.stale(), nil, "and at once after a refresh")
  end)
end)

test("party: a look at the index that fails says nothing, and the fight still draws", "adventure", function()
  local real = index.pages
  index.pages = function() error("index gone") end
  local good, err = pcall(function()
    party.refresh()
    eq(party.stale(), nil)
  end)
  index.pages = real
  if not good then error(err, 0) end
  party.refresh()
  hasnt(party.fight(BARROW).html, "Reload this tab")
end)
