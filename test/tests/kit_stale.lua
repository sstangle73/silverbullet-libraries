------------------------------------------------------------------ A stale tab
-- A tab runs the Lua it loaded until System: Reload, but indexes a newer
-- GM Kit the moment one is installed. Until it reloads, it writes nothing:
-- every action refuses with a warning, before any picker or prompt, and
-- the bar says so first.

local S_LIB = "Library/Storie/GM Kit"
local S_WARDEN = "Adventure/World/People/The Warden"
local S_TAM = "Adventure/World/People/Old Tam"
local S_HOUSE = "Adventure/Rules/House Rules"
local S_SCENE2 = "Adventure/Campaign/Act I/Scene 2"
local S_LANTERN = "Adventure/World/Items/Lantern"
local S_POOL = "Adventure/Campaign/Act I/Scene 4"
local S_NL = string.char(10)

-- A scene that sets one check, for the rolls.
local S_POOL_TEXT = table.concat({
  "---", "type: scene", "scene: 4", "scene_title: The Mill Pool", "book_order: 14", "---", "",
  "# Scene 4 — The Mill Pool", "",
  "## The bank", "",
  "**Wisdom (Perception)** — what the bank gives you.", "",
  "| | |", "|---|---|",
  "| **Any roll** | Bootprints in the mud |",
  "| **10** | One set is a child's |", "",
}, S_NL)

-- The page `at` as GM Kit's own page with another version, as a newer
-- release installed into the space would leave it: the index reads it at
-- once, and this tab still runs the code it loaded.
local function install(version, at)
  local text, n = SRC["GM Kit"]:gsub('\nversion: "[^"\n]*"\n', '\nversion: "' .. version .. '"\n', 1)
  eq(n, 1, "GM Kit's page has a version")
  H.pages[at or S_LIB] = text
end

local function staleSays(version)
  return "This tab runs GM Kit " .. gm.version .. ", but the space has " .. version ..
         ": reload it (System: Reload, Ctrl-Alt-R) first."
end

-- Runs fn and holds it to a refusal: one warning, and nothing written,
-- deleted or asked.
local function refused(what, fn)
  local writes, deleted, boxes = #H.writes, #H.deleted, #H.filterBoxes
  local prompts, confirms, notes = #H.promptsAsked, #H.confirmsAsked, #H.notifications
  fn()
  eq(#H.writes, writes, what .. " wrote")
  eq(#H.deleted, deleted, what .. " deleted")
  eq(#H.filterBoxes, boxes, what .. " asked with a picker")
  eq(#H.promptsAsked, prompts, what .. " prompted")
  eq(#H.confirmsAsked, confirms, what .. " asked to confirm")
  eq(#H.notifications, notes + 1, what .. ": one warning, and only that")
  local n = lastNotification()
  eq(n.kind, "warning", what)
  eq(n.message, staleSays("9.9.9"), what)
end

test("stale: the code's version is the library page's own", "dm", function()
  local version = SRC["GM Kit"]:match('^%-%-%-\n.-\nversion: "([^"\n]*)"\n')
  ok(version, "GM Kit's frontmatter has a version")
  eq(gm.version, version, "gm.version and the frontmatter are kept equal")
  eq(H.pages[S_LIB], SRC["GM Kit"], "the space holds this very page")
end)

test("stale: a tab that runs the version the space has is current, and writes", "dm", function()
  eq(gm.stale(), nil)
  eq(gm.refuse(), false)
  hasnt(textOf(gm.bar(S_WARDEN).html), "⟳")
  ok(gm.mark(S_WARDEN, "met"))
  ok(H.pages["State/People/The Warden"], "the mark was written")
end)

test("stale: a newer GM Kit in the space says what to do", "dm", function()
  install("9.9.9")
  eq(gm.stale(), staleSays("9.9.9"))
  eq(gm.refuse(), true)
  local n = lastNotification()
  eq(n.kind, "warning")
  eq(n.message, staleSays("9.9.9"))
  install("3.0.0")
  eq(gm.stale(), staleSays("3.0.0"), "an older one too: the two differ, whichever is newer")
end)

test("stale: the bar says so first, with a glyph and words, and a button to reload", "dm", function()
  install("9.9.9")
  local bar = gm.bar(S_WARDEN)
  eq(textOf(bar.html.children[1]), "⟳ Reload this tab: GM Kit 9.9.9 is installed, this tab runs " .. gm.version)
  eq(list(buttonsOf(bar.html)), "Reload | Reveal | Reveal part… | Mark met | Mark dead…")
  local reloads = 0
  H.commands["System: Reload"] = { name = "System: Reload", run = function() reloads = reloads + 1 end }
  click(bar, "Reload")
  eq(reloads, 1, "the bar's button runs System: Reload")
  gm.refuse()
  runAction(lastNotification(), "Reload")
  eq(reloads, 2, "and so does the warning's")
end)

test("stale: every action refuses, and writes and asks nothing", "dm", function()
  H.pages[S_POOL] = S_POOL_TEXT
  -- what there is to take back, recorded while the tab was current
  ok(gm.mark(S_TAM, "met"))
  ok(gm.markFound(S_LANTERN, S_SCENE2))
  H.picks = { "Wisdom (Perception)", "10 or more" }
  ok(gm.logRoll(S_POOL))
  install("9.9.9")
  local check = gm.checks(S_POOL)[1]
  local band = gm.bands(check.rungs)[2]
  refused("mark met", function() eq(gm.mark(S_WARDEN, "met"), false) end)
  refused("mark dead", function() eq(gm.markDead(S_WARDEN), false) end)
  refused("mark visited", function() eq(gm.mark("Adventure/World/Places/Fordtown", "visited"), false) end)
  refused("mark started", function() eq(gm.mark(S_POOL, "started"), false) end)
  refused("mark found", function() eq(gm.markFound(S_LANTERN, S_SCENE2), false) end)
  refused("unmark", function() eq(gm.unmark(S_TAM, "met"), false) end)
  refused("use", function() eq(gm.spend(S_LANTERN, -1), false) end)
  refused("refund", function() eq(gm.spend(S_LANTERN, 1), false) end)
  refused("reveal", function() eq(gm.reveal(S_WARDEN), false) end)
  refused("pick a part", function() eq(gm.pickPart(S_WARDEN), nil) end)
  refused("reveal a part", function() eq(gm.revealPart(S_WARDEN, "Who They Are"), false) end)
  refused("unreveal", function() eq(gm.unreveal(S_HOUSE), false) end)
  refused("hide", function() eq(gm.hide(S_HOUSE), false) end)
  refused("publish", function() eq(gm.publish(), false) end)
  refused("preview", function() eq(gm.previewPublish(), false) end)
  refused("draft a recap", function() eq(gm.draftRecap(1), false) end)
  refused("publish a recap", function() eq(gm.publishRecap("Sessions/Session 1 Recap"), false) end)
  refused("log a decision", function() eq(gm.logDecision(), false) end)
  refused("next session", function() eq(gm.nextSession(), false) end)
  refused("log a roll", function() eq(gm.logRoll(S_POOL), false) end)
  refused("log a check", function() eq(gm.logCheck(S_POOL, check), false) end)
  refused("record a roll", function() eq(gm.recordRoll(S_POOL, check, { band = band }), false) end)
  refused("another roll", function() eq(gm.logOtherRoll(S_POOL), false) end)
  refused("unlog a roll", function() eq(gm.unlogRoll(S_POOL, check), false) end)
  refused("pick a roll to unlog", function() eq(gm.pickUnlog(S_POOL), false) end)
  eq(gm.readState(S_TAM).met, "true", "what was recorded stays recorded")
end)

test("stale: every command refuses before it asks anything", "dm", function()
  install("9.9.9")
  for _, page in ipairs({ "Session Table", S_WARDEN, S_SCENE2, S_LANTERN }) do
    H.current = page
    for _, name in ipairs({ "GM: Mark Met", "GM: Mark Dead", "GM: Mark Visited", "GM: Mark Found",
        "GM: Mark Scene Planned", "GM: Mark Scene Started", "GM: Mark Scene Finished", "GM: Unmark",
        "GM: Spend Use", "GM: Refund Use", "GM: Reveal Page", "GM: Reveal Part", "GM: Unreveal Page",
        "GM: Hide Page", "GM: Publish to Players", "GM: Preview Publish", "GM: Log Decision", "GM: Log Roll",
        "GM: Unlog Roll", "GM: Next Session", "GM: Draft Recap", "GM: Publish Recap" }) do
      refused(name .. " on " .. page, function() H.commands[name].run() end)
    end
  end
end)

test("stale: every button on a bar refuses", "dm", function()
  gm.markFound(S_LANTERN, S_SCENE2)
  H.pages["Sessions/Session 1 Recap"] = "---\ntype: recap-draft\nsession: 1\n---\n\n# Session 1\n\nThey met.\n"
  install("9.9.9")
  local recap = gm.sessionBar("Sessions/Session 1 Recap")
  eq(textOf(recap.html.children[1]), "⟳ Reload this tab: GM Kit 9.9.9 is installed, this tab runs " .. gm.version,
     "a recap's bar says so first too")
  refused("Publish recap", function() click(recap, "Publish recap") end)
  for _, page in ipairs({ S_WARDEN, S_SCENE2, S_LANTERN, S_HOUSE }) do
    local bar = gm.bar(page)
    for _, label in ipairs(buttonsOf(bar.html)) do
      if label ~= "Reload" then
        refused(label .. " on " .. page, function() click(bar, label) end)
      end
    end
  end
end)

test("stale: a character's bar says so first, and every change to a character refuses", "dm", function()
  local bram = "Party/Bram"
  H.pages[bram] = table.concat({
    "---", "type: pc", "level: 3", "hp: 20", "hit_dice: 3d10", "slots: [2]",
    "pact_slots: 1", "resources:", "  - {name: Second Wind, uses: 1, reset: Short Rest}", "---", "",
    "# Bram", "",
  }, S_NL)
  H.current = bram
  ok(gm.damage(bram, 5))
  local hurt = lastNotification()
  local record = H.pages["State/Characters/Bram"]
  install("9.9.9")
  local bar = gm.characterBar(bram)
  eq(textOf(bar.html.children[1]), "⟳ Reload this tab: GM Kit 9.9.9 is installed, this tab runs " .. gm.version)
  eq(buttonsOf(bar.html)[1], "Reload")
  refused("damage", function() eq(gm.damage(bram), false) end)
  refused("heal", function() eq(gm.heal(bram), false) end)
  refused("temporary", function() eq(gm.temporary(bram), false) end)
  refused("a death save", function() eq(gm.deathSave(bram, false), false) end)
  refused("a slot", function() eq(gm.slot(bram, 1, true), false) end)
  refused("a pact slot", function() eq(gm.pact(bram, true), false) end)
  refused("a Hit Point Die", function() eq(gm.hitDie(bram, true), false) end)
  refused("a resource", function() eq(gm.resource(bram, "used_second_wind", true), false) end)
  refused("inspiration", function() eq(gm.inspiration(bram, true), false) end)
  refused("a Short Rest", function() eq(gm.shortRest(bram), false) end)
  refused("a Long Rest", function() eq(gm.longRest(bram), false) end)
  refused("undo the damage", function() runAction(hurt, "Undo") end)
  for _, label in ipairs(buttonsOf(bar.html)) do
    if label ~= "Reload" then
      refused(label .. " on Bram's bar", function() click(bar, label) end)
    end
  end
  eq(H.pages["State/Characters/Bram"], record, "what was recorded stays recorded")
end)

test("stale: an Undo from before the new version came refuses too", "dm", function()
  gm.mark(S_WARDEN, "met")
  local met = lastNotification()
  local record = H.pages["State/People/The Warden"]
  gm.markFound(S_LANTERN, S_SCENE2)
  gm.spend(S_LANTERN, -1)
  local used = lastNotification()
  H.confirms = { true }
  gm.nextSession()
  local next = lastNotification()
  install("9.9.9")
  refused("undo a mark", function() runAction(met, "Undo") end)
  refused("undo a use", function() runAction(used, "Undo") end)
  refused("undo a new session", function() runAction(next, "Undo") end)
  eq(H.pages["State/People/The Warden"], record)
  eq(gm.currentSession(), 2)
end)

test("stale: a copy of GM Kit in a space held as a folder counts too", "dm", function()
  install(gm.version, "Player/Library/Storie/GM Kit")
  eq(gm.stale(), nil, "a copy of the same version")
  install("9.9.9", "Player/Library/Storie/GM Kit")
  eq(gm.stale(), staleSays("9.9.9"))
  has(textOf(gm.bar(S_WARDEN).html), "⟳ Reload this tab: GM Kit 9.9.9 is installed")
end)

test("stale: a page that only ends in GM Kit's name isn't GM Kit", "dm", function()
  install("9.9.9", "Notes/GM Kit")
  install("9.9.9", "Library/Storie/GM Kit Notes")
  install("9.9.9", "Archive/Old Library/Storie/GM Kit Draft")
  H.pages["Library/Storie/Another GM Kit"] = '---\nversion: "0.1"\n---\n'
  eq(gm.stale(), nil)
  H.pages[S_LIB] = "---\ntags: meta/library\n---\n\n# GM Kit\n"
  eq(gm.stale(), nil, "a copy with no version says nothing")
end)

test("stale: a version written as a number reads as it is written", "dm", function()
  H.pages[S_LIB] = (SRC["GM Kit"]:gsub('\nversion: "[^"\n]*"\n', "\nversion: 4.5\n", 1))
  eq(gm.stale(), staleSays("4.5"))
end)

test("stale: an index that fails says nothing, so the check never stops a write", "dm", function()
  install("9.9.9")
  local real = index.pages
  index.pages = function() error("index gone") end
  local ok1, stale = pcall(gm.stale)
  local ok2, refuse = pcall(gm.refuse)
  index.pages = real
  ok(ok1 and ok2, "neither raises")
  eq(stale, nil)
  eq(refuse, false)
end)

test("stale: reloaded, the tab runs the new code and writes again", "dm", function()
  install("9.9.9")
  eq(gm.mark(S_WARDEN, "met"), false)
  -- what System: Reload does: the space's Lua runs again, the new code's
  gm.version = "9.9.9"
  eq(gm.stale(), nil)
  ok(gm.mark(S_WARDEN, "met"))
  has(H.pages["State/People/The Warden"], "met: true")
end)
