------------------------------------------------------------------ GM Beyond: what a player chose

-- Three more made-up characters in D&D Beyond's shape, in test/ddb/, with
-- what a player chooses on D&D Beyond beyond the class and the scores:
-- Vesper, a tiefling warlock 5 with Eldritch Invocations and a pact boon;
-- Rook, a human Battle Master 5 with a Fighting Style and maneuvers; and
-- Nell, a dragonborn sorcerer 3 with Metamagic, a draconic ancestry and a
-- feat's element. D&D Beyond sends a chosen option, with its rules, in
-- `options`, and every choice, made or not, in `choices`, the options it
-- was chosen from in `choices.choiceDefinitions`; and what a player adds by
-- hand in `customProficiencies`, `customSenses`, `customSpeeds` and
-- `characterValues`. The numbers are worked out here by hand.

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

local function named(t, name)
  for _, x in ipairs(t or {}) do if x.name == name then return x end end
  error("nothing named " .. name .. " in " .. names(t))
end

test("beyond: a warlock's invocations and pact boon are features, each with its rules", "dm", function()
  serve("vesper")
  local page = gmb.import("1006")
  eq(page, "Characters/Vesper Quill")
  local d, v = values(page)
  eq(d.class, "Warlock")
  eq(d.subclass, "The Fiend")
  eq(joined({ d.str, d.dex, d.con, d.int, d.wis, d.cha }), "10, 14, 14, 11, 12, 18")
  eq(v.spellDC, 15, "8, +3 and Charisma's +4")
  eq(names(d.features), "Pact Magic, Otherworldly Patron, Dark One's Blessing, Eldritch Invocations, " ..
    "Eldritch Invocations: Agonizing Blast, Eldritch Invocations: Devil's Sight, Pact Boon, " ..
    "Pact Boon: Pact of the Tome, Ability Score Improvement",
    "each after the feature it was chosen for; the subclass and a skill have keys of their own; " ..
    "an option of a level-9 feature waits for level 9")
  eq(named(d.features, "Eldritch Invocations: Agonizing Blast").text,
    "Agonizing Blast, made up for the tests: your Charisma on each beam.\n")
  eq(joined(d.skills), "arcana, deception")
  -- her legacy is an option with rules, named like a language she speaks;
  -- the language she picked is a label alone, and already in her languages
  eq(names(d.traits), "Darkvision, Hellish Resistance, Fiendish Legacy, Fiendish Legacy: Infernal")
  eq(named(d.traits, "Fiendish Legacy: Infernal").text, "Infernal, made up for the tests: fire, and the hells.\n")
  has(joined(d.languages), "Infernal")
end)

test("beyond: Agonizing Blast adds Charisma to its cantrip's damage", "dm", function()
  local data = serve("vesper")
  local d = values(gmb.import("1006"))
  local blast = named(d.attacks, "Eldritch Blast")
  eq(blast.hit, 7, "+3 and Charisma's +4")
  eq(blast.damage, "1d10+4 Force", "each beam's d10, and Charisma")
  eq(blast.notes, "120 ft.")
  -- the 2024 invocation names its cantrip
  data.options.class[1].definition.name = "Agonizing Blast (Eldritch Blast)"
  H.confirms = { true }
  gmb.refresh("Characters/Vesper Quill")
  d = values("Characters/Vesper Quill")
  eq(named(d.attacks, "Eldritch Blast").damage, "1d10+4 Force")
  has(names(d.features), "Eldritch Invocations: Agonizing Blast (Eldritch Blast)")
  -- chosen for another cantrip, Eldritch Blast has none of it
  data.options.class[1].definition.name = "Agonizing Blast (Mind Sliver)"
  H.confirms = { true }
  gmb.refresh("Characters/Vesper Quill")
  d = values("Characters/Vesper Quill")
  eq(named(d.attacks, "Eldritch Blast").damage, "1d10 Force")
  -- and without the invocation, none: gone from the options and the choices
  table.remove(data.options.class, 1)
  table.remove(data.choices.class, 1)
  H.confirms = { true }
  gmb.refresh("Characters/Vesper Quill")
  d = values("Characters/Vesper Quill")
  eq(named(d.attacks, "Eldritch Blast").damage, "1d10 Force")
  hasnt(names(d.features), "Agonizing")
end)

test("beyond: Devil's Sight is a sense of its own, beside darkvision and a custom sense", "dm", function()
  local data = serve("vesper")
  local d = values(gmb.import("1006"))
  eq(joined(d.senses), "Darkvision 60 ft., Blindsight 10 ft., Devil's Sight 120 ft.",
    "the tiefling's darkvision, a blindsight the player set on D&D Beyond, and the invocation's sight")
  -- a condition with no option to name it is said as it is
  data.modifiers.class[7].componentTypeId = 12168134
  data.modifiers.class[7].componentId = 502
  H.confirms = { true }
  gmb.refresh("Characters/Vesper Quill")
  d = values("Characters/Vesper Quill")
  eq(joined(d.senses), "Darkvision 60 ft., Blindsight 10 ft., " ..
    "Darkvision 120 ft. (You can see normally in darkness, both magical and nonmagical)")
end)

test("beyond: an option counts once its feature is reached", "dm", function()
  local data = serve("vesper")
  local d = values(gmb.import("1006"))
  -- Improved Pact comes at level 9: its option's +10 speed waits too
  eq(d.speed, "30 ft., Fly 30 ft.", "and a fly speed the player set on D&D Beyond")
  hasnt(names(d.features), "Tome of Ancient Secrets")
  data.classes[1].level = 9
  H.confirms = { true }
  gmb.refresh("Characters/Vesper Quill")
  d = values("Characters/Vesper Quill")
  eq(d.speed, "40 ft., Fly 30 ft.")
  has(names(d.features), "Improved Pact, Improved Pact: Tome of Ancient Secrets")
end)

test("beyond: languages and tools a player adds by hand come in", "dm", function()
  local data = serve("vesper")
  local d = values(gmb.import("1006"))
  eq(joined(d.languages), "Common, Draconic, Infernal, Old Marsh Cant",
    "Draconic picked from D&D Beyond's list, Old Marsh Cant written in")
  eq(joined(d.tools), "Chess Set")
  -- one not proficient, a language already known, and one D&D Beyond knows only by a number
  table.insert(data.customProficiencies, { name = "Lute", type = 2, proficiencyLevel = 1 })
  table.insert(data.customProficiencies, { name = "Chess Set", type = 2, proficiencyLevel = 4 })
  table.insert(data.customProficiencies, { name = "infernal", type = 3 })
  table.insert(data.characterValues, { typeId = 35, value = 3, valueId = "999", valueTypeId = "906033267" })
  table.insert(data.characterValues, { typeId = 35, value = 1, valueId = "3", valueTypeId = "906033267" })
  H.confirms = { true }
  gmb.refresh("Characters/Vesper Quill")
  d = values("Characters/Vesper Quill")
  eq(joined(d.languages), "Common, Draconic, Infernal, Old Marsh Cant")
  eq(joined(d.tools), "Chess Set, Chess Set (Expertise)")
end)

test("beyond: a fighter's style and maneuvers are features, and the style's bonus counts", "dm", function()
  serve("rook")
  local page = gmb.import("1007")
  local d, v = values(page)
  eq(d.subclass, "Battle Master")
  eq(names(d.features), "Fighting Style, Fighting Style: Archery, Second Wind, Weapon Mastery, Action Surge, " ..
    "Martial Archetype, Combat Superiority, Combat Superiority: Riposte, Combat Superiority: Precision Attack, " ..
    "Combat Superiority: Trip Attack, Student of War, Ability Score Improvement, Extra Attack",
    "the mastery, the tool, the feat and the skill chosen have keys of their own")
  eq(named(d.attacks, "Longbow").hit, 8, "Dexterity +3, +3, and Archery's +2")
  eq(named(d.attacks, "Longsword").hit, 5, "Archery is for ranged attacks")
  eq(joined(d.masteries), "Sap (Longsword), Slow (Longbow)")
  eq(names(d.feats), "Alert")
  eq(names(d.traits), "Resourceful, Skillful, Versatile")
  eq(joined(d.skills), "athletics, perception, stealth")
  eq(v.pb, 3)
end)

test("beyond: a skill of the player's own, a custom speed and firearms come in", "dm", function()
  local data = serve("rook")
  local d = values(gmb.import("1007"))
  eq(joined(d.tools), "Riverlore (Wis +5), Smith's Tools", "Wisdom +1, +3 and the player's own +1")
  eq(d.speed, 35, "the speed the player set, over the species' 30")
  eq(joined(d.weapons), "Simple, Martial, Firearms")
  -- the skill with Expertise, half proficiency or a total the player set
  data.customProficiencies[1].proficiencyLevel = 4
  data.customProficiencies[1].miscBonus = nil
  table.insert(data.customProficiencies, { name = "Card Sharping", type = 1, statId = 2, proficiencyLevel = 2 })
  table.insert(data.customProficiencies, { name = "Old Roads", type = 1, statId = 4, proficiencyLevel = 3,
    override = 9 })
  table.insert(data.customProficiencies, { name = "No Ability", type = 1, proficiencyLevel = 3 })
  -- a custom sense or speed D&D Beyond numbers as unknown is left out
  data.customSenses = { { senseId = 5, distance = 30 } }
  data.customSpeeds = { { movementId = 9, distance = 90 }, { movementId = 5, distance = 20 } }
  H.confirms = { true }
  gmb.refresh("Characters/Rook Varga")
  d = values("Characters/Rook Varga")
  eq(joined(d.tools), "Card Sharping (Dex +4), Old Roads (Int +9), Riverlore (Wis +7), Smith's Tools")
  eq(d.speed, "30 ft., Swim 20 ft.")
  eq(d.senses, nil)
end)

test("beyond: a sorcerer's metamagic, a choice with rules, an ancestry and a feat's element", "dm", function()
  serve("nell")
  local d = values(gmb.import("1008"))
  eq(names(d.features), "Spellcasting, Innate Sorcery, Font of Magic, Font of Magic: Flexible Casting, " ..
    "Metamagic, Metamagic: Quickened Spell, Metamagic: Twinned Spell, Sorcerer Subclass",
    "a choice not yet made, and the subclass, add nothing")
  eq(named(d.features, "Font of Magic: Flexible Casting").text, "Flexible Casting, made up for the tests.\n")
  eq(names(d.traits), "Draconic Ancestry, Draconic Ancestry: Red, Breath Weapon, Damage Resistance, Darkvision")
  eq(named(d.traits, "Draconic Ancestry: Red").text, nil, "D&D Beyond gives the choice no rules of its own")
  eq(names(d.feats), "Elemental Adept, Elemental Adept: Fire")
  eq(joined(d.senses), "Darkvision 120 ft.", "the player's own range, farther than the species'")
  eq(joined(d.slots), "4, 2")
end)

test("beyond: what a player names in an option or a choice stays words", "dm", function()
  local data = serve("nell")
  data.options.class[1].definition.name = "Quick <img src=x onerror=y>\n---\nhp: 1"
  data.options.class[1].definition.description = '<p>&lt;form action="https://x/"&gt; and ${js.import("x")}</p>'
  data.choices.choiceDefinitions[4].options[1].label = "[[Red]] #dragon"
  local page = gmb.import("1008")
  local text = H.pages[page]
  eq(count("\n" .. text, "\n---\n"), 2, "the frontmatter ends where it should")
  local head = text:match("^%-%-%-\n(.-)\n%-%-%-\n")
  local d = yaml.parse(head)
  eq(d.hp, 20)
  local quick = d.features[6]
  eq(quick.name, "Metamagic: Quick <img src=x onerror=y> --- hp: 1")
  eq(quick.text, [==[\<form action="https://x/"\> and \$\{js.import("x")\}]==] .. "\n")
  eq(d.traits[2].name, "Draconic Ancestry: [[Red]] #dragon")
end)

test("beyond: a character with no options or choices at all is imported as before", "dm", function()
  local data = serve("nell")
  data.options, data.choices, data.customProficiencies, data.customSenses, data.customSpeeds = nil, nil, nil, nil, nil
  data.characterValues = nil
  local d = values(gmb.import("1008"))
  eq(names(d.features), "Spellcasting, Innate Sorcery, Font of Magic, Metamagic, Sorcerer Subclass")
  eq(joined(d.senses), "Darkvision 60 ft.")
end)
