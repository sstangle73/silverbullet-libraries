---
tags: meta/library
name: "Library/Storie/Space Switcher"
description: "A strip across the top of every page that names the space you are in and links to your other spaces, for a server with several SilverBullet spaces."
author: "Steven Storie"
version: "1.0.0"
---

# Space Switcher

A strip across the top of every page that says which space you are in and takes you to the others. It is for a server with several SilverBullet spaces, including spaces that hold others as folders.

- **Every space you list** gets a tab with its name, and an icon and colour of its own. The one you are in is filled in; the others link to their home pages.
- **Nested spaces.** Where one space is also a folder of another, *This page in …* at the right opens the page you are on in the other space.
- **A space can keep to itself.** List only that space in its own settings: its strip shows just its own tab, and a link you choose, such as the server's list of spaces.

Every tab writes its name out, so its colour is never the only cue. The default colours are violet, sky, orange, yellow and pink, which stay distinct for red-green colour blindness and in grayscale.

## Setting it up

Install this page in every space, and list the spaces in a `space-lua` block on each space's `CONFIG` page:

    config.set("spaceSwitcher", {
      spaces = {
        { name = "Notes",   url = "/notes/",   icon = "edit-3" },
        { name = "Journal", url = "/journal/", folder = "Journal/", icon = "calendar" },
        { name = "Work",    url = "/work/",    icon = "briefcase", color = "#e65100" },
      },
    })

| Key | Means |
|---|---|
| `name` | What the tab says |
| `url` | The space's address: a path on this server, such as `/notes/`, or a full `https://` address |
| `folder` | For a space that is also a folder of another space, that folder, such as `Journal/`. The other space is the first one listed without a `folder` |
| `icon` | A [Feather](https://feathericons.com) icon name |
| `color` | The tab's fill in its own space, as a hex colour such as `#311b92`. Without one, a space takes the default colour for its place in the list |
| `textColor` | The text on that fill. Without one, black or white, whichever reads better; give one when `color` isn't hex |

Beside `spaces`, a `directory` puts a link at the right of the strip:

    directory = { name = "All spaces", url = "/.dashboard", title = "The spaces your account can open" },

`/.dashboard` is the multi-space server's list of spaces. At an address that isn't one of the listed spaces, the strip stays hidden.

## This page in …

From a space that holds others as folders, a page inside one of those folders opens in that space. From a space that is a folder of another, any page opens in that other space. The link appears only when both spaces are in the list.

## Spaces inside spaces

A space runs only the `space-lua` inside it, so every space needs this page and its own settings. A space that holds others as folders runs their copies as well. Its copies of this page all define the same view, so it still draws one strip. Its copies of the settings all run too, and the last to load wins, so give every space the same list.

A space that keeps to itself has a shorter list on purpose. Start its block with `-- priority: 1`: blocks load highest priority first, and a block without one counts as 0, so in the space that holds it, the full list loads later and replaces the short one. Give every space its `color` in that case: a default colour goes by place in the list, and the short list's places differ.

## Implementation

```space-lua
-- priority: 20
spaceSwitcher = spaceSwitcher or {}

-- Fills for spaces without a colour of their own, in list order. Violet, sky,
-- orange, yellow and pink stay apart for red-green colour blindness and in
-- grayscale; two blues or two reds would not.
spaceSwitcher.palette = { "#311b92", "#4fc3f7", "#e65100", "#fff176", "#ad1457" }

function spaceSwitcher.spaces()
  return config.get("spaceSwitcher.spaces", {})
end

function spaceSwitcher.origin()
  return system.getBaseURI():match("^(https?://[^/]+)") or ""
end

-- A full URL: a path is taken to be on this server.
function spaceSwitcher.resolve(url)
  if url:match("^%a[%w+.-]*://") then return url end
  if not url:startsWith("/") then url = "/" .. url end
  return spaceSwitcher.origin() .. url
end

local function slashed(path)
  if path == "" or path:endsWith("/") then return path end
  return path .. "/"
end

-- A space's home, ending in a slash as SilverBullet's base URI does.
function spaceSwitcher.address(space)
  return slashed(spaceSwitcher.resolve(space.url or "/"))
end

-- The folder a space is served from inside another; "" for none.
local function folderOf(space)
  return slashed(space.folder or "")
end

-- The space this client serves, and its place in the list.
function spaceSwitcher.current()
  local base = slashed(system.getBaseURI())
  for i, space in ipairs(spaceSwitcher.spaces()) do
    if spaceSwitcher.address(space) == base then return space, i end
  end
end

-- Page names go into URLs the way SilverBullet writes them: the browser's
-- encodeURIComponent, with the slashes put back. (A Lua version would get
-- non-ASCII names wrong: Space Lua strings are JavaScript strings, not bytes.)
function spaceSwitcher.encode(page)
  return (js.window.encodeURIComponent(page):gsub("%%2F", "/"))
end

function spaceSwitcher.url(space, page)
  local url = spaceSwitcher.address(space)
  if page and page ~= "index" then url = url .. spaceSwitcher.encode(page) end
  return url
end

-- The same page in the other space that holds it: from a space that holds
-- others as folders, the one whose folder the page is in (the deepest, if
-- folders nest); from a space inside another, that other space.
function spaceSwitcher.counterpart(here, page)
  local folder = folderOf(here)
  if folder ~= "" then
    for _, space in ipairs(spaceSwitcher.spaces()) do
      if folderOf(space) == "" then return space, folder .. page end
    end
    return nil
  end
  local best, bestFolder = nil, ""
  for _, space in ipairs(spaceSwitcher.spaces()) do
    local candidate = folderOf(space)
    if #candidate > #bestFolder and page:startsWith(candidate) then
      best, bestFolder = space, candidate
    end
  end
  if best then return best, page:sub(#bestFolder + 1) end
end

-- Black or white, whichever has more contrast on a hex fill; nil for a
-- colour written any other way.
function spaceSwitcher.textOn(fill)
  local r, g, b = fill:match("^#(%x%x)(%x%x)(%x%x)$")
  if not r then
    r, g, b = fill:match("^#(%x)(%x)(%x)$")
    if not r then return nil end
    r, g, b = r .. r, g .. g, b .. b
  end
  local weights, lum = { 0.2126, 0.7152, 0.0722 }, 0
  for i, part in ipairs({ r, g, b }) do
    local c = tonumber(part, 16) / 255
    if c <= 0.04045 then c = c / 12.92 else c = ((c + 0.055) / 1.055) ^ 2.4 end
    lum = lum + weights[i] * c
  end
  -- Contrast with black is (L + 0.05) / 0.05, and with white 1.05 / (L + 0.05).
  if (lum + 0.05) / 0.05 >= 1.05 / (lum + 0.05) then return "#000000" end
  return "#ffffff"
end

local function colours(space, i)
  local palette = spaceSwitcher.palette
  local fill = space.color or palette[(i - 1) % #palette + 1]
  return fill, space.textColor or spaceSwitcher.textOn(fill) or "#000000"
end

local function escape(text)
  return (tostring(text):gsub('[&<>"]', function(c)
    return ({ ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;", ['"'] = "&quot;" })[c]
  end))
end

local function iconFor(name)
  if not name then return "" end
  local ok, svg = pcall(function() return icon.feather(name) end)
  if not ok or not svg then return "" end
  -- One line, so the strip stays a single block of HTML.
  return (svg:gsub("%s*\n%s*", " "))
end

local function tab(space, i, here)
  local name = escape(space.name or "?")
  local body = iconFor(space.icon) .. "<span>" .. name .. "</span>"
  if here then
    local fill, text = colours(space, i)
    return '<span class="space-switcher-tab space-switcher-here" data-space="' .. name ..
           '" style="--space-switcher-fill: ' .. escape(fill) .. "; --space-switcher-text: " ..
           escape(text) .. '" aria-current="page" title="You are in the ' .. name .. ' space">' ..
           body .. "</span>"
  end
  return '<a class="space-switcher-tab" data-space="' .. name .. '" href="' ..
         escape(spaceSwitcher.url(space)) .. '" title="Go to the ' .. name .. ' space">' .. body .. "</a>"
end

-- The strip, as one line of HTML; nil at an address that is none of the spaces.
function spaceSwitcher.html(page)
  local here, at = spaceSwitcher.current()
  if not here then return nil end
  page = page or editor.getCurrentPage()
  local parts, links = {}, {}
  for i, space in ipairs(spaceSwitcher.spaces()) do
    parts[#parts + 1] = tab(space, i, i == at)
  end
  local other, otherPage
  if page then other, otherPage = spaceSwitcher.counterpart(here, page) end
  if other then
    local name = escape(other.name or "?")
    links[#links + 1] = '<a href="' .. escape(spaceSwitcher.url(other, otherPage)) .. '" title="Open ' ..
      escape(otherPage) .. " in the " .. name .. ' space">This page in ' .. name .. " ↗</a>"
  end
  local directory = config.get("spaceSwitcher.directory", nil)
  if directory and directory.url then
    local title = directory.title and (' title="' .. escape(directory.title) .. '"') or ""
    links[#links + 1] = '<a href="' .. escape(spaceSwitcher.resolve(directory.url)) .. '"' .. title ..
      ">" .. escape(directory.name or "All spaces") .. " ↗</a>"
  end
  if #links > 0 then
    parts[#parts + 1] = '<span class="space-switcher-links">' .. table.concat(links) .. "</span>"
  end
  return '<div class="space-switcher">' .. table.concat(parts) .. "</div>"
end

view.define {
  name = "spaceSwitcher",
  title = "Spaces",
  command = "Navigate: Space Switcher",
  dock = "page-top",
  defaultOpen = true,
  refreshOn = { "editor:pageLoaded" },
  content = function()
    local ok, html = pcall(spaceSwitcher.html)
    if ok then return html end
    print("Space Switcher: " .. tostring(html))
  end,
}
```

```space-style
/* One slim row: no title strip over this view. */
.sb-page-widget[data-view="spaceSwitcher"] > .sb-page-widget-bar {
  display: none;
}

.sb-page-widget[data-view="spaceSwitcher"] > .sb-page-widget-body {
  padding: 6px 8px;
}

.space-switcher {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 4px 6px;
  font-family: var(--ui-font);
  font-size: 0.9em;
  line-height: 1.4;
}

.space-switcher-tab {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 2px 10px;
  border: 1px solid transparent;
  border-radius: 999px;
  color: inherit;
  text-decoration: none;
}

.space-switcher-tab svg {
  width: 1em;
  height: 1em;
  flex-shrink: 0;
}

a.space-switcher-tab:hover,
a.space-switcher-tab:focus-visible {
  border-color: currentColor;
}

/* The ring keeps a pale fill visible on a light page and a dark one on a dark page. */
.space-switcher-here {
  background: var(--space-switcher-fill);
  border-color: color-mix(in srgb, var(--space-switcher-text) 45%, transparent);
  color: var(--space-switcher-text);
  font-weight: 600;
}

.space-switcher-links {
  display: inline-flex;
  flex-wrap: wrap;
  gap: 4px 12px;
  margin-left: auto;
}

.space-switcher-links a {
  padding: 2px 4px;
  color: var(--editor-link-color);
}

/* On a phone, five spaces fit on one row. */
@media (max-width: 600px) {
  .space-switcher {
    gap: 2px;
    font-size: 0.85em;
  }

  .space-switcher-tab {
    gap: 3px;
    padding: 2px 5px;
  }
}
```
