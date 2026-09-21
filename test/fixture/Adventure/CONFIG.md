#meta

# Configuration

The test campaign's settings for the libraries in `Library/Storie/`. Each space has a `CONFIG` page of its own, and the DM space, which holds the other four as folders, runs all four.

## Space Switcher

The five spaces, in the strip's order. Adventure, Author and Book carry this same block, so keep the three identical: the DM space runs every copy, and the last to load wins. Player's `CONFIG` lists only Player.

```space-lua
config.set("spaceSwitcher", {
  spaces = {
    { name = "DM",        url = "/dm/",                               icon = "eye",       color = "#311b92" },
    { name = "Adventure", url = "/adventure/", folder = "Adventure/", icon = "map",       color = "#4fc3f7" },
    { name = "Author",    url = "/author/",    folder = "Author/",    icon = "feather",   color = "#e65100" },
    { name = "Book",      url = "/book/",      folder = "Book/",      icon = "book-open", color = "#fff176" },
    { name = "Player",    url = "/player/",    folder = "Player/",    icon = "users",     color = "#ad1457" },
  },
})
```

## Chapter Navigation

Chapters in `Book/`, their notes in `Adaptation/`, and scenes in `Adventure/`, one folder per act. Adventure's and Book's `CONFIG` carry this same block.

```space-lua
config.set("chapterNav", {
  types = { "chapter", "adaptation", "scene" },
  counterparts = {
    chapter    = { type = "adaptation", label = "Adaptation notes" },
    adaptation = { type = "chapter",    label = "Book chapter" },
  },
  perType = {
    scene = { numberField = "scene", labelField = "scene_title", labelFormat = "Scene %s" },
  },
})
```
