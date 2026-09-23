"""Run the libraries' tests in plain Lua 5.4, with SilverBullet's APIs mocked,
over the test campaign in fixture/ with every library installed from src/.

usage: python test/run.py [--only book,kit] [-k words] [--src DIR] [--shuffle]

  --only     run only these files from tests/, named without .lua
  -k         run only the tests whose name holds these words
  --src      the libraries to test, if not src/: an older release, say, to
             check that a regression test fails on the code before its fix
  --shuffle  a stress run: the blocks of every page load in reverse, so a
             block that leans on another from its own page shows up

The fixture is a server's DM space. It holds the other four spaces as
folders, Adventure/, Author/, Book/ and Player/, and each of those is a
space of its own as well, so a test names the space it runs in. Every
space-lua block in a space loads the way SilverBullet 2.11 loads them, each
as a chunk of its own: highest priority first, the first `-- priority: N`
anywhere in the block and none counting as 0, then by the block's name,
"<page>@<offset of its fence in UTF-16 code units>", compared as JavaScript
compares strings. So a page's blocks need not load in page order: two fences
at 26434 and 146433 load the second first, since "146433" < "26434".

install.json says which library goes where, as a campaign would install
them. The fixture holds no library pages of its own, so what runs is always
src/ as it is now.
"""
import argparse
import json
import locale
import pathlib
import re
import sys

from lupa import lua54

try:
    import yaml as pyyaml
except ImportError:  # the tests that read YAML say so
    pyyaml = None

TEST = pathlib.Path(__file__).parent
FIXTURE = TEST / "fixture"
SRC = TEST.parent / "src"

KEYWORDS = re.compile(r"\b(where|order\s+by|select|limit)\b")
BLOCK = re.compile(r"```space-lua\n(.*?)\n```", flags=re.S)
# SilverBullet 2.11 (plugs/index/space_lua.ts) reads a block's priority with
# /--\s*priority:\s*(-?\d+)/, the first match anywhere in the block: \s and
# \d as JavaScript has them.
JS_SPACE = "[\t\n\v\f\r \u00a0\u1680\u2000-\u200a\u2028\u2029\u202f\u205f\u3000\ufeff]"
PRIORITY = re.compile(f"--{JS_SPACE}*priority:{JS_SPACE}*(-?[0-9]+)")
SPACES = {"dm": "", "adventure": "Adventure/", "author": "Author/",
          "book": "Book/", "player": "Player/"}


def split_top(text, sep=","):
    parts, depth, cur, quote = [], 0, "", None
    for ch in text:
        if quote:
            cur += ch
            if ch == quote:
                quote = None
            continue
        if ch in "\"'":
            quote = ch
        elif ch in "({[":
            depth += 1
        elif ch in ")}]":
            depth -= 1
        elif ch == sep and depth == 0:
            parts.append(cur)
            cur = ""
            continue
        cur += ch
    parts.append(cur)
    return parts


def transpile_query(body):
    """query[[ from p = src where .. order by .. select .. limit .. ]] -> __liq(...)"""
    m = re.match(r"\s*from\s+(\w+)\s*=\s*", body)
    if not m:
        raise ValueError("unsupported query: " + body)
    var = m.group(1)
    parts = KEYWORDS.split(body[m.end():])
    src, clauses = parts[0].strip(), {}
    for i in range(1, len(parts), 2):
        clauses[re.sub(r"\s+", " ", parts[i])] = " ".join(parts[i + 1].split())
    where = clauses.get("where")
    orders = []
    for item in split_top(clauses.get("order by", "")):
        item = item.strip()
        if not item:
            continue
        desc = False
        mm = re.match(r"(.*?)\s+(desc|asc)$", item)
        if mm:
            item, desc = mm.group(1), mm.group(2) == "desc"
        orders.append(f"{{fn=function({var}) return {item} end, desc={'true' if desc else 'false'}}}")
    select = clauses.get("select")
    return (
        f"__liq(function() return {' '.join(src.split())} end, "
        f"{f'function({var}) return {where} end' if where else 'nil'}, "
        f"{{{', '.join(orders)}}}, "
        f"{f'function({var}) return {select} end' if select else 'nil'}, "
        f"{clauses.get('limit') or 'nil'})"
    )


def transpile(block):
    # Keep line numbers: pad each rewritten query with the newlines it had.
    return re.sub(
        r"query\s*\[\[(.*?)\]\]",
        lambda m: transpile_query(m.group(1)) + "\n" * m.group(1).count("\n"),
        block, flags=re.S)


def read_page(path):
    # The bytes as SilverBullet reads them: no newline translation, so a
    # carriage return stays where it is, and offsets count it.
    return path.read_bytes().decode("utf-8")


def read_pages(root):
    """Every page under root, by name."""
    return {p.relative_to(root).as_posix()[:-3]: read_page(p)
            for p in sorted(root.rglob("*.md"))}


def src_pages():
    return {p.stem: read_page(p) for p in sorted(SRC.glob("*.md"))}


def use_src(folder):
    """Test the libraries in folder instead of src/."""
    global SRC
    SRC = pathlib.Path(folder)
    if not any(SRC.glob("*.md")):
        sys.exit(f"{folder}: no libraries there")


def install_map():
    return json.loads((TEST / "install.json").read_text(encoding="utf-8"))


def tree():
    """The DM space: the fixture's pages, and each library where install.json puts it."""
    pages, src = read_pages(FIXTURE), src_pages()
    for folder, libs in install_map().items():
        for lib in libs:
            if folder + lib in pages:
                sys.exit(f"fixture/{folder}{lib}.md: the fixture holds no libraries, "
                         "install.json puts src/ there")
            pages[folder + lib] = src[lib]
    return pages


def space(pages, prefix):
    return {n[len(prefix):]: t for n, t in pages.items() if n.startswith(prefix)}


def utf16_length(text):
    """The length of text as JavaScript counts it, in UTF-16 code units."""
    return len(text.encode("utf-16-le")) // 2


def js_order(text):
    """A sort key that orders strings as JavaScript's < does, by UTF-16 code
    unit. Python's own order is by code point, which differs for a character
    beyond U+FFFF: JavaScript sees its surrogates, D800-DFFF, and sorts it
    before U+E000-U+FFFF. Big-endian UTF-16 bytes sort as the code units do."""
    return text.encode("utf-16-be")


def blocks(name, text):
    """A page's space-lua blocks, each with the name SilverBullet gives it
    (plugs/index/space_lua.ts): "<page>@<offset of the fence>"."""
    out = []
    for i, m in enumerate(BLOCK.finditer(text), 1):
        source = m.group(1)
        found = PRIORITY.search(source)
        offset = utf16_length(text[:m.start()])
        out.append({"page": name, "index": i, "offset": offset, "ref": f"{name}@{offset}",
                    "priority": int(found.group(1)) if found else 0, "source": source})
    return out


def load_order(found, shuffle=False):
    """The blocks of a space's pages in the order SilverBullet 2.11 runs them
    (client/space_lua.ts): priority, highest first, then the name as a
    JavaScript string. With shuffle, each page's blocks of one priority swap
    places end for end, a stress run for code that leans on their order."""
    out = [b for name, text in found.items() for b in blocks(name, text)]
    out.sort(key=lambda b: (-b["priority"], js_order(b["ref"])))
    if shuffle:
        slots = {}
        for i, b in enumerate(out):
            slots.setdefault((b["page"], b["priority"]), []).append(i)
        shuffled = list(out)
        for places in slots.values():
            for place, taken in zip(places, reversed(places)):
                shuffled[place] = out[taken]
        out = shuffled
    return out


def to_lua(L, value):
    if isinstance(value, dict):
        t = L.table()
        for k, v in value.items():
            t[k] = to_lua(L, v)
        return t
    if isinstance(value, list):
        t = L.table()
        for i, v in enumerate(value, 1):
            t[i] = to_lua(L, v)
        return t
    return value


def js_key(k):
    # String(k), as a key of a JavaScript object: YAML's null, true and 1.0
    # are "null", "true" and "1" there
    if k is None:
        return "null"
    if isinstance(k, bool):
        return "true" if k else "false"
    if isinstance(k, float) and k.is_integer():
        return str(int(k))
    return str(k)


def jsify(value):
    # js-yaml's result as SilverBullet hands it to Lua: every map key a
    # string, as a JavaScript object's keys are, and a date as its text
    if isinstance(value, dict):
        return {js_key(k): jsify(v) for k, v in value.items()}
    if isinstance(value, list):
        return [jsify(v) for v in value]
    if hasattr(value, "isoformat"):
        return value.isoformat()
    return value


if pyyaml is not None:
    class JsYamlLoader(pyyaml.SafeLoader):
        """PyYAML's safe loader, reading plain scalars as js-yaml 4 does for
        SilverBullet: YAML 1.2's core schema, where only true and false (in
        three spellings) are booleans and there is no base 60. PyYAML follows
        YAML 1.1, where yes, No and on are booleans and 1:30 is 90."""

    # Every resolver but YAML 1.1's booleans, numbers and "=" stays: null,
    # timestamps and merge keys read the same in both.
    JsYamlLoader.yaml_implicit_resolvers = {
        first: [(tag, rx) for tag, rx in resolvers
                if tag.rsplit(":", 1)[-1] not in ("bool", "int", "float", "value")]
        for first, resolvers in pyyaml.SafeLoader.yaml_implicit_resolvers.items()
    }
    # js-yaml 4's lib/type/bool.js, int.js and float.js, as patterns; an int
    # is tried before a float, as there
    JsYamlLoader.add_implicit_resolver(
        "tag:yaml.org,2002:bool",
        re.compile(r"^(?:true|True|TRUE|false|False|FALSE)$"), list("tTfF"))
    JsYamlLoader.add_implicit_resolver(
        "tag:yaml.org,2002:int",
        re.compile(r"^[-+]?(?:0|0b[01_]*[01]|0x[0-9a-fA-F_]*[0-9a-fA-F]|0o[0-7_]*[0-7]"
                   r"|0[0-9](?:[0-9_]*[0-9])?|[1-9](?:[0-9_]*[0-9])?)$"),
        list("-+0123456789"))
    JsYamlLoader.add_implicit_resolver(
        "tag:yaml.org,2002:float",
        re.compile(r"^(?:[-+]?[0-9][0-9_]*(?:\.[0-9_]*)?(?:[eE][-+]?[0-9]+)?"
                   r"|\.[0-9_]+(?:[eE][-+]?[0-9]+)?|[-+]?\.(?:inf|Inf|INF)|\.(?:nan|NaN|NAN))(?<!_)$"),
        list("-+0123456789."))

    def js_yaml_int(loader, node):
        # constructYamlInteger: 0b, 0x and 0o, and anything else decimal, so
        # 010 is ten, where PyYAML reads it as octal
        value = loader.construct_scalar(node).replace("_", "")
        sign = -1 if value[0] == "-" else 1
        value = value.lstrip("+-")
        base = {"0b": 2, "0x": 16, "0o": 8}.get(value[:2])
        return sign * (int(value[2:], base) if base else int(value, 10))

    JsYamlLoader.add_constructor("tag:yaml.org,2002:int", js_yaml_int)


def yaml_parse(text):
    """yaml.parse as SilverBullet has it: js-yaml's reading of text."""
    return jsify(pyyaml.load(text, Loader=JsYamlLoader))


def build(pages=None, shuffle=False):
    """A Lua runtime with the mocks loaded and each space's pages and libraries.

    FIXTURES[space] holds the space's pages by name and LIBS[space] its
    space-lua blocks in load order, each as { name = "<page> #<n>", ref =
    "<page>@<offset>", page, index, offset, priority, source }. SRC holds
    each library as src/ has it, INSTALL the folders install.json puts it
    in, and REPOSITORY the page Library: Install reads.
    """
    # Lua's %s, %a and string.lower ask the C library, which follows the
    # locale: Python sets LC_CTYPE from the system at startup, and on Windows
    # that is a code page such as 1252, where byte 0xA0 is a space, so %s cut
    # "à" (C3 A0) in half. SilverBullet's strings are JavaScript's, whose
    # classes are ASCII. LC_COLLATE (string <) and LC_NUMERIC (tostring)
    # start as "C" in Python; set all three, for any caller.
    locale.setlocale(locale.LC_ALL, "C")
    pages = tree() if pages is None else pages
    L = lua54.LuaRuntime(unpack_returned_tuples=True)
    g = L.globals()
    fixtures, libs = {}, {}
    for layout, prefix in SPACES.items():
        found = space(pages, prefix)
        fixtures[layout] = found
        libs[layout] = [dict(b, name=f"{b['page']} #{b['index']}", source=transpile(b["source"]))
                        for b in load_order(found, shuffle)]
    g.FIXTURES = to_lua(L, fixtures)
    g.LIBS = to_lua(L, libs)
    g.SHUFFLED = shuffle
    g.SRC = to_lua(L, src_pages())
    g.INSTALL = to_lua(L, install_map())
    # the query rewrite, for a test that loads a library no space installs
    g.transpile = transpile
    repository = TEST.parent / "Repositories" / "storie.md"
    g.REPOSITORY = read_page(repository) if repository.exists() else None
    # For the harness's own tests: the names of a set of pages' blocks in
    # load order, as a space holding just those pages would load them.
    g.__load_order = lambda found: to_lua(L, [b["ref"] for b in load_order(dict(found.items()))])
    if pyyaml is not None:
        g.__yaml_parse = lambda text: to_lua(L, yaml_parse(text))
    # the made-up D&D Beyond characters, as the character service sends them
    g.DDB = to_lua(L, {p.stem: json.loads(p.read_text(encoding="utf-8"))
                       for p in sorted((TEST / "ddb").glob("*.json"))})
    L.execute((TEST / "mocks.lua").read_text(encoding="utf-8"))
    return L


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--only", help="test files to run, comma-separated, without .lua")
    ap.add_argument("-k", dest="words", help="run only the tests whose name holds these words")
    ap.add_argument("--src", help="the libraries to test, if not src/")
    ap.add_argument("--shuffle", action="store_true",
                    help="load the blocks of every page in reverse, as a stress run")
    args = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8")
    if args.src:
        use_src(args.src)
    files = sorted((TEST / "tests").glob("*.lua"))
    if args.only:
        wanted = [w.strip() for w in args.only.split(",") if w.strip()]
        missing = [w for w in wanted if not (TEST / "tests" / f"{w}.lua").exists()]
        if missing:
            sys.exit("no tests/" + ".lua, tests/".join(missing) + ".lua")
        files = [f for f in files if f.stem in wanted]
    L = build(shuffle=args.shuffle)
    L.execute((TEST / "framework.lua").read_text(encoding="utf-8"))
    load = L.eval("loadTests")
    for f in files:
        load(f"tests/{f.name}", f.read_text(encoding="utf-8"))
    passed, total, failed, report = L.eval("runAll")(args.words)
    for line in report.values():
        print("note:", line)
    for f in failed.values():
        print("FAIL", f)
    excused = L.eval("#EXCUSED")
    print(f"{passed}/{total} passed" + (f", {excused} of them failing but excused until merged "
                                        "(TEMPORARILY_EXPECTED_TO_FAIL in framework.lua)" if excused else "")
          + (" (shuffled)" if args.shuffle else ""))
    sys.exit(0 if total and passed == total else 1)


if __name__ == "__main__":
    main()
