------------------------------------------------------------------ GM Beyond: spells and armor

-- Three more made-up characters in D&D Beyond's shape, in test/ddb/: Cass,
-- a human fighter 7 whose Eldritch Knight subclass casts, Wren, a fighter
-- whose 2024 Acolyte background grants Magic Initiate, and Sorrel, a wood
-- elf rogue with the Elven Lineage's cantrip. None of their classes casts a
-- spell itself. The numbers they should come out at are worked out here by
-- hand, as for Bram and Ilse in tests/beyond.lua.

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

local function spellNamed(list, name)
  for _, e in ipairs(list or {}) do if e.name == name then return e end end
  error("no spell " .. name .. " in " .. names(list))
end

test("beyond: an Eldritch Knight casts with the subclass's ability and slots", "dm", function()
  serve("cass")
  local page = gmb.import("1003")
  eq(page, "Characters/Cass Ironwood")
  local d, v = values(page)
  eq(d.class, "Fighter")
  eq(d.subclass, "Eldritch Knight")
  eq(d.level, 7)
  eq(v.pb, 3)
  eq(d.spellcasting, "int", "the subclass's Intelligence, since the fighter casts nothing")
  eq(v.spellDC, 14)
  eq(v.spellAttack, 6)
  eq(joined(d.slots), "4, 2", "a third caster's own table at fighter 7")
  eq(d.pact_slots, nil)
  eq(names(d.cantrips), "Fire Bolt, Light")
  eq(d.cantrips[2].material, "a firefly or phosphorescent moss")
  eq(names(d.spells["1"]), "Magic Missile, Shield")
  eq(names(d.spells["2"]), "Blur")
  eq(d.spells["2"][1].concentration, true)
  eq(d.always_prepared, nil)
  eq(d.spellbook, nil)
  local bolt = attack(d, "Fire Bolt")
  eq(bolt.hit, 6, "Intelligence +3 and the proficiency bonus")
  eq(bolt.damage, "2d10 Fire")
  eq(bolt.notes, "120 ft.")
  eq(names(d.attacks), "Longsword, Fire Bolt, Unarmed Strike")
  eq(d.ac, 16)
  eq(d.hp, 80)
  eq(joined(d.saves), "str, con")
  eq(joined(d.skills), "athletics, intimidation, perception")
  eq(names(d.features), "Fighting Style, Second Wind, Action Surge, Martial Archetype, Spellcasting, " ..
    "War Bond, Ability Score Improvement, Extra Attack, War Magic")
end)

test("beyond: an Eldritch Knight who is a wizard too has the multiclass table's slots", "dm", function()
  local data = serve("cass")
  local wizard = copy(DDB.bram.data.classes[2])
  wizard.id = 7002
  table.insert(data.classes, wizard)
  local d, v = values(gmb.import("1003"))
  eq(d.class, "Fighter 7 / Wizard 2")
  eq(v.pb, 4)
  eq(d.spellcasting, "int")
  -- a third of seven, rounded down, and the wizard's two: caster level 4
  eq(joined(d.slots), "4, 3")
end)

test("beyond: a fighter with Magic Initiate from a 2024 background keeps its spells", "dm", function()
  serve("wren")
  local page = gmb.import("1004")
  local d, v = values(page)
  eq(d.class, "Fighter")
  eq(d.background, "Acolyte")
  eq(d.spellcasting, "wis", "the ability Magic Initiate was taken with")
  eq(v.spellDC, 12)
  eq(v.spellAttack, 4)
  eq(d.slots, nil, "a fighter has no slots of its own")
  eq(names(d.cantrips), "Guidance, Sacred Flame")
  eq(names(d.always_prepared["1"]), "Bless")
  local bless = d.always_prepared["1"][1]
  eq(bless.material, "a Holy Symbol worth 5+ GP")
  eq(bless.concentration, true)
  eq(bless.range, "30 ft.")
  eq(bless.notes, nil, "cast with the sheet's own ability")
  local flame = attack(d, "Sacred Flame")
  eq(flame.hit, "DC 12 Dex", "a Dexterity save against Wisdom's DC")
  eq(flame.damage, "1d8 Radiant")
  eq(names(d.attacks), "Warhammer, Sacred Flame, Unarmed Strike")
  eq(joined(d.tools), "Calligrapher's Supplies")
  -- and a refresh keeps them: the import owns these keys
  H.pages[page] = H.pages[page] .. "\nNotes.\n"
  gmb.refresh(page)
  d = values(page)
  eq(names(d.cantrips), "Guidance, Sacred Flame")
  eq(names(d.always_prepared["1"]), "Bless")
end)

test("beyond: a wood elf rogue keeps her species' cantrip and spell", "dm", function()
  serve("sorrel")
  local d, v = values(gmb.import("1005"))
  eq(d.species, "Wood Elf")
  eq(d.class, "Rogue")
  eq(d.subclass, "Thief")
  eq(joined({ d.str, d.dex, d.con, d.int, d.wis, d.cha }), "10, 16, 14, 12, 14, 10")
  eq(d.spellcasting, "wis")
  eq(v.spellDC, 12)
  eq(names(d.cantrips), "Druidcraft")
  eq(names(d.always_prepared["1"]), "Longstrider", "the lineage's level 3 spell")
  eq(d.slots, nil)
  eq(d.speed, 35)
  eq(joined(d.senses), "Darkvision 60 ft.")
  eq(joined(d.expertise), "stealth")
  eq(joined(d.skills), "perception, sleight_of_hand")
  eq(d.ac, 14)
  eq(attack(d, "Dagger").hit, 5)
  eq(attack(d, "Shortbow").notes, "Ammunition, Two-Handed; 80/320 ft.")
end)

test("beyond: a spell cast with its own ability is rolled with it, and says so", "dm", function()
  local data = serve("bram")
  -- Magic Initiate taken with Wisdom by an Intelligence caster
  data.spells.feat = { copy(DDB.wren.data.spells.feat[2]) }
  local d, v = values(gmb.import("1001"))
  eq(d.spellcasting, "int", "the wizard's, as before")
  eq(v.spellDC, 12)
  -- Wisdom 11 is +0: DC 8 + 3 + 0, not the wizard's 12
  eq(attack(d, "Sacred Flame").hit, "DC 11 Dex")
  eq(spellNamed(d.cantrips, "Sacred Flame").notes, "Wis: DC 11, +3 to hit")
  eq(spellNamed(d.cantrips, "Fire Bolt").notes, nil)
  eq(attack(d, "Fire Bolt").hit, 4, "the wizard's own cantrip with Intelligence")
end)

test("beyond: an item's spells come while it is attuned, and name the item", "dm", function()
  local data = serve("cass")
  local staff = {
    id = 90001, quantity = 1, equipped = true, isAttuned = true,
    definition = { id = 777, name = "Staff of Embers", filterType = "Staff", type = "Staff",
      canAttune = true, canEquip = true, isConsumable = false, grantedModifiers = {} },
  }
  table.insert(data.inventory, staff)
  -- and one known by the inventory entry's own id, its definition having none
  table.insert(data.inventory, {
    id = 90002, quantity = 1, equipped = true, isAttuned = false,
    definition = { name = "Wand of Sparks", filterType = "Wand", type = "Wand",
      canAttune = false, canEquip = true, isConsumable = false, grantedModifiers = {} },
  })
  data.spells.item = { {
    prepared = false, alwaysPrepared = false, countsAsKnownSpell = false, componentId = 777,
    definition = { name = "Burning Hands", level = 1, activation = { activationTime = 1, activationType = 1 },
      range = { origin = "Self", aoeType = "Cone", aoeValue = 15 }, components = { 1, 2 },
      componentsDescription = "", ritual = false, concentration = false, modifiers = {} },
  }, {
    prepared = false, alwaysPrepared = false, countsAsKnownSpell = false, componentId = 90002,
    definition = { name = "Mage Hand", level = 0, activation = { activationTime = 1, activationType = 1 },
      range = { origin = "Ranged", rangeValue = 30 }, components = { 1, 2 }, componentsDescription = "",
      modifiers = {} },
  } }
  local page = gmb.import("1003")
  local d = values(page)
  local hands = spellNamed(d.always_prepared["1"], "Burning Hands")
  eq(hands.notes, "from Staff of Embers")
  eq(hands.range, "Self (15 ft. Cone)")
  eq(spellNamed(d.cantrips, "Mage Hand").notes, "from Wand of Sparks")
  -- no longer attuned, the staff's spell goes, and the wand's stays
  staff.isAttuned = false
  H.confirms = { true }
  gmb.refresh(page)
  has(H.confirmsAsked[1], "Takes away Burning Hands.")
  d = values(page)
  eq(d.always_prepared, nil)
  eq(spellNamed(d.cantrips, "Mage Hand").notes, "from Wand of Sparks")
end)

test("beyond: a class's spells without a class ability still come in", "dm", function()
  -- a class feature's spell, as an invocation gives, with no ability of its own
  local data = serve("wren")
  data.spells.feat = {}
  data.spells.class = { {
    prepared = false, alwaysPrepared = true, countsAsKnownSpell = false, componentId = 905,
    definition = { name = "Disguise Self", level = 1, activation = { activationTime = 1, activationType = 1 },
      range = { origin = "Self" }, components = { 1, 2 }, componentsDescription = "", modifiers = {} },
  } }
  local d = values(gmb.import("1004"))
  eq(names(d.always_prepared["1"]), "Disguise Self")
  eq(d.spellcasting, nil, "no ability anywhere to cast it with")
  eq(d.cantrips, nil)
end)

-- Ilse is a monk, whose Unarmored Defense adds Wisdom: with Dexterity 8 and
-- Wisdom 15 her AC is 10 - 1 + 2.
test("beyond: a negative Dexterity counts against Unarmored Defense", "dm", function()
  local data = serve("ilse")
  data.stats[2].value = 7   -- 8 with the species' +1
  data.stats[5].value = 14  -- 15 with the species' +1
  local d = values(gmb.import("1002"))
  eq(d.dex, 8)
  eq(d.wis, 15)
  eq(d.ac, 11)
end)

test("beyond: a barbarian's Unarmored Defense with Dexterity 8 and Constitution 16", "dm", function()
  local data = serve("ilse")
  data.stats[2].value = 7
  data.stats[3].value = 16
  data.modifiers.class[1].statId = 3  -- Constitution, as a barbarian's
  local d = values(gmb.import("1002"))
  eq(d.con, 16)
  eq(d.ac, 12)
end)

test("beyond: a maximum Dexterity of 0 leaves a negative Dexterity out too", "dm", function()
  local data = serve("ilse")
  data.stats[2].value = 7
  data.stats[5].value = 14
  table.insert(data.modifiers.class, { type = "set", subType = "ac-max-dex-modifier", value = 0,
    fixedValue = 0, restriction = "", componentId = 301, availableToMulticlass = true })
  local d = values(gmb.import("1002"))
  eq(d.ac, 12, "10 + 0 + Wisdom's 2")
end)
