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
