---
tags: meta/library
name: "Library/Storie/GM Book"
description: "Compile a campaign space into a single manuscript in DM and player editions, transformed for Homebrewery so it renders as a WotC-style 5e book."
author: "Steven Storie"
version: "1.2.0"
---

# GM Book

Compile a campaign space into a single manuscript, in two editions, ready for [Homebrewery](https://homebrewery.naturalcrit.com) to render as a WotC-style 5e book.

Self-contained as of 1.1: it no longer needs GM Kit, so it can live inside a standalone adventure space.

## Buttons

- **In the header**, the printer builds both editions.
- **On a built page**, a bar across the top has *Build again*, *Copy for Homebrewery* and *Open Homebrewery*. The bar isn't part of the page, so the copy is the manuscript alone.
- **After a build**, the notification has a button to open each edition.

To put a build button on a page of your own:

    ${widgets.commandButton("Build the book", "GM: Build Book")}

## The editions

| Command | Output | Contains |
|---|---|---|
| `GM: Build Book` | Both editions | The two below, built together |
| `GM: Build Book (DM)` | `Build/Book DM` | Everything, secrets included |
| `GM: Build Book (Player)` | `Build/Book Player` | `## DM Only` sections removed |
| `GM: Copy Book for Homebrewery` | The clipboard | The edition you are looking at, or the one you pick |

## Setting the order

Put `book_order` in the frontmatter of any page that belongs in the book. Pages without it are skipped, so dashboards and scratch pages stay out automatically.

    book_order: 20

Leave gaps (10, 20, 30) so you can insert chapters without renumbering.

## Bake before you build

Live `${...}` expressions only exist inside SilverBullet. Run `Baked Sections: Update` on any page with queries first. The builder names the pages still holding live expressions, rather than shipping gaps.

## Building from a larger space

A build reads the pages that sit beside GM Book's own `Library/` folder, and writes `Build/` there. Installed at `Library/Storie/GM Book`, that is the whole space.

An adventure folder can also be part of a larger space, as `Planning/` is when a DM space contains it. That space sees this page at `Planning/Library/Storie/GM Book`, so a build started there reads only `Planning/` and writes the same `Planning/Build/` pages as a build from inside. To choose the folder yourself, put this in a `space-lua` block:

    config.set("gmBook", { root = "Adventure/" })

## What it transforms

- Frontmatter stripped
- `[[Some/Path/Page]]` becomes `Page`; `[[Page|Label]]` becomes `Label`
- Baked-section markers removed, rendered bodies kept
- `> **note**` blockquotes become Homebrewery `{{note}}` blocks
- A page break inserted between chapters

## Rendering it

**Homebrewery**: open a built page, press *Copy for Homebrewery*, then *Open Homebrewery* and paste into the new brew. Free, authentic PHB look, PDF export.

**Pandoc with a 5e LaTeX template**: for a fully local, reproducible build.

## Implementation

```space-lua
-- priority: 10
gmbook = gmbook or {}

gmbook.config = {
  outputFolder = "Build/",
  pageBreak    = "\\page",
  dmHeading    = "DM Only",
  libraryPage  = "Library/Storie/GM Book",
  homebrewery  = "https://homebrewery.naturalcrit.com/new",
}

gmbook.editions = {
  dm     = { page = "Book DM",     label = "DM edition" },
  player = { page = "Book Player", label = "player edition" },
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

-- The folder a build reads from and writes to: "" for the whole space, or
-- the folder this page is installed under. See "Building from a larger space".
function gmbook.root()
  local configured = config.get("gmBook.root", nil)
  if configured then return configured end
  local lib = gmbook.config.libraryPage
  local names = query[[
    from p = index.pages()
    where p.name:endsWith(lib)
    select p.name
  ]]
  local root
  for _, name in ipairs(names) do
    local candidate = name:sub(1, #name - #lib)
    if (candidate == "" or candidate:endsWith("/"))
        and (not root or #candidate < #root) then
      root = candidate
    end
  end
  return root or ""
end

function gmbook.output(edition, root)
  return (root or gmbook.root()) .. gmbook.config.outputFolder ..
         gmbook.editions[edition].page
end

-- "dm" or "player" if the page is a built edition, otherwise nil.
function gmbook.editionOf(page)
  for key, edition in pairs(gmbook.editions) do
    if page:endsWith(gmbook.config.outputFolder .. edition.page)
        and page == gmbook.output(key) then
      return key
    end
  end
end

function gmbook.pages(root)
  local pages = query[[
    from p = index.pages()
    where p.book_order
    order by p.book_order
  ]]
  local out = {}
  for _, p in ipairs(pages) do
    if p.name:startsWith(root) then out[#out + 1] = p end
  end
  return out
end

function gmbook.render(text, playerEdition)
  text = gmbook.stripFrontmatter(text)
  if playerEdition then text = gmbook.stripSecrets(text) end
  text = gmbook.unbake(text)
  text = gmbook.delink(text)
  return gmbook.admonitions(text)
end

-- Writes each edition asked for ("dm", "player") and reports what it did.
function gmbook.compile(editions)
  local root = gmbook.root()
  local pages = gmbook.pages(root)
  local report = { pages = #pages, live = {}, written = {} }
  if #pages == 0 then return report end
  local texts = {}
  for i, p in ipairs(pages) do
    texts[i] = space.readPage(p.name)
    if texts[i]:find("%${") then
      report.live[#report.live + 1] = p.name:sub(#root + 1)
    end
  end
  local sep = "\n\n" .. gmbook.config.pageBreak .. "\n\n"
  for _, edition in ipairs(editions) do
    local parts = {}
    for i, text in ipairs(texts) do
      parts[i] = gmbook.render(text, edition == "player")
    end
    local out = gmbook.output(edition, root)
    space.writePage(out, table.concat(parts, sep))
    report.written[#report.written + 1] = { edition = edition, page = out }
  end
  return report
end

function gmbook.build(editions)
  local report = gmbook.compile(editions)
  if report.pages == 0 then
    editor.flashNotification("No pages have a book_order, so there is nothing to build", "warning")
    return report
  end
  local names, actions = {}, {}
  for _, w in ipairs(report.written) do
    local label = gmbook.editions[w.edition].label
    names[#names + 1] = "the " .. label
    actions[#actions + 1] = {
      name = "Open " .. label,
      run = function() editor.navigate(w.page) end,
    }
    if editor.getCurrentPage() == w.page then editor.reloadPage() end
  end
  local message = "Built " .. table.concat(names, " and ") ..
                  " from " .. report.pages .. " pages."
  local kind = "info"
  if #report.live > 0 then
    kind = "warning"
    message = message .. " " .. #report.live ..
      (#report.live == 1 and " page still holds" or " pages still hold") ..
      " live expressions, which print as code: " ..
      table.concat(report.live, ", ") ..
      ". Run Baked Sections: Update on them and build again."
  end
  editor.flashNotification(message, kind, { timeout = 12000, actions = actions })
  return report
end

function gmbook.openHomebrewery()
  editor.openUrl(gmbook.config.homebrewery)
end

function gmbook.copy(edition)
  local label = gmbook.editions[edition].label
  local page = gmbook.output(edition)
  if not space.pageExists(page) then
    editor.flashNotification("There is no " .. label .. " yet. Build the book first.", "warning")
    return false
  end
  local ok, err = pcall(editor.copyToClipboard, space.readPage(page))
  if not ok then
    editor.flashNotification("Couldn't copy to the clipboard (" .. tostring(err) ..
      "). Open " .. page .. " and copy it by hand.", "error")
    return false
  end
  editor.flashNotification("Copied the " .. label .. ". Paste it into a new Homebrewery brew.",
    "info", {
      timeout = 12000,
      actions = {{ name = "Open Homebrewery", run = gmbook.openHomebrewery }},
    })
  return true
end

function gmbook.button(label, run, primary)
  return dom.button {
    class = primary and "sb-button-primary" or "sb-button",
    onclick = function()
      local ok, err = pcall(run)
      if not ok then editor.flashNotification("GM Book: " .. tostring(err), "error") end
    end,
    label,
  }
end

-- The bar across the top of a built edition.
function gmbook.bar(page)
  page = page or editor.getCurrentPage()
  local edition = gmbook.editionOf(page)
  if not edition then return nil end
  local label = gmbook.editions[edition].label
  return widget.new {
    display = "block",
    html = dom.div {
      class = "gmbook-bar",
      dom.span {
        class = "gmbook-bar-text",
        "**" .. label:sub(1, 1):upper() .. label:sub(2) .. "**, built by GM Book. " ..
        "A build replaces this page, so make changes in the pages it comes from.",
      },
      gmbook.button("Build again", function() gmbook.build({ "dm", "player" }) end, true),
      gmbook.button("Copy for Homebrewery", function() gmbook.copy(edition) end),
      gmbook.button("Open Homebrewery", gmbook.openHomebrewery),
    },
  }
end
```

```space-lua
-- priority: 10
command.define {
  name = "GM: Build Book",
  run = function() gmbook.build({ "dm", "player" }) end
}

command.define {
  name = "GM: Build Book (DM)",
  run = function() gmbook.build({ "dm" }) end
}

command.define {
  name = "GM: Build Book (Player)",
  run = function() gmbook.build({ "player" }) end
}

command.define {
  name = "GM: Copy Book for Homebrewery",
  run = function()
    local edition = gmbook.editionOf(editor.getCurrentPage())
    if not edition then
      local choice = editor.filterBox("Copy", {
        { name = "DM edition", description = "Everything, secrets included" },
        { name = "Player edition", description = "Without the DM Only sections" },
      }, "Copies a built edition, ready to paste into Homebrewery.")
      if not choice then return end
      edition = choice.name == "DM edition" and "dm" or "player"
    end
    gmbook.copy(edition)
  end
}

actionButton.define {
  icon = "printer",
  description = "Build the book (DM and player editions)",
  command = "GM: Build Book",
  priority = 0.5,
}

event.listen {
  name = "hooks:renderTopWidgets",
  run = function()
    local ok, bar = pcall(gmbook.bar)
    if ok then return bar end
    print("GM Book: " .. tostring(bar))
  end
}
```

```space-style
.gmbook-bar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px 8px;
}

.gmbook-bar-text {
  flex: 1 1 18em;
}

/* The widget's own Copy and Reload overlay would cover the bar's buttons. */
.sb-lua-top-widget:has(.gmbook-bar) .button-bar {
  display: none !important;
}
```
