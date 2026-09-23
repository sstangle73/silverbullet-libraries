------------------------------------------------------------------ GM Beyond: the party

-- GM: Refresh the Party refreshes every imported character in the folder,
-- one after another, having asked once, and says what changed for each;
-- one that can't be fetched or written doesn't stop the rest. The import
-- records the day it wrote a page, and the live roster reads the imported
-- pages instead of fetching every character from D&D Beyond on each view.

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

-- Bram, Cass, Ilse and Wren imported on the 23rd, and the day moved on.
local function party()
  gmb.today = function() return "2026-09-23" end
  local data = {}
  for _, name in ipairs({ "bram", "cass", "ilse", "wren" }) do
    data[name] = serve(name)
    ok(gmb.import(tostring(data[name].id)), name .. " imported")
  end
  gmb.today = function() return "2026-10-01" end
  return data
end

test("beyond: Refresh the Party asks once, refreshes each character and says what changed", "dm", function()
  local data = party()
  local before = {}
  for name, text in pairs(H.pages) do before[name] = text end
  data.bram.baseHitPoints = 40
  data.bram.classes[1].level = 4
  data.ilse.baseHitPoints = 31
  -- Cass is private now: D&D Beyond answers 404
  H.responses[gmb.endpoint .. "1003"] = { ok = true, status = 404 }
  H.confirms = { true }
  local writes = #H.writes
  editor.invokeCommand("GM: Refresh the Party")
  eq(#H.confirmsAsked, 1, "one question")
  eq(H.confirmsAsked[1], "Refresh 4 characters from D&D Beyond: Bram Holloway, Cass Ironwood, Ilse Marrow, " ..
    "Wren Ashdown? Each page's keys from D&D Beyond are rewritten, and nothing else: its text, the keys you " ..
    "added and those its keep lists stay as they are.")
  local n = lastNotification()
  eq(n.message, "Bram Holloway 5→6, HP 68→76, +Ability Score Improvement, Str 15→17, Str save +6→+7, " ..
    "Longsword +5→+6 to hit and 1d8+2→1d8+3 Slashing, Unarmed Strike +5→+6 to hit and 3→4 Bludgeoning, " ..
    "and 1 more; " ..
    "Cass Ironwood couldn't be fetched: private or deleted; Ilse Marrow, HP 35→36; Wren Ashdown unchanged.")
  eq(n.kind, "warning", "one couldn't be refreshed")
  has(H.pages["Characters/Bram Holloway"], "\nlevel: 6\n")
  has(H.pages["Characters/Ilse Marrow"], "\nhp: 36\n")
  has(H.pages["Characters/Wren Ashdown"], '\nddb_refreshed: "2026-10-01"\n', "checked today")
  eq(H.pages["Characters/Cass Ironwood"], before["Characters/Cass Ironwood"])
  eq(#H.writes, writes + 3)
  -- Undo puts back the pages the refresh changed, and not one changed since
  H.pages["Characters/Ilse Marrow"] = H.pages["Characters/Ilse Marrow"] .. "\nNotes.\n"
  runAction(n, "Undo")
  eq(H.pages["Characters/Bram Holloway"], before["Characters/Bram Holloway"])
  has(H.pages["Characters/Ilse Marrow"], "\nhp: 36\n")
  eq(lastNotification().message, "Undone: 1 page is as it was. Characters/Ilse Marrow has changed since, " ..
    "so Undo left it as it is.")
end)

test("beyond: a character the party refresh can't write is left, and the rest go on", "dm", function()
  local data = party()
  data.bram.classes[1].level = 1         -- down to level 3
  data.cass.classes = {}                 -- no class at all
  data.ilse.baseHitPoints = 31
  H.pages["Characters/Wren Ashdown"] = (H.pages["Characters/Wren Ashdown"]:gsub("\nddb: 1004\n", "\nddb: 9999\n"))
  H.confirms = { true }
  local report = gmb.refreshParty()
  eq(table.concat(report, "; "), "Bram Holloway would go from level 5 to 3, so it was left as it is " ..
    "(refresh it on its own to take the lower level); Cass Ironwood was left as it is: D&D Beyond sent it " ..
    "with no class; Ilse Marrow, HP 35→36; Wren Ashdown couldn't be fetched: private or deleted")
  has(H.pages["Characters/Bram Holloway"], "\nlevel: 5\n")
  has(H.pages["Characters/Ilse Marrow"], "\nhp: 36\n")
  eq(#H.confirmsAsked, 1, "nothing asked but the once")
end)

test("beyond: Refresh the Party declined, or with no one to refresh, does nothing", "dm", function()
  local data = party()
  data.bram.baseHitPoints = 40
  local fetched, writes = #H.fetched, #H.writes
  H.confirms = { false }
  eq(gmb.refreshParty(), nil)
  eq(#H.fetched, fetched, "nothing fetched")
  eq(#H.writes, writes)
  config.set("gmBeyond", { folder = "Party/" })
  eq(gmb.refreshParty(), nil)
  eq(lastNotification().message, "GM Beyond: no page in Party/ has a D&D Beyond character to refresh.")
  eq(#H.confirmsAsked, 1)
end)

test("beyond: the import records the day it wrote the page", "dm", function()
  serve("cass")
  gmb.today = function() return "2026-09-23" end
  local page = gmb.import("1003")
  local d = yaml.parse(H.pages[page]:match("^%-%-%-\n(.-)\n%-%-%-\n"))
  eq(d.ddb_refreshed, "2026-09-23", "a date written as text, which every reader keeps as text")
  ok(gmb.owned.ddb_refreshed and gmb.owned.ddb_written, "the import's own keys")
end)

test("beyond: the roster is built from the imported pages, without a fetch", "dm", function()
  local data = party()
  local fetched = #H.fetched
  eq(gmb.summary(1001), "Bram Holloway — Hill Dwarf Fighter 3 / Wizard 2, level 5, refreshed 2026-09-23")
  eq(gmb.summary(1003), "Cass Ironwood — Human Fighter 7, refreshed 2026-09-23")
  eq(#H.fetched, fetched, "nothing fetched")
  -- from a query's page, as the docs have it
  local rows = __liq(function() return index.pages() end, function(p) return p.type == "pc" and p.ddb end,
    { { fn = function(p) return p.name end, desc = false } }, function(p) return gmb.summary(p) end, nil)
  eq(table.concat(rows, " | "), "Bram Holloway — Hill Dwarf Fighter 3 / Wizard 2, level 5, refreshed 2026-09-23 | " ..
    "Cass Ironwood — Human Fighter 7, refreshed 2026-09-23 | " ..
    "Ilse Marrow — Human Monk 2 / Bard 2 / Warlock 1, level 5, refreshed 2026-09-23 | " ..
    "Wren Ashdown — Human Fighter 4, refreshed 2026-09-23")
  eq(#H.fetched, fetched)
  -- a character with no imported page is fetched, as before
  serve("sorrel")
  eq(gmb.summary(1005), "Sorrel Fenwick — Wood Elf Rogue 3")
  eq(#H.fetched, fetched + 1)
  -- and a page of the GM's own with only the number
  H.pages["Party/Sam"] = "---\ntype: pc\nplayer: Sam\nddb: 1005\n---\n"
  eq(gmb.summary(1005), "Sorrel Fenwick — Wood Elf Rogue 3")
  eq(gmb.liveSummary(1001), "Bram Holloway — Hill Dwarf Fighter 3 / Wizard 2", "live, always")
  eq(gmb.summary(nil), "_(private or unreachable)_")
end)

test("beyond: the roster escapes what the page holds", "dm", function()
  local data = serve("bram")
  data.race.fullName = "Hill *Dwarf* #deep"
  data.classes[1].definition.name = "[[Fighter]]"
  local page = gmb.import("1001")
  local line = gmb.summary(1001)
  eq(line, [==[Bram Holloway — Hill \*Dwarf\* \#deep \[\[Fighter\]\] 3 / Wizard 2, level 5, refreshed ]==] ..
    gmb.today())
  -- a page renamed by hand keeps its own name in the roster, as on its sheet
  H.pages["Characters/Brammy"] = H.pages[page]
  H.pages[page] = nil
  has(gmb.summary(1001), "Brammy — ")
end)
