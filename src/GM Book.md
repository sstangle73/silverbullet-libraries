---
tags: meta/library
name: "Library/Storie/GM Book"
description: "Compile a campaign space into a single manuscript in DM and player editions, transformed for Homebrewery so it renders as a WotC-style 5e book. Requires GM Kit."
author: "Steven Storie"
version: "1.0.0"
---

# GM Book

Compile a campaign space into a single manuscript, in two editions, ready for
[Homebrewery](https://homebrewery.naturalcrit.com) to render as a WotC-style
5e book.

**Requires [[Library/Storie/GM Kit]]** — it reuses that library's DM-only
stripping so the player edition and the player wiki hide exactly the same things.

## The two editions

| Command | Output | Contains |
|---|---|---|
| `GM: Build Book (DM)` | `Build/Book DM` | Everything, secrets included |
| `GM: Build Book (Player)` | `Build/Book Player` | `## DM Only` sections removed |

Same split as the two instances, same source pages. Nothing is maintained twice.

## Setting the order

Put `book_order` in the frontmatter of any page that belongs in the book. Pages
without it are skipped, so your dashboards and scratch pages stay out
automatically.

```yaml
---
type: campaign
book_order: 20
---
```

Leave gaps (10, 20, 30…) so you can insert chapters without renumbering.

## Bake before you build

Live `${...}` expressions only exist inside SilverBullet — the markdown file
holds the *source*, so a query becomes an empty space in a PDF. Run
`Baked Sections: Update` (`Ctrl-Shift-b`) on any page with queries first.

The builder won't guess at this: it counts pages still holding live expressions
and names them in the notification rather than silently shipping gaps.

## What it transforms

- Frontmatter stripped
- `[[Some/Path/Page]]` → `Page`, `[[Page|Label]]` → `Label`
- Baked-section comment markers removed, rendered bodies kept
- `> **note** …` blockquotes → Homebrewery `{{note}}` blocks
- `\page` inserted between chapters

## Rendering it

**Homebrewery** — paste `Build/Book DM` in. Free, gives you the authentic PHB
look and a PDF export. Fastest path to something that looks like a real book.

**Pandoc + a 5e LaTeX template** — if you want the build fully local and
reproducible in git, point pandoc at the same output. More setup, no web
dependency, and `make book` becomes a commit-able artifact.

Start with Homebrewery. Move to pandoc only if the web round-trip annoys you.

## Implementation

```space-lua
-- priority: 10
gmbook = gmbook or {}

gmbook.config = {
  outputFolder = "Build/",
  pageBreak    = "\page",
}

function gmbook.stripFrontmatter(text)
  if text:match("^%-%-%-") then
    local _, e = text:find("\n%-%-%-\n")
    if e then return text:sub(e + 1) end
  end
  return text
end

--- Wikilinks have no meaning on paper.
function gmbook.delink(text)
  text = text:gsub("%[%[[^%]|]*|([^%]]*)%]%]", "%1")
  text = text:gsub("%[%[([^%]]*)%]%]", function(p)
    return p:match("([^/]+)$") or p
  end)
  return text
end

--- Drop baked-section markers, keep the rendered body.
function gmbook.unbake(text)
  text = text:gsub("<!%-%-#lua.-%-%->\n?", "")
  text = text:gsub("<!%-%-/lua%-%->\n?", "")
  return text
end

--- SilverBullet admonitions to Homebrewery blocks.
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
    editor.flashNotification "No pages have a book_order — nothing to build"
    return
  end
  local parts, unbaked = {}, 0
  for _, p in ipairs(pages) do
    local text = space.readPage(p.name)
    if text:find("%${") then unbaked = unbaked + 1 end
    text = gmbook.stripFrontmatter(text)
    if playerEdition then text = gm.stripSecrets(text) end
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
    editor.flashNotification("Built " .. out .. " — but " .. unbaked ..
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
