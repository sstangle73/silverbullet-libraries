---
tags: meta/library
name: "Library/Storie/RecurringTasks"
description: "Generates recurring tasks based on a master list and handles daily rollovers."
author: "Steven Storie"
version: "1.0.0"
---

# Recurring Task Manager
This library is a robust engine for managing recurring tasks in SilverBullet. It separates the **definition** of your tasks (in a master list) from the **execution** of your tasks (in your daily notes).

## Features
* **Multiple Frequencies:** Supports daily, weekly, monthly, quarterly, and yearly schedules.
* **Flexible Strategies:** Choose between "Strict" schedules (bills, events) or "Completion" based schedules (chores that reset only after you do them).
* **Weekend Logic:** Automatically skips generating tasks on Saturdays and Sundays unless explicitly told otherwise.
* **Task Rollover:** "Vacuums" up unfinished recurring tasks from previous daily notes and moves them to today so nothing gets lost.

## Usage
Create a page (default: `RecurringTasks`) to act as your master list. Add tasks using standard Markdown checkboxes with special attributes in brackets.

### 1. Basic Syntax
The core tag is `[recur: unit_frequency]`.
* **Units:** `day`, `week`, `month`, `quarter`, `year`
* **Frequency:** An integer (e.g., `1` for every unit, `2` for every other).

**Examples:**
* `* [ ] Take out trash [recur: week_1]` (Every week)
* `* [ ] Pay Quarterly Taxes [recur: quarter_1]` (Every 3 months)
* `* [ ] Replace Air Filter [recur: month_6]` (Every 6 months)

### 2. Attributes & Options
You can modify behavior by adding these attributes to the same line:

| Attribute | Format | Description |
| :--- | :--- | :--- |
| **Start Date** | `[start: YYYY-MM-DD]` | **Highly Recommended.** Sets the "Anchor" date. The script calculates due dates relative to this specific day. If omitted, it calculates based on the "Epoch" (computer time 0), which can be unpredictable. |
| **Weekend** | `[include: weekend]` | By default, tasks **will not generate** on Saturday or Sunday. Add this tag to allow tasks to appear on weekends. |
| **Strategy** | `[strategy: type]` | Controls *how* the next due date is calculated (see below). Defaults to `strict`. |

### 3. Strategies
#### Strict (Default)
`[strategy: strict]`
Use this for **Fixed Schedule** items.
* **Logic:** "Is today strictly X days/weeks from the Start Date?"
* **Behavior:** If you miss doing it, the task is still due. If you do it late, the next due date does not change.
* **Use Case:** Paying rent, Trash day, Birthdays.

#### Completion
`[strategy: completion]`
Use this for **Maintenance/Chore** items.
* **Logic:** "Has it been X days/weeks since I last **completed** this task?"
* **Behavior:** The script looks at your completed tasks database. If you were supposed to water plants on Monday but did it on Wednesday, the next reminder will be calculated from Wednesday.
* **Use Case:** Watering plants, haircut, changing oil.

### 4. Master List Examples
```markdown
* [ ] 🗑️ Take out Trash [recur: week_1] [start: 2025-01-01] (Strict: Every Wednesday)
* [ ] 💊 Give Dog Meds [recur: day_1] [include: weekend] (Every single day)
* [ ] 🪴 Water Office Plants [recur: day_4] [strategy: completion] (4 days after I last did it)
* [ ] 💰 Pay Mortgage [recur: month_1] [start: 2025-01-01] (Strict: 1st of the month)

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

    -- How far back to check for incomplete tasks
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

## Code
```space-lua
-- ==========================================================
-- COMMAND LOGIC
-- ==========================================================
command.define({
  name = "Tasks: Generate for Today",
  run = function()

    -- 1. DYNAMIC CONFIGURATION
    -- We fetch the config inside the run function so it updates instantly
    local userConfig = system.getSpaceConfig("recurringTasks") or {}
    
    local CONFIG = {
      sourcePage = userConfig.sourcePage or "RecurringTasks",
      dailyNotePrefix = userConfig.dailyNotePrefix or "Inbox/",
      rolloverHeader = userConfig.rolloverHeader or "### 🔄 Recurring Tasks",
      maxLookbackDays = userConfig.maxLookbackDays or 90
    }

    -- 2. DATE HELPERS
    local function parseDate(str)
      if not str then return nil end
      local y, m, d = str:match("(%d+)%-(%d+)%-(%d+)")
      if not y or not m or not d then return nil end
      local Y, M, D = tonumber(y, 10), tonumber(m, 10), tonumber(d, 10)
      if not Y or not M or not D then return nil end
      local success, result = pcall(os.time, {year=Y, month=M, day=D, hour=12})
      return success and result or nil
    end

    local today = os.time()
    local todayDate = os.date("*t", today)
    local todayString = os.date("%Y-%m-%d", today)
    local isWeekend = (todayDate.wday == 1 or todayDate.wday == 7) -- 1=Sun, 7=Sat

    local fileExistenceCache = {} 
    local tasksToAdd = {}
    local completionCache = {}

    -- 3. READ SOURCE PAGE
    local success, pageData = pcall(space.readPage, CONFIG.sourcePage)
    if not success or not pageData then
      editor.flashNotification("❌ Error: Page '" .. CONFIG.sourcePage .. "' not found. Check your recurringTasks settings.", "error")
      return
    end
    local content = (type(pageData) == "string") and pageData or (pageData.text or "")

    -- 4. BUILD COMPLETION CACHE
    local qSuccess, completedTasks = pcall(system.invokeFunction, "index.query", [[
      task where completed = true select name, lastModified
    ]])
    
    if qSuccess and completedTasks then
        for _, t in ipairs(completedTasks) do
            if t.name then
                local existing = completionCache[t.name] or 0
                local doneTime = parseDate(t.lastModified) or 0
                if doneTime > existing then
                    completionCache[t.name] = doneTime
                end
            end
        end
    end

    -- 5. GENERATE TASKS
    for line in string.gmatch(content, "[^\r\n]+") do
      local unit, freqStr = line:match("recur.-([a-z]+)_(%d+)")
      
      if unit and freqStr then
        local freq = tonumber(freqStr)
        local shouldGenerate = false
        
        -- Parse Attributes
        local startStr = line:match('start:%s*["\']?(%d+%-%d+%-%d+)["\']?')
        local startTime = parseDate(startStr)
        local strategy = line:match('strategy:%s*["\']?([a-z]+)["\']?') or "strict"
        local includeWeekend = line:match('include:%s*["\']?weekend["\']?')

        -- A. WEEKEND CHECK
        if isWeekend and not includeWeekend then
            -- Skip
        else
            -- B. STRATEGY CHECK
            if strategy == "completion" then
                -- Extract clean name
                local cleanName = line:match("%[[^%]]*%]%s*(.*)") or line
                cleanName = string.gsub(cleanName, "%s*%[recur.-%]", "")
                cleanName = string.gsub(cleanName, "%s*%[start.-%]", "")
                cleanName = string.gsub(cleanName, "%s*%[strategy.-%]", "")
                cleanName = string.gsub(cleanName, "%s*%[include.-%]", "")
                cleanName = cleanName:match("^%s*(.-)%s*$")
                
                local lastDone = completionCache[cleanName]
                
                local referenceDate = lastDone or startTime
                
                if not referenceDate then
                    shouldGenerate = true 
                else
                    local daysSince = math.floor((today - referenceDate) / 86400)
                    
                    if unit == "day" and daysSince >= freq then shouldGenerate = true
                    elseif unit == "week" and daysSince >= (freq * 7) then shouldGenerate = true
                    elseif unit == "month" and daysSince >= (freq * 30) then shouldGenerate = true
                    end
                end
                
            else
                -- STRICT STRATEGY (Default)
                for lookback = 0, CONFIG.maxLookbackDays do
                    local checkTime = today - (86400 * lookback)
                    local checkDateStruct = os.date("*t", checkTime)
                    local isDueOnDay = false
                    
                    if unit == "day" then
                        if startTime then
                            local diff = math.floor((checkTime - startTime) / 86400)
                            if diff >= 0 and diff % freq == 0 then isDueOnDay = true end
                        else
                            local epochDays = math.floor(checkTime / 86400)
                            if epochDays % freq == 0 then isDueOnDay = true end
                        end
                    elseif unit == "week" then
                        if startTime then
                            local diff = math.floor((checkTime - startTime) / 604800)
                            if diff >= 0 and diff % freq == 0 and os.date("%w", checkTime) == os.date("%w", startTime) then isDueOnDay = true end
                        else
                            local epochDays = math.floor(checkTime / 86400)
                            local epochWeeks = math.floor(epochDays / 7)
                            if checkDateStruct.wday == 2 and (epochWeeks % freq == 0) then isDueOnDay = true end
                        end
                    elseif unit == "month" then
                        if startTime then
                            local sDate = os.date("*t", startTime)
                            local monthDiff = (checkDateStruct.year - sDate.year) * 12 + (checkDateStruct.month - sDate.month)
                            if checkDateStruct.day == sDate.day and monthDiff % freq == 0 then isDueOnDay = true end
                        else
                            if checkDateStruct.day == 1 and checkDateStruct.month % freq == 0 then isDueOnDay = true end
                        end
                    elseif unit == "quarter" then
                        if startTime then
                            local sDate = os.date("*t", startTime)
                            local monthDiff = (checkDateStruct.year - sDate.year) * 12 + (checkDateStruct.month - sDate.month)
                            if checkDateStruct.day == sDate.day and monthDiff % (3 * freq) == 0 then isDueOnDay = true end
                        else
                            if checkDateStruct.day == 1 and (checkDateStruct.month - 1) % 3 == 0 then isDueOnDay = true end
                        end
                    elseif unit == "year" then
                         if startTime then
                            local sDate = os.date("*t", startTime)
                            if checkDateStruct.day == sDate.day and checkDateStruct.month == sDate.month then
                                local yearDiff = checkDateStruct.year - sDate.year
                                if yearDiff % freq == 0 then isDueOnDay = true end
                            end
                         else
                            if checkDateStruct.day == 1 and checkDateStruct.month == 1 then isDueOnDay = true end
                         end
                    end

                    if isDueOnDay then
                        if lookback == 0 then
                            shouldGenerate = true; break 
                        else
                            local pastDateString = os.date("%Y-%m-%d", checkTime)
                            local pastPageName = CONFIG.dailyNotePrefix .. pastDateString
                            if fileExistenceCache[pastPageName] == nil then
                                local pSuccess, pData = pcall(space.readPage, pastPageName)
                                fileExistenceCache[pastPageName] = (pSuccess and pData)
                            end
                            if not fileExistenceCache[pastPageName] then
                                shouldGenerate = true; break
                            end
                        end
                    end
                end
            end
        end

        if shouldGenerate then
            -- Clean all tags
            line = string.gsub(line, '%s*%[recur.-%]', '')
            line = string.gsub(line, '%s*%[start.-%]', '')
            line = string.gsub(line, '%s*%[strategy.-%]', '')
            line = string.gsub(line, '%s*%[include.-%]', '')
            table.insert(tasksToAdd, line)
        end
      end
    end

    -- 6. VACUUM ROLLOVER
    local totalRolledOver = 0
    for i = 1, CONFIG.maxLookbackDays do
        local pastDate = today - (86400 * i)
        local pastString = os.date("%Y-%m-%d", pastDate)
        local checkPage = CONFIG.dailyNotePrefix .. pastString
        
        local pSuccess, pData = pcall(space.readPage, checkPage)
        if pSuccess and pData then
            local yContent = (type(pData) == "string") and pData or (pData.text or "")
            if yContent ~= "" then
                local header = CONFIG.rolloverHeader
                local s, e = string.find(yContent, header, 1, true)
                if s then
                    local nextHeaderStart = string.find(yContent, "\n### ", e, true)
                    local sectionEnd = nextHeaderStart and (nextHeaderStart - 1) or #yContent
                    local preSection = string.sub(yContent, 1, e)
                    local sectionText = string.sub(yContent, e + 1, sectionEnd)
                    local postSection = string.sub(yContent, sectionEnd + 1)
                    
                    local pageMovedCount = 0
                    local newSectionText = sectionText:gsub("([%*%-])%s+%[%s+%]([^\r\n]+)", function(bullet, taskText)
                        local fullTask = "* [ ]" .. taskText
                        local isDuplicate = false
                        for _, t in ipairs(tasksToAdd) do if t == fullTask then isDuplicate = true break end end
                        if not isDuplicate then table.insert(tasksToAdd, fullTask) end
                        pageMovedCount = pageMovedCount + 1
                        totalRolledOver = totalRolledOver + 1
                        return bullet .. " [>]" .. taskText
                    end)
                    if pageMovedCount > 0 then
                        pcall(space.writePage, checkPage, preSection .. newSectionText .. postSection)
                    end
                end
            end
        end
    end

    -- 7. WRITE TO TODAY
    if #tasksToAdd > 0 then
        local dailyPage = CONFIG.dailyNotePrefix .. todayString
        local currentContent = ""
        local exists = false
        local readSuccess, dailyPageData = pcall(space.readPage, dailyPage)
        if readSuccess and dailyPageData then
             if type(dailyPageData) == "string" then currentContent = dailyPageData; exists = true
             elseif type(dailyPageData) == "table" and dailyPageData.text then currentContent = dailyPageData.text; exists = true end
        end
        local header = CONFIG.rolloverHeader
        local appendText = ""
        if not string.find(currentContent, header, 1, true) then appendText = "\n\n" .. header .. "\n" end
        
        local addedCount = 0
        for _, task in ipairs(tasksToAdd) do
            local coreText = task:match("%[[^%]]*%]%s*(.*)") or task
            local safeText = coreText:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
            local pattern = "%[[^%]]*%]%s+" .. safeText
            if not string.find(currentContent, pattern) then
                appendText = appendText .. task .. "\n"
                addedCount = addedCount + 1
            end
        end
        
        if addedCount > 0 then
            if exists then space.writePage(dailyPage, currentContent .. appendText)
            else space.writePage(dailyPage, appendText) end
            local msg = "✅ Added " .. addedCount .. " tasks"
            if totalRolledOver > 0 then msg = msg .. " (" .. totalRolledOver .. " rolled over)" end
            editor.flashNotification(msg)
            if editor.getCurrentPage() == dailyPage then editor.reloadPage() end
        else
            editor.flashNotification("Recurring tasks up to date.")
        end
    else
        if totalRolledOver > 0 then editor.flashNotification("Rolled over " .. totalRolledOver .. " tasks from history.")
        else editor.flashNotification("No recurring tasks due.") end
    end
  end
})
```