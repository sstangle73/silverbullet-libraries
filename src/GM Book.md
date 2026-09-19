---
tags: meta/library
name: "Library/Storie/GM Book"
description: "Compile a campaign space into a single manuscript in DM and player editions, transformed for Homebrewery so it renders as a WotC-style 5e book."
author: "Steven Storie"
version: "1.6.2"
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

## A chapter in several pages

A long chapter can be split into a page of its own for each scene or section. Give each of those pages `book_section: true`, and a `book_order` just after its chapter's:

    book_order: 18.01
    book_section: true

A section carries on the chapter before it. There is no page break ahead of it, and its headings drop a level, so its `#` title prints as a section of that chapter. Number sections with two decimals: with one, YAML reads a tenth section's 18.10 as 18.1, the same as the first.

## Live values

A `${...}` expression prints as what it gives. Text and numbers print as they are, so `${1 + 2}` prints 3, and a widget prints its Markdown face.

A library can print something other than what the page shows. The builder evaluates every expression with the tables in `gmbook.printers` standing in for globals of the same name, so a library that puts its own table there decides what its functions print:

    gmbook = gmbook or {}
    gmbook.printers = gmbook.printers or {}
    gmbook.printers.mylib = mylib.printed

GM Party does this: on the page its numbers show your party's count, and in print they show the rule behind it.

A query's table, a button or anything else with no Markdown to give can't print. The builder names the pages that hold one, and prints the expression as code. Bake those first with `Baked Sections: Update`.

## One page shown in another

SilverBullet shows `![[Page]]` inside the page that holds it, or `![[Page#Section]]` for the section under one heading, down to the next heading of the same level. A scene can show an item's rules this way, and the item's page stays the one place they are written. Put each on a line of its own.

A book doesn't print the same text twice. Where the page shown is in the book, the builder prints a pointer to it instead, from that page's title and the section:

    *See Lantern: Rules.*

A page that isn't in the book is printed in place: the section, with its headings moved in under the heading above, its expressions printed, and its `## DM Only` sections left out of the player edition. The player edition also leaves out a pointer to a section it doesn't have. A page or section that can't be found prints nothing, and the build names it.

To print every one in place, or to word the pointer your own way (`%s` is the page and section):

    config.set("gmBook.transclusions", "inline")
    config.set("gmBook.see", "*For more, see %s.*")

## Building from a larger space

A build reads the pages that sit beside GM Book's own `Library/` folder, and writes `Build/` there. Installed at `Library/Storie/GM Book`, that is the whole space.

An adventure folder can also be part of a larger space, as `Planning/` is when a DM space contains it. That space sees this page at `Planning/Library/Storie/GM Book`, so a build started there reads only `Planning/` and writes the same `Planning/Build/` pages as a build from inside. To choose the folder yourself, put this in a `space-lua` block:

    config.set("gmBook", { root = "Adventure/" })

In the larger space, a wiki link written for the adventure folder, such as `[[World/Items/Lantern]]`, isn't the page's full path, so SilverBullet finds it by the end of its path. Any other page whose path ends the same way, such as notes kept at the same path in another folder, matches too, and SilverBullet asks which one you meant. A relative Markdown link, `[Lantern](<../../World/Items/Lantern>)`, starts from the folder of the page it is on, so it opens the same page in either space. The builder prints it as its label.

## What it transforms

- Frontmatter stripped
- Expressions printed, as in *Live values*. A line that held only an expression printing nothing goes too.
- `![[Page#Section]]` becomes a pointer to it, or the section itself, as in *One page shown in another*
- `[[Some/Path/Page]]` becomes `Page`; `[[Page#Section]]` becomes `Page`; `[[Page|Label]]` becomes `Label`
- `[Label](<../Some/Page>)`, a link to a page in the space, becomes `Label`. Images and links to websites stay.
- Baked-section markers removed, rendered bodies kept
- `> **note**` and `> **warning**` blockquotes become Homebrewery `{{note}}` boxes. A warning keeps a `warning` class, so a brew's style can set it apart.
- A section's headings dropped a level
- A page break before every chapter, though not before a section, and wherever a page fills up

## Page breaks

Homebrewery never carries text over to the next page. Whatever doesn't fit in a page's two columns runs on into a third column past the right edge, where it is cut off. So the builder lays each page out itself and puts a `\page` before the first block that would not fit.

The layout comes from measurements of Homebrewery's 5ePHB theme on US Letter, taken in Chrome: character widths for each font, line heights, the space between blocks, the drop cap. A page breaks between blocks, never inside a paragraph, list item, quote, table or box, and a heading goes with the text under it. Your own `\page` and `\column` lines are kept. A single block taller than a page still spills, so split it in the source.

It is an estimate, so each page keeps `gmbook.layout.slack` (one line) free at the foot. If a page still spills, raise it. The measurements only hold for 5ePHB on Letter. Set `paginate = false` in the config for chapter breaks only.

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
  paginate     = true,
  -- SilverBullet admonition -> Homebrewery box classes
  admonitions  = { note = "note", warning = "note,warning" },
  -- ![[Page#Section]] of a page the book prints: "see" points to it, and
  -- "inline" prints it in place. %s is the page's title and the section.
  transclusions = "see",
  see          = "*See %s.*",
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
    local page, heading = p:match("^(.-)#(.*)$")
    if page == "" then return heading end
    p = page or p
    return p:match("([^/]+)$") or p
  end)
  -- [Label](../Some/Page) is a page in the space, so it prints as its label.
  -- An image or a link to a website stays as it is.
  text = text:gsub("(!?)%[([^%]]*)%](%b())", function(bang, label, target)
    local url = target:sub(2, -2)
    url = url:match("^<(.*)>$") or url
    if bang == "" and not url:find("://", 1, true)
        and not url:match("^mailto:") and not url:match("^tel:") then
      return label
    end
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
    local box = kind and gmbook.config.admonitions[kind:lower()]
    if box then
      inBlock = true
      out[#out + 1] = "{{" .. box
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

-- A book_section page carries on the chapter before it, so each heading
-- drops a level. Code blocks are left as they are.
function gmbook.demote(text)
  local out, fence = {}, nil
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    local mark = line:sub(1, 3)
    if fence then
      if mark == fence then fence = nil end
    elseif mark == "```" or mark == "~~~" then
      fence = mark
    else
      local hashes = line:match("^(#+)%s")
      if hashes and #hashes < 6 then line = "#" .. line end
    end
    out[#out + 1] = line
  end
  return table.concat(out, "\n")
end

-- Libraries that print something other than what the page shows put a
-- table here, and it stands in for their global while an expression prints.
gmbook.printers = gmbook.printers or {}

-- Each ${...} put in as what it prints: text and numbers as they are, a
-- widget as its Markdown face. Found with SilverBullet's own parser, so it
-- sees exactly what the page renders. Returns the text, and the expressions
-- left in because they give nothing to print.
function gmbook.print(text)
  if not text:find("${", 1, true) then return text, {} end
  local found = {}
  local function walk(node)
    if node.type == "LuaDirective" then
      found[#found + 1] = node
    elseif node.children then
      for _, child in ipairs(node.children) do walk(child) end
    end
  end
  walk(markdown.parseMarkdown(text))
  local left = {}
  for i = #found, 1, -1 do
    local node = found[i]
    local source = text:sub(node.from + 3, node.to - 1)
    local ok, value = pcall(function()
      return spacelua.evalExpression(spacelua.parseExpression(source), gmbook.printers)
    end)
    local out
    if ok then
      if type(value) == "string" then
        out = value
      elseif type(value) == "number" then
        out = tostring(value)
      elseif type(value) == "table" and value._isWidget and type(value.markdown) == "string" then
        out = value.markdown
      end
    end
    local head, tail = text:sub(1, node.from), text:sub(node.to + 1)
    if not out then
      table.insert(left, 1, source)
    elseif out == "" and (head == "" or head:match("\n[ \t]*$")) and tail:match("^[ \t]*\n") then
      -- an expression alone on its line, printing nothing: the line goes too
      head = head:gsub("[ \t]*$", "")
      tail = tail:gsub("^[ \t]*\n", "", 1)
      if (head == "" or head:sub(-2) == "\n\n") and tail:sub(1, 1) == "\n" then tail = tail:sub(2) end
      text = head .. tail
    else
      text = head .. out .. tail
    end
  end
  return text, left
end

-- A transclusion alone on its line, ![[Page]] or ![[Page#Section]], as the
-- page and the section. Media such as images are left alone.
local MEDIA = { png = true, jpg = true, jpeg = true, gif = true, svg = true, webp = true,
  pdf = true, mp3 = true, mp4 = true, ogg = true, wav = true, webm = true }

local function transclusionOf(line)
  local inner = line:match("^%s*!%[%[(.-)%]%]%s*$")
  if not inner or inner:find("[%[%]]") then return nil end
  inner = inner:gsub("|.*$", "")
  local page, heading = inner:match("^(.-)#(.*)$")
  page = page or inner
  local ext = page:match("%.(%w+)$")
  if page == "" or page:find("^%$") or (ext and MEDIA[ext:lower()]) then return nil end
  page = page:gsub("%.md$", "")
  return page, (heading ~= "" and heading or nil)
end

-- The page a link in the book names: relative to the book's folder, as its
-- pages write links, or a whole path, or the one page whose path ends so.
function gmbook.resolve(ref, root)
  for _, name in ipairs({ root .. ref, ref }) do
    if space.pageExists(name) then return name end
  end
  local names = query[[
    from p = index.pages()
    select p.name
  ]]
  local tail, found = "/" .. ref:lower(), nil
  for _, name in ipairs(names) do
    if name:startsWith(root) and ("/" .. name:lower()):endsWith(tail) then
      if found then return nil end
      found = name
    end
  end
  return found
end

-- The section under a heading, as SilverBullet cuts it for ![[Page#Section]]:
-- from the heading to the next heading of the same level. The whole text
-- without a heading, and nil if the heading isn't there.
function gmbook.section(text, heading)
  if not heading then return text end
  local out, level, fence = nil, nil, nil
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    local mark, hashes, title = line:sub(1, 3), nil, nil
    if fence then
      if mark == fence then fence = nil end
    elseif mark == "```" or mark == "~~~" then
      fence = mark
    else
      hashes, title = line:match("^(#+)%s+(.-)%s*$")
    end
    if out then
      if hashes and #hashes == level then break end
      out[#out + 1] = line
    elseif hashes and #hashes <= 6 and title == heading then
      out, level = { line }, #hashes
    end
  end
  return out and table.concat(out, "\n") or nil
end

-- A page's title: its first # heading, or the last part of its name.
local function titleOf(text, name)
  local fence
  for line in (gmbook.stripFrontmatter(text) .. "\n"):gmatch("([^\n]*)\n") do
    local mark = line:sub(1, 3)
    if fence then
      if mark == fence then fence = nil end
    elseif mark == "```" or mark == "~~~" then
      fence = mark
    else
      local title = line:match("^#%s+(.-)%s*$")
      if title then return title end
    end
  end
  return name:match("([^/]+)$") or name
end

-- Moves text's headings so the highest of them sits at level `top`.
local function shiftHeadings(text, top)
  local lines, highest, fence = {}, nil, nil
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do lines[#lines + 1] = line end
  for _, line in ipairs(lines) do
    local mark = line:sub(1, 3)
    if fence then
      if mark == fence then fence = nil end
    elseif mark == "```" or mark == "~~~" then
      fence = mark
    else
      local hashes = line:match("^(#+)%s")
      if hashes and (not highest or #hashes < highest) then highest = #hashes end
    end
  end
  if not highest or highest == top then return text end
  fence = nil
  for i, line in ipairs(lines) do
    local mark = line:sub(1, 3)
    if fence then
      if mark == fence then fence = nil end
    elseif mark == "```" or mark == "~~~" then
      fence = mark
    else
      local hashes, rest = line:match("^(#+)(%s.*)$")
      if hashes then
        lines[i] = string.rep("#", math.max(1, math.min(6, #hashes + top - highest))) .. rest
      end
    end
  end
  return table.concat(lines, "\n")
end

-- What a transclusion prints as, as lines: a pointer, the section itself,
-- or nothing. level is the heading the transclusion sits under.
local function transcluded(ref, heading, playerEdition, ctx, level, depth)
  local page = gmbook.resolve(ref, ctx.root)
  local text = page and ctx.read(page)
  local body = text and gmbook.section(gmbook.stripFrontmatter(text), heading)
  if not body then
    ctx.missing[ctx.from .. " (" .. ref .. (heading and ("#" .. heading) or "") .. ")"] = true
    return {}
  end
  if ctx.mode ~= "inline" and ctx.inBook[page] then
    if playerEdition and heading and
        not gmbook.section(gmbook.stripSecrets(gmbook.stripFrontmatter(text)), heading) then
      return {}  -- the player edition doesn't have that section
    end
    local label = titleOf(text, page) .. (heading and (": " .. heading) or "")
    return { (ctx.see:gsub("%%s", function() return label end)) }
  end
  if depth >= 4 then return {} end
  local left
  body, left = gmbook.print(body)
  if #left > 0 then ctx.live[ctx.from] = true end
  if playerEdition then body = gmbook.stripSecrets(body) end
  body = gmbook.transclude(body, playerEdition, ctx, depth + 1)
  body = shiftHeadings(body, math.max(level, 1) + 1)
  body = (body:gsub("^%s*\n", "")):gsub("%s+$", "")
  local lines = {}
  for line in (body .. "\n"):gmatch("([^\n]*)\n") do lines[#lines + 1] = line end
  return lines
end

-- Puts each ![[Page]] or ![[Page#Section]] on a line of its own in as what
-- it prints: see "One page shown in another".
function gmbook.transclude(text, playerEdition, ctx, depth)
  if not text:find("![[", 1, true) then return text end
  local out, fence, level = {}, nil, 0
  local skipBlank, needBlank = false, false
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    local mark, ref, heading = line:sub(1, 3), nil, nil
    if fence then
      if mark == fence then fence = nil end
    elseif mark == "```" or mark == "~~~" then
      fence = mark
    else
      local hashes = line:match("^(#+)%s")
      if hashes then level = #hashes end
      ref, heading = transclusionOf(line)
    end
    if ref then
      local lines = transcluded(ref, heading, playerEdition, ctx, level, depth or 0)
      if #lines == 0 then
        -- printing nothing, the line goes, and one of the blank lines around it
        skipBlank = #out == 0 or out[#out] == ""
      else
        -- what it prints stands apart from the text around it
        if #out > 0 and out[#out] ~= "" then out[#out + 1] = "" end
        for _, l in ipairs(lines) do out[#out + 1] = l end
        skipBlank, needBlank = false, true
      end
    elseif skipBlank and line == "" then
      skipBlank = false
    else
      if needBlank and line ~= "" then out[#out + 1] = "" end
      skipBlank, needBlank = false, false
      out[#out + 1] = line
    end
  end
  return table.concat(out, "\n")
end

function gmbook.render(text, playerEdition, section, ctx)
  text = gmbook.stripFrontmatter(text)
  if playerEdition then text = gmbook.stripSecrets(text) end
  if ctx then text = gmbook.transclude(text, playerEdition, ctx) end
  if section then text = gmbook.demote(text) end
  text = gmbook.unbake(text)
  text = gmbook.delink(text)
  return gmbook.admonitions(text)
end

-- Writes each edition asked for ("dm", "player") and reports what it did.
function gmbook.compile(editions)
  local root = gmbook.root()
  local pages = gmbook.pages(root)
  local report = { pages = #pages, live = {}, written = {}, missing = {} }
  if #pages == 0 then return report end
  local texts, cache = {}, {}
  local ctx = {
    root = root, inBook = {}, missing = {}, live = {},
    mode = config.get("gmBook.transclusions", gmbook.config.transclusions),
    see = config.get("gmBook.see", gmbook.config.see),
    read = function(name)
      if cache[name] == nil then cache[name] = space.pageExists(name) and space.readPage(name) or false end
      return cache[name] or nil
    end,
  }
  for i, p in ipairs(pages) do
    ctx.inBook[p.name] = true
    local text, left = gmbook.print(space.readPage(p.name))
    texts[i] = text
    if #left > 0 then ctx.live[p.name:sub(#root + 1)] = true end
  end
  local sep = "\n\n" .. gmbook.config.pageBreak .. "\n\n"
  for _, edition in ipairs(editions) do
    local parts = {}
    for i, text in ipairs(texts) do
      local section = pages[i].book_section == true
      ctx.from = pages[i].name:sub(#root + 1)
      if i > 1 then parts[#parts + 1] = section and "\n\n" or sep end
      parts[#parts + 1] = gmbook.render(text, edition == "player", section, ctx)
    end
    local out = gmbook.output(edition, root)
    local book, sheets = table.concat(parts), nil
    if gmbook.config.paginate then book, sheets = gmbook.paginate(book) end
    space.writePage(out, book)
    report.written[#report.written + 1] = { edition = edition, page = out, sheets = sheets }
  end
  for _, p in ipairs(pages) do
    local name = p.name:sub(#root + 1)
    if ctx.live[name] then report.live[#report.live + 1] = name end
  end
  for what in pairs(ctx.missing) do report.missing[#report.missing + 1] = what end
  table.sort(report.missing)
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
    names[#names + 1] = "the " .. label ..
      (w.sheets and " (" .. w.sheets .. " Homebrewery pages)" or "")
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
      (#report.live == 1 and " page holds" or " pages hold") ..
      " expressions with nothing to print, so they print as code: " ..
      table.concat(report.live, ", ") ..
      ". Run Baked Sections: Update on them and build again."
  end
  if #report.missing > 0 then
    kind = "warning"
    message = message .. " " .. #report.missing .. (#report.missing == 1 and
      " transclusion names a page or section that can't be found, so it prints nothing: " or
      " transclusions name pages or sections that can't be found, so they print nothing: ") ..
      table.concat(report.missing, ", ") .. "."
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
gmbook = gmbook or {}

-- Homebrewery's 5ePHB theme on US Letter, measured in its renderer, in CSS px.
gmbook.layout = {
  height = 938.83,  -- a column: the page less its margins
  slack  = 16,      -- kept free at the foot of each page against estimation error
}

-- Character widths in px, measured the same way: ASCII 32-126, then
-- fontExtras. head is per px of heading size, caps is a-z in the small caps
-- of a chapter's first line, and drop is A-Z as the drop cap that opens it.
gmbook.fontExtras = "—–’‘“”…★◆●▲■é×½→·"
gmbook.fonts = {
  body   = "3.23 3.08 5.44 7.09 7.43 10.57 9.62 3.08 3.98 3.98 4.94 7.09 3.08 3.12 3.08 3.98 7.43 7.43 7.43 7.43 7.43 7.43 7.43 7.43 7.43 7.43 3.08 3.08 7.09 7.09 7.09 6.03 12.02 8.55 9.05 9 9.82 8.84 8.46 9.76 10.15 4.54 4.43 9.47 8.22 11.49 9.74 9.68 8.85 9.68 9.28 8.82 8.57 9.84 8.55 12.53 8.78 8.09 8.38 4.18 3.93 4.18 7.02 6.96 6.6 6.66 7.04 6.2 7.18 6.54 3.85 6.75 7.35 3.55 3.43 6.91 3.55 11.17 7.35 6.96 7.12 6.99 5.16 5.97 4.1 7.25 5.96 9.79 6.58 5.96 6.07 3.98 3.98 3.98 6.63 10.5 6.43 3.07 3.07 5.38 5.38 9.13 10.71 10.67 7.76 12.72 7.76 6.54 7.09 9.63 12.85 4.28",
  bold   = "2.78 3.19 6.13 7.32 7.32 10.48 9.67 2.31 4 4 4.48 7.03 3.18 3.35 3.18 4 7.32 7.32 7.32 7.32 7.32 7.32 7.32 7.32 7.32 7.32 3.18 3.18 7.03 7.03 7.03 5.97 11.44 8.95 9.06 8.67 9.67 8.67 8.12 9.38 10.18 4.56 4.49 9.57 7.95 11.49 9.07 9.9 8.87 9.9 9.4 8.37 8.63 9.6 8.95 12.35 8.69 8.45 8.22 3.46 4 3.45 7.03 7.03 6.65 6.77 7.26 6.19 7.4 6.55 3.88 6.6 7.59 3.65 3.51 7.41 3.65 11.54 7.59 7.07 7.32 7.25 5.48 5.99 4.24 7.52 6.16 9.8 6.62 6.16 6.15 4 4 4 6.65 10.71 6.17 3.18 3.18 5.75 6.13 10.05 10.45 11.08 7.51 12.46 7.51 6.55 7.03 9.38 12.59 4.03",
  scaly  = "3.01 3.18 4.96 7.81 6.42 10.22 8.43 3.02 4.37 4.37 6.01 6.62 3.03 3.32 3.02 4.92 6.01 6 6.01 6.01 6.01 6.01 6.01 6.01 6.01 6.01 3.02 3.02 6.62 6.62 6.62 5.06 12.02 7.16 7.1 7.27 8.54 6.48 6.28 8.51 9.27 3.6 3.6 6.87 5.95 10.55 9.12 9.17 6.69 9.17 7.02 6.42 6.48 8.42 7.01 10.38 6.88 6.62 7.16 3.01 4.92 3.01 6.28 6.01 4.6 5.72 6.33 5.34 6.48 5.63 3.4 6.09 6.45 2.97 2.95 5.46 2.88 10.18 6.55 6.41 6.53 6.25 4.05 5.38 3.72 6.5 5.38 8.03 4.83 4.88 5.53 4.92 3.01 4.92 6.54 12.02 6.01 3.03 3.03 5.25 5.25 9.01 10.01 10.04 7.26 11.9 7.26 5.63 6.62 9.01 12.02 4.01",
  scalyB = "2.77 2.94 4.72 6.38 6.29 9.98 8.19 2.78 3.48 3.48 5.77 6.38 2.78 3.08 2.78 4.68 5.77 5.77 5.77 5.77 5.77 5.77 5.77 5.77 5.77 5.77 2.78 2.81 6.38 6.38 6.38 4.78 11.78 6.92 6.87 7.03 8.3 6.24 6.03 8.27 9.03 3.37 3.37 6.62 5.71 10.31 8.88 8.93 6.45 8.93 6.78 6.18 6.24 8.18 6.77 10.15 6.63 6.38 6.92 2.77 4.68 2.77 6.03 5.77 4.37 5.45 5.99 5.09 6.15 5.38 3.23 5.85 6.31 2.73 2.71 5.38 2.63 9.76 6.31 5.97 6.23 5.94 3.81 5.13 3.48 6.31 6.54 8.19 5.24 4.97 4.94 4.68 2.77 4.68 6.3 11.78 5.77 2.78 2.78 5.01 5.01 8.77 9.77 10.04 7.02 11.66 7.02 5.38 6.38 8.77 11.78 3.77",
  head   = "0.233 0.314 0.412 0.435 0.498 0.763 0.657 0.245 0.358 0.358 0.407 0.458 0.313 0.458 0.313 0.181 0.467 0.467 0.467 0.467 0.467 0.467 0.467 0.467 0.467 0.467 0.335 0.335 0.5 0.458 0.5 0.504 0.708 0.617 0.598 0.692 0.713 0.583 0.536 0.725 0.765 0.346 0.346 0.73 0.575 0.825 0.725 0.808 0.54 0.808 0.62 0.498 0.641 0.716 0.617 0.793 0.614 0.625 0.575 0.358 0.348 0.358 0.485 0.358 0.405 0.514 0.49 0.517 0.558 0.475 0.435 0.558 0.62 0.322 0.322 0.571 0.443 0.678 0.597 0.602 0.433 0.602 0.485 0.398 0.464 0.573 0.514 0.664 0.513 0.483 0.445 0.358 0.467 0.358 0.423 0.667 0.5 0.251 0.251 0.418 0.418 0.896 0.833 0.855 0.604 0.99 0.604 0.475 0.57 0.75 1 0.334",
  caps   = "5.77 6.1 6.07 6.62 5.97 5.71 6.58 6.84 3.06 2.99 6.4 5.54 7.75 6.57 6.53 5.98 6.53 6.26 5.95 5.78 6.65 5.77 8.46 5.93 5.47 5.66",
  drop   = "68.21 59.23 62.4 55.94 79.77 65.7 70.34 68.99 35.79 63.69 69.7 68.47 88.56 86.23 75.64 55.17 100.57 60.14 55.68 71.9 75.06 65.11 68.08 84.36 55.75 82.29",
}

-- Letter pairs that set wider than their two widths add up to. Pairs that
-- set tighter are left out, so the estimate errs long, never short.
gmbook.kerning = {
  bold   = "(J1.85 [J1.73 (j1.57 f?1.57 [j1.54 f’1.39 f”1.38 FA1.34 f)1.31 f]1.28 f!1.16 Wa1.06 Wd0.93 Wq0.93 PT0.3 Pv0.3 Pw0.3 Py0.3 ‘v0.29 ‘w0.29 ‘y0.29 “v0.29 “w0.29 “y0.29 W?0.25 V?0.22 Pt0.2 b-0.2 p-0.2 ‘t0.2 (V0.19 (W0.19 (Y0.19 E-0.19 E—0.19 L-0.19 Y)0.19 Z-0.19 b—0.19 c:0.19 c;0.19 ca0.19 p—0.19 ‘,0.19 ‘.0.19 ‘b0.19 ‘h0.19 ‘i0.19 ‘j0.19 ‘k0.19 ‘l0.19 “,0.19 “.0.19 “b0.19 “h0.19 “j0.19 “k0.19 “t0.19 L—0.18 Y?0.18 Z—0.18 “i0.18 “l0.18 rv0.17 rw0.17 ry0.17 vt0.14 wt0.14 yt0.14 [V0.12 [W0.12 [Y0.12 -O0.1 -Q0.1 -e0.1 -o0.1 D-0.1 O-0.1 Ov0.1 Ow0.1 Oy0.1 PC0.1 PO0.1 PQ0.1 P’0.1 P”0.1 Q-0.1 Qv0.1 Qw0.1 Qy0.1 o-0.1 —e0.1 ‘S0.1",
  scaly  = "f]1.31 f)1.07 f”0.72 f!0.71 f?0.71 f’0.35",
  scalyB = "f]1.79 f)1.55 f’1.31 f”1.31 f?1.2 f!1.19",
}

local W1, W2 = 319.19, 672.39      -- a column; both, for a chapter title
local LINE, BUMP = 16.063, 0.666    -- body line; bold or italic makes a line taller
local NOTE_LINE, NOTE_PAD, NOTE_W = 14.427, 11.146, 305.77
local HEADS = {                     -- font size, line height, extra below
  h1 = {33.638, 33.635, 6.803}, h2 = {28.347, 28.006, 0}, h3 = {21.732, 21.624, 2},
  h4 = {17.31, 16.808, 0}, h5 = {15.987, 15.208, 0}, h6 = {12.85, 15.417, 0},
}
local CODE_W, CODE_PAD = 7.37, 4     -- Courier New in code, and the padding either side of a span
local CODE_BUMP, PRE_W = 2, 306.5    -- a body line holding code is taller; a code block's width
local DROP_PUNCT = 58.7              -- a quote mark ahead of the drop cap
local OWN = {h3 = 5.86, h4 = 8.88, note = 9, descriptive = 4}
local BOX = {note = true, descriptive = true, box = true}

-- SilverBullet strings are UTF-16; stock Lua's are UTF-8 bytes
local WIDE = #"—" == 1
local CHAR = WIDE and "^." or ("^[" .. string.char(0) .. "-" .. string.char(127) ..
  string.char(194) .. "-" .. string.char(244) .. "][" .. string.char(128) .. "-" ..
  string.char(191) .. "]*")

local F, EXTRA, KERN

local function fonts()
  if F then return F end
  F, EXTRA, KERN = {}, {}, {}
  for name, list in pairs(gmbook.fonts) do
    local t = {}
    for v in list:gmatch("%S+") do t[#t + 1] = tonumber(v) end
    F[name] = t
  end
  for name, list in pairs(gmbook.kerning) do
    local kp = {}
    for token in list:gmatch("%S+") do
      local pair, v = token:match("^(.-)([%d.]+)$")
      kp[pair] = tonumber(v)
    end
    KERN[F[name]] = kp
  end
  local s, p, i = gmbook.fontExtras, 1, 95
  while p <= #s do
    local ch = s:match(CHAR, p)
    i = i + 1
    EXTRA[ch] = i
    p = p + #ch
  end
  return F
end

local function charWidth(t, ch)
  local b = ch:byte()
  if b < 128 then return t[b - 31] or 0 end
  return t[EXTRA[ch] or 79]  -- 79 is "n"
end

-- Width tables for plain and strong text, a scale, an addition per
-- character, and how much taller bold or italic, or code, makes a line.
local function family(kind)
  local f = fonts()
  local h = HEADS[kind]
  if kind == "scaly" then return {r = f.scaly, b = f.scalyB, s = 1, add = 0, bump = 0, code = 0.667} end
  if kind == "th" then return {r = f.scalyB, b = f.scalyB, s = 1, add = 0.24, bump = 0, code = 0.667} end
  if kind == "h5" then return {r = f.scaly, b = f.scaly, s = h[1] / 12.019, add = 0, bump = 0, code = 2} end
  if kind == "h6" then return {r = f.bold, b = f.bold, s = 1, add = 0, bump = 0, code = 2} end
  if h then return {r = f.head, b = f.head, s = h[1], add = 0, bump = 0, code = 3.33} end
  return {r = f.body, b = f.bold, s = 1, add = 0, bump = BUMP, code = CODE_BUMP}
end

-- Inline Markdown as unbreakable pieces with their widths. Each piece has
-- the space before it (0 where a line breaks without one, after a hyphen or
-- dash) and how much taller it makes its line: bold, italic and code come
-- from fonts that sit higher. dropCap floats the opening letter out, with
-- any punctuation before it, and prices each piece in small caps too, for
-- the first line.
local function pieces(text, fam, dropCap)
  text = text:gsub("!%[[^%]]*%]%([^%)]*%)", "")
  text = text:gsub("%[([^%]]*)%]%([^%)]*%)", "%1")
  text = text:gsub("<[^>]*>", "")
  text = text:gsub("&nbsp;", " ")
  text = text:gsub("&amp;", "&")
  local caps = dropCap and fonts().caps
  local out, cur, space, pad = {}, nil, 0, 0
  local bold, italic, code, last = false, false, false, nil
  local drop = dropCap and "letter"
  local function flush()
    if cur then out[#out + 1] = cur end
    cur, last = nil, nil
  end
  local function add(ch, nextCh)
    if drop then
      -- Chrome floats punctuation with the letter, unless markup comes between
      if ch:match("%w") then drop = nil else drop = "punct" end
      return
    end
    -- Homebrewery sets straight quotes curly
    if ch == "'" then ch = cur and "’" or "‘" elseif ch == '"' then ch = cur and "”" or "“" end
    if ch == "—" and cur then
      flush()
      space = 0
    end
    local t = bold and fam.b or fam.r
    local w = code and CODE_W or charWidth(t, ch) * fam.s + fam.add
    local kp = not code and last and KERN[t]
    if kp then w = w + (kp[last .. ch] or 0) end
    if not cur then
      cur = {w = 0, c = 0, sp = space, bump = 0}
      space = 0
    end
    cur.w = cur.w + w + pad
    if caps then cur.c = cur.c + (ch:match("%l") and caps[ch:byte() - 96] or w) + pad end
    pad, last = 0, ch
    local bump = (code and fam.code) or ((bold or italic) and fam.bump) or 0
    if bump > cur.bump then cur.bump = bump end
    if ch == "—" or ch == "–" or (ch == "-" and nextCh:match("%a")) then
      flush()
      space = 0
    end
  end
  local p, n = 1, #text
  while p <= n do
    local c = text:sub(p, p)
    local q = p
    if c == "`" then
      code, last = not code, nil
      if code or not cur then  -- inline code is padded at both ends
        pad = pad + CODE_PAD
      else
        cur.w, cur.c = cur.w + CODE_PAD, cur.c + CODE_PAD
      end
      if drop == "punct" then drop = nil end
    elseif (c == "*" or c == "_") and not code then
      while text:sub(q + 1, q + 1) == c do q = q + 1 end
      local before, after = text:sub(p - 1, p - 1), text:sub(q + 1, q + 1)
      if before:match("^%s?$") and after:match("^%s?$")
        or c == "_" and before:match("%w") and after:match("%w") then
        for _ = p, q do add(c, after) end
      else
        if q > p then bold = not bold end
        if (q - p) % 2 == 0 then italic = not italic end
        if drop == "punct" then drop = nil end
        last = nil  -- no kerning across a change of font
      end
    elseif c == " " or c == "\t" then
      flush()
      space = code and CODE_W or charWidth(bold and fam.b or fam.r, " ") * fam.s + fam.add
    else
      if c == "\\" and not code and text:sub(p + 1, p + 1):match("%p") then
        q = q + 1
        c = text:sub(q, q)
      end
      if not WIDE and c:byte() >= 192 then c = text:match(CHAR, q) or c end
      q = q + #c - 1
      add(c, text:sub(q + 1, q + 1))
    end
    p = q + 1
  end
  flush()
  return out
end

-- Break pieces into lines greedily, as a browser does. room(y) is the width
-- free at height y. Returns the height of each line.
local function wrap(ps, room, lineHeight, y, indent, capsFirst)
  local lines, x, bump, empty = {}, indent or 0, 0, true
  local limit = room(y)
  local function newline()
    local h = lineHeight + bump
    lines[#lines + 1] = h
    y = y + h
    x, bump, empty, limit = 0, 0, true, room(y)
  end
  for _, pc in ipairs(ps) do
    local w = (capsFirst and #lines == 0) and pc.c or pc.w
    if not empty and x + pc.sp + w > limit + 0.01 then
      newline()
      w = pc.w
    end
    x = x + (empty and 0 or pc.sp) + w
    empty = false
    if pc.bump > bump then bump = pc.bump end
    while x > limit + 0.01 and limit > 20 do  -- overflow-wrap splits a word too long for a line
      local over = x - limit
      newline()
      x, empty, bump = over, false, pc.bump
    end
  end
  if not empty or #lines == 0 then newline() end
  return lines
end

local function sum(t)
  local s = 0
  for _, v in ipairs(t) do s = s + v end
  return s
end

-- The manuscript as blocks: heading, paragraph, list item, quote, table,
-- {{box}}, code, rule, or an explicit \page or \column.
local function isBreak(l)
  local c = l:match("^%s*([-*_])")
  if not c then return false end
  local bare = l:gsub("%s", "")
  local rest = bare:gsub("%" .. c, "")
  return #bare >= 3 and rest == ""
end

local function isItem(l)
  return l:match("^%s*[-*+]%s+%S") or l:match("^%s*%d+[.)]%s+%S")
end

local function opensBlock(l)
  return l:match("^%s*$") or l:match("^#+%s") or l:match("^{{") or l:match("^|")
    or l:match("^>") or isItem(l) or l:match("^\\") or l:match("^%`%`%`")
    or l:match("^~~~") or l:match("^<") or isBreak(l)
end

local function parse(text)
  local lines = {}
  for l in (text .. "\n"):gmatch("([^\n]*)\n") do lines[#lines + 1] = l end
  local out, i, n = {}, 1, #lines
  local blank = false
  while i <= n do
    local l = lines[i]
    local b = {first = i}
    if l:match("^%s*$") then
      b = nil
      i = i + 1
      blank = true
    elseif l:match("^\\page") then
      b.kind = "page"
      i = i + 1
    elseif l:match("^\\column") then
      b.kind = "column"
      i = i + 1
    elseif l:match("^#+%s") then
      local hashes, t = l:match("^(#+)%s+(.-)%s*$")
      b.kind = "h" .. math.min(#hashes, 6)
      b.text = t:gsub("%s+#+$", "")
      i = i + 1
    elseif l:match("^{{") then
      local cls, depth, j = l:match("^{{(%S*)"), 0, i
      repeat
        local _, opened = lines[j]:gsub("{{", "")
        local _, closed = lines[j]:gsub("}}", "")
        depth = depth + opened - closed
        j = j + 1
      until depth <= 0 or j > n
      b.kind = (cls:match("^note") and "note") or (cls:match("^descriptive") and "descriptive") or "box"
      b.inner = {}
      if j == i + 1 then
        local one = l:gsub("^{{%S*%s*", "")
        b.inner[1] = one:gsub("}}%s*$", "")
      else
        for k = i + 1, j - 2 do b.inner[#b.inner + 1] = lines[k] end
      end
      i = j
    elseif l:match("^|") then
      b.kind, b.rows = "table", {}
      while i <= n and lines[i]:match("^|") do
        b.rows[#b.rows + 1] = lines[i]
        i = i + 1
      end
    elseif l:match("^>") then
      b.kind, b.inner = "quote", {}
      while i <= n and lines[i]:match("^>") do
        b.inner[#b.inner + 1] = lines[i]:gsub("^>%s?", "")
        i = i + 1
      end
    elseif isBreak(l) then
      b.kind = "hr"
      i = i + 1
    elseif isItem(l) then
      -- Markdown nests an item only when it is indented as far as its
      -- parent's text: two spaces under "- ", three under "1. ".
      local indent, marker, space = l:match("^(%s*)(%S+)(%s+)")
      b.kind = "li"
      b.list = marker:match("^%d") and "ol" or "ul"
      b.key = marker:match("^%d") and marker:sub(-1) or marker
      b.at, b.content = #indent, #indent + #marker + #space
      b.text = l:gsub("^%s*%S+%s+", "")
      i = i + 1
      while i <= n and lines[i]:match("^%s+%S") and not isItem(lines[i]) do
        local more = lines[i]:gsub("^%s+", "")
        b.text = b.text .. " " .. more
        i = i + 1
      end
      local last = out[#out]
      if last and last.kind == "li" and b.at >= last.content then
        -- a nested item lives inside its parent's box, and they never part
        last.subs = last.subs or {}
        local above = last.subs[#last.subs]
        if not above then b.level = 1
        elseif b.at >= above.content then b.level = above.level + 1
        elseif b.at >= above.at then b.level = above.level
        else b.level = 1
        end
        last.subs[#last.subs + 1] = b
        b = nil
      else
        b.opens = not (last and last.kind == "li" and last.key == b.key)
        b.head = b.opens and b or last.head
        -- a blank line between items makes the whole list loose: each item's
        -- text becomes a paragraph, and p+* spaces a nested list from it
        if blank and not b.opens then b.head.loose = true end
      end
    elseif l:match("^%`%`%`") or l:match("^~~~") then
      local fence = l:sub(1, 3)
      b.kind, b.code = "code", {}
      i = i + 1
      while i <= n and lines[i]:sub(1, 3) ~= fence do
        b.code[#b.code + 1] = lines[i]
        i = i + 1
      end
      i = i + 1
    elseif l:match("^<") then
      b.kind = "html"
      i = i + 1
      while i <= n and not lines[i]:match("^%s*$") do i = i + 1 end
    else
      b.kind, b.text = "p", l
      i = i + 1
      while i <= n and not opensBlock(lines[i]) do
        b.text = b.text .. " " .. lines[i]
        i = i + 1
      end
    end
    if b then
      out[#out + 1] = b
      blank = false
    end
  end
  return out, lines
end

-- Space between two sibling blocks, from the theme's p+*, h3+*, *+h3 ...
-- rules. Boxes are inline-blocks, so a list's bottom margin adds to theirs.
local function gap(prev, kind)
  if prev == "note" or prev == "descriptive" then return 17.01 end
  if kind == "hr" then return 0 end
  local m = OWN[kind] or 0
  if kind == "h3" or kind == "h4" then
    if prev == "h4" then m = kind == "h4" and 8.88 or 3.40
    elseif prev == "h5" then m = 7.56
    elseif prev == "table" then m = 12.28
    end
  elseif prev == "p" then m = kind == "p" and 0 or 12.28
  elseif prev == "h3" then m = 6.43
  elseif prev == "h4" then m = 3.40
  elseif prev == "h5" then m = 7.56
  elseif prev == "table" then m = 12.28
  end
  if prev == "ul" or prev == "ol" then
    return BOX[kind] and 10.28 + m or math.max(10.28, m)
  end
  return m
end

local cache = {}

local function textLines(text, kind, width, lineHeight, ctx, indent, dropCap)
  local fam = family(kind)
  local key = kind .. (dropCap and "^" or "|") .. text
  local ps = cache[key]
  if not ps then
    ps = pieces(text, fam, dropCap)
    cache[key] = ps
  end
  local room = function(y) return width - ctx.inset(y) end
  return wrap(ps, room, lineHeight, ctx.y, indent, dropCap)
end

-- Height of the paragraphs, list items and small headings inside a quote or
-- box. Notes indent their lists 1em and drop the last margin; a plain quote
-- or box indents them 1.4em, and a box keeps a closing list's margin.
local function flow(inner, kind, width, lineHeight, em, ctx, noteLike, keepsMargin)
  local h, prev = 0, nil
  local y0 = ctx.y
  local pad = noteLike and em or 1.4 * em
  for _, b in ipairs((parse(table.concat(inner, "\n")))) do
    local k = b.kind == "li" and "ul" or b.kind
    if b.text then
      local g = 0
      if prev == "ul" and k ~= "ul" then g = 0.8 * em
      elseif prev == "h5" then g = 3.78
      elseif prev == "p" and k ~= "p" then g = 12.28
      end
      h = h + g
      ctx.y = y0 + h
      if k == "h5" then
        h = h + 13.48 * #textLines(b.text, "h5", width, 13.48, ctx)
      else
        local w = k == "ul" and width - pad or width
        local indent = (k == "p" and (prev == "p" or prev == "ul")) and em or 0
        h = h + sum(textLines(b.text, kind, w, lineHeight, ctx, indent))
        for _, sub in ipairs(b.subs or {}) do
          h = h + sum(textLines(sub.text, kind, w - (pad + 1.5 * em) * sub.level, lineHeight, ctx, 0))
        end
      end
      prev = k
    end
  end
  if prev == "ul" and keepsMargin then h = h + 0.8 * em end
  ctx.y = y0
  return h
end

local function cells(row)
  local out = {}
  row = row:gsub("^%s*|", "")
  row = row:gsub("|%s*$", "")
  for c in (row .. "|"):gmatch("(.-)|") do out[#out + 1] = c end
  return out
end

-- A table sizes its columns by content, as CSS automatic table layout does,
-- then each row is as tall as its tallest cell.
local function tableHeight(rows)
  local grid = {{cells = cells(rows[1]), fam = family("th")}}
  for r = 3, #rows do grid[#grid + 1] = {cells = cells(rows[r]), fam = family("scaly")} end
  local ncol = #grid[1].cells
  local minW, maxW = {}, {}
  for c = 1, ncol do minW[c], maxW[c] = 3, 3 end
  for _, row in ipairs(grid) do
    row.ps = {}
    for c = 1, ncol do
      local ps = pieces(row.cells[c] or "", row.fam)
      local line, widest = 0, 0
      for k, pc in ipairs(ps) do
        line = line + (k > 1 and pc.sp or 0) + pc.w
        widest = math.max(widest, pc.w)
      end
      row.ps[c] = ps
      minW[c] = math.max(minW[c], widest + 3)
      maxW[c] = math.max(maxW[c], line + 3)
    end
  end
  local sumMin, sumMax = 0, 0
  for c = 1, ncol do
    sumMin = sumMin + minW[c]
    sumMax = sumMax + maxW[c]
  end
  local h = 0
  for _, row in ipairs(grid) do
    local most = 0
    for c = 1, ncol do
      local w
      if sumMax <= W1 then w = maxW[c] * W1 / sumMax
      elseif sumMin >= W1 then w = minW[c]
      else w = minW[c] + (W1 - sumMin) * (maxW[c] - minW[c]) / (sumMax - sumMin)
      end
      if #row.ps[c] > 0 then
        most = math.max(most, #wrap(row.ps[c], function() return w - 3 end, 16, 0, 0))
      end
    end
    h = h + most * 16
  end
  return h
end

-- A code block's line wraps at spaces, in fixed-width characters.
local function codeLines(line)
  local ps = {}
  for gap, word in line:gmatch("(%s*)(%S+)") do
    local w = #word * CODE_W
    if #ps == 0 then w = w + #gap * CODE_W end
    ps[#ps + 1] = {w = w, c = 0, sp = #gap * CODE_W, bump = 0}
  end
  return #wrap(ps, function() return PRE_W end, 1, 0, 0)
end

-- The drop cap is the opening letter at 3.5cm, with any punctuation ahead
-- of it; markup between the two (a quote, then bold) leaves the letter out.
local function dropWidth(text)
  local p = 1
  while text:sub(p, p):match("[%*_`%[]") do p = p + 1 end
  local c, w = text:sub(p, p), 0
  if c ~= "" and not c:match("%w") then
    if not WIDE and c:byte() >= 192 then c = text:match(CHAR, p) or c end
    w, p = DROP_PUNCT, p + #c
    if text:sub(p, p):match("[%*_`%[]") then return w end
    c = text:sub(p, p)
  end
  local d = fonts().drop
  return w + (c:match("%a") and d[c:upper():byte() - 64] or 70)
end

-- A text block as the height of each line (it can split between columns),
-- anything else as one unbreakable height.
local function measure(b, ctx, prev)
  local k = b.kind
  if k == "p" then
    local indent = (prev == "p" or prev == "ul" or prev == "ol" or prev == "table") and 12.85 or 0
    return {lines = textLines(b.text, "body", W1, LINE, ctx, indent, b.dropCap)}
  elseif k == "li" then
    local h = sum(textLines(b.text, "body", W1 - 17.99, LINE, ctx, 0))
    if b.subs and b.head.loose then h = h + 12.28 end
    for _, sub in ipairs(b.subs or {}) do
      h = h + sum(textLines(sub.text, "body", W1 - 17.99 - 37.27 * sub.level, LINE, ctx, 0))
    end
    return {h = h}
  elseif HEADS[k] then
    local spec = HEADS[k]
    return {h = sum(textLines(b.text, k, k == "h1" and W2 or W1, spec[2], ctx)) + spec[3]}
  elseif k == "quote" then
    return {h = flow(b.inner, "body", W1, LINE, 12.85, ctx, false, false)}
  elseif k == "note" then
    local flat = {y = 0, inset = function() return 0 end}
    return {h = NOTE_PAD + flow(b.inner, "scaly", NOTE_W, NOTE_LINE, 12.02, flat, true, false)}
  elseif k == "descriptive" then
    local flat = {y = 0, inset = function() return 0 end}
    return {h = 16 + flow(b.inner, "scaly", W1 - 17, 18.03, 12.02, flat, true, false)}
  elseif k == "box" then
    local flat = {y = 0, inset = function() return 0 end}
    return {h = flow(b.inner, "body", W1, LINE, 12.85, flat, false, true)}
  elseif k == "table" then
    return {h = tableHeight(b.rows)}
  elseif k == "code" then
    local n = 0
    for _, l in ipairs(b.code) do n = n + codeLines(l) end
    return {h = 16.667 + 12.281 * n}
  elseif k == "hr" then
    return {h = 1.333}
  end
  return {h = 0}
end

local function keepsWithNext(b)
  return b.kind:match("^h[2-6]$") ~= nil or (b.kind == "p" and b.text:match(":%s*$") ~= nil)
end

-- Lay blocks out on one page, starting at block s, the way the two columns
-- fill. Returns the block the next page starts at, and whether an explicit
-- \page already puts it there; nil once the rest fits.
local function fitPage(bs, s, trace, pageNo)
  local L = gmbook.layout
  local H = L.height
  local top, col, y, prev, float = 0, 1, 0, nil, nil
  local placed = {}
  local ctx = {y = 0}
  ctx.inset = function(yy)
    return (float and col == 1 and yy < float.bottom) and float.w or 0
  end
  local function breakAt(i)
    if #placed == 0 then return i, false end
    local keep = bs[placed[1]].kind == "h1" and 2 or 1
    local j = #placed
    while j > keep and keepsWithNext(bs[placed[j]]) do j = j - 1 end
    return j < #placed and placed[j + 1] or i, false
  end
  local i = s
  if bs[i] and bs[i].kind == "h1" then
    top = measure(bs[i], ctx).h
    y = top
    placed[1] = i
    i = i + 1
    if bs[i] and bs[i].kind == "p" then
      float = {bottom = top + 102.94, w = dropWidth(bs[i].text)}
      bs[i].dropCap = true
    end
  end
  local content = top > 0 and 1 or 0
  while i <= #bs do
    local b = bs[i]
    local k = b.kind
    if k == "page" then return i + 1, true end
    if k == "h1" and #placed > 0 then return i, false end
    if k == "column" then
      if col == 2 then return i + 1, false end
      col, y, prev = 2, top, nil
    elseif k ~= "html" then
      -- Margins vanish at the top of a column, except a box's: boxes are
      -- inline-blocks, and their margin sits inside the line that holds them.
      local g = gap(prev, k == "li" and b.list or k)
      if k == "li" and not b.opens then g = 0 end
      local boxed = g
      if not BOX[k] then boxed = 0 end
      if y <= top + 0.01 then g = (top > 0 and col == 1) and 0 or boxed end
      local bottom = col == 1 and H or H - L.slack
      if float and col == 1 and (BOX[k] or k == "table") and y + g < float.bottom then
        g = float.bottom - y  -- a full-width box can't sit beside the drop cap
      end
      ctx.y = y + g
      local m = measure(b, ctx, prev)
      local at, h = y + g, m.h
      if m.lines then
        local ls = m.lines
        local fit, yy = 0, y + g
        while fit < #ls and yy + ls[fit + 1] <= bottom + 0.01 do
          fit = fit + 1
          yy = yy + ls[fit]
        end
        if fit < #ls then
          -- Chrome never leaves one line at the foot of a column, and moves
          -- lines over so two start the next, unless that would leave one
          if fit < 2 then fit = 0
          elseif #ls - fit < 2 then fit = math.max(2, #ls - 2)
          end
        end
        if fit == #ls then
          y = yy
        elseif col == 1 then
          col = 2
          if fit == 0 then
            ctx.y = top
            ls = measure(b, ctx, prev).lines
            at = top
          end
          local rest = 0
          for j = fit + 1, #ls do rest = rest + ls[j] end
          y = top + rest
          if y > H - L.slack + 0.01 and #placed > content then return breakAt(i) end
        else
          return breakAt(i)
        end
        h = sum(ls)
      elseif at + h <= bottom - (col == 1 and L.slack or 0) + 0.01 then
        y = at + h  -- in column 1 it needs the slack too: if it jumped a column, all of it would
      elseif col == 1 and top + boxed + h <= H - L.slack + 0.01 then
        col, at = 2, top + boxed
        y = at + h
      elseif #placed > content then
        return breakAt(i)
      else
        y = at + h  -- taller than a page: it spills whatever happens
      end
      if trace then
        trace[#trace + 1] = {line = b.first, kind = k, page = pageNo, col = col, y = at, h = h}
      end
      prev = k == "li" and b.list or k
    end
    placed[#placed + 1] = i
    i = i + 1
  end
  return nil
end

-- Put a \page wherever a page fills up. Returns the text and its page count.
function gmbook.paginate(text, trace)
  cache = {}
  local bs, lines = parse(text)
  local at, s, pages = {}, 1, 1
  while s <= #bs do
    local nxt, explicit = fitPage(bs, s, trace, pages)
    if not nxt or nxt > #bs then break end
    if nxt <= s then nxt = s + 1 end
    while trace and #trace > 0 and trace[#trace].line >= bs[nxt].first do
      table.remove(trace)  -- a heading that moved on with its text
    end
    if not explicit then at[bs[nxt].first] = true end
    pages = pages + 1
    s = nxt
  end
  local out = {}
  for n, l in ipairs(lines) do
    if at[n] then
      if #out > 0 and out[#out] ~= "" then out[#out + 1] = "" end
      out[#out + 1] = gmbook.config.pageBreak
      out[#out + 1] = ""
    end
    out[#out + 1] = l
  end
  return table.concat(out, "\n"), pages
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
