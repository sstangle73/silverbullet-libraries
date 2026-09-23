------------------------------------------------------------------ RecurringTasks

-- RecurringTasks isn't one of the campaign's libraries, so no space loads it:
-- each test here loads its block from src/ itself, through run.py's own
-- query rewrite (the global transpile).

local function loadRecurring()
  recurringTasks = nil
  local n = 0
  for block in SRC["RecurringTasks"]:gmatch("```space%-lua\n(.-)\n```") do
    n = n + 1
    assert(load(transpile(block), "=RecurringTasks #" .. n))()
  end
  assert(n > 0, "RecurringTasks has no space-lua block")
end

-- The index's tasks, the way SilverBullet 2.11 indexes them
-- (plugs/index/item.ts): a list item with a checkbox, outside code blocks.
-- `text` is what follows the checkbox, `name` the same without its
-- [key: value] attributes and hashtags, `done` whether it is ticked.
local function tasksIn(pages)
  local out = {}
  for page, text in pairs(pages) do
    local fence, pos = nil, 0
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
      local mark = line:match("^%s*(```)") or line:match("^%s*(~~~)")
      if fence then
        if mark == fence then fence = nil end
      elseif mark then
        fence = mark
      else
        local state, rest = line:match("^%s*[%*%-%+]%s+%[(.)%]%s*(.-)%s*$")
        if state then
          local name = rest:gsub("%[[%w_%-]+:[^%]]*%]", ""):gsub("#[%w_/%-]+", "")
          out[#out + 1] = { ref = page .. "@" .. pos, tag = "task", page = page, state = state,
                            done = state == "x" or state == "X", text = rest,
                            name = name:match("^%s*(.-)%s*$") }
        end
      end
      pos = pos + #line + 1
    end
  end
  return out
end

local realTime, realDate = os.time, os.date

-- The clock at that hour of that day, for the library and the test alike.
local function at(date, hour)
  local y, m, d = date:match("^(%d+)%-(%d+)%-(%d+)$")
  local now = realTime({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = hour or 9 })
  os.time = function(t) if t == nil then return now end return realTime(t) end
  os.date = function(format, t) return realDate(format, t or now) end
end

-- Every date from one to another, as text.
local function dates(from, to)
  local function noon(s)
    local y, m, d = s:match("^(%d+)%-(%d+)%-(%d+)$")
    return realTime({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12 })
  end
  local out, t, stop = {}, noon(from), noon(to)
  while t <= stop + 3600 do
    out[#out + 1] = realDate("%Y-%m-%d", t)
    t = t + 86400
  end
  return out
end

local function weekday(date)
  local y, m, d = date:match("^(%d+)%-(%d+)%-(%d+)$")
  return tonumber(realDate("%w", realTime({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12 })))
end

-- A test with RecurringTasks loaded, the index's tasks read from H.pages, and
-- the clock put back after. SilverBullet 2.11 still has the deprecated
-- system.getSpaceConfig, which 1.0.0 reads its settings with; H.deprecated
-- counts its calls.
local function recurring(name, fn)
  test("recurring: " .. name, "author", function()
    local saved = { tasks = index.tasks, available = index.isAvailable, getSpaceConfig = system.getSpaceConfig,
                    readPage = space.readPage, writePage = space.writePage }
    index.tasks = function() return tasksIn(H.pages) end
    system.getSpaceConfig = function(key, default)
      H.deprecated = (H.deprecated or 0) + 1
      return config.get(key, default)
    end
    local good, err = pcall(function()
      loadRecurring()
      fn()
    end)
    os.time, os.date = realTime, realDate
    index.tasks, index.isAvailable = saved.tasks, saved.available
    system.getSpaceConfig, space.readPage, space.writePage = saved.getSpaceConfig, saved.readPage, saved.writePage
    if not good then error(err, 0) end
  end)
end

local HEADER = "### 🔄 Recurring Tasks"

local function master(...)
  H.pages["RecurringTasks"] = table.concat({ ... }, "\n") .. "\n"
end

-- A daily note as the command writes one: its recurring section, these tasks.
local function daily(date, ...)
  H.pages["Inbox/" .. date] = "\n\n" .. HEADER .. "\n" .. table.concat({ ... }, "\n") .. "\n"
end

local function note(date) return H.pages["Inbox/" .. date] end

-- Ticks off every open task in a day's note.
local function tick(date)
  H.pages["Inbox/" .. date] = (note(date):gsub("%[ %]", "[x]"))
end

local function generate(date, hour)
  at(date, hour)
  H.notifications = {}
  H.commands["Tasks: Generate for Today"].run()
  return lastNotification() and lastNotification().message
end

local function kinds(kind)
  local out = {}
  for _, n in ipairs(H.notifications) do
    if n.kind == kind then out[#out + 1] = n.message end
  end
  return table.concat(out, " | ")
end

------------------------------------------------------------ The command

-- The master list's forms, quoted and not, and a daily note in the format
-- 1.0 wrote, which a year of notes is kept in. 1.0 passes this one.
recurring("the note it writes keeps 1.0's format", function()
  master("# Chores",
         "* [ ] Feed the fish [recur: day_1]",
         '* [ ] 🪴 Water the ferns [recur: "day_2"] [start: "2026-09-21"] [include: "weekend"]',
         "* [ ] Put the bins out [recur: week_1] [start: 2026-09-02]")
  for _, date in ipairs(dates("2026-09-01", "2026-09-22")) do
    H.pages["Inbox/" .. date] = "# " .. date .. "\n"
  end
  local first = "\n\n" .. HEADER .. "\n* [ ] Feed the fish\n* [ ] 🪴 Water the ferns\n* [ ] Put the bins out\n"
  eq(generate("2026-09-23", 15), "✅ Added 3 tasks")
  eq(note("2026-09-23"), first)
  eq(generate("2026-09-23", 16), "Recurring tasks up to date.")
  eq(note("2026-09-23"), first)
  tick("2026-09-23")
  eq(generate("2026-09-24", 15), "✅ Added 1 tasks")
  eq(note("2026-09-24"), "\n\n" .. HEADER .. "\n* [ ] Feed the fish\n")
end)

-- 1.0 counted days in seconds from noon on the start date, so before noon a
-- day_2 task came up a day late, and a week_2 task a week late.
recurring("a task's dates don't move with the hour", function()
  local function run(date, hour)
    for name in pairs(H.pages) do
      if name:match("^Inbox/") then H.pages[name] = nil end
    end
    master("* [ ] Water the ferns [recur: day_2] [start: 2026-09-21] [include: weekend]",
           "* [ ] Sweep the yard [recur: week_2] [start: 2026-09-09]")
    for _, before in ipairs(dates("2026-09-07", date)) do
      if before ~= date then daily(before, "* [x] Feed the fish") end
    end
    generate(date, hour)
    return note(date)
  end
  for _, hour in ipairs({ 8, 15 }) do
    has(run("2026-09-23", hour), "* [ ] Water the ferns\n* [ ] Sweep the yard\n", "the 23rd at " .. hour)
    eq(run("2026-09-24", hour), nil, "the 24th at " .. hour)
  end
end)

-- The date passed with no note on it, so the task is caught up: once. 1.0
-- caught up any date in the last 90 days whose note was missing, so a weekly
-- task came back every day for three months.
recurring("a weekly task comes up once, however many notes are missing", function()
  master("* [ ] Put the bins out [recur: week_1] [start: 2026-09-02]")
  daily("2026-09-16", "* [x] Put the bins out")
  daily("2026-09-17", "* [x] Feed the fish")
  daily("2026-09-23", "* [x] Put the bins out")
  daily("2026-09-24", "* [x] Feed the fish")
  eq(generate("2026-09-25"), "No recurring tasks due.", "the 9th has no note, but that was two weeks ago")
  -- Away on the Wednesday and the Thursday: Friday catches it up...
  H.pages["Inbox/2026-09-23"], H.pages["Inbox/2026-09-24"] = nil, nil
  eq(generate("2026-09-25"), "✅ Added 1 tasks")
  has(note("2026-09-25"), "* [ ] Put the bins out")
  tick("2026-09-25")
  -- ...and Monday doesn't bring it back.
  eq(generate("2026-09-28"), "No recurring tasks due.")
end)

-- Saturday's note was written for the weekend's own tasks, which 1.0 took to
-- mean the weekday task had had its chance.
recurring("a weekday task due on a Saturday comes up on the Monday", function()
  master("* [ ] Pay the window cleaner [recur: week_2] [start: 2026-09-12]",
         "* [ ] Feed the cat [recur: day_1] [include: weekend]")
  for _, date in ipairs(dates("2026-09-12", "2026-09-25")) do
    daily(date, "* [x] Feed the cat")
  end
  for _, date in ipairs({ "2026-09-26", "2026-09-27" }) do
    eq(generate(date, 15), "✅ Added 1 tasks", date)
    eq(note(date), "\n\n" .. HEADER .. "\n* [ ] Feed the cat\n", date)
    tick(date)
  end
  eq(generate("2026-09-28", 15), "✅ Added 2 tasks")
  eq(note("2026-09-28"), "\n\n" .. HEADER .. "\n* [ ] Pay the window cleaner\n* [ ] Feed the cat\n")
  tick("2026-09-28")
  eq(generate("2026-09-29", 15), "✅ Added 1 tasks", "Tuesday: the cat only")
end)

-- 1.0 wanted the 31st itself, so a month without one never had the task.
recurring("a month_1 task from the 31st is due on a shorter month's last day", function()
  master("* [ ] Pay the rent [recur: month_1] [start: 2026-01-31] [include: weekend]")
  for _, date in ipairs(dates("2026-07-02", "2026-09-29")) do
    H.pages["Inbox/" .. date] = "# " .. date .. "\n"
  end
  eq(generate("2026-09-30"), "✅ Added 1 tasks")
  has(note("2026-09-30"), "* [ ] Pay the rent")
  for _, date in ipairs(dates("2026-01-31", "2026-02-27")) do
    H.pages["Inbox/" .. date] = "# " .. date .. "\n"
  end
  eq(generate("2026-02-28"), "✅ Added 1 tasks")
end)

-- 1.0 read only a month's date and number, so it was due before it started.
recurring("a monthly task isn't due before its start date", function()
  master("* [ ] Renew the parking permit [recur: month_1] [start: 2026-10-23] [include: weekend]")
  eq(generate("2026-09-23"), "No recurring tasks due.")
  eq(generate("2026-10-23"), "✅ Added 1 tasks")
end)

-- 1.0 ended the section only at the next ### heading, so a task of your own
-- under ## Work was marked moved and brought to today.
recurring("rollover takes the recurring section only, to the next heading as high", function()
  master("# Chores")
  H.pages["Inbox/2026-09-22"] = table.concat({
    "# Tuesday", "", HEADER,
    "* [ ] Feed the fish", "#### Garden", "- [ ] Water the ferns", "* [x] Put the bins out", "",
    "## Work", "* [ ] Send the invoice", "",
  }, "\n")
  eq(generate("2026-09-23"), "✅ Added 2 tasks (2 rolled over)")
  eq(note("2026-09-23"), "\n\n" .. HEADER .. "\n* [ ] Feed the fish\n* [ ] Water the ferns\n")
  eq(note("2026-09-22"), table.concat({
    "# Tuesday", "", HEADER,
    "* [>] Feed the fish", "#### Garden", "- [>] Water the ferns", "* [x] Put the bins out", "",
    "## Work", "* [ ] Send the invoice", "",
  }, "\n"))
  H.pages["Inbox/2026-09-21"] = HEADER .. "\n* [ ] Buy milk\n### Shopping\n* [ ] Buy bread\n"
  eq(generate("2026-09-23"), "✅ Added 1 tasks (1 rolled over)", "a ### heading ends it as well")
  eq(note("2026-09-21"), HEADER .. "\n* [>] Buy milk\n### Shopping\n* [ ] Buy bread\n")
end)

-- 1.0 added them at the end of the page, under whatever heading was last,
-- where the next day's rollover doesn't look.
recurring("new tasks go at the end of today's recurring section", function()
  master("* [ ] Put the bins out [recur: week_1] [start: 2026-09-02]")
  H.pages["Inbox/2026-09-23"] = "# Wednesday\n\n" .. HEADER .. "\n* [x] Feed the fish\n\n## Work\n* [ ] Send the invoice\n"
  eq(generate("2026-09-23"), "✅ Added 1 tasks")
  eq(note("2026-09-23"),
     "# Wednesday\n\n" .. HEADER .. "\n* [x] Feed the fish\n* [ ] Put the bins out\n\n## Work\n* [ ] Send the invoice\n")
  eq(generate("2026-09-24"), "✅ Added 1 tasks (1 rolled over)")
  eq(note("2026-09-24"), "\n\n" .. HEADER .. "\n* [ ] Put the bins out\n")
end)

-- 1.0 took any line that began with the task's text for the task.
recurring("a task isn't taken for another that starts the same", function()
  master("* [ ] Water the herbs [recur: day_1]")
  H.pages["Inbox/2026-09-23"] = "* [x] Water the herbs on the balcony\n"
  eq(generate("2026-09-23"), "✅ Added 1 tasks")
  eq(note("2026-09-23"), "* [x] Water the herbs on the balcony\n\n\n" .. HEADER .. "\n* [ ] Water the herbs\n")
end)

-- 1.0 asked for a function the index hasn't had since 2.8, and took the
-- failure for "never done": a completion task came up every day.
recurring("completion counts from the last daily note it was ticked in", function()
  master('* [ ] Sharpen the knives [recur: "day_14"] [include: "weekend"] [strategy: "completion"] [start: "2026-01-08"]')
  daily("2026-09-02", "* [x] Sharpen the knives")
  daily("2026-09-15", "* [x] Sharpen the knives")
  -- A tick on a page that isn't a daily note has no date, and doesn't count.
  H.pages["Projects/Kitchen"] = "* [x] Sharpen the knives\n"
  eq(generate("2026-09-23"), "No recurring tasks due.", "8 days after")
  eq(generate("2026-09-28"), "No recurring tasks due.", "13 days after")
  eq(generate("2026-09-29"), "✅ Added 1 tasks", "14 days after")
  tick("2026-09-29")
  eq(generate("2026-10-12"), "No recurring tasks due.")
  eq(generate("2026-10-13"), "✅ Added 1 tasks")
  eq(kinds("error"), "")
end)

recurring("completion: never done, it counts from the start date, or is due at once", function()
  master("* [ ] Clean the gutters [recur: day_30] [strategy: completion] [start: 2026-09-01] [include: weekend]",
         "* [ ] Read the meter [recur: week_1] [strategy: completion]")
  eq(generate("2026-09-30"), "✅ Added 1 tasks")
  eq(note("2026-09-30"), "\n\n" .. HEADER .. "\n* [ ] Read the meter\n")
  eq(generate("2026-10-01"), "✅ Added 2 tasks (1 rolled over)", "30 days after the start, and the meter still never done")
  eq(note("2026-10-01"), "\n\n" .. HEADER .. "\n* [ ] Clean the gutters\n* [ ] Read the meter\n")
end)

-- 1.0 counted a month as 30 days and never reached a quarter or a year.
recurring("completion: months, quarters and years are calendar ones", function()
  master("* [ ] Check the smoke alarms [recur: month_1] [strategy: completion] [include: weekend]",
         "* [ ] Descale the kettle [recur: quarter_1] [strategy: completion] [include: weekend]",
         "* [ ] Service the boiler [recur: year_1] [strategy: completion] [include: weekend]")
  daily("2025-10-01", "* [x] Service the boiler")
  daily("2026-01-31", "* [x] Check the smoke alarms")
  daily("2026-05-10", "* [x] Descale the kettle")
  eq(generate("2026-02-27"), "No recurring tasks due.")
  eq(generate("2026-02-28"), "✅ Added 1 tasks", "a month after 31 January")
  has(note("2026-02-28"), "Check the smoke alarms")
  H.pages["Inbox/2026-02-28"] = nil
  daily("2026-08-01", "* [x] Check the smoke alarms")
  eq(generate("2026-08-09"), "No recurring tasks due.")
  eq(generate("2026-08-10"), "✅ Added 1 tasks", "a quarter after 10 May")
  has(note("2026-08-10"), "Descale the kettle")
  tick("2026-08-10")
  daily("2026-09-01", "* [x] Check the smoke alarms")
  eq(generate("2026-09-30"), "No recurring tasks due.")
  eq(generate("2026-10-01"), "✅ Added 2 tasks", "a month after 1 September, a year after 1 October 2025")
end)

-- 1.0 let the failed call pass without a word.
recurring("a failed index query is an error you see, and the rest still comes", function()
  master("* [ ] Feed the fish [recur: day_1]",
         "* [ ] Sharpen the knives [recur: day_14] [strategy: completion] [start: 2026-01-08]")
  index.tasks = function() error("the index is gone") end
  eq(generate("2026-09-23"), "✅ Added 1 tasks")
  eq(note("2026-09-23"), "\n\n" .. HEADER .. "\n* [ ] Feed the fish\n")
  local err = kinds("error")
  has(err, "the index is gone")
  has(err, "Sharpen the knives")
end)

recurring("an index still being built is said, and waited for", function()
  master("* [ ] Sharpen the knives [recur: day_14] [strategy: completion] [start: 2026-01-08]")
  index.isAvailable = function() return false end
  eq(generate("2026-09-23"), "No recurring tasks due.")
  has(kinds("error"), "still indexing")
  has(kinds("error"), "Sharpen the knives")
  index.isAvailable = function() return true end
  eq(generate("2026-09-24"), "✅ Added 1 tasks")
end)

recurring("its settings come from config.get", function()
  H.config.recurringTasks = { sourcePage = "Chores", dailyNotePrefix = "Journal/",
                              rolloverHeader = "## Recurring", maxLookbackDays = 3 }
  H.pages["Chores"] = "* [ ] Feed the fish [recur: day_1]\n"
  H.pages["Journal/2026-09-18"] = "## Recurring\n* [ ] Buy milk\n"
  H.pages["Journal/2026-09-22"] = "## Recurring\n* [ ] Buy bread\n"
  eq(generate("2026-09-23"), "✅ Added 2 tasks (1 rolled over)", "the 18th is more than 3 days back")
  eq(H.pages["Journal/2026-09-23"], "\n\n## Recurring\n* [ ] Feed the fish\n* [ ] Buy bread\n")
  eq(H.deprecated, nil, "system.getSpaceConfig, deprecated in 2.11")
end)

-- 1.0 stopped at a zero with a Lua error, and passed over an unknown unit.
recurring("a schedule it can't read is named, and the rest still comes", function()
  master("* [ ] Feed the fish [recur: day_1]",
         "* [ ] Wind the clock [recur: day_0]",
         "* [ ] Oil the gate [recur: fortnight_1]")
  eq(generate("2026-09-23"), "✅ Added 1 tasks")
  has(kinds("warning"), "2 lines")
  has(kinds("warning"), "Wind the clock")
end)

recurring("a missing master list says so", function()
  eq(generate("2026-09-23"),
     "❌ Error: Page 'RecurringTasks' not found. Check your recurringTasks settings.")
end)

-- 1.0 took any failure to read today's note for a missing note, and wrote a
-- new one over it.
recurring("today's note is never written over when it can't be read", function()
  master("* [ ] Feed the fish [recur: day_1]")
  H.pages["Inbox/2026-09-23"] = "# My day\n"
  local read = space.readPage
  space.readPage = function(name)
    if name == "Inbox/2026-09-23" then error("Failed to fetch") end
    return read(name)
  end
  generate("2026-09-23")
  eq(note("2026-09-23"), "# My day\n")
  has(kinds("error"), "Failed to fetch")
end)

-- 1.0 marked the old note first, so a failed write lost the task.
recurring("past notes are marked only once today's note is written", function()
  master("# Chores")
  daily("2026-09-22", "* [ ] Feed the fish")
  local write = space.writePage
  space.writePage = function(name, text)
    if name == "Inbox/2026-09-23" then error("Failed to fetch") end
    return write(name, text)
  end
  pcall(generate, "2026-09-23")
  eq(note("2026-09-22"), "\n\n" .. HEADER .. "\n* [ ] Feed the fish\n")
  has(kinds("error"), "Failed to fetch")
end)

-- Ten weeks of mornings, ticking everything off each day: every unit, and a
-- weekday task whose date falls on a weekend.
recurring("ten weeks of mornings", function()
  master("* [ ] Feed the fish [recur: day_1]",
         "* [ ] Water the ferns [recur: day_2] [start: 2026-09-21] [include: weekend]",
         "* [ ] Put the bins out [recur: week_1] [start: 2026-09-02]",
         "* [ ] Pay the rent [recur: month_1] [start: 2026-01-31] [include: weekend]",
         "* [ ] Descale the kettle [recur: quarter_1] [start: 2026-08-15]",
         "* [ ] Renew the insurance [recur: year_1] [start: 2025-10-10]")
  -- A summer of notes before it, so nothing is a date missed.
  for _, date in ipairs(dates("2026-06-01", "2026-09-20")) do
    H.pages["Inbox/" .. date] = "# " .. date .. "\n"
  end
  local seen = {}
  for _, date in ipairs(dates("2026-09-21", "2026-11-30")) do
    generate(date, 7)
    for task in (note(date) or ""):gmatch("%* %[ %] ([^\n]+)") do
      seen[task] = seen[task] or {}
      table.insert(seen[task], date)
    end
    if note(date) then tick(date) end
  end
  local want = { ["Feed the fish"] = {}, ["Water the ferns"] = {}, ["Put the bins out"] = {} }
  for i, date in ipairs(dates("2026-09-21", "2026-11-30")) do
    local w = weekday(date)
    if w ~= 0 and w ~= 6 then table.insert(want["Feed the fish"], date) end
    if i % 2 == 1 then table.insert(want["Water the ferns"], date) end
    if w == 3 then table.insert(want["Put the bins out"], date) end
  end
  want["Pay the rent"] = { "2026-09-30", "2026-10-31", "2026-11-30" }
  want["Descale the kettle"] = { "2026-11-16" }    -- 15 November is a Sunday
  want["Renew the insurance"] = { "2026-10-12" }   -- 10 October is a Saturday
  for task, days in pairs(want) do
    eq(list(seen[task] or {}), list(days), task)
  end
end)

------------------------------------------------------------ The schedule

local function spec(line) return assert(recurringTasks.parse(line), line) end

-- A task's dates between two days, before the weekend rule.
local function scheduled(line, from, to)
  local s, out = spec(line), {}
  for _, date in ipairs(dates(from, to)) do
    if recurringTasks.scheduled(s, recurringTasks.parseDate(date)) then out[#out + 1] = date end
  end
  return list(out)
end

recurring("dates are whole days, the calendar's own", function()
  local rt = recurringTasks
  eq(rt.day(1970, 1, 1), 0)
  eq(rt.parseDate("2026-09-22"), 20718)
  eq(rt.weekday(20718), 2, "a Tuesday")
  for n = rt.day(1970, 1, 1), rt.day(2100, 12, 31) do
    local y, m, d = rt.date(n)
    if rt.day(y, m, d) ~= n or rt.iso(n) ~= realDate("!%Y-%m-%d", n * 86400)
        or rt.weekday(n) ~= tonumber(realDate("!%w", n * 86400)) then
      error("day " .. n .. ": " .. rt.iso(n) .. ", " .. realDate("!%Y-%m-%d", n * 86400))
    end
  end
  eq(rt.iso(rt.day(2026, 2, 30)), "2026-03-02", "rolled on, as os.time rolls it")
  eq(rt.iso(rt.day(2026, 13, 1)), "2027-01-01")
  eq(rt.iso(rt.addMonths(rt.parseDate("2026-01-31"), 1)), "2026-02-28")
  eq(rt.iso(rt.addMonths(rt.parseDate("2024-02-29"), 12)), "2025-02-28")
  eq(rt.iso(rt.addMonths(rt.parseDate("2026-11-30"), 3)), "2027-02-28")
  eq(rt.parseDate("tomorrow"), nil)
end)

recurring("a master list line, read", function()
  local s = spec('* [ ] 🪴 Water the ferns [recur: "day_2"] [start: "2026-09-21"] [include: "weekend"] [strategy: "completion"]')
  eq(s.unit, "day")
  eq(s.every, 2)
  eq(recurringTasks.iso(s.start), "2026-09-21")
  eq(s.weekend, true)
  eq(s.strategy, "completion")
  eq(s.line, "* [ ] 🪴 Water the ferns")
  eq(s.key, "🪴 Water the ferns")
  s = spec("- [ ] Put the bins out [recur: Week_1] [start: 2026-09-02] (every Wednesday)")
  eq(s.unit .. " " .. s.every .. " " .. s.strategy .. " " .. tostring(s.weekend), "week 1 strict false")
  eq(s.line, "- [ ] Put the bins out (every Wednesday)")
  eq(s.key, "Put the bins out (every Wednesday)")
  eq(spec("* [ ] Feed the fish [recur: day_1]").start, nil)
  -- A phone's curly quotes, which 1.0 took in a recur but not in the rest.
  s = spec("* [ ] Feed the fish [recur: “day_2”] [start: “2026-09-21”] [include: ‘weekend’] [strategy: “completion”]")
  eq(s.unit .. " " .. s.every .. " " .. recurringTasks.iso(s.start) .. " " .. tostring(s.weekend) .. " " .. s.strategy,
     "day 2 2026-09-21 true completion")
  eq(s.line, "* [ ] Feed the fish")
  eq(recurringTasks.parse("* [ ] Feed the fish"), nil)
  local none, bad = recurringTasks.parse("* [ ] Wind the clock [recur: day_0]")
  eq(none, nil)
  eq(bad, "* [ ] Wind the clock [recur: day_0]")
  eq(select(2, recurringTasks.parse("* [ ] Oil the gate [recur: fortnight_1]")), "* [ ] Oil the gate [recur: fortnight_1]")
end)

recurring("every unit from a start date", function()
  eq(scheduled("[recur: day_2] [start: 2026-09-21]", "2026-09-19", "2026-09-28"),
     "2026-09-21 | 2026-09-23 | 2026-09-25 | 2026-09-27")
  eq(scheduled("[recur: day_3] [start: 2026-02-03]", "2026-02-01", "2026-02-12"),
     "2026-02-03 | 2026-02-06 | 2026-02-09 | 2026-02-12")
  eq(scheduled("[recur: week_1] [start: 2025-01-01]", "2026-09-20", "2026-10-10"),
     "2026-09-23 | 2026-09-30 | 2026-10-07")
  eq(scheduled("[recur: week_2] [start: 2026-02-04]", "2026-02-01", "2026-03-10"),
     "2026-02-04 | 2026-02-18 | 2026-03-04")
  eq(scheduled("[recur: month_1] [start: 2026-02-04]", "2026-01-01", "2026-04-30"),
     "2026-02-04 | 2026-03-04 | 2026-04-04")
  eq(scheduled("[recur: month_1] [start: 2026-01-31]", "2026-01-01", "2026-06-30"),
     "2026-01-31 | 2026-02-28 | 2026-03-31 | 2026-04-30 | 2026-05-31 | 2026-06-30")
  eq(scheduled("[recur: month_6] [start: 2026-02-04]", "2026-01-01", "2027-03-01"),
     "2026-02-04 | 2026-08-04 | 2027-02-04")
  eq(scheduled("[recur: quarter_1] [start: 2026-02-04]", "2026-01-01", "2026-12-31"),
     "2026-02-04 | 2026-05-04 | 2026-08-04 | 2026-11-04")
  eq(scheduled("[recur: year_1] [start: 2024-02-29]", "2024-01-01", "2028-12-31"),
     "2024-02-29 | 2025-02-28 | 2026-02-28 | 2027-02-28 | 2028-02-29")
  eq(scheduled("[recur: year_2] [start: 2026-02-04]", "2025-01-01", "2029-12-31"),
     "2026-02-04 | 2028-02-04")
end)

recurring("every unit without a start date", function()
  eq(scheduled("[recur: day_1]", "2026-09-26", "2026-09-28"), "2026-09-26 | 2026-09-27 | 2026-09-28")
  eq(scheduled("[recur: week_1]", "2026-09-20", "2026-10-06"), "2026-09-21 | 2026-09-28 | 2026-10-05")
  eq(scheduled("[recur: week_2]", "2026-09-20", "2026-10-13"), "2026-09-28 | 2026-10-12")
  eq(scheduled("[recur: month_1]", "2026-09-20", "2026-11-05"), "2026-10-01 | 2026-11-01")
  eq(scheduled("[recur: month_3]", "2026-01-01", "2026-12-31"),
     "2026-03-01 | 2026-06-01 | 2026-09-01 | 2026-12-01")
  eq(scheduled("[recur: quarter_1]", "2026-01-01", "2026-12-31"),
     "2026-01-01 | 2026-04-01 | 2026-07-01 | 2026-10-01")
  eq(scheduled("[recur: quarter_2]", "2026-01-01", "2026-12-31"), "2026-01-01 | 2026-07-01")
  eq(scheduled("[recur: year_1]", "2026-01-01", "2027-12-31"), "2026-01-01 | 2027-01-01")
end)

recurring("the next date, with the weekend and completion rules", function()
  local rt = recurringTasks
  local function next(line, from, lastDone)
    local n = rt.nextDue(spec(line), rt.parseDate(from), lastDone and rt.parseDate(lastDone))
    return n and rt.iso(n)
  end
  eq(next("[recur: week_2] [start: 2026-09-12]", "2026-09-13"), "2026-09-28", "the 26th is a Saturday")
  eq(next("[recur: week_2] [start: 2026-09-12] [include: weekend]", "2026-09-13"), "2026-09-26")
  eq(next("[recur: month_1] [start: 2026-10-23]", "2026-09-01"), "2026-10-23", "not before its start")
  eq(next("[recur: month_13]", "2026-09-01"), nil, "never: no month's number divides by 13")
  eq(next("[recur: day_14] [strategy: completion] [start: 2026-01-08]", "2026-09-23", "2026-09-15"), "2026-09-29")
  eq(next("[recur: day_14] [strategy: completion] [start: 2026-01-08]", "2026-09-23"), "2026-09-23", "long overdue")
  eq(next("[recur: day_14] [strategy: completion] [start: 2026-09-20] [include: weekend]", "2026-09-23", "2026-09-15"),
     "2026-10-04", "a start after the last tick counts from the start")
  eq(next("[recur: month_1] [strategy: completion] [include: weekend]", "2026-02-01", "2026-01-31"), "2026-02-28")
  eq(next("[recur: month_1] [strategy: completion]", "2026-02-01", "2026-01-31"), "2026-03-02", "28 February is a Saturday")
  eq(next("[recur: week_1] [strategy: completion]", "2026-09-23"), "2026-09-23", "never done: due at once")
end)

-- The catch-up: a date that passed with no note on a day it could have gone in.
recurring("a missed date is caught up once, on a day it can go in", function()
  local rt = recurringTasks
  local notes = {}
  local facts = { lookback = 90, hasNote = function(n) return notes[rt.iso(n)] == true end }
  local s = spec("[recur: week_2] [start: 2026-09-12]")
  local monday = rt.parseDate("2026-09-28")
  eq(rt.isDue(s, rt.parseDate("2026-09-26"), facts), false, "Saturday: not a weekend task")
  notes["2026-09-26"], notes["2026-09-27"] = true, true
  eq(rt.isDue(s, monday, facts), true, "notes on the weekend don't count for a weekday task")
  notes["2026-09-28"] = true
  eq(rt.isDue(s, rt.parseDate("2026-09-29"), facts), false, "Monday's note had it")
  s = spec("[recur: week_2] [start: 2026-09-12] [include: weekend]")
  eq(rt.isDue(s, monday, facts), false, "a weekend task had its chance on Saturday")
  facts.lookback = 1
  notes = {}
  eq(rt.isDue(spec("[recur: week_2] [start: 2026-09-12]"), monday, facts), false, "further back than maxLookbackDays")
end)

recurring("the recurring section ends at a heading as high as its own", function()
  local rt = recurringTasks
  local text = table.concat({
    HEADER, "* [ ] A", "```", "## not a heading, code", "* [ ] not a task, code", "```",
    "#### Deeper", "* [ ] B", "## Higher", "* [ ] C", "",
  }, "\n")
  local marked, moved = rt.rollover(text, HEADER)
  eq(list(moved), "* [ ] A | * [ ] B")
  has(marked, "* [>] A\n```\n## not a heading, code\n* [ ] not a task, code\n```\n#### Deeper\n* [>] B\n## Higher\n* [ ] C\n")
  -- A header that isn't a heading ends at any heading.
  marked, moved = rt.rollover("Recurring:\n* [ ] A\n#### Deeper\n* [ ] B\n", "Recurring:")
  eq(list(moved), "* [ ] A")
  -- No header, nothing moved, the page as it was.
  eq(rt.rollover("* [ ] A\n", HEADER), "* [ ] A\n")
end)
