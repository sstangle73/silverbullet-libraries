---
type: book-contents
book: 1
book_title: The Tin Crown
---

# The Tin Crown

The first novel. Chapters in order.

${query[[
  from p = index.pages()
  where p.type == "chapter" and p.book == 1
  order by p.chapter
  select { Chapter = "[[" .. p.name .. "|" .. (p.chapter_label or ("Chapter " .. p.chapter)) .. "]]" }
]]}
