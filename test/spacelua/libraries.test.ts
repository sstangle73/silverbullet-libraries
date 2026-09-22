// Runs the GM libraries in SilverBullet 2.11's own Lua runtime, over the test
// campaign as a DM space holds it: test/fixture/, with each library from src/
// where test/install.json puts it. SBLIB is the silverbullet-libraries root.
//
// The plain-Lua suite (test/run.py) is the wide one. This one is narrow and
// honest: Space Lua is not Lua 5.4, and a library that passes there can
// still fail here, as GM Kit's marks once did.
import { expect, test } from "vitest";
import { readFileSync, readdirSync, statSync } from "node:fs";
import { join, relative, sep } from "node:path";
import { parseBlock } from "./parse.ts";
import { luaBuildStandardEnv } from "./stdlib.ts";
import { LuaEnv, LuaNativeJSFunction, LuaStackFrame, LuaTable } from "./runtime.ts";
import { evalStatement } from "./eval.ts";
import { extractSpaceLuaFromPageText } from "../boot_config.ts";
import { parse } from "../markdown_parser/parse_tree.ts";
import { buildExtendedMarkdownLanguage } from "../markdown_parser/parser.ts";
import YAML from "js-yaml";

const ROOT = process.env.SBLIB!;
const SB = process.cwd();
const SCENE2 = "Adventure/Campaign/Act I/Scene 2";
const LANTERN = "Adventure/World/Items/Lantern";
const RECORD = "State/Items/Lantern";
const WARDEN = "Adventure/World/People/The Warden";

function loadTree(root: string): Map<string, string> {
  const pages = new Map<string, string>();
  const fixture = join(root, "test", "fixture");
  const walk = (dir: string) => {
    for (const e of readdirSync(dir)) {
      const p = join(dir, e);
      if (statSync(p).isDirectory()) walk(p);
      else if (e.endsWith(".md")) {
        pages.set(relative(fixture, p).split(sep).join("/").replace(/\.md$/, ""), readFileSync(p, "utf-8"));
      }
    }
  };
  walk(fixture);
  const install: Record<string, string[]> = JSON.parse(readFileSync(join(root, "test", "install.json"), "utf-8"));
  for (const [folder, libs] of Object.entries(install)) {
    for (const lib of libs) pages.set(folder + lib, readFileSync(join(root, "src", lib + ".md"), "utf-8"));
  }
  // As the plain-Lua suite's reset does, start from a campaign nobody has
  // played: State/, Sessions/ and the players' copies go, the revealed list
  // stays.
  for (const name of [...pages.keys()]) {
    const rest = name.match(/^(?:State|Sessions|Player)\/(.*)$/)?.[1];
    if (rest && !/^(index|CONFIG|Revealed)$/.test(rest) && !/^(Notes|Library)\//.test(rest)) {
      pages.delete(name);
    }
  }
  return pages;
}

function scalar(v: string): unknown {
  if (v === "") return null;
  // YAML flow lists, as a creature's CRs are: ["3", "5"]
  const list = v.match(/^\[(.*)\]$/);
  if (list) return list[1].split(",").map((s) => s.trim()).filter((s) => s !== "").map(scalar);
  if (v === "true") return true;
  if (v === "false") return false;
  if (/^-?\d+(\.\d+)?$/.test(v)) return Number(v);
  const q = v.match(/^"(.*)"$/) || v.match(/^'(.*)'$/);
  return q ? q[1] : v;
}

function frontmatter(text: string): Record<string, unknown> {
  const m = text.match(/^---\n([\s\S]*?)\n---/);
  const out: Record<string, unknown> = {};
  if (!m) return out;
  for (const line of m[1].split("\n")) {
    const kv = line.match(/^([\w-]+):\s*(.*?)\s*$/);
    if (kv && kv[1] !== "name") out[kv[1]] = scalar(kv[2]);
  }
  return out;
}

const PRELUDE = `
-- dom, as plain tables: enough to draw, read and click a bar
dom = setmetatable({}, { __index = function(_, tag)
  return function(spec)
    return setmetatable({ tag = tag, spec = spec }, { __index = function(node, key)
      if key == "outerHTML" then
        local out = {}
        for _, c in ipairs(spec) do out[#out + 1] = type(c) == "string" and c or c.outerHTML end
        return "<" .. tag .. ">" .. (spec.__rawText or table.concat(out)) .. "</" .. tag .. ">"
      end
    end })
  end
end })

function __text(node)
  if type(node) == "string" then return node end
  local out = {}
  if node.spec.__rawText then out[#out + 1] = node.spec.__rawText end
  for _, c in ipairs(node.spec) do out[#out + 1] = __text(c) end
  return table.concat(out, " ")
end

local function collect(node, out)
  if type(node) ~= "table" then return end
  if node.tag == "button" then out[#out + 1] = node end
  for _, c in ipairs(node.spec) do collect(c, out) end
end

function __buttons(node)
  local found, names = {}, {}
  collect(node, found)
  for i, b in ipairs(found) do names[i] = __text(b) end
  return table.concat(names, " | ")
end

function __click(node, label)
  local found = {}
  collect(node, found)
  for _, b in ipairs(found) do
    if __text(b) == label then return b.spec.onclick() end
  end
  error("no button " .. label .. " in " .. __buttons(node))
end
`;

async function setup(root: string) {
  const pages = loadTree(root);
  const notes: { message: string; kind: string; options: any }[] = [];
  const printed: string[] = [];
  const store: Record<string, any> = {};
  const picks: string[] = [];
  const prompts: string[] = [];
  const opened: string[] = [];
  // files other than pages, such as a printed PDF: path to lastModified, in ms
  const files = new Map<string, number>();
  const state = { current: "index" };
  const lagged: { known: Set<string> | null } = { known: null };
  const freeze = () => {
    lagged.known = new Set(pages.keys());
  };
  (globalThis as any).client = {
    config: { get: (_k: string, fallback: unknown) => fallback ?? {} },
  };
  const env = new LuaEnv(luaBuildStandardEnv());
  const stub = (name: string, fns: Record<string, (...a: any[]) => unknown>) => {
    const t = new LuaTable();
    for (const [k, f] of Object.entries(fns)) t.rawSet(k, new LuaNativeJSFunction(f));
    env.set(name, t);
  };
  const getPath = (path: string) =>
    path.split(".").reduce((o: any, k) => (o === null || o === undefined ? undefined : o[k]), store);
  stub("config", {
    get: (key: string, fallback: unknown) => {
      const v = getPath(key);
      return v === undefined ? (fallback ?? null) : v;
    },
    set: (key: string, value: unknown) => {
      const parts = key.split(".");
      let o = store;
      for (const p of parts.slice(0, -1)) o = o[p] ??= {};
      o[parts.at(-1)!] = value;
    },
  });
  stub("editor", {
    getCurrentPage: () => state.current,
    flashNotification: (message: string, kind: string, options: any) => {
      notes.push({ message, kind: kind ?? "info", options });
    },
    filterBox: (_label: string, options: any[]) => {
      const want = picks.shift();
      return options.find((o) => o.name === want) ?? null;
    },
    prompt: () => prompts.shift() ?? null,
    confirm: () => true,
    save: () => null,
    reloadPage: () => null,
    navigate: (p: string) => {
      state.current = p;
    },
    openUrl: (url: string) => {
      opened.push(url);
    },
  });
  stub("space", {
    readPage: (n: string) => {
      const t = pages.get(n);
      if (t === undefined) throw new Error("Not found: " + n);
      return t;
    },
    writePage: (n: string, t: string) => {
      pages.set(n, t);
      return { name: n };
    },
    // As in SilverBullet 2.11 (client/plugos/syscalls/space.ts): link
    // resolution, an exact name or else any page whose path ends in it,
    // ignoring case, over a list that lags writes (freeze() holds it), and
    // not the look at the page that getPageMeta is.
    pageExists: (n: string) => {
      const names = lagged.known ?? new Set(pages.keys());
      if (names.has(n)) return true;
      const tail = "/" + n.toLowerCase();
      return [...names].some((p) => ("/" + p.toLowerCase()).endsWith(tail));
    },
    getPageMeta: (n: string) => {
      if (!pages.has(n)) throw new Error("Not found");
      return { name: n };
    },
    // Exact, over every file: a page is its name plus ".md", last changed
    // at 1000 ms; any other file is in files.
    fileExists: (n: string) => (n.endsWith(".md") ? pages.has(n.slice(0, -3)) : files.has(n)),
    getFileMeta: (n: string) => {
      if (n.endsWith(".md") && pages.has(n.slice(0, -3))) return { name: n, lastModified: 1000 };
      if (files.has(n)) return { name: n, lastModified: files.get(n) };
      throw new Error("Not found");
    },
    deletePage: (n: string) => {
      pages.delete(n);
    },
  });
  stub("index", {
    pages: () => [...pages].map(([name, text]) => ({ ...frontmatter(text), name })),
  });
  stub("markdown", {
    parseMarkdown: (text: string) => parse(buildExtendedMarkdownLanguage({}), text),
    // the tests read the Markdown it was given, not a rendering of it
    markdownToHtml: (text: string) => '<div class="md">' + text + "</div>",
  });
  // As SilverBullet's own yaml.parse: js-yaml, its result handed to Lua as
  // plain JavaScript values, unconverted, as every syscall's result is
  stub("yaml", { parse: (text: string) => YAML.load(text) });
  stub("codeWidget", { refreshAll: () => null });
  stub("command", { define: () => null });
  stub("actionButton", { define: () => null });
  stub("event", { listen: () => null });
  stub("jsonschema", { validateObject: () => null });
  stub("system", {
    getURLPrefix: () => "/dm/",
    getBaseURI: () => "https://wiki.example.org/dm/",
  });
  env.set("print", new LuaNativeJSFunction((...a: unknown[]) => {
    printed.push(a.join(" "));
  }));

  // A Lua error holds its stack frame, and through it the whole environment:
  // pass on the message alone, or vitest runs out of memory reporting it.
  const run = async (code: string) => {
    const c = parseBlock(code, {});
    try {
      await evalStatement(c, env, LuaStackFrame.createWithGlobalEnv(env, c.ctx));
    } catch (e: any) {
      throw new Error(String(e?.message ?? e));
    }
  };
  await run(PRELUDE);
  // Every GM library the DM space loads, in SilverBullet's order: priority
  // first, then page name.
  const priority = (md: string) => Number(md.match(/```space-lua\n\s*--\s*priority:\s*(-?\d+)/)?.[1] ?? 0);
  const gmLibs = [...pages.keys()]
    .filter((n) => /(^|\/)Library\/Storie\/GM [^/]+$/.test(n))
    .sort((a, b) => priority(pages.get(b)!) - priority(pages.get(a)!) || (a < b ? -1 : a > b ? 1 : 0));
  const libs = [
    readFileSync(join(SB, "libraries/Library/Std/APIs/Widget.md"), "utf-8"),
    ...gmLibs.map((n) => pages.get(n)!),
  ];
  for (const md of libs) await run(extractSpaceLuaFromPageText(md));
  return { env, run, pages, notes, printed, picks, prompts, state, freeze, opened, files };
}

// Run a notification's action, passing on only the message of an error.
async function action(note: { options: any }, name: string) {
  try {
    await note.options.actions.find((a: any) => a.name === name).run();
  } catch (e: any) {
    throw new Error(String(e?.message ?? e));
  }
}

test("Scene 2's bar draws, with a row for the lantern", async () => {
  const { env, run, printed } = await setup(ROOT);
  await run(`__bar = gm.bar("${SCENE2}")`);
  await run(`__b = __buttons(__bar.html); __t = __text(__bar.html)`);
  expect(env.get("__b")).toBe("Reveal | Mark planned | Mark started | Mark found");
  expect(env.get("__t")).toContain("six wicks here");
  expect(printed).toEqual([]);
}, 60000);

test("the lantern is found, used, refunded and undone from its buttons", async () => {
  const { env, run, pages, notes, state } = await setup(ROOT);
  state.current = SCENE2;
  await run(`__click(gm.bar().html, "Mark found")`);
  expect(notes.filter((n) => n.message.startsWith("GM Kit:"))).toEqual([]);
  expect(notes.at(-1)!.message).toBe("Lantern: found in session 1, with six wicks.");
  expect(notes.at(-1)!.options.actions.map((a: any) => a.name)).toEqual(["Reveal", "Undo"]);
  const found = pages.get(RECORD)!;
  expect(found).toContain(
    'found: true\nfound_in: "[[' + SCENE2 + ']]"\nfound_session: 1\nunit: wick\nunits: wicks\nuses: 6\nuses_found: 6\n',
  );
  expect(found).toContain("- [[Sessions/Session 1|Session 1]]: found in [[" + SCENE2 + "]], with six wicks\n");
  await run(`__click(gm.bar().html, "Use a wick")`);
  await run(`__click(gm.bar().html, "Use a wick")`);
  expect(notes.filter((n) => n.message.startsWith("GM Kit:"))).toEqual([]);
  expect(notes.at(-1)!.message).toBe("Lantern: a wick used. 4 of 6 wicks left.");
  expect(pages.get(RECORD)).toContain("\nuses: 4\n");
  await run(`__t = __text(gm.bar().html)`);
  expect(env.get("__t")).toContain("●●●●○○ 4 of 6 wicks left");
  await action(notes.at(-1)!, "Undo");
  expect(pages.get(RECORD)).toContain("\nuses: 5\n");
  expect(notes.at(-1)!.message).toBe("Undone: Lantern is back to 5 of 6 wicks left");
  await run(`__click(gm.bar().html, "Refund a wick")`);
  expect(pages.get(RECORD)).toContain("\nuses: 6\n");
  expect(pages.get(RECORD)).toContain("- [[Sessions/Session 1|Session 1]]: a wick refunded, 6 left\n");
  expect(notes.filter((n) => n.message.startsWith("GM Kit:"))).toEqual([]);
}, 60000);

test("a find recorded by mistake comes off again", async () => {
  const { env, run, pages, notes, state } = await setup(ROOT);
  state.current = SCENE2;
  await run(`__click(gm.bar().html, "Mark found")`);
  await run(`gm.spend("${LANTERN}", -1)`);
  state.current = LANTERN;
  await run(`__click(gm.bar().html, "Unmark found")`);
  expect(notes.filter((n) => n.message.startsWith("GM Kit:"))).toEqual([]);
  expect(notes.at(-1)!.message).toBe("Lantern: no longer marked found, and its uses with it.");
  const record = pages.get(RECORD)!;
  expect(record).not.toContain("found: true");
  expect(record).not.toContain("uses:");
  expect(record).toContain("- [[Sessions/Session 1|Session 1]]: not found after all");
  await run(`__b = __buttons(gm.bar().html)`);
  // the lantern's Rules section is a part the players can be shown alone
  expect(env.get("__b")).toBe("Reveal | Reveal part… | Mark found");
  await action(notes.at(-1)!, "Undo");
  expect(pages.get(RECORD)).toContain("\nuses: 5\n");
  expect(pages.get(RECORD)).not.toContain("not found after all");
}, 60000);

test("a second mark keeps the first, whatever space.pageExists says", async () => {
  const { env, run, pages, freeze } = await setup(ROOT);
  // the list pageExists reads stays as it was before the first mark, the way
  // a client's lags a write: GM Kit 3.1 then rebuilt the record and lost it
  freeze();
  await run(`gm.mark("${WARDEN}", "met"); gm.mark("${WARDEN}", "dead")`);
  const record = pages.get("State/People/The Warden")!;
  expect(record).toContain("met: true");
  expect(record).toContain("status: dead");
  // pageExists answers the way a link resolves; gm.exists asks for the page
  await run(`__e = gm.exists("World/Items/Lantern"); __f = space.pageExists("World/Items/Lantern")`);
  expect(env.get("__f")).toBe(true);
  expect(env.get("__e")).toBe(false);
}, 60000);

test("marking someone met writes their play state, and reveals what the page shows first", async () => {
  const { run, pages, notes } = await setup(ROOT);
  await run(`gm.mark("${WARDEN}", "met")`);
  expect(pages.get("State/People/The Warden")).toContain("met: true\nmet_session: 1\n");
  expect(notes.at(-1)!.message).toBe("The Warden: met in session 1, and revealed “First Impressions”.");
  expect(pages.get("State/Revealed")).toContain("- [[" + WARDEN + "#First Impressions]]\n");
}, 60000);

// Revealing part of a page, in SilverBullet's own Lua: the parts are read
// with its string library, and the players' copy has the title and the
// parts revealed.
test("a page revealed in part publishes its title and those parts only", async () => {
  const { run, pages } = await setup(ROOT);
  await run(`gm.writeRevealed({}); gm.revealPart("${WARDEN}", "At the Table"); gm.mark("Adventure/World/People/Old Tam", "met"); gm.publish()`);
  expect(pages.get("Player/World/People/The Warden")).toBe(
    "---\ntype: npc\n---\n\n# The Warden\n\n## At the Table\n\n" +
      "Polite, tired, and never in a hurry. The Warden answers a question with a question.\n",
  );
  expect(pages.get("Player/World/People/Old Tam")).toBe("---\ntype: npc\n---\n\n# Old Tam\n");
}, 60000);

test("the Session Table's Found query reads the uses", async () => {
  const { env, run, pages } = await setup(ROOT);
  await run(`gm.markFound("${LANTERN}", "${SCENE2}"); gm.spend("${LANTERN}", -1)`);
  const table = pages.get("Session Table")!;
  const src = table.slice(table.indexOf("## Found")).match(/\$\{(query\[\[[\s\S]*?\]\])\}/)![1];
  env.set("__src", src);
  await run(`__rows = spacelua.evalExpression(spacelua.parseExpression(__src))`);
  const rows = env.get("__rows") as any[];
  expect(rows.length).toBe(1);
  expect(rows[0].Left).toBe("●●●●●○ 5 of 6 wicks left");
  // the number is the Session Table's own, not a constant
  const n = Number(table.match(/^---\n[\s\S]*?\nsession: (\d+)\n[\s\S]*?---/)![1]);
  expect(rows[0].Session).toBe(`[[Sessions/Session ${n}|Session ${n}]]`);
}, 60000);

test("party.value gives the count as a number", async () => {
  const { env, run } = await setup(ROOT);
  await run(`__v = party.value{"wick", plus = 1}; __w = party.value({"wick"}, 7)`);
  expect(env.get("__v")).toBe(6);
  expect(env.get("__w")).toBe(7);
}, 60000);

test("the book builds as committed, with the pointer, and in place when asked", async () => {
  const { run, pages, notes } = await setup(ROOT);
  const committed = {
    dm: pages.get("Adventure/Build/Book DM")!,
    player: pages.get("Adventure/Build/Book Player")!,
  };
  await run(`gmbook.build({ "dm", "player" })`);
  // say what the warning was, if there is one
  expect(notes.at(-1)!.message).not.toContain("nothing to print");
  expect(notes.at(-1)!.kind).toBe("info");
  expect(pages.get("Adventure/Build/Book DM")).toBe(committed.dm);
  expect(pages.get("Adventure/Build/Book Player")).toBe(committed.player);
  expect(committed.dm).toContain("every traveller after.\n\n*See Lantern: Rules.*\n\n");
  // in place, the section sits one level under the heading it follows: the
  // scene's title
  await run(`config.set("gmBook.transclusions", "inline"); gmbook.compile({ "dm" })`);
  expect(pages.get("Adventure/Build/Book DM")).toContain("every traveller after.\n\n## Rules\n\n- **Wicks.**");
}, 300000);

test("a PDF printed beside an edition gets a button that opens it", async () => {
  const { env, run, notes, opened, files } = await setup(ROOT);
  const DM = "Adventure/Build/Book DM";
  await run(`__b = __buttons(gmbook.bar("${DM}").html)`);
  expect(env.get("__b")).toBe("Build again | Copy for Homebrewery | Open Homebrewery");
  files.set(DM + ".pdf", 2000);
  await run(`__b = __buttons(gmbook.bar("${DM}").html)`);
  expect(env.get("__b")).toBe("Build again | Open PDF | Copy for Homebrewery | Open Homebrewery");
  await run(`__click(gmbook.bar("${DM}").html, "Open PDF")`);
  expect(notes.filter((n) => n.message.startsWith("GM Book:"))).toEqual([]);
  expect(opened).toEqual(["https://wiki.example.org/dm/.fs/Adventure/Build/Book%20DM.pdf"]);
  // printed before the edition last changed
  files.set(DM + ".pdf", 999);
  await run(`__b = __buttons(gmbook.bar("${DM}").html)`);
  expect(env.get("__b")).toBe("Build again | Open PDF (older) | Copy for Homebrewery | Open Homebrewery");
}, 60000);

// DM-only text, in SilverBullet's own Lua: the cases tests/dmonly.lua runs in
// plain Lua, read from that file so the two suites can't drift apart.
test("DM-only text: each way of marking it strips and shows as in plain Lua", async () => {
  const { env, run } = await setup(ROOT);
  const src = readFileSync(join(ROOT, "test", "tests", "dmonly.lua"), "utf-8");
  const from = src.indexOf("local DM_CASES = {");
  const cases = src.slice(from + "local ".length, src.indexOf("\n}\n", from) + 2);
  await run(cases + `
__bad = {}
for _, c in ipairs(DM_CASES) do
  local function check(got, want, what)
    if got ~= want then __bad[#__bad + 1] = what .. ", " .. c[1] .. ": [" .. got .. "]" end
  end
  check(gm.stripSecrets(c[2]), c[3], "GM Kit")
  check(gmbook.stripSecrets(c[2]), c[3], "GM Book's player edition")
  check(gmbook.showSecrets(c[2]), c[4], "GM Book's DM edition")
end
__bad = table.concat(__bad, " | ")`);
  expect(env.get("DM_CASES").length).toBeGreaterThan(20);
  expect(env.get("__bad")).toBe("");
}, 60000);

test("DM-only text: publishing and both editions leave it where it belongs", async () => {
  const { run, pages } = await setup(ROOT);
  const crypt = [
    "# Crypt", "",
    'The door is locked. <span class="dm">The key is under the mat.</span> It is heavy.', "",
    "> **dm** Who waits below", "> The lich, asleep.", "",
    "Stone steps lead down.", "",
    "<!--#dm-->", "", "| Clue | Where |", "|---|---|", "| The torn letter | The cellar |", "", "<!--/dm-->", "",
    "## DM Only", "", "The third step is a pressure plate.", "",
  ].join("\n");
  pages.set("Adventure/World/Places/Crypt", "---\ntype: place\n---\n\n" + crypt);
  pages.set("Adventure/Campaign/Crypt", "---\nbook_order: 11\n---\n\n" + crypt);
  await run(`gm.writeRevealed({ "Adventure/World/Places/Crypt" }); gm.publish(); gmbook.compile({ "dm", "player" })`);
  expect(pages.get("Player/World/Places/Crypt")).toBe(
    "---\ntype: place\n---\n\n# Crypt\n\nThe door is locked. It is heavy.\n\nStone steps lead down.\n",
  );
  const dm = pages.get("Adventure/Build/Book DM")!;
  const player = pages.get("Adventure/Build/Book Player")!;
  expect(dm).toContain("The door is locked. The key is under the mat. It is heavy.");
  expect(dm).toContain("**Who waits below.** The lich, asleep.");
  expect(dm).toContain("| The torn letter | The cellar |");
  expect(player).toContain("The door is locked. It is heavy.\n\nStone steps lead down.");
  for (const secret of ["key is under", "The lich", "torn letter", "pressure plate", "**dm**", "<!--#dm"]) {
    expect(player).not.toContain(secret);
  }
  for (const syntax of ["**dm**", "<!--#dm", "<!--/dm", 'class="dm"']) expect(dm).not.toContain(syntax);
}, 300000);

// Rolls, in SilverBullet's own Lua: a check read off a scene with its string
// library, and the words of each rung written into the session's log. The
// scene is tests/rolls.lua's, read from that file so the two can't drift.
test("a roll logs the words of each rung it reached, and takes itself back", async () => {
  const { env, run, pages, notes, printed, picks, prompts, state } = await setup(ROOT);
  const src = readFileSync(join(ROOT, "test", "tests", "rolls.lua"), "utf-8");
  const mill = src.slice(src.indexOf("[==[") + 4, src.indexOf("]==]"));
  const MILL = "Adventure/Campaign/Act I/Scene 4";
  const LOG = "Sessions/Session 1";
  const STATE = "State/Scenes/Act I/Scene 4";
  const bank = "[[" + MILL + "#The bank|Scene 4]]";
  pages.set(MILL, mill);
  state.current = MILL;
  const errors = () => notes.filter((n) => n.message.startsWith("GM Kit:"));

  await run(`__names = {}; for i, c in ipairs(gm.checks("${MILL}")) do __names[i] = c.name .. "=" .. c.kind end; __names = table.concat(__names, " | ")`);
  expect(env.get("__names")).toBe(
    "Wisdom (Perception)=ladder | Intelligence (Investigation) · The bank=ladder | Wisdom (Insight)=ladder | " +
      "Intelligence (History)=ladder | Dexterity (Stealth), group, DC 12=dc | Intelligence (Investigation) · The loft=finds",
  );

  picks.push("Wisdom (Perception)", "15 to 19");
  await run(`__click(gm.bar().html, "Log a roll…")`);
  expect(errors()).toEqual([]);
  expect(pages.get(LOG)).toBe(
    "---\ntype: session\nsession: 1\n---\n\n# Session 1\n\n## Scenes\n\n## Rolls\n\n" +
      "- " + bank + " · Wisdom (Perception), 15 to 19:\n" +
      "  - Bootprints in the mud, heading for [[Adventure/World/Places/Fordtown|Fordtown]]\n" +
      "  - One set is a child's\n" +
      "  - The child was running, and the bigger prints were following\n\n## Decisions\n",
  );
  expect(pages.get(STATE)).toContain("roll_wisdom_perception: 15\nroll_wisdom_perception_session: 1\n");
  expect(notes.at(-1)!.message).toBe("Wisdom (Perception), 15 to 19: three things they know, logged to session 1.");
  await run(`__t = __text(gm.bar().html); __b = __buttons(gm.bar().html)`);
  expect(env.get("__t")).toContain("✓ Perception: [[Sessions/Session 1|15 to 19]]");
  expect(env.get("__t")).toContain("○ Stealth");
  expect(env.get("__b")).toBe("Reveal | Reveal part… | Mark planned | Mark started | Log a roll… | Unlog a roll…");

  // a better roll adds only what is new, and its Undo leaves the first
  picks.push("Wisdom (Perception)", "20 or more");
  await run(`gm.logRoll()`);
  expect(notes.at(-1)!.message).toBe("Wisdom (Perception), now 20 or more: one more thing they know, logged to session 1.");
  expect(pages.get(LOG)).toContain("- " + bank + " · Wisdom (Perception), now 20 or more:\n  - Whoever followed stopped at the water, and went back\n");
  await action(notes.at(-1)!, "Undo");
  expect(pages.get(STATE)).toContain("roll_wisdom_perception: 15\n");
  expect(pages.get(LOG)).not.toContain("now 20 or more");

  // a DC, a table of finds, a ladder in paragraphs with a live value, and
  // a roll the page doesn't set
  picks.push("Dexterity (Stealth), group, DC 12", "Failed");
  picks.push("Intelligence (Investigation) · The loft", "The sack", "10 or more");
  picks.push("Intelligence (History)", "15 or more");
  picks.push("Another roll…", "Wisdom (Survival)");
  prompts.push("14: the prints are a day old");
  await run(`gm.logRoll(); gm.logRoll(); gm.logRoll(); gm.logRoll()`);
  expect(errors()).toEqual([]);
  const log = pages.get(LOG)!;
  expect(log).toContain("- [[" + MILL + "#Getting away|Scene 4]] · Dexterity (Stealth), group, DC 12: failed\n");
  expect(log).toContain("The loft, The sack, 10 or more:\n  - Flour, gone grey\n  - A key sewn into the hem\n");
  expect(log).toContain("  - **If somebody reads the ledger.** Intelligence (History) says the last five pages are torn out.\n");
  expect(log).toContain("  - The last entry is in a different hand.\n");
  expect(log).toContain("- [[" + MILL + "|Scene 4]] · Wisdom (Survival): 14: the prints are a day old\n");
  await run(`__t = __text(gm.bar().html)`);
  expect(env.get("__t")).toContain("✗ Stealth: [[Sessions/Session 1|failed]]");
  expect(env.get("__t")).toContain("✓ Investigation: 1 of 2 found");

  // a link to another site stays, an image stays, and the page's own go
  // where they went
  await run(`__r = gm.rollText("${MILL}", "See [the map](https://example.org/map), ![a](<x.png>) and [Fordtown](<../../World/Places/Fordtown>)")`);
  expect(env.get("__r")).toBe("See [the map](https://example.org/map), ![a](<x.png>) and [[Adventure/World/Places/Fordtown|Fordtown]]");

  // unlogged, the logs say so, and Undo puts it back
  picks.push("Wisdom (Perception)");
  await run(`__click(gm.bar().html, "Unlog a roll…")`);
  expect(errors()).toEqual([]);
  expect(pages.get(STATE)).not.toContain("roll_wisdom_perception:");
  expect(pages.get(LOG)).toContain("- " + bank + " · Wisdom (Perception): not rolled after all\n");
  await action(notes.at(-1)!, "Undo");
  expect(pages.get(STATE)).toContain("roll_wisdom_perception: 15\n");
  expect(pages.get(LOG)).not.toContain("not rolled after all");
  expect(pages.get(MILL)).toBe(mill);
  expect(printed).toEqual([]);
}, 120000);

// Late, not lost, in SilverBullet's own Lua: the weir from tests/rolls.lua.
test("a rung the page calls late, not lost is owed until a roll reaches it", async () => {
  const { env, run, pages, notes, printed, picks, state } = await setup(ROOT);
  const src = readFileSync(join(ROOT, "test", "tests", "rolls.lua"), "utf-8");
  const at = src.indexOf("local WEIR_TEXT = [==[");
  const weir = src.slice(src.indexOf("[==[", at) + 4, src.indexOf("]==]", at));
  const WEIR = "Adventure/Campaign/Act I/Scene 5";
  pages.set(WEIR, weir);
  state.current = WEIR;
  picks.push("Intelligence (Arcana)", "10 to 19");
  await run(`gm.logRoll()`);
  expect(notes.filter((n) => n.message.startsWith("GM Kit:"))).toEqual([]);
  expect(notes.at(-1)!.message).toBe("Intelligence (Arcana), 10 to 19: two things they know, the 20 owed, logged to session 1.");
  expect(pages.get("Sessions/Session 1")).toContain(
    "  - Owed: the 20, late, not lost. The next time that character crosses running water, it comes back to them.\n",
  );
  await run(`__o = gm.owed().markdown; __t = __text(gm.bar().html); __l = gm.checks("${WEIR}")[3].late`);
  expect(env.get("__o")).toBe(
    "- [[" + WEIR + "#The weir|Scene 5]] · Intelligence (Arcana): the 20, owed since [[Sessions/Session 1|session 1]]. " +
      "The next time that character crosses running water, it comes back to them.",
  );
  expect(env.get("__t")).toContain("✓ Arcana: [[Sessions/Session 1|10 to 19]] · 20 owed");
  expect(env.get("__l")).toBe("they see it the next time he lies.");
  picks.push("Intelligence (Arcana)", "20 or more");
  await run(`gm.logRoll(); __o = gm.owed().markdown`);
  expect(env.get("__o")).toBe("Nothing is owed.");
  expect(printed).toEqual([]);
}, 60000);

// The party's level, in SilverBullet's own Lua: a fight in versions, a DC
// that rises with it, a creature page that lists every CR it runs at, and a
// check whose rungs are written through party.dc. The fight, what it
// prints and the scene are tests/levels.lua's, read from that file so the
// two can't drift apart.
test("a fight in versions, DCs by level, and a check that reads them", async () => {
  const { env, run, pages, printed, picks, notes, state } = await setup(ROOT);
  const src = readFileSync(join(ROOT, "test", "tests", "levels.lua"), "utf-8");
  const lua = (name: string, end: string) => {
    const from = src.indexOf("local " + name + " = ");
    return src.slice(from + "local ".length, src.indexOf(end, from) + end.length);
  };
  const at = src.indexOf("local VAULT_TEXT = [==[");
  const vault = src.slice(src.indexOf("[==[", at) + 4, src.indexOf("]==]", at));
  const VAULT = "Adventure/Campaign/Act I/Scene 6";
  pages.set(VAULT, vault);
  const level = (n: number) =>
    pages.set("The Party", pages.get("The Party")!.replace(/\nlevel: \d+\n/, `\nlevel: ${n}\n`));
  await run(lua("BARROW_LEVELS", "\n}\n") + lua("BARROW_LEVELS_PRINTED", '}, "\\n")\n'));

  level(5);
  await run(`party.refresh()
__print = party.fightPrint(BARROW_LEVELS)
__live = party.fight(BARROW_LEVELS).html
__dc = party.dc(15).markdown
__written = party.printed.dc(15)`);
  expect(env.get("__print")).toBe(env.get("BARROW_LEVELS_PRINTED"));
  expect(env.get("__live")).toContain("▶ Level 6");
  expect(env.get("__live")).toContain(", the nearest to your party's level 5");
  expect(env.get("__live")).toContain("Five here at level 5: a wraith, two wights and four skeletons, 3,400 XP.");
  expect(env.get("__live")).toContain("Level 3");
  expect(env.get("__dc")).toBe("16");
  expect(env.get("__written")).toBe("15");

  level(9);
  await run(`party.refresh()
local checks = gm.checks("${VAULT}")
__names = {}
for i, c in ipairs(checks) do __names[i] = c.name end
__names = table.concat(__names, " | ")
__bands = {}
for i, b in ipairs(gm.bands(checks[1].rungs, checks[1].rise)) do __bands[i] = b.label end
__bands = table.concat(__bands, " | ")
__late = checks[3].late
__insight = gm.bands(checks[4].rungs, checks[4].rise)[2].label`);
  expect(env.get("__names")).toBe(
    "Wisdom (Perception) | Strength (Athletics), DC 17 | Intelligence (Arcana) | Wisdom (Insight) | " +
      "Dexterity (Stealth), group, DC 14 | Intelligence (Investigation) | Wisdom (Survival), DC 15",
  );
  expect(env.get("__bands")).toBe("Under 12 | 12 to 16 | 17 or more");
  expect(env.get("__late")).toBe("The next time they see the caster, they know.");
  expect(env.get("__insight")).toBe("22 or more");

  state.current = VAULT;
  picks.push("Wisdom (Perception)", "17 or more");
  await run(`gm.logRoll()`);
  expect(notes.filter((n) => n.message.startsWith("GM Kit:"))).toEqual([]);
  expect(notes.at(-1)!.message).toBe("Wisdom (Perception), 17 or more: three things they know, logged to session 1.");
  expect(pages.get("Sessions/Session 1")).toContain("  - A second keyhole, under the plate: DC 22 to pick\n");
  expect(pages.get("State/Scenes/Act I/Scene 6")).toContain("roll_wisdom_perception: 15\n");

  pages.set("Adventure/World/Monsters/Barrow Lord", '---\ntype: monster\ncr: ["3", "5"]\n---\n\n# Barrow Lord\n');
  await run(`bestiary.refresh()
__five = tostring(party.creatureRef("World/Monsters/Barrow Lord", "barrow lord", 5).warn)
__four = party.creatureRef("World/Monsters/Barrow Lord", "barrow lord", 4).warn`);
  expect(env.get("__five")).toBe("nil");
  expect(env.get("__four")).toBe("The barrow lord is CR 4 here, and CR 3 or 5 on Barrow Lord.");
  expect(printed).toEqual([]);
}, 120000);

test("a character's sheet draws, and prints a page to itself, in SilverBullet's own Lua", async () => {
  const { env, run, pages, printed } = await setup(ROOT);
  // the ranger the plain-Lua tests draw, read from their file
  const src = readFileSync(join(ROOT, "test", "tests", "sheets.lua"), "utf-8");
  const at = src.indexOf("local RANGER = [==[");
  const ranger = src.slice(src.indexOf("[==[", at) + 4, src.indexOf("]==]", at));
  pages.set("Party/Tamsin Reed", ranger);
  await run(`local w = sheets.draw("Party/Tamsin Reed")
__html, __md = w.html, w.markdown
local d = sheets.read("Party/Tamsin Reed")
local v = sheets.values(d)
__sums = table.concat({ v.pb, v.saves.dex, v.skills.survival, v.passive.perception, v.spellDC,
  v.spellAttack, v.initiative }, " ")`);
  expect(env.get("__sums")).toBe("2 5 6 19 12 4 3");
  const md: string = env.get("__md");
  const html: string = env.get("__html");
  expect(md.startsWith('<div class="gmsheets-page" style="column-span:all">\n<svg ')).toBe(true);
  const svg = md.match(/<svg[\s\S]*?<\/svg>/)![0];
  expect(html).toContain(svg);
  expect(svg).toContain('<text x="0" y="24" font-size="24" font-weight="bold">Tamsin Reed</text>');
  expect(svg).toMatch(/width="672" height="\d+"/);
  // every number written as the plain-Lua suite writes it: no float's ".0"
  expect(svg).not.toMatch(/\.0"/);
  expect(svg).toContain(">Once the guild outfits her</text>");
  expect(md).toContain("### Deft Explorer\n\n***Expertise.*** You have Expertise in Survival.");
  expect(md).toContain(
    "**Level 1 (3 slots).** Cure Wounds, Goodberry (Action, Self; material: a sprig of mistletoe); " +
      "always prepared: Hunter's Mark (Bonus Action, 90 ft.; concentration).",
  );
  expect(md).toContain("**Coins.** 12 GP, 4 SP.");

  // a sample of the adventure's, in a chapter of its own, built into the book
  pages.set("Adventure/Rules/Sample Characters", "---\nbook_order: 45\n---\n\n# Sample Characters\n\nOne of them.\n");
  pages.set(
    "Adventure/Rules/Sample Characters/Tamsin Reed",
    ranger.replace("type: pc\nplayer: Sam\n", "type: sample\nbook_order: 45.01\nbook_section: true\n"),
  );
  await run(`__report = gmbook.compile({ "dm" })
__left = table.concat(__report.live, ", ")
__sample = sheets.printed.draw("Adventure/Rules/Sample Characters/Tamsin Reed")`);
  expect(env.get("__left")).toBe("");
  const book = pages.get("Adventure/Build/Book DM")!;
  expect(book).toContain('\\page\n\n<div class="gmsheets-page" style="column-span:all">\n<svg ');
  expect(book).toContain("</div>\n\n\\page\n\n### Class Features");
  // the book's drawing is the sample's own, which has no player
  const sample = (env.get("__sample") as string).match(/<svg[\s\S]*?<\/svg>/)![0];
  expect(book).toContain(sample);
  expect(sample).not.toContain(">Sam</text>");
  expect(printed).toEqual([]);
}, 120000);
