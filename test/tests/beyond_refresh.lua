------------------------------------------------------------------ GM Beyond: refreshing

-- A refresh or a second import rewrites the keys the import owns and
-- nothing else: not a key the GM added, not a comment, not what is typed
-- into the page and not yet saved, and not a page it can't be sure of.

local BRAM_LINK = "https://www.dndbeyond.com/characters/1001/AbCdEf"
local ILSE_LINK = "https://www.dndbeyond.com/characters/1002"

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

-- Run fn with a SilverBullet API replaced, and put it back however fn ends.
local function replacing(tbl, key, with, fn)
  local was = tbl[key]
  tbl[key] = with
  local good, err = pcall(fn)
  tbl[key] = was
  if not good then error(err, 0) end
end

test("beyond: the keys the import owns are exactly the keys it can write", "dm", function()
  -- the made-up characters, and one with what none of them has: Advantage,
  -- a bonus to each passive and to spells, and a weapon's mastery
  local sink = copy(DDB.ilse.data)
  for _, m in ipairs({
    { type = "advantage", subType = "dexterity-saving-throws" },
    { type = "bonus", subType = "passive-perception", value = 1 },
    { type = "bonus", subType = "passive-insight", value = 1 },
    { type = "bonus", subType = "passive-investigation", value = 1 },
    { type = "bonus", subType = "spell-save-dc", value = 1 },
    { type = "bonus", subType = "spell-attacks", value = 1 },
    { type = "weapon-mastery", subType = "quarterstaff", friendlySubtypeName = "Topple (Quarterstaff)" },
  }) do
    m.restriction = ""
    table.insert(sink.modifiers.feat, m)
  end
  local written = {}
  local characters = { sink }
  for _, name in ipairs({ "bram", "ilse", "cass", "wren", "sorrel" }) do characters[#characters + 1] = DDB[name].data end
  for _, c in ipairs(characters) do
    for _, e in ipairs(gmb.sheet(copy(c))) do written[e[1]] = true end
  end
  for key in pairs(written) do ok(gmb.owned[key], key .. " is written but not owned") end
  for key in pairs(gmb.owned) do ok(written[key], key .. " is owned, but the import never writes it") end
end)

test("beyond: a refresh keeps a loadout and a proficiency bonus written by hand", "dm", function()
  local data = serve("bram")
  local page = gmb.import(BRAM_LINK)
  H.pages[page] = (H.pages[page]:gsub("\nddb: 1001\n",
    "\npb: 4\nkit:\n  label: Travelling\n  ac: 15\nddb: 1001\n"))
  data.baseHitPoints = 40
  eq(gmb.refresh(page), page)
  has(H.pages[page], "\npb: 4\nkit:\n  label: Travelling\n  ac: 15\n")
  has(H.pages[page], "\nhp: 70\n")
end)

test("beyond: a refresh keeps a comment and a key YAML reads with quotes or spaces", "dm", function()
  local data = serve("bram")
  local page = gmb.import(BRAM_LINK)
  local text = H.pages[page]
  text = (text:gsub("\nlevel: 5\n", "\nlevel: 5\n# the DM's own note\nreal name: Bramwell Holloway\n" ..
    "\"shadow hook\": the ferryman\n'debt': 30 gp\nallies:\n- Sam\n- Mara\n"))
  -- a list at the left edge under a key the import owns, a comment inside it,
  -- and a key of the import's in quotes
  text = (text:gsub("\nsaves: %[str, con%]\n", "\nsaves:\n# proficient\n- str\n- con\n"))
  text = (text:gsub("\nhp: 68\n", "\n\"hp\": 99\n"))
  H.pages[page] = text
  data.baseHitPoints = 40
  gmb.refresh(page)
  local after = H.pages[page]
  has(after, "\n# the DM's own note\nreal name: Bramwell Holloway\n\"shadow hook\": the ferryman\n'debt': 30 gp\n" ..
    "allies:\n- Sam\n- Mara\n")
  hasnt(after, "# proficient")
  hasnt(after, "\"hp\"")
  local d = yaml.parse(frontmatter(after))
  eq(d["real name"], "Bramwell Holloway")
  eq(d["shadow hook"], "the ferryman")
  eq(d.debt, "30 gp")
  eq(table.concat(d.allies, ", "), "Sam, Mara")
  eq(table.concat(d.saves, ", "), "str, con")
  eq(d.hp, 70)
end)

test("beyond: a character renamed on D&D Beyond is found by its number", "dm", function()
  local data = serve("bram")
  local page = gmb.import(BRAM_LINK)
  H.pages[page] = H.pages[page] .. "\nOwes the ferryman.\n"
  data.name = "Bram the Bold"
  data.baseHitPoints = 40
  eq(gmb.import(BRAM_LINK), page, "the page it has")
  eq(H.pages["Characters/Bram the Bold"], nil, "no second page")
  has(H.pages[page], "\nhp: 70\n")
  has(H.pages[page], "Owes the ferryman.")
  local n = lastNotification()
  has(n.message, "Refreshed Characters/Bram Holloway from D&D Beyond: Bram the Bold, level 5.")
  has(n.message, "The name has changed on D&D Beyond; the page keeps its own.")
  local pcs = 0
  for _, text in pairs(H.pages) do
    if text:find("\nddb: 1001\n", 1, true) then pcs = pcs + 1 end
  end
  eq(pcs, 1, "GM Party counts one character")
end)

test("beyond: of two pages with the character's number, the one named for it is refreshed", "dm", function()
  local data = serve("bram")
  local page = gmb.import(BRAM_LINK)
  local older = "---\ntype: pc\nddb: 1001\nlevel: 5\n---\n\n# Bram, before\n"
  H.pages["Characters/Bram (before)"] = older
  data.baseHitPoints = 40
  eq(gmb.import(BRAM_LINK), page)
  has(H.pages[page], "\nhp: 70\n")
  eq(H.pages["Characters/Bram (before)"], older)
end)

test("beyond: a page that can't be looked at isn't written over", "dm", function()
  serve("bram")
  local page = "Characters/Bram Holloway"
  local mine = "---\ntype: pc\nplayer: Sam\n---\n\n# Bram Holloway\n\nThe DM's notes.\n"
  H.pages[page] = mine
  H.failMeta = { [page] = "TypeError: Failed to fetch" }
  eq(gmb.import(BRAM_LINK), nil)
  has(lastNotification().message, "couldn't tell whether Characters/Bram Holloway exists (")
  has(lastNotification().message, "Failed to fetch), so nothing was written.")
  eq(lastNotification().kind, "error")
  eq(H.pages[page], mine)
end)

test("beyond: a page that is there but can't be read isn't written over", "dm", function()
  serve("bram")
  local page = "Characters/Bram Holloway"
  local mine = "---\ntype: pc\nddb: 1001\nplayer: Sam\n---\n\n# Bram Holloway\n\nThe DM's notes.\n"
  H.pages[page] = mine
  local real = space.readPage
  replacing(space, "readPage", function(n)
    if n == page then error("TypeError: Failed to fetch") end
    return real(n)
  end, function()
    eq(gmb.import(BRAM_LINK), nil)
  end)
  has(lastNotification().message, "couldn't read Characters/Bram Holloway, so nothing was written.")
  eq(H.pages[page], mine)
end)

test("beyond: Undo takes away only what the import wrote", "dm", function()
  local data = serve("ilse")
  local page = gmb.import(ILSE_LINK)
  local imported = lastNotification()
  H.pages[page] = H.pages[page] .. "\nThe DM's notes.\n"
  runAction(imported, "Undo")
  has(H.pages[page], "The DM's notes.", "a page with something of the GM's in it stays")
  has(lastNotification().message, "has changed since, so Undo left it as it is")
  -- a refresh's Undo, the same
  data.baseHitPoints = 31
  gmb.refresh(page)
  local refreshed = lastNotification()
  H.pages[page] = H.pages[page] .. "More notes.\n"
  runAction(refreshed, "Undo")
  has(H.pages[page], "\nhp: 36\n")
  has(H.pages[page], "More notes.")
end)

test("beyond: a refresh saves what is typed into the open page first", "dm", function()
  local data = serve("bram")
  local page = gmb.import(BRAM_LINK)
  H.current = page
  data.baseHitPoints = 40
  local url = gmb.endpoint .. "1001"
  local answer = H.responses[url]
  local savedBeforeFetch
  H.responses[url] = function()
    savedBeforeFetch = H.saves > 0
    return answer
  end
  replacing(editor, "save", function()
    H.saves = H.saves + 1
    -- what was typed while the fetch was out reaches the page
    H.pages[page] = H.pages[page] .. "\nTyped while it fetched.\n"
  end, function()
    eq(gmb.refresh(page), page)
  end)
  eq(savedBeforeFetch, false, "fetched first, then saved")
  eq(H.saves, 1)
  has(H.pages[page], "\nhp: 70\n")
  has(H.pages[page], "Typed while it fetched.")
  eq(H.reloads, 1, "then the editor shows what was written")
  -- a page that isn't open has nothing to save
  H.current = "index"
  data.baseHitPoints = 41
  gmb.refresh(page)
  eq(H.saves, 1)
  eq(H.reloads, 1)
end)

test("beyond: a refresh stops if what is typed into the page can't be saved", "dm", function()
  local data = serve("bram")
  local page = gmb.import(BRAM_LINK)
  local before = H.pages[page]
  H.current = page
  data.baseHitPoints = 40
  replacing(editor, "save", function() error("Could not save page") end, function()
    eq(gmb.refresh(page), nil)
  end)
  has(lastNotification().message, "couldn't save what is typed into Characters/Bram Holloway first")
  eq(H.pages[page], before)
  eq(H.reloads, 0)
end)

test("beyond: a character sent with no class isn't written", "dm", function()
  local data = serve("bram")
  local page = gmb.import(BRAM_LINK)
  local before = H.pages[page]
  data.classes = {}
  eq(gmb.refresh(page), nil)
  has(lastNotification().message, "with no class, so the page is left as it is")
  eq(lastNotification().kind, "error")
  eq(H.pages[page], before)
  eq(gmb.import(BRAM_LINK), nil)
  has(lastNotification().message, "D&D Beyond sent character 1001 with no class, so nothing was written")
  eq(H.pages[page], before)
  H.pages[page] = nil
  eq(gmb.import(BRAM_LINK), nil)
  eq(H.pages[page], nil, "nor is a page made from it")
end)

test("beyond: a refresh that would drop the level asks first", "dm", function()
  local data = serve("bram")
  local page = gmb.import(BRAM_LINK)
  local before = H.pages[page]
  data.classes[1].level = 1  -- fighter 1 / wizard 2: level 3
  H.confirms = { false }
  eq(gmb.refresh(page), nil)
  has(H.confirmsAsked[1], "D&D Beyond has Bram Holloway at level 3, and Characters/Bram Holloway says level 5.")
  has(lastNotification().message, "Characters/Bram Holloway is left at level 5.")
  eq(H.pages[page], before)
  H.confirms = { true }
  eq(gmb.refresh(page), page)
  has(H.pages[page], "\nlevel: 3\n")
  -- a level that rises needs no asking
  data.classes[1].level = 3
  eq(gmb.refresh(page), page)
  eq(#H.confirmsAsked, 2)
  has(H.pages[page], "\nlevel: 5\n")
end)
