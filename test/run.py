"""Run the libraries' tests in plain Lua 5.4, with SilverBullet's APIs mocked,
over the test campaign in fixture/ with every library installed from src/.

usage: python test/run.py [--only book,kit] [-k words] [--src DIR]

  --only  run only these files from tests/, named without .lua
  -k      run only the tests whose name holds these words
  --src   the libraries to test, if not src/: an older release, say, to
          check that a regression test fails on the code before its fix

The fixture is a server's DM space. It holds the other four spaces as
folders, Adventure/, Author/, Book/ and Player/, and each of those is a
space of its own as well, so a test names the space it runs in. Every
space-lua block in a space loads the way SilverBullet loads them: priority
first, highest first and none counting as 0, then page name.

install.json says which library goes where, as a campaign would install
them. The fixture holds no library pages of its own, so what runs is always
src/ as it is now.
"""
import argparse
import json
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
PRIORITY = re.compile(r"\s*--\s*priority:\s*(-?\d+)")
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


def read_pages(root):
    """Every page under root, by name."""
    return {p.relative_to(root).as_posix()[:-3]: p.read_text(encoding="utf-8")
            for p in sorted(root.rglob("*.md"))}


def src_pages():
    return {p.stem: p.read_text(encoding="utf-8") for p in sorted(SRC.glob("*.md"))}


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


def scripts(found):
    out = []
    for name, text in found.items():
        for i, block in enumerate(BLOCK.findall(text)):
            m = PRIORITY.match(block)
            out.append((-(int(m.group(1)) if m else 0), name, i, transpile(block)))
    out.sort(key=lambda s: s[:3])
    return [(f"{name} #{i + 1}", source) for _, name, i, source in out]


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


def jsify(value):
    # js-yaml's result as SilverBullet hands it to Lua: every map key a
    # string, as a JavaScript object's keys are, and a date as its text
    if isinstance(value, dict):
        return {str(k): jsify(v) for k, v in value.items()}
    if isinstance(value, list):
        return [jsify(v) for v in value]
    if hasattr(value, "isoformat"):
        return value.isoformat()
    return value


def build(pages=None):
    """A Lua runtime with the mocks loaded and each space's pages and libraries.

    FIXTURES[space] holds the space's pages by name and LIBS[space] its
    space-lua blocks in load order. SRC holds each library as src/ has it,
    INSTALL the folders install.json puts it in, and REPOSITORY the page
    Library: Install reads.
    """
    pages = tree() if pages is None else pages
    L = lua54.LuaRuntime(unpack_returned_tuples=True)
    g = L.globals()
    fixtures, libs = {}, {}
    for layout, prefix in SPACES.items():
        found = space(pages, prefix)
        fixtures[layout] = found
        libs[layout] = [{"name": n, "source": s} for n, s in scripts(found)]
    g.FIXTURES = to_lua(L, fixtures)
    g.LIBS = to_lua(L, libs)
    g.SRC = to_lua(L, src_pages())
    g.INSTALL = to_lua(L, install_map())
    repository = TEST.parent / "Repositories" / "storie.md"
    g.REPOSITORY = repository.read_text(encoding="utf-8") if repository.exists() else None
    if pyyaml is not None:
        g.__yaml_parse = lambda text: to_lua(L, jsify(pyyaml.safe_load(text)))
    L.execute((TEST / "mocks.lua").read_text(encoding="utf-8"))
    return L


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--only", help="test files to run, comma-separated, without .lua")
    ap.add_argument("-k", dest="words", help="run only the tests whose name holds these words")
    ap.add_argument("--src", help="the libraries to test, if not src/")
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
    L = build()
    L.execute((TEST / "framework.lua").read_text(encoding="utf-8"))
    load = L.eval("loadTests")
    for f in files:
        load(f"tests/{f.name}", f.read_text(encoding="utf-8"))
    passed, total, failed, report = L.eval("runAll")(args.words)
    for line in report.values():
        print("note:", line)
    for f in failed.values():
        print("FAIL", f)
    print(f"{passed}/{total} passed")
    sys.exit(0 if total and passed == total else 1)


if __name__ == "__main__":
    main()
