------------------------------------------------------------------ GM Kit: characters at the table
-- A character's page (type pc) gets a bar that counts what runs out in
-- play: hit points, death saves, spell slots, Pact Magic, resources, Hit
-- Point Dice and Heroic Inspiration, with a Short Rest and a Long Rest.
-- What has gone is play state in State/Characters/<name>; the character's
-- own page is never written to.

local BRAM = "Party/Bram"
local RECORD = "State/Characters/Bram"
local SCENE2 = "Adventure/Campaign/Act I/Scene 2"

-- Bram, a fighter who has started on wizardry: 28 hit points, five Hit
-- Point Dice of two sizes, two levels of slots, and three resources that
-- come back three different ways.
local SHEET = table.concat({
  "---",
  "type: pc",
  "player: Sam",
  "level: 5",
  "class: Fighter 3 / Wizard 2",
  "con: 14",
  "hp: 28",
  "hit_dice: 3d10 + 2d6",
  "slots: [3, 1]",
  "resources:",
  "  - {name: Second Wind, uses: 2, reset: Short Rest}",
  "  - {name: Arcane Recovery, uses: 1, reset: Long Rest}",
  "  - {name: Lucky Coin, uses: 3, reset: Dawn}",
  "---",
  "",
  "# Bram",
  "",
  "A miller's son from Fordtown.",
  "",
}, "\n")

-- Wren, a warlock: Pact Magic and nothing else that runs out but hit points.
local WREN = "Party/Wren"
local WREN_SHEET = "---\ntype: pc\nlevel: 3\nhp: 21\nhit_dice: 3d8\npact_slots: 2\npact_level: 2\n---\n\n# Wren\n"

local function bram()
  H.pages[BRAM] = SHEET
  H.current = BRAM
end

-- The row of a bar that goes by `name`.
local function row(bar, name)
  local function find(node)
    if type(node) ~= "table" then return nil end
    if node.tag == "div" and node.attrs.class == "gmkit-item" then
      local first = node.children[1]
      if type(first) == "table" and first.tag == "strong" and textOf(first) == name then return node end
    end
    for _, c in ipairs(node.children or {}) do
      local f = find(c)
      if f then return f end
    end
  end
  local found = find(bar.html or bar)
  if not found then error("no row " .. name .. " in: " .. textOf(bar.html or bar)) end
  return found
end

local function state(key)
  return gm.frontmatter(H.pages[RECORD] or "")[key]
end

test("kit track: a character's page gets a bar of its own, and only a character's", "dm", function()
  bram()
  local bar = gm.topBar()
  ok(bar, "Bram's page has a bar")
  eq(bar.display, "block")
  local text = textOf(bar.html)
  has(text, "Session 1 28 of 28 hit points")
  eq(list(buttonsOf(bar.html)),
     "Damage… | Temporary… | Spend | Spend | Use | Use | Use | Spend | Give | Short Rest… | Long Rest",
     "nothing to heal or regain yet")
  has(textOf(row(bar, "Level 1 slots")), "●●● 3 of 3 left")
  has(textOf(row(bar, "Level 2 slots")), "● 1 of 1 left")
  has(textOf(row(bar, "Second Wind")), "●● 2 of 2 left · Short Rest")
  has(textOf(row(bar, "Lucky Coin")), "●●● 3 of 3 left · Dawn")
  has(textOf(row(bar, "Hit Point Dice")), "●●●●● 5 of 5 left · 3d10 + 2d6")
  has(textOf(row(bar, "Heroic Inspiration")), "◇ No")
  hasnt(text, "Play state", "nothing recorded yet")
  hasnt(text, "Death saves", "not at 0 hit points")
  -- the page's other bars and the other pages keep theirs
  for _, page in ipairs({ "The Party", "Session Table", "index", "State/Revealed", SCENE2,
                          "Sessions/Session 1", "Library/Storie/GM Kit" }) do
    eq(gm.characterBar(page), nil, page)
  end
  H.current = SCENE2
  eq(list(buttonsOf(gm.topBar().html)), "Reveal | Mark planned | Mark started | Mark found",
     "an adventure page's bar as it was")
  -- SilverBullet's hook draws it, beside GM Beyond's own where there is one
  H.current = BRAM
  local drawn = 0
  for _, b in ipairs(dispatch("hooks:renderTopWidgets")) do
    if b.html and textOf(b.html):find("28 of 28 hit points", 1, true) then drawn = drawn + 1 end
  end
  eq(drawn, 1)
end)

test("kit track: a character's bar asks the server about no page that isn't there", "dm", function()
  bram()
  H.metaMisses = 0
  ok(gm.characterBar(BRAM))
  gm.damage(BRAM, 3)
  H.metaMisses = 0
  ok(gm.characterBar(BRAM))
  eq(H.metaMisses, 0)
end)

test("kit track: damage takes temporary hit points first, with undo", "dm", function()
  bram()
  ok(gm.temporary(BRAM, 5))
  eq(lastNotification().message, "Bram: gained 5 temporary hit points.")
  eq(state("temp_hp"), "5")
  ok(gm.damage(BRAM, 8))
  local n = lastNotification()
  eq(n.message, "Bram: took 8 damage, 5 of it temporary, 25 of 28 hit points left.")
  eq(state("temp_hp"), nil, "gone, so not written")
  eq(state("hp_lost"), "3")
  has(H.pages[RECORD], "- [[Sessions/Session 1|Session 1]]: gained 5 temporary hit points\n" ..
    "- [[Sessions/Session 1|Session 1]]: took 8 damage, 5 of it temporary, 25 of 28 hit points left\n")
  local bar = gm.characterBar(BRAM)
  has(textOf(bar.html), "Session 1 25 of 28 hit points")
  hasnt(textOf(bar.html), "temporary")
  ok(list(buttonsOf(bar.html)):startsWith("Damage… | Heal… | Temporary… | "), "hurt, so Heal…")
  runAction(n, "Undo")
  eq(lastNotification().message, "Undone: Bram's 8 damage")
  eq(state("temp_hp"), "5")
  eq(state("hp_lost"), nil)
  hasnt(H.pages[RECORD], "took 8 damage")
  has(textOf(gm.characterBar(BRAM).html), "28 of 28 hit points +5 temporary")
  eq(H.pages[BRAM], SHEET, "the character's page is never written to")
end)

test("kit track: undo takes back its own change, and leaves the ones since", "dm", function()
  bram()
  gm.damage(BRAM, 6)
  local first = lastNotification()
  -- the record the first change made goes with it, while nothing else is in it
  runAction(first, "Undo")
  eq(H.pages[RECORD], nil, "the record it made is gone")
  gm.damage(BRAM, 6)
  first = lastNotification()
  gm.damage(BRAM, 4)
  eq(state("hp_lost"), "10")
  runAction(first, "Undo")
  eq(state("hp_lost"), "4", "the second 4 stays")
  hasnt(H.pages[RECORD], "took 6 damage")
  has(H.pages[RECORD], "took 4 damage")
  -- an undo finds the record as it is, and stays within the page's numbers
  gm.heal(BRAM, 50)
  eq(state("hp_lost"), nil)
  local healed = lastNotification()
  eq(healed.message, "Bram: healed 50, 28 of 28 hit points.")
  gm.damage(BRAM, 2)
  runAction(healed, "Undo")
  eq(state("hp_lost"), "6", "the 4 the healing took off come back, on top of the 2 since")
  eq(lastNotification().message, "Undone: Bram's healing of 50")
end)

test("kit track: at 0 hit points, death saves; three made is stable, three failed is dead", "dm", function()
  bram()
  gm.damage(BRAM, 30)
  eq(lastNotification().message, "Bram: took 30 damage, down to 0 hit points.")
  local bar = gm.characterBar(BRAM)
  has(textOf(bar.html), "0 of 28 hit points ▲ Dying")
  local saves = row(bar, "Death saves")
  eq(textOf(saves), "Death saves ○○○ 0 of 3 successes ○○○ 0 of 3 failures Success Failure")
  click(saves, "Success")
  eq(lastNotification().message, "Bram: made a death save, 1 of 3.")
  click(row(gm.characterBar(BRAM), "Death saves"), "Failure")
  eq(textOf(row(gm.characterBar(BRAM), "Death saves")),
     "Death saves ✓○○ 1 of 3 successes ✗○○ 1 of 3 failures Success Failure")
  gm.deathSave(BRAM, true)
  gm.deathSave(BRAM, true)
  eq(lastNotification().message, "Bram: made a death save, 3 of 3: stable.")
  eq(state("death_failures"), nil, "stable, the failures start again")
  bar = gm.characterBar(BRAM)
  has(textOf(bar.html), "0 of 28 hit points ■ Stable")
  hasnt(textOf(bar.html), "Death saves", "a stable character makes no more")
  eq(gm.deathSave(BRAM, false), false)
  eq(lastNotification().message, "Bram is stable.")
  -- damage at 0 is a failed death save, and a stable character is dying again
  gm.damage(BRAM, 2)
  eq(lastNotification().message, "Bram: took 2 damage at 0 hit points: a death save failed, 1 of 3.")
  eq(state("death_successes"), nil)
  has(textOf(gm.characterBar(BRAM).html), "▲ Dying")
  gm.deathSave(BRAM, false)
  gm.deathSave(BRAM, false)
  eq(lastNotification().message, "Bram: failed a death save, 3 of 3: dead.")
  bar = gm.characterBar(BRAM)
  has(textOf(bar.html), "0 of 28 hit points † Dead")
  hasnt(textOf(bar.html), "Death saves")
  eq(gm.damage(BRAM, 5), false)
  eq(lastNotification().message, "Bram is dead.")
  -- hit points, from a spell that brings the dead back, start them afresh
  gm.heal(BRAM, 1)
  eq(lastNotification().message, "Bram: healed 1, 1 of 28 hit points, back from the dead.")
  eq(state("death_failures"), nil)
  eq(state("death_successes"), nil)
  eq(state("hp_lost"), "27")
end)

test("kit track: undoing the save that made a character stable puts their failures back", "dm", function()
  bram()
  gm.damage(BRAM, 28)
  gm.deathSave(BRAM, false)
  for _ = 1, 3 do gm.deathSave(BRAM, true) end
  eq(state("death_failures"), nil)
  runAction(lastNotification(), "Undo")
  eq(state("death_successes"), "2")
  eq(state("death_failures"), "1")
  has(textOf(row(gm.characterBar(BRAM), "Death saves")), "✓✓○ 2 of 3 successes ✗○○ 1 of 3 failures")
end)

test("kit track: healing a character at 0 wakes them, and undo puts the saves back", "dm", function()
  bram()
  gm.damage(BRAM, 28)
  gm.deathSave(BRAM, true)
  gm.deathSave(BRAM, false)
  gm.heal(BRAM, 4)
  local n = lastNotification()
  eq(n.message, "Bram: healed 4, 4 of 28 hit points, conscious again.")
  hasnt(H.pages[RECORD], "death_")
  runAction(n, "Undo")
  eq(state("death_successes"), "1")
  eq(state("death_failures"), "1")
  eq(state("hp_lost"), "28")
  eq(gm.heal(BRAM, 0), false, "no healing, no change")
end)

test("kit track: damage as much as the hit point maximum kills", "dm", function()
  bram()
  gm.damage(BRAM, 55)
  eq(lastNotification().message, "Bram: took 55 damage, down to 0 hit points.",
     "27 left over, one short of 28")
  gm.heal(BRAM, 28)
  gm.damage(BRAM, 56)
  eq(lastNotification().message, "Bram: took 56 damage, down to 0 hit points with as much again left over: dead.")
  eq(state("death_failures"), "3")
  runAction(lastNotification(), "Undo")
  eq(state("death_failures"), nil)
  eq(state("hp_lost"), nil)
  gm.damage(BRAM, 28)
  gm.damage(BRAM, 28)
  eq(lastNotification().message, "Bram: took 28 damage at 0 hit points, as much as their hit point maximum: dead.")
end)

test("kit track: temporary hit points don't add up, and 0 takes them away", "dm", function()
  bram()
  gm.temporary(BRAM, 5)
  eq(gm.temporary(BRAM, 3), false)
  eq(lastNotification().message, "Bram keeps the 5 temporary hit points they have: temporary hit points " ..
     "don't add up, and a character keeps the higher.")
  gm.temporary(BRAM, 8)
  eq(lastNotification().message, "Bram: gained 8 temporary hit points, in place of 5.")
  gm.temporary(BRAM, 0)
  eq(lastNotification().message, "Bram: lost 8 temporary hit points.")
  eq(state("temp_hp"), nil)
  -- asked for from the bar
  H.prompts = { "6" }
  click(gm.characterBar(BRAM), "Temporary…")
  has(H.promptsAsked[1], "How many temporary hit points does Bram gain?")
  eq(state("temp_hp"), "6")
end)

test("kit track: the bar asks how much, and a cancel or a word changes nothing", "dm", function()
  bram()
  H.prompts = { "7" }
  click(gm.characterBar(BRAM), "Damage…")
  eq(H.promptsAsked[1], "How much damage does Bram take?")
  eq(state("hp_lost"), "7")
  H.prompts = { NIL }
  click(gm.characterBar(BRAM), "Heal…")
  eq(H.promptsAsked[2], "How many hit points does Bram regain?")
  eq(state("hp_lost"), "7", "cancelled")
  H.prompts = { "lots" }
  click(gm.characterBar(BRAM), "Damage…")
  eq(lastNotification().message, "“lots” isn't a whole number")
  eq(lastNotification().kind, "warning")
  eq(state("hp_lost"), "7")
  H.prompts = { "  " }
  click(gm.characterBar(BRAM), "Damage…")
  eq(state("hp_lost"), "7", "nothing said, nothing done")
end)

test("kit track: spell slots, level by level, spent and regained", "dm", function()
  bram()
  click(row(gm.characterBar(BRAM), "Level 1 slots"), "Spend")
  eq(lastNotification().message, "Bram: a level 1 slot spent, 2 of 3 left.")
  eq(state("slot_1_used"), "1")
  local slots = row(gm.characterBar(BRAM), "Level 1 slots")
  eq(textOf(slots), "Level 1 slots ●●○ 2 of 3 left Spend Regain")
  gm.slot(BRAM, 2, true)
  eq(textOf(row(gm.characterBar(BRAM), "Level 2 slots")), "Level 2 slots ○ 0 of 1 left Regain")
  eq(gm.slot(BRAM, 2, true), false)
  eq(lastNotification().message, "Bram has no level 2 slots left.")
  click(row(gm.characterBar(BRAM), "Level 2 slots"), "Regain")
  eq(lastNotification().message, "Bram: a level 2 slot regained, 1 of 1 left.")
  eq(gm.slot(BRAM, 2, false), false)
  eq(lastNotification().message, "Bram has all 1 level 2 slot already.")
  eq(gm.slot(BRAM, 4, true), false)
  eq(lastNotification().message, "Bram has no level 4 slots on the page to count.")
  -- the aria labels say which slot each button spends
  local labels = {}
  for _, b in ipairs(slots.children) do
    if b.tag == "button" then labels[#labels + 1] = b.attrs["aria-label"] end
  end
  eq(list(labels), "Spend a level 1 slot | Regain a level 1 slot")
  eq(slots.children[2].attrs["aria-hidden"], "true", "the circles are for the eye")
end)

test("kit track: slots written as a map, and Pact Magic", "dm", function()
  H.pages[BRAM] = SHEET:gsub("slots: %[3, 1%]", "slots: {1: 4, 3: 2}")
  local bar = gm.characterBar(BRAM)
  has(textOf(row(bar, "Level 1 slots")), "●●●● 4 of 4 left")
  has(textOf(row(bar, "Level 3 slots")), "●● 2 of 2 left")
  hasnt(textOf(bar.html), "Level 2 slots")
  H.pages[WREN] = WREN_SHEET
  bar = gm.characterBar(WREN)
  eq(textOf(row(bar, "Pact Magic, level 2")), "Pact Magic, level 2 ●● 2 of 2 left Spend")
  hasnt(textOf(bar.html), "slots")
  click(row(bar, "Pact Magic, level 2"), "Spend")
  eq(lastNotification().message, "Wren: a Pact Magic slot spent, 1 of 2 left.")
  eq(gm.frontmatter(H.pages["State/Characters/Wren"]).pact_used, "1")
end)

test("kit track: resources, used and regained, and what each rest brings back", "dm", function()
  bram()
  H.pages[BRAM] = SHEET:gsub("slots: %[3, 1%]", "slots: [3, 1]\npact_slots: 1")
  click(row(gm.characterBar(BRAM), "Second Wind"), "Use")
  eq(lastNotification().message, "Bram: Second Wind used, 1 of 2 left.")
  eq(state("used_second_wind"), "1")
  gm.resource(BRAM, "used_second_wind", true)
  eq(gm.resource(BRAM, "used_second_wind", true), false)
  eq(lastNotification().message, "Bram has no uses of Second Wind left.")
  gm.resource(BRAM, "used_arcane_recovery", true)
  gm.resource(BRAM, "used_lucky_coin", true)
  gm.pact(BRAM, true)
  gm.slot(BRAM, 1, true)
  gm.hitDie(BRAM, true)
  gm.temporary(BRAM, 4)
  -- a Short Rest: Pact Magic and what comes back after one
  ok(gm.shortRest(BRAM, 0, 0))
  eq(lastNotification().message, "Bram: Short Rest: Pact Magic's slots and Second Wind back.")
  eq(state("used_second_wind"), nil)
  eq(state("pact_used"), nil)
  eq(state("used_arcane_recovery"), "1")
  eq(state("used_lucky_coin"), "1")
  eq(state("slot_1_used"), "1")
  eq(state("hit_dice_spent"), "1")
  eq(gm.shortRest(BRAM, 0, 0), false, "nothing more for it to bring back")
  eq(lastNotification().message, "Bram has nothing for a Short Rest to bring back.")
  -- a Long Rest: the rest, but not what comes back at dawn
  gm.resource(BRAM, "used_second_wind", true)
  gm.damage(BRAM, 10)
  ok(gm.longRest(BRAM))
  eq(lastNotification().message, "Bram: Long Rest: all 28 hit points, every spell slot, Second Wind, " ..
     "Arcane Recovery and 1 Hit Point Die back.")
  for _, key in ipairs({ "hp_lost", "temp_hp", "slot_1_used", "used_second_wind", "used_arcane_recovery",
                         "hit_dice_spent" }) do
    eq(state(key), nil, key)
  end
  eq(state("used_lucky_coin"), "1", "Dawn is no rest")
  click(row(gm.characterBar(BRAM), "Lucky Coin"), "Regain")
  eq(state("used_lucky_coin"), nil)
  -- and a rest has its undo, as everything does
  gm.slot(BRAM, 1, true)
  gm.longRest(BRAM)
  runAction(lastNotification(), "Undo")
  eq(state("slot_1_used"), "1")
  eq(lastNotification().message, "Undone: Bram's Long Rest")
end)

test("kit track: a Long Rest ends temporary hit points", "dm", function()
  bram()
  gm.temporary(BRAM, 4)
  gm.longRest(BRAM)
  eq(lastNotification().message, "Bram: Long Rest: temporary hit points gone.")
  eq(state("temp_hp"), nil)
end)

test("kit track: a Short Rest asks about Hit Point Dice when there is healing to do", "dm", function()
  bram()
  -- whole, it asks nothing
  gm.slot(BRAM, 1, true)
  eq(gm.shortRest(BRAM), false)
  eq(#H.promptsAsked, 0)
  gm.damage(BRAM, 20)
  H.prompts = { "2", "13" }
  click(row(gm.characterBar(BRAM), "Rest"), "Short Rest…")
  eq(H.promptsAsked[1], "How many Hit Point Dice does Bram spend? 5 of 5 left, 3d10 + 2d6; 0 for none.")
  eq(H.promptsAsked[2], "How many hit points does Bram regain? Roll the 2 dice, adding +2 to each for Constitution.")
  eq(lastNotification().message, "Bram: Short Rest: 2 Hit Point Dice spent for 13 hit points, 21 of 28 hit points.")
  eq(state("hit_dice_spent"), "2")
  eq(state("hp_lost"), "7")
  has(textOf(row(gm.characterBar(BRAM), "Hit Point Dice")), "●●●○○ 3 of 5 left")
  -- none, or more than there are
  H.prompts = { "0" }
  gm.resource(BRAM, "used_second_wind", true)
  gm.shortRest(BRAM)
  eq(lastNotification().message, "Bram: Short Rest: Second Wind back.")
  H.prompts = { "9", "20" }
  gm.shortRest(BRAM)
  has(H.promptsAsked[#H.promptsAsked], "Roll the 3 dice")
  eq(state("hit_dice_spent"), "5", "no more than there were")
  eq(state("hp_lost"), nil)
  -- a cancel is no rest
  gm.damage(BRAM, 5)
  gm.hitDie(BRAM, false)
  local before = H.pages[RECORD]
  H.prompts = { NIL }
  eq(gm.shortRest(BRAM), false)
  eq(H.pages[RECORD], before)
  H.prompts = { "1", NIL }
  eq(gm.shortRest(BRAM), false)
  eq(H.pages[RECORD], before)
end)

test("kit track: a rest needs at least 1 hit point", "dm", function()
  bram()
  gm.slot(BRAM, 1, true)
  gm.damage(BRAM, 28)
  eq(gm.longRest(BRAM), false)
  eq(lastNotification().message, "Bram has 0 hit points, and a Long Rest needs at least 1: heal them first.")
  eq(gm.shortRest(BRAM), false, "and asks nothing")
  eq(lastNotification().message, "Bram has 0 hit points, and a Short Rest needs at least 1: heal them first.")
  eq(state("slot_1_used"), "1")
end)

test("kit track: a Long Rest gives back every Hit Point Die, or half with longRestDice", "dm", function()
  bram()
  for _ = 1, 5 do ok(gm.hitDie(BRAM, true)) end
  eq(gm.hitDie(BRAM, true), false)
  eq(lastNotification().message, "Bram has no Hit Point Dice left.")
  gm.longRest(BRAM)
  eq(lastNotification().message, "Bram: Long Rest: 5 Hit Point Dice back.")
  eq(state("hit_dice_spent"), nil)
  gm.config.longRestDice = "half"
  for _ = 1, 5 do gm.hitDie(BRAM, true) end
  gm.longRest(BRAM)
  eq(lastNotification().message, "Bram: Long Rest: 2 Hit Point Dice back.", "half of five, rounded down")
  eq(state("hit_dice_spent"), "3")
  gm.hitDie(BRAM, false)
  gm.hitDie(BRAM, false)
  gm.longRest(BRAM)
  eq(lastNotification().message, "Bram: Long Rest: 1 Hit Point Die back.", "never more than were spent")
  gm.config.longRestDice = "all"
end)

test("kit track: Heroic Inspiration, given and used, and no rest touches it", "dm", function()
  bram()
  click(row(gm.characterBar(BRAM), "Heroic Inspiration"), "Give")
  eq(lastNotification().message, "Bram: gained Heroic Inspiration.")
  eq(state("inspiration"), "true")
  local inspired = row(gm.characterBar(BRAM), "Heroic Inspiration")
  eq(textOf(inspired), "Heroic Inspiration ◆ Yes Use")
  eq(gm.inspiration(BRAM, true), false)
  eq(lastNotification().message, "Bram has Heroic Inspiration already.")
  gm.damage(BRAM, 3)
  gm.longRest(BRAM)
  eq(state("inspiration"), "true")
  click(inspired, "Use")
  eq(state("inspiration"), nil)
  runAction(lastNotification(), "Undo")
  eq(state("inspiration"), "true")
  eq(lastNotification().message, "Undone: Bram's use of Heroic Inspiration")
end)

test("kit track: the most of each is the page's: GM Sheets' sums, or the page alone", "dm", function()
  -- no hit_dice: as many as the level, which GM Sheets reads
  H.pages[BRAM] = SHEET:gsub("hit_dice: [^\n]*\n", "")
  local c = gm.character(BRAM)
  eq(c.level, 5)
  eq(c.con, 2)
  eq(c.dice.most, 5)
  eq(c.dice.text, nil)
  eq(c.hp, 28)
  eq(#c.resources, 3)
  local withSheets = textOf(gm.characterBar(BRAM).html)
  has(withSheets, "Hit Point Dice ●●●●● 5 of 5 left Spend")
  local loaded = sheets
  sheets = nil
  local without = textOf(gm.characterBar(BRAM).html)
  sheets = loaded
  eq(without, withSheets, "the same without GM Sheets")
  -- a page YAML can't be read from counts what its lines give
  local parse = yaml.parse
  yaml.parse = function() error("YAML: bad indentation") end
  local good, err = pcall(function()
    local flat = gm.characterBar(BRAM)
    has(textOf(flat.html), "28 of 28 hit points")
    has(textOf(flat.html), "⚠ The page's frontmatter doesn't parse as YAML, so only its plain keys count")
    hasnt(textOf(flat.html), "Second Wind", "a resource needs YAML")
    has(textOf(row(flat, "Level 1 slots")), "3 of 3 left")
    has(textOf(row(flat, "Hit Point Dice")), "5 of 5 left")
  end)
  yaml.parse = parse
  if not good then error(err, 0) end
end)

test("kit track: play state goes to State/Characters, as a record of its own", "dm", function()
  bram()
  eq(gm.characterPath(BRAM), RECORD)
  gm.damage(BRAM, 5)
  gm.slot(BRAM, 1, true)
  gm.inspiration(BRAM, true)
  eq(H.pages[RECORD], table.concat({
    "---",
    "type: character-state",
    'subject: "[[Party/Bram]]"',
    "hp_lost: 5",
    "slot_1_used: 1",
    "inspiration: true",
    "---",
    "",
    "# Bram",
    "",
    "Play state for [[Party/Bram]]: what has gone since the character was last whole, kept by GM Kit.",
    "",
    "## Log",
    "",
    "- [[Sessions/Session 1|Session 1]]: took 5 damage, 23 of 28 hit points left",
    "- [[Sessions/Session 1|Session 1]]: a level 1 slot spent, 2 of 3 left",
    "- [[Sessions/Session 1|Session 1]]: gained Heroic Inspiration",
    "",
  }, "\n"))
  eq(H.pages[BRAM], SHEET, "the character's page is never written to")
  eq(H.pages["Sessions/Session 1"], nil, "a hit point is no line in the session's log")
  has(textOf(gm.characterBar(BRAM).html), "[[" .. RECORD .. "|Play state]]")
  -- the lists of the adventure's play state leave it out
  local records = __liq(function() return index.pages() end,
    function(p) return p.type == "state-record" end, {}, nil, nil)
  eq(#records, 0)
end)

test("kit track: a character renamed keeps its play state", "dm", function()
  bram()
  gm.damage(BRAM, 6)
  -- SilverBullet's rename moves the page and rewrites the subject's link
  local renamed = "Party/Bram Holloway"
  H.pages[renamed] = SHEET
  H.pages[BRAM] = nil
  H.pages[RECORD] = H.pages[RECORD]:gsub("%[%[Party/Bram%]%]", "[[Party/Bram Holloway]]")
  has(textOf(gm.characterBar(renamed).html), "22 of 28 hit points")
  gm.damage(renamed, 2)
  eq(state("hp_lost"), "8", "the record it had")
  eq(H.pages["State/Characters/Bram Holloway"], nil, "and no second one")
end)

test("kit track: what the page names stays words", "dm", function()
  H.pages[BRAM] = SHEET:gsub("Second Wind", '"<b>Rage</b> [[Trap]]"')
  local bar = gm.characterBar(BRAM)
  local rage = row(bar, "<b>Rage</b> [[Trap]]")
  ok(rage.children[1].raw, "the name is text, not Markdown or HTML")
  has(rage.children[1].outerHTML, "&lt;b&gt;Rage&lt;/b&gt; [[Trap]]")
  click(rage, "Use")
  eq(lastNotification().message, "Bram: <b>Rage</b> [[Trap]] used, 1 of 2 left.")
  has(H.pages[RECORD], "Session 1]]: \\<b\\>Rage\\</b\\> \\[\\[Trap\\]\\] used, 1 of 2 left\n")
end)

test("kit track: a character with nothing to count says so", "dm", function()
  H.pages[BRAM] = "---\ntype: pc\nplayer: Sam\n---\n\n# Bram\n"
  local bar = gm.characterBar(BRAM)
  has(textOf(bar.html), "Nothing on the page to count: give it hp, hit_dice, slots, pact_slots or resources")
  eq(list(buttonsOf(bar.html)), "Give | Short Rest… | Long Rest")
  eq(gm.damage(BRAM, 3), false)
  eq(lastNotification().message, "Bram has no hit points on the page to count.")
end)

test("kit track: whatever number it is given, it counts in whole ones", "dm", function()
  H.pages[BRAM] = SHEET:gsub("hp: 28", "hp: 28.0")
  gm.damage(BRAM, 2.5)
  eq(lastNotification().message, "Bram: took 2 damage, 26 of 28 hit points left.")
  gm.heal(BRAM, "1")
  eq(state("hp_lost"), "1")
  ok(gm.slot(BRAM, 1.0, true))
  eq(state("slot_1_used"), "1")
  eq(gm.slot(BRAM, "first", true), false)
  ok(gm.shortRest(BRAM, 1.0, 3.7))
  eq(state("hit_dice_spent"), "1")
  eq(state("hp_lost"), nil)
end)

test("kit track: every change on the bar has undo", "dm", function()
  bram()
  gm.damage(BRAM, 10)
  gm.temporary(BRAM, 3)
  local before = H.pages[RECORD]
  local steps = {
    function() gm.damage(BRAM, 4) end,
    function() gm.heal(BRAM, 2) end,
    function() gm.temporary(BRAM, 9) end,
    function() gm.slot(BRAM, 1, true) end,
    function() gm.resource(BRAM, "used_second_wind", true) end,
    function() gm.hitDie(BRAM, true) end,
    function() gm.inspiration(BRAM, true) end,
    function() gm.shortRest(BRAM, 1, 6) end,
    function() gm.longRest(BRAM) end,
  }
  for i, step in ipairs(steps) do
    step()
    local n = lastNotification()
    ok(n.options and n.options.actions, "step " .. i .. " has undo: " .. n.message)
    runAction(n, "Undo")
    eq(H.pages[RECORD], before, "step " .. i .. " undone: " .. n.message)
  end
end)

test("kit track: a tab that opens straight onto a character's page draws the bar as the character stands", "dm", function()
  bram()
  ok(gm.damage(BRAM, 6))
  -- a tab just opened: the client's list of pages hasn't loaded, so it knows
  -- of no page at all, and the bar is drawn only now
  H.known = {}
  local bar = gm.topBar()
  settle()
  ok(bar, "a bar, though the client's list knows no page yet")
  local text = textOf(bar.html)
  has(text, "22 of 28 hit points", "the damage recorded, not a whole character")
  has(text, "Play state")
end)
