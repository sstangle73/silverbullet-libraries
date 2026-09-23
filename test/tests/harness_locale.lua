------------------------------------------------------------------ Harness: the C locale
-- Lua's %s, %a and string.lower ask the C library, which follows the locale.
-- On Windows, Python starts with LC_CTYPE in a code page such as 1252, where
-- byte 0xA0 is a space and 0xC3 a letter; a UTF-8 character holds such
-- bytes, and a pattern cut it in half. SilverBullet's strings are
-- JavaScript's, whose classes stop at ASCII, so run.py sets the C locale
-- before it makes a runtime. The checks compare here in Lua: a string cut
-- in half is not UTF-8, and would not reach Python whole.

test("harness: a pattern's classes stop at ASCII, and keep every byte of a character", "dm", function()
  -- à is C3 A0, ■ is E2 96 A0, † is E2 80 A0
  eq((("à la carte"):gsub("%s+", " ")), "à la carte")
  eq((("x■"):gsub("%s+$", "")), "x■")
  eq((("a † b"):gsub("%s+", " ")), "a † b")
  eq((("†"):gsub("%s", "")), "†")
  eq(("é"):find("%a"), nil, "%a found a letter in a byte of é")
  eq(("Àb"):lower(), "Àb", "string.lower changed a byte of À")
  -- Ú is C3 9A, and 9A is š in 1252, whose capital is 8A: Ê
  eq(("Úb"):upper(), "ÚB", "string.upper changed a byte of Ú")
end)
