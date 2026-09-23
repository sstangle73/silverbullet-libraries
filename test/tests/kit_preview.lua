------------------------------------------------------------------ Publish preview and report
-- GM: Preview Publish works out every players' copy as Publish would and
-- writes only a page of the DM's that says what would happen; Publish
-- keeps a lasting report of what each publish sent and kept back.

local V_PREVIEW = "State/Publish Preview"
local V_REPORT = "State/Publish Report"
local V_TRAVEL = "Adventure/Rules/Travel"
local V_HOUSE = "Adventure/Rules/House Rules"
local V_MARA = "Adventure/World/People/Mara"
local V_WREN = "Adventure/World/People/Wren"
local V_HEIR = "Adventure/World/People/The Heir"
local V_CRYPT = "Adventure/World/Places/Crypt"
local V_MILL = "Adventure/World/Places/Mill"
local V_BARE = "Adventure/World/Places/Nowhere"
local V_ORCHARD = "Adventure/World/Maps/The Old Orchard"
local V_NL = string.char(10)

local function vPublish(...)
  H.confirms = { true, ... }
  return gm.publish()
end

-- A page for each reason a copy is kept back, one with an embed of a part
-- the players don't get, and a map page, which only the DM sees. Nowhere
-- has something in it, so it doesn't hide its name, and prints as nothing.
local function useTrouble()
  H.pages[V_HEIR] = "---\ntype: npc\n---\n\n<!--#dm-->\n# The Heir\n<!--/dm-->\n\nThe Warden's son.\n"
  H.pages[V_MILL] = "---\ntype: place\n---\n\n# Mill\n\n## DM Only Notes\n\nThe miller is the Warden's brother.\n"
  H.pages[V_BARE] = "---\ntype: place\n---\n\n${widget.markdown(\"\")}\n"
  H.pages[V_CRYPT] = "---\ntype: place\n---\n\n# Crypt\n\n![[World/People/The Warden#What They Want]]\n\nEnd.\n"
  gm.writeRevealed({ V_HOUSE, V_HEIR, V_MILL, V_BARE, V_CRYPT, V_ORCHARD, "Adventure/Gone" })
end

-- The lines of a page's `## heading` section, up to the next heading.
local function section(text, heading)
  local out, inside = {}, false
  for line in (text .. V_NL):gmatch("([^\n]*)\n") do
    if line:match("^## ") then
      inside = line == "## " .. heading
    elseif inside and line ~= "" then
      out[#out + 1] = line
    end
  end
  return table.concat(out, V_NL)
end

test("preview: writes its own page and nothing else, and opens it", "dm", function()
  local writes = #H.writes
  ok(gm.previewPublish())
  eq(#H.writes, writes + 1, "one page written")
  eq(H.writes[#H.writes], V_PREVIEW)
  eq(H.current, V_PREVIEW)
  for name in pairs(H.pages) do
    ok(not name:match("^Player/Rules/") and not name:match("^Player/Campaign/"), "sent " .. name)
  end
  local page = H.pages[V_PREVIEW]
  has(page, "---\ntype: state\n---\n\n# Publish preview\n\nWhat publishing would do, worked out ")
  ok(page:match("worked out %d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d UTC in session 1%. Nothing has been sent"),
     "when, to the second, and the session")
  eq(section(page, "New copies"), table.concat({
    "- [[Adventure/Campaign/Session Zero]]: the whole page",
    "- [[Adventure/Rules/House Rules]]: the whole page",
    "- [[Adventure/Rules/Travel]]: the whole page",
    "- [[Adventure/World/Factions/The Guild]]: the whole page",
  }, V_NL))
  local n = lastNotification()
  eq(n.message, "Preview: 4 new, 0 changed, 0 unchanged. Nothing has been sent.")
  eq(n.kind, "info")
end)

test("preview: a page revealed in part or by name says what goes", "dm", function()
  H.pages["Adventure/World/Places/Door"] = "---\ntype: place\n---\n\n# Door\n\n## The ${gm.version} Door\n\nIt creaks.\n"
  gm.writeRevealed({ V_MARA .. "#Who They Are", "Adventure/World/People/The Warden#The Warden",
    "Adventure/World/Places/Door#The ${gm.version} Door" })
  gm.previewPublish()
  eq(section(H.pages[V_PREVIEW], "New copies"), table.concat({
    "- [[Adventure/World/People/Mara]]: “Who They Are”",
    "- [[Adventure/World/People/The Warden]]: its name only",
    "- [[Adventure/World/Places/Door]]: “The \\$\\{gm.version\\} Door”",
  }, V_NL), "a part's name as words, escaped")
end)

test("preview: a changed copy shows the lines that change, as code", "dm", function()
  vPublish()
  local travel = H.pages[V_TRAVEL]
  local first = travel:match("\n# [^\n]*\n\n([^\n]+)\n")
  ok(first, "Travel has a first paragraph")
  H.pages[V_TRAVEL] = travel:gsub(first:gsub("%p", "%%%0"), "The road is shut at dusk.", 1) ..
    "\nAsk `[[Old Tam]]` for rope: ${party.n()} lengths of it.\n"
  gm.previewPublish()
  local page = H.pages[V_PREVIEW]
  eq(section(page, "Changed copies"), table.concat({
    "- [[Adventure/Rules/Travel]]: 1 line removed, 2 added",
    "```",
    "− A day's travel is eight hours on foot. The ford can be crossed in daylight; at night it takes a …",
    "+ The road is shut at dusk.",
    "+ Ask `[[Old Tam]]` for rope: five lengths of it.",
    "```",
  }, V_NL), "a live value as the players get it, in fenced code")
  has(page, "## Changed copies\n\n- [[Adventure/Rules/Travel]]: 1 line removed, 2 added\n\n```\n",
      "the fence on a line of its own, a blank line before it")
  eq(section(page, "Unchanged"), table.concat({
    "- [[Adventure/Campaign/Session Zero]]",
    "- [[Adventure/Rules/House Rules]]",
    "- [[Adventure/World/Factions/The Guild]]",
  }, V_NL))
  eq(lastNotification().message, "Preview: 0 new, 1 changed, 3 unchanged. Nothing has been sent.")
  hasnt(H.pages["Player/Rules/Travel"], "shut at dusk", "the players' copy is as it was")
end)

test("preview: a long change is cut short, and so is a long line", "dm", function()
  gm.writeRevealed({ V_TRAVEL })
  vPublish()
  local more = {}
  for i = 1, 11 do more[i] = "Milestone " .. i .. "." end
  local long = "The road " .. string.rep("winds on and on ", 12) .. "to the ford."
  H.pages[V_TRAVEL] = H.pages[V_TRAVEL] .. V_NL .. long .. V_NL .. table.concat(more, V_NL) .. V_NL
  gm.previewPublish()
  local lines = section(H.pages[V_PREVIEW], "Changed copies")
  has(lines, "- [[Adventure/Rules/Travel]]: 12 lines added\n```\n")
  has(lines, "\n+ Milestone 7.\n… and 4 more\n```")
  hasnt(lines, "Milestone 8.")
  local cut = lines:match("\n%+ (The road[^\n]*)\n")
  ok(cut, "the long line is there")
  ok(#cut <= 104, "cut near 100 characters: " .. #cut)
  eq(cut:sub(-4), " …", "cut at a space, and says so")
end)

-- The lines of a text outside fenced code, as a reader that knows only
-- fences at the start of a line finds them.
local function outsideFences(text)
  local out, fence = {}, nil
  for line in (text .. V_NL):gmatch("([^\n]*)\n") do
    local run = line:match("^(```+)") or line:match("^(~~~+)")
    if fence then
      if run and run:sub(1, 1) == fence:sub(1, 1) and #run >= #fence and line:match("^[`~]+%s*$") then
        fence = nil
      end
    elseif run then
      fence = run
    else
      out[#out + 1] = line
    end
  end
  return table.concat(out, V_NL)
end

test("preview: page text it quotes is in fenced code, where nothing in it runs", "dm", function()
  gm.writeRevealed({ V_TRAVEL })
  vPublish()
  -- the players' copy as it was, with a marker a hand put in it since
  H.pages["Player/Rules/Travel"] = H.pages["Player/Rules/Travel"] .. "\n<!--#dm-->\n"
  H.pages[V_TRAVEL] = H.pages[V_TRAVEL] .. table.concat({
    "", "The ferry runs on ${gm.version}, and ``` three ticks.",
    "", "```space-lua", "gm.config.sessionPage = \"Elsewhere\"", "```",
    "", "```space-style", "body { color: red }", "```", "",
  }, V_NL)
  gm.previewPublish()
  local page = H.pages[V_PREVIEW]
  for _, quoted in ipairs({ "${gm.version}", "```space-lua", "```space-style", "<!--#dm-->", "Elsewhere" }) do
    has(page, quoted, "quoted")
    hasnt(outsideFences(page), quoted, "outside a fence")
  end
  has(page, "\n````\n− <!--#dm-->\n+ The ferry runs on ${gm.version}, and ``` three ticks.\n+ ```space-lua\n",
      "a fence longer than any run of backticks it holds")
  -- SilverBullet's own reading: only the page's two buttons are live
  local live = {}
  for _, node in ipairs(markdown.parseMarkdown(page).children) do
    live[#live + 1] = page:sub(node.from + 1, node.to)
  end
  eq(list(live), '${widgets.commandButton("Publish now", "GM: Publish to Players")} | ' ..
     '${widgets.commandButton("Preview again", "GM: Preview Publish")}')
  eq(H.pages["Session Table"]:match("\nsession: (%d+)"), "1", "and nothing ran")
end)

test("preview: a name it can't link is escaped, not run", "dm", function()
  gm.writeRevealed({ "Adventure/World/People/${gm.version} and `x` <!--/dm-->" })
  gm.previewPublish()
  local gone = section(H.pages[V_PREVIEW], "Revealed but no longer there")
  eq(gone, "- Adventure/World/People/\\$\\{gm.version\\} and \\`x\\` \\<\\!--/dm--\\>")
  hasnt(gone, "${")
  hasnt(gone, "<!--")
end)

test("preview: a copy that only gains a blank line says so", "dm", function()
  gm.writeRevealed({ V_TRAVEL })
  vPublish()
  H.pages[V_TRAVEL] = H.pages[V_TRAVEL] .. V_NL
  gm.previewPublish()
  eq(section(H.pages[V_PREVIEW], "Changed copies"),
     "- [[Adventure/Rules/Travel]]: only its blank lines, or the order of its lines")
end)

test("preview: what is kept back, and why, and everything else that doesn't go", "dm", function()
  useTrouble()
  H.pages["Player/World/People/The Heir"] = "# The Heir\n"
  H.pages["Player/World/People/Nobody"] = "# Nobody\n"
  gm.previewPublish()
  local page = H.pages[V_PREVIEW]
  eq(section(page, "Kept back"), table.concat({
    "- [[Adventure/World/People/The Heir]] hides its name in DM-only text. The players still have a " ..
      "copy of it, which gives them its name: take it back with *Delete their copy* on its bar",
    "- [[Adventure/World/Places/Mill]] still has DM-only marks (a DM Only heading)",
    "- [[Adventure/World/Places/Nowhere]] would be empty",
    "The players keep what they have of these until each is put right.",
  }, V_NL))
  eq(section(page, "Embeds left out"), table.concat({
    "- In [[Adventure/World/Places/Crypt]]:",
    "```",
    "![[World/People/The Warden#What They Want]]",
    "```",
    "The players don't have what these show.",
  }, V_NL))
  eq(section(page, "Revealed but no longer there"), "- Adventure/Gone")
  eq(section(page, "Only for the DM"), "- [[Adventure/World/Maps/The Old Orchard]] is left out: only the DM may see it")
  eq(section(page, "Copies no revealed page makes any more"), table.concat({
    "- [[Player/World/People/Nobody]]",
    "Renamed, deleted or unrevealed since they were published: publishing asks before it deletes them.",
  }, V_NL))
  ok(H.pages["Player/World/People/Nobody"], "listed, not deleted")
  eq(lastNotification().message,
     "Preview: 2 new, 0 changed, 0 unchanged, 3 kept back, 1 copy to delete. Nothing has been sent.")
end)

test("preview: a part renamed since it was revealed is named", "dm", function()
  gm.writeRevealed({ V_MARA .. "#Who They Are", V_MARA .. "#Her Boat" })
  gm.previewPublish()
  eq(section(H.pages[V_PREVIEW], "Revealed but no longer there"),
     "- [[Adventure/World/People/Mara]]: “Her Boat” isn't one of its parts any more")
end)

test("preview: with nothing revealed it says so", "dm", function()
  gm.writeRevealed({})
  gm.previewPublish()
  has(H.pages[V_PREVIEW], "\n\nNothing is revealed yet, so there is nothing to publish.\n")
  hasnt(H.pages[V_PREVIEW], "\n## ")
end)

test("preview: what it lists is what Publish then sends", "dm", function()
  useTrouble()
  gm.setRevealed(V_TRAVEL, true)
  vPublish()
  H.pages[V_TRAVEL] = H.pages[V_TRAVEL] .. "\nOne more milestone.\n"
  gm.setRevealed(V_WREN, true)
  local plan = gm.publishPlan()
  gm.previewPublish()
  eq(lastNotification().message,
     "Preview: 1 new, 1 changed, 2 unchanged, 3 kept back. Nothing has been sent.")
  H.confirms = { true }
  runAction(lastNotification(), "Publish now")
  eq(H.confirmsAsked[#H.confirmsAsked], "Publish 4 revealed pages to the players? Each replaces " ..
     "its earlier copy in Player/, and Player/Notes/ is never touched.")
  has(lastNotification().message, "Published to players: 1 new, 1 updated, 2 unchanged.")
  eq(#plan.copies, 4)
  for _, c in ipairs(plan.copies) do eq(H.pages[c.copy], c.text, c.copy .. " as the plan made it") end
end)

test("preview: the page's button publishes, and each place Publish is offers it", "dm", function()
  gm.previewPublish()
  has(H.pages[V_PREVIEW], '${widgets.commandButton("Publish now", "GM: Publish to Players")} ' ..
      '${widgets.commandButton("Preview again", "GM: Preview Publish")}')
  ok(H.commands["GM: Preview Publish"], "a command")
  local eye, send
  for _, b in ipairs(config.get("actionButtons")) do
    if b.command == "GM: Preview Publish" then eye = b end
    if b.command == "GM: Publish to Players" then send = b end
  end
  ok(eye, "a header button")
  eq(eye.icon, "eye")
  ok(eye.priority > send.priority and eye.priority < 0.75, "just ahead of Publish, after Log a roll")
  gm.writeRevealed({ V_HOUSE })
  has(H.pages["State/Revealed"], '${widgets.commandButton("Preview publishing", "GM: Preview Publish")} ' ..
      '${widgets.commandButton("Publish to players", "GM: Publish to Players")}')
  gm.reveal(V_MARA)
  local n = lastNotification()
  eq(list(names(n.options.actions)), "Publish now | Preview | Undo")
  runAction(n, "Preview")
  eq(H.current, V_PREVIEW)
  has(section(H.pages[V_PREVIEW], "New copies"), "- [[Adventure/World/People/Mara]]: the whole page")
  gm.revealPart("Adventure/World/People/The Warden", "Who They Are")
  eq(list(names(lastNotification().options.actions)), "Publish now | Preview | Undo")
end)

------------------------------------------------ the lasting report

test("report: a publish writes when, what it sent, and what it kept back and why", "dm", function()
  useTrouble()
  H.pages["Player/World/People/Nobody"] = "# Nobody\n"
  vPublish(false)
  local report = H.pages[V_REPORT]
  ok(report, "a report")
  has(report, "---\ntype: state\n---\n\n# Publish report\n\n")
  has(report, '${widgets.commandButton("Preview publishing", "GM: Preview Publish")}')
  local heading, body = report:match("\n(## [^\n]*)\n\n(.*)$")
  ok(heading:match("^## %d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d UTC, session 1$"), heading)
  eq(body, table.concat({
    "Published to players: 2 new, 0 updated, 0 unchanged.",
    "",
    "- New: [[Adventure/Rules/House Rules]], [[Adventure/World/Places/Crypt]]",
    "- Kept back: [[Adventure/World/People/The Heir]] hides its name in DM-only text",
    "- Kept back: [[Adventure/World/Places/Mill]] still has DM-only marks (a DM Only heading)",
    "- Kept back: [[Adventure/World/Places/Nowhere]] would be empty",
    "- Embeds left out, in [[Adventure/World/Places/Crypt]]:",
    "",
    "```",
    "![[World/People/The Warden#What They Want]]",
    "```",
    "",
    "- Revealed but no longer there: Adventure/Gone",
    "- [[Adventure/World/Maps/The Old Orchard]] is left out: only the DM may see it",
    "- Kept, though no revealed page makes it any more: [[Player/World/People/Nobody]]",
    "",
  }, V_NL))
  local n = lastNotification()
  has(n.message, "Published to players: 2 new, 0 updated, 0 unchanged.")
  runAction(n, "Open report")
  eq(H.current, V_REPORT)
end)

test("report: copies deleted, and their Undo", "dm", function()
  gm.writeRevealed({})
  H.pages["Player/World/People/Nobody"] = "# Nobody\n"
  vPublish()
  has(H.pages[V_REPORT], "\nNothing to publish.\n\n- Deleted, as no revealed page makes it any more: " ..
      "Player/World/People/Nobody\n")
  eq(list(names(lastNotification().options.actions)), "Open report | Undo")
end)

test("report: the last five publishes, newest first", "dm", function()
  gm.writeRevealed({ V_TRAVEL })
  for i = 1, 6 do
    H.pages[V_TRAVEL] = H.pages[V_TRAVEL] .. "\nMilestone " .. i .. ".\n"
    vPublish()
  end
  local report = H.pages[V_REPORT]
  eq(count(report, "\n## "), 5)
  eq(count(report, "- New: [[Adventure/Rules/Travel]]"), 0, "the first, which made the copy, has gone")
  eq(count(report, "- Updated: [[Adventure/Rules/Travel]]"), 5)
end)

test("report: a publish that sends and keeps back nothing adds nothing, nor does a repeat", "dm", function()
  vPublish()
  local report = H.pages[V_REPORT]
  eq(count(report, "\n## "), 1)
  local writes = #H.writes
  vPublish()
  eq(#H.writes, writes, "nothing sent, nothing kept back: nothing written, the report included")
  eq(H.pages[V_REPORT], report)
  eq((lastNotification().options or {}).actions, nil, "and nothing to open")
  H.pages[V_MILL] = "---\ntype: place\n---\n\n# Mill\n\n## DM Only Notes\n\nA secret.\n"
  gm.setRevealed(V_MILL, true)
  vPublish()
  eq(count(H.pages[V_REPORT], "\n## "), 2, "something kept back is worth a line")
  writes = #H.writes
  vPublish()
  eq(#H.writes, writes, "the same kept back as last time, and nothing sent, adds nothing")
  has(lastNotification().message, "Kept back:")
  eq(list(names(lastNotification().options.actions)), "Open report", "the report still says why")
end)

test("report: nothing to publish, with something kept back, is reported", "dm", function()
  H.pages[V_MILL] = "---\ntype: place\n---\n\n# Mill\n\n## DM Only Notes\n\nA secret.\n"
  gm.writeRevealed({ V_MILL })
  eq(gm.publish(), false)
  eq(#H.confirmsAsked, 0)
  has(H.pages[V_REPORT], "\nNothing to publish.\n\n- Kept back: [[Adventure/World/Places/Mill]] still has " ..
      "DM-only marks (a DM Only heading)\n")
  runAction(lastNotification(), "Open report")
  eq(H.current, V_REPORT)
end)

test("report: a publish declined, or with nothing revealed, writes none", "dm", function()
  H.confirms = { false }
  eq(gm.publish(), false)
  eq(H.pages[V_REPORT], nil)
  gm.writeRevealed({})
  eq(gm.publish(), false)
  eq(H.pages[V_REPORT], nil)
end)
