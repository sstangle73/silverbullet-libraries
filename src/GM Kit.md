---
tags: meta/library
name: "Library/Storie/GM Kit"
description: "Session tracking and fog-of-war publishing for tabletop RPG campaigns. Keeps play state out of your adventure pages so the adventure stays publishable."
author: "Steven Storie"
version: "2.0.0"
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

## Commands

| Command | Key | Does |
|---|---|---|
| `GM: Mark Met` | `Ctrl-Alt-m` | Records the party met the NPC on the current page, stamps the session, reveals the page |
| `GM: Mark Dead` | | Records a death and how it happened |
| `GM: Mark Visited` | | Records the party visited the current place, reveals it |
| `GM: Reveal Page` | | Adds the current Planning page to the revealed list |
| `GM: Hide Page` | | Removes it |
| `GM: Publish to Players` | | Copies every revealed page into the Player space, stripping `## DM Only` sections |
| `GM: Log Decision` | `Ctrl-Alt-d` | Appends to this session's log |
| `GM: Next Session` | | Increments the session counter |

## Where the state goes

- `State/Revealed`: one link per revealed Planning page
- `State/People/<name>`, `State/Places/<name>`: met, dead, visited, with a log
- `Sessions/Session N`: decisions, one line each

## Players' own notes

Publishing writes into `Player/` and **replaces** what is there, except `Player/Notes/`, which it never touches.

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

function gm.currentSession()
  local r = query[[
    from p = index.pages()
    where p.name == gm.config.sessionPage
    select p.session
    limit 1
  ]]
  return tonumber(r[1]) or 1
end

function gm.setFrontmatter(text, key, value)
  local line = key .. ": " .. tostring(value)
  if not text:match("^%-%-%-") then
    return "---\n" .. line .. "\n---\n\n" .. text
  end
  local pattern = "\n" .. key .. ":[^\n]*"
  if text:match(pattern) then
    return (text:gsub(pattern, "\n" .. line, 1))
  end
  return (text:gsub("^(%-%-%-\n)", "%1" .. line .. "\n", 1))
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

function gm.patch(page, key, value)
  space.writePage(page, gm.setFrontmatter(space.readPage(page), key, value))
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
    "Planning pages the players have learned about. Managed by GM Kit:",
    "`GM: Reveal Page`, `GM: Hide Page`, `GM: Publish to Players`.", "",
  }
  for _, n in ipairs(list) do lines[#lines + 1] = "- [[" .. n .. "]]" end
  space.writePage(gm.config.revealedPage, table.concat(lines, "\n") .. "\n")
end

function gm.setRevealed(page, on)
  local out, found = {}, false
  for _, n in ipairs(gm.readRevealed()) do
    if n == page then
      found = true
      if on then out[#out + 1] = n end
    else
      out[#out + 1] = n
    end
  end
  if on and not found then out[#out + 1] = page end
  gm.writeRevealed(out)
end

function gm.statePath(page)
  local kind = page:match("/(People)/") or page:match("/(Places)/")
            or page:match("/(Factions)/") or "Other"
  return gm.config.stateFolder .. kind .. "/" .. (page:match("([^/]+)$") or page)
end

function gm.recordState(page, fields)
  local path = gm.statePath(page)
  local text
  if space.pageExists(path) then
    text = space.readPage(path)
  else
    local name = page:match("([^/]+)$") or page
    text = "---\ntype: state-record\nsubject: \"[[" .. page .. "]]\"\n---\n\n# " ..
           name .. "\n\nPlay state for [[" .. page .. "]].\n\n## Log\n"
  end
  for k, v in pairs(fields) do text = gm.setFrontmatter(text, k, v) end
  space.writePage(path, text)
  return path
end

function gm.log(path, entry)
  space.writePage(path, space.readPage(path) .. "\n- " .. entry)
end
```

```space-lua
-- priority: 10
command.define {
  name = "GM: Reveal Page",
  run = function()
    local page = editor.getCurrentPage()
    if not page:startsWith(gm.config.planningPrefix) then
      editor.flashNotification "Only Planning pages can be revealed"
      return
    end
    gm.setRevealed(page, true)
    editor.flashNotification("Revealed " .. page)
  end
}

command.define {
  name = "GM: Hide Page",
  run = function()
    gm.setRevealed(editor.getCurrentPage(), false)
    editor.flashNotification "Hidden"
  end
}

command.define {
  name = "GM: Publish to Players",
  run = function()
    local n = 0
    for _, page in ipairs(gm.readRevealed()) do
      if page:startsWith(gm.config.planningPrefix) and space.pageExists(page) then
        local relative = page:sub(#gm.config.planningPrefix + 1)
        if relative ~= "index" and not relative:startsWith(gm.config.playerNotes) then
          space.writePage(gm.config.playerFolder .. relative,
                          gm.stripSecrets(space.readPage(page)))
          n = n + 1
        end
      end
    end
    editor.flashNotification("Published " .. n .. " page(s) to players")
  end
}

command.define {
  name = "GM: Mark Met",
  key = "Ctrl-Alt-m",
  run = function()
    local page, s = editor.getCurrentPage(), gm.currentSession()
    local path = gm.recordState(page, { met = "true", met_session = s })
    gm.log(path, "Session " .. s .. ": met")
    if page:startsWith(gm.config.planningPrefix) then gm.setRevealed(page, true) end
    editor.flashNotification("Met in session " .. s)
  end
}

command.define {
  name = "GM: Mark Dead",
  run = function()
    local page, s = editor.getCurrentPage(), gm.currentSession()
    local how = editor.prompt "How did they die?" or ""
    local path = gm.recordState(page, { status = "dead", died_session = s })
    gm.log(path, "Session " .. s .. ": died" .. (how ~= "" and (" - " .. how) or ""))
    editor.flashNotification("Death recorded, session " .. s)
  end
}

command.define {
  name = "GM: Mark Visited",
  run = function()
    local page, s = editor.getCurrentPage(), gm.currentSession()
    local path = gm.recordState(page, { visited = "true", visited_session = s })
    gm.log(path, "Session " .. s .. ": visited")
    if page:startsWith(gm.config.planningPrefix) then gm.setRevealed(page, true) end
    editor.flashNotification("Visited in session " .. s)
  end
}

command.define {
  name = "GM: Log Decision",
  key = "Ctrl-Alt-d",
  run = function()
    local what = editor.prompt "What did they decide?"
    if not what or what == "" then return end
    local s = gm.currentSession()
    local log = gm.config.sessionsFolder .. "Session " .. s
    local text
    if space.pageExists(log) then
      text = space.readPage(log)
    else
      text = "---\ntype: session\nsession: " .. s .. "\n---\n\n# Session " .. s .. "\n\n## Decisions\n"
    end
    space.writePage(log, text .. "\n- " .. what)
    editor.flashNotification("Logged to " .. log)
  end
}

command.define {
  name = "GM: Next Session",
  run = function()
    local n = gm.currentSession() + 1
    gm.patch(gm.config.sessionPage, "session", n)
    editor.flashNotification("Now session " .. n)
  end
}
```
