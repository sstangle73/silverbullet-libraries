------------------------------------------------------------------ Scenes (Chapter Navigation 1.1)

local ACT = "Adventure/Campaign/Act I"

-- The scenes directly in an act's folder, in scene order, read from the
-- pages themselves, so a scene added to the fixture doesn't break these tests.
local function sceneList(act)
  local out = {}
  for name, text in pairs(H.pages) do
    local rest = name:sub(#act + 2)
    if name:sub(1, #act + 1) == act .. "/" and not rest:find("/", 1, true) then
      local fm = text:match("^%-%-%-\n(.-\n)%-%-%-")
      fm = fm and ("\n" .. fm)
      if fm and fm:find("\ntype: scene\n", 1, true) then
        out[#out + 1] = { name = name, n = tonumber(fm:match("\nscene: (%d+)")),
                          title = fm:match("\nscene_title: ([^\n]+)") }
      end
    end
  end
  table.sort(out, function(a, b) return a.n < b.n end)
  return out
end

-- The bar the i-th of those scenes should get: the scene before, the act's
-- page with the count, and the scene after.
local function sceneBar(scenes, i, act, actLabel)
  local function label(s) return s.title or ("Scene " .. s.n) end
  local parts = {}
  if i > 1 then parts[#parts + 1] = "[[" .. scenes[i - 1].name .. "|← " .. label(scenes[i - 1]) .. "]]" end
  parts[#parts + 1] = "[[" .. act .. "|" .. actLabel .. "]] (" .. i .. " of " .. #scenes .. ")"
  if i < #scenes then parts[#parts + 1] = "[[" .. scenes[i + 1].name .. "|" .. label(scenes[i + 1]) .. " →]]" end
  return table.concat(parts, " · ")
end

test("scenes: the bar runs between the scenes of an act, through the act's page", "dm", function()
  local scenes = sceneList(ACT)
  ok(#scenes >= 2, "Act I should have scenes to walk between")
  for i, s in ipairs(scenes) do
    eq(chapterNav.markdown(s.name), sceneBar(scenes, i, ACT, "Act I"), s.name)
  end
  -- one anchor that holds however many scenes there are
  has(chapterNav.markdown(ACT .. "/Scene 1"), "[[" .. ACT .. "/Scene 2|The Market →]]")
  hasnt(chapterNav.markdown(ACT .. "/Scene 1"), "←")
end)

test("scenes: an act of three, pinned exactly", "dm", function()
  local act = "Adventure/Campaign/Act Z"
  H.pages[act] = "---\ntype: campaign\n---\n\n# Act Z\n"
  H.pages[act .. "/Scene 1"] = "---\ntype: scene\nscene: 1\nscene_title: One\n---\n\n# One\n"
  H.pages[act .. "/Scene 2"] = "---\ntype: scene\nscene: 2\nscene_title: Two\n---\n\n# Two\n"
  H.pages[act .. "/Scene 3"] = "---\ntype: scene\nscene: 3\nscene_title: Three\n---\n\n# Three\n"
  eq(chapterNav.markdown(act .. "/Scene 2"),
     "[[" .. act .. "/Scene 1|← One]] · [[" .. act .. "|Act Z]] (2 of 3) · [[" .. act .. "/Scene 3|Three →]]")
  eq(chapterNav.markdown(act .. "/Scene 1"), "[[" .. act .. "|Act Z]] (1 of 3) · [[" .. act .. "/Scene 2|Two →]]")
  eq(chapterNav.markdown(act .. "/Scene 3"), "[[" .. act .. "/Scene 2|← Two]] · [[" .. act .. "|Act Z]] (3 of 3)")
end)

test("scenes: the act page and the other campaign pages get no bar", "dm", function()
  eq(chapterNav.markdown(ACT), nil)
  eq(chapterNav.markdown("Adventure/Campaign/Premise"), nil)
  eq(chapterNav.markdown("Adventure/index"), nil)
  eq(chapterNav.markdown("Adventure/World/People/The Warden"), nil)
end)

test("scenes: the Adventure space draws the same bar in its own names", "adventure", function()
  local act = "Campaign/Act I"
  local scenes = sceneList(act)
  ok(#scenes >= 2, "Act I should have scenes to walk between")
  eq(chapterNav.markdown(scenes[2].name), sceneBar(scenes, 2, act, "Act I"))
  eq(H.views["chapterNavTop"].content(), nil, "no current page, no bar")
  H.current = scenes[#scenes].name
  has(H.views["chapterNavBottom"].content(), "(" .. #scenes .. " of " .. #scenes .. ")")
end)

test("scenes: a scene without a title falls back to its number, and an act to its folder", "dm", function()
  local act = "Adventure/Campaign/Act Z"
  H.pages[act] = "---\ntype: campaign\n---\n\n# Act Z\n"
  H.pages[act .. "/Scene 1"] = "---\ntype: scene\nscene: 1\nscene_title: One\n---\n\n# One\n"
  H.pages[act .. "/Scene 2"] = "---\ntype: scene\nscene: 2\n---\n\n# Scene 2\n"
  eq(chapterNav.markdown(act .. "/Scene 1"),
     "[[" .. act .. "|Act Z]] (1 of 2) · [[" .. act .. "/Scene 2|Scene 2 →]]")
  H.pages["Adventure/Campaign/Act II/Scene 1"] = "---\ntype: scene\nscene: 1\n---\n\n# One\n"
  H.pages["Adventure/Campaign/Act II/Scene 2"] = "---\ntype: scene\nscene: 2\n---\n\n# Two\n"
  eq(chapterNav.markdown("Adventure/Campaign/Act II/Scene 1"),
     "Act II (1 of 2) · [[Adventure/Campaign/Act II/Scene 2|Scene 2 →]]",
     "an act with no page of its own still names itself")
end)

test("scenes: chapters keep their own numbering and contents page", "dm", function()
  eq(chapterNav.markdown("Book/Books/01 The Tin Crown/Chapter 02"),
     "[[Book/Books/01 The Tin Crown/Chapter 01|← Chapter 1]] · " ..
     "[[Book/Books/01 The Tin Crown/Contents|The Tin Crown]] (2 of 3) · " ..
     "[[Book/Books/01 The Tin Crown/Chapter 03|Chapter 3 →]] · " ..
     "[[Adaptation/01 The Tin Crown/Chapter 02|Adaptation notes]]")
end)

test("scenes: per-type settings don't leak between types", "dm", function()
  eq(config.get("chapterNav.perType.scene.numberField"), "scene")
  eq(config.get("chapterNav.perType.chapter"), nil)
  local scenes = sceneList(ACT)
  local before = #scenes
  H.pages[ACT .. "/Scene 99"] = "---\ntype: scene\nscene: 99\nchapter: 1\nchapter_label: Wrong\n---\n\n# Ninety-nine\n"
  has(chapterNav.markdown(ACT .. "/Scene 2"), "(2 of " .. (before + 1) .. ")")
  hasnt(chapterNav.markdown(ACT .. "/Scene 2"), "Wrong")
  -- Scene 99 comes after the act's last scene, whose bar names it by its number.
  has(chapterNav.markdown(scenes[before].name), "[[" .. ACT .. "/Scene 99|Scene 99 →]]",
      "the scene before it takes nothing from chapter_label")
  hasnt(chapterNav.markdown(ACT .. "/Scene 99"), "Wrong", "the scene's own bar takes nothing from chapter_label")
end)

test("scenes: the Session Table lists them in order, with their act and status", "dm", function()
  local want = 0
  for _, text in pairs(H.pages) do
    local fm = text:match("^%-%-%-\n(.-\n)%-%-%-")
    if fm and ("\n" .. fm):find("\ntype: scene\n", 1, true) then want = want + 1 end
  end
  local rows = __liq(function() return index.pages() end,
    function(p) return p.type == "scene" end,
    { { fn = function(p) return p.book_order end, desc = false } }, nil, nil)
  eq(#rows, want, "one row per scene page")
  for i = 2, #rows do
    ok(rows[i - 1].book_order < rows[i].book_order,
       "book order: " .. rows[i - 1].name .. " before " .. rows[i].name)
  end
  eq(rows[1].scene_title, "The Ford", "the adventure opens on Act I's first scene")
  eq(string.match(rows[2].name, "([^/]+)/[^/]+$"), "Act I")
  has(H.pages["Session Table"], '\n## Scenes\n')
  has(H.pages["Session Table"], 'where p.type == "scene"')
  has(H.pages["Session Table"], 'p.scene_title or p.name')
end)
