------------------------------------------------------ GM Maps: coordinates

-- Letters across the top and numbers down the left side, outside the frame,
-- so a square can be called out at the table: "the crate at C4". Off by
-- default, so a committed book doesn't change; the setting turns them on
-- for every map, and a map's own `coordinates` line for that map.

local ORCHARD = "World/Maps/The Old Orchard"
local NL = string.char(10)

local function svgOf(text) return text:match("(<svg.-</svg>)") end

local function attr(svg, name)
  return tonumber(svg:match('^<svg[^>]-%s' .. name .. '="([^"]*)"'))
end

-- The coordinate labels a drawing writes: each one's text, x and y.
local function labels(svg)
  local out = {}
  for tag, text in svg:gmatch('(<text class="gmm%-coord"[^>]*>)(.-)</text>') do
    out[#out + 1] = { text = text, x = tag:match(' x="([^"]*)"'), y = tag:match(' y="([^"]*)"'),
                      size = tag:match(' font%-size="([^"]*)"'), fill = tag:match(' fill="([^"]*)"'),
                      anchor = tag:match(' text%-anchor="([^"]*)"') }
  end
  return out
end

local function texts(ls)
  local out = {}
  for _, l in ipairs(ls) do out[#out + 1] = l.text end
  return table.concat(out, " ")
end

-- The frame round the grid: its x, y, width and height.
local function frame(svg)
  local x, y, w, h = svg:match('<rect x="([^"]*)" y="([^"]*)" width="([^"]*)" height="([^"]*)" fill="none" ' ..
    'stroke="#111111" stroke%-width="1.2"/>')
  return tonumber(x), tonumber(y), tonumber(w), tonumber(h)
end

local function keyLines(svg)
  local out = {}
  for line in svg:gmatch('<text class="gmm%-key"[^>]*>(.-)</text>') do out[#out + 1] = line end
  return table.concat(out, " | ")
end

local function mapPage(name, lines)
  H.pages[name] = table.concat({ "---", "type: map", "---", "", "# " .. name:match("[^/]+$"), "", "```map" }, NL) ..
    NL .. table.concat(lines, NL) .. NL .. "```" .. NL
  maps.refresh()
  return name
end

test("maps: no coordinates by default", "adventure", function()
  eq(maps.setting("coordinates"), false)
  local w = maps.draw(ORCHARD)
  hasnt(w.html, "gmm-coord")
  hasnt(w.markdown, "gmm-coord")
end)

test("maps: coordinates go outside the frame, letters over the columns and numbers by the rows", "adventure", function()
  config.set("gmMaps.coordinates", true)
  maps.refresh()
  local w = maps.draw(ORCHARD)
  for _, svg in ipairs({ svgOf(w.html), svgOf(w.markdown) }) do
    local ls = labels(svg)
    eq(texts(ls), "A B C D E F G H 1 2 3 4 5 6 7 8", "a letter for each column, a number for each row")
    local fx, fy, fw, fh = frame(svg)
    ok(fx and fx > 1 and fy > 1, "the grid moves in to make room for them")
    for _, l in ipairs(ls) do
      for _, v in ipairs({ l.x, l.y, l.size }) do
        ok(v:match("^%d+$"), "a whole number of px, the same in any Lua: " .. v)
      end
      eq(l.fill, "#111111", "in the map's own ink")
      if l.text:match("%a") then
        ok(tonumber(l.y) < fy, l.text .. " sits above the frame")
        eq(l.anchor, "middle")
      else
        ok(tonumber(l.x) < fx, l.text .. " sits left of the frame")
        eq(l.anchor, "end")
      end
    end
    -- the letters run left to right over the columns, the numbers down the rows
    ok(tonumber(ls[1].x) > fx and tonumber(ls[8].x) < fx + fw, "the letters span the grid")
    ok(tonumber(ls[9].y) > fy and tonumber(ls[16].y) < fy + fh, "the numbers span it too")
  end
  has(w.markdown, ">C<", "and in print as on the page")
end)

test("maps: a map with coordinates still fits a column, and its key wraps as it did", "adventure", function()
  local plain = svgOf(maps.draw(ORCHARD).markdown)
  config.set("gmMaps.coordinates", true)
  maps.refresh()
  local svg = svgOf(maps.draw(ORCHARD).markdown)
  ok(attr(svg, "width") <= maps.setting("width"), "no wider than a column: " .. attr(svg, "width"))
  ok(attr(svg, "height") <= 860, "no taller than a map is given")
  eq(keyLines(svg), keyLines(plain), "the key's rows break as they did")
  ok(attr(svg, "height") > attr(plain, "height"), "taller by the letters' margin")
  -- GM Book measures it at the height it declares
  local trace = {}
  gmbook.paginate("Before." .. NL .. NL .. svg .. NL .. NL .. "After.", trace)
  local drawn
  for _, t in ipairs(trace) do if t.kind == "drawn" then drawn = t end end
  ok(drawn, "the book sees a drawing it can measure")
  eq(drawn.h, attr(svg, "height"))
  -- a tall map with a long key, as maps_layout holds without coordinates
  local chars, src = "abcdefghijkl", { "##########" }
  for r = 1, 18 do
    local i = (r - 1) % 12 + 1
    src[#src + 1] = "#" .. string.rep(chars:sub(i, i), 8) .. "#"
  end
  src[#src + 1] = "##########"
  src[#src + 1] = ""
  src[#src + 1] = "# wall wall"
  for i = 1, 12 do src[#src + 1] = chars:sub(i, i) .. " rough " .. string.rep("gorse ", 21) .. "gorse" end
  local tall = (maps.svg(maps.parse(table.concat(src, NL)), {}))
  ok(attr(tall, "height") <= 860, "a tall map and a long key fit together: " .. attr(tall, "height"))
  ok(attr(tall, "width") <= maps.setting("width"))
  eq(#labels(tall), 10 + 20)
end)

test("maps: a map's own coordinates line has its way whatever the setting", "adventure", function()
  local src = { "#####", "#...#", "#####", "", "coordinates", "# wall wall", ". floor floor" }
  local m = maps.parse(table.concat(src, NL))
  eq(m.coordinates, true)
  eq(#m.warn, 0)
  local svg = svgOf(maps.draw(mapPage("World/Maps/Ford", src)).markdown)
  eq(texts(labels(svg)), "A B C D E 1 2 3", "on, with the setting off")
  config.set("gmMaps.coordinates", true)
  src[5] = "coordinates off"
  svg = svgOf(maps.draw(mapPage("World/Maps/Ford", src)).markdown)
  eq(#labels(svg), 0, "off, with the setting on")
  src[5] = "coordinates sideways"
  m = maps.parse(table.concat(src, NL))
  eq(m.coordinates, nil)
  eq(#m.warn, 1)
  has(m.warn[1], "A coordinates line is on or off")
end)

test("maps: a map too big to label every square labels every other one", "adventure", function()
  config.set("gmMaps.coordinates", true)
  local src = space.readPage(ORCHARD):match("```map\n(.-)\n```")
  local m = maps.parse(src)
  m.grow = 40
  local ls = labels((maps.svg(m, {})))
  local letters, numbers = {}, {}
  for _, l in ipairs(ls) do
    if l.text:match("%a") then letters[#letters + 1] = l.text else numbers[#numbers + 1] = l.text end
  end
  eq(table.concat(letters, " ", 1, 4), "A C E G", "every other column")
  eq(letters[#letters], "AM", "on past Z: AA, AB and so on")
  eq(table.concat(numbers, " ", 1, 3), "1 3 5", "every other row")
  for _, l in ipairs(ls) do ok(l.x:match("^%d+$") and l.y:match("^%d+$"), "whole px") end
  -- thirty across has room for every letter
  m.grow = 30
  local thirty = texts(labels((maps.svg(m, {}))))
  has(thirty, "Z AA AB AC AD 1 2 3")
end)

test("maps: a book built with coordinates measures its maps as it did", "adventure", function()
  config.set("gmMaps.coordinates", true)
  maps.refresh()
  H.current = "index"
  local report = gmbook.build({ "dm", "player" })
  eq(#report.written, 2)
  eq(#report.warnings, 0, "nothing the page breaks can't allow for")
  has(H.pages["Build/Book DM"], 'class="gmm-coord"', "the maps in the book have them")
  has(H.pages["Build/Book Player"], 'class="gmm-coord"')
end)
