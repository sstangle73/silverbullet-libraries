------------------------------------------------------------------ Party expressions in pages

local function partyExpressions(pages, prefix)
  local found = {}
  for name, text in pairs(pages) do
    if name:sub(1, #prefix) == prefix and not name:find("Library/", 1, true) and text:find("${", 1, true) then
      for _, node in ipairs(markdown.parseMarkdown(text).children) do
        local src = text:sub(node.from + 3, node.to - 1)
        if src:match("^%s*party[%.:]") then found[#found + 1] = { page = name, src = src } end
      end
    end
  end
  return found
end

local function checkExpressions(found)
  ok(#found > 0, "no party expressions found")
  for _, e in ipairs(found) do
    local good, v = pcall(function() return spacelua.evalExpression(spacelua.parseExpression(e.src)) end)
    ok(good, e.page .. ": " .. e.src .. ": " .. tostring(v))
    ok(type(v) == "table" and v._isWidget and type(v.markdown) == "string",
       e.page .. ": " .. e.src .. " has no Markdown face")
    local printed, pv = pcall(function()
      return spacelua.evalExpression(spacelua.parseExpression(e.src), gmbook.printers)
    end)
    -- GM Book prints text as it is and a widget as its Markdown face
    ok(printed and (type(pv) == "string" or type(pv) == "table" and pv._isWidget and type(pv.markdown) == "string"),
       e.page .. ": " .. e.src .. " doesn't print: " .. tostring(pv))
  end
end

test("pages: every party expression in Adventure works in Adventure", "adventure", function()
  checkExpressions(partyExpressions(H.pages, ""))
end)

test("pages: every party expression in Adventure works in DM", "dm", function()
  checkExpressions(partyExpressions(H.pages, "Adventure/"))
end)

------------------------------------------------------------------ Pages

test("pages: every command button names a real command", "dm", function()
  local missing = {}
  for name, text in pairs(H.pages) do
    for args in text:gmatch("widgets%.commandButton%((.-)%)}") do
      local strings = {}
      for s in args:gmatch('"([^"]*)"') do strings[#strings + 1] = s end
      local cmd = strings[2] or strings[1]
      if not H.commands[cmd] and not cmd:find("^System:") then
        missing[#missing + 1] = name .. " -> " .. cmd
      end
    end
  end
  eq(list(missing), "", "buttons for commands that don't exist")
end)

test("pages: Adventure's command buttons exist in the Adventure space", "adventure", function()
  local missing = {}
  for name, text in pairs(H.pages) do
    for args in text:gmatch("widgets%.commandButton%((.-)%)}") do
      local strings = {}
      for s in args:gmatch('"([^"]*)"') do strings[#strings + 1] = s end
      local cmd = strings[2] or strings[1]
      if not H.commands[cmd] then missing[#missing + 1] = name .. " -> " .. cmd end
    end
  end
  eq(list(missing), "", "buttons for commands that don't exist")
end)
