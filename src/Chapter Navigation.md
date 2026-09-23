---
tags: meta/library
name: "Library/Storie/Chapter Navigation"
description: "Previous, contents and next links above and below every chapter page, read from the index, with an optional link to a companion page for the same chapter."
author: "Steven Storie"
version: "1.1.1"
---

# Chapter Navigation

Adds a bar above and below every chapter page: the previous chapter, the book's contents, and the next chapter.

    ← Chapter 2 · The Long Road (3 of 12) · Chapter 4 →

It works for anything kept as numbered pages in a folder, a play's scenes or an adventure's, not only a book's chapters. Each type can order and label itself its own way; see *Types of its own*.

It reads the index, so the chapter pages carry no links of their own, and a new or renumbered chapter needs nothing extra.

Close either bar with its ×. `Navigate: Chapter Links (Top)` or `Navigate: Chapter Links (Bottom)` brings it back.

## Chapter pages

A chapter is a page with `type: chapter` and its number in `chapter`:

    ---
    type: chapter
    book_title: The Long Road
    chapter: 3
    ---

The bar links the chapters in the same folder, in order of `chapter`. The middle link goes to a `Contents` page in that folder, failing that to the folder's own page, and failing that to the page named after the top folder: a page of exactly that name, not one elsewhere whose path ends the same way. With none of them the title shows without a link, and so it does while the page can't be checked, offline for instance. It reads `book_title`, or the folder's name without one. A chapter with a `chapter_label`, such as `Prologue`, shows that instead of "Chapter 3".

## Companion pages

Pages of a second type can follow the chapters, such as your notes on each one. List both types, and say what each links to:

    config.set("chapterNav", {
      types = { "chapter", "notes" },
      counterparts = {
        chapter = { type = "notes", label = "My notes" },
        notes = { type = "chapter", label = "The chapter" },
      },
    })

The notes pages then get the bar too, and each page links to the page of the other type with the same `book` and `chapter`. Where there is none, as in a space that holds only one of the two, the link doesn't appear.

## Types of its own

A second type can be numbered and labelled its own way. `perType` holds the settings that type overrides, and the rest fall back to the ones below. An adventure whose scenes live in a folder per act, each `type: scene` with a `scene` number and a `scene_title`:

    config.set("chapterNav", {
      types = { "chapter", "scene" },
      perType = {
        scene = { numberField = "scene", labelField = "scene_title", labelFormat = "Scene %s" },
      },
    })

gets, on the second of three scenes in `Act I`:

    ← The Gate · Act I (2 of 3) · The Vault →

The middle link goes to the act's own page, because a folder's page stands in as its contents page.

Everything but `types`, `counterparts` and `typeField` can be set per type.

## Settings

All optional. Set them with `config.set("chapterNav", { ... })` in a `space-lua` block, on your `CONFIG` page for example.

| Key | Default | Means |
|---|---|---|
| `types` | `{ "chapter" }` | The page types that get the bar |
| `counterparts` | none | For a type, the `type` of its companion page and the link's `label` |
| `typeField` | `type` | The frontmatter field holding a page's type |
| `numberField` | `chapter` | The chapter's number, which orders the bar |
| `labelField` | `chapter_label` | A label to show instead of the number |
| `labelFormat` | `Chapter %s` | The label of a chapter without its own; `%s` is its number |
| `bookField` | `book` | Which book a chapter is in; a companion page must match it |
| `titleField` | `book_title` | The book's title, for the contents link |
| `contents` | `Contents` | The name of the contents page in a book's folder |
| `perType` | none | Per type, any of the settings above but the first three |

SilverBullet checks these settings against their shape, declared in the last block on this page. A `config.set("chapterNav", ...)` of the wrong shape, a misspelt key or `types = "chapter"` for `types = { "chapter" }`, raises where it is written, in the browser's console, and the rest of that `space-lua` block doesn't run, so give each library's settings a block of their own. The bar still reads what it can: one type written without braces counts as a list of that one. Storie Check lists what is wrong.

## Its version

`chapterNav.version` is the version of the Lua the tab runs, and `chapterNav.stale()` says in words when a copy of this page, at any depth, holds another: nil while every copy matches. Storie Check lists both, for every library in the space.

## Changes in 1.1.1

The contents link goes only to a page of exactly that name: a page elsewhere whose name merely ends the same way no longer takes it over.

## Changes in 1.1

Types of its own, as above. A folder's own page now stands in as its contents page, and a page without a title falls back to the folder's name rather than its whole path.

## Implementation

```space-lua
-- priority: -1
chapterNav = chapterNav or {}
chapterNav.version = "1.1.1"

-- Nil while this tab runs the Lua that every copy of this page holds, or
-- else what differs, in words: a copy that holds a newer version, which
-- System: Reload loads, or an older one, to update from inside its own
-- space. The copies are the library pages the index names
-- Library/Storie/Chapter Navigation, at any depth. It never raises: what it
-- can't find out, it doesn't report.
function chapterNav.stale()
  local ok, found = pcall(function()
    local lib, running = "Library/Storie/Chapter Navigation", chapterNav.version
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
    return { text = "Chapter Navigation " .. running .. " is running; " .. table.concat(newer, "; ") .. ". " .. advice,
             reload = reload }
  end)
  if ok and found then return found.text, found.reload end
  return nil
end

-- A setting, or what the page's own type overrides it with.
local function setting(key, default, kind)
  if kind then
    local own = config.get("chapterNav.perType." .. kind .. "." .. key, nil)
    if own ~= nil then return own end
  end
  return config.get("chapterNav." .. key, default)
end

-- A setting that holds a list, as a list: one name written without the
-- braces, types = "chapter", is a list of that one, and anything else that
-- isn't a table is none. The schema below reports either shape.
local function listOf(value)
  if type(value) == "string" then return { value } end
  if type(value) ~= "table" then return {} end
  return value
end

-- Pages of the same type directly inside `folder`, in chapter order.
local function siblings(folder, kind, typeField, numberField)
  local prefix = folder .. "/"
  return query[[
    from p = index.pages()
    where p[typeField] == kind
      and string.sub(p.name, 1, #prefix) == prefix
      and not string.match(string.sub(p.name, #prefix + 1), "/")
    order by p[numberField]
  ]]
end

-- Whether there is a page of exactly this name: true, false, or nil when the
-- check itself failed, offline say. space.pageExists can't say on its own: it
-- answers the way a link resolves, so a page whose path only ends in the name
-- counts, and a link in a widget opens the name as written, an empty page. Its
-- no costs nothing, and its yes is checked against the page itself.
local function exists(name)
  if not space.pageExists(name) then return false end
  local ok, err = pcall(space.getPageMeta, name)
  if ok then return true end
  local why = tostring(err)
  if why:find("Not found", 1, true) or why:find("isn't readable", 1, true) then return false end
  return nil
end

-- The contents page for a folder: one named inside it, the folder's own page,
-- or failing those the page at the top of the tree. A page that can't be
-- checked might be the one, so it ends the search with no link rather than a
-- link further up.
local function contentsPage(folder, kind)
  local candidates = { folder .. "/" .. setting("contents", "Contents", kind), folder }
  local top = string.match(folder, "^[^/]+")
  if top and top ~= folder then table.insert(candidates, top) end
  for _, name in ipairs(candidates) do
    local found = exists(name)
    if found ~= false then
      return found and name or nil
    end
  end
end

function chapterNav.markdown(name)
  name = name or editor.getCurrentPage()
  local folder = string.match(name, "^(.*)/[^/]+$")
  if not folder then return nil end

  local typeField = setting("typeField", "type")
  local cur
  for _, p in ipairs(query[[from p = index.pages() where p.name == name]]) do
    cur = p
  end
  local kind = cur and cur[typeField]
  if not kind then return nil end
  local listed = false
  for _, t in ipairs(listOf(setting("types", { "chapter" }))) do
    if t == kind then listed = true end
  end
  if not listed then return nil end

  local numberField = setting("numberField", "chapter", kind)
  local labelField = setting("labelField", "chapter_label", kind)
  local labelFormat = setting("labelFormat", "Chapter %s", kind)
  local function label(p)
    if p[labelField] then return p[labelField] end
    if p[numberField] == nil then return string.match(p.name, "([^/]+)$") end
    return string.format(labelFormat, tostring(p[numberField]))
  end

  local list = siblings(folder, kind, typeField, numberField)
  local at
  for i, p in ipairs(list) do
    if p.name == name then at = i end
  end
  if not at then return nil end

  local parts = {}
  if at > 1 then
    table.insert(parts, "[[" .. list[at - 1].name .. "|← " .. label(list[at - 1]) .. "]]")
  end
  local title = cur[setting("titleField", "book_title", kind)]
    or string.match(folder, "([^/]+)$") or folder
  local contents = contentsPage(folder, kind)
  if contents then
    title = "[[" .. contents .. "|" .. title .. "]]"
  end
  table.insert(parts, title .. " (" .. at .. " of " .. #list .. ")")
  if at < #list then
    table.insert(parts, "[[" .. list[at + 1].name .. "|" .. label(list[at + 1]) .. " →]]")
  end

  -- The companion page, where this space has one: the page of the other type
  -- with the same book and chapter.
  local counterparts = setting("counterparts", {})
  local companion = type(counterparts) == "table" and counterparts[kind] or nil
  if type(companion) == "table" and companion.type then
    local other, bookField = companion.type, setting("bookField", "book", kind)
    local book, number = cur[bookField], cur[numberField]
    local match = query[[
      from p = index.pages()
      where p[typeField] == other and p[bookField] == book and p[numberField] == number
    ]]
    if #match > 0 then
      table.insert(parts, "[[" .. match[1].name .. "|" .. (companion.label or other) .. "]]")
    end
  end

  return table.concat(parts, " · ")
end

local function content()
  local ok, markdown = pcall(chapterNav.markdown)
  if ok then return markdown end
  print("Chapter Navigation: " .. tostring(markdown))
end

view.define {
  name = "chapterNavTop",
  title = "Chapters",
  command = "Navigate: Chapter Links (Top)",
  dock = "page-top",
  defaultOpen = true,
  refreshOn = { "editor:pageLoaded", "mq:emptyQueue:indexQueue" },
  content = content,
}

view.define {
  name = "chapterNavBottom",
  title = "Chapters",
  command = "Navigate: Chapter Links (Bottom)",
  dock = "page-bottom",
  defaultOpen = true,
  refreshOn = { "editor:pageLoaded", "mq:emptyQueue:indexQueue" },
  content = content,
}
```

The shape of the settings, for SilverBullet's `config.define`. This block loads ahead of any `CONFIG` page's, so SilverBullet checks each `config.set("chapterNav", ...)` against it as it runs.

```space-lua
-- priority: 50
-- Ahead of every CONFIG block, which counts as 0 without a priority of its
-- own: a config.set of the wrong shape then raises where it is written, and
-- Storie Check reads the same schema. The bar still reads what it can.
chapterNav = chapterNav or {}
local text = { type = "string" }
local own = {
  numberField = text, labelField = text, labelFormat = text,
  bookField = text, titleField = text, contents = text,
}
local all = {
  types = { type = "array", items = text },
  typeField = text,
  counterparts = {
    type = "object",
    additionalProperties = {
      type = "object",
      properties = { type = text, label = text },
      required = { "type" },
      additionalProperties = false,
    },
  },
  perType = {
    type = "object",
    additionalProperties = { type = "object", properties = own, additionalProperties = false },
  },
}
for key, schema in pairs(own) do all[key] = schema end
chapterNav.schema = { type = "object", properties = all, additionalProperties = false }
config.define("chapterNav", chapterNav.schema)
```
