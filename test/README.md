# Tests

The libraries are Space Lua, and Space Lua only runs inside SilverBullet. These tests run them here instead, over a small made-up campaign, *The Tin Crown*, in `fixture/`. A campaign in real use changes every week; this one changes only when a test needs something it doesn't have, so a failing test means a library changed.

## Running them

```
pip install lupa
python test/run.py
```

About ten seconds. `--only kit,maps` runs only those files from `tests/`, `-k "mark met"` only the tests whose name holds those words, and `--src <folder>` tests the libraries in another folder instead of `src/`, such as an older release, to check that a regression test fails on the code before its fix.

| File | Holds |
|---|---|
| `run.py` | Loads the campaign, installs the libraries, runs the tests |
| `mocks.lua` | SilverBullet 2.11's APIs, mocked for plain Lua 5.4 |
| `framework.lua` | `test()`, the checks, and the helpers the test files share |
| `tests/*.lua` | The tests, a file for each library or feature |
| `install.json` | Which library goes in which space's `Library/Storie/` |
| `fixture/` | The campaign |
| `build_book.py` | Builds the campaign's book, to diff or to commit |
| `spacelua/` | The same libraries in SilverBullet's own Lua |
| `instance/` | A real SilverBullet server over the campaign |

## The campaign

`fixture/` is a server's DM space. It holds four more spaces as folders, `Adventure/`, `Author/`, `Book/` and `Player/`, and each is a space of its own as well, so a test names the space it runs in: `"dm"`, `"adventure"`, `"author"`, `"book"` or `"player"`. Each space's `CONFIG` page configures the libraries as a campaign would.

It holds no libraries. `run.py` puts each one from `src/` where `install.json` says, so what the tests run is always the code as it is now.

`Adventure/Build/` is the book as GM Book builds it, and a test holds a fresh build to it. When a change alters the book on purpose, rebuild it with `python test/build_book.py --write` and read the diff before committing it.

Keep it small. A test that needs a page the campaign lacks can usually write it in the test itself: `H.pages["Adventure/World/Items/Key"] = "..."`.

## Writing a test

```lua
test("kit: marking someone met records the session", "dm", function()
  gm.mark("Adventure/World/People/Mara", "met")
  has(H.pages["State/People/Mara"], "met: true\nmet_session: 1\n")
  has(lastNotification().message, "Mara: met in session 1")
end)
```

Before each test, `reset()` gives it the space's pages, loads every `space-lua` block there in SilverBullet's order (priority first, then page name), and clears the play state: `State/`, `Sessions/` and the players' copies, all but `State/Revealed`. Everything a library does lands in `H`: `H.pages`, `H.notifications`, `H.commands`, `H.views`. A test answers the library's questions ahead of time with `H.picks`, `H.prompts` and `H.confirms`. A file that isn't a page, such as a printed PDF, is the test's to put in `H.files[path]`, with its `lastModified`.

**The mocks answer as SilverBullet does where it has bitten.** `space.pageExists` is link resolution, as it is in 2.11: an exact name, or else any page whose path ends in it. `freezeFileList()` holds the list it reads the way a real client's lags behind a write, and `settle()` catches it up. `space.getPageMeta` asks for the page itself, and `space.fileExists` and `space.getFileMeta` are exact, over pages and `H.files` alike. A query's `where` reads `0` and `""` as false, as SilverBullet's does.

## SilverBullet's own Lua

Plain Lua is not Space Lua: `s:gsub(...):sub(2)` works here and fails there. `spacelua/libraries.test.ts` runs the GM libraries in SilverBullet's own interpreter, with its standard library, its `widget.new` and its Markdown parser, over the same campaign. It drives the bar, marks, uses and Undo, a query on the Session Table, a book build, DM-only text, whose cases it reads from `tests/dmonly.lua` so the two can't drift apart, rolls, over the scene `tests/rolls.lua` writes for its own, and the party's level: a fight in versions, DCs that rise and a check that reads them, from `tests/levels.lua`.

It needs a SilverBullet checkout at 2.11:

```
git clone --depth 1 --branch 2.11.0 https://github.com/silverbulletmd/silverbullet sb211
cd sb211 && npm ci --ignore-scripts
cp <this repo>/test/spacelua/libraries.test.ts client/space_lua/
SBLIB=<this repo> NODE_OPTIONS=--max-old-space-size=4096 npx vitest run client/space_lua/libraries.test.ts
```

**Both pass, or the library doesn't go out.**

## A real server

Some things only a real client shows: real `query[[...]]` in page bodies, requalified links after `space.writePage`, config loading across nested spaces, notifications and their buttons, widgets as the browser draws them. `instance/instance.py` runs a SilverBullet 2.11 server on `127.0.0.1:3111` with the five spaces over a copy of the campaign, and drives its headless client through the Runtime API. It is Windows-only, and needs the server (`SB_BIN`, or `instance/bin/silverbullet.exe`) and chrome-headless-shell (`SB_CHROME_PATH`).

```
python test/instance/instance.py provision          # data, campaign, admin and token; starts it
python test/instance/instance.py eval dm "type(gm)"
python test/instance/instance.py script dm flow.lua # a whole flow; `return` what to see
python test/instance/instance.py restore            # put back what a flow wrote
```

A script gets the helpers in `instance/prelude.lua`: `T.go(page)`, `T.bar()`, `T.click(label)`, `T.notes()`, `T.act("Undo")`, `T.scan()` and more. Put a whole flow in one script, since requests hold a lock but nothing else survives between them, and undo what it wrote, or `restore`. The first request after a start takes about twenty seconds. A mark takes up to ten more in the headless client, so poll for its record rather than sleeping a fixed time.
