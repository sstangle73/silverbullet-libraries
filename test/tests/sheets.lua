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
