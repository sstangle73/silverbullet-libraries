------------------------------------------------------------------ Storie Check
-- The campaign installs it in the adventure space, so the DM space, which
-- holds that as a folder, runs it too.

local function entry(report, name)
  for _, e in ipairs(report.libraries) do
    if e.name == name then return e end
  end
  error("no line for " .. name)
end

local function setting(report, key)
  for _, s in ipairs(report.settings) do
    if s.key == key then return s end
  end
  error("no line for " .. key)
end

local function printer(report, key)
  for _, p in ipairs(report.printers) do
    if p.key == key then return p end
  end
end

local function pages(e)
  local out = {}
  for _, c in ipairs(e.copies) do out[#out + 1] = c.page end
  return list(out)
end

local function withVersion(text, version)
  local out, n = text:gsub('\nversion: "[^"\n]*"\n', '\nversion: "' .. version .. '"\n', 1)
  assert(n == 1, "no version to change")
  return out
end

-- The share.* keys Library: Install writes into a copy's frontmatter
-- (plugs/configuration-manager/libraries.ts at 2.11.0).
local function installed(text, lib)
  local head = "---\nshare.uri: https://github.com/sstangle73/silverbullet-libraries/blob/main/src/" ..
    lib:gsub(" ", "%%20") .. ".md\nshare.hash: 1a2b3c4d\nshare.mode: pull\n"
  return (text:gsub("^%-%-%-\n", function() return head end, 1))
end

test("storie: the command and the widget, where the campaign installs it", "adventure", function()
  ok(H.commands["Storie: Check Libraries"], "no command in the adventure space")
  local w = storie.health()
  eq(w._isWidget, true)
  eq(w.display, "block")
  has(w.markdown, "**Storie libraries in this space:**")
  reset("dm")
  ok(H.commands["Storie: Check Libraries"], "the DM space runs the adventure's copy")
  reset("book")
  eq(storie, nil, "the book space has no copy")
end)

test("storie: every copy the index holds, its version, and whether Library: Install put it there", "dm", function()
  local report = storie.check()
  local switcher = entry(report, "Space Switcher")
  eq(pages(switcher), "Adventure/Library/Storie/Space Switcher | Author/Library/Storie/Space Switcher | " ..
     "Book/Library/Storie/Space Switcher | Player/Library/Storie/Space Switcher")
  eq(switcher.copies[1].version, spaceSwitcher.version)
  eq(switcher.copies[1].installed, false)
  eq(switcher.depths, nil, "four copies at one depth, as the DM space holds them")
  eq(pages(entry(report, "GM Kit")), "Library/Storie/GM Kit")
  local md = storie.markdown(report)
  has(md, "  - [[Book/Library/Storie/Space Switcher]] " .. spaceSwitcher.version ..
          ", ○ copied by hand: Library: Update skips it")
  -- a copy that Library: Install wrote
  local copy = "Author/Library/Storie/Space Switcher"
  H.pages[copy] = installed(H.pages[copy], "Space Switcher")
  report = storie.check()
  eq(entry(report, "Space Switcher").copies[2].installed, true)
  has(storie.markdown(report), "  - [[" .. copy .. "]] " .. spaceSwitcher.version .. ", ✓ from Library: Install")
end)

test("storie: each library's Lua, current, stale, older, not running or not here", "adventure", function()
  local report = storie.check()
  local nav = entry(report, "Chapter Navigation")
  eq(nav.mark, "ok")
  eq(nav.version, chapterNav.version)
  eq(nav.text, "current")
  has(storie.markdown(report), "- ✓ **Storie Check** " .. storie.version .. ": current")
  eq(entry(report, "GM Kit").mark, "absent", "the DM space's library")
  eq(entry(report, "GM Kit").text, "not installed here")
  eq(entry(report, "RecurringTasks").mark, "absent")
  -- a newer copy: reload
  local copy = "Library/Storie/Chapter Navigation"
  H.pages[copy] = withVersion(H.pages[copy], chapterNav.version .. ".1")
  report = storie.check()
  nav = entry(report, "Chapter Navigation")
  eq(nav.mark, "stale")
  eq(nav.text, (chapterNav.stale()))
  eq(report.reload, true)
  has(storie.markdown(report), "- ⟳ **Chapter Navigation** " .. chapterNav.version .. ": Chapter Navigation")
  -- an older one: update it
  H.pages[copy] = withVersion(H.pages[copy], "0.0.1")
  report = storie.check()
  eq(entry(report, "Chapter Navigation").mark, "warn")
  has(entry(report, "Chapter Navigation").text, "Update the older copy from inside its own space.")
  eq(report.reload, false)
  -- a copy here whose Lua isn't running
  H.pages[copy] = SRC["Chapter Navigation"]
  chapterNav = nil
  report = storie.check()
  eq(entry(report, "Chapter Navigation").mark, "off")
  has(storie.markdown(report), "- ✗ **Chapter Navigation**: not running, though a copy is here: run System: Reload")
  -- Lua from before libraries had a version
  reset("adventure")
  chapterNav.version, chapterNav.stale = nil, nil
  report = storie.check()
  eq(entry(report, "Chapter Navigation").mark, "warn")
  eq(entry(report, "Chapter Navigation").text,
     "loaded, an older library without a version: update it from inside its own space")
end)

test("storie: a GM library's newer copy asks for a reload, though its stale() gives words alone", "adventure", function()
  local copy = "Library/Storie/GM Book"
  local text = H.pages[copy]
  H.pages[copy] = withVersion(text, gmbook.version .. ".1")
  local report = storie.check()
  local book = entry(report, "GM Book")
  eq(book.mark, "stale")
  eq(book.text, (gmbook.stale()))
  eq(report.reload, true)
  has(storie.markdown(report), "- ⟳ **GM Book** " .. gmbook.version .. ": This tab runs GM Book")
  -- an older one: update it
  H.pages[copy] = withVersion(text, "0.0.1")
  report = storie.check()
  eq(entry(report, "GM Book").mark, "warn")
  eq(report.reload, false)
end)

test("storie: another library's stand-in table is no library of its own", "dm", function()
  -- GM Maps makes gmbook, to register its printer, where GM Book isn't
  -- installed; GM Bestiary makes party
  H.pages["Adventure/Library/Storie/GM Book"] = nil
  H.pages["Adventure/Library/Storie/GM Party"] = nil
  gmbook = { printers = gmbook.printers }
  party = { creatureRef = party.creatureRef }
  local report = storie.check()
  eq(entry(report, "GM Book").mark, "absent")
  eq(entry(report, "GM Party").mark, "absent")
  has(printer(report, "maps").text, "once GM Book runs here")
end)

test("storie: copies of one library at different depths are flagged", "dm", function()
  eq(entry(storie.check(), "GM Book").depths, nil)
  H.pages["Library/Storie/GM Book"] = SRC["GM Book"]
  local report = storie.check()
  local book = entry(report, "GM Book")
  eq(pages(book), "Adventure/Library/Storie/GM Book | Library/Storie/GM Book")
  has(book.depths, "copies at different depths")
  has(list(report.problems), "GM Book has copies at different depths: Adventure/Library/Storie/GM Book, Library/Storie/GM Book")
  has(storie.markdown(report), "  - ⚠ copies at different depths, and a space that holds others runs every one")
end)

test("storie: GM Book's printers, and a library that runs without one", "adventure", function()
  local report = storie.check()
  for _, key in ipairs({ "bestiary", "maps", "party", "sheets" }) do
    local p = printer(report, key)
    ok(p, "no printer line for " .. key)
    eq(p.mark, "ok", key)
  end
  eq(printer(report, "party").text, "GM Party tells GM Book how to print it")
  has(storie.markdown(report), "- ✓ `sheets`: GM Sheets tells GM Book how to print it")
  gmbook.printers.maps = nil
  report = storie.check()
  eq(printer(report, "maps").mark, "warn")
  eq(printer(report, "maps").text,
     "GM Maps runs here but hasn't told GM Book how to print it: a book prints what the page shows")
  has(list(report.problems), "GM Maps has no printer in gmbook.printers")
  gmbook = nil
  eq(#storie.check().printers, 4, "without GM Book's table, each of the four that run misses its printer")
end)

test("storie: the small libraries' settings, held to the shape each declares", "dm", function()
  local report = storie.check()
  for _, key in ipairs({ "spaceSwitcher", "chapterNav", "appearances" }) do
    eq(setting(report, key).mark, "ok", key)
  end
  eq(setting(report, "chapterNav").text, "the shape Chapter Navigation reads")
  pcall(config.set, "chapterNav", { types = "chapter" })
  report = storie.check()
  eq(setting(report, "chapterNav").mark, "warn")
  eq(setting(report, "chapterNav").text,
     'not the shape Chapter Navigation reads: types: Instance type "string" is invalid. Expected "array".')
  has(storie.markdown(report),
      '- ⚠ `chapterNav`: not the shape Chapter Navigation reads: types: Instance type "string" is invalid. Expected "array".')
  has(list(report.problems), "chapterNav isn't the shape Chapter Navigation reads")
  H.config.appearances = nil
  eq(setting(storie.check(), "appearances").text, "not set: Appearances uses its defaults")
  -- set, where the library that reads it isn't running
  reset("adventure")
  config.set("appearances", { fields = { person = "people" } })
  eq(setting(storie.check(), "appearances").text, "set, but Appearances isn't running here to read it")
  eq(setting(storie.check(), "appearances").mark, "absent")
  -- a library from before the shape was declared
  chapterNav.schema = nil
  eq(setting(storie.check(), "chapterNav").text,
     "set, and Chapter Navigation declares no shape to hold it to: an older version")
end)

test("storie: the command sums it up, and offers a reload when one would help", "book", function()
  loadLibrary("Storie Check")
  H.commands["System: Reload"] = { name = "System: Reload", run = function() H.reloaded = (H.reloaded or 0) + 1 end }
  editor.invokeCommand("Storie: Check Libraries")
  eq(lastNotification().message, "✓ Storie libraries: 4 current, 8 not here. Nothing to put right.")
  eq(lastNotification().kind, "info")
  local copy = "Library/Storie/Appearances"
  H.pages[copy] = withVersion(H.pages[copy], kb.version .. ".1")
  editor.invokeCommand("Storie: Check Libraries")
  local n = lastNotification()
  eq(n.kind, "warning")
  has(n.message, "⚠ Storie libraries: 3 current, 1 waiting for a reload, 8 not here. ")
  has(n.message, "Appearances " .. kb.version .. " is running; " .. copy .. " holds " .. kb.version .. ".1. Run System: Reload.")
  has(n.message, "Put ${storie.health()} on a page for the whole list.")
  runAction(n, "Reload")
  eq(H.reloaded, 1)
  -- an older copy: nothing a reload fixes
  H.pages[copy] = withVersion(H.pages[copy], "0.0.1")
  editor.invokeCommand("Storie: Check Libraries")
  eq(lastNotification().options.actions, nil)
end)

-- A phone shows a notification's first lines: what a reload fixes comes
-- first, then what isn't running, and past three the rest are counted.
test("storie: the command names a reload first, and counts past three", "book", function()
  loadLibrary("Storie Check")
  chapterNav.version = nil
  pcall(config.set, "chapterNav", { types = "chapter" })
  H.pages["Notes/Library/Storie/Space Switcher"] = SRC["Space Switcher"]
  spaceSwitcher = nil
  local copy = "Library/Storie/Appearances"
  H.pages[copy] = withVersion(H.pages[copy], kb.version .. ".1")
  local problems = storie.check().problems
  eq(#problems, 5, list(problems))
  has(problems[1], "Appearances " .. kb.version .. " is running")
  eq(problems[2], "Space Switcher isn't running, though a copy is here")
  editor.invokeCommand("Storie: Check Libraries")
  local message = lastNotification().message
  has(message, ". Appearances " .. kb.version .. " is running; ")
  has(message, " Space Switcher isn't running, though a copy is here. Chapter Navigation is an older library " ..
               "without a version. And 2 more. Put ${storie.health()} on a page for the whole list.")
end)

test("storie: what it can't find out is a line, never an error", "adventure", function()
  chapterNav.stale = function() error("boom") end
  local report = storie.check()
  eq(entry(report, "Chapter Navigation").mark, "warn")
  has(entry(report, "Chapter Navigation").text, "its stale() failed: ")
  has(entry(report, "Chapter Navigation").text, "boom")
  local real = index.pages
  index.pages = function() error("index gone") end
  local good, w = pcall(storie.health)
  index.pages = real
  ok(good, tostring(w))
  has(w.markdown, "⚠ The index couldn't be read: ")
  has(w.markdown, "index gone")
  -- a copy of a Storie library it doesn't know
  H.pages["Library/Storie/GM Almanac"] = "---\ntags: meta/library\nversion: \"0.1.0\"\n---\n# GM Almanac\n"
  local almanac = entry(storie.check(), "GM Almanac")
  eq(almanac.mark, "absent")
  eq(almanac.text, "Storie Check doesn't know this library, so can't tell what it runs")
  eq(pages(almanac), "Library/Storie/GM Almanac")
end)

test("storie: a name that isn't a table, no validator, and a check that fails, in words", "dm", function()
  spaceSwitcher = "a string"
  eq(entry(storie.check(), "Space Switcher").text, "spaceSwitcher isn't a library's table here")
  reset("dm")
  jsonschema = nil
  eq(setting(storie.check(), "chapterNav").text,
     "set, but this SilverBullet has no jsonschema.validateObject to check it with")
  reset("dm")
  jsonschema.validateObject = function() error("validator gone") end
  local line = setting(storie.check(), "chapterNav")
  eq(line.mark, "warn")
  has(line.text, "couldn't be checked: ")
  has(line.text, "validator gone")
  reset("dm")
  storie.check = function() error("no index") end
  storie.notify()
  eq(lastNotification().kind, "error")
  has(lastNotification().message, "✗ Storie Check failed: ")
  has(storie.health().markdown, "⚠ Storie Check failed: ")
end)

-- Names and messages come from pages and settings: nothing in them may
-- read as Markdown, or as ${...}.
test("storie: what it shows is escaped for Markdown", "adventure", function()
  local copy = "Library/Storie/Chapter Navigation"
  H.pages[copy] = withVersion(H.pages[copy], "9.0_beta*${x}")
  local md = storie.markdown()
  has(md, "holds 9.0\\_beta\\*\\$\\{x\\}")
  has(md, "[[" .. copy .. "]] 9.0\\_beta\\*\\$\\{x\\}, ")
  hasnt(md, "9.0_beta")
end)

-- Every line starts with its mark, and the mark is never alone: words
-- follow it, so the state never rests on the glyph, or on colour.
test("storie: every line has a mark and its words", "dm", function()
  H.pages["Library/Storie/GM Book"] = SRC["GM Book"]
  pcall(config.set, "chapterNav", { types = "chapter" })
  local md = storie.markdown()
  local lines = 0
  for line in (md .. "\n"):gmatch("([^\n]*)\n") do
    if line:match("^%s*%- ") then
      lines = lines + 1
      local rest = line:match("^%s*%- (.*)$")
      if not rest:match("^%[%[") then
        local mark = rest:match("^([^%s]+) ")
        ok(({ ["✓"] = true, ["⟳"] = true, ["⚠"] = true, ["✗"] = true, ["○"] = true })[mark],
           "a line without its mark: " .. line)
        ok(#rest > #mark + 4, "a mark without words: " .. line)
      else
        ok(line:find("✓ from Library: Install", 1, true) or line:find("○ copied by hand", 1, true), line)
      end
    end
  end
  ok(lines > 20, "the check listed " .. lines .. " lines")
end)
