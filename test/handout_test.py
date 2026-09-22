"""Tests for tools/handout.py, which fills Wizards of the Coast's 2024
character sheet from a page in GM Sheets' shape.

usage: python test/handout_test.py

The handout works the sheet's numbers out in Python, so they are held here
against GM Sheets' own Lua, on the same pages: the made-up ranger in
tests/sheets.lua, with and without numbers written over the sums, and the
two made-up D&D Beyond characters as GM Beyond imports them. Filling is
tested on a blank stand-in with the sheet's size, so no test needs WotC's
PDF; if it has been fetched into the cache, it is filled too.
"""
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


def imported(L):
    """Bram's and Ilse's pages as GM Beyond writes them."""
    L.execute('reset("dm")')
    L.execute('''
for _, name in ipairs({ "bram", "ilse" }) do
  local body = DDB[name]
  H.responses[gmb.endpoint .. tostring(body.data.id)] = { ok = true, status = 200, body = body }
end
__bram = H.pages[gmb.import("1001")]
__ilse = H.pages[gmb.import("1002")]
''')
    g = L.globals()
    return {"Bram Holloway": g.__bram, "Ilse Marrow": g.__ilse}


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
        check("one handout per pc page", made, ["Bram Holloway.pdf", "Ilse Marrow.pdf", "Tamsin Reed.pdf", "Tamsin Written.pdf"])

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
