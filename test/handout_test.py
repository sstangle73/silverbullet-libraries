"""Tests for tools/handout.py, which fills Wizards of the Coast's 2024
character sheet from a page in GM Sheets' shape.

usage: python test/handout_test.py

The handout works the sheet's numbers out in Python, so they are held here
against GM Sheets' own Lua, on the same pages: the made-up ranger in
tests/sheets.lua, with and without numbers written over the sums, and the
made-up D&D Beyond characters as GM Beyond imports them. Filling is tested
on a blank stand-in with the sheet's size, so no test needs WotC's PDF; if
it has been fetched into the cache, it is filled too. Everything the script
writes goes to a temporary folder.
"""
import contextlib
import io
import pathlib
import sys
import tempfile

TEST = pathlib.Path(__file__).parent
sys.path.insert(0, str(TEST))
sys.path.insert(0, str(TEST.parent / "tools"))
import handout  # noqa: E402
import run  # noqa: E402

from pypdf import PdfReader, PdfWriter  # noqa: E402

failures = []
passed = 0


def check(name, got, want):
    global passed
    if got == want:
        passed += 1
    else:
        failures.append(f"{name}: expected {want!r}, got {got!r}")


def ranger():
    src = (TEST / "tests" / "sheets.lua").read_text(encoding="utf-8")
    at = src.index("local RANGER = [==[")
    return src[src.index("[==[", at) + 4:src.index("]==]", at)]


IMPORTED = {"1001": "Bram Holloway", "1002": "Ilse Marrow", "1003": "Cass Ironwood",
            "1004": "Wren Ashdown", "1005": "Sorrel Fenwick"}


def imported(L):
    """The made-up D&D Beyond characters' pages as GM Beyond writes them."""
    L.execute('reset("dm")')
    L.execute('''
__imported = {}
for name, body in pairs(DDB) do
  H.responses[gmb.endpoint .. tostring(body.data.id)] = { ok = true, status = 200, body = body }
end
for _, id in ipairs({ "1001", "1002", "1003", "1004", "1005" }) do
  __imported[id] = H.pages[gmb.import(id)]
end
''')
    pages = L.globals().__imported
    return {name: pages[id] for id, name in IMPORTED.items()}


def lua_values(L, text):
    L.execute('reset("dm")')
    L.globals().H.pages["Party/Test"] = text
    v = L.eval('sheets.values(assert(sheets.read("Party/Test")))')
    out = {"pb": v.pb, "initiative": v.initiative, "spell_dc": v.spellDC, "spell_attack": v.spellAttack}
    for a in handout.ABILITIES:
        out[f"mod {a}"] = v.mods[a]
        out[f"save {a}"] = v.saves[a]
        out[f"save prof {a}"] = bool(v.saveProf[a])
    for s in handout.SKILLS:
        out[f"skill {s}"] = v.skills[s]
        out[f"skill prof {s}"] = v.skillProf[s]
    for s in ("perception", "insight", "investigation"):
        out[f"passive {s}"] = v.passive[s]
    return out


def py_values(space, name):
    v = handout.values(handout.read_page(space, name))
    out = {"pb": v["pb"], "initiative": v["initiative"], "spell_dc": v["spell_dc"], "spell_attack": v["spell_attack"]}
    for a in handout.ABILITIES:
        out[f"mod {a}"] = v["mods"][a]
        out[f"save {a}"] = v["saves"][a]
        out[f"save prof {a}"] = v["save_prof"][a]
    for s in handout.SKILLS:
        out[f"skill {s}"] = v["skills"][s]
        out[f"skill prof {s}"] = v["skill_prof"][s]
    for s in ("perception", "insight", "investigation"):
        out[f"passive {s}"] = v["passive"][s]
    return out


def blank_template(path):
    w = PdfWriter()
    w.add_blank_page(handout.PAGE_W, handout.PAGE_H)
    w.add_blank_page(handout.PAGE_W, handout.PAGE_H)
    with open(path, "wb") as f:
        w.write(f)


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    L = run.build()
    L.execute((TEST / "framework.lua").read_text(encoding="utf-8"))
    pages = {"Tamsin Reed": ranger()}
    pages["Tamsin Written"] = ranger().replace(
        "hp: 28", "hp: 28\ninitiative: 5\nstr_save: 9\narcana: 4\npassive_perception: 11\nspell_dc: 15\npb: 3")
    pages.update(imported(L))
    with tempfile.TemporaryDirectory() as tmp:
        space = pathlib.Path(tmp)
        (space / "Party").mkdir()
        for name, text in pages.items():
            (space / "Party" / f"{name}.md").write_text(text, encoding="utf-8", newline="\n")

        # the sums, the same in both languages
        for name, text in pages.items():
            lua = lua_values(L, text)
            py = py_values(space, f"Party/{name}")
            for k in lua:
                check(f"{name}: {k}", py[k], lua[k])

        # a sheet filled on a stand-in the sheet's size
        template = space / "blank.pdf"
        blank_template(template)
        d = handout.read_page(space, "Party/Tamsin Reed")
        filled = PdfReader(io.BytesIO(handout.fill(template, d, "Tamsin Reed", [("want", "Want")])))
        check("pages: the sheet's two, and one for the rules text", len(filled.pages), 3)
        front = filled.pages[0].extract_text()
        for want in ("Tamsin Reed", "Ranger", "Hunter", "Human", "Guide", "+3", "15", "28", "3d10",
                     "30 ft.", "Medium", "19", "Longbow", "+7", "1d8+3 Piercing", "Favored Enemy: 2, Long Rest",
                     "Deft Explorer", "Resourceful", "Alert", "Simple, Martial", "Herbalism Kit"):
            check(f"front has {want}", want in front, True)
        back = filled.pages[1].extract_text()
        for want in ("Wisdom", "12", "+4", "Cure Wounds", "Goodberry", "Hunter's Mark", "Bonus", "90 ft.",
                     "always prepared", "Common, Elvish", "Quiver (20 arrows)", "12", "4"):
            check(f"back has {want}", want in back, True)
        rest = filled.pages[2].extract_text()
        check("the kit on the extra page", "Once the guild outfits her" in rest, True)
        check("the rules in full", "You have Expertise in Survival." in rest, True)
        check("no Want on this page", "Want:" in back, False)

        # a campaign's key in Backstory & Personality
        d["want"] = "Home"
        filled = PdfReader(io.BytesIO(handout.fill(template, d, "Tamsin Reed", [("want", "Want")])))
        check("the Want", "Want: Home" in filled.pages[1].extract_text(), True)

        # a long list overflows onto the extra pages, all of it
        d["equipment"] = [f"Thing {i}" for i in range(1, 200)]
        filled = PdfReader(io.BytesIO(handout.fill(template, d, "Tamsin Reed", [])))
        text = "".join(p.extract_text() for p in filled.pages[2:])
        check("equipment that outgrew its box", "Thing 199" in text, True)

        # every page from the command line, into the folder asked for
        out = space / "out"
        sys.argv = ["handout.py", str(space), "--template", str(template), "--out", str(out), "--extras", "want:Want"]
        try:
            handout.main()
        except SystemExit:
            pass
        made = sorted(p.name for p in out.glob("*.pdf"))
        check("one handout per pc page", made, sorted(f"{name}.pdf" for name in pages))

        # a key present but left blank prints nothing, never "None"
        d = handout.read_page(space, "Party/Tamsin Reed")
        for k in ("subclass", "background", "species", "class", "ac", "hp", "hit_dice", "creature_size", "speed"):
            d[k] = None
        d["attacks"] = [{"name": None, "hit": None, "damage": None, "notes": None}, None]
        d["resources"] = [{"name": "Luck", "uses": None, "reset": None}]
        d["features"] = [{"name": None, "text": None}]
        d["want"] = None
        filled = PdfReader(io.BytesIO(handout.fill(template, d, "Tamsin Reed", [("want", "Want")])))
        text = "".join(p.extract_text() for p in filled.pages)
        check("a blank key prints nothing", "None" in text, False)
        check("a resource with blank uses keeps its name", "Luck:" in text, True)

        # a letter the sheet's font can't show, as the nearest it can, and said
        d = handout.read_page(space, "Party/Tamsin Reed")
        d["species"] = "Wood Elf of Łódź"
        d["weapons"] = ["Simple", "Dragon 🐉 Bow"]
        d["features"] = [{"name": "Đurađ's Gift", "text": "Ħope, **twice**."}]
        err = io.StringIO()
        with contextlib.redirect_stderr(err):
            filled = PdfReader(io.BytesIO(handout.fill(template, d, "Łucja Dvořák", [])))
        front = filled.pages[0].extract_text()
        check("a letter the font lacks, as the nearest it has", "Lucja Dvorák" in front, True)
        check("the species' too", "Wood Elf of Lódz" in front, True)
        check("a ? only for what has no near letter", "Dragon ? Bow" in front, True)
        check("the rules text's too", "Durad's Gift. Hope, twice." in filled.pages[2].extract_text(), True)
        said = err.getvalue()
        check("the script says so", 'warning: Łucja Dvořák: the sheet\'s font can\'t show every letter of '
              '"Łucja Dvořák", so it is printed "Lucja Dvorák"\n' in said, True)
        check("and says so once", said.count('printed "Lucja Dvorák"'), 1)
        check("and where it printed a ?", 'printed "Simple, Dragon ? Bow", a ? for what has no near letter' in said, True)

        # Backstory & Personality that outgrows its box: the rest after the sheet, and said
        d = handout.read_page(space, "Party/Tamsin Reed")
        extras = [(f"k{i}", f"Key {i}") for i in range(30)]
        for i in range(30):
            d[f"k{i}"] = f"value {i}"
        err = io.StringIO()
        with contextlib.redirect_stderr(err):
            filled = PdfReader(io.BytesIO(handout.fill(template, d, "Tamsin Reed", extras)))
        check("the backstory the box had no room for", "Key 29: value 29" in
              "".join(p.extract_text() for p in filled.pages[2:]), True)
        check("and a warning", "warning: Tamsin Reed: Backstory & Personality holds more than its box" in
              err.getvalue(), True)

        # each page's writing given to it through pypdf's public API
        from pypdf import PageObject
        given, real = [], PageObject.replace_contents

        def recording(page, content):
            given.append(content)
            return real(page, content)

        PageObject.replace_contents = recording
        try:
            handout.fill(template, handout.read_page(space, "Party/Tamsin Reed"), "Tamsin Reed", [])
        finally:
            PageObject.replace_contents = real
        # pypdf's merge_page gives pages contents this way too: only the layers' writing counts
        ours = [c for c in given if hasattr(c, "get_data") and c.get_data().startswith(handout.INK)]
        check("the sheet's two pages and the extra one, through PageObject.replace_contents", len(ours), 3)

        # saves and skills as GM Sheets may take them, names separated by commas
        (space / "Party" / "Tamsin Commas.md").write_text(ranger().replace("saves: [str, dex]", "saves: str, dex").replace(
            "skills: [athletics, nature, perception, stealth, survival]",
            "skills: athletics, nature, perception, stealth, survival"), encoding="utf-8", newline="\n")
        py = py_values(space, "Party/Tamsin Commas")
        check("comma-separated saves and skills read as lists", py, py_values(space, "Party/Tamsin Reed"))
        commas = (space / "Party" / "Tamsin Commas.md").read_text(encoding="utf-8")
        lua = lua_values(L, commas)
        if lua == lua_values(L, ranger()):
            for k in lua:
                check(f"Tamsin Commas: {k}", py[k], lua[k])
        else:
            print("note: GM Sheets doesn't read comma-separated saves and skills yet, so they weren't held against it")

        # spell slots as a list, a string of numbers, or a map by level
        check("slots from a list", handout.slot_counts([4, 3, 0, 2]), {1: 4, 2: 3, 4: 2})
        check("slots from a string", handout.slot_counts("4, 3"), {1: 4, 2: 3})
        check("slots by level", handout.slot_counts({1: 4, "2": 3, "x": 1}), {1: 4, 2: 3})
        check("no slots", handout.slot_counts(None), {})
        layer = handout.Layer()
        handout.fill_back(layer, {"slots": {1: 4, "2": 3}}, handout.values({}), [], [])
        check("a map's slots drawn by level", (b"680.80 Td (4) Tj" in layer.data(), b"666.80 Td (3) Tj" in layer.data()),
              (True, True))

        # the rules text GM Beyond escapes, printed as the words it shows
        check("an escaped character as itself", handout.plain(
            r"\<b\> **2 \* 3** \$\{x\} \[\[Secret\]\] a\_b \\ *c*"), r"<b> 2 * 3 ${x} [[Secret]] a_b \ c")

    # the real sheet, if it has been fetched
    cached = pathlib.Path("~/.cache/gm-sheets/DnD_2024_Character-Sheet.pdf").expanduser()
    if cached.exists():
        with tempfile.TemporaryDirectory() as tmp:
            space = pathlib.Path(tmp)
            (space / "Party").mkdir()
            (space / "Party" / "Tamsin Reed.md").write_text(ranger(), encoding="utf-8", newline="\n")
            d = handout.read_page(space, "Party/Tamsin Reed")
            filled = PdfReader(io.BytesIO(handout.fill(cached, d, "Tamsin Reed", [])))
            check("the real sheet, filled", len(filled.pages), 3)
    else:
        print("note: the 2024 sheet isn't in ~/.cache/gm-sheets, so it wasn't filled")

    for f in failures:
        print("FAIL", f)
    print(f"{passed}/{passed + len(failures)} passed")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
