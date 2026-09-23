---
tags: meta/library
name: "Library/Storie/RecurringTasks"
description: "Generates recurring tasks based on a master list and handles daily rollovers."
author: "Steven Storie"
version: "1.1.0"
---

# Recurring Task Manager
This library is a robust engine for managing recurring tasks in SilverBullet. It separates the **definition** of your tasks (in a master list) from the **execution** of your tasks (in your daily notes). It is written for SilverBullet 2.11.

## Features
* **Multiple Frequencies:** Supports daily, weekly, monthly, quarterly, and yearly schedules.
* **Flexible Strategies:** Choose between "Strict" schedules (bills, events) or "Completion" based schedules (chores that reset only after you do them).
* **Weekend Logic:** Automatically skips generating tasks on Saturdays and Sundays unless explicitly told otherwise. A task that falls due on a weekend comes up on the Monday instead.
* **Task Rollover:** "Vacuums" up unfinished recurring tasks from previous daily notes and moves them to today so nothing gets lost.

## Usage
Create a page (default: `RecurringTasks`) to act as your master list. Add tasks using standard Markdown checkboxes with special attributes in brackets. Then run `Tasks: Generate for Today` once a day: it adds the tasks due today to today's daily note, under a heading of their own.

### 1. Basic Syntax
The core tag is `[recur: unit_frequency]`. Quotes are optional, here and in every attribute: `[recur: week_1]` and `[recur: "week_1"]` are the same.
* **Units:** `day`, `week`, `month`, `quarter`, `year`
* **Frequency:** A whole number from 1 (e.g., `1` for every unit, `2` for every other).

**Examples:**
* `* [ ] Take out trash [recur: week_1]` (Every week)
* `* [ ] Pay Quarterly Taxes [recur: quarter_1]` (Every 3 months)
* `* [ ] Replace Air Filter [recur: month_6]` (Every 6 months)

A line whose schedule can't be read, such as `[recur: fortnight_1]` or `[recur: day_0]`, is left out, and the command names it in a warning.

### 2. Attributes & Options
You can modify behavior by adding these attributes to the same line:

| Attribute | Format | Description |
| :--- | :--- | :--- |
| **Start Date** | `[start: YYYY-MM-DD]` | **Highly Recommended.** Sets the "Anchor" date: the task is due on it and every *frequency* units after it, and never before it. A monthly, quarterly or yearly task falls on the start date's day of the month, or on the month's last day when the month is shorter: `month_1` from 31 January is due on 28 February and 30 April. Without one, the task falls on fixed dates, listed under *Without a start date*. |
| **Weekend** | `[include: weekend]` | By default, tasks **will not generate** on Saturday or Sunday: one that falls due on a weekend comes up on the Monday. Add this tag to allow tasks to appear on weekends. |
| **Strategy** | `[strategy: type]` | Controls *how* the next due date is calculated (see below). Defaults to `strict`. |

### 3. Strategies
#### Strict (Default)
`[strategy: strict]`
Use this for **Fixed Schedule** items.
* **Logic:** "Is today strictly X days/weeks from the Start Date?" Dates are counted in calendar days, so the answer is the same whatever time of day you generate.
* **Behavior:** If you miss doing it, the task is still due: it rolls over to each day's note until you tick it off. If you do it late, the next due date does not change. A due date that passed without a daily note being written on a day the task could have gone into (a weekday, for a task without `[include: weekend]`) is caught up, once, the next time you generate, if it is no more than `maxLookbackDays` ago.
* **Use Case:** Paying rent, Trash day, Birthdays.

#### Completion
`[strategy: completion]`
Use this for **Maintenance/Chore** items.
* **Logic:** "Has it been X days/weeks since I last **completed** this task?"
* **Behavior:** The script asks SilverBullet's index for the task ticked off (`[x]`) in your daily notes, and counts from the date of the latest daily note it is ticked in. If you were supposed to water plants on Monday but did it on Wednesday, the next reminder will be calculated from Wednesday. Until you have ticked it off, it counts from the start date, and with no start date it is due at once. Months, quarters and years are calendar ones: `month_1` last done on 31 January is due again on 28 February.
* The index knows the task by its text, so tick it off in the daily note it went into and leave its text as the master list has it. A tick anywhere else, on the master list or on another page, doesn't count.
* If the index can't be read, or SilverBullet is still building it, the command says so in an error and leaves these tasks out for the day rather than guess. Everything else is generated as usual.
* **Use Case:** Watering plants, haircut, changing oil.

#### Without a start date
* `day_N`: every N days, counted from 1 January 1970.
* `week_N`: Mondays, every N weeks, counted from Monday 5 January 1970.
* `month_N`: the 1st of each month whose number, 1 to 12, divides by N: `month_3` is March, June, September and December.
* `quarter_N`: the 1st of January, April, July and October, every Nth of them counted from January 1970.
* `year_N`: 1 January, every N years counted from 1970.

### 4. Rollover
Generating also looks through the daily notes of the last `maxLookbackDays` days for tasks left open, `* [ ]` or `- [ ]`, in their recurring section: from the `rolloverHeader` heading to the next heading of the same level or a higher one. A `### 🔄 Recurring Tasks` section ends at the next `###`, `##` or `#` heading; a `####` heading inside it doesn't end it. Each open task there is marked moved, `[>]`, where it was, and added to today's note. Tasks under a later heading, such as a `## Work` section of your own, are left alone.

New tasks go at the end of the recurring section of today's note, or, when it has none, under a new heading at the end of the page. A task today's note already has, ticked or not, isn't added again. Today's note is written before any past note is marked, so a task marked moved is always in today's note.

### 5. Master List Examples
```markdown
* [ ] 🗑️ Take out Trash [recur: week_1] [start: 2025-01-01] (Strict: Every Wednesday)
* [ ] 💊 Give Dog Meds [recur: day_1] [include: weekend] (Every single day)
* [ ] 🪴 Water Office Plants [recur: day_4] [strategy: completion] (4 days after I last did it)
* [ ] 💰 Pay Mortgage [recur: month_1] [start: 2025-01-01] (Strict: 1st of the month)
```

## Setup
Ensure you have a page named `RecurringTasks` with your master list.

To configure this library, add a `recurringTasks` block to your `CONFIG` (or `SETTINGS`) page inside a `space-lua` block. You can override any of the defaults shown below:

```lua
config.set {
  recurringTasks = {
    -- Page containing your master list
    sourcePage = "RecurringTasks",

    -- Folder where daily notes live (include trailing slash)
    dailyNotePrefix = "Inbox/",

    -- Header to search for (or create if missing)
    rolloverHeader = "### 🔄 Recurring Tasks",

    -- How far back to roll over unfinished tasks, and to catch up a missed date
    maxLookbackDays = 90
  },
}
```

I suggest you also add the following button to your CONFIG page (inside the same space-lua block) so you have a clickable action:

```lua
actionButton.define { 
  icon = "calendar", 
  description = "Generate Daily Tasks", 
  run = function() 
    editor.invokeCommand("Tasks: Generate for Today") 
  end 
}
```

## Its version

`recurringTasks.version` is the version of the Lua the tab runs, and `recurringTasks.stale()` says in words when a copy of this page, at any depth, holds another: nil while every copy matches. Storie Check lists both, for every library in the space.

## Changes in 1.1

**Works with SilverBullet 2.x.** Completed tasks are read from the index, so the `completion` strategy finally sees when a task was last ticked, and counts from the daily note it was ticked in. If the index can't be read, a notification names the completion tasks left out that day instead of failing silently. Settings are read with `config.get`.

**A schedule that holds.** A day missed is caught up once, not every day after. A task for weekdays only that falls due at the weekend comes up on Monday. A monthly task that starts on the 31st falls on the last day of a shorter month. Dates no longer slip a day, or a week, when tasks are generated before noon; monthly tasks are no longer due before they start; quarterly and yearly completion tasks come round; and a task whose name begins another's is no longer mistaken for it.

**Rollover** stops at the next heading of the same or a higher level, and new tasks go at the end of that section. Today's note is never overwritten when it merely can't be read, and past notes are marked `[>]` only once today's is written. Curly quotes from a phone keyboard work in attributes.

**If you have been using it:** a completion task that has been coming up every day now waits its interval from the last tick, and a task generated before noon may move once by a day.

## Code
```space-lua
-- ==========================================================
-- RECURRING TASKS
-- ==========================================================
-- The schedule is pure functions of a master list line and the days they
-- are given, so it can be checked without a space. recurringTasks.generate
-- does the reading and writing.
recurringTasks = recurringTasks or {}
recurringTasks.version = "1.1.0"
local rt = recurringTasks

-- Nil while this tab runs the Lua that every copy of this page holds, or
-- else what differs, in words: a copy that holds a newer version, which
-- System: Reload loads, or an older one, to update from inside its own
-- space. The copies are the library pages the index names
-- Library/Storie/RecurringTasks, at any depth. It never raises: what it
-- can't find out, it doesn't report.
function rt.stale()
  local ok, found = pcall(function()
    local lib, running = "Library/Storie/RecurringTasks", rt.version
    local function shown(v)
      if type(v) == "number" and v == math.floor(v) then return string.format("%d", v) end
      return tostring(v)
    end
    local function before(a, b)
      local x, y = {}, {}
      for n in string.gmatch(shown(a), "%d+") do x[#x + 1] = tonumber(n) end
      for n in string.gmatch(shown(b), "%d+") do y[#y + 1] = tonumber(n) end
      for i = 1, math.max(#x, #y) do
        if (x[i] or 0) ~= (y[i] or 0) then return (x[i] or 0) < (y[i] or 0) end
      end
      return false
    end
    local copies = query[[
      from p = index.pages("meta/library")
      where p.name == lib or string.endsWith(p.name, "/" .. lib)
      order by p.name
    ]]
    local newer, older = {}, {}
    for _, p in ipairs(copies) do
      if p.version == nil then
        older[#older + 1] = p.name .. " has no version"
      elseif p.version ~= running and before(running, p.version) then
        newer[#newer + 1] = p.name .. " holds " .. shown(p.version)
      elseif p.version ~= running then
        older[#older + 1] = p.name .. " holds " .. shown(p.version) .. ", an older version"
      end
    end
    if #newer + #older == 0 then return nil end
    local advice = "Run System: Reload."
    if #older > 0 then
      advice = #newer > 0 and "Run System: Reload, and update the older copy from inside its own space."
        or "Update the older copy from inside its own space."
    end
    local reload = #newer > 0
    for _, o in ipairs(older) do newer[#newer + 1] = o end
    return { text = "RecurringTasks " .. running .. " is running; " .. table.concat(newer, "; ") .. ". " .. advice,
             reload = reload }
  end)
  if ok and found then return found.text, found.reload end
  return nil
end

-- ---------------------------------------------------------- Dates
-- A date is a whole number of days since 1 January 1970, from the calendar
-- alone: no clock and no time zone, so a task falls on the same days
-- whatever the hour you generate, and a date's text is built from whole
-- numbers.

function rt.day(y, m, d)
  y = y + (m - 1) // 12
  m = (m - 1) % 12 + 1
  if m <= 2 then y = y - 1 end
  local era = y // 400
  local yoe = y - era * 400
  local doy = (153 * ((m + 9) % 12) + 2) // 5 + d - 1
  local doe = yoe * 365 + yoe // 4 - yoe // 100 + doy
  return era * 146097 + doe - 719468
end

function rt.date(n)
  local z = n + 719468
  local era = z // 146097
  local doe = z - era * 146097
  local yoe = (doe - doe // 1460 + doe // 36524 - doe // 146096) // 365
  local doy = doe - (365 * yoe + yoe // 4 - yoe // 100)
  local mp = (5 * doy + 2) // 153
  local d = doy - (153 * mp + 2) // 5 + 1
  local m = mp < 10 and mp + 3 or mp - 9
  local y = yoe + era * 400
  if m <= 2 then y = y + 1 end
  return y, m, d
end

function rt.iso(n)
  local y, m, d = rt.date(n)
  return string.format("%04d-%02d-%02d", y, m, d)
end

-- The date in text such as "2026-02-03", or nil. An impossible date rolls on,
-- the way os.time rolls it: 30 February is 2 March.
function rt.parseDate(s)
  local y, m, d = string.match(s or "", "(%d%d%d%d)%-(%d%d?)%-(%d%d?)")
  if not y then return nil end
  return rt.day(tonumber(y), tonumber(m), tonumber(d))
end

-- 0 for Sunday to 6 for Saturday: 1 January 1970 was a Thursday.
function rt.weekday(n)
  return (n + 4) % 7
end

function rt.weekend(n)
  local w = (n + 4) % 7
  return w == 0 or w == 6
end

local function monthDays(y, m)
  if m == 2 then
    return (y % 4 == 0 and (y % 100 ~= 0 or y % 400 == 0)) and 29 or 28
  end
  return (m == 4 or m == 6 or m == 9 or m == 11) and 30 or 31
end

-- Day n moved by a number of months: the same day of the month, or the
-- month's last day when the month is shorter.
function rt.addMonths(n, months)
  local y, m, d = rt.date(n)
  local total = y * 12 + (m - 1) + months
  y, m = total // 12, total % 12 + 1
  return rt.day(y, m, math.min(d, monthDays(y, m)))
end

-- Today, by the clock of the device you generate on.
function rt.today()
  local t = os.date("*t")
  return rt.day(t.year, t.month, t.day)
end

-- ---------------------------------------------------------- The master list

local UNITS = { day = true, week = true, month = true, quarter = true, year = true }

-- A master list line, read: its unit and frequency (every), start date,
-- strategy and weekend rule; the line as it goes into a daily note; and its
-- key, the text after the checkbox, which is the task's text in the index
-- once it is in a daily note. A value may be quoted, with straight quotes or
-- a phone's curly ones. A line without [recur: ...] gives nil; one whose
-- schedule can't be read gives nil and the line.
function rt.parse(line)
  local unit, every = string.match(line, "%[%s*recur%s*:[^A-Za-z0-9%]]-([A-Za-z]+)_(%d+)")
  if not unit then
    if string.find(line, "%[%s*recur%s*:") then return nil, line end
    return nil
  end
  unit, every = string.lower(unit), tonumber(every)
  if not UNITS[unit] or every < 1 then return nil, line end
  local clean = line
  for _, attribute in ipairs({ "recur", "start", "strategy", "include" }) do
    clean = (string.gsub(clean, "%s*%[" .. attribute .. ".-%]", ""))
  end
  local key = string.match(clean, "%[[^%]]*%]%s*(.*)") or clean
  local strategy = string.match(line, "strategy:[^A-Za-z0-9%]]-([A-Za-z]+)")
  return {
    unit = unit,
    every = every,
    start = rt.parseDate(string.match(line, "start:[^A-Za-z0-9%]]-(%d+%-%d+%-%d+)")),
    strategy = (strategy and string.lower(strategy) == "completion") and "completion" or "strict",
    weekend = string.find(line, "include:[^A-Za-z0-9%]]-weekend") ~= nil,
    line = clean,
    key = string.match(key, "^%s*(.-)%s*$"),
  }
end

-- ---------------------------------------------------------- The schedule

-- Whether day n is one of the task's dates, before the weekend rule: every
-- `every` units from its start date or, without one, the fixed dates the
-- documentation lists. A month, quarter or year falls on the start date's
-- day of the month, or on the month's last day when it is shorter.
function rt.scheduled(spec, n)
  local start, every = spec.start, spec.every
  if start and n < start then return false end
  if spec.unit == "day" then return (n - (start or 0)) % every == 0 end
  -- 4 is Monday 5 January 1970
  if spec.unit == "week" then return (n - (start or 4)) % (7 * every) == 0 end
  local y, m, d = rt.date(n)
  if not start then
    if spec.unit == "year" then return m == 1 and d == 1 and (y - 1970) % every == 0 end
    if d ~= 1 then return false end
    if spec.unit == "month" then return m % every == 0 end
    return ((y - 1970) * 12 + m - 1) % (3 * every) == 0
  end
  local sy, sm, sd = rt.date(start)
  local step = every
  if spec.unit == "quarter" then step = 3 * every elseif spec.unit == "year" then step = 12 * every end
  return ((y - sy) * 12 + m - sm) % step == 0 and d == math.min(sd, monthDays(y, m))
end

-- The latest of the task's dates on or before day n, looking back at most
-- `lookback` days, or nil.
function rt.lastDue(spec, n, lookback)
  for back = 0, lookback or 0 do
    if rt.scheduled(spec, n - back) then return n - back end
  end
  return nil
end

-- `every` units after day n.
function rt.after(spec, n)
  if spec.unit == "day" then return n + spec.every end
  if spec.unit == "week" then return n + 7 * spec.every end
  local months = spec.every
  if spec.unit == "quarter" then months = 3 * spec.every elseif spec.unit == "year" then months = 12 * spec.every end
  return rt.addMonths(n, months)
end

-- The first day on or after `from` that the task comes up if nothing is
-- missed: its next date or, with the completion strategy, `every` units after
-- the later of lastDone, the day it was last ticked off, and its start date,
-- or at once with neither. A weekday task's weekend date moves to the
-- Monday. Nil if it never comes up, as month_13 without a start date doesn't.
function rt.nextDue(spec, from, lastDone)
  local n = from
  if spec.strategy == "completion" then
    local since = spec.start
    if lastDone and (not since or lastDone > since) then since = lastDone end
    if since and rt.after(spec, since) > n then n = rt.after(spec, since) end
  else
    if spec.start and n < spec.start then n = spec.start end
    local limit = n + 366 * spec.every + 31
    while not rt.scheduled(spec, n) do
      if n >= limit then return nil end
      n = n + 1
    end
  end
  if not spec.weekend then
    while rt.weekend(n) do n = n + 1 end
  end
  return n
end

-- Whether the task goes into day `today`'s note. facts.lastDone is the day
-- the index says it was last ticked off, for the completion strategy;
-- facts.hasNote(n), whether day n has a daily note; facts.lookback, how many
-- days back a missed date is still caught up. A strict task is due on its
-- date, or, when that date passed without a note on a day it could have gone
-- into, on the next day it can.
function rt.isDue(spec, today, facts)
  facts = facts or {}
  if not spec.weekend and rt.weekend(today) then return false end
  if spec.strategy == "completion" then
    return rt.nextDue(spec, today, facts.lastDone) == today
  end
  local due = rt.lastDue(spec, today, facts.lookback or 90)
  if not due then return false end
  for n = due, today - 1 do
    if (spec.weekend or not rt.weekend(n)) and facts.hasNote and facts.hasNote(n) then return false end
  end
  return true
end

-- ---------------------------------------------------------- Daily notes

local function trim(s)
  return string.match(s, "^%s*(.-)%s*$")
end

-- A page's lines, which table.concat(lines, "\n") puts back as they were.
local function split(text)
  local lines, i = {}, 1
  while true do
    local j = string.find(text, "\n", i, true)
    if not j then
      table.insert(lines, string.sub(text, i))
      return lines
    end
    table.insert(lines, string.sub(text, i, j - 1))
    i = j + 1
  end
end

local function fence(line)
  return string.match(line, "^ ? ? ?(```)") or string.match(line, "^ ? ? ?(~~~)")
end

local function headingLevel(line)
  local hashes = string.match(line, "^ ? ? ?(#+)%s") or string.match(line, "^ ? ? ?(#+)$")
  if hashes and #hashes <= 6 then return #hashes end
  return nil
end

-- The recurring section of a page's lines: the index of the heading line, and
-- of the section's last line, the one before the next heading of the same
-- level or a higher one outside a code block, or the page's last. A header
-- that isn't a heading ends at any heading. Nil without the heading.
function rt.section(lines, header)
  local want = trim(header)
  local level = headingLevel(want) or 7
  local open, from = nil, nil
  for i, line in ipairs(lines) do
    local mark = fence(line)
    if open then
      if mark == open then open = nil end
    elseif mark then
      open = mark
    elseif from then
      local l = headingLevel(line)
      if l and l <= level then return from, i - 1 end
    elseif trim(line) == want then
      from = i
    end
  end
  if from then return from, #lines end
  return nil
end

-- A past note with the open tasks of its recurring section marked moved,
-- [>], and those tasks as they go into today's note.
function rt.rollover(text, header)
  local lines = split(text)
  local moved = {}
  local from, to = rt.section(lines, header)
  if not from then return text, moved end
  local open = nil
  for i = from + 1, to do
    local line = lines[i]
    local mark = fence(line)
    if open then
      if mark == open then open = nil end
    elseif mark then
      open = mark
    else
      local indent, bullet, rest = string.match(line, "^(%s*)([%*%-])%s+%[%s+%](.-)\r?$")
      if indent and rest ~= "" then
        lines[i] = indent .. bullet .. " [>]" .. rest
        table.insert(moved, "* [ ]" .. rest)
      end
    end
  end
  if #moved == 0 then return text, moved end
  return table.concat(lines, "\n"), moved
end

-- Whether a page's lines hold this task, ticked or not: its text after the
-- checkbox, and nothing more, after a checkbox on some line.
local function holds(lines, task)
  local want = trim(string.match(task, "%[[^%]]*%]%s*(.*)") or task)
  for _, line in ipairs(lines) do
    if string.match(line, "%[[^%]]*%]%s+(.-)%s*$") == want then return true end
  end
  return false
end

-- Today's note with the tasks it doesn't hold yet at the end of its
-- recurring section, or in a new one at the end of the page, and how many
-- went in.
function rt.addTasks(text, header, tasks)
  local lines, fresh = split(text), {}
  for _, task in ipairs(tasks) do
    if not holds(lines, task) and not holds(fresh, task) then table.insert(fresh, task) end
  end
  if #fresh == 0 then return text, 0 end
  local from, to = rt.section(lines, header)
  if not from then
    return text .. "\n\n" .. header .. "\n" .. table.concat(fresh, "\n") .. "\n", #fresh
  end
  local at = to
  while at > from and trim(lines[at]) == "" do at = at - 1 end
  for i, task in ipairs(fresh) do table.insert(lines, at + i, task) end
  return table.concat(lines, "\n"), #fresh
end

-- ---------------------------------------------------------- The index

-- The day of a daily note, from its name, or nil for any other page.
function rt.noteDay(page, prefix)
  if string.sub(page, 1, #prefix) ~= prefix then return nil end
  local rest = string.sub(page, #prefix + 1)
  if not string.match(rest, "^%d%d%d%d%-%d%d%-%d%d$") then return nil end
  return rt.parseDate(rest)
end

-- The last day each task was ticked off in a daily note, by the task's text
-- and by its name. SilverBullet 2.11 indexes every task: index.tasks() gives
-- each with its page, its text after the checkbox, the same without
-- attributes and tags as its name, and done when it is ticked. A tick is
-- dated by its note. Raises when the index can't be read or isn't built yet.
function rt.completions(prefix)
  if index.isAvailable and not index.isAvailable() then
    error("SilverBullet is still indexing the space; try again in a moment", 0)
  end
  local ticked = query[[
    from t = index.tasks()
    where t.done and string.sub(t.page, 1, #prefix) == prefix
  ]]
  local last = {}
  local function mark(key, n)
    if key and (last[key] == nil or n > last[key]) then last[key] = n end
  end
  for _, t in ipairs(ticked) do
    local n = rt.noteDay(t.page, prefix)
    if n then
      mark(t.text, n)
      mark(t.name, n)
    end
  end
  return last
end

-- ---------------------------------------------------------- The command

function rt.settings()
  local function get(key, default)
    local value = config.get("recurringTasks." .. key, nil)
    if value == nil then return default end
    return value
  end
  return {
    sourcePage = get("sourcePage", "RecurringTasks"),
    dailyNotePrefix = get("dailyNotePrefix", "Inbox/"),
    rolloverHeader = get("rolloverHeader", "### 🔄 Recurring Tasks"),
    maxLookbackDays = math.max(0, math.floor(tonumber(get("maxLookbackDays", 90)) or 90)),
  }
end

-- A page's text, or nil when there is no such page. Any other failure is
-- raised: a page that couldn't be read, taken for a missing one, would be
-- written over. The open page is saved first, so no typing is lost.
local function read(name, current)
  if name == current then editor.save() end
  local ok, text = pcall(space.readPage, name)
  if ok then return text or "" end
  local why = tostring(text)
  if string.find(why, "Not found", 1, true) or string.find(why, "isn't readable", 1, true) then return nil end
  error("couldn't read " .. name .. ": " .. why, 0)
end

local function lineCount(count)
  return count .. (count == 1 and " line" or " lines")
end

-- Adds today's tasks to today's note: the ones due from the master list, and
-- the ones left open in past notes. `today` is for tests; the command takes
-- it from the clock.
function rt.generate(today)
  today = today or rt.today()
  local settings = rt.settings()
  local prefix, header = settings.dailyNotePrefix, settings.rolloverHeader
  local current = editor.getCurrentPage()

  local ok, source = pcall(read, settings.sourcePage, current)
  if not ok then
    editor.flashNotification("❌ Error: " .. tostring(source), "error")
    return
  end
  if source == nil then
    editor.flashNotification("❌ Error: Page '" .. settings.sourcePage .. "' not found. Check your recurringTasks settings.", "error")
    return
  end

  local specs, unreadable, completion = {}, {}, false
  for line in string.gmatch(source, "[^\r\n]+") do
    local spec, bad = rt.parse(line)
    if spec then
      table.insert(specs, spec)
      if spec.strategy == "completion" then completion = true end
    elseif bad then
      table.insert(unreadable, trim(bad))
    end
  end

  local lastDone, indexError = {}, nil
  if completion then
    local good, result = pcall(rt.completions, prefix)
    if good then lastDone = result else indexError = tostring(result) end
  end

  -- Each daily note read once: its text, or false when there is none.
  local notes = {}
  local function note(n)
    if notes[n] == nil then notes[n] = read(prefix .. rt.iso(n), current) or false end
    return notes[n]
  end

  local tasks, skipped = {}, {}
  local function add(task)
    for _, t in ipairs(tasks) do
      if t == task then return end
    end
    table.insert(tasks, task)
  end
  local facts = {
    lookback = settings.maxLookbackDays,
    hasNote = function(n) return note(n) ~= false end,
  }
  for _, spec in ipairs(specs) do
    if spec.strategy == "completion" and indexError then
      if spec.weekend or not rt.weekend(today) then table.insert(skipped, spec.key) end
    else
      facts.lastDone = lastDone[spec.key]
      if rt.isDue(spec, today, facts) then add(spec.line) end
    end
  end

  local rolled, moves = 0, {}
  for back = 1, settings.maxLookbackDays do
    local text = note(today - back)
    if text and text ~= "" then
      local marked, moved = rt.rollover(text, header)
      if #moved > 0 then
        table.insert(moves, { name = prefix .. rt.iso(today - back), text = marked })
        for _, task in ipairs(moved) do add(task) end
        rolled = rolled + #moved
      end
    end
  end

  -- Today's note first, then the past notes' marks: a task marked moved is
  -- always in today's note.
  local todayName = prefix .. rt.iso(today)
  local text, added = rt.addTasks(note(today) or "", header, tasks)
  local written = {}
  if added > 0 then
    space.writePage(todayName, text)
    written[todayName] = true
  end
  for _, move in ipairs(moves) do
    space.writePage(move.name, move.text)
    written[move.name] = true
  end
  if current and written[current] then editor.reloadPage() end

  if indexError then
    local message = "❌ Couldn't read completed tasks from the index: " .. indexError
    if #skipped > 0 then
      message = message .. ". Left out today: " .. table.concat(skipped, ", ")
    end
    editor.flashNotification(message, "error")
  end
  if #unreadable > 0 then
    editor.flashNotification("⚠️ Couldn't read the schedule on " .. lineCount(#unreadable) .. " of " ..
      settings.sourcePage .. ", left out: " .. table.concat(unreadable, "; "), "warning")
  end
  if added > 0 then
    local message = "✅ Added " .. added .. " tasks"
    if rolled > 0 then message = message .. " (" .. rolled .. " rolled over)" end
    editor.flashNotification(message)
  elseif #tasks > 0 then
    editor.flashNotification("Recurring tasks up to date.")
  else
    editor.flashNotification("No recurring tasks due.")
  end
end

command.define({
  name = "Tasks: Generate for Today",
  run = function()
    local ok, err = pcall(rt.generate)
    if not ok then editor.flashNotification("❌ Recurring tasks: " .. tostring(err), "error") end
  end
})
```
