---
tags: meta
---

# The Tin Crown: DM

A small campaign the libraries are tested against. It is laid out the way the libraries expect a campaign to be: this DM space holds the others as folders.

- [Adventure](<Adventure/index>): the adventure as written
- [Author](<Author/index>): why it says what it says
- [Book](<Book/index>): the novels it adapts, as a knowledge base
- [Player](<Player/index>): what the players have been shown

Run the table from the [[Session Table]]. The party is on [[The Party]].

## Play state

${query[[
  from p = index.pages()
  where p.type == "state-record"
  order by p.name
  select { Subject = p.subject, Met = p.met, Status = p.status, Visited = p.visited, Found = p.found }
]]}

Revealed to players: [[State/Revealed]]
