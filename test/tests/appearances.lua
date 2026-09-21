------------------------------------------------------------------ Appearances

-- The lists, worked out from the chapters' frontmatter. Ada is in chapters 1
-- and 2 of The Tin Crown and chapter 1 of The Glass Road. The chapters call
-- Beatrice Bea, her name_, in The Tin Crown's 2 and 3. The Mill is in The Tin
-- Crown's 1 and 3 and The Glass Road's 1. The Glass Road's Epilogue names no
-- one. Then every page of both spaces: a list on those three, and no other.
test("appearances: the lists on Ada, Beatrice and The Mill", "dm", function()
  -- b: the folder Book's pages are in, in this space.
  local function lists(b)
    return {
      [b .. "People/Ada"] = "3 chapters in 2 books.\n\n" ..
        "**1. The Tin Crown** (2): [[" .. b .. "Books/01 The Tin Crown/Chapter 01|1]], " ..
        "[[" .. b .. "Books/01 The Tin Crown/Chapter 02|2]]\n\n" ..
        "**2. The Glass Road** (1): [[" .. b .. "Books/02 The Glass Road/Chapter 01|1]]",
      [b .. "People/Beatrice"] = "2 chapters in 1 book.\n\n" ..
        "**1. The Tin Crown** (2): [[" .. b .. "Books/01 The Tin Crown/Chapter 02|2]], " ..
        "[[" .. b .. "Books/01 The Tin Crown/Chapter 03|3]]",
      [b .. "Places/The Mill"] = "3 chapters in 2 books.\n\n" ..
        "**1. The Tin Crown** (2): [[" .. b .. "Books/01 The Tin Crown/Chapter 01|1]], " ..
        "[[" .. b .. "Books/01 The Tin Crown/Chapter 03|3]]\n\n" ..
        "**2. The Glass Road** (1): [[" .. b .. "Books/02 The Glass Road/Chapter 01|1]]",
      [b .. "Books/01 The Tin Crown/Chapter 01"] = false,
    }
  end
  local real = 0
  for layout, b in pairs({ dm = "Book/", book = "" }) do
    reset(layout)
    for name, markdown in pairs(lists(b)) do
      local w = kb.appearances(name)
      eq(w and w.markdown, markdown or nil, layout .. ": " .. name)
    end
    for name in pairs(H.pages) do
      if kb.appearances(name) then real = real + 1 end
    end
  end
  eq(real, 3 * 2, "pages with a list: Ada, Beatrice and The Mill, in DM and in Book")
end)

test("appearances: Book's CONFIG maps each kb type to its field", "book", function()
  eq(config.get("appearances.fields")["kb-person"], "people")
  eq(config.get("appearances.fields")["kb-place"], "places")
  eq(config.get("appearances.nameField"), "name_")
  local w = kb.appearances("People/Ada")
  has(w.markdown, "3 chapters in 2 books.")
  has(w.markdown, "**1. The Tin Crown** (2): [[Books/01 The Tin Crown/Chapter 01|1]]")
end)

test("appearances: without settings, nothing", "book", function()
  H.config.appearances = nil
  eq(kb.appearances("People/Ada"), nil)
end)

test("appearances: one book, a name of its own, and a field with a single name", "dm", function()
  reset("dm")
  H.pages = {
    ["Cast/Ada"] = "---\ntype: person\nalias: Ada Byron\n---\n",
    ["Cast/Brin"] = "---\ntype: person\n---\n",
    ["Chapters/1"] = "---\ntype: chapter\nchapter: 1\npeople: [Ada Byron, Brin]\n---\n",
    ["Chapters/2"] = "---\ntype: chapter\nchapter: 2\npeople: Brin\n---\n",
    ["Chapters/3"] = "---\ntype: chapter\nchapter: 3\nchapter_label: Coda\npeople: [Ada Byron]\n---\n",
    ["Chapters/4"] = "---\ntype: chapter\nchapter: 4\n---\n",
  }
  config.set("appearances", { fields = { person = "people" }, nameField = "alias" })
  eq(kb.appearances("Cast/Ada").markdown, "2 chapters.\n\n[[Chapters/1|1]], [[Chapters/3|Coda]]")
  eq(kb.appearances("Cast/Brin").markdown, "2 chapters.\n\n[[Chapters/1|1]], [[Chapters/2|2]]")
  H.pages["Cast/Cy"] = "---\ntype: person\n---\n"
  eq(kb.appearances("Cast/Cy").markdown, "Not named in any chapter's frontmatter.")
  eq(kb.appearances("Chapters/1"), nil)
  eq(kb.appearances("Nowhere"), nil)
end)

test("appearances: books with a title or a number only", "dm", function()
  reset("dm")
  H.pages = {
    ["P/Ada"] = "---\nkind: who\n---\n",
    ["B/One"] = "---\nkind: ch\nvol: 1\nno: 1\nwho: [Ada]\n---\n",
    ["B/Two"] = "---\nkind: ch\nvol: 2\nno: 1\nname_of_book: Second\nwho: [Ada]\n---\n",
    ["B/Three"] = "---\nkind: ch\nvol: 2\nno: 2\nname_of_book: Second\nwho: [Ada]\n---\n",
  }
  config.set("appearances", {
    fields = { who = "who" }, chapterType = "ch", typeField = "kind", numberField = "no",
    bookField = "vol", titleField = "name_of_book",
  })
  eq(kb.appearances("P/Ada").markdown,
     "3 chapters in 2 books.\n\n**1** (1): [[B/One|1]]\n\n**2. Second** (2): [[B/Two|1]], [[B/Three|2]]")
end)
