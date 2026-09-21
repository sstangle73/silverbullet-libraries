---
type: campaign
session: 1
---

# Session Table

The page kept open while running, powered by [[Library/Storie/GM Kit]].

Currently session **${gm.currentSession()}**. ${widgets.commandButton("Next session", "GM: Next Session")}

${widgets.commandButton("Scene started…", "GM: Mark Scene Started")} ${widgets.commandButton("Scene finished…", "GM: Mark Scene Finished")} ${widgets.commandButton("Log a decision", "GM: Log Decision")}

${widgets.commandButton("Met…", "GM: Mark Met")} ${widgets.commandButton("Died…", "GM: Mark Dead")} ${widgets.commandButton("Visited…", "GM: Mark Visited")} ${widgets.commandButton("Found…", "GM: Mark Found")} ${widgets.commandButton("Reveal a page…", "GM: Reveal Page")} ${widgets.commandButton("Publish to players", "GM: Publish to Players")}

${widgets.commandButton("Use one…", "GM: Spend Use")} ${widgets.commandButton("Refund one…", "GM: Refund Use")} ${widgets.commandButton("Unmark…", "GM: Unmark")}

## Scenes

${query[[
  from p = index.pages()
  where p.type == "scene"
  order by p.book_order
  select {
    Act = string.match(p.name, "([^/]+)/[^/]+$"),
    Scene = "[[" .. p.name .. "|" .. (p.scene_title or p.name) .. "]]",
    Status = p.status,
    Played = gm.playedText(gm.readState(p.name)),
  }
]]}

## Met

${query[[
  from p = index.pages()
  where p.type == "state-record" and p.met == true
  order by p.met_session
  select { Who = p.subject, Session = gm.sessionLink(p.met_session, true) }
]]}

## Dead

${query[[
  from p = index.pages()
  where p.type == "state-record" and p.status == "dead"
  order by p.died_session
  select { Who = p.subject, Session = gm.sessionLink(p.died_session, true) }
]]}

## Visited

${query[[
  from p = index.pages()
  where p.type == "state-record" and p.visited == true
  order by p.visited_session
  select { Where = p.subject, Session = gm.sessionLink(p.visited_session, true) }
]]}

## Found

${query[[
  from p = index.pages()
  where p.type == "state-record" and p.found == true
  order by p.found_session
  select { What = p.subject, Session = gm.sessionLink(p.found_session, true), Left = gm.usesText(p) }
]]}

## Session logs

${query[[
  from p = index.pages()
  where p.type == "session"
  order by p.session desc
  select { Session = "[[" .. p.name .. "]]" }
]]}
