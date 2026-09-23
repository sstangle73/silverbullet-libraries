"""A local SilverBullet 2.11 server over the test campaign, to drive the
libraries in a real client through its Runtime API.

Five spaces on one server, as the libraries expect: /dm serves the whole
campaign, and /adventure, /author, /book and /player serve its folders
through directory junctions. SilverBullet refuses nested space folders and
compares paths without resolving junctions, so junctions give it the shape.

The campaign is fixture/ with each library from src/ where install.json
puts it, as run.py builds it, copied into work/space/. Nothing a test
writes reaches the repo.

Windows only. It needs SilverBullet's server, 2.11.0 (SB_BIN, or
bin/silverbullet.exe beside this script), and chrome-headless-shell for the
server's headless client (SB_CHROME_PATH).

usage:
  python test/instance/instance.py provision [--src DIR]  new data, campaign, admin, token; starts it
  python test/instance/instance.py start | stop | status
  python test/instance/instance.py reset [--src DIR]      stop, copy the campaign afresh, start
  python test/instance/instance.py eval <space> <lua expression>
  python test/instance/instance.py script <space> <file or ->  prelude.lua (the T helpers) first
  python test/instance/instance.py logs <space> [limit]   the headless client's console
  python test/instance/instance.py diff                   what the server changed in the campaign
  python test/instance/instance.py restore                put it back as copied (no restart)

--src tests the libraries in another folder instead of src/.

Every request holds a lock, so scripts from several callers never
interleave: put a whole flow (open a page, click, wait, read) in one
script. The lock is the machine's, one for each port, since every checkout
serves on the same port: a caller from another checkout waits too. After
each eval or script, any file the request changed is reported on stderr.

A request goes only to this checkout's own server: the process it started,
still running, and the one listening on the port. Anything else there, such
as another checkout's server, stops it with a message saying so.
"""
import _winapi
import csv
import hashlib
import json
import msvcrt
import os
import pathlib
import secrets
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT.parent))
import run  # noqa: E402  the test runner, for the campaign it builds

WORK = ROOT / "work"
DATA = WORK / "data"
TREE = WORK / "space"
CHROME_DATA = WORK / "chrome"
LOG = WORK / "server.log"
PIDFILE = WORK / "server.pid"
SECRETS = WORK / "secrets.json"
BASELINE = WORK / "baseline.json"
COPIED = WORK / "copied.json"
PRELUDE = ROOT / "prelude.lua"
BIN = pathlib.Path(os.environ.get("SB_BIN", str(ROOT / "bin" / "silverbullet.exe")))
CHROME = pathlib.Path(os.environ.get(
    "SB_CHROME_PATH",
    str(pathlib.Path.home() / "AppData/Local/ms-playwright/chromium_headless_shell-1217"
        / "chrome-headless-shell-win64/chrome-headless-shell.exe")))
HOST, PORT = "127.0.0.1", int(os.environ.get("SB_TEST_PORT", "3111"))
BASE = f"http://{HOST}:{PORT}"
# Machine-wide, not the checkout's: every checkout serves on PORT.
LOCKFILE = pathlib.Path.home() / ".cache" / "sblib-instance" / f"port-{PORT}.lock"
ADMIN = "admin"

# Space id: folder in the campaign ("" for all of it), name, description.
SPACES = {
    "dm": ("", "DM", "The whole campaign: play state, and a window into the other four"),
    "adventure": ("Adventure", "Adventure", "The adventure as written; what the book is built from"),
    "author": ("Author", "Author", "Why the adventure says what it says"),
    "book": ("Book", "Book", "Notes on the novels the campaign adapts"),
    "player": ("Player", "Player", "What the party has been shown, and their own notes"),
}


def folder(sid):
    return TREE if sid == "dm" else WORK / ("space-" + sid)


# ---------------------------------------------------------------- locking

class Lock:
    """An exclusive lock on the port's lock file, released when the process ends."""

    def __enter__(self):
        WORK.mkdir(exist_ok=True)
        LOCKFILE.parent.mkdir(parents=True, exist_ok=True)
        self.f = open(LOCKFILE, "a+b")
        waited = 0.0
        while True:
            try:
                self.f.seek(0)
                msvcrt.locking(self.f.fileno(), msvcrt.LK_NBLCK, 1)
                return self
            except OSError:
                if waited == 0:
                    print(f"[instance] waiting for the lock on port {PORT} ({LOCKFILE}), "
                          "which this or another checkout holds...", file=sys.stderr)
                time.sleep(0.25)
                waited += 0.25
                if waited > 1800:
                    sys.exit("[instance] gave up waiting for the lock after 30 min")

    def __exit__(self, *exc):
        self.f.seek(0)
        msvcrt.locking(self.f.fileno(), msvcrt.LK_UNLCK, 1)
        self.f.close()


# ---------------------------------------------------------------- the campaign

def hashes():
    out = {}
    for p in TREE.rglob("*"):
        if p.is_file():
            out[p.relative_to(TREE).as_posix()] = hashlib.sha1(p.read_bytes()).hexdigest()
    return out


def copy_campaign(src):
    if src:
        run.use_src(src)
    pages = run.tree()
    if TREE.exists():
        shutil.rmtree(TREE)
    for name, text in pages.items():
        p = TREE / f"{name}.md"
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(text.encode("utf-8"))
    COPIED.write_text(json.dumps(pages), encoding="utf-8")
    BASELINE.write_text(json.dumps(hashes()), encoding="utf-8")
    print(f"campaign: {len(pages)} pages copied to {TREE}, libraries from {run.SRC}")


def junctions():
    for sid in SPACES:
        if sid != "dm":
            link = folder(sid)
            if os.path.isdir(link):
                os.rmdir(link)  # a junction: removes the link, never its target
            _winapi.CreateJunction(str(TREE / SPACES[sid][0]), str(link))


def changes(before, after):
    added = sorted(set(after) - set(before))
    removed = sorted(set(before) - set(after))
    changed = sorted(k for k in set(before) & set(after) if before[k] != after[k])
    return added, changed, removed


def diff():
    return changes(json.loads(BASELINE.read_text(encoding="utf-8")), hashes())


def restore():
    added, changed, removed = diff()
    pages = json.loads(COPIED.read_text(encoding="utf-8"))
    for rel in changed + removed:
        name = rel[:-3] if rel.endswith(".md") else None
        if name in pages:
            (TREE / rel).parent.mkdir(parents=True, exist_ok=True)
            (TREE / rel).write_bytes(pages[name].encode("utf-8"))
    for rel in added:
        (TREE / rel).unlink()
    return added, changed, removed


# ---------------------------------------------------------------- the server

def pid():
    try:
        return int(PIDFILE.read_text())
    except (OSError, ValueError):
        return None


def alive(p):
    """Whether pid p is running, and is a SilverBullet server: after a
    restart, the pid in server.pid may be some other program's."""
    if not p:
        return False
    out = subprocess.run(["tasklist", "/FI", f"PID eq {p}", "/FO", "CSV", "/NH"],
                         capture_output=True, text=True).stdout
    for row in csv.reader(out.splitlines()):
        if len(row) > 1 and row[1] == str(p):
            return row[0].lower() == BIN.name.lower()
    return False


def listener():
    """The pid listening on PORT, or None. A listening socket is the one whose
    far end is 0.0.0.0:0; netstat's state column is in the system's language."""
    out = subprocess.run(["netstat", "-ano", "-p", "TCP"], capture_output=True, text=True).stdout
    for line in out.splitlines():
        parts = line.split()
        if (len(parts) == 5 and parts[0] == "TCP" and parts[1].rsplit(":", 1)[-1] == str(PORT)
                and parts[2] == "0.0.0.0:0" and parts[4].isdigit()):
            return int(parts[4])
    return None


def ours():
    """Stop unless this checkout's server is running and is the one on PORT."""
    p, owner = pid(), listener()
    if not alive(p):
        sys.exit(f"[instance] this checkout's server is not running"
                 + (f", and pid {owner} is listening on port {PORT}" if owner else "")
                 + ": start it (or provision)")
    if owner != p:
        sys.exit(f"[instance] this checkout's server (pid {p}) is running, but "
                 + (f"pid {owner}" if owner else "nothing") + f" is listening on port {PORT}: "
                 "stop it and start it again")


def start():
    """Start this checkout's server, and wait until it is the one answering."""
    p, owner = pid(), listener()
    if alive(p):
        if owner == p:
            print("already running, pid", p)
            return
        sys.exit(f"[instance] this checkout's server (pid {p}) is running, but "
                 + (f"pid {owner}" if owner else "nothing") + f" is listening on port {PORT}: "
                 "stop it and start it again")
    if owner is not None:
        sys.exit(f"[instance] pid {owner}, not this checkout's server, is listening on port {PORT}: "
                 "stop it, with its own checkout's instance.py stop if it is one, or set SB_TEST_PORT")
    if not BIN.exists():
        sys.exit(f"no SilverBullet server at {BIN}: set SB_BIN, or put the 2.11.0 release's there")
    env = dict(os.environ, SB_HOSTNAME=HOST, SB_PORT=str(PORT), SB_SHELL_BACKEND="off",
               SB_CHROME_PATH=str(CHROME), SB_CHROME_DATA_DIR=str(CHROME_DATA))
    for k in ("SB_USER", "SB_URL_PREFIX", "SB_READ_ONLY", "SB_AUTH_TOKEN"):
        env.pop(k, None)  # any of these would force single-space mode
    CHROME_DATA.mkdir(parents=True, exist_ok=True)
    log = open(LOG, "ab")
    flags = subprocess.DETACHED_PROCESS | subprocess.CREATE_NEW_PROCESS_GROUP
    proc = subprocess.Popen([str(BIN), str(DATA)], env=env, stdout=log, stderr=log,
                            stdin=subprocess.DEVNULL, creationflags=flags, cwd=str(WORK))
    PIDFILE.write_text(str(proc.pid))
    began = time.time()
    while time.time() - began < 30:
        code = proc.poll()
        if code is not None:
            PIDFILE.unlink(missing_ok=True)
            sys.exit(f"[instance] the server stopped, with exit code {code}, before it answered; "
                     f"see {LOG}")
        try:
            urllib.request.urlopen(BASE + "/dm/.ping", timeout=2)
        except Exception:
            time.sleep(0.5)
            continue
        owner = listener()
        if owner == proc.pid:
            print("started, pid", proc.pid, "at", BASE)
            return
        stop()
        sys.exit(f"[instance] {BASE} answered, but pid {owner}, not the server just started "
                 f"(pid {proc.pid}, now stopped), is listening there")
    stop()
    sys.exit(f"[instance] the server (pid {proc.pid}, now stopped) did not answer /dm/.ping "
             f"within 30 s; see {LOG}")


def stop():
    p = pid()
    if alive(p):
        subprocess.run(["taskkill", "/PID", str(p), "/T", "/F"], capture_output=True)
        print("stopped", p)
    PIDFILE.unlink(missing_ok=True)


def write_spaces():
    spaces = {}
    for sid, (_, name, desc) in SPACES.items():
        spaces[sid] = {
            "name": name, "folder": str(folder(sid)), "binding": {"prefix": "/" + sid},
            "access": "read", "shell": {"enabled": False, "whitelist": []},
            "revisions": "disabled", "description": desc,
        }
    (DATA / "spaces.json").write_text(json.dumps(spaces, indent=2), encoding="utf-8")


# ---------------------------------------------------------------- HTTP

def http(method, path, body=None, headers=None, timeout=120):
    data = body.encode("utf-8") if isinstance(body, str) else body
    req = urllib.request.Request(BASE + path, data=data, method=method, headers=headers or {})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, r.read().decode("utf-8"), r.headers
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace"), e.headers


def secrets_():
    return json.loads(SECRETS.read_text(encoding="utf-8"))


def login_cookie():
    status, body, headers = http("POST", "/.dashboard/api/login",
                                 json.dumps({"username": ADMIN, "password": secrets_()["password"]}),
                                 {"Content-Type": "application/json"})
    if status != 200:
        sys.exit(f"login failed: {status} {body}")
    return "; ".join(c.split(";")[0] for c in headers.get_all("Set-Cookie") or [])


def auth():
    return {"Authorization": "Bearer " + secrets_()["token"]}


def runtime(space, kind, src, timeout=120):
    status, body, _ = http("POST", f"/{space}/.runtime/{kind}", src,
                           dict(auth(), **{"X-Timeout": str(timeout), "Content-Type": "text/plain"}),
                           timeout=timeout + 30)
    return status, body


def wait_idle(space, limit=900):
    """After a timeout: poll until no wrapped script is running in the client."""
    began = time.time()
    while time.time() - began < limit:
        status, body = runtime(space, "lua", "__instance_busy or 0", 30)
        if status == 200:
            try:
                if json.loads(body).get("result", 0) in (0, None):
                    break
            except ValueError:
                pass
        time.sleep(2)
    return int(time.time() - began)


def report(before):
    added, changed, removed = changes(before, hashes())
    if added or changed or removed:
        print("[instance] this request changed the campaign:", file=sys.stderr)
        for label, items in (("+", added), ("~", changed), ("-", removed)):
            for rel in items:
                print(f"[instance]   {label} {rel}", file=sys.stderr)


# ---------------------------------------------------------------- commands

def provision(src):
    stop()
    for d in (DATA, CHROME_DATA):
        if d.exists():
            shutil.rmtree(d)
    WORK.mkdir(exist_ok=True)
    copy_campaign(src)
    junctions()
    password = secrets.token_urlsafe(18)
    if not BIN.exists():
        sys.exit(f"no SilverBullet server at {BIN}: set SB_BIN, or put the 2.11.0 release's there")
    subprocess.run([str(BIN), "setup", "--admin", f"{ADMIN}:{password}", str(DATA)],
                   check=True, capture_output=True)
    write_spaces()
    start()
    SECRETS.write_text(json.dumps({"password": password, "token": ""}), encoding="utf-8")
    cookie = login_cookie()
    status, body, _ = http("POST", f"/.dashboard/api/admin/users/{ADMIN}/tokens",
                           json.dumps({"name": "tests"}),
                           {"Content-Type": "application/json", "Cookie": cookie, "Origin": BASE})
    if status != 200:
        sys.exit(f"token failed: {status} {body}")
    SECRETS.write_text(json.dumps({"password": password, "token": json.loads(body)["token"]}),
                       encoding="utf-8")
    print("admin and an API token saved to", SECRETS)
    print("spaces:", ", ".join("/" + s + "/" for s in SPACES))


def reset(src):
    stop()
    if CHROME_DATA.exists():
        shutil.rmtree(CHROME_DATA, ignore_errors=True)
    copy_campaign(src)
    junctions()
    write_spaces()
    start()


def main(argv):
    if not argv:
        sys.exit(__doc__)
    cmd, rest = argv[0], argv[1:]
    src = rest[rest.index("--src") + 1] if "--src" in rest else None
    sys.stdout.reconfigure(encoding="utf-8")
    if cmd == "provision":
        with Lock():
            provision(src)
    elif cmd == "start":
        with Lock():
            start()
    elif cmd == "stop":
        with Lock():
            stop()
    elif cmd == "status":
        p, owner = pid(), listener()
        print("running" if alive(p) else "stopped", p, BASE)
        if owner is not None and owner != p:
            print(f"pid {owner}, not this checkout's server, is listening on port {PORT}")
        print("spaces:", ", ".join("/" + s + "/" for s in SPACES))
    elif cmd == "reset":
        with Lock():
            reset(src)
    elif cmd in ("eval", "script"):
        space, source = rest[0], rest[1]
        if cmd == "script":
            source = sys.stdin.read() if source == "-" else pathlib.Path(source).read_text(encoding="utf-8")
            # Count the script as running until it really ends: a request that
            # times out leaves it running in the client, and the lock must
            # outlast it or the next caller's flow interleaves with it.
            source = (PRELUDE.read_text(encoding="utf-8") + "\n"
                      + "__instance_busy = (__instance_busy or 0) + 1\n"
                      + "local __instance_ok, __instance_res = pcall(function()\n"
                      + source
                      + "\nend)\n__instance_busy = __instance_busy - 1\n"
                      + "if not __instance_ok then error(__instance_res, 0) end\n"
                      + "return __instance_res\n")
        timeout = int(os.environ.get("INSTANCE_TIMEOUT", "120"))
        with Lock():
            ours()
            before = hashes()
            status, body = runtime(space, "lua" if cmd == "eval" else "lua_script", source, timeout)
            if cmd == "script" and status == 504:
                waited = wait_idle(space)
                print(f"[instance] timed out after {timeout} s; the script kept running in the "
                      f"client, and the lock was held {waited} s more until it finished",
                      file=sys.stderr)
            report(before)
        print(body)
        sys.exit(0 if status == 200 else 1)
    elif cmd == "logs":
        ours()
        limit = rest[1] if len(rest) > 1 else "100"
        status, body, _ = http("GET", f"/{rest[0]}/.runtime/logs?limit={limit}", headers=auth())
        for e in json.loads(body).get("logs", []) if status == 200 else []:
            print(e["level"], e["text"])
        if status != 200:
            print(status, body)
    elif cmd == "diff":
        added, changed, removed = diff()
        for label, items in (("+", added), ("~", changed), ("-", removed)):
            for rel in items:
                print(label, rel)
        if not (added or changed or removed):
            print("the campaign is as copied")
    elif cmd == "restore":
        with Lock():
            added, changed, removed = restore()
            if added or changed or removed:
                time.sleep(5)  # the client notices disk changes within ~4 s
        print(f"restored: {len(changed)} changed and {len(removed)} deleted files put back, "
              f"{len(added)} new files removed")
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
