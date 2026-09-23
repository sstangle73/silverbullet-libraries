-- Prepended to every `instance.py script` request. Helpers for driving the
-- real headless client: open a page, read what it drew, click, wait.
-- Arguments cross into JavaScript percent-encoded, so any label is safe.
T = {}

function T.js(src) return js.window.eval(src) end

local function enc(s) return js.window.encodeURIComponent(tostring(s)) end

function T.sleep(ms)
  js.window.eval("new Promise(r => setTimeout(r, " .. math.floor(ms) .. "))")
end

-- The browser's clock, in ms.
function T.now() return js.window.eval("Date.now()") end

-- Call check() every `every` ms (default 100) until it gives a true value,
-- and return that value; nil once `timeout` ms (default 15000) are up. An
-- error in check() counts as not yet.
function T.poll(check, timeout, every)
  local deadline = T.now() + (timeout or 15000)
  while true do
    local ok, v = pcall(check)
    if ok and v then return v end
    if T.now() >= deadline then return nil end
    T.sleep(every or 100)
  end
end

-- As T.poll, but an error naming `what` was waited for once the time is up:
--   T.waitUntil(function() return T.page("State/People/Mara") end, "Mara's record", 20000)
function T.waitUntil(check, what, timeout, every)
  local v = T.poll(check, timeout, every)
  if not v then
    error("T.waitUntil: gave up after " .. (timeout or 15000) .. " ms waiting for " .. (what or "a condition"), 2)
  end
  return v
end

-- When the page last changed, in the browser's clock: a node or its text
-- added, removed or rewritten anywhere. The first call starts watching.
function T.lastChange()
  return js.window.eval([[(() => {
    if (!window.__tWatch) {
      window.__tChanged = Date.now();
      window.__tWatch = new MutationObserver(() => { window.__tChanged = Date.now(); });
      window.__tWatch.observe(document.body, { childList: true, characterData: true, subtree: true });
    }
    return window.__tChanged;
  })()]])
end

-- After something done at `since` (a T.now()), wait until the page has
-- changed and then kept still for `quiet` ms (default 400): what the click
-- or the navigation set off has been drawn. A page that doesn't change at
-- all is taken as drawn after 1500 ms. True, or false once `timeout` ms
-- (default 15000) are up, as when a build keeps its progress ring turning:
-- then wait for what the flow needs with T.waitUntil.
function T.settle(since, quiet, timeout)
  quiet = quiet or 400
  return T.poll(function()
    local changed, now = T.lastChange(), T.now()
    return now - changed >= quiet and (changed > since or now - since >= 1500)
  end, timeout, 50) ~= nil
end

-- Open a page and wait for it to draw; `settle` is the stillness that
-- counts as drawn, in ms (T.settle).
function T.go(page, settle)
  T.lastChange()
  local since = T.now()
  editor.navigate(page)
  T.poll(function() return editor.getCurrentPage() == page end, 5000)
  T.settle(since, settle)
  return editor.getCurrentPage()
end

-- Text of every page-top Lua widget (the GM bar, scene bars), joined by ---.
function T.bar()
  return js.window.eval([[Array.from(document.querySelectorAll(".sb-lua-top-widget"))
    .map(e => e.innerText).join("\n---\n")]])
end

-- Text of every page-top view (view.define), with its name.
function T.views()
  return js.window.eval([[Array.from(document.querySelectorAll(".sb-page-widget"))
    .map(e => "[" + (e.dataset.view || "?") + "] " + e.innerText).join("\n---\n")]])
end

-- Labels of the buttons inside `scope` (default: the page-top Lua widgets).
function T.buttons(scope)
  return js.window.eval("JSON.stringify(Array.from(document.querySelectorAll(decodeURIComponent('"
    .. enc((scope or ".sb-lua-top-widget") .. " button") .. "'))).map(b => b.innerText.trim()))")
end

-- Click the nth (default first) button labelled exactly `label` inside
-- `scope`; errors when there is none. Then waits for the page to settle
-- (T.settle, `settle` ms of stillness).
function T.click(label, scope, nth, settle)
  T.lastChange()
  local since = T.now()
  local n = js.window.eval("(() => { const bs = Array.from(document.querySelectorAll(decodeURIComponent('"
    .. enc((scope or ".sb-lua-top-widget") .. " button") .. "'))).filter(b => b.innerText.trim() === decodeURIComponent('"
    .. enc(label) .. "')); const b = bs[" .. ((nth or 1) - 1) .. "]; if (!b) return -1; b.click(); return bs.length; })()")
  if n == -1 then error("T.click: no button '" .. label .. "' in " .. (scope or ".sb-lua-top-widget")) end
  T.settle(since, settle)
  return n
end

-- The notifications on screen: { {message=..., actions={...}}, ... }
function T.notes()
  return js.window.eval([[JSON.stringify(Array.from(document.querySelectorAll(".sb-notifications > div"))
    .map(n => ({ kind: n.className, message: (n.querySelector(".sb-notification-message") || n).innerText,
                 actions: Array.from(n.querySelectorAll("button")).map(b => b.innerText) })))]])
end

-- Click an action button (Undo, Reveal, Open...) on the newest notification
-- that has it, and wait for the page to settle (T.settle).
function T.act(name, settle)
  T.lastChange()
  local since = T.now()
  local ok = js.window.eval("(() => { const bs = Array.from(document.querySelectorAll('.sb-notifications button')).filter(b => b.innerText.trim() === decodeURIComponent('"
    .. enc(name) .. "')); const b = bs[bs.length - 1]; if (!b) return false; b.click(); return true; })()")
  if not ok then error("T.act: no notification action '" .. name .. "'") end
  T.settle(since, settle)
end

-- Dismiss every notification, so the next T.notes() shows only new ones.
function T.clearNotes()
  js.window.eval([[document.querySelectorAll(".sb-notifications > div").forEach(n => n.remove())]])
end

-- A page's text, or nil when it does not exist.
function T.page(name)
  local ok, text = pcall(space.readPage, name)
  if ok then return text end
  return nil
end

-- Scroll through the open page and collect the text of every rendered Lua
-- widget and every Lua error, since CodeMirror only draws what is on screen.
function T.scan()
  return js.window.eval([[(async () => {
    const sc = document.querySelector(".cm-scroller");
    const seen = new Map(); const errors = new Set();
    const grab = () => {
      document.querySelectorAll(".sb-lua-directive-inline, .sb-lua-directive-block, .sb-lua-wrapper, .sb-lua-top-widget")
        .forEach(e => { const t = e.innerText.trim(); if (t) seen.set(t, true); });
      document.querySelectorAll(".cm-content, .sb-lua-top-widget").forEach(e => {
        for (const m of e.innerText.matchAll(/Lua error[^\n]*/g)) errors.add(m[0]); });
    };
    sc.scrollTop = 0; await new Promise(r => setTimeout(r, 300)); grab();
    for (let i = 0; i < 400 && sc.scrollTop + sc.clientHeight < sc.scrollHeight; i++) {
      sc.scrollTop += sc.clientHeight * 0.8; await new Promise(r => setTimeout(r, 120)); grab();
    }
    sc.scrollTop = 0;
    return JSON.stringify({ widgets: Array.from(seen.keys()), errors: Array.from(errors) });
  })()]])
end

-- Evaluate every ${...} on a page the way the editor finds them, in the
-- page's own context, and return { {expr=, ok=, value=} ... }. Uses the
-- widget's markdown face when there is one.
function T.directives(name)
  local text = space.readPage(name)
  local tree = markdown.parseMarkdown(text)
  local found = {}
  local function walk(n)
    if n.type == "LuaDirective" then
      found[#found + 1] = text:sub(n.from + 3, n.to - 1)
    end
    for _, c in ipairs(n.children or {}) do walk(c) end
  end
  walk(tree)
  local out = {}
  for _, src in ipairs(found) do
    local ok, v = pcall(function()
      return spacelua.evalExpression(spacelua.parseExpression(src), {})
    end)
    local shown = v
    if ok and type(v) == "table" then shown = v.markdown or v.html or "(table)" end
    out[#out + 1] = { expr = src, ok = ok, value = tostring(shown) }
  end
  return out
end
