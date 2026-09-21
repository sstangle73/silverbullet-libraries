------------------------------------------------------------------ Space Switcher

local ORIGIN = "https://wiki.example.org"
local FIVE = "DM Adventure Author Book Player"

local function strip(layout, page)
  reset(layout)
  H.current = page
  return H.views["spaceSwitcher"].content()
end

local function spaceNames()
  local out = {}
  for _, s in ipairs(config.get("spaceSwitcher.spaces", {})) do out[#out + 1] = s.name end
  return table.concat(out, " ")
end

-- The space-lua block in a page that configures a library.
local function configBlock(page, key)
  local text = assert(FIXTURES.dm[page], "no page " .. page)
  for block in text:gmatch("```space%-lua\n(.-)\n```") do
    if block:find('config.set("' .. key .. '"', 1, true) then return block end
  end
end

-- Each space's fill and the text on it: the colour its CONFIG gives it, and
-- black or white, whichever reads better on that fill.
local FILLS = {
  dm = "#311b92/#ffffff", adventure = "#4fc3f7/#000000", author = "#e65100/#000000",
  book = "#fff176/#000000", player = "#ad1457/#ffffff",
}

-- A strip's pieces as Space Switcher writes them, with the mocks' icons: the
-- tab of the space you are in, filled in; a tab that goes to another space's
-- home; and a "This page in" link at the right.
local function svg(glyph) return '<svg class="feather feather-' .. glyph .. '"><path d="M0 0"></path></svg>' end
local function here(name, glyph, fill, text)
  return '<span class="space-switcher-tab space-switcher-here" data-space="' .. name ..
         '" style="--space-switcher-fill: ' .. fill .. "; --space-switcher-text: " .. text ..
         '" aria-current="page" title="You are in the ' .. name .. ' space">' .. svg(glyph) ..
         "<span>" .. name .. "</span></span>"
end
local function to(name, glyph)
  return '<a class="space-switcher-tab" data-space="' .. name .. '" href="' .. ORIGIN .. "/" .. name:lower() ..
         '/" title="Go to the ' .. name .. ' space">' .. svg(glyph) .. "<span>" .. name .. "</span></a>"
end
local function thisPage(path, page, space)
  return '<span class="space-switcher-links"><a href="' .. ORIGIN .. path .. '" title="Open ' .. page ..
         " in the " .. space .. ' space">This page in ' .. space .. " ↗</a></span>"
end

-- The tabs in each space, whatever the page: the five spaces in their CONFIG
-- order, and Player's own list of one.
local TABS = {
  dm = here("DM", "eye", "#311b92", "#ffffff") .. to("Adventure", "map") .. to("Author", "feather") ..
       to("Book", "book-open") .. to("Player", "users"),
  adventure = to("DM", "eye") .. here("Adventure", "map", "#4fc3f7", "#000000") .. to("Author", "feather") ..
       to("Book", "book-open") .. to("Player", "users"),
  author = to("DM", "eye") .. to("Adventure", "map") .. here("Author", "feather", "#e65100", "#000000") ..
       to("Book", "book-open") .. to("Player", "users"),
  book = to("DM", "eye") .. to("Adventure", "map") .. to("Author", "feather") ..
       here("Book", "book-open", "#fff176", "#000000") .. to("Player", "users"),
  player = here("Player", "users", "#ad1457", "#ffffff"),
}

test("switcher: one strip per space, ahead of the chapter bar", "dm", function()
  for _, layout in ipairs({ "dm", "adventure", "author", "book", "player" }) do
    reset(layout)
    local v = H.views["spaceSwitcher"]
    ok(v, layout .. ": no switcher")
    eq(v.dock, "page-top", layout)
    eq(v.defaultOpen, true, layout)
    ok(H.commands["Navigate: Space Switcher"], layout .. ": no command")
    local mine, chapters
    for i, name in ipairs(H.viewOrder) do
      if name == "spaceSwitcher" then mine = i end
      if name == "chapterNavTop" then chapters = i end
    end
    if layout == "dm" or layout == "book" then ok(chapters, layout .. ": no chapter bar loaded") end
    if chapters then ok(mine < chapters, layout .. ": the chapter bar would sit above the switcher") end
  end
end)

test("switcher: the four copies are identical", "dm", function()
  local adventure = FIXTURES.dm["Adventure/Library/Storie/Space Switcher"]
  ok(adventure, "no Adventure copy")
  for _, folder in ipairs({ "Author", "Book", "Player" }) do
    eq(FIXTURES.dm[folder .. "/Library/Storie/Space Switcher"], adventure, folder .. " copy differs")
  end
  for _, old in ipairs({ "Adventure", "Author", "Book", "Player" }) do
    eq(FIXTURES.dm[old .. "/Library/Space Switcher"], nil, "an old copy is still in " .. old .. "/Library")
  end
end)

test("switcher: each space's CONFIG gives it the spaces it shows", "dm", function()
  for _, layout in ipairs({ "dm", "adventure", "author", "book" }) do
    reset(layout)
    eq(spaceNames(), FIVE, layout)
    eq(config.get("spaceSwitcher.directory", nil), nil, layout .. " has a directory link")
  end
  reset("player")
  eq(spaceNames(), "Player")
  eq(config.get("spaceSwitcher.directory.url", nil), "/.dashboard")
end)

test("switcher: DM runs Player's CONFIG first, so the full list wins", "dm", function()
  local order = {}
  for i, lib in ipairs(LIBS.dm) do
    if lib.name:find("/CONFIG #", 1, true) then order[#order + 1] = lib.name end
  end
  eq(order[1], "Player/CONFIG #1")
  ok(configBlock("Player/CONFIG", "spaceSwitcher"):find("^%-%- priority: 1\n"), "Player's block lost its priority")
end)

test("switcher: Adventure, Author and Book configure it identically", "dm", function()
  local adventure = configBlock("Adventure/CONFIG", "spaceSwitcher")
  ok(adventure, "no Space Switcher block in Adventure/CONFIG")
  eq(configBlock("Author/CONFIG", "spaceSwitcher"), adventure, "Author/CONFIG differs")
  eq(configBlock("Book/CONFIG", "spaceSwitcher"), adventure, "Book/CONFIG differs")
  -- Adventure also configures the scene bars, so only the shared section matches.
  local function section(page, heading)
    local text = FIXTURES.dm[page] or ""
    local from = string.find(text, "## " .. heading, 1, true)
    if not from then return nil end
    local rest = string.sub(text, from)
    local stop = string.find(rest, string.char(10) .. "## ", 2, true)
    local body = stop and string.sub(rest, 1, stop) or rest
    return (string.match(body, "^(.-)%s*$"))
  end
  local shared = section("Adventure/CONFIG", "Space Switcher")
  ok(shared, "no Space Switcher section in Adventure/CONFIG")
  eq(section("Author/CONFIG", "Space Switcher"), shared, "Author/CONFIG's section differs")
  eq(section("Book/CONFIG", "Space Switcher"), shared, "Book/CONFIG's section differs")
  eq(section("Book/CONFIG", "Chapter Navigation"), section("Adventure/CONFIG", "Chapter Navigation"),
     "Book/CONFIG and Adventure/CONFIG must configure the bars the same way")
end)

test("switcher: Player's own entry matches the full list's", "dm", function()
  reset("adventure")
  local full
  for _, s in ipairs(config.get("spaceSwitcher.spaces")) do
    if s.name == "Player" then full = s end
  end
  reset("player")
  local own = config.get("spaceSwitcher.spaces")[1]
  for _, key in ipairs({ "name", "url", "icon", "color", "textColor" }) do
    eq(own[key], full[key], key)
  end
end)

test("switcher: the Player space names no other space anywhere", "player", function()
  for name, text in pairs(FIXTURES.player) do
    for _, word in ipairs({ "Adventure space", "Author", "/dm/", "/adventure/", "/author/", "/book/", "Book space", "DM space" }) do
      hasnt(text, word, name)
    end
  end
end)

-- The whole strip on a handful of pages in each space. DM's own pages have no
-- page link, and its copies of the other spaces' pages link to them there, an
-- index to the space's home. Every page of Adventure, Author and Book opens in
-- DM, at its path there. Player shows only itself and the server's list of
-- spaces. Then every page of each space, for the tabs at least.
test("switcher: the strip on pages of each space, exactly", "dm", function()
  local allSpaces = '<span class="space-switcher-links"><a href="' .. ORIGIN ..
                    '/.dashboard" title="The spaces your account can open">All spaces ↗</a></span>'
  local pages = {
    dm = {
      ["index"] = "",
      ["Session Table"] = "",
      ["Adaptation/01 The Tin Crown/Chapter 02"] = "",
      ["Adventure/index"] = thisPage("/adventure/", "index", "Adventure"),
      ["Adventure/Campaign/Act I/Scene 2"] =
        thisPage("/adventure/Campaign/Act%20I/Scene%202", "Campaign/Act I/Scene 2", "Adventure"),
      ["Author/Rules/Party Size"] = thisPage("/author/Rules/Party%20Size", "Rules/Party Size", "Author"),
      ["Book/Books/02 The Glass Road/Chapter 02"] =
        thisPage("/book/Books/02%20The%20Glass%20Road/Chapter%2002", "Books/02 The Glass Road/Chapter 02", "Book"),
      ["Player/Notes/index"] = thisPage("/player/Notes/index", "Notes/index", "Player"),
    },
    adventure = {
      ["index"] = thisPage("/dm/Adventure/index", "Adventure/index", "DM"),
      ["Campaign/Act I/Scene 2"] =
        thisPage("/dm/Adventure/Campaign/Act%20I/Scene%202", "Adventure/Campaign/Act I/Scene 2", "DM"),
    },
    author = {
      ["index"] = thisPage("/dm/Author/index", "Author/index", "DM"),
      ["Rules/Party Size"] = thisPage("/dm/Author/Rules/Party%20Size", "Author/Rules/Party Size", "DM"),
    },
    book = {
      ["People/Beatrice"] = thisPage("/dm/Book/People/Beatrice", "Book/People/Beatrice", "DM"),
      ["Books/01 The Tin Crown/Contents"] =
        thisPage("/dm/Book/Books/01%20The%20Tin%20Crown/Contents", "Book/Books/01 The Tin Crown/Contents", "DM"),
    },
    player = {
      ["index"] = allSpaces,
      ["Notes/index"] = allSpaces,
    },
  }
  for _, layout in ipairs({ "dm", "adventure", "author", "book", "player" }) do
    reset(layout)
    for page, links in pairs(pages[layout]) do
      H.current = page
      eq(H.views["spaceSwitcher"].content(), '<div class="space-switcher">' .. TABS[layout] .. links .. "</div>",
         layout .. ": " .. page)
    end
    for page in pairs(H.pages) do
      H.current = page
      has(H.views["spaceSwitcher"].content(), '<div class="space-switcher">' .. TABS[layout], layout .. ": " .. page)
    end
  end
end)

test("switcher: DM on an Adventure page", "dm", function()
  local html = strip("dm", "Adventure/Campaign/Act I")
  has(html, '<span class="space-switcher-tab space-switcher-here" data-space="DM" ' ..
            'style="--space-switcher-fill: #311b92; --space-switcher-text: #ffffff" aria-current="page"')
  for _, key in ipairs({ "adventure", "author", "book", "player" }) do
    has(html, 'href="' .. ORIGIN .. "/" .. key .. '/"')
  end
  has(html, 'href="' .. ORIGIN .. '/adventure/Campaign/Act%20I"')
  has(html, "This page in Adventure ↗")
  hasnt(html, "\n")
  eq(html:sub(1, 28), '<div class="space-switcher">')
  eq(html:sub(-6), "</div>")
end)

test("switcher: DM pages of its own have no page link", "dm", function()
  local html = strip("dm", "Session Table")
  hasnt(html, "This page in")
  hasnt(html, "space-switcher-links")
  has(html, 'space-switcher-here" data-space="DM"')
end)

test("switcher: DM's copies of other spaces' pages", "dm", function()
  has(strip("dm", "Adventure/index"),
      'href="' .. ORIGIN .. '/adventure/" title="Open index in the Adventure space">This page in Adventure')
  has(strip("dm", "Player/Notes/index"), 'href="' .. ORIGIN .. '/player/Notes/index"')
  has(strip("dm", "Book/People/Ada"), "This page in Book ↗")
  has(strip("dm", "Author/Rules/Party Size"), 'href="' .. ORIGIN .. '/author/Rules/Party%20Size"')
end)

test("switcher: Adventure, Author and Book pages open in DM", "dm", function()
  local html = strip("adventure", "Campaign/Premise")
  has(html, 'space-switcher-here" data-space="Adventure"')
  hasnt(html, 'space-switcher-here" data-space="DM"')
  has(html, 'href="' .. ORIGIN .. '/dm/"')
  has(html, 'href="' .. ORIGIN .. '/dm/Adventure/Campaign/Premise"')
  has(html, "This page in DM ↗")
  has(strip("book", "People/Ada"), 'href="' .. ORIGIN .. '/dm/Book/People/Ada"')
  has(strip("author", "index"), 'href="' .. ORIGIN .. '/dm/Author/index"')
end)

test("switcher: the Player space names no other space", "dm", function()
  local html = strip("player", "index")
  has(html, 'space-switcher-here" data-space="Player"')
  has(html, 'href="' .. ORIGIN .. '/.dashboard" title="The spaces your account can open">All spaces ↗</a>')
  for _, word in ipairs({ "DM", "Adventure", "Author", "Book", "/dm/" }) do
    hasnt(html, word)
  end
end)

test("switcher: each space keeps its colour and its text reads", "dm", function()
  for layout, colours in pairs(FILLS) do
    local fill, text = colours:match("(.+)/(.+)")
    has(strip(layout, "index"), "--space-switcher-fill: " .. fill .. "; --space-switcher-text: " .. text, layout)
  end
end)

test("switcher: black or white text by contrast", "dm", function()
  reset("dm")
  eq(spaceSwitcher.textOn("#000000"), "#ffffff")
  eq(spaceSwitcher.textOn("#ffffff"), "#000000")
  eq(spaceSwitcher.textOn("#fff"), "#000000")
  eq(spaceSwitcher.textOn("#00F"), "#ffffff")
  eq(spaceSwitcher.textOn("#777777"), "#000000")
  eq(spaceSwitcher.textOn("#757575"), "#ffffff")
  eq(spaceSwitcher.textOn("rebeccapurple"), nil)
  eq(spaceSwitcher.textOn("#12345"), nil)
end)

test("switcher: hidden away from the five spaces", "dm", function()
  reset("dm")
  H.prefix = "/"
  eq(H.views["spaceSwitcher"].content(), nil)
  H.prefix = "/notes/"
  eq(H.views["spaceSwitcher"].content(), nil)
end)

test("switcher: hidden without settings", "dm", function()
  reset("dm")
  H.config.spaceSwitcher = nil
  H.current = "index"
  eq(H.views["spaceSwitcher"].content(), nil)
  eq(#H.printed, 0, "it should hide quietly: " .. list(H.printed))
end)

test("switcher: page names are encoded like SilverBullet's URLs", "dm", function()
  reset("dm")
  eq(spaceSwitcher.encode("Things/The Warden's Wand (Broken) & Co?#é"),
     "Things/The%20Warden's%20Wand%20(Broken)%20%26%20Co%3F%23%C3%A9")
  eq(spaceSwitcher.encode("Books/01 The Tin Crown/Chapter 01"),
     "Books/01%20The%20Tin%20Crown/Chapter%2001")
end)

test("switcher: HTML stays well formed", "dm", function()
  local html = strip("dm", 'Adventure/The "Odd" <Page>')
  has(html, 'title="Open The &quot;Odd&quot; &lt;Page&gt; in the Adventure space"')
  has(html, "/adventure/The%20%22Odd%22%20%3CPage%3E")
  eq(count(html, "<a "), count(html, "</a>"))
  eq(count(html, "<span"), count(html, "</span>"))
  eq(count(html, "<div"), 1)
end)

test("switcher: a failure hides the strip instead of breaking the page", "dm", function()
  reset("dm")
  local original = system.getBaseURI
  system.getBaseURI = function() error("offline") end
  local good, err = pcall(function()
    eq(H.views["spaceSwitcher"].content(), nil)
    has(H.printed[1], "offline")
  end)
  system.getBaseURI = original
  if not good then error(err, 0) end
end)

test("switcher: any server, with its own names, folders and colours", "dm", function()
  reset("dm")
  local base = "https://notes.example.org/journal/"
  local original = system.getBaseURI
  system.getBaseURI = function() return base end
  local good, err = pcall(function()
    config.set("spaceSwitcher", {
      spaces = {
        { name = "Notes", url = "https://notes.example.org/", icon = "edit-3" },
        { name = "Journal", url = "/journal", folder = "Journal", icon = "calendar" },
        { name = "Deep", url = "/deep/", folder = "Journal/Deep/" },
        { name = 'Work & "Play"', url = "https://work.example.org/w/", color = "rebeccapurple", textColor = "#fff" },
        { name = "Six", url = "/six/" },
        { name = "Seven", url = "/seven/" },
      },
      directory = { name = "Everything", url = "/.dashboard" },
    })
    -- In Journal: the default fill for the second place, text by contrast.
    local html = spaceSwitcher.html("Plans")
    has(html, 'data-space="Journal" style="--space-switcher-fill: #4fc3f7; --space-switcher-text: #000000"')
    has(html, 'href="https://notes.example.org/Journal/Plans" title="Open Journal/Plans in the Notes space">This page in Notes ↗</a>')
    has(html, 'href="https://work.example.org/w/" title="Go to the Work &amp; &quot;Play&quot; space">')
    has(html, '<span>Work &amp; &quot;Play&quot;</span>')
    has(html, '<a href="https://notes.example.org/.dashboard">Everything ↗</a></span></div>')
    has(html, '<span class="space-switcher-links"><a href="https://notes.example.org/Journal/Plans"')
    eq(count(html, "<span"), count(html, "</span>"))
    -- In Notes: a page inside the deepest folder opens there.
    base = "https://notes.example.org/"
    html = spaceSwitcher.html("Journal/Deep/Well")
    has(html, 'href="https://notes.example.org/deep/Well" title="Open Well in the Deep space">This page in Deep ↗</a>')
    has(spaceSwitcher.html("Journal/Plans"), "This page in Journal ↗")
    hasnt(spaceSwitcher.html("Journalism"), "This page in")
    -- Colours past the palette start again; a set colour and text are used as given.
    base = "https://notes.example.org/seven/"
    has(spaceSwitcher.html("x"), 'data-space="Seven" style="--space-switcher-fill: #311b92;')
    base = "https://work.example.org/w/"
    has(spaceSwitcher.html("x"), "--space-switcher-fill: rebeccapurple; --space-switcher-text: #fff\"")
  end)
  system.getBaseURI = original
  if not good then error(err, 0) end
end)

test("switcher: a space without an icon or a name still draws", "dm", function()
  reset("dm")
  config.set("spaceSwitcher", { spaces = { { url = "/dm/" }, { name = "Two", url = "/two/" } } })
  local html = spaceSwitcher.html("index")
  has(html, '<span>?</span>')
  has(html, '<a class="space-switcher-tab" data-space="Two" href="https://wiki.example.org/two/" title="Go to the Two space"><span>Two</span></a>')
end)
