---
tags: meta/library
name: "Library/Storie/RecurringTasks"
description: "Generates recurring tasks based on a master list and handles daily rollovers."
author: "Steven Storie"
version: "1.0.0"
---

# Recurring Task Manager
This library manages recurring tasks using a strict/flexible strategy and handles rolling over unfinished tasks from previous days.

## Setup
Ensure you have a page named `RecurringTasks` (or edit the config below) with your master list.
I suggest you add the following button to your toolbar:
```space-lua
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
-- 1. CONFIGURATION
-- ==========================================================
local CONFIG = {
  sourcePage = "RecurringTasks",           -- Page containing your master list
  dailyNotePrefix = "Inbox/",              -- Folder where daily notes live
  rolloverHeader = "### 🔄 Recurring Tasks", -- Header to search for/create
  maxLookbackDays = 90                     -- How far back to vacuum tasks
}

-- ==========================================================
-- 2. COMMAND LOGIC
-- ==========================================================
command.define({
  name = "Tasks: Generate for Today",
  run = function()

    -- A. DATE HELPERS
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

    -- B. READ SOURCE PAGE
    local success, pageData = pcall(space.readPage, CONFIG.sourcePage)
    if not success or not pageData then
      editor.flashNotification("❌ Error: Page '" .. CONFIG.sourcePage .. "' not found.", "error")
      return
    end
    local content = (type(pageData) == "string") and pageData or (pageData.text or "")

    -- C. BUILD COMPLETION CACHE
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

    -- D. GENERATE TASKS
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

        -- 1. WEEKEND CHECK
        if isWeekend and not includeWeekend then
            -- Skip
        else
            -- 2. STRATEGY CHECK
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

    -- E. VACUUM ROLLOVER
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

    -- F. WRITE TO TODAY
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