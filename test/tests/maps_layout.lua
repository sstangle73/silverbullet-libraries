------------------------------------------------------ GM Maps: shape and key

local NL = string.char(10)

-- The rows of the key a drawing writes, in order.
local function keyLines(svg)
  local out = {}
  for line in svg:gmatch('<text class="gmm%-key"[^>]*>(.-)</text>') do out[#out + 1] = line end
  return out
end

------------------------------------------------ the same drawing in every Lua

test("maps: a key line wraps at the same word in every Lua", "adventure", function()
  -- "—" is one UTF-16 unit in SilverBullet and three bytes in stock Lua,
  -- and "à" one and two: counted in bytes, this line broke a word early
  local m = maps.parse(table.concat({
    "#####", "#,,,#", "#####", "",
    "# wall briar",
    ", rough gorse and root — difficult terrain, à la ronde, where the brambles close over the path",
  }, NL))
  local lines = keyLines((maps.svg(m, {})))
  eq(#lines, 3, "a row for the briar, and two for the gorse")
  eq(lines[2], "gorse and root — difficult terrain, à la ronde, where the")
  eq(lines[3], "brambles close over the path")
end)

test("maps: a number a map's source prints is written the same in every Lua", "adventure", function()
  mylib = { paces = function() return 10 / 4 * 4 end }
  local fine, m = pcall(maps.parse, table.concat({
    "###", "#.#", "###", "", "title ${mylib.paces()} paces of ford", "# wall wall", ". floor floor",
  }, NL))
  mylib = nil
  assert(fine, m)
  eq(m.title, "10 paces of ford")
end)

------------------------------------------------ the grid's shape

-- A corridor twelve squares by five, with a way in at one end and a way
-- out at the other.
local CORRIDOR = {
  "############",
  "#..........#",
  "^..........v",
  "#..........#",
  "############",
}

local function corridor(grow)
  local lines = {}
  for _, l in ipairs(CORRIDOR) do lines[#lines + 1] = l end
  lines[#lines + 1] = ""
  if grow then lines[#lines + 1] = "grow to " .. grow end
  for _, l in ipairs({ "# wall wall", ". floor floor", "^ exit the way in", "v exit the way out" }) do
    lines[#lines + 1] = l
  end
  return maps.parse(table.concat(lines, NL))
end

local function shape(m)
  local out = {}
  for _, row in ipairs((maps.grid(m))) do out[#out + 1] = table.concat(row) end
  return out
end

test("maps: grow to the width a map is drawn at leaves it as it is", "adventure", function()
  eq(table.concat(shape(corridor(12)), "/"), table.concat(CORRIDOR, "/"),
    "a corridor twelve across stays a corridor, five deep, its ways out where they were")
end)

test("maps: grow adds as many rows as it adds columns, so a map keeps its shape", "adventure", function()
  local rows = shape(corridor(14))
  eq(#rows, 7, "two more across, two more down")
  for _, r in ipairs(rows) do eq(#r, 14, "every row is fourteen across") end
  local ends = {}
  for _, r in ipairs(rows) do
    if r:sub(1, 1) == "^" and r:sub(-1) == "v" then ends[#ends + 1] = r end
  end
  eq(#ends, 1, "one row still has the way in at one end and the way out at the other")
  rows = shape(corridor(10))
  eq(table.concat(rows, "/"), "##########/^........v/##########", "two fewer each way")
end)

------------------------------------------------ what the map says under it

local function mapPage(name, lines)
  H.pages[name] = table.concat({ "---", "type: map", "---", "", "# " .. name:match("[^/]+$"), "", "```map" }, NL) ..
    NL .. table.concat(lines, NL) .. NL .. "```" .. NL
  maps.refresh()
  return name
end

test("maps: a grid character with no legend line is drawn as floor, and says so", "adventure", function()
  local src = { "#####", "#.x.#", "#.y.#", "#####", "", "# wall wall", ". floor floor" }
  local m = maps.parse(table.concat(src, NL))
  eq(#m.warn, 1)
  eq(m.warn[1], "No legend lines for x and y, so they are drawn as open floor.")
  local w = maps.draw(mapPage("World/Maps/Odd", src))
  has(w.html, "No legend lines for x and y", "the page says so under the map")
  hasnt(w.markdown, "legend line", "print never does")
end)

test("maps: a row indented with spaces says it lost them", "adventure", function()
  -- an L-shaped room written by indenting its narrow end
  local src = { "   ####", "   #..#", "####..#", "#.....#", "#######", "", "# wall wall", ". floor floor" }
  local m = maps.parse(table.concat(src, NL))
  eq(#m.warn, 1)
  has(m.warn[1], "Rows 1 and 2 start with spaces")
  has(m.warn[1], "a character for each empty square")
  local w = maps.draw(mapPage("World/Maps/Ell", src))
  has(w.html, "Rows 1 and 2 start with spaces")
  hasnt(w.markdown, "spaces")
end)

------------------------------------------------ the key

test("maps: a key whose lines wrap still leaves map and key inside a column", "adventure", function()
  -- a tall map, and a key of thirteen rows, twelve of them three lines long
  local chars, src = "abcdefghijkl", { "##########" }
  for r = 1, 18 do
    local i = (r - 1) % 12 + 1
    src[#src + 1] = "#" .. string.rep(chars:sub(i, i), 8) .. "#"
  end
  src[#src + 1] = "##########"
  src[#src + 1] = ""
  src[#src + 1] = "# wall wall"
  for i = 1, 12 do
    src[#src + 1] = chars:sub(i, i) .. " rough " .. string.rep("gorse ", 21) .. "gorse"
  end
  local svg = (maps.svg(maps.parse(table.concat(src, NL)), {}))
  local lines = keyLines(svg)
  eq(#lines, 1 + 12 * 3, "each gorse row wraps onto three lines")
  local height = tonumber(svg:match('^<svg[^>]-%sheight="([^"]*)"'))
  ok(height <= 860, "the map and its key fit the height a map is given: " .. height)
  ok(height < gmbook.layout.height, "and a column of the book")
end)
