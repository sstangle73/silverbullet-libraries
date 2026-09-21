"""Build both editions of the test campaign's book, as GM Book builds them.

usage: python test/build_book.py [--space adventure|dm] [--out DIR | --write]

With --out, the two editions are saved there, for diffing. With --write,
they replace the committed build in fixture/Adventure/Build/, which the
tests hold a fresh build to: do that when a library change alters the book
on purpose, and read the diff before committing it.
"""
import argparse
import pathlib
import sys

import run


def editions(layout="adventure"):
    L = run.build()
    L.execute(f'reset("{layout}"); H.current = "index"; __report = gmbook.compile({{ "dm", "player" }})')
    build = "Adventure/Build/" if layout == "dm" else "Build/"
    return {edition: L.eval(f'H.pages["{build}Book {edition}"]') for edition in ("DM", "Player")}


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--space", choices=("adventure", "dm"), default="adventure")
    where = ap.add_mutually_exclusive_group(required=True)
    where.add_argument("--out", type=pathlib.Path)
    where.add_argument("--write", action="store_true")
    args = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8")
    out = run.FIXTURE / "Adventure" / "Build" if args.write else args.out
    out.mkdir(parents=True, exist_ok=True)
    for edition, text in editions(args.space).items():
        (out / f"Book {edition}.md").write_text(text, encoding="utf-8", newline="\n")
        print(f"Book {edition}: {len(text)} characters")


if __name__ == "__main__":
    main()
