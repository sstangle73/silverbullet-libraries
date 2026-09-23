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

-- config.set of the wrong shape raises once the shape is declared, as
-- SilverBullet's Config.set does, after it has set the value.
local function refused(value)
  local good, err = pcall(config.set, "appearances", value)
  ok(not good, "config.set took appearances of the wrong shape")
  return tostring(err)
end

test("appearances: the settings' shape is declared, and a wrong one is reported where it is set", "book", function()
  eq(config.getSchemas().properties.appearances, kb.schema)
  eq(refused({ fields = "people" }),
     'Validation error for appearances:> fields: Instance type "string" is invalid. Expected "object".')
  has(refused({ fields = { person = { "people", "cast" } } }),
      'fields.person: Instance type "array" is invalid. Expected "string".')
  has(refused({ fields = { person = "people" }, namefield = "alias" }),
      'Property "namefield" does not match additional properties schema.', "a misspelt key")
  config.set("appearances", { fields = { person = "people" }, nameField = "alias", chapterType = "chapter" })
end)

-- SilverBullet sets the value before it checks it; a list of the wrong
-- shape lists nothing, quietly, rather than break the page it is on.
test("appearances: settings of the wrong shape list nothing, and break nothing", "book", function()
  ok(kb.appearances("People/Ada"), "Ada's list, as the CONFIG page sets it")
  refused({ fields = "people" })
  eq(kb.appearances("People/Ada"), nil)
  refused({ fields = { ["kb-person"] = { "people" } } })
  eq(kb.appearances("People/Ada"), nil)
  eq(#H.printed, 0)
end)

-- A chapter's field that holds a map rather than a list names no one: it
-- is walked, not handed to table.includes, which throws on one.
test("appearances: a chapter field that isn't a list or a name names no one", "dm", function()
  reset("dm")
  H.pages = {
    ["Cast/Ada"] = "---\ntype: person\n---\n",
    ["Chapters/1"] = "---\ntype: chapter\nchapter: 1\npeople: [Ada]\n---\n",
    ["Chapters/2"] = "---\ntype: chapter\nchapter: 2\n---\n",
  }
  config.set("appearances", { fields = { person = "people" } })
  local real = index.pages
  index.pages = function(...)
    local out = real(...)
    for _, p in ipairs(out) do
      if p.name == "Chapters/2" then p.people = { lead = "Ada" } end
    end
    return out
  end
  local good, w = pcall(kb.appearances, "Cast/Ada")
  index.pages = real
  ok(good, tostring(w))
  eq(w.markdown, "1 chapter.\n\n[[Chapters/1|1]]")
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
