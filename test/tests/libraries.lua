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
