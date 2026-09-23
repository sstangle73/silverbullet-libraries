------------------------------------------------------------------ Chapter Navigation

local function nav(layout, page)
  reset(layout)
  H.current = page
  return H.views["chapterNavTop"].content()
end

-- The bar on each kind of page, worked out from the fixture. The Tin Crown
-- has three chapters, the second with an adaptation page in DM; The Glass
-- Road has two, the second labelled Epilogue; Act I has three scenes. Book
-- holds no adaptation pages, so its chapters link to none. Then every page of
-- both spaces: a bar on each chapter, adaptation and scene page, and no other.
test("chapters: the bars in DM and Book, page by page", "dm", function()
  local want = {
    dm = {
      ["Book/Books/01 The Tin Crown/Chapter 01"] =
        "[[Book/Books/01 The Tin Crown/Contents|The Tin Crown]] (1 of 3) · " ..
        "[[Book/Books/01 The Tin Crown/Chapter 02|Chapter 2 →]]",
      ["Book/Books/01 The Tin Crown/Chapter 02"] =
        "[[Book/Books/01 The Tin Crown/Chapter 01|← Chapter 1]] · " ..
        "[[Book/Books/01 The Tin Crown/Contents|The Tin Crown]] (2 of 3) · " ..
        "[[Book/Books/01 The Tin Crown/Chapter 03|Chapter 3 →]] · " ..
        "[[Adaptation/01 The Tin Crown/Chapter 02|Adaptation notes]]",
      ["Book/Books/01 The Tin Crown/Chapter 03"] =
        "[[Book/Books/01 The Tin Crown/Chapter 02|← Chapter 2]] · " ..
        "[[Book/Books/01 The Tin Crown/Contents|The Tin Crown]] (3 of 3)",
      ["Book/Books/02 The Glass Road/Chapter 01"] =
        "[[Book/Books/02 The Glass Road/Contents|The Glass Road]] (1 of 2) · " ..
        "[[Book/Books/02 The Glass Road/Chapter 02|Epilogue →]]",
      ["Book/Books/02 The Glass Road/Chapter 02"] =
        "[[Book/Books/02 The Glass Road/Chapter 01|← Chapter 1]] · " ..
        "[[Book/Books/02 The Glass Road/Contents|The Glass Road]] (2 of 2)",
      -- No contents page in its folder, and no page of the folder's own: the
      -- top folder's page.
      ["Adaptation/01 The Tin Crown/Chapter 02"] =
        "[[Adaptation|The Tin Crown]] (1 of 1) · " ..
        "[[Book/Books/01 The Tin Crown/Chapter 02|Book chapter]]",
      ["Adventure/Campaign/Act I/Scene 2"] =
        "[[Adventure/Campaign/Act I/Scene 1|← The Ford]] · " ..
        "[[Adventure/Campaign/Act I|Act I]] (2 of 3) · " ..
        "[[Adventure/Campaign/Act I/Scene 3|The Old Orchard →]]",
      ["Book/Books/01 The Tin Crown/Contents"] = false,
      ["Book/People/Ada"] = false,
      ["Adventure/Campaign/Act I"] = false,
    },
    book = {
      ["Books/01 The Tin Crown/Chapter 01"] =
        "[[Books/01 The Tin Crown/Contents|The Tin Crown]] (1 of 3) · " ..
        "[[Books/01 The Tin Crown/Chapter 02|Chapter 2 →]]",
      ["Books/01 The Tin Crown/Chapter 02"] =
        "[[Books/01 The Tin Crown/Chapter 01|← Chapter 1]] · " ..
        "[[Books/01 The Tin Crown/Contents|The Tin Crown]] (2 of 3) · " ..
        "[[Books/01 The Tin Crown/Chapter 03|Chapter 3 →]]",
      ["Books/01 The Tin Crown/Chapter 03"] =
        "[[Books/01 The Tin Crown/Chapter 02|← Chapter 2]] · " ..
        "[[Books/01 The Tin Crown/Contents|The Tin Crown]] (3 of 3)",
      ["Books/02 The Glass Road/Chapter 01"] =
        "[[Books/02 The Glass Road/Contents|The Glass Road]] (1 of 2) · " ..
        "[[Books/02 The Glass Road/Chapter 02|Epilogue →]]",
      ["Books/02 The Glass Road/Chapter 02"] =
        "[[Books/02 The Glass Road/Chapter 01|← Chapter 1]] · " ..
        "[[Books/02 The Glass Road/Contents|The Glass Road]] (2 of 2)",
      ["Books/01 The Tin Crown/Contents"] = false,
      ["People/Beatrice"] = false,
    },
  }
  local real = 0
  for _, layout in ipairs({ "dm", "book" }) do
    reset(layout)
    for name, bar in pairs(want[layout]) do
      eq(chapterNav.markdown(name), bar or nil, layout .. ": " .. name)
    end
    for name in pairs(H.pages) do
      if chapterNav.markdown(name) ~= nil then real = real + 1 end
    end
  end
  eq(real, (5 + 1 + 3) + 5,
     "pages with a bar: DM's five chapters, adaptation page and three scenes, and Book's five chapters")
end)

test("chapters: Book's CONFIG sets the adaptation links", "dm", function()
  for _, layout in ipairs({ "dm", "book" }) do
    reset(layout)
    eq(table.concat(config.get("chapterNav.types"), " "), "chapter adaptation scene", layout)
    eq(config.get("chapterNav.counterparts.chapter.label"), "Adaptation notes", layout)
  end
  has(nav("dm", "Book/Books/01 The Tin Crown/Chapter 02"),
      "[[Adaptation/01 The Tin Crown/Chapter 02|Adaptation notes]]")
  has(nav("dm", "Adaptation/01 The Tin Crown/Chapter 02"),
      "[[Book/Books/01 The Tin Crown/Chapter 02|Book chapter]]")
  hasnt(nav("book", "Books/01 The Tin Crown/Chapter 02"), "Adaptation")
  eq(H.views["chapterNavBottom"].content(), nav("book", "Books/01 The Tin Crown/Chapter 02"))
end)

test("chapters: without settings, chapters only", "dm", function()
  reset("dm")
  H.config.chapterNav = nil
  local bar = chapterNav.markdown("Book/Books/01 The Tin Crown/Chapter 02")
  eq(bar, "[[Book/Books/01 The Tin Crown/Chapter 01|← Chapter 1]] · " ..
          "[[Book/Books/01 The Tin Crown/Contents|The Tin Crown]] (2 of 3) · " ..
          "[[Book/Books/01 The Tin Crown/Chapter 03|Chapter 3 →]]")
  eq(chapterNav.markdown("Adaptation/01 The Tin Crown/Chapter 02"), nil)
end)

test("chapters: other field names and types", "dm", function()
  reset("dm")
  H.pages = {
    ["Saga/Parts/One"] = "---\nkind: part\nn: 1\ntitle: The Saga\n---\n",
    ["Saga/Parts/Two"] = "---\nkind: part\nn: 2\ntitle: The Saga\nlabel: Interlude\n---\n",
    ["Saga/Parts/Three"] = "---\nkind: part\nn: 3\ntitle: The Saga\n---\n",
    ["Saga/Parts/Nested/Four"] = "---\nkind: part\nn: 4\n---\n",
    ["Saga/Parts/Index"] = "# Parts\n",
    ["Saga/Notes/Two"] = "---\nkind: note\nn: 2\n---\n",
    ["Saga"] = "# Saga\n",
  }
  config.set("chapterNav", {
    types = { "part", "note" },
    typeField = "kind", numberField = "n", labelField = "label", titleField = "title",
    labelFormat = "Part %s", contents = "Index",
    counterparts = { part = { type = "note" }, note = { type = "part", label = "The part" } },
  })
  eq(chapterNav.markdown("Saga/Parts/Two"),
     "[[Saga/Parts/One|← Part 1]] · [[Saga/Parts/Index|The Saga]] (2 of 3) · [[Saga/Parts/Three|Part 3 →]] · [[Saga/Notes/Two|note]]")
  eq(chapterNav.markdown("Saga/Parts/One"),
     "[[Saga/Parts/Index|The Saga]] (1 of 3) · [[Saga/Parts/Two|Interlude →]]")
  -- No contents page in the folder and none of its own: the top of the tree.
  -- No title: the folder's name, which 1.1 reads without its path.
  eq(chapterNav.markdown("Saga/Notes/Two"), "[[Saga|Notes]] (1 of 1) · [[Saga/Parts/Two|The part]]")
  eq(chapterNav.markdown("Saga/Parts/Nested/Four"), "[[Saga|Nested]] (1 of 1)")
  eq(chapterNav.markdown("Saga/Parts/Index"), nil)
  eq(chapterNav.markdown("Saga"), nil)
end)

-- space.pageExists is link resolution: a page whose path only ends in the
-- name counts. A link in a widget opens the name as written, so a middle link
-- to a page that isn't there opens an empty one. Book, with its contents
-- page gone and a reading list called Books elsewhere in the space.
test("chapters: the contents link goes only to a page of exactly that name", "book", function()
  local page = "Books/01 The Tin Crown/Chapter 01"
  local next = " · [[Books/01 The Tin Crown/Chapter 02|Chapter 2 →]]"
  H.pages["Books/01 The Tin Crown/Contents"] = nil
  H.pages["Reading Lists/Books"] = "# Books to read\n"
  eq(chapterNav.markdown(page), "The Tin Crown (1 of 3)" .. next, "a page ending in the top folder's name")
  H.pages["Archive/Books/01 The Tin Crown"] = "# The old folder page\n"
  H.pages["Archive/Books/01 The Tin Crown/Contents"] = "# The old contents\n"
  eq(chapterNav.markdown(page), "The Tin Crown (1 of 3)" .. next, "pages ending in the folder's and its contents' names")
  -- Each of the three, once it is there, from the top of the tree down.
  H.pages["Books"] = "# Books\n"
  eq(chapterNav.markdown(page), "[[Books|The Tin Crown]] (1 of 3)" .. next)
  H.pages["Books/01 The Tin Crown"] = "# The Tin Crown\n"
  eq(chapterNav.markdown(page), "[[Books/01 The Tin Crown|The Tin Crown]] (1 of 3)" .. next)
  H.pages["Books/01 The Tin Crown/Contents"] = "# Contents\n"
  eq(chapterNav.markdown(page), "[[Books/01 The Tin Crown/Contents|The Tin Crown]] (1 of 3)" .. next)
end)

-- Offline, say: the page may be there, so the bar links nothing rather than
-- a page further up the tree, and keeps its other links.
test("chapters: a contents page that can't be checked leaves the title unlinked", "book", function()
  H.failMeta = { ["Books/01 The Tin Crown/Contents"] = "Failed to fetch" }
  eq(chapterNav.markdown("Books/01 The Tin Crown/Chapter 02"),
     "[[Books/01 The Tin Crown/Chapter 01|← Chapter 1]] · The Tin Crown (2 of 3) · " ..
     "[[Books/01 The Tin Crown/Chapter 03|Chapter 3 →]]")
end)

test("chapters: a failure hides the bar instead of breaking the page", "dm", function()
  reset("dm")
  H.current = "Book/Books/01 The Tin Crown/Chapter 02"
  local original = index.pages
  index.pages = function() error("index gone") end
  local good, err = pcall(function()
    eq(H.views["chapterNavTop"].content(), nil)
    has(takePrinted()[1], "index gone")
  end)
  index.pages = original
  if not good then error(err, 0) end
end)
