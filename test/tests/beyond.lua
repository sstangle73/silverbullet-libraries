------------------------------------------------------------------ GM Beyond

-- Two made-up characters in D&D Beyond's shape, in test/ddb/: Bram, a
-- fighter-wizard in heavy armor, and Ilse, a monk-bard-warlock with a lucky
-- stone. The numbers each should come out at are worked out here by hand,
-- the way D&D Beyond's own sheet works them out.

local BRAM_LINK = "https://www.dndbeyond.com/characters/1001/AbCdEf"
local ILSE_LINK = "https://www.dndbeyond.com/characters/1002"

local function copy(t)
  if type(t) ~= "table" then return t end
  local out = {}
  for k, v in pairs(t) do out[k] = copy(v) end
  return out
end

-- Serve a character as D&D Beyond's character service would, and return
-- the data to change if a test wants to.
local function serve(name)
  local body = copy(DDB[name])
  H.responses[gmb.endpoint .. tostring(body.data.id)] = { ok = true, status = 200, body = body }
  return body.data
end

local function values(page)
  local d = assert(sheets.read(page))
  return d, sheets.values(d)
end

local function joined(t)
  local out = {}
  for _, x in ipairs(t or {}) do out[#out + 1] = tostring(x) end
  return table.concat(out, ", ")
end

local function names(t)
  local out = {}
  for _, x in ipairs(t or {}) do out[#out + 1] = type(x) == "table" and tostring(x.name) or tostring(x) end
  return table.concat(out, ", ")
end

local function attack(d, name)
  for _, a in ipairs(d.attacks or {}) do if a.name == name then return a end end
  error("no attack " .. name .. " in " .. names(d.attacks))
end

local function resource(d, name)
  for _, r in ipairs(d.resources or {}) do if r.name == name then return r end end
  error("no resource " .. name .. " in " .. names(d.resources))
end

local function frontmatter(text) return text:match("^%-%-%-\n(.-)\n%-%-%-") end

test("beyond: a link or a number names the character", "dm", function()
  eq(gmb.idOf("https://www.dndbeyond.com/characters/1001/AbCdEf"), 1001)
  eq(gmb.idOf("https://www.dndbeyond.com/characters/1001"), 1001)
  eq(gmb.idOf("dndbeyond.com/characters/1001?x=1"), 1001)
  eq(gmb.idOf(" 1001 "), 1001)
  eq(gmb.idOf("https://www.dndbeyond.com/monsters/1001"), nil)
  eq(gmb.idOf(nil), nil)
end)

test("beyond: a fighter-wizard in heavy armor comes out as D&D Beyond works it out", "dm", function()
  serve("bram")
  local page = gmb.import(BRAM_LINK)
  eq(page, "Characters/Bram Holloway")
  local d, v = values(page)
  eq(d.type, "pc")
  eq(d.ddb, 1001)
  eq(d.level, 5)
  eq(d.class, "Fighter 3 / Wizard 2")
  eq(d.subclass, "Champion / Evoker")
  eq(d.species, "Hill Dwarf")
  eq(d.background, "Soldier")
  eq(d.creature_size, "Medium")
  -- the dwarf's +2 Con and +1 Wis; the fighter's level-4 increase isn't reached
  eq(joined({ d.str, d.dex, d.con, d.int, d.wis, d.cha }), "15, 12, 16, 13, 11, 8")
  eq(v.pb, 3)
  -- the fighter's saves, not the wizard's, which a second class doesn't bring
  eq(joined(d.saves), "str, con")
  -- and the ring's +1 on every one
  eq(joined({ v.saves.str, v.saves.dex, v.saves.con, v.saves.int, v.saves.wis, v.saves.cha }), "6, 2, 7, 2, 1, 0")
  eq(joined(d.skills), "athletics, intimidation, perception, survival")
  eq(v.skills.arcana, 1, "the wizard's Arcana doesn't come with a second class")
  eq(v.skills.athletics, 5)
  eq(v.passive.perception, 13)
  eq(v.initiative, 1)
  -- chain mail 16, +1, the Defense style's +1, a shield's 2 and the ring's 1
  eq(d.ac, 21)
  -- 38 rolled, Con +3 a level, the dwarf's 1 a level and Tough's 2
  eq(d.hp, 68)
  eq(d.hit_dice, "3d10 + 2d6")
  eq(d.speed, 25)
  eq(joined(d.senses), "Darkvision 60 ft.")
  eq(joined(d.languages), "Common, Dwarvish")
  eq(joined(d.tools), "Dice Set")
  eq(joined(d.armor_training), "light, medium, heavy, shields")
  eq(joined(d.weapons), "Simple, Martial")
  eq(d.spellcasting, "int")
  eq(v.spellDC, 12)
  eq(v.spellAttack, 4)
  eq(joined(d.slots), "3", "a wizard's own table, since the fighter casts nothing")
  eq(names(d.cantrips), "Fire Bolt")
  eq(d.cantrips[1].range, "120 ft.", "a cantrip is a spell, with how it is cast")
  eq(names(d.spells["1"]), "Magic Missile, Shield")
  eq(names(d.spellbook["1"]), "Detect Magic, Sleep")
  local longsword = attack(d, "Longsword")
  eq(longsword.hit, 5)
  eq(longsword.damage, "1d8+2 Slashing")
  eq(longsword.notes, "Versatile (1d10), Sap")
  local bow = attack(d, "Longbow")
  eq(bow.hit, 4)
  eq(bow.damage, "1d8+1 Piercing")
  eq(bow.notes, "Ammunition, Heavy, Two-Handed, Slow; 150/600 ft.")
  local bolt = attack(d, "Fire Bolt")
  eq(bolt.hit, 4)
  eq(bolt.damage, "2d10 Fire", "a cantrip's dice at level 5")
  eq(attack(d, "Unarmed Strike").damage, "3 Bludgeoning")
  eq(names(d.attacks), "Longsword, Longbow, Fire Bolt, Unarmed Strike", "the dagger isn't in hand")
  eq(resource(d, "Second Wind").uses, 1)
  eq(resource(d, "Second Wind").reset, "Short Rest")
  eq(resource(d, "Arcane Recovery").reset, "Long Rest")
  eq(names(d.features), "Fighting Style, Second Wind, Action Surge, Martial Archetype, Improved Critical, " ..
    "Spellcasting, Arcane Recovery, Arcane Tradition, Military Rank")
  eq(names(d.traits), "Darkvision, Dwarven Resilience", "a trait D&D Beyond hides stays hidden")
  eq(names(d.feats), "Tough")
  eq(joined(d.equipment), "Chain Mail +1, Shield, Longsword, Longbow, Dagger, Ring of Protection, " ..
    "Rations (1 day) (5), Arrows (20), Lucky Coin")
  eq(joined(d.attuned), "Ring of Protection")
  eq(d.coins.sp, 5)
  eq(d.coins.gp, 23)
  eq(d.coins.cp, nil)
end)

test("beyond: a monk-bard-warlock with a lucky stone comes out as D&D Beyond works it out", "dm", function()
  serve("ilse")
  local page = gmb.import(ILSE_LINK)
  local d, v = values(page)
  eq(d.class, "Monk 2 / Bard 2 / Warlock 1")
  eq(d.subclass, nil)
  -- the headband sets Intelligence to 19
  eq(joined({ d.str, d.dex, d.con, d.int, d.wis, d.cha }), "10, 16, 12, 19, 15, 14")
  eq(joined(d.saves), "str, dex", "the monk's, not the bard's Charisma")
  eq(joined({ v.saves.str, v.saves.dex, v.saves.con, v.saves.int, v.saves.wis, v.saves.cha }), "4, 7, 2, 5, 3, 3")
  eq(joined(d.skills), "acrobatics, insight, performance")
  eq(joined(d.expertise), "stealth")
  -- Jack of All Trades' half of +3, and the stone's +1 on every check
  eq(v.skills.arcana, 6)
  eq(v.skills.athletics, 2)
  eq(v.skills.acrobatics, 7)
  eq(v.skills.stealth, 10)
  eq(v.initiative, 5)
  eq(v.passive.perception, 14)
  -- 10, Dex +3 and Wis +2, with no armor on
  eq(d.ac, 15)
  eq(d.hp, 35)
  eq(d.hit_dice, "2d8 + 2d8 + 1d8")
  eq(d.speed, 40, "Unarmored Movement's 10 feet")
  eq(d.spellcasting, "cha")
  eq(v.spellDC, 13)
  eq(joined(d.slots), "3", "the bard's own slots")
  eq(d.pact_slots, 1)
  eq(d.pact_level, 1)
  eq(names(d.cantrips), "Vicious Mockery, Eldritch Blast")
  eq(names(d.spells["1"]), "Healing Word, Hex", "a bard and a warlock know their spells")
  eq(d.spells["1"][2].concentration, true)
  eq(d.spells["1"][2].material, "an eye of newt")
  eq(d.spells["1"][1].time, "Bonus Action")
  local staff = attack(d, "Quarterstaff")
  eq(staff.hit, 6, "a monk weapon with Dexterity")
  eq(staff.damage, "1d6+3 Bludgeoning")
  eq(staff.notes, "Versatile (1d8), Topple")
  eq(attack(d, "Unarmed Strike").damage, "1d6+3 Bludgeoning", "the Martial Arts die")
  eq(attack(d, "Unarmed Strike").hit, 6)
  eq(attack(d, "Eldritch Blast").hit, 5)
  eq(attack(d, "Eldritch Blast").damage, "2d10 Force")
  eq(attack(d, "Vicious Mockery").hit, "DC 13 Wis")
  eq(attack(d, "Vicious Mockery").damage, "2d6 Psychic")
  eq(resource(d, "Bardic Inspiration").uses, 2, "Charisma's +2")
  eq(resource(d, "Focus Points").reset, "Short Rest")
  eq(names(d.features), "Unarmored Defense, Martial Arts, Focus, Unarmored Movement, Spellcasting, " ..
    "Bardic Inspiration, Jack of All Trades, Pact Magic")
  eq(joined(d.attuned), "Stone of Good Luck, Headband of Intellect")
  eq(d.coins, nil, "no coins, no key")
end)

test("beyond: a number the sums give is left for GM Sheets to work out", "dm", function()
  serve("bram")
  local head = frontmatter(H.pages[gmb.import(BRAM_LINK)])
  hasnt(head, "\ninitiative:")
  hasnt(head, "\nathletics:")
  hasnt(head, "\nspell_dc:")
  hasnt(head, "\npassive_perception:")
  has(head, "\nstr_save: 6\n", "the ring's +1 makes the saves differ")
  serve("ilse")
  head = frontmatter(H.pages[gmb.import(ILSE_LINK)])
  has(head, "\ninitiative: 5\n")
  has(head, "\nstealth: 10\n")
  hasnt(head, "\npassive_perception:", "the passive follows from the skill written")
end)

test("beyond: the page is YAML any reader takes, with the sheet under the title", "dm", function()
  serve("bram")
  local page = gmb.import(BRAM_LINK)
  local text = H.pages[page]
  ok(text:startsWith("---\ntype: pc\nddb: 1001\nlevel: 5\n"), text:sub(1, 60))
  has(text, "\n---\n\n# Bram Holloway\n\n${sheets.draw()}\n\n[The character on D&D Beyond](https://www.dndbeyond.com/characters/1001)\n")
  has(text, '\n  - {name: Longsword, hit: 5, damage: 1d8+2 Slashing, notes: "Versatile (1d10), Sap"}\n')
  has(text, "\nhit_dice: 3d10 + 2d6\n")
  has(text, "\n  - name: Second Wind\n    text: |\n      ***Second Wind.*** Catch your breath *twice*, then:\n      - stand\n      - fight\n")
  has(text, '\nequipment: [Chain Mail +1, Shield, Longsword, Longbow, Dagger, Ring of Protection, Rations (1 day) (5), Arrows (20), Lucky Coin]\n')
  has(text, "\ncoins: {sp: 5, gp: 23}\n")
  -- and GM Sheets draws it
  local w = sheets.draw(page)
  has(w.html, "Bram Holloway")
  has(w.markdown, "### Military Rank\n\nSoldiers still salute you, **in the tests**.")
end)

test("beyond: rules text in HTML becomes Markdown", "dm", function()
  eq(gmb.markdown("<p>One.</p><p>Two&nbsp;<strong>bold </strong>then.</p>"), "One.\nTwo **bold** then.")
  eq(gmb.markdown("<p><strong><em>Lead.</em></strong> Text.</p>"), "***Lead.*** Text.")
  eq(gmb.markdown('<p><strong><span class="x">Spell save DC </span></strong>= 8</p>'), "**Spell save DC** = 8")
  eq(gmb.markdown("<ul><li>one</li><li>two</li></ul>"), "- one\n- two")
  eq(gmb.markdown("<table><tr><th>d4</th><th>Result</th></tr><tr><td>1</td><td>A <em>thing</em></td></tr></table>"),
    "| d4 | Result |\n|---|---|\n| 1 | A thing |")
  eq(gmb.markdown("<p>It&rsquo;s 5&#8211;10 &amp; more&hellip;</p>"), "It’s 5–10 & more…")
  eq(gmb.markdown('<p>See <a href="/x">the rules</a>.</p>'), "See the rules.")
  eq(gmb.markdown(nil), "")
end)

test("beyond: a refresh rewrites the import's keys and keeps everything else", "dm", function()
  local data = serve("bram")
  local page = gmb.import(BRAM_LINK)
  -- what a DM adds by hand, and a number of the import's they changed
  local text = H.pages[page]
  text = (text:gsub("\nddb: 1001\n", "\nplayer: Sam\nwant: Courage\nddb: 1001\n"))
  text = (text:gsub("\nhp: 68\n", "\nhp: 99\n"))
  text = text .. "\n## Notes\n\nOwes the ferryman.\n"
  H.pages[page] = text
  -- the character gains Hit Points on D&D Beyond
  data.baseHitPoints = 40
  H.confirms = { true }
  gmb.refresh(page)
  has(H.confirmsAsked[1], "HP 99→70.")
  has(H.confirmsAsked[1], "Writes over what you changed by hand: hp (you wrote 99).")
  local after = H.pages[page]
  has(after, "\nplayer: Sam\nwant: Courage\n")
  has(after, "\nhp: 70\n")
  hasnt(after, "hp: 99")
  has(after, "\n## Notes\n\nOwes the ferryman.\n")
  eq(count(after, "\nattacks:\n"), 1, "each key once")
  has(lastNotification().message, "Refreshed " .. page)
  runAction(lastNotification(), "Undo")
  eq(H.pages[page], text, "Undo puts the page back")
end)

test("beyond: importing a character again refreshes its page", "dm", function()
  serve("bram")
  local page = gmb.import(BRAM_LINK)
  local first = H.pages[page]
  local writes = #H.writes
  eq(gmb.import("1001"), page)
  eq(#H.writes, writes, "nothing to write")
  has(lastNotification().message, "already up to date")
  eq(H.pages[page], first)
end)

test("beyond: a page that is another character's isn't overwritten", "dm", function()
  serve("bram")
  H.pages["Characters/Bram Holloway"] = "---\ntype: pc\nddb: 999\n---\n\n# Bram Holloway\n"
  eq(gmb.import(BRAM_LINK), nil)
  has(lastNotification().message, "another character's page")
  eq(lastNotification().kind, "error")
  eq(H.pages["Characters/Bram Holloway"], "---\ntype: pc\nddb: 999\n---\n\n# Bram Holloway\n")
end)

test("beyond: a character that isn't public says so", "dm", function()
  eq(gmb.import(ILSE_LINK), nil)
  has(lastNotification().message, "D&D Beyond answered 404: the character is private, or has been deleted")
  eq(lastNotification().kind, "error")
  eq(gmb.import("not a link"), nil)
  has(lastNotification().message, "isn't a link to a D&D Beyond character")
end)

test("beyond: what the character's sheet on D&D Beyond overrides, wins", "dm", function()
  local data = serve("bram")
  data.characterValues = { { typeId = 1, value = 19 } }
  data.overrideStats[6].value = 20
  data.overrideHitPoints = 50
  local d = values(gmb.import(BRAM_LINK))
  eq(d.ac, 19)
  eq(d.cha, 20)
  eq(d.hp, 50)
end)

test("beyond: Undo takes a new import away again", "dm", function()
  serve("ilse")
  local page = gmb.import(ILSE_LINK)
  ok(H.pages[page], "written")
  local n = lastNotification()
  eq(joined((function() local t = {} for i, a in ipairs(n.options.actions) do t[i] = a.name end return t end)()), "Open, Undo")
  runAction(n, "Undo")
  eq(H.pages[page], nil)
end)

test("beyond: the folder and a campaign's own keys come from the settings", "dm", function()
  config.set("gmBeyond", { folder = "Party/" })
  config.set("gmSheets", { extras = { { key = "oath", label = "Oath" } } })
  serve("bram")
  local page = gmb.import(BRAM_LINK)
  eq(page, "Party/Bram Holloway")
  ok(H.pages[page]:startsWith("---\ntype: pc\noath:\nddb: 1001\n"), H.pages[page]:sub(1, 40))
end)

test("beyond: an imported page has a bar to refresh it, and nothing else does", "dm", function()
  local data = serve("bram")
  local page = gmb.import(BRAM_LINK)
  local bar = gmb.bar(page)
  ok(bar, "a bar")
  eq(list(buttonsOf(bar.html)), "Refresh from D&D Beyond")
  has(bar.html.outerHTML, 'href="https://www.dndbeyond.com/characters/1001"')
  eq(gmb.bar("index"), nil)
  data.baseHitPoints = 41
  H.confirms = { true }
  click(bar, "Refresh from D&D Beyond")
  has(H.pages[page], "\nhp: 71\n")
end)
