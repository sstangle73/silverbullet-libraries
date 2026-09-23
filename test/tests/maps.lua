------------------------------------------------------------------ GM Maps

local ORCHARD = "World/Maps/The Old Orchard"
local NL = string.char(10)

-- The grid a map draws, as rows of characters, so a test reads the shape
-- rather than the SVG.
local function shape(m)
  local grid = (maps.grid(m))
  local out = {}
  for _, row in ipairs(grid) do out[#out + 1] = table.concat(row) end
  return table.concat(out, NL)
end

local function rowsOf(m)
  local out = {}
  for line in (shape(m) .. NL):gmatch("([^" .. NL .. "]*)" .. NL) do
    if line ~= "" then out[#out + 1] = line end
  end
  return out
end

local function drawn(ref, opts)
  local w = maps.draw(ref, opts)
  assert(type(w.html) == "string", "a GM Maps widget's html should be text")
  return w
end

local function attr(svg, name)
  return svg:match('^<svg[^>]-%s' .. name .. '="([^"]*)"')
end

local function svgOf(text) return text:match("(<svg.-</svg>)") end

-- Whether the key inside a drawing has a row reading exactly this: the
-- key's own text, not the label beside a thing or the title over it.
local function keyRow(svg, text)
  return svg:find('<text class="gmm%-key"[^>]*>' .. text .. '</text>') ~= nil
end

local function counted(rows, ch)
  local n = 0
  for _, row in ipairs(rows) do n = n + select(2, row:gsub(ch, "")) end
  return n
end

-- The old orchard's grid, as its page draws it: the strangler at the
-- middle, a creeper near each corner, and a way on and a way back through
-- the briar.
local SOURCE = table.concat({
  "#####^##",
  "#,,,,,,#",
  "#,c,,c,#",
  "#,,S,,,#",
  "#,,,,,,#",
  "#,c,,c,#",
  "#,,,,,,#",
  "##v#####",
  "",
  "grow to 8",
  "",
  "# wall briar, ten feet high",
  ", rough bramble and root",
  ". floor bare path",
  "^ exit the way on",
  "v exit the way back",
  "S token strangler = World/Monsters/Strangler",
  "c token creeper = World/Monsters/Creeper",
}, NL)

test("maps: loads in Adventure and in DM", "adventure", function()
  ok(maps and maps.draw and maps.parse, "no GM Maps in the Adventure space")
  eq(config.get("gmMaps.type"), nil, "the defaults need no campaign settings")
  eq(maps.setting("scale"), 5)
  eq(maps.setting("units"), "ft")
end)

test("maps: a map's source reads as a grid and a legend", "adventure", function()
  local m = maps.parse(SOURCE)
  eq(#m.rows, 8, "eight rows of grid")
  eq(m.grow, 8)
  eq(#m.warn, 0, "nothing to complain about")
  eq(table.concat(m.order), "#,.^vSc", "the legend keeps the order it was written in")
  eq(m.legend["#"].kind, "wall")
  eq(m.legend[","].kind, "rough")
  eq(m.legend["."].kind, "floor")
  eq(m.legend["^"].kind, "exit")
  eq(m.legend["S"].kind, "token")
  eq(m.legend["S"].text, "strangler", "the page comes off the end of the text")
  eq(m.legend["S"].page, "World/Monsters/Strangler")
  eq(m.legend[","].text, "bramble and root")
  eq(m.legend[","].page, nil, "only a creature names a page")
end)

test("maps: a line with no kind is drawn as floor, and says so", "adventure", function()
  local m = maps.parse("##" .. NL .. "##" .. NL .. NL .. "# wall wall" .. NL .. "x it is a mystery")
  eq(m.legend["x"].kind, "floor")
  eq(m.legend["x"].text, "it is a mystery")
  eq(#m.warn, 1)
  has(m.warn[1], "No kind for x")
end)

test("maps: grow takes the grid to the squares it asks for", "adventure", function()
  local m = maps.parse(SOURCE)
  m.grow = 6
  eq(shape(m), table.concat({
    "###^##",
    "#c,c,#",
    "#,S,,#",
    "#c,c,#",
    "#,,,,#",
    "#v####",
  }, NL), "a party of three: six squares across")
  m.grow = 10
  eq(shape(m), table.concat({
    "#######^##",
    "#,,,,,,,,#",
    "#,c,,,,c,#",
    "#,,,,,,,,#",
    "#,,,S,,,,#",
    "#,,,,,,,,#",
    "#,,,,,,,,#",
    "#,c,,,,c,#",
    "#,,,,,,,,#",
    "##v#######",
  }, NL), "a party of seven: ten squares across")
end)

test("maps: growing never loses or repeats a creature or a way out", "adventure", function()
  local m = maps.parse(SOURCE)
  for _, across in ipairs({ 6, 7, 8, 9, 10 }) do
    m.grow = across
    local rows = rowsOf(m)
    local at = " at " .. across .. " across"
    eq(#rows, across, "the grid is square" .. at)
    for _, row in ipairs(rows) do eq(#row, across, "every row is as wide as it is tall" .. at) end
    eq(counted(rows, "S"), 1, "one strangler" .. at)
    eq(counted(rows, "c"), 4, "four creepers" .. at)
    eq(counted(rows, "%^"), 1, "one way on" .. at)
    eq(counted(rows, "v"), 1, "one way back" .. at)
  end
end)

test("maps: growing keeps the middle in the middle", "adventure", function()
  local m = maps.parse(SOURCE)
  for _, across in ipairs({ 6, 7, 8, 9, 10 }) do
    m.grow = across
    local rows, sr, sc = rowsOf(m), nil, nil
    for r, row in ipairs(rows) do
      local c = row:find("S", 1, true)
      if c then sr, sc = r, c end
    end
    local mid = (across + 1) / 2
    ok(math.abs(sr - mid) <= 1, "the strangler's row is within one of the middle at " .. across)
    ok(math.abs(sc - mid) <= 1, "the strangler's column is within one of the middle at " .. across)
  end
end)

test("maps: a map with nothing plain to grow by says so", "adventure", function()
  local m = maps.parse(table.concat({
    "####", "#Sc#", "#cS#", "####", "", "grow to 9", "",
    "# wall wall", "S token strangler", "c token creeper",
  }, NL))
  local grid, note = maps.grid(m)
  ok(note, "it should say it could not grow")
  has(note, "no uniform row or column")
  eq(#grid, 4, "and leave the map the size it was drawn")
end)

test("maps: the page shows the creatures and print leaves them off", "adventure", function()
  local w = drawn(ORCHARD)
  has(w.html, "<svg", "the page gets an SVG")
  has(w.html, "Monsters/Strangler", "a creature on the map links to its Bestiary page")
  has(w.html, ">S<", "and is drawn as its legend letter")
  hasnt(w.markdown, ">S<", "print leaves the creatures off")
  hasnt(w.markdown, "Monsters/", "and links to nothing")
  has(w.markdown, "<svg", "but still draws the ground")
  has(w.markdown, "briar, ten feet high", "with its key inside the drawing")
  hasnt(w.markdown, "strangler", "and no key row for a creature")
end)

test("maps: the key is drawn, never the character from the source", "adventure", function()
  -- the defect this guards: the key used to list #, , ^ and v, none of
  -- which is anywhere on the drawing
  local svg = svgOf(drawn(ORCHARD).markdown)
  has(svg, "-hatchk)", "a wall's key row is a hatched swatch")
  has(svg, "-stipplek)", "difficult ground's is a stippled one")
  has(svg, "<polygon", "a way out's is the arrow itself")
  for _, ch in ipairs({ "#", ",", "^", "v" }) do
    hasnt(svg, ">" .. ch .. "<", "the key writes " .. ch .. ", which is not on the map")
  end
  local tokens = svgOf(drawn(ORCHARD, { tokens = true }).markdown)
  has(tokens, ">S<", "a creature's key row is its own ring and letter, which is on the map")
end)

test("maps: a creature's square is drawn as the ground under it", "adventure", function()
  local w = drawn(ORCHARD)
  local function squares(svg) return select(2, svg:gsub("%-stipple%)", "")) end
  eq(squares(svgOf(w.html)), squares(svgOf(w.markdown)),
     "the same squares are drawn either way, so the map without its creatures " ..
     "has no bare holes left where they were standing")
  -- inside the briar the orchard is six squares by six, all bramble: 31
  -- written as bramble, and the five a creature stands on drawn as it too
  eq(squares(svgOf(w.markdown)), 36, "every square inside the briar is bramble")
end)

test("maps: asked for them, print keeps the creatures", "adventure", function()
  local w = drawn(ORCHARD, { tokens = true })
  has(w.markdown, ">S<", "the DM edition can have them")
  ok(keyRow(w.markdown, "strangler"), "and their key rows")
  hasnt(w.markdown, "<a href", "but never a link, since print has nowhere to go")
end)

test("maps: the key can be left off", "adventure", function()
  local w = drawn(ORCHARD, { legend = false })
  hasnt(w.markdown, "briar", "no key in print")
  hasnt(w.markdown, "-hatchk)", "and no swatches drawn for one")
  hasnt(w.html, "briar", "nor on the page")
  local with = tonumber(attr(svgOf(drawn(ORCHARD).markdown), "height"))
  local without = tonumber(attr(svgOf(w.markdown), "height"))
  ok(without < with, "and the drawing is shorter by the key it does not have")
end)

test("maps: the SVG says how big it is, so GM Book can measure it", "adventure", function()
  local svg = svgOf(drawn(ORCHARD).markdown)
  local w, h = tonumber(attr(svg, "width")), tonumber(attr(svg, "height"))
  ok(w and h, "a width and a height in px")
  ok(w <= maps.setting("width"), "no wider than a column: " .. tostring(w))
  ok(h < gmbook.layout.height, "no taller than a column: " .. tostring(h))
  has(svg, 'style="display:block"', "and displayed as a block, or it would not measure")
  eq(attr(svg, "viewBox"), "0 0 " .. attr(svg, "width") .. " " .. attr(svg, "height"))
end)

test("maps: GM Book measures a map and spaces it as a paragraph", "adventure", function()
  local svg = svgOf(drawn(ORCHARD).markdown)
  local text = "Before the map." .. NL .. NL .. svg .. NL .. NL .. "After the map."
  local trace = {}
  gmbook.paginate(text, trace)
  local map
  for _, t in ipairs(trace) do
    if t.kind == "drawn" then map = t end
  end
  ok(map, "the paginator should see a block it can measure, not raw html")
  eq(map.h, tonumber(attr(svg, "height")), "measured at the height it declares")
end)

test("maps: every number in the drawing is written the same by any Lua", "adventure", function()
  local svg = svgOf(drawn(ORCHARD).markdown)
  hasnt(svg, '.0"', "a float printed as 274.0 here and 274 in SilverBullet " ..
        "would make a built edition differ from the wiki's")
  for value in svg:gmatch('="(%-?%d+%.%d+)"') do
    ok(value:sub(-1) ~= "0",
       "a trailing zero in " .. value .. " is one Lua's formatting, not the other's")
  end
end)

test("maps: two maps on one page do not share their patterns", "adventure", function()
  H.pages["World/Maps/Other"] = table.concat({
    "---", "type: map", "---", "", "# Other", "", "```map",
    "###", "#.#", "###", "", "# wall wall", ". floor floor", "```",
  }, NL)
  maps.refresh()
  local one = drawn(ORCHARD).html:match('id="(gmm%w+)%-hatch"')
  local two = drawn("World/Maps/Other").html:match('id="(gmm%w+)%-hatch"')
  ok(one and two, "both name their patterns")
  ok(one ~= two, "an id is document-wide, so two maps must not share one")
  eq(drawn(ORCHARD).html:match('id="(gmm%w+)%-hatch"'), one, "the same map always gets the same id")
end)

test("maps: a path written for Adventure finds the page from DM", "dm", function()
  has(drawn(ORCHARD).html, "<svg", "the adventure's own path still finds the map")
  eq(maps.find(ORCHARD).name, "Adventure/" .. ORCHARD)
end)

test("maps: a page it can't find says so on the page, and prints nothing", "adventure", function()
  local w = maps.draw("World/Maps/Nowhere")
  has(w.html, "No map page for World/Maps/Nowhere")
  has(w.markdown, "No map page for World/Maps/Nowhere")
  -- in print a message would go into the book as if it were the map, so
  -- it prints nothing but raises why, and GM Book keeps the edition back
  -- and names the page with that reason
  local good, why = pcall(maps.printed.draw, "World/Maps/Nowhere")
  ok(not good, "nothing printed")
  has(why, "No map to draw from World/Maps/Nowhere")
end)

test("maps: print is the size the adventure is written for", "adventure", function()
  local before = maps.printed.draw(ORCHARD)
  useParty(7, 1)
  maps.refresh()
  eq(maps.printed.draw(ORCHARD), before, "a bigger party at the table must not change the book")
  local live = tonumber(attr(svgOf(drawn(ORCHARD).html), "height"))
  ok(live > tonumber(attr(svgOf(before), "height")),
     "but the page draws the map for who is playing tonight")
end)

test("maps: Scene 3 draws the old orchard", "adventure", function()
  local scene = space.readPage("Campaign/Act I/Scene 3")
  has(scene, 'maps.draw("World/Maps/The Old Orchard")', "the scene names the map")
  hasnt(scene, "```map", "and draws it from the map's own page, holding no grid of its own")
  local printed = gmbook.print(scene, "Campaign/Act I/Scene 3")
  gmbook.printing = nil
  has(printed, "<svg", "and the map prints inside the scene")
  hasnt(printed, "maps.draw", "with nothing left live")
end)

------------------------------------------------------------- kinds and layers

local EVERY = table.concat({
  "#####^##",
  "#,,,,,,#",
  "#~~,,O,#",
  "#~~O,C,#",
  "#::,T,,#",
  "#::,HL,#",
  "#,,,,,,#",
  "##D#####",
  "",
  "# wall stone wall",
  ", rough rubble",
  ". floor swept floor",
  "~ water the flooded end",
  ": pit the shaft",
  "^ exit the way up",
  "D door the hatch",
  "T token a crow = World/Monsters/Crow",
  "O object a crate",
  "L control [lever] the brake lever",
  "C treasure [strongbox] the strongbox",
  "H hidden a trapdoor",
}, NL)

local function everyMap()
  H.pages["World/Maps/Everything"] = table.concat({
    "---", "type: map", "---", "", "# Everything", "", "```map", EVERY, "```",
  }, NL)
  maps.refresh()
  return "World/Maps/Everything"
end

test("maps: every kind is a kind", "adventure", function()
  local m = maps.parse(EVERY)
  eq(#m.warn, 0, "a map using all of them complains about none of them")
  local want = {
    ["#"] = "wall", [","] = "rough", ["."] = "floor", ["~"] = "water", [":"] = "pit",
    ["^"] = "exit", ["D"] = "door", ["T"] = "token", ["O"] = "object",
    ["L"] = "control", ["C"] = "treasure", ["H"] = "hidden",
  }
  for ch, kind in pairs(want) do
    eq(m.legend[ch].kind, kind, ch .. " should be " .. kind)
  end
end)

test("maps: terrain is drawn identically with the DM layer and without", "adventure", function()
  local ref = everyMap()
  local function fills(svg)
    local out = {}
    for _, p in ipairs({ "hatch", "stipple", "cross", "wave" }) do
      out[#out + 1] = p .. "=" .. select(2, svg:gsub("%-" .. p .. "%)", ""))
    end
    return table.concat(out, " ")
  end
  local dm = fills(svgOf(drawn(ref, { dm = true }).markdown))
  local players = fills(svgOf(drawn(ref).markdown))
  eq(players, dm, "a square must not change when the DM's layer comes off, or the " ..
     "players' map shows where the creatures and the trapdoors are")
end)

test("maps: the ground under a thing comes from its neighbours", "adventure", function()
  -- a crate in the water stands on water, not on whatever the map has most of
  local src = table.concat({
    "#####", "#~~~#", "#~O~#", "#,,,#", "#####", "",
    "# wall wall", "~ water water", ", rough rubble", "O object a crate",
  }, NL)
  H.pages["World/Maps/Wet"] = table.concat({
    "---", "type: map", "---", "", "# Wet", "", "```map", src, "```",
  }, NL)
  maps.refresh()
  local svg = svgOf(drawn("World/Maps/Wet").markdown)
  -- five squares of water are written, and the crate's makes a sixth: it is
  -- drawn on the water it sits in, not on the rubble the map also has
  eq(select(2, svg:gsub("%-wave%)", "")), 6, "the crate's square is drawn as water")
  eq(select(2, svg:gsub("%-stipple%)", "")), 3, "the rubble row is only the rubble row")
  eq(select(2, svg:gsub("%-hatch%)", "")), 16, "and the wall is untouched")
end)

test("maps: only creatures and hidden things are the DM's", "adventure", function()
  local ref = everyMap()
  local players = drawn(ref).markdown
  local dm = drawn(ref, { dm = true }).markdown
  has(players, "a crate", "a crate is in plain sight")
  has(players, "the brake lever", "so is a lever")
  has(players, "the strongbox", "so is a chest")
  hasnt(players, "a crow", "a creature is not")
  hasnt(players, "a trapdoor", "nor is a hidden thing")
  for _, want in ipairs({ "a crate", "the brake lever", "the strongbox", "a crow", "a trapdoor" }) do
    has(dm, want, "the DM's map has " .. want)
  end
end)

test("maps: dm is the option's name, and tokens still works", "adventure", function()
  local ref = everyMap()
  eq(drawn(ref, { dm = true }).markdown, drawn(ref, { tokens = true }).markdown,
     "tokens was this option's name in 1.1")
end)

test("maps: every silhouette is drawn inside its own square", "adventure", function()
  for _, kind in ipairs({ "token", "object", "control", "treasure", "hidden" }) do
    local src = table.concat({
      "###", "#X#", "###", "", "# wall wall", "X " .. kind .. " a thing",
    }, NL)
    H.pages["World/Maps/One"] = table.concat({
      "---", "type: map", "---", "", "# One", "", "```map", src, "```",
    }, NL)
    maps.refresh()
    local svg = svgOf(drawn("World/Maps/One", { dm = true }).markdown)
    hasnt(svg, '="-', kind .. " is drawn off the edge of the canvas")
    hasnt(svg, ",-", kind .. " has a point off the edge of the canvas")
  end
end)

----------------------------------------------------------------- the parser

test("maps: a space inside a grid row stays part of the grid", "adventure", function()
  -- it used to look like a legend line, and threw the rest of the map away
  local m = maps.parse(table.concat({
    "####", "# ##", "#  #", "####", "", "# wall wall",
  }, NL))
  eq(#m.rows, 4, "all four rows are grid")
  eq(#m.warn, 0, "and nothing is wrong with them")
end)

test("maps: a grid row that spells a keyword stays part of the grid", "adventure", function()
  local m = maps.parse(table.concat({
    "####", "grow", "####", "", "# wall wall",
    "g rough g", "r rough r", "o rough o", "w rough w",
  }, NL))
  eq(#m.rows, 3, "the row reading 'grow' is part of the picture")
  eq(m.grow, nil, "and it set nothing")
  eq(#m.warn, 0)
end)

test("maps: a real grow line is still a grow line", "adventure", function()
  local m = maps.parse(table.concat({ "####", "####", "", "grow to 6", "# wall wall" }, NL))
  eq(m.grow, 6)
  eq(#m.rows, 2)
end)

test("maps: two legend lines for one character say so", "adventure", function()
  local m = maps.parse(table.concat({ "##", "", "# wall first", "# rough second" }, NL))
  eq(m.legend["#"].kind, "rough", "the last one wins")
  eq(#m.warn, 1)
  has(m.warn[1], "Two legend lines for #")
end)

-------------------------------------------------------------- labels on the map

test("maps: a thing is named on the map, not only in the key", "adventure", function()
  local m = maps.parse(table.concat({
    "###", "#S#", "###", "",
    "# wall wall", "S token strangler, rooted at the middle",
  }, NL))
  eq(m.legend["S"].label, "strangler", "the label is the line up to its first comma")
  eq(m.legend["S"].text, "strangler, rooted at the middle", "and the key keeps all of it")
  eq(#m.warn, 0)
end)

-- The docs' own examples, read from the docs, so they can't promise a label
-- the code won't draw. Until GM Maps 1.2.3 they promised "the strongbox",
-- one character over the limit they state.
test("maps: the docs' examples of a label draw as the docs say", "adventure", function()
  local doc = SRC["GM Maps"]
  local line = doc:match("\n    (C treasure [^\n]+)\n")
  local label = doc:match("draws %*%*([^*]+)%*%* beside the triangle")
  ok(line and label, "the docs' strongbox example has moved")
  local m = maps.parse(table.concat({ "###", "#C#", "###", "", "# wall wall", line }, NL))
  eq(m.legend["C"].label, label)
  eq(#m.warn, 0)
  local bracketed = doc:match("\n    (O object %[[^\n]+)\n")
  ok(bracketed, "the docs' bracket example has moved")
  m = maps.parse(table.concat({ "###", "#O#", "###", "", "# wall wall", bracketed }, NL))
  eq(m.legend["O"].label, bracketed:match("%[([^%]]+)%]"))
  eq(#m.warn, 0)
end)

test("maps: a label too long to draw asks for a short one", "adventure", function()
  local m = maps.parse(table.concat({
    "###", "#O#", "###", "", "# wall wall", "O object a crate of blasting powder",
  }, NL))
  eq(m.legend["O"].label, nil, "nothing is drawn beside it")
  eq(#m.warn, 1, "and the map says why, rather than leaving a bare letter")
  has(m.warn[1], "Give it a label in brackets")
end)

test("maps: a label in brackets is used and kept out of the key", "adventure", function()
  local m = maps.parse(table.concat({
    "###", "#O#", "###", "", "# wall wall", "O object [crate] a crate of blasting powder",
  }, NL))
  eq(m.legend["O"].label, "crate")
  eq(m.legend["O"].text, "a crate of blasting powder", "the brackets are not part of the text")
  eq(#m.warn, 0)
end)

test("maps: only a thing is labelled, and only where a square can hold it", "adventure", function()
  local m = maps.parse(table.concat({
    "###", "#S#", "###", "", "# wall stone wall", "S token strangler",
  }, NL))
  eq(m.legend["#"].label, nil, "terrain is named in the key, not on every square of itself")
  local svg = svgOf(drawn(everyMap(), { dm = true }).markdown)
  has(svg, 'class="gmm-label"', "a label is drawn beside a thing at this size")
  has(svg, ">a crow<", "and it says what the thing is")
  -- a map grown small enough leaves them off rather than drawing a smudge
  local small = maps.parse(EVERY)
  small.grow = 40
  local tiny = (maps.svg(small, { dm = true }))
  -- the key still names it; what goes is the label beside the square
  hasnt(tiny, 'class="gmm-label"', "and off where a square is too small for words")
  has(tiny, ">a crow<", "the key names it either way")
end)

test("maps: a label never measures differently in the two Luas", "adventure", function()
  -- the length is counted, so the pattern admits only ASCII: bytes and
  -- UTF-16 units agree there, and a build has to match the wiki
  local m = maps.parse(table.concat({
    "###", "#O#", "###", "", "# wall wall", "O object [caf\u{00e9} table] a table",
  }, NL))
  eq(m.legend["O"].label, nil, "a label outside ASCII is not drawn")
  eq(#m.warn, 1)
end)

-------------------------------------------------------------- a stale tab

-- A tab left open over a Library: Update runs the old GM Maps over the new
-- pages; GM Book asks maps.stale before it builds.
test("maps: stale says when the space holds another GM Maps", "dm", function()
  local page = "Adventure/Library/Storie/GM Maps"
  eq(maps.stale(), nil, "the tab runs the page the space holds")
  H.pages[page] = (H.pages[page]:gsub('\nversion: "[^"\n]*"\n', '\nversion: "7.0.0"\n', 1))
  eq(maps.stale(), "This tab runs GM Maps " .. maps.version .. ", but the space has 7.0.0: " ..
    "reload it (System: Reload, Ctrl-Alt-R) before building.")
  eq(maps.printed.stale(), maps.stale(), "GM Book finds it through the printer")
end)
