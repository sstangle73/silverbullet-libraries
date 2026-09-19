---
tags: meta/library
name: "Library/Storie/GM Kit"
description: "Session tracking and fog-of-war publishing for tabletop RPG campaigns. Keeps play state out of your adventure pages so the adventure stays publishable."
author: "Steven Storie"
version: "2.4.0"
---

# GM Kit

Run a campaign from one SilverBullet space while keeping **what happened at the table** completely separate from **the adventure as written**.

Your adventure pages are never touched. Who the party met, who died, where they went, what they found and what they have learned all live in `State/` in the DM space, so the adventure itself stays clean enough to compile into a book.

## Layout it expects

One DM space containing the others as subfolders, each bind-mounted as its own SilverBullet space:

    dm/            this library lives here
      Planning/    the adventure, never written to by this library
      Player/      what the players see, plus their own Notes/
      State/       play state, written by this library
      Sessions/    decision logs, written by this library

People, places, factions and items are the Planning pages inside a `People/`, `Places/`, `Factions/` or `Items/` folder, at any depth.

## Buttons

**The GM bar.** In the DM space, every Planning page gets a bar across the top. It shows whether the players can see the page, with a button to reveal it or take it back: ◉ revealed and published, ◉ revealed but not published yet, or ○ hidden. A person adds *Mark met* and *Mark dead…*, a faction adds *Mark met*, a place adds *Mark visited*, and an item adds *Mark found*. Once something is recorded, the bar says when: "✓ Met in session 3". An item with uses shows how many are left, with buttons to use one and to refund one. A page that hands out an item, or shows its rules, gets a row for that item as well: see *Items*.

**The header.** Three buttons: the session table, *Log a decision* and *Publish to players*.

**Notifications.** Marking, revealing, unrevealing and starting a session each come with *Undo*. A reveal also offers *Publish now*.

**Taking a page back.** *Unreveal* takes a page off the revealed list and deletes the copy the players were sent, so a page revealed or published by mistake is gone from the Player space at once. *Undo* puts both back, and so does revealing it and publishing again. A page that isn't revealed but that the players still have a copy of, say one hidden before 2.4, shows ◐ on its bar, with *Delete their copy*.

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
| `GM: Mark Found` | | Records that the party found an item, starts counting its uses, and offers to reveal it |
| `GM: Spend Use` | | Uses one of an item's uses |
| `GM: Refund Use` | | Gives one back |
| `GM: Reveal Page` | | Adds a Planning page to the revealed list |
| `GM: Unreveal Page` | | Takes a page back: off the revealed list, and the players' copy deleted |
| `GM: Publish to Players` | | Copies every revealed page into the Player space, stripping `## DM Only` sections |
| `GM: Log Decision` | `Ctrl-Alt-d` | Appends to this session's log |
| `GM: Next Session` | | Increments the session counter |

On a person's page, `GM: Mark Met` marks that person. Anywhere else it opens a list of people and factions, with the ones already met at the bottom. The other marks work the same way, and so do reveal and unreveal on any Planning page; off one, `GM: Unreveal Page` lists what the players can see or still have. `GM: Hide Page`, its name before 2.4, still works. Found, use and refund also act at once on a page with a row for just one item. Publishing and starting a session ask first.

## Items

An item is a Planning page in an `Items/` folder. Marking it found records the session but doesn't reveal the page, because a party can carry a thing before it knows what it is. The notification offers *Reveal*, and so does the item's row until you press it.

**Uses.** A page hands out an item when a GM Party count on it names the item:

    It holds ${party.count{"grin", plus = 1, item = "World/Items/Tube"}}.

That page's bar gets a row for the item, "Tube: six grins here", with *Mark found*. Found there, its uses start at that count for the party of the moment, and its rows and its own bar show what is left, "●●●●○○ 4 of 6 grins left", with *Use a grin* and *Refund a grin*. Each has *Undo*. Marked found from its own page, an item takes the count of the page that hands it out, and asks where when several do. An item that nothing hands out is found without uses.

**Rules in a scene.** A page that shows an item's rules with `![[World/Items/Tube#Rules]]` gets a row for it too, so wherever the rules are, the uses are.

## Where the state goes

- `State/Revealed`: one link per revealed Planning page
- `State/People/<name>`, `State/Places/<name>`: met, dead, visited, with a log
- `State/Items/<name>`: found, the uses left of those found, and where, with a log
- `Sessions/Session N`: decisions, one line each

## Players' own notes

Publishing writes into `Player/` and **replaces** what is there, except `Player/Notes/`, which it never touches. Nothing in `Player/` is ever deleted except the copy of a page you unreveal.

## Live values in players' copies

The Player space runs only its own code, so a copy can't lean on the DM's libraries. Publishing puts in the Markdown face of any `${...}` that gives a widget with one: GM Party's numbers go in as your party's, "seven grins" rather than the rule. Everything else stays live, and the Player space evaluates it against what it can see: a query there lists only what has been published.

## Changes in 2.4

*Unreveal* replaces *Hide*. Hide took a page off the revealed list but left the players their published copy unless you caught a button in its notification; unrevealing deletes that copy too, with *Undo*. The bar says whether a revealed page has been published yet, and marks a page the players still have a copy of after it came off the list.

A space's `CONFIG` page is no longer an adventure page. Before 2.4 it could be revealed, and publishing would then have copied Planning's settings over the Player space's own.

## Changes in 2.3.1

Marks work in SilverBullet. Every mark, and the bar of any page that shows an item's rules, stopped with "attempt to index a userdata value": Space Lua won't call a method straight on the two values `gsub` gives, and plain Lua, where the libraries were tested, quietly keeps the first.

## Changes in 2.3

Items: *Mark found*, uses counted from the page that hands an item out, *Use* and *Refund* with *Undo*, and a row on the bar of each page that hands out an item or shows its rules. Finding offers to reveal rather than revealing.

## Changes in 2.2

Publishing puts in the Markdown face of widgets that have one, as above.

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
  Items    = { found = true },
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
  -- gsub gives two values, and Space Lua won't call a method on the pair:
  -- the brackets keep the first.
  head = (("\n" .. head):gsub("\n" .. key .. ":[^\n]*", function()
    found = true
    return "\n" .. line
  end, 1)):sub(2)
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

-- A players' copy carries no code the Player space can't run: each ${...}
-- that gives a widget with a Markdown face goes in as that Markdown. The rest
-- stays live, so a query in the Player space sees only what was published.
function gm.print(text)
  if not text:find("${", 1, true) then return text end
  local found = {}
  local function walk(node)
    if node.type == "LuaDirective" then
      found[#found + 1] = node
    elseif node.children then
      for _, child in ipairs(node.children) do walk(child) end
    end
  end
  walk(markdown.parseMarkdown(text))
  for i = #found, 1, -1 do
    local node = found[i]
    local ok, value = pcall(function()
      return spacelua.evalExpression(spacelua.parseExpression(text:sub(node.from + 3, node.to - 1)))
    end)
    if ok and type(value) == "table" and value._isWidget and type(value.markdown) == "string" then
      text = text:sub(1, node.from) .. value.markdown .. text:sub(node.to + 1)
    end
  end
  return text
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
      '${widgets.commandButton("Unreveal a page…", "GM: Unreveal Page")} ' ..
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

-- An adventure page: in Planning, but not its index, its CONFIG, libraries
-- or build output.
function gm.isPlanningPage(page)
  local prefix = gm.config.planningPrefix
  if not page or not page:startsWith(prefix) then return false end
  local rel = page:sub(#prefix + 1)
  return rel ~= "index" and rel ~= "CONFIG" and not rel:startsWith("Library/")
    and not rel:startsWith("Build/")
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

-- "People", "Places", "Factions" or "Items", from the page's folder.
function gm.kind(page)
  return page:match("/(People)/") or page:match("/(Places)/") or page:match("/(Factions)/")
    or page:match("/(Items)/")
end

function gm.statePath(page)
  return gm.config.stateFolder .. (gm.kind(page) or "Other") .. "/" .. gm.name(page)
end

function gm.readState(page)
  local path = gm.statePath(page)
  if not space.pageExists(path) then return {} end
  return gm.frontmatter(space.readPage(path))
end

-- Where publishing puts a page, or nil for the pages it skips: anything but an
-- adventure page, so never a space's index, CONFIG or libraries, and never
-- the players' Notes.
function gm.playerCopy(page)
  if not gm.isPlanningPage(page) then return nil end
  local rel = page:sub(#gm.config.planningPrefix + 1)
  if rel:startsWith(gm.config.playerNotes) then return nil end
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
  -- A party can carry a thing before it knows what it is, so finding one
  -- offers to reveal its page instead of revealing it.
  found = {
    field = "found", value = "true", session = "found_session",
    done = "Found in session ", reveals = false, offers = true,
    pick = "Found", ask = "What did the party find?",
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

-- Records a mark. extra can add state fields, replace the log entry, and
-- add a note to the notification, as finding an item does for its uses.
function gm.mark(page, mark, detail, extra)
  extra = extra or {}
  local m, s = gm.marks[mark], gm.currentSession()
  local name, state = gm.name(page), gm.readState(page)
  if state[m.field] == m.value then
    gm.notify(name .. ": already recorded. " .. m.done .. (state[m.session] or "?") .. ".")
    return false
  end
  local path = gm.statePath(page)
  local before = space.pageExists(path) and space.readPage(path) or nil
  local entry = extra.entry or (mark == "dead" and "died" or mark)
  if detail and detail ~= "" then entry = entry .. " - " .. detail end
  local fields = { [m.field] = m.value, [m.session] = s }
  for k, v in pairs(extra.fields or {}) do fields[k] = v end
  gm.recordState(page, fields, "Session " .. s .. ": " .. entry)
  local revealed = m.reveals and page:startsWith(gm.config.planningPrefix)
                   and gm.setRevealed(page, true)
  gm.refresh()
  local actions = {}
  if m.offers and page:startsWith(gm.config.planningPrefix) and not gm.isRevealed(page) then
    actions[#actions + 1] = { name = "Reveal", run = function() gm.reveal(page) end }
  end
  actions[#actions + 1] = { name = "Undo", run = function()
    if before then gm.write(path, before) else space.deletePage(path) end
    if revealed then gm.setRevealed(page, false) end
    gm.refresh()
    gm.notify("Undone: " .. name .. " is no longer marked " .. mark)
  end }
  gm.notify(name .. ": " .. m.done:lower() .. s .. (extra.note or "") ..
            (revealed and ", and revealed" or "") .. ".", actions)
  return true
end

function gm.markDead(page)
  local state = gm.readState(page)
  if state.status == "dead" then return gm.mark(page, "dead") end
  local how = editor.prompt("How did " .. gm.name(page) .. " die? (optional)", "")
  if how == nil then return false end
  return gm.mark(page, "dead", how:match("^%s*(.-)%s*$"))
end

------------------------------------------------------------------ items

-- The Planning page a link in the adventure names: World/Items/Tube, a
-- path from this space's root, or a name that only one page ends with.
function gm.resolve(ref)
  ref = ref:match("^%s*(.-)%s*$"):gsub("%.md$", "")
  local prefix = gm.config.planningPrefix
  if space.pageExists(prefix .. ref) then return prefix .. ref end
  if ref:startsWith(prefix) and space.pageExists(ref) then return ref end
  local tail, found = "/" .. ref:lower(), nil
  for _, page in ipairs(gm.planningPages()) do
    if ("/" .. page:lower()):endsWith(tail) then
      if found then return nil end
      found = page
    end
  end
  return found
end

local function int(n)
  return string.format("%d", n)
end

-- "a grin", "an arrow", "a use"
local function a(noun)
  local an = noun:match("^[aeiouAEIOU]") and not noun:match("^[uU][^aeiouAEIOU][aeiouAEIOU]")
  return (an and "an " or "a ") .. noun
end

-- What a page hands out: each GM Party count on it that names an item, as
-- { item, page, count, text, unit, units, at }, with the count for the
-- party as it is now. The count is read by running the expression with a
-- stand-in for party.count that keeps the rule it is given.
function gm.handouts(page, text)
  local out = {}
  text = text or (space.pageExists(page) and space.readPage(page)) or ""
  if not (party and party.value) or not text:find("item%s*=") then return out end
  local nodes = {}
  local function walk(node)
    if node.type == "LuaDirective" then
      nodes[#nodes + 1] = node
    elseif node.children then
      for _, child in ipairs(node.children) do walk(child) end
    end
  end
  walk(markdown.parseMarkdown(text))
  for _, node in ipairs(nodes) do
    local src = text:sub(node.from + 3, node.to - 1)
    if src:match("^%s*party%.count%s*[{(]") and src:find("item%s*=") then
      local rules = {}
      local stand = setmetatable({
        count = function(spec)
          rules[#rules + 1] = spec
          return ""
        end,
      }, { __index = party })
      pcall(function()
        spacelua.evalExpression(spacelua.parseExpression(src), { party = stand })
      end)
      for _, spec in ipairs(rules) do
        local item = type(spec) == "table" and type(spec.item) == "string" and gm.resolve(spec.item)
        local ok, count = pcall(party.value, spec)
        local shown, face = pcall(party.count, spec)
        if item and ok and shown then
          out[#out + 1] = {
            item = item, page = page, count = count, text = face.markdown, at = node.from,
            unit = spec[1], units = spec[2] or party.plural(spec[1]),
          }
        end
      end
    end
  end
  return out
end

-- The items a page shows part of with ![[...]], such as their rules.
function gm.transcludedItems(text)
  local out, at, fence = {}, 0, nil
  if not text:find("![[", 1, true) then return out end
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    local mark = line:sub(1, 3)
    if fence then
      if mark == fence then fence = nil end
    elseif mark == "```" or mark == "~~~" then
      fence = mark
    else
      for ref in (line:gsub("`[^`]*`", "")):gmatch("!%[%[([^%]|#]+)") do
        local item = gm.resolve(ref)
        if item and gm.kind(item) == "Items" then out[#out + 1] = { item = item, at = at } end
      end
    end
    at = at + #line + 1
  end
  return out
end

-- The items a page hands out or shows, in page order and not counting the
-- page itself, and what the page hands out of each.
function gm.itemsOn(page)
  if not space.pageExists(page) then return {}, {} end
  local text = space.readPage(page)
  local all, given = {}, {}
  for _, h in ipairs(gm.handouts(page, text)) do
    all[#all + 1] = h
    given[h.item] = given[h.item] or h
  end
  for _, t in ipairs(gm.transcludedItems(text)) do all[#all + 1] = t end
  table.sort(all, function(x, y) return x.at < y.at end)
  local items, seen = {}, { [page] = true }
  for _, x in ipairs(all) do
    if not seen[x.item] then
      seen[x.item] = true
      items[#items + 1] = x.item
    end
  end
  return items, given
end

-- Every page that hands an item out, first by page name.
function gm.handoutsOf(item)
  local out = {}
  for _, page in ipairs(gm.planningPages()) do
    local text = space.readPage(page)
    if text:find("item%s*=") then
      for _, h in ipairs(gm.handouts(page, text)) do
        if h.item == item then
          out[#out + 1] = h
          break
        end
      end
    end
  end
  return out
end

-- Marks an item found. Its uses start at the count on the page it was found
-- on: `from`, if that page hands it out; else the one page that does, or the
-- one picked when several do. Nothing handing it out, it has no uses.
function gm.markFound(item, from)
  if gm.readState(item).found == "true" then return gm.mark(item, "found") end
  local choices = {}
  if from then
    for _, h in ipairs(gm.handouts(from)) do
      if h.item == item then
        choices[1] = h
        break
      end
    end
  end
  if #choices == 0 then choices = gm.handoutsOf(item) end
  local h = choices[1]
  if #choices > 1 then
    local pages, notes = {}, {}
    for i, c in ipairs(choices) do
      pages[i] = c.page
      notes[c.page] = c.text
    end
    local page = gm.pick("Found", "Where did the party find " .. gm.name(item) .. "?", pages, notes)
    if not page then return false end
    for _, c in ipairs(choices) do
      if c.page == page then h = c end
    end
  end
  if not h then return gm.mark(item, "found") end
  return gm.mark(item, "found", nil, {
    fields = {
      uses = int(h.count), uses_found = int(h.count), unit = h.unit, units = h.units,
      found_in = '"[[' .. h.page .. ']]"',
    },
    entry = "found in [[" .. h.page .. "]], with " .. h.text,
    note = ", with " .. h.text,
  })
end

-- "●●●●○○ 4 of 6 grins left" from a state record or a query's page, or ""
-- for an item without uses. plain leaves out the pips.
function gm.usesText(state, plain)
  local uses, top = tonumber(state.uses), tonumber(state.uses_found)
  if not uses then return "" end
  local one, many = state.unit or "use", state.units or "uses"
  local text
  if top then
    text = int(uses) .. " of " .. int(top) .. " " .. (top == 1 and one or many) .. " left"
  else
    text = int(uses) .. " " .. (uses == 1 and one or many) .. " left"
  end
  if not plain and top and top <= 12 and uses <= top then
    text = string.rep("●", uses) .. string.rep("○", top - uses) .. " " .. text
  end
  return text
end

-- Spends one of an item's uses (delta -1) or refunds one (+1), with Undo.
function gm.spend(item, delta)
  local name, state = gm.name(item), gm.readState(item)
  local uses, top = tonumber(state.uses), tonumber(state.uses_found)
  if state.found ~= "true" or not uses then
    gm.notify(name .. " has no uses to count", nil, "warning")
    return false
  end
  local unit, units = state.unit or "use", state.units or "uses"
  local after = uses + delta
  if after < 0 then
    gm.notify(name .. ": no " .. units .. " left")
    return false
  end
  if top and after > top then
    gm.notify(name .. ": all " .. int(top) .. " " .. (top == 1 and unit or units) .. " are there already")
    return false
  end
  local path, s = gm.statePath(item), gm.currentSession()
  local before = gm.read(path)
  local what = a(unit) .. (delta < 0 and " used" or " refunded")
  local text = gm.setFrontmatter(before, "uses", int(after))
  gm.write(path, gm.appendItem(text, "Session " .. s .. ": " .. what .. ", " .. int(after) .. " left"))
  gm.refresh()
  gm.notify(name .. ": " .. what .. ". " .. gm.usesText(gm.readState(item), true) .. ".", {
    { name = "Undo", run = function()
      gm.write(path, before)
      gm.refresh()
      gm.notify("Undone: " .. name .. " is back to " .. gm.usesText(gm.readState(item), true))
    end },
  })
  return true
end

-- The found items a use can come off (spend) or go back to (refund).
function gm.withUses(refund)
  local pages, notes = {}, {}
  for _, page in ipairs(gm.planningPages()) do
    if gm.kind(page) == "Items" then
      local state = gm.readState(page)
      local uses, top = tonumber(state.uses), tonumber(state.uses_found)
      if state.found == "true" and uses and (refund and (not top or uses < top) or (not refund and uses > 0)) then
        pages[#pages + 1] = page
        notes[page] = gm.usesText(state, true)
      end
    end
  end
  return pages, notes
end

-- The item a command acts on: the open page if it is one of `pages`, the
-- one of them the open page has a row for, or one picked. Also returns the
-- open page when the item came off its rows, so finding it there takes
-- that page's count.
function gm.pickItem(label, help, pages, notes)
  local current, allowed = editor.getCurrentPage(), {}
  for _, page in ipairs(pages) do
    if page == current then return current end
    allowed[page] = true
  end
  if gm.isPlanningPage(current) then
    local here = {}
    for _, item in ipairs((gm.itemsOn(current))) do
      if allowed[item] then here[#here + 1] = item end
    end
    if #here == 1 then return here[1], current end
    if #here > 1 then
      local item = gm.pick(label, help, here, notes)
      return item, item and current or nil
    end
  end
  return gm.pick(label, help, pages, notes)
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

-- Whether the players can see a page: "published" (revealed, and they have
-- their copy), "revealed" (on the list, not published yet), "stale" (off the
-- list, but they still have a copy) or "hidden".
function gm.visibility(page)
  local copy = gm.playerCopy(page)
  local has = copy ~= nil and space.pageExists(copy)
  if gm.isRevealed(page) then
    return has and "published" or "revealed"
  end
  return has and "stale" or "hidden"
end

-- Takes a page back from the players: off the revealed list, and the copy
-- they were sent deleted. Undo puts both back.
function gm.unreveal(page)
  local name, copy = gm.name(page), gm.playerCopy(page)
  local copyText = copy and space.pageExists(copy) and space.readPage(copy) or nil
  local listed = gm.setRevealed(page, false)
  if not listed and not copyText then
    gm.notify(name .. " isn't revealed, and the players have no copy of it")
    return false
  end
  if copyText then space.deletePage(copy) end
  gm.refresh()
  local message
  if listed and copyText then
    message = "Unrevealed " .. name .. ": it's off the revealed list, and the players' copy is deleted."
  elseif listed then
    message = "Unrevealed " .. name .. ". It was never published, so the players never had it."
  else
    message = "Deleted the players' copy of " .. name .. ", which wasn't revealed any more."
  end
  gm.notify(message, {
    { name = "Undo", run = function()
      if listed then gm.setRevealed(page, true) end
      if copyText then gm.write(copy, copyText) end
      gm.refresh()
      gm.notify("Undone: " .. name .. (copyText and " is back with the players" or " is revealed again"))
    end },
  })
  return true
end

-- The name before 2.4.
function gm.hide(page)
  return gm.unreveal(page)
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
    local text = gm.print(gm.stripSecrets(space.readPage(page)))
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

-- An item's uses, and the buttons to spend and refund one, added to a bar.
local function usesParts(item, state, add, note)
  local uses, top = tonumber(state.uses), tonumber(state.uses_found)
  if state.found ~= "true" or not uses then return end
  local unit = state.unit or "use"
  note(gm.usesText(state))
  if uses > 0 then add(gm.button("Use " .. a(unit), function() gm.spend(item, -1) end)) end
  if not top or uses < top then
    add(gm.button("Refund " .. a(unit), function() gm.spend(item, 1) end))
  end
end

-- What the players can see of a page, with the buttons that change it.
-- `quiet` leaves out the states where they can see it.
local function visibilityParts(page, add, note, quiet)
  local seen = gm.visibility(page)
  if seen == "stale" then
    note("◐ Not revealed, but the players still have a copy")
    add(gm.button("Delete their copy", function() gm.unreveal(page) end))
    add(gm.button("Reveal", function() gm.reveal(page) end))
  elseif seen == "hidden" then
    note("○ Hidden from players")
    add(gm.button("Reveal", function() gm.reveal(page) end))
  elseif not quiet then
    note(seen == "published" and "◉ Revealed to players" or "◉ Revealed, not published yet")
    add(gm.button("Unreveal", function() gm.unreveal(page) end))
  end
end

-- A row on a page's bar for an item the page hands out or shows: found or
-- not, the uses left, and whether the players can see the item's page.
function gm.itemRow(item, from, handout)
  local state = gm.readState(item)
  local spec = { class = "gmkit-item" }
  local function add(x) spec[#spec + 1] = x end
  local function note(text) add(dom.span { class = "gmkit-bar-note", text }) end
  note("**[[" .. item .. "|" .. gm.name(item) .. "]]**")
  if state.found == "true" then
    note("✓ Found in session " .. (state.found_session or "?"))
    usesParts(item, state, add, note)
    visibilityParts(item, add, note, true)
  else
    if handout then note(handout.text .. " here") end
    add(gm.button("Mark found", function() gm.markFound(item, from) end))
  end
  return dom.div(spec)
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
  visibilityParts(page, add, note)
  for _, mark in ipairs({ "met", "dead", "visited", "found" }) do
    local m = gm.marks[mark]
    if can[mark] then
      if state[m.field] == m.value then
        note((mark == "dead" and "† " or "✓ ") .. m.done .. (state[m.session] or "?"))
      elseif mark == "dead" then
        add(gm.button("Mark dead…", function() gm.markDead(page) end))
      elseif mark == "found" then
        add(gm.button("Mark found", function() gm.markFound(page) end))
      else
        add(gm.button("Mark " .. mark, function() gm.mark(page, mark) end))
      end
    end
  end
  if can.found then usesParts(page, state, add, note) end
  if space.pageExists(gm.statePath(page)) then
    note("[[" .. gm.statePath(page) .. "|Play state]]")
  end
  local items, given = gm.itemsOn(page)
  for _, item in ipairs(items) do add(gm.itemRow(item, page, given[item])) end
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

-- The open Planning page, or one picked from those the players can see or
-- still have a copy of.
local function unrevealCommand()
  local page = editor.getCurrentPage()
  if not gm.isPlanningPage(page) then
    local pages, notes, listed = {}, {}, {}
    local function hasCopy(n)
      local copy = gm.playerCopy(n)
      return copy ~= nil and space.pageExists(copy)
    end
    for _, n in ipairs(gm.readRevealed()) do
      pages[#pages + 1] = n
      listed[n] = true
      notes[n] = hasCopy(n) and "Published" or "Revealed, not published yet"
    end
    for _, n in ipairs(gm.planningPages()) do
      if not listed[n] and hasCopy(n) then
        pages[#pages + 1] = n
        notes[n] = "Not revealed, but the players still have a copy"
      end
    end
    page = gm.pick("Unreveal", "Which page should the players lose?", pages, notes)
  end
  if page then gm.unreveal(page) end
end

command.define {
  name = "GM: Unreveal Page",
  run = unrevealCommand
}

-- The name before 2.4, so buttons made with it still work.
command.define {
  name = "GM: Hide Page",
  hide = true,
  run = unrevealCommand
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
  name = "GM: Mark Found",
  run = function()
    local pages, notes = gm.markable("found")
    local page, from = gm.pickItem("Found", "What did the party find? Recorded for session " ..
                                   gm.currentSession() .. ".", pages, notes)
    if page then gm.markFound(page, from) end
  end
}

local function useCommand(refund)
  return function()
    local pages, notes = gm.withUses(refund)
    if #pages == 0 then
      gm.notify(refund and "Nothing the party found is missing a use" or
                "Nothing the party found has a use left")
      return
    end
    local item = gm.pickItem(refund and "Refund" or "Use", refund and
      "Which item gets a use back?" or "Which item did they use? Recorded for session " ..
      gm.currentSession() .. ".", pages, notes)
    if item then gm.spend(item, refund and 1 or -1) end
  end
end

command.define {
  name = "GM: Spend Use",
  run = useCommand(false)
}

command.define {
  name = "GM: Refund Use",
  run = useCommand(true)
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

/* A row of its own for each item the page hands out or shows. */
.gmkit-item {
  flex: 1 0 100%;
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px 10px;
  padding-top: 6px;
  border-top: 1px solid var(--editor-widget-background-color);
}

/* The widget's own Copy and Reload overlay would cover the bar's buttons. */
.sb-lua-top-widget:has(.gmkit-bar) .button-bar {
  display: none !important;
}
```
