------------------------------------------------------------------ GM Sheets

local NL = string.char(10)
local TAMSIN = "Party/Tamsin Reed"

-- A level 3 ranger, with a little of everything a sheet draws: proficiency
-- and Expertise, Advantage, a second loadout, resources, spells with and
-- without details, and features with titled paragraphs.
local RANGER = [==[---
type: pc
player: Sam
level: 3
class: Ranger
subclass: Hunter
species: Human
background: Guide
creature_size: Medium
str: 12
dex: 16
con: 14
int: 10
wis: 14
cha: 8
saves: [str, dex]
skills: [athletics, nature, perception, stealth, survival]
expertise: [survival]
advantage: [perception]
ac: 15
hp: 28
hit_dice: 3d10
speed: 30
senses: []
languages: [Common, Elvish]
tools: [Herbalism Kit]
armor_training: [light, medium, shields]
weapons: [Simple, Martial]
masteries: [Longbow (Slow), Shortsword (Vex)]
attacks:
  - {name: Longbow, hit: 7, damage: 1d8+3 Piercing, notes: "150/600 ft.; Slow"}
  - {name: Shortsword, hit: 5, damage: 1d6+3 Piercing, notes: "Finesse, Light; Vex"}
kit:
  label: Once the guild outfits her
  ac: 16
  attacks:
    - {name: Longsword, hit: 3, damage: 1d8+1 Slashing}
  equipment: [Scale Mail, Longsword]
resources:
  - {name: Favored Enemy, uses: 2, reset: Long Rest}
  - {name: Healing Pool, uses: 30, reset: Long Rest}
spellcasting: wis
slots: [3]
spells: {1: [Cure Wounds, {name: Goodberry, time: Action, range: Self, material: a sprig of mistletoe}]}
always_prepared: {1: [{name: Hunter's Mark, time: Bonus Action, range: 90 ft., concentration: true}]}
features:
  - name: Favored Enemy
    text: |
      You always have Hunter's Mark prepared, and can cast it twice without a spell slot.
  - name: Deft Explorer
    text: |
      Expertise. You have Expertise in Survival.
      Languages. You know two more languages.
traits:
  - name: Resourceful
    text: |
      You gain Heroic Inspiration each time you finish a Long Rest.
feats:
  - name: Alert
equipment: [Longbow, Shortsword, Quiver (20 arrows)]
coins: {gp: 12, sp: 4}
---

# Tamsin Reed

${sheets.draw()}
]==]

local function page(name, text)
  H.pages[name] = text
  H.current = name
end

local function svgOf(s) return s:match("(<svg.-</svg>)") end

-- Every text the drawing sets, in order, joined by " | ".
local function texts(svg)
  local out = {}
  for t in svg:gmatch("<text[^>]*>([^<]*)</text>") do out[#out + 1] = t end
  return table.concat(out, " | ")
end

test("sheets: the page gives the choices and the sheet does the sums", "dm", function()
  page(TAMSIN, RANGER)
  local d = sheets.read(TAMSIN)
  local v = sheets.values(d)
  eq(v.pb, 2, "a level 3 character's Proficiency Bonus")
  eq(v.mods.dex, 3)
  eq(v.mods.cha, -1)
  eq(v.saves.str, 3, "Strength save: +1, and proficient")
  eq(v.saves.dex, 5, "Dexterity save: +3, and proficient")
  eq(v.saves.con, 2, "Constitution save, not proficient")
  eq(v.skills.athletics, 3)
  eq(v.skills.survival, 6, "Expertise doubles the bonus")
  eq(v.skills.acrobatics, 3, "a skill without proficiency is its ability's modifier")
  eq(v.skillProf.survival, 2)
  eq(v.skillProf.stealth, 1)
  eq(v.skillProf.arcana, 0)
  eq(v.passive.perception, 19, "10, the skill's +4, and 5 for Advantage")
  eq(v.passive.insight, 12)
  eq(v.passive.investigation, 10)
  eq(v.initiative, 3)
  eq(v.spellDC, 12, "8 + 2 + Wisdom's 2")
  eq(v.spellAttack, 4)
end)

test("sheets: a number the page writes beats the sums", "dm", function()
  page(TAMSIN, (RANGER:gsub("hp: 28", "hp: 28\ninitiative: 5\nstr_save: 9\narcana: 4\npassive_perception: 11\nspell_dc: 15\npb: 3")))
  local v = sheets.values(sheets.read(TAMSIN))
  eq(v.initiative, 5)
  eq(v.saves.str, 9)
  eq(v.skills.arcana, 4)
  eq(v.passive.perception, 11)
  eq(v.spellDC, 15)
  eq(v.pb, 3)
  eq(v.saves.dex, 6, "a written pb feeds the sums it is part of")
  eq(v.spellAttack, 5)
end)

test("sheets: Proficiency Bonus and modifiers follow the SRD's tables", "dm", function()
  local pbs = {}
  for level = 1, 20 do pbs[#pbs + 1] = tostring(sheets.proficiency(level)) end
  eq(table.concat(pbs, " "), "2 2 2 2 3 3 3 3 4 4 4 4 5 5 5 5 6 6 6 6")
  local mods = {}
  for _, s in ipairs({ 1, 3, 5, 8, 9, 10, 11, 12, 19, 20, 30 }) do mods[#mods + 1] = sheets.signed(sheets.modifier(s)) end
  eq(table.concat(mods, " "), "-5 -4 -3 -1 -1 +0 +0 +1 +4 +5 +10")
end)

test("sheets: saves, skills and Advantage can be named any sensible way", "dm", function()
  page(TAMSIN, (RANGER:gsub("saves: %[str, dex%]", "saves: [Strength, DEX_SAVE]")
    :gsub("skills: %[athletics", "skills: [Sleight of Hand, athletics")
    :gsub("advantage: %[perception%]", "advantage: [Perception, wis_save, Initiative]")))
  local v = sheets.values(sheets.read(TAMSIN))
  eq(v.saveProf.str, true)
  eq(v.saveProf.dex, true)
  eq(v.skillProf.sleight_of_hand, 1)
  ok(v.adv.perception and v.adv.wis_save and v.adv.initiative, "each Advantage read")
end)

test("sheets: saves and skills written as a line of names are read as a list", "dm", function()
  page(TAMSIN, RANGER)
  local listed = sheets.draw()
  page(TAMSIN, (RANGER:gsub("saves: %[str, dex%]", "saves: str, dex")
    :gsub("skills: %[([^%]]*)%]", "skills: %1")
    :gsub("expertise: %[survival%]", "expertise: survival")
    :gsub("advantage: %[perception%]", "advantage: perception")
    :gsub("armor_training: %[([^%]]*)%]", "armor_training: %1")))
  local d = sheets.read(TAMSIN)
  eq(d.skills, "athletics, nature, perception, stealth, survival", "YAML reads the line as one text")
  local v = sheets.values(d)
  eq(v.saveProf.str, true)
  eq(v.saveProf.con, false)
  eq(v.skillProf.perception, 1)
  eq(v.skillProf.survival, 2)
  eq(v.passive.perception, 19)
  local lined = sheets.draw()
  eq(svgOf(lined.html), svgOf(listed.html), "the same sheet as the list draws")
  eq(lined.markdown, listed.markdown)
  eq(#sheets.problems(d), 0)
  -- a list whose entry is such a line, too
  page(TAMSIN, (RANGER:gsub("saves: %[str, dex%]", 'saves: ["str, dex"]')))
  eq(sheets.values(sheets.read(TAMSIN)).saveProf.dex, true)
end)

-- The line over a drawn sheet naming what it couldn't read, or nil.
local function warning(w)
  return w.html:match('<p class="gmsheets%-warn">(.-)</p>')
end

test("sheets: a name the sheet doesn't know is named over it, and never printed", "dm", function()
  page(TAMSIN, (RANGER:gsub("skills: %[athletics", "skills: [athletcs, perceptoin, athletics")
    :gsub("saves: %[str, dex%]", "saves: [str, dex, death]")
    :gsub("expertise: %[survival%]", "expertise: [survival, thieves_tools]")
    :gsub("advantage: %[perception%]", "advantage: [perception, stealth checks, initiative, wis_save, Dexterity]")
    :gsub("armor_training: %[light, medium, shields%]", "armor_training: [light, medium, shield]")))
  local w = sheets.draw()
  eq(warning(w), "⚠ Left off the sheet, since it can't read them: saves death; skills athletcs, perceptoin; " ..
    "expertise thieves_tools; advantage stealth checks; armor_training shield.")
  ok(w.html:find("gmsheets-warn", 1, true) < w.html:find("<svg", 1, true), "over the sheet")
  hasnt(w.markdown, "perceptoin", "never in the Markdown face, which prints and goes to the players")
  hasnt(sheets.printed.draw(), "Left off the sheet")
  -- a page the sheet reads all of has no such line
  page(TAMSIN, RANGER)
  eq(warning(sheets.draw()), nil)
  -- nor does one with a map where a list of names goes, without saying so
  page(TAMSIN, (RANGER:gsub("skills: %[[^%]]*%]", "skills: {athletics: 5}")))
  has(warning(sheets.draw()), "skills, a map where a list of names goes")
end)

test("sheets: slots keyed by level draw as a list of them does", "dm", function()
  page(TAMSIN, (RANGER:gsub("slots: %[3%]", "slots: [4, 2]")))
  local listed = sheets.draw()
  has(texts(svgOf(listed.html)), "SLOTS | 1st | 2nd")
  for _, keyed in ipairs({ "slots: {1: 4, 2: 2}", 'slots: {"2": 2, "1": 4}' }) do
    page(TAMSIN, (RANGER:gsub("slots: %[3%]", keyed)))
    local w = sheets.draw()
    eq(svgOf(w.html), svgOf(listed.html), keyed)
    eq(w.markdown, listed.markdown, keyed)
    has(w.markdown, "**Level 1 (4 slots).**", keyed)
    eq(warning(w), nil, keyed)
  end
  -- a level left out is a level with none
  page(TAMSIN, (RANGER:gsub("slots: %[3%]", "slots: {1: 4, 3: 2}")))
  has(texts(svgOf(sheets.draw().html)), "SLOTS | 1st | 3rd")
end)

test("sheets: a list of spells with no levels is given as a list, not read as levels", "dm", function()
  page(TAMSIN, (RANGER:gsub("spells: {1:[^\n]*}", "spells: [Bless, Cure Wounds, Guiding Bolt, Aid]")
    :gsub("always_prepared: {1: %[([^\n]*)%]}", "always_prepared: [%1]")))
  local w = sheets.draw()
  has(w.markdown, "**Prepared.** Bless, Cure Wounds, Guiding Bolt, Aid.")
  has(w.markdown, "**Always prepared.** Hunter's Mark (Bonus Action, 90 ft.; concentration).")
  hasnt(w.markdown, "**Level ", "no levels made up from the list's places")
  eq(warning(w), nil)
  -- beside levels that are written
  page(TAMSIN, (RANGER:gsub("spells: {1:[^\n]*}", "spells: [Bless, Aid]")))
  local md = sheets.draw().markdown
  has(md, "**Level 1 (3 slots).** always prepared: Hunter's Mark")
  has(md, "**Prepared.** Bless, Aid.")
end)

test("sheets: spells and slots in a shape it can't read are named over the sheet", "dm", function()
  page(TAMSIN, (RANGER:gsub("spells: {1:[^\n]*}", "spells: {first: [Bless], 1: [Cure Wounds, [Aid, Sleep]]}")
    :gsub("slots: %[3%]", "slots: {1: three, ninth: 1}")))
  local w = sheets.draw()
  local warn = warning(w)
  has(warn, "spells under “first”, which isn't a spell level")
  has(warn, "spells at level 1: an entry with no spell's name")
  has(warn, "slots at level 1: “three”, which is no number")
  has(warn, "slots under “ninth”, which isn't a spell level")
  has(w.markdown, "**Level 1.** Cure Wounds; always prepared: Hunter's Mark", "what it can read is still there")
  hasnt(w.markdown, "three")
  has(texts(svgOf(w.html)), "SLOTS | None", "no slot it can count, so none drawn")
end)

test("sheets: the drawn page names the character and every number", "dm", function()
  page(TAMSIN, RANGER)
  local w = sheets.draw()
  local svg = svgOf(w.html)
  ok(svg, "the page drawn as SVG")
  eq(svg:match('^<svg[^>]-%swidth="(%d+)"'), "672", "both columns of a book page")
  local h = tonumber(svg:match('^<svg[^>]-%sheight="(%d+)"'))
  ok(h and h <= 918, "no taller than a page: " .. tostring(h))
  has(svg, 'style="display:block"')
  local t = texts(svg)
  for _, want in ipairs({ "Tamsin Reed", "Ranger", "Hunter", "Human", "Guide", "Sam",
      "STRENGTH", "+3", "15", "28", "3d10", "30 ft.", "Medium", "+2", "19",
      "Longbow", "+7", "1d8+3 Piercing", "Once the guild outfits her", "Longsword",
      "Favored Enemy", "Healing Pool", "Long Rest", "Survival", "+6",
      "SPELL SAVE DC", "12", "+4", "Common, Elvish", "Herbalism Kit",
      "Longbow (Slow), Shortsword (Vex)", "Deft Explorer", "Resourceful", "Alert",
      "Quiver (20 arrows)" }) do
    has(t, want)
  end
  hasnt(t, "nil")
  eq(count(svg, "<text"), count(svg, "</text>"), "every text closed")
end)

test("sheets: marks say what they mean without colour, and the page keys them", "dm", function()
  page(TAMSIN, RANGER)
  local svg = svgOf(sheets.draw().html)
  local t = texts(svg)
  has(t, "proficient")
  has(t, "expertise")
  has(t, "ADV", "Advantage on Perception is a word, not a colour")
  -- the key's marks and the skills': one diamond for Survival and one in the key
  eq(count(svg, '<path d="M10 '), 1, "Survival's diamond")
  -- the favored enemy's two uses and three 1st-level slots are circles to tick
  ok(count(svg, 'r="3.3" fill="none"') >= 2 + 3 + 6, "circles to tick")
  -- one ink and a fainter grey of it: nothing else is painted
  local paints = {}
  for attr, colour in svg:gmatch('(%a+)="(#%x+)"') do
    if attr == "fill" or attr == "stroke" then paints[colour] = true end
  end
  local found = {}
  for colour in pairs(paints) do found[#found + 1] = colour end
  table.sort(found)
  eq(table.concat(found, " "), "#2a2521 #8a8178")
end)

test("sheets: the text after the page gives every feature in full", "dm", function()
  page(TAMSIN, RANGER)
  local md = sheets.text(sheets.read(TAMSIN), sheets.values(sheets.read(TAMSIN)))
  has(md, "## Class Features\n\n### Favored Enemy\n\nYou always have Hunter's Mark prepared")
  has(md, "### Deft Explorer\n\n***Expertise.*** You have Expertise in Survival.\n\n***Languages.*** You know two more languages.")
  has(md, "## Species Traits\n\n### Resourceful\n\nYou gain Heroic Inspiration")
  has(md, "## Feats\n\n### Alert\n")
  has(md, "**Level 1 (3 slots).** Cure Wounds, Goodberry (Action, Self; material: a sprig of mistletoe); " ..
    "always prepared: Hunter's Mark (Bonus Action, 90 ft.; concentration).")
  has(md, "**Spellcasting ability** Wisdom · **Spell save DC** 12 · **Spell attack bonus** +4")
  has(md, "## Equipment\n\nLongbow; Shortsword; Quiver (20 arrows).")
  has(md, "**Coins.** 12 GP, 4 SP.")
  has(md, "**Once the guild outfits her.** Scale Mail; Longsword.")
  hasnt(md, "nil")
end)

test("sheets: a titled paragraph is set as a lead only where it looks like one", "dm", function()
  local text = table.concat({
    "---", "level: 1", "str: 10", "dex: 10", "con: 10", "int: 10", "wis: 10", "cha: 10",
    "features:",
    "  - name: Test",
    "    text: |",
    "      You attack twice. Then you rest.",
    "      Initiative Swap. You trade places.",
    "      Strength +2. It rises.",
    "      A Very Long Title That Goes On And On Forever. Too long.",
    "      - one item",
    "      - two items",
    "---", "",
  }, NL)
  page("Party/Test", text)
  local d = sheets.read("Party/Test")
  local md = sheets.text(d, sheets.values(d))
  has(md, "You attack twice. Then you rest.")
  has(md, "***Initiative Swap.*** You trade places.")
  has(md, "\nStrength +2. It rises.")
  has(md, "\nA Very Long Title That Goes On And On Forever. Too long.")
  has(md, "- one item\n- two items", "a list's items stay together")
end)

test("sheets: the Markdown face is the drawn page two columns wide, then the text", "dm", function()
  page(TAMSIN, RANGER)
  local w = sheets.draw()
  local md = w.markdown
  ok(md:startsWith('<div class="gmsheets-page" style="column-span:all">\n<svg '), "a block two columns wide")
  has(md, "</svg>\n</div>\n\n## Class Features")
  eq(md:match("<svg.-</svg>"), svgOf(w.html), "one drawing on the page and in print")
  -- no blank line inside the drawing, or Markdown would end the HTML block there
  hasnt(md:match("<div.-</div>"), "\n\n")
  eq(sheets.printed.draw(), md, "what GM Book prints")
  eq(gmbook.printers.sheets, sheets.printed)
end)

test("sheets: a page by name, from anywhere", "dm", function()
  page(TAMSIN, RANGER)
  H.current = "index"
  local w = sheets.draw(TAMSIN)
  has(w.html, "Tamsin Reed")
  local w2 = sheets.draw(TAMSIN, {})
  eq(w2.markdown, w.markdown)
end)

-- A build takes a while and yields at every call, so a sheet drawn on the
-- page while one runs must draw its own page, not the one being printed.
test("sheets: a live sheet during a build draws its own page", "dm", function()
  page(TAMSIN, RANGER)
  H.pages["Party/Other"] = (RANGER:gsub("class: Ranger", "class: Wizard"))
  gmbook.printing = "Party/Other"
  local good, err = pcall(function()
    has(texts(svgOf(sheets.draw().html)), "Tamsin Reed | LEVEL | 3 | Ranger", "the page open, not the one being printed")
    has(texts(svgOf(sheets.printed.draw())), "Other | LEVEL | 3 | Wizard", "while print draws the page being printed")
  end)
  gmbook.printing = nil
  if not good then error(err, 0) end
end)

test("sheets: a page that can't be drawn says why", "dm", function()
  local w = sheets.draw("Party/Nobody")
  has(w.html, "No page Party/Nobody.")
  eq(w.markdown, "*No page Party/Nobody.*")
  page("Party/Bare", "# Bare\n")
  has(sheets.draw("Party/Bare").markdown, "has no frontmatter to draw a sheet from")
  page("Party/Broken", "---\nstr: [10\n---\n")
  has(sheets.draw("Party/Broken").markdown, "doesn't parse as YAML")
end)

test("sheets: a page with only its scores still draws", "dm", function()
  page("Party/Plain", "---\nstr: 10\ndex: 10\ncon: 10\nint: 10\nwis: 10\ncha: 10\n---\n")
  local w = sheets.draw("Party/Plain")
  local svg = svgOf(w.html)
  ok(svg, "drawn")
  local t = texts(svg)
  has(t, "Plain")
  has(t, "None", "no attacks, said so")
  hasnt(t, "nil")
  eq(sheets.text(sheets.read("Party/Plain"), sheets.values(sheets.read("Party/Plain"))), "")
  ok(w.markdown:match("</div>$"), "nothing after the page")
end)

test("sheets: spells keyed by number or by text are the same", "dm", function()
  page(TAMSIN, (RANGER:gsub("spells: {1:", 'spells: {"1":')))
  local d = sheets.read(TAMSIN)
  has(sheets.text(d, sheets.values(d)), "**Level 1 (3 slots).** Cure Wounds")
end)

test("sheets: extras from the settings are drawn beside the class", "dm", function()
  config.set("gmSheets", { extras = { { key = "oath", label = "Oath" } } })
  page(TAMSIN, (RANGER:gsub("class: Ranger", "class: Ranger\noath: Silence")))
  local t = texts(svgOf(sheets.draw().html))
  has(t, "Silence")
  has(t, "OATH")
end)

test("sheets: text too long for its box is fitted, never split mid-character", "dm", function()
  local long = "Bartholomew Aldous Fitzwilliam Montgomery-Hargreaves the Third of Nowhere"
  page("Party/" .. long, RANGER)
  local svg = svgOf(sheets.draw("Party/" .. long).html)
  local size, first = svg:match('<text[^>]-font%-size="([%d.]+)"[^>]*>([^<]*)</text>')
  eq(first, long, "a long name fits whole, smaller")
  ok(tonumber(size) < 24, "set smaller than 24: " .. size)
  local longer = long .. ", Warden of the Upper Fords and Keeper of the Seven Keys"
  page("Party/" .. longer, RANGER)
  svg = svgOf(sheets.draw("Party/" .. longer).html)
  first = svg:match("<text[^>]*>([^<]*)</text>")
  ok(first:find("…", 1, true), "cut short with an ellipsis: " .. first)
  eq(sheets.dropLast("ab—"), "ab", "a dash is one character")
  eq(sheets.dropLast("a"), "")
end)

-- The text the drawing sets at x and y, and its size.
local function drawnAt(svg, x, y)
  local size, s = svg:match('<text x="' .. x .. '" y="' .. y .. '" font%-size="([%d.]+)"[^>]*>([^<]*)</text>')
  return s, tonumber(size)
end

test("sheets: a value the page cuts short is given whole after it", "dm", function()
  -- seven fields across the class line leave each too little room for
  -- a subclass this long
  config.set("gmSheets", { extras = { { key = "oath", label = "Oath" }, { key = "patron", label = "Patron" } } })
  page(TAMSIN, (RANGER:gsub("subclass: Hunter", "subclass: School of Evocation / Champion\noath: Silence\npatron: The Warden")
    :gsub("ac: 15", "ac: 12 (15 with mage armor)")
    :gsub("hp: 28", "hp: 28 (35 with Aid, 40 with Heroes' Feast)")
    :gsub("label: Once the guild outfits her\n  ac: 16", "label: Once the guild outfits her\n  ac: 16 (18 with a shield)")))
  local w = sheets.draw()
  local svg = svgOf(w.html)
  has(texts(svg), "School of Evocation", "cut short on the page")
  hasnt(texts(svg), "Champion")
  has(w.markdown, "**Subclass.** School of Evocation / Champion.\n")
  has(w.markdown, "**Armor Class.** 12 (15 with mage armor).\n")
  has(w.markdown, "**Hit Points.** 28 (35 with Aid, 40 with Heroes' Feast).\n")
  has(w.markdown, "**Once the guild outfits her: Armor Class.** 16 (18 with a shield).\n")
  ok(w.markdown:find("**Subclass.**", 1, true) < w.markdown:find("## Class Features", 1, true),
    "before the features, where the page leaves off")
  -- the Armor Class fits its shield and the Hit Points their box, not over the next one
  local ac, acSize = drawnAt(svg, "39", "215")
  ok(ac and ac:find("…", 1, true), "the Armor Class is cut short: " .. tostring(ac))
  ok(sheets.textWidth(ac, acSize, true) <= 58, "and fits the shield: " .. sheets.textWidth(ac, acSize, true))
  local hp, hpSize = drawnAt(svg, "126", "214")
  ok(hp and sheets.textWidth(hp, hpSize, true) <= 68, "the Hit Points fit before the Current box")
  -- what fits is drawn as it was, and isn't repeated
  page(TAMSIN, RANGER)
  svg = svgOf(sheets.draw().html)
  eq(drawnAt(svg, "39", "215"), "15")
  eq(select(2, drawnAt(svg, "39", "215")), 20)
  hasnt(sheets.draw().markdown, "**Armor Class.**")
end)

test("sheets: a path written for the adventure finds its page from the DM space", "dm", function()
  local sample = (RANGER:gsub("type: pc\nplayer: Sam\n", "type: sample\n"))
  H.pages["Adventure/Rules/Sample Characters/Tam"] = sample
  local w = sheets.draw("Rules/Sample Characters/Tam")
  hasnt(w.html, "No page")
  has(texts(svgOf(w.html)), "Tam | LEVEL | 3 | Ranger")
  -- a copy published to the players makes the path ambiguous: the adventure's own is drawn
  H.pages["Player/Rules/Sample Characters/Tam"] = (sample:gsub("class: Ranger", "class: Copied"))
  eq(sheets.find("Rules/Sample Characters/Tam"), "Adventure/Rules/Sample Characters/Tam")
  hasnt(texts(svgOf(sheets.draw("Rules/Sample Characters/Tam").html)), "Copied")
  eq(sheets.find("Player/Rules/Sample Characters/Tam"), "Player/Rules/Sample Characters/Tam", "a whole name wins")
  eq(sheets.find("Rules/Sample Characters/Nobody"), nil)
  has(sheets.draw("Rules/Sample Characters/Nobody").markdown, "No page Rules/Sample Characters/Nobody.")
  has(sheets.printed.draw("Rules/Sample Characters/Tam"), "<svg ", "and in print")
end)

test("sheets: a warlock's Pact Magic and a long list are drawn and counted", "dm", function()
  local gear = {}
  for i = 1, 40 do gear[#gear + 1] = "Thing " .. i end
  page(TAMSIN, (RANGER:gsub("slots: %[3%]", "pact_slots: 2\npact_level: 3")
    :gsub("equipment: %[Longbow, Shortsword, Quiver %(20 arrows%)%]", "equipment: [" .. table.concat(gear, ", ") .. "]")))
  local w = sheets.draw()
  local t = texts(svgOf(w.html))
  has(t, "Pact Magic, 3rd level")
  has(t, "more, after this page", "the gear that didn't fit is counted")
  has(w.markdown, "Thing 40.", "and all of it is in the text")
  has(w.markdown, "**Pact Magic.** 2 slots of level 3, back after a Short or Long Rest.")
end)

-- A character whose every name and text is HTML, as a player could write
-- one on D&D Beyond: a form to catch a password, an image, a redirect, and
-- an entity that a careless unescape would turn into a tag.
local FORM = "<form action=x><input name=pw></form>"
local IMG = "<img src=x>"
local META = '<meta http-equiv="refresh" content="0;url=https://x">'
local ENTITY = "&lt;b&gt;"
local HOSTILE = [==[---
level: 3
class: 'FORM'
subclass: 'IMG'
species: 'META'
background: 'ENTITY'
player: 'IMG'
oath: 'FORM'
str: 10
dex: 10
con: 10
int: 16
wis: 10
cha: 10
attacks:
  - {name: 'IMG', hit: 'FORM FORM', damage: 'ENTITY ENTITY ENTITY', notes: 'META META'}
resources:
  - {name: 'IMG', uses: 2, reset: 'META'}
languages: ['META', 'META', 'META', 'META', 'META', 'META']
spellcasting: int
slots: [2]
cantrips: ['IMG']
spells: {1: ['FORM', {name: 'IMG', time: 'ENTITY', range: 'FORM', material: 'IMG', notes: 'META'}]}
features:
  - name: 'FORM'
    text: |
      Hidden. IMG and ENTITY.
      META
      - a list item <b>bold</b>
traits:
  - name: 'ENTITY'
feats:
  - name: 'IMG'
equipment: ['IMG', 'ENTITY']
attuned: ['FORM']
kit: {label: 'IMG', equipment: ['META']}
---
]==]

test("sheets: text from the page never reaches the browser as HTML", "dm", function()
  config.set("gmSheets", { extras = { { key = "oath", label = "Oath" } } })
  local text = HOSTILE
  for word, value in pairs({ FORM = FORM, IMG = IMG, META = META, ENTITY = ENTITY }) do
    text = (text:gsub(word, function() return value end))
  end
  local name = "Party/" .. IMG .. " Reed"
  page(name, text)
  local w = sheets.draw(name)
  ok(svgOf(w.html), "drawn")
  -- nothing is read as a tag: the drawing sets it all as XML-escaped text,
  -- and in the text after it every < is escaped with a backslash, which
  -- SilverBullet renders as the character (it shows &lt; as written)
  local function bare(s)
    for slashes in s:gmatch("(\\*)<") do
      if #slashes % 2 == 0 then return true end
    end
    return false
  end
  local function after(face)
    return face:match('<div class="md">(.-)</div>') or face:match("</svg>\n</div>(.*)$")
  end
  local faces = { html = w.html, markdown = w.markdown, printed = sheets.printed.draw(name) }
  for which, face in pairs(faces) do
    for _, tag in ipairs({ "<form", "<input", "<img", "<meta", "<b>" }) do
      hasnt(svgOf(face), tag, which .. "'s drawing")
    end
    local text = after(face)
    ok(text and text:find("Class Features", 1, true), which .. ": the text after the drawing")
    ok(not bare(text), which .. ": a < left unescaped")
  end
  -- what the page says is all there, as text
  local md = w.markdown
  has(md, "## Class Features\n\n### \\<form action=x\\>\\<input name=pw\\>\\</form\\>\n")
  has(md, "### \\&lt;b\\&gt;\n", "an entity in a name shows as itself")
  has(md, "**Level 1 (2 slots).** \\<form action=x\\>")
  has(md, "\\<img src=x\\> (\\&lt;b\\&gt;, \\<form")
  has(md, "**Cantrips.** \\<img src=x\\>.")
  has(md, "## Equipment\n\n\\<img src=x\\>; \\&lt;b\\&gt;.")
  has(md, "**Attuned.** \\<form action=x\\>")
  has(md, "**\\<img src=x\\>.** \\<meta http-equiv=")
  has(md, "## Attacks\n\n***\\<img src=x\\>.*** \\<form action=x\\>")
  has(md, "## Resources\n\n***\\<img src=x\\>.*** 2; back after \\<meta")
  has(md, "**Languages.** \\<meta http-equiv=")
  -- a feature's text is Markdown, its bold and lists kept, and only a < that
  -- would open a tag escaped
  has(md, "***Hidden.*** \\<img src=x> and &lt;b&gt;.\n\n\\<meta")
  has(md, "\n- a list item \\<b>bold\\</b>\n")
  -- the drawing sets it all as text too, the name included
  local t = texts(svgOf(w.html))
  has(t, "&lt;img src=x&gt; Reed")
  has(t, "&lt;form action=x&gt;")
  has(svgOf(w.html), 'aria-label="Character sheet: &lt;img src=x&gt; Reed"')
  -- a message that names a page is text as well
  ok(not bare(sheets.draw("Party/" .. IMG).markdown), "the message's page name")
end)

test("sheets: rules text GM Beyond escaped already is left as it is, and a lone & stays", "dm", function()
  -- GM Beyond writes a feature's rules text as Markdown with its < escaped;
  -- the sheet must not escape it again, or the page would show backslashes
  page("Party/Pip", table.concat({
    "---", "type: pc", "level: 1", "class: Wizard", "species: Human",
    "str: 8", "dex: 14", "con: 12", "int: 16", "wis: 10", "cha: 10",
    "features:", "  - name: Salt & Pepper",
    "    text: 'Deals 1d4 \\<fire\\> damage, **twice**.'",
    "---", "", "# Pip", "" }, "\n"))
  local md = sheets.draw("Party/Pip").markdown
  has(md, "### Salt & Pepper\n", "a lone & is no entity and stays as it is")
  has(md, "Deals 1d4 \\<fire\\> damage, **twice**.", "escaped once, bold kept")
  hasnt(md, "\\\\<", "never escaped twice")
end)

test("sheets: a value on lines of its own is drawn on one, and the drawing stays one block", "dm", function()
  page(TAMSIN, (RANGER:gsub("class: Ranger", 'class: "Ranger\\n\\nof the High Country"')))
  local w = sheets.draw()
  has(texts(svgOf(w.html)), "Ranger of the High Country")
  hasnt(w.markdown:match("<div.-</div>"), "\n\n", "a blank line would end the HTML block the drawing prints in")
end)

-- Measured at 375px in SilverBullet 2.11's widget frame: the sheet ran 12px
-- past its 333px frame, since its padding came on top of max-width: 100%
-- (SilverBullet sets border-box only on its standalone pages), and it drew
-- at half size, its labels at 3px. With these rules it draws at its own 672px
-- in a frame that scrolls, and a desktop's is as it was.
test("sheets: on a phone the sheet keeps its size and scrolls, and its padding counts in its width", "dm", function()
  local style = SRC["GM Sheets"]:match("```space%-style\n(.-)\n```")
  local svg = style:match("\n%.gmsheets%-page svg%s*(%b{})")
  ok(svg, "a rule for the drawing")
  has(svg, "box-sizing: border-box;")
  has(svg, "width: auto;", "its width the one it is drawn at, not the attribute taken as the whole box")
  has(svg, "max-width: 100%;")
  has(svg, "height: auto;")
  has(style:match("\n%.gmsheets%-page%s*(%b{})") or "", "overflow-x: auto;", "the frame the drawing scrolls in")
  local phone = style:match("@media screen and %(max%-width: 600px%)%s*(%b{})")
  ok(phone, "a rule for a phone, for the screen alone, so printing is as it was")
  has(phone, ".gmsheets-page svg")
  has(phone, "max-width: none;")
  page(TAMSIN, RANGER)
  has(sheets.draw().html, '<div class="gmsheets-page"><svg ', "and the drawing is in that frame")
end)

test("sheets: the widget's faces are text, so two on one page both draw", "dm", function()
  page(TAMSIN, RANGER)
  local w = sheets.draw()
  eq(type(w.html), "string")
  eq(type(w.markdown), "string")
  eq(w.display, "block")
end)

------------------------------------------------------------------ in the book

-- Where GM Book breaks the pages of a text: the text of each page.
local function pagesOf(text)
  local out, cur = {}, {}
  for line in (gmbook.paginate(text) .. NL):gmatch("([^" .. NL .. "]*)" .. NL) do
    if line == "\\page" then
      out[#out + 1] = table.concat(cur, NL)
      cur = {}
    else
      cur[#cur + 1] = line
    end
  end
  out[#out + 1] = table.concat(cur, NL)
  return out
end

test("sheets: GM Book gives a drawn sheet a page to itself", "adventure", function()
  page(TAMSIN, RANGER)
  local md = sheets.printed.draw(TAMSIN)
  local pages = pagesOf("Before the sheet." .. NL .. NL .. md .. NL .. NL .. "After it.")
  eq(#pages >= 3, true, "before, the sheet, after: " .. #pages)
  has(pages[1], "Before the sheet.")
  hasnt(pages[1], "<svg")
  ok(pages[2]:match("^%s*<div class=\"gmsheets%-page\""), "the sheet starts its page: " .. pages[2]:sub(1, 60))
  hasnt(pages[2], "## Class Features", "and has it to itself")
  has(pages[3], "## Class Features")
end)

test("sheets: a sheet that already starts a page takes no break before it", "adventure", function()
  page(TAMSIN, RANGER)
  local md = sheets.printed.draw(TAMSIN)
  local pages = pagesOf(md .. NL .. NL .. "\\page" .. NL .. NL .. "Next.")
  ok(pages[1]:match("^<div"), "first on its page")
  eq(#pages, 3, "the sheet, its text, and the explicit break's page: no empty page")
  local trace = {}
  gmbook.paginate(md, trace)
  eq(trace[1].kind, "drawn")
  eq(trace[1].page, 1)
end)

test("sheets: a drawing no wider than a column is measured in the column", "adventure", function()
  local narrow = '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="200" style="display:block"></svg>'
  local pages = pagesOf("Before." .. NL .. NL .. narrow .. NL .. NL .. "After.")
  eq(#pages, 1, "a map-sized drawing sits among the text")
end)

test("sheets: every number in the drawing is written the same by any Lua", "dm", function()
  page(TAMSIN, RANGER)
  local svg = svgOf(sheets.draw().html)
  hasnt(svg, '.0"', "a float printed as 12.0 here and 12 in SilverBullet")
  for value in svg:gmatch('="(%-?%d+%.%d+)"') do
    ok(value:sub(-1) ~= "0", "a trailing zero in " .. value)
  end
end)

test("sheets: a sample character builds into both editions with its sheet", "adventure", function()
  -- a chapter of sample characters, and one of them, the way a book would
  -- put a sheet among its pages: the introduction, then the sheet
  H.pages["Rules/Sample Characters"] = "---\nbook_order: 45\n---\n\n# Sample Characters\n\nOne, to show what a character looks like.\n"
  local sample = (RANGER:gsub("type: pc\nplayer: Sam\n", "type: sample\nbook_order: 45.01\nbook_section: true\n"))
  sample = (sample:gsub("# Tamsin Reed\n\n", "# Tamsin Reed\n\nA guide from the high country.\n\n> **dm** Her secret\n> She owes the guild.\n\n"))
  H.pages["Rules/Sample Characters/Tamsin Reed"] = sample
  local report = gmbook.compile({ "dm", "player" })
  eq(#report.live, 0, "every expression printed: " .. table.concat(report.live, ", "))
  for _, edition in ipairs({ "Build/Book DM", "Build/Book Player" }) do
    local book = H.pages[edition]
    eq(count(book, "<svg"), 1 + count(FIXTURES.adventure[edition], "<svg"), edition .. ": one more drawing")
    has(book, "\\page\n\n<div class=\"gmsheets-page\" style=\"column-span:all\">\n<svg ", edition .. ": a page to itself")
    has(book, "</div>\n\n\\page\n\n### Class Features", edition .. ": and the text on the next page")
    has(book, "#### Deft Explorer\n\n***Expertise.*** You have Expertise in Survival.", edition .. ": the features in full")
    has(book, "## Tamsin Reed\n\nA guide from the high country.")
  end
  has(H.pages["Build/Book DM"], "**Her secret.** She owes the guild.")
  hasnt(H.pages["Build/Book Player"], "She owes the guild.")
end)

test("sheets: a sheet that can't be drawn keeps the book back and names its page", "adventure", function()
  -- one sheet of a page that isn't there, one of a page whose frontmatter
  -- doesn't parse; neither page is in the book itself
  H.pages["Rules/Sample Characters"] = "---\nbook_order: 45\n---\n\n# Sample Characters\n\n" ..
    '${sheets.draw("Rules/Sample Characters/Nobody")}\n'
  H.pages["Rules/Sample Characters/Broken"] = "---\nstr: [10\n---\n\n# Broken\n"
  H.pages["Rules/Sample Heroes"] = "---\nbook_order: 46\n---\n\n# Sample Heroes\n\n" ..
    '${sheets.draw("Rules/Sample Characters/Broken")}\n'
  local before = { dm = H.pages["Build/Book DM"], player = H.pages["Build/Book Player"] }
  H.current = "index"
  local report = gmbook.build({ "dm", "player" })
  eq(#report.written, 0, "nothing written")
  eq(#report.kept, 2, "both editions kept back")
  eq(list(report.live), "Rules/Sample Characters | Rules/Sample Heroes", "and the pages named")
  local said = lastNotification().message
  has(said, "Rules/Sample Characters, ${sheets.draw(\"Rules/Sample Characters/Nobody\")}")
  has(said, "Rules/Sample Heroes, ${sheets.draw(\"Rules/Sample Characters/Broken\")}")
  has(said, "doesn't parse as YAML")
  hasnt(said, "Baked Sections", "a sheet that can't be drawn is no query to bake")
  eq(H.pages["Build/Book DM"], before.dm, "the edition on the page is left as it was")
  eq(H.pages["Build/Book Player"], before.player)
  -- the printer prints nothing but says why, and the wiki still says so too
  local good, why = pcall(sheets.printed.draw, "Rules/Sample Characters/Nobody")
  ok(not good, "the printer draws nothing")
  has(why, "Nobody")
  good, why = pcall(sheets.printed.draw, "Rules/Sample Characters/Broken")
  ok(not good)
  has(why, "doesn't parse as YAML")
  has(sheets.draw("Rules/Sample Characters/Nobody").markdown, "No page Rules/Sample Characters/Nobody.")
  has(sheets.draw("Rules/Sample Characters/Broken").markdown, "doesn't parse as YAML")
end)

test("sheets: a wizard's spellbook prints beside the spells prepared", "dm", function()
  page(TAMSIN, (RANGER:gsub("always_prepared:", "spellbook: {1: [Sleep, {name: Alarm, ritual: true}], 2: [Web]}\nalways_prepared:")))
  local d = sheets.read(TAMSIN)
  local md = sheets.text(d, sheets.values(d))
  has(md, "**Level 1 (3 slots).** Cure Wounds, Goodberry (Action, Self; material: a sprig of mistletoe); " ..
    "always prepared: Hunter's Mark (Bonus Action, 90 ft.; concentration); " ..
    "in the spellbook, not prepared: Sleep, Alarm (ritual).")
  has(md, "**Level 2.** in the spellbook, not prepared: Web.")
end)

test("sheets: a table in a feature's rules stays a table", "dm", function()
  local text = table.concat({
    "---", "level: 1", "str: 10", "dex: 10", "con: 10", "int: 10", "wis: 10", "cha: 10",
    "features:",
    "  - name: Wild Surge",
    "    text: |",
    "      Roll on the table.",
    "      | d4 | Effect |",
    "      |---|---|",
    "      | 1 | A flash |",
    "      | 2 | A bang |",
    "      Then carry on.",
    "---", "",
  }, "\n")
  page("Party/Test", text)
  local d = sheets.read("Party/Test")
  has(sheets.text(d, sheets.values(d)),
    "Roll on the table.\n\n| d4 | Effect |\n|---|---|\n| 1 | A flash |\n| 2 | A bang |\n\nThen carry on.")
end)

test("sheets: the drawn page never runs past its height, however long the lists", "dm", function()
  local gear, feats = {}, {}
  for i = 1, 60 do gear[#gear + 1] = "Thing " .. i end
  for i = 1, 60 do feats[#feats + 1] = "  - name: Feature " .. i end
  page(TAMSIN, (RANGER:gsub("equipment: %[Longbow, Shortsword, Quiver %(20 arrows%)%]", "equipment: [" .. table.concat(gear, ", ") .. "]")
    :gsub("features:\n", "features:\n" .. table.concat(feats, "\n") .. "\n")))
  local svg = sheets.draw().html:match("(<svg.-</svg>)")
  local h = tonumber(svg:match('^<svg[^>]-%sheight="(%d+)"'))
  ok(h <= 918 and h > 880, "near the whole page and never past it: " .. tostring(h))
  for y, height in svg:gmatch('<rect x="[%d.]+" y="([%d.]+)" width="[%d.]+" height="([%d.]+)"') do
    ok(tonumber(y) + tonumber(height) <= h + 0.01, "a box ends at " .. (tonumber(y) + tonumber(height)))
  end
  for y in svg:gmatch('<text x="[%d.]+" y="([%d.]+)"') do
    ok(tonumber(y) <= h, "text at " .. y)
  end
  has(svg, "more, after this page")
end)

------------------------------------------------------------------ a tab behind its space

local SHEETS = "Library/Storie/GM Sheets"

-- The library's page as the space holds it, at another version.
local function sheetsAt(name, version)
  H.pages[name] = (SRC["GM Sheets"]:gsub('\nversion: "[^"]*"\n', '\nversion: "' .. version .. '"\n', 1))
end

test("sheets: the version this tab runs is its page's", "dm", function()
  local written = SRC["GM Sheets"]:match('^%-%-%-\n.-\nversion: "([^"]+)"\n.-%-%-%-\n')
  ok(written, "a version in GM Sheets' frontmatter")
  eq(sheets.version, written)
  eq(sheets.stale(), nil, "a space that holds the same says nothing")
  page(TAMSIN, RANGER)
  hasnt(sheets.draw().html, "Reload this tab")
end)

test("sheets: a tab behind its space says so over the sheet, on the page alone", "dm", function()
  sheetsAt("Adventure/" .. SHEETS, "1.99.0")
  eq(sheets.stale(), "This tab runs GM Sheets " .. sheets.version .. ", but the space has 1.99.0: " ..
    "reload it (System: Reload, Ctrl-Alt-R).")
  page(TAMSIN, RANGER)
  local w = sheets.draw()
  has(w.html, '<div class="gmsheets"><p class="gmsheets-stale">⟳ Reload this tab: it runs GM Sheets ' ..
    sheets.version .. ", and the space has 1.99.0 (System: Reload, Ctrl-Alt-R).</p>", "first, over the sheet")
  hasnt(w.markdown, "Reload", "never in the Markdown face, which prints and goes to the players")
  hasnt(sheets.printed.draw(), "Reload", "nor in print")
  -- over a sheet that can't be drawn as well
  local gone = sheets.draw("Party/Nobody")
  has(gone.html, '<p class="gmsheets-stale">')
  eq(gone.markdown, "*No page Party/Nobody.*")
  -- another copy, at any depth, and a version is a page's text, never HTML
  sheetsAt("Old/Library/Storie/GM Sheets", "<b>2</b>")
  has(sheets.stale(), "but the space has 1.99.0 and <b>2</b>:")
  has(sheets.draw().html, "the space has 1.99.0 and &lt;b&gt;2&lt;/b&gt; (System")
  hasnt(sheets.draw().html, "<b>2")
end)

test("sheets: a look at the index that fails says nothing, and the sheet still draws", "dm", function()
  page(TAMSIN, RANGER)
  local real = index.pages
  index.pages = function() error("index gone") end
  local good, err = pcall(function()
    eq(sheets.stale(), nil)
    local w = sheets.draw()
    ok(svgOf(w.html), "drawn")
    hasnt(w.html, "Reload this tab")
  end)
  index.pages = real
  if not good then error(err, 0) end
end)

------------------------------------------------------------------ Jack of All Trades, and Disadvantage

-- A level 5 bard: Proficiency Bonus +3, so Jack of All Trades is +1.
local BARD = [==[---
type: pc
level: 5
class: Bard
str: 8
dex: 14
con: 12
int: 10
wis: 13
cha: 16
saves: [dex, cha]
skills: [deception, performance, persuasion]
expertise: [persuasion]
history: 5
spellcasting: cha
---

# Wren Hollow
]==]

test("sheets: Jack of All Trades adds half the bonus to a skill without proficiency, and nothing else", "dm", function()
  page("Party/Wren Hollow", BARD)
  local v = sheets.values(sheets.read("Party/Wren Hollow"))
  eq(v.pb, 3)
  eq(v.jack, true, "a bard at level 5")
  -- skills without proficiency: the modifier and 1, half of +3 rounded down
  eq(v.skills.athletics, 0, "Strength -1, and 1")
  eq(v.skills.arcana, 1, "Intelligence +0, and 1")
  eq(v.skills.stealth, 3, "Dexterity +2, and 1")
  eq(v.skills.perception, 2, "Wisdom +1, and 1")
  -- a skill that uses the bonus already has no more of it
  eq(v.skills.deception, 6, "proficient: +3 and +3")
  eq(v.skills.performance, 6)
  eq(v.skills.persuasion, 9, "Expertise: +3 and +6")
  eq(v.skills.history, 5, "a number the page writes still wins")
  -- a passive score built on a skill has it through the skill
  eq(v.passive.perception, 12, "10 and Perception's +2")
  eq(v.passive.insight, 12)
  eq(v.passive.investigation, 11, "10 and Investigation's +1")
  -- not initiative, not a saving throw
  eq(v.initiative, 2, "Dexterity alone")
  eq(v.saves.str, -1)
  eq(v.saves.wis, 1)
  eq(v.saves.dex, 5, "proficient: +2 and +3")
  eq(v.spellDC, 14, "8, +3 and Charisma's +3")
  -- the sheet draws those numbers
  local t = texts(svgOf(sheets.draw("Party/Wren Hollow").html))
  has(t, "Arcana | Int | +1")
  has(t, "Persuasion | Cha | +9")
  has(t, "Passive Investigation | 11")
  -- and without it, as before
  page("Party/Wren Hollow", (BARD:gsub("level: 5", "level: 5\njack_of_all_trades: false")))
  v = sheets.values(sheets.read("Party/Wren Hollow"))
  eq(v.jack, false)
  eq(v.skills.arcana, 0)
  eq(v.passive.investigation, 10)
  -- half of an odd bonus rounds down: +5 at level 13 gives 2
  page("Party/Wren Hollow", (BARD:gsub("level: 5", "level: 13")))
  eq(sheets.values(sheets.read("Party/Wren Hollow")).skills.arcana, 2)
end)

test("sheets: who has Jack of All Trades", "dm", function()
  local function jack(extra)
    return sheets.jackOfAllTrades(yaml.parse(extra))
  end
  eq(jack("class: Bard\nlevel: 1"), false, "a bard gains it at level 2")
  eq(jack("class: Bard\nlevel: 2"), true)
  eq(jack("class: bard\nlevel: 9"), true, "however it is capitalised")
  eq(jack("class: Monk 2 / Bard 2 / Warlock 1\nlevel: 5"), true, "multiclassed, from the bard's own level")
  eq(jack("class: Fighter 3 / Bard 1\nlevel: 4"), false, "a level of bard is not enough, whatever the total")
  eq(jack("class: Bard 3, Fighter 2\nlevel: 5"), true)
  eq(jack("class: Bard (College of Lore) 6\nlevel: 6"), true)
  eq(jack("class: Barbarian\nlevel: 9"), false)
  eq(jack("class: Bardic Scholar\nlevel: 9"), false, "only a class that is Bard")
  eq(jack("class: Bard / Fighter\nlevel: 9"), false, "a bard's level not given")
  eq(jack("class: Fighter\nlevel: 7\nfeatures:\n  - {name: Jack of All Trades, text: Half the bonus.}"), true,
    "a feature of that name")
  eq(jack("class: Rogue\nlevel: 3\nfeats: [jack-of-all-trades]"), true, "a feat, named any sensible way")
  eq(jack("class: Wizard\nlevel: 3\njack_of_all_trades: true"), true, "the page's word")
  eq(jack("class: Bard\nlevel: 5\njack_of_all_trades: false"), false, "either way")
  eq(jack("class: Wizard\nlevel: 3"), false)
  eq(sheets.classLevel(yaml.parse("class: Monk 2 / Bard 3"), "bard"), 3)
  eq(sheets.classLevel(yaml.parse("class: Bard\nlevel: 4"), "bard"), 4)
  eq(sheets.classLevel(yaml.parse("class: Bard"), "bard"), nil, "no level")
  eq(sheets.classLevel(yaml.parse("class: Wizard 3"), "bard"), nil)
end)

test("sheets: a passive score is 5 less with Disadvantage, and Advantage cancels it", "dm", function()
  -- Tamsin's Perception is +4, and she has Advantage on it: 19
  page(TAMSIN, (RANGER:gsub("advantage: %[perception%]", "advantage: [perception]\ndisadvantage: [perception]")))
  local v = sheets.values(sheets.read(TAMSIN))
  eq(v.passive.perception, 14, "both: 10 and +4")
  page(TAMSIN, (RANGER:gsub("advantage: %[perception%]", "disadvantage: [perception]")))
  eq(sheets.values(sheets.read(TAMSIN)).passive.perception, 9, "Disadvantage alone: 10, +4 and -5")
  -- the shapes Advantage takes: a line of names, a skill's own name
  page(TAMSIN, (RANGER:gsub("advantage: %[perception%]", "disadvantage: Insight, investigation")))
  v = sheets.values(sheets.read(TAMSIN))
  eq(v.passive.insight, 7, "10, Insight's +2 and -5")
  eq(v.passive.investigation, 5, "10, Investigation's +0 and -5")
  eq(v.passive.perception, 14, "no Advantage left, none lost")
  -- a passive score the page writes still wins
  page(TAMSIN, (RANGER:gsub("advantage: %[perception%]", "disadvantage: [perception]\npassive_perception: 15")))
  eq(sheets.values(sheets.read(TAMSIN)).passive.perception, 15)
end)

-- How many times the drawing sets a word in its labels.
local function marks(svg, word)
  return count(svg, ">" .. word .. "</text>")
end

test("sheets: Disadvantage is the word DIS beside the number, and a name it doesn't know is named", "dm", function()
  page(TAMSIN, RANGER)
  local svg = svgOf(sheets.draw().html)
  eq(marks(svg, "ADV"), 2, "Perception's, and passive Perception's")
  eq(marks(svg, "DIS"), 0)
  page(TAMSIN, (RANGER:gsub("advantage: %[perception%]", "advantage: [perception]\ndisadvantage: [stealth, initiative, str_save]")))
  local w = sheets.draw()
  svg = svgOf(w.html)
  eq(marks(svg, "DIS"), 3, "Stealth, initiative and the Strength save")
  eq(marks(svg, "ADV"), 2)
  eq(warning(w), nil, "every name read")
  -- both on one roll: neither shows, as neither applies
  page(TAMSIN, (RANGER:gsub("advantage: %[perception%]", "advantage: [perception]\ndisadvantage: [perception]")))
  svg = svgOf(sheets.draw().html)
  eq(marks(svg, "ADV"), 0)
  eq(marks(svg, "DIS"), 0)
  has(texts(svg), "PASSIVE PERCEPTION | 14")
  -- a name it can't read is named over the sheet, as one in advantage is
  page(TAMSIN, (RANGER:gsub("advantage: %[perception%]", "disadvantage: [stealth checks]")))
  eq(warning(sheets.draw()), "⚠ Left off the sheet, since it can't read them: disadvantage stealth checks.")
end)

------------------------------------------------------------------ retired

test("sheets: a retired character's sheet says so beside the level, in words", "dm", function()
  page(TAMSIN, (RANGER:gsub("type: pc\n", "type: pc\nretired: true\n")))
  local w = sheets.draw()
  local svg = svgOf(w.html)
  has(texts(svg), "Tamsin Reed | RETIRED | LEVEL | 3 | Ranger")
  has(svg, 'aria-label="Character sheet: Tamsin Reed (retired)"')
  has(svgOf(sheets.printed.draw()), ">RETIRED</text>", "the drawing is the same in print")
  -- a name long enough to reach it is set smaller, clear of it
  local long = "Bartholomew Aldous Fitzwilliam Montgomery-Hargreaves the Third"
  page("Party/" .. long, (RANGER:gsub("type: pc\n", "type: pc\nretired: true\n")))
  svg = svgOf(sheets.draw("Party/" .. long).html)
  local size, first = svg:match('<text[^>]-font%-size="([%d.]+)"[^>]*>([^<]*)</text>')
  eq(first, long)
  local x = tonumber(svg:match('<text x="([%d.]+)" y="24" font%-size="9" font%-weight="bold" text%-anchor="end" letter%-spacing="0.6">RETIRED</text>'))
  ok(x, "RETIRED set right of the name, before the level")
  local retiredLeft = x - sheets.textWidth("RETIRED", 9, true) - 0.6 * 7
  ok(sheets.textWidth(first, tonumber(size), true) < retiredLeft,
    "the name ends before RETIRED starts: " .. sheets.textWidth(first, tonumber(size), true) .. " < " .. retiredLeft)
  -- only true retires a character
  page(TAMSIN, (RANGER:gsub("type: pc\n", "type: pc\nretired: false\n")))
  hasnt(texts(svgOf(sheets.draw().html)), "RETIRED")
  page(TAMSIN, RANGER)
  hasnt(texts(svgOf(sheets.draw().html)), "RETIRED")
end)

------------------------------------------------------------------ numbers written over the sums

-- The line over a drawn sheet naming the numbers written over a sum that
-- differs, or nil.
local function written(w)
  return w.html:match('<p class="gmsheets%-warn gmsheets%-written">(.-)</p>')
end

test("sheets: a number written where the sum differs is named over the sheet, and never printed", "dm", function()
  -- Tamsin at level 3, with a Proficiency Bonus of +3 written over her +2
  page(TAMSIN, (RANGER:gsub("hp: 28", "hp: 28\ninitiative: 5\nstr_save: 9\narcana: 4\npassive_perception: 11\n" ..
    "spell_dc: 15\npb: 3\nathletics: 4\nstealth: 6")))
  local w = sheets.draw()
  eq(written(w), "⚠ Proficiency Bonus +3 as written; the sum is +2. " ..
    "Initiative +5 as written; the sum is +3. " ..
    "Strength save +9 as written; the sum is +4. " ..
    "Arcana +4 as written; the sum is +0. " ..
    "Passive Perception 11 as written; the sum is 20. " ..
    "Spell save DC 15 as written; the sum is 13.",
    "each sum with the other numbers as shown: the +3 written, Perception's +5 and Advantage's 5")
  local v = sheets.values(sheets.read(TAMSIN))
  eq(v.initiative, 5, "the sheet shows what is written")
  eq(v.sums.initiative, 3)
  -- Athletics +4 and Stealth +6, written too, are their sums with the +3: nothing said
  hasnt(written(w), "Athletics")
  hasnt(written(w), "Stealth")
  ok(w.html:find("gmsheets-written", 1, true) < w.html:find("<svg", 1, true), "over the sheet")
  hasnt(w.markdown, "as written", "never in the Markdown face, which prints and goes to the players")
  hasnt(sheets.printed.draw(), "as written")
  eq(warning(w), nil, "a line of its own, apart from what the sheet can't read")
end)

test("sheets: numbers that agree with the sums, or come from D&D Beyond, have no such line", "dm", function()
  page(TAMSIN, RANGER)
  eq(written(sheets.draw()), nil, "nothing written over a sum")
  page(TAMSIN, (RANGER:gsub("hp: 28", "hp: 28\ninitiative: 3\ndex_save: 5\nsurvival: 6\npassive_insight: 12\nspell_attack: 4")))
  eq(written(sheets.draw()), nil, "each written as its sum")
  page(TAMSIN, (RANGER:gsub("hp: 28", "hp: 28\ninitiative: 6\nddb: 1002")))
  eq(written(sheets.draw()), nil, "D&D Beyond's numbers, with what the sums don't know")
  eq(list(sheets.differences(sheets.read(TAMSIN))), "")
end)

test("sheets: a written number is held to the sum with Jack of All Trades and Disadvantage in it", "dm", function()
  -- the bard's Arcana is +1 with Jack of All Trades: a +0 written is a point short
  page("Party/Wren Hollow", (BARD:gsub("history: 5", "arcana: 0\nhistory: 5\npassive_perception: 12\ndisadvantage: [perception]")))
  eq(list(sheets.differences(sheets.read("Party/Wren Hollow"))),
    "Arcana +0 as written; the sum is +1. | History +5 as written; the sum is +1. | " ..
    "Passive Perception 12 as written; the sum is 7.")
end)

------------------------------------------------------------------ fit to screen

-- On a phone the sheet keeps its drawn size and scrolls; a tick box there
-- shrinks it to the screen for the whole page at once, by style alone.
test("sheets: on a phone, a tick in Fit to screen shows the whole page at once", "dm", function()
  page(TAMSIN, RANGER)
  local w = sheets.draw()
  has(w.html, '<label class="gmsheets-fit"><input type="checkbox"> Fit to screen</label><div class="gmsheets-page"><svg ',
    "a tick box over the drawing, which a tap works with no Lua")
  hasnt(w.markdown, "Fit to screen", "on the page only")
  hasnt(sheets.printed.draw(), "<input")
  local style = SRC["GM Sheets"]:match("```space%-style\n(.-)\n```")
  has(style:match("\n%.gmsheets%-fit%s*(%b{})") or "", "display: none;", "no box on a wider screen, where the sheet fits")
  local phone = style:match("@media screen and %(max%-width: 600px%)%s*(%b{})")
  ok(phone, "a rule for a phone")
  has(phone:match("%.gmsheets%-fit%s*(%b{})") or "", "display: inline-flex;", "the box shows on a phone")
  local fit = phone:match("%.gmsheets:has%(%.gmsheets%-fit input:checked%) %.gmsheets%-page svg%s*(%b{})")
  ok(fit, "ticked, the sheet it sits over")
  has(fit, "max-width: 100%;", "shrinks to the screen's width")
  ok(phone:find(".gmsheets-page svg {\n    max-width: none;", 1, true), "and unticked keeps its size")
end)
