------------------------------------------------------------------ GM Beyond: what a player writes

-- Everything on a D&D Beyond character is written by its player: its name,
-- a homebrew item's, feat's or spell's name, and homebrew rules text. None of
-- it may reach the DM's page as markup: no tag, no expression, no link, and
-- no line that ends the frontmatter. And what D&D Beyond answers when it
-- doesn't send a character says why.

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

local function frontmatter(text)
  local head, body = text:match("^%-%-%-\n(.-)\n%-%-%-\n(.*)$")
  return head, body
end

-- Every < in the text escaped with a backslash, so none starts a tag.
local function noTag(text, what)
  ok(text:sub(1, 1) ~= "<" and not text:find("[^\\]<"), (what or "text") .. " has a live <: " .. text)
end

local function sortedKeys(t)
  local out = {}
  for k in pairs(t) do out[#out + 1] = tostring(k) end
  table.sort(out)
  return table.concat(out, " ")
end

-- Every string in a parsed value, but a feature's Markdown text, is one line.
local function oneLine(v, path)
  if type(v) == "string" then
    ok(not v:find("\n", 1, true), path .. " holds a newline: " .. v)
  elseif type(v) == "table" then
    for k, x in pairs(v) do
      if k ~= "text" then oneLine(x, path .. "." .. tostring(k)) end
    end
  end
end

-- As SilverBullet 2.11 reads a page name in a link (plug-api/lib/ref.ts):
-- a whole page, with nothing taken for a position (@), header (#), anchor
-- ($), alias (|) or tag (< >), no [[ or ]], no . or .. for a folder, no
-- leading . or ^, and no ending normalizePath takes for an extension.
local function linkable(name)
  if name == "" or name:find("[@#|<>$]") then return false end
  if name:find("[[", 1, true) or name:find("]]", 1, true) then return false end
  if name:match("^/?[%.%^]") or name:find("//", 1, true) then return false end
  for seg in (name .. "/"):gmatch("([^/]*)/") do
    if seg == "." or seg == ".." then return false end
  end
  return not name:match("%.[A-Za-z0-9]+$")
end

local HOSTILE = 'Zed <form action="https://x/"><input name="pw"></form>\n---\n${js.import("x")}'

-- Bram, with a hostile string in every name a player can write.
local function hostile()
  local data = serve("bram")
  data.name = HOSTILE
  data.classes[1].definition.name = "<img src=x onerror=y>"
  data.classes[2].subclassDefinition.name = '&lt;meta http-equiv="refresh" content="0;url=https://x"&gt;'
  data.race.fullName = "Hill Dwarf\nspecies: injected"
  data.background.definition.name = "&#60;b&#62;Soldier"
  data.background.definition.featureName = "Rank\r\n---\r\nhp: 1"
  data.inventory[3].definition.name = "<script>alert(1)</script>"
  data.customItems[1].name = "Lucky Coin\n---\nhp: 999"
  data.feats[1].definition.name = '![[Secret]] ${js.import("x")}'
  data.race.racialTraits[1].definition.description = '<p>&lt;form action="https://x/"&gt;&lt;input ' ..
    'name="pw"&gt;&lt;/form&gt; and &#60;b&#62;bold&#60;/b&#62; and ${js.import("x")} and ![[Secret]] ' ..
    "and <img src=x onerror=y> and &amp;lt;b&amp;gt;</p>"
  data.classSpells[1].spells[1].definition.name = "Fire <b>Bolt</b>\n"
  data.actions.class[1].name = "Second\nWind"
  return data
end

test("beyond: rules text written as a tag on D&D Beyond stays words", "dm", function()
  eq(gmb.markdown("<p>&lt;form action=\"https://x/\"&gt;</p>"), [==[\<form action="https://x/"\>]==])
  eq(gmb.markdown("<p>&#60;b&#62;x&#60;/b&#62; &#x3C;i&#x3E;</p>"), [==[\<b\>x\</b\> \<i\>]==])
  eq(gmb.markdown("<p>a < b and c > d</p>"), [==[a \< b and c \> d]==])
  -- what D&D Beyond shows as the characters &lt; stays those characters
  eq(gmb.markdown("<p>&amp;lt;b&amp;gt; &amp; D&amp;D</p>"), [==[\&lt;b\&gt; & D&D]==])
  eq(gmb.markdown('<p>${js.import("x")} ![[Secret]] [x](https://x) `code` #tag</p>'),
    [==[\$\{js.import("x")\} !\[\[Secret\]\] \[x\](https://x) \`code\` \#tag]==])
  eq(gmb.markdown("<p>Before<!-- <b>hidden</b> --> after<script>alert(1)</script>.</p>"), "Before after.")
  -- D&D Beyond's own tags still become Markdown
  eq(gmb.markdown("<p><strong>2 * 3</strong> is <em>six</em></p>"), [==[**2 \* 3** is *six*]==])
  eq(gmb.markdown("<table><tr><th>a|b</th></tr><tr><td>&lt;c&gt;</td></tr></table>"),
    "| a/b |\n|---|\n| " .. [==[\<c\>]==] .. " |")
end)

test("beyond: a name as Markdown shows as it is, on one line", "dm", function()
  eq(gmb.inline("Bram Holloway"), "Bram Holloway")
  eq(gmb.inline("O'Brien-Smythe, Jr."), "O'Brien-Smythe, Jr.")
  eq(gmb.inline(HOSTILE),
    [==[Zed \<form action="https://x/"\>\<input name="pw"\>\</form\> --- \$\{js.import("x")\}]==])
  eq(gmb.inline("[[Mara]] #pc *b* &lt;"), [==[\[\[Mara\]\] \#pc \*b\* \&lt;]==])
  eq(gmb.line("a\r\n\tb\0c\u{2028}d"), "a b c d")
  eq(gmb.line(nil), nil)
end)

test("beyond: nothing a player names on D&D Beyond is live on the page", "dm", function()
  hostile()
  local page = gmb.import("1001")
  ok(page, "imported")
  local text = H.pages[page]
  noTag(text, "the page")
  -- the frontmatter ends where it should, and no value ends it early
  eq(count("\n" .. text, "\n---\n"), 2, "two lines of ---, the frontmatter's own")
  local head, body = frontmatter(text)
  ok(head, "a frontmatter")
  -- the body's one expression is the sheet
  local found = {}
  for _, n in ipairs(markdown.parseMarkdown(text).children) do
    if n.type == "LuaDirective" then found[#found + 1] = text:sub(n.from + 1, n.to) end
  end
  eq(table.concat(found, " "), "${sheets.draw()}")
  eq(count(body, "${"), 1, "no ${ outside code in the body")
  has(body, "\n# " .. [==[Zed \<form action="https://x/"\>\<input name="pw"\>\</form\> --- \$\{js.import("x")\}]==] .. "\n")
  -- the frontmatter parses, with the keys an ordinary import has, and the
  -- names as they were written, each on one line
  local d = yaml.parse(head)
  oneLine(d, "frontmatter")
  local plain = serve("bram")
  plain.id = 1009
  H.responses[gmb.endpoint .. "1009"] = { ok = true, status = 200, body = { data = plain } }
  local ordinary = yaml.parse((frontmatter(H.pages[gmb.import("1009")])))
  eq(sortedKeys(d), sortedKeys(ordinary))
  eq(d.hp, 68, "no name sets a key of its own")
  eq(d.class, "<img src=x onerror=y> 3 / Wizard 2")
  eq(d.subclass, 'Champion / &lt;meta http-equiv="refresh" content="0;url=https://x"&gt;')
  eq(d.species, "Hill Dwarf species: injected")
  eq(d.background, "&#60;b&#62;Soldier")
  eq(d.features[#d.features].name, "Rank --- hp: 1")
  eq(d.feats[1].name, '![[Secret]] ${js.import("x")}')
  eq(d.cantrips[1].name, "Fire <b>Bolt</b>")
  eq(d.resources[1].name, "Second Wind")
  has(table.concat(d.equipment, " | "), "Shield | <script>alert(1)</script> | Longbow")
  has(table.concat(d.equipment, " | "), "Lucky Coin --- hp: 999")
  -- rules text as words: every would-be tag, expression and link escaped
  eq(d.traits[1].text, [==[\<form action="https://x/"\>\<input name="pw"\>\</form\> and \<b\>bold\</b\> ]==] ..
    [==[and \$\{js.import("x")\} and !\[\[Secret\]\] and and \&lt;b\&gt;]==] .. "\n")
  ok(linkable(page), "a page name SilverBullet can link to: " .. tostring(page))
end)

test("beyond: the live roster escapes what a player names", "dm", function()
  hostile()
  local s = gmb.summary(1001)
  noTag(s, "the summary")
  hasnt(s, "${")
  hasnt(s, "[[")
  hasnt(s, "\n")
  has(s, [==[Zed \<form action="https://x/"\>]==])
  has(s, [==[ — Hill Dwarf species: injected \<img src=x onerror=y\> 3 / Wizard 2]==])
end)

test("beyond: a page name is one SilverBullet can open and link to", "dm", function()
  local data = serve("bram")
  for _, case in ipairs({
    { "Zed <the Bold>", "Characters/Zed the Bold" },
    { "Agent@47", "Characters/Agent 47" },
    { "Brin$", "Characters/Brin" },
    { "Hash#Tag", "Characters/Hash Tag" },
    { "a|b", "Characters/a b" },
    { "[[Mara]]", "Characters/Mara" },
    { "^Up", "Characters/Up" },
    { "../Secret", "Characters/Secret" },
    { "Dr.Who", "Characters/Dr Who" },
    { "notes.md", "Characters/notes md" },
    { "Line\nbreak", "Characters/Line break" },
    { "Zoë.Ärger", "Characters/Zoë.Ärger" },
    { "Dr. Who", "Characters/Dr. Who" },
  }) do
    data.name = case[1]
    local page = gmb.import("1001")
    eq(page, case[2], case[1])
    ok(linkable(page), "SilverBullet can link to " .. page)
    H.pages[page] = nil
  end
end)

test("beyond: an answer that isn't a character's JSON says so, and the roster still shows", "dm", function()
  local asked
  H.responses[gmb.endpoint .. "1001"] = function(_, options)
    asked = options
    return { ok = true, status = 200, body = '{"data": {"id": 1001}}' }
  end
  eq(gmb.summary(1001), "_(private or unreachable)_")
  eq(asked and asked.responseEncoding, "application/json", "JSON asked for")
  eq(gmb.import("1001"), nil)
  has(lastNotification().message, "D&D Beyond's answer wasn't a character's data")
  eq(lastNotification().kind, "error")
  eq(H.pages["Characters/Bram Holloway"], nil)
end)

test("beyond: each way D&D Beyond can refuse has its own words", "dm", function()
  local url = gmb.endpoint .. "1001"
  local function said(response)
    H.responses[url] = response
    eq(gmb.import("1001"), nil)
    eq(lastNotification().kind, "error")
    return lastNotification().message
  end
  has(said({ ok = true, status = 404, body = { success = false } }),
    "D&D Beyond answered 404: the character is private, or has been deleted")
  has(said({ ok = true, status = 403, body = "Forbidden" }), "D&D Beyond answered 403: the character is private")
  has(said({ ok = true, status = 429, body = "Too Many Requests" }),
    "D&D Beyond answered 429: too many requests just now, so try again shortly")
  has(said({ ok = true, status = 503, body = "<html>Service Unavailable</html>" }),
    "D&D Beyond answered 503: something is wrong at D&D Beyond, so try again later")
  -- the server's own proxy failing: its 500, not D&D Beyond's
  has(said({ ok = false, status = 500, body = "error sending request for url" }),
    "the server couldn't reach D&D Beyond (it answered 500: error sending request for url)")
  -- an error page that isn't JSON: asked for again as it comes, for its status
  has(said(function(_, options)
    if options and options.responseEncoding then error("SyntaxError: Unexpected token '<'") end
    return { ok = true, status = 429, body = "<html>Slow down</html>" }
  end), "D&D Beyond answered 429")
  -- no answer at all
  has(said(function() error("TypeError: Failed to fetch") end),
    "couldn't reach D&D Beyond through the server: ")
  for _, n in ipairs(H.notifications) do hasnt(n.message, "may be private") end
end)
