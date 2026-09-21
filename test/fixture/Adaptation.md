---
type: dashboard
---

# Adaptation

Campaign ideas drawn from each chapter of the books, one page per chapter.

${query[[
  from p = index.pages()
  where p.type == "adaptation"
  order by p.book, p.chapter
  select { Source = p.book_title, Ch = p.chapter, Page = "[[" .. p.name .. "]]" }
]]}
