---
tags: meta/library
name: "Library/Storie/Chapter Navigation"
description: "Previous, contents and next links above and below every chapter page, read from the index, with an optional link to a companion page for the same chapter."
author: "Steven Storie"
version: "1.0.0"
---

# Chapter Navigation

Adds a bar above and below every chapter page: the previous chapter, the book's contents, and the next chapter.

    ← Chapter 2 · The Long Road (3 of 12) · Chapter 4 →

It reads the index, so the chapter pages carry no links of their own, and a new or renumbered chapter needs nothing extra.

Close either bar with its ×. `Navigate: Chapter Links (Top)` or `Navigate: Chapter Links (Bottom)` brings it back.

## Chapter pages

A chapter is a page with `type: chapter` and its number in `chapter`:

    ---
    type: chapter
    book_title: The Long Road
    chapter: 3
    ---

The bar links the chapters in the same folder, in order of `chapter`. The middle link goes to a `Contents` page in that folder, or failing that to the page named after the top folder, and reads `book_title`, or the folder's name without one. A chapter with a `chapter_label`, such as `Prologue`, shows that instead of "Chapter 3".

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

## Implementation

```space-lua
-- priority: -1
chapterNav = chapterNav or {}

local function setting(key, default)
  return config.get("chapterNav." .. key, default)
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

-- The book's contents page, or failing that the page at the top of the tree.
local function contentsPage(folder)
  local contents = folder .. "/" .. setting("contents", "Contents")
  if space.pageExists(contents) then
    return contents
  end
  local top = string.match(folder, "^[^/]+")
  if top and space.pageExists(top) then
    return top
  end
end

function chapterNav.markdown(name)
  name = name or editor.getCurrentPage()
  local folder = string.match(name, "^(.*)/[^/]+$")
  if not folder then return nil end

  local typeField = setting("typeField", "type")
  local numberField = setting("numberField", "chapter")
  local labelField = setting("labelField", "chapter_label")
  local labelFormat = setting("labelFormat", "Chapter %s")
  local function label(p)
    if p[labelField] then return p[labelField] end
    if p[numberField] == nil then return string.match(p.name, "([^/]+)$") end
    return string.format(labelFormat, tostring(p[numberField]))
  end

  local cur
  for _, p in ipairs(query[[from p = index.pages() where p.name == name]]) do
    cur = p
  end
  local kind = cur and cur[typeField]
  if not kind or not table.includes(setting("types", { "chapter" }), kind) then return nil end

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
  local title = cur[setting("titleField", "book_title")] or folder
  local contents = contentsPage(folder)
  if contents then
    title = "[[" .. contents .. "|" .. title .. "]]"
  end
  table.insert(parts, title .. " (" .. at .. " of " .. #list .. ")")
  if at < #list then
    table.insert(parts, "[[" .. list[at + 1].name .. "|" .. label(list[at + 1]) .. " →]]")
  end

  -- The companion page, where this space has one: the page of the other type
  -- with the same book and chapter.
  local companion = setting("counterparts", {})[kind]
  if companion and companion.type then
    local other, bookField = companion.type, setting("bookField", "book")
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
