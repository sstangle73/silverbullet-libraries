#meta

# Configuration

Settings for the libraries in `Library/Storie/`.

## Space Switcher

This space names only itself: the strip shows its own tab, and a link to the server's list of the spaces an account can open. A space that holds this one as a folder runs this block too. It loads first there (`priority: 1`), and that space's own list replaces it.

```space-lua
-- priority: 1
config.set("spaceSwitcher", {
  spaces = {
    { name = "Player", url = "/player/", icon = "users", color = "#ad1457" },
  },
  directory = { name = "All spaces", url = "/.dashboard", title = "The spaces your account can open" },
})
```
