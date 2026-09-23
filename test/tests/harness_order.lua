------------------------------------------------------------------ Harness: load order
-- The order run.py loads space-lua blocks in, held to SilverBullet 2.11's:
-- plugs/index/space_lua.ts names each block "<page>@<offset of its fence>"
-- and reads the first "-- priority: N" anywhere in it, and client/space_lua.ts
-- runs them by priority, highest first, then by that name as JavaScript
-- sorts strings. A library that leans on the order of its own page's blocks
-- passes here only if it passes on the wiki.

-- The length of a string as JavaScript counts it, in UTF-16 code units.
local function utf16Length(s)
  local n = 0
  for _, c in utf8.codes(s) do n = n + (c > 0xFFFF and 2 or 1) end
  return n
end

-- A page's blocks as this file reads them, apart from run.py: each with its
-- name as SilverBullet gives it, and its priority.
local function blocksOf(page, text)
  local out, from = {}, 1
  while true do
    local at = text:find("```space-lua\n", from, true)
    if not at then return out end
    local close = assert(text:find("\n```", at + 13, true), page .. ": a block with no end")
    local code = text:sub(at + 13, close - 1)
    out[#out + 1] = { ref = page .. "@" .. utf16Length(text:sub(1, at - 1)), index = #out + 1,
                      priority = tonumber(code:match("%-%-%s*priority:%s*(%-?%d+)") or "0") }
    from = close + 4
  end
end

local function loaded(layout, page)
  local out = {}
  for _, lib in ipairs(LIBS[layout]) do
    if lib.page == page then out[#out + 1] = lib.ref end
  end
  return out
end

test("harness: GM Kit's blocks load in the order their names sort, not the page's", "dm", function()
  local page = "Library/Storie/GM Kit"
  local blocks = blocksOf(page, FIXTURES.dm[page])
  ok(#blocks >= 2, "GM Kit should have two blocks")
  local expected = {}
  for i, b in ipairs(blocks) do
    eq(b.priority, blocks[1].priority, "GM Kit's blocks share a priority, so their names decide")
    expected[i] = b
  end
  -- ASCII names: Lua's byte order is JavaScript's here
  table.sort(expected, function(a, b) return a.ref < b.ref end)
  local want = {}
  for i, b in ipairs(expected) do want[i] = b.ref end
  if SHUFFLED then
    local reversed = {}
    for i = #want, 1, -1 do reversed[#reversed + 1] = want[i] end
    want = reversed
  end
  eq(list(loaded("dm", page)), list(want), "GM Kit's blocks in the DM space")
  -- As the page stands, the second fence's offset sorts first as text (it
  -- has a digit more, and a smaller first one), so SilverBullet runs the
  -- second block first: code at the top of it that reads what the first
  -- block defines finds nothing there, and the whole block is skipped.
  if not SHUFFLED and blocks[2].ref < blocks[1].ref then
    local names = {}
    for _, lib in ipairs(LIBS.dm) do
      if lib.page == page then names[#names + 1] = lib.name end
    end
    eq(names[1], page .. " #2", "the second block loads first")
  end
end)

local function block(code) return "```space-lua\n" .. code .. "\n```\n" end

local function order(pages) return list(__load_order(pages)) end

test("harness: a block's priority counts wherever in the block it is", "dm", function()
  eq(order({
    A = block("-- priority: 1\na = 1"),
    B = block("b = 2\n-- priority: 5"),
    C = block("c = 3"),
    D = block("d = 4 -- priority: -1"),
  }), "B@0 | A@0 | C@0 | D@0")
end)

test("harness: blocks of one priority load by name, compared as text", "dm", function()
  -- The fence at 100 loads before the one at 20, since "100" < "20".
  local text = string.rep("a", 19) .. "\n" .. block("one = 1") .. string.rep("b", 54) .. "\n" .. block("two = 2")
  eq(order({ P = text }), "P@100 | P@20")
  -- A page whose name another page's extends: " " sorts before "@".
  eq(order({ ["GM Kit"] = block("x = 1"), ["GM Kit Extra"] = block("y = 2") }),
     "GM Kit Extra@0 | GM Kit@0")
end)

test("harness: an offset counts UTF-16 code units, as JavaScript's strings do", "dm", function()
  -- é is two bytes and one unit, U+1F5D1 four bytes and two units
  eq(order({ Q = "é\u{1F5D1}\n" .. block("x = 1") }), "Q@4")
  -- A character beyond U+FFFF is two surrogates, D800-DFFF, to JavaScript,
  -- and sorts before U+FF01, which it follows by code point.
  eq(order({ ["\u{FF01}"] = block("x = 1"), ["\u{1F5D1}"] = block("y = 2") }),
     "\u{1F5D1}@0 | \u{FF01}@0")
end)

test("harness: a local in one block is not seen in the next", "dm", function()
  local libs = LIBS.dm
  LIBS.dm = {
    { name = "P #1", ref = "P@0", source = "local secret = 1\n__harnessFirst = secret" },
    { name = "P #2", ref = "P@60", source = "__harnessSecond = secret" },
  }
  local good, err = pcall(reset, "dm")
  LIBS.dm = libs
  ok(good, err)
  eq(__harnessFirst, 1)
  eq(__harnessSecond, nil, "the second block saw the first's local")
  __harnessFirst = nil
end)
