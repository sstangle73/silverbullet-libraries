---
tags: meta/library
name: "Library/Storie/Appearances"
description: "Lists the chapters that name the current page in their frontmatter, grouped by book, for a wiki about a book or a series."
author: "Steven Storie"
version: "1.0.0"
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

## Implementation

```space-lua
kb = kb or {}

local function setting(key, default)
  return config.get("appearances." .. key, default)
end

-- Whether a chapter's field names the page: a list holding the name, or the
-- name on its own.
local function names(value, entity)
  if type(value) == "table" then return table.includes(value, entity) end
  return value == entity
end

function kb.appearances(name)
  name = name or editor.getCurrentPage()
  local typeField = setting("typeField", "type")
  local page
  for _, p in ipairs(query[[from p = index.pages() where p.name == name]]) do
    page = p
  end
  local field = page and setting("fields", {})[page[typeField]]
  if not field then return nil end

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
