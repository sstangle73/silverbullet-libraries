---
tags: meta/library
name: "Library/Storie/GM Book"
description: "Compile a campaign space into a single manuscript in DM and player editions, transformed for Homebrewery so it renders as a WotC-style 5e book."
author: "Steven Storie"
version: "1.1.0"
---

# GM Book

Compile a campaign space into a single manuscript, in two editions, ready for
[Homebrewery](https://homebrewery.naturalcrit.com) to render as a WotC-style 5e
book.

Self-contained as of 1.1: it no longer needs GM Kit, so it can live inside a
standalone adventure space.

## The two editions

| Command | Output | Contains |
|---|---|---|
| `GM: Build Book (DM)` | `Build/Book DM` | Everything, secrets included |
| `GM: Build Book (Player)` | `Build/Book Player` | `## DM Only` sections removed |

## Setting the order

Put `book_order` in the frontmatter of any page that belongs in the book. Pages
without it are skipped, so dashboards and scratch pages stay out automatically.

    book_order: 20

Leave gaps (10, 20, 30) so you can insert chapters without renumbering.

## Bake before you build

Live `${...}` expressions only exist inside SilverBullet. Run
`Baked Sections: Update` on any page with queries first. The builder counts
pages still holding live expressions and names them, rather than shipping gaps.

## What it transforms

- Frontmatter stripped
- `[[Some/Path/Page]]` becomes `Page`; `[[Page|Label]]` becomes `Label`
- Baked-section markers removed, rendered bodies kept
- `> **note**` blockquotes become Homebrewery `{{note}}` blocks
- A page break inserted between chapters

## Rendering it

**Homebrewery**: paste `Build/Book DM` in. Free, authentic PHB look, PDF export.

**Pandoc with a 5e LaTeX template**: for a fully local, reproducible build.

## Implementation

```space-lua
-- priority: 10
gmbook = gmbook or {}

gmbook.config = {
  outputFolder = "Build/",
  pageBreak    = "\\page",
  dmHeading    = "DM Only",
}

function gmbook.stripSecrets(text)
  local out, skipping = {}, false
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    if line:match("^##%s+" .. gmbook.config.dmHeading) then
      skipping = true
    elseif skipping and line:match("^##?%s") then
      skipping = false
    end
    if not skipping then out[#out + 1] = line end
  end
  return table.concat(out, "\n")
end

function gmbook.stripFrontmatter(text)
  if text:match("^%-%-%-") then
    local _, e = text:find("\n%-%-%-\n")
    if e then return text:sub(e + 1) end
  end
  return text
end

function gmbook.delink(text)
  text = text:gsub("%[%[[^%]|]*|([^%]]*)%]%]", "%1")
  text = text:gsub("%[%[([^%]]*)%]%]", function(p)
    return p:match("([^/]+)$") or p
  end)
  return text
end

function gmbook.unbake(text)
  text = text:gsub("<!%-%-#lua.-%-%->\n?", "")
  text = text:gsub("<!%-%-/lua%-%->\n?", "")
  return text
end

function gmbook.admonitions(text)
  local out, inBlock = {}, false
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    local kind, rest = line:match("^>%s+%*%*(%a+)%*%*%s*(.*)$")
    if kind then
      inBlock = true
      out[#out + 1] = "{{" .. kind:lower()
      if rest ~= "" then out[#out + 1] = "**" .. rest .. "**" end
    elseif inBlock and line:match("^>") then
      out[#out + 1] = line:match("^>%s?(.*)$")
    elseif inBlock then
      out[#out + 1] = "}}"
      out[#out + 1] = line
      inBlock = false
    else
      out[#out + 1] = line
    end
  end
  if inBlock then out[#out + 1] = "}}" end
  return table.concat(out, "\n")
end

function gmbook.build(playerEdition)
  local pages = query[[
    from p = index.pages()
    where p.book_order
    order by p.book_order
  ]]
  if #pages == 0 then
    editor.flashNotification "No pages have a book_order - nothing to build"
    return
  end
  local parts, unbaked = {}, 0
  for _, p in ipairs(pages) do
    local text = space.readPage(p.name)
    if text:find("%${") then unbaked = unbaked + 1 end
    text = gmbook.stripFrontmatter(text)
    if playerEdition then text = gmbook.stripSecrets(text) end
    text = gmbook.unbake(text)
    text = gmbook.delink(text)
    text = gmbook.admonitions(text)
    parts[#parts + 1] = text
  end
  local sep = "\n\n" .. gmbook.config.pageBreak .. "\n\n"
  local out = gmbook.config.outputFolder ..
              (playerEdition and "Book Player" or "Book DM")
  space.writePage(out, table.concat(parts, sep))
  if unbaked > 0 then
    editor.flashNotification("Built " .. out .. " - but " .. unbaked ..
      " page(s) still hold live expressions. Run Baked Sections: Update on them.")
  else
    editor.flashNotification("Built " .. out .. " from " .. #pages .. " pages")
  end
end
```

```space-lua
-- priority: 10
command.define {
  name = "GM: Build Book (DM)",
  run = function() gmbook.build(false) end
}

command.define {
  name = "GM: Build Book (Player)",
  run = function() gmbook.build(true) end
}
```
