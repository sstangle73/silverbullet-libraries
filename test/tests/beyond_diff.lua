------------------------------------------------------------------ GM Beyond: what a refresh changes

-- Before a refresh writes, it says what would change and asks: the level,
-- HP, AC and spell DC, every other number that moves, what it adds and
-- takes away, and the keys the GM changed by hand that it would write over,
-- which it tells from D&D Beyond's changes by the checksums the import
-- recorded in ddb_written. A page's `keep` holds keys back from it
-- altogether. The notification after says what changed in one line.

local BRAM_LINK = "https://www.dndbeyond.com/characters/1001/AbCdEf"

local function copy(t)
  if type(t) ~= "table" then return t end
  local out = {}
  for k, v in pairs(t) do out[k] = copy(v) end
  return out
end

local function serve(name)
  local body = copy(DDB[name])
  H.responses[gmb.endpoint .. tostring(body.data.id)] = { ok = true, status = 200, body = body }
  return body.data
end

local function frontmatter(text) return text:match("^%-%-%-\n(.-)\n%-%-%-\n") end

-- Bram gains a level of fighter, and its Ability Score Improvement, more
-- Hit Points and two potions, and loses his dagger.
local function levelUp(data)
  data.classes[1].level = 4
  data.baseHitPoints = 44
  table.insert(data.inventory, { quantity = 2, equipped = false, definition = { name = "Potion of Healing",
    filterType = "Potion", canAttune = false, canEquip = false, isConsumable = true, grantedModifiers = {} } })
  table.remove(data.inventory, 5)
end

test("beyond: a refresh says what it changes and asks, and the notification says it in a line", "dm", function()
  local data = serve("bram")
  local page = gmb.import(BRAM_LINK)
  local before = H.pages[page]
  levelUp(data)
  H.confirms = { false }
  eq(gmb.refresh(page), nil)
  eq(H.confirmsAsked[1], "Refresh Characters/Bram Holloway from D&D Beyond? Level 5→6, HP 68→80, Str 15→17, " ..
    "Str save +6→+7, Longsword +5→+6 to hit and 1d8+2→1d8+3 Slashing, Unarmed Strike +5→+6 to hit and " ..
    "3→4 Bludgeoning. Adds Ability Score Improvement, Potion of Healing (2). Takes away Dagger. " ..
    "Rewrites class, hit dice.")
  eq(H.pages[page], before, "declined: nothing written")
  eq(lastNotification().message, "Characters/Bram Holloway is left as it was.")
  H.confirms = { true }
  eq(gmb.refresh(page), page)
  has(H.pages[page], "\nlevel: 6\n")
  eq(lastNotification().message, "Refreshed Characters/Bram Holloway from D&D Beyond: Bram Holloway 5→6, " ..
    "HP 68→80, +Ability Score Improvement, +Potion of Healing (2), −Dagger, Str 15→17, Str save +6→+7, " ..
    "and 3 more.")
end)

test("beyond: AC and spell DC lead the numbers, and a spell learned or lost is named", "dm", function()
  local data = serve("bram")
  local page = gmb.import(BRAM_LINK)
  data.stats[4].value = 15                     -- Intelligence 15: the spell DC goes up
  data.characterValues = { { typeId = 1, value = 22 } }
  table.remove(data.classSpells[1].spells, 3)  -- a spell forgotten
  H.confirms = { true }
  gmb.refresh(page)
  -- the Intelligence save is written, since the ring adds to it; Arcana isn't
  eq(H.confirmsAsked[1], "Refresh Characters/Bram Holloway from D&D Beyond? AC 21→22, spell DC 12→13, " ..
    "Int 13→15, Int save +2→+3, Fire Bolt +4→+5 to hit. Takes away Magic Missile.")
  eq(lastNotification().message, "Refreshed Characters/Bram Holloway from D&D Beyond: Bram Holloway, AC 21→22, " ..
    "spell DC 12→13, −Magic Missile, Int 13→15, Int save +2→+3, Fire Bolt +4→+5 to hit.")
end)

test("beyond: a refresh with nothing new writes only the day, and asks nothing", "dm", function()
  serve("bram")
  gmb.today = function() return "2026-09-23" end
  local page = gmb.import(BRAM_LINK)
  has(H.pages[page], '\nddb_refreshed: "2026-09-23"\n')
  gmb.today = function() return "2026-10-01" end
  local writes = #H.writes
  eq(gmb.refresh(page), page)
  eq(#H.confirmsAsked, 0)
  eq(#H.writes, writes + 1, "the day it was checked")
  has(H.pages[page], '\nddb_refreshed: "2026-10-01"\n')
  has(lastNotification().message, "already up to date")
  -- and the same day again writes nothing at all
  eq(gmb.refresh(page), page)
  eq(#H.writes, writes + 1)
end)

test("beyond: with ask off, a refresh writes without asking and still says what changed", "dm", function()
  local data = serve("bram")
  local page = gmb.import(BRAM_LINK)
  config.set("gmBeyond", { ask = false })
  data.baseHitPoints = 40
  eq(gmb.refresh(page), page)
  eq(#H.confirmsAsked, 0)
  eq(lastNotification().message, "Refreshed Characters/Bram Holloway from D&D Beyond: Bram Holloway, HP 68→70.")
  runAction(lastNotification(), "Undo")
  has(H.pages[page], "\nhp: 68\n")
end)

test("beyond: the keys the GM changed by hand are named before they are written over", "dm", function()
  local data = serve("bram")
  local page = gmb.import(BRAM_LINK)
  local text = H.pages[page]
  -- a number changed, one the import doesn't write added, one taken out
  text = (text:gsub("\nhp: 68\n", "\nhp: 99\n"))
  text = (text:gsub("\nac: 21\n", "\n"))
  text = (text:gsub("\nlevel: 5\n", "\nlevel: 5\ninitiative: 7\n"))
  H.pages[page] = text
  data.baseHitPoints = 40
  H.confirms = { true }
  gmb.refresh(page)
  has(H.confirmsAsked[1], "Writes over what you changed by hand: initiative (you wrote 7), ac (you took it out), " ..
    "hp (you wrote 99).")
  has(H.confirmsAsked[1], "HP 99→70")
  has(lastNotification().message, "HP 99→70")
  has(H.pages[page], "\nhp: 70\nhit_dice:")
  has(H.pages[page], "\nac: 21\n")
  hasnt(H.pages[page], "initiative:")
  -- once written, the page's record matches again: nothing more to name
  data.baseHitPoints = 41
  H.confirms = { true }
  gmb.refresh(page)
  hasnt(H.confirmsAsked[2], "by hand")
end)

test("beyond: a page from before the record can't tell, and says so once", "dm", function()
  local data = serve("bram")
  local page = gmb.import(BRAM_LINK)
  -- as GM Beyond 2.1 wrote it: no record
  H.pages[page] = (H.pages[page]:gsub('\nddb_refreshed: [^\n]*\nddb_written: [^\n]*', ""))
  H.pages[page] = (H.pages[page]:gsub("\nhp: 68\n", "\nhp: 99\n"))
  data.baseHitPoints = 40
  H.confirms = { true, true }
  gmb.refresh(page)
  has(H.confirmsAsked[1], "HP 99→70. (The page has no record yet of what GM Beyond wrote")
  hasnt(H.confirmsAsked[1], "Writes over")
  has(H.pages[page], '\nddb_written: "sum ddb:')
  data.baseHitPoints = 41
  gmb.refresh(page)
  hasnt(H.confirmsAsked[2], "no record")
end)

test("beyond: keep holds the keys it lists as the GM wrote them", "dm", function()
  local data = serve("bram")
  local page = gmb.import(BRAM_LINK)
  local text = H.pages[page]
  text = (text:gsub("\nhp: 68\n", "\nhp: 99\n"))
  text = (text:gsub("\nac: 21\n", "\nac: 12 (with the shield off)\n"))
  text = (text:gsub("\nddb: 1001\n", "\nkeep: [ac, hp, Sleight of Hand]\nddb: 1001\n"))
  H.pages[page] = text
  data.baseHitPoints = 40
  data.stats[1].value = 16
  H.confirms = { true }
  eq(gmb.refresh(page), page)
  local asked = H.confirmsAsked[1]
  has(asked, "Str 15→16")
  hasnt(asked, "HP")
  hasnt(asked, "by hand", "kept, so not written over")
  has(asked, "Leaves as you wrote them, as keep says: ac (D&D Beyond has 21), hp (D&D Beyond has 70).")
  local after = H.pages[page]
  has(after, "\nkeep: [ac, hp, Sleight of Hand]\n")
  has(after, "\nac: 12 (with the shield off)\nhp: 99\nhit_dice:", "in their places")
  has(after, "\nstr: 16\n")
  -- nothing else to do: kept keys alone ask nothing
  eq(gmb.refresh(page), page)
  eq(#H.confirmsAsked, 1)
  has(lastNotification().message, "already up to date")
end)

test("beyond: keep can be a line of names or a list, and keeps a key out", "dm", function()
  local data = serve("bram")
  local page = gmb.import(BRAM_LINK)
  local text = H.pages[page]
  text = (text:gsub("\nhp: 68\n", "\n"))
  text = (text:gsub("\nddb: 1001\n", "\nkeep: hp, speed\nddb: 1001\n"))
  H.pages[page] = text
  data.baseHitPoints = 40
  H.confirms = { true }
  gmb.refresh(page)
  hasnt(H.pages[page], "\nhp:", "kept out")
  has(H.pages[page], "\nspeed: 25\n")
  H.pages[page] = (H.pages[page]:gsub("\nkeep: hp, speed\n", "\nkeep:\n  - hp # mine\n  - \"coins\"\n"))
  eq(gmb.keepOf(H.pages[page]).hp, true)
  eq(gmb.keepOf(H.pages[page]).coins, true)
  eq(gmb.keepOf(H.pages[page]).speed, nil)
  -- a frontmatter that doesn't parse still keeps them
  eq(gmb.keepOf("---\nkeep: [ac\n: :\n---\n").ac, true)
end)

test("beyond: a frontmatter that doesn't parse still asks, naming the keys it rewrites", "dm", function()
  local data = serve("bram")
  local page = gmb.import(BRAM_LINK)
  H.pages[page] = (H.pages[page]:gsub("\nddb: 1001\n", "\nnote: [unclosed\nddb: 1001\n"))
  data.baseHitPoints = 40
  H.confirms = { false }
  eq(gmb.refresh(page), nil)
  has(H.confirmsAsked[1], "Rewrites hp.")
  has(H.confirmsAsked[1], "(The page's frontmatter doesn't parse as YAML, so only the keys it rewrites are named.)")
end)

test("beyond: the record is a checksum of each key as written", "dm", function()
  serve("bram")
  local page = gmb.import(BRAM_LINK)
  local d = yaml.parse(frontmatter(H.pages[page]))
  local record = d.ddb_written
  ok(record:startsWith("sum ddb:"), record:sub(1, 20))
  has(record, " hp:" .. gmb.checksum("hp: 68") .. " ")
  eq(#gmb.checksum("hp: 68"), 6)
  ok(gmb.checksum("hp: 68") ~= gmb.checksum("hp: 69"), "a change shows")
  hasnt(record, "ddb_refreshed:", "the record doesn't hold itself")
  eq(gmb.changeLine("Bram", { unchanged = true }), "Bram unchanged")
end)
