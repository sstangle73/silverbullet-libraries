---
tags: meta/library
name: "Library/Storie/GM Kit"
description: "Fog-of-war publishing and session tracking for tabletop RPG campaigns. Reveal pages into a read-only player space, mark NPCs met, log decisions, track sessions."
author: "Steven Storie"
version: "1.0.0"
---

# GM Kit

Fog-of-war publishing and session tracking for tabletop RPG campaigns run in
SilverBullet.

Keep your whole campaign in one space, mark what the party has learned, and push
just that subset into a **player-facing subfolder** — which a second, read-only
SilverBullet instance can serve as the players' wiki. One source of truth, no
second copy to keep in sync.

> **note** Rename me
> `sstangle73` must be your GitHub username, in **both** the folder path and the
> `name:` frontmatter key above. They have to match or installation breaks.

## Install

`Library: Install`, then the `share.uri` from this page's frontmatter.

## Setup

Two instances over one folder tree:

```
mycampaign/          ← DM instance, read-write
mycampaign/Player/   ← player instance, READ-ONLY
```

Because `Player/` is inside the DM space, the DM instance can write into it
directly. Run the player instance read-only so the two clients never fight over
the same files.

## Commands

| Command | Key | Does |
|---|---|---|
| `GM: Reveal Page` | | `revealed: true` |
| `GM: Hide Page` | | `revealed: false` |
| `GM: Publish to Players` | | Copies every revealed page into the player folder, stripping DM-only sections |
| `GM: Mark Met` | `Ctrl-Alt-m` | Flags an NPC met, stamps the session, reveals it |
| `GM: Log Decision` | `Ctrl-Alt-d` | Prompts, appends to this session's log |
| `GM: Next Session` | | Increments the session counter |

## Configuration

Override in any `space-lua` block **without** a priority comment — those load
last, so yours wins:

```lua
gm.config.playerFolder = "Wiki/"
gm.config.sessionPage  = "Play/Tracker"
gm.config.dmHeading    = "Secrets"
```

## DM-only sections

Anything under a `## DM Only` heading is stripped on publish, so secrets can sit
on the same page as player-facing text:

```markdown
# The Tin Woodman

Commander of the army. Tin from the neck down.

## DM Only

The heart in his chest isn't his.
```

The published page ends at "Tin from the neck down."

## Implementation

```space-lua
-- priority: 10
gm = gm or {}

gm.config = {
  playerFolder = "Player/",
  sessionPage  = "Campaign/Session Table",
  dmHeading    = "DM Only",
}

--- Current session number, read from the configured session page.
function gm.currentSession()
  local r = query[[
    from p = index.pages()
    where p.name == gm.config.sessionPage
    select p.session
    limit 1
  ]]
  return tonumber(r[1]) or 1
end

--- Set or replace a frontmatter key in raw page text.
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

--- Drop every DM-only section, up to the next top- or second-level heading.
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

--- Patch one frontmatter key on a page, in place.
function gm.patch(page, key, value)
  space.writePage(page, gm.setFrontmatter(space.readPage(page), key, value))
end
```

```space-lua
-- priority: 10
command.define {
  name = "GM: Reveal Page",
  run = function()
    gm.patch(editor.getCurrentPage(), "revealed", "true")
    editor.flashNotification "Revealed"
  end
}

command.define {
  name = "GM: Hide Page",
  run = function()
    gm.patch(editor.getCurrentPage(), "revealed", "false")
    editor.flashNotification "Hidden"
  end
}

command.define {
  name = "GM: Publish to Players",
  run = function()
    local folder = gm.config.playerFolder
    local pages = query[[
      from p = index.pages()
      where p.revealed == true and not p.name:startsWith(folder)
    ]]
    local n = 0
    for _, p in ipairs(pages) do
      space.writePage(folder .. p.name, gm.stripSecrets(space.readPage(p.name)))
      n = n + 1
    end
    editor.flashNotification("Published " .. n .. " page(s)")
  end
}

command.define {
  name = "GM: Mark Met",
  key = "Ctrl-Alt-m",
  run = function()
    local page = editor.getCurrentPage()
    local s = gm.currentSession()
    local text = space.readPage(page)
    text = gm.setFrontmatter(text, "met", "true")
    text = gm.setFrontmatter(text, "met_session", s)
    text = gm.setFrontmatter(text, "revealed", "true")
    space.writePage(page, text)
    editor.flashNotification("Met in session " .. s)
  end
}

command.define {
  name = "GM: Log Decision",
  key = "Ctrl-Alt-d",
  run = function()
    local what = editor.prompt "What did they decide?"
    if not what or what == "" then return end
    local s = gm.currentSession()
    local log = "Campaign/Sessions/Session " .. s
    local text
    if space.pageExists(log) then
      text = space.readPage(log)
    else
      text = "---\ntype: session\nsession: " .. s ..
             "\nstatus: draft\nrevealed: false\n---\n\n# Session " .. s ..
             "\n\n## Decisions\n"
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
