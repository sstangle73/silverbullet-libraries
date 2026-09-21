------------------------------------------------------------------ DM-only text (GM Kit 3.1, GM Book 1.8)

local DM_SHARED = { "-- GM Kit and GM Book share the code from here to",
                    "-- end of the shared DM-only code" }

local function dmBetween(text, a, b)
  local s = assert(text:find(a, 1, true), "no [" .. a .. "]")
  local e = assert(text:find(b, s, true), "no [" .. b .. "]")
  return text:sub(s, e + #b - 1)
end

test("dm-only: GM Kit and GM Book share its code word for word", "dm", function()
  local kit = dmBetween(FIXTURES.dm["Library/Storie/GM Kit"], DM_SHARED[1], DM_SHARED[2])
  local book = dmBetween(FIXTURES.dm["Adventure/Library/Storie/GM Book"], DM_SHARED[1], DM_SHARED[2])
  ok(#kit > 2000, "the shared block is missing")
  eq(kit, book, "the shared DM-only code differs between GM Kit and GM Book")
end)

-- { what, page, the players' copy, the DM's edition }
local DM_CASES = {
  { "a callout between paragraphs",
    "a\n\n> **dm** Who hid it\n> The Warden did.\n\nb\n",
    "a\n\nb\n",
    "a\n\n**Who hid it.** The Warden did.\n\nb\n" },
  { "a callout written GitHub's way, in capitals",
    "a\n\n> [!DM] Title\n> Secret.\n\nb",
    "a\n\nb",
    "a\n\n**Title.** Secret.\n\nb" },
  { "a title that ends in its own punctuation",
    "> **dm** Say nothing yet!\n> They learn it in the orchard.\n",
    "",
    "**Say nothing yet!** They learn it in the orchard.\n" },
  { "a callout without a title",
    "a\n\n> **dm**\n> Just this.\n\nb\n",
    "a\n\nb\n",
    "a\n\nJust this.\n\nb\n" },
  { "a title over a table",
    "a\n\n> **dm** For the DM\n> | A | B |\n> |---|---|\n> | 1 | 2 |\n\nb\n",
    "a\n\nb\n",
    "a\n\n**For the DM.**\n\n| A | B |\n|---|---|\n| 1 | 2 |\n\nb\n" },
  { "a line straight after a callout carries on its paragraph",
    "> **dm** T\n> secret\nstill secret\n\npublic\n",
    "public\n",
    "**T.** secret\nstill secret\n\npublic\n" },
  { "a heading straight after a callout isn't part of it",
    "> **dm** T\n> secret\n## Next\npublic\n",
    "## Next\npublic\n",
    "**T.** secret\n\n## Next\npublic\n" },
  { "a quote that isn't a DM callout",
    "> **note** Why\n> Because.\n\n> Read aloud.\n",
    "> **note** Why\n> Because.\n\n> Read aloud.\n",
    "> **note** Why\n> Because.\n\n> Read aloud.\n" },
  { "the first callout line decides, as SilverBullet does",
    "> plain first\n> **dm** then this\n\nb\n",
    "b\n",
    "plain first\n**then this.**\n\nb\n" },
  { "a DM callout inside a note goes on its own",
    "> **note** Why\n> Public.\n>\n> > **dm** Secret\n> > More secret.\n>\n> Public again.\n",
    "> **note** Why\n> Public.\n>\n>\n> Public again.\n",
    "> **note** Why\n> Public.\n>\n> **Secret.** More secret.\n>\n> Public again.\n" },
  { "a DM callout in a list item",
    "- one\n  > **dm** T\n  > secret\n- two\n",
    "- one\n- two\n",
    "- one\n\n  **T.** secret\n\n- two\n" },
  { "a stretch",
    "a\n\n<!--#dm-->\n\nsecret\n\n<!--/dm-->\n\nb\n",
    "a\n\nb\n",
    "a\n\nsecret\n\nb\n" },
  { "stretch markers with spaces and capitals",
    "a\n\n<!-- #DM -->\nsecret\n<!-- /dm -->\n\nb",
    "a\n\nb",
    "a\n\nsecret\n\nb" },
  { "a stretch holds headings, boxes and tables",
    "a\n\n<!--#dm-->\n## Hidden\n> **warning** Careful\n> Really.\n\n| x |\n|---|\n<!--/dm-->\n\nb\n",
    "a\n\nb\n",
    "a\n\n## Hidden\n> **warning** Careful\n> Really.\n\n| x |\n|---|\n\nb\n" },
  { "stretches nest",
    "<!--#dm-->\none\n<!--#dm-->\ntwo\n<!--/dm-->\nthree\n<!--/dm-->\npublic\n",
    "public\n",
    "one\ntwo\nthree\npublic\n" },
  { "a stretch with no end runs to the end of the page",
    "a\n\n<!--#dm-->\nsecret\n\n## Later\nstill hidden\n",
    "a\n",
    "a\n\nsecret\n\n## Later\nstill hidden\n" },
  { "markers in a fence are code",
    "```\n<!--#dm-->\n```\n\npublic\n",
    "```\n<!--#dm-->\n```\n\npublic\n",
    "```\n<!--#dm-->\n```\n\npublic\n" },
  { "a callout in a fence is code",
    "~~~\n> **dm** sample\n~~~\npublic\n",
    "~~~\n> **dm** sample\n~~~\npublic\n",
    "~~~\n> **dm** sample\n~~~\npublic\n" },
  { "a fenced # line under DM Only doesn't end it",
    "a\n\n## DM Only\n\nsecret one\n\n```map\n# wall stone\nH hidden secret two\n```\n\nsecret three\n",
    "a\n",
    "a\n\n## DM Only\n\nsecret one\n\n```map\n# wall stone\nH hidden secret two\n```\n\nsecret three\n" },
  { "a fenced DM Only heading isn't one",
    "a\n\n```markdown\n## DM Only\nsample\n```\n\npublic\n",
    "a\n\n```markdown\n## DM Only\nsample\n```\n\npublic\n",
    "a\n\n```markdown\n## DM Only\nsample\n```\n\npublic\n" },
  { "a shorter fence doesn't close a longer one",
    "````\n```\n## DM Only\n```\n````\npublic\n",
    "````\n```\n## DM Only\n```\n````\npublic\n",
    "````\n```\n## DM Only\n```\n````\npublic\n" },
  { "DM Only still runs to the next # or ## heading",
    "# A\nopen\n## DM Only\nsecret\n### deeper\nstill secret\n## Next\nopen again",
    "# A\nopen\n## Next\nopen again",
    "# A\nopen\n## DM Only\nsecret\n### deeper\nstill secret\n## Next\nopen again" },
  { "a span",
    "The Warden is kind. <span class=\"dm\">The Warden hid the crown.</span> Everyone says so.\n",
    "The Warden is kind. Everyone says so.\n",
    "The Warden is kind. The Warden hid the crown. Everyone says so.\n" },
  { "spans at the start and the end of a line",
    "<span class=\"dm\">Secret.</span> Public. <span class='dm'>Secret.</span>\n",
    "Public.\n",
    "Secret. Public. Secret.\n" },
  { "a span that is a whole paragraph takes the paragraph",
    "a\n\n<span class=\"dm\">All of it.</span>\n\nb\n",
    "a\n\nb\n",
    "a\n\nAll of it.\n\nb\n" },
  { "spans nest, and other classes stay",
    "x <span class=\"dm\">a <span class=\"k\">b</span> c</span> y <span class=\"k\">z</span>\n",
    "x y <span class=\"k\">z</span>\n",
    "x a <span class=\"k\">b</span> c y <span class=\"k\">z</span>\n" },
  { "a span shown in inline code",
    "Write `<span class=\"dm\">` round it.\n",
    "Write `<span class=\"dm\">` round it.\n",
    "Write `<span class=\"dm\">` round it.\n" },
  { "a span over two lines of a paragraph",
    "one <span class=\"dm\">two\nthree</span> four\n\nfive\n",
    "one\nfour\n\nfive\n",
    "one two\nthree four\n\nfive\n" },
  { "a span left open runs to the end of its paragraph",
    "one <span class=\"dm\">two\nthree\n\nfour\n",
    "one\n\nfour\n",
    "one two\nthree\n\nfour\n" },
  { "a span in a table cell",
    "| a | <span class=\"dm\">b</span> |\n",
    "| a | |\n",
    "| a | b |\n" },
  { "a page with none of it",
    "---\ntype: x\n---\n\n# T\n\n> Read aloud.\n\n<!-- a note -->\n\ntext <span>x</span>\n",
    "---\ntype: x\n---\n\n# T\n\n> Read aloud.\n\n<!-- a note -->\n\ntext <span>x</span>\n",
    "---\ntype: x\n---\n\n# T\n\n> Read aloud.\n\n<!-- a note -->\n\ntext <span>x</span>\n" },
}

test("dm-only: each way of marking it, for the players and for the DM", "dm", function()
  for _, c in ipairs(DM_CASES) do
    eq(gm.stripSecrets(c[2]), c[3], "GM Kit, " .. c[1])
    eq(gmbook.stripSecrets(c[2]), c[3], "GM Book's player edition, " .. c[1])
    eq(gmbook.showSecrets(c[2]), c[4], "GM Book's DM edition, " .. c[1])
    eq(gmbook.stripSecrets(c[3]), c[3], "stripping twice, " .. c[1])
    eq(gmbook.showSecrets(c[4]), c[4], "showing twice, " .. c[1])
  end
end)

test("dm-only: every Adventure page strips the same in both libraries", "dm", function()
  local n = 0
  for name, text in pairs(FIXTURES.dm) do
    if name:startsWith("Adventure/") then
      eq(gm.stripSecrets(text), gmbook.stripSecrets(text), name)
      n = n + 1
    end
  end
  ok(n > 20, "only " .. n .. " Adventure pages")
end)

local DM_CRYPT = table.concat({
  "# Crypt", "",
  "The door is locked. <span class=\"dm\">The key is under the mat.</span> It is heavy.", "",
  "> **dm** Who waits below",
  "> The lich, asleep.", "",
  "Stone steps lead down.", "",
  "<!--#dm-->", "",
  "| Clue | Where |", "|---|---|", "| The torn letter | The cellar |", "",
  "<!--/dm-->", "",
  "## Getting in", "",
  "Force the door.", "",
  "## DM Only", "",
  "The third step is a pressure plate.", "",
}, "\n")

test("dm-only: publishing leaves every kind of it out of the players' copy", "dm", function()
  local page = "Adventure/World/Places/Crypt"
  H.pages[page] = "---\ntype: place\n---\n\n" .. DM_CRYPT
  gm.writeRevealed({ page })
  H.confirms = { true }
  gm.publish()
  eq(H.pages["Player/World/Places/Crypt"],
     "---\ntype: place\n---\n\n# Crypt\n\nThe door is locked. It is heavy.\n\n" ..
     "Stone steps lead down.\n\n## Getting in\n\nForce the door.\n")
end)

test("dm-only: a fence under DM Only keeps the rest of the section from the players", "dm", function()
  local page = "Adventure/World/Places/Crypt"
  H.pages[page] = table.concat({
    "# Crypt", "", "What the players see.", "",
    "## DM Only", "", "The trapdoor is under the straw.", "",
    "```map", "#####", "#,,H#", "#####", "",
    "# wall stone", ", floor straw", "H hidden trapdoor to the ossuary", "```", "",
    "The lich waits below.", "",
  }, "\n")
  gm.writeRevealed({ page })
  H.confirms = { true }
  gm.publish()
  local copy = H.pages["Player/World/Places/Crypt"]
  has(copy, "What the players see.")
  hasnt(copy, "trapdoor", "the map's hidden layer or the text before it")
  hasnt(copy, "The lich waits below.", "the text after the map")
end)

test("dm-only: the DM's edition prints it as ordinary text, and the player edition leaves it out", "adventure", function()
  H.pages["Campaign/Crypt"] = "---\nbook_order: 11\n---\n\n" .. DM_CRYPT
  gmbook.compile({ "dm", "player" })
  local dm, player = H.pages["Build/Book DM"], H.pages["Build/Book Player"]
  has(dm, "The door is locked. The key is under the mat. It is heavy.")
  has(dm, "**Who waits below.** The lich, asleep.")
  has(dm, "| The torn letter | The cellar |")
  has(dm, "The third step is a pressure plate.")
  has(player, "The door is locked. It is heavy.\n\nStone steps lead down.")
  for _, s in ipairs({ "key is under the mat", "The lich", "Who waits below", "torn letter", "pressure plate" }) do
    hasnt(player, s, "the player edition")
  end
  for _, s in ipairs({ "**dm**", "<!--#dm", "<!--/dm", "class=\"dm\"" }) do
    hasnt(dm, s, "the DM's edition")
    hasnt(player, s, "the player edition")
  end
end)

test("dm-only: a map in a DM callout prints in the DM's edition only", "adventure", function()
  gmbook.compile({ "dm", "player" })
  local dmBefore = count(H.pages["Build/Book DM"], "<svg")
  local playerBefore = count(H.pages["Build/Book Player"], "<svg")
  H.pages["Campaign/Clearing"] = table.concat({
    "---", "book_order: 11", "---", "", "# Clearing", "",
    "${maps.draw(\"World/Maps/The Old Orchard\")}", "",
    "> **dm** Where they start",
    "> The creatures, in place.",
    ">",
    "> ${maps.draw(\"World/Maps/The Old Orchard\", { dm = true })}", "",
    "The fight starts.", "",
  }, "\n")
  gmbook.compile({ "dm", "player" })
  local dm, player = H.pages["Build/Book DM"], H.pages["Build/Book Player"]
  eq(count(dm, "<svg"), dmBefore + 2, "the DM's edition draws both maps")
  eq(count(player, "<svg"), playerBefore + 1, "the player edition draws the clean one")
  has(dm, "**Where they start.** The creatures, in place.")
  hasnt(player, "Where they start")
end)

test("dm-only: an expression over several lines in a DM callout prints", "adventure", function()
  H.pages["Campaign/Ambush"] = table.concat({
    "---", "book_order: 11", "---", "", "# Ambush", "",
    "The road narrows.", "",
    "> **dm** The fight",
    "> ${party.fight { \"The ambush\", level = 1, difficulty = \"low\",",
    ">   {1, \"strangler\", cr = \"1/2\"},",
    "> }}", "",
    "Then the road opens out.", "",
  }, "\n")
  local report = gmbook.compile({ "dm", "player" })
  local dm, player = H.pages["Build/Book DM"], H.pages["Build/Book Player"]
  has(dm, "**The fight.**\n\n**The ambush.**")
  hasnt(dm, "party.fight", "an expression left unprinted")
  hasnt(player, "The ambush")
  has(player, "The road narrows.\n\nThen the road opens out.")
  for _, name in ipairs(report.live) do ok(name ~= "Campaign/Ambush", "Ambush reported as unprintable") end
end)

test("dm-only: the DM space says what is hidden in words, not colour alone", "dm", function()
  for _, lib in ipairs({ "Library/Storie/GM Kit", "Adventure/Library/Storie/GM Book" }) do
    local style = FIXTURES.dm[lib]:match("```space%-style\n(.-)\n```")
    ok(style, lib .. " has no space-style block")
    has(style, ".sb-admonition[admonition=\"dm\" i]", lib)
    has(style, "--admonition-icon", lib)
    has(style, "content: \"DM only", lib)
    has(style, "span.dm::before", lib)
    has(style, "content: \"DM ", lib)
  end
end)

test("dm-only: a page kept back whole takes no room in the player edition", "adventure", function()
  gmbook.compile({ "dm", "player" })
  local player = H.pages["Build/Book Player"]
  H.pages["Campaign/Secret Chapter"] =
    "---\nbook_order: 99\n---\n\n<!--#dm-->\n\n# Secret Chapter\n\nThe cult meets at the mill.\n"
  gmbook.compile({ "dm", "player" })
  eq(H.pages["Build/Book Player"], player, "the player edition changed")
  has(H.pages["Build/Book DM"], "# Secret Chapter\n\nThe cult meets at the mill.")
end)

-- What Adventure's pages hold, read line by line: a DM callout followed
-- straight by text takes that text with it, and a stretch never closed hides
-- the rest of its page, so either one is almost certainly a mistake. The
-- exception is a stretch opened above a page's title, which keeps the whole
-- page back on purpose.
test("dm-only: Adventure's callouts end at a blank line, and its stretches end", "dm", function()
  local bad = {}
  for name, text in pairs(FIXTURES.dm) do
    if name:startsWith("Adventure/") and not name:startsWith("Adventure/Library/") then
      local lines, fence, open, quote = {}, nil, 0, nil
      local headed, whole = false, false
      for line in (text .. "\n"):gmatch("([^\n]*)\n") do lines[#lines + 1] = line end
      for i, line in ipairs(lines) do
        local mark = line:match("^%s*(```)") or line:match("^%s*(~~~)")
        if fence then
          if mark == fence then fence = nil end
        elseif mark then
          fence = mark
        else
          if line:match("^#+%s") then headed = true end
          if line:match("^%s*<!%-%-%s*#%s*[dD][mM][^%w_]") then
            if not headed and open == 0 then whole = true end
            open = open + 1
          end
          if line:match("^%s*<!%-%-%s*/%s*[dD][mM][^%w_]") then open = open - 1 end
          if line:match("^%s*>") then
            local kind = line:match("^%s*>%s*%*%*(.-)%*%*") or line:match("^%s*>%s*%[!(.-)%]")
            if not quote then quote = { dm = false, typed = false } end
            if kind and not quote.typed then quote.typed, quote.dm = true, kind:lower() == "dm" end
            local nxt = lines[i + 1]
            if quote.dm and nxt and nxt:match("%S") and not nxt:match("^%s*>") then
              bad[#bad + 1] = name .. ": a DM callout runs on into \"" .. nxt:sub(1, 30) .. "\""
            end
          else
            quote = nil
          end
        end
      end
      if open > (whole and 1 or 0) then bad[#bad + 1] = name .. ": a stretch has no end marker" end
    end
  end
  eq(list(bad), "")
end)
