"""Fill Wizards of the Coast's 2024 character sheet with a character from a
SilverBullet page in GM Sheets' shape: a handout for your own table.

usage: python tools/handout.py SPACE [PAGE ...] [--out DIR] [--type TYPE]
                               [--extras KEY:LABEL,...] [--template PDF] [--cache DIR]

SPACE is the folder a SilverBullet space serves, and a PAGE is a page's name
in it, "Party/Tamsin Reed". With no PAGE, every page whose frontmatter has
`type: TYPE` (pc) is filled. Each goes to DIR, SPACE/Handouts unless you say,
as "<name>.pdf": the two pages of the sheet with the character written in,
then as many plain pages as the rest needs, the features, traits and feats
with their rules and whatever outgrew its box.

The numbers are GM Sheets' own: a number the page writes, or else the SRD's
sum for it. --extras names a campaign's own keys to put in the sheet's
Backstory & Personality box, "want:Want" for a key `want` shown as "Want";
what doesn't fit there goes on the pages after the sheet.

The sheet's font shows the letters of Windows' Western alphabet (cp1252). A
letter it can't show is printed as the nearest it can, Łucja Dvořák as Lucja
Dvorák, and the script says so; a key left blank prints nothing.

The sheet is Wizards of the Coast's, and its only terms are that you may
print and photocopy it for personal use. So nothing here carries it: the
first run fetches it from D&D Beyond into a cache outside the space
(--cache), and a filled copy is for your table, never for anything
published. Keep DIR out of version control. The positions below were
measured on one printing of the sheet, which the script checks by its hash,
and it says so if D&D Beyond ever serves a different one.

Needs `pip install pypdf pyyaml`.
"""
import argparse
import hashlib
import math
import pathlib
import re
import sys
import unicodedata
import urllib.request

TEMPLATE_URL = "https://media.dndbeyond.com/compendium-images/phb/downloads/DnD_2024_Character-Sheet.pdf"
TEMPLATE_SHA256 = "f223ca7bf03bcb4062ed1487816c1c1fd8b8d51d49011bfd02d63cad75f54454"
PAGE_W, PAGE_H = 603, 774
INK = b"0.09 0.11 0.27"  # a dark blue-black, as a pen would write

ABILITIES = ["str", "dex", "con", "int", "wis", "cha"]
ABILITY_NAMES = {"str": "Strength", "dex": "Dexterity", "con": "Constitution",
                 "int": "Intelligence", "wis": "Wisdom", "cha": "Charisma"}
SKILLS = {
    "acrobatics": "dex", "animal_handling": "wis", "arcana": "int", "athletics": "str",
    "deception": "cha", "history": "int", "insight": "wis", "intimidation": "cha",
    "investigation": "int", "medicine": "wis", "nature": "int", "perception": "wis",
    "performance": "cha", "persuasion": "cha", "religion": "int", "sleight_of_hand": "dex",
    "stealth": "dex", "survival": "wis",
}

# Where each ability's labels sit on the sheet's first page, in points from
# its bottom left: the modifier's and the score's, the saving throw's, and
# each skill's. Every value is placed from its own label.
ABILITY_LABELS = {
    "str": {"mod": (28.2, 525.2), "score": (64.0, 530.3), "save": (47.9, 506.2),
            "skills": [("athletics", 47.0, 486.2)]},
    "dex": {"mod": (28.1, 407.4), "score": (63.9, 412.5), "save": (47.9, 388.5),
            "skills": [("acrobatics", 46.9, 368.4), ("sleight_of_hand", 46.9, 354.4), ("stealth", 46.9, 340.4)]},
    "con": {"mod": (28.2, 261.5), "score": (64.0, 266.6), "save": (47.9, 242.6), "skills": []},
    "int": {"mod": (134.4, 602.6), "score": (170.1, 607.6), "save": (154.1, 583.6),
            "skills": [("arcana", 153.1, 563.6), ("history", 153.1, 549.6), ("investigation", 153.1, 535.6),
                       ("nature", 153.1, 521.5), ("religion", 153.1, 507.5)]},
    "wis": {"mod": (134.4, 428.7), "score": (170.1, 433.7), "save": (154.1, 409.7),
            "skills": [("animal_handling", 153.1, 389.7), ("insight", 153.1, 375.7), ("medicine", 153.1, 361.7),
                       ("perception", 153.1, 347.7), ("survival", 153.1, 333.7)]},
    "cha": {"mod": (134.4, 254.7), "score": (170.1, 259.8), "save": (154.1, 235.8),
            "skills": [("deception", 153.1, 215.7), ("intimidation", 153.1, 201.7),
                       ("performance", 153.1, 187.7), ("persuasion", 153.1, 173.7)]},
}
SKILL_LABELS = {"athletics": "Athletics", "acrobatics": "Acrobatics", "sleight_of_hand": "Sleight of Hand",
                "stealth": "Stealth", "arcana": "Arcana", "history": "History", "investigation": "Investigation",
                "nature": "Nature", "religion": "Religion", "animal_handling": "Animal Handling",
                "insight": "Insight", "medicine": "Medicine", "perception": "Perception",
                "survival": "Survival", "deception": "Deception", "intimidation": "Intimidation",
                "performance": "Performance", "persuasion": "Persuasion"}

# Helvetica's widths, ASCII 32 to 126, in thousandths of an em.
HELV = [
    278, 278, 355, 556, 556, 889, 667, 191, 333, 333, 389, 584, 278, 333, 278, 278,
    556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 584, 584, 584, 556, 1015,
    667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556, 833, 722, 778, 667, 778,
    722, 667, 611, 722, 667, 944, 667, 667, 611, 278, 278, 278, 469, 556, 333,
    556, 556, 500, 556, 556, 278, 556, 556, 222, 222, 500, 222, 833, 556, 556, 556, 556,
    333, 500, 278, 556, 500, 722, 500, 500, 500, 334, 260, 334, 584,
]


# And Helvetica-Bold's.
HELV_BOLD = [
    278, 333, 474, 556, 556, 889, 722, 238, 333, 333, 389, 584, 278, 333, 278, 278,
    556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 333, 333, 584, 584, 584, 611, 975,
    722, 722, 722, 722, 667, 611, 778, 722, 278, 556, 722, 611, 833, 722, 778, 667, 778,
    722, 667, 611, 722, 667, 944, 667, 667, 611, 333, 278, 333, 584, 556, 333,
    556, 611, 556, 611, 556, 333, 611, 611, 278, 278, 556, 278, 889, 611, 611, 611, 611,
    389, 556, 333, 611, 556, 778, 556, 556, 500, 389, 280, 389, 584,
]
# The few characters past ASCII that rules text uses, regular and bold.
EXTRA_WIDTHS = {"’": (222, 278), "‘": (222, 278), "“": (333, 500), "”": (333, 500),
                "–": (556, 556), "—": (1000, 1000), "…": (1000, 1000), "é": (556, 556),
                "×": (584, 584), "½": (834, 834), "•": (350, 350), "°": (400, 400)}


# Letters Unicode can't take apart into a Western one and a mark, as the
# nearest the sheet's font shows.
TRANSLITERATED = {"Ł": "L", "ł": "l", "Đ": "D", "đ": "d", "Ħ": "H", "ħ": "h", "ı": "i", "Ŧ": "T",
                  "ŧ": "t", "Ŋ": "N", "ŋ": "n", "ĸ": "k", "ſ": "s", "Ə": "E", "ə": "e",
                  "‐": "-", "‑": "-", "−": "-", "′": "'", "″": '"', "→": "->", "←": "<-",
                  "≤": "<=", "≥": ">=", "≠": "!="}

# What filling the sheet had to warn about, said once each when it is done.
WARNINGS = []


def warn(message):
    if message not in WARNINGS:
        WARNINGS.append(message)


def shown(s):
    """Text as the sheet's font can show it: each letter it has kept, one it
    hasn't as the nearest it has (Ł as L, ř as r), and a warning that says
    so. Only what has no near letter at all becomes a ?."""
    s = str(s)
    out, lost = [], False
    for ch in s:
        try:
            ch.encode("cp1252")
            out.append(ch)
            continue
        except UnicodeEncodeError:
            pass
        near = TRANSLITERATED.get(ch)
        if near is None:
            near = "".join(c for c in unicodedata.normalize("NFKD", ch) if not unicodedata.combining(c))
            try:
                near.encode("cp1252")
            except UnicodeEncodeError:
                near = ""
        if not near:
            near, lost = "?", True
        out.append(near)
    printed = "".join(out)
    if printed != s:
        warn(f'the sheet\'s font can\'t show every letter of "{s}", so it is printed "{printed}"'
             + (", a ? for what has no near letter" if lost else ""))
    return printed


def text_width(s, size, bold=False):
    table = HELV_BOLD if bold else HELV
    total = 0
    for ch in s:
        o = ord(ch)
        if 32 <= o <= 126:
            total += table[o - 32]
        else:
            total += EXTRA_WIDTHS.get(ch, (600, 600))[1 if bold else 0]
    return total * size / 1000


def fitted(s, width, size, smallest, bold=False):
    """The text and a size at which it fits width, cut short with an
    ellipsis if it won't fit even at the smallest."""
    at = size
    while at > smallest and text_width(s, at, bold) > width:
        at -= 0.25
    if text_width(s, at, bold) <= width:
        return s, at
    while len(s) > 1 and text_width(s + "…", at, bold) > width:
        s = s[:-1]
    return s.rstrip() + "…", at


def wrapped(s, width, size, bold=False):
    lines, line = [], ""
    for word in s.split():
        attempt = word if not line else line + " " + word
        if line and text_width(attempt, size, bold) > width:
            lines.append(line)
            line = word
        else:
            line = attempt
    if line:
        lines.append(line)
    return lines


# ------------------------------------------------------------------ the page


def read_page(space, name):
    import yaml
    path = pathlib.Path(space) / (name + ".md")
    text = path.read_text(encoding="utf-8")
    m = re.match(r"---\r?\n(.*?)\r?\n---", text, re.S)
    if not m:
        raise SystemExit(f"{name}: no frontmatter to fill a sheet from")
    data = yaml.safe_load(m.group(1)) or {}
    if not isinstance(data, dict):
        raise SystemExit(f"{name}: its frontmatter isn't a map of keys")
    return data


def number(v):
    if isinstance(v, bool):
        return None
    if isinstance(v, (int, float)):
        return v
    if isinstance(v, str):
        try:
            return float(v.strip().lstrip("+"))
        except ValueError:
            return None
    return None


def whole(v):
    n = number(v)
    return None if n is None else math.floor(n)


def items(v):
    if v is None:
        return []
    return list(v) if isinstance(v, list) else [v]


def text_of(v):
    """A value from the page as the sheet prints it: nothing for a key left
    blank, a whole number without a .0, true and false as YAML spells them."""
    if v is None:
        return ""
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, float) and v.is_integer():
        return str(int(v))
    return str(v)


def names_in(v):
    """A list of names from a page: a list, one name, or a string of names
    separated by commas, `athletics, perception`."""
    if isinstance(v, str):
        return [p.strip() for p in v.split(",") if p.strip()]
    return [e for e in items(v) if e is not None]


def slot_counts(v):
    """Spell slots by level from a page: a list, [4, 3], its numbers in a
    string, "4, 3", or a map by level, whose keys YAML may read as numbers or
    as text, {1: 4, "2": 3}."""
    out = {}
    if isinstance(v, dict):
        for k, n in v.items():
            level, n = whole(k), whole(n)
            if level and n:
                out[level] = n
        return out
    for i, n in enumerate(names_in(v), 1):
        n = whole(n)
        if n:
            out[i] = n
    return out


def key(v):
    return re.sub(r"[\s\-]+", "_", str(v).strip().lower())


def ability_key(v):
    if v is None:
        return None
    k = key(v)
    for a, full in ABILITY_NAMES.items():
        if k in (a, full.lower()):
            return a
    return None


def keyset(v):
    out = set()
    for e in names_in(v):
        k = key(e)
        out.add(k)
        a = ability_key(re.sub(r"_saves?$", "", k))
        if a:
            out.add(a + "_save")
    return out


def signed(n):
    return "" if n is None else (f"+{n}" if n >= 0 else f"-{-n}")


def values(d):
    """Every number the sheet shows, as GM Sheets works them out: a number
    the page writes, or else the SRD's sum."""
    level = max(1, whole(d.get("level")) or 1)
    v = {"pb": whole(d.get("pb")) or 2 + (level - 1) // 4, "scores": {}, "mods": {}, "saves": {},
         "save_prof": {}, "skills": {}, "skill_prof": {}, "adv": keyset(d.get("advantage"))}
    saves, skills, expert = keyset(d.get("saves")), keyset(d.get("skills")), keyset(d.get("expertise"))
    for a in ABILITIES:
        score = whole(d.get(a))
        m = None if score is None else (score - 10) // 2
        v["scores"][a], v["mods"][a] = score, m
        prof = (a + "_save") in saves
        v["save_prof"][a] = prof
        written = whole(d.get(a + "_save"))
        v["saves"][a] = written if written is not None else (None if m is None else m + (v["pb"] if prof else 0))
    for s, a in SKILLS.items():
        m = v["mods"][a]
        p = 2 if s in expert else (1 if s in skills else 0)
        v["skill_prof"][s] = p
        written = whole(d.get(s))
        v["skills"][s] = written if written is not None else (None if m is None else m + p * v["pb"])
    written = whole(d.get("initiative"))
    v["initiative"] = written if written is not None else v["mods"]["dex"]
    v["passive"] = {}
    for s in ("perception", "insight", "investigation"):
        written = whole(d.get("passive_" + s))
        skill = v["skills"][s]
        v["passive"][s] = written if written is not None else (
            None if skill is None else 10 + skill + (5 if s in v["adv"] else 0))
    v["casting"] = ability_key(d.get("spellcasting"))
    cm = v["mods"].get(v["casting"]) if v["casting"] else None
    written = whole(d.get("spell_dc"))
    v["spell_dc"] = written if written is not None else (None if cm is None else 8 + v["pb"] + cm)
    written = whole(d.get("spell_attack"))
    v["spell_attack"] = written if written is not None else (None if cm is None else v["pb"] + cm)
    return v


def name_of(e):
    if isinstance(e, dict):
        return text_of(e.get("name"))
    return text_of(e)


# A Markdown backslash escape, \< or \*, which GM Beyond writes in rules text
# so that nothing in it is read as markup: the character alone, once the
# emphasis around it is gone.
ESCAPED = re.compile(r"\\([!-/:-@\[-`{-~])")


def plain(text):
    """Markdown as plain words: emphasis gone, a list's dash kept, and an
    escaped character as itself."""
    s = str(text or "")
    # an escaped character stands aside, in Unicode's private use area,
    # while the emphasis goes, so an escaped * is never taken for one
    s = ESCAPED.sub(lambda m: chr(0xE000 + ord(m.group(1))), s)
    s = re.sub(r"\*\*\*(.+?)\*\*\*", r"\1", s)
    s = re.sub(r"\*\*(.+?)\*\*", r"\1", s)
    s = re.sub(r"(?<![\w*])\*(?!\s)(.+?)(?<!\s)\*(?!\w)", r"\1", s)
    s = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", s)
    return re.sub("[\ue000-\ue07f]", lambda m: chr(ord(m.group(0)) - 0xE000), s)


def by_level(v):
    out = {}
    if isinstance(v, dict):
        for k, lst in v.items():
            n = whole(k)
            if n is not None:
                out[n] = items(lst)
    return dict(sorted(out.items()))


# ------------------------------------------------------------------ drawing


def pdf_string(s):
    # shown() has made every letter one cp1252 has; "replace" is only a guard
    raw = s.encode("cp1252", "replace")
    raw = raw.replace(b"\\", b"\\\\").replace(b"(", b"\\(").replace(b")", b"\\)")
    return b"(" + raw + b")"


class Layer:
    """What is written on one page, as PDF drawing operators."""

    def __init__(self):
        self.ops = [INK + b" rg", INK + b" RG"]

    def text(self, x, y, s, size, bold=False, align="left"):
        s = shown(text_of(s))
        if s == "":
            return
        if align == "center":
            x -= text_width(s, size, bold) / 2
        elif align == "right":
            x -= text_width(s, size, bold)
        font = b"/F2" if bold else b"/F1"
        self.ops.append(b"BT %s %.2f Tf %.2f %.2f Td %s Tj ET" % (font, size, x, y, pdf_string(s)))

    def fit(self, x, y, s, width, size, smallest=5.5, bold=False, align="left"):
        s, at = fitted(shown(text_of(s)), width, size, smallest, bold)
        self.text(x, y, s, at, bold, align)

    def dot(self, x, y, r):
        k = 0.5523 * r
        self.ops.append(
            b"%.2f %.2f m %.2f %.2f %.2f %.2f %.2f %.2f c %.2f %.2f %.2f %.2f %.2f %.2f c "
            b"%.2f %.2f %.2f %.2f %.2f %.2f c %.2f %.2f %.2f %.2f %.2f %.2f c f" % (
                x + r, y,
                x + r, y + k, x + k, y + r, x, y + r,
                x - k, y + r, x - r, y + k, x - r, y,
                x - r, y - k, x - k, y - r, x, y - r,
                x + k, y - r, x + r, y - k, x + r, y))

    def ring(self, x, y, r, weight=0.8):
        k = 0.5523 * r
        self.ops.append(
            b"%.2f w %.2f %.2f m %.2f %.2f %.2f %.2f %.2f %.2f c %.2f %.2f %.2f %.2f %.2f %.2f c "
            b"%.2f %.2f %.2f %.2f %.2f %.2f c %.2f %.2f %.2f %.2f %.2f %.2f c S" % (
                weight, x + r, y,
                x + r, y + k, x + k, y + r, x, y + r,
                x - k, y + r, x - r, y + k, x - r, y,
                x - r, y - k, x - k, y - r, x, y - r,
                x + k, y - r, x + r, y - k, x + r, y))

    def diamond(self, x, y, r):
        self.ops.append(b"%.2f %.2f m %.2f %.2f l %.2f %.2f l %.2f %.2f l h f" % (
            x, y + r, x + r, y, x, y - r, x - r, y))

    def data(self):
        return b"\n".join(self.ops)


# ------------------------------------------------------------------ the sheet


def lines_in(layer, x, top, bottom, leading, width, texts, size=7.8, bold_heads=True):
    """Lines of text down a box, from top to bottom; returns what didn't fit."""
    y = top
    rest = []
    for i, entry in enumerate(texts):
        head = isinstance(entry, tuple)
        words = shown(entry[1] if head else entry)
        pieces = wrapped(words, width, size, head and bold_heads) or [""]
        if y - leading * (len(pieces) - 1) < bottom:
            rest.extend(texts[i:])
            break
        for piece in pieces:
            layer.text(x, y, piece, size, head and bold_heads)
            y -= leading
    return rest


def fill_front(layer, d, v, name, overflow):
    """The sheet's first page."""
    layer.fit(25, 744, name, 222, 13, bold=True)
    layer.fit(25, 722, d.get("background", ""), 115, 10)
    layer.fit(149, 722, d.get("class", ""), 102, 10)
    layer.fit(25, 701, d.get("species", ""), 115, 10)
    layer.fit(149, 701, d.get("subclass", ""), 102, 10)
    layer.text(276, 729, "" if whole(d.get("level")) is None else str(whole(d.get("level"))), 15, True, "center")
    layer.text(340.5, 719, text_of(d.get("ac")), 20, True, "center")
    layer.fit(438, 703, text_of(d.get("hp")), 46, 11, bold=True)
    layer.fit(492, 703, text_of(d.get("hit_dice")), 42, 10)
    layer.text(52.5, 616, signed(v["pb"]), 18, True, "center")
    speed = d.get("speed")
    # a number is feet, as GM Sheets writes it; text is as it stands
    number_ = isinstance(speed, (int, float)) and not isinstance(speed, bool)
    speed = f"{text_of(speed)} ft." if number_ else text_of(speed)
    initiative = signed(v["initiative"]) + (" ADV" if "initiative" in v["adv"] else "")
    layer.fit(263.5, 627, initiative, 70, 15, bold=True, align="center")
    layer.fit(354, 627, speed, 70, 12, bold=True, align="center")
    layer.fit(445.5, 627, text_of(d.get("creature_size")), 70, 11, align="center")
    passive = str(v["passive"]["perception"] if v["passive"]["perception"] is not None else "")
    layer.text(542, 627, passive, 15, True, "center")

    for a, spot in ABILITY_LABELS.items():
        mx, my = spot["mod"]
        layer.text(mx + 15.6, my + 19.5, signed(v["mods"][a]), 16, True, "center")
        sx, sy = spot["score"]
        layer.text(sx + 15, sy + 11.5, "" if v["scores"][a] is None else str(v["scores"][a]), 10, True, "center")
        tx, ty = spot["save"]
        layer.text(tx - 12, ty, signed(v["saves"][a]), 8.5, True, "center")
        if v["save_prof"][a]:
            layer.dot(tx - 26.1, ty + 2.7, 2.7)
        if (a + "_save") in v["adv"]:
            layer.text(tx + text_width("Saving Throw", 7.5, True) + 3, ty, "ADV", 5.5, True)
        for s, kx, ky in spot["skills"]:
            layer.text(kx - 11, ky, signed(v["skills"][s]), 8.5, True, "center")
            p = v["skill_prof"][s]
            if p >= 1:
                layer.dot(kx - 25.1, ky + 2.7, 2.7)
            if p == 2:
                layer.ring(kx - 25.1, ky + 2.7, 4.4)
            if s in v["adv"]:
                layer.text(kx + text_width(SKILL_LABELS[s], 7.5) + 3, ky, "ADV", 5.5, True)

    trained = keyset(d.get("armor_training"))
    for kind, x in (("light", 60), ("medium", 95), ("heavy", 139), ("shields", 176)):
        if kind in trained:
            layer.diamond(x, 125, 3.4)
    weapons = ", ".join(name_of(w) for w in items(d.get("weapons")))
    masteries = ", ".join(name_of(m) for m in items(d.get("masteries")))
    texts = [weapons] if weapons else []
    if masteries:
        texts.append(("m", "Mastery: " + masteries))
    rest = lines_in(layer, 16, 97, 56, 9, 190, texts, size=7.8, bold_heads=False)
    tools = ", ".join(name_of(t) for t in items(d.get("tools")))
    rest += lines_in(layer, 16, 40, 18, 9, 190, [tools] if tools else [])
    if rest:
        overflow.append(("Proficiencies", [r[1] if isinstance(r, tuple) else r for r in rest]))

    rows = [564.5, 545.1, 525.6, 506.2, 486.8, 467.3]
    attacks = items(d.get("attacks"))
    for row, a in zip(rows, attacks):
        if isinstance(a, dict):
            hit = a.get("hit")
            hit = signed(math.floor(hit)) if isinstance(hit, (int, float)) and not isinstance(hit, bool) else str(hit or "")
            layer.fit(228, row, a.get("name", ""), 104, 8.5, bold=True)
            layer.fit(358, row, hit, 42, 8.5, align="center")
            layer.fit(384, row, text_of(a.get("damage")), 74, 8.5)
            notes = shown(text_of(a.get("notes")))
            if text_width(notes, 7) <= 122:
                layer.text(462, row, notes, 7)
            else:
                two = wrapped(notes, 122, 6.3)
                layer.text(462, row + 4, two[0], 6.3)
                layer.fit(462, row - 3.4, " ".join(two[1:]), 122, 6.3)
        else:
            layer.fit(228, row, text_of(a), 104, 8.5, bold=True)
    if len(attacks) > len(rows):
        overflow.append(("More attacks", [attack_line(a) for a in attacks[len(rows):]]))

    features = []
    for r in items(d.get("resources")):
        if isinstance(r, dict):
            bits = [text_of(r.get("uses")), text_of(r.get("reset"))]
            features.append(f"{text_of(r.get('name'))}: " + ", ".join(b for b in bits if b))
    pact = whole(d.get("pact_slots"))
    if pact:
        level = whole(d.get("pact_level")) or 1
        features.append(f"Pact Magic: {pact} slot{'s' if pact != 1 else ''} of level {level}, Short Rest")
    features += [name_of(f) for f in items(d.get("features"))]
    per_column = int((416 - 208) / 8.6) + 1
    left, right = features[:per_column], features[per_column:2 * per_column]
    for i, f in enumerate(left):
        layer.fit(228, 416 - i * 8.6, f, 172, 7.8)
    for i, f in enumerate(right):
        layer.fit(411, 416 - i * 8.6, f, 174, 7.8)
    for i, t in enumerate(items(d.get("traits"))[:18]):
        layer.fit(228, 177 - i * 8.6, name_of(t), 170, 7.8)
    for i, f in enumerate(items(d.get("feats"))[:18]):
        layer.fit(413, 177 - i * 8.6, name_of(f), 172, 7.8)


def attack_line(a):
    if not isinstance(a, dict):
        return text_of(a)
    hit = a.get("hit")
    hit = signed(math.floor(hit)) + " to hit" if isinstance(hit, (int, float)) and not isinstance(hit, bool) else text_of(hit)
    parts = [p for p in (hit, text_of(a.get("damage"))) if p]
    line = f"{text_of(a.get('name'))}: " + ", ".join(parts)
    if a.get("notes"):
        line += f". {text_of(a['notes'])}"
    return line


SHORT_TIMES = {"Bonus Action": "Bonus", "Reaction": "Reaction", "Action": "Action"}


def spell_rows(d):
    """The sheet's spell table rows: cantrips, then prepared spells by level,
    always-prepared ones marked."""
    rows = []
    for e in items(d.get("cantrips")):
        rows.append((0, e, ""))
    prepared, always = by_level(d.get("spells")), by_level(d.get("always_prepared"))
    for level in sorted(set(prepared) | set(always)):
        for e in prepared.get(level, []):
            rows.append((level, e, ""))
        for e in always.get(level, []):
            rows.append((level, e, "always prepared"))
    return rows


def fill_back(layer, d, v, extras, overflow):
    """The sheet's second page."""
    if v["casting"]:
        layer.fit(25, 741.5, ABILITY_NAMES[v["casting"]], 105, 9, bold=True)
        layer.text(31, 709, signed(v["mods"][v["casting"]]), 13, True, "center")
    layer.text(31, 684, "" if v["spell_dc"] is None else str(v["spell_dc"]), 13, True, "center")
    layer.text(31, 657, signed(v["spell_attack"]), 13, True, "center")
    xs, ys = [185, 271, 348], [680.8, 666.8, 652.8]
    for level, n in slot_counts(d.get("slots")).items():
        i = level - 1
        if 0 <= i < 9:
            layer.text(xs[i // 3], ys[i % 3], str(n), 9, True, "center")
    pact = whole(d.get("pact_slots"))
    if pact:
        level = whole(d.get("pact_level")) or 1
        i = level - 1
        if 0 <= i < 9:
            layer.text(xs[i // 3], ys[i % 3], str(pact), 9, True, "center")

    rows = spell_rows(d)
    y0, step = 586.5, 19.435
    for i, (level, e, note) in enumerate(rows[:30]):
        y = y0 - i * step
        name = name_of(e)
        layer.text(27, y, str(level), 8.5, True, "center")
        layer.fit(42, y, name, 108, 8.5)
        if isinstance(e, dict):
            time = text_of(e.get("time"))
            time = SHORT_TIMES.get(time, time.replace(" minutes", " min").replace(" minute", " min")
                                   .replace(" hours", " hr").replace(" hour", " hr"))
            layer.fit(155, y, time, 31, 7.5)
            rng = text_of(e.get("range"))
            area = ""
            if " (" in rng:
                rng, area = rng.split(" (", 1)
                area = area.rstrip(")")
            layer.fit(188.5, y, rng, 42, 7.5)
            if e.get("concentration") is True:
                layer.diamond(243.3, y + 2.8, 2.6)
            if e.get("ritual") is True:
                layer.diamond(265.0, y + 2.8, 2.6)
            material = e.get("material")
            if material not in (None, False):
                layer.diamond(286.7, y + 2.8, 2.6)
            notes = [n for n in (area, material if isinstance(material, str) else "", text_of(e.get("notes")), note) if n]
            if notes:
                layer.fit(305, y, "; ".join(notes), 88, 6.5, smallest=5)
        elif note:
            layer.fit(305, y, note, 88, 6.5, smallest=5)
    if len(rows) > 30:
        overflow.append(("More spells", [f"Level {lvl}: {name_of(e)}" for lvl, e, _ in rows[30:]]))

    langs = ", ".join(name_of(x) for x in items(d.get("languages")))
    senses = ", ".join(name_of(x) for x in items(d.get("senses")))
    texts = [langs] if langs else []
    if senses:
        texts.append(("s", "Senses: " + senses))
    rest = lines_in(layer, 413, 424, 400, 9, 175, texts, bold_heads=False)
    gear = [name_of(x) for x in items(d.get("equipment"))]
    kit = d.get("kit") if isinstance(d.get("kit"), dict) else None
    texts = ["; ".join(gear)] if gear else []
    if kit and items(kit.get("equipment")):
        label = text_of(kit.get("label")) or "Another loadout"
        texts.append(("k", f"{label}: " + "; ".join(name_of(x) for x in items(kit.get("equipment")))))
    rest += lines_in(layer, 413, 355, 188, 8.8, 175, texts, bold_heads=False)
    if rest:
        overflow.append(("Equipment", [r[1] if isinstance(r, tuple) else r for r in rest]))
    for y, item in zip((166, 147, 129), items(d.get("attuned"))):
        layer.fit(432, y, name_of(item), 155, 8)
    coins = d.get("coins") if isinstance(d.get("coins"), dict) else {}
    for coin, x in zip(("cp", "sp", "ep", "gp", "pp"), (428, 464, 500, 536, 572)):
        n = whole(coins.get(coin))
        if n:
            layer.fit(x, 56, str(n), 28, 10, bold=True, align="center")
    texts = []
    for k, label in extras:
        if text_of(d.get(k)) != "":
            texts.append(f"{label}: {text_of(d.get(k))}")
    rest = lines_in(layer, 413, 628, 500, 10, 175, texts, size=9, bold_heads=False)
    if rest:
        overflow.append(("Backstory & Personality", rest))
        warn("Backstory & Personality holds more than its box, so the rest is on the pages after the sheet")


def more_pages(d, v, name, overflow):
    """The rest of the sheet on plain pages: the kit, what outgrew its box,
    and every feature, trait and feat with its rules."""
    blocks = []

    def heading(t):
        blocks.append(("h", t))

    def para(t, bold_lead=None):
        blocks.append(("p", t, bold_lead))

    kit = d.get("kit") if isinstance(d.get("kit"), dict) else None
    if kit:
        heading(text_of(kit.get("label")) or "Another loadout")
        if kit.get("ac") is not None:
            para(f"Armor Class {text_of(kit['ac'])}.")
        for a in items(kit.get("attacks")):
            para(attack_line(a))
    for title, lines in overflow:
        heading(title)
        for line in lines:
            para(line)
    for title, key_ in (("Class Features", "features"), ("Species Traits", "traits"), ("Feats", "feats")):
        entries = items(d.get(key_))
        if not entries:
            continue
        heading(title)
        for e in entries:
            text = e.get("text") if isinstance(e, dict) else None
            ps = [p for p in plain(text).splitlines() if p.strip()] if text else []
            para(ps[0] if ps else "", bold_lead=name_of(e) + ".")
            for p in ps[1:]:
                para(p)
    book = by_level(d.get("spellbook"))
    if book:
        heading("In the Spellbook, Not Prepared")
        for level, lst in book.items():
            para(", ".join(name_of(e) for e in lst) + ".", bold_lead=f"Level {level}.")
    if not blocks:
        return []

    pages, layer, y = [], None, 0
    top, bottom, left, width = PAGE_H - 44, 40, 42, PAGE_W - 84

    def new_page():
        nonlocal layer, y
        layer = Layer()
        pages.append(layer)
        layer.text(left, PAGE_H - 30, f"{name}: the rest of the sheet", 8, True)
        y = top

    new_page()
    for b in blocks:
        if b[0] == "h":
            if y - 30 < bottom:
                new_page()
            y -= 6 if y < top else 0
            layer.text(left, y, b[1], 11.5, True)
            y -= 15
            continue
        _, t, lead = b
        t, lead = shown(t), shown(lead) if lead else lead
        size, leading = 8.8, 11.2
        words = (lead + " " if lead else "") + t
        lines = wrapped(words, width, size) or [""]
        for i, line in enumerate(lines):
            if y < bottom:
                new_page()
            if i == 0 and lead and line.startswith(lead):
                layer.text(left, y, lead, size, True)
                layer.text(left + text_width(lead + " ", size, True), y, line[len(lead) + 1:], size)
            else:
                layer.text(left, y, line, size)
            y -= leading
        y -= 3
    return pages


# ------------------------------------------------------------------ writing the PDF


def fonts_resource():
    from pypdf.generic import DictionaryObject, NameObject
    fonts = DictionaryObject()
    for key_, base in (("/F1", "/Helvetica"), ("/F2", "/Helvetica-Bold")):
        fonts[NameObject(key_)] = DictionaryObject({
            NameObject("/Type"): NameObject("/Font"),
            NameObject("/Subtype"): NameObject("/Type1"),
            NameObject("/BaseFont"): NameObject(base),
            NameObject("/Encoding"): NameObject("/WinAnsiEncoding"),
        })
    return DictionaryObject({NameObject("/Font"): fonts})


def layer_page(writer, layer):
    """A page holding only a layer's writing."""
    from pypdf.generic import ContentStream, NameObject
    page = writer.add_blank_page(PAGE_W, PAGE_H)
    page[NameObject("/Resources")] = fonts_resource()
    stream = ContentStream(None, writer)
    stream.set_data(layer.data())
    if hasattr(page, "replace_contents"):
        page.replace_contents(stream)
    else:
        # an older pypdf, without PageObject.replace_contents, has no public
        # way to give a page its contents: its writer's own _add_object,
        # private, and so used here and nowhere else
        page[NameObject("/Contents")] = writer._add_object(stream)
    return page


def fill(template, d, name, extras):
    """The filled sheet, as PDF bytes. What it had to warn about goes to
    stderr, as "warning: <name>: ..."."""
    import io

    from pypdf import PdfReader, PdfWriter
    WARNINGS.clear()
    v = values(d)
    overflow = []
    front, back = Layer(), Layer()
    fill_front(front, d, v, name, overflow)
    fill_back(back, d, v, extras, overflow)
    writer = PdfWriter()
    writer.append(PdfReader(str(template)))
    scratch = PdfWriter()
    for i, layer in enumerate((front, back)):
        overlay = layer_page(scratch, layer)
        writer.pages[i].merge_page(overlay)
    for layer in more_pages(d, v, name, overflow):
        layer_page(writer, layer)
    writer.add_metadata({"/Title": f"{name}: character sheet", "/Creator": "GM Sheets handout"})
    out = io.BytesIO()
    writer.write(out)
    for message in WARNINGS:
        print(f"warning: {name}: {message}", file=sys.stderr)
    return out.getvalue()


# ------------------------------------------------------------------ the template


def template_path(given, cache):
    if given:
        path = pathlib.Path(given)
    else:
        path = pathlib.Path(cache).expanduser() / "DnD_2024_Character-Sheet.pdf"
        if not path.exists():
            path.parent.mkdir(parents=True, exist_ok=True)
            print(f"Fetching the 2024 character sheet from D&D Beyond into {path.parent} (about 16 MB)")
            with urllib.request.urlopen(TEMPLATE_URL, timeout=120) as r:
                path.write_bytes(r.read())
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    if digest != TEMPLATE_SHA256:
        print(f"warning: {path.name} isn't the printing these positions were measured on; "
              "check the filled sheet before you trust it", file=sys.stderr)
    return path


def pages_of_type(space, kind):
    import yaml
    out = []
    for p in sorted(pathlib.Path(space).rglob("*.md")):
        text = p.read_text(encoding="utf-8", errors="replace")
        m = re.match(r"---\r?\n(.*?)\r?\n---", text, re.S)
        if not m or not re.search(r"^type:\s*" + re.escape(kind) + r"\s*$", m.group(1), re.M):
            continue
        try:
            yaml.safe_load(m.group(1))
        except yaml.YAMLError:
            continue
        out.append(p.relative_to(space).as_posix()[:-3])
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("space", help="the folder the SilverBullet space serves")
    ap.add_argument("pages", nargs="*", help="pages to fill, by name; every --type page if none")
    ap.add_argument("--out", help="where the filled sheets go (SPACE/Handouts)")
    ap.add_argument("--type", default="pc", help="the type of page to fill when none is named (pc)")
    ap.add_argument("--extras", default="", help="campaign keys for Backstory & Personality: key:Label,...")
    ap.add_argument("--template", help="the 2024 character sheet PDF, if not the cached copy")
    ap.add_argument("--cache", default="~/.cache/gm-sheets", help="where the fetched sheet is kept")
    args = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8")
    space = pathlib.Path(args.space)
    names = args.pages or pages_of_type(space, args.type)
    if not names:
        sys.exit(f"no pages of type {args.type} in {space}")
    extras = []
    for part in filter(None, (s.strip() for s in args.extras.split(","))):
        k, _, label = part.partition(":")
        extras.append((k.strip(), (label or k).strip()))
    template = template_path(args.template, args.cache)
    out = pathlib.Path(args.out) if args.out else space / "Handouts"
    out.mkdir(parents=True, exist_ok=True)
    for page in names:
        d = read_page(space, page)
        name = page.rsplit("/", 1)[-1]
        path = out / f"{name}.pdf"
        path.write_bytes(fill(template, d, name, extras))
        print(f"{path}")


if __name__ == "__main__":
    main()
