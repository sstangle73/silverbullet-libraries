"""Run libraries.test.ts, beside this script, in SilverBullet 2.11's own Lua.

usage: python test/spacelua/run.py [CHECKOUT]

CHECKOUT, or else the SB211 environment variable, is a SilverBullet checkout
at tag 2.11.0 with its packages installed (npm ci --ignore-scripts). This
checks that it is 2.11.0 and has no changes to its tracked files, writes its
version.json if it has none, copies the test in under a name of its own,
client/space_lua/_sblib_<pid>.test.ts, runs vitest on that one file with
SBLIB set to this repository, and deletes the copy again, pass or fail. The
exit code is vitest's.

vitest runs as `npx vitest run` would, from the checkout's own
node_modules, through node: npx would fetch vitest from the registry when
the checkout has none installed.
"""
import json
import os
import pathlib
import shutil
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent
TEST = HERE / "libraries.test.ts"
VERSION = "2.11.0"


def fail(message):
    sys.exit(f"spacelua: {message}")


def check(sb):
    """Stop unless sb is SilverBullet 2.11.0, unchanged, with vitest installed."""
    package = sb / "package.json"
    if not package.is_file():
        fail(f"{sb} has no package.json: not a SilverBullet checkout")
    meta = json.loads(package.read_text(encoding="utf-8"))
    if meta.get("name") != "@silverbulletmd/silverbullet":
        fail(f"{sb} holds {meta.get('name')}, not SilverBullet")
    if meta.get("version") != VERSION:
        fail(f"{sb} is SilverBullet {meta.get('version')}, not {VERSION}")
    if (sb / ".git").exists():
        # --no-optional-locks: reading the tag must not rewrite the index
        found = subprocess.run(
            ["git", "--no-optional-locks", "-C", str(sb), "describe", "--tags", "--exact-match", "--dirty"],
            capture_output=True, text=True)
        tag = found.stdout.strip()
        if found.returncode != 0:
            fail(f"{sb} is not checked out at a tag ({found.stderr.strip()}): "
                 f"git -C {sb} checkout {VERSION}")
        if tag != VERSION:
            fail(f"{sb} is at {tag}, not {VERSION}"
                 + (": it has changes to tracked files" if tag.endswith("-dirty") else ""))
    vitest = sb / "node_modules" / "vitest" / "vitest.mjs"
    if not vitest.is_file():
        fail(f"{sb} has no vitest installed: cd {sb} && npm ci --ignore-scripts")
    return vitest


def main():
    args = sys.argv[1:]
    if args and args[0] in ("-h", "--help"):
        print(__doc__)
        return 0
    where = args[0] if args else os.environ.get("SB211")
    if not where:
        fail("say where SilverBullet 2.11.0 is: python test/spacelua/run.py <checkout>, or set SB211")
    sb = pathlib.Path(where).resolve()
    vitest = check(sb)
    node = shutil.which("node")
    if not node:
        fail("no node on PATH")
    # client/plugos/syscalls/system.ts imports version.json, which only the
    # build step that --ignore-scripts skips would write
    version = sb / "version.json"
    if not version.exists():
        version.write_bytes(json.dumps({"version": VERSION}, separators=(",", ":")).encode("utf-8"))
        print(f"spacelua: wrote {version}")
    copy = sb / "client" / "space_lua" / f"_sblib_{os.getpid()}.test.ts"
    if copy.exists():
        fail(f"{copy} is there already")
    env = dict(os.environ, SBLIB=str(REPO), NODE_OPTIONS="--max-old-space-size=4096")
    print(f"spacelua: SilverBullet {VERSION} at {sb}, libraries from {REPO}", flush=True)
    try:
        shutil.copyfile(TEST, copy)
        rel = copy.relative_to(sb).as_posix()
        return subprocess.run([node, str(vitest), "run", rel], cwd=str(sb), env=env).returncode
    finally:
        copy.unlink(missing_ok=True)


if __name__ == "__main__":
    sys.exit(main())
