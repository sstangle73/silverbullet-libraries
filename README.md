# Storie libraries for SilverBullet

Space Lua libraries for [SilverBullet](https://silverbullet.md) 2.11: a set of tools for running a tabletop RPG campaign from a wiki, with its adventure kept clean enough to print as a book, and a few small ones that stand on their own, for a server with several spaces, a wiki about a book or a series, and recurring tasks.

Each library is one page in `src/`, installed into a space as `Library/Storie/<name>`, and the repository page, `Repositories/storie.md`, lists them for SilverBullet's `Library:` commands.

## The libraries

| Library | What it does | Space | Version |
|---|---|---|---|
| [GM Kit](src/GM%20Kit.md) | Play state kept out of the adventure: who the party met, where they went, what they found and its uses, rolls and decisions logged by session, each character's hit points, slots and rests, and fog-of-war publishing of what the players have learned into their own space, with a preview before and a report after, and a recap of each session for the players | The DM space, the one that holds the others | 3.9.1 |
| [GM Beyond](src/GM%20Beyond.md) | D&D Beyond characters: an import that writes a character's whole sheet into a page, for GM Sheets to draw, a refresh that says what it changes before it writes, one for the whole party, and a roster read from the pages | The DM space | 2.2.0 |
| [GM Book](src/GM%20Book.md) | Compiles the adventure into DM and player editions of one manuscript, for Homebrewery to render as a 5e book | The adventure space | 1.14.0 |
| [GM Party](src/GM%20Party.md) | Numbers, hand-outs, fights and DCs that follow the party's size and level: your table's on the page, the general rule in print | The adventure space | 1.5.0 |
| [GM Bestiary](src/GM%20Bestiary.md) | Creature pages that point at official stat blocks: a compendium link on the page, the book and its entry in print | The adventure space | 1.3.0 |
| [GM Maps](src/GM%20Maps.md) | Encounter maps written as a grid of characters with a legend, drawn as a scaled plan with its own key, sized to the party | The adventure space | 1.5.0 |
| [GM Sheets](src/GM%20Sheets.md) | Character sheets drawn from a character page's frontmatter, on the wiki and a page to themselves in the book | The adventure space | 1.4.0 |
| [Chapter Navigation](src/Chapter%20Navigation.md) | Previous, contents and next links above and below every chapter or scene page, read from the index | Each space with chapters or scenes to page through | 1.2.0 |
| [Space Switcher](src/Space%20Switcher.md) | A strip across the top of every page that names the space you are in and links to your others, nested ones included | Every space | 1.1.0 |
| [Appearances](src/Appearances.md) | Lists the chapters that name a page in their frontmatter, grouped by book | The space of the book's chapters and people | 1.1.0 |
| [RecurringTasks](src/RecurringTasks.md) | Adds each day's recurring tasks to the daily note from a master list, and rolls over the ones left open | Any space | 1.2.0 |
| [Storie Check](src/Storie%20Check.md) | A health check: every copy of every library in the space and its version, which of them the tab runs and whether it is stale, GM Book's printers, and whether the small libraries' settings are the shape they read | The adventure space, or any other with these libraries to check | 1.0.0 |

The campaign libraries expect a DM space that holds the others as folders, each a space of its own as well: the adventure, your notes on it, the book it adapts, and the players' space. [`Repositories/storie.md`](Repositories/storie.md) says where each goes in more words, and each library's own page says how to set it up.

## Installing

In each space, from inside that space:

1. Run `Library: Add Repository` with this repository's page, `https://github.com/sstangle73/silverbullet-libraries/blob/main/Repositories/storie.md`, and keep the name it suggests, `Repositories/storie`.
2. Run `Library: Install` for each library that space needs, with the library's own address, its `uri` in the repository page's *Contents*. The Libraries panel, `Libraries: Manager`, lists them under **Available** too, each with an **Install** button.

**Install and update each space's libraries from inside that space, and never run `Library: Update All` in a space that holds others as folders.** SilverBullet writes a library, installed or updated, to the name in its own frontmatter at the root of the space the command runs in, so Update All there writes each folder's libraries again at the root, where they run beside the folders' copies, and leaves those copies as they were. Update the DM space's own libraries one at a time, and the others from inside their own spaces. Storie Check lists copies of one library at different depths, and a tab that runs older Lua than a copy holds; `System: Reload` loads what an update wrote.

## How they fit together

Each works alone; together they hand each other what they know. Nothing depends on the order they load in.

- **GM Book prints what the others draw.** GM Party, GM Bestiary, GM Maps and GM Sheets each put a table in `gmbook.printers`, and a build evaluates every `${...}` with those standing in for the libraries' own names, so the book gets a rule where the page shows your table's number, a citation where it shows a link, and a map or a sheet drawn for print. GM Book doesn't need GM Kit.
- **GM Kit publishes what the others draw, for your table.** The players' copies get each widget's Markdown face, so GM Party's numbers go in as your party's. GM Kit also reads GM Party's counts for an item's uses, and its rising DCs for a roll's rungs.
- **GM Party is the party.** GM Bestiary wires creature pages into its fights, through `party.creatureRef`, and GM Maps sizes a grid by `party.value`: your table's on the page, the adventure's in print.
- **GM Beyond feeds GM Sheets.** It writes a D&D Beyond character into a page whose frontmatter GM Sheets draws.
- **Storie Check reads every library's `version` and `stale()`,** GM Book's printers, and the schemas Space Switcher, Chapter Navigation and Appearances declare for their settings with `config.define`.
- **Space Switcher, Chapter Navigation, Appearances and RecurringTasks** stand alone.

## Tests

```
pip install lupa pyyaml
python test/run.py                   # the libraries in plain Lua 5.4, SilverBullet's APIs mocked
python test/run.py --shuffle         # the same, with each page's blocks loaded in reverse
python test/coverage.py              # each library's function and line coverage
python test/spacelua/run.py <sb211>  # the libraries in SilverBullet 2.11's own Lua
```

`test/run.py` is the wide suite: it runs the libraries over a small made-up campaign, *The Tin Crown*, in `test/fixture/`, with each library from `src/` installed where `test/install.json` says, and mocks that answer as SilverBullet 2.11 does where it has bitten and fail where Space Lua would. It takes `--only`, `-k` and `--src` as well, the last to hold an older release to a new test. The Space Lua suite runs the same libraries in SilverBullet's own interpreter, over the same campaign, in a SilverBullet checkout at tag 2.11.0 with its packages installed; `test/spacelua/run.py` checks the checkout, runs vitest on the test and cleans up after it. Both pass, or a library doesn't go out. `test/README.md` has the details, and `test/instance/` a real SilverBullet server over the campaign, for what only a real client shows.

`tools/handout.py` fills the 2024 character sheet from a GM Sheets page, for your own table; `python test/handout_test.py` holds it to GM Sheets' own sums.

## Change notes

Each library keeps its own on its page, under a *Changes in* heading for each version, so they travel with the library into your space. The repository's history has the rest.

## Licence

MIT: see [LICENSE](LICENSE).
