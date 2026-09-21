---
tags: meta/library
name: "Library/Storie/GM Kit"
description: "Session tracking and fog-of-war publishing for tabletop RPG campaigns. Keeps play state out of your adventure pages so the adventure stays publishable."
author: "Steven Storie"
version: "3.2.0"
---

# GM Kit

Run a campaign from one SilverBullet space while keeping **what happened at the table** completely separate from **the adventure as written**.

Your adventure pages are never touched. Who the party met, who died, where they went, what they found and what they have learned all live in `State/` in the DM space, so the adventure itself stays clean enough to compile into a book.

## Layout it expects

One DM space containing the others as subfolders, each bind-mounted as its own SilverBullet space:

    dm/            this library lives here
      Adventure/   the adventure, never written to by this library
      Player/      what the players see, plus their own Notes/
      State/       play state, written by this library
      Sessions/    decision logs, written by this library

People, places, factions and items are the adventure pages inside a `People/`, `Places/`, `Factions/` or `Items/` folder, at any depth. Scenes are named by their type instead, because an adventure keeps its scenes under its acts: see *Scenes*.

## Buttons

**The GM bar.** In the DM space, every adventure page gets a bar across the top. It shows whether the players can see the page, with a button to reveal it or take it back: ◉ revealed and published, ◉ revealed but not published yet, or ○ hidden. A person adds *Mark met* and *Mark dead…*, a faction adds *Mark met*, a place adds *Mark visited*, an item adds *Mark found*, and a scene adds *Mark planned* and *Mark started*, then *Mark finished*. Once something is recorded, the bar says when, with the session linked to its log: "✓ Met in session 3", and a button takes the mark off again for one recorded by mistake. An item with uses shows how many are left, with buttons to use one and to refund one. A page that hands out an item, or shows its rules, gets a row for that item as well: see *Items*.

**A session's own notes.** A page in `Sessions/` gets a bar of its own instead: the scene before, the scene the session is on, and the scene after. See *Scenes*.

**The header.** Three buttons: the session table, *Log a decision* and *Publish to players*.

**Notifications.** Marking, unmarking, revealing, unrevealing and starting a session each come with *Undo*. A reveal also offers *Publish now*. *Undo* takes back what its own action did and nothing else, so a mark, a use or a decision made since stays made. It only lives as long as the notification; afterwards *Unmark* is what takes a mark off.

**Taking a page back.** *Unreveal* takes a page off the revealed list and deletes the copy the players were sent, so a page revealed or published by mistake is gone from the Player space at once. *Undo* puts both back, and so does revealing it and publishing again. A page that isn't revealed but that the players still have a copy of, say one hidden before 2.4, shows ◐ on its bar, with *Delete their copy*.

**Your own pages.** Every command works as a button, and a command that acts on a page asks which one when you aren't on one:

    ${widgets.commandButton("Met…", "GM: Mark Met")}
    ${widgets.commandButton("Log a decision", "GM: Log Decision")}

## Commands

| Command | Key | Does |
|---|---|---|
| `GM: Session Table` | | Opens the session page |
| `GM: Mark Met` | `Ctrl-Alt-m` | Records that the party met a person or faction, stamps the session, reveals the page |
| `GM: Mark Dead` | | Records a death and how it happened |
| `GM: Mark Visited` | | Records that the party visited a place, reveals it |
| `GM: Mark Found` | | Records that the party found an item, starts counting its uses, and offers to reveal it |
| `GM: Mark Scene Planned` | | Records a scene you expect the party to reach this session |
| `GM: Mark Scene Started` | | Opens a scene at the table |
| `GM: Mark Scene Finished` | | Closes it, in this session or a later one |
| `GM: Unmark` | | Takes a mark off again: met, dead, visited or found, and an item's uses with its find; started, and its finish with it |
| `GM: Spend Use` | | Uses one of an item's uses |
| `GM: Refund Use` | | Gives one back |
| `GM: Reveal Page` | | Adds an adventure page to the revealed list |
| `GM: Unreveal Page` | | Takes a page back: off the revealed list, and the players' copy deleted |
| `GM: Publish to Players` | | Copies every revealed page into the Player space, leaving out its DM-only text |
| `GM: Log Decision` | `Ctrl-Alt-d` | Appends to this session's log |
| `GM: Next Session` | | Increments the session counter |

On a person's page, `GM: Mark Met` marks that person. Anywhere else it opens a list of people and factions, with the ones already met at the bottom. The other marks work the same way, and so do reveal and unreveal on any adventure page; off one, `GM: Unreveal Page` lists what the players can see or still have. `GM: Hide Page`, its name before 2.4, still works. Found, use and refund also act at once on a page with a row for just one item. The scene marks work like the rest: on a scene page they mark that scene, and anywhere else they ask which. Publishing and starting a session ask first.

## Items

An item is an adventure page in an `Items/` folder. Marking it found records the session but doesn't reveal the page, because a party can carry a thing before it knows what it is. The notification offers *Reveal*, and so does the item's row until you press it.

**Uses.** A page hands out an item when a GM Party count on it names the item:

    It holds ${party.count{"grin", plus = 1, item = "World/Items/Tube"}}.

That page's bar gets a row for the item, "Tube: six grins here", with *Mark found*. Found there, its uses start at that count for the party of the moment, and its rows and its own bar show what is left, "●●●●○○ 4 of 6 grins left", with *Use a grin* and *Refund a grin*. Each has *Undo*. Marked found from its own page, an item takes the count of the page that hands it out, and asks where when several do. An item that nothing hands out is found without uses. *Unmark found* takes the find back, uses and all, so finding it again counts them afresh.

**Rules in a scene.** A page that shows an item's rules with `![[World/Items/Tube#Rules]]` gets a row for it too, so wherever the rules are, the uses are.

## Scenes

A scene is an adventure page of `type: scene`, wherever it lives, since an adventure keeps its scenes under its acts rather than in one folder. `gm.config.sceneType` names the type.

**Planned, started, finished.** Before a session, *Mark planned* records the scenes you expect the party to reach. At the table *Mark started* opens one and *Mark finished* closes it. The two ends are kept apart because a scene that runs long finishes in the next session: the bar then reads "✓ Played in sessions 1–2", each number linked to its log, where a scene inside one session reads "✓ Played in session 3" and one still running reads "▶ Started in session 3, still going". A scene can only be finished once it is started, and unstarting one takes its finish with it.

Every mark stamps the session you are in, so plan **after** pressing *Next session*, not before.

**Both ways round.** Each mark also writes a line into that session's own log, under `## Scenes`:

    - Started: [[Campaign/Act I/Scene 3|Scene 3 — Off the Road]]

So the notes for a session link the scenes played in it, and each scene's bar links the sessions it was played in. Unmarking writes "Not started after all" rather than taking the line out, the way a state log already reads, and *Undo* takes both back.

**Where you are.** A page in `Sessions/` gets a bar of the scene before, the scene the session is on, and the scene after:

    ← Scene 1 — The Field · **Scene 2 — The Road, and the Town** · Scene 3 — Off the Road →

A session sits on the last scene it started, failing that the first scene planned for it, failing that wherever the session before it left off, so next week's empty notes already point at the right place. The order is the adventure's own, `book_order` and then name, so the scene after the last of one act is the first of the next.

Playing a scene never reveals it: what the players can see of the adventure stays your business.

## Where the state goes

- `State/Revealed`: one link per revealed adventure page
- `State/People/<name>`, `State/Places/<name>`: met, dead, visited, with a log
- `State/Items/<name>`: found, the uses left of those found, and where, with a log
- `State/Scenes/<act>/<scene>`: planned, started and finished, with a log; the act comes too, so scenes numbered alike in two acts stay apart
- Each log line names its session and links to it
- `Sessions/Session N`: the scenes under `## Scenes`, the decisions under `## Decisions`, one line each

## Players' own notes

Publishing writes into `Player/` and **replaces** what is there, except `Player/Notes/`, which it never touches. Nothing in `Player/` is ever deleted except the copy of a page you unreveal.

## DM-only text

An adventure page can keep its secrets beside what the players may see, and publishing leaves them out of the players' copy. Four things mark them, and each can sit wherever it belongs on the page.

**A DM callout**, for a note in place. It is a quote like a `note` or a `warning`, with `dm` for its type, and it ends at the first blank line:

    > **dm** Who the stranger is
    > The missing heir, though nobody has told him yet.

**A stretch**, for anything longer: a table, a map, headings of its own. Everything between the two markers goes, and a stretch with no end runs to the end of the page:

    <!--#dm-->

    | Clue | Where it points |
    |---|---|
    | The torn letter | The miller's cellar |

    <!--/dm-->

**A span**, for words inside a sentence:

    The door is locked. <span class="dm">The key is under the mat.</span>

**A `## DM Only` section**, which runs to the next `#` or `##` heading.

None of them counts inside fenced code, so a code sample can show one. Give markers and callouts lines of their own, with a blank line after, as you would a heading: a line straight after a callout carries on its paragraph, and goes with it.

The DM space shows a callout with *DM only* and a crossed-out eye at its top, and a span with *DM* before it and a dotted line under it, so what the players won't get says so in words, not only in colour. `gm.config.dmWord` is the word all three look for, `dm`. The style looks for `dm` as well, so copy it with your own word if you change it.

## Pages only the DM sees

Some pages keep what only the DM may see in the page itself, where no DM-only marking can reach it. A GM Maps map page is one: its map block is the grid with the creatures on it, and every trapdoor, written out. Their types are in `gm.config.privateTypes`, `{ "map" }` by default, and the type GM Maps is set to give its pages counts too. Such a page is never revealed or published, and its bar says so: "⊘ Only for the DM". The players see a map where a page of theirs draws it, which prints it clean.

A private page that is on the revealed list from before, or that the players already have a copy of, says that on its bar with a button to take it back. Publishing leaves it out and names it.

## Live values in players' copies

The Player space runs only its own code, so a copy can't lean on the DM's libraries. Publishing puts in the Markdown face of any `${...}` that gives a widget with one: GM Party's numbers go in as your party's, "seven grins" rather than the rule. Everything else stays live, and the Player space evaluates it against what it can see: a query there lists only what has been published.

## Changes in 3.2

**Marks no longer overwrite each other.** GM Kit asked `space.pageExists` whether a state page or a session's log was there yet. In SilverBullet 2.11 that answers the way a link resolves, from a list of pages that can be seconds behind a write, so a page written a moment before could look missing. A second action on it then built it afresh from its template: *Mark met* then *Mark dead*, or *Mark started* then *Log a decision*, lost the first, and both said they had worked. GM Kit now asks for the page itself (`gm.exists`).

**Undo takes back only its own action.** It used to put the whole page back as the action found it, so undoing a scene's start deleted the session's log with a decision logged after it, and undoing one use of two gave both back. Now the fields the action set go back to what they were, its log lines come out, and a log it began goes only if nothing else was written to it.

**A map page is never revealed or published.** Its map block holds the creatures and every hidden thing, and publishing one sent them to the players. See *Pages only the DM sees*.

**A published page reads itself.** While publishing, `gm.printing` is the page being printed, so an expression that reads the page it sits on, such as GM Bestiary's `${bestiary.ref()}`, prints for that page instead of the one open in the editor.

## Changes in 3.1

DM-only text can sit where it belongs on a page, instead of only in a `## DM Only` section at the bottom: a DM callout, `> **dm** Title`; a stretch between `<!--#dm-->` and `<!--/dm-->`; and `<span class="dm">` inside a sentence. Publishing leaves all of them out, and the DM space labels them. See *DM-only text*.

Fenced code no longer confuses a `## DM Only` section. A `#` line in a fence under one, such as a map's legend, used to end the section and publish the rest of it, and a `## DM Only` line in a code sample hid everything after it.

## Changes in 3.0

The adventure lives in `Adventure/`, which was `Planning/`. Rename the folder, and the links to it in `State/`, or keep the old name with a `space-lua` block of your own:

    gm.config.adventureFolder = "Planning/"

In code, `gm.config.planningPrefix` is now `gm.config.adventureFolder`, `gm.isPlanningPage` is `gm.isAdventurePage` and `gm.planningPages` is `gm.adventurePages`.

## Changes in 2.6

Scenes. A scene is marked *planned* before a session and *started* and *finished* during it, and each mark writes a line into that session's log as well as into the scene's own state, so a session's notes link the scenes played in it and every scene links the sessions it was played in. A session's notes also get a bar of the scene before, the scene it is on and the scene after. A scene's state keeps its act, `State/Scenes/Act I/Scene 3`, so two acts' third scenes don't land on one page.

Session logs keep scenes and decisions in sections of their own, and a decision is added under `## Decisions` rather than at the end of the page.

## Changes in 2.5

*Unmark* takes a mark off a page that was marked by mistake: met, dead, visited, or found with its uses. It is on the bar beside each recorded mark and on every item row, as a command, and it has *Undo* of its own. Before this, once a mark's notification had gone, only editing the state page by hand could undo it. Every log line, and every "found in session 3" on a bar, now links to that session's log.

## Changes in 2.4

*Unreveal* replaces *Hide*. Hide took a page off the revealed list but left the players their published copy unless you caught a button in its notification; unrevealing deletes that copy too, with *Undo*. The bar says whether a revealed page has been published yet, and marks a page the players still have a copy of after it came off the list.

A space's `CONFIG` page is no longer an adventure page. Before 2.4 it could be revealed, and publishing would then have copied the adventure's settings over the Player space's own.

## Changes in 2.3.1

Marks work in SilverBullet. Every mark, and the bar of any page that shows an item's rules, stopped with "attempt to index a userdata value": Space Lua won't call a method straight on the two values `gsub` gives, and plain Lua, where the libraries were tested, quietly keeps the first.

## Changes in 2.3

Items: *Mark found*, uses counted from the page that hands an item out, *Use* and *Refund* with *Undo*, and a row on the bar of each page that hands out an item or shows its rules. Finding offers to reveal rather than revealing.

## Changes in 2.2

Publishing puts in the Markdown face of widgets that have one, as above.

## Changes in 2.1

Buttons: the GM bar, the header buttons, pickers, and *Undo*. Marking someone met a second time no longer moves their session of first contact. Publishing reports what it added and changed, and leaves unchanged player pages alone. The session number is read straight from the session page, so it is right the moment it changes.

## Changes from 1.x

1.x wrote `met` and `revealed` into the adventure pages' own frontmatter, so a published adventure shipped with one particular party's history baked in. 2.0 keeps all of it in `State/`.

## Implementation

```space-lua
-- priority: 10
gm = gm or {}

gm.config = {
  sessionPage     = "Session Table",
  sessionsFolder  = "Sessions/",
  stateFolder     = "State/",
  revealedPage    = "State/Revealed",
  adventureFolder = "Adventure/",
  playerFolder    = "Player/",
  playerNotes     = "Notes/",
  dmHeading       = "DM Only",
  dmWord          = "dm",
  sceneType       = "scene",
  sessionType     = "session",
  -- Page types whose page itself holds what only the DM may see, so they
  -- are never revealed or published: GM Maps keeps a map's creatures, and
  -- everything hidden on it, in the map block on its page.
  privateTypes    = { "map" },
}

-- What GM Kit tracks, and what each kind's pages can be marked. The first
-- four are adventure folders. A scene is any adventure page of `sceneType`,
-- because an adventure keeps its scenes under its acts, not in one folder.
gm.kinds = {
  People   = { met = true, dead = true },
  Factions = { met = true },
  Places   = { visited = true },
  Items    = { found = true },
  Scenes   = { planned = true, started = true, finished = true },
}

-- "---\n<head>---\n<rest>" as head and rest, or nil without frontmatter.
function gm.splitFrontmatter(text)
  if text:sub(1, 4) ~= "---\n" then return nil end
  local s, e = text:find("\n%-%-%-[ \t]*\n", 4)
  if not s then
    s, e = text:find("\n%-%-%-[ \t]*$", 4)
    if not s then return nil end
  end
  return text:sub(5, s), text:sub(e + 1)
end

-- A YAML value as SilverBullet's index reads it: "quoted" or 'quoted' comes
-- without its quotes, and a # comment after it goes. A page typed 'map', or
-- map # the clearing, is a map page to GM Maps, so it has to be one here.
local function yamlValue(v)
  local dq = v:match('^"(.*)"$') or v:match('^"(.-)"%s+#')
  if dq then return dq end
  local sq = v:match("^'(.*)'$") or v:match("^'(.-)'%s+#")
  if sq then return (sq:gsub("''", "'")) end
  return (v:gsub("%s+#.*$", ""))
end

-- Frontmatter as a table of strings.
function gm.frontmatter(text)
  local fields = {}
  local head = gm.splitFrontmatter(text)
  for line in (head or ""):gmatch("([^\n]*)\n") do
    local k, v = line:match("^([%w_]+):%s*(.-)%s*$")
    if k then fields[k] = yamlValue(v) end
  end
  return fields
end

function gm.setFrontmatter(text, key, value)
  local line = key .. ": " .. tostring(value)
  local head, rest = gm.splitFrontmatter(text)
  if not head then
    return "---\n" .. line .. "\n---\n\n" .. text
  end
  local found = false
  -- gsub gives two values, and Space Lua won't call a method on the pair:
  -- the brackets keep the first.
  head = (("\n" .. head):gsub("\n" .. key .. ":[^\n]*", function()
    found = true
    return "\n" .. line
  end, 1)):sub(2)
  if not found then head = head .. line .. "\n" end
  return "---\n" .. head .. "---\n" .. rest
end

-- Takes a key back out of the frontmatter, leaving the rest as it was.
function gm.clearFrontmatter(text, key)
  local head, rest = gm.splitFrontmatter(text)
  if not head then return text end
  local out = {}
  for line in head:gmatch("([^\n]*)\n") do
    if not line:startsWith(key .. ":") then out[#out + 1] = line end
  end
  if #out == 0 then return rest end
  return "---\n" .. table.concat(out, "\n") .. "\n---\n" .. rest
end

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

-- Whether a <span ...> tag's class names `word`.
local function dmClass(tag, word)
  local c = "%s[cC][lL][aA][sS][sS]%s*=%s*"
  local cls = tag:match(c .. "\"([^\"]*)\"") or tag:match(c .. "'([^']*)'")
    or tag:match(c .. "([^%s>\"']+)")
  if not cls then return false end
  return (" " .. (cls:gsub("%s+", " ")):lower() .. " "):find(" " .. word .. " ", 1, true) ~= nil
end

-- A line's DM spans, <span class="dm">...</span>: left out, or with keep
-- only their tags left out. open is how deep in one the line starts, carried
-- from the line above. Gives back the line, how deep it ends, and whether it
-- changed. Inline code is skipped, so a span shown in backticks stays.
local function dmSpans(line, word, open, keep)
  local out, pos, i, n = {}, 1, 1, #line
  local changed, seam = false, false
  local dropping = open > 0 and not keep
  local function put(s)
    if seam and s:match("^%s") then
      local last = out[#out]
      if not last or last:match("%s$") then s = (s:gsub("^%s+", "")) end
    end
    seam = false
    if s ~= "" then out[#out + 1] = s end
  end
  while i <= n do
    local a = line:find("[`<]", i)
    if not a then break end
    if line:sub(a, a) == "`" then
      local run = line:match("^`+", a)
      local close = line:find(run, a + #run, true)
      i = close and close + #run or a + #run
    else
      local tag = line:match("^<[sS][pP][aA][nN][%s>][^>]*>", a)
        or line:match("^<[sS][pP][aA][nN]>", a)
      local shut = not tag and line:match("^</[sS][pP][aA][nN]%s*>", a)
      if tag then
        if open > 0 then
          open = open + 1
        elseif dmClass(tag, word) then
          put(line:sub(pos, a - 1))
          open, changed, pos = 1, true, a + #tag
          dropping = not keep
        end
        i = a + #tag
      elseif shut then
        if open > 0 then
          open = open - 1
          if open == 0 then
            if keep then put(line:sub(pos, a - 1)) end
            changed, pos = true, a + #shut
            if not keep then dropping, seam = false, true end
          end
        end
        i = a + #shut
      else
        i = a + 1
      end
    end
  end
  local tail = dropping and "" or line:sub(pos)
  if dropping then changed = true end
  put(tail)
  local text = table.concat(out)
  if not keep and changed and (dropping or not tail:match("%S")) then
    text = (text:gsub("%s+$", ""))
  end
  return text, open, changed
end

-- Finds a page's DM-only text: a `## DM Only` section, a DM callout
-- (> **dm** Title), a stretch between <!--#dm--> and <!--/dm-->, and a span
-- inside a line. None of them counts in fenced code. Gives back the lines,
-- and for each one what it is.
local function dmScan(text, heading, word)
  local lines = {}
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do lines[#lines + 1] = line end
  local n = #lines
  local scan = { lines = lines, code = {}, callout = {}, section = {}, stretch = {},
                 marker = {}, word = word:lower() }
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
  -- callout type names `word`, and a quote that isn't is searched for one
  -- inside it. A quote runs over the lines that carry its marker, and over a
  -- line without one that carries on the paragraph above.
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
        if kind == scan.word then
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

  -- `## DM Only` sections, to the next # or ## heading, and stretches
  -- between the markers. Markers nest, so an inner end can't close an outer
  -- stretch, and a stretch with no end runs to the end of the page.
  local head = "^##%s+" .. (heading:gsub("%p", "%%%0"))
  local w = (scan.word:gsub("%p", "%%%0")):gsub("%a", function(ch)
    return "[" .. ch .. ch:upper() .. "]"
  end)
  local open = "^[%s>]*<!%-%-%s*#%s*" .. w .. "[^%w_]"
  local shut = "<!%-%-%s*/%s*" .. w .. "[^%w_]"
  local inSection, depth = false, 0
  for i = 1, n do
    local line = lines[i]
    if not code[i] then
      if inSection then
        if line:match("^##?%s") and not line:match(head) then inSection = false end
      elseif line:match(head) then
        inSection = true
      end
      local l = line .. " "
      if not scan.callout[i] and l:match(open) then
        scan.marker[i] = true
        local after = l:sub((l:find("<!--", 1, true)) + 4)
        if not after:find(shut) then depth = depth + 1 end
      elseif not scan.callout[i] and l:match("^[%s>]*" .. shut) then
        scan.marker[i] = true
        if depth > 0 then depth = depth - 1 end
      end
    end
    if inSection then scan.section[i] = true end
    if depth > 0 or scan.marker[i] then scan.stretch[i] = true end
  end
  return scan
end

-- The page without its DM-only text. Where a block goes from between two
-- blank lines, one of them goes with it.
local function dmStrip(scan)
  local out, cut, span = {}, false, 0
  for i, line in ipairs(scan.lines) do
    local drop = scan.callout[i] or scan.section[i] or scan.stretch[i]
    if drop or scan.code[i] or not line:match("%S") then
      span = 0
    else
      local text, open, changed = dmSpans(line, scan.word, span, false)
      span = open
      if changed and not text:match("%S") then drop = true else line = text end
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

-- end of the shared DM-only code

-- The page without its DM-only text, for the players' copy.
function gm.stripSecrets(text)
  local c = gm.config
  if not text:find("[<>]") and not text:find(c.dmHeading, 1, true) then return text end
  return dmStrip(dmScan(text, c.dmHeading, c.dmWord))
end

-- While a page is printed for the players, gm.printing is its name, so an
-- expression that reads the page it sits on, such as GM Bestiary's
-- ${bestiary.ref()}, reads that page rather than the one open in the editor.
gm.printing = nil

-- A players' copy carries no code the Player space can't run: each ${...}
-- that gives a widget with a Markdown face goes in as that Markdown. The rest
-- stays live, so a query in the Player space sees only what was published.
-- `page` is the page the text comes from.
function gm.print(text, page)
  if not text:find("${", 1, true) then return text end
  local found = {}
  local function walk(node)
    if node.type == "LuaDirective" then
      found[#found + 1] = node
    elseif node.children then
      for _, child in ipairs(node.children) do walk(child) end
    end
  end
  walk(markdown.parseMarkdown(text))
  local was = gm.printing
  gm.printing = page
  -- put back however this ends, a stop from the user included, which pcall
  -- passes on rather than catching
  local restore <close> = setmetatable({}, { __close = function() gm.printing = was end })
  for i = #found, 1, -1 do
    local node = found[i]
    local ok, value = pcall(function()
      return spacelua.evalExpression(spacelua.parseExpression(text:sub(node.from + 3, node.to - 1)))
    end)
    if ok and type(value) == "table" and value._isWidget and type(value.markdown) == "string" then
      text = text:sub(1, node.from) .. value.markdown .. text:sub(node.to + 1)
    end
  end
  return text
end

-- Whether there is a page of exactly this name. space.pageExists can't say:
-- it answers the way a link resolves, so a page whose path only ends that
-- way counts, and it reads a list of pages that can be seconds behind a
-- write. A page written a moment ago then looks missing, and marking it again
-- would build it afresh from its template over the first mark. Any failure
-- but a missing page is raised rather than taken for one, for the same reason.
function gm.exists(page)
  if not page or page:find("^%.") or page:find("/%.%.?/") or page:find("/%.%.?$") then
    return false
  end
  local ok, err = pcall(space.getPageMeta, page)
  if ok then return true end
  local why = tostring(err)
  if why:find("Not found", 1, true) or why:find("isn't readable", 1, true) then return false end
  error(err, 0)
end

-- For what a bar, a table or a picker shows: the client's own list first,
-- which costs nothing, or GM Kit's note of a page it has just written, which
-- the list can take seconds to show; then the page itself, only for a yes,
-- since the list says yes to any page whose path ends the same way. gm.exists
-- asks the space every time, which goes to the server for a page that isn't
-- there.
function gm.seen(page)
  return (space.pageExists(page) or gm.written[page] == true) and gm.exists(page)
end

-- Reads a page, saving it first if it is open so no typing is lost.
function gm.read(page)
  if editor.getCurrentPage() == page then editor.save() end
  return space.readPage(page)
end

-- The pages GM Kit has written since the space loaded, which the client's
-- own list can take seconds to show: gm.seen counts them at once, so a bar
-- redrawn straight after a mark shows the mark.
gm.written = {}

-- Writes a page, reloading it if it is open so the editor never shows a stale copy.
function gm.write(page, text)
  space.writePage(page, text)
  gm.written[page] = true
  if editor.getCurrentPage() == page then editor.reloadPage() end
end

-- Redraws the bar and any buttons or queries on the open page.
function gm.refresh()
  pcall(function() codeWidget.refreshAll() end)
end

-- Actions become buttons on the notification: { { name = "Undo", run = fn } }.
function gm.notify(message, actions, kind)
  local options
  if actions then options = { timeout = 10000, actions = actions } end
  editor.flashNotification(message, kind or "info", options)
end

function gm.name(page)
  return page:match("([^/]+)$") or page
end

function gm.patch(page, key, value)
  local text = gm.exists(page) and gm.read(page) or ("# " .. gm.name(page) .. "\n")
  gm.write(page, gm.setFrontmatter(text, key, value))
end

-- Read from the page rather than the index, so it is right straight after a change.
function gm.currentSession()
  local page = gm.config.sessionPage
  if not gm.exists(page) then return 1 end
  return tonumber(gm.frontmatter(space.readPage(page)).session) or 1
end

-- "session 3", linked to that session's log, for a bar, a log line or a
-- table. cap gives "Session 3", to open a sentence or fill a column.
function gm.sessionLink(n, cap)
  local label = (cap and "Session " or "session ") .. tostring(n or "?")
  if not n then return label end
  return "[[" .. gm.config.sessionsFolder .. "Session " .. n .. "|" .. label .. "]]"
end

function gm.readRevealed()
  local list = {}
  if not gm.exists(gm.config.revealedPage) then return list end
  for name in space.readPage(gm.config.revealedPage):gmatch("%- %[%[([^%]]+)%]%]") do
    list[#list + 1] = name
  end
  return list
end

function gm.writeRevealed(list)
  table.sort(list)
  local lines = {
    "---", "type: state", "---", "",
    "# Revealed to players", "",
    "Adventure pages the players have learned about, kept by GM Kit. " ..
      "Publishing copies each of them into `" .. gm.config.playerFolder .. "`.", "",
    '${widgets.commandButton("Reveal a page…", "GM: Reveal Page")} ' ..
      '${widgets.commandButton("Unreveal a page…", "GM: Unreveal Page")} ' ..
      '${widgets.commandButton("Publish to players", "GM: Publish to Players")}', "",
  }
  for _, n in ipairs(list) do lines[#lines + 1] = "- [[" .. n .. "]]" end
  gm.write(gm.config.revealedPage, table.concat(lines, "\n") .. "\n")
end

function gm.isRevealed(page)
  for _, n in ipairs(gm.readRevealed()) do
    if n == page then return true end
  end
  return false
end

-- Adds or removes a page. Returns whether the list changed.
function gm.setRevealed(page, on)
  local out, found = {}, false
  for _, n in ipairs(gm.readRevealed()) do
    if n == page then found = true else out[#out + 1] = n end
  end
  if found == on then return false end
  if on then out[#out + 1] = page end
  gm.writeRevealed(out)
  return true
end

-- An adventure page: in the adventure folder, but not its index, its CONFIG,
-- libraries or build output.
function gm.isAdventurePage(page)
  local prefix = gm.config.adventureFolder
  if not page or not page:startsWith(prefix) then return false end
  local rel = page:sub(#prefix + 1)
  return rel ~= "index" and rel ~= "CONFIG" and not rel:startsWith("Library/")
    and not rel:startsWith("Build/")
end

function gm.adventurePages()
  local prefix = gm.config.adventureFolder
  local names = query[[
    from p = index.pages()
    where p.name:startsWith(prefix)
    order by p.name
    select p.name
  ]]
  local out = {}
  for _, name in ipairs(names) do
    if gm.isAdventurePage(name) then out[#out + 1] = name end
  end
  return out
end

-- "People", "Places", "Factions" or "Items", from the page's folder.
-- A page's type, read from the page rather than the index so a page
-- written a moment ago already counts.
function gm.pageType(page)
  if not page or not gm.exists(page) then return nil end
  return gm.frontmatter(space.readPage(page)).type
end

function gm.isScene(page)
  return gm.isAdventurePage(page) and gm.pageType(page) == gm.config.sceneType
end

-- The private types as a set: the configured ones, and the type GM Maps is
-- set to give its map pages, since a space may have told it another.
local function privateSet()
  local set = {}
  for _, t in ipairs(gm.config.privateTypes) do set[t] = true end
  if maps and maps.setting then
    local ok, t = pcall(maps.setting, "type")
    if ok and type(t) == "string" then set[t] = true end
  end
  return set
end

-- A page of one of the private types, which only the DM may ever see. The
-- page's own frontmatter is asked, which is right the moment it is written,
-- and so is the index, which reads YAML the way GM Maps sees the page:
-- either one saying so is enough.
function gm.isPrivate(page)
  local set = privateSet()
  local t = gm.pageType(page)
  if t and set[t] then return true end
  local indexed = query[[
    from p = index.pages()
    where p.name == page and p.type ~= nil
    select p.type
  ]]
  return type(indexed[1]) == "string" and set[indexed[1]] == true
end

-- The adventure pages of a private type, by the index, for a picker, where
-- a page written a moment ago can wait to be left out.
function gm.privatePages()
  local prefix, set = gm.config.adventureFolder, privateSet()
  local rows = query[[
    from p = index.pages()
    where p.name:startsWith(prefix) and p.type ~= nil
    select { name = p.name, type = p.type }
  ]]
  local out = {}
  for _, row in ipairs(rows) do
    if set[row.type] then out[row.name] = true end
  end
  return out
end

-- The folder decides for people, places, factions and items; for anything
-- else only the page itself can say, so it is read last and rarely.
function gm.kind(page)
  local folder = page:match("/(People)/") or page:match("/(Places)/")
    or page:match("/(Factions)/") or page:match("/(Items)/")
  if folder then return folder end
  if gm.isScene(page) then return "Scenes" end
  return nil
end

-- "Act I/Scene 3" for a scene, so scenes numbered alike in two acts don't
-- land on one state page, and the page's own name for everything else.
function gm.stateName(page)
  local act, scene = page:match("([^/]+)/([^/]+)$")
  if act and scene then return act .. "/" .. scene end
  return gm.name(page)
end

function gm.statePath(page)
  local kind = gm.kind(page) or "Other"
  local name = kind == "Scenes" and gm.stateName(page) or gm.name(page)
  return gm.config.stateFolder .. kind .. "/" .. name
end

-- A page's play state. What a bar or a table shows reads it the cheap way
-- (gm.seen); an action that decides by it passes `exact`, so a record
-- written a moment ago counts.
function gm.readState(page, exact)
  local path = gm.statePath(page)
  local there
  if exact then there = gm.exists(path) else there = gm.seen(path) end
  if not there then return {} end
  return gm.frontmatter(space.readPage(path))
end

-- Where publishing puts a page, or nil for the pages it skips: anything but an
-- adventure page, so never a space's index, CONFIG or libraries, and never
-- the players' Notes.
function gm.playerCopy(page)
  if not gm.isAdventurePage(page) then return nil end
  local rel = page:sub(#gm.config.adventureFolder + 1)
  if rel:startsWith(gm.config.playerNotes) then return nil end
  return gm.config.playerFolder .. rel
end

-- Adds a list item to the end of a page's text.
function gm.appendItem(text, item)
  if text:sub(-1) ~= "\n" then text = text .. "\n" end
  return text .. "- " .. item .. "\n"
end

-- Adds a list item at the end of one `## Heading` section, making the
-- heading at the end of the page when it isn't there yet. A session log
-- keeps two sections, and appending to the page would file every line
-- under whichever of them came last.
function gm.appendUnder(text, heading, item)
  if text:sub(-1) ~= "\n" then text = text .. "\n" end
  local head = "## " .. heading
  local _, to = text:find("\n" .. head .. "[ \t]*\n")
  if not to then
    local trimmed = (text:gsub("[ \t\r\n]+$", ""))
    return trimmed .. "\n\n" .. head .. "\n\n- " .. item .. "\n"
  end
  local rest = text:sub(to + 1)
  local at = rest:find("^##[^#]") and 0 or rest:find("\n##[^#]")
  local body = at and rest:sub(1, at) or rest
  local tail = at and rest:sub(at + 1) or ""
  body = (body:gsub("^[ \t\r\n]*", ""))
  body = (body:gsub("[ \t\r\n]*$", ""))
  body = (body == "" and "" or body .. "\n") .. "- " .. item .. "\n"
  return text:sub(1, to) .. "\n" .. body .. (tail ~= "" and "\n" .. tail or "")
end

-- What a session's log starts as. Scenes come first, because they say what
-- the decisions are.
function gm.sessionTemplate(s)
  return "---\ntype: session\nsession: " .. s .. "\n---\n\n# Session " ..
         s .. "\n\n## Scenes\n\n## Decisions\n"
end

-- A session's log page and its text, from the template when the session has
-- none yet.
function gm.sessionLog(s)
  local page = gm.config.sessionsFolder .. "Session " .. s
  if gm.exists(page) then return page, gm.read(page) end
  return page, gm.sessionTemplate(s)
end

-- "Scene 3 — Off the Road", or the page's name where it has no title.
function gm.sceneTitle(page)
  local name = gm.name(page)
  local title = gm.exists(page) and gm.frontmatter(space.readPage(page)).scene_title
  if title and title ~= "" then return name .. " — " .. title end
  return name
end

-- A scene's line in a session's own log, so the notes for a session jump
-- straight to the scene that was played in it. Gives back the log and the
-- line, so Undo can take that line out again.
function gm.logScene(s, what, page)
  local log, text = gm.sessionLog(s)
  local item = what .. ": [[" .. page .. "|" .. gm.sceneTitle(page) .. "]]"
  gm.write(log, gm.appendUnder(text, "Scenes", item))
  return log, item
end

-- Every scene in the adventure, in the order it is meant to be played:
-- by `book_order` where the scenes carry one, and by name where they
-- don't, so an adventure that never compiles to a book still orders.
function gm.scenes()
  local t = gm.config.sceneType
  local rows = query[[
    from p = index.pages()
    where p.type == t
    select { name = p.name, order = p.book_order }
  ]]
  table.sort(rows, function(a, b)
    local x, y = tonumber(a.order), tonumber(b.order)
    if x and y and x ~= y then return x < y end
    if x and not y then return true end
    if y and not x then return false end
    return a.name < b.name
  end)
  local out = {}
  for i, row in ipairs(rows) do out[i] = row.name end
  return out
end

-- The scene a session sits on: the last one it started, failing that the
-- last one planned for it, failing that wherever the session before it
-- left off. nil until some scene has been marked at all.
function gm.sessionScene(s)
  local want = tostring(s)
  local started, planned, earlier = nil, nil, nil
  for _, page in ipairs(gm.scenes()) do
    local state = gm.readState(page)
    if state.started == "true" then
      if tostring(state.started_session) == want then started = page end
      if (tonumber(state.started_session) or 0) < (tonumber(s) or 0) then earlier = page end
    end
    if state.planned == "true" and tostring(state.planned_session) == want
       and not planned then
      planned = page
    end
  end
  return started or planned or earlier
end

-- "3", linked to session 3's log, for a range that says "sessions" once.
function gm.sessionNumberLink(n)
  if not n then return "?" end
  return "[[" .. gm.config.sessionsFolder .. "Session " .. n .. "|" .. n .. "]]"
end

-- Where a scene stands: planned for a session, played in one, run across
-- two, or still going. Empty for a scene nobody has marked at all.
function gm.playedText(state)
  local from, to = state.started_session, state.finished_session
  if state.started ~= "true" then
    if state.planned == "true" then
      return "Planned for " .. gm.sessionLink(state.planned_session)
    end
    return ""
  end
  if state.finished ~= "true" then
    return "Started in " .. gm.sessionLink(from) .. ", still going"
  end
  if tostring(to) == tostring(from) then return "Played in " .. gm.sessionLink(from) end
  return "Played in sessions " .. gm.sessionNumberLink(from) .. "–" ..
         gm.sessionNumberLink(to)
end

-- Creates or updates a page's play state and appends to its log. Gives back
-- the page and the text it wrote.
function gm.recordState(page, fields, entry)
  local path = gm.statePath(page)
  local text
  if gm.exists(path) then
    text = gm.read(path)
  else
    text = "---\ntype: state-record\nsubject: \"[[" .. page .. "]]\"\n---\n\n# " ..
           gm.name(page) .. "\n\nPlay state for [[" .. page .. "]].\n\n## Log\n\n"
  end
  local keys = {}
  for k in pairs(fields) do keys[#keys + 1] = k end
  table.sort(keys)
  for _, k in ipairs(keys) do text = gm.setFrontmatter(text, k, fields[k]) end
  if entry then text = gm.appendItem(text, entry) end
  gm.write(path, text)
  return path, text
end

function gm.log(path, entry)
  gm.write(path, gm.appendItem(gm.read(path), entry))
end

-- A frontmatter field as it is written, quotes and all, or nil.
function gm.rawField(text, key)
  local head = gm.splitFrontmatter(text)
  for line in (head or ""):gmatch("([^\n]*)\n") do
    local k, v = line:match("^([%w_]+):%s*(.-)%s*$")
    if k == key then return v end
  end
  return nil
end

-- Takes the last "- item" line out of a page's text, and gives back the
-- text and whether the line was there. Where the line stood between two
-- blank lines, one of them goes with it.
function gm.removeItem(text, item)
  local line = "- " .. item .. "\n"
  local at, from = nil, 1
  while true do
    local s = text:find(line, from, true)
    if not s then break end
    if s == 1 or text:sub(s - 1, s - 1) == "\n" then at = s end
    from = s + 1
  end
  if not at then return text, false end
  local out = text:sub(1, at - 1) .. text:sub(at + #line)
  if at > 2 and out:sub(at - 2, at - 1) == "\n\n" and out:sub(at, at) == "\n" then
    out = out:sub(1, at - 1) .. out:sub(at + 1)
  end
  return out, true
end

-- Takes one action back off a page without touching what was done after it:
-- each field it set goes back to what it was, or comes off if it wasn't
-- there, and each line it added comes out. A page the action brought into
-- being goes, unless something has been written to it since. Gives back
-- whether there was anything to take back.
function gm.revert(path, before, keys, items, created)
  if not gm.exists(path) then return false end
  local now = gm.read(path)
  if not before and now == created then
    space.deletePage(path)
    return true
  end
  local text = now
  for _, key in ipairs(keys) do
    local was = before and gm.rawField(before, key)
    if was then
      text = gm.setFrontmatter(text, key, was)
    else
      text = gm.clearFrontmatter(text, key)
    end
  end
  for _, item in ipairs(items) do text = (gm.removeItem(text, item)) end
  gm.write(path, text)
  return true
end

-- The marks, with the state field each sets and how it reads once set.
-- `clears` is what an unmark takes off the record again.
gm.marks = {
  met = {
    field = "met", value = "true", session = "met_session",
    done = "Met in ", reveals = true,
    pick = "Met", ask = "Who did the party meet?",
    clears = { "met", "met_session" },
  },
  dead = {
    field = "status", value = "dead", session = "died_session",
    done = "Died in ", reveals = false,
    pick = "Dead", ask = "Who died?",
    clears = { "status", "died_session" },
  },
  visited = {
    field = "visited", value = "true", session = "visited_session",
    done = "Visited in ", reveals = true,
    pick = "Visited", ask = "Where did the party go?",
    clears = { "visited", "visited_session" },
  },
  -- A party can carry a thing before it knows what it is, so finding one
  -- offers to reveal its page instead of revealing it.
  found = {
    field = "found", value = "true", session = "found_session",
    done = "Found in ", reveals = false, offers = true,
    pick = "Found", ask = "What did the party find?",
    clears = { "found", "found_session", "found_in", "unit", "units", "uses", "uses_found" },
  },
  -- Planned before the session, so it stamps the session you are in: press
  -- Next session first, then plan into it.
  planned = {
    field = "planned", value = "true", session = "planned_session",
    done = "Planned for ", reveals = false, logs = "Planned", scoped = true,
    empty = "There are no scenes to plan.",
    pick = "Planned", ask = "Which scene do you expect them to reach?",
    clears = { "planned", "planned_session" },
  },
  -- A scene is played rather than discovered, so it keeps both ends: the
  -- session it opened in and the one it closed in, which are usually the
  -- same. `needs` means a scene can only be finished once it is started,
  -- and `logs` is the word its line takes in that session's own log.
  started = {
    field = "started", value = "true", session = "started_session",
    done = "Started in ", reveals = false, logs = "Started", scoped = true,
    empty = "There are no scenes to start.",
    pick = "Started", ask = "Which scene did they start?",
    -- unstarting a scene lets its finish go too, the way unmarking a find
    -- forgets its uses, so the two ends can never disagree
    clears = { "started", "started_session", "finished", "finished_session" },
  },
  finished = {
    field = "finished", value = "true", session = "finished_session",
    done = "Finished in ", reveals = false, logs = "Finished",
    needs = "started", scoped = true,
    empty = "No scene is open. Mark one started first.",
    pick = "Finished", ask = "Which scene did they finish?",
    clears = { "finished", "finished_session" },
  },
}

gm.markOrder = { "met", "dead", "visited", "found", "planned", "started", "finished" }

-- Whether a mark's prerequisite is recorded: a scene has to be started
-- before it can be finished. Marks without one are always allowed.
function gm.allows(page, mark, state)
  local needs = gm.marks[mark].needs
  if not needs then return true end
  local n = gm.marks[needs]
  return (state or gm.readState(page))[n.field] == n.value
end

-- Pages that can take a mark, unmarked first. If the adventure has no
-- People, Places or Factions folders at all, every adventure page can.
function gm.markable(mark)
  local m, all = gm.marks[mark], gm.adventurePages()
  local open, done, notes = {}, {}, {}
  for _, page in ipairs(all) do
    local kind = gm.kind(page)
    if kind and gm.kinds[kind][mark] and gm.allows(page, mark) then
      local state = gm.readState(page)
      if state[m.field] == m.value then
        done[#done + 1] = page
        notes[page] = m.done .. "session " .. (state[m.session] or "?")
      else
        open[#open + 1] = page
      end
    end
  end
  -- A space with no People, Places or Factions folders at all can mark
  -- any page; a space with no scenes simply has no scene to mark.
  if #open + #done == 0 and not m.scoped then return all, notes end
  for _, page in ipairs(done) do open[#open + 1] = page end
  return open, notes
end

-- Asks for one of `pages`; `notes` adds a description to some of them.
function gm.pick(label, help, pages, notes)
  if #pages == 0 then
    gm.notify("There are no pages to choose from", nil, "warning")
    return nil
  end
  local prefix = gm.config.adventureFolder
  local options = {}
  for i, page in ipairs(pages) do
    options[i] = {
      name = page:startsWith(prefix) and page:sub(#prefix + 1) or page,
      description = notes and notes[page] or nil,
      orderId = i,
    }
  end
  local choice = editor.filterBox(label, options, help, "Type to filter")
  if not choice then return nil end
  for i, option in ipairs(options) do
    if option.name == choice.name then return pages[i] end
  end
end

-- The open page if it is one of `pages`, otherwise one picked from them.
function gm.target(label, help, pages, notes)
  local current = editor.getCurrentPage()
  for _, page in ipairs(pages) do
    if page == current then return current end
  end
  return gm.pick(label, help, pages, notes)
end

-- A mark's line in its session's own log, worked out before anything is
-- written, so a read that fails stops the mark before any of it happens.
-- A mark with no `logs` has no line.
function gm.logPlan(m, s, page, what)
  if not m.logs then return nil end
  local log = gm.config.sessionsFolder .. "Session " .. s
  local existed = gm.exists(log)
  return {
    log = log, session = s, existed = existed,
    text = existed and gm.read(log) or gm.sessionTemplate(s),
    item = (what or m.logs) .. ": [[" .. page .. "|" .. gm.sceneTitle(page) .. "]]",
  }
end

-- Writes the line a plan worked out, and gives the plan back: it is what
-- Undo needs to take that line out again.
function gm.logged(plan)
  if not plan then return nil end
  gm.write(plan.log, gm.appendUnder(plan.text, "Scenes", plan.item))
  return plan
end

-- Takes a mark's line back out of a session's log, and nothing else, so a
-- decision or a scene logged after it stays. A log left with nothing but
-- its template goes, whichever action began it: GM Kit never keeps an
-- empty one.
function gm.unlogged(done)
  if not done or not gm.exists(done.log) then return end
  local text = gm.removeItem(gm.read(done.log), done.item)
  local function squeeze(t) return (t:gsub("%s+", " ")) end
  if squeeze(text) == squeeze(gm.sessionTemplate(done.session)) then
    space.deletePage(done.log)
  else
    gm.write(done.log, text)
  end
end

-- Records a mark. extra can add state fields, replace the log entry, and
-- add a note to the notification, as finding an item does for its uses.
function gm.mark(page, mark, detail, extra)
  extra = extra or {}
  local m, s = gm.marks[mark], gm.currentSession()
  local name, state = gm.name(page), gm.readState(page, true)
  if state[m.field] == m.value then
    gm.notify(name .. ": already recorded. " .. m.done .. "session " .. (state[m.session] or "?") .. ".")
    return false
  end
  if not gm.allows(page, mark, state) then
    gm.notify(name .. " hasn't been marked " .. m.needs .. " yet.")
    return false
  end
  local path = gm.statePath(page)
  local before = gm.exists(path) and space.readPage(path) or nil
  local entry = extra.entry or (mark == "dead" and "died" or mark)
  if detail and detail ~= "" then entry = entry .. " - " .. detail end
  local fields = { [m.field] = m.value, [m.session] = s }
  for k, v in pairs(extra.fields or {}) do fields[k] = v end
  local line = gm.sessionLink(s, true) .. ": " .. entry
  -- everything read before anything is written, so a read that fails
  -- stops the mark before any of it has happened
  local plan = gm.logPlan(m, s, page)
  local reveals = m.reveals and page:startsWith(gm.config.adventureFolder)
                  and not gm.isPrivate(page)
  local _, written = gm.recordState(page, fields, line)
  local created = not before and written or nil
  local logged = gm.logged(plan)
  local revealed = reveals and gm.setRevealed(page, true)
  gm.refresh()
  local actions = {}
  if m.offers and page:startsWith(gm.config.adventureFolder) and not gm.isRevealed(page) then
    actions[#actions + 1] = { name = "Reveal", run = function() gm.reveal(page) end }
  end
  -- Undo takes back this mark and nothing done since: another mark, a use
  -- or a decision on the same pages stays
  local keys = {}
  for k in pairs(fields) do keys[#keys + 1] = k end
  table.sort(keys)
  actions[#actions + 1] = { name = "Undo", run = function()
    gm.revert(path, before, keys, { line }, created)
    gm.unlogged(logged)
    if revealed then gm.setRevealed(page, false) end
    gm.refresh()
    gm.notify("Undone: " .. name .. " is no longer marked " .. mark)
  end }
  gm.notify(name .. ": " .. m.done:lower() .. "session " .. s .. (extra.note or "") ..
            (revealed and ", and revealed" or "") .. ".", actions)
  return true
end

-- Takes a mark off again, for one recorded by mistake, with Undo. The log
-- keeps both lines. An item's uses go with its find, so finding it again
-- counts them afresh from the page that hands it out.
function gm.unmark(page, mark)
  local m, s = gm.marks[mark], gm.currentSession()
  local name, path = gm.name(page), gm.statePath(page)
  if gm.readState(page, true)[m.field] ~= m.value then
    gm.notify(name .. " isn't marked " .. mark)
    return false
  end
  local before = gm.read(path)
  local state = gm.readState(page, true)
  local alsoFinished = mark == "started" and state.finished == "true"
  local text = before
  for _, key in ipairs(m.clears) do text = gm.clearFrontmatter(text, key) end
  local was = gm.usesText(state, true)
  local line = gm.sessionLink(s, true) .. ": not " ..
               (mark == "dead" and "dead" or mark) .. " after all"
  local plan = gm.logPlan(m, s, page, "Not " .. mark .. " after all")
  gm.write(path, gm.appendItem(text, line))
  local logged = gm.logged(plan)
  gm.refresh()
  gm.notify(name .. ": no longer marked " .. mark ..
    ((mark == "found" and was ~= "") and ", and its uses with it" or "") ..
    (alsoFinished and ", and its finish with it" or "") .. ".", {
    { name = "Undo", run = function()
      -- the cleared fields come back as they were, and only this line goes;
      -- a record deleted since comes back whole, as it was before the unmark
      if not gm.revert(path, before, m.clears, { line }) then gm.write(path, before) end
      gm.unlogged(logged)
      gm.refresh()
      gm.notify("Undone: " .. name .. " is marked " .. mark .. " again")
    end },
  })
  return true
end

function gm.markDead(page)
  local state = gm.readState(page, true)
  if state.status == "dead" then return gm.mark(page, "dead") end
  local how = editor.prompt("How did " .. gm.name(page) .. " die? (optional)", "")
  if how == nil then return false end
  return gm.mark(page, "dead", how:match("^%s*(.-)%s*$"))
end

------------------------------------------------------------------ items

-- The adventure page a link in the adventure names: World/Items/Tube, a
-- path from this space's root, or a name that only one page ends with.
function gm.resolve(ref)
  ref = ref:match("^%s*(.-)%s*$"):gsub("%.md$", "")
  local prefix = gm.config.adventureFolder
  if gm.exists(prefix .. ref) then return prefix .. ref end
  if ref:startsWith(prefix) and gm.exists(ref) then return ref end
  local tail, found = "/" .. ref:lower(), nil
  for _, page in ipairs(gm.adventurePages()) do
    if ("/" .. page:lower()):endsWith(tail) then
      if found then return nil end
      found = page
    end
  end
  return found
end

local function int(n)
  return string.format("%d", n)
end

-- "a grin", "an arrow", "a use"
local function a(noun)
  local an = noun:match("^[aeiouAEIOU]") and not noun:match("^[uU][^aeiouAEIOU][aeiouAEIOU]")
  return (an and "an " or "a ") .. noun
end

-- What a page hands out: each GM Party count on it that names an item, as
-- { item, page, count, text, unit, units, at }, with the count for the
-- party as it is now. The count is read by running the expression with a
-- stand-in for party.count that keeps the rule it is given.
function gm.handouts(page, text)
  local out = {}
  text = text or (gm.exists(page) and space.readPage(page)) or ""
  if not (party and party.value) or not text:find("item%s*=") then return out end
  local nodes = {}
  local function walk(node)
    if node.type == "LuaDirective" then
      nodes[#nodes + 1] = node
    elseif node.children then
      for _, child in ipairs(node.children) do walk(child) end
    end
  end
  walk(markdown.parseMarkdown(text))
  for _, node in ipairs(nodes) do
    local src = text:sub(node.from + 3, node.to - 1)
    if src:match("^%s*party%.count%s*[{(]") and src:find("item%s*=") then
      local rules = {}
      local stand = setmetatable({
        count = function(spec)
          rules[#rules + 1] = spec
          return ""
        end,
      }, { __index = party })
      pcall(function()
        spacelua.evalExpression(spacelua.parseExpression(src), { party = stand })
      end)
      for _, spec in ipairs(rules) do
        local item = type(spec) == "table" and type(spec.item) == "string" and gm.resolve(spec.item)
        local ok, count = pcall(party.value, spec)
        local shown, face = pcall(party.count, spec)
        if item and ok and shown then
          out[#out + 1] = {
            item = item, page = page, count = count, text = face.markdown, at = node.from,
            unit = spec[1], units = spec[2] or party.plural(spec[1]),
          }
        end
      end
    end
  end
  return out
end

-- The items a page shows part of with ![[...]], such as their rules.
function gm.transcludedItems(text)
  local out, at, fence = {}, 0, nil
  if not text:find("![[", 1, true) then return out end
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    local mark = line:sub(1, 3)
    if fence then
      if mark == fence then fence = nil end
    elseif mark == "```" or mark == "~~~" then
      fence = mark
    else
      for ref in (line:gsub("`[^`]*`", "")):gmatch("!%[%[([^%]|#]+)") do
        local item = gm.resolve(ref)
        if item and gm.kind(item) == "Items" then out[#out + 1] = { item = item, at = at } end
      end
    end
    at = at + #line + 1
  end
  return out
end

-- The items a page hands out or shows, in page order and not counting the
-- page itself, and what the page hands out of each.
function gm.itemsOn(page)
  if not gm.exists(page) then return {}, {} end
  local text = space.readPage(page)
  local all, given = {}, {}
  for _, h in ipairs(gm.handouts(page, text)) do
    all[#all + 1] = h
    given[h.item] = given[h.item] or h
  end
  for _, t in ipairs(gm.transcludedItems(text)) do all[#all + 1] = t end
  table.sort(all, function(x, y) return x.at < y.at end)
  local items, seen = {}, { [page] = true }
  for _, x in ipairs(all) do
    if not seen[x.item] then
      seen[x.item] = true
      items[#items + 1] = x.item
    end
  end
  return items, given
end

-- Every page that hands an item out, first by page name.
function gm.handoutsOf(item)
  local out = {}
  for _, page in ipairs(gm.adventurePages()) do
    local text = space.readPage(page)
    if text:find("item%s*=") then
      for _, h in ipairs(gm.handouts(page, text)) do
        if h.item == item then
          out[#out + 1] = h
          break
        end
      end
    end
  end
  return out
end

-- Marks an item found. Its uses start at the count on the page it was found
-- on: `from`, if that page hands it out; else the one page that does, or the
-- one picked when several do. Nothing handing it out, it has no uses.
function gm.markFound(item, from)
  if gm.readState(item, true).found == "true" then return gm.mark(item, "found") end
  local choices = {}
  if from then
    for _, h in ipairs(gm.handouts(from)) do
      if h.item == item then
        choices[1] = h
        break
      end
    end
  end
  if #choices == 0 then choices = gm.handoutsOf(item) end
  local h = choices[1]
  if #choices > 1 then
    local pages, notes = {}, {}
    for i, c in ipairs(choices) do
      pages[i] = c.page
      notes[c.page] = c.text
    end
    local page = gm.pick("Found", "Where did the party find " .. gm.name(item) .. "?", pages, notes)
    if not page then return false end
    for _, c in ipairs(choices) do
      if c.page == page then h = c end
    end
  end
  if not h then return gm.mark(item, "found") end
  return gm.mark(item, "found", nil, {
    fields = {
      uses = int(h.count), uses_found = int(h.count), unit = h.unit, units = h.units,
      found_in = '"[[' .. h.page .. ']]"',
    },
    entry = "found in [[" .. h.page .. "]], with " .. h.text,
    note = ", with " .. h.text,
  })
end

-- "●●●●○○ 4 of 6 grins left" from a state record or a query's page, or ""
-- for an item without uses. plain leaves out the pips.
function gm.usesText(state, plain)
  local uses, top = tonumber(state.uses), tonumber(state.uses_found)
  if not uses then return "" end
  local one, many = state.unit or "use", state.units or "uses"
  local text
  if top then
    text = int(uses) .. " of " .. int(top) .. " " .. (top == 1 and one or many) .. " left"
  else
    text = int(uses) .. " " .. (uses == 1 and one or many) .. " left"
  end
  if not plain and top and top <= 12 and uses <= top then
    text = string.rep("●", uses) .. string.rep("○", top - uses) .. " " .. text
  end
  return text
end

-- Spends one of an item's uses (delta -1) or refunds one (+1), with Undo.
function gm.spend(item, delta)
  local name, state = gm.name(item), gm.readState(item, true)
  local uses, top = tonumber(state.uses), tonumber(state.uses_found)
  if state.found ~= "true" or not uses then
    gm.notify(name .. " has no uses to count", nil, "warning")
    return false
  end
  local unit, units = state.unit or "use", state.units or "uses"
  local after = uses + delta
  if after < 0 then
    gm.notify(name .. ": no " .. units .. " left")
    return false
  end
  if top and after > top then
    gm.notify(name .. ": all " .. int(top) .. " " .. (top == 1 and unit or units) .. " are there already")
    return false
  end
  local path, s = gm.statePath(item), gm.currentSession()
  local before = gm.read(path)
  local what = a(unit) .. (delta < 0 and " used" or " refunded")
  local text = gm.setFrontmatter(before, "uses", int(after))
  local line = gm.sessionLink(s, true) .. ": " .. what .. ", " .. int(after) .. " left"
  gm.write(path, gm.appendItem(text, line))
  gm.refresh()
  gm.notify(name .. ": " .. what .. ". " .. gm.usesText(gm.readState(item, true), true) .. ".", {
    { name = "Undo", run = function()
      -- one use back the other way, counted from what is left now, so a use
      -- or refund made since this one stays made
      if not gm.exists(path) then return end
      local now = gm.read(path)
      local left, most = tonumber(gm.frontmatter(now).uses), tonumber(gm.frontmatter(now).uses_found)
      if left then
        left = left - delta
        if left < 0 then left = 0 end
        if most and left > most then left = most end
        now = gm.setFrontmatter(now, "uses", int(left))
      end
      gm.write(path, (gm.removeItem(now, line)))
      gm.refresh()
      gm.notify("Undone: " .. name .. " is back to " .. gm.usesText(gm.readState(item, true), true))
    end },
  })
  return true
end

-- The found items a use can come off (spend) or go back to (refund).
function gm.withUses(refund)
  local pages, notes = {}, {}
  for _, page in ipairs(gm.adventurePages()) do
    if gm.kind(page) == "Items" then
      local state = gm.readState(page)
      local uses, top = tonumber(state.uses), tonumber(state.uses_found)
      if state.found == "true" and uses and (refund and (not top or uses < top) or (not refund and uses > 0)) then
        pages[#pages + 1] = page
        notes[page] = gm.usesText(state, true)
      end
    end
  end
  return pages, notes
end

-- The item a command acts on: the open page if it is one of `pages`, the
-- one of them the open page has a row for, or one picked. Also returns the
-- open page when the item came off its rows, so finding it there takes
-- that page's count.
function gm.pickItem(label, help, pages, notes)
  local current, allowed = editor.getCurrentPage(), {}
  for _, page in ipairs(pages) do
    if page == current then return current end
    allowed[page] = true
  end
  if gm.isAdventurePage(current) then
    local here = {}
    for _, item in ipairs((gm.itemsOn(current))) do
      if allowed[item] then here[#here + 1] = item end
    end
    if #here == 1 then return here[1], current end
    if #here > 1 then
      local item = gm.pick(label, help, here, notes)
      return item, item and current or nil
    end
  end
  return gm.pick(label, help, pages, notes)
end

-- What the notification says of a private page, for reveal and publish.
local function privateNote(page)
  return gm.name(page) .. " is a " .. tostring(gm.pageType(page)) ..
    " page, which keeps what only the DM may see in the page itself, so it is " ..
    "never revealed or published. The players see what a page they have shows of it."
end

function gm.reveal(page)
  if gm.isPrivate(page) then
    gm.notify(privateNote(page), nil, "warning")
    return false
  end
  if not gm.setRevealed(page, true) then
    gm.notify(gm.name(page) .. " is already revealed")
    return false
  end
  gm.refresh()
  gm.notify("Revealed " .. gm.name(page) .. ". The players see it once you publish.", {
    { name = "Publish now", run = function() gm.publish() end },
    { name = "Undo", run = function()
      gm.setRevealed(page, false)
      gm.refresh()
    end },
  })
  return true
end

-- Whether the players can see a page: "published" (revealed, and they have
-- their copy), "revealed" (on the list, not published yet), "stale" (off the
-- list, but they still have a copy) or "hidden".
function gm.visibility(page)
  local copy = gm.playerCopy(page)
  local has = copy ~= nil and gm.seen(copy)
  if gm.isRevealed(page) then
    return has and "published" or "revealed"
  end
  return has and "stale" or "hidden"
end

-- Takes a page back from the players: off the revealed list, and the copy
-- they were sent deleted. Undo puts both back.
function gm.unreveal(page)
  local name, copy = gm.name(page), gm.playerCopy(page)
  local copyText = copy and gm.exists(copy) and space.readPage(copy) or nil
  local listed = gm.setRevealed(page, false)
  if not listed and not copyText then
    gm.notify(name .. " isn't revealed, and the players have no copy of it")
    return false
  end
  if copyText then space.deletePage(copy) end
  gm.refresh()
  local message
  if listed and copyText then
    message = "Unrevealed " .. name .. ": it's off the revealed list, and the players' copy is deleted."
  elseif listed then
    message = "Unrevealed " .. name .. ". It was never published, so the players never had it."
  else
    message = "Deleted the players' copy of " .. name .. ", which wasn't revealed any more."
  end
  -- a private page is taken back for good: an Undo would hand the players
  -- the DM's layer again
  if gm.isPrivate(page) then
    gm.notify(message)
    return true
  end
  gm.notify(message, {
    { name = "Undo", run = function()
      if listed then gm.setRevealed(page, true) end
      if copyText then gm.write(copy, copyText) end
      gm.refresh()
      gm.notify("Undone: " .. name .. (copyText and " is back with the players" or " is revealed again"))
    end },
  })
  return true
end

-- The name before 2.4.
function gm.hide(page)
  return gm.unreveal(page)
end

function gm.publish()
  local pages, missing, private = {}, {}, {}
  for _, page in ipairs(gm.readRevealed()) do
    if gm.playerCopy(page) then
      if not gm.exists(page) then
        missing[#missing + 1] = page
      elseif gm.isPrivate(page) then
        private[#private + 1] = page
      else
        pages[#pages + 1] = page
      end
    end
  end
  -- A private page is never published. One on the list, from before GM Kit
  -- refused them, is named. One the players still have a copy of, on the
  -- list or not, is named with how to take it back, since publishing never
  -- deletes anything.
  local seen, leaked = {}, {}
  for _, page in ipairs(private) do seen[page] = true end
  for page in pairs(gm.privatePages()) do seen[page] = true end
  local all = {}
  for page in pairs(seen) do all[#all + 1] = page end
  table.sort(all)
  for _, page in ipairs(all) do
    local copy = gm.playerCopy(page)
    if copy and gm.exists(copy) then leaked[#leaked + 1] = page end
  end
  local held = ""
  if #private > 0 then
    held = " Left out, as only the DM may see them: " .. table.concat(private, ", ") .. "."
  end
  if #leaked > 0 then
    held = held .. " The players still have a copy of " .. table.concat(leaked, ", ") ..
           ", sent before such pages were kept to the DM: take it back with" ..
           " Delete their copy on its bar."
  end
  if #pages == 0 then
    if held ~= "" then
      gm.notify("Nothing to publish." .. held, nil, "warning")
    else
      gm.notify("Nothing is revealed yet, so there is nothing to publish", nil, "warning")
    end
    return false
  end
  local folder = gm.config.playerFolder
  if not editor.confirm("Publish " .. #pages ..
      (#pages == 1 and " revealed page" or " revealed pages") ..
      " to the players? Each replaces its earlier copy in " .. folder .. ", and " ..
      folder .. gm.config.playerNotes .. " is never touched.") then
    return false
  end
  local added, updated, same = 0, 0, 0
  for _, page in ipairs(pages) do
    local copy = gm.playerCopy(page)
    local text = gm.print(gm.stripSecrets(space.readPage(page)), page)
    if not gm.exists(copy) then
      gm.write(copy, text)
      added = added + 1
    elseif space.readPage(copy) ~= text then
      gm.write(copy, text)
      updated = updated + 1
    else
      same = same + 1
    end
  end
  local message = "Published to players: " .. added .. " new, " .. updated ..
                  " updated, " .. same .. " unchanged."
  local kind = "info"
  if #missing > 0 then
    kind = "warning"
    message = message .. " Revealed but no longer there: " ..
              table.concat(missing, ", ") .. "."
  end
  if held ~= "" then
    kind = "warning"
    message = message .. held
  end
  gm.notify(message, nil, kind)
  return true
end

function gm.logDecision()
  local s = gm.currentSession()
  local what = editor.prompt("What did they decide? (session " .. s .. ")")
  what = what and what:match("^%s*(.-)%s*$") or ""
  if what == "" then return false end
  local log, text = gm.sessionLog(s)
  gm.write(log, gm.appendUnder(text, "Decisions", what))
  gm.refresh()
  gm.notify("Logged to " .. log, {
    { name = "Open log", run = function() editor.navigate(log) end },
  })
  return true
end

function gm.nextSession()
  local page, n = gm.config.sessionPage, gm.currentSession()
  if not editor.confirm("Start session " .. (n + 1) .. "? From now on, marks and " ..
      "decisions are recorded against it.") then
    return false
  end
  gm.patch(page, "session", n + 1)
  gm.refresh()
  gm.notify("Now session " .. (n + 1), {
    { name = "Undo", run = function()
      gm.patch(page, "session", n)
      gm.refresh()
      gm.notify("Back to session " .. n)
    end },
  })
  return true
end

function gm.button(label, run, primary)
  return dom.button {
    class = primary and "sb-button-primary" or "sb-button",
    onclick = function()
      local ok, err = pcall(run)
      if not ok then editor.flashNotification("GM Kit: " .. tostring(err), "error") end
    end,
    label,
  }
end

-- An item's uses, and the buttons to spend and refund one, added to a bar.
local function usesParts(item, state, add, note)
  local uses, top = tonumber(state.uses), tonumber(state.uses_found)
  if state.found ~= "true" or not uses then return end
  local unit = state.unit or "use"
  note(gm.usesText(state))
  if uses > 0 then add(gm.button("Use " .. a(unit), function() gm.spend(item, -1) end)) end
  if not top or uses < top then
    add(gm.button("Refund " .. a(unit), function() gm.spend(item, 1) end))
  end
end

-- What the players can see of a page, with the buttons that change it.
-- `quiet` leaves out the states where they can see it.
local function visibilityParts(page, add, note, quiet)
  local seen = gm.visibility(page)
  -- a private page is never offered to the players; a copy or a place on
  -- the list from before it could be refused is offered for taking back
  if gm.isPrivate(page) then
    if seen == "hidden" then
      note("⊘ Only for the DM: never revealed")
    elseif seen == "revealed" then
      note("⊘ Only for the DM, but on the revealed list")
      add(gm.button("Unreveal", function() gm.unreveal(page) end))
    else
      note("◐ Only for the DM, but the players have a copy")
      add(gm.button("Delete their copy", function() gm.unreveal(page) end))
    end
    return
  end
  if seen == "stale" then
    note("◐ Not revealed, but the players still have a copy")
    add(gm.button("Delete their copy", function() gm.unreveal(page) end))
    add(gm.button("Reveal", function() gm.reveal(page) end))
  elseif seen == "hidden" then
    note("○ Hidden from players")
    add(gm.button("Reveal", function() gm.reveal(page) end))
  elseif not quiet then
    note(seen == "published" and "◉ Revealed to players" or "◉ Revealed, not published yet")
    add(gm.button("Unreveal", function() gm.unreveal(page) end))
  end
end

-- A scene's play on its bar: the session it was played in, the sessions it
-- ran across, or that it is still going, with the button that moves it on.
-- The two ends are drawn together, since "Started in session 1, finished in
-- session 1" is a long way of saying one thing.
local function scenePlayParts(page, state, add, note)
  local standing = gm.playedText(state)
  -- three shapes as well as three words, so the three states stay apart
  -- for a reader who doesn't see the colour of them
  if standing ~= "" then
    local glyph = "◇ "
    if state.finished == "true" then glyph = "✓ "
    elseif state.started == "true" then glyph = "▶ " end
    note(glyph .. standing)
  end
  if state.started ~= "true" then
    if state.planned ~= "true" then
      add(gm.button("Mark planned", function() gm.mark(page, "planned") end))
    end
    add(gm.button("Mark started", function() gm.mark(page, "started") end))
    if state.planned == "true" then
      add(gm.button("Unmark planned", function() gm.unmark(page, "planned") end))
    end
  elseif state.finished ~= "true" then
    add(gm.button("Mark finished", function() gm.mark(page, "finished") end))
    add(gm.button("Unmark started", function() gm.unmark(page, "started") end))
  else
    add(gm.button("Unmark finished", function() gm.unmark(page, "finished") end))
  end
end

-- A row on a page's bar for an item the page hands out or shows: found or
-- not, the uses left, and whether the players can see the item's page.
function gm.itemRow(item, from, handout)
  local state = gm.readState(item)
  local spec = { class = "gmkit-item" }
  local function add(x) spec[#spec + 1] = x end
  local function note(text) add(dom.span { class = "gmkit-bar-note", text }) end
  note("**[[" .. item .. "|" .. gm.name(item) .. "]]**")
  if state.found == "true" then
    note("✓ Found in " .. gm.sessionLink(state.found_session))
    usesParts(item, state, add, note)
    add(gm.button("Unmark found", function() gm.unmark(item, "found") end))
    visibilityParts(item, add, note, true)
  else
    if handout then note(handout.text .. " here") end
    add(gm.button("Mark found", function() gm.markFound(item, from) end))
  end
  return dom.div(spec)
end

-- Previous, current and next scene, for the top of a session's own notes:
-- "← The Field · Scene 2 — The Road, and the Town · Off the Road →". The
-- order is the adventure's, so the next scene can be the next act's first.
function gm.sessionNav(page)
  if not gm.exists(page) then return nil end
  local here = gm.sessionScene(gm.frontmatter(space.readPage(page)).session)
  if not here then return nil end
  local scenes, at = gm.scenes(), nil
  for i, name in ipairs(scenes) do
    if name == here then at = i end
  end
  if not at then return nil end
  local function link(name, before, after)
    return "[[" .. name .. "|" .. (before or "") .. gm.sceneTitle(name) .. (after or "") .. "]]"
  end
  local parts = {}
  if at > 1 then parts[#parts + 1] = link(scenes[at - 1], "← ") end
  parts[#parts + 1] = "**" .. link(here) .. "**"
  if at < #scenes then parts[#parts + 1] = link(scenes[at + 1], nil, " →") end
  return table.concat(parts, " · ")
end

-- A session's log gets that bar instead of an adventure page's, so the
-- page you write in during play is one click from the scene you are on.
function gm.sessionBar(page)
  page = page or editor.getCurrentPage()
  if not page or not page:startsWith(gm.config.sessionsFolder) then return nil end
  if gm.pageType(page) ~= gm.config.sessionType then return nil end
  local nav = gm.sessionNav(page)
  if not nav then return nil end
  return widget.new {
    display = "block",
    html = dom.div { class = "gmkit-bar", dom.span { class = "gmkit-bar-note", nav } },
  }
end

-- The bar across the top of an adventure page: what the players can see,
-- what the party has done, and a button for each thing not yet recorded.
function gm.bar(page)
  page = page or editor.getCurrentPage()
  if not gm.isAdventurePage(page) then return nil end
  local kind = gm.kind(page)
  local can = kind and gm.kinds[kind] or {}
  local state = gm.readState(page)
  local spec = {
    class = "gmkit-bar",
    dom.strong { "Session " .. gm.currentSession() },
  }
  local function add(item) spec[#spec + 1] = item end
  local function note(text) add(dom.span { class = "gmkit-bar-note", text }) end
  visibilityParts(page, add, note)
  local scene = can.started == true
  if scene then scenePlayParts(page, state, add, note) end
  -- what is recorded, then what to do about it, so an unmark sits after the
  -- uses of a find rather than between them
  local recorded = {}
  for _, mark in ipairs(gm.markOrder) do
    local m = gm.marks[mark]
    if can[mark] and not scene then
      if state[m.field] == m.value then
        note((mark == "dead" and "† " or "✓ ") .. m.done .. gm.sessionLink(state[m.session]))
        recorded[#recorded + 1] = mark
      elseif mark == "dead" then
        add(gm.button("Mark dead…", function() gm.markDead(page) end))
      elseif mark == "found" then
        add(gm.button("Mark found", function() gm.markFound(page) end))
      else
        add(gm.button("Mark " .. mark, function() gm.mark(page, mark) end))
      end
    end
  end
  if can.found then usesParts(page, state, add, note) end
  for _, mark in ipairs(recorded) do
    add(gm.button("Unmark " .. mark, function() gm.unmark(page, mark) end))
  end
  if gm.seen(gm.statePath(page)) then
    note("[[" .. gm.statePath(page) .. "|Play state]]")
  end
  local items, given = gm.itemsOn(page)
  for _, item in ipairs(items) do add(gm.itemRow(item, page, given[item])) end
  return widget.new { display = "block", html = dom.div(spec) }
end
```

```space-lua
-- priority: 10
local function markCommand(mark)
  return function()
    local m = gm.marks[mark]
    local pages, notes = gm.markable(mark)
    if #pages == 0 and m.empty then
      gm.notify(m.empty)
      return
    end
    local page = gm.target(m.pick, m.ask .. " Recorded for session " ..
                           gm.currentSession() .. ".", pages, notes)
    if not page then return end
    if mark == "dead" then gm.markDead(page) else gm.mark(page, mark) end
  end
end

command.define {
  name = "GM: Session Table",
  run = function() editor.navigate(gm.config.sessionPage) end
}

command.define {
  name = "GM: Reveal Page",
  run = function()
    local page = editor.getCurrentPage()
    if not gm.isAdventurePage(page) then
      local revealed, hidden, private = {}, {}, gm.privatePages()
      for _, n in ipairs(gm.readRevealed()) do revealed[n] = true end
      for _, n in ipairs(gm.adventurePages()) do
        if not revealed[n] and not private[n] then hidden[#hidden + 1] = n end
      end
      page = gm.pick("Reveal", "Which page have the players learned about?", hidden)
    end
    if page then gm.reveal(page) end
  end
}

-- The open adventure page, or one picked from those the players can see or
-- still have a copy of.
local function unrevealCommand()
  local page = editor.getCurrentPage()
  if not gm.isAdventurePage(page) then
    local pages, notes, listed = {}, {}, {}
    local function hasCopy(n)
      local copy = gm.playerCopy(n)
      return copy ~= nil and gm.seen(copy)
    end
    for _, n in ipairs(gm.readRevealed()) do
      pages[#pages + 1] = n
      listed[n] = true
      notes[n] = hasCopy(n) and "Published" or "Revealed, not published yet"
    end
    for _, n in ipairs(gm.adventurePages()) do
      if not listed[n] and hasCopy(n) then
        pages[#pages + 1] = n
        notes[n] = "Not revealed, but the players still have a copy"
      end
    end
    page = gm.pick("Unreveal", "Which page should the players lose?", pages, notes)
  end
  if page then gm.unreveal(page) end
end

command.define {
  name = "GM: Unreveal Page",
  run = unrevealCommand
}

-- The name before 2.4, so buttons made with it still work.
command.define {
  name = "GM: Hide Page",
  hide = true,
  run = unrevealCommand
}

command.define {
  name = "GM: Publish to Players",
  run = function() gm.publish() end
}

command.define {
  name = "GM: Mark Met",
  key = "Ctrl-Alt-m",
  run = markCommand("met")
}

command.define {
  name = "GM: Mark Dead",
  run = markCommand("dead")
}

command.define {
  name = "GM: Mark Visited",
  run = markCommand("visited")
}

command.define {
  name = "GM: Mark Found",
  run = function()
    local pages, notes = gm.markable("found")
    local page, from = gm.pickItem("Found", "What did the party find? Recorded for session " ..
                                   gm.currentSession() .. ".", pages, notes)
    if page then gm.markFound(page, from) end
  end
}

command.define {
  name = "GM: Mark Scene Planned",
  run = markCommand("planned")
}

command.define {
  name = "GM: Mark Scene Started",
  run = markCommand("started")
}

command.define {
  name = "GM: Mark Scene Finished",
  run = markCommand("finished")
}

local function useCommand(refund)
  return function()
    local pages, notes = gm.withUses(refund)
    if #pages == 0 then
      gm.notify(refund and "Nothing the party found is missing a use" or
                "Nothing the party found has a use left")
      return
    end
    local item = gm.pickItem(refund and "Refund" or "Use", refund and
      "Which item gets a use back?" or "Which item did they use? Recorded for session " ..
      gm.currentSession() .. ".", pages, notes)
    if item then gm.spend(item, refund and 1 or -1) end
  end
end

command.define {
  name = "GM: Spend Use",
  run = useCommand(false)
}

command.define {
  name = "GM: Refund Use",
  run = useCommand(true)
}

command.define {
  name = "GM: Unmark",
  run = function()
    local pages, notes, marked = {}, {}, {}
    for _, page in ipairs(gm.adventurePages()) do
      local kind = gm.kind(page)
      local can = kind and gm.kinds[kind] or {}
      local state, mine, said = gm.readState(page), {}, {}
      for _, mark in ipairs(gm.markOrder) do
        local m = gm.marks[mark]
        if can[mark] and state[m.field] == m.value then
          mine[#mine + 1] = mark
          said[#said + 1] = m.done .. "session " .. (state[m.session] or "?")
        end
      end
      if #mine > 0 then
        pages[#pages + 1] = page
        marked[page] = mine
        notes[page] = table.concat(said, ", ")
      end
    end
    if #pages == 0 then
      gm.notify("Nothing is marked yet")
      return
    end
    local page = gm.target("Unmark", "What was marked by mistake?", pages, notes)
    if not page then return end
    local mine = marked[page]
    local mark = mine[1]
    if #mine > 1 then
      local options = {}
      for i, name in ipairs(mine) do options[i] = { name = name, orderId = i } end
      local choice = editor.filterBox("Unmark", options,
        "Which mark comes off " .. gm.name(page) .. "?", "Type to filter")
      if not choice then return end
      mark = choice.name
    end
    gm.unmark(page, mark)
  end
}

command.define {
  name = "GM: Log Decision",
  key = "Ctrl-Alt-d",
  run = function() gm.logDecision() end
}

command.define {
  name = "GM: Next Session",
  run = function() gm.nextSession() end
}

actionButton.define {
  icon = "clipboard",
  description = "Session table",
  command = "GM: Session Table",
  priority = 0.9,
}

actionButton.define {
  icon = "edit-3",
  description = "Log a decision",
  command = "GM: Log Decision",
  priority = 0.8,
}

actionButton.define {
  icon = "send",
  description = "Publish revealed pages to players",
  command = "GM: Publish to Players",
  priority = 0.7,
}

event.listen {
  name = "hooks:renderTopWidgets",
  run = function()
    local ok, bar = pcall(function() return gm.sessionBar() or gm.bar() end)
    if ok then return bar end
    print("GM Kit: " .. tostring(bar))
  end
}
```

```space-style
.gmkit-bar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px 10px;
}

/* A row of its own for each item the page hands out or shows. */
.gmkit-item {
  flex: 1 0 100%;
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 6px 10px;
  padding-top: 6px;
  border-top: 1px solid var(--editor-widget-background-color);
}

/* The widget's own Copy and Reload overlay would cover the bar's buttons. */
.sb-lua-top-widget:has(.gmkit-bar) .button-bar {
  display: none !important;
}

/* DM-only text, where it sits on the page. The words and the icon say what
   the players won't get, so the colour is never the only sign of it. */
.sb-admonition[admonition="dm" i] {
  --admonition-icon: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path><line x1="1" y1="1" x2="23" y2="23"></line></svg>');
  --admonition-color: #8e5bd6;
}

.sb-admonition[admonition="dm" i] .sb-admonition-type::before {
  width: var(--admonition-width) !important;
}

.sb-admonition[admonition="dm" i] .sb-admonition-type * {
  display: none;
}

.sb-admonition[admonition="dm" i] .sb-admonition-type::after {
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
```
