------------------------------------------------------------------ GM Beyond: a tab behind its space

-- A tab reads GM Beyond when it opens. If the space's copy changes after
-- that, from another tab, a sync or Library: Install, the tab would go on
-- importing and refreshing with the code it read: gmb.stale() says so, and
-- nothing that writes runs until the tab is reloaded.

local BEYOND = "Library/Storie/GM Beyond"

local function copy(t)
  if type(t) ~= "table" then return t end
  local out = {}
  for k, v in pairs(t) do out[k] = copy(v) end
  return out
end

local function serve(name)
  local body = copy(DDB[name])
  H.responses[gmb.endpoint .. tostring(body.data.id)] = { ok = true, status = 200, body = body }
  return body.data
end

-- The library's page as the space holds it, at another version.
local function beyondAt(name, version)
  H.pages[name] = (SRC["GM Beyond"]:gsub('\nversion: "[^"]*"\n', '\nversion: "' .. version .. '"\n', 1))
end

test("beyond: the version this tab runs is its page's", "dm", function()
  local written = SRC["GM Beyond"]:match('^%-%-%-\n.-\nversion: "([^"]+)"\n.-%-%-%-\n')
  ok(written, "a version in GM Beyond's frontmatter")
  eq(gmb.version, written)
  eq(gmb.stale(), nil, "a space that holds the same says nothing")
  serve("bram")
  local page = gmb.import("1001")
  ok(page, "imported")
  hasnt(gmb.bar(page).html.outerHTML, "Reload this tab")
end)

test("beyond: a tab behind its space says so, and writes nothing", "dm", function()
  local data = serve("bram")
  local page = gmb.import("1001")
  local imported = lastNotification()
  local before = H.pages[page]
  beyondAt(BEYOND, "2.2.0")
  local said = "This tab runs GM Beyond " .. gmb.version .. ", but the space has 2.2.0: " ..
    "reload it (System: Reload, Ctrl-Alt-R) first."
  eq(gmb.stale(), said)
  local writes, fetched = #H.writes, #H.fetched
  -- no import, not even a question or a fetch
  eq(gmb.import(), nil)
  eq(#H.promptsAsked, 0)
  eq(lastNotification().message, said)
  eq(lastNotification().kind, "warning")
  data.baseHitPoints = 40
  eq(gmb.import("1001"), nil)
  eq(gmb.refresh(page), nil)
  eq(gmb.refreshParty(), nil)
  eq(#H.confirmsAsked, 0)
  eq(#H.fetched, fetched, "nothing fetched")
  -- nor an Undo from before
  runAction(imported, "Undo")
  eq(lastNotification().message, said)
  eq(#H.writes, writes, "nothing written")
  eq(H.pages[page], before)
  -- the bar says it first, in words
  local bar = gmb.bar(page)
  local first = bar.html.children[1]
  eq(first.attrs.class, "gmb-stale")
  eq(textOf(first), "⟳ Reload this tab: it runs GM Beyond " .. gmb.version .. ", and the space has 2.2.0 " ..
    "(System: Reload, Ctrl-Alt-R).")
  eq(list(buttonsOf(bar.html)), "Refresh from D&D Beyond")
  click(bar, "Refresh from D&D Beyond")
  eq(lastNotification().message, said)
  eq(H.pages[page], before)
  -- once the space and the tab agree again, it writes
  beyondAt(BEYOND, gmb.version)
  eq(gmb.stale(), nil)
  H.confirms = { true }
  eq(gmb.refresh(page), page)
  has(H.pages[page], "\nhp: 70\n")
end)

test("beyond: a copy in any folder counts, and each version is named, lowest first", "dm", function()
  beyondAt("Old/Library/Storie/GM Beyond", "2.10.0")
  beyondAt("Adventure/" .. BEYOND, "2.2.0")
  -- a copy of the same version says nothing, and neither does a page merely named like it
  beyondAt("Backup/" .. BEYOND, gmb.version)
  H.pages["Library/Storie/GM Beyond Notes"] = '---\nversion: "9.9.9"\n---\n'
  eq(gmb.stale(), "This tab runs GM Beyond " .. gmb.version .. ", but the space has 2.2.0 and 2.10.0: " ..
    "reload it (System: Reload, Ctrl-Alt-R) first.")
  -- a version is words from a page: the bar shows it as words
  beyondAt("Old/Library/Storie/GM Beyond", "<b>3</b>")
  serve("bram")
  H.pages["Characters/Bram Holloway"] = "---\ntype: pc\nddb: 1001\n---\n"
  local html = gmb.bar("Characters/Bram Holloway").html.outerHTML
  has(html, "and the space has 2.2.0 and &lt;b&gt;3&lt;/b&gt; (System")
  hasnt(html, "<b>3")
end)

test("beyond: a look at the index that fails says nothing, and the import still works", "dm", function()
  serve("bram")
  local real = index.pages
  index.pages = function() error("index gone") end
  local good, err = pcall(function()
    eq(gmb.stale(), nil)
    eq(gmb.import("1001"), "Characters/Bram Holloway")
    ok(gmb.bar("Characters/Bram Holloway"), "a bar")
  end)
  index.pages = real
  if not good then error(err, 0) end
  hasnt(gmb.bar("Characters/Bram Holloway").html.outerHTML, "Reload")
end)
