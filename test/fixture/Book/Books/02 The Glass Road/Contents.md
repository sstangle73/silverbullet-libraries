---
type: book-contents
book: 2
book_title: The Glass Road
---

# The Glass Road

The second novel. Chapters in order.

${query[[
  from p = index.pages()
  where p.type == "chapter" and p.book == 2
  order by p.chapter
  select { Chapter = "[[" .. p.name .. "|" .. (p.chapter_label or ("Chapter " .. p.chapter)) .. "]]" }
]]}
