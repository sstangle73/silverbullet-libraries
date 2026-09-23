------------------------------------------------------------------ Publishing (GM Kit 3.8)
-- What a players' copy links to, what the bar says of a copy that has
-- fallen behind, and the copies and play state a renamed page leaves.

local P_CRYPT = "Adventure/World/Places/Crypt"
local P_CRYPT_COPY = "Player/World/Places/Crypt"
local P_WARDEN = "Adventure/World/People/The Warden"
local P_MARA = "Adventure/World/People/Mara"
local P_NL = string.char(10)

local function pPublish(...)
  H.confirms = { true, ... }
  return gm.publish()
end

------------------------------------------------ links in a players' copy

local function useCrypt()
  H.pages[P_CRYPT] = table.concat({
    "---", "type: place", "---", "", "# Crypt", "",
    "A [hooded stranger](<../People/The Warden>) waits by [the door](<../People/The Warden#At the Table>).",
    "[[Adventure/World/People/Mara|A friend]] rows the ferry, and [[Old Tam]] sells rope.",
    "The [house rules](<../../Rules/House Rules>) apply. See [the map](https://example.org/map) and ![a](<x.png>).",
    "The [orchard](<../Maps/The Old Orchard>) is near. Write `[[Old Tam]]` in code. ${\"[[Old Tam]]\"}",
    "[Nowhere](<../People/Nobody>), [up the stair](Stair%20Top) and [back to the top](#Crypt).",
    "",
    "![[World/People/The Warden#What They Want]]",
    "",
    "![[World/Items/Lantern#Rules]]",
    "",
    "![[World/People/Mara]]",
    "",
    "```",
    "[[Old Tam]] in a fence stays as written.",
    "```",
    "",
    "End.",
  }, P_NL)
  gm.writeRevealed({ P_CRYPT, "Adventure/Rules/House Rules", "Adventure/World/Items/Lantern",
    P_WARDEN .. "#Who They Are", "Adventure/World/Maps/The Old Orchard" })
end

test("links: a link to a page the players won't have is its label, and one they will have stays", "dm", function()
  useCrypt()
  pPublish()
  eq(H.pages[P_CRYPT_COPY], table.concat({
    "---", "type: place", "---", "", "# Crypt", "",
    "A [hooded stranger](<../People/The Warden>) waits by [the door](<../People/The Warden#At the Table>).",
    "A friend rows the ferry, and Old Tam sells rope.",
    "The [house rules](<../../Rules/House Rules>) apply. See [the map](https://example.org/map) and ![a](<x.png>).",
    "The orchard is near. Write `[[Old Tam]]` in code. ${\"[[Old Tam]]\"}",
    "Nowhere, up the stair and [back to the top](#Crypt).",
    "",
    "![[World/Items/Lantern#Rules]]",
    "",
    "```",
    "[[Old Tam]] in a fence stays as written.",
    "```",
    "",
    "End.",
  }, P_NL), "a page revealed in part is theirs, a map page never is, and a page gone is no page")
end)

test("links: an embed of a page or a section the players won't have goes, and is named", "dm", function()
  useCrypt()
  pPublish()
  local n = lastNotification()
  eq(n.kind, "warning")
  has(n.message, "Embeds left out, as the players don't have what they show: " ..
    "![[World/People/The Warden#What They Want]] in " .. P_CRYPT .. ", ![[World/People/Mara]] in " .. P_CRYPT .. ".")
end)

------------------------------------------------ a copy that has fallen behind

test("behind: publishing keeps a record of what each copy was made from", "dm", function()
  gm.writeRevealed({ P_WARDEN .. "#Who They Are", P_WARDEN .. "#At the Table", P_MARA })
  pPublish()
  local record = H.pages["State/Published"]
  ok(record, "a record")
  has(record, "# Published to players")
  has(record, "- [[" .. P_MARA .. "]], saved 1970-01-01 00:00:01 UTC" .. P_NL)
  has(record, "- [[" .. P_WARDEN .. "#At the Table]], saved 1970-01-01 00:00:01 UTC" .. P_NL ..
              "- [[" .. P_WARDEN .. "#Who They Are]], saved 1970-01-01 00:00:01 UTC" .. P_NL)
  eq(gm.readPublished()[P_WARDEN].saved, "1970-01-01 00:00:01 UTC")
  local writes = #H.writes
  pPublish()
  eq(#H.writes, writes, "a publish that changes nothing writes nothing, the record included")
end)

test("behind: a part revealed since publishing isn't published yet, and the bar says so", "dm", function()
  gm.writeRevealed({})
  gm.revealPart(P_WARDEN, "Who They Are")
  pPublish()
  has(textOf(gm.bar(P_WARDEN).html), "◔ Revealed in part: Who They Are")
  hasnt(textOf(gm.bar(P_WARDEN).html), "not published yet")
  gm.revealPart(P_WARDEN, "At the Table")
  local text = textOf(gm.bar(P_WARDEN).html)
  has(text, "◔ Revealed in part: At the Table, Who They Are")
  has(text, "◔ 1 part not published yet")
  pPublish()
  hasnt(textOf(gm.bar(P_WARDEN).html), "not published yet", "published, it catches up")
end)

test("behind: a page saved since publishing has changed since, and the bar says so", "dm", function()
  gm.writeRevealed({ P_WARDEN })
  pPublish()
  local text = textOf(gm.bar(P_WARDEN).html)
  has(text, "◉ Revealed to players")
  hasnt(text, "Changed since")
  H.modified[P_WARDEN .. ".md"] = 5000000
  has(textOf(gm.bar(P_WARDEN).html), "◐ Changed since publishing")
  pPublish()
  hasnt(textOf(gm.bar(P_WARDEN).html), "Changed since", "published again, it catches up")
end)

test("behind: a page revealed whole after a part was published isn't out whole yet", "dm", function()
  gm.writeRevealed({})
  gm.revealPart(P_WARDEN, "Who They Are")
  pPublish()
  gm.reveal(P_WARDEN)
  local text = textOf(gm.bar(P_WARDEN).html)
  has(text, "◉ Revealed to players")
  has(text, "◔ Whole page not published yet")
end)

test("behind: a part taken back since publishing leaves their copy changed", "dm", function()
  gm.writeRevealed({})
  gm.revealPart(P_WARDEN, "Who They Are")
  gm.revealPart(P_WARDEN, "At the Table")
  pPublish()
  gm.writeRevealed({ P_WARDEN .. "#Who They Are" })
  has(textOf(gm.bar(P_WARDEN).html), "◐ Changed since publishing")
end)

test("behind: a copy published before the record says nothing more", "dm", function()
  gm.writeRevealed({ P_WARDEN })
  H.pages["Player/World/People/The Warden"] = "# The Warden\n"
  local text = textOf(gm.bar(P_WARDEN).html)
  has(text, "◉ Revealed to players")
  hasnt(text, "not published yet")
  hasnt(text, "Changed since")
end)

------------------------------------------------ a page renamed

local P_MARA2 = "Adventure/World/People/Mara the Ferrywoman"

-- What SilverBullet's rename does, as far as GM Kit can see: the page moves,
-- and every link to it is rewritten, the revealed list's and a play state's
-- subject among them, `short` as linkWriteFormat: shortest-suffix may write
-- one. The players' copy and the play state stay where they were.
local function rename(from, to, short)
  H.pages[to], H.pages[from] = H.pages[from], nil
  local written = short and to:sub(#"Adventure/" + 1) or to
  local pattern = "%[%[" .. (from:gsub("%p", "%%%0")) .. "([#|%]])"
  for name, text in pairs(H.pages) do
    local new = text:gsub(pattern, function(tail) return "[[" .. written .. tail end)
    if new ~= text then H.pages[name] = new end
  end
end

test("renamed: the play state follows the page by its subject", "dm", function()
  gm.mark(P_MARA, "met")
  -- a page with no record reads the records by their subjects, before the rename
  eq(gm.readState("Adventure/World/People/Old Tam").met, nil)
  rename(P_MARA, P_MARA2)
  has(H.pages["State/People/Mara"], 'subject: "[[' .. P_MARA2 .. ']]"', "as the rename leaves it")
  eq(gm.readState(P_MARA2).met, "true")
  local bar = gm.bar(P_MARA2)
  has(textOf(bar.html), "✓ Met in [[Sessions/Session 1|session 1]]")
  has(textOf(bar.html), "[[State/People/Mara|Play state]]")
  eq(list(buttonsOf(bar.html)), "Reveal all | Reveal part… | Unreveal | Mark dead… | Unmark met")
  eq(gm.mark(P_MARA2, "met"), false, "met already")
  H.prompts = { "Drowned" }
  gm.markDead(P_MARA2)
  has(H.pages["State/People/Mara"], "status: dead", "into the record it has")
  eq(H.pages["State/People/Mara the Ferrywoman"], nil, "and no second one")
end)

test("renamed: a subject written the short way still names the page", "dm", function()
  gm.mark(P_MARA, "met")
  rename(P_MARA, P_MARA2, true)
  has(H.pages["State/People/Mara"], 'subject: "[[World/People/Mara the Ferrywoman]]"')
  eq(gm.readState(P_MARA2, true).met, "true")
  eq(gm.readState(P_MARA2).met, "true")
end)

test("renamed: publishing offers to delete the copy the old name left, and Undo brings it back", "dm", function()
  gm.writeRevealed({ P_MARA })
  pPublish()
  local old = H.pages["Player/World/People/Mara"]
  ok(old, "published under its old name")
  rename(P_MARA, P_MARA2)
  pPublish(true)
  ok(H.pages["Player/World/People/Mara the Ferrywoman"], "published under its new one")
  eq(H.pages["Player/World/People/Mara"], nil, "and the old copy is gone")
  has(H.confirmsAsked[#H.confirmsAsked], "Delete the players' copies of 1 page no longer revealed")
  has(H.confirmsAsked[#H.confirmsAsked], "Player/World/People/Mara")
  local n = lastNotification()
  has(n.message, "Published to players: 1 new, 0 updated, 0 unchanged. " ..
      "Deleted the copies no revealed page makes any more: Player/World/People/Mara.")
  eq(H.pages["Player/index"], FIXTURES.dm["Player/index"], "the Player space's own pages stay")
  eq(H.pages["Player/Notes/index"], FIXTURES.dm["Player/Notes/index"])
  runAction(n, "Undo")
  eq(H.pages["Player/World/People/Mara"], old)
end)

test("renamed: a copy the DM keeps is named", "dm", function()
  gm.writeRevealed({ P_MARA })
  pPublish()
  rename(P_MARA, P_MARA2)
  pPublish(false)
  ok(H.pages["Player/World/People/Mara"], "kept")
  has(lastNotification().message,
      "The players still have copies no revealed page makes any more: Player/World/People/Mara.")
end)

test("orphans: a copy of a page unrevealed, or of none, is offered with nothing else to publish", "dm", function()
  gm.writeRevealed({})
  H.pages["Player/World/People/The Warden"] = "# The Warden\n"
  H.pages["Player/World/People/Nobody"] = "# Nobody\n"
  H.confirms = { true }
  ok(gm.publish())
  eq(#H.confirmsAsked, 1, "nothing to publish, so only the one question")
  has(H.confirmsAsked[1], "Delete the players' copies of 2 pages")
  eq(H.pages["Player/World/People/The Warden"], nil)
  eq(H.pages["Player/World/People/Nobody"], nil)
  has(lastNotification().message, "Nothing to publish. Deleted the copies no revealed page makes any more: " ..
      "Player/World/People/Nobody, Player/World/People/The Warden.")
end)

test("links: a page published beside it keeps its links and embeds", "dm", function()
  useCrypt()
  gm.setRevealed(P_MARA, true)
  gm.setRevealed(P_WARDEN, true)
  pPublish()
  local copy = H.pages[P_CRYPT_COPY]
  has(copy, "[[Adventure/World/People/Mara|A friend]] rows the ferry")
  has(copy, P_NL .. "![[World/People/The Warden#What They Want]]" .. P_NL)
  has(copy, P_NL .. "![[World/People/Mara]]" .. P_NL)
  hasnt(lastNotification().message, "Embeds left out")
end)
