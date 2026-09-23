------------------------------------------------------------------ Libraries
-- The library pages themselves, as src/ has them.

-- Space Lua's gsub gives its two values as one object, and a method called
-- straight on it fails: "attempt to index a userdata value". Plain Lua keeps
-- the first value, so only reading the source catches it.
test("libraries: no method is called straight on what gsub gives", "dm", function()
  local bad = {}
  for lib, text in pairs(SRC) do
    for block in text:gmatch("```space%-lua\n(.-)\n```") do
      for call in block:gmatch("gsub%s*%b()%s*:%s*[%w_]+") do
        bad[#bad + 1] = lib .. ": " .. (call:gsub("%s+", " ")):sub(1, 70)
      end
    end
  end
  eq(list(bad), "", "bracket the gsub, (s:gsub(...)):sub(2), so Space Lua keeps its first value")
end)

-- The same for find, which gives its bounds as one object, and for a match
-- with two captures or more (client/space_lua/stdlib/string.ts): a match with
-- one capture, or none, gives a plain string, which takes a method.
test("libraries: no method is called straight on what find gives, or a match of two captures", "dm", function()
  local bad = {}
  for lib, text in pairs(SRC) do
    for block in text:gmatch("```space%-lua\n(.-)\n```") do
      for call in block:gmatch("%f[%w_]find%s*%b()%s*:%s*[%w_]+") do
        bad[#bad + 1] = lib .. ": " .. (call:gsub("%s+", " ")):sub(1, 70)
      end
      for call, args in block:gmatch("%f[%w_](match%s*(%b())%s*:%s*[%w_]+)") do
        local pattern = args:match('^%(%s*"(.-[^\\])"') or args:match("^%(%s*'(.-[^\\])'")
        local captures = 0
        for escapes in (pattern or ""):gmatch("(%%*)%(") do
          if #escapes % 2 == 0 then captures = captures + 1 end
        end
        if not pattern or captures > 1 then
          bad[#bad + 1] = lib .. ": " .. (call:gsub("%s+", " ")):sub(1, 70)
        end
      end
    end
  end
  eq(list(bad), "", "bracket the call, (s:find(...)), so Space Lua keeps its first value")
end)

-- A block's code with its comments blanked, its strings emptied and each
-- long bracket, a query's included, left as [[]]: what remains is names and
-- syntax.
local function codeOnly(block)
  local out, i, n = {}, 1, #block
  while i <= n do
    local c, long = block:sub(i, i), block:match("^%[(=*)%[", i)
    if block:sub(i, i + 1) == "--" then
      local level = block:match("^%-%-%[(=*)%[", i)
      if level then
        local close = block:find("]" .. level .. "]", i + 4 + #level, true)
        i = close and close + #level + 2 or n + 1
      else
        i = block:find("\n", i, true) or n + 1
      end
      out[#out + 1] = " "
    elseif c == '"' or c == "'" then
      local j = i + 1
      while j <= n and block:sub(j, j) ~= c and block:sub(j, j) ~= "\n" do
        j = j + (block:sub(j, j) == "\\" and 2 or 1)
      end
      i = j + 1
      out[#out + 1] = '""'
    elseif long then
      local close = block:find("]" .. long .. "]", i + 2 + #long, true)
      i = close and close + #long + 2 or n + 1
      out[#out + 1] = "[[]]"
    else
      out[#out + 1] = c
      i = i + 1
    end
  end
  return table.concat(out)
end

-- Space Lua's grammar (client/space_lua/lua.grammar) makes `query` and
-- `using` keywords, so neither can name a variable, a parameter or a field,
-- as both can in plain Lua. It has no utf8 library, and its long strings
-- stop at level 2, [==[ ]==] (a long comment goes deeper).
test("libraries: no name Space Lua reserves or lacks, and no long string it can't read", "dm", function()
  local bad = {}
  for lib, text in pairs(SRC) do
    for block in text:gmatch("```space%-lua\n(.-)\n```") do
      local code = codeOnly(block)
      for at, word in code:gmatch("()%f[%w_]([%a_][%w_]*)") do
        if word == "using" or word == "utf8" or (word == "query" and not code:find("^query%s*%[%[%]%]", at)) then
          bad[#bad + 1] = lib .. ": " .. (code:sub(math.max(1, at - 25), at + 30):gsub("%s+", " "))
        end
      end
      for at, long in block:gmatch("()(%[====*%[)") do
        if block:sub(at - 2, at - 1) ~= "--" then bad[#bad + 1] = lib .. ": a long string " .. long end
      end
    end
  end
  eq(list(bad), "")
end)

-- SilverBullet saves pages with LF alone, and a library or a campaign page
-- copied from here must match its source byte for byte; a carriage return
-- would also move every offset after it. run.py reads the bytes as they are.
test("libraries: src/ and the campaign hold no carriage return", "dm", function()
  local bad = {}
  for lib, text in pairs(SRC) do
    if text:find("\r", 1, true) then bad[#bad + 1] = "src/" .. lib .. ".md" end
  end
  for name, text in pairs(FIXTURES.dm) do
    if text:find("\r", 1, true) then bad[#bad + 1] = "fixture/" .. name .. ".md" end
  end
  table.sort(bad)
  eq(list(bad), "")
end)

test("libraries: each is a library page named for its file", "dm", function()
  for lib, text in pairs(SRC) do
    eq(text:sub(1, 22), "---\ntags: meta/library", lib .. " frontmatter")
    ok(text:find('\nname: "Library/Storie/' .. lib .. '"\n', 1, true), lib .. " is not named Library/Storie/" .. lib)
  end
end)

-- The test campaign's space URLs and the words its CONFIG pages set. A
-- library that names one has taken a campaign's setting as a given.
local CONFIG_WORDS = { "/dm/", "/adventure/", "/author/", "/book/", "/player/",
                       "adaptation", "Adaptation", "name_", "kb%-person", "kb%-place" }

-- The space names are the GM libraries' own vocabulary: GM Kit documents
-- `Adventure/` as the layout it expects and reads it from `adventureFolder`,
-- and the suite shares that structure on purpose. These three know nothing
-- of spaces and take every name from config, so for them it is a leak.
local CONFIGURED = { "Adventure", "Player" }
local SPACE_AGNOSTIC = { "Space Switcher", "Chapter Navigation", "Appearances" }

test("libraries: none names a setting that belongs on a CONFIG page", "dm", function()
  for lib, text in pairs(SRC) do
    for _, word in ipairs(CONFIG_WORDS) do
      ok(not text:find(word), lib .. " says " .. word)
    end
  end
  for _, lib in ipairs(SPACE_AGNOSTIC) do
    local text = assert(SRC[lib], "src/ has no " .. lib)
    for _, word in ipairs(CONFIGURED) do
      ok(not text:find(word), lib .. " names " .. word .. " instead of taking it from config")
    end
  end
end)

test("libraries: install.json installs only what src/ has", "dm", function()
  local n = 0
  for folder, libs in pairs(INSTALL) do
    for _, lib in ipairs(libs) do
      ok(SRC[lib], folder .. lib .. ": src/ has no " .. lib)
      eq(H.pages[folder .. lib], SRC[lib], folder .. lib)
      n = n + 1
    end
  end
  ok(n > 0, "nothing installed")
end)

-- Library: Install finds a library only through the repository page, and
-- until 2026-09-21 it had no GM Bestiary or GM Maps.
test("libraries: the repository page lists every library in src/", "dm", function()
  ok(REPOSITORY, "no Repositories/storie.md")
  local missing = {}
  for lib in pairs(SRC) do
    local path = "/blob/main/src/" .. (lib:gsub(" ", "%%20")) .. ".md"
    if not REPOSITORY:find('\nname: "' .. lib .. '"\nuri: https://github.com/sstangle73/silverbullet-libraries'
                           .. path .. "\n", 1, true) then
      missing[#missing + 1] = lib
    end
  end
  table.sort(missing)
  eq(list(missing), "", "not listed in Repositories/storie.md")
end)
