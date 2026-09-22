-- Mock SilverBullet 2.11 APIs for testing Space Lua libraries under plain Lua 5.4.
-- Everything observable lands in the global H, which reset() rebuilds.

NIL = setmetatable({}, { __tostring = function() return "NIL" end })

function string.startsWith(s, p) return s:sub(1, #p) == p end
function string.endsWith(s, p) return p == "" or s:sub(-#p) == p end
function table.includes(t, v)
  for _, x in ipairs(t) do if x == v then return true end end
  return false
end

local function fresh()
  return {
    pages = {}, current = nil, writes = {}, deleted = {}, navigations = {},
    notifications = {}, prompts = {}, promptsAsked = {}, confirms = {}, confirmsAsked = {},
    picks = {}, filterBoxes = {}, clipboard = nil, clipboardFails = false, opened = {},
    reloads = 0, saves = 0, refreshes = 0, commands = {}, listeners = {}, printed = {},
    views = {}, viewOrder = {}, prefix = "/dm/", files = {}, modified = {},
    config = {
      actionButtons = {
        { icon = "home", description = "Go to the index page", command = "Navigate: Home", priority = 3 },
        { icon = "book", description = "Open page", command = "Navigate: Page Picker", priority = 2 },
        { icon = "terminal", description = "Run command", command = "Open Command Palette", priority = 1 },
      },
    },
  }
end

space = {}
function space.readPage(name)
  local t = H.pages[name]
  if t == nil then error("Not found: " .. tostring(name)) end
  return t
end
function space.writePage(name, text)
  assert(type(text) == "string", "writePage needs a string")
  H.pages[name] = text
  H.writes[#H.writes + 1] = name
  return { name = name }
end
-- As in SilverBullet 2.11 (client/plugos/syscalls/space.ts), space.pageExists
-- is link resolution over the client's list of files, not a look at the page:
-- an exact name, or failing that any page whose path ends in the name,
-- ignoring case. The list lags writes by seconds in a real client; a test
-- calls freezeFileList() to hold it where it is, and settle() to catch it up.
function space.pageExists(name)
  local names = H.known or H.pages
  if names[name] ~= nil then return true end
  local tail = "/" .. name:lower()
  for n in pairs(names) do
    if ("/" .. n:lower()):endsWith(tail) then return true end
  end
  return false
end
-- Exact, and never behind: it asks the space itself, which in a real client
-- is a request to the server for a page that isn't there, so the misses are
-- counted. H.failMeta[name] makes the request fail, as it does offline.
function space.getPageMeta(name)
  if H.failMeta and H.failMeta[name] then error(H.failMeta[name]) end
  local t = H.pages[name]
  if t == nil then
    H.metaMisses = (H.metaMisses or 0) + 1
    error("Not found")
  end
  return { name = name, size = #t, perm = "rw", contentType = "text/markdown",
           lastModified = "2026-09-18T00:00:00" }
end
-- Any file in the space, by its path: a page is its name plus ".md", and
-- anything else, such as a PDF, is a test's to put in H.files[path], as
-- { lastModified = ms }. As in 2.11, fileExists is exact, and a file's
-- lastModified is a number of milliseconds; a page's is H.modified[path],
-- or 1000. H.failMeta[path] makes either fail, as getPageMeta does.
function space.fileExists(name)
  if H.failMeta and H.failMeta[name] then error(H.failMeta[name]) end
  if name:endsWith(".md") then return H.pages[name:sub(1, -4)] ~= nil end
  return H.files[name] ~= nil
end
function space.getFileMeta(name)
  if H.failMeta and H.failMeta[name] then error(H.failMeta[name]) end
  if name:endsWith(".md") and H.pages[name:sub(1, -4)] ~= nil then
    return { name = name, contentType = "text/markdown", lastModified = H.modified[name] or 1000 }
  end
  local f = H.files[name]
  if f == nil then error("Not found: " .. name) end
  return { name = name, contentType = f.contentType or "application/octet-stream",
           lastModified = f.lastModified or 1000 }
end
function freezeFileList()
  H.known = {}
  for n in pairs(H.pages) do H.known[n] = true end
end
function settle() H.known = nil end
function space.deletePage(name)
  if H.pages[name] == nil then error("Not found: " .. name) end
  H.pages[name] = nil
  H.deleted[#H.deleted + 1] = name
end
function space.listPages()
  local out = {}
  for n in pairs(H.pages) do out[#out + 1] = { name = n } end
  return out
end

local function parseValue(v)
  if v == "" then return nil end
  -- YAML flow lists, as a chapter's people are: [Ada, Bea]
  local inner = v:match("^%[(.*)%]$")
  if inner then
    local out = {}
    for item in (inner .. ","):gmatch("%s*(.-)%s*,") do
      if item ~= "" then out[#out + 1] = parseValue(item) end
    end
    return out
  end
  if v == "true" then return true end
  if v == "false" then return false end
  local n = tonumber(v)
  if n then return n end
  return v:match('^"(.*)"$') or v:match("^'(.*)'$") or v
end

-- Parsed frontmatter by page text: the parse is the slow part of a query.
local PARSED = {}
local function frontmatterOf(text)
  local fm = PARSED[text]
  if fm then return fm end
  fm = {}
  local head = text:match("^%-%-%-\n(.-)\n%-%-%-")
  if head then
    for line in (head .. "\n"):gmatch("([^\n]*)\n") do
      local k, v = line:match("^([%w_%-]+):%s*(.-)%s*$")
      if k and k ~= "name" then fm[k] = parseValue(v) end
    end
  end
  PARSED[text] = fm
  return fm
end

index = {}
function index.pages()
  local out = {}
  for name, text in pairs(H.pages) do
    local obj = { name = name }
    for k, v in pairs(frontmatterOf(text)) do obj[k] = v end
    -- As in SilverBullet's indexPage: the page's own attributes win over its
    -- frontmatter, so a frontmatter "size" reads as the size in bytes.
    obj.name, obj.size, obj.perm, obj.contentType = name, #text, "rw", "text/markdown"
    obj.created, obj.lastModified, obj.tag = "2026-09-18T00:00:00", "2026-09-18T00:00:00", "page"
    out[#out + 1] = obj
  end
  table.sort(out, function(a, b) return a.name < b.name end)
  return out
end

-- SLIQ tests `where` the way JavaScript does (query_collection.ts), so 0 and
-- "" fail it as well as nil and false.
local function truthy(v) return v ~= nil and v ~= false and v ~= 0 and v ~= "" end

-- Target of the query[[...]] transpiler in run.py.
function __liq(src, where, orders, select, limit)
  local rows = {}
  for _, p in ipairs(src()) do
    if not where or truthy(where(p)) then rows[#rows + 1] = p end
  end
  if orders and #orders > 0 then
    table.sort(rows, function(a, b)
      for _, o in ipairs(orders) do
        local x, y = o.fn(a), o.fn(b)
        if x ~= y then
          if x == nil then return false end
          if y == nil then return true end
          if o.desc then return x > y end
          return x < y
        end
      end
      return false
    end)
  end
  local out = {}
  for i, p in ipairs(rows) do
    if limit and i > limit then break end
    if select then out[#out + 1] = select(p) else out[#out + 1] = p end
  end
  return out
end

editor = {}
function editor.getCurrentPage() return H.current end
function editor.navigate(ref)
  H.current = type(ref) == "string" and ref:gsub("@.*$", "") or ref.page
  H.navigations[#H.navigations + 1] = H.current
end
function editor.reloadPage() H.reloads = H.reloads + 1 end
function editor.save() H.saves = H.saves + 1 end
function editor.flashNotification(message, kind, options)
  assert(type(message) == "string", "notification message must be a string")
  H.notifications[#H.notifications + 1] = { message = message, kind = kind or "info", options = options }
end
function editor.prompt(message, default)
  H.promptsAsked[#H.promptsAsked + 1] = message
  if #H.prompts == 0 then error("unexpected prompt: " .. message) end
  local v = table.remove(H.prompts, 1)
  if v == NIL then return nil end
  return v
end
function editor.confirm(message)
  H.confirmsAsked[#H.confirmsAsked + 1] = message
  if #H.confirms == 0 then error("unexpected confirm: " .. message) end
  return table.remove(H.confirms, 1)
end
function editor.filterBox(label, options, help, placeholder)
  H.filterBoxes[#H.filterBoxes + 1] = { label = label, options = options, help = help, placeholder = placeholder }
  for _, o in ipairs(options) do
    assert(type(o.name) == "string", "filter option needs a name")
  end
  if #H.picks == 0 then error("unexpected picker: " .. label) end
  local choice = table.remove(H.picks, 1)
  if choice == NIL then return nil end
  for _, o in ipairs(options) do
    if o.name == choice then
      -- Only the documented fields survive the trip back, to keep the code honest.
      return { name = o.name, description = o.description }
    end
  end
  error("picker '" .. label .. "' has no option '" .. choice .. "'")
end
function editor.copyToClipboard(text)
  if H.clipboardFails then error("Document is not focused") end
  H.clipboard = text
end
function editor.openUrl(url) H.opened[#H.opened + 1] = url end
function editor.invokeCommand(name, args)
  local c = H.commands[name]
  if not c then error("no command " .. name) end
  return c.run(args)
end

local function getPath(t, path)
  for part in path:gmatch("[^%.]+") do
    if type(t) ~= "table" then return nil end
    t = t[part]
  end
  return t
end
-- What a Lua table becomes on its way into SilverBullet's config
-- (LuaTable.toJS): with an array part it keeps only that, so a table that
-- mixes a list and named keys loses the keys. Functions pass through.
local function jsify(v)
  if type(v) ~= "table" then return v end
  local out = {}
  if #v > 0 then
    for i = 1, #v do out[i] = jsify(v[i]) end
  else
    for k, x in pairs(v) do out[k] = jsify(x) end
  end
  return out
end

config = {}
function config.get(path, default)
  local v = getPath(H.config, path)
  if v == nil then return default end
  return v
end
-- Like Config.set: a dotted path creates the tables on the way and replaces
-- whatever is at the end of it.
function config.set(path, value)
  if type(path) == "table" then
    for k, v in pairs(path) do config.set(k, v) end
    return
  end
  local parts = {}
  for part in path:gmatch("[^%.]+") do parts[#parts + 1] = part end
  local t = H.config
  for i = 1, #parts - 1 do
    if type(t[parts[i]]) ~= "table" then t[parts[i]] = {} end
    t = t[parts[i]]
  end
  t[parts[#parts]] = jsify(value)
end

actionButton = {}
function actionButton.define(spec)
  table.insert(config.get("actionButtons", {}), spec)
end

command = {}
function command.define(def) H.commands[def.name] = def end

event = {}
function event.listen(listener)
  assert(type(listener.run) == "function", "event.listen needs run")
  H.listeners[listener.name] = H.listeners[listener.name] or {}
  table.insert(H.listeners[listener.name], listener)
end
function dispatch(name)
  local out = {}
  for _, l in ipairs(H.listeners[name] or {}) do
    local r = l.run({ name = name })
    if r ~= nil then out[#out + 1] = r end
  end
  return out
end

widget = {}
function widget.new(spec)
  local allowed = { markdown = true, html = true, cssClasses = true, display = true,
                    events = true, sandbox = true, script = true }
  for k in pairs(spec) do assert(allowed[k], "widget.new: unknown key " .. tostring(k)) end
  spec._isWidget = true
  return spec
end
function widget.markdown(md)
  assert(type(md) == "string", "widget.markdown needs a string")
  return { markdown = md, _isWidget = true }
end

-- node.outerHTML, serialized the way a browser does: attributes escape & < > ",
-- raw text escapes & < >. Plain string children stand for rendered Markdown.
local function escapeHtml(s, attribute)
  s = s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
  if attribute then s = s:gsub('"', "&quot;") end
  return s
end
local NODE = {}
NODE.__index = function(node, key)
  if key ~= "outerHTML" then return nil end
  local names = {}
  for k in pairs(node.attrs) do names[#names + 1] = k end
  table.sort(names)
  local out = { "<" .. node.tag }
  for _, k in ipairs(names) do
    out[#out + 1] = " " .. k .. '="' .. escapeHtml(tostring(node.attrs[k]), true) .. '"'
  end
  out[#out + 1] = ">"
  for _, c in ipairs(node.children) do
    if type(c) == "string" then out[#out + 1] = node.raw and escapeHtml(c) or c
    elseif c._isWidget then out[#out + 1] = type(c.html) == "string" and c.html or c.html.outerHTML
    else out[#out + 1] = c.outerHTML end
  end
  out[#out + 1] = "</" .. node.tag .. ">"
  return table.concat(out)
end

dom = setmetatable({}, { __index = function(_, tag)
  return function(spec)
    local node = { tag = tag, attrs = {}, children = {}, handlers = {} }
    for k, v in pairs(spec) do
      if type(k) == "string" and k ~= "__rawText" then
        if k:sub(1, 2) == "on" then node.handlers[k:sub(3)] = v else node.attrs[k] = v end
      end
    end
    for i, v in ipairs(spec) do
      assert(type(v) == "string" or type(v) == "table", "dom child must be a string or node")
      node.children[i] = v
    end
    -- SilverBullet appends children in pairs() order, so raw text beside
    -- child nodes would land in no fixed place.
    if spec.__rawText ~= nil then
      assert(#node.children == 0, "dom." .. tag .. ": __rawText beside child nodes")
      assert(type(spec.__rawText) == "string", "__rawText must be a string")
      node.children[1] = spec.__rawText
      node.raw = true
    end
    return setmetatable(node, NODE)
  end
end })

-- markdown.parseMarkdown, reduced to what the libraries read: LuaDirective
-- nodes with 0-based from/to offsets, found the way SilverBullet's parser
-- finds them (balanced braces, a body that parses as an expression), and not
-- inside frontmatter, fenced code, inline code or HTML comments.
markdown = {}
function markdown.parseMarkdown(text)
  local children, i, n = {}, 1, #text
  if text:sub(1, 4) == "---\n" then
    local _, e = text:find("\n%-%-%-\n", 4)
    if e then i = e + 1 end
  end
  local lineStart, fence = true, nil
  while i <= n do
    local skipLine = false
    if lineStart then
      local line = text:match("^[^\n]*", i)
      local mark = line:sub(1, 3)
      if fence then
        if mark == fence then fence = nil end
        skipLine = true
      elseif mark == "```" or mark == "~~~" then
        fence = mark
        skipLine = true
      end
      if skipLine then i = i + #line + 1 end
    end
    if not skipLine then
      local c = text:sub(i, i)
      if c == "`" then
        local run = text:match("^`+", i)
        local close = text:find(run, i + #run, true)
        i = close and close + #run or i + #run
        lineStart = false
      elseif text:sub(i, i + 3) == "<!--" then
        local close = text:find("-->", i + 4, true)
        i = close and close + 3 or n + 1
        lineStart = false
      elseif text:sub(i, i + 1) == "${" then
        local depth, j = 0, i + 1
        while j <= n do
          local ch = text:sub(j, j)
          if ch == "{" then depth = depth + 1
          elseif ch == "}" then
            depth = depth - 1
            if depth == 0 then break end
          end
          j = j + 1
        end
        if depth == 0 and j <= n and load("return " .. text:sub(i + 2, j - 1)) then
          children[#children + 1] = {
            type = "LuaDirective", from = i - 1, to = j,
            children = { { type = "LuaExpressionDirective", from = i + 1, to = j - 1 } },
          }
          i = j + 1
        else
          i = i + 2
        end
        lineStart = false
      else
        lineStart = c == "\n"
        i = i + 1
      end
    end
  end
  return { type = "Document", from = 0, to = n, children = children }
end

-- markdown.markdownToHtml, reduced to a wrapper: the tests read the
-- Markdown it was given, not a rendering of it.
function markdown.markdownToHtml(text)
  assert(type(text) == "string", "markdownToHtml needs a string")
  return '<div class="md">' .. text .. "</div>"
end

-- yaml.parse, by PyYAML through run.py, the way SilverBullet hands js-yaml's
-- result to Lua: a map's keys are always strings, as a JavaScript object's
-- are, so a spell list's {1: [...]} is keyed "1", never 1.
yaml = {}
function yaml.parse(text)
  assert(type(text) == "string", "yaml.parse needs a string")
  assert(__yaml_parse, "yaml.parse: run.py needs PyYAML (pip install pyyaml)")
  local ok, value = pcall(__yaml_parse, text)
  if not ok then error("YAML: " .. tostring(value)) end
  return value
end

-- spacelua.parseExpression / evalExpression over plain Lua. As in
-- SilverBullet, each key of the augmentation table stands in for the global
-- of that name while the expression runs.
spacelua = {}
function spacelua.parseExpression(source)
  assert(load("return " .. source, "=expression"))
  return { source = source }
end
function spacelua.evalExpression(parsed, augmentation)
  local env = setmetatable({}, { __index = _G })
  for k, v in pairs(augmentation or {}) do env[k] = v end
  env._ = augmentation
  return assert(load("return " .. parsed.source, "=expression", "t", env))()
end


codeWidget = { refreshAll = function() H.refreshes = H.refreshes + 1 end }

system = {}
function system.getURLPrefix() return H.prefix end
function system.getBaseURI() return "https://wiki.example.org" .. H.prefix end

-- The browser's encodeURIComponent. Real Lua strings are UTF-8 bytes, so
-- encoding byte by byte gives the same result; the class is spelled out
-- because %w follows the C locale.
js = { window = {} }
function js.window.encodeURIComponent(s)
  return (s:gsub("[^A-Za-z0-9%-_%.!~%*'%(%)]", function(c)
    return string.format("%%%02X", c:byte())
  end))
end

icon = {}
function icon.feather(name)
  return '<svg class="feather feather-' .. name .. '"><path d="M0 0"></path></svg>'
end

-- Like the navigator registry: a redefinition replaces the spec but keeps
-- the view's place, which the first definition set.
view = {}
function view.define(spec)
  assert(type(spec.name) == "string" and spec.name ~= "", "view.define needs a name")
  if not H.views[spec.name] then H.viewOrder[#H.viewOrder + 1] = spec.name end
  H.views[spec.name] = spec
  if spec.command then H.commands[spec.command] = { name = spec.command, run = function() end } end
end

function print(...)
  local parts = {}
  for i = 1, select("#", ...) do parts[#parts + 1] = tostring(select(i, ...)) end
  H.printed[#H.printed + 1] = table.concat(parts, " ")
end

-- Widget tree helpers.
function textOf(node)
  if type(node) == "string" then return node end
  if type(node) ~= "table" then return "" end
  local parts = {}
  for _, c in ipairs(node.children or {}) do parts[#parts + 1] = textOf(c) end
  return table.concat(parts, " ")
end

function buttonsOf(node, out)
  out = out or {}
  if type(node) ~= "table" then return out end
  if node.tag == "button" then out[#out + 1] = textOf(node) end
  for _, c in ipairs(node.children or {}) do buttonsOf(c, out) end
  return out
end

function click(root, label)
  root = root.html or root
  local function find(node)
    if type(node) ~= "table" then return nil end
    if node.tag == "button" and textOf(node) == label then return node end
    for _, c in ipairs(node.children or {}) do
      local f = find(c)
      if f then return f end
    end
  end
  local b = find(root)
  if not b then error("no button '" .. label .. "' in: " .. table.concat(buttonsOf(root), " | ")) end
  return b.handlers.click({})
end

function lastNotification() return H.notifications[#H.notifications] end

function runAction(n, name)
  for _, a in ipairs((n.options or {}).actions or {}) do
    if a.name == name then return a.run() end
  end
  local names = {}
  for _, a in ipairs((n.options or {}).actions or {}) do names[#names + 1] = a.name end
  error("no action '" .. name .. "' on '" .. n.message .. "' (has: " .. table.concat(names, ", ") .. ")")
end

-- The table's own play state: what the party has met, found and been
-- published, written by GM Kit as the campaign is run. Every test starts
-- from a campaign that has not been played yet, so a fixture that gains
-- some can't decide what a test sees. The revealed list stays, since it
-- is written by hand as well.
local function clearPlay(layout, pages)
  local keep = { index = true, CONFIG = true, Revealed = true }
  for name in pairs(pages) do
    local rest = name:match("^State/(.*)$") or name:match("^Sessions/(.*)$")
    if layout == "dm" then
      rest = rest or name:match("^Player/(.*)$")
    elseif layout == "player" then
      rest = rest or name
    end
    if rest and not keep[rest] and not rest:startsWith("Notes/")
        and not rest:startsWith("Library/") then
      pages[name] = nil
    end
  end
end

function reset(layout)
  H = fresh()
  H.prefix = "/" .. layout .. "/"
  -- Every library global goes, so nothing a library remembered in one
  -- space is still there in the next. A library that caches the pages it
  -- found (GM Party, GM Bestiary, GM Maps) would otherwise answer the DM
  -- space with what it read in Adventure, and the two builds would differ.
  gm, gmbook, spaceSwitcher, chapterNav, kb, gmb, party, bestiary, maps, sheets =
    nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
  for name, text in pairs(FIXTURES[layout]) do H.pages[name] = text end
  clearPlay(layout, H.pages)
  for _, lib in ipairs(LIBS[layout]) do
    local chunk, err = load(lib.source, "=" .. lib.name)
    if not chunk then error("load " .. lib.name .. ": " .. err) end
    chunk()
  end
end
