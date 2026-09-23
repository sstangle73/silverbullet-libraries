-- Mock SilverBullet 2.11 APIs for testing Space Lua libraries under plain Lua 5.4.
-- Everything observable lands in the global H, which reset() rebuilds.

NIL = setmetatable({}, { __tostring = function() return "NIL" end })

function string.startsWith(s, p) return s:sub(1, #p) == p end
function string.endsWith(s, p) return p == "" or s:sub(-#p) == p end

-- The tables config.get hands back as JavaScript objects rather than arrays:
-- what a table with no list part becomes on its way into SilverBullet's
-- config (see jsify, below). Space Lua reads a JavaScript object's fields as
-- a table's, but table.includes throws on one.
local JS_OBJECTS = setmetatable({}, { __mode = "k" })

-- As SilverBullet 2.11's (client/space_lua/stdlib/table.ts): false for a
-- value JavaScript counts as false (nil, false, 0, ""), a search of every
-- value of a Lua table, its named keys' as well as its list's, and an error
-- for anything else: a string, a number, or a JavaScript object, such as
-- config.get gives for a table of named keys.
function table.includes(t, v)
  if t == nil or t == false or t == 0 or t == "" then return false end
  if type(t) ~= "table" or JS_OBJECTS[t] then
    error("Cannot use includes on a non-table or non-array value", 2)
  end
  for _, x in pairs(t) do
    if x == v then return true end
  end
  return false
end

-- Space Lua's string.rep counts with JavaScript's < and <=, and a float
-- that holds a whole number is an object to JavaScript: string.rep("a", 4 / 2)
-- gives "" there, where Lua 5.4 gives "aa", and a count of 2.5 gives three
-- copies where Lua 5.4 raises. Either hides a count that went wrong, so a
-- float count is an error here.
local rep = string.rep
function string.rep(s, n, sep)
  if math.type(n) == "float" then
    local gives = (n == math.floor(n) or n <= 0) and '""' or (math.ceil(n) .. " copies")
    error("string.rep: a count of " .. tostring(n) .. " is a float, which Space Lua repeats as " ..
          gives .. "; make it a whole number", 2)
  end
  return rep(s, n, sep)
end

local function fresh()
  return {
    -- A client always has a page open, the index page when nothing else is.
    pages = {}, current = "index", writes = {}, deleted = {}, navigations = {},
    notifications = {}, progress = {}, prompts = {}, promptsAsked = {}, confirms = {}, confirmsAsked = {},
    picks = {}, filterBoxes = {}, clipboard = nil, clipboardFails = false, opened = {},
    reloads = 0, saves = 0, refreshes = 0, commands = {}, listeners = {}, printed = {},
    views = {}, viewOrder = {}, prefix = "/dm/", files = {}, modified = {},
    responses = {}, fetched = {},
    -- What the mocks saw that SilverBullet lets pass but gets wrong, such as
    -- a config.set that loses keys: a test with any left at its end fails.
    warnings = {},
    -- config.define's schemas, as Config.schemas holds them
    schemas = { type = "object", properties = {} },
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
-- A file's contents, as 2.11 gives them: bytes, never text, which
-- encoding.utf8Decode makes text. Bytes here are { bytes = text }; a test
-- gives a file its contents as H.files[path].data, text or bytes. A page
-- reads as its text, as bytes.
function space.readFile(name)
  if H.failMeta and H.failMeta[name] then error(H.failMeta[name]) end
  if name:endsWith(".md") and H.pages[name:sub(1, -4)] ~= nil then
    return { bytes = H.pages[name:sub(1, -4)] }
  end
  local f = H.files[name]
  if f == nil or f.data == nil then error("Not found: " .. name) end
  if type(f.data) == "string" then return { bytes = f.data } end
  return f.data
end
-- 2.11's encoding library, for the bytes above.
encoding = {
  utf8Decode = function(data)
    assert(type(data) == "table" and type(data.bytes) == "string", "utf8Decode needs bytes")
    return data.bytes
  end,
  utf8Encode = function(s)
    assert(type(s) == "string", "utf8Encode needs a string")
    return { bytes = s }
  end,
}
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
-- A dotted key is a path, as SilverBullet's cleanupJSON reads it
-- (plug-api/lib/json.ts): the share.uri, share.hash and share.mode that
-- Library: Install writes read as one table, share.
local PARSED = {}
local function frontmatterOf(text)
  local fm = PARSED[text]
  if fm then return fm end
  fm = {}
  local head = text:match("^%-%-%-\n(.-)\n%-%-%-")
  if head then
    for line in (head .. "\n"):gmatch("([^\n]*)\n") do
      local k, v = line:match("^([%w_%-%.]+):%s*(.-)%s*$")
      if k and k ~= "name" then
        local target, parts = fm, {}
        for part in k:gmatch("[^%.]+") do parts[#parts + 1] = part end
        for i = 1, #parts - 1 do
          if type(target[parts[i]]) ~= "table" then target[parts[i]] = {} end
          target = target[parts[i]]
        end
        target[parts[#parts]] = parseValue(v)
      end
    end
  end
  PARSED[text] = fm
  return fm
end

-- Whether a page's frontmatter tags hold this tag: a list, or one tag alone.
local function tagged(fm, tag)
  local tags = fm.tags
  if type(tags) == "table" then
    for _, t in ipairs(tags) do if t == tag then return true end end
    return false
  end
  return tags == tag
end

index = {}
-- index.pages(tag), as SilverBullet 2.11 has it: every page, or with a tag,
-- the pages that carry it as well, such as "meta/library".
function index.pages(tag)
  local out = {}
  for name, text in pairs(H.pages) do
    local fm = frontmatterOf(text)
    if tag == nil or tagged(fm, tag) then
      local obj = { name = name }
      for k, v in pairs(fm) do obj[k] = v end
      -- As in SilverBullet's indexPage: the page's own attributes win over its
      -- frontmatter, so a frontmatter "size" reads as the size in bytes.
      obj.name, obj.size, obj.perm, obj.contentType = name, #text, "rw", "text/markdown"
      obj.created, obj.lastModified, obj.tag = "2026-09-18T00:00:00", "2026-09-18T00:00:00", "page"
      out[#out + 1] = obj
    end
  end
  table.sort(out, function(a, b) return a.name < b.name end)
  return out
end

-- SLIQ tests `where` the way JavaScript does (query_collection.ts), so 0 and
-- "" fail it as well as nil and false.
local function truthy(v) return v ~= nil and v ~= false and v ~= 0 and v ~= "" end

-- Target of the query[[...]] transpiler in run.py. It orders as SLIQ does
-- (query_collection.ts, sortKeyCompare): a stable merge sort, so rows that
-- tie on every key keep the order they came in, and a nil sorts after every
-- value ascending and before every value descending. Values compare as Lua
-- compares them; for strings that is JavaScript's order too, but for a
-- character beyond U+FFFF, which JavaScript puts before U+E000-U+FFFF.
function __liq(src, where, orders, select, limit)
  local rows = {}
  for _, p in ipairs(src()) do
    if not where or truthy(where(p)) then rows[#rows + 1] = p end
  end
  if orders and #orders > 0 then
    local keyed = {}
    for i, p in ipairs(rows) do
      local keys = {}
      for j, o in ipairs(orders) do keys[j] = o.fn(p) end
      keyed[i] = { row = p, keys = keys, at = i }
    end
    table.sort(keyed, function(a, b)
      for j, o in ipairs(orders) do
        local x, y = a.keys[j], b.keys[j]
        if (x == nil) ~= (y == nil) then
          if o.desc then return x == nil end
          return y == nil
        end
        if x ~= y then
          if o.desc then return x > y end
          return x < y
        end
      end
      return a.at < b.at
    end)
    for i, k in ipairs(keyed) do rows[i] = k.row end
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
-- SilverBullet's one progress indicator, shared by syncing and indexing. A
-- call with no percentage clears it.
function editor.showProgress(kind, percentage)
  assert(kind == "sync" or kind == "index", "progress kind must be sync or index")
  H.progress[#H.progress + 1] = { kind = kind, percentage = percentage }
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
-- As in SilverBullet 2.11 (client/plugos/syscalls/editor.ts): a copy that
-- fails, as one does when the page has lost focus, is caught there and shown
-- in a notification of SilverBullet's own, and the call returns as usual.
-- H.clipboardFails makes it fail.
function editor.copyToClipboard(text)
  if H.clipboardFails then
    H.notifications[#H.notifications + 1] = { kind = "info", message = "Could not copy to clipboard: " ..
      "NotAllowedError: Failed to execute 'writeText' on 'Clipboard': Document is not focused." }
    return
  end
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
-- The keys of a table in a fixed order, numbers first: pairs() promises
-- none, and a message or a check that depends on it would differ run to run.
local function sortedKeys(t)
  local keys = {}
  for k in pairs(t) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b)
    if type(a) ~= type(b) then return type(a) == "number" end
    return a < b
  end)
  return keys
end

-- The named keys of a table that also has a list part: what LuaTable.toJS
-- drops, since a table with a list part becomes a JavaScript array.
local function droppedKeys(v)
  if type(v) ~= "table" or #v == 0 then return {} end
  local out = {}
  for _, k in ipairs(sortedKeys(v)) do
    if math.type(k) ~= "integer" or k < 1 or k > #v then out[#out + 1] = tostring(k) end
  end
  return out
end

-- What a Lua table becomes on its way into SilverBullet's config
-- (LuaTable.toJS): with an array part it keeps only that, so a table that
-- mixes a list and named keys loses the keys, and the mocks warn, which
-- fails the test. A table with no list part, an empty one included, is a
-- JavaScript object, which table.includes throws on. Functions pass through.
local function jsify(v, where, call)
  if type(v) ~= "table" then return v end
  local out = {}
  if #v > 0 then
    local lost = droppedKeys(v)
    if #lost > 0 then
      H.warnings[#H.warnings + 1] = (call or "config.set") .. ": " .. where ..
        " mixes a list with named keys (" .. table.concat(lost, ", ") ..
        "), and SilverBullet keeps only the list"
    end
    for i = 1, #v do out[i] = jsify(v[i], where .. "[" .. i .. "]", call) end
  else
    for k, x in pairs(v) do out[k] = jsify(x, where .. "." .. tostring(k), call) end
    JS_OBJECTS[out] = true
  end
  return out
end

-------------------------------------------------------------- jsonschema
-- jsonschema.validateObject as SilverBullet 2.11 has it
-- (client/plugos/syscalls/jsonschema.ts): @cfworker/json-schema's validate,
-- draft 7, stopping at a property's first failure, over the value as
-- JavaScript sees it, and its errors in the same words, the wrappers of
-- properties left out, each at its path ("spaces.0.url": a list counts from
-- 0 there). The keywords the libraries' schemas and widget.new's use: type,
-- enum, anyOf, required, properties, additionalProperties and items. Where
-- two properties fail, SilverBullet reports the first as the schema was
-- written, and this the first by name: Lua keeps no order of keys.

-- A value's type as JavaScript sees it once the table is converted: a
-- table with a list part is an array, any other an object, and a function
-- null (stripFunctions).
local function jsType(v)
  if v == nil or type(v) == "function" then return "null" end
  if type(v) == "table" then return #v > 0 and "array" or "object" end
  return type(v)
end

local function jsonText(v)
  if type(v) == "string" then return '"' .. v .. '"' end
  if type(v) == "table" then
    local parts = {}
    for i, x in ipairs(v) do parts[i] = jsonText(x) end
    return "[" .. table.concat(parts, ",") .. "]"
  end
  return tostring(v)
end

local function pointer(at, key)
  local escaped = tostring(key):gsub("~", "~0"):gsub("/", "~1")
  return at .. "/" .. escaped
end

local function validate(value, schema, at, errors)
  if schema == true then return true end
  if schema == false then
    errors[#errors + 1] = { at = at, keyword = "false", error = "False boolean schema." }
    return false
  end
  local before, kind = #errors, jsType(value)
  local want = schema.type
  local function typeError(expected)
    errors[#errors + 1] = { at = at, keyword = "type",
      error = 'Instance type "' .. kind .. '" is invalid. Expected "' .. expected .. '".' }
  end
  if type(want) == "table" then
    local fine = false
    for _, w in ipairs(want) do
      if w == kind or (w == "integer" and kind == "number" and value % 1 == 0) then fine = true end
    end
    if not fine then typeError(table.concat(want, '", "')) end
  elseif want == "integer" then
    if kind ~= "number" or value % 1 ~= 0 then typeError("integer") end
  elseif want ~= nil and kind ~= want then
    typeError(want)
  end
  if schema.enum then
    local found = false
    for _, e in ipairs(schema.enum) do
      if e == value then found = true end
    end
    if not found then
      errors[#errors + 1] = { at = at, keyword = "enum",
        error = "Instance does not match any of " .. jsonText(schema.enum) .. "." }
    end
  end
  if schema.anyOf then
    local any, sub = false, {}
    for _, s in ipairs(schema.anyOf) do
      local e = {}
      if validate(value, s, at, e) then any = true end
      for _, x in ipairs(e) do sub[#sub + 1] = x end
    end
    if not any then
      errors[#errors + 1] = { at = at, keyword = "anyOf", error = "Instance does not match any subschemas." }
      for _, x in ipairs(sub) do errors[#errors + 1] = x end
    end
  end
  if kind == "object" then
    for _, key in ipairs(schema.required or {}) do
      if value[key] == nil then
        errors[#errors + 1] = { at = at, keyword = "required",
          error = 'Instance does not have required property "' .. key .. '".' }
      end
    end
    local evaluated, stop = {}, false
    for _, key in ipairs(sortedKeys(schema.properties or {})) do
      if value[key] ~= nil then
        local e = {}
        if validate(value[key], schema.properties[key], pointer(at, key), e) then
          evaluated[key] = true
        else
          errors[#errors + 1] = { at = at, keyword = "properties", error = 'Property "' .. key .. '" does not match schema.' }
          for _, x in ipairs(e) do errors[#errors + 1] = x end
          stop = true
          break
        end
      end
    end
    if not stop and schema.additionalProperties ~= nil then
      for _, key in ipairs(sortedKeys(value)) do
        if not evaluated[key] then
          local e = {}
          if not validate(value[key], schema.additionalProperties, pointer(at, key), e) then
            errors[#errors + 1] = { at = at, keyword = "additionalProperties",
              error = 'Property "' .. tostring(key) .. '" does not match additional properties schema.' }
            for _, x in ipairs(e) do errors[#errors + 1] = x end
          end
        end
      end
    end
  elseif kind == "array" and schema.items ~= nil then
    for i = 1, #value do
      local e = {}
      if not validate(value[i], schema.items, pointer(at, i - 1), e) then
        errors[#errors + 1] = { at = at, keyword = "items", error = "Items did not match schema." }
        for _, x in ipairs(e) do errors[#errors + 1] = x end
        break
      end
    end
  end
  return #errors == before
end

-- The errors as SilverBullet words them: each at its path, dotted, and the
-- "Property ... does not match schema." wrappers left out.
local function formatErrors(errors)
  local leaves = {}
  for _, e in ipairs(errors) do
    if e.keyword ~= "properties" then leaves[#leaves + 1] = e end
  end
  if #leaves == 0 then leaves = errors end
  local out = {}
  for _, e in ipairs(leaves) do
    local path = e.at == "#" and "" or (e.at:sub(3):gsub("/", "."))
    out[#out + 1] = path ~= "" and (path .. ": " .. e.error) or e.error
  end
  return table.concat(out, ", ")
end

jsonschema = {}
function jsonschema.validateObject(schema, value)
  if value == nil then return 'Instances of "undefined" type are not supported.' end
  local errors = {}
  if validate(value, schema, "#", errors) then return nil end
  return formatErrors(errors)
end

-------------------------------------------------------------- config

-- config.define's rule for a schema (client/config.ts, isValidJsonSchema)
local SCHEMA_TYPES = { string = true, number = true, integer = true, boolean = true,
                       object = true, array = true, null = true }

local function splitPath(path)
  local parts = {}
  for part in path:gmatch("[^%.]+") do parts[#parts + 1] = part end
  return parts
end

-- The schema that governs a path, as Config.getSchemaAtPath finds it: one
-- defined there, with a type.
local function schemaAt(parts, last)
  local current = H.schemas
  for i = 1, last do
    if not current.properties or not current.properties[parts[i]] then return nil end
    current = current.properties[parts[i]]
  end
  return current.type and current or nil
end

config = {}
function config.get(path, default)
  local v = getPath(H.config, path)
  -- the default crosses into JavaScript as well, and comes back as it went
  if v == nil then return jsify(default, path, "config.get's default") end
  return v
end
function config.has(path)
  return getPath(H.config, path) ~= nil
end
-- Like Config.set: a dotted path creates the tables on the way and replaces
-- whatever is at the end of it. Then, as there, the value is checked against
-- the schema config.define gave its path, or the nearest one above it, and a
-- value of the wrong shape raises, with the value already set.
function config.set(path, value)
  if type(path) == "table" then
    for k, v in pairs(path) do config.set(k, v) end
    return
  end
  local parts = splitPath(path)
  local t = H.config
  for i = 1, #parts - 1 do
    if type(t[parts[i]]) ~= "table" then t[parts[i]] = {} end
    t = t[parts[i]]
  end
  t[parts[#parts]] = jsify(value, path)
  for i = #parts, 1, -1 do
    local schema = schemaAt(parts, i)
    if schema then
      local at = table.concat(parts, ".", 1, i)
      local v = getPath(H.config, at)
      if v ~= nil then
        local err = jsonschema.validateObject(schema, v)
        if err then error("Validation error for " .. at .. ":> " .. err, 2) end
      end
      break
    end
  end
end
-- Like Config.define: the schema goes in at its path, replacing any there.
function config.define(key, schema)
  local kind = type(schema) == "table" and schema.type
  if schema == nil or (type(schema) ~= "table" and type(schema) ~= "boolean") then
    error("Invalid schema for key " .. tostring(key) .. ": schema must be an object or boolean", 2)
  end
  for _, t in ipairs(type(kind) == "table" and kind or { kind or nil }) do
    if not SCHEMA_TYPES[t] then
      error("Invalid schema for key " .. tostring(key) .. ": schema.type must be one of " ..
            "string, number, integer, boolean, object, array, null", 2)
    end
  end
  local parts = splitPath(key)
  local current = H.schemas
  for i = 1, #parts - 1 do
    current.properties[parts[i]] = current.properties[parts[i]] or { type = "object", properties = {} }
    current = current.properties[parts[i]]
  end
  current.properties[parts[#parts]] = schema
  if type(schema) == "table" and schema.default ~= nil and not config.has(key) then
    config.set(key, schema.default)
  end
end
function config.getSchemas() return H.schemas end

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

-- SilverBullet 2.11's widgetSchema (Library/Std/APIs/Widget), which its
-- widget.new checks each spec against with jsonschema.validateObject and
-- raises on: markdown a string, html a string or a DOM node, cssClasses a
-- list of strings (an empty table is a JavaScript object, not a list),
-- display "block" or "inline", events a table, sandbox a boolean, script a
-- string.
local WIDGET_SCHEMA = {
  type = "object",
  properties = {
    markdown = { type = "string" },
    html = { anyOf = { { type = "object" }, { type = "string" } } },
    cssClasses = { type = "array", items = { type = "string" } },
    display = { type = "string", enum = { "block", "inline" } },
    events = { type = "object", additionalProperties = true },
    sandbox = { type = "boolean" },
    script = { type = "string" },
  },
}

widget = {}
function widget.new(spec)
  local err = jsonschema.validateObject(WIDGET_SCHEMA, spec)
  if err then error("widget.new: " .. err, 2) end
  -- SilverBullet passes a key it doesn't know, and ignores it; a misspelt
  -- one is a bug all the same, so the mocks stop it.
  local allowed = { markdown = true, html = true, cssClasses = true, display = true,
                    events = true, sandbox = true, script = true, _isWidget = true }
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

-- net.proxyFetch answers from H.responses, by URL, and counts what it was
-- asked for in H.fetched; anything else is a 404, as D&D Beyond gives for a
-- character that isn't public. SilverBullet 2.11's server proxy answers ok
-- whenever D&D Beyond answered at all, with D&D Beyond's own status, so ok
-- false is only ever the server's own failure.
net = {}
function net.proxyFetch(url, options)
  H.fetched[#H.fetched + 1] = url
  local r = H.responses[url]
  if r == nil then return { ok = true, status = 404 } end
  if type(r) == "function" then return r(url, options) end
  return r
end

-- markdown.markdownToHtml, reduced to a wrapper: the tests read the
-- Markdown it was given, not a rendering of it.
function markdown.markdownToHtml(text)
  assert(type(text) == "string", "markdownToHtml needs a string")
  return '<div class="md">' .. text .. "</div>"
end

-- yaml.parse, by PyYAML through run.py, read as js-yaml reads it (YAML 1.2's
-- core schema: `yes` and `on` stay words, 1:30 stays text) and handed to Lua
-- the way SilverBullet hands js-yaml's result over: a map's keys are always
-- strings, as a JavaScript object's are, so a spell list's {1: [...]} is
-- keyed "1", never 1.
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

-------------------------------------------------------------- globals

-- The globals as the harness left them: the mocks, run.py's tables, the
-- framework and every test file, taken once they are all loaded and before
-- any library runs (runAll takes it, or the first reset). reset() puts it
-- back, so every global a library made is gone, and so is any a test left.
-- The mocks' own tables are put back field by field as well, so a mock a
-- test replaced and failed to restore is the harness's own again.
local SNAPSHOT
local RESTORED = { "space", "index", "editor", "config", "actionButton", "command", "event",
  "widget", "dom", "markdown", "net", "yaml", "spacelua", "codeWidget", "system", "js",
  "icon", "view", "jsonschema", "string", "table", "math", "os" }

function snapshotGlobals()
  if SNAPSHOT then return end
  SNAPSHOT = { globals = {}, fields = {} }
  for k, v in pairs(_G) do SNAPSHOT.globals[k] = v end
  for _, name in ipairs(RESTORED) do
    local t = _G[name]
    if type(t) == "table" then
      local copy = {}
      for k, v in pairs(t) do copy[k] = v end
      SNAPSHOT.fields[name] = copy
    end
  end
end

local function restoreGlobals()
  for k in pairs(_G) do
    if SNAPSHOT.globals[k] == nil then _G[k] = nil end
  end
  for k, v in pairs(SNAPSHOT.globals) do _G[k] = v end
  for name, copy in pairs(SNAPSHOT.fields) do
    local t = SNAPSHOT.globals[name]
    for k in pairs(t) do
      if copy[k] == nil then t[k] = nil end
    end
    for k, v in pairs(copy) do t[k] = v end
  end
end

-- Space Lua has no utf8 table, so a library that reaches for it while it
-- loads fails there: it is nil here too while the blocks run.
local function withoutUtf8(fn)
  local lib = utf8
  utf8 = nil
  local good, err = pcall(fn)
  utf8 = lib
  if not good then error(err, 0) end
end

-- Blocks as reset() and loadLibrary() run them: each a chunk of its own,
-- in the order given, so a local in one block is never seen in the next.
local function runBlocks(blocks)
  withoutUtf8(function()
    for _, lib in ipairs(blocks) do
      local chunk, err = load(lib.source, "=" .. lib.name)
      if chunk then
        local good, e = pcall(chunk)
        if not good then chunk, err = nil, tostring(e) end
      end
      if not chunk then error("load " .. lib.name .. " (" .. tostring(lib.ref) .. "): " .. err, 0) end
    end
  end)
end

-- A library from src/ that no space installs, such as RecurringTasks, run
-- into the current space as a copy at Library/Storie/<name> would run: its
-- blocks in SilverBullet's order, through the query rewrite, by run.py.
function loadLibrary(name)
  assert(SRC[name], "src/ has no " .. tostring(name))
  local blocks = __library_blocks(name)
  assert(#blocks > 0, name .. " has no space-lua block")
  runBlocks(blocks)
end

function reset(layout)
  snapshotGlobals()
  -- What the libraries printed, and what the mocks warned of, outlive a
  -- reset in the middle of a test, for runAll to check at its end; runAll
  -- clears H before each test.
  local printed, warnings = H and H.printed, H and H.warnings
  -- Every library global goes, so nothing a library remembered in one
  -- space is still there in the next. A library that caches the pages it
  -- found (GM Party, GM Bestiary, GM Maps) would otherwise answer the DM
  -- space with what it read in Adventure, and the two builds would differ.
  restoreGlobals()
  H = fresh()
  H.printed = printed or H.printed
  H.warnings = warnings or H.warnings
  H.prefix = "/" .. layout .. "/"
  for name, text in pairs(FIXTURES[layout]) do H.pages[name] = text end
  clearPlay(layout, H.pages)
  -- Each block a chunk of its own, in SilverBullet's order (run.py).
  runBlocks(LIBS[layout])
end
