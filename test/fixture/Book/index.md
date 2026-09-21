---
type: kb-index
---

# Book

Reference notes on the two novels the test campaign adapts: plot, people and places as the books have them.

## Works

${query[[
  from p = index.pages()
  where p.type == "book-contents"
  order by p.book
  select { Work = "[[" .. p.name .. "|" .. p.book_title .. "]]" }
]]}

## People

${query[[
  from p = index.pages()
  where p.type == "kb-person"
  order by p.name
  select { Name = "[[" .. p.name .. "]]" }
]]}
