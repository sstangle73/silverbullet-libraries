---
tags: meta/library
name: "Library/Storie/GM Beyond"
description: "Live party roster pulled from D&D Beyond public character data via the server-side fetch proxy. Renders name, race, class and level."
author: "Steven Storie"
version: "1.0.0"
---

# GM Beyond

Pull a live party roster from D&D Beyond into SilverBullet.

## What this does and doesn't do

**Does:** fetches public character data — name, race, classes, levels — and renders a roster that never goes stale.

**Doesn't:** embed character sheets. D&D Beyond sends frame-blocking headers, so an iframe will not work, ever. Anyone offering you a DDB "embed" means a link.

**Won't:** compute AC or current HP. The endpoint returns *raw* character data, not derived values — getting AC right means reimplementing a large slice of 5e, which is why ddb-importer is a whole project. Keep DDB open at the table for live numbers. A wiki that's subtly wrong about AC is worse than no wiki.

## How it works

`net.proxyFetch` runs server-side, so there's no CORS wall between your space and DDB's character service — the same unofficial endpoint Beyond20, Avrae and ddb-importer all use. Characters must have privacy set to **public**. It's undocumented and does break occasionally; failures degrade to an italic placeholder rather than erroring the page.

## Usage

Put the numeric character id in frontmatter:

```yaml
---
type: pc
player: Sam
ddb: 147258369
---
```

Then anywhere:

    ${gmb.summary(147258369)}

Or across a roster:

    ${query[[
      from p = index.pages()
      where p.type == "pc" and p.ddb
      select gmb.summary(p.ddb)
    ]]}

Always keep a plain link too, so the page stays useful when the fetch doesn't:

    [Sheet](https://www.dndbeyond.com/characters/147258369)

## Licensing note

Link to monsters and rules content; don't mirror it. SRD material is open, the rest isn't, and a wiki of pasted statblocks is a legal problem and a maintenance burden at once.

## Implementation

```space-lua
-- priority: 10
gmb = gmb or {}

gmb.endpoint = "https://character-service.dndbeyond.com/character/v5/character/"

--- Fetch a public DDB character. Returns nil when private or unreachable.
function gmb.fetch(id)
  local res = net.proxyFetch(gmb.endpoint .. tostring(id))
  if not res or res.status ~= 200 then return nil end
  local body = res.body
  if type(body) == "string" then body = js.parse(body) end
  return body and body.data or nil
end

--- "Nox — Half-Elf Rogue 4 / Warlock 2"
function gmb.summary(id)
  local c = gmb.fetch(id)
  if not c then return "_(private or unreachable)_" end
  local classes = {}
  for _, cl in ipairs(c.classes or {}) do
    classes[#classes + 1] =
      (cl.definition and cl.definition.name or "?") .. " " .. (cl.level or "?")
  end
  local race = c.race and c.race.fullName or ""
  return (c.name or "?") .. " — " .. race .. " " .. table.concat(classes, " / ")
end

--- Total level across all classes.
function gmb.level(id)
  local c = gmb.fetch(id)
  if not c then return nil end
  local total = 0
  for _, cl in ipairs(c.classes or {}) do total = total + (cl.level or 0) end
  return total
end
```
