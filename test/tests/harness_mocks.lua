------------------------------------------------------------------ Harness: the mocks
-- The mocks answer as SilverBullet 2.11 does, and these hold them to it.

-- A query's rows by name, as __liq, the query[[...]] transpiler's target,
-- orders them.
local function sorted(rows, desc)
  return list(__liq(function() return rows end, nil,
    { { fn = function(p) return p.n end, desc = desc } }, function(p) return p.name end, nil))
end

test("harness: a query sorts as SLIQ does: a nil last ascending, first descending", "dm", function()
  local rows = { { name = "a", n = 2 }, { name = "b" }, { name = "c", n = 1 },
                 { name = "d", n = 2 }, { name = "e" } }
  eq(sorted(rows, false), "c | a | d | b | e")
  eq(sorted(rows, true), "b | e | a | d | c")
end)

test("harness: a query's sort is stable, so rows that tie keep the order they came in", "dm", function()
  local rows, want = {}, {}
  for i = 1, 60 do
    rows[i] = { name = string.format("%02d", i), n = i % 3 }
  end
  for _, n in ipairs({ 0, 1, 2 }) do
    for i = 1, 60 do
      if i % 3 == n then want[#want + 1] = string.format("%02d", i) end
    end
  end
  eq(sorted(rows, false), list(want))
end)

test("harness: yaml.parse reads YAML 1.2, as js-yaml does", "dm", function()
  local v = yaml.parse(table.concat({
    "concentration: yes", "ritual: No", "lit: on", "doused: OFF", "cast: 1:30",
    "flag: true", "other: False", "count: 12", "half: 1.5", "leading: 010",
    "octal: 0o17", "hex: 0x1F", "big: 1e3", "grouped: 1_000", "nothing: ~",
  }, "\n"))
  eq(v.concentration, "yes")
  eq(v.ritual, "No")
  eq(v.lit, "on")
  eq(v.doused, "OFF")
  eq(v.cast, "1:30", "no base 60")
  eq(v.flag, true)
  eq(v.other, false)
  eq(v.count, 12)
  eq(v.half, 1.5)
  eq(v.leading, 10, "a leading zero is not octal")
  eq(v.octal, 15)
  eq(v.hex, 31)
  eq(v.big, 1000)
  eq(v.grouped, 1000)
  eq(v.nothing, nil)
  -- a key is its text, as a JavaScript object's is
  local keys = yaml.parse("yes: 1\n1: 2\n")
  eq(keys.yes, 1)
  eq(keys["1"], 2)
end)

test("harness: a failed copy is caught and shown by SilverBullet, never the caller", "dm", function()
  H.clipboardFails = true
  editor.copyToClipboard("some text")
  eq(H.clipboard, nil)
  has(lastNotification().message, "Could not copy to clipboard: ")
  eq(lastNotification().kind, "info")
  H.clipboardFails = false
  editor.copyToClipboard("some text")
  eq(H.clipboard, "some text")
end)

test("harness: a test starts on the index page, as a client always has a page open", "dm", function()
  eq(editor.getCurrentPage(), "index")
  reset("adventure")
  eq(editor.getCurrentPage(), "index")
end)

test("harness: a test that leaves a line printed fails, unless it takes it", "dm", function()
  local saved = { T = T, EXCUSED = EXCUSED, REPORT = REPORT }
  T = {
    { name = "prints", layout = "dm", file = "here", fn = function() print("oops") end },
    { name = "takes it", layout = "dm", file = "here", fn = function()
      print("meant")
      eq(list(takePrinted()), "meant")
    end },
    { name = "prints, then resets", layout = "dm", file = "here", fn = function()
      print("before")
      reset("adventure")
    end },
  }
  REPORT = {}
  local good, passed, total, failed = pcall(runAll)
  T, EXCUSED, REPORT = saved.T, saved.EXCUSED, saved.REPORT
  ok(good, passed)
  eq(total, 3)
  eq(passed, 1)
  has(failed[1], "oops")
  has(failed[2], "before", "a reset in the middle of a test lost what was printed")
  takePrinted()
end)

------------------------------------------------------------------ Harness: failing as Space Lua fails
-- Where Space Lua lets a mistake through quietly, or trips over what plain
-- Lua 5.4 allows, the mocks fail the test instead of passing it.

-- The error a call raises, or nil if it raises none.
local function raised(fn, ...)
  local good, err = pcall(fn, ...)
  if good then return nil end
  return tostring(err)
end

-- reset(layout) with these blocks standing in for the space's own, which
-- are put back however it ends; whether it loaded, and why not.
local function resetWith(layout, blocks)
  local libs = LIBS[layout]
  LIBS[layout] = blocks
  local good, err = pcall(reset, layout)
  LIBS[layout] = libs
  return good, err
end

test("harness: a test that leaves a warning fails, unless it takes it", "dm", function()
  local saved = { T = T, REPORT = REPORT }
  T = {
    { name = "warned", layout = "dm", file = "here", fn = function()
      config.set("probe", { "a", label = "b" })
    end },
    { name = "takes it", layout = "dm", file = "here", fn = function()
      config.set("probe", { "a", label = "b" })
      has(takeWarnings()[1], "mixes a list with named keys (label)")
    end },
    { name = "warned, then resets", layout = "dm", file = "here", fn = function()
      config.set("probe", { "a", label = "b" })
      reset("adventure")
    end },
  }
  REPORT = {}
  local good, passed, total, failed = pcall(runAll)
  T, REPORT = saved.T, saved.REPORT
  ok(good, passed)
  eq(total, 3)
  eq(passed, 1)
  has(failed[1], "config.set: probe mixes a list with named keys (label), and SilverBullet keeps only the list")
  has(failed[2], "mixes a list", "a reset in the middle of a test lost the warning")
  takeWarnings()
end)

-- client/space_lua/stdlib/table.ts at 2.11.0
test("harness: table.includes searches and throws as SilverBullet's does", "dm", function()
  eq(table.includes({ "a", "b" }, "b"), true)
  eq(table.includes({ "a", "b" }, "c"), false)
  eq(table.includes({ first = "a" }, "a"), true, "a named key's value counts too")
  for _, falsy in ipairs({ false, 0, "" }) do
    eq(table.includes(falsy, "a"), false, "JavaScript's false: " .. tostring(falsy))
  end
  eq(table.includes(nil, "a"), false)
  has(raised(table.includes, "chapter", "chapter"), "Cannot use includes on a non-table or non-array value")
  has(raised(table.includes, 5, 5), "Cannot use includes")
  -- config.get gives JavaScript's values: a list is an array, which it
  -- searches, and a table of named keys an object, which it throws on
  config.set("probe", { list = { "x" }, map = { a = "x" } })
  eq(table.includes(config.get("probe.list"), "x"), true)
  has(raised(table.includes, config.get("probe.map"), "x"), "Cannot use includes")
  has(raised(table.includes, config.get("probe.missing", {}), "x"), "Cannot use includes",
      "an empty default is an object too")
  eq(table.includes(config.get("probe.missing", { "x" }), "x"), true)
end)

-- client/space_lua/stdlib/string.ts at 2.11.0: n <= 0 and i < n, with a
-- whole float an object to JavaScript
test("harness: string.rep with a float count is an error, not Space Lua's quiet one", "dm", function()
  eq(string.rep("ab", 3), "ababab")
  eq(("x"):rep(2, ","), "x,x")
  eq(string.rep("x", 0), "")
  has(raised(string.rep, "a", 4 / 2), 'a count of 2.0 is a float, which Space Lua repeats as ""')
  has(raised(string.rep, "a", 2.5), "which Space Lua repeats as 3 copies")
  has(raised(function() return ("a"):rep(1.0) end), "is a float", "the method form as well")
end)

test("harness: utf8 is nil while the libraries load, as Space Lua has none", "dm", function()
  local good, err = resetWith("dm", { { name = "P #1", ref = "P@0", source = "__harnessUtf8 = utf8 ~= nil" } })
  ok(good, err)
  eq(__harnessUtf8, false, "a block saw utf8")
  ok(utf8 and utf8.char, "utf8 is back for the tests once the blocks have loaded")
  good, err = resetWith("dm", { { name = "P #1", ref = "P@0", source = "local s = utf8.char(233)" } })
  ok(not good, "a block used utf8 as it loaded")
  has(err, "load P #1 (P@0)")
  has(err, "utf8")
  ok(utf8 and utf8.char, "utf8 is back after a block failed")
  reset("dm")
end)

-- LuaTable.toJS (client/space_lua/runtime.ts): a table with a list part
-- becomes a JavaScript array of that part alone.
test("harness: config.set warns of a table that mixes a list with named keys", "dm", function()
  config.set("probe", { "a", "b", label = "x" })
  eq(config.get("probe.label"), nil, "SilverBullet keeps only the list")
  eq(config.get("probe")[2], "b")
  local warned = takeWarnings()
  eq(#warned, 1)
  eq(warned[1], "config.set: probe mixes a list with named keys (label), and SilverBullet keeps only the list")
  config.set("probe", { spaces = { { url = "/a/" }, directory = { url = "/b/" } } })
  has(takeWarnings()[1], "config.set: probe.spaces mixes a list with named keys (directory)", "a table inside")
  config.set({ probe = { "x", 3, [7] = "y" } })
  has(takeWarnings()[1], "(7)", "a key past the list's end")
  config.set("probe", { "a", "b" })
  config.set("probe", { a = 1, b = { "c" } })
  eq(#H.warnings, 0, "a list, or named keys alone, lose nothing")
  config.get("nothing", { "a", label = "x" })
  has(takeWarnings()[1], "config.get's default: nothing mixes a list")
end)

-- Library/Std/APIs/Widget at 2.11.0: widget.new raises when
-- jsonschema.validateObject finds the spec isn't its widgetSchema's shape.
test("harness: widget.new checks each field's type as 2.11's schema does", "dm", function()
  for _, spec in ipairs({
    { markdown = "x", display = "block" }, { markdown = "", display = "inline" },
    { html = "<b>x</b>" }, { html = dom.span { "x" } }, { cssClasses = { "a", "b" } },
    { events = { click = function() end } }, { sandbox = true, script = "x", html = "<div></div>" },
    {},
  }) do
    local w = widget.new(spec)
    eq(w._isWidget, true)
  end
  local function refused(spec) return raised(widget.new, spec) or "" end
  has(refused({ markdown = 5 }), 'widget.new: markdown: Instance type "number" is invalid. Expected "string".')
  has(refused({ markdown = true }), 'Instance type "boolean" is invalid. Expected "string".')
  has(refused({ cssClasses = {} }), 'cssClasses: Instance type "object" is invalid. Expected "array".',
      "an empty table is an object to JavaScript")
  has(refused({ cssClasses = "wide" }), 'Instance type "string" is invalid. Expected "array".')
  has(refused({ cssClasses = { "a", 3 } }),
      'cssClasses: Items did not match schema., cssClasses.1: Instance type "number" is invalid. Expected "string".')
  has(refused({ display = "Block" }), 'display: Instance does not match any of ["block","inline"].')
  has(refused({ html = 5 }), "html: Instance does not match any subschemas.")
  has(refused({ html = { "<b>", "</b>" } }), 'html: Instance type "array" is invalid. Expected "object".')
  has(refused({ sandbox = "yes" }), 'sandbox: Instance type "string" is invalid. Expected "boolean".')
  has(refused({ events = { function() end } }), 'events: Instance type "array" is invalid. Expected "object".')
  has(refused({ "a list" }), 'Instance type "array" is invalid. Expected "object".')
  has(refused({ markdwon = "x" }), "unknown key markdwon", "a misspelt key, which SilverBullet ignores")
end)

-- @cfworker/json-schema's words, as client/plugos/syscalls/jsonschema.ts
-- joins them: the "Property ... does not match schema." wrappers left out,
-- each error at its path, a list counted from 0.
test("harness: jsonschema.validateObject words its errors as SilverBullet's does", "dm", function()
  local schema = {
    type = "object",
    properties = {
      spaces = { type = "array", items = {
        type = "object", properties = { url = { type = "string" } }, required = { "url" },
        additionalProperties = false } },
      count = { type = "integer" },
      either = { type = { "string", "array" } },
      map = { type = "object", additionalProperties = { type = "string" } },
    },
    additionalProperties = false,
  }
  eq(jsonschema.validateObject(schema, { spaces = { { url = "/a/" } }, count = 2, either = { "x" } }), nil)
  eq(jsonschema.validateObject(schema, { count = 2.0 }), nil, "a whole float is an integer")
  eq(jsonschema.validateObject(schema, { spaces = "x" }),
     'spaces: Instance type "string" is invalid. Expected "array".')
  eq(jsonschema.validateObject(schema, { spaces = { { url = "/a/" }, { url = 5 } } }),
     'spaces: Items did not match schema., spaces.1.url: Instance type "number" is invalid. Expected "string".')
  eq(jsonschema.validateObject(schema, { spaces = { { name = "A" } } }),
     'spaces: Items did not match schema., spaces.0: Instance does not have required property "url".,' ..
     ' spaces.0: Property "name" does not match additional properties schema., spaces.0.name: False boolean schema.')
  eq(jsonschema.validateObject(schema, { count = 1.5 }), 'count: Instance type "number" is invalid. Expected "integer".')
  eq(jsonschema.validateObject(schema, { either = 3 }),
     'either: Instance type "number" is invalid. Expected "string", "array".')
  eq(jsonschema.validateObject(schema, { map = { a = "x", b = 2 } }),
     'map: Property "b" does not match additional properties schema., map.b: Instance type "number" is invalid. Expected "string".')
  eq(jsonschema.validateObject(schema, { typo = 1 }),
     'Property "typo" does not match additional properties schema., typo: False boolean schema.')
  eq(jsonschema.validateObject(schema, "x"), 'Instance type "string" is invalid. Expected "object".')
  eq(jsonschema.validateObject(schema, {}), nil, "an empty table is an empty object")
  eq(jsonschema.validateObject({ type = "array" }, {}), 'Instance type "object" is invalid. Expected "array".')
end)

-- client/config.ts at 2.11.0: Config.define, and Config.set's validatePath
test("harness: config.define's schema checks each config.set, which raises after it sets", "dm", function()
  local schema = { type = "object", properties = { list = { type = "array", items = { type = "string" } } },
                   additionalProperties = false }
  config.set("probe", { list = "set before the schema" })
  config.define("probe", schema)
  eq(config.getSchemas().properties.probe, schema)
  eq(config.get("probe.list"), "set before the schema", "a define checks nothing already set")
  config.set("probe", { list = { "a" } })
  eq(raised(config.set, "probe", { list = "a" }),
     'Validation error for probe:> list: Instance type "string" is invalid. Expected "array".')
  eq(config.get("probe.list"), "a", "the value is set all the same")
  has(raised(config.set, "probe", { lists = { "a" } }), 'Property "lists" does not match additional properties schema.')
  -- a path inside is checked against the schema nearest it
  has(raised(config.set, "probe.list", 5), 'Validation error for probe.list:> Instance type "number" is invalid.')
  config.set({ probe = { list = { "b" } } })
  eq(config.get("probe.list")[1], "b")
  has(raised(config.define, "bad", { type = "list" }), "Invalid schema for key bad: schema.type must be one of")
  has(raised(config.define, "bad", "x"), "schema must be an object or boolean")
  config.define("probe.deep.flag", { type = "boolean", default = true })
  eq(config.get("probe.deep.flag"), true, "a default applies where nothing is set")
end)

test("harness: reset puts every global back as the harness left it", "dm", function()
  __harnessLeftBehind = 1
  local real = space.readPage
  space.readPage = function() error("a test forgot to put me back") end
  gm.extra = "remembered"
  reset("dm")
  eq(__harnessLeftBehind, nil, "a global a test made")
  eq(space.readPage, real, "a mock a test replaced")
  eq(gm.extra, nil, "a library's table is made afresh")
  ok(gm, "and the space's libraries are loaded again")
  reset("player")
  eq(gm, nil, "a library the space doesn't load")
  ok(spaceSwitcher, "Player's own")
  local good, err = resetWith("dm", { { name = "P #1", ref = "P@0", source = "__harnessNew = {}" } })
  ok(good, err)
  ok(__harnessNew, "the block ran")
  reset("dm")
  eq(__harnessNew, nil, "a namespace no list of names foresaw")
end)

-- plugs/index at 2.11.0: index.pages(tag) keeps the pages carrying the tag;
-- the frontmatter's dotted keys are paths (plug-api/lib/json.ts, cleanupJSON)
test("harness: index.pages takes a tag, and dotted frontmatter keys read as tables", "dm", function()
  H.pages["Lib/Probe"] = "---\ntags: meta/library\nversion: \"1.0.0\"\nshare.uri: https://example.org/x.md\n" ..
                         "share.hash: 0a1b2c3d\nshare.mode: pull\n---\n# Probe\n"
  H.pages["Lib/Other"] = "---\ntags: [meta/library, extra]\n---\n# Other\n"
  local found = {}
  for _, p in ipairs(index.pages("meta/library")) do found[p.name] = p end
  ok(found["Lib/Probe"] and found["Lib/Other"], "both library pages")
  eq(found["index"], nil, "a page without the tag")
  eq(found["Lib/Probe"].share.uri, "https://example.org/x.md")
  eq(found["Lib/Probe"].share.mode, "pull")
  eq(found["Lib/Probe"].version, "1.0.0")
  local all = 0
  for _ in pairs(index.pages()) do all = all + 1 end
  local pages = 0
  for _ in pairs(H.pages) do pages = pages + 1 end
  eq(all, pages, "without a tag, every page")
end)
