---
type: party
characters: 5
level: 1
---

# The Party

${party.summary()}

Every number in the adventure that follows the party reads it from here, through [[Adventure/Library/Storie/GM Party]]. Until there are character pages (`type: pc`), the party is this page's `characters` and `level`.

${query[[
  from p = index.pages()
  where p.type == "pc"
  order by p.name
  select { Character = "[[" .. p.name .. "]]", Player = p.player }
]]}

## What they carry

${query[[
  from p = index.pages()
  where p.type == "state-record" and p.found == true
  order by p.found_session
  select { Item = p.subject, Left = gm.usesText(p), Where = p.found_in, Session = gm.sessionLink(p.found_session, true) }
]]}

## Live from D&D Beyond

${query[[
  from p = index.pages()
  where p.type == "pc" and p.ddb
  select gmb.summary(p.ddb)
]]}
