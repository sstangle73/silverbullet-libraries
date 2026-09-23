-- What every file in tests/ shares: test() to register a test, the checks,
-- and the helpers more than one file needs. run.py loads this after
-- mocks.lua and before the tests, each file a chunk of its own.

T = {}
local loading

-- A test runs in one space: "dm", "adventure", "author", "book" or "player".
-- reset() gives it that space's pages, freshly loaded libraries, and a
-- campaign nobody has played yet.
function test(name, layout, fn)
  assert(FIXTURES[layout], "test '" .. name .. "': no space " .. tostring(layout))
  T[#T + 1] = { name = name, layout = layout, fn = fn, file = loading }
end

function loadTests(name, source)
  local chunk, err = load(source, "@" .. name)
  if not chunk then error(err, 0) end
  loading = name
  chunk()
  loading = nil
end

function eq(a, b, msg)
  if a ~= b then
    error((msg and msg .. ": " or "") .. "expected [" .. tostring(b) .. "] got [" .. tostring(a) .. "]", 2)
  end
end
function ok(v, msg) if not v then error(msg or "expected a true value", 2) end end
function has(s, sub, msg)
  if not tostring(s):find(sub, 1, true) then
    error((msg and msg .. ": " or "") .. "expected [" .. sub .. "] in [" .. tostring(s) .. "]", 2)
  end
end
function hasnt(s, sub, msg)
  if tostring(s):find(sub, 1, true) then
    error((msg and msg .. ": " or "") .. "did not expect [" .. sub .. "] in [" .. tostring(s) .. "]", 2)
  end
end
function list(t) return table.concat(t, " | ") end
function names(options)
  local out = {}
  for _, o in ipairs(options) do out[#out + 1] = o.name end
  return out
end
function count(s, sub)
  local n, i = 0, 1
  while true do
    local a, b = s:find(sub, i, true)
    if not a then return n end
    n, i = n + 1, b + 1
  end
end

-- Adventure's pages with a book_order: what a build compiles.
function bookPageCount()
  local n = 0
  for _, text in pairs(FIXTURES.adventure) do
    local head = text:match("^%-%-%-\n(.-\n)%-%-%-")
    if head and ("\n" .. head):find("\nbook_order:") then n = n + 1 end
  end
  return n
end

-- The keys SilverBullet 2.11's schema allows on an action button.
ALLOWED_BUTTON_KEYS = { icon = true, description = true, command = true, priority = true,
  mobile = true, standalone = true, accountManaged = true, dropdown = true, run = true }

-- A character page, for GM Party to count.
function pcPage(level, extra)
  return "---\ntype: pc\n" .. (level and ("level: " .. level .. "\n") or "") .. (extra or "") .. "---\n\n# PC\n"
end

-- n character pages at one level, the first `away` of them away tonight.
function useParty(n, level, away)
  for name in pairs(H.pages) do
    if name:match("^Party/") then H.pages[name] = nil end
  end
  for i = 1, n do
    H.pages[string.format("Party/PC %02d", i)] = pcPage(level, i <= (away or 0) and "away: true\n" or nil)
  end
  party.refresh()
end

-- Lines a test wants printed with the results, not as failures.
REPORT = {}

-- A library prints only when something went wrong that it chose to swallow,
-- such as a bar that failed to draw, so a test fails if anything is left in
-- H.printed at its end. A test that makes a library print on purpose takes
-- what it printed, and checks it:
--   has(takePrinted()[1], "boom")
function takePrinted()
  local lines = H.printed
  H.printed = {}
  return lines
end

-- A message that isn't valid UTF-8 would stop Python reading it back.
local function printable(s)
  if utf8.len(s) then return s end
  return (s:gsub("[\128-\255]", function(c) return string.format("\\x%02X", c:byte()) end))
end

function runAll(words)
  local passed, total, failed = 0, 0, {}
  for _, t in ipairs(T) do
    if not words or t.name:find(words, 1, true) then
      total = total + 1
      -- No H, so reset() starts the test's printed lines afresh; a reset in
      -- the middle of the test keeps them.
      H = nil
      local good, err = pcall(function()
        reset(t.layout)
        t.fn()
        if #H.printed > 0 then
          error("a library printed, as it does only when something went wrong (a test that " ..
                "means it to reads it with takePrinted()): " .. table.concat(H.printed, " | "), 0)
        end
      end)
      if good then
        passed = passed + 1
      else
        failed[#failed + 1] = printable(t.name .. "  (" .. t.file .. ")\n    " .. tostring(err))
      end
    end
  end
  return passed, total, failed, REPORT
end
