---
tags: meta/library
name: "Library/Storie/GM Kit"
description: "Session tracking and fog-of-war publishing for tabletop RPG campaigns. Keeps play state out of your adventure pages so the adventure stays publishable."
author: "Steven Storie"
version: "2.1.0"
---

# GM Kit

Run a campaign from one SilverBullet space while keeping **what happened at the table** completely separate from **the adventure as written**.

Your adventure pages are never touched. Who the party met, who died, where they went and what they have learned all live in `State/` in the DM space, so the adventure itself stays clean enough to compile into a book.

## Layout it expects

One DM space containing the others as subfolders, each bind-mounted as its own SilverBullet space:

    dm/            this library lives here
      Planning/    the adventure, never written to by this library
      Player/      what the players see, plus their own Notes/
      State/       play state, written by this library
      Sessions/    decision logs, written by this library

People, places and factions are the Planning pages inside a `People/`, `Places/` or `Factions/` folder, at any depth.

## Buttons

**The GM bar.** In the DM space, every Planning page gets a bar across the top. It shows whether the players can see the page, with a button to reveal or hide it. A person adds *Mark met* and *Mark dead…*, a faction adds *Mark met*, and a place adds *Mark visited*. Once something is recorded, the bar says when: "✓ Met in session 3".

**The header.** Three buttons: the session table, *Log a decision* and *Publish to players*.

**Notifications.** Marking, revealing and starting a session each come with *Undo*. A reveal also offers *Publish now*, and hiding a page the players already have offers to delete their copy.

**Your own pages.** Every command works as a button, and a command that acts on a page asks which one when you aren't on one:

    ${widgets.commandButton("Met…", "GM: Mark Met")}
    ${widgets.commandButton("Log a decision", "GM: Log Decision")}

## Commands

| Command | Key | Does |
|---|---|---|
| `GM: Session Table` | | Opens the session page |
| `GM: Mark Met` | `Ctrl-Alt-m` | Records that the party met a person or faction, stamps the session, reveals the page |
| `GM: Mark Dead` | | Records a death and how it happened |
| `GM: Mark Visited` | | Records that the party visited a place, reveals it |
| `GM: Reveal Page` | | Adds a Planning page to the revealed list |
| `GM: Hide Page` | | Removes it |
| `GM: Publish to Players` | | Copies every revealed page into the Player space, stripping `## DM Only` sections |
| `GM: Log Decision` | `Ctrl-Alt-d` | Appends to this session's log |
| `GM: Next Session` | | Increments the session counter |

On a person's page, `GM: Mark Met` marks that person. Anywhere else it opens a list of people and factions, with the ones already met at the bottom. The other marks work the same way, and so do reveal and hide on any Planning page. Publishing and starting a session ask first.

## Where the state goes

- `State/Revealed`: one link per revealed Planning page
- `State/People/<name>`, `State/Places/<name>`: met, dead, visited, with a log
- `Sessions/Session N`: decisions, one line each

## Players' own notes

Publishing writes into `Player/` and **replaces** what is there, except `Player/Notes/`, which it never touches.

## Changes in 2.1

Buttons: the GM bar, the header buttons, pickers, and *Undo*. Marking someone met a second time no longer moves their session of first contact. Publishing reports what it added and changed, and leaves unchanged player pages alone. The session number is read straight from the session page, so it is right the moment it changes.

## Changes from 1.x

1.x wrote `met` and `revealed` into the adventure pages' own frontmatter, so a published adventure shipped with one particular party's history baked in. 2.0 keeps all of it in `State/`.

## Implementation

```space-lua
-- priority: 10
gm = gm or {}

gm.config = {
  sessionPage    = "Session Table",
  sessionsFolder = "Sessions/",
  stateFolder    = "State/",
  revealedPage   = "State/Revealed",
  planningPrefix = "Planning/",
  playerFolder   = "Player/",
  playerNotes    = "Notes/",
  dmHeading      = "DM Only",
}

-- The Planning folders GM Kit tracks, and what their pages can be marked.
gm.kinds = {
  People   = { met = true, dead = true },
  Factions = { met = true },
  Places   = { visited = true },
}

-- "---\n<head>---\n<rest>" as head and rest, or nil without frontmatter.
function gm.splitFrontmatter(text)
  if text:sub(1, 4) ~= "---\n" then return nil end
  local s, e = text:find("\n%-%-%-[ \t]*\n", 4)
  if not s then
    s, e = text:find("\n%-%-%-[ \t]*$", 4)
    if not s then return nil end
  end
  return text:sub(5, s), text:sub(e + 1)
end

-- Frontmatter as a table of strings.
function gm.frontmatter(text)
  local fields = {}
  local head = gm.splitFrontmatter(text)
  for line in (head or ""):gmatch("([^\n]*)\n") do
    local k, v = line:match("^([%w_]+):%s*(.-)%s*$")
    if k then fields[k] = v:match('^"(.*)"$') or v end
  end
  return fields
end

function gm.setFrontmatter(text, key, value)
  local line = key .. ": " .. tostring(value)
  local head, rest = gm.splitFrontmatter(text)
  if not head then
    return "---\n" .. line .. "\n---\n\n" .. text
  end
  local found = false
  head = ("\n" .. head):gsub("\n" .. key .. ":[^\n]*", function()
    found = true
    return "\n" .. line
  end, 1):sub(2)
  if not found then head = head .. line .. "\n" end
  return "---\n" .. head .. "---\n" .. rest
end

function gm.stripSecrets(text)
  local out, skipping = {}, false
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    if line:match("^##%s+" .. gm.config.dmHeading) then
      skipping = true
    elseif skipping and line:match("^##?%s") then
      skipping = false
    end
    if not skipping then out[#out + 1] = line end
  end
  return table.concat(out, "\n")
end

-- Reads a page, saving it first if it is open so no typing is lost.
function gm.read(page)
  if editor.getCurrentPage() == page then editor.save() end
  return space.readPage(page)
end

-- Writes a page, reloading it if it is open so the editor never shows a stale copy.
function gm.write(page, text)
  space.writePage(page, text)
  if editor.getCurrentPage() == page then editor.reloadPage() end
end

-- Redraws the bar and any buttons or queries on the open page.
function gm.refresh()
  pcall(function() codeWidget.refreshAll() end)
end

-- Actions become buttons on the notification: { { name = "Undo", run = fn } }.
function gm.notify(message, actions, kind)
  local options
  if actions then options = { timeout = 10000, actions = actions } end
  editor.flashNotification(message, kind or "info", options)
end

function gm.name(page)
  return page:match("([^/]+)$") or page
end

function gm.patch(page, key, value)
  local text = space.pageExists(page) and gm.read(page) or ("# " .. gm.name(page) .. "\n")
  gm.write(page, gm.setFrontmatter(text, key, value))
end

-- Read from the page rather than the index, so it is right straight after a change.
function gm.currentSession()
  local page = gm.config.sessionPage
  if not space.pageExists(page) then return 1 end
  return tonumber(gm.frontmatter(space.readPage(page)).session) or 1
end

function gm.readRevealed()
  local list = {}
  if not space.pageExists(gm.config.revealedPage) then return list end
  for name in space.readPage(gm.config.revealedPage):gmatch("%- %[%[([^%]]+)%]%]") do
    list[#list + 1] = name
  end
  return list
end

function gm.writeRevealed(list)
  table.sort(list)
  local lines = {
    "---", "type: state", "---", "",
    "# Revealed to players", "",
    "Planning pages the players have learned about, kept by GM Kit. " ..
      "Publishing copies each of them into `" .. gm.config.playerFolder .. "`.", "",
    '${widgets.commandButton("Reveal a page…", "GM: Reveal Page")} ' ..
      '${widgets.commandButton("Hide a page…", "GM: Hide Page")} ' ..
      '${widgets.commandButton("Publish to players", "GM: Publish to Players")}', "",
  }
  for _, n in ipairs(list) do lines[#lines + 1] = "- [[" .. n .. "]]" end
  gm.write(gm.config.revealedPage, table.concat(lines, "\n") .. "\n")
end

function gm.isRevealed(page)
  for _, n in ipairs(gm.readRevealed()) do
    if n == page then return true end
  end
  return false
end

-- Adds or removes a page. Returns whether the list changed.
function gm.setRevealed(page, on)
  local out, found = {}, false
  for _, n in ipairs(gm.readRevealed()) do
    if n == page then found = true else out[#out + 1] = n end
  end
  if found == on then return false end
  if on then out[#out + 1] = page end
  gm.writeRevealed(out)
  return true
end

-- An adventure page: in Planning, but not its index, libraries or build output.
function gm.isPlanningPage(page)
  local prefix = gm.config.planningPrefix
  if not page or not page:startsWith(prefix) then return false end
  local rel = page:sub(#prefix + 1)
  return rel ~= "index" and not rel:startsWith("Library/") and not rel:startsWith("Build/")
end

function gm.planningPages()
  local prefix = gm.config.planningPrefix
  local names = query[[
    from p = index.pages()
    where p.name:startsWith(prefix)
    order by p.name
    select p.name
  ]]
  local out = {}
  for _, name in ipairs(names) do
    if gm.isPlanningPage(name) then out[#out + 1] = name end
  end
  return out
end

-- "People", "Places" or "Factions", from the page's folder.
function gm.kind(page)
  return page:match("/(People)/") or page:match("/(Places)/") or page:match("/(Factions)/")
end

function gm.statePath(page)
  return gm.config.stateFolder .. (gm.kind(page) or "Other") .. "/" .. gm.name(page)
end

function gm.readState(page)
  local path = gm.statePath(page)
  if not space.pageExists(path) then return {} end
  return gm.frontmatter(space.readPage(path))
end

-- Where publishing puts a page, or nil for the pages it skips.
function gm.playerCopy(page)
  local prefix = gm.config.planningPrefix
  if not page:startsWith(prefix) then return nil end
  local rel = page:sub(#prefix + 1)
  if rel == "index" or rel:startsWith(gm.config.playerNotes) then return nil end
  return gm.config.playerFolder .. rel
end

-- Adds a list item to the end of a page's text.
function gm.appendItem(text, item)
  if text:sub(-1) ~= "\n" then text = text .. "\n" end
  return text .. "- " .. item .. "\n"
end

-- Creates or updates a page's play state and appends to its log.
function gm.recordState(page, fields, entry)
  local path = gm.statePath(page)
  local text
  if space.pageExists(path) then
    text = gm.read(path)
  else
    text = "---\ntype: state-record\nsubject: \"[[" .. page .. "]]\"\n---\n\n# " ..
           gm.name(page) .. "\n\nPlay state for [[" .. page .. "]].\n\n## Log\n\n"
  end
  local keys = {}
  for k in pairs(fields) do keys[#keys + 1] = k end
  table.sort(keys)
  for _, k in ipairs(keys) do text = gm.setFrontmatter(text, k, fields[k]) end
  if entry then text = gm.appendItem(text, entry) end
  gm.write(path, text)
  return path
end

function gm.log(path, entry)
  gm.write(path, gm.appendItem(gm.read(path), entry))
end

-- The marks, with the state field each sets and how it reads once set.
gm.marks = {
  met = {
    field = "met", value = "true", session = "met_session",
    done = "Met in session ", reveals = true,
    pick = "Met", ask = "Who did the party meet?",
  },
  dead = {
    field = "status", value = "dead", session = "died_session",
    done = "Died in session ", reveals = false,
    pick = "Dead", ask = "Who died?",
  },
  visited = {
    field = "visited", value = "true", session = "visited_session",
    done = "Visited in session ", reveals = true,
    pick = "Visited", ask = "Where did the party go?",
  },
}

-- Pages that can take a mark, unmarked first. If Planning has no People,
-- Places or Factions folders at all, every Planning page can.
function gm.markable(mark)
  local m, all = gm.marks[mark], gm.planningPages()
  local open, done, notes = {}, {}, {}
  for _, page in ipairs(all) do
    local kind = gm.kind(page)
    if kind and gm.kinds[kind][mark] then
      local state = gm.readState(page)
      if state[m.field] == m.value then
        done[#done + 1] = page
        notes[page] = m.done .. (state[m.session] or "?")
      else
        open[#open + 1] = page
      end
    end
  end
  if #open + #done == 0 then return all, notes end
  for _, page in ipairs(done) do open[#open + 1] = page end
  return open, notes
end

-- Asks for one of `pages`; `notes` adds a description to some of them.
function gm.pick(label, help, pages, notes)
  if #pages == 0 then
    gm.notify("There are no pages to choose from", nil, "warning")
    return nil
  end
  local prefix = gm.config.planningPrefix
  local options = {}
  for i, page in ipairs(pages) do
    options[i] = {
      name = page:startsWith(prefix) and page:sub(#prefix + 1) or page,
      description = notes and notes[page] or nil,
      orderId = i,
    }
  end
  local choice = editor.filterBox(label, options, help, "Type to filter")
  if not choice then return nil end
  for i, option in ipairs(options) do
    if option.name == choice.name then return pages[i] end
  end
end

-- The open page if it is one of `pages`, otherwise one picked from them.
function gm.target(label, help, pages, notes)
  local current = editor.getCurrentPage()
  for _, page in ipairs(pages) do
    if page == current then return current end
  end
  return gm.pick(label, help, pages, notes)
end

function gm.mark(page, mark, detail)
  local m, s = gm.marks[mark], gm.currentSession()
  local name, state = gm.name(page), gm.readState(page)
  if state[m.field] == m.value then
    gm.notify(name .. ": already recorded. " .. m.done .. (state[m.session] or "?") .. ".")
    return false
  end
  local path = gm.statePath(page)
  local before = space.pageExists(path) and space.readPage(path) or nil
  local entry = "Session " .. s .. ": " .. (mark == "dead" and "died" or mark)
  if detail and detail ~= "" then entry = entry .. " - " .. detail end
  gm.recordState(page, { [m.field] = m.value, [m.session] = s }, entry)
  local revealed = m.reveals and page:startsWith(gm.config.planningPrefix)
                   and gm.setRevealed(page, true)
  gm.refresh()
  gm.notify(name .. ": " .. m.done:lower() .. s .. (revealed and ", and revealed" or "") .. ".", {
    { name = "Undo", run = function()
      if before then gm.write(path, before) else space.deletePage(path) end
      if revealed then gm.setRevealed(page, false) end
      gm.refresh()
      gm.notify("Undone: " .. name .. " is no longer marked " .. mark)
    end },
  })
  return true
end

function gm.markDead(page)
  local state = gm.readState(page)
  if state.status == "dead" then return gm.mark(page, "dead") end
  local how = editor.prompt("How did " .. gm.name(page) .. " die? (optional)", "")
  if how == nil then return false end
  return gm.mark(page, "dead", how:match("^%s*(.-)%s*$"))
end

function gm.reveal(page)
  if not gm.setRevealed(page, true) then
    gm.notify(gm.name(page) .. " is already revealed")
    return false
  end
  gm.refresh()
  gm.notify("Revealed " .. gm.name(page) .. ". The players see it once you publish.", {
    { name = "Publish now", run = function() gm.publish() end },
    { name = "Undo", run = function()
      gm.setRevealed(page, false)
      gm.refresh()
    end },
  })
  return true
end

function gm.hide(page)
  if not gm.setRevealed(page, false) then
    gm.notify(gm.name(page) .. " isn't revealed")
    return false
  end
  gm.refresh()
  local message = "Hid " .. gm.name(page) .. " from future publishes."
  local actions = {
    { name = "Undo", run = function()
      gm.setRevealed(page, true)
      gm.refresh()
    end },
  }
  local copy = gm.playerCopy(page)
  if copy and space.pageExists(copy) then
    message = message .. " The players still have the copy published earlier."
    table.insert(actions, 1, { name = "Delete their copy", run = function()
      space.deletePage(copy)
      gm.notify("Deleted " .. copy)
    end })
  end
  gm.notify(message, actions)
  return true
end

function gm.publish()
  local pages, missing = {}, {}
  for _, page in ipairs(gm.readRevealed()) do
    if gm.playerCopy(page) then
      if space.pageExists(page) then
        pages[#pages + 1] = page
      else
        missing[#missing + 1] = page
      end
    end
  end
  if #pages == 0 then
    gm.notify("Nothing is revealed yet, so there is nothing to publish", nil, "warning")
    return false
  end
  local folder = gm.config.playerFolder
  if not editor.confirm("Publish " .. #pages ..
      (#pages == 1 and " revealed page" or " revealed pages") ..
      " to the players? Each replaces its earlier copy in " .. folder .. ", and " ..
      folder .. gm.config.playerNotes .. " is never touched.") then
    return false
  end
  local added, updated, same = 0, 0, 0
  for _, page in ipairs(pages) do
    local copy = gm.playerCopy(page)
    local text = gm.stripSecrets(space.readPage(page))
    if not space.pageExists(copy) then
      gm.write(copy, text)
      added = added + 1
    elseif space.readPage(copy) ~= text then
      gm.write(copy, text)
      updated = updated + 1
    else
      same = same + 1
    end
  end
  local message = "Published to players: " .. added .. " new, " .. updated ..
                  " updated, " .. same .. " unchanged."
  local kind = "info"
  if #missing > 0 then
    kind = "warning"
    message = message .. " Revealed but no longer there: " ..
              table.concat(missing, ", ") .. "."
  end
  gm.notify(message, nil, kind)
  return true
end

function gm.logDecision()
  local s = gm.currentSession()
  local what = editor.prompt("What did they decide? (session " .. s .. ")")
  what = what and what:match("^%s*(.-)%s*$") or ""
  if what == "" then return false end
  local log = gm.config.sessionsFolder .. "Session " .. s
  local text
  if space.pageExists(log) then
    text = gm.read(log)
  else
    text = "---\ntype: session\nsession: " .. s .. "\n---\n\n# Session " .. s .. "\n\n## Decisions\n\n"
  end
  gm.write(log, gm.appendItem(text, what))
  gm.refresh()
  gm.notify("Logged to " .. log, {
    { name = "Open log", run = function() editor.navigate(log) end },
  })
  return true
end

function gm.nextSession()
  local page, n = gm.config.sessionPage, gm.currentSession()
  if not editor.confirm("Start session " .. (n + 1) .. "? From now on, marks and " ..
      "decisions are recorded against it.") then
    return false
  end
  gm.patch(page, "session", n + 1)
  gm.refresh()
  gm.notify("Now session " .. (n + 1), {
    { name = "Undo", run = function()
      gm.patch(page, "session", n)
      gm.refresh()
      gm.notify("Back to session " .. n)
    end },
  })
  return true
end

function gm.button(label, run, primary)
  return dom.button {
    class = primary and "sb-button-primary" or "sb-button",
    onclick = function()
      local ok, err = pcall(run)
      if not ok then editor.flashNotification("GM Kit: " .. tostring(err), "error") end
    end,
    label,
  }
end

-- The bar across the top of an adventure page: what the players can see,
-- what the party has done, and a button for each thing not yet recorded.
function gm.bar(page)
  page = page or editor.getCurrentPage()
  if not gm.isPlanningPage(page) then return nil end
  local kind = gm.kind(page)
  local can = kind and gm.kinds[kind] or {}
  local state = gm.readState(page)
  local spec = {
    class = "gmkit-bar",
    dom.strong { "Session " .. gm.currentSession() },
  }
  local function add(item) spec[#spec + 1] = item end
  local function note(text) add(dom.span { class = "gmkit-bar-note", text }) end
  if gm.isRevealed(page) then
    note("◉ Revealed to players")
    add(gm.button("Hide", function() gm.hide(page) end))
  else
    note("○ Hidden from players")
    add(gm.button("Reveal", function() gm.reveal(page) end))
  end
  for _, mark in ipairs({ "met", "dead", "visited" }) do
    local m = gm.marks[mark]
    if can[mark] then
      if state[m.field] == m.value then
        note((mark == "dead" and "† " or "✓ ") .. m.done .. (state[m.session] or "?"))
      elseif mark == "dead" then
        add(gm.button("Mark dead…", function() gm.markDead(page) end))
      else
        add(gm.button("Mark " .. mark, function() gm.mark(page, mark) end))
      end
    end
  end
  if space.pageExists(gm.statePath(page)) then
    note("[[" .. gm.statePath(page) .. "|Play state]]")
  end
  return widget.new { display = "block", html = dom.div(spec) }
end
```

```space-lua
-- priority: 10
local function markCommand(mark)
  return function()
    local m = gm.marks[mark]
    local pages, notes = gm.markable(mark)
    local page = gm.target(m.pick, m.ask .. " Recorded for session " ..
                           gm.currentSession() .. ".", pages, notes)
    if not page then return end
    if mark == "dead" then gm.markDead(page) else gm.mark(page, mark) end
  end
end

command.define {
  name = "GM: Session Table",
  run = function() editor.navigate(gm.config.sessionPage) end
}

command.define {
  name = "GM: Reveal Page",
  run = function()
    local page = editor.getCurrentPage()
    if not gm.isPlanningPage(page) then
      local revealed, hidden = {}, {}
      for _, n in ipairs(gm.readRevealed()) do revealed[n] = true end
      for _, n in ipairs(gm.planningPages()) do
        if not revealed[n] then hidden[#hidden + 1] = n end
      end
      page = gm.pick("Reveal", "Which page have the players learned about?", hidden)
    end
    if page then gm.reveal(page) end
  end
}

command.define {
  name = "GM: Hide Page",
  run = function()
    local page = editor.getCurrentPage()
    if not gm.isPlanningPage(page) then
      page = gm.pick("Hide", "Which page should publishing leave out?", gm.readRevealed())
    end
    if page then gm.hide(page) end
  end
}

command.define {
  name = "GM: Publish to Players",
  run = function() gm.publish() end
}

command.define {
  name = "GM: Mark Met",
  key = "Ctrl-Alt-m",
  run = markCommand("met")
}

command.define {
  name = "GM: Mark Dead",
  run = markCommand("dead")
}

command.define {
  name = "GM: Mark Visited",
  run = markCommand("visited")
}

command.define {
  name = "GM: Log Decision",
  key = "Ctrl-Alt-d",
  run = function() gm.logDecision() end
}

command.define {
  name = "GM: Next Session",
  run = function() gm.nextSession() end
}

actionButton.define {
  icon = "clipboard",
  description = "Session table",
  command = "GM: Session Table",
  priority = 0.9,
}

actionButton.define {
  icon = "edit-3",
  description = "Log a decision",
  command = "GM: Log Decision",
  priority = 0.8,
}

actionButton.define {
  icon = "send",
  description = "Publish revealed pages to players",
  command = "GM: Publish to Players",
  priority = 0.7,
}

event.listen {
  name = "hooks:renderTopWidgets",
  run = function()
    local ok, bar = pcall(gm.bar)
    if ok then return bar end
    print("GM Kit: " .. tostring(bar))
  end
}
```

```space-style
.gmkit-bar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px 10px;
}

/* The widget's own Copy and Reload overlay would cover the bar's buttons. */
.sb-lua-top-widget:has(.gmkit-bar) .button-bar {
  display: none !important;
}
```
