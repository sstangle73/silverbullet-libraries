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

------------------------------------------------------------------ Versions
-- Each library says which version its Lua is, <ns>.version, and <ns>.stale()
-- tells whether the tab runs older Lua than a copy of its page holds: nil,
-- or what differs in words. A library's namespace is the first table its
-- page makes, `<ns> = <ns> or {}`, at the start of a line.

local function namespaceOf(text)
  for block in text:gmatch("```space%-lua\n(.-)\n```") do
    for a, b in ("\n" .. block):gmatch("\n([%a_][%w_]*) = ([%a_][%w_]*) or {}") do
      if a == b then return a end
    end
  end
end

local function frontmatterVersion(text)
  local head = text:match("^%-%-%-\n(.-\n)%-%-%-") or ""
  return head:match('\nversion: "([^"\n]*)"\n') or head:match("\nversion: ([^\n]*)\n")
end

-- Every library of src/ loaded in the DM space: the ones the campaign
-- installs are there already, and the others are loaded into it.
local function loadEveryLibrary()
  reset("dm")
  local installed = {}
  for _, libs in pairs(INSTALL) do
    for _, lib in ipairs(libs) do installed[lib] = true end
  end
  local names = {}
  for lib in pairs(SRC) do names[#names + 1] = lib end
  table.sort(names)
  for _, lib in ipairs(names) do
    if not installed[lib] then loadLibrary(lib) end
  end
  return names
end

test("libraries: each names its version as its frontmatter does, or is listed until it does", "dm", function()
  local missing = {}
  for _, lib in ipairs(loadEveryLibrary()) do
    local ns = namespaceOf(SRC[lib])
    ok(ns, lib .. " makes no table of its own")
    local t = _G[ns]
    ok(type(t) == "table", lib .. ": " .. ns .. " is not a table once it has loaded")
    if t.version == nil then
      missing[#missing + 1] = lib .. " (" .. ns .. ")"
    else
      eq(t.version, frontmatterVersion(SRC[lib]), lib .. ": " .. ns .. ".version")
      eq(type(t.stale), "function", lib .. ": " .. ns .. ".stale")
    end
  end
  if #missing > 0 then
    REPORT[#REPORT + 1] = "libraries without <ns>.version yet: " .. table.concat(missing, ", ")
  end
end)

-- A copy of the library's page in the space, one there already or one put
-- at Library/Storie/<lib>, and the text it holds now.
local function copyOf(lib)
  local tail = "Library/Storie/" .. lib
  local names = {}
  for name in pairs(H.pages) do
    if name == tail or name:endsWith("/" .. tail) then names[#names + 1] = name end
  end
  table.sort(names)
  if #names == 0 then
    H.pages[tail] = SRC[lib]
    return tail
  end
  return names[1]
end

local function withVersion(text, version)
  local out, n = text:gsub('\nversion: "[^"\n]*"\n', '\nversion: "' .. version .. '"\n', 1)
  assert(n == 1, "no version to change")
  return out
end

-- stale() asked as if some seconds had passed since it was last asked: a
-- library may keep its answer for a moment, as GM Party and GM Bestiary
-- keep theirs for two seconds, since every number or reference on a page
-- asks.
local later = 0
local function staleNow(stale)
  local real = os.time
  os.time = function(t)
    if t ~= nil then return real(t) end
    later = later + 10
    return real() + later
  end
  local good, answer = pcall(stale)
  os.time = real
  if not good then error(answer, 0) end
  return answer
end

test("libraries: stale() is nil while every copy matches, and says so when one differs", "dm", function()
  for _, lib in ipairs(loadEveryLibrary()) do
    local t = _G[namespaceOf(SRC[lib])]
    if t and t.version ~= nil and type(t.stale) == "function" then
      eq(staleNow(t.stale), nil, lib .. ": every copy is the version that runs")
      local copy = copyOf(lib)
      local text = H.pages[copy]
      H.pages[copy] = withVersion(text, t.version .. ".1")
      local newer = staleNow(t.stale)
      ok(type(newer) == "string" and newer ~= "", lib .. ": a newer copy goes unreported")
      H.pages[copy] = withVersion(text, "0.0.1")
      local older = staleNow(t.stale)
      ok(type(older) == "string" and older ~= "", lib .. ": an older copy goes unreported")
      H.pages[copy] = text
      eq(staleNow(t.stale), nil, lib .. ": the copy put back")
      local real = index.pages
      index.pages = function() error("index gone") end
      local good, answer = pcall(staleNow, t.stale)
      index.pages = real
      ok(good, lib .. ": stale() raised: " .. tostring(answer))
      eq(answer, nil, lib .. ": no answer while the index can't be read")
    end
  end
end)

-- The four small libraries and Storie Check share their stale(), word for
-- word, so one test holds the words: a newer copy wants a reload, an older
-- one an update from inside its own space.
test("libraries: the small libraries' stale() names each copy that differs, and what to do", "dm", function()
  loadEveryLibrary()
  local tail = "Library/Storie/Chapter Navigation"
  local newer, older = "Adventure/" .. tail, "Book/" .. tail
  H.pages[newer] = withVersion(H.pages[newer], "1.2.0")
  eq(chapterNav.stale(), "Chapter Navigation 1.1.1 is running; " .. newer .. " holds 1.2.0. Run System: Reload.")
  H.pages[older] = withVersion(H.pages[older], "1.0.9")
  eq(chapterNav.stale(), "Chapter Navigation 1.1.1 is running; " .. newer .. " holds 1.2.0; " .. older ..
     " holds 1.0.9, an older version. Run System: Reload, and update the older copy from inside its own space.")
  H.pages[newer] = SRC["Chapter Navigation"]
  eq(chapterNav.stale(), "Chapter Navigation 1.1.1 is running; " .. older ..
     " holds 1.0.9, an older version. Update the older copy from inside its own space.")
  H.pages[older] = H.pages[older]:gsub('\nversion: "[^"\n]*"', "", 1)
  eq(chapterNav.stale(), "Chapter Navigation 1.1.1 is running; " .. older ..
     " has no version. Update the older copy from inside its own space.")
  -- 1.10 is after 1.9, as numbers, not as text
  H.pages[older] = withVersion(SRC["Chapter Navigation"], "1.1.10")
  has(chapterNav.stale(), "holds 1.1.10. Run System: Reload.")
  H.pages[older] = SRC["Chapter Navigation"]
  H.pages["Notes/Deep/Library/Storie/Chapter Navigation"] = withVersion(SRC["Chapter Navigation"], "9.0.0")
  has(chapterNav.stale(), "Notes/Deep/Library/Storie/Chapter Navigation holds 9.0.0",
      "a copy at any depth counts")
  H.pages["Notes/Deep/Library/Storie/Chapter Navigation"] = nil
  -- a page whose name merely ends in the copy's is no copy
  H.pages["Notes/My Library/Storie/Chapter Navigation"] = withVersion(SRC["Chapter Navigation"], "9.0.0")
  H.pages["Notes/Chapter Navigation"] = withVersion(SRC["Chapter Navigation"], "9.0.0")
  H.pages["Library/Storie/Chapter Navigation Extra"] = withVersion(SRC["Chapter Navigation"], "9.0.0")
  eq(chapterNav.stale(), nil, "pages of other names")
  -- and a copy that isn't a library page, untagged, isn't one of its copies
  H.pages["Library/Storie/Chapter Navigation"] = "---\nversion: \"9.0.0\"\n---\n"
  eq(chapterNav.stale(), nil, "a page without the library tag")
end)

------------------------------------------------------------------ Settings
-- Space Switcher, Chapter Navigation and Appearances declare the shape of
-- their settings with config.define, which SilverBullet checks each later
-- config.set against. Declared after a CONFIG page's block has run, it
-- checks nothing there, so a library's schema block must load first.

local SCHEMAS = { spaceSwitcher = "Space Switcher", chapterNav = "Chapter Navigation", appearances = "Appearances" }

test("libraries: a schema loads ahead of every CONFIG page's block", "dm", function()
  local highest, where = nil, nil
  for _, layout in ipairs({ "dm", "adventure", "author", "book", "player" }) do
    for _, b in ipairs(LIBS[layout]) do
      if b.page:match("CONFIG$") and (not highest or b.priority > highest) then
        highest, where = b.priority, layout .. ": " .. b.ref
      end
    end
  end
  ok(highest, "the campaign has no CONFIG block")
  local found = 0
  for lib, text in pairs(SRC) do
    for block in text:gmatch("```space%-lua\n(.-)\n```") do
      if block:find("config.define(", 1, true) then
        found = found + 1
        local priority = tonumber(block:match("%-%-%s*priority:%s*(%-?%d+)") or "0")
        ok(priority > highest, lib .. ": its schema loads at priority " .. priority ..
           ", no earlier than " .. where .. " at " .. highest)
        ok(priority <= 50, lib .. ": a priority above 50 runs before SilverBullet's own libraries")
      end
    end
  end
  ok(found >= 3, "the three small libraries declare their settings")
end)

test("libraries: every CONFIG page sets the small libraries' settings in the shape they read", "dm", function()
  local checked = 0
  for _, layout in ipairs({ "dm", "adventure", "author", "book", "player" }) do
    reset(layout)
    local schemas = config.getSchemas().properties
    for key, lib in pairs(SCHEMAS) do
      local value = config.get(key, nil)
      if value ~= nil then
        ok(schemas[key], layout .. ": " .. lib .. " declares no schema for " .. key)
        eq(jsonschema.validateObject(schemas[key], value), nil, layout .. ": " .. key)
        checked = checked + 1
      end
    end
  end
  ok(checked >= 8, "the campaign's CONFIG pages set each of the three")
end)

-- The README's table names every library in src/, at the version its page
-- has, with a link to it: a version bumped without the README fails here.
test("libraries: the README's table names each library at its version, with its link", "dm", function()
  ok(README, "no README.md")
  local rows = {}
  for name, path, version in README:gmatch("\n| %[([^%]]+)%]%(([^)]+)%) |[^\n]*| ([^|\n]+) |") do
    rows[name] = { path = path, version = version }
  end
  local names = {}
  for lib in pairs(SRC) do names[#names + 1] = lib end
  table.sort(names)
  for _, lib in ipairs(names) do
    local row = rows[lib]
    ok(row, lib .. " has no row in the README's table")
    eq(row.path, "src/" .. (lib:gsub(" ", "%%20")) .. ".md", lib .. "'s link")
    eq(row.version, frontmatterVersion(SRC[lib]), lib .. "'s version in the README")
    rows[lib] = nil
  end
  eq(next(rows), nil, "the README names a library src/ doesn't have")
end)

test("libraries: the README names the licence the LICENSE file holds", "dm", function()
  ok(LICENSE, "no LICENSE")
  ok(LICENSE:find("^MIT License\n"), "LICENSE is the MIT License")
  has(README, "\n## Licence\n\nMIT: see [LICENSE](LICENSE).\n")
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
