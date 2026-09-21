-- Prepended to every `instance.py script` request. Helpers for driving the
-- real headless client: open a page, read what it drew, click, wait.
-- Arguments cross into JavaScript percent-encoded, so any label is safe.
T = {}

function T.js(src) return js.window.eval(src) end

local function enc(s) return js.window.encodeURIComponent(tostring(s)) end

function T.sleep(ms)
  js.window.eval("new Promise(r => setTimeout(r, " .. math.floor(ms) .. "))")
end

-- Open a page and give its widgets time to draw.
function T.go(page, settle)
  editor.navigate(page)
  for _ = 1, 50 do
    if editor.getCurrentPage() == page then break end
    T.sleep(100)
  end
  T.sleep(settle or 1500)
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
-- `scope`; errors when there is none. Waits `settle` ms afterwards.
function T.click(label, scope, nth, settle)
  local n = js.window.eval("(() => { const bs = Array.from(document.querySelectorAll(decodeURIComponent('"
    .. enc((scope or ".sb-lua-top-widget") .. " button") .. "'))).filter(b => b.innerText.trim() === decodeURIComponent('"
    .. enc(label) .. "')); const b = bs[" .. ((nth or 1) - 1) .. "]; if (!b) return -1; b.click(); return bs.length; })()")
  if n == -1 then error("T.click: no button '" .. label .. "' in " .. (scope or ".sb-lua-top-widget")) end
  T.sleep(settle or 1200)
  return n
end

-- The notifications on screen: { {message=..., actions={...}}, ... }
function T.notes()
  return js.window.eval([[JSON.stringify(Array.from(document.querySelectorAll(".sb-notifications > div"))
    .map(n => ({ kind: n.className, message: (n.querySelector(".sb-notification-message") || n).innerText,
                 actions: Array.from(n.querySelectorAll("button")).map(b => b.innerText) })))]])
end

-- Click an action button (Undo, Reveal, Open...) on the newest notification that has it.
function T.act(name, settle)
  local ok = js.window.eval("(() => { const bs = Array.from(document.querySelectorAll('.sb-notifications button')).filter(b => b.innerText.trim() === decodeURIComponent('"
    .. enc(name) .. "')); const b = bs[bs.length - 1]; if (!b) return false; b.click(); return true; })()")
  if not ok then error("T.act: no notification action '" .. name .. "'") end
  T.sleep(settle or 1200)
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
