---
tags: meta/library
name: "Library/Storie/GM Book"
description: "Compile a campaign space into a single manuscript in DM and player editions, transformed for Homebrewery so it renders as a WotC-style 5e book."
author: "Steven Storie"
version: "1.13.0"
---

# GM Book

Compile a campaign space into a single manuscript, in two editions, ready for [Homebrewery](https://homebrewery.naturalcrit.com) to render as a WotC-style 5e book.

Self-contained as of 1.1: it no longer needs GM Kit, so it can live inside a standalone adventure space.

## Buttons

- **In the header**, the printer builds both editions.
- **On a built page**, a bar across the top has *Build again*, *Copy for Homebrewery* and *Open Homebrewery*, and *Open PDF* when a PDF of that edition sits beside it: see *Rendering it*. The bar isn't part of the page, so the copy is the manuscript alone.
- **After a build**, the notification has a button to open each edition.

A build takes a while, and one runs at a time: a click while one is running is told so and starts nothing.

**A tab that needs a reload builds nothing.** Space Lua is read when a tab opens and not again, so a tab left open while `Library: Update` brings a new GM Book, or a new release of a library the book prints with, runs the old code over the new pages. Its build is refused, with a notification naming each library and both versions, and the bar on a built edition says so first, *⟳ Reload this tab*, until `System: Reload` (Ctrl-Alt-R). Both have a *Reload* button that runs it, for a phone, which has no keyboard to press it on. Each library's version is read from its own page, at any depth of the space, so a copy at another depth with another version is named too: remove the one you don't use. `gmbook.stale()` gives GM Book's message, or nil, and `gmbook.staleLibraries()` every message, GM Book's and those of the libraries in `gmbook.printers` that have a `stale()` of their own, such as GM Maps.

To put a build button on a page of your own:

    ${widgets.commandButton("Build the book", "GM: Build Book")}

## The editions

| Command | Output | Contains |
|---|---|---|
| `GM: Build Book` | Both editions | The two below, built together |
| `GM: Build Book (DM)` | `Build/Book DM` | Everything, secrets included |
| `GM: Build Book (Player)` | `Build/Book Player` | The DM-only text left out: see *DM-only text* |
| `GM: Copy Book for Homebrewery` | The clipboard | The edition you are looking at, or the one you pick |

## DM-only text

The player edition leaves out everything a page marks as DM-only, and the DM's edition prints it as part of the page:

| Marked as | In the DM's edition |
|---|---|
| A DM callout: `> **dm** Title`, and the lines of the quote under it. Any callout whose type's first word is `dm` counts, in any case: `> **DM only**`, `> [!dm]` | Ordinary text, the title the bold lead of its first paragraph: "**Title.** The text…" |
| A stretch between `<!--#dm-->` and `<!--/dm-->`, the markers anywhere in a line | Everything between, the markers gone |
| An element whose class list holds `dm`: `<span class="dm">…</span>` inside a line, or a `<div class="dm">` round lines of their own | The words, the tags gone |
| A DM Only heading at any level and in any case, `## DM Only`, `### DM only`, `## DM-Only`, to the next heading of its level or above | As it is, heading and all |

A callout ends at the first blank line. A stretch holds anything, headings, tables and boxes included, and one with no end runs to the end of the page, so a start marker above a page's title keeps the whole page back. A page with nothing left for the player edition takes no room in it, not even a page break. **The player edition fails closed**: a page that still holds a DM-only mark after all this, a stretch left open or a tag written in a way the scan doesn't read, keeps the edition back and is named, rather than going out with it. None of them counts inside fenced code. GM Kit reads them with the same code, so the players' copies it publishes leave out exactly what the player edition does.

**A page only the DM may see** has nothing on it marked, because all of it is the DM's: a [GM Maps](<GM Maps>) map page writes out every creature and trapdoor in its map block. The player edition leaves out every page of such a type, even one with a `book_order`, and prints nothing where another page shows it. The DM's edition prints it like any other page. The types are `map` by default, and the type GM Maps is set to give its pages counts as well:

    config.set("gmBook.privateTypes", { "map", "plot" })

Each edition is printed from its own text, so an expression inside DM-only text prints in the DM's edition and never runs for the player edition. A map drawn with its DM's layer can sit in a callout right under the clean one: see [GM Maps](<GM Maps>). Unwrapped, a callout's paragraphs, tables and maps are measured like any others, so the page breaks fall around them as they do around the rest of the page.

## Setting the order

Put `book_order` in the frontmatter of any page that belongs in the book. Pages without it are skipped, so dashboards and scratch pages stay out automatically.

    book_order: 20

Leave gaps (10, 20, 30) so you can insert chapters without renumbering. Pages that share a `book_order` go in by their names, and a `book_order` that isn't a number, such as `soon`, puts its page at the end of the book. A build names both, and builds all the same.

## A chapter in several pages

A long chapter can be split into a page of its own for each scene or section. Give each of those pages `book_section: true`, and a `book_order` just after its chapter's:

    book_order: 18.01
    book_section: true

A section carries on the chapter before it. There is no page break ahead of it, and its headings drop a level, so its `#` title prints as a section of that chapter. Number sections with two decimals: with one, YAML reads a tenth section's 18.10 as 18.1, the same as the first.

A section whose chapter an edition leaves out, such as a chapter kept back for the DM from above its title, carries on whatever page comes before it in that edition, under that page's title. A build names such a section, and one with no chapter before it at all.

## Live values

A `${...}` expression prints as what it gives. Text and numbers print as they are, so `${1 + 2}` prints 3, and a widget prints its Markdown face.

A library can print something other than what the page shows. The builder evaluates every expression with the tables in `gmbook.printers` standing in for globals of the same name, so a library that puts its own table there decides what its functions print:

    gmbook = gmbook or {}
    gmbook.printers = gmbook.printers or {}
    gmbook.printers.mylib = mylib.printed

GM Party does this: on the page its numbers show your party's count, and in print they show the rule behind it.

**A printer that can't draw what it is asked for raises an error saying why**, or returns nil, never a message as if it were the thing: a map whose page isn't there, say. Either one keeps the edition back and names the page, the expression and why, and the widget on the page can say what went wrong. A message returned as text would be printed into the book as if it were the map.

While a page is being printed, `gmbook.printing` is that page's name, so an expression that reads the page it sits on prints from the right one. It is nil outside a build. Read it only in a printer: a widget the browser draws while a build runs belongs to the page on the screen, not to the one being printed.

A query's table, a button or anything else with no Markdown to give can't print, and nor can an expression that raises an error. **An edition holding one is kept back**: the builder writes nothing, leaves the edition already on the page as it is, and names each such expression with its page and why. Writing it would take what the expression draws out of the book with nothing in the text to say so, and a wiki that commits the book would push the loss; an edition a build old is the smaller harm.

The notification tells three causes apart. The expression may be one that never prints, such as a query or a button — bake those with `Baked Sections: Update`. The library that gives the expression its meaning may be missing from the client: Space Lua is read when a client boots and not again, so a library installed while the tab was open is on disk and in the index but not in its Lua, and every expression that calls it fails. `System: Reload` reads them afresh; the notification says so when the name an expression starts from means nothing in the tab. Otherwise the expression raised an error, such as `${party.nn()}` for `${party.n()}`, and the notification gives the error.

## One page shown in another

SilverBullet shows `![[Page]]` inside the page that holds it, or `![[Page#Section]]` for the section under one heading, down to the next heading of the same level. A scene can show an item's rules this way, and the item's page stays the one place they are written. Put each on a line of its own.

A book doesn't print the same text twice. Where the page shown is in the book, the builder prints a pointer to it instead, from that page's title and the section:

    *See Lantern: Rules.*

A page that isn't in the book is printed in place: the section, with its headings moved in under the heading above, and its expressions printed.

Each edition cuts the section out of the page as that edition prints it, never the other way round. So a section under a `## DM Only` heading, or on a page kept back from above its title, isn't in the player edition at all: it prints nothing there, neither in place nor as a pointer. The same goes for a pointer to a whole page with nothing left for the players. A pointer's words come from the page as its edition prints it too: the title without its DM-only words, and with its expressions printed. A page or section that no edition has prints nothing, and the build names it.

To print every one in place, or to word the pointer your own way (`%s` is the page and section):

    config.set("gmBook.transclusions", "inline")
    config.set("gmBook.see", "*For more, see %s.*")

With `gmBook.pageRefs`, the page and section are followed by the page they are on: see *Page numbers*.

## Building from a larger space

A build reads the pages that sit beside GM Book's own `Library/` folder, and writes `Build/` there. Installed at `Library/Storie/GM Book`, that is the whole space.

An adventure folder can also be part of a larger space, as `Adventure/` is when a DM space contains it. That space sees this page at `Adventure/Library/Storie/GM Book`, so a build started there reads only `Adventure/` and writes the same `Adventure/Build/` pages as a build from inside. To choose the folder yourself, put this in a `space-lua` block:

    config.set("gmBook", { root = "Module/" })

Copies of GM Book can end up at more than one depth, as `Library: Update All` in the larger space can leave them: one at `Library/Storie/GM Book` as well as the adventure's own. A build then reads from the shortest folder of any, here the whole space, so its notification names the copies. Remove the one you don't use, or set the root yourself.

In the larger space, a wiki link written for the adventure folder, such as `[[World/Items/Lantern]]`, isn't the page's full path, so SilverBullet finds it by the end of its path. Any other page whose path ends the same way, such as notes kept at the same path in another folder, matches too, and SilverBullet asks which one you meant. A relative Markdown link, `[Lantern](<../../World/Items/Lantern>)`, starts from the folder of the page it is on, so it opens the same page in either space. The builder prints it as its label.

## What it transforms

- Frontmatter stripped
- Expressions printed, as in *Live values*. A line that held only an expression printing nothing goes too.
- `![[Page#Section]]` becomes a pointer to it, or the section itself, as in *One page shown in another*
- `[[Some/Path/Page]]` becomes `Page`; `[[Page#Section]]` becomes `Page`; `[[Page|Label]]` becomes `Label`
- `[Label](<../Some/Page>)`, a link to a page in the space, becomes `Label`. Images and links to websites stay.
- Baked-section markers removed, rendered bodies kept
- DM-only text left out of the player edition, and in the DM's printed as ordinary text, as in *DM-only text*
- HTML comments, `<!-- … -->`, left out of the player edition: a brew doesn't show them, but anyone who opens it reads them. One never closed runs to the end of its page, as it does on the page. Code keeps its own.
- `> **note**` and `> **warning**` blockquotes become Homebrewery `{{note}}` boxes. A warning keeps a `warning` class, so a brew's style can set it apart.
- A section's headings dropped a level
- A page break before every chapter, though not before a section, and wherever a page fills up

A link prints as its label whatever it names, so in the player edition a label can name a page the players have nothing of: one kept back for the DM whole, one only the DM may see, such as a map's own page, or one not in the book at all. The notification after a build names each such page with the words a link gives it, and `report.missingLinks` lists every such link, its `label`, the `page` it names and the page it is `from`. It may be meant, so it is said, not warned of. A link in code, an image and a link to a website aren't counted, and a link in a section printed in place is read from the page it was written on.

## Page breaks

Homebrewery never carries text over to the next page. Whatever doesn't fit in a page's two columns runs on into a third column past the right edge, where it is cut off. So the builder lays each page out itself and puts a `\page` before the first block that would not fit.

The layout comes from measurements of Homebrewery's 5ePHB theme on US Letter, taken in Chrome: character widths for each font, line heights, the space between blocks, the drop cap. A page breaks between blocks, never inside a paragraph, list item, quote, table or box, and a heading goes with the text under it. Your own `\page` and `\column` lines are kept. A single block taller than a page still spills, so split it in the source.

**Raw HTML** is Homebrewery's own to lay out, so the builder leaves it out of the count — except where the element says how tall it is, with a `height` in px and `display: block`. Then it is measured at that height and spaced as the paragraph Homebrewery wraps it in, which is how [GM Maps](<GM Maps>) gets a drawn map onto a page without overflowing it.

**A drawing wider than a column** gets a page to itself: a page break before it, unless it already starts one, and a page break after it. That is a drawing that also says how wide it is, with a `width` in px wider than a column, set in a block that spans both columns, the way [GM Sheets](<GM Sheets>) prints a character's sheet:

    <div style="column-span:all">
    <svg width="672" height="900" style="display:block">…</svg>
    </div>

Keep it to one block, with no blank line inside: Markdown ends an HTML block at the first blank line. A heading just above such a drawing stays on the page before it, so put the drawing after the text that belongs above it.

It is an estimate, so each page keeps `gmbook.layout.slack` (one line) free at the foot. If a page still spills, raise it. The measurements only hold for 5ePHB on Letter. Set `paginate = false` in the config for chapter breaks only.

**What the page breaks can't allow for is named** in the notification after a build, with the book's page it is on and the Homebrewery page it lands on in each edition, and the book is written all the same:

- A block taller than a column, such as a long table, a long code block or a long box. It can't be broken, so it spills wherever it goes: split it in the source.
- An image, `![…](…)` or `<img>`, or raw HTML, with no height the model can read. Give it a `height` in px and `display: block`, as above, or leave room for it.
- A `\page` line inside fenced code. Homebrewery splits the brew into pages before it reads any Markdown, so it breaks the page there all the same, and every page number after it is one out.

A comment, or a tag alone on its line that only opens or closes a wrapper round Markdown, takes no room and isn't named. `report.warnings` lists each for a script, along with the book_order problems under *Setting the order* and *A chapter in several pages*.

## Page numbers

Two settings print page numbers in the book. Both are off, so a book already committed doesn't change when GM Book does:

    config.set("gmBook.contents", true)
    config.set("gmBook.pageRefs", true)

**`gmBook.contents`** puts a contents page at the front of each edition: a table of its chapters, each with the page it starts on and its title a link to that page, which a PDF printed from the brew keeps. The chapters are the pages with a `book_order` that aren't sections, under their titles as that edition prints them. A long contents takes the pages it needs, a table to a column, and every number allows for them. Give it a title of your own, or words of your own for the table's headings too:

    config.set("gmBook.contents", "Table of Contents")
    config.set("gmBook.contents", { title = "Inhalt", chapter = "Kapitel", page = "Seite" })

**`gmBook.pageRefs`** gives a pointer the page it points to, *See Lantern: Rules (p. 21).*: the page the section's heading is on, or the page a whole page starts on.

The numbers are Homebrewery's own: a brew is split into pages at each `\page` line and nowhere else, and a number is the page its line lands on, the contents counted. A number can move what follows it onto the next page, so a build lays each edition out again until no number moves, and says so if they won't settle. With `paginate = false` they count the page breaks the book has of itself. A `\page` inside fenced code puts every number after it one out, which the build names (see *Page breaks*).

## Rendering it

**Homebrewery**: open a built page, press *Copy for Homebrewery*, then *Open Homebrewery* and paste into the new brew. Free, authentic PHB look, PDF export.

**A PDF beside the edition**: GM Book can't print a PDF itself, since that takes a browser's print engine, but something outside SilverBullet can print one and leave it beside the edition, `Build/Book DM.pdf` beside `Build/Book DM`. The bar then has *Open PDF*, which opens it in a tab of its own. A PDF older than its edition gets *Open PDF (older)*, so one from before the last build never passes for the current one.

The script that prints it can say what it printed in a JSON file beside it, `Build/Book DM.pdf.json`: an object with `pages`, `printed_at` (UTC, as ISO 8601 gives it), `homebrewery` (`{ "version": …, "hash": … }`), `spills`, the pages whose text ran past their foot as `[[page, text], …]`, and whatever else it keeps, such as `edition`, `chrome` and `sandbox`. The bar then says beside *Open PDF*, *83 pages · printed 22 Sep · Homebrewery 3.23.0*, and when any page spills, *⚠ 2 pages spill: p. 14, p. 31*. A field missing or of the wrong kind is left out, and a file that isn't a JSON object says nothing.

**Pandoc with a 5e LaTeX template**: for a fully local, reproducible build.

## Changes in 1.13

**The player edition keeps back what the DM keeps back, however it arrives.** Every form of DM-only text GM Kit 3.8 reads counts here too, as the table under *DM-only text* shows: a DM Only heading at any level and in any case, a callout whose type begins `dm`, a `<div class="dm">`, a stretch marker mid-line. A page whose only DM-only text sat under `## DM only` used to reach the player edition whole. And the player edition fails closed: a page that still holds a DM-only mark keeps it back, named in the notification. A section shown from another page is cut from that page as the edition prints it, so a stretch opened above it, or a `## DM Only` it sits under, keeps it out. A pointer is named by its page's title as the edition prints it, and a page whose title the players don't get, or that gives them nothing at all, gets no pointer. A page only the DM may see, a map's own page by default, is left out of the player edition along with anything shown from it: see *DM-only text*. HTML comments stay out of the player edition too.

**One build at a time.** A second build while one is running is refused, with a notification. `gmbook.printing` is put back however a build ends.

**An edition kept back says why.** The notification names each expression that printed nothing and its error, and suggests a reload only when the library the expression calls isn't loaded in the tab. A library that can't draw something in print now returns nothing, so the edition waits rather than printing its message: see *Live values*. `report.unprinted` lists them for scripts.

**Smaller things.** Pages with the same `book_order` go in the order of their names, so every Lua builds the same book. Copies of GM Book at different depths of the space are named when the book builds. *Copy for Homebrewery* says what to do if SilverBullet couldn't copy.

## Implementation

```space-lua
-- priority: 10
gmbook = gmbook or {}
-- The version this tab's Lua is, the same as this page's frontmatter: a tab
-- left open over a Library: Update runs the old one (see gmbook.stale).
gmbook.version = "1.13.0"

gmbook.config = {
  outputFolder = "Build/",
  pageBreak    = "\\page",
  dmHeading    = "DM Only",
  dmWord       = "dm",
  libraryPage  = "Library/Storie/GM Book",
  homebrewery  = "https://homebrewery.naturalcrit.com/new",
  paginate     = true,
  -- SilverBullet admonition -> Homebrewery box classes
  admonitions  = { note = "note", warning = "note,warning" },
  -- ![[Page#Section]] of a page the book prints: "see" points to it, and
  -- "inline" prints it in place. %s is the page's title and the section.
  transclusions = "see",
  see          = "*See %s.*",
  -- A build takes tens of seconds, so it drives SilverBullet's own progress
  -- ring in the top bar. The ring is shared with syncing and indexing, and
  -- takes only their two names; "sync" and "index" differ only in colour, and
  -- neither is labelled unless the space is still doing its first index. false
  -- turns the ring off.
  progress     = "sync",
  -- Page types whose page is itself the DM's: a GM Maps map page writes
  -- out every creature and trapdoor, and nothing on it is marked DM-only
  -- because all of it is. The player edition leaves such a page out, even
  -- with a book_order, and prints nothing where a page shows it. The type
  -- GM Maps is set to give its pages counts too.
  privateTypes = { "map" },
  -- The words of the contents page gmBook.contents puts at the front of
  -- each edition: its title, and its table's two headings.
  contentsWords = { title = "Contents", chapter = "Chapter", page = "Page" },
}

gmbook.editions = {
  dm     = { page = "Book DM",     label = "DM edition" },
  player = { page = "Book Player", label = "player edition" },
}

------------------------------------------------------------ DM-only text
-- GM Kit and GM Book share the code from here to "end of the shared DM-only
-- code", word for word, so the players' copies leave out exactly what the
-- player edition does.

-- A quote line's markers: how many, and what follows them. "> > text"
-- gives 2 and "text".
local function dmQuote(line)
  local depth, rest = 0, line
  while true do
    local sp, after = rest:match("^(%s*)>(.*)$")
    if not sp or (depth > 0 and #sp > 3) then return depth, rest end
    depth = depth + 1
    rest = after:sub(1, 1) == " " and after:sub(2) or after
  end
end

-- A quote line split at its d-th marker: what comes before the marker, and
-- what follows it. Nothing for a line with fewer markers.
local function dmSplit(line, d)
  local rest, before = line, ""
  for k = 1, d do
    local sp, after = rest:match("^(%s*)>(.*)$")
    if not sp or (k > 1 and #sp > 3) then return nil end
    if k == d then before = line:sub(1, #line - #rest) .. sp end
    rest = after:sub(1, 1) == " " and after:sub(2) or after
  end
  return before, rest
end

-- A callout's type and title, from what follows the quote marker on its
-- line. Read the way SilverBullet reads them: "**note** Title" or
-- "[!note] Title", the type running to whichever of ** and ] comes first.
local function dmCallout(rest)
  local body = rest:match("^ *%*%*(.*)$") or rest:match("^ *%[!(.*)$")
  if not body then return nil end
  local a = body:find("**", 1, true)
  local b = body:find("]", 1, true)
  local stop = a
  if b and (not a or b < a) then stop = b end
  if not stop then return nil end
  return body:sub(1, stop - 1):lower(), body:sub(stop + (stop == a and 2 or 1))
end

-- Whether a callout's type makes it the DM's: its first word is `word`, as
-- in **dm**, **DM only**, **DM-only note** and [!dm].
local function dmIsCallout(kind, word)
  if not kind then return false end
  kind = kind:match("^%s*(.*)$")
  return kind:sub(1, #word) == word and not kind:sub(#word + 1, #word + 1):match("%w")
end

-- A fenced code block's opening line, as its character and how many.
local function dmFence(s)
  local run = s:match("^%s*(```+)") or s:match("^%s*(~~~+)")
  if not run then return nil end
  local at = s:find(run, 1, true)
  if run:sub(1, 1) == "`" and s:find("`", at + #run, true) then return nil end
  return run:sub(1, 1), #run
end

local function dmCloses(s, ch, n)
  local run = s:match(ch == "`" and "^%s*(`+)%s*$" or "^%s*(~+)%s*$")
  return run ~= nil and #run >= n
end

-- Three or more of -, * or _, spaces between allowed: a rule across the page.
local function dmRule(s)
  local c = s:match("^%s*([-*_])")
  if not c then return false end
  local bare = (s:gsub("%s", ""))
  return #bare >= 3 and (bare:gsub("%" .. c, "")) == ""
end

-- A line that begins a block of its own, so it can't carry on a paragraph.
local function dmStarts(s)
  return s:match("^%s*#+%s") ~= nil or s:match("^%s*#+$") ~= nil
    or s:match("^%s*[-*+]%s+%S") ~= nil or s:match("^%s*1[.)]%s+%S") ~= nil
    or dmFence(s) ~= nil or s:match("^%s*<!%-%-") ~= nil or dmRule(s)
end

-- Whether a tag's class names `word`: class="dm", class='note dm', class=dm.
local function dmClass(tag, word)
  local c = "%s[cC][lL][aA][sS][sS]%s*=%s*"
  local cls = tag:match(c .. "\"([^\"]*)\"") or tag:match(c .. "'([^']*)'")
    or tag:match(c .. "([^%s>\"']+)")
  if not cls then return false end
  return (" " .. (cls:gsub("%s+", " ")):lower() .. " "):find(" " .. word .. " ", 1, true) ~= nil
end

-- A heading line's level, and its text as the DM Only test reads it: in
-- lower case, without emphasis, closing #s or the spaces round it. nil for
-- a line that is no heading. Up to three spaces can come before the #s.
local function dmHeadingOf(line)
  local sp, marks, rest = line:match("^( *)(#+)(.*)$")
  if not sp or #sp > 3 or #marks > 6 or not (rest == "" or rest:match("^%s")) then return nil end
  rest = (rest:gsub("%s+#+%s*$", ""))
  rest = (rest:gsub("[%*_]", ""))
  return #marks, (rest:match("^%s*(.-)%s*$")):lower()
end

-- The DM Only heading as a pattern for a heading's text: its words in any
-- case, joined by spaces, a hyphen or nothing. `more` lets other words
-- follow, for the detector.
local function dmHeadingWords(heading, more)
  local words = {}
  for w in heading:lower():gmatch("[^%s%-_]+") do words[#words + 1] = (w:gsub("%p", "%%%0")) end
  return "^" .. table.concat(words, "[%s%-]*") .. (more and "" or "$")
end

-- Elements that sit inside a paragraph, so one left open ends with its
-- paragraph. A DM element of any other kind left open runs on, over blank
-- lines, to its end tag or the end of the page.
local DM_INLINE = {
  a = true, abbr = true, b = true, bdi = true, bdo = true, cite = true, code = true,
  data = true, del = true, dfn = true, em = true, font = true, i = true, ins = true,
  kbd = true, label = true, mark = true, q = true, s = true, samp = true, small = true,
  span = true, strong = true, sub = true, sup = true, time = true, u = true, var = true,
}

-- Elements with no end tag: the DM's one is left out whole.
local DM_VOID = {
  area = true, base = true, br = true, col = true, embed = true, hr = true, img = true,
  input = true, link = true, meta = true, source = true, track = true, wbr = true,
}

-- An HTML comment that is a stretch marker: "open" for <!--#dm-->, "shut"
-- for <!--/dm-->, spaces and capitals allowed, or nil for any other.
local function dmMarker(comment, word)
  local sign, name = comment:match("^<!%-%-%s*([#/])%s*([%w_]*)")
  if not sign or name:lower() ~= word then return nil end
  return sign == "#" and "open" or "shut"
end

-- One line read for its DM-only text, with `st` carrying what is open from
-- the line above: st.depth stretches, and st.el a DM element, its tag and
-- how deep in it. Gives back what the players get of the line, false for
-- none of it; what the DM's edition prints, the text with only the markers
-- and the DM elements' own tags gone; whether the line held those and
-- nothing else; and whether anything was taken out. Inline code is text,
-- and so is any other HTML comment, whatever it holds. A stretch closer
-- with no stretch open stays in the players' copy, since what it closes
-- was never marked: the copy is then held back (dmMarks) rather than sent.
local function dmLine(line, st, word)
  local pub, dm = {}, {}
  local seamPub, seamDm, marks, cut = false, false, false, false
  local after, afterDm = "", ""
  local started = st.depth > 0 or st.el ~= nil
  local function dropping() return st.depth > 0 or st.el ~= nil end
  -- where something came out, the gap it leaves is one space, not two
  local function put(t, s, seam)
    if seam and s:match("^%s") then
      local last = t[#t]
      if not last or last:match("%s$") then s = (s:gsub("^%s+", "")) end
    end
    if s ~= "" then t[#t + 1] = s end
  end
  local function text(s)
    if s == "" then return end
    put(dm, s, seamDm)
    seamDm, afterDm = false, afterDm .. s
    if not dropping() then
      put(pub, s, seamPub)
      seamPub = false
      after = after .. s
    end
  end
  local function out()
    marks, cut, after, afterDm = true, true, "", ""
  end
  local from, i = 1, 1
  while true do
    local a = line:find("[`<]", i)
    if not a then break end
    if line:sub(a, a) == "`" then
      local run = line:match("^`+", a)
      local close = line:find(run, a + #run, true)
      i = close and close + #run or a + #run
    elseif line:sub(a, a + 3) == "<!--" then
      local close = line:find("-->", a + 4, true)
      local stop = close and close + 2 or #line
      local kind = dmMarker(line:sub(a, stop), word)
      if kind == "open" or (kind == "shut" and st.depth > 0) then
        text(line:sub(from, a - 1))
        out()
        st.depth = st.depth + (kind == "open" and 1 or -1)
        seamPub, seamDm, from = true, true, stop + 1
      elseif kind == "shut" then
        text(line:sub(from, a - 1))
        marks = true
        if not dropping() then
          put(pub, line:sub(a, stop), seamPub)
          seamPub = false
          after = after .. line:sub(a, stop)
        end
        seamDm, afterDm, from = true, "", stop + 1
      end
      i = stop + 1
    else
      local _, e, name = line:find("^</([%a][%w%-]*)%s*>", a)
      if e then
        name = name:lower()
        if st.el and name == st.el.tag then
          st.el.depth = st.el.depth - 1
          if st.el.depth == 0 then
            text(line:sub(from, a - 1))
            out()
            st.el = nil
            seamPub, from = true, e + 1
          end
        end
        i = e + 1
      else
        local _, f, tag = line:find("^<([%a][%w%-]*)[^>]*>", a)
        if f then
          tag = tag:lower()
          local whole = line:sub(a, f)
          local empty = DM_VOID[tag] or whole:match("/%s*>$") ~= nil
          if st.el then
            if tag == st.el.tag and not empty then st.el.depth = st.el.depth + 1 end
          elseif dmClass(whole, word) then
            text(line:sub(from, a - 1))
            out()
            if empty then
              -- nothing inside it: the DM's edition keeps it as it is
              put(dm, whole, seamDm)
              seamDm, afterDm = false, whole
            else
              st.el = { tag = tag, depth = 1, inline = DM_INLINE[tag] == true }
            end
            seamPub, from = true, f + 1
          end
          i = f + 1
        else
          i = a + 1
        end
      end
    end
  end
  text(line:sub(from))
  local p = table.concat(pub)
  if cut and (dropping() or not after:match("%S")) then p = (p:gsub("%s+$", "")) end
  local changed = marks or started or dropping()
  if changed and not p:match("%S") then p = false end
  local d = table.concat(dm)
  if marks and not afterDm:match("%S") then d = (d:gsub("%s+$", "")) end
  return p, d, marks and not d:match("[^%s>]"), changed
end

-- A line's DM elements and markers taken out, for a caller that reads a
-- page a line at a time: with keep only their tags and markers go, and
-- without, all they hold goes too. `open` is what the line above left
-- open, 0 for nothing. Gives back the line, what is left open at its end,
-- and whether it changed.
local function dmSpans(line, word, open, keep)
  local st = type(open) == "table" and open or { depth = 0 }
  local p, d, _, changed = dmLine(line, st, word)
  local still = (st.depth > 0 or st.el ~= nil) and st or 0
  if keep then return d, still, changed end
  return p or "", still, changed
end

-- Finds a page's DM-only text: a DM Only section, a DM callout (> **dm**
-- Title), a stretch between <!--#dm--> and <!--/dm-->, and an element of
-- the class dm, <span class="dm"> or <div class="dm">. None of them counts
-- in fenced code. Gives back, for each line, what the players get of it
-- (scan.public, false for none), and what the DM's edition prints
-- (scan.lines: the line with the markers and the DM elements' tags gone),
-- with scan.raw the lines as written, and for each line what it is:
-- code, callout, section, stretch, and marker for a line of markers or tags
-- and nothing else.
local function dmScan(text, heading, word)
  local lines = {}
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do lines[#lines + 1] = line end
  local n = #lines
  local scan = { raw = lines, lines = {}, public = {}, code = {}, callout = {}, section = {},
                 stretch = {}, marker = {}, word = word:lower() }
  local code = scan.code

  -- Fenced code, and the quote depth its fence opened at: a quote that ends
  -- takes its fence with it.
  local fence
  for i = 1, n do
    if fence then
      local _, rest = dmSplit(lines[i], fence.depth)
      if rest then
        code[i] = fence.depth
        if dmCloses(rest, fence.ch, fence.n) then fence = nil end
      else
        fence = nil
      end
    end
    if not fence and not code[i] then
      local depth, rest = dmQuote(lines[i])
      local ch, len = dmFence(rest)
      if ch then
        fence = { ch = ch, n = len, depth = depth }
        code[i] = depth
      end
    end
  end

  -- DM callouts. A quote is one when the first of its lines to name a
  -- callout type names `word` first, and a quote that isn't is searched for
  -- one inside it. A quote runs over the lines that carry its marker, and
  -- over a line without one that carries on the paragraph above.
  local function quotes(view, at, level)
    local j, count = 1, #view
    while j <= count do
      local depth, inner = dmQuote(view[j])
      local c = code[at[j]]
      if depth == 0 or (c and c <= level) then
        j = j + 1
      else
        local last, open = j, inner:match("%S") ~= nil and not dmStarts(inner)
        for k = j + 1, count do
          local d, rest = dmQuote(view[k])
          if d > 0 then
            last, open = k, rest:match("%S") ~= nil and not dmStarts(rest)
          elseif open and view[k]:match("%S") and not dmStarts(view[k]) then
            last = k
          else
            break
          end
        end
        local kind, title, typeAt
        for k = j, last do
          local _, rest = dmSplit(view[k], 1)
          if rest then
            kind, title = dmCallout(rest)
            if kind then
              typeAt = k
              break
            end
          end
        end
        if dmIsCallout(kind, scan.word) then
          local callout = {
            first = at[j], last = at[last], depth = level + 1, typeAt = at[typeAt],
            title = title:match("^%s*(.-)%s*$"),
            gap = (dmSplit(lines[at[j]], level + 1) or ""):match("^(.-)%s*$"),
          }
          for k = j, last do scan.callout[at[k]] = callout end
        else
          local sub, subAt = {}, {}
          for k = j, last do
            local _, rest = dmSplit(view[k], 1)
            sub[#sub + 1] = rest or view[k]
            subAt[#subAt + 1] = at[k]
          end
          quotes(sub, subAt, level + 1)
        end
        j = last + 1
      end
    end
  end
  local all = {}
  for i = 1, n do all[i] = i end
  quotes(lines, all, 0)

  -- Stretches, DM elements and DM Only sections, line by line. Markers and
  -- tags count anywhere outside code, callouts included, and stretches nest,
  -- so an inner end can't close an outer stretch; one with no end runs to
  -- the end of the page. A DM Only heading, at any level, runs to the next
  -- heading of its level or above, where that heading is text of its own:
  -- not code, a callout, or inside a stretch or a DM element.
  local head = dmHeadingWords(heading)
  local st, section = { depth = 0 }, nil
  for i = 1, n do
    local line = lines[i]
    if (code[i] or not line:match("%S")) and st.el and st.el.inline then st.el = nil end
    local inside = st.depth > 0 or st.el ~= nil
    if not code[i] and not scan.callout[i] then
      local level, words = dmHeadingOf(line)
      if level then
        if section and not inside and level <= section then section = nil end
        if not section and words:match(head) then section = level end
      end
    end
    local pub
    if code[i] then
      scan.lines[i] = line
      pub = not inside and line
    else
      local p, d, only, changed = dmLine(line, st, scan.word)
      scan.lines[i], scan.marker[i] = d, only or nil
      pub = p
      if changed then scan.stretch[i] = true end
    end
    if section then scan.section[i] = true end
    if section or scan.callout[i] then pub = false end
    scan.public[i] = pub
  end
  return scan
end

-- The page without its DM-only text. Where a block goes from between two
-- blank lines, one of them goes with it.
local function dmStrip(scan)
  local out, cut = {}, false
  for i = 1, #scan.raw do
    local line = scan.public[i]
    if line == false then
      cut = true
    elseif cut and not line:match("%S") and (#out == 0 or not out[#out]:match("%S")) then
      cut = false
    else
      out[#out + 1] = line
      cut = false
    end
  end
  return table.concat(out, "\n")
end

-- Whether a page can hold DM-only text at all: a marker, a tag or a
-- callout needs a < or a >, and a DM Only heading its first word. A page
-- with none of them needn't be read.
local function dmMaybe(text, heading)
  if text:find("[<>]") then return true end
  local first = heading:lower():match("[^%s%-_]+")
  return first ~= nil and text:lower():find(first, 1, true) ~= nil
end

-- A line with its inline code taken out.
local function dmNoCode(line)
  local out, i = {}, 1
  while true do
    local a = line:find("`", i, true)
    if not a then break end
    local run = line:match("^`+", a)
    local close = line:find(run, a + #run, true)
    if not close then break end
    out[#out + 1] = line:sub(i, a - 1)
    i = close + #run
  end
  out[#out + 1] = line:sub(i)
  return table.concat(out)
end

-- A line with the quote and list markers in front of it taken off, and
-- whether any of them was a quote's.
local function dmBare(line)
  local rest, quoted = line, false
  while true do
    local r = rest:match("^%s*>%s?(.*)$")
    if r then
      rest, quoted = r, true
    else
      r = rest:match("^%s*[%-%*%+]%s+(.*)$") or rest:match("^%s*%d+[%.%)]%s+(.*)$")
      if not r then return rest, quoted end
      rest = r
    end
  end
end

-- Whether a class="..." anywhere in a line names `word`, in a tag or not:
-- a tag written over two lines still has its class on one of them.
local function dmAnyClass(line, word)
  local low, i = line:lower(), 1
  while true do
    local _, b = low:find("class%s*=%s*", i)
    if not b then return false end
    local q, v = low:sub(b + 1, b + 1), nil
    if q == "\"" or q == "'" then
      local c = low:find(q, b + 2, true)
      v = low:sub(b + 2, (c or #low + 1) - 1)
    else
      v = low:match("^[^%s>\"']*", b + 1)
    end
    if (" " .. (v:gsub("%s+", " ")) .. " "):find(" " .. word .. " ", 1, true) then return true end
    i = b + 1
  end
end

-- The DM-only marks a text still holds outside code, each kind once: a
-- stretch marker, an element of the class, a DM callout or a DM Only
-- heading, in any form these find and more: a heading that only starts
-- with the words, one underlined, a callout in a list, a tag over two
-- lines. Run on a players' copy, anything it finds means the copy isn't
-- to be sent, since whatever is marked may not have been left out.
local function dmMarks(text, heading, word)
  word = word:lower()
  local found, seen = {}, {}
  local function add(what)
    if not seen[what] then
      seen[what] = true
      found[#found + 1] = what
    end
  end
  local lines = {}
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do lines[#lines + 1] = line end
  local head = dmHeadingWords(heading, true)
  local w = (word:gsub("%p", "%%%0"))
  local fence
  for i, line in ipairs(lines) do
    local _, rest = dmQuote(line)
    if fence then
      if dmCloses(rest, fence.ch, fence.n) then fence = nil end
    elseif dmFence(rest) then
      local ch, len = dmFence(rest)
      fence = { ch = ch, n = len }
    else
      local plain = dmNoCode(line)
      if plain:lower():find("<!%-%-%s*[#/]%s*" .. w) then add("a stretch marker") end
      if dmAnyClass(plain, word) then add("an element of class " .. word) end
      local bare, quoted = dmBare(plain)
      if quoted and dmIsCallout((dmCallout(bare)), word) then add("a " .. word .. " callout") end
      local level, words = dmHeadingOf(bare)
      if not level then
        -- a line underlined with = or - is a heading too
        local nxt = lines[i + 1] and (dmBare(lines[i + 1]))
        if nxt and (nxt:match("^%s*=+%s*$") or nxt:match("^%s*%-+%s*$")) then
          level, words = dmHeadingOf("# " .. bare)
        end
      end
      if level and words:match(head) then add("a " .. heading .. " heading") end
    end
  end
  return found
end

-- end of the shared DM-only code

-- Whether a line is prose, so a bold lead can open it.
local function dmProse(s)
  return s:match("^%s*[^%s|>!<{\\$]") ~= nil and not dmStarts(s)
    and not s:match("^%s*%d+[.)]%s")
end

-- A DM callout as ordinary text, for the DM's edition: its markers off, and
-- its title the bold lead of the paragraph under it.
local function dmUnwrap(scan, c)
  local items, out, span = {}, {}, 0
  for k = c.first, c.last do
    local before, rest = dmSplit(scan.lines[k], c.depth)
    local item = { pre = before or "", text = rest or scan.lines[k], lead = k == c.typeAt }
    if item.lead or scan.code[k] or not item.text:match("%S") then
      span = 0
    else
      item.text, span = dmSpans(item.text, scan.word, span, true)
    end
    items[#items + 1] = item
  end
  local t = c.title
  local lead = t ~= "" and ("**" .. t .. (t:match("[%.!%?:;]$") and "" or ".") .. "**") or nil
  local waiting
  for _, item in ipairs(items) do
    local blank = not item.text:match("%S")
    if item.lead then
      waiting = lead and item or nil
    elseif waiting and blank then
      -- the blank lines between a title and its text go
    elseif waiting then
      if dmProse(item.text) then
        out[#out + 1] = item.pre .. lead .. " " .. (item.text:gsub("^%s+", ""))
      else
        out[#out + 1] = waiting.pre .. lead
        out[#out + 1] = c.gap
        out[#out + 1] = item.pre .. item.text
      end
      waiting = nil
    elseif not (blank and #out == 0) then
      out[#out + 1] = item.pre .. item.text
    end
  end
  if waiting then out[#out + 1] = waiting.pre .. lead end
  while #out > 0 and not out[#out]:match("%S") do out[#out] = nil end
  return out
end

-- The page with its DM-only text shown as ordinary text, for the DM's
-- edition: a callout unwrapped, a stretch's markers gone, a span's tags gone.
-- A `## DM Only` section stays as it is.
local function dmShow(scan)
  local lines, out, cut, span = scan.lines, {}, false, 0
  local i, n = 1, #lines
  while i <= n do
    local c = scan.callout[i]
    if c and i == c.first then
      local body = dmUnwrap(scan, c)
      if #body > 0 then
        if #out > 0 and out[#out]:match("[^%s>]") then out[#out + 1] = c.gap end
        for _, line in ipairs(body) do out[#out + 1] = line end
        local after = lines[c.last + 1]
        if after and after:match("[^%s>]") and not scan.marker[c.last + 1] then
          out[#out + 1] = c.gap
        end
        cut = false
      else
        cut = true
      end
      span, i = 0, c.last + 1
    elseif scan.marker[i] then
      cut, span, i = true, 0, i + 1
    else
      local line = lines[i]
      if scan.code[i] or not line:match("%S") then
        span = 0
      else
        line, span = dmSpans(line, scan.word, span, true)
      end
      if not (cut and not line:match("%S") and (#out == 0 or not out[#out]:match("%S"))) then
        out[#out + 1] = line
      end
      cut, i = false, i + 1
    end
  end
  return table.concat(out, "\n")
end

-- The page without its DM-only text, for the player edition.
function gmbook.stripSecrets(text)
  local c = gmbook.config
  if not dmMaybe(text, c.dmHeading) then return text end
  return dmStrip(dmScan(text, c.dmHeading, c.dmWord))
end

-- The page with its DM-only text shown as ordinary text, for the DM's.
function gmbook.showSecrets(text)
  local c = gmbook.config
  if not text:find("[<>]") then return text end
  return dmShow(dmScan(text, c.dmHeading, c.dmWord))
end

-- A page as an edition prints it.
function gmbook.forEdition(text, playerEdition)
  if playerEdition then return gmbook.stripSecrets(text) end
  return gmbook.showSecrets(text)
end

-- The page types only the DM may see, as a set: gmBook.privateTypes, and
-- the type GM Maps gives its pages when it is loaded, since a space may have
-- told it another.
function gmbook.privateTypes()
  local set = {}
  local list = config.get("gmBook.privateTypes", gmbook.config.privateTypes)
  if type(list) == "string" then list = { list } end
  if type(list) == "table" then
    for _, t in ipairs(list) do set[t] = true end
  end
  if maps and maps.setting then
    local ok, t = pcall(maps.setting, "type")
    if ok and type(t) == "string" then set[t] = true end
  end
  return set
end

-- A page's type from its own frontmatter, read the way the index reads it:
-- "quoted" or 'quoted' without its quotes, and a # comment after it gone.
local function typeOf(text)
  local head = text:match("^%-%-%-\n(.-\n)%-%-%-")
  local v = head and ("\n" .. head):match("\ntype:[ \t]*([^\n]*)")
  if not v then return nil end
  v = (v:gsub("[ \t]+#.*$", ""))
  v = (v:gsub("[ \t]+$", ""))
  return v:match('^"(.*)"$') or v:match("^'(.*)'$") or v
end

-- Whether a page is of a private type, by the index or by its own
-- frontmatter: either one saying so is enough. Gives back the test, for
-- the pages of one build.
local function privateTest()
  local set, indexed = gmbook.privateTypes(), {}
  local typed = query[[
    from p = index.pages()
    where p.type ~= nil
    select { name = p.name, kind = p.type }
  ]]
  for _, p in ipairs(typed) do
    if type(p.kind) == "string" and set[p.kind] then indexed[p.name] = true end
  end
  return function(name, text)
    if indexed[name] then return true end
    local t = text and typeOf(text)
    return t ~= nil and set[t] == true
  end
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

-- The page a Markdown link on page `base` names, as SilverBullet resolves
-- one: its <...> off, a leading / from the top of the space, anything else
-- from base's folder, each leading .. a folder up, and a #section or @place
-- after it no part of the name. Nil for a link to this same page, or to a
-- file that isn't a page, such as a PDF.
local function linkedPage(base, url)
  url = url:match("^<(.*)>$") or url
  -- %20 and the like, as decodeURI decodes them
  url = (url:gsub("%%(%x%x)", function(h)
    local n = tonumber(h, 16)
    local ch = n < 128 and string.char(n) or nil
    if ch and not (";/?:@&=+$,#"):find(ch, 1, true) then return ch end
    return nil
  end))
  local path = url:match("^([^#@%$|]*)")
  if path == "" then return nil end
  local name
  if path:sub(1, 1) == "/" then
    name = path:sub(2)
  else
    local parts = {}
    for part in base:gmatch("[^/]+") do parts[#parts + 1] = part end
    parts[#parts] = nil
    local rel = {}
    for part in (path .. "/"):gmatch("([^/]*)/") do rel[#rel + 1] = part end
    local k = 1
    while rel[k] == ".." do
      parts[#parts] = nil
      k = k + 1
    end
    for j = k, #rel do parts[#parts + 1] = rel[j] end
    name = table.concat(parts, "/")
  end
  -- a name that ends in an extension is a file; .md is a page's
  local ext = name:match("%.(%w+)$")
  if ext then
    if ext ~= "md" then return nil end
    name = name:sub(1, -4)
  end
  return name
end

-- A link on its way to the book: Markdown links to pages with their pages
-- named from the top of the space, so text shown in another page still
-- names the pages it did where it was written. The book prints a link as
-- its label either way.
local function linksFromTop(text, page)
  return (text:gsub("(!?)%[([^%]]*)%](%b())", function(bang, label, target)
    if bang ~= "" then return nil end
    local url = target:sub(2, -2)
    url = url:match("^<(.*)>$") or url
    if url:find("://", 1, true) or url:match("^mailto:") or url:match("^tel:") or url:match("^[/#]") then
      return nil
    end
    local name = linkedPage(page, url)
    if not name then return nil end
    return "[" .. label .. "](</" .. name .. ">)"
  end))
end

-- A line without its inline code, `...` or ``...``.
local function withoutCode(line)
  local out, i = {}, 1
  while true do
    local a = line:find("`", i, true)
    if not a then break end
    local run = line:match("^`+", a)
    local close = line:find(run, a + #run, true)
    if not close then break end
    out[#out + 1] = line:sub(i, a - 1)
    i = close + #run
  end
  out[#out + 1] = line:sub(i)
  return table.concat(out)
end

-- The links a text prints as their labels, outside code: [[Page]],
-- [[Page#Section]] and [[Page|Label]] as `wiki` with the name written, and
-- [Label](<page>) with the name it resolves to from page `base`. Each with
-- the label the book prints. Images, media and links to websites are left
-- out, and so is a link to the page it is on.
local function linksIn(text, base)
  local found, fence = {}, nil
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    local mark = line:sub(1, 3)
    if fence then
      if mark == fence then fence = nil end
    elseif mark == "```" or mark == "~~~" then
      fence = mark
    else
      local plain = withoutCode(line)
      for bang, inner in plain:gmatch("(!?)%[%[([^%]]*)%]%]") do
        local page, label = inner:match("^([^|]*)|(.*)$")
        page = (page or inner):match("^([^#]*)")
        if bang == "" and page ~= "" then
          found[#found + 1] = { wiki = true, target = page, label = label or page:match("([^/]+)$") or page }
        end
      end
      for bang, label, target in plain:gmatch("(!?)%[([^%]]*)%](%b())") do
        local url = target:sub(2, -2)
        url = url:match("^<(.*)>$") or url
        if bang == "" and not url:find("://", 1, true) and not url:match("^mailto:")
            and not url:match("^tel:") then
          local name = linkedPage(base, url)
          if name then found[#found + 1] = { target = name, label = label } end
        end
      end
    end
  end
  return found
end

function gmbook.unbake(text)
  text = text:gsub("<!%-%-#lua.-%-%->\n?", "")
  text = text:gsub("<!%-%-/lua%-%->\n?", "")
  return text
end

-- A line without its HTML comments. open says whether a comment is still
-- open from the lines above. Inline code keeps its own. Gives back the
-- line, whether a comment is open at its end, and whether it changed.
local function uncomment(line, open)
  local out, i, n, changed = {}, 1, #line, open
  local keep = not open and 1 or nil
  local function put(s)
    -- the space either side of a comment stands once
    local last = out[#out]
    if last and last:match("%s$") and s:match("^%s") then s = (s:gsub("^%s+", "")) end
    if s ~= "" then out[#out + 1] = s end
  end
  while i <= n do
    if open then
      local e = line:find("-->", i, true)
      if not e then break end
      open, i, keep = false, e + 3, e + 3
    else
      local a = line:find("[`<]", i)
      if not a then break end
      if line:sub(a, a) == "`" then
        local run = line:match("^`+", a)
        local close = line:find(run, a + #run, true)
        i = close and close + #run or a + #run
      elseif line:sub(a, a + 3) == "<!--" then
        -- a DM stretch marker is no comment to drop: the scan has taken out
        -- every stretch it could, so one still here is a stretch it couldn't,
        -- which the edition's fail-closed check must see and keep back
        local marker = line:match("^<!%-%-%s*[#/]%s*%a+%s*%-%->", a)
        local word = marker and marker:match("^<!%-%-%s*[#/]%s*(%a+)")
        if word and word:lower() == tostring(gmbook.config.dmWord or "dm"):lower() then
          i = a + #marker
        else
          put(line:sub(keep, a - 1))
          open, changed, i, keep = true, true, a + 4, nil
        end
      else
        i = a + 1
      end
    end
  end
  if keep then put(line:sub(keep)) end
  local text = table.concat(out)
  if changed then text = (text:gsub("%s+$", "")) end
  return text, open, changed
end

-- The player edition without HTML comments: one doesn't show when the brew
-- renders, but anyone who opens the brew reads it. Code, fenced or inline,
-- keeps its own. A comment never closed runs to the end, as it does on the
-- page. A line left with nothing on it goes, and one of the blank lines
-- around it with it.
function gmbook.stripComments(text)
  if not text:find("<!--", 1, true) then return text end
  local out, fence, open, cut = {}, nil, false, false
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    local drop = false
    if fence then
      local run = line:match("^%s*(" .. fence.ch .. "+)%s*$")
      if run and #run >= fence.n then fence = nil end
    else
      local run = not open and (line:match("^%s*(```+)") or line:match("^%s*(~~~+)"))
      if run then
        fence = { ch = run:sub(1, 1), n = #run }
      else
        local kept, still, changed = uncomment(line, open)
        open = still
        if changed then
          if kept:match("%S") then line = kept else drop = true end
        end
      end
    end
    if drop then
      cut = true
    elseif cut and not line:match("%S") and (#out == 0 or not out[#out]:match("%S")) then
      cut = false
    else
      out[#out + 1] = line
      cut = false
    end
  end
  return table.concat(out, "\n")
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

-- Every copy of this library in the space: its page, and the folder it is
-- installed under.
local function installs()
  local lib = gmbook.config.libraryPage
  local names = query[[
    from p = index.pages()
    where p.name:endsWith(lib)
    select p.name
  ]]
  local out = {}
  for _, name in ipairs(names) do
    local candidate = name:sub(1, #name - #lib)
    if candidate == "" or candidate:endsWith("/") then
      out[#out + 1] = { page = name, root = candidate }
    end
  end
  return out
end

-- The folder a build reads from and writes to: "" for the whole space, or
-- the folder this page is installed under. See "Building from a larger space".
function gmbook.root()
  local configured = config.get("gmBook.root", nil)
  if configured then return configured end
  local root
  for _, c in ipairs(installs()) do
    if not root or #c.root < #root then root = c.root end
  end
  return root or ""
end

-- The copies of this library, shallowest first, when they sit at different
-- depths, as a Library: Update All run in a space that holds others can
-- leave them: a copy at the top silently moves the build to the whole
-- space. Empty when there is one, or they share a depth, or the config
-- chooses the root.
function gmbook.copies()
  if config.get("gmBook.root", nil) then return {} end
  local all, depths, seen = installs(), 0, {}
  for _, c in ipairs(all) do
    local _, d = c.root:gsub("/", "")
    c.depth = d
    if not seen[d] then
      seen[d] = true
      depths = depths + 1
    end
  end
  if depths < 2 then return {} end
  table.sort(all, function(a, b)
    if a.depth ~= b.depth then return a.depth < b.depth end
    return a.page < b.page
  end)
  local names = {}
  for _, c in ipairs(all) do names[#names + 1] = c.page end
  return names
end

-- Whether this tab runs the library the space holds. Space Lua is read when
-- a client boots and not again, so a tab left open over a Library: Update
-- runs the old code over the new pages until it reloads. Every copy of the
-- library's page at any depth is read from the index, and a message names
-- the first whose version differs from the one this tab runs; nil when none
-- does, or when a copy gives no version as text.
local function staleText(name, running, lib)
  local pages = query[[
    from p = index.pages()
    where p.name:endsWith(lib)
  ]]
  local copies, other = 0, nil
  for _, p in ipairs(pages) do
    local at = p.name:sub(1, #p.name - #lib)
    if at == "" or at:endsWith("/") then
      copies = copies + 1
      if not other and type(p.version) == "string" and p.version ~= running then other = p end
    end
  end
  if not other or type(running) ~= "string" then return nil end
  if copies > 1 then
    return "This tab runs " .. name .. " " .. running .. ", but " .. other.name .. " has " ..
      other.version .. ": reload it (System: Reload, Ctrl-Alt-R) before building, or remove " ..
      "the copy you don't use."
  end
  return "This tab runs " .. name .. " " .. running .. ", but the space has " .. other.version ..
    ": reload it (System: Reload, Ctrl-Alt-R) before building."
end

-- Nil when this tab runs the GM Book the space holds, else a message saying
-- which version each has and to reload. Never raises: a check that fails
-- says nothing.
function gmbook.stale()
  local ok, message = pcall(staleText, "GM Book", gmbook.version, gmbook.config.libraryPage)
  if ok then return message end
  return nil
end

-- Reads this tab's Space Lua afresh, as System: Reload does: the cure for a
-- stale tab, a tap away on a phone, which has no Ctrl-Alt-R.
function gmbook.reload()
  editor.invokeCommand("System: Reload")
end

-- What is stale of GM Book and of each library it prints with: a message
-- for each, GM Book's first, then each table in gmbook.printers that has a
-- stale function (GM Party, GM Sheets, GM Maps, GM Bestiary), by its name.
function gmbook.staleLibraries()
  local out, seen = {}, {}
  local function add(message)
    if type(message) == "string" and message ~= "" and not seen[message] then
      seen[message] = true
      out[#out + 1] = message
    end
  end
  add(gmbook.stale())
  local names = {}
  for name in pairs(gmbook.printers or {}) do
    if type(name) == "string" then names[#names + 1] = name end
  end
  table.sort(names)
  for _, name in ipairs(names) do
    local printer = gmbook.printers[name]
    local ok, message = pcall(function()
      if type(printer) == "table" and type(printer.stale) == "function" then return printer.stale() end
    end)
    if ok then add(message) end
  end
  return out
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

-- A page's book_order as the number the book orders it by: a number, or
-- text that reads as one. Nil for anything else, such as `soon`.
local function orderOf(p)
  local v = p.book_order
  if type(v) == "string" then v = tonumber(v) end
  if type(v) ~= "number" or v ~= v then return nil end
  return v
end

function gmbook.pages(root)
  -- `~= nil`, not the field alone: a query's where reads 0 as false, so a
  -- page at book_order 0 would drop out of the book.
  local pages = query[[
    from p = index.pages()
    where p.book_order ~= nil
  ]]
  local out = {}
  for _, p in ipairs(pages) do
    if p.name:startsWith(root) then out[#out + 1] = p end
  end
  -- By book_order, and pages that share one by name: the index promises no
  -- order of its own, so without one the harness and SilverBullet built
  -- different books. A book_order that isn't a number goes at the end, by
  -- name, the same in every Lua: a query's order by compared it with the
  -- numbers as JavaScript does, which is no order at all, and plain Lua
  -- can't compare them.
  table.sort(out, function(a, b)
    local x, y = orderOf(a), orderOf(b)
    if x ~= y then
      if x == nil then return false end
      if y == nil then return true end
      return x < y
    end
    return a.name < b.name
  end)
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

-- The page being printed, for an expression that reads the one it sits on.
-- Nil outside a build.
gmbook.printing = nil

-- A number as the book prints it, the same in SilverBullet's Lua, whose
-- numbers are JavaScript's, and in stock Lua, which prints 10/4*4 as 10.0:
-- a whole number without a point, anything else to 14 figures, as stock
-- Lua's own tostring gives a fraction. Nil for what isn't a number at all,
-- such as 0/0, which neither Lua spells the same.
local function numeral(n)
  if n ~= n or n == math.huge or n == -math.huge then return nil end
  if n == math.floor(n) and math.abs(n) <= 2 ^ 53 then return string.format("%d", n) end
  return string.format("%.14g", n)
end

-- Lua's own words, which no library is named.
local RESERVED = {}
for word in ("and break do else elseif end false for function goto if in local nil not or " ..
    "repeat return then true until while query using"):gmatch("%a+") do
  RESERVED[word] = true
end

-- Whether the name an expression starts from means nothing in this client,
-- as a library's doesn't when the client loaded before it was installed:
-- every expression that calls it fails, and System: Reload is the cure.
local function unloaded(source)
  local name = source:match("^%s*([%a_][%w_]*)")
  if not name or RESERVED[name] then return false end
  local ok, value = pcall(function()
    return spacelua.evalExpression(spacelua.parseExpression(name), gmbook.printers)
  end)
  return ok and value == nil
end

-- Each ${...} put in as what it prints: text and numbers as they are, a
-- widget as its Markdown face. Found with SilverBullet's own parser, so it
-- sees exactly what the page renders. Returns the text, the expressions
-- left in because they give nothing to print, and for each of those why:
-- the error it raised, if it did, and whether the name it starts from is
-- missing from this client.
function gmbook.print(text, page)
  if not text:find("${", 1, true) then return text, {}, {} end
  local found = {}
  local function walk(node)
    if node.type == "LuaDirective" then
      found[#found + 1] = node
    elseif node.children then
      for _, child in ipairs(node.children) do walk(child) end
    end
  end
  walk(markdown.parseMarkdown(text))
  -- The page being printed, put back however this ends: an error, or a
  -- stop from the user, which pcall passes on rather than catching. Left
  -- set, every map or reference that reads the page it is on would read
  -- this one until the client reloads.
  local was = gmbook.printing
  gmbook.printing = page
  local restore <close> = setmetatable({}, { __close = function() gmbook.printing = was end })
  local left, why = {}, {}
  for i = #found, 1, -1 do
    local node = found[i]
    local source = text:sub(node.from + 3, node.to - 1)
    local out
    -- what it gives is looked at inside the pcall too: a value that errors
    -- when read is as unprintable as an expression that errors
    local fine, err = pcall(function()
      local value = spacelua.evalExpression(spacelua.parseExpression(source), gmbook.printers)
      if type(value) == "string" then
        out = value
      elseif type(value) == "number" then
        out = numeral(value)
      elseif type(value) == "table" and value._isWidget and type(value.markdown) == "string" then
        out = value.markdown
      end
    end)
    local head, tail = text:sub(1, node.from), text:sub(node.to + 1)
    if not out then
      table.insert(left, 1, source)
      table.insert(why, 1, { error = (not fine) and tostring(err) or nil, unloaded = unloaded(source) })
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
  return text, left, why
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

-- Whether there is a page of exactly this name. space.pageExists answers the
-- way a link resolves, so a name that only ends a page's path counts, and
-- space.readPage, which wants the exact name, then fails. A path with a `.`
-- or `..` in it names no page. Any other failure is raised rather than taken
-- for a missing page.
function gmbook.exists(name)
  if name:find("^%.") or name:find("/%.%.?/") or name:find("/%.%.?$") then return false end
  local ok, err = pcall(space.getPageMeta, name)
  if ok then return true end
  local why = tostring(err)
  if why:find("Not found", 1, true) or why:find("isn't readable", 1, true) then return false end
  error(err, 0)
end

-- The page a link in the book names: relative to the book's folder, as its
-- pages write links, or a whole path, or the one page whose path ends so.
function gmbook.resolve(ref, root)
  for _, name in ipairs({ root .. ref, ref }) do
    if gmbook.exists(name) then return name end
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

-- A page's first # heading, or nil.
local function headingOf(text)
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
end

-- A page's title: its first # heading, or the last part of its name.
local function titleOf(text, name)
  return headingOf(text) or name:match("([^/]+)$") or name
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

-- Where a pointer's page goes until the edition is laid out and the page is
-- known: text no page holds, and nothing on the way to the book changes.
local REF_MARK, REF_END, REF_PATTERN = "@@gmbook-ref-", "@@", "@@gmbook%-ref%-(%d+)@@"

-- What a transclusion prints as, as lines: a pointer, the section itself,
-- or nothing. level is the heading the transclusion sits under.
local function transcluded(ref, heading, playerEdition, ctx, level, depth)
  local page = gmbook.resolve(ref, ctx.root)
  local text = page and ctx.read(page)
  local raw = text and gmbook.stripFrontmatter(text)
  local named = ctx.from .. " (" .. ref .. (heading and ("#" .. heading) or "") .. ")"
  if not raw then
    ctx.missing[named] = true
    return {}
  end
  -- a page only the DM may see, such as a map's own page, shows nowhere in
  -- the player edition
  if playerEdition and ctx.private(page, text) then return {} end
  -- The page as this edition prints it first, and the section cut from
  -- that: a section cut first can't see a stretch opened above it, or the
  -- `## DM Only` it sits under.
  local shown = gmbook.forEdition(raw, playerEdition)
  local body = gmbook.section(shown, heading)
  if not body or not body:match("%S") then
    -- kept from this edition, which is no reason to name it; missing only
    -- when no edition has it
    if not gmbook.section(raw, heading) and not gmbook.section(gmbook.showSecrets(raw), heading) then
      ctx.missing[named] = true
    end
    return {}
  end
  if ctx.mode ~= "inline" and ctx.inBook[page] then
    -- a page whose title the player edition leaves out keeps its name back:
    -- the page's own name is that title, so no pointer may name it
    if playerEdition and headingOf(raw) and not headingOf(shown) then return {} end
    -- named as this edition prints the page: its title without what the
    -- edition leaves out, and with its expressions printed
    local title, left, why = gmbook.print(titleOf(shown, page), page)
    ctx.note(left, why, page)
    title = gmbook.forEdition(title, playerEdition)
    if not title:match("%S") then title = page:match("([^/]+)$") or page end
    local label = title .. (heading and (": " .. heading) or "")
    -- with gmBook.pageRefs, the page it is on, once the edition is laid out
    if ctx.refs then
      ctx.refs[#ctx.refs + 1] = { page = page, heading = heading }
      label = label .. REF_MARK .. #ctx.refs .. REF_END
    end
    return { (ctx.see:gsub("%%s", function() return label end)) }
  end
  if depth >= 4 then return {} end
  local left, why
  body, left, why = gmbook.print(body, page)
  ctx.note(left, why, page)
  -- what an expression printed can hold DM-only text of its own
  body = gmbook.forEdition(body, playerEdition)
  -- its links still name the pages they did on its own page
  if ctx.links then body = linksFromTop(body, page) end
  body = gmbook.transclude(body, playerEdition, ctx, depth + 1)
  body = shiftHeadings(body, math.max(level, 1) + 1)
  body = (body:gsub("^%s*\n", "")):gsub("%s+$", "")
  if body == "" then return {} end
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
  text = gmbook.forEdition(gmbook.stripFrontmatter(text), playerEdition)
  if ctx then text = gmbook.transclude(text, playerEdition, ctx) end
  if section then text = gmbook.demote(text) end
  text = gmbook.unbake(text)
  if playerEdition then text = gmbook.stripComments(text) end
  -- the links this page prints as their labels, for the build to check
  -- that the edition has the pages they name
  if ctx and ctx.links then
    for _, link in ipairs(linksIn(text, ctx.root .. ctx.from)) do
      link.from = ctx.from
      ctx.links[#ctx.links + 1] = link
    end
  end
  text = gmbook.delink(text)
  return gmbook.admonitions(text)
end

-- Items in words: "A", "A and B", "A, B and C".
local function andList(items)
  if #items <= 1 then return items[1] or "" end
  return table.concat(items, ", ", 1, #items - 1) .. " and " .. items[#items]
end

-- A frontmatter value as a sentence shows it.
local function shownValue(v)
  if type(v) == "string" then return "\"" .. v .. "\"" end
  if type(v) == "number" then return numeral(v) or "NaN" end
  if type(v) == "boolean" then return tostring(v) end
  return "a list"
end

-- The book's page a line of an edition's text comes from, by the lines
-- each page's text runs over.
local function pageOfLine(ranges, line)
  for _, r in ipairs(ranges) do
    if line >= r.first and line <= r.last then return r.name end
  end
  return nil
end

-- The links the player edition prints as their labels whose pages it has
-- nothing of: a page whose every word is the DM's, a page only the DM may
-- see, a page not in the book. Each page once for each page linking to it,
-- in the book's order, named from the book's folder where it is in it.
local function missingLinks(links, inEdition, root)
  local out, seen, resolved = {}, {}, {}
  local function short(name) return name:startsWith(root) and name:sub(#root + 1) or name end
  for _, link in ipairs(links or {}) do
    local name = link.target
    if link.wiki then
      -- a wiki link finds its page as SilverBullet does, by the end of its
      -- path; a look that fails, offline say, names the link as written
      if resolved[name] == nil then
        local ok, found = pcall(gmbook.resolve, name, root)
        resolved[name] = ok and found or false
      end
      name = resolved[name] or name
    end
    local key = link.from .. "\n" .. name
    if not inEdition[name] and not seen[key] then
      seen[key] = true
      out[#out + 1] = { label = link.label, page = short(name), from = link.from }
    end
  end
  return out
end

-- The words of the contents page gmBook.contents asks for, or nil for
-- none: true for the defaults, a title, or a table of title, chapter and
-- page, any of them.
local function contentsWords()
  local asked = config.get("gmBook.contents", false)
  if not asked then return nil end
  local words = {}
  for k, v in pairs(gmbook.config.contentsWords) do words[k] = v end
  if type(asked) == "string" then
    words.title = asked
  elseif type(asked) == "table" then
    for _, k in ipairs({ "title", "chapter", "page" }) do
      if type(asked[k]) == "string" then words[k] = asked[k] end
    end
  end
  return words
end

-- An edition laid out as Homebrewery will lay it: broken where each page
-- fills up, or with paginate off only where it says \page.
local function laidOut(text)
  if gmbook.config.paginate then return gmbook.paginate(text) end
  return gmbook.explicitPages(text)
end

-- An edition laid out with its page numbers in it: a contents page at the
-- front when `words` asks for one, and each pointer's page. A number can
-- move what follows it onto another page, and the contents can take more
-- than one page, so the edition is laid out again until no number moves.
-- The book after the contents starts a page of its own, so it lies as it
-- did alone, only later by the pages the contents takes. Returns the text,
-- its pages, the book's layout without the contents, and whether every
-- number settled.
local function numbered(book, chapters, refs, words, sep)
  local nums, k, head = {}, 0, nil
  local text, sheets, info
  for _ = 1, 6 do
    text, sheets, info = laidOut((book:gsub(REF_PATTERN, function(id)
      local n = nums[tonumber(id)]
      return n and (" (p. " .. string.format("%d", n) .. ")") or ""
    end)))
    local settled = true
    if words then
      k = math.max(k, 1)
      settled = false
      for _ = 1, 6 do
        local rows = {}
        for i, c in ipairs(chapters) do rows[i] = { title = c.title, page = gmbook.pageAt(info, c.line) + k } end
        local laid, count = laidOut(gmbook.contentsPage(words, rows))
        head = laid
        if count == k then
          settled = true
          break
        end
        k = count
      end
    end
    for id, r in ipairs(refs) do
      local p = r.line and (gmbook.pageAt(info, r.line) + k) or nil
      if p ~= nums[id] then
        nums[id] = p
        settled = false
      end
    end
    if settled then return head and (head .. sep .. text) or text, sheets + k, info, true end
  end
  return head and (head .. sep .. text) or text, sheets + k, info, false
end

-- The line of an edition's text each pointer's page and section starts on,
-- from the lines each page's text runs over: the section's heading, or
-- the page's first line.
local function refLines(book, refs, rangeOf)
  local lines = {}
  for line in (book .. "\n"):gmatch("([^\n]*)\n") do lines[#lines + 1] = line end
  for _, ref in ipairs(refs) do
    local range = rangeOf[ref.page]
    if range then
      ref.line = range.first
      if ref.heading then
        for n = range.first, math.min(range.last, #lines) do
          if lines[n]:match("^#+%s+(.-)%s*$") == ref.heading then
            ref.line = n
            break
          end
        end
      end
    end
  end
end

-- Book order problems, which a build reports and never stops for: pages
-- that share a book_order, and one that isn't a number.
local function orderProblems(pages, root, warn)
  local i = 1
  while i <= #pages do
    local o = orderOf(pages[i])
    local name = pages[i].name:sub(#root + 1)
    if o == nil then
      warn({ kind = "order", page = name, text = name .. "'s book_order, " ..
        shownValue(pages[i].book_order) .. ", isn't a number, so it goes at the end of the book" })
      i = i + 1
    else
      local j = i
      while j < #pages and orderOf(pages[j + 1]) == o do j = j + 1 end
      if j > i then
        local names = {}
        for k = i, j do names[#names + 1] = pages[k].name:sub(#root + 1) end
        warn({ kind = "order", page = names[1], pages = names, text = andList(names) ..
          " share book_order " .. (numeral(o) or tostring(o)) .. ", so they go in by name" })
      end
      i = j + 1
    end
  end
end

-- Writes each edition asked for ("dm", "player") and reports what it did.
-- `progress`, when given, is called as progress(done, total) after each page,
-- before each edition is paginated, and after each is written. Only
-- gmbook.build passes one: a build run headlessly has no editor to draw on.
-- The report says the folder it read (`root`), what it wrote (`written`),
-- which editions it kept back (`kept`), the transclusions it couldn't find
-- (`missing`), and the copies of GM Book at different depths (`copies`,
-- see gmbook.copies). `live` names the pages holding an expression that
-- gave nothing to print, and `unprinted` has each such expression: the
-- book's page it is in (`page`), the page it is written on when that is
-- another, shown in this one (`from`), its source (`expression`), the error
-- it raised if it did (`error`), and whether the name it starts from is
-- missing from this client (`unloaded`). `warnings` has what a build
-- reports and writes the book all the same, each with its `kind`, the
-- book's `page` it is about, and a sentence, `text`: "layout", a block the
-- page breaks can't allow for, with the `edition` and the Homebrewery page
-- (`sheet`) it is on; and "order", a book_order problem. `missingLinks`
-- has each link the player edition prints as its label to a page it has
-- nothing of, once written: the `label`, the `page` it names, and the page
-- it is `from`.
function gmbook.compile(editions, progress)
  local root = gmbook.root()
  local pages = gmbook.pages(root)
  local report = { pages = #pages, root = root, copies = gmbook.copies(), live = {}, unprinted = {},
                   written = {}, kept = {}, missing = {}, warnings = {}, missingLinks = {} }
  if #pages == 0 then return report end
  local warned = {}
  local function warn(w)
    local key = w.kind .. "\n" .. (w.edition or "") .. "\n" .. tostring(w.sheet) .. "\n" ..
      (w.page or "") .. "\n" .. w.text
    if w.kind == "order" then key = w.text end
    if not warned[key] then
      warned[key] = true
      report.warnings[#report.warnings + 1] = w
    end
  end
  orderProblems(pages, root, warn)
  local texts, cache = {}, {}
  local ctx = {
    root = root, inBook = {}, missing = {}, live = {},
    mode = config.get("gmBook.transclusions", gmbook.config.transclusions),
    see = config.get("gmBook.see", gmbook.config.see),
    read = function(name)
      if cache[name] == nil then cache[name] = gmbook.exists(name) and space.readPage(name) or false end
      return cache[name] or nil
    end,
    private = privateTest(),
  }
  -- The expressions left unprinted, by the book's page they are in: each
  -- one's source, the page it is written on, and why.
  ctx.note = function(left, why, source)
    if #left == 0 then return end
    local list = ctx.live[ctx.from]
    if not list then
      list = {}
      ctx.live[ctx.from] = list
    end
    for k, expression in ipairs(left) do
      local w = why and why[k] or {}
      list[#list + 1] = { expression = expression, source = source, error = w.error,
                          unloaded = w.unloaded == true }
    end
  end
  for i, p in ipairs(pages) do
    ctx.inBook[p.name] = true
    texts[i] = space.readPage(p.name)
  end
  local sep = "\n\n" .. gmbook.config.pageBreak .. "\n\n"
  local liveAll = {}
  -- each page of each edition, then paginating it, then writing it
  local step, steps = 0, #editions * (#pages + 2)
  local function tick()
    step = step + 1
    if progress then progress(step, steps) end
  end
  for _, edition in ipairs(editions) do
    -- each edition prints its own text, so what is DM-only never runs for
    -- the player edition
    local player, parts = edition == "player", {}
    local label = gmbook.editions[edition].label
    -- an expression that gives nothing is the edition's own problem: a page
    -- can print in the DM edition and not in the player's
    ctx.live = {}
    -- the lines of the edition each page's text runs over, to name the page
    -- a layout note is about and to find a page's page number
    local ranges, rangeOf, lineCount = {}, {}, 0
    -- the pointers whose page gmBook.pageRefs puts in, in this edition
    ctx.refs = config.get("gmBook.pageRefs", false) and {} or nil
    local function put(s)
      parts[#parts + 1] = s
      local _, n = s:gsub("\n", "")
      lineCount = lineCount + n
    end
    -- the chapter a section carries on, and whether this edition has it
    local chapter, chapterShown = nil, false
    -- the pages this edition prints something of, and the links the player
    -- edition prints as their labels, to check it has the pages they name
    local inEdition = {}
    ctx.links = player and {} or nil
    for i, raw in ipairs(texts) do
      local from = pages[i].name:sub(#root + 1)
      local section = pages[i].book_section == true
      local shown = false
      -- a page only the DM may see is no part of the player edition, and
      -- its expressions never run for it
      if not (player and ctx.private(pages[i].name, raw)) then
        ctx.from = from
        local text, left, why = gmbook.print(gmbook.forEdition(raw, player), pages[i].name)
        ctx.note(left, why, pages[i].name)
        local body = gmbook.render(text, player, section, ctx)

        -- Fail closed: the player edition's page is final here, with what it
        -- shows from other pages. A DM-only mark still in it is DM-only text
        -- the scan couldn't take out, so the edition is kept back and the
        -- page named, as for an expression that couldn't print.
        if player then
          local marks = dmMarks(body, gmbook.config.dmHeading, gmbook.config.dmWord)
          if #marks > 0 then
            local list = ctx.live[ctx.from] or {}
            ctx.live[ctx.from] = list
            list[#list + 1] = { expression = "", source = pages[i].name, dm = table.concat(marks, ", ") }
          end
        end

        -- a page with nothing left for this edition, such as one kept back
        -- whole for the DM, takes no room in it
        if body:match("%S") then
          if #parts > 0 then put(section and "\n\n" or sep) end
          local first = lineCount + 1
          put(body)
          ranges[#ranges + 1] = { first = first, last = lineCount + 1, name = from, section = section,
                                  title = headingOf(body) or from:match("([^/]+)$") or from }
          rangeOf[pages[i].name] = ranges[#ranges]
          shown = true
          inEdition[pages[i].name] = true
        end
      end
      -- A section carries on the chapter before it. Without that chapter in
      -- the edition it carries on whatever came before, under the wrong
      -- chapter's title: said once for each chapter.
      if not section then
        chapter, chapterShown = from, shown
      elseif shown and not chapterShown then
        warn({ kind = "order", edition = edition, page = from, text = chapter and
          (from .. " is a book_section, but its chapter, " .. chapter .. ", isn't in the " .. label) or
          (from .. " is a book_section with no chapter before it") })
        chapterShown = true
      end
      tick()
    end
    local live = {}
    for _, p in ipairs(pages) do
      local name = p.name:sub(#root + 1)
      if ctx.live[name] then
        live[#live + 1] = name
        local all = liveAll[name] or {}
        liveAll[name] = all
        for _, e in ipairs(ctx.live[name]) do all[#all + 1] = e end
      end
    end
    local out = gmbook.output(edition, root)
    if #live > 0 then
      -- What the expression should have drawn would go out of the edition
      -- with nothing in it to say so, and a wiki that commits the book would
      -- push the loss. The edition on the page is older but whole, so keep
      -- it, and name the pages to fix.
      report.kept[#report.kept + 1] = { edition = edition, page = out, pages = live }
      tick()
      tick()
    else
      local book, sheets, info = table.concat(parts), nil, nil
      tick()
      local words, refs = contentsWords(), ctx.refs or {}
      if words or #refs > 0 then
        -- page numbers: the contents' chapters, and the pointers' pages
        local chapters = {}
        for _, r in ipairs(ranges) do
          if not r.section then chapters[#chapters + 1] = { title = r.title, line = r.first } end
        end
        if #chapters == 0 then words = nil end
        if #refs > 0 then refLines(book, refs, rangeOf) end
        local settled
        book, sheets, info, settled = numbered(book, chapters, refs, words, sep)
        if not settled then
          warn({ kind = "numbers", edition = edition, text = "The " .. label .. "'s page numbers " ..
            "wouldn't settle, so its contents or a pointer's page may be a page out." })
        end
      elseif gmbook.config.paginate then
        book, sheets, info = gmbook.paginate(book)
      end
      -- what the page breaks can't allow for, named with its page: the
      -- edition is written all the same
      for _, note in ipairs(info and info.notes or {}) do
        warn({ kind = "layout", edition = edition, page = pageOfLine(ranges, note.line),
               sheet = note.page, text = note.what })
      end
      space.writePage(out, book)
      tick()
      report.written[#report.written + 1] = { edition = edition, page = out, sheets = sheets }
      if player then report.missingLinks = missingLinks(ctx.links, inEdition, root) end
    end
    ctx.links = nil
  end
  -- each expression once, though both editions left it unprinted
  local seen = {}
  for _, p in ipairs(pages) do
    local name = p.name:sub(#root + 1)
    if liveAll[name] then
      report.live[#report.live + 1] = name
      for _, e in ipairs(liveAll[name]) do
        local from = e.source:startsWith(root) and e.source:sub(#root + 1) or e.source
        local key = name .. "\n" .. from .. "\n" .. e.expression
        if not seen[key] then
          seen[key] = true
          report.unprinted[#report.unprinted + 1] = {
            page = name, from = from ~= name and from or nil, expression = e.expression,
            error = e.error, unloaded = e.unloaded, dm = e.dm,
          }
        end
      end
    end
  end
  for what in pairs(ctx.missing) do report.missing[#report.missing + 1] = what end
  table.sort(report.missing)
  return report
end

-- Stock Lua's strings are bytes, SilverBullet's UTF-16.
local BYTES = #"—" ~= 1

-- Text for a notification, on one line and at most about n characters, cut
-- at a space where there is one, so a long expression or error can't fill
-- a phone's screen.
local function brief(s, n)
  s = (tostring(s):gsub("%s+", " "))
  s = (s:gsub("^ ", ""))
  s = (s:gsub(" $", ""))
  if #s <= n then return s end
  local cut, at, from = s:sub(1, n), nil, 1
  while true do
    local space = cut:find(" ", from, true)
    if not space then break end
    at, from = space, space + 1
  end
  if at and at > n / 2 then
    cut = cut:sub(1, at - 1)
  elseif BYTES then
    -- no half of a character left behind
    while #cut > 0 and cut:byte(#cut) >= 128 and cut:byte(#cut) < 192 do cut = cut:sub(1, -2) end
    if #cut > 0 and cut:byte(#cut) >= 192 then cut = cut:sub(1, -2) end
  end
  return cut .. "…"
end

-- What the notification says of the expressions a kept-back edition would
-- lose: the first three, each with its page and why, and what to do. A
-- library missing from the tab is cured by a reload, and a query or a button
-- by baking; an error says what is wrong itself.
local function unprintedText(report)
  local items, reload, bake, marked = {}, false, false, false
  for k, u in ipairs(report.unprinted) do
    local why
    if u.dm then
      marked = true
      if k <= 3 then
        items[#items + 1] = u.page .. ": DM-only text left in the player edition (" .. u.dm .. ")"
      end
    elseif u.unloaded then
      why, reload = "its library isn't loaded in this tab", true
    elseif u.expression:match("^%s*query%s*%[") then
      why, bake = "a query never prints", true
    elseif u.error then
      why = brief(u.error, 100)
    else
      why, bake = "it gives nothing to print", true
    end
    if k <= 3 and not u.dm then
      items[#items + 1] = u.page .. (u.from and (" (from " .. u.from .. ")") or "") ..
        ", ${" .. brief(u.expression, 60) .. "}: " .. why
    end
  end
  local text = table.concat(items, "; ")
  if #report.unprinted > 3 then text = text .. "; and " .. (#report.unprinted - 3) .. " more" end
  text = text .. "."
  if reload then
    text = text .. " A library installed while this tab was open isn't in its Lua until System: Reload."
  end
  if bake then
    text = text .. " A query or a button never prints: bake it with Baked Sections: Update."
  end
  if marked then
    text = text .. " Mark the text as the docs show, under DM-only text, or close the stretch it opens."
  end
  return text .. " Then build again."
end

-- The first three of a list, and how many more.
local function firstThree(items)
  local text = table.concat(items, "; ", 1, math.min(3, #items))
  if #items > 3 then text = text .. "; and " .. (#items - 3) .. " more" end
  return text
end

-- What the notification says of what a build wrote all the same: the
-- blocks the page breaks can't allow for, each once with its page in each
-- edition, and book_order problems.
local function warningsText(report)
  local layout, byKey, order, other = {}, {}, {}, {}
  for _, w in ipairs(report.warnings or {}) do
    if w.kind ~= "layout" and w.kind ~= "order" then
      other[#other + 1] = w.text
    elseif w.kind == "layout" then
      local key = (w.page or "") .. "\n" .. w.text
      local item = byKey[key]
      if not item then
        item = { page = w.page, text = w.text, sheets = {} }
        byKey[key] = item
        layout[#layout + 1] = item
      end
      local e = w.edition or ""
      item.sheets[e] = item.sheets[e] or {}
      local list = item.sheets[e]
      local sheet = numeral(w.sheet) or "?"
      if list[#list] ~= sheet then list[#list + 1] = sheet end
    else
      order[#order + 1] = w.text
    end
  end
  local text = ""
  if #layout > 0 then
    local items = {}
    for _, item in ipairs(layout) do
      local where = {}
      for _, e in ipairs({ "dm", "player" }) do
        local list = item.sheets[e]
        if list then where[#where + 1] = gmbook.editions[e].label .. " p. " .. andList(list) end
      end
      items[#items + 1] = (item.page and (item.page .. ": ") or "") .. item.text ..
        " (" .. table.concat(where, ", ") .. ")"
    end
    text = text .. " The page breaks can't allow for " ..
      (#layout == 1 and "one block, so its page" or (#layout .. " blocks, so their pages")) ..
      " may spill: " .. firstThree(items) .. ". See Page breaks in GM Book's docs."
  end
  if #order > 0 then
    text = text .. " Book order: " .. firstThree(order) .. "."
  end
  for _, sentence in ipairs(other) do text = text .. " " .. sentence end
  return text
end

-- What the notification says of the pages the player edition names by a
-- link's label but has nothing of: each page once, with the words it is
-- named by, the first three of them. It may be meant, so it is only said.
local function missingLinksText(report)
  local names, label = {}, {}
  for _, m in ipairs(report.missingLinks or {}) do
    if not label[m.page] then
      label[m.page] = m.label
      names[#names + 1] = m.page
    end
  end
  local items = {}
  for k = 1, math.min(3, #names) do
    items[k] = names[k] .. " (“" .. brief(label[names[k]], 40) .. "”)"
  end
  if #names > 3 then items[#items + 1] = (#names - 3) .. " more" end
  return " The player edition names " .. (#names == 1 and "a page" or (#names .. " pages")) ..
    " it doesn't contain: " .. andList(items) .. ". That may be meant."
end

-- What the notification says of copies of GM Book at different depths.
local function copiesText(report)
  local names = report.copies
  local listed = #names == 1 and names[1] or
    (table.concat(names, ", ", 1, #names - 1) .. " and " .. names[#names])
  return " GM Book is installed at more than one depth, " .. listed .. ", so the build read " ..
    (report.root == "" and "the whole space" or report.root) ..
    ". Set gmBook.root to choose, or remove the copy you don't use."
end

function gmbook.build(editions)
  -- Every syscall a build makes yields to the browser, so a second click,
  -- or Build again beside the header's printer, would start a second build
  -- over the first: the two would print through the one gmbook.printing and
  -- write the same pages. One at a time.
  if gmbook.building then
    editor.flashNotification("The book is already being built. Wait for it to say it's done, " ..
      "then build again if you need to.", "warning")
    return nil
  end
  -- A tab whose Lua is older, or newer, than the libraries the space holds
  -- would print the book with code the pages weren't written for, and write
  -- it over the one on the page. Nothing is written until it reloads.
  local stale = gmbook.staleLibraries()
  if #stale > 0 then
    editor.flashNotification("The book wasn't built. " .. table.concat(stale, " "), "warning",
      { timeout = 30000, actions = {{ name = "Reload", run = gmbook.reload }} })
    return nil
  end
  gmbook.building = true
  -- The ring is the only progress SilverBullet draws, and every syscall the
  -- build makes yields to the browser, so it moves while the build runs.
  local ring = config.get("gmBook.progress", gmbook.config.progress)
  local cleared = false
  -- However the build ends, an error or a stop from the user included, the
  -- next one can start and the ring doesn't stay on the screen.
  local finish <close> = setmetatable({}, { __close = function()
    gmbook.building = false
    if ring and not cleared then pcall(editor.showProgress, ring) end
  end })
  local report = gmbook.compile(editions, ring and function(done, total)
    editor.showProgress(ring, math.floor(done / total * 100))
  end or nil)
  if ring then
    cleared = true
    editor.showProgress(ring)
  end
  if report.pages == 0 then
    editor.flashNotification("No pages have a book_order, so there is nothing to build." ..
      (#report.copies > 0 and copiesText(report) or ""), "warning")
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
  local message = #report.written > 0
    and ("Built " .. table.concat(names, " and ") .. " from " .. report.pages .. " pages.")
    or ("Built nothing from " .. report.pages .. " pages.")
  local kind = "info"
  if #report.kept > 0 then
    kind = "warning"
    local kept = {}
    for _, k in ipairs(report.kept) do kept[#kept + 1] = "the " .. gmbook.editions[k.edition].label end
    message = message .. " Kept back " .. table.concat(kept, " and ") .. ", unchanged, as writing " ..
      (#kept == 1 and "it" or "them") .. " would take out what " ..
      (#report.unprinted == 1 and "this expression draws: " or "these expressions draw: ") ..
      unprintedText(report)
  end
  if #report.missing > 0 then
    kind = "warning"
    message = message .. " " .. #report.missing .. (#report.missing == 1 and
      " transclusion names a page or section that can't be found, so it prints nothing: " or
      " transclusions name pages or sections that can't be found, so they print nothing: ") ..
      table.concat(report.missing, ", ") .. "."
  end
  if #report.copies > 0 then
    kind = "warning"
    message = message .. copiesText(report)
  end
  if #report.warnings > 0 then
    kind = "warning"
    message = message .. warningsText(report)
  end
  -- said, not warned of: a link to a page the players don't get may be meant
  if #report.missingLinks > 0 then message = message .. missingLinksText(report) end
  -- A warning names pages to go and fix, and is several lines on a phone:
  -- it needs longer on the screen than "built it, here it is".
  editor.flashNotification(message, kind,
    { timeout = kind == "warning" and 30000 or 12000, actions = actions })
  return report
end

function gmbook.openHomebrewery()
  editor.openUrl(gmbook.config.homebrewery)
end

function gmbook.copy(edition)
  local label = gmbook.editions[edition].label
  local page = gmbook.output(edition)
  if not gmbook.exists(page) then
    editor.flashNotification("There is no " .. label .. " yet. Build the book first.", "warning")
    return false
  end
  -- SilverBullet 2.11 catches a copy that fails, says so in a notification
  -- of its own and returns as if it had worked, so this can't tell the two
  -- apart: the message holds either way.
  editor.copyToClipboard(space.readPage(page))
  editor.flashNotification("Copied the " .. label .. ": paste it into a new Homebrewery brew. " ..
    "If SilverBullet said it couldn't copy, open " .. page .. " and copy it by hand.",
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

-- When a space file last changed, or nil if that can't be told.
local function modified(path)
  local ok, meta = pcall(space.getFileMeta, path)
  if not ok or not meta then return nil end
  return tonumber(meta.lastModified)
end

-- The PDF something has printed beside an edition, as Build/Book DM.pdf
-- beside Build/Book DM, and whether it is older than the edition. Nil when
-- there is none.
function gmbook.pdfOf(page)
  local path = page .. ".pdf"
  local ok, found = pcall(space.fileExists, path)
  if not (ok and found) then return nil end
  local pdf, md = modified(path), modified(page .. ".md")
  return path, (pdf ~= nil and md ~= nil and pdf < md)
end

-- The characters Markdown, and SilverBullet's own syntax, read as markup: a
-- tag, a link, an expression ${...}, a hashtag, emphasis, code, a table's
-- cell, an entity, and the backslash that escapes the rest.
local MARKUP = "[\\`*_{}%[%]<>#|$~&]"

-- Text from a page or a file, as Markdown that shows it as it is: a widget's
-- text is rendered as Markdown, where a backslash escape shows as the
-- character and an entity such as &lt; shows as written.
local function plain(s)
  return (tostring(s):gsub(MARKUP, "\\%0"))
end

local MONTHS = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }

-- A whole number, or nil for anything else.
local function whole(v)
  if type(v) == "number" and v == math.floor(v) and v >= 0 and v < 1e9 then return v end
  return nil
end

-- What the script that printed a PDF says of it, in <pdf>.json beside it:
-- its `pages`, when it was `printed` (day and month, UTC), the
-- `homebrewery` version it was printed with, and the pages it found
-- spilling (`spills`, in order, each once). A field missing or of the
-- wrong kind is left out; nil when there is no such file or it isn't a
-- JSON object. Never raises: the bar is drawn whatever the file holds.
function gmbook.provenance(pdf)
  local ok, info = pcall(function()
    local path = pdf .. ".json"
    if not space.fileExists(path) then return nil end
    -- SilverBullet reads a file that isn't a page as bytes
    local data = space.readFile(path)
    local text = type(data) == "string" and data or encoding.utf8Decode(data)
    -- JSON is YAML, as SilverBullet's own reader reads it
    return yaml.parse(text)
  end)
  if not ok or type(info) ~= "table" then return nil end
  local out = { pages = whole(info.pages), spills = {} }
  if type(info.printed_at) == "string" then
    local month, day = info.printed_at:match("^%d%d%d%d%-(%d%d)%-(%d%d)")
    day = day and tonumber(day)
    if month and MONTHS[tonumber(month)] and day >= 1 and day <= 31 then
      out.printed = string.format("%d", day) .. " " .. MONTHS[tonumber(month)]
    end
  end
  if type(info.homebrewery) == "table" and type(info.homebrewery.version) == "string" then
    out.homebrewery = info.homebrewery.version
  end
  if type(info.spills) == "table" then
    local seen = {}
    for _, spill in ipairs(info.spills) do
      local page = whole(type(spill) == "table" and spill[1] or spill)
      if page and not seen[page] then
        seen[page] = true
        out.spills[#out.spills + 1] = page
      end
    end
  end
  return out
end

-- The provenance as the bar says it: a line, "83 pages · printed 22 Sep ·
-- Homebrewery 3.23.0", and one naming the pages that spill, with a glyph
-- and words, or nil when none does.
local function provenanceText(p)
  local parts = {}
  if p.pages then parts[#parts + 1] = string.format("%d", p.pages) .. (p.pages == 1 and " page" or " pages") end
  if p.printed then parts[#parts + 1] = "printed " .. p.printed end
  if p.homebrewery then parts[#parts + 1] = "Homebrewery " .. plain(brief(p.homebrewery, 20)) end
  local spill
  if #p.spills > 0 then
    local pages = {}
    for k = 1, math.min(5, #p.spills) do pages[k] = "p. " .. string.format("%d", p.spills[k]) end
    spill = "⚠ " .. #p.spills .. (#p.spills == 1 and " page spills: " or " pages spill: ") ..
      table.concat(pages, ", ") .. (#p.spills > 5 and (", and " .. (#p.spills - 5) .. " more") or "")
  end
  return table.concat(parts, " · "), spill
end

-- A space file in a tab of its own, as SilverBullet opens a document it has
-- no editor for: the space's address, then .fs/ and the path.
function gmbook.openFile(path)
  local url = string.gsub(js.window.encodeURIComponent(path), "%%2F", "/")
  editor.openUrl(system.getBaseURI() .. ".fs/" .. url)
end

-- The bar across the top of a built edition.
function gmbook.bar(page)
  page = page or editor.getCurrentPage()
  local edition = gmbook.editionOf(page)
  if not edition then return nil end
  local label = gmbook.editions[edition].label
  local parts = { class = "gmbook-bar" }
  -- first, since a build from this tab would be refused: the glyph and the
  -- words say so, not a colour
  local stale = gmbook.staleLibraries()
  if #stale > 0 then
    parts[#parts + 1] = dom.span {
      class = "gmbook-bar-stale",
      "⟳ **Reload this tab:** " .. plain(table.concat(stale, " ")),
    }
    parts[#parts + 1] = gmbook.button("Reload", gmbook.reload, true)
  end
  parts[#parts + 1] = dom.span {
    class = "gmbook-bar-text",
    "**" .. label:sub(1, 1):upper() .. label:sub(2) .. "**, built by GM Book. " ..
    "A build replaces this page, so make changes in the pages it comes from.",
  }
  parts[#parts + 1] = gmbook.button("Build again", function() gmbook.build({ "dm", "player" }) end, true)
  local pdf, older = gmbook.pdfOf(page)
  if pdf then
    parts[#parts + 1] = gmbook.button(older and "Open PDF (older)" or "Open PDF",
      function() gmbook.openFile(pdf) end)
    -- what the script that printed it says of it, beside it
    local printed = gmbook.provenance(pdf)
    if printed then
      local line, spill = provenanceText(printed)
      if line ~= "" then parts[#parts + 1] = dom.span { class = "gmbook-bar-pdf", line } end
      if spill then parts[#parts + 1] = dom.span { class = "gmbook-bar-spill", spill } end
    end
  end
  parts[#parts + 1] = gmbook.button("Copy for Homebrewery", function() gmbook.copy(edition) end)
  parts[#parts + 1] = gmbook.button("Open Homebrewery", gmbook.openHomebrewery)
  return widget.new { display = "block", html = dom.div(parts) }
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

-- A line Homebrewery breaks the page at: \page or \pagebreak, alone or with
-- its {attributes}. The brew is split on these before any Markdown is read
-- (brewRenderer.jsx, PAGEBREAK_REGEX_V3), so one inside fenced code breaks
-- the page there all the same.
local function hbPage(l)
  local rest = l:match("^\\page(.*)$")
  if not rest then return false end
  if rest:sub(1, 5) == "break" then rest = rest:sub(6) end
  return rest == "" or rest:match("^ *{[^{}]*}$") ~= nil
end

-- Elements that take room of their own, which the model can't measure.
local MEDIA_TAGS = { img = true, picture = true, svg = true, iframe = true, video = true, audio = true,
  canvas = true, object = true, embed = true, table = true }

-- Why raw HTML the model leaves out of the count matters, or nil where it
-- takes no room: comments, and tags alone on their lines that open or
-- close a wrapper round Markdown the model measures as usual.
local function unmeasured(html)
  local text = (table.concat(html, "\n"):gsub("<!%-%-.-%-%->", ""))
  -- a comment that runs on past the block, to its end
  text = (text:gsub("<!%-%-.*$", ""))
  local image, media = false, false
  local rest = (text:gsub("</?([%a][%w%-]*)[^>]*>", function(tag)
    tag = tag:lower()
    if tag == "img" or tag == "picture" then image = true end
    if MEDIA_TAGS[tag] then media = true end
    return ""
  end))
  if image then return "an image without a declared height" end
  if media or rest:match("%S") then return "raw HTML without a declared height" end
  return nil
end

-- Whether any of lines a to b holds a Markdown image, ![alt](url), which
-- the model measures as nothing.
local function imageIn(lines, a, b)
  for k = a, b do
    if lines[k]:find("!%[[^%]]*%]%(") then return true end
  end
  return false
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
        if imageIn(lines, b.first, i - 1) then last.image = true end
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
        if hbPage(lines[i]) then b.pageInCode = true end
        i = i + 1
      end
      i = i + 1
    elseif l:match("^<") then
      b.kind = "html"
      local html = { l }
      i = i + 1
      while i <= n and not lines[i]:match("^%s*$") do
        html[#html + 1] = lines[i]
        i = i + 1
      end
      -- Raw HTML is Homebrewery's to lay out and can't be measured, except
      -- where the element declares its own height in px and is displayed as
      -- a block: an inline SVG map does both, so it can be measured exactly.
      local h, w, blocked = nil, nil, false
      for _, line in ipairs(html) do
        local lh = tonumber(line:match('^<%a+[^>]-%sheight="(%d+%.?%d*)"'))
        if lh and not h then
          h = lh
          w = tonumber(line:match('^<%a+[^>]-%swidth="(%d+%.?%d*)"'))
        end
        if line:find("display:%s*block") then blocked = true end
      end
      if h and blocked then
        -- one wider than a column spans both, and gets a page to itself
        b.kind, b.h, b.wide = "drawn", h, w ~= nil and w > W1 + 0.5
      else
        b.unmeasured = unmeasured(html)
      end
    else
      b.kind, b.text = "p", l
      i = i + 1
      while i <= n and not opensBlock(lines[i]) do
        b.text = b.text .. " " .. lines[i]
        i = i + 1
      end
    end
    if b then
      if b.kind ~= "code" and b.kind ~= "html" and b.kind ~= "drawn" and imageIn(lines, b.first, i - 1) then
        b.image = true
      end
      out[#out + 1] = b
      blank = false
    end
  end
  return out, lines
end

-- Space between two sibling blocks, from the theme's p+*, h3+*, *+h3 ...
-- rules. Boxes are inline-blocks, so a list's bottom margin adds to theirs.
local function gap(prev, kind)
  -- a drawn block is a paragraph holding one element, and spaces like one
  if kind == "drawn" then kind = "p" end
  if prev == "drawn" then prev = "p" end
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
  elseif k == "drawn" then
    return {h = b.h}
  end
  return {h = 0}
end

local function keepsWithNext(b)
  return b.kind:match("^h[2-6]$") ~= nil or (b.kind == "p" and b.text:match(":%s*$") ~= nil)
end

-- A block no page can hold, by its kind, as a build names it: it spills
-- wherever it goes, so it wants splitting in the source.
local TALL = {
  p = "a paragraph longer than a page", li = "a list item taller than a column",
  quote = "a quote taller than a column", note = "a box taller than a column",
  descriptive = "a box taller than a column", box = "a box taller than a column",
  table = "a table taller than a column", code = "a code block taller than a column",
  drawn = "a drawing taller than a column", block = "a block taller than a column",
}

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
    if k == "drawn" and b.wide then
      -- a page to itself: whatever is already here stays on this page, and
      -- whatever comes after it starts the next
      if #placed > 0 then return i, false end
      if b.h > H + 0.01 then b.spills = "a drawing taller than a page" end
      if trace then
        trace[#trace + 1] = {line = b.first, kind = k, page = pageNo, col = 1, y = 0, h = b.h}
      end
      if bs[i + 1] and bs[i + 1].kind == "page" then return i + 2, true end
      return i + 1, false
    end
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
          if y > H - L.slack + 0.01 then
            if #placed > content then return breakAt(i) end
            b.spills = TALL[k] or TALL.block  -- longer than both columns: it spills
          end
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
        b.spills = TALL[k] or TALL.block
      end
      if trace then
        trace[#trace + 1] = {line = b.first, kind = k, page = pageNo, col = col, y = at, h = h}
      end
      prev = k == "li" and b.list or (k == "drawn" and "p" or k)
    end
    placed[#placed + 1] = i
    i = i + 1
  end
  return nil
end

-- Put a \page wherever a page fills up. Returns the text, its page count,
-- and what the layout found: `notes`, each block the model can't fit or
-- measure ({ line, page, what }, line being the text's own line), and
-- `starts`, the page each block starts on ({ line, page }, in order), which
-- gmbook.pageAt reads.
function gmbook.paginate(text, trace)
  cache = {}
  local bs, lines = parse(text)
  local at, s, pages = {}, 1, 1
  while s <= #bs do
    local nxt, explicit = fitPage(bs, s, trace, pages)
    if not nxt or nxt > #bs then
      for j = s, #bs do bs[j].page = pages end
      break
    end
    if nxt <= s then
      -- nothing fitted, so the block goes here whatever happens, and spills
      bs[s].spills = bs[s].spills or TALL[bs[s].kind] or TALL.block
      nxt = s + 1
    end
    for j = s, nxt - 1 do bs[j].page = pages end
    while trace and #trace > 0 and trace[#trace].line >= bs[nxt].first do
      table.remove(trace)  -- a heading that moved on with its text
    end
    if not explicit then at[bs[nxt].first] = true end
    pages = pages + 1
    s = nxt
  end
  local notes, starts = {}, {}
  for _, b in ipairs(bs) do
    local page = b.page or pages
    starts[#starts + 1] = { line = b.first, page = page }
    for _, what in ipairs({ b.spills or false, b.unmeasured or false,
                            b.image and "an image without a declared height" or false,
                            b.pageInCode and "a \\page line inside a code block, " ..
                              "where Homebrewery breaks the page all the same" or false }) do
      if what then notes[#notes + 1] = { line = b.first, page = page, what = what } end
    end
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
  return table.concat(out, "\n"), pages, { notes = notes, starts = starts }
end

-- The pages of a text Homebrewery breaks only where it says \page, with the
-- same `starts` as gmbook.paginate gives, a line at a time: for a build
-- with paginate off. Each line of \page starts a page, even in code.
function gmbook.explicitPages(text)
  local starts, page, n = {}, 1, 0
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    n = n + 1
    if hbPage(line) then page = page + 1 end
    starts[#starts + 1] = { line = n, page = page }
  end
  return text, page, { notes = {}, starts = starts }
end

-- The contents page gmBook.contents puts at the front of an edition: its
-- title, and a table of the chapters, each with the page it starts on and
-- its title a link to that page (#pN is Homebrewery's own id for page N).
-- Neither the model nor Homebrewery breaks a table, so a long contents is
-- as many tables as it takes for none to be taller than a column, each as
-- long as a column holds, measured as the page breaks measure it. `words`
-- has the title and the two headings; rows are { title, page }.
function gmbook.contentsPage(words, rows)
  local L = gmbook.layout
  local flat = { y = 0, inset = function() return 0 end }
  local room = L.height - L.slack - measure({ kind = "h1", text = words.title }, flat).h - 1
  local function cell(s) return (tostring(s):gsub("|", "\\|")) end
  local head = { "| " .. cell(words.chapter) .. " | " .. cell(words.page) .. " |", "|:--|--:|" }
  local all = {}
  for _, r in ipairs(rows) do
    local title = (cell(r.title):gsub("[%[%]]", "\\%0"))
    local page = string.format("%d", r.page)
    all[#all + 1] = "| [" .. title .. "](#p" .. page .. ") | " .. page .. " |"
  end
  -- whether rows a to b make a table no taller than a column
  local function fits(a, b)
    local t = { head[1], head[2] }
    for k = a, b do t[#t + 1] = all[k] end
    return tableHeight(t) <= room
  end
  local out, a = { "# " .. words.title }, 1
  while a <= #all do
    -- the most rows from a that fit, and at least one; a column holds
    -- fewer than 60 rows of one line
    local lo, hi = a, math.min(#all, a + 59)
    while lo < hi do
      local mid = math.floor((lo + hi + 1) / 2)
      if fits(a, mid) then lo = mid else hi = mid - 1 end
    end
    local t = { head[1], head[2] }
    for k = a, lo do t[#t + 1] = all[k] end
    out[#out + 1] = ""
    out[#out + 1] = table.concat(t, "\n")
    a = lo + 1
  end
  return table.concat(out, "\n")
end

-- The page a line of a laid-out text is on: the page of the first block
-- that starts on that line or after it, or the last page.
function gmbook.pageAt(info, line)
  local starts, lo, hi = info.starts, 1, #info.starts
  if hi == 0 then return 1 end
  if starts[hi].line < line then return starts[hi].page end
  while lo < hi do
    local mid = math.floor((lo + hi) / 2)
    if starts[mid].line < line then lo = mid + 1 else hi = mid end
  end
  return starts[lo].page
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
        { name = "Player edition", description = "Without the DM-only text" },
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
/* A build's notification carries two buttons, and on a narrow screen those
   alone are wider than the space the notification is given. The row is a flex
   that doesn't wrap and whose buttons don't shrink, and the column is aligned
   to its right edge, so the row grows off the LEFT edge of the screen and the
   message is cut off mid-word. Let the row wrap and the message shrink, and
   the buttons drop to a line of their own instead. */
.sb-notifications > div {
  max-width: 100%;
  flex-wrap: wrap;
}

.sb-notifications > div > :first-child {
  min-width: 0;
  overflow-wrap: anywhere;
}

.sb-notifications .sb-notification-actions {
  flex-wrap: wrap;
}

.gmbook-bar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px 8px;
}

.gmbook-bar-text {
  flex: 1 1 18em;
}

/* A tab that has to reload before it builds says so on a line of its own,
   above the rest of the bar. */
.gmbook-bar-stale {
  flex: 1 1 100%;
}

/* The widget's own Copy and Reload overlay would cover the bar's buttons. */
.sb-lua-top-widget:has(.gmbook-bar) .button-bar {
  display: none !important;
}

/* DM-only text, where it sits on the page. The words and the icon say what
   the players won't get, so the colour is never the only sign of it. */
.sb-admonition[admonition="dm" i],
.sb-admonition[admonition^="dm " i],
.sb-admonition[admonition^="dm-" i] {
  --admonition-icon: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path><line x1="1" y1="1" x2="23" y2="23"></line></svg>');
  --admonition-color: #8e5bd6;
}

.sb-admonition[admonition="dm" i] .sb-admonition-type::before,
.sb-admonition[admonition^="dm " i] .sb-admonition-type::before,
.sb-admonition[admonition^="dm-" i] .sb-admonition-type::before {
  width: var(--admonition-width) !important;
}

.sb-admonition[admonition="dm" i] .sb-admonition-type *,
.sb-admonition[admonition^="dm " i] .sb-admonition-type *,
.sb-admonition[admonition^="dm-" i] .sb-admonition-type * {
  display: none;
}

.sb-admonition[admonition="dm" i] .sb-admonition-type::after,
.sb-admonition[admonition^="dm " i] .sb-admonition-type::after,
.sb-admonition[admonition^="dm-" i] .sb-admonition-type::after {
  content: "DM only \00b7";
  font-size: 85%;
  font-weight: bold;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  margin: 0 0.4em 0 0.35em;
}

span.dm {
  border-bottom: 2px dotted #8e5bd6;
}

span.dm::before {
  content: "DM \25b8  ";
  font-size: 80%;
  font-weight: bold;
}

div.dm {
  border-left: 2px dotted #8e5bd6;
  padding-left: 0.6em;
}

div.dm::before {
  content: "DM only \25b8";
  display: block;
  font-size: 80%;
  font-weight: bold;
}
```
