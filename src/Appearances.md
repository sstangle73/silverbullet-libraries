---
tags: meta/library
name: "Library/Storie/Appearances"
description: "Lists the chapters that name the current page in their frontmatter, grouped by book, for a wiki about a book or a series."
author: "Steven Storie"
version: "1.1.0"
---

# Appearances

`${kb.appearances()}` lists every chapter that names the current page in its frontmatter, grouped by book. Fix a chapter's frontmatter and every page that lists it updates.

It is for a wiki about a book or a series, with a page per chapter and a page per character, place or thing.

## Setting it up

A chapter names what appears in it in lists in its frontmatter:

    ---
    type: chapter
    book: 1
    book_title: The Long Road
    chapter: 3
    people: [Ada, Brin]
    places: [Harbour]
    ---

Say which list to look in for each type of page, in a `space-lua` block on your `CONFIG` page:

    config.set("appearances", {
      fields = {
        person = "people",
        place = "places",
      },
    })

Then on `People/Ada`, a page with `type: person`, `${kb.appearances()}` lists every chapter whose `people` include `Ada`:

> 2 chapters in 1 book.
>
> **1. The Long Road** (2): 3, 7

On a page of any other type it shows nothing.

## Settings

All but `fields` are optional.

| Key | Default | Means |
|---|---|---|
| `fields` | none | For each page type, the chapter field that names pages of that type |
| `nameField` | none | A field holding the name chapters use for a page, where that isn't the last part of the page's own name |
| `chapterType` | `chapter` | The type of a chapter page |
| `typeField` | `type` | The frontmatter field holding a page's type |
| `numberField` | `chapter` | The chapter's number, which orders the list |
| `labelField` | `chapter_label` | A label to show instead of the number |
| `bookField` | `book` | Which book a chapter is in; the list groups by it |
| `titleField` | `book_title` | The book's title, for each group's heading |

A chapter without a book goes in a group with no heading, so a single book needs neither field.

SilverBullet checks these settings against their shape, declared in the last block on this page. A `config.set("appearances", ...)` of the wrong shape, such as `fields = "people"` or a misspelt key, raises where it is written, in the browser's console, and the rest of that `space-lua` block doesn't run, so give the settings a block of their own. Settings of the wrong shape list nothing rather than break the page they are on. Storie Check lists what is wrong.

## Its version

`kb.version` is the version of the Lua the tab runs, and `kb.stale()` says in words when a copy of this page, at any depth, holds another: nil while every copy matches. Storie Check lists both, for every library in the space.

## Changes in 1.1

**Its version, and settings with a shape.** `kb.version` and `kb.stale()`: see *Its version*. The settings are declared with `config.define`, so a setting of the wrong shape is named where it is set, and the list shows what it can.

## Implementation

```space-lua
kb = kb or {}
kb.version = "1.1.0"

-- Nil while this tab runs the Lua that every copy of this page holds, or
-- else what differs, in words: a copy that holds a newer version, which
-- System: Reload loads, or an older one, to update from inside its own
-- space. The copies are the library pages the index names
-- Library/Storie/Appearances, at any depth. It never raises: what it can't
-- find out, it doesn't report.
function kb.stale()
  local ok, found = pcall(function()
    local lib, running = "Library/Storie/Appearances", kb.version
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
    return { text = "Appearances " .. running .. " is running; " .. table.concat(newer, "; ") .. ". " .. advice,
             reload = reload }
  end)
  if ok and found then return found.text, found.reload end
  return nil
end

local function setting(key, default)
  return config.get("appearances." .. key, default)
end

-- Whether a chapter's field names the page: a list holding the name, or the
-- name on its own. The list is walked, not searched with table.includes,
-- which throws on a field that holds a map.
local function names(value, entity)
  if type(value) == "table" then
    for _, v in ipairs(value) do
      if v == entity then return true end
    end
    return false
  end
  return value == entity
end

function kb.appearances(name)
  name = name or editor.getCurrentPage()
  local typeField = setting("typeField", "type")
  local page
  for _, p in ipairs(query[[from p = index.pages() where p.name == name]]) do
    page = p
  end
  -- fields maps each type of page to a field's name; any other shape is
  -- none, which the schema below reports
  local fields = setting("fields", {})
  local field = page and type(fields) == "table" and fields[page[typeField]] or nil
  if type(field) ~= "string" then return nil end

  local nameField = setting("nameField", nil)
  local entity = (nameField and page[nameField]) or string.match(name, "([^/]+)$")
  local chapterType = setting("chapterType", "chapter")
  local numberField = setting("numberField", "chapter")
  local bookField = setting("bookField", "book")
  local chapters = query[[
    from p = index.pages()
    where p[typeField] == chapterType and names(p[field], entity)
    order by p[bookField], p[numberField]
  ]]
  if #chapters == 0 then
    return widget.markdown("Not named in any chapter's frontmatter.")
  end

  local labelField = setting("labelField", "chapter_label")
  local titleField = setting("titleField", "book_title")
  local lines, links = {}, {}
  local book, title, books, started = nil, nil, 0, false
  local function flush()
    if not started then return end
    local line = table.concat(links, ", ")
    if book ~= nil and title ~= nil then
      line = "**" .. book .. ". " .. title .. "** (" .. #links .. "): " .. line
    elseif book ~= nil or title ~= nil then
      line = "**" .. tostring(book or title) .. "** (" .. #links .. "): " .. line
    end
    table.insert(lines, line)
  end
  for _, c in ipairs(chapters) do
    if not started or c[bookField] ~= book then
      flush()
      started, book, title, links = true, c[bookField], c[titleField], {}
      if book ~= nil then books = books + 1 end
    end
    local label = c[labelField] or c[numberField] or string.match(c.name, "([^/]+)$")
    table.insert(links, "[[" .. c.name .. "|" .. tostring(label) .. "]]")
  end
  flush()

  local summary = #chapters .. (#chapters == 1 and " chapter" or " chapters")
  if books > 0 then
    summary = summary .. " in " .. books .. (books == 1 and " book." or " books.")
  else
    summary = summary .. "."
  end
  return widget.markdown(summary .. "\n\n" .. table.concat(lines, "\n\n"))
end
```

The shape of the settings, for SilverBullet's `config.define`. This block loads ahead of any `CONFIG` page's, so SilverBullet checks each `config.set("appearances", ...)` against it as it runs.

```space-lua
-- priority: 50
-- Ahead of every CONFIG block, which counts as 0 without a priority of its
-- own: a config.set of the wrong shape then raises where it is written, and
-- Storie Check reads the same schema.
kb = kb or {}
local text = { type = "string" }
kb.schema = {
  type = "object",
  properties = {
    fields = { type = "object", additionalProperties = text },
    nameField = text, chapterType = text, typeField = text, numberField = text,
    labelField = text, bookField = text, titleField = text,
  },
  additionalProperties = false,
}
config.define("appearances", kb.schema)
```
