"""Function and line coverage of the libraries, from the plain-Lua suite.

usage: python test/coverage.py [--only book,kit] [-k words] [--src DIR]
                               [--shuffle] [--missed LIB[,LIB]]

Runs the suite as run.py does, with a Lua hook on every line that runs,
and prints for each library the functions called of those its blocks
define, and the lines run of those that hold code. --missed lists, for
those libraries, each function no test called and each line no test ran,
by its line on the library's page. The flags run.py takes pick the tests
and the libraries the same way.

A function is each `function` in a block's code, anonymous ones included,
and it ran if any line of its own did. A line holds code when Lua compiles
an instruction to it, which is what its line hook can see: each block is
compiled and its bytecode read for the lines of every function in it,
called or not, and the reader is held to debug.getinfo's own answer for
each function that ran. A comment, a blank line, and an `else` or an `end`
that compiles to nothing hold none. Every copy of a library, in whichever
space's folder, counts as the library.

The whole suite takes about 40 seconds with the hook, some 30 more than
without it.
"""
import argparse
import pathlib
import re
import sys
import time

import run

# Lua 5.4's bytecode, read for the lines each function's instructions sit
# on (ldump.c): the same lines debug.getinfo(f, "L").activelines gives for
# a function that exists, found for every function in a block, called or
# not. A vararg function's first instruction, VARARGPREP, has no line of
# its own there either.
DUMP_READER = r"""
return function(source, name)
  local s = string.dump(assert(load(source, name)))
  local pos = 1
  local function byte() local b = s:byte(pos); pos = pos + 1; return b end
  local function size()
    local x = 0
    while true do
      local b = byte()
      x = (x << 7) | (b & 0x7f)
      if b & 0x80 ~= 0 then return x end
    end
  end
  local function str()
    local n = size()
    if n == 0 then return nil end
    pos = pos + n - 1
  end
  assert(s:sub(1, 4) == "\27Lua" and s:byte(5) == 0x54 and s:byte(6) == 0, "not Lua 5.4's bytecode")
  pos = 13
  local isize, intsize, numsize = byte(), byte(), byte()
  pos = pos + intsize + numsize + 1
  local protos = {}
  local function fn()
    str()
    local linedefined, lastline = size(), size()
    byte()
    local vararg = byte()
    byte()
    -- size() moves pos, so it is read before pos is: pos + size() would add
    -- to the old place
    local code = size()
    pos = pos + code * isize
    for _ = 1, size() do
      local t = byte()
      if t == 3 then pos = pos + intsize
      elseif t == 19 then pos = pos + numsize
      elseif t == 4 or t == 20 then str() end
    end
    local upvalues = size()
    pos = pos + upvalues * 3
    for _ = 1, size() do fn() end
    local deltas = {}
    for i = 1, size() do
      local d = byte()
      deltas[i] = d >= 128 and d - 256 or d
    end
    local absolute = {}
    for _ = 1, size() do
      local pc = size()
      absolute[pc] = size()
    end
    for _ = 1, size() do str(); size(); size() end
    for _ = 1, size() do str() end
    local lines, line = {}, linedefined
    for pc = 0, #deltas - 1 do
      local d = deltas[pc + 1]
      if d == -128 then line = absolute[pc] else line = line + d end
      if not (vararg ~= 0 and pc == 0) then lines[#lines + 1] = line end
    end
    protos[#protos + 1] = { linedefined = linedefined, lastline = lastline, lines = lines }
  end
  fn()
  assert(pos == #s + 1, "the bytecode reader lost its place")
  return protos
end
"""

# The hook, on each line that runs: which function it runs in, found once
# for each closure and kept, since asking for a function's source on every
# line is what makes a hook slow. A function ran if any of its own lines
# did; the lines Lua says it holds are kept once, to check the bytecode
# reader against. Only a library's blocks count: their chunks are named
# "=<page> #<n>".
HOOK = r"""
local hits, calls, active = {}, {}, {}
local getinfo = debug.getinfo
local seen = setmetatable({}, { __mode = "k" })
local function hook(_, line)
  local f = getinfo(2, "f").func
  local where = seen[f]
  if where == nil then
    local info = getinfo(f, "S")
    local src = info.source
    if src:find("Library/Storie/", 1, true) and src:byte(1) == 61 then
      hits[src] = hits[src] or {}
      calls[src] = calls[src] or {}
      active[src] = active[src] or {}
      where = { hits = hits[src], calls = calls[src], at = info.linedefined }
      if not where.calls[where.at] then
        where.calls[where.at] = true
        active[src][where.at] = getinfo(f, "L").activelines
      end
    else
      where = false
    end
    seen[f] = where
  end
  if where then where.hits[line] = true end
end
return function(on)
  if on then debug.sethook(hook, "l") else debug.sethook() end
  return hits, calls, active
end
"""

CHUNK = re.compile(r"^=(?:.*/)?Library/Storie/(?P<lib>[^/#]+) #(?P<n>\d+)$")


def blocks_of(text):
    """Each space-lua block on a library's page: its code, and the line of
    the page its first line is."""
    out = []
    for m in run.BLOCK.finditer(text):
        out.append((m.group(1), text[:m.start()].count("\n") + 2))
    return out


def ranges(lines):
    """[3, 4, 5, 9] as "3-5, 9"."""
    out, start, prev = [], None, None
    for n in sorted(lines):
        if start is None:
            start = prev = n
        elif n == prev + 1:
            prev = n
        else:
            out.append(f"{start}-{prev}" if prev > start else str(start))
            start = prev = n
    if start is not None:
        out.append(f"{start}-{prev}" if prev > start else str(start))
    return ", ".join(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--only", help="test files to run, comma-separated, without .lua")
    ap.add_argument("-k", dest="words", help="run only the tests whose name holds these words")
    ap.add_argument("--src", help="the libraries to test, if not src/")
    ap.add_argument("--shuffle", action="store_true", help="load the blocks of every page in reverse")
    ap.add_argument("--missed", help="libraries to list what no test reached in, comma-separated")
    args = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8")
    if args.src:
        run.use_src(args.src)
    files = sorted((run.TEST / "tests").glob("*.lua"))
    if args.only:
        wanted = [w.strip() for w in args.only.split(",") if w.strip()]
        missing = [w for w in wanted if not (run.TEST / "tests" / f"{w}.lua").exists()]
        if missing:
            sys.exit("no tests/" + ".lua, tests/".join(missing) + ".lua")
        files = [f for f in files if f.stem in wanted]
    src = run.src_pages()
    missed = [m.strip() for m in (args.missed or "").split(",") if m.strip()]
    for lib in missed:
        if lib not in src:
            sys.exit(f"--missed: src/ has no {lib}")

    L = run.build(shuffle=args.shuffle)
    L.execute((run.TEST / "framework.lua").read_text(encoding="utf-8"))
    load = L.eval("loadTests")
    for f in files:
        load(f"tests/{f.name}", f.read_text(encoding="utf-8"))

    # What each block holds: its functions, by the line each starts on, and
    # its lines of code, by the page's own line numbers.
    read = L.execute(DUMP_READER)
    code = {}
    for lib, text in src.items():
        for n, (block, first) in enumerate(blocks_of(text), 1):
            protos = read(run.transpile(block), f"={lib} #{n}")
            functions, lines = {}, set()
            for p in protos.values():
                for line in p.lines.values():
                    lines.add(line)
                if p.linedefined > 0:
                    functions.setdefault(p.linedefined, []).append(sorted(p.lines.values()))
            code[(lib, n)] = {"first": first, "functions": functions, "lines": lines}

    toggle = L.execute(HOOK)
    started = time.time()
    toggle(True)
    passed, total, failed, _ = L.eval("runAll")(args.words)
    hits, calls, active = toggle(False)
    took = time.time() - started

    ran = {key: set() for key in code}
    called = {key: set() for key in code}
    disagree = []
    for chunk, lines in hits.items():
        m = CHUNK.match(chunk)
        if m and (m["lib"], int(m["n"])) in code:
            ran[(m["lib"], int(m["n"]))].update(lines.keys())
    for chunk, starts in calls.items():
        m = CHUNK.match(chunk)
        if not m or (m["lib"], int(m["n"])) not in code:
            continue
        key = (m["lib"], int(m["n"]))
        called[key].update(starts.keys())
        # hold the bytecode reader to Lua's own answer, where one function
        # starts on the line
        for at, lines in active[chunk].items():
            mine = code[key]["functions"].get(at)
            if at > 0 and mine and len(mine) == 1 and sorted(set(mine[0])) != sorted(lines.keys()):
                disagree.append(f"{key[0]} #{key[1]} line {at}")

    print(f"{passed}/{total} passed" + (" (shuffled)" if args.shuffle else "") + f", {took:.0f} s with the hook")
    for f in failed.values():
        print("FAIL", f)
    for d in disagree:
        print("coverage: the bytecode reader and Lua disagree on the lines of", d)
    print()
    print(f"{'Library':<22}{'Functions':>18}{'Lines':>20}")
    totals = [0, 0, 0, 0]
    for lib in sorted(src):
        keys = [k for k in code if k[0] == lib]
        fn_all = sum(len(code[k]["functions"]) for k in keys)
        fn_hit = sum(len(called[k] & set(code[k]["functions"])) for k in keys)
        ln_all = sum(len(code[k]["lines"]) for k in keys)
        ln_hit = sum(len(ran[k] & code[k]["lines"]) for k in keys)
        totals = [totals[0] + fn_hit, totals[1] + fn_all, totals[2] + ln_hit, totals[3] + ln_all]

        def share(hit, of):
            return f"{hit:>5}/{of:<5}{(100 * hit // of) if of else 100:>4}%"
        print(f"{lib:<22}{share(fn_hit, fn_all):>18}{share(ln_hit, ln_all):>20}")
    print(f"{'All':<22}{f'{totals[0]:>5}/{totals[1]:<5}{100 * totals[0] // max(totals[1], 1):>4}%':>18}"
          f"{f'{totals[2]:>5}/{totals[3]:<5}{100 * totals[2] // max(totals[3], 1):>4}%':>20}")

    for lib in missed:
        lines_of = src[lib].split("\n")
        print(f"\n{lib}: what no test reached, by its line on the page")
        for key in sorted(k for k in code if k[0] == lib):
            first = code[key]["first"]
            for at in sorted(set(code[key]["functions"]) - called[key]):
                page = first + at - 1
                print(f"  function at {page}: {lines_of[page - 1].strip()[:90]}")
            left = {first + n - 1 for n in code[key]["lines"] - ran[key]}
            if left:
                print(f"  block {key[1]}, lines not run: {ranges(left)}")
    sys.exit(0 if total and passed == total and not disagree else 1)


if __name__ == "__main__":
    main()
