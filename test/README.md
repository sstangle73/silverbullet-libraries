# Tests

The libraries are Space Lua, and Space Lua only runs inside SilverBullet. These tests run them here instead, over a small made-up campaign, *The Tin Crown*, in `fixture/`. A campaign in real use changes every week; this one changes only when a test needs something it doesn't have, so a failing test means a library changed.

## Running them

```
pip install lupa pyyaml
python test/run.py
```

About ten seconds. PyYAML stands in for SilverBullet's `yaml.parse`, which GM Sheets reads a character's page with, made to read YAML 1.2 as SilverBullet's js-yaml does: `yes`, `No` and `on` stay words and `1:30` stays text, where PyYAML's own YAML 1.1 makes them booleans and 90. `--only kit,maps` runs only those files from `tests/`, `-k "mark met"` only the tests whose name holds those words, and `--src <folder>` tests the libraries in another folder instead of `src/`, such as an older release, to check that a regression test fails on the code before its fix. `--shuffle` is a stress run: every page's blocks load in reverse, so a block that leans on another from its own page shows up.

`run.py` sets the C locale before it makes a Lua runtime, and so does anything that builds one through it, such as `build_book.py`. Lua's `%s`, `%a` and `string.lower` follow the locale, and Windows starts Python in a code page such as 1252, where byte `0xA0` is a space: `%s` then cut `à` in half.

| File | Holds |
|---|---|
| `run.py` | Loads the campaign, installs the libraries, runs the tests |
| `mocks.lua` | SilverBullet 2.11's APIs, mocked for plain Lua 5.4 |
| `framework.lua` | `test()`, the checks, and the helpers the test files share |
| `tests/*.lua` | The tests, a file for each library or feature; `harness_*.lua` test the harness itself |
| `install.json` | Which library goes in which space's `Library/Storie/` |
| `fixture/` | The campaign |
| `ddb/` | Two made-up characters as D&D Beyond's character service sends them, for GM Beyond's import |
| `build_book.py` | Builds the campaign's book, to diff or to commit |
| `spacelua/` | The same libraries in SilverBullet's own Lua, and `run.py` to run them in a 2.11.0 checkout |
| `handout_test.py` | `tools/handout.py`, which fills the 2024 character sheet: its sums held against GM Sheets' own, and a sheet filled on a stand-in |
| `instance/` | A real SilverBullet server over the campaign |

## The campaign

`fixture/` is a server's DM space. It holds four more spaces as folders, `Adventure/`, `Author/`, `Book/` and `Player/`, and each is a space of its own as well, so a test names the space it runs in: `"dm"`, `"adventure"`, `"author"`, `"book"` or `"player"`. Each space's `CONFIG` page configures the libraries as a campaign would.

It holds no libraries. `run.py` puts each one from `src/` where `install.json` says, so what the tests run is always the code as it is now.

`Adventure/Build/` is the book as GM Book builds it, and both editions must match the committed book byte for byte: a test holds a fresh build to it, here and in SilverBullet's own Lua. When a change alters the book on purpose, rebuild it with `python test/build_book.py --write` and read the diff before committing it.

Keep it small. A test that needs a page the campaign lacks can usually write it in the test itself: `H.pages["Adventure/World/Items/Key"] = "..."`.

## Writing a test

```lua
test("kit: marking someone met records the session", "dm", function()
  gm.mark("Adventure/World/People/Mara", "met")
  has(H.pages["State/People/Mara"], "met: true\nmet_session: 1\n")
  has(lastNotification().message, "Mara: met in session 1")
end)
```

Before each test, `reset()` gives it the space's pages, loads every `space-lua` block there, and clears the play state: `State/`, `Sessions/` and the players' copies, all but `State/Revealed`. The current page is `index`, since a client always has a page open. Everything a library does lands in `H`: `H.pages`, `H.notifications`, `H.commands`, `H.views`. A test answers the library's questions ahead of time with `H.picks`, `H.prompts` and `H.confirms`. A file that isn't a page, such as a printed PDF, is the test's to put in `H.files[path]`, with its `lastModified`.

The blocks load as SilverBullet 2.11 loads them, each a chunk of its own: highest priority first, the first `-- priority: N` anywhere in the block and none counting as 0, then by the block's name, `<page>@<offset of its fence>`, with the offset in UTF-16 code units and the names compared as JavaScript compares strings. So a page's blocks need not run in page order: GM Kit's fences sit at offsets where `"146433" < "26434"`, and its second block runs first. Code at the top of a block can't count on the page's other blocks having run. `tests/harness_order.lua` holds the harness to this, and the Space Lua suite holds the rule to SilverBullet's own indexer and sort.

A library prints only when something went wrong that it chose to swallow, such as a bar that failed to draw, so a test fails if a line is left in `H.printed` at its end. A test that makes a library print on purpose takes the lines and checks them: `has(takePrinted()[1], "boom")`.

**The mocks answer as SilverBullet does where it has bitten.** `space.pageExists` is link resolution, as it is in 2.11: an exact name, or else any page whose path ends in it. `freezeFileList()` holds the list it reads the way a real client's lags behind a write, and `settle()` catches it up. `space.getPageMeta` asks for the page itself, and `space.fileExists` and `space.getFileMeta` are exact, over pages and `H.files` alike. A query's `where` reads `0` and `""` as false, as SilverBullet's does, and its `order by` sorts stably, a nil last ascending and first descending. `editor.copyToClipboard` never fails to its caller: with `H.clipboardFails` set, it shows SilverBullet's own *Could not copy to clipboard* notification and returns.

## SilverBullet's own Lua

Plain Lua is not Space Lua: `s:gsub(...):sub(2)` works here and fails there, and `query` and `using` are keywords there. `spacelua/libraries.test.ts` runs the libraries in SilverBullet's own interpreter, with its standard library, its `widget.new` and its Markdown parser, over the same campaign. It loads every `space-lua` block the DM space holds, each on its own, in the order SilverBullet's own indexer and sort give, and fails on any that doesn't load; it loads every library in `src/` together as well, the ones the campaign doesn't install included. It drives the bar, marks, uses and Undo, a query on the Session Table, a book build, DM-only text, whose cases it reads from `tests/dmonly.lua` so the two can't drift apart, rolls, over the scene `tests/rolls.lua` writes for its own, and the party's level: a fight in versions, DCs that rise and a check that reads them, from `tests/levels.lua`.

It needs a SilverBullet checkout at 2.11.0, with its packages:

```
git clone --depth 1 --branch 2.11.0 https://github.com/silverbulletmd/silverbullet sb211
cd sb211 && npm ci --ignore-scripts
python <this repo>/test/spacelua/run.py <path to sb211>
```

or set `SB211` to the checkout and leave the path off. `spacelua/run.py` checks the checkout is 2.11.0 with no changes to its tracked files, writes its `version.json` if it has none (`--ignore-scripts` skips the build step that writes it, and without it the suite fails to load, *Cannot find module '../../../version.json'*, and reports no tests), copies the test in under a name of its own, runs vitest on it with `SBLIB` set to this repo, and deletes the copy again, pass or fail. Don't copy the test in by hand: a copy left behind is run again later, whatever the repo holds by then. Run one suite at a time; each takes a few gigabytes.

**Both pass, or the library doesn't go out.** A change to `tools/handout.py` also needs `python test/handout_test.py`, which runs GM Sheets' Lua beside the script's Python.

## A real server

Some things only a real client shows: real `query[[...]]` in page bodies, requalified links after `space.writePage`, config loading across nested spaces, notifications and their buttons, widgets as the browser draws them. `instance/instance.py` runs a SilverBullet 2.11 server on `127.0.0.1:3111` with the five spaces over a copy of the campaign, and drives its headless client through the Runtime API. It is Windows-only, and needs the server (`SB_BIN`, or `instance/bin/silverbullet.exe`) and chrome-headless-shell (`SB_CHROME_PATH`).

```
python test/instance/instance.py provision          # data, campaign, admin and token; starts it
python test/instance/instance.py eval dm "type(gm)"
python test/instance/instance.py script dm flow.lua # a whole flow; `return` what to see
python test/instance/instance.py restore            # put back what a flow wrote
```

A script gets the helpers in `instance/prelude.lua`: `T.go(page)`, `T.bar()`, `T.click(label)`, `T.notes()`, `T.act("Undo")`, `T.scan()`, `T.waitUntil(check, what)` and more. `T.go`, `T.click` and `T.act` wait until the page has changed and then kept still, not a fixed time. Put a whole flow in one script, since requests hold a lock but nothing else survives between them, and undo what it wrote, or `restore`. The lock is the machine's, one for each port, since every checkout's server uses `127.0.0.1:3111` unless `SB_TEST_PORT` says otherwise, and a request goes only to this checkout's own server: the process it started, still running, and the one listening on the port. The first request after a start takes about twenty seconds. A mark takes up to ten more in the headless client, so wait for its record, `T.waitUntil(function() return T.page("State/People/Mara") end, "Mara's record", 20000)`, rather than sleeping a fixed time.
