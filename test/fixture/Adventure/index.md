---
type: dashboard
tags: meta
---

# The Tin Crown: Adventure

The adventure as written: what could happen. The printer in the header, or the buttons under The book below, compile every page carrying a `book_order` into a manuscript. No play state lives here.

Start at [Premise](<Campaign/Premise>).

## Scenes

${query[[
  from p = index.pages()
  where p.type == "scene"
  order by p.book_order
  select { Scene = "[[" .. p.name .. "]]", Status = p.status }
]]}

## Cast

${query[[
  from p = index.pages()
  where p.type == "npc"
  order by p.faction, p.name
  select { Name = "[[" .. p.name .. "]]", Faction = p.faction, Role = p.role }
]]}

## The book

${widgets.commandButton("Build the book", "GM: Build Book")} ${widgets.commandButton("DM edition only", "GM: Build Book (DM)")} ${widgets.commandButton("Player edition only", "GM: Build Book (Player)")}

A build writes [Book DM](<Build/Book DM>), with everything, and [Book Player](<Build/Book Player>), without what is only for the DM. The chapters go in this order:

${query[[
  from p = index.pages()
  where p.book_order ~= nil
  order by p.book_order
  select { Order = p.book_order, Page = "[[" .. p.name .. "]]" }
]]}
