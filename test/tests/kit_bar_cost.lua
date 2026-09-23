------------------------------------------------------------------ GM Kit: what a bar costs
-- A bar asks about the same pages from several places. Before its cache,
-- one draw of a scene with a found item made 14 reads, 17 looks at whether
-- a page was there and 3 scans of the whole page index, one more for every
-- item row (gm.isPrivate): the scene itself was read 8 times and looked at
-- 7, and in a real campaign a scan is every page there is. One draw now
-- reads each page once, looks at each once, and makes each scan once.

local SCENE2 = "Adventure/Campaign/Act I/Scene 2"
local LANTERN = "Adventure/World/Items/Lantern"
local LOG1 = "Sessions/Session 1"

-- What `draw` asks of the space and the index: the reads and the looks at
-- whether a page is there, by page, and the scans of the page index. GM
-- Party reads the index for the party at most every two seconds, so the
-- party is read first and kept as it is while `draw` runs.
local function costOf(draw)
  local cost = { reads = {}, metas = {}, readCount = 0, metaCount = 0, scans = 0 }
  local read, meta, pages, get = space.readPage, space.getPageMeta, index.pages, party.get
  local p = party.get()
  party.get = function() return p end
  space.readPage = function(name)
    cost.readCount = cost.readCount + 1
    cost.reads[name] = (cost.reads[name] or 0) + 1
    return read(name)
  end
  space.getPageMeta = function(name)
    cost.metaCount = cost.metaCount + 1
    cost.metas[name] = (cost.metas[name] or 0) + 1
    return meta(name)
  end
  index.pages = function()
    cost.scans = cost.scans + 1
    return pages()
  end
  local ok, result = pcall(draw)
  space.readPage, space.getPageMeta, index.pages, party.get = read, meta, pages, get
  if not ok then error(result, 0) end
  cost.result = result
  return cost
end

-- Every page read, or asked after, more than once in one draw.
local function twice(cost)
  local out = {}
  for _, kind in ipairs({ "reads", "metas" }) do
    local names = {}
    for name, n in pairs(cost[kind]) do
      if n > 1 then names[#names + 1] = name .. " (" .. n .. ")" end
    end
    table.sort(names)
    if #names > 0 then out[#out + 1] = kind .. ": " .. table.concat(names, ", ") end
  end
  return table.concat(out, "; ")
end

-- Holds a draw to its ceiling: no page read or asked after twice, and at
-- most so many reads, looks and scans in all. Says everything over it at
-- once, so a draw from before the cache shows all it costs.
local function ceiling(cost, reads, metas, scans)
  local over = {}
  local again = twice(cost)
  if again ~= "" then over[#over + 1] = "twice: " .. again end
  if cost.readCount > reads then over[#over + 1] = cost.readCount .. " reads, not " .. reads end
  if cost.metaCount > metas then over[#over + 1] = cost.metaCount .. " looks, not " .. metas end
  if cost.scans > scans then over[#over + 1] = cost.scans .. " scans of the index, not " .. scans end
  eq(table.concat(over, " | "), "", "over the ceiling")
end

-- A second item the scene shows the rules of, so the scene's bar has two
-- item rows.
local function withRope()
  H.pages["Adventure/World/Items/Rope"] =
    "---\ntype: item\n---\n\n# Rope\n\nFifty feet of it.\n\n## Rules\n\n- **Climb.** It holds one climber.\n"
  H.pages[SCENE2] = H.pages[SCENE2]:gsub("\n## DM Only", "\n![[World/Items/Rope#Rules]]\n\n## DM Only", 1)
end

test("kit bar: the ceiling: a scene with a found item reads each page once, and scans three times", "dm", function()
  gm.markFound(LANTERN, SCENE2)
  local cost = costOf(function() return gm.bar(SCENE2) end)
  ok(cost.result, "the scene has a bar")
  -- the scene, the session table, the revealed list, the lantern and its
  -- record; the records by the pages they are about, every page's type, and
  -- GM Kit's own page, for whether this tab is stale
  ceiling(cost, 5, 5, 3)
end)

test("kit bar: the ceiling: another item row costs no scan of the index", "dm", function()
  withRope()
  gm.markFound(LANTERN, SCENE2)
  gm.mark("Adventure/World/Items/Rope", "found")
  local cost = costOf(function() return gm.bar(SCENE2) end)
  eq(#gm.itemsOn(SCENE2), 2, "two item rows")
  -- the rope and its record as well; gm.isPrivate's one scan answers for
  -- every row
  ceiling(cost, 7, 7, 3)
end)

test("kit bar: a session's bar reads each scene once, and scans each thing once", "dm", function()
  gm.mark("Adventure/Campaign/Act I/Scene 1", "started")
  gm.mark("Adventure/Campaign/Act I/Scene 1", "finished")
  gm.mark(SCENE2, "started")
  local cost = costOf(function() return gm.sessionBar(LOG1) end)
  has(textOf(cost.result.html), "**[[" .. SCENE2 .. "|Scene 2 — The Market]]**")
  -- the log, the three scenes and the records of the two played; the scenes
  -- in order, and the records by the pages they are about
  ceiling(cost, 6, 6, 2)
end)

test("kit bar: a character's bar reads each page once", "dm", function()
  local bram = "Party/Bram"
  H.pages[bram] = "---\ntype: pc\nhp: 20\nslots: [2]\nresources:\n  - {name: Rage, uses: 2, reset: Long Rest}\n" ..
                  "---\n\n# Bram\n"
  local cost = costOf(function() return gm.characterBar(bram) end)
  ok(cost.result, "Bram has a bar")
  -- the page and the session table; GM Kit's own page, for whether this tab
  -- is stale; and, with no record where Bram's goes, the characters'
  -- records by the pages they are about
  ceiling(cost, 2, 2, 2)
  gm.damage(bram, 3)
  gm.slot(bram, 1, true)
  cost = costOf(function() return gm.characterBar(bram) end)
  -- and the record, where it belongs, so nothing to look for
  ceiling(cost, 3, 3, 1)
  -- and the same bar without the cache
  local cached = cost.result.html.outerHTML
  local rendering = gm.rendering
  gm.rendering = function() return nil end
  local good, err = pcall(function() eq(gm.characterBar(bram).html.outerHTML, cached) end)
  gm.rendering = rendering
  if not good then error(err, 0) end
end)

test("kit bar: the cache lives while a bar is drawn, and no longer", "dm", function()
  eq(gm.cache, nil)
  H.current = SCENE2
  ok(gm.topBar())
  eq(gm.cache, nil, "gone once the bar is drawn")
  ok(gm.bar(SCENE2))
  eq(gm.cache, nil, "a bar drawn on its own opens and closes one too")
  -- a bar drawn inside another's draw shares its cache
  do
    local render <close> = gm.rendering()
    local mine = gm.cache
    ok(mine, "open")
    eq(gm.rendering(), nil, "a second draw inside shares it")
    gm.bar(SCENE2)
    eq(gm.cache, mine, "and leaves it open for the draw it is part of")
  end
  eq(gm.cache, nil)
  -- a draw that fails still lets it go
  local good = pcall(function()
    local render <close> = gm.rendering()
    error("boom")
  end)
  ok(not good)
  eq(gm.cache, nil, "let go of after an error")
end)

test("kit bar: a write, a delete or a read to change lets the cache go", "dm", function()
  local page = "State/Scratch"
  H.pages[page] = "one\n"
  do
    local render <close> = gm.rendering()
    eq(gm.exists(page), true)
    gm.write(page, "two\n")
    eq(gm.cache, nil, "a write lets it go")
  end
  do
    local render <close> = gm.rendering()
    eq(gm.exists(page), true)
    H.pages[page] = "three\n"
    eq(gm.read(page), "three\n", "a read to change reads the space itself")
    eq(gm.cache, nil, "and lets the cache go")
  end
  do
    local render <close> = gm.rendering()
    local copy = "Player/World/People/Wren"
    H.pages[copy] = "# Wren\n"
    eq(gm.exists(copy), true)
    gm.unreveal("Adventure/World/People/Wren")
    eq(H.pages[copy], nil, "the players' copy is deleted")
    eq(gm.cache, nil, "a delete lets it go")
    eq(gm.exists(copy), false, "and the next look asks the space")
  end
end)

test("kit bar: what a draw read stays out of a click on its bar", "dm", function()
  gm.markFound(LANTERN, SCENE2)
  H.current = LANTERN
  do
    -- the click lands while the draw is still open, as it can in SilverBullet
    local render <close> = gm.rendering()
    local bar = gm.bar()
    eq(gm.readState(LANTERN).uses, "6")
    -- the record changes behind the bar's back, from another device
    H.pages["State/Items/Lantern"] = H.pages["State/Items/Lantern"]:gsub("\nuses: 6\n", "\nuses: 3\n", 1)
    click(bar, "Use a wick")
  end
  eq(lastNotification().message, "Lantern: a wick used. 2 of 6 wicks left.")
  has(H.pages["State/Items/Lantern"], "\nuses: 2\n")
end)

test("kit bar: what a draw read stays out of a notification's action", "dm", function()
  local mara = "Adventure/World/People/Mara"
  gm.mark(mara, "met")
  local met = lastNotification()
  do
    local render <close> = gm.rendering()
    eq(gm.exists("State/People/Mara"), true)
    -- the record goes behind the bar's back
    H.pages["State/People/Mara"] = nil
    runAction(met, "Undo")
  end
  eq(H.pages["State/People/Mara"], nil, "nothing to take back, and nothing written")
  eq(lastNotification().message, "Undone: Mara is no longer marked met")
end)

-- The cache changes what a bar costs, never what it shows: every adventure
-- page's bar, with play marked on some of them, drawn with the cache and
-- without it.
test("kit bar: a bar shows the same with the cache as without it", "dm", function()
  withRope()
  gm.markFound(LANTERN, SCENE2)
  gm.mark("Adventure/World/People/The Warden", "met")
  gm.mark("Adventure/World/Places/Fordtown", "visited")
  gm.mark(SCENE2, "started")
  gm.reveal("Adventure/World/People/Mara")
  H.confirms = { true }
  gm.publish()
  local function draw(page)
    local bar = gm.bar(page)
    return bar and bar.html.outerHTML or "none"
  end
  local pages = gm.adventurePages()
  ok(#pages > 10, "the adventure's pages")
  local cached = {}
  for _, page in ipairs(pages) do cached[page] = draw(page) end
  local rendering = gm.rendering
  gm.rendering = function() return nil end
  local good, err = pcall(function()
    for _, page in ipairs(pages) do
      eq(gm.cache, nil, "no cache")
      eq(draw(page), cached[page], page)
    end
  end)
  gm.rendering = rendering
  if not good then error(err, 0) end
end)
