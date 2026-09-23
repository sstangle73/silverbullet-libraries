"""Scan this repo, and the commits a pipeline brings, for names that must
never be in it.

usage: python tools/leakscan.py [--names FILE]

This repo is public, and the campaigns these libraries were written for are
not. The names to look for are the campaigns' own, so they can't be kept
here: they come from a file named by --names, or by the LEAKSCAN_NAMES environment
variable, which in CI is a GitLab File variable. One entry a line:

    word    <word>             a whole word, in any case
    phrase  <word> <word> ...  those words in that order, in any case
    pattern <regex>            a Python regular expression, as written

A line starting with # is a comment. It looks in every tracked file's text
and path, and in the messages of the commits the pipeline brings: a merge
request's, or a push's. Without a names file it says so and passes, since a
fork or a local run has nothing to look for.
"""
import argparse
import os
import re
import subprocess
import sys

ZERO = "0" * 40


def git(*args):
    return subprocess.run(["git", *args], capture_output=True, text=True, encoding="utf-8",
                          errors="replace", check=True).stdout


def read_names(path):
    words, phrases, patterns = set(), {}, []
    with open(path, encoding="utf-8") as f:
        for n, line in enumerate(f, 1):
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            kind, _, rest = line.partition(" ")
            rest = rest.strip()
            if kind == "word":
                words.add(rest.lower())
            elif kind == "phrase":
                parts = rest.lower().split()
                if len(parts) == 1:
                    words.add(parts[0])
                elif parts:
                    phrases.setdefault(parts[0], []).append(parts)
            elif kind == "pattern":
                patterns.append((rest, re.compile(rest)))
            else:
                sys.exit(f"{path}:{n}: no kind {kind!r} (word, phrase or pattern)")
    return words, phrases, patterns


def hits(text, words, phrases, patterns):
    """Each name found in text, once, with a little of the text round it."""
    found, seen = [], set()

    def near(start, end):
        return " ".join(text[max(0, start - 25):end + 25].split())

    tokens = [(m.group(0).lower(), m.start(), m.end()) for m in re.finditer(r"[A-Za-z]+", text)]
    for i, (w, s, e) in enumerate(tokens):
        if w in words and w not in seen:
            seen.add(w)
            found.append(f'{w} in "{near(s, e)}"')
        for parts in phrases.get(w, ()):
            if len(tokens) - i >= len(parts) and all(tokens[i + k][0] == p for k, p in enumerate(parts)):
                name = " ".join(parts)
                if name not in seen:
                    seen.add(name)
                    found.append(f'{name} in "{near(s, tokens[i + len(parts) - 1][2])}"')
    for source, rx in patterns:
        m = rx.search(text)
        if m and source not in seen:
            seen.add(source)
            found.append(f'/{source}/ in "{near(m.start(), m.end())}"')
    return found


def commit_range():
    """The commits this pipeline brings, as a git log range, or None."""
    base = os.environ.get("CI_MERGE_REQUEST_DIFF_BASE_SHA")
    if base:
        return f"{base}..HEAD"
    before = os.environ.get("CI_COMMIT_BEFORE_SHA")
    if before and before != ZERO:
        return f"{before}..HEAD"
    return "HEAD~1..HEAD" if git("rev-list", "--count", "HEAD").strip() != "1" else "HEAD"


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--names", default=os.environ.get("LEAKSCAN_NAMES"), help="the names file")
    args = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8")
    if not args.names or not os.path.isfile(args.names):
        print("leakscan: no names file (--names or LEAKSCAN_NAMES), so nothing to look for")
        return 0
    words, phrases, patterns = read_names(args.names)
    bad = []
    files = [f for f in git("ls-files", "-z").split("\0") if f]
    for f in files:
        for h in hits(f, words, phrases, patterns):
            bad.append(f"path {f}: {h}")
        try:
            with open(f, encoding="utf-8") as fh:
                text = fh.read()
        except (UnicodeDecodeError, IsADirectoryError, FileNotFoundError):
            continue
        for h in hits(text, words, phrases, patterns):
            bad.append(f"{f}: {h}")
    span = commit_range()
    log = git("log", "--format=%H%n%B%n%x00", span) if span else ""
    commits = [c.strip() for c in log.split("\0") if c.strip()]
    for c in commits:
        sha, _, message = c.partition("\n")
        for h in hits(message, words, phrases, patterns):
            bad.append(f"commit {sha[:7]}: {h}")
    names = len(words) + sum(len(v) for v in phrases.values()) + len(patterns)
    print(f"leakscan: {len(files)} files and {len(commits)} commit messages ({span}) checked against {names} names")
    for b in bad:
        print("  " + b)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
