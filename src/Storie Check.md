---
tags: meta/library
name: "Library/Storie/Storie Check"
description: "A health check for the Storie libraries in a space: every copy the index holds, the version each library runs and whether it is stale, GM Book's printers, and whether the small libraries' settings are the shape they read."
author: "Steven Storie"
version: "1.0.0"
---

# Storie Check

A health check for the Storie libraries in the space it runs in. Put `${storie.health()}` on any page, or run `Storie: Check Libraries`, which sums it up in a notification.

- **Copies.** Every copy of every Storie library the index holds: its page, its version, and whether `Library: Install` put it there. An installed copy carries `share.uri`, `share.hash` and `share.mode` in its frontmatter, which `Library: Update` follows; a copy put there by hand has none, and `Library: Update` skips it. Copies of one library at different depths are flagged: a space that holds others as folders runs every copy, and `Library: Update All` run there leaves one at its root.
- **Running.** For each library, the version of the Lua the tab runs, and whether a copy of its page holds another, as the library's own `stale()` finds. A library with a copy here but no Lua running isn't loaded; one whose Lua runs without a version is a library older than this check.
- **Printers.** The libraries that tell GM Book how to print their widgets, in `gmbook.printers`, and any that runs here without having told it.
- **Settings.** Whether the settings Space Switcher, Chapter Navigation and Appearances read are the shape each declares.

Every line starts with a mark and says what it means in words, so no state rests on the mark, or on colour, alone:

| Mark | Means |
|---|---|
| ✓ | As it should be |
| ⟳ | A copy holds a newer version than the tab runs: run `System: Reload` |
| ⚠ | Something to put right: the line says what |
| ✗ | Installed here, but not running |
| ○ | Not here, or not set, which may be as you want it |

It checks the space it runs in, so run it from inside each space. A space that holds others as folders sees their copies as well, and runs them.

## Setting it up

Install this page in any space with Storie libraries to check, from inside that space. It has no settings.

## Its version

`storie.version` is the version of the Lua the tab runs, and `storie.stale()` says in words when a copy of this page, at any depth, holds another: nil while every copy matches. It lists itself with the others.

## Implementation

```space-lua
storie = storie or {}
storie.version = "1.0.0"

-- Nil while this tab runs the Lua that every copy of this page holds, or
-- else what differs, in words: a copy that holds a newer version, which
-- System: Reload loads, or an older one, to update from inside its own
-- space. The copies are the library pages the index names
-- Library/Storie/Storie Check, at any depth. It never raises: what it
-- can't find out, it doesn't report.
function storie.stale()
  local ok, found = pcall(function()
    local lib, running = "Library/Storie/Storie Check", storie.version
    local function shown(v)
      if type(v) == "number" and v == math.floor(v) then return string.format("%d", v) end
      return tostring(v)
    end
    local function before(a, b)
      local x, y = {}, {}
      for n in string.gmatch(shown(a), "%d+") do x[#x + 1] = tonumber(n) end
      for n in string.gmatch(shown(b), "%d+") do y[#y + 1] = tonumber(n) end
      for i = 1, math.max(#x, #y) do
        if (x[i] or 0) ~= (y[i] or 0) then return (x[i] or 0) < (y[i] or 0) end
      end
      return false
    end
    local copies = query[[
      from p = index.pages("meta/library")
      where p.name == lib or string.endsWith(p.name, "/" .. lib)
      order by p.name
    ]]
    local newer, older = {}, {}
    for _, p in ipairs(copies) do
      if p.version == nil then
        older[#older + 1] = p.name .. " has no version"
      elseif p.version ~= running and before(running, p.version) then
        newer[#newer + 1] = p.name .. " holds " .. shown(p.version)
      elseif p.version ~= running then
        older[#older + 1] = p.name .. " holds " .. shown(p.version) .. ", an older version"
      end
    end
    if #newer + #older == 0 then return nil end
    local advice = "Run System: Reload."
    if #older > 0 then
      advice = #newer > 0 and "Run System: Reload, and update the older copy from inside its own space."
        or "Update the older copy from inside its own space."
    end
    local reload = #newer > 0
    for _, o in ipairs(older) do newer[#newer + 1] = o end
    return { text = "Storie Check " .. running .. " is running; " .. table.concat(newer, "; ") .. ". " .. advice,
             reload = reload }
  end)
  if ok and found then return found.text, found.reload end
  return nil
end

-- The Storie libraries, each with the table its Lua makes, read through a
-- function since a library that isn't loaded leaves the name unset, and,
-- for the ones that tell GM Book how to print, their key in gmbook.printers.
storie.libraries = {
  { name = "GM Kit", ns = "gm", get = function() return gm end },
  { name = "GM Beyond", ns = "gmb", get = function() return gmb end },
  { name = "GM Book", ns = "gmbook", get = function() return gmbook end },
  { name = "GM Party", ns = "party", printer = "party", get = function() return party end },
  { name = "GM Bestiary", ns = "bestiary", printer = "bestiary", get = function() return bestiary end },
  { name = "GM Maps", ns = "maps", printer = "maps", get = function() return maps end },
  { name = "GM Sheets", ns = "sheets", printer = "sheets", get = function() return sheets end },
  { name = "Chapter Navigation", ns = "chapterNav", get = function() return chapterNav end },
  { name = "Space Switcher", ns = "spaceSwitcher", get = function() return spaceSwitcher end },
  { name = "Appearances", ns = "kb", get = function() return kb end },
  { name = "RecurringTasks", ns = "recurringTasks", get = function() return recurringTasks end },
  { name = "Storie Check", ns = "storie", get = function() return storie end },
}

-- The settings the small libraries read, each with the library whose
-- schema, <ns>.schema, gives their shape.
storie.settings = {
  { key = "spaceSwitcher", library = "Space Switcher" },
  { key = "chapterNav", library = "Chapter Navigation" },
  { key = "appearances", library = "Appearances" },
}

local function known(name)
  for _, lib in ipairs(storie.libraries) do
    if lib.name == name then return lib end
  end
end

-- A version as text: a whole number without a point, as JavaScript and
-- Lua 5.4 would print it differently.
local function shown(v)
  if type(v) == "number" and v == math.floor(v) then return string.format("%d", v) end
  return tostring(v)
end

-- Text for a Markdown page, its punctuation escaped with backslashes, so
-- nothing in a name or a message reads as Markdown or as ${...}.
local function md(text)
  return (string.gsub(shown(text), "[\\`*_{}%[%]<>()#+!|~$]", "\\%0"))
end

-- Every copy of a Storie library in the space: the library pages the index
-- names Library/Storie/<name>, at any depth, each with its library's name,
-- the folder it is installed under, that folder's depth, its version and
-- its share.* keys, if Library: Install wrote them.
function storie.copies()
  local pages = query[[
    from p = index.pages("meta/library")
    order by p.name
  ]]
  local out = {}
  for _, p in ipairs(pages) do
    local folder, name = string.match(p.name, "^(.-)Library/Storie/([^/]+)$")
    if name and (folder == "" or string.endsWith(folder, "/")) then
      local _, depth = string.gsub(folder, "/", "")
      local share = type(p.share) == "table" and p.share or nil
      out[#out + 1] = { page = p.name, library = name, folder = folder, depth = depth,
                        version = p.version, installed = share ~= nil and share.uri ~= nil }
    end
  end
  return out
end

-- The whole check, as data. Each line has a mark, ok, stale, warn, off or
-- absent, and its words; a problem is a line the command's notification
-- names, what a reload fixes first, then a library that isn't running, then
-- the rest. Nothing here raises for a library that misbehaves: its stale()
-- or its settings are looked at inside a pcall.
function storie.check()
  local report = { libraries = {}, printers = {}, settings = {}, problems = {}, reload = false,
                   counts = { ok = 0, stale = 0, warn = 0, off = 0, absent = 0 } }
  local ranked = {}
  local function problem(text, rank)
    ranked[#ranked + 1] = { text = text, rank = rank or 3, at = #ranked + 1 }
  end

  local good, copies = pcall(storie.copies)
  if not good then
    report.indexError = tostring(copies)
    problem("the index couldn't be read: " .. report.indexError, 1)
    copies = {}
  end
  local byLibrary, order = {}, {}
  for _, lib in ipairs(storie.libraries) do
    byLibrary[lib.name] = {}
    order[#order + 1] = lib.name
  end
  local unknown = {}
  for _, c in ipairs(copies) do
    if not byLibrary[c.library] then
      byLibrary[c.library] = {}
      unknown[#unknown + 1] = c.library
    end
    table.insert(byLibrary[c.library], c)
  end
  table.sort(unknown)
  for _, name in ipairs(unknown) do order[#order + 1] = name end

  local running = {}
  for _, name in ipairs(order) do
    local lib, here = known(name), byLibrary[name]
    local entry = { name = name, copies = here }
    local t = lib and lib.get() or nil
    if not lib then
      entry.mark, entry.text = "absent", "Storie Check doesn't know this library, so can't tell what it runs"
    elseif t == nil or (type(t) == "table" and t.version == nil and #here == 0) then
      if #here == 0 then
        entry.mark, entry.text = "absent", "not installed here"
      else
        entry.mark, entry.text = "off", "not running, though a copy is here: run System: Reload, and if it stays, " ..
          "its page failed to load (the browser's console says why)"
        problem(name .. " isn't running, though a copy is here", 2)
      end
    elseif type(t) ~= "table" then
      entry.mark, entry.text = "warn", lib.ns .. " isn't a library's table here"
      problem(name .. ": " .. lib.ns .. " isn't its table")
    elseif t.version == nil then
      entry.mark, entry.text = "warn", "loaded, an older library without a version: update it from inside its own space"
      problem(name .. " is an older library without a version")
      running[name] = true
    else
      running[name] = true
      entry.version = shown(t.version)
      local message, reload
      if type(t.stale) == "function" then
        local fine, m, r = pcall(t.stale)
        if fine then message, reload = m, r else message = "its stale() failed: " .. tostring(m) end
      end
      if message == nil then
        entry.mark, entry.text = "ok", "current"
      elseif reload then
        entry.mark, entry.text = "stale", message
        report.reload = true
        problem(message, 1)
      else
        entry.mark, entry.text = "warn", message
        problem(message)
      end
    end
    -- copies at different depths: a space that holds others runs them all
    local depths, seen = 0, {}
    for _, c in ipairs(here) do
      if not seen[c.depth] then
        seen[c.depth] = true
        depths = depths + 1
      end
    end
    if depths > 1 then
      local pages = {}
      for _, c in ipairs(here) do pages[#pages + 1] = c.page end
      entry.depths = "copies at different depths, and a space that holds others runs every one: remove the one " ..
        "you don't use, which Library: Update All may have left at the top"
      problem(name .. " has copies at different depths: " .. table.concat(pages, ", "))
    end
    report.counts[entry.mark] = report.counts[entry.mark] + 1
    report.libraries[#report.libraries + 1] = entry
  end

  -- GM Book's printers: the libraries that print something other than what
  -- the page shows put a table in gmbook.printers.
  local book = known("GM Book").get()
  local printers = type(book) == "table" and type(book.printers) == "table" and book.printers or {}
  local keys = {}
  for key in pairs(printers) do keys[#keys + 1] = key end
  table.sort(keys)
  for _, key in ipairs(keys) do
    local owner
    for _, lib in ipairs(storie.libraries) do
      if lib.printer == key then owner = lib.name end
    end
    report.printers[#report.printers + 1] = { mark = "ok", key = key,
      text = (owner or key) .. " tells GM Book how to print it" .. (running["GM Book"] and "" or ", once GM Book runs here") }
  end
  for _, lib in ipairs(storie.libraries) do
    if lib.printer and running[lib.name] and printers[lib.printer] == nil then
      report.printers[#report.printers + 1] = { mark = "warn", key = lib.printer,
        text = lib.name .. " runs here but hasn't told GM Book how to print it: a book prints what the page shows" }
      problem(lib.name .. " has no printer in gmbook.printers")
    end
  end

  -- The small libraries' settings, held to the shape each declares.
  local validate = jsonschema and jsonschema.validateObject
  for _, s in ipairs(storie.settings) do
    local lib = known(s.library)
    local t = lib.get()
    local line = { key = s.key }
    local value = config.get(s.key, nil)
    local schema = type(t) == "table" and t.schema or nil
    if value == nil then
      line.mark, line.text = "absent", "not set" .. (running[s.library] and (": " .. s.library .. " uses its defaults") or "")
    elseif schema == nil then
      line.mark, line.text = "absent", running[s.library]
        and ("set, and " .. s.library .. " declares no shape to hold it to: an older version")
        or ("set, but " .. s.library .. " isn't running here to read it")
    elseif not validate then
      line.mark, line.text = "absent", "set, but this SilverBullet has no jsonschema.validateObject to check it with"
    else
      local fine, err = pcall(validate, schema, value)
      if not fine then
        line.mark, line.text = "warn", "couldn't be checked: " .. tostring(err)
      elseif err == nil then
        line.mark, line.text = "ok", "the shape " .. s.library .. " reads"
      else
        line.mark, line.text = "warn", "not the shape " .. s.library .. " reads: " .. tostring(err)
        problem(s.key .. " isn't the shape " .. s.library .. " reads: " .. tostring(err))
      end
    end
    report.settings[#report.settings + 1] = line
  end
  table.sort(ranked, function(a, b)
    if a.rank ~= b.rank then return a.rank < b.rank end
    return a.at < b.at
  end)
  for _, p in ipairs(ranked) do report.problems[#report.problems + 1] = p.text end
  return report
end

local MARKS = { ok = "✓", stale = "⟳", warn = "⚠", off = "✗", absent = "○" }

-- How many libraries are in each state, in words, leaving out the states
-- none is in: "3 current, 1 waiting for a reload, 4 not here".
function storie.summary(report)
  local c, parts = report.counts, {}
  for _, s in ipairs({ { "ok", "current" }, { "stale", "waiting for a reload" }, { "warn", "to put right" },
                       { "off", "not running" }, { "absent", "not here" } }) do
    if c[s[1]] > 0 then parts[#parts + 1] = c[s[1]] .. " " .. s[2] end
  end
  if #parts == 0 then return "none here" end
  return table.concat(parts, ", ")
end

-- The check as Markdown: a summary, then each library with its copies, the
-- printers and the settings, every line a mark and its words.
function storie.markdown(report)
  report = report or storie.check()
  local lines = { "**Storie libraries in this space:** " .. storie.summary(report) .. ".", "" }
  if report.indexError then
    lines[#lines + 1] = "⚠ The index couldn't be read: " .. md(report.indexError)
    lines[#lines + 1] = ""
  end
  lines[#lines + 1] = "**Libraries**"
  lines[#lines + 1] = ""
  for _, e in ipairs(report.libraries) do
    local head = "- " .. MARKS[e.mark] .. " **" .. md(e.name) .. "**"
    if e.version then head = head .. " " .. md(e.version) end
    lines[#lines + 1] = head .. ": " .. md(e.text)
    for _, copy in ipairs(e.copies) do
      lines[#lines + 1] = "  - [[" .. copy.page .. "]] " ..
        (copy.version ~= nil and md(copy.version) or "without a version") .. ", " ..
        (copy.installed and "✓ from Library: Install" or "○ copied by hand: Library: Update skips it")
    end
    if e.depths then lines[#lines + 1] = "  - ⚠ " .. md(e.depths) end
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "**Printers for GM Book**"
  lines[#lines + 1] = ""
  if #report.printers == 0 then lines[#lines + 1] = "- ○ none registered" end
  for _, p in ipairs(report.printers) do
    lines[#lines + 1] = "- " .. MARKS[p.mark] .. " `" .. p.key .. "`: " .. md(p.text)
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "**Settings**"
  lines[#lines + 1] = ""
  for _, s in ipairs(report.settings) do
    lines[#lines + 1] = "- " .. MARKS[s.mark] .. " `" .. s.key .. "`: " .. md(s.text)
  end
  return table.concat(lines, "\n")
end

-- ${storie.health()}: the check, on the page it sits on.
function storie.health()
  local ok, text = pcall(storie.markdown)
  if not ok then text = "⚠ Storie Check failed: " .. md(tostring(text)) end
  return widget.new { markdown = text, display = "block" }
end

-- The command: the check summed up in a notification, the first things to
-- put right named, and a Reload when a newer copy is waiting.
function storie.notify()
  local ok, report = pcall(storie.check)
  if not ok then
    editor.flashNotification("✗ Storie Check failed: " .. tostring(report), "error")
    return
  end
  local summary = storie.summary(report)
  if #report.problems == 0 then
    editor.flashNotification("✓ Storie libraries: " .. summary .. ". Nothing to put right.")
    return
  end
  local named = {}
  for i, p in ipairs(report.problems) do
    if i > 3 then break end
    named[#named + 1] = string.match(p, "%.$") and p or (p .. ".")
  end
  local more = #report.problems - #named
  local options = { timeout = 30000 }
  if report.reload then
    options.actions = { { name = "Reload", run = function() editor.invokeCommand("System: Reload") end } }
  end
  editor.flashNotification("⚠ Storie libraries: " .. summary .. ". " .. table.concat(named, " ") ..
    (more > 0 and (" And " .. more .. " more.") or "") .. " Put ${storie.health()} on a page for the whole list.",
    "warning", options)
end

command.define {
  name = "Storie: Check Libraries",
  run = function() storie.notify() end,
}
```
