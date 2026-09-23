---
tags: meta/repository
name: Repository/Storie
version: 1.3.0
---

# Storie Library Repository
Custom SilverBullet libraries — task management, a set of tools for running tabletop RPG campaigns, a switcher for servers with several spaces, chapter tools for a wiki about a book or a series, and a health check for all of them.

They are written for SilverBullet 2.11.

## Installation
In each space you install into:

1. Run `Library: Add Repository`, give it this page's address, `https://github.com/sstangle73/silverbullet-libraries/blob/main/Repositories/storie.md`, and keep the page name it suggests, `Repositories/storie`.
2. Run `Library: Install` for each library that space needs (see *Where each library goes*), with the library's own address: its `uri` under *Contents*. Once the repository is added, the Libraries panel (`Libraries: Manager`) also lists these under **Available**, each with an **Install** button.

## Updating
Install and update each library from inside the space it belongs to, and never run `Library: Update All` in a space that holds others as folders, such as a campaign's DM space. SilverBullet writes a library, installed or updated, to the name in its own frontmatter, `Library/Storie/…`, at the root of the space you run the command in, so Update All there writes each folder's libraries again at the root, where they run beside the folders' copies, and leaves those copies as they were. **Update** on a library the Libraries panel finds in one of those folders does the same. Update the DM space's own libraries one at a time, and the others from inside their own spaces.

## Where each library goes
The campaign libraries expect a DM space that holds the others as folders: the adventure (`Adventure/`, unless you tell GM Kit otherwise), your notes on it, the book it adapts, and the players' space. Each of those is a space of its own as well.

| Library | Space |
|---|---|
| GM Kit, GM Beyond | The DM space, the one that holds the others |
| GM Book, GM Party, GM Bestiary, GM Maps, GM Sheets | The adventure space |
| Chapter Navigation | Each space with chapters or scenes to page through, such as the adventure's and the book's |
| Appearances | The book's space, where its chapters name the people and places in them |
| Space Switcher | Every space. One that holds others as folders runs their copies, and needs none of its own |
| RecurringTasks | Any space; it has nothing to do with the others |
| Storie Check | The adventure space, or any other with Storie libraries to check. One that holds others as folders runs their copy, and checks their libraries too |

## Contents
```#meta/library/remote
name: "RecurringTasks"
uri: https://github.com/sstangle73/silverbullet-libraries/blob/main/src/RecurringTasks.md
website: https://github.com/sstangle73/silverbullet-libraries/blob/main/src/RecurringTasks.md
description: "A manager for recurring tasks"
---
name: "GM Kit"
uri: https://github.com/sstangle73/silverbullet-libraries/blob/main/src/GM%20Kit.md
website: https://github.com/sstangle73/silverbullet-libraries/blob/main/src/GM%20Kit.md
description: "Session tracking and fog-of-war publishing for tabletop RPG campaigns. Keeps play state out of your adventure pages so they stay publishable. Mark NPCs met or dead, places visited, items found and their uses left; log rolls and decisions; count each character's hit points, slots and rests; preview what publishing sends, and recap each session for the players."
---
name: "GM Beyond"
uri: https://github.com/sstangle73/silverbullet-libraries/blob/main/src/GM%20Beyond.md
website: https://github.com/sstangle73/silverbullet-libraries/blob/main/src/GM%20Beyond.md
description: "D&D Beyond characters: an import that writes a character's whole sheet into a page, every number worked out from the raw data, for GM Sheets to draw; a refresh that says what it changes before it writes, one for the whole party, and a roster read from the pages."
---
name: "GM Book"
uri: https://github.com/sstangle73/silverbullet-libraries/blob/main/src/GM%20Book.md
website: https://github.com/sstangle73/silverbullet-libraries/blob/main/src/GM%20Book.md
description: "Compile a campaign space into DM and player manuscripts, transformed for Homebrewery."
---
name: "GM Party"
uri: https://github.com/sstangle73/silverbullet-libraries/blob/main/src/GM%20Party.md
website: https://github.com/sstangle73/silverbullet-libraries/blob/main/src/GM%20Party.md
description: "Numbers, hand-outs and fights that follow the party's size: live for your table, general rules in print. 2024 encounter math from the SRD 5.2.1."
---
name: "GM Bestiary"
uri: https://github.com/sstangle73/silverbullet-libraries/blob/main/src/GM%20Bestiary.md
website: https://github.com/sstangle73/silverbullet-libraries/blob/main/src/GM%20Bestiary.md
description: "Creature pages that point at official stat blocks: a link to a compendium on the page, the book and its entry in print. Wires those pages to GM Party's fights."
---
name: "GM Maps"
uri: https://github.com/sstangle73/silverbullet-libraries/blob/main/src/GM%20Maps.md
website: https://github.com/sstangle73/silverbullet-libraries/blob/main/src/GM%20Maps.md
description: "Encounter maps written as a grid of characters with a legend: drawn as a scaled plan with its own key, on the wiki and in the book, and sized to the party."
---
name: "GM Sheets"
uri: https://github.com/sstangle73/silverbullet-libraries/blob/main/src/GM%20Sheets.md
website: https://github.com/sstangle73/silverbullet-libraries/blob/main/src/GM%20Sheets.md
description: "Character sheets drawn from a character page's frontmatter: a page like a sheet on the wiki and a page of its own in the book, then the features, spells and equipment in full. The SRD's sums worked out."
---
name: "Space Switcher"
uri: https://github.com/sstangle73/silverbullet-libraries/blob/main/src/Space%20Switcher.md
website: https://github.com/sstangle73/silverbullet-libraries/blob/main/src/Space%20Switcher.md
description: "A strip across the top of every page that names the space you are in and links to your other spaces, for a server with several SilverBullet spaces, nested ones included."
---
name: "Chapter Navigation"
uri: https://github.com/sstangle73/silverbullet-libraries/blob/main/src/Chapter%20Navigation.md
website: https://github.com/sstangle73/silverbullet-libraries/blob/main/src/Chapter%20Navigation.md
description: "Previous, contents and next links above and below every chapter page, read from the index, with an optional link to a companion page for the same chapter."
---
name: "Appearances"
uri: https://github.com/sstangle73/silverbullet-libraries/blob/main/src/Appearances.md
website: https://github.com/sstangle73/silverbullet-libraries/blob/main/src/Appearances.md
description: "Lists the chapters that name the current page in their frontmatter, grouped by book, for a wiki about a book or a series."
---
name: "Storie Check"
uri: https://github.com/sstangle73/silverbullet-libraries/blob/main/src/Storie%20Check.md
website: https://github.com/sstangle73/silverbullet-libraries/blob/main/src/Storie%20Check.md
description: "A health check for the Storie libraries in a space: every copy and its version, whether the tab runs them current, GM Book's printers, and whether the small libraries' settings are the shape they read."
---
```