---
tags: meta/library
name: "Library/Storie/GM Kit"
description: "Session tracking and fog-of-war publishing for tabletop RPG campaigns. Keeps play state out of your adventure pages so the adventure stays publishable."
author: "Steven Storie"
version: "3.8.0"
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

**The GM bar.** In the DM space, every adventure page gets a bar across the top. It shows whether the players can see the page, with buttons to reveal it, or part of it, or take it back: ◉ revealed and published, ◉ revealed but not published yet, ◔ revealed in part, ○ hidden, or ⊘ never published, for a map or a page whose name is DM-only. Once a page is published it says when the players' copy has fallen behind: "◔ 1 part not published yet", "◔ Whole page not published yet", or "◐ Changed since publishing", for a page saved since or a part taken back since. A person adds *Mark met* and *Mark dead…*, a faction adds *Mark met*, a place adds *Mark visited*, an item adds *Mark found*, and a scene adds *Mark planned* and *Mark started*, then *Mark finished*. Once something is recorded, the bar says when, with the session linked to its log: "✓ Met in session 3", and a button takes the mark off again for one recorded by mistake. An item with uses shows how many are left, with buttons to use one and to refund one. A page that hands out an item, or shows its rules, gets a row for that item as well: see *Items*. A page that sets checks gets a row of them, with *Log a roll…*: see *Rolls*.

**A session's own notes.** A page in `Sessions/` gets a bar of its own instead: the scene before, the scene the session is on, and the scene after. See *Scenes*. A session's recap draft gets one that says whether the players have it, with the button that sends it: see *The players' recap*.

**The header.** Five buttons: the session table, *Log a decision*, *Log a roll*, *Preview publishing* (an eye) and *Publish to players*.

**Notifications.** Marking, unmarking, revealing, unrevealing, logging a roll and starting a session each come with *Undo*. A reveal also offers *Publish now* and *Preview*, and a publish *Open report*. *Undo* takes back what its own action did and nothing else, so a mark, a use, a decision or a reveal made since stays made: undoing the reveal of one part leaves a part revealed after it. It only lives as long as the notification; afterwards *Unmark* is what takes a mark off.

**Taking a page back.** *Unreveal* takes a page off the revealed list and deletes the copy the players were sent, so a page revealed or published by mistake is gone from the Player space at once. *Undo* puts both back, and so does revealing it and publishing again. A page that isn't revealed but that the players still have a copy of, say one hidden before 2.4, shows ◐ on its bar, with *Delete their copy*.

**Your own pages.** Every command works as a button, and a command that acts on a page asks which one when you aren't on one:

    ${widgets.commandButton("Met…", "GM: Mark Met")}
    ${widgets.commandButton("Log a decision", "GM: Log Decision")}

## Commands

| Command | Key | Does |
|---|---|---|
| `GM: Session Table` | | Opens the session page |
| `GM: Mark Met` | `Ctrl-Alt-m` | Records that the party met a person or faction, stamps the session, and reveals what the page shows first |
| `GM: Mark Dead` | | Records a death and how it happened |
| `GM: Mark Visited` | | Records that the party visited a place, and reveals what the page shows first |
| `GM: Mark Found` | | Records that the party found an item, starts counting its uses, and offers to reveal it |
| `GM: Mark Scene Planned` | | Records a scene you expect the party to reach this session |
| `GM: Mark Scene Started` | | Opens a scene at the table |
| `GM: Mark Scene Finished` | | Closes it, in this session or a later one |
| `GM: Unmark` | | Takes a mark off again: met, dead, visited or found, and an item's uses with its find; started, and its finish with it |
| `GM: Spend Use` | | Uses one of an item's uses |
| `GM: Refund Use` | | Gives one back |
| `GM: Reveal Page` | | Adds an adventure page to the revealed list |
| `GM: Reveal Part` | | Adds one section of a page to the revealed list |
| `GM: Unreveal Page` | | Takes a page back: off the revealed list, and the players' copy deleted |
| `GM: Publish to Players` | | Copies every revealed page into the Player space, leaving out its DM-only text, and names the pages it keeps back: one whose name is DM-only, or whose copy would be empty or still holds a DM-only mark. Keeps a report of what it did |
| `GM: Preview Publish` | | Works out what publishing would send, and shows it on a page of its own without sending anything |
| `GM: Log Decision` | `Ctrl-Alt-d` | Appends to this session's log |
| `GM: Log Roll` | `Ctrl-Alt-k` | Logs a roll against one of the page's checks, with the words of every rung it reached, into this session's log |
| `GM: Unlog Roll` | | Takes a roll off again, for one logged by mistake |
| `GM: Next Session` | | Increments the session counter |
| `GM: Draft Recap` | | Drafts the players' recap of a session from what GM Kit recorded in it, naming only what they may know |
| `GM: Publish Recap` | | Sends a recap draft to the players, as `Player/Sessions/Session N` |

On a person's page, `GM: Mark Met` marks that person. Anywhere else it opens a list of people and factions, with the ones already met at the bottom. The other marks work the same way, and so do reveal and unreveal on any adventure page; off one, `GM: Unreveal Page` lists what the players can see or still have. `GM: Hide Page`, its name before 2.4, still works. Found, use and refund also act at once on a page with a row for just one item. The scene marks work like the rest: on a scene page they mark that scene, and anywhere else they ask which. Publishing and starting a session ask first.

## A tab that is behind

A tab runs the Lua it loaded, and only *System: Reload* (`Ctrl-Alt-R`) runs the space's Lua again. Install a newer GM Kit, from this tab or on another device, and the tab indexes the new page at once while it still runs the old code, which could write the play state in a shape the new code doesn't read, or without a fix the new code makes. So a tab that is behind writes nothing. Every mark and unmark, use and refund, reveal and unreveal, publish and preview, roll, decision, recap and new session, and every *Undo*, stops before it asks anything, with a warning and a *Reload* button:

    This tab runs GM Kit 3.8.0, but the space has 3.9.0: reload it (System: Reload, Ctrl-Alt-R) first.

The bar says so first, with *Reload* beside it: "⟳ Reload this tab: GM Kit 3.9.0 is installed, this tab runs 3.8.0".

GM Kit finds its own page in the index by the end of its name, `Library/Storie/GM Kit`, so a copy in a space held as a folder counts as well, and a tab is behind when any copy's `version` differs from its own. `gm.version` is the version the tab runs, and `gm.stale()` says what to do, or gives `nil` while the tab is current. It is one question to the index, and never an error: an index it can't read says nothing. A button of your own that writes through GM Kit's own functions, `gm.write` or `gm.patch` say, can ask `gm.refuse()` first, which gives `true`, with the warning, on a tab that is behind.

## Items

An item is an adventure page in an `Items/` folder. Marking it found records the session but doesn't reveal the page, because a party can carry a thing before it knows what it is. The notification offers *Reveal*, and so does the item's row until you press it.

**Uses.** A page hands out an item when a GM Party count on it names the item:

    It holds ${party.count{"arrow", plus = 1, item = "World/Items/Quiver"}}.

That page's bar gets a row for the item, "Quiver: six arrows here", with *Mark found*. Found there, its uses start at that count for the party of the moment, and its rows and its own bar show what is left, "●●●●○○ 4 of 6 arrows left", with *Use an arrow* and *Refund an arrow*. Each has *Undo*. Marked found from its own page, an item takes the count of the page that hands it out, and asks where when several do. An item that nothing hands out is found without uses. *Unmark found* takes the find back, uses and all, so finding it again counts them afresh.

**Rules in a scene.** A page that shows an item's rules with `![[World/Items/Quiver#Rules]]` gets a row for it too, so wherever the rules are, the uses are.

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

## Rolls

A roll is logged against a check the page sets, so a session's notes say what the party rolled for and what it got them, in the adventure's own words. The page is only read: nothing is added to it.

**Writing a check.** A check is a paragraph that names one, *Wisdom (Perception)*, followed by what the roll gives, before the next check or heading. It can give it four ways:

- a table whose rows start with a rung: **Any roll**, **No roll**, **10**, **15 or better**;
- paragraphs that start with one, `At **15**,` or `**At 15**,`, where whatever comes between the check and the first of them is what any roll gets, or else the check's own paragraph;
- a table with a column for each rung and a row for each thing to find, `| They find | Any roll | 10 or better also gets |`, where each character rolls for a row;
- a DC and nothing more, *group Dexterity (Stealth), DC 12*, for a check that is passed or failed.

A ladder in a table reads like this:

    **Wisdom (Perception)** — what the bank gives you from the water.

    | | |
    |---|---|
    | **Any roll** | Bootprints in the mud, heading for the town |
    | **10** | One set is a child's |
    | **15** | The child was running |

Rungs count up, so a 15 gets what any roll gets, what 10 gets and what 15 gets. A check with none of these, *don't call for Wisdom (Survival) here*, is only mentioned, and isn't offered. Nor is anything in fenced code or an HTML comment.

**A DC that rises with the party.** A rung or a DC can be written through GM Party 1.3 or later, `**${party.dc(15)}**` or `DC ${party.dc(12)}`, so the page shows the party's DC. A check reads it as the number it is written as, and shows the party's DC wherever it gives one: at level 9 the bands are *Under 12*, *12 to 16*, *17 to 21* and *22 or more*. The play state keeps the rung as written, so a roll logged at one level still counts at the next.

**Logging one.** *Log a roll* in the header, `Ctrl-Alt-k`, or *Log a roll…* on the page's bar lists the checks on the page you are on, and off an adventure page those of the scene the session is on. Pick the check, then how high they rolled. The rungs make bands, *Under 10*, *10 to 14*, *15 to 19* and *20 or more*, and each band shows what it adds. A DC asks *Passed* or *Failed*, and a table of finds asks which thing first. Once there are character pages it asks who rolled, with *The party* first for the best roll at the table. A group check is everybody's, so it doesn't ask.

**What the log gets.** The session's log gets a line under `## Rolls`, which comes in ahead of `## Decisions`, with the words of every rung reached:

    ## Rolls

    - [[Campaign/Act I/Scene 4#The bank|Scene 4]] · Wisdom (Perception), 15 to 19:
      - Bootprints in the mud, heading for the town
      - One set is a child's
      - The child was running

A better roll later logs only what is new, "now 20 or more", and a roll that reaches nothing new says so. The page's links are written to work from the log, and its live values, a GM Party number say, go in as they read.

**Another roll.** Most rolls at a table aren't in the book. *Another roll…*, at the foot of the list, asks which skill, save or ability check, then what they got, in your words, and logs that.

**The bar.** A page that sets checks gets a row of them: "✓ Perception: 15 to 19", linked to the session it was rolled in, "✗ Stealth: failed", or "○ Investigation" for one nobody has rolled. A roll comes with *Undo*. Afterwards *Unlog a roll…* takes one off, for a roll logged by mistake: the logs say it was taken back, and the next roll counts afresh.

**Late, not lost.** A ladder only one character can roll often says what happens when nobody reaches its top rung, that it comes back later: *If nobody reaches the 20, it is late, not lost. The next time that character crosses running water, it comes back to them.* A roll below that rung then logs it as owed, with when it comes back:

    - [[Campaign/Act I/Scene 5#The weir|Scene 5]] · Intelligence (Arcana), 10 to 19:
      - Something old holds the water back
      - It was made, not grown
      - Owed: the 20, late, not lost. The next time that character crosses running water, it comes back to them.

The page's bar says "· 20 owed", the picker marks the band owed, and `${gm.owed()}` on your session page lists every rung owed, in the order the adventure is played, until a roll that reaches it is logged. The words it looks for are `gm.config.latePhrases`: *late, not lost* and *late and not lost*.

## Revealing part of a page

Players rarely learn all of a page at once. They meet the Warden and see a tall figure in a grey coat; what the Warden wants comes later, if it comes at all. So a page can be revealed a section at a time.

**Parts.** A page's parts are its `##` sections. *Reveal part…* on its bar, or `GM: Reveal Part`, asks which. The revealed list then links that section, `[[Adventure/World/People/The Warden#What They Want]]`, and the bar reads "◔ Revealed in part: What They Want", with *Reveal all* for the rest. A DM Only section is never a part, and neither is a heading inside DM-only text or fenced code. Two sections under the same heading are told apart by number, *Notes* and *Notes (2)*, so revealing one never sends the other, and a heading with a `[`, `]` or `|` in it goes into the list's link as `%5B`, `%5D` or `%7C`, and comes out as it was.

**What the players get.** Publishing a page revealed in part sends its title and the parts revealed, in the page's order, with their DM-only text left out as ever. Nothing in the copy says there is more. The text above a page's first section goes only with the whole page, since that is where a page usually sums itself up for the DM. A part whose heading has been renamed since it was revealed is named when you publish, so it can be revealed again under its new name.

**Meeting someone is not learning everything.** *Mark met* and *Mark visited* reveal only what the page says the players see first:

- the sections its frontmatter names under `reveal_first`, one or a list: `reveal_first: [Who They Are]`;
- or else a section called *First Impressions*, if it has one;
- or else the page by its name alone: the players' copy is its title, and the bar reads "◔ Revealed by name only".

`reveal_first: all` reveals the whole page, for a page with nothing to hold back, and `reveal_first: none` nothing at all, for a page the party learns of some other way: the mark is recorded all the same. A page already revealed keeps what it has, and *Undo* takes back only what the mark revealed. `gm.config.revealFirstKey` names the frontmatter key, and `gm.config.firstReveal` the sections looked for without one.

**A name the party mustn't know.** A page whose title sits in DM-only text, under a stretch opened above it, say, keeps its name from the players, and its copy would give it away: it would sit at a path that names it, with that name for its title. So *Mark met* and *Mark visited* record the mark on such a page and reveal nothing, and say so: "The Heir: met in session 1. Not revealed: the page's name is DM-only." It can't be revealed, publishing never sends it, even from the revealed list, and its bar reads "⊘ Name is DM-only: not published". A title with some of its words DM-only still names the page while the page's own name is among the words left, `# The Tinker <span class="dm">(the Warden's spy)</span>`. A page without a title goes by its file name, which hides it only when nothing of the page is left for the players. What the party knows of someone they can't name yet goes on a page of its own, *The Hooded Stranger*.

## Where the state goes

- `State/Revealed`: a link for each revealed adventure page, `[[Adventure/World/People/Mara]]`, or for each part of one, `[[Adventure/World/People/Mara#Who They Are]]`
- `State/Published`: what each players' copy was made from when it was last published, the page or its parts as the revealed list had them, and when the page had last been saved: `[[Adventure/World/People/Mara#Who They Are]], saved 2026-09-22 19:40:12 UTC`. Publishing writes it; a bar reads it
- `State/Publish Preview`: what publishing would do, as the last preview found it (`gm.config.previewPage`)
- `State/Publish Report`: what the last five publishes did (`gm.config.publishReportPage`)
- `State/People/<name>`, `State/Places/<name>`: met, dead, visited, with a log
- `State/Items/<name>`: found, the uses left of those found, and where, with a log
- `State/Scenes/<act>/<scene>`: planned, started and finished, with a log; the act comes too, so scenes numbered alike in two acts stay apart
- A page's rolls, on its own play state: `roll_wisdom_perception: 15`, the lowest number of the highest band reached, or `passed` or `failed` for a DC, with `roll_wisdom_perception_session`, the session that reached it, and `roll_wisdom_perception_where: the_bank`, the section the check sits in (`top` above any heading), so a check added later, above it or anywhere, keeps clear of its rolls. Another check of that name takes `roll_wisdom_perception_2`, and a second in the same section is `the_bank_2`. A roll logged before 3.8 has no `_where` and is read by its check's place among the page's checks of that name, until the next roll on the page pins it to its section
- Each log line names its session and links to it
- `Sessions/Session N`: the scenes under `## Scenes`, the rolls under `## Rolls`, the decisions under `## Decisions`, one line each, and a roll's rungs under its line
- `Sessions/Session N Recap`: the draft of the players' recap of the session, `type: recap-draft` and `session: N`, yours to edit
- `Player/Sessions/Session N`: the recap as the players have it, `type: recap` and nothing else in its frontmatter

**When SilverBullet rewrites the links.** Renaming a page rewrites the links to it, the revealed list's among them, and the `subject` of its play state, which stays where it was: GM Kit finds a page's record by its subject when the page's own path has none, so a page renamed or moved after it was marked keeps what the party did. A Lua write that makes a page of the same name as an adventure page, a play state in `State/` or a copy in `Player/`, can make SilverBullet 2.11 rewrite bare `[[Name]]` links elsewhere to a full path, and with `linkWriteFormat: shortest-suffix` it can write an entry of the revealed list without its adventure folder, `[[World/People/Mara]]`. GM Kit reads such an entry as the adventure page whose path ends that way, and writes it back in full the next time the list changes.

## Players' own notes

Publishing writes into `Player/` and **replaces** what is there, except `Player/Notes/` and `Player/Sessions/`, where the recaps are, which it never touches. It deletes nothing without asking. A copy that no revealed page makes any more, of a page renamed, deleted or unrevealed since it was published, is listed, and publishing asks before it deletes them, with *Undo*; kept, they are named in the report. The Player space's own `index`, `CONFIG`, `Notes/` and `Library/` are never among them, and nor is anything in its `Sessions/`, where the sessions' recaps are. The copy of a page you unreveal goes at once.

A players' copy keeps only the frontmatter keys in `gm.config.publishKeys`, `type` and `tags` by default. Everything else there is the DM's: an NPC's `role` or `faction`, a page's `status`, its `book_order`.

## Before and after publishing

**A preview.** `GM: Preview Publish`, the eye beside *Publish* in the header, *Preview publishing* on the revealed list or *Preview* on a reveal's notification works out every players' copy exactly as publishing would, and sends nothing. It writes what it found on `State/Publish Preview` (`gm.config.previewPage`), and opens it:

- **New copies**, each with what it is made of: the whole page, its name only, or the parts revealed;
- **Changed copies**, each with the lines that change, *−* for a line that goes and *+* for one that comes, counted in words beside them, up to eight lines a copy and each cut near a hundred characters; a blank line that comes or goes isn't counted;
- **Unchanged** copies;
- what is **kept back**, and why: DM-only marks left once the DM-only text is out, a name that is DM-only, or a copy that would be empty;
- the **embeds left out**, what is **revealed but no longer there**, the pages **only for the DM**, and the **copies no revealed page makes any more**, which publishing asks before it deletes.

Every space-lua block in the space runs and every `${...}` on a page shown is worked out, so nothing a page says is let loose on the preview: the lines it quotes, a copy's changes and the embeds left out, sit in fenced code whose fence is longer than any run of backticks in them, where nothing runs, links or counts as a DM-only mark, and a name it can't link is escaped. The report quotes the same way.

*Publish now* at its top publishes, and asks first as ever; *Preview again* works it out afresh.

**A report.** A notification is gone in seconds, so publishing also keeps a report on `State/Publish Report` (`gm.config.publishReportPage`), newest first: when and in which session, how many copies were new, updated and unchanged, which pages went, what was kept back and why, the embeds left out, and the copies no revealed page makes any more, deleted or kept. It keeps the last five publishes. A publish that sent, deleted and kept back nothing adds nothing, and nor does one that sent nothing and kept back just what the one before it did. The publish's notification has *Open report*.

## The players' recap

**Drafting it.** After a session, `GM: Draft Recap` drafts a recap of it for the players from what GM Kit recorded in it, and opens it. On a session's log or its recap it drafts that session's; anywhere else it asks which, the one being played first. The draft is a page of yours beside the log, `Sessions/Session 3 Recap`, with `type: recap-draft` and `session: 3`, and holds, under a heading each, only where there is something:

- **Met**: the people and factions marked met in the session;
- **Visited**: the places marked visited;
- **Found**: the items marked found, with the uses they have left, "5 of 6 wicks left";
- **Rolls**: each roll logged, with the words of every rung it reached, as the log has them;
- **Decisions**: the decisions logged, in your words.

**Only what the players may know.** It keeps to the adventure's own words where the records give them, and names only what the players may know. A page they have a copy of is a link to that copy, which works once the recap is theirs; a page revealed but not published yet is its name, in words; and a page not revealed, only for the DM or whose name is DM-only is left out, and the notification counts those. A link in a rung's words or a decision goes the same way. A roll goes without the scene it was rolled in, and a roll that reached nothing new, or was taken back later in the log, doesn't go at all; nor does what a roll owes, since when a rung comes back is yours to know. DM-only text never goes in: each line is read with the code publishing uses, and a line that still holds a DM-only mark after that is left out whole, and counted. Nor does anything it quotes run, in your space or the players': a `${` in a name, a rung's words or a decision goes in as `$\{`, and a line that would open fenced code, a space-lua block above all, has its first backtick escaped.

**Publishing it.** Edit the draft as you like, then *Publish recap* on its bar, or `GM: Publish Recap`, which takes the draft you are on, or the only one there is, or asks. It asks first, then copies the draft to `Player/Sessions/Session 3` with nothing in its frontmatter but `type: recap`, its links made to go from there, a link to anything else of yours as its words, and its live values printed as a published page's are. *Undo* takes it back again, or puts back the recap the players had. A draft that holds a DM-only mark isn't published: the notification names the marks, and the bar says so. The bar also says whether the players have the recap as it stands: "○ Not published yet", "◉ Published to players", or "◐ Changed since publishing", with *Publish again*.

Drafting again asks before it replaces a draft you may have edited, and *Undo* puts that back. The players' `Sessions/` folder is theirs and the recaps': publishing the adventure's pages never writes there, so an adventure page under `Sessions/` isn't published, and never offers to delete anything in it. `gm.config.recapFolder` names that folder for both, `Sessions/`, and `recapType` and `recapDraftType` are the recap's types.

## DM-only text

An adventure page can keep its secrets beside what the players may see, and publishing leaves them out of the players' copy. Four things mark them, and each can sit wherever it belongs on the page.

**A DM callout**, for a note in place. It is a quote like a `note` or a `warning` whose type starts with the word `dm`, in any case: `> **dm**`, `> **DM only**`, `> **DM-only note**`, `> [!dm]`. It ends at the first blank line:

    > **dm** Who the stranger is
    > The missing heir, though nobody has told him yet.

**A stretch**, for anything longer: a table, a map, headings of its own. Everything between the two markers goes, and a stretch with no end runs to the end of the page:

    <!--#dm-->

    | Clue | Where it points |
    |---|---|
    | The torn letter | The miller's cellar |

    <!--/dm-->

A marker can sit inside a line as well: the words before `<!--#dm-->` stay, and so do the words after `<!--/dm-->`.

**An element of the class `dm`**, for words inside a sentence or a block of its own. Any element counts, whatever other classes it has, in double quotes or single, and one of the same kind inside it goes with it:

    The door is locked. <span class="dm">The key is under the mat.</span>

    <div class="dm">

    The key is under the mat, and the mat is nailed down.

    </div>

A span left open ends with its paragraph; a div left open runs to the end of the page.

**A DM Only section**, under a heading of any level that says *DM Only*, in any case, with a space, a hyphen or nothing between the words: `## DM Only`, `### DM only`, `# DM-Only`. It runs to the next heading of its own level or above, so a `## DM Only` ends at the next `#` or `##` heading, and a `###` inside it goes with it. A heading in code, a callout, a stretch or a DM element doesn't end it.

None of them counts inside fenced code or inline code, so a code sample can show one. Give markers and callouts lines of their own, with a blank line after, as you would a heading: a line straight after a callout carries on its paragraph, and goes with it.

**What can't be read is kept back.** Once a copy's DM-only text is out, publishing looks through what is left for any sign of a mark, in more forms than the ones above: a stretch marker, an end marker with no stretch open, an element of the class `dm` (a tag written over two lines, say), a DM callout inside a list, a heading that only starts *DM Only*, such as `## DM Only Notes`, or one underlined with `---`. A copy holding any of them isn't sent. The report names it, "Kept back: … still has DM-only marks (…)", and the players keep what they had until the page is put right. `gm.dmMarks(text)` lists the marks a text holds.

The DM space shows a callout with *DM only* and a crossed-out eye at its top, and a span or a div with *DM* before it and a dotted line beside it, so what the players won't get says so in words, not only in colour. `gm.config.dmWord` is the word all of them look for, `dm`, and `gm.config.dmHeading` the heading, `DM Only`. The style looks for `dm` as well, so copy it with your own word if you change it.

## Pages only the DM sees

Some pages keep what only the DM may see in the page itself, where no DM-only marking can reach it. A GM Maps map page is one: its map block is the grid with the creatures on it, and every trapdoor, written out. Their types are in `gm.config.privateTypes`, `{ "map" }` by default, and the type GM Maps is set to give its pages counts too. Such a page is never revealed or published, and its bar says so: "⊘ Only for the DM". The players see a map where a page of theirs draws it, which prints it clean.

A private page that is on the revealed list from before, or that the players already have a copy of, says that on its bar with a button to take it back. Publishing leaves it out and names it.

## Live values in players' copies

The Player space runs only its own code, so a copy can't lean on the DM's libraries. Publishing puts in the Markdown face of any `${...}` that gives a widget with one: GM Party's numbers go in as your party's, "seven arrows" rather than the rule. Everything else stays live, and the Player space evaluates it against what it can see: a query there lists only what has been published.

## Links in players' copies

A link in a players' copy to an adventure page they won't have, hidden, private, kept back or gone, goes in as its words, since following it would open an empty page that names it: `[a hooded stranger](<../People/The Warden>)` is just *a hooded stranger*, `[[Adventure/World/People/Mara|a friend]]` just *a friend*, and `[[Old Tam]]` just *Old Tam*, as the page shows it anyway. A link to a page they have, whole or in part, stays, and so does a link to another site, within the page, or outside the adventure.

An embed of a page they won't have, or of a section of one they don't get, `![[World/People/The Warden#What They Want]]`, is left out of the copy, and the report names it. Links in code and in `${...}` stay as they are.

## Changes in 3.8

**DM-only text in every form it is written.** A DM Only heading counts at any level and in any case, `### DM only` and `## DM-Only` as well as `## DM Only`, and runs to the next heading of its level or above; a callout counts when its type's first word is `dm`, `> **DM only**` included; any element whose class list holds `dm` counts, a `<div class="dm">` too; and the stretch markers count anywhere in a line. **Publishing fails closed**: a copy that still holds a DM-only mark after all that is kept back and named, never sent. GM Book shares the same code, so the player edition does the same.

**A name the party mustn't know stays back.** A page whose title sits inside DM-only text, or whose copy would be empty, is never revealed or published: *Mark met* and *Mark visited* record the mark and reveal nothing, and say so, and the bar says "⊘ Name is DM-only: not published". `reveal_first: none` marks without revealing anything.

**The players' copies link only to what they have.** A link to a page they haven't been shown becomes its words, and a section shown from one is left out and named in the report.

**The bar says when their copy has fallen behind**: "◔ 1 part not published yet", or "◐ Changed since publishing". Publishing records what it sent in `State/Published`.

**A renamed page keeps its play state**, and publishing offers to delete the copies no revealed page makes any more. **A check's rolls stay with its section**, not its place on the page, so a check added above no longer takes another's results. *Undo* of a reveal takes back only what it revealed, two parts under the same heading are told apart ("Notes (2)"), a `]` in a heading is kept, and an entry of `State/Revealed` that SilverBullet rewrote without the adventure folder is still read.

New functions: `gm.dmMarks`, `gm.hidesName`, `gm.unlink`, `gm.stateFor`, `gm.orphanCopies`; and the setting `publishedPage`.

## Changes in 3.7

**DCs that rise with the party.** A rung or DC written through GM Party's `party.dc` is read as the number it is written as, and the bands, the DC, what is owed and the bar show the party's. See *Rolls*.

## Changes in 3.6

**Late, not lost.** A top rung that a check's page says comes back later, and that a roll missed, is kept as owed: the roll's line in the log says so and when it comes back, the page's bar shows it, and `${gm.owed()}` lists everything owed. Logging a roll that reaches it clears it. See *Rolls*.

## Changes in 3.5

**Rolls.** *Log a roll* records what the party rolled for and what it got them, in the session's log and in the adventure's own words. It reads the checks a page sets from the page itself, asks how high they rolled, and who, and writes the words of every rung reached under `## Rolls`. A roll the page doesn't set goes in as *Another roll…*, and the page's bar shows how each of its checks stands. See *Rolls*.

`gm.appendUnder` takes a fourth argument, the section a new one goes in ahead of.

## Changes in 3.4

**A page can be revealed a part at a time.** *Reveal part…* reveals one `##` section, and publishing sends the players the page's title and the parts revealed. See *Revealing part of a page*.

**Marking someone met, or a place visited, no longer reveals the whole page.** It reveals what the page says the players see first: the sections named under `reveal_first`, a *First Impressions* section, or else the page's name alone. A page that should go out whole on meeting says `reveal_first: all`.

**Undo puts the revealed list back as it was**, so undoing a reveal leaves a part revealed before it still revealed.

## Changes in 3.3.1

New examples in these docs, of a quiver and its arrows.

## Changes in 3.3

**A players' copy keeps only a page's `type` and `tags`.** Publishing copied the frontmatter whole, so revealing a person could tell the players the `role` the DM had given them, villain or ally. See *Players' own notes*.

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
-- The version this code is, as the page's frontmatter says: gm.stale()
-- holds it to the copies of GM Kit the space has.
gm.version = "3.8.0"

gm.config = {
  sessionPage     = "Session Table",
  sessionsFolder  = "Sessions/",
  stateFolder     = "State/",
  revealedPage    = "State/Revealed",
  -- What each players' copy was made from, written as it is published.
  publishedPage   = "State/Published",
  -- What publishing would do now, written by GM: Preview Publish, and
  -- what the last few publishes did, written by each one.
  previewPage     = "State/Publish Preview",
  publishReportPage = "State/Publish Report",
  adventureFolder = "Adventure/",
  playerFolder    = "Player/",
  playerNotes     = "Notes/",
  dmHeading       = "DM Only",
  dmWord          = "dm",
  sceneType       = "scene",
  sessionType     = "session",
  -- A session's recap for the players: the DM drafts it on a page of
  -- recapDraftType beside the session's log, and publishing it makes a
  -- page of recapType in this folder of the players' space.
  recapFolder     = "Sessions/",
  recapType       = "recap",
  recapDraftType  = "recap-draft",
  -- Page types whose page itself holds what only the DM may see, so they
  -- are never revealed or published: GM Maps keeps a map's creatures, and
  -- everything hidden on it, in the map block on its page.
  privateTypes    = { "map" },
  -- The frontmatter a players' copy keeps: what a page is and how it is
  -- tagged. The rest is the DM's: an NPC's role or faction, a page's draft
  -- status, its place in the book.
  publishKeys     = { "type", "tags" },
  -- What marking a page met or visited reveals of it: the sections its
  -- frontmatter names under this key, or `all` for the whole page...
  revealFirstKey  = "reveal_first",
  -- ...or else whichever of these sections it has, or else its name alone.
  firstReveal     = { "First Impressions" },
  -- A check whose text says one of these of its top rung keeps that rung
  -- owed after a roll that misses it, until a roll reaches it.
  latePhrases     = { "late, not lost", "late and not lost" },
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

-- The page with only the frontmatter keys in gm.config.publishKeys, for a
-- players' copy. A key's own continuation lines, a list under `tags:` say,
-- go with it; a page left with no keys at all loses its frontmatter.
function gm.publicFrontmatter(text)
  local head, rest = gm.splitFrontmatter(text)
  if not head then return text end
  local keep, out, keeping = {}, {}, false
  for _, k in ipairs(gm.config.publishKeys) do keep[k] = true end
  for line in head:gmatch("([^\n]*)\n") do
    local key = line:match("^([%w_%-]+):")
    if key then
      keeping = keep[key] == true
    elseif not line:match("^[ \t%-]") then
      keeping = false
    end
    if keeping then out[#out + 1] = line end
  end
  if #out == 0 then return (rest:gsub("^\n+", "")) end
  return "---\n" .. table.concat(out, "\n") .. "\n---\n" .. rest
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

-- The page without its DM-only text, for the players' copy.
function gm.stripSecrets(text)
  local c = gm.config
  if not dmMaybe(text, c.dmHeading) then return text end
  return dmStrip(dmScan(text, c.dmHeading, c.dmWord))
end

-- The DM-only marks a text still holds, a word or two for each kind, or an
-- empty list: publishing sends no copy that holds one.
function gm.dmMarks(text)
  local c = gm.config
  return dmMarks(text, c.dmHeading, c.dmWord)
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

------------------------------------------------------------ a stale tab
-- A tab runs the Lua it loaded until System: Reload runs the space's Lua
-- again, but it indexes a page the moment the page changes: a newer GM Kit
-- installed since, from this tab or another, is in the index while this
-- tab still runs the old one. What the old code writes may be in a shape
-- the new one doesn't read, or miss a fix, so GM Kit writes nothing until
-- the tab is reloaded.

-- GM Kit's own page, found by the end of its name: a space that holds
-- another as a folder can hold a copy in each.
local LIBRARY = "Library/Storie/GM Kit"

-- The version of a copy of GM Kit in the space that isn't the version this
-- tab runs, the first such copy by name, or nil. One question to the
-- index, and nil on any error, so the check can never stop what it guards.
local function installedVersion()
  local ok, found = pcall(function()
    local own, tail = LIBRARY, "/" .. LIBRARY
    local rows = query[[
      from p = index.pages()
      where p.name == own or p.name:endsWith(tail)
      order by p.name
      select { name = p.name, version = p.version }
    ]]
    for _, row in ipairs(rows) do
      local v = row.version
      if type(v) == "number" then
        v = v == math.floor(v) and string.format("%d", v) or tostring(v)
      end
      if type(v) == "string" and v ~= "" and v ~= gm.version then return v end
    end
    return nil
  end)
  if ok then return found end
  return nil
end

-- What a bar says of a stale tab, with a glyph and the words.
local function reloadNote(v)
  return "⟳ Reload this tab: GM Kit " .. v .. " is installed, this tab runs " .. tostring(gm.version)
end

-- System: Reload, which runs the space's Lua again: what a stale tab
-- offers, since a phone has no Ctrl-Alt-R.
local function reloadTab()
  editor.invokeCommand("System: Reload")
end

-- nil while this tab runs the GM Kit the space has, else what to do about
-- it. Never raises an error.
function gm.stale()
  local ok, why = pcall(function()
    local v = installedVersion()
    if not v then return nil end
    return "This tab runs GM Kit " .. gm.version .. ", but the space has " .. v ..
           ": reload it (System: Reload, Ctrl-Alt-R) first."
  end)
  if ok then return why end
  return nil
end

-- Whether an action has to stop because this tab is stale: it says so, in
-- a warning with a button to reload. Every write GM Kit makes for the DM
-- asks first, before any picker or prompt, so a stale tab neither asks
-- anything nor writes anything.
function gm.refuse()
  local why = gm.stale()
  if not why then return false end
  gm.notify(why, { { name = "Reload", run = reloadTab } }, "warning")
  return true
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

-- A revealed-list entry as its page and its part: "Adventure/X" is the
-- whole page, "Adventure/X#Who They Are" one section of it.
local function entryParts(entry)
  local page, part = entry:match("^(.-)#(.*)$")
  if page and page ~= "" then return page, part end
  return entry, nil
end

-- What a part's name can't carry inside a link goes into the list as a
-- code, "The %5BHidden%5D Door", and comes back out as it was.
local ENTRY_CODES = { ["%"] = "%25", ["["] = "%5B", ["]"] = "%5D", ["|"] = "%7C" }

local function entryEncode(entry)
  local page, part = entryParts(entry)
  if not part then return entry end
  return page .. "#" .. (part:gsub("[%%%[%]|]", function(c) return ENTRY_CODES[c] end))
end

local function entryDecode(part)
  part = (part:gsub("%%5[bB]", "["))
  part = (part:gsub("%%5[dD]", "]"))
  part = (part:gsub("%%7[cC]", "|"))
  return (part:gsub("%%25", "%%"))
end

-- The adventure page an entry names. SilverBullet rewrites the list's links
-- when a page is renamed, and with linkWriteFormat set to shortest-suffix it
-- can write one without the adventure folder, [[World/People/Mara]]: that
-- is the adventure page the path ends, or, where none or several do, a
-- page gone, named as the adventure's so that publishing says so.
local function entryPage(page, adventure)
  local prefix = gm.config.adventureFolder
  page = (page:gsub("^/", ""))
  if page:startsWith(prefix) then return page end
  if gm.seen(prefix .. page) then return prefix .. page end
  local tail, found = "/" .. page:lower(), nil
  for _, p in ipairs(adventure()) do
    if ("/" .. p:lower()):endsWith(tail) then
      if found then return prefix .. page end
      found = p
    end
  end
  return found or (prefix .. page)
end

-- The revealed list's entries, each with its adventure page's full name. A
-- hand-written entry whose heading holds a ] is read whole.
function gm.readRevealed()
  local list = {}
  if not gm.exists(gm.config.revealedPage) then return list end
  local all
  local function adventure()
    all = all or gm.adventurePages()
    return all
  end
  for line in (space.readPage(gm.config.revealedPage) .. "\n"):gmatch("([^\n]*)\n") do
    local entry = line:match("^%s*[%-%*] %[%[(.*)%]%]")
    if entry then
      local page, part = entryParts(entry)
      page = entryPage(page, adventure)
      list[#list + 1] = part and (page .. "#" .. entryDecode(part)) or page
    end
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
      '${widgets.commandButton("Preview publishing", "GM: Preview Publish")} ' ..
      '${widgets.commandButton("Publish to players", "GM: Publish to Players")}', "",
  }
  for _, n in ipairs(list) do lines[#lines + 1] = "- [[" .. entryEncode(n) .. "]]" end
  gm.write(gm.config.revealedPage, table.concat(lines, "\n") .. "\n")
end

-- When a page was last saved, to the second, as the published record
-- keeps it: "2026-09-22 10:15:30 UTC". nil where the space can't say.
local function savedAt(page)
  local ok, meta = pcall(space.getFileMeta, page .. ".md")
  local ms = ok and meta and tonumber(meta.lastModified)
  if not ms then return nil end
  return os.date("!%Y-%m-%d %H:%M:%S", math.floor(ms / 1000)) .. " UTC"
end

-- What each players' copy was made from when it was last published, by
-- adventure page: `entries`, the revealed-list entries it was made from,
-- the whole page or its parts, as a set, and `saved`, when the page had
-- last been saved. Read as a bar reads, so a record not there costs nothing.
function gm.readPublished()
  local out = {}
  local path = gm.config.publishedPage
  if not gm.seen(path) then return out end
  local all
  local function adventure()
    all = all or gm.adventurePages()
    return all
  end
  for line in (space.readPage(path) .. "\n"):gmatch("([^\n]*)\n") do
    local entry, saved = line:match("^%s*[%-%*] %[%[(.*)%]%], saved (.-)%s*$")
    if entry then
      local name, part = entryParts(entry)
      name = entryPage(name, adventure)
      local r = out[name] or { entries = {} }
      out[name] = r
      r.entries[part and (name .. "#" .. entryDecode(part)) or name] = true
      r.saved = saved
    end
  end
  return out
end

-- Writes the record, a line for each entry a copy was made from, sorted,
-- and only where it has changed, so a publish that changes nothing writes
-- nothing.
function gm.writePublished(records)
  local lines = {}
  for _, r in pairs(records) do
    for entry in pairs(r.entries) do
      lines[#lines + 1] = "- [[" .. entryEncode(entry) .. "]], saved " .. (r.saved or "?")
    end
  end
  table.sort(lines)
  local path = gm.config.publishedPage
  local there = gm.exists(path)
  if #lines == 0 and not there then return false end
  local text = table.concat({
    "---", "type: state", "---", "",
    "# Published to players", "",
    "What each of the players' copies was made from when GM Kit last published it: " ..
      "the page, or the parts of it revealed, and when the page had last been saved. " ..
      "A page's bar compares them with the page and the revealed list as they are now.", "",
  }, "\n") .. "\n" .. table.concat(lines, "\n") .. (#lines > 0 and "\n" or "")
  if there and space.readPage(path) == text then return false end
  gm.write(path, text)
  return true
end

-- What the players are meant to see of each page on the revealed list:
-- true for the whole page, or the names of the parts revealed. The pages
-- come in the list's order.
function gm.reveals()
  local pages, of = {}, {}
  for _, entry in ipairs(gm.readRevealed()) do
    local page, part = entryParts(entry)
    if of[page] == nil then
      pages[#pages + 1] = page
      of[page] = {}
    end
    if part == nil then
      of[page] = true
    elseif of[page] ~= true then
      local parts = of[page]
      parts[#parts + 1] = part
    end
  end
  return pages, of
end

-- true when the whole page is revealed, the names of the parts revealed
-- when only some are, or nil.
function gm.revealedPart(page)
  local _, of = gm.reveals()
  return of[page]
end

-- Whether the players are meant to see any of a page, whole or in part.
function gm.isRevealed(page)
  return gm.revealedPart(page) ~= nil
end

-- A page's own entries on the list, to put back as they were.
function gm.revealEntries(page)
  local mine = {}
  for _, entry in ipairs(gm.readRevealed()) do
    if (entryParts(entry)) == page then mine[#mine + 1] = entry end
  end
  return mine
end

-- Puts a page's entries back as they were, and only that page's.
function gm.putRevealEntries(page, entries)
  local out = {}
  for _, entry in ipairs(gm.readRevealed()) do
    if (entryParts(entry)) ~= page then out[#out + 1] = entry end
  end
  for _, entry in ipairs(entries) do out[#out + 1] = entry end
  gm.writeRevealed(out)
end

-- Takes back what one action did to a page's entries, given the page's
-- entries before it and after it, and nothing done since: the entries it
-- added come off, and those it took off go back, so a part revealed after
-- it stays revealed. An action whose entries have all been taken off since
-- has nothing left to take back.
function gm.undoReveals(page, before, after)
  local was, now, added = {}, {}, {}
  for _, entry in ipairs(before) do was[entry] = true end
  for _, entry in ipairs(after) do
    now[entry] = true
    if not was[entry] then added[#added + 1] = entry end
  end
  local list, present = gm.readRevealed(), {}
  for _, entry in ipairs(list) do present[entry] = true end
  local still = #added == 0
  for _, entry in ipairs(added) do
    if present[entry] then still = true end
  end
  if not still then return false end
  local out = {}
  for _, entry in ipairs(list) do
    if was[entry] or not now[entry] then out[#out + 1] = entry end
  end
  for _, entry in ipairs(before) do
    if not now[entry] and not present[entry] then out[#out + 1] = entry end
  end
  gm.writeRevealed(out)
  return true
end

-- Reveals the whole page, in place of any parts of it, or takes all of it
-- back. Returns whether the list changed.
function gm.setRevealed(page, on)
  local out, listed, whole = {}, false, false
  for _, entry in ipairs(gm.readRevealed()) do
    local p, part = entryParts(entry)
    if p == page then
      listed = true
      if part == nil then whole = true end
    else
      out[#out + 1] = entry
    end
  end
  if on and whole then return false end
  if not on and not listed then return false end
  if on then out[#out + 1] = page end
  gm.writeRevealed(out)
  return true
end

-- A frontmatter key's value as a list: `key: A`, `key: [A, B]`, or a YAML
-- list under it, a `- A` a line.
function gm.frontmatterList(text, key)
  local head = gm.splitFrontmatter(text)
  local out, under = {}, false
  for line in (head or ""):gmatch("([^\n]*)\n") do
    local k, v = line:match("^([%w_%-]+):%s*(.-)%s*$")
    if k then
      under = false
      if k == key then
        v = yamlValue(v)
        local inner = v:match("^%[(.*)%]$")
        if inner then
          for item in (inner .. ","):gmatch("([^,]*),") do
            item = yamlValue(item:match("^%s*(.-)%s*$"))
            if item ~= "" then out[#out + 1] = item end
          end
        elseif v ~= "" then
          out[#out + 1] = v
        else
          under = true
        end
      end
    elseif under then
      local item = line:match("^%s*%-%s+(.-)%s*$")
      if item then out[#out + 1] = yamlValue(item) end
    end
  end
  return out
end

-- A page as parts the players can be shown one at a time: its `##`
-- sections, read from the page as the players would have it, so DM-only
-- text is gone, a DM Only section is never a part, and a heading in fenced
-- code isn't one. Gives the title line, the name the page goes by (its
-- title, or else its own name), the parts in page order, each with its
-- lines, and the opening above the first part. Two sections under one
-- heading are told apart by number: the second `## Notes` is "Notes (2)".
function gm.parts(page, text)
  text = text or space.readPage(page)
  local _, body = gm.splitFrontmatter(text)
  body = gm.stripSecrets(body or text)
  local title, opening, parts, current, fence = nil, {}, {}, nil, nil
  local taken = {}
  for line in (body .. "\n"):gmatch("([^\n]*)\n") do
    local mark = line:match("^%s*(```+)") or line:match("^%s*(~~~+)")
    local heading = false
    if fence then
      if mark and mark:sub(1, 1) == fence:sub(1, 1) and #mark >= #fence then fence = nil end
    elseif mark then
      fence = mark
    else
      heading = line:match("^##?%s") ~= nil
    end
    if heading and not title and not current and line:match("^#%s") then
      title = line
    elseif heading then
      local name = line:match("^##?%s+(.-)%s*$")
      local unique, k = name, 1
      while taken[unique] do
        k = k + 1
        unique = name .. " (" .. string.format("%d", k) .. ")"
      end
      taken[unique] = true
      current = { name = unique, lines = { line } }
      parts[#parts + 1] = current
    elseif current then
      current.lines[#current.lines + 1] = line
    else
      opening[#opening + 1] = line
    end
  end
  return {
    title = title, parts = parts, opening = opening,
    name = title and title:match("^#%s+(.-)%s*$") or gm.name(page),
  }
end

-- The players' copy of some of a page: its frontmatter and its title, then
-- the parts named, in the page's order. The opening above the first part
-- goes only with the whole page, since that is where a page usually sums
-- itself up for the DM.
function gm.partialCopy(page, text, names)
  local want = {}
  for _, n in ipairs(names) do want[n] = true end
  local p = gm.parts(page, text)
  local out = { p.title or ("# " .. p.name), "" }
  for _, part in ipairs(p.parts) do
    if want[part.name] then
      for _, line in ipairs(part.lines) do out[#out + 1] = line end
    end
  end
  local body = (table.concat(out, "\n"):gsub("\n\n\n+", "\n\n"))
  body = (body:gsub("%s+$", "")) .. "\n"
  local head = gm.splitFrontmatter(text)
  if not head then return body end
  return "---\n" .. head .. "---\n\n" .. body
end

-- The parts named that the page no longer has, a heading renamed since
-- it was revealed, say. The page's own name is always there.
function gm.missingParts(page, text, names)
  local p, have, gone = gm.parts(page, text), {}, {}
  have[p.name] = true
  for _, part in ipairs(p.parts) do have[part.name] = true end
  for _, n in ipairs(names) do
    if not have[n] then gone[#gone + 1] = n end
  end
  return gone
end

-- The players' copy of a page as it is revealed, before its live values
-- print: `reveal` is true for the whole page, or the names of the parts
-- revealed. A part the page no longer has goes into `missing`, if given.
function gm.copyText(page, raw, reveal, missing)
  if reveal == true then return gm.publicFrontmatter(gm.stripSecrets(raw)) end
  -- revealed in part: its title and those parts, and nothing that says
  -- there is more
  if missing then
    for _, part in ipairs(gm.missingParts(page, raw, reveal)) do
      missing[#missing + 1] = page .. "#" .. part
    end
  end
  return gm.publicFrontmatter(gm.partialCopy(page, raw, reveal))
end

-- A page's title, its first heading of level one outside fenced code, as
-- its line: in a quote too, since a title can be hidden in a callout.
local function titleLine(body)
  local fence
  for line in (body .. "\n"):gmatch("([^\n]*)\n") do
    local bare = line:match("^[%s>]*(.*)$")
    local mark = bare:match("^(```+)") or bare:match("^(~~~+)")
    if fence then
      if mark and mark:sub(1, 1) == fence:sub(1, 1) and #mark >= #fence then fence = nil end
    elseif mark then
      fence = mark
    elseif bare:match("^#%s") then
      return line
    end
  end
  return nil
end

-- Whether a page keeps its own name from the players: its title isn't there
-- once the DM-only text is out, or what is left of it no longer shows the
-- page's name; or, for a page without a title, nothing is left at all. Its
-- copy would sit at a path that names it, with that name for its title, so
-- such a page is never revealed or published.
function gm.hidesName(page, text)
  text = text or (gm.exists(page) and space.readPage(page))
  if not text then return false end
  local _, body = gm.splitFrontmatter(text)
  body = body or text
  local title, stripped = titleLine(body), gm.stripSecrets(body)
  if not title then return not stripped:find("%S") end
  local now = titleLine(stripped)
  if not now then return true end
  if now == title then return false end
  local shown = (now:match("^[%s>]*#%s+(.-)%s*$") or ""):lower()
  return not shown:find(gm.name(page):lower(), 1, true)
end

-- What the notification and the bar say of a page that hides its name.
local HIDDEN_NAME = "Not revealed: the page's name is DM-only."

local function hiddenNameNote(page)
  return gm.name(page) .. "'s name is DM-only: its title sits in DM-only text, and its copy " ..
    "would give the players the name, so it is never revealed or published. Take the title " ..
    "out of the DM-only text, or give what the party knows a page of its own."
end

-- What marking a page met or visited reveals of it, never the whole page
-- unless the page says so: true for `all`, false for `none`, else the parts
-- named under gm.config.revealFirstKey, else those in gm.config.firstReveal,
-- of those the page has. An empty list is the page's name alone. The name
-- the page goes by comes second.
function gm.firstReveal(page, text)
  text = text or space.readPage(page)
  local named = gm.frontmatterList(text, gm.config.revealFirstKey)
  if #named == 1 and named[1]:lower() == "all" then return true, nil end
  if #named == 1 and named[1]:lower() == "none" then return false, nil end
  local p, have, out = gm.parts(page, text), {}, {}
  for _, part in ipairs(p.parts) do have[part.name] = true end
  for _, n in ipairs(#named > 0 and named or gm.config.firstReveal) do
    if have[n] then out[#out + 1] = n end
  end
  return out, p.name
end

-- "“Who They Are”", "“Who They Are” and “At the Table”".
local function partNames(names)
  local out = ""
  for i, n in ipairs(names) do
    if i > 1 then out = out .. (i == #names and " and " or ", ") end
    out = out .. "“" .. n .. "”"
  end
  return out
end

-- Reveals what marking the page reveals (gm.firstReveal), unless the
-- players are meant to see all of that already. Gives back the page's
-- entries as they were, for Undo, and what was revealed, for the
-- notification, or nil when nothing changed; and, for a page that hides
-- its name, which reveals nothing, a note saying so.
function gm.revealFirst(page)
  local before, now = gm.revealEntries(page), gm.revealedPart(page)
  local text = space.readPage(page)
  if gm.hidesName(page, text) then return before, nil, HIDDEN_NAME end
  if now == true then return before, nil end
  local first, name = gm.firstReveal(page, text)
  if first == false then return before, nil end
  if first == true then
    gm.setRevealed(page, true)
    return before, "revealed"
  end
  if #first == 0 then
    -- the page by its name: anything revealed of it already says as much
    if now then return before, nil end
    first = { name }
  end
  local have, added = {}, {}
  for _, n in ipairs(now or {}) do have[n] = true end
  for _, n in ipairs(first) do
    if not have[n] then added[#added + 1] = n end
  end
  if #added == 0 then return before, nil end
  local list = gm.readRevealed()
  for _, n in ipairs(added) do list[#list + 1] = page .. "#" .. n end
  gm.writeRevealed(list)
  if added[1] == name and #added == 1 then return before, "revealed by name" end
  return before, "revealed " .. partNames(added)
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

-- Where a page's play state goes, by its name: see gm.stateFor for where
-- it is.
function gm.statePath(page)
  local kind = gm.kind(page) or "Other"
  local name = kind == "Scenes" and gm.stateName(page) or gm.name(page)
  return gm.config.stateFolder .. kind .. "/" .. name
end

-- The play state records by the adventure page their subject names. A
-- page renamed or moved after it was marked keeps its record where it was:
-- SilverBullet 2.11 has no rename event, but its rename rewrites the link
-- in the record's subject. Read from the index once and kept until
-- gm.freshStates(), which a bar and each list of pages call first, since a
-- list reads every page's state; a page renamed since is caught all the
-- same, as its record's subject then names a page that isn't there.
local subjects

function gm.freshStates()
  subjects = nil
end

-- The adventure page a subject's link names, however SilverBullet wrote it.
local function subjectPage(subject, adventure)
  local target = type(subject) == "string" and subject:match("%[%[([^%]|#]+)")
  return target and entryPage(target, adventure) or nil
end

local function recordsBySubject(fresh)
  if subjects and not fresh then return subjects end
  local all
  local function adventure()
    all = all or gm.adventurePages()
    return all
  end
  subjects = { byPage = {}, rows = {}, adventure = adventure }
  local record = "state-record"
  local rows = query[[
    from p = index.pages()
    where p.type == record and p.subject ~= nil
    order by p.name
    select { name = p.name, subject = p.subject }
  ]]
  for _, row in ipairs(rows) do
    local page = subjectPage(row.subject, adventure)
    if page then
      subjects.rows[#subjects.rows + 1] = { name = row.name, page = page }
      if not subjects.byPage[page] then subjects.byPage[page] = row.name end
    end
  end
  return subjects
end

-- The record whose subject names a page, if one does. A record whose
-- subject names a page that isn't there any more is read again, once: its
-- page was renamed after the index was read, and the subject rewritten.
local function recordFor(page, fresh)
  local s = recordsBySubject(fresh)
  if s.byPage[page] then return s.byPage[page] end
  for _, row in ipairs(s.rows) do
    if not row.read and not gm.seen(row.page) then
      row.read = true
      local ok, text = pcall(space.readPage, row.name)
      local now = ok and subjectPage(gm.frontmatter(text).subject, s.adventure)
      if now then
        row.page = now
        if not s.byPage[now] then s.byPage[now] = row.name end
        if now == page then return row.name end
      end
    end
  end
  return nil
end

-- Where a page's play state is, and whether it is there: its own path, or
-- failing that the record whose subject names it, for a page renamed since
-- it was marked; else its own path, for a record still to be made. What a
-- bar or a table shows asks the cheap way (gm.seen); an action that decides
-- by it passes `exact`, so a record written a moment ago counts.
function gm.stateFor(page, exact)
  local function there(path)
    if exact then return gm.exists(path) end
    return gm.seen(path)
  end
  local path = gm.statePath(page)
  if there(path) then return path, true end
  local other = recordFor(page, exact)
  if other and other ~= path and there(other) then return other, true end
  return path, false
end

-- A page's play state, as gm.stateFor finds it.
function gm.readState(page, exact)
  local path, there = gm.stateFor(page, exact)
  if not there then return {} end
  return gm.frontmatter(space.readPage(path))
end

-- Where publishing puts a page, or nil for the pages it skips: anything but an
-- adventure page, so never a space's index, CONFIG or libraries, and never
-- the players' Notes, nor the folder their sessions' recaps are in.
function gm.playerCopy(page)
  if not gm.isAdventurePage(page) then return nil end
  local rel = page:sub(#gm.config.adventureFolder + 1)
  if rel:startsWith(gm.config.playerNotes) or rel:startsWith(gm.config.recapFolder) then return nil end
  return gm.config.playerFolder .. rel
end

-- Adds a list item to the end of a page's text.
function gm.appendItem(text, item)
  if text:sub(-1) ~= "\n" then text = text .. "\n" end
  return text .. "- " .. item .. "\n"
end

-- Adds a list item at the end of one `## Heading` section, making the
-- heading when it isn't there yet: ahead of the `## <before>` section if
-- one is named and there, else at the end of the page. A session log keeps
-- sections of its own, and appending to the page would file every line
-- under whichever of them came last.
function gm.appendUnder(text, heading, item, before)
  if text:sub(-1) ~= "\n" then text = text .. "\n" end
  local head = "## " .. heading
  local _, to = text:find("\n" .. head .. "[ \t]*\n")
  if not to then
    local at = before and text:find("\n## " .. before .. "[ \t]*\n")
    if at then
      local lead = (text:sub(1, at):gsub("[ \t\r\n]+$", ""))
      return lead .. "\n\n" .. head .. "\n\n- " .. item .. "\n\n" .. text:sub(at + 1)
    end
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

-- Takes a `## Heading` line back out when nothing but blank lines is under
-- it, so taking a section's last line out leaves the page as it was before
-- the section came.
function gm.dropEmptySection(text, heading)
  local s, e = text:find("\n## " .. heading .. "[ \t]*\n")
  if not s then return text end
  local rest = text:sub(e + 1)
  local stop = rest:find("^##[^#]") and 0 or rest:find("\n##[^#]")
  local body = stop and rest:sub(1, stop) or rest
  if body:find("%S") then return text end
  local tail = stop and rest:sub(stop + 1) or ""
  local lead = (text:sub(1, s):gsub("[ \t\r\n]+$", ""))
  if tail == "" then return lead .. "\n" end
  return lead .. "\n\n" .. tail
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
  local path = (gm.stateFor(page, true))
  local text
  if gm.exists(path) then
    text = gm.read(path)
  else
    text = "---\ntype: state-record\nsubject: \"[[" .. page .. "]]\"\n---\n\n# " ..
           gm.name(page) .. "\n\nPlay state for [[" .. page .. "]].\n\n## Log\n\n"
    -- a new record: the records read by their subjects are read again
    subjects = nil
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
  gm.freshStates()
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
  if gm.refuse() then return false end
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
  local path = (gm.stateFor(page, true))
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
  -- what the players get is what the page says they see first, and never
  -- the whole page unless it says so
  local listed, revealed, shown, held
  if reveals then listed, revealed, held = gm.revealFirst(page) end
  if revealed then shown = gm.revealEntries(page) end
  gm.refresh()
  local actions = {}
  if m.offers and page:startsWith(gm.config.adventureFolder) and not gm.isRevealed(page)
      and not gm.hidesName(page) then
    actions[#actions + 1] = { name = "Reveal", run = function() gm.reveal(page) end }
  end
  -- Undo takes back this mark and nothing done since: another mark, a use
  -- or a decision on the same pages stays
  local keys = {}
  for k in pairs(fields) do keys[#keys + 1] = k end
  table.sort(keys)
  actions[#actions + 1] = { name = "Undo", run = function()
    if gm.refuse() then return end
    gm.revert(path, before, keys, { line }, created)
    gm.unlogged(logged)
    if revealed then gm.undoReveals(page, listed, shown) end
    gm.refresh()
    gm.notify("Undone: " .. name .. " is no longer marked " .. mark)
  end }
  gm.notify(name .. ": " .. m.done:lower() .. "session " .. s .. (extra.note or "") ..
            (revealed and (", and " .. revealed) or "") .. "." .. (held and (" " .. held) or ""),
            actions)
  return true
end

-- Takes a mark off again, for one recorded by mistake, with Undo. The log
-- keeps both lines. An item's uses go with its find, so finding it again
-- counts them afresh from the page that hands it out.
function gm.unmark(page, mark)
  if gm.refuse() then return false end
  local m, s = gm.marks[mark], gm.currentSession()
  local name, path = gm.name(page), (gm.stateFor(page, true))
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
      if gm.refuse() then return end
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
  if gm.refuse() then return false end
  local state = gm.readState(page, true)
  if state.status == "dead" then return gm.mark(page, "dead") end
  local how = editor.prompt("How did " .. gm.name(page) .. " die? (optional)", "")
  if how == nil then return false end
  return gm.mark(page, "dead", how:match("^%s*(.-)%s*$"))
end

------------------------------------------------------------------ items

-- The adventure page a link in the adventure names: World/Items/Quiver, a
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

-- "a torch", "an arrow", "a use"
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
  if gm.refuse() then return false end
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

-- "●●●●○○ 4 of 6 arrows left" from a state record or a query's page, or ""
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
  if gm.refuse() then return false end
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
  local path, s = (gm.stateFor(item, true)), gm.currentSession()
  local before = gm.read(path)
  local what = a(unit) .. (delta < 0 and " used" or " refunded")
  local text = gm.setFrontmatter(before, "uses", int(after))
  local line = gm.sessionLink(s, true) .. ": " .. what .. ", " .. int(after) .. " left"
  gm.write(path, gm.appendItem(text, line))
  gm.refresh()
  gm.notify(name .. ": " .. what .. ". " .. gm.usesText(gm.readState(item, true), true) .. ".", {
    { name = "Undo", run = function()
      if gm.refuse() then return end
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
  gm.freshStates()
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

------------------------------------------------------------------ rolls
-- A roll is logged against a check a page sets, read from the page as the
-- DM has it. A check is a paragraph that names one, "Wisdom (Perception)",
-- followed, before the next check or heading, by what the roll gives:
--   a table whose rows start with a rung: **Any roll**, **No roll**, **10**;
--   paragraphs that start with one, At **15** or **At 15**, where whatever
--     comes between the check and the first of them is what any roll gets;
--   a table with a column for each rung and a row for each thing to find,
--     one roll a row;
--   or a DC and nothing else, for a check that is passed or failed.
-- A check with none of these is only mentioned, and isn't one. The page is
-- never written to: a roll goes into the session's log, with the words of
-- every rung it reached, and into the page's play state.

gm.abilities = { "Strength", "Dexterity", "Constitution", "Intelligence", "Wisdom", "Charisma" }

-- The skills, for a roll the page doesn't set.
gm.skills = {
  "Strength (Athletics)", "Dexterity (Acrobatics)", "Dexterity (Sleight of Hand)",
  "Dexterity (Stealth)", "Intelligence (Arcana)", "Intelligence (History)",
  "Intelligence (Investigation)", "Intelligence (Nature)", "Intelligence (Religion)",
  "Wisdom (Animal Handling)", "Wisdom (Insight)", "Wisdom (Medicine)",
  "Wisdom (Perception)", "Wisdom (Survival)", "Charisma (Deception)",
  "Charisma (Intimidation)", "Charisma (Performance)", "Charisma (Persuasion)",
}

-- The option that logs a roll the page doesn't set.
local OTHER = "Another roll…"

-- A number written as one, or nil: tonumber alone reads "" as 0 in
-- SilverBullet, which runs on JavaScript's Number.
local function num(v)
  if type(v) == "number" then return v end
  if type(v) ~= "string" or not v:match("^%-?%d+$") then return nil end
  return tonumber(v)
end

-- Text as it reads: a link as its label, and no stars or tags.
function gm.flat(s)
  s = (s:gsub("%[%[([^%]|]*)|([^%]]*)%]%]", function(_, label) return label end))
  s = (s:gsub("%[%[([^%]]*)%]%]", function(p) return p:match("([^/#]+)$") or p end))
  s = (s:gsub("!?%[([^%]]*)%]%(<[^>]*>%)", function(label) return label end))
  s = (s:gsub("!?%[([^%]]*)%]%([^%)]*%)", function(label) return label end))
  s = (s:gsub("<[^>]+>", ""))
  return (s:gsub("%*", ""))
end

-- A DC written through GM Party, ${party.dc(15)}, which the page shows as
-- the party's DC. A check reads the number it is written as, 15, and adds
-- how far the party's DCs rise wherever it shows one.
local DC_FORM = "%$%{%s*party%.dc%s*[%(%{]%s*(%d+)%s*[%)%}]%s*%}"

-- Text with each such DC put back as the number it is written as, and
-- whether it had one.
local function undc(s)
  local found = false
  s = (s:gsub(DC_FORM, function(n)
    found = true
    return n
  end))
  return s, found
end

-- A paragraph that opens a rung written that way, "At **${party.dc(15)}**,
-- ...": the rung put back as its number, and whether it was. The words
-- after it keep their own expressions, which print as they read.
local function leadingDc(text)
  local pre, n, post = text:match("^(%*?%*?At %*?%*?)" .. DC_FORM .. "(.*)$")
  if pre then return pre .. n .. post, true end
  return text, false
end

-- How far the party's DCs rise over the ones written, from GM Party.
local function dcRise()
  if not (party and party.dcRise) then return 0 end
  local ok, rise = pcall(party.dcRise)
  if ok and type(rise) == "number" then return rise end
  return 0
end

-- A line for a picker: flat, on one line, and cut at a word near n
-- characters.
local function shortText(s, n)
  s = (gm.flat(s):gsub("%s+", " "))
  s = (s:match("^%s*(.-)%s*$"))
  if #s <= n then return s end
  local stop, i = nil, 1
  while true do
    local at = s:find(" ", i, true)
    if not at or at > n then break end
    stop, i = at, at + 1
  end
  local cut = s:sub(1, (stop or (n + 1)) - 1)
  return (cut:gsub("[%s,;:%.]+$", "")) .. "…"
end

-- A rung as a scene writes one: "Any roll" and "No roll" are the floor, 0;
-- "15", "15+", "15 or better", and a column's "10 or better also gets",
-- are that number, and so is ${party.dc(15)}. nil for anything else.
local function rungAt(cell)
  local s = (gm.flat((undc(cell))):lower():match("^%s*(.-)[%s%.:]*$"))
  if s:find("^any roll") or s:find("^no roll") then return 0 end
  local n = s:match("^(%d+)%+?$") or s:match("^(%d+)%+? or %a") or s:match("^(%d+)%+? and up")
    or s:match("^(%d+) to %d+$") or s:match("^dc (%d+)$")
  return num(n)
end

-- A table row's cells, trimmed. An escaped pipe, \|, stays in its cell.
local function rowCells(line)
  local s = (line:match("^%s*|(.*)$")) or ""
  s = (s:gsub("\\|", "&#124;"))
  if not s:find("|%s*$") then s = s .. "|" end
  local out = {}
  for cell in s:gmatch("([^|]*)|") do
    local c = (cell:gsub("&#124;", "|"))
    out[#out + 1] = (c:match("^%s*(.-)%s*$"))
  end
  return out
end

local function separatorRow(cells)
  for _, c in ipairs(cells) do
    if not c:match("^:?%-+:?$") then return false end
  end
  return #cells > 0
end

-- A page's body as headings, paragraphs and tables, with quote markers
-- taken off, and without its frontmatter, fenced code or HTML comments.
local function rollBlocks(text)
  local _, body = gm.splitFrontmatter(text)
  body = body or text
  local out, para, rows, fence = {}, nil, nil, nil
  local function endPara()
    if para then out[#out + 1] = { kind = "para", text = table.concat(para, " ") } end
    para = nil
  end
  local function endTable()
    if rows then out[#out + 1] = { kind = "table", rows = rows } end
    rows = nil
  end
  for line in (body .. "\n"):gmatch("([^\n]*)\n") do
    local q = line
    while q:find("^%s*>") do q = (q:gsub("^%s*> ?", "", 1)) end
    local mark = q:match("^%s*(```+)") or q:match("^%s*(~~~+)")
    if fence then
      if mark and mark:sub(1, 1) == fence:sub(1, 1) and #mark >= #fence then fence = nil end
    elseif mark then
      endPara()
      endTable()
      fence = mark
    elseif not q:find("%S") or q:find("^%s*<!%-%-") then
      endPara()
      endTable()
    elseif q ~= line and (q:find("^%s*%*%*[%w_%-]+%*%*") or q:find("^%s*%[![%w_%-]+%]")) then
      -- a callout's type and title are a line of their own
      endPara()
      endTable()
      para = { (q:match("^%s*(.-)%s*$")) }
      endPara()
    elseif q:find("^#+%s") then
      endPara()
      endTable()
      out[#out + 1] = { kind = "heading", text = (q:match("^#+%s+(.-)%s*$")) }
    elseif q:find("^%s*|") then
      endPara()
      rows = rows or {}
      rows[#rows + 1] = rowCells(q)
    else
      endTable()
      para = para or {}
      para[#para + 1] = (q:match("^%s*(.-)%s*$"))
    end
  end
  endPara()
  endTable()
  return out
end

-- Where a paragraph's plain text names a check, "Wisdom (Perception)", from
-- its first character to its last. Two named together, "Strength (Athletics)
-- or Dexterity (Acrobatics)", are one check.
local function namedCheck(plain)
  local found = {}
  for _, ability in ipairs(gm.abilities) do
    local from = 1
    while true do
      local s, e = plain:find(ability .. " %(%u[%a' ]*%)", from)
      if not s then break end
      found[#found + 1] = { s = s, e = e }
      from = e + 1
    end
  end
  if #found == 0 then return nil end
  table.sort(found, function(x, y) return x.s < y.s end)
  local first, last = found[1].s, found[1].e
  for i = 2, #found do
    local gap = plain:sub(last + 1, found[i].s - 1)
    if not (gap:match("^,? or $") or gap:match("^ ?/ ?$") or gap:match("^,? and $")) then break end
    last = found[i].e
  end
  return first, last
end

-- The sentence of a plain paragraph that holds from..to.
local function sentenceOf(plain, from, to)
  local start, i = 1, 1
  while true do
    local s, e = plain:find("[%.!?]%s+", i)
    if not s or s >= from then break end
    start, i = e + 1, e + 1
  end
  local stop = plain:find("[%.!?]%s", to) or plain:find("[%.!?]$", to) or #plain
  return (plain:sub(start, stop):match("^%s*(.-)%s*$"))
end

-- A paragraph that opens a rung, "At **15**, ..." or "**At 15**, ...": its
-- threshold, the rest of the paragraph with a capital to start it, and
-- whether the rung is written through party.dc.
local function proseRung(text)
  local scaled
  text, scaled = leadingDc(text)
  local n, rest = text:match("^%*%*At (%d+)%+?[^%*]*%*%*[%s,:;%.]*(.*)$")
  if not n then n, rest = text:match("^At %*%*(%d+)%+?[^%*]*%*%*[%s,:;%.]*(.*)$") end
  if not n then return nil end
  return num(n), (rest:gsub("^%l", function(c) return c:upper() end)), scaled
end

-- What a table under a check gives: its rungs, when its rows start with
-- them, or else the things to find, when its columns do; and whether a
-- rung is written through party.dc.
local function readTable(rows)
  local head, body = rows[1] or {}, {}
  for i = 2, #rows do
    if not separatorRow(rows[i]) then body[#body + 1] = rows[i] end
  end
  local candidates = {}
  if head[1] and rungAt(head[1]) then candidates[1] = head end
  for _, r in ipairs(body) do candidates[#candidates + 1] = r end
  local rungs, scaled = {}, false
  for _, r in ipairs(candidates) do
    local at = r[1] and rungAt(r[1])
    if at then
      if r[1]:find(DC_FORM) then scaled = true end
      local words = {}
      for j = 2, #r do
        if r[j] ~= "" then words[#words + 1] = r[j] end
      end
      rungs[#rungs + 1] = { at = at, text = table.concat(words, " ") }
    end
  end
  if #rungs > 0 then return rungs, nil, scaled end
  local cols = {}
  for j = 2, #head do
    local at = rungAt(head[j])
    if at then
      if head[j]:find(DC_FORM) then scaled = true end
      cols[#cols + 1] = { j = j, at = at }
    end
  end
  if #cols == 0 then return nil, nil end
  local found = {}
  for _, r in ipairs(body) do
    local name = (gm.flat(r[1] or ""):match("^%s*(.-)%s*$"))
    local given = {}
    for _, c in ipairs(cols) do
      if (r[c.j] or "") ~= "" then given[#given + 1] = { at = c.at, text = r[c.j] } end
    end
    if name ~= "" and #given > 0 then found[#found + 1] = { name = name, rungs = given } end
  end
  if #found == 0 then return nil, nil end
  return nil, found, scaled
end

-- Rungs lowest first, keeping the page's order among equals.
local function byRung(rungs)
  local out = {}
  for _, r in ipairs(rungs) do
    local k = #out + 1
    while k > 1 and out[k - 1].at > r.at do
      out[k] = out[k - 1]
      k = k - 1
    end
    out[k] = r
  end
  return out
end

-- Whether a paragraph says a missed top rung comes back later: one of
-- gm.config.latePhrases, "late, not lost".
local function isLate(text)
  local low = gm.flat(text):lower()
  for _, phrase in ipairs(gm.config.latePhrases) do
    if low:find(phrase, 1, true) then return true end
  end
  return false
end

-- When such a paragraph says the rung comes back: the rest of it, after the
-- sentence that says it is late.
local function lateWhen(text)
  local bold, rest = text:match("^%*%*(.-)%*%*[%s%.,;:]*(.*)$")
  if bold and isLate(bold) then return (rest:match("^%s*(.-)%s*$")) end
  local low = text:lower()
  for _, phrase in ipairs(gm.config.latePhrases) do
    local _, e = low:find(phrase, 1, true)
    if e then
      local stop = text:find("[%.!?]%s", e)
      return stop and (text:sub(stop + 1):match("^%s*(.-)%s*$")) or ""
    end
  end
  return ""
end

-- "wisdom_perception", for a key in the play state.
local function slug(s)
  s = (gm.flat(s):lower():gsub("[^%w]+", "_"))
  s = (s:gsub("^_+", ""))
  return (s:gsub("_+$", ""))
end

-- The checks a page sets, in page order, each with `name` (unique on the
-- page), `short` (the skill), `sentence`, `section`, `kind` ("ladder",
-- "finds" or "dc"), `group`, `dc`, and `rungs` or `rows`. `late` is set
-- when the page says a missed top rung is late, not lost: what it says of
-- when the rung comes back, or "". Its rolls are kept by `base`, the
-- skill's slug, and `where`, its section's; `id` is its slot by its place
-- among the page's checks of that name, as rolls were kept before 3.8.
function gm.checks(page, text)
  text = text or (page and gm.exists(page) and space.readPage(page)) or ""
  if not text:find("%u%l+ %(%u") then return {} end
  local out, current, section = {}, nil, nil
  local function finish()
    local c = current
    current = nil
    if not c then return end
    if c.rows then
      c.kind = "finds"
    else
      local rungs = {}
      for _, r in ipairs(c.table or {}) do rungs[#rungs + 1] = r end
      if #c.prose > 0 and not c.table then
        -- a ladder in paragraphs gives any roll what comes before its first
        -- rung, or else the check's own paragraph
        rungs[#rungs + 1] = { at = 0, text = #c.pending > 0 and table.concat(c.pending, " ") or c.own }
      end
      for _, r in ipairs(c.prose) do rungs[#rungs + 1] = r end
      if #rungs > 0 then
        c.kind, c.rungs = "ladder", byRung(rungs)
      elseif c.dc then
        c.kind = "dc"
      else
        return
      end
    end
    -- how far a check written through party.dc rises for the party
    c.rise = c.scaled and dcRise() or 0
    out[#out + 1] = c
  end
  for _, b in ipairs(rollBlocks(text)) do
    if b.kind == "heading" then
      finish()
      section = b.text
    elseif b.kind == "table" then
      if current and not current.table and not current.rows then
        local scaled
        current.table, current.rows, scaled = readTable(b.rows)
        if scaled then current.scaled = true end
      end
    else
      local at, rest, scaled
      if current then at, rest, scaled = proseRung(b.text) end
      if at then
        if scaled then current.scaled = true end
        current.prose[#current.prose + 1] = { at = at, text = rest }
      elseif current and isLate(b.text) then
        -- a missed top rung comes back later, and this says when
        current.late = lateWhen(b.text)
      else
        local plain = gm.flat(b.text)
        local from, to = namedCheck(plain)
        if from then
          finish()
          local sentence = sentenceOf(plain, from, to)
          local dc = (undc(sentence)):match("DC (%d+)")
          current = {
            label = plain:sub(from, to), sentence = sentence, section = section,
            own = b.text, pending = {}, prose = {}, dc = num(dc),
            scaled = sentence:find("DC " .. DC_FORM) ~= nil,
            group = (" " .. sentence:lower() .. " "):find("[^%a]group[^%a]") ~= nil,
          }
        elseif current and #current.prose == 0 and not current.table and not current.rows
            and not b.text:find("^%$%{") and not b.text:find("^!%[%[") then
          current.pending[#current.pending + 1] = b.text
        end
      end
    end
  end
  finish()
  local used, count, taken, within = {}, {}, {}, {}
  for _, c in ipairs(out) do
    local base, n = slug(c.label), 1
    c.base, c.id = base, base
    while used[c.id] do
      n = n + 1
      c.id = base .. "_" .. int(n)
    end
    used[c.id] = true
    -- which of the page's checks of this name it is, by its section:
    -- "the_bank", "top" above any heading, "the_bank_2" for a second one
    local sec = c.section and slug(c.section) or ""
    if sec == "" then sec = "top" end
    within[base .. "@" .. sec] = (within[base .. "@" .. sec] or 0) + 1
    local k = within[base .. "@" .. sec]
    c.where = sec .. (k > 1 and ("_" .. int(k)) or "")
    c.short = (c.label:gsub("%a+ %(([^%)]*)%)", function(skill) return skill end))
    c.name = c.label .. (c.group and ", group" or "") ..
             ((c.kind == "dc") and (", DC " .. int(c.dc + c.rise)) or "")
    count[c.name] = (count[c.name] or 0) + 1
    -- a row's key is never "where", which says which check a slot is
    local keys = { where = true }
    for _, r in ipairs(c.rows or {}) do
      local k, m = slug(r.name), 1
      r.key = k
      while keys[r.key] do
        m = m + 1
        r.key = k .. "_" .. int(m)
      end
      keys[r.key] = true
    end
  end
  for _, c in ipairs(out) do
    if count[c.name] > 1 and c.section then c.name = c.name .. " · " .. gm.flat(c.section) end
    local name, n = c.name, 1
    while taken[name] do
      n = n + 1
      name = c.name .. " (" .. int(n) .. ")"
    end
    taken[name] = true
    c.name = name
  end
  return out
end

-- The bands a check's rungs make, lowest first, "Under 10", "10 to 14",
-- "15 to 19", "20 or more", each with the rungs it adds. `rise` is how far
-- a check written through party.dc rises for the party: the labels show
-- the party's DCs, and each band's floor stays the rung as written.
function gm.bands(rungs, rise)
  rise = rise or 0
  local ats, seen = { 0 }, { [0] = true }
  for _, r in ipairs(rungs) do
    if not seen[r.at] then
      seen[r.at] = true
      ats[#ats + 1] = r.at
    end
  end
  table.sort(ats)
  local out = {}
  for i, at in ipairs(ats) do
    local up, label = ats[i + 1], nil
    if not up then
      label = at == 0 and "Any roll" or (int(at + rise) .. " or more")
    elseif at == 0 then
      label = "Under " .. int(up + rise)
    elseif up == at + 1 then
      label = int(at + rise)
    else
      label = int(at + rise) .. " to " .. int(up - 1 + rise)
    end
    local adds = {}
    for _, r in ipairs(rungs) do
      if r.at == at then adds[#adds + 1] = r end
    end
    out[i] = { floor = at, label = label, adds = adds }
  end
  return out
end

local function bandLabel(rungs, floor, rise)
  for _, b in ipairs(gm.bands(rungs, rise)) do
    if b.floor == floor then return b.label end
  end
  return int(floor + (rise or 0)) .. " or more"
end

-- A check's rolls are kept in a slot of the page's play state named for the
-- skill: roll_wisdom_perception, and roll_wisdom_perception_2 and on for
-- more checks of that name. roll_<slot>_where says which check a slot is,
-- by the section it sits in, so a check added above one keeps clear of its
-- rolls. A slot without it holds rolls from before 3.8, and is the check at
-- that place among the page's checks of that name.

local function rollKey(check, row, id)
  return "roll_" .. (id or check.id) .. (row and ("_" .. row.key) or "")
end

-- Whether a slot holds anything of a check's: its roll, or a row's.
local function slotHolds(state, check, id)
  if state["roll_" .. id] ~= nil then return true end
  for _, r in ipairs(check.rows or {}) do
    if state["roll_" .. id .. "_" .. r.key] ~= nil then return true end
  end
  return false
end

-- The slot a check's rolls are in, or nil, and whether it is one from
-- before 3.8, found by the check's place rather than its section.
local function rollSlot(check, state)
  for k, v in pairs(state) do
    if v == check.where then
      local id = k:match("^roll_(.+)_where$")
      if id and (id == check.base or id:match("^" .. check.base .. "_%d+$")) then return id, false end
    end
  end
  if state["roll_" .. check.id .. "_where"] == nil and slotHolds(state, check, check.id) then
    return check.id, true
  end
  return nil, false
end

-- A slot with nothing in it for a check's first roll: the one its place
-- gives it where that is free, as before 3.8, or else the first free one.
local function newSlot(check, state)
  local function free(id)
    return state["roll_" .. id .. "_where"] == nil and state["roll_" .. id .. "_session"] == nil
      and not slotHolds(state, check, id)
  end
  if free(check.id) then return check.id end
  local n = 1
  while true do
    local id = n == 1 and check.base or (check.base .. "_" .. int(n))
    if free(id) then return id end
    n = n + 1
  end
end

-- A check's roll in a page's play state, and the session it was rolled in.
local function rollOf(check, state, row)
  local id = rollSlot(check, state)
  if not id then return nil, nil end
  local key = rollKey(check, row, id)
  return state[key], state[key .. "_session"]
end

-- The first roll logged on a page after 3.8 pins each slot from before it
-- to the check that has its place now, so a check added later can't move
-- them. Gives the fields to write.
local function pinSlots(checks, state)
  local fields = {}
  for _, c in ipairs(checks) do
    local id, old = rollSlot(c, state)
    if id and old then fields["roll_" .. id .. "_where"] = c.where end
  end
  return fields
end

local function topAt(rungs)
  local top = 0
  for _, r in ipairs(rungs) do
    if r.at > top then top = r.at end
  end
  return top
end

-- The top rung a check's rolls still owe, for a check its page calls late,
-- not lost, once a roll has been logged below it; nil for anything else.
local function owedAt(check, state, row)
  local rungs = row and row.rungs or check.rungs
  if not check.late or not rungs then return nil end
  local best, top = num((rollOf(check, state, row))), topAt(rungs)
  if best and best < top then return top end
  return nil
end

-- Where a link on `page` goes, as a page name, or nil for another site's.
local function linkTarget(page, path)
  if path:find("^%a[%w+%.%-]*:") or path:sub(1, 1) == "#" then return nil end
  local anchor = path:match("(#.*)$") or ""
  path = (path:gsub("#.*$", ""))
  path = (path:gsub("%.md$", ""))
  local parts = {}
  if path:sub(1, 1) ~= "/" then
    for seg in (page:match("^(.*)/[^/]*$") or ""):gmatch("[^/]+") do parts[#parts + 1] = seg end
  end
  for seg in path:gmatch("[^/]+") do
    if seg == ".." then
      parts[#parts] = nil
    elseif seg ~= "." then
      parts[#parts + 1] = seg
    end
  end
  return table.concat(parts, "/") .. anchor
end

-- A rung's words for the session's log: live values printed, and the page's
-- own links written so they still go where they went from another folder.
function gm.rollText(page, raw)
  local text = gm.print(raw, page)
  local function relink(bang, label, path)
    if bang == "!" then return nil end
    local to = linkTarget(page, path)
    if not to then return nil end
    return "[[" .. to .. "|" .. label .. "]]"
  end
  text = (text:gsub("(!?)%[([^%]]*)%]%(<([^>]*)>%)", relink))
  text = (text:gsub("(!?)%[([^%]]*)%]%(([^%)%s]*)%)", relink))
  text = (text:gsub("%s+", " "))
  return (text:match("^%s*(.-)%s*$"))
end

-- Where a roll's line in the log points: the check's section of its page,
-- where the section's name can go in a link, or else the page.
local function rollPlace(page, check)
  local sec = check and check.section
  if sec and not sec:find("[%[%]|#%^{}$]") then
    return "[[" .. page .. "#" .. sec .. "|" .. gm.name(page) .. "]]"
  end
  return "[[" .. page .. "|" .. gm.name(page) .. "]]"
end

-- The characters at the table tonight, by name: GM Party's when it is
-- there, else the character pages'. None while there are no character pages.
function gm.rollers()
  local out = {}
  if party and party.get then
    local ok, p = pcall(party.get)
    if ok and type(p) == "table" then
      if p.source == "characters" then
        for _, m in ipairs(p.here or {}) do out[#out + 1] = m.name end
      end
      return out
    end
  end
  local pcs = query[[
    from p = index.pages()
    where p.type == "pc"
    order by p.name
    select p.name
  ]]
  for _, name in ipairs(pcs) do out[#out + 1] = gm.name(name) end
  return out
end

-- Who rolled: "the party", a character's name, false where nobody is
-- asked (no character pages, or a group check, which is everybody's), or
-- nil for a question cancelled.
local function pickWho(check)
  if check and check.group then return false end
  local people = gm.rollers()
  if #people == 0 then return false end
  local options = { { name = "The party", description = "The best roll at the table", orderId = 1 } }
  for i, name in ipairs(people) do options[#options + 1] = { name = name, orderId = i + 1 } end
  local choice = editor.filterBox("Who rolled?", options,
    "The party, for the best roll at the table, or the one it belongs to", "Type to filter")
  if not choice then return nil end
  if choice.name == "The party" then return "the party" end
  return choice.name
end

-- How a check stands, for a bar: "✓ Perception: 15 to 19", linked to the
-- log of the session it was rolled in, "✗ Stealth: failed", or
-- "○ Investigation" for one nobody has rolled, with "· 20 owed" after a
-- rung still owed. `hint` gives the words alone, for a picker, and "" for
-- a check not rolled.
function gm.rollStanding(check, state, hint)
  if check.kind == "finds" then
    local got, owed = 0, 0
    for _, r in ipairs(check.rows) do
      if rollOf(check, state, r) then got = got + 1 end
      if owedAt(check, state, r) then owed = owed + 1 end
    end
    if got == 0 then return hint and "" or ("○ " .. check.short) end
    local words = int(got) .. " of " .. int(#check.rows) .. " found" ..
                  (owed > 0 and (", " .. int(owed) .. " owed") or "")
    return "✓ " .. (hint and words or (check.short .. ": " .. words))
  end
  local v, s = rollOf(check, state)
  if not v then return hint and "" or ("○ " .. check.short) end
  local words = v
  local rise = check.rise or 0
  if check.kind ~= "dc" and num(v) then words = bandLabel(check.rungs, num(v), rise) end
  local glyph = (check.kind == "dc" and v == "failed") and "✗ " or "✓ "
  local owed = owedAt(check, state)
  if hint then
    return glyph .. words .. (s and (", session " .. s) or "") ..
           (owed and (", " .. int(owed + rise) .. " owed") or "")
  end
  if s then words = "[[" .. gm.config.sessionsFolder .. "Session " .. s .. "|" .. words .. "]]" end
  return glyph .. check.short .. ": " .. words .. (owed and (" · " .. int(owed + rise) .. " owed") or "")
end

-- A roll's line for its session's log, worked out before anything is
-- written. It goes under ## Rolls, which comes in ahead of ## Decisions.
local function rollPlan(s, item)
  local log = gm.config.sessionsFolder .. "Session " .. s
  local existed = gm.exists(log)
  return { log = log, session = s, item = item,
           text = existed and gm.read(log) or gm.sessionTemplate(s) }
end

local function rollLogged(plan)
  gm.write(plan.log, gm.appendUnder(plan.text, "Rolls", plan.item, "Decisions"))
  return plan
end

-- Takes a roll's line back out of its log and nothing else. The Rolls
-- heading goes with the last line under it, and a log left as nothing but
-- its template goes, as it does for a mark.
local function rollUnlogged(done)
  if not done or not gm.exists(done.log) then return end
  local text = gm.removeItem(gm.read(done.log), done.item)
  text = gm.dropEmptySection(text, "Rolls")
  local function squeeze(t) return (t:gsub("%s+", " ")) end
  if squeeze(text) == squeeze(gm.sessionTemplate(done.session)) then
    space.deletePage(done.log)
  else
    gm.write(done.log, text)
  end
end

local WORDS = { "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten" }

-- "three things they know", "one more thing they know"
local function things(n, more)
  return (WORDS[n] or int(n)) .. (more and " more" or "") ..
         (n == 1 and " thing" or " things") .. " they know"
end

-- "under 10", for the middle of a line.
local function lowerFirst(s)
  return (s:gsub("^%u", function(c) return c:lower() end))
end

-- Logs a roll against one of a page's checks. `pick` says how it went:
-- `band`, one of gm.bands, and `row`, the thing found in a table of finds;
-- or `result`, "passed" or "failed", for a DC. `who` names who rolled. The
-- log gets the words of each rung reached that no roll has reached before,
-- and the page's play state the highest rung reached. A top rung the page
-- calls late, not lost, and the roll missed, is logged as owed, with when
-- it comes back.
function gm.recordRoll(page, check, pick)
  if gm.refuse() then return false end
  local s = gm.currentSession()
  local path = (gm.stateFor(page, true))
  local before = gm.exists(path) and gm.read(path) or nil
  local state = before and gm.frontmatter(before) or {}
  -- rolls from before 3.8 pinned to their checks, then this check's slot,
  -- which says whose it is
  local fields = pinSlots(gm.checks(page), state)
  for k, v in pairs(fields) do state[k] = v end
  local id = rollSlot(check, state) or newSlot(check, state)
  fields["roll_" .. id .. "_where"] = check.where
  local key = rollKey(check, pick.row, id)
  local was = state[key]
  local label = check.name .. (pick.row and (", " .. pick.row.name) or "")
  local who = pick.who and (", " .. pick.who) or ""
  local lines, what, outcome, note, owed = {}, nil, nil, nil, nil
  if check.kind == "dc" then
    fields[key], fields[key .. "_session"] = pick.result, s
    what, outcome = label .. who, pick.result
    note = outcome
  else
    local rungs = pick.row and pick.row.rungs or check.rungs
    local floor, best = pick.band.floor, num(was)
    local band = lowerFirst(pick.band.label)
    if best and floor <= best then
      what, outcome, note = label .. ", " .. band .. who, "nothing new", ", nothing new"
    else
      what = label .. ", " .. (best and ("now " .. band) or band) .. who
      for _, r in ipairs(rungs) do
        if r.at <= floor and (not best or r.at > best) then
          lines[#lines + 1] = gm.rollText(page, r.text)
        end
      end
      fields[key], fields[key .. "_session"] = int(floor), s
      outcome = #lines > 0 and things(#lines, best ~= nil) or "nothing from this check"
      if check.late and floor < topAt(rungs) then
        local top = int(topAt(rungs) + (check.rise or 0))
        owed = "Owed: the " .. top .. ", late, not lost." ..
               (check.late ~= "" and (" " .. gm.rollText(page, check.late)) or "")
        outcome = outcome .. ", the " .. top .. " owed"
      end
    end
  end
  local item = rollPlace(page, check) .. " · " .. what
  if #lines > 0 then item = item .. ":" else item = item .. ": " .. outcome end
  for _, l in ipairs(lines) do item = item .. "\n  - " .. l end
  if owed then item = item .. "\n  - " .. owed end
  local line = gm.sessionLink(s, true) .. ": " .. what ..
               ((check.kind == "dc") and (", " .. note) or (note or ""))
  -- everything read before anything is written, so a read that fails
  -- stops the roll before any of it has happened
  local plan = rollPlan(s, item)
  local _, written = gm.recordState(page, fields, line)
  local created = not before and written or nil
  local logged = rollLogged(plan)
  gm.refresh()
  local keys = {}
  for k in pairs(fields) do keys[#keys + 1] = k end
  table.sort(keys)
  gm.notify(what .. ": " .. outcome .. ", logged to session " .. s .. ".", {
    { name = "Open log", run = function() editor.navigate(logged.log) end },
    -- Undo takes back this roll and nothing logged since
    { name = "Undo", run = function()
      if gm.refuse() then return end
      gm.revert(path, before, keys, { line }, created)
      rollUnlogged(logged)
      gm.refresh()
      gm.notify("Undone: " .. what .. " is no longer logged")
    end },
  })
  return true
end

-- Asks how a roll against one of a page's checks went, and logs it: passed
-- or failed for a DC; else the thing found, for a table of finds, and how
-- high they rolled; then who, where there is anyone to ask about.
function gm.logCheck(page, check)
  if gm.refuse() then return false end
  local state = gm.readState(page, true)
  local pick = {}
  local rise = check.rise or 0
  if check.kind == "dc" then
    local options = {
      { name = "Passed", orderId = 1, description = check.group and "Half of them or more made it"
          or ("They met or beat DC " .. int(check.dc + rise)) },
      { name = "Failed", orderId = 2, description = check.group and "Fewer than half of them made it"
          or ("They rolled under DC " .. int(check.dc + rise)) },
    }
    local choice = editor.filterBox(check.name, options, "Did they make it?", "Type to filter")
    if not choice then return false end
    pick.result = choice.name:lower()
  else
    local rungs = check.rungs
    if check.kind == "finds" then
      local options = {}
      for i, r in ipairs(check.rows) do
        local v = num((rollOf(check, state, r)))
        options[i] = { name = r.name, orderId = i, description = shortText(gm.print(r.rungs[1].text, page), 120),
                       hint = v and ("✓ " .. bandLabel(r.rungs, v, rise)) or nil }
      end
      local choice = editor.filterBox(check.name, options, "What did they find?", "Type to filter")
      if not choice then return false end
      for _, r in ipairs(check.rows) do
        if r.name == choice.name then pick.row = r end
      end
      if not pick.row then return false end
      rungs = pick.row.rungs
    end
    local best = num((rollOf(check, state, pick.row)))
    local owed = owedAt(check, state, pick.row)
    local bands, options = gm.bands(rungs, rise), {}
    for i, b in ipairs(bands) do
      local words = {}
      for _, r in ipairs(b.adds) do words[#words + 1] = r.text end
      local d = table.concat(words, " ")
      if d == "" then d = "Nothing from this check" elseif i > 1 then d = "+ " .. d end
      local hint = nil
      if best == b.floor then hint = "✓ so far" elseif owed == b.floor then hint = "owed" end
      options[i] = { name = b.label, orderId = i, description = shortText(gm.print(d, page), 140),
                     hint = hint }
    end
    local choice = editor.filterBox(check.name .. (pick.row and (", " .. pick.row.name) or ""),
      options, "How high did they roll?", "Type to filter")
    if not choice then return false end
    for _, b in ipairs(bands) do
      if b.label == choice.name then pick.band = b end
    end
    if not pick.band then return false end
  end
  local who = pickWho(check)
  if who == nil then return false end
  if who then pick.who = who end
  return gm.recordRoll(page, check, pick)
end

-- The page a roll is logged against: the open page, when it is a scene or
-- sets checks of its own, else the scene the session is on.
function gm.rollPage()
  local current = editor.getCurrentPage()
  if gm.isAdventurePage(current) and (gm.isScene(current) or #gm.checks(current) > 0) then
    return current
  end
  local here = gm.sessionScene(gm.currentSession())
  if here then return here end
  if gm.isAdventurePage(current) then return current end
  return nil
end

-- A roll the page doesn't set: which skill or save, what they got, and
-- who. It goes into the session's log alone, since there is no check for
-- the page's play state to keep.
function gm.logOtherRoll(page)
  if gm.refuse() then return false end
  local options = {}
  for i, skill in ipairs(gm.skills) do options[i] = { name = skill, orderId = i } end
  for _, ability in ipairs(gm.abilities) do
    options[#options + 1] = { name = ability .. " saving throw", orderId = #options + 1 }
  end
  for _, ability in ipairs(gm.abilities) do
    options[#options + 1] = { name = ability .. " check", orderId = #options + 1 }
  end
  local choice = editor.filterBox("Another roll", options, "What did they roll?", "Type to filter")
  if not choice then return false end
  local s = gm.currentSession()
  local got = editor.prompt(choice.name .. ": what did they get? (session " .. s .. ")", "")
  got = got and got:match("^%s*(.-)%s*$") or ""
  if got == "" then return false end
  local who = pickWho(nil)
  if who == nil then return false end
  local what = choice.name .. (who and (", " .. who) or "")
  local item = (page and (rollPlace(page, nil) .. " · ") or "") .. what .. ": " .. got
  local logged = rollLogged(rollPlan(s, item))
  gm.refresh()
  gm.notify(what .. ": logged to session " .. s .. ".", {
    { name = "Open log", run = function() editor.navigate(logged.log) end },
    { name = "Undo", run = function()
      if gm.refuse() then return end
      rollUnlogged(logged)
      gm.refresh()
      gm.notify("Undone: " .. what .. " is no longer logged")
    end },
  })
  return true
end

-- Logs a roll: which of the page's checks, then how it went. A page that
-- sets none goes straight to a roll it doesn't set.
function gm.logRoll(page)
  if gm.refuse() then return false end
  page = page or gm.rollPage()
  local checks = page and gm.checks(page) or {}
  if #checks == 0 then return gm.logOtherRoll(page) end
  local state = gm.readState(page, true)
  local options = {}
  for i, c in ipairs(checks) do
    local standing = gm.rollStanding(c, state, true)
    options[i] = { name = c.name, orderId = i, description = shortText(gm.print(c.sentence, page), 140),
                   hint = standing ~= "" and standing or nil }
  end
  options[#options + 1] = { name = OTHER, orderId = #options + 1,
    description = "A roll this page doesn't set: say what it was and what they got" }
  local title = gm.isScene(page) and gm.sceneTitle(page) or gm.name(page)
  local choice = editor.filterBox("Log a roll", options, title .. ": which check?", "Type to filter")
  if not choice then return false end
  if choice.name == OTHER then return gm.logOtherRoll(page) end
  for _, c in ipairs(checks) do
    if c.name == choice.name then return gm.logCheck(page, c) end
  end
  return false
end

-- The rolls a page's play state records: each check rolled, and each
-- thing found of a table of finds.
local function rolledOn(checks, state)
  local out = {}
  for _, c in ipairs(checks) do
    if c.kind == "finds" then
      for _, r in ipairs(c.rows) do
        if rollOf(c, state, r) then out[#out + 1] = { check = c, row = r } end
      end
    elseif rollOf(c, state) then
      out[#out + 1] = { check = c }
    end
  end
  return out
end

-- Takes a roll off a page's play state, for one logged by mistake, with
-- Undo. Both logs keep what they said and add that it was taken back, the
-- way an unmark's do, so a later roll counts afresh.
function gm.unlogRoll(page, check, row)
  if gm.refuse() then return false end
  local path, s = (gm.stateFor(page, true)), gm.currentSession()
  local label = check.name .. (row and (", " .. row.name) or "")
  local before = gm.exists(path) and gm.read(path) or nil
  local state = before and gm.frontmatter(before) or {}
  local id = rollSlot(check, state)
  local key = id and rollKey(check, row, id)
  if not key or not state[key] then
    gm.notify(label .. " isn't logged")
    return false
  end
  local keys = { key, key .. "_session" }
  -- a slot left with nothing in it lets go of its check
  state[key], state[key .. "_session"] = nil, nil
  if not slotHolds(state, check, id) then keys[#keys + 1] = "roll_" .. id .. "_where" end
  local text = before
  for _, k in ipairs(keys) do text = gm.clearFrontmatter(text, k) end
  local line = gm.sessionLink(s, true) .. ": " .. label .. ", not rolled after all"
  local plan = rollPlan(s, rollPlace(page, check) .. " · " .. label .. ": not rolled after all")
  gm.write(path, gm.appendItem(text, line))
  local logged = rollLogged(plan)
  gm.refresh()
  gm.notify(label .. ": no longer logged.", {
    { name = "Undo", run = function()
      if gm.refuse() then return end
      if not gm.revert(path, before, keys, { line }) then gm.write(path, before) end
      rollUnlogged(logged)
      gm.refresh()
      gm.notify("Undone: " .. label .. " is logged again")
    end },
  })
  return true
end

-- Asks which of a page's rolls was logged by mistake, and takes it off.
function gm.pickUnlog(page)
  if gm.refuse() then return false end
  local state = gm.readState(page, true)
  local rolled = rolledOn(gm.checks(page), state)
  if #rolled == 0 then
    gm.notify(gm.name(page) .. ": no rolls logged to take back")
    return false
  end
  local options = {}
  for i, x in ipairs(rolled) do
    local v, at = rollOf(x.check, state, x.row)
    local rungs = x.row and x.row.rungs or x.check.rungs
    local words = (rungs and num(v)) and bandLabel(rungs, num(v), x.check.rise) or v
    options[i] = { name = x.check.name .. (x.row and (", " .. x.row.name) or ""), orderId = i,
                   description = words .. (at and (", session " .. at) or "") }
  end
  local choice = editor.filterBox("Unlog a roll", options, "Which roll was logged by mistake?", "Type to filter")
  if not choice then return false end
  for i, x in ipairs(rolled) do
    if options[i].name == choice.name then return gm.unlogRoll(page, x.check, x.row) end
  end
  return false
end

-- A row on a page's bar for the checks it sets: how each stands, and the
-- buttons to log a roll and to take one back.
function gm.rollRow(page, checks, state)
  local spec = { class = "gmkit-item" }
  local function add(x) spec[#spec + 1] = x end
  local function note(text) add(dom.span { class = "gmkit-bar-note", text }) end
  note("**Checks**")
  local any = false
  for _, c in ipairs(checks) do
    if gm.rollStanding(c, state, true) ~= "" then any = true end
    note(gm.rollStanding(c, state))
  end
  add(gm.button("Log a roll…", function() gm.logRoll(page) end))
  if any then add(gm.button("Unlog a roll…", function() gm.pickUnlog(page) end)) end
  return dom.div(spec)
end

-- Every top rung still owed, late, not lost, in the order the adventure is
-- played: { page, check, row, at, since, when }. Only a check somebody has
-- rolled owes anything.
function gm.owedRungs()
  gm.freshStates()
  local pages, seen, out = {}, {}, {}
  for _, page in ipairs(gm.scenes()) do
    pages[#pages + 1] = page
    seen[page] = true
  end
  for _, page in ipairs(gm.adventurePages()) do
    if not seen[page] then pages[#pages + 1] = page end
  end
  for _, page in ipairs(pages) do
    local state, rolled = gm.readState(page), false
    for k in pairs(state) do
      if k:sub(1, 5) == "roll_" then rolled = true end
    end
    if rolled then
      for _, c in ipairs(gm.checks(page)) do
        local function add(row)
          local at = owedAt(c, state, row)
          if at then
            local _, since = rollOf(c, state, row)
            out[#out + 1] = { page = page, check = c, row = row, at = at,
                              since = since, when = c.late }
          end
        end
        if c.rows then
          for _, row in ipairs(c.rows) do add(row) end
        else
          add(nil)
        end
      end
    end
  end
  return out
end

-- What is owed, for the session table: a line for each rung a roll missed
-- that its page says comes back later, with when.
function gm.owed()
  local lines = {}
  for _, o in ipairs(gm.owedRungs()) do
    local line = "- " .. rollPlace(o.page, o.check) .. " · " .. o.check.name ..
                 (o.row and (", " .. o.row.name) or "") .. ": the " .. int(o.at + (o.check.rise or 0)) ..
                 (o.since and (", owed since " .. gm.sessionLink(o.since)) or "")
    if o.when and o.when ~= "" then line = line .. ". " .. gm.rollText(o.page, o.when) end
    lines[#lines + 1] = line
  end
  local md = #lines > 0 and table.concat(lines, "\n") or "Nothing is owed."
  return widget.new { markdown = md, display = "block" }
end

-- What the notification says of a private page, for reveal and publish.
local function privateNote(page)
  return gm.name(page) .. " is a " .. tostring(gm.pageType(page)) ..
    " page, which keeps what only the DM may see in the page itself, so it is " ..
    "never revealed or published. The players see what a page they have shows of it."
end

function gm.reveal(page)
  if gm.refuse() then return false end
  if gm.isPrivate(page) then
    gm.notify(privateNote(page), nil, "warning")
    return false
  end
  if gm.hidesName(page) then
    gm.notify(hiddenNameNote(page), nil, "warning")
    return false
  end
  local before = gm.revealEntries(page)
  if not gm.setRevealed(page, true) then
    gm.notify(gm.name(page) .. " is already revealed")
    return false
  end
  local after = gm.revealEntries(page)
  gm.refresh()
  gm.notify("Revealed " .. gm.name(page) .. ". The players see it once you publish.", {
    { name = "Publish now", run = function() gm.publish() end },
    { name = "Preview", run = function() gm.previewPublish() end },
    { name = "Undo", run = function()
      if gm.refuse() then return end
      gm.undoReveals(page, before, after)
      gm.refresh()
    end },
  })
  return true
end

-- Asks which part of a page to reveal, of those not revealed yet.
function gm.pickPart(page)
  if gm.refuse() then return nil end
  local now = gm.revealedPart(page)
  if now == true then
    gm.notify(gm.name(page) .. " is revealed whole already")
    return nil
  end
  local have, options = {}, {}
  for _, n in ipairs(now or {}) do have[n] = true end
  for i, part in ipairs(gm.parts(page).parts) do
    if not have[part.name] then options[#options + 1] = { name = part.name, orderId = i } end
  end
  if #options == 0 then
    gm.notify("Every part of " .. gm.name(page) .. " is revealed already")
    return nil
  end
  local choice = editor.filterBox("Reveal part", options,
    "Which part of " .. gm.name(page) .. " have the players learned?", "Type to filter")
  return choice and choice.name or nil
end

-- Reveals one part of a page, one of its `##` sections, with Undo.
-- Publishing then sends the players the page's title and the parts
-- revealed, and nothing that says there is more.
function gm.revealPart(page, part)
  if gm.refuse() then return false end
  if gm.isPrivate(page) then
    gm.notify(privateNote(page), nil, "warning")
    return false
  end
  if gm.hidesName(page) then
    gm.notify(hiddenNameNote(page), nil, "warning")
    return false
  end
  local before, now = gm.revealEntries(page), gm.revealedPart(page)
  if now == true then
    gm.notify(gm.name(page) .. " is revealed whole already")
    return false
  end
  for _, n in ipairs(now or {}) do
    if n == part then
      gm.notify("“" .. part .. "” of " .. gm.name(page) .. " is already revealed")
      return false
    end
  end
  local list = gm.readRevealed()
  list[#list + 1] = page .. "#" .. part
  gm.writeRevealed(list)
  local after = gm.revealEntries(page)
  gm.refresh()
  gm.notify("Revealed “" .. part .. "” of " .. gm.name(page) .. ". The players see it once you publish.", {
    { name = "Publish now", run = function() gm.publish() end },
    { name = "Preview", run = function() gm.previewPublish() end },
    { name = "Undo", run = function()
      if gm.refuse() then return end
      gm.undoReveals(page, before, after)
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
  if gm.refuse() then return false end
  local name, copy = gm.name(page), gm.playerCopy(page)
  local copyText = copy and gm.exists(copy) and space.readPage(copy) or nil
  local entries = gm.revealEntries(page)
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
  -- the DM's layer again, and a page hiding its name would give it away
  if gm.isPrivate(page) or gm.hidesName(page) then
    gm.notify(message)
    return true
  end
  gm.notify(message, {
    { name = "Undo", run = function()
      if gm.refuse() then return end
      if listed then gm.undoReveals(page, entries, {}) end
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

-- The stretches of a text that are ${...} expressions, as SilverBullet's
-- own parser finds them: { from, to }, counted from 1.
local function expressionRanges(text)
  local out = {}
  if not text:find("${", 1, true) then return out end
  local function walk(node)
    if node.type == "LuaDirective" then
      out[#out + 1] = { node.from + 1, node.to }
    elseif node.children then
      for _, child in ipairs(node.children) do walk(child) end
    end
  end
  walk(markdown.parseMarkdown(text))
  return out
end

-- The page a Markdown link's (...) names, its %XX codes read, or nil for a
-- link to another site, within the page, or to nothing.
local function pageUrl(paren)
  local body = paren:sub(2, -2)
  local url = body:match("^%s*<(.-)>") or body:match("^%s*(%S*)")
  if url == "" or url:find("^%a[%w+%.%-]*:") or url:find("^//") or url:find("^#") then return nil end
  return (url:gsub("%%(%x%x)", function(h)
    local n = tonumber(h, 16)
    if n and n >= 32 and n < 127 then return string.char(n) end
  end))
end

-- A text with `relink` run over its prose: every line outside fenced code,
-- and in each line whatever isn't inline code or a ${...} expression. A
-- line that held something and is left with nothing, an embed that went,
-- goes too, and so does a blank line next to it.
local function relinkProse(text, relink)
  local exprs = expressionRanges(text)
  local out, pos, fence, cut = {}, 1, nil, false
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    local first, last = pos, pos + #line - 1
    pos = pos + #line + 1
    local q = line:match("^[%s>]*(.*)$")
    local mark = q:match("^(```+)") or q:match("^(~~~+)")
    if fence or mark then
      if fence then
        if mark and mark:sub(1, 1) == fence:sub(1, 1) and #mark >= #fence then fence = nil end
      else
        fence = mark
      end
      out[#out + 1] = line
      cut = false
    else
      -- what stays as it is: the line's inline code, and any expression
      local keep = {}
      for _, e in ipairs(exprs) do
        if e[2] >= first and e[1] <= last then
          keep[#keep + 1] = { math.max(e[1], first) - first + 1, math.min(e[2], last) - first + 1 }
        end
      end
      local i = 1
      while true do
        local a = line:find("`", i, true)
        if not a then break end
        local run = line:match("^`+", a)
        local close = line:find(run, a + #run, true)
        if not close then break end
        keep[#keep + 1] = { a, close + #run - 1 }
        i = close + #run
      end
      table.sort(keep, function(x, y) return x[1] < y[1] end)
      local parts, at = {}, 1
      for _, k in ipairs(keep) do
        if k[1] > at then parts[#parts + 1] = relink(line:sub(at, k[1] - 1)) end
        if k[2] >= at then parts[#parts + 1] = line:sub(math.max(at, k[1]), k[2]) end
        if k[2] + 1 > at then at = k[2] + 1 end
      end
      parts[#parts + 1] = relink(line:sub(at))
      local new = table.concat(parts)
      if line:match("%S") and not new:match("%S") then
        -- a line that held nothing but an embed that went goes with it
        cut = true
      elseif cut and not new:match("%S") and (#out == 0 or not out[#out]:match("%S")) then
        cut = false
      else
        out[#out + 1] = new
        cut = false
      end
    end
  end
  return table.concat(out, "\n")
end

-- A players' copy without links to pages the players won't have. `shown`
-- holds each adventure page this publish sends: true for the whole page,
-- or the names of the parts sent. A link to any other adventure page, one
-- hidden, private, kept back or gone, becomes its label, and a wiki link
-- without one the name it shows, since the prose shows that anyway; an
-- embed of such a page, or of a section the players don't get, goes, and
-- is named in `dropped`. Links to other sites, within the page, or to
-- pages outside the adventure stay, and so do code and ${...} expressions.
-- `cache` keeps what each wiki link resolved to, over one publish.
function gm.unlink(text, page, shown, dropped, cache)
  if not text:find("[[", 1, true) and not text:find("](", 1, true) then return text end
  cache = cache or {}
  local prefix = gm.config.adventureFolder
  local function resolve(ref)
    if cache[ref] == nil then
      local found = gm.resolve(ref)
      if not found and ref:startsWith(prefix) then found = ref end
      cache[ref] = found or false
    end
    return cache[ref] or nil
  end
  local function wiki(bang, inner)
    local ref, alias = inner:match("^(.-)|(.*)$")
    ref = ref or inner
    local name, section = ref:match("^(.-)#(.*)$")
    name = name or ref
    if name == "" then return nil end
    local to = resolve(name)
    if not to or not gm.isAdventurePage(to) then return nil end
    local sent = shown[to]
    if bang == "!" then
      if sent == true or (sent and (not section or table.includes(sent, section))) then return nil end
      dropped[#dropped + 1] = "![[" .. inner .. "]] in " .. page
      return ""
    end
    if sent then return nil end
    return alias or gm.name(to)
  end
  local function markdownLink(bang, label, paren)
    if bang == "!" then return nil end
    local url = pageUrl(paren)
    if not url then return nil end
    local to = linkTarget(page, url)
    if not to then return nil end
    to = (to:gsub("#.*$", ""))
    if not gm.isAdventurePage(to) or shown[to] then return nil end
    return label
  end
  return relinkProse(text, function(s)
    s = (s:gsub("(!?)%[%[([^%]\n]-)%]%]", wiki))
    return (s:gsub("(!?)%[([^%]\n]*)%](%b())", markdownLink))
  end)
end

-- The players' copies that no revealed page makes any more: a page renamed,
-- deleted or unrevealed since it was published. SilverBullet 2.11 has no
-- rename event, and its rename rewrites the revealed list, so publishing
-- writes the new copy and nothing else sees the old one. The Player space's
-- own index, CONFIG, Notes and libraries are never among them, nor the
-- sessions' recaps in its recapFolder, which no adventure page makes, nor
-- a private page's copy, which publishing names with how to take it back.
-- `of` is gm.reveals()'s second value.
function gm.orphanCopies(of)
  local folder, notes, prefix = gm.config.playerFolder, gm.config.playerNotes, gm.config.adventureFolder
  local names = query[[
    from p = index.pages()
    where p.name:startsWith(folder)
    order by p.name
    select p.name
  ]]
  local private, out = gm.privatePages(), {}
  for _, copy in ipairs(names) do
    local rel = copy:sub(#folder + 1)
    if rel ~= "index" and rel ~= "CONFIG" and not rel:startsWith(notes)
        and not rel:startsWith("Library/") and not rel:startsWith(gm.config.recapFolder) then
      local page = prefix .. rel
      if not private[page] and (not of[page] or not gm.exists(page)) and gm.exists(copy) then
        out[#out + 1] = copy
      end
    end
  end
  return out
end

-- Everything a publish would do, worked out before anything is written:
-- each players' copy as it would go, and what is kept back and why. It
-- writes nothing, so the preview (gm.previewPublish) shows exactly what
-- Publish then sends. `copies` are { page, copy, text }; `kept` the pages
-- kept back, { page, why }; `private` the private pages on the revealed
-- list; `leaked` the private pages the players still have a copy of;
-- `named` the pages whose name is DM-only that they have a copy of;
-- `dropped` the embeds left out, "![[...]] in <page>"; `missing` what is
-- revealed but no longer there, pages and parts; `orphans` the copies no
-- revealed page makes any more; and `of`, gm.reveals()'s second value.
function gm.publishPlan()
  local plan = { copies = {}, kept = {}, private = {}, leaked = {}, named = {},
                 dropped = {}, missing = {}, orphans = {} }
  local pages = {}
  local order, of = gm.reveals()
  plan.of = of
  for _, page in ipairs(order) do
    if gm.playerCopy(page) then
      if not gm.exists(page) then
        plan.missing[#plan.missing + 1] = page
      elseif gm.isPrivate(page) then
        plan.private[#plan.private + 1] = page
      else
        pages[#pages + 1] = page
      end
    end
  end
  -- A private page is never published. One on the list, from before GM Kit
  -- refused them, is named. One the players still have a copy of, on the
  -- list or not, is named with how to take it back from its own bar.
  local seen = {}
  for _, page in ipairs(plan.private) do seen[page] = true end
  for page in pairs(gm.privatePages()) do seen[page] = true end
  local all = {}
  for page in pairs(seen) do all[#all + 1] = page end
  table.sort(all)
  for _, page in ipairs(all) do
    local copy = gm.playerCopy(page)
    if copy and gm.exists(copy) then plan.leaked[#plan.leaked + 1] = page end
  end
  -- Every copy is made before anything is written, so one that can't go is
  -- named and the rest go without it. Kept back: a page that hides its
  -- name, since its copy would sit at a path that names it; a copy with
  -- nothing in it; and a copy that still holds a DM-only mark once its
  -- DM-only text is out, since what the mark hides may not be out with it.
  for _, page in ipairs(pages) do
    local raw = space.readPage(page)
    if gm.hidesName(page, raw) then
      plan.kept[#plan.kept + 1] = { page = page, why = "hides its name in DM-only text" }
      if gm.exists(gm.playerCopy(page)) then plan.named[#plan.named + 1] = page end
    else
      local text = gm.print(gm.copyText(page, raw, of[page], plan.missing), page)
      local marks = gm.dmMarks(text)
      local _, body = gm.splitFrontmatter(text)
      if #marks > 0 then
        plan.kept[#plan.kept + 1] = { page = page,
          why = "still has DM-only marks (" .. table.concat(marks, ", ") .. ")" }
      elseif not (body or text):find("%S") then
        plan.kept[#plan.kept + 1] = { page = page, why = "would be empty" }
      else
        plan.copies[#plan.copies + 1] = { page = page, copy = gm.playerCopy(page), text = text }
      end
    end
  end
  -- A link to a page the players won't have becomes its label, since
  -- following it would open an empty page that names it, and an embed of
  -- one goes.
  local shown, cache = {}, {}
  for _, c in ipairs(plan.copies) do shown[c.page] = of[c.page] end
  for _, c in ipairs(plan.copies) do
    c.text = gm.unlink(c.text, c.page, shown, plan.dropped, cache)
  end
  plan.orphans = gm.orphanCopies(of)
  return plan
end

-- What a publish's notification says of its plan: what it leaves out and
-- why, and what is revealed but no longer there.
local function planNotes(plan)
  local held = ""
  if #plan.private > 0 then
    held = " Left out, as only the DM may see them: " .. table.concat(plan.private, ", ") .. "."
  end
  if #plan.leaked > 0 then
    held = held .. " The players still have a copy of " .. table.concat(plan.leaked, ", ") ..
           ", sent before such pages were kept to the DM: take it back with" ..
           " Delete their copy on its bar."
  end
  if #plan.kept > 0 then
    local kept = {}
    for i, k in ipairs(plan.kept) do kept[i] = k.page .. " " .. k.why end
    held = held .. " Kept back: " .. table.concat(kept, "; ") .. "."
  end
  if #plan.dropped > 0 then
    held = held .. " Embeds left out, as the players don't have what they show: " ..
           table.concat(plan.dropped, ", ") .. "."
  end
  if #plan.named > 0 then
    held = held .. " The players still have a copy of " .. table.concat(plan.named, ", ") ..
           ", which gives them its name: take it back with Delete their copy on its bar."
  end
  local gone = ""
  if #plan.missing > 0 then
    gone = " Revealed but no longer there: " .. table.concat(plan.missing, ", ") .. "."
  end
  return held, gone
end

-- The time, to the second, as GM Kit's own pages give it.
local function now()
  return os.date("!%Y-%m-%d %H:%M:%S") .. " UTC"
end

-- A page as a link on GM Kit's own pages.
local function pageLink(page)
  return "[[" .. page .. "]]"
end

-- A line cut at a space near n characters, and saying so.
local function cutLine(line, n)
  line = (line:gsub("%s+$", ""))
  if #line <= n then return line end
  local at, i = nil, 1
  while true do
    local space = line:find(" ", i, true)
    if not space or space > n then break end
    at, i = space, space + 1
  end
  if not at then return line end
  return line:sub(1, at - 1) .. " …"
end

-- Lines quoted from pages as a fenced code block of their own, a blank line
-- either side and its fences at the start of the line, where every reader
-- of Markdown agrees it is one. Every space-lua block in the space runs,
-- and every ${...} on a page shown, so what a page quotes must never be read
-- as either: in fenced code none of it runs, links, or counts as a DM-only
-- mark, and its fence, longer than any run of backticks in the lines, can't
-- be closed by one of them.
local function fenced(lines)
  local run = 2
  for _, l in ipairs(lines) do
    for ticks in l:gmatch("`+") do
      if #ticks > run then run = #ticks end
    end
  end
  local fence = string.rep("`", run + 1)
  local out = { "", fence }
  for _, l in ipairs(lines) do out[#out + 1] = l end
  out[#out + 1] = fence
  out[#out + 1] = ""
  return out
end

-- Lines with no two blank ones together, and none at either end.
local function tidy(lines)
  local out = {}
  for _, l in ipairs(lines) do
    if l ~= "" or (#out > 0 and out[#out] ~= "") then out[#out + 1] = l end
  end
  while out[#out] == "" do out[#out] = nil end
  return out
end

-- A name, a page's or a part's, as words on a page of GM Kit's own: each
-- character that could begin a link, code, a tag, an HTML comment or a
-- live value is escaped, so the name shows as written and nothing in it
-- runs.
local function plain(s)
  return (s:gsub("[\\`*_{}%[%]<>#!$|~]", "\\%0"))
end

-- The lines that change between the copy the players have and the one that
-- would replace it, in page order, each as { sign, line }: "−" for a line
-- that goes, "+" for one that comes. What the two share at the start and at
-- the end is set aside, and what is left is matched line by line where it
-- is short enough, or else set against each other as two lists.
local function lineChanges(old, new)
  local a, b = {}, {}
  for line in (old .. "\n"):gmatch("([^\n]*)\n") do a[#a + 1] = line end
  for line in (new .. "\n"):gmatch("([^\n]*)\n") do b[#b + 1] = line end
  local s = 1
  while s <= #a and s <= #b and a[s] == b[s] do s = s + 1 end
  local ea, eb = #a, #b
  while ea >= s and eb >= s and a[ea] == b[eb] do ea, eb = ea - 1, eb - 1 end
  local n, m, out = ea - s + 1, eb - s + 1, {}
  if n * m <= 2500 then
    -- run[i][j]: how many lines the two share, in order, from a's i-th and
    -- b's j-th line of what is left on
    local run = {}
    for i = n + 1, 1, -1 do
      run[i] = {}
      for j = m + 1, 1, -1 do
        if i > n or j > m then
          run[i][j] = 0
        elseif a[s + i - 1] == b[s + j - 1] then
          run[i][j] = run[i + 1][j + 1] + 1
        else
          run[i][j] = math.max(run[i + 1][j], run[i][j + 1])
        end
      end
    end
    local i, j = 1, 1
    while i <= n or j <= m do
      if i <= n and j <= m and a[s + i - 1] == b[s + j - 1] then
        i, j = i + 1, j + 1
      elseif i <= n and (j > m or run[i + 1][j] >= run[i][j + 1]) then
        out[#out + 1] = { "−", a[s + i - 1] }
        i = i + 1
      else
        out[#out + 1] = { "+", b[s + j - 1] }
        j = j + 1
      end
    end
  else
    local inOld, inNew = {}, {}
    for i = s, ea do inOld[a[i]] = (inOld[a[i]] or 0) + 1 end
    for j = s, eb do inNew[b[j]] = (inNew[b[j]] or 0) + 1 end
    for i = s, ea do
      if (inNew[a[i]] or 0) > 0 then inNew[a[i]] = inNew[a[i]] - 1
      else out[#out + 1] = { "−", a[i] } end
    end
    for j = s, eb do
      if (inOld[b[j]] or 0) > 0 then inOld[b[j]] = inOld[b[j]] - 1
      else out[#out + 1] = { "+", b[j] } end
    end
  end
  -- a blank line that comes or goes changes nothing the players read
  local read = {}
  for _, c in ipairs(out) do
    if c[2]:find("%S") then read[#read + 1] = c end
  end
  return read
end

-- "1 line removed, 2 added", in words beside the signs.
local function changeCount(changes)
  local gone, came = 0, 0
  for _, c in ipairs(changes) do
    if c[1] == "+" then came = came + 1 else gone = gone + 1 end
  end
  local out = {}
  if gone > 0 then out[#out + 1] = int(gone) .. (gone == 1 and " line" or " lines") .. " removed" end
  if came > 0 then
    out[#out + 1] = int(came) .. (gone > 0 and "" or (came == 1 and " line" or " lines")) .. " added"
  end
  if #out == 0 then return "only its blank lines, or the order of its lines" end
  return table.concat(out, ", ")
end

-- How many of a copy's changed lines the preview shows, and how long each.
local DIFF_LINES, DIFF_WIDTH = 8, 100

-- What a copy is made of: the whole page, its name, or the parts revealed.
local function madeOf(page, reveal)
  if reveal == true then return "the whole page" end
  local name, parts = gm.parts(page).name, {}
  for _, n in ipairs(reveal) do
    if n ~= name then parts[#parts + 1] = plain(n) end
  end
  if #parts == 0 then return "its name only" end
  return partNames(parts)
end

-- An embed left out, "![[...]] in <page>", as its embed and its page.
local function droppedParts(d)
  local embed, page = d:match("^(!%[%[[^%]]*%]%]) in (.*)$")
  return embed or d, page
end

-- The lines of the plan's pages that go unsent, as lists for a page of
-- GM Kit's own: what is kept back and why, what is no longer there, and
-- what only the DM may see; and the embeds left out, by the page they are
-- on, as { page, embeds }, to quote in fenced code.
local function heldLines(plan)
  local kept, embeds, gone, private = {}, {}, {}, {}
  local named = {}
  for _, p in ipairs(plan.named) do named[p] = true end
  for _, k in ipairs(plan.kept) do
    kept[#kept + 1] = "- " .. pageLink(k.page) .. " " .. k.why ..
      (named[k.page] and (". The players still have a copy of it, which gives them its name: " ..
        "take it back with *Delete their copy* on its bar") or "")
  end
  local on = {}
  for _, d in ipairs(plan.dropped) do
    local embed, page = droppedParts(d)
    local key = page or ""
    if not on[key] then
      on[key] = { page = page, embeds = {} }
      embeds[#embeds + 1] = on[key]
    end
    local list = on[key].embeds
    list[#list + 1] = embed
  end
  for _, m in ipairs(plan.missing) do
    local page, part = entryParts(m)
    if part and gm.exists(page) then
      gone[#gone + 1] = "- " .. pageLink(page) .. ": “" .. plain(part) .. "” isn't one of its parts any more"
    else
      gone[#gone + 1] = "- " .. plain(m)
    end
  end
  for _, p in ipairs(plan.private) do
    private[#private + 1] = "- " .. pageLink(p) .. " is left out: only the DM may see it"
  end
  for _, p in ipairs(plan.leaked) do
    private[#private + 1] = "- The players still have a copy of " .. pageLink(p) ..
      ", sent before such pages were kept to the DM: take it back with *Delete their copy* on its bar"
  end
  return kept, embeds, gone, private
end

-- The preview: what publishing would send now, a copy at a time, and all
-- that it wouldn't, on a page of GM Kit's own, with a button to publish.
local function previewText(plan, new, changed, same)
  local out = {
    "---", "type: state", "---", "",
    "# Publish preview", "",
    "What publishing would do, worked out " .. now() .. " in session " ..
      int(gm.currentSession()) .. ". Nothing has been sent: the players' copies are as they were.", "",
    '${widgets.commandButton("Publish now", "GM: Publish to Players")} ' ..
      '${widgets.commandButton("Preview again", "GM: Preview Publish")}',
  }
  local function section(heading, lines, after)
    lines = tidy(lines)
    if #lines == 0 then return end
    out[#out + 1] = ""
    out[#out + 1] = "## " .. heading
    out[#out + 1] = ""
    for _, l in ipairs(lines) do out[#out + 1] = l end
    if after then
      out[#out + 1] = ""
      out[#out + 1] = after
    end
  end
  local lines = {}
  for _, c in ipairs(new) do
    lines[#lines + 1] = "- " .. pageLink(c.page) .. ": " .. madeOf(c.page, plan.of[c.page])
  end
  section("New copies", lines)
  lines = {}
  for _, c in ipairs(changed) do
    local changes = lineChanges(c.old, c.text)
    lines[#lines + 1] = "- " .. pageLink(c.page) .. ": " .. changeCount(changes)
    local quoted = {}
    for i, x in ipairs(changes) do
      if i > DIFF_LINES then
        quoted[#quoted + 1] = "… and " .. int(#changes - DIFF_LINES) .. " more"
        break
      end
      quoted[#quoted + 1] = x[1] .. " " .. cutLine(x[2], DIFF_WIDTH)
    end
    if #quoted > 0 then
      for _, l in ipairs(fenced(quoted)) do lines[#lines + 1] = l end
    end
  end
  section("Changed copies", lines)
  lines = {}
  for _, c in ipairs(same) do lines[#lines + 1] = "- " .. pageLink(c.page) end
  section("Unchanged", lines)
  local kept, embeds, gone, private = heldLines(plan)
  section("Kept back", kept, "The players keep what they have of these until each is put right.")
  lines = {}
  for _, g in ipairs(embeds) do
    lines[#lines + 1] = "- In " .. (g.page and pageLink(g.page) or "a copy") .. ":"
    for _, l in ipairs(fenced(g.embeds)) do lines[#lines + 1] = l end
  end
  section("Embeds left out", lines, "The players don't have what these show.")
  section("Revealed but no longer there", gone)
  section("Only for the DM", private)
  lines = {}
  for _, copy in ipairs(plan.orphans) do lines[#lines + 1] = "- " .. pageLink(copy) end
  section("Copies no revealed page makes any more", lines,
    "Renamed, deleted or unrevealed since they were published: publishing asks before it deletes them.")
  if #plan.copies + #plan.kept + #plan.missing + #plan.private + #plan.leaked + #plan.orphans == 0 then
    out[#out + 1] = ""
    out[#out + 1] = "Nothing is revealed yet, so there is nothing to publish."
  end
  return table.concat(out, "\n") .. "\n"
end

-- Shows what publishing would do, on the page gm.config.previewPage, and
-- sends nothing: each copy it would make, new, changed with the lines that
-- change, or unchanged; what it keeps back and why; the embeds it leaves
-- out; and the copies no revealed page makes any more, which it would
-- offer to delete. The page has a button that publishes.
function gm.previewPublish()
  if gm.refuse() then return false end
  local plan = gm.publishPlan()
  local new, changed, same = {}, {}, {}
  for _, c in ipairs(plan.copies) do
    if not gm.exists(c.copy) then
      new[#new + 1] = c
    else
      local old = space.readPage(c.copy)
      if old == c.text then
        same[#same + 1] = c
      else
        c.old = old
        changed[#changed + 1] = c
      end
    end
  end
  local page = gm.config.previewPage
  gm.write(page, previewText(plan, new, changed, same))
  gm.refresh()
  editor.navigate(page)
  local held = #plan.kept > 0 and (", " .. int(#plan.kept) .. " kept back") or ""
  local lapsed = #plan.orphans > 0 and (", " .. int(#plan.orphans) ..
    (#plan.orphans == 1 and " copy" or " copies") .. " to delete") or ""
  gm.notify("Preview: " .. int(#new) .. " new, " .. int(#changed) .. " changed, " ..
    int(#same) .. " unchanged" .. held .. lapsed .. ". Nothing has been sent.", {
    { name = "Publish now", run = function() gm.publish() end },
  })
  return true
end

-- How many publishes the report keeps, newest first.
local REPORTS = 5

-- Adds a publish to the lasting report, gm.config.publishReportPage, newest
-- first, so what it said outlives its notification: when, what was sent,
-- and what was kept back and why. `done` holds the pages whose copies were
-- added, updated and left the same, and the copies no revealed page makes
-- any more that were removed or left. A publish that sent, deleted and
-- held back nothing has nothing to report, and one that sent and deleted
-- nothing, and says just what the last one said of what it held back, adds
-- nothing to it. Gives whether there is a report of it.
local function publishReport(plan, done, headline)
  local items = {}
  local function list(pages)
    local out = {}
    for i, p in ipairs(pages) do out[i] = pageLink(p) end
    return table.concat(out, ", ")
  end
  if #done.added > 0 then items[#items + 1] = "- New: " .. list(done.added) end
  if #done.updated > 0 then items[#items + 1] = "- Updated: " .. list(done.updated) end
  local kept, embeds, gone, private = heldLines(plan)
  for _, l in ipairs(kept) do items[#items + 1] = "- Kept back: " .. l:sub(3) end
  for _, g in ipairs(embeds) do
    items[#items + 1] = "- Embeds left out, in " .. (g.page and pageLink(g.page) or "a copy") .. ":"
    for _, l in ipairs(fenced(g.embeds)) do items[#items + 1] = l end
  end
  for _, l in ipairs(gone) do items[#items + 1] = "- Revealed but no longer there: " .. l:sub(3) end
  for _, l in ipairs(private) do items[#items + 1] = l end
  for _, c in ipairs(done.removed) do
    items[#items + 1] = "- Deleted, as no revealed page makes it any more: " .. plain(c)
  end
  for _, c in ipairs(done.left) do
    items[#items + 1] = "- Kept, though no revealed page makes it any more: " .. pageLink(c)
  end
  if #items == 0 then return false end
  local body = headline .. "\n\n" .. table.concat(tidy(items), "\n")
  -- the publishes before it, as the page has them
  local path = gm.config.publishReportPage
  local earlier = {}
  if gm.exists(path) then
    local current
    for line in (space.readPage(path) .. "\n"):gmatch("([^\n]*)\n") do
      if line:sub(1, 3) == "## " then
        current = { line }
        earlier[#earlier + 1] = current
      elseif current then
        current[#current + 1] = line
      end
    end
  end
  if earlier[1] and #done.added + #done.updated + #done.removed == 0 then
    local last = {}
    for i = 3, #earlier[1] do last[#last + 1] = earlier[1][i] end
    if (table.concat(last, "\n"):gsub("%s+$", "")) == body then return true end
  end
  local entries = { "## " .. now() .. ", session " .. int(gm.currentSession()) .. "\n\n" .. body }
  for i = 1, math.min(#earlier, REPORTS - 1) do
    entries[#entries + 1] = (table.concat(earlier[i], "\n"):gsub("%s+$", ""))
  end
  gm.write(path, table.concat({
    "---", "type: state", "---", "",
    "# Publish report", "",
    "What GM Kit's last publishes did, newest first: when, what went to the players, " ..
      "and what was kept back and why.", "",
    '${widgets.commandButton("Preview publishing", "GM: Preview Publish")} ' ..
      '${widgets.commandButton("Publish to players", "GM: Publish to Players")}',
  }, "\n") .. "\n\n" .. table.concat(entries, "\n\n") .. "\n")
  return true
end

-- Opens the report, from a publish's notification.
local function openReport()
  return { name = "Open report", run = function() editor.navigate(gm.config.publishReportPage) end }
end

function gm.publish()
  if gm.refuse() then return false end
  local plan = gm.publishPlan()
  local held, gone = planNotes(plan)
  local copies, orphans, of = plan.copies, plan.orphans, plan.of
  local done = { added = {}, updated = {}, same = {}, removed = {}, left = {} }
  if #copies == 0 and #orphans == 0 then
    if held ~= "" or gone ~= "" then
      local reported = publishReport(plan, done, "Nothing to publish.")
      gm.notify("Nothing to publish." .. gone .. held, reported and { openReport() } or nil, "warning")
    else
      gm.notify("Nothing is revealed yet, so there is nothing to publish", nil, "warning")
    end
    return false
  end
  local folder = gm.config.playerFolder
  if #copies > 0 then
    if not editor.confirm("Publish " .. #copies ..
        (#copies == 1 and " revealed page" or " revealed pages") ..
        " to the players? Each replaces its earlier copy in " .. folder .. ", and " ..
        folder .. gm.config.playerNotes .. " is never touched.") then
      return false
    end
    for _, c in ipairs(copies) do
      if not gm.exists(c.copy) then
        gm.write(c.copy, c.text)
        done.added[#done.added + 1] = c.page
      elseif space.readPage(c.copy) ~= c.text then
        gm.write(c.copy, c.text)
        done.updated[#done.updated + 1] = c.page
      else
        done.same[#done.same + 1] = c.page
      end
    end
  end
  -- The copies no revealed page makes any more go only when the DM says so,
  -- and Undo brings them back.
  local removed, left = {}, ""
  if #orphans > 0 then
    if editor.confirm("Delete the players' copies of " .. #orphans ..
        (#orphans == 1 and " page" or " pages") .. " no longer revealed, renamed, deleted or " ..
        "unrevealed since they were published? " .. table.concat(orphans, ", ")) then
      for _, copy in ipairs(orphans) do
        removed[#removed + 1] = { copy = copy, text = space.readPage(copy) }
        space.deletePage(copy)
        done.removed[#done.removed + 1] = copy
      end
    else
      left = " The players still have copies no revealed page makes any more: " ..
             table.concat(orphans, ", ") .. "."
      done.left = orphans
    end
  end
  -- What each copy was made from, so a bar can say when one falls behind.
  -- A page not sent this time keeps its line while the players have its copy.
  local record = gm.readPublished()
  for _, c in ipairs(copies) do
    local entries = {}
    if of[c.page] == true then
      entries[c.page] = true
    else
      for _, part in ipairs(of[c.page]) do entries[c.page .. "#" .. part] = true end
    end
    record[c.page] = { entries = entries, saved = savedAt(c.page) }
  end
  local lapsed = {}
  for page in pairs(record) do
    local copy = gm.playerCopy(page)
    if not copy or not gm.exists(copy) then lapsed[#lapsed + 1] = page end
  end
  for _, page in ipairs(lapsed) do record[page] = nil end
  gm.writePublished(record)
  local message = #copies > 0 and ("Published to players: " .. #done.added .. " new, " .. #done.updated ..
                  " updated, " .. #done.same .. " unchanged.") or "Nothing to publish."
  local reported = publishReport(plan, done, message)
  gm.refresh()
  local actions = {}
  if reported then actions[#actions + 1] = openReport() end
  if #removed > 0 then
    local names = {}
    for i, r in ipairs(removed) do names[i] = r.copy end
    message = message .. " Deleted the copies no revealed page makes any more: " ..
              table.concat(names, ", ") .. "."
    actions[#actions + 1] = { name = "Undo", run = function()
      if gm.refuse() then return end
      for _, r in ipairs(removed) do gm.write(r.copy, r.text) end
      gm.refresh()
      gm.notify("Undone: the players have " .. table.concat(names, ", ") .. " back")
    end }
  end
  message = message .. gone .. held .. left
  gm.notify(message, #actions > 0 and actions or nil,
            (gone ~= "" or held ~= "" or left ~= "") and "warning" or "info")
  return true
end

function gm.logDecision()
  if gm.refuse() then return false end
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
  if gm.refuse() then return false end
  local page, n = gm.config.sessionPage, gm.currentSession()
  if not editor.confirm("Start session " .. (n + 1) .. "? From now on, marks and " ..
      "decisions are recorded against it.") then
    return false
  end
  gm.patch(page, "session", n + 1)
  gm.refresh()
  gm.notify("Now session " .. (n + 1), {
    { name = "Undo", run = function()
      if gm.refuse() then return end
      gm.patch(page, "session", n)
      gm.refresh()
      gm.notify("Back to session " .. n)
    end },
  })
  return true
end

------------------------------------------------------------ the players' recap
-- A session's recap for the players, drafted from what GM Kit recorded in
-- it: who the party met, where it went, what it found, what its rolls
-- turned up and what it decided. The DM edits the draft, a page of their
-- own beside the session's log, and publishes it into the players' space.

-- Where a session's recap goes: the DM's draft, beside the session's log,
-- and the players' copy, in their own space.
function gm.recapDraftPage(n)
  return gm.config.sessionsFolder .. "Session " .. int(n) .. " Recap"
end

function gm.recapPage(n)
  return gm.config.playerFolder .. gm.config.recapFolder .. "Session " .. int(n)
end

-- The session a recap draft is of: its frontmatter's `session`, or the
-- number in its name. nil when neither says.
local function recapSession(draft, text)
  local n = num(gm.frontmatter(text or "").session)
  return n or num((draft:match("Session (%d+) Recap$")))
end

-- The path from one page's folder to another page, for a Markdown link:
-- from "Sessions/Session 3 Recap" to "Player/World/People/Mara" it is
-- "../Player/World/People/Mara".
local function relPath(from, to)
  local a, b = {}, {}
  for seg in (from:match("^(.*)/[^/]*$") or ""):gmatch("[^/]+") do a[#a + 1] = seg end
  for seg in to:gmatch("[^/]+") do b[#b + 1] = seg end
  local i = 1
  while i <= #a and i < #b and a[i] == b[i] do i = i + 1 end
  local out = {}
  for _ = i, #a do out[#out + 1] = ".." end
  for j = i, #b do out[#out + 1] = b[j] end
  return table.concat(out, "/")
end

-- A recap's links, made to work from `to`, the page the text is going to,
-- as `from`, where it is now, has them. A link to one of the players' own
-- pages goes there by a path from `to`, and so does a link to an adventure
-- page they have a copy of, to its copy. A link to any other page of this
-- space goes in as its words, since the players have no such page, and an
-- embed of one goes. Links to other sites and within the page stay, and so
-- do code and ${...} expressions.
local function recapLinks(text, from, to)
  if not text:find("[[", 1, true) and not text:find("](", 1, true) then return text end
  local players, found = gm.config.playerFolder, {}
  -- the players' page a page of this space is, or nil
  local function theirs(target)
    if found[target] == nil then
      local copy = false
      if target:startsWith(players) then
        copy = gm.exists(target) and target
      elseif gm.isAdventurePage(target) and gm.exists(target) and not gm.isPrivate(target)
          and not gm.hidesName(target) then
        local c = gm.playerCopy(target)
        copy = c and gm.exists(c) and c or false
      end
      found[target] = copy
    end
    return found[target] or nil
  end
  local function link(label, target)
    return "[" .. label .. "](<" .. relPath(to, target) .. ">)"
  end
  local function wiki(bang, inner)
    local ref, alias = inner:match("^(.-)|(.*)$")
    ref = ref or inner
    local name = ref:match("^(.-)#") or ref
    if name == "" then return nil end
    if bang == "!" then return "" end
    local target = name
    if not name:startsWith(players) then target = gm.resolve(name) or name end
    local copy = theirs(target)
    local label = alias or gm.name(name)
    return copy and link(label, copy) or label
  end
  local function markdownLink(bang, label, paren)
    local url = pageUrl(paren)
    if not url then return nil end
    local target = linkTarget(from, url)
    if not target then return nil end
    target = (target:gsub("#.*$", ""))
    if bang == "!" then
      if target:startsWith(players) then return "![" .. label .. "](<" .. relPath(to, target) .. ">)" end
      return ""
    end
    local copy = theirs(target)
    return copy and link(label, copy) or label
  end
  -- Markdown links first: a wiki link becomes one that already goes from
  -- `to`, which mustn't be read again as if it went from `from`
  return relinkProse(text, function(s)
    s = (s:gsub("(!?)%[([^%]\n]*)%](%b())", markdownLink))
    return (s:gsub("(!?)%[%[([^%]\n]-)%]%]", wiki))
  end)
end

-- What GM Kit recorded of the party in session n: the people and factions
-- met, the places visited and the items found in it, each an adventure
-- page with its play state, in the adventure's order.
local function recapMarks(n)
  gm.freshStates()
  local want = int(n)
  local out = { met = {}, visited = {}, found = {} }
  for _, page in ipairs(gm.adventurePages()) do
    local folder = page:match("/(People)/") or page:match("/(Factions)/")
      or page:match("/(Places)/") or page:match("/(Items)/")
    if folder then
      local state = gm.readState(page)
      for mark, list in pairs(out) do
        local m = gm.marks[mark]
        if state[m.field] == m.value and state[m.session] == want then
          list[#list + 1] = { page = page, state = state }
        end
      end
    end
  end
  return out
end

-- Words the recap quotes, made inert: a ${ in them can't start a live
-- value, and a line of them can't open fenced code, a space-lua block
-- above all, so nothing quoted runs, in the DM's space or the players'.
local function inert(s)
  s = (s:gsub("%${", "$\\{"))
  if s:match("^%s*[`~][`~][`~]") then s = "\\" .. (s:match("^%s*(.*)$")) end
  return s
end

-- How the recap names an adventure page, or nil where the players may not
-- know its name: a link to their copy when they have one; for a page
-- revealed but not published yet, the name its copy will show, as words;
-- and nothing for a page not revealed, only for the DM, or whose name is
-- DM-only. `of` is gm.reveals()'s second value, `to` the draft.
local function recapName(page, of, to)
  if gm.isPrivate(page) or gm.hidesName(page) then return nil end
  local copy = gm.playerCopy(page)
  local has = copy and gm.exists(copy)
  if not has and not of[page] then return nil end
  local name = inert(gm.parts(page).name)
  if not has then return name end
  return "[" .. (name:gsub("[%[%]]", "\\%0")) .. "](<" .. relPath(to, copy) .. ">)"
end

-- A `## heading` section of a session's log as its list: each item's line,
-- and the lines indented under it.
local function logItems(text, heading)
  local items, inside, current = {}, false, nil
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    if line:match("^#+%s") then
      inside = line:match("^##%s+(.-)%s*$") == heading
      current = nil
    elseif inside then
      local top = line:match("^[%-%*]%s+(.*)$")
      local sub = line:match("^%s+[%-%*]%s+(.*)$")
      if top then
        current = { text = top, subs = {} }
        items[#items + 1] = current
      elseif sub and current then
        current.subs[#current.subs + 1] = sub
      end
    end
  end
  return items
end

-- The rolls a session's log records, for its recap, each with the words
-- of the rungs it reached as the log has them. The scene it was rolled in
-- is left off, since the players may have no such page; a roll that
-- reached nothing new goes, and so does one taken back later in the log;
-- and what is owed, when it comes back, is the DM's to know.
local function recapRolls(items)
  local out = {}
  for _, it in ipairs(items) do
    local text = it.text:match("^%[%[[^%]]*%]%] · (.*)$") or it.text
    local taken = text:match("^(.-): not rolled after all$")
    if taken then
      for i = #out, 1, -1 do
        local t = out[i].text
        local after = t:sub(#taken + 1, #taken + 1)
        if t:sub(1, #taken) == taken and (after == "," or after == ":") then
          table.remove(out, i)
          break
        end
      end
    elseif not text:find(": nothing new$") and not text:find(": nothing from this check") then
      local subs = {}
      for _, s in ipairs(it.subs) do
        if not s:find("^Owed:") then subs[#subs + 1] = s end
      end
      out[#out + 1] = { text = text, subs = subs }
    end
  end
  return out
end

-- A line of the recap as the players may read it: its DM-only text out and
-- its links made theirs. nil when nothing is left, or when a DM-only mark
-- the scanner couldn't take out is left, which fails closed: `held` counts
-- those lines.
local function recapLine(text, from, to, held)
  local line = gm.stripSecrets(text)
  line = (line:match("^%s*(.-)%s*$"))
  if line == "" then return nil end
  line = inert(recapLinks(line, from, to))
  if not line:find("%S") then return nil end
  if #gm.dmMarks(line) > 0 then
    held.lines = held.lines + 1
    return nil
  end
  return line
end

-- The players' recap of session n, drafted from what GM Kit recorded in
-- it, in the adventure's own words where the records give them, and naming
-- only what the players may know. Gives the draft, how many things each of
-- its sections holds, and what it left out: `lines` that still had a
-- DM-only mark, and `names` the players may not know.
function gm.recapText(n)
  local draft = gm.recapDraftPage(n)
  local log = gm.config.sessionsFolder .. "Session " .. int(n)
  local _, of = gm.reveals()
  local marks = recapMarks(n)
  local held = { lines = 0, names = 0 }
  local counts = {}
  local out = { "---", "type: " .. gm.config.recapDraftType, "session: " .. int(n), "---", "",
                "# Session " .. int(n) }
  local function section(heading, lines, items)
    counts[#counts + 1] = { heading = heading, n = items }
    if #lines == 0 then return end
    out[#out + 1] = ""
    out[#out + 1] = "## " .. heading
    out[#out + 1] = ""
    for _, l in ipairs(lines) do out[#out + 1] = l end
  end
  local function named(list, heading, extra)
    local lines = {}
    for _, x in ipairs(list) do
      local name = recapName(x.page, of, draft)
      if name then
        lines[#lines + 1] = "- " .. name .. (extra and extra(x.state) or "")
      else
        held.names = held.names + 1
      end
    end
    section(heading, lines, #lines)
  end
  named(marks.met, "Met")
  named(marks.visited, "Visited")
  named(marks.found, "Found", function(state)
    local uses = gm.usesText(state, true)
    return uses ~= "" and (": " .. uses) or ""
  end)
  -- the log as it stands, saved first if it is open
  local text = gm.exists(log) and gm.read(log) or ""
  local rolls, rolled = {}, 0
  for _, r in ipairs(recapRolls(logItems(text, "Rolls"))) do
    local top = recapLine(r.text, log, draft, held)
    local subs = {}
    for _, s in ipairs(r.subs) do
      local line = recapLine(s, log, draft, held)
      if line then subs[#subs + 1] = "  - " .. line end
    end
    -- a roll whose words all went, as the DM's, goes with them
    if top and (#r.subs == 0 or #subs > 0) then
      rolls[#rolls + 1] = "- " .. top
      for _, s in ipairs(subs) do rolls[#rolls + 1] = s end
      rolled = rolled + 1
    end
  end
  section("Rolls", rolls, rolled)
  local decisions, decided = {}, 0
  for _, d in ipairs(logItems(text, "Decisions")) do
    local top = recapLine(d.text, log, draft, held)
    if top then
      decisions[#decisions + 1] = "- " .. top
      for _, s in ipairs(d.subs) do
        local line = recapLine(s, log, draft, held)
        if line then decisions[#decisions + 1] = "  - " .. line end
      end
      decided = decided + 1
    end
  end
  section("Decisions", decisions, decided)
  return table.concat(out, "\n") .. "\n", counts, held
end

-- "2 met, 1 visited, 3 rolls", of what the draft holds.
local function recapCounts(counts)
  local words = { Met = "met", Visited = "visited", Found = "found", Rolls = "roll", Decisions = "decision" }
  local out = {}
  for _, c in ipairs(counts) do
    if c.n > 0 then
      local w = words[c.heading]
      if c.heading == "Rolls" or c.heading == "Decisions" then
        w = w .. (c.n == 1 and "" or "s")
      end
      out[#out + 1] = int(c.n) .. " " .. w
    end
  end
  return table.concat(out, ", ")
end

-- Drafts the players' recap of session n, the one being played unless
-- told, on a page of the DM's beside the session's log, and opens it. The
-- DM edits it, then publishes it (gm.publishRecap). A draft already there
-- is replaced only when the DM says so, and Undo puts it back.
function gm.draftRecap(n)
  if gm.refuse() then return false end
  n = n or gm.currentSession()
  local draft = gm.recapDraftPage(n)
  local text, counts, held = gm.recapText(n)
  -- fail closed: nothing that holds a DM-only mark goes into a draft
  local marks = gm.dmMarks(text)
  if #marks > 0 then
    gm.notify("The recap of session " .. int(n) .. " isn't drafted: it would hold DM-only marks (" ..
      table.concat(marks, ", ") .. ").", nil, "warning")
    return false
  end
  local before = gm.exists(draft) and gm.read(draft) or nil
  if before == text then
    editor.navigate(draft)
    gm.notify("The recap of session " .. int(n) .. " is drafted already, and nothing recorded since changes it.")
    return false
  end
  if before and not editor.confirm("Draft the recap of session " .. int(n) .. " afresh? It replaces " ..
      draft .. ", and any change you made to it.") then
    return false
  end
  gm.write(draft, text)
  gm.refresh()
  editor.navigate(draft)
  local said = recapCounts(counts)
  local message = said ~= "" and
    ("Drafted the players' recap of session " .. int(n) .. ": " .. said .. ". Edit it, then publish it from its bar.")
    or ("Drafted the players' recap of session " .. int(n) .. ", with nothing in it: GM Kit recorded nothing " ..
        "the players may know in it. Write it yourself, then publish it from its bar.")
  if held.names > 0 then
    message = message .. " Left unnamed: " .. int(held.names) ..
      (held.names == 1 and " page" or " pages") .. " the players may not know by name."
  end
  if held.lines > 0 then
    message = message .. " Left out: " .. int(held.lines) ..
      (held.lines == 1 and " line" or " lines") .. " with a DM-only mark."
  end
  gm.notify(message, {
    { name = "Undo", run = function()
      if gm.refuse() then return end
      if before then
        gm.write(draft, before)
      elseif gm.exists(draft) then
        space.deletePage(draft)
      end
      gm.refresh()
      gm.notify("Undone: " .. (before and "the draft is as it was" or "the draft is gone"))
    end },
  })
  return true
end

-- The players' copy of a recap draft, and where it goes: its body under
-- frontmatter that says only that it is a recap, its live values printed
-- as a published page's are, and its links made to work from there.
function gm.recapCopy(draft, text)
  text = text or space.readPage(draft)
  local n = recapSession(draft, text)
  if not n then return nil, nil end
  local copy = gm.recapPage(n)
  local _, body = gm.splitFrontmatter(text)
  body = recapLinks(gm.print(body or text, draft), draft, copy)
  body = (body:gsub("^%s+", ""))
  body = (body:gsub("%s+$", ""))
  return "---\ntype: " .. gm.config.recapType .. "\n---\n\n" .. body .. "\n", copy
end

-- The DM-only marks a recap draft holds, and any its players' copy would,
-- once its live values print: publishing sends neither.
local function recapHeld(text, copyText)
  local _, body = gm.splitFrontmatter(text)
  local marks = gm.dmMarks(body or text)
  for _, m in ipairs(gm.dmMarks(copyText)) do
    if not table.includes(marks, m) then marks[#marks + 1] = m end
  end
  return marks
end

-- Publishes a recap draft to the players, with Undo. It refuses a draft
-- that still holds a DM-only mark, or anything the players' copy would
-- hold one of, rather than send it: the DM takes it out first.
function gm.publishRecap(draft)
  if gm.refuse() then return false end
  if not draft or not gm.exists(draft) then
    gm.notify("There is no recap draft to publish: GM: Draft Recap drafts one.", nil, "warning")
    return false
  end
  local text = gm.read(draft)
  local copyText, copy = gm.recapCopy(draft, text)
  if not copyText then
    gm.notify(gm.name(draft) .. " doesn't say which session it is the recap of: give it `session:` " ..
      "in its frontmatter.", nil, "warning")
    return false
  end
  local marks = recapHeld(text, copyText)
  if #marks > 0 then
    gm.notify("Not published: the recap still has DM-only marks (" .. table.concat(marks, ", ") ..
      "). Take them out of " .. draft .. ", then publish it.", nil, "warning")
    return false
  end
  local n = recapSession(draft, text)
  local before = gm.exists(copy) and space.readPage(copy) or nil
  if before == copyText then
    gm.notify("The players have this recap already, as it stands, at " .. copy .. ".")
    return false
  end
  if not editor.confirm("Publish the recap of session " .. int(n) .. " to the players, as " .. copy .. "?" ..
      (before and " It replaces the one they have." or "")) then
    return false
  end
  gm.write(copy, copyText)
  gm.refresh()
  gm.notify("Published the recap of session " .. int(n) .. " to the players, as " .. copy .. ".", {
    { name = "Undo", run = function()
      if gm.refuse() then return end
      if before then
        gm.write(copy, before)
      elseif gm.exists(copy) then
        space.deletePage(copy)
      end
      gm.refresh()
      gm.notify("Undone: " .. (before and "the players have the recap they had before" or
        "the players' recap is gone again"))
    end },
  })
  return true
end

-- The session the open page is of, when it is a session's log or a recap
-- draft.
function gm.sessionHere()
  local page = editor.getCurrentPage()
  if not page or not page:startsWith(gm.config.sessionsFolder) or not gm.exists(page) then return nil end
  local fm = gm.frontmatter(space.readPage(page))
  if fm.type ~= gm.config.sessionType and fm.type ~= gm.config.recapDraftType then return nil end
  return num(fm.session)
end

-- Asks which session, the one being played first; the first is the only
-- one there is to ask about until the second begins.
function gm.pickSession(label, help)
  local now = gm.currentSession()
  if now <= 1 then return now end
  local options = {}
  for s = now, 1, -1 do
    options[#options + 1] = { name = "Session " .. int(s), orderId = now - s + 1,
                              description = s == now and "This session" or nil }
  end
  local choice = editor.filterBox(label, options, help, "Type to filter")
  if not choice then return nil end
  return num((choice.name:match("(%d+)$")))
end

-- The recap draft a command acts on: the open page when it is one, else the
-- only one there is, else one picked, the latest session first.
function gm.pickRecap()
  local here = editor.getCurrentPage()
  if here and gm.pageType(here) == gm.config.recapDraftType then return here end
  local t = gm.config.recapDraftType
  local rows = query[[
    from p = index.pages()
    where p.type == t
    select { name = p.name, session = p.session }
  ]]
  table.sort(rows, function(x, y) return (num(x.session) or 0) > (num(y.session) or 0) end)
  if #rows == 0 then
    gm.notify("No recap is drafted yet: GM: Draft Recap drafts one from what GM Kit recorded.", nil, "warning")
    return nil
  end
  if #rows == 1 then return rows[1].name end
  local pages = {}
  for i, r in ipairs(rows) do pages[i] = r.name end
  return gm.pick("Publish recap", "Which session's recap goes to the players?", pages)
end

-- The bar across a recap draft: whether the players have it as it stands,
-- and the button that sends it.
function gm.recapBar(page)
  local text = space.readPage(page)
  local spec = { class = "gmkit-bar" }
  local function add(x) spec[#spec + 1] = x end
  local function note(t) add(dom.span { class = "gmkit-bar-note", t }) end
  local stale = installedVersion()
  if stale then
    note(reloadNote(stale))
    add(gm.button("Reload", reloadTab))
  end
  local copyText, copy = gm.recapCopy(page, text)
  if not copyText then
    note("⚠ Which session is this the recap of? Give it `session:` in its frontmatter")
    return widget.new { display = "block", html = dom.div(spec) }
  end
  add(dom.strong { "Recap of session " .. int(recapSession(page, text)) })
  local has = gm.exists(copy)
  local same = has and space.readPage(copy) == copyText
  if not has then
    note("○ Not published yet")
  elseif same then
    note("◉ Published to players")
  else
    note("◐ Changed since publishing")
  end
  local marks = recapHeld(text, copyText)
  if #marks > 0 then
    note("⚠ Has DM-only marks, so it can't be published: " .. table.concat(marks, ", "))
  elseif not same then
    add(gm.button(has and "Publish again" or "Publish recap", function() gm.publishRecap(page) end))
  end
  if has then note("[[" .. copy .. "|The players' copy]]") end
  return widget.new { display = "block", html = dom.div(spec) }
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

-- How the players' copy of a page has fallen behind since it was
-- published, by the record publishing keeps: parts revealed since, the
-- whole page revealed since, or the page saved since, or parts taken back,
-- each a note with its glyph. `part` is what is revealed now: true for the
-- whole page, or the names of its parts. Nothing for a page without a
-- record, such as one published before GM Kit kept one.
local function behind(page, part, rec)
  local out = {}
  if not rec then return out end
  local changed = false
  if part == true then
    if not rec.entries[page] then out[#out + 1] = "◔ Whole page not published yet" end
  else
    local n = 0
    for _, name in ipairs(part) do
      if not rec.entries[page .. "#" .. name] then n = n + 1 end
    end
    if n > 0 then out[#out + 1] = "◔ " .. int(n) .. (n == 1 and " part" or " parts") .. " not published yet" end
    -- their copy holds more than is revealed now
    if rec.entries[page] then changed = true end
    for entry in pairs(rec.entries) do
      local _, name = entryParts(entry)
      if name and not table.includes(part, name) then changed = true end
    end
  end
  local now = savedAt(page)
  if rec.saved and now and rec.saved ~= now then changed = true end
  if changed then out[#out + 1] = "◐ Changed since publishing" end
  return out
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
  -- nor is a page whose title is DM-only, since its copy would name it
  if gm.hidesName(page) then
    if seen == "hidden" then
      note("⊘ Name is DM-only: not published")
    elseif seen == "revealed" then
      note("⊘ Name is DM-only: not published, though on the revealed list")
      add(gm.button("Unreveal", function() gm.unreveal(page) end))
    else
      note("◐ Name is DM-only, but the players have a copy")
      add(gm.button("Delete their copy", function() gm.unreveal(page) end))
    end
    return
  end
  local function revealPart()
    local part = gm.pickPart(page)
    if part then gm.revealPart(page, part) end
  end
  if seen == "stale" then
    note("◐ Not revealed, but the players still have a copy")
    add(gm.button("Delete their copy", function() gm.unreveal(page) end))
    add(gm.button("Reveal", function() gm.reveal(page) end))
  elseif seen == "hidden" then
    note("○ Hidden from players")
    add(gm.button("Reveal", function() gm.reveal(page) end))
    -- an item's row on another page's bar keeps to the one button; the
    -- item's own bar has the rest
    if not quiet and #gm.parts(page).parts > 0 then add(gm.button("Reveal part…", revealPart)) end
  elseif not quiet then
    local part = gm.revealedPart(page)
    local waiting = seen == "published" and "" or ", not published yet"
    -- the record is read once, and only for a page the players have
    local late = seen == "published" and behind(page, part, gm.readPublished()[page]) or {}
    if part == true then
      note(seen == "published" and "◉ Revealed to players" or "◉ Revealed, not published yet")
      for _, n in ipairs(late) do note(n) end
    else
      -- a quarter circle, and the words, for a page the players see some of
      local p, shown = gm.parts(page), {}
      for _, n in ipairs(part) do
        if n ~= p.name then shown[#shown + 1] = n end
      end
      if #shown == 0 then
        note("◔ Revealed by name only" .. waiting)
      else
        note("◔ Revealed in part" .. waiting .. ": " .. table.concat(shown, ", "))
      end
      for _, n in ipairs(late) do note(n) end
      add(gm.button("Reveal all", function() gm.reveal(page) end))
      if #shown < #p.parts then add(gm.button("Reveal part…", revealPart)) end
    end
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
  gm.freshStates()
  local t = gm.pageType(page)
  if t == gm.config.recapDraftType then return gm.recapBar(page) end
  if t ~= gm.config.sessionType then return nil end
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
  gm.freshStates()
  local kind = gm.kind(page)
  local can = kind and gm.kinds[kind] or {}
  local state = gm.readState(page)
  local spec = {
    class = "gmkit-bar",
    dom.strong { "Session " .. gm.currentSession() },
  }
  local function add(item) spec[#spec + 1] = item end
  local function note(text) add(dom.span { class = "gmkit-bar-note", text }) end
  -- a stale tab says so first, since every button after it refuses to act
  local stale = installedVersion()
  if stale then
    table.insert(spec, 1, dom.span { class = "gmkit-bar-note", reloadNote(stale) })
    table.insert(spec, 2, gm.button("Reload", reloadTab))
  end
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
  local statePage, stated = gm.stateFor(page)
  if stated then note("[[" .. statePage .. "|Play state]]") end
  local items, given = gm.itemsOn(page)
  for _, item in ipairs(items) do add(gm.itemRow(item, page, given[item])) end
  local checks = gm.checks(page)
  if #checks > 0 then add(gm.rollRow(page, checks, state)) end
  return widget.new { display = "block", html = dom.div(spec) }
end
```

```space-lua
-- priority: 10
local function markCommand(mark)
  return function()
    -- a stale tab refuses before the picker, not after it
    if gm.refuse() then return end
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

-- The adventure pages not revealed whole, for a picker: a page revealed in
-- part can still be revealed whole, or in another part.
local function notWhollyRevealed()
  local _, of = gm.reveals()
  local pages, notes, private = {}, {}, gm.privatePages()
  for _, n in ipairs(gm.adventurePages()) do
    if of[n] ~= true and not private[n] then
      pages[#pages + 1] = n
      if of[n] then notes[n] = "Revealed in part" end
    end
  end
  return pages, notes
end

command.define {
  name = "GM: Reveal Page",
  run = function()
    if gm.refuse() then return end
    local page = editor.getCurrentPage()
    if not gm.isAdventurePage(page) then
      local pages, notes = notWhollyRevealed()
      page = gm.pick("Reveal", "Which page have the players learned about?", pages, notes)
    end
    if page then gm.reveal(page) end
  end
}

command.define {
  name = "GM: Reveal Part",
  run = function()
    if gm.refuse() then return end
    local page = editor.getCurrentPage()
    if not gm.isAdventurePage(page) then
      local pages, notes = notWhollyRevealed()
      page = gm.pick("Reveal part", "Which page have the players learned some of?", pages, notes)
    end
    if not page then return end
    local part = gm.pickPart(page)
    if part then gm.revealPart(page, part) end
  end
}

-- The open adventure page, or one picked from those the players can see or
-- still have a copy of.
local function unrevealCommand()
  if gm.refuse() then return end
  local page = editor.getCurrentPage()
  if not gm.isAdventurePage(page) then
    local pages, notes, listed = {}, {}, {}
    local function hasCopy(n)
      local copy = gm.playerCopy(n)
      return copy ~= nil and gm.seen(copy)
    end
    local order, of = gm.reveals()
    for _, n in ipairs(order) do
      pages[#pages + 1] = n
      listed[n] = true
      if of[n] == true then
        notes[n] = hasCopy(n) and "Published" or "Revealed, not published yet"
      else
        notes[n] = hasCopy(n) and "Published in part" or "Revealed in part, not published yet"
      end
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
  name = "GM: Preview Publish",
  run = function() gm.previewPublish() end
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
    if gm.refuse() then return end
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
    if gm.refuse() then return end
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
    if gm.refuse() then return end
    gm.freshStates()
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

-- Ctrl-Alt-r is SilverBullet's own System: Reload, so a roll is k, for check.
command.define {
  name = "GM: Log Roll",
  key = "Ctrl-Alt-k",
  run = function() gm.logRoll() end
}

command.define {
  name = "GM: Unlog Roll",
  run = function()
    if gm.refuse() then return end
    local page = gm.rollPage()
    if not page then
      gm.notify("There is no page here with rolls to take back", nil, "warning")
      return
    end
    gm.pickUnlog(page)
  end
}

command.define {
  name = "GM: Next Session",
  run = function() gm.nextSession() end
}

-- On a session's log or its recap, that session's; anywhere else it asks
-- which, the one being played first.
command.define {
  name = "GM: Draft Recap",
  run = function()
    if gm.refuse() then return end
    local n = gm.sessionHere() or gm.pickSession("Draft recap",
      "Which session's recap? The players see it once you publish it.")
    if n then gm.draftRecap(n) end
  end
}

command.define {
  name = "GM: Publish Recap",
  run = function()
    if gm.refuse() then return end
    local draft = gm.pickRecap()
    if draft then gm.publishRecap(draft) end
  end
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

-- Feather has no die; a d20's outline is a hexagon.
actionButton.define {
  icon = "hexagon",
  description = "Log a roll",
  command = "GM: Log Roll",
  priority = 0.75,
}

-- Just ahead of Publish, so what it would send is a click away from it.
actionButton.define {
  icon = "eye",
  description = "Preview what publishing would send",
  command = "GM: Preview Publish",
  priority = 0.72,
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

/* A DM div: the words over it, and a dotted line down its side. */
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
