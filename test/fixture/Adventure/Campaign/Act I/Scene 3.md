---
book_order: 13
type: scene
scene: 3
scene_title: The Old Orchard
status: approved
---

# Scene 3 — The Old Orchard

## The ground

${maps.draw("World/Maps/The Old Orchard")}

> **dm** Where they start
> ${maps.draw("World/Maps/The Old Orchard", { dm = true })}

## The fight

${party.fight { "The old orchard", level = 1, difficulty = "low",
  {1, "strangler", cr = "1/2", page = "World/Monsters/Strangler"},
  {6, "creeper", cr = "1/8", step = 2, min = 2, page = "World/Monsters/Creeper"},
}}

The [strangler](<../../World/Monsters/Strangler>) never moves; the [creepers](<../../World/Monsters/Creeper>) do.
