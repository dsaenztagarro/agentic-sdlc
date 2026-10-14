// shots — a screenshot of every page in every state it names, of the application surface alone.
//
// A page is a snapshot of the application: one surface, every state it can be in, reached from a
// state bar (design-handoff §4). This walks that bar on every page and captures the surface in each
// state, so what a reader looks at is the application and nothing drawn around it — a caption, a
// note or a paragraph beside the surface never reaches a shot. A page that does not keep the
// contract is named, and a brief fixes it; nothing here edits a page.
//
// The contract, in the page's own markup:
//   [data-surface]                            exactly one: the application as it renders, chrome included
//   [data-state="<Name>"]                     one per state, inside the surface, one shown at a time
//   [role="tablist"][aria-label="State"]      the state bar, one [role="tab"] per state, labelled with its name;
//                                             required once a page has two states, hidden in every shot
//   [data-family="<Family>"]                  on every state or none: a page with many states groups them;
//                                             a family's states sit together, each named "<Family> · <state>",
//                                             or "<Family>" alone for its first, without repeating the family;
//                                             its tab reads "<state>", or "Default" for the bare one, and may
//                                             be hidden while another family is shown
//
// Usage: node lib/shots.js PAGES_DIR OUT_DIR
// Exit 0 when every page keeps the contract, 1 when one does not, 2 when no browser can be launched.

const fs = require("fs");
const http = require("http");
const path = require("path");
const { chromium } = require("playwright-core");

const [pagesDir, outDir] = process.argv.slice(2).map((p) => path.resolve(p));
const SCALE = 2;
const BAR = '[role="tablist"][aria-label="State"]';
const TYPES = { ".html": "text/html", ".css": "text/css", ".js": "text/javascript", ".jsx": "text/javascript",
  ".json": "application/json", ".svg": "image/svg+xml", ".png": "image/png", ".woff2": "font/woff2" };

const slug = (s) => s.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");

function pages(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) return entry.name === "_ds" ? [] : pages(full);
    return entry.name.endsWith(".html") ? [full] : [];
  }).sort();
}

// Served over http rather than file://, which gives a page a null origin and breaks every fetch.
function serve(root) {
  const server = http.createServer((req, res) => {
    const file = path.join(root, decodeURIComponent(new URL(req.url, "http://x").pathname));
    if (!file.startsWith(root) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) {
      res.writeHead(404).end();
      return;
    }
    res.writeHead(200, { "content-type": TYPES[path.extname(file)] || "application/octet-stream" });
    fs.createReadStream(file).pipe(res);
  });
  return new Promise((resolve) => server.listen(0, "127.0.0.1", () => resolve(server)));
}

async function launch() {
  try {
    return await chromium.launch({ channel: "chrome" });
  } catch {
    return chromium.launch();
  }
}

async function contract(page) {
  return page.evaluate((bar) => {
    const states = [...document.querySelectorAll("[data-state]")]
      .filter((el) => !el.parentElement.closest("[data-state]"))
      .map((el) => ({ name: el.dataset.state, family: el.dataset.family }));
    const tablist = document.querySelector(bar);
    const tabs = tablist ? [...tablist.querySelectorAll('[role="tab"]')].map((t) => t.textContent.trim()) : null;
    return { surfaces: document.querySelectorAll("[data-surface]").length, states, tabs };
  }, BAR);
}

const escape = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

// The label a state's tab carries: its whole name, or within a family the part after the family.
function label({ name, family }) {
  if (!family) return name;
  if (name === family) return "Default";
  return name.startsWith(`${family} · `) ? name.slice(family.length + 3) : name;
}

function familyBreaches(states) {
  const grouped = states.filter((s) => s.family).length;
  if (grouped === 0) return [];
  if (grouped < states.length) return [`gives ${grouped} of its ${states.length} states a family; a grouped page gives every state one`];
  const found = [];
  const families = [...new Set(states.map((s) => s.family))];
  for (const family of families) {
    const at = states.flatMap((s, i) => (s.family === family ? [i] : []));
    if (at[at.length - 1] - at[0] + 1 !== at.length) found.push(`its "${family}" family is split: its states do not sit together`);
  }
  for (const s of states) {
    if (s.name !== s.family && !s.name.startsWith(`${s.family} · `)) {
      found.push(`its state "${s.name}" does not start with its family "${s.family}"`);
    } else if (s.name !== s.family && new RegExp(`\\b${escape(s.family)}\\b`, "i").test(label(s))) {
      found.push(`its state "${s.name}" repeats its family`);
    }
  }
  return found;
}

function breaches({ surfaces, states, tabs }) {
  const found = [];
  if (surfaces !== 1) found.push(`has ${surfaces} [data-surface] elements; it needs exactly one`);
  if (states.length === 0) found.push("names no state: no [data-state] element");
  if (states.length > 1 && !tabs) found.push(`has ${states.length} states and no state bar`);
  found.push(...familyBreaches(states));
  const labels = states.map(label);
  if (tabs && tabs.join("|") !== labels.join("|")) {
    found.push(`its state bar reads ${JSON.stringify(tabs)}, its states are ${JSON.stringify(labels)}`);
  }
  return found;
}

async function shoot(page, rel, states, hasBar) {
  const shots = [];
  for (const [i, { name }] of states.entries()) {
    if (hasBar) {
      // Dispatched rather than clicked: a grouped bar hides the tabs of every family but the one shown.
      await page.locator(`${BAR} [role="tab"]`).nth(i).dispatchEvent("click");
      const shown = await page.waitForFunction(
        (n) => [...document.querySelectorAll("[data-state]")].some((el) => el.dataset.state === n && el.checkVisibility()),
        name, { timeout: 2000 }
      ).then(() => true, () => false);
      if (!shown) return { breach: `its "${name}" tab does not show the "${name}" state` };
      await page.evaluate((bar) => { document.querySelector(bar).style.visibility = "hidden"; }, BAR);
    }
    const file = path.join(rel.replace(/\.html$/, ""), `${String(i + 1).padStart(2, "0")}-${slug(name)}.png`);
    fs.mkdirSync(path.join(outDir, path.dirname(file)), { recursive: true });
    await page.locator("[data-surface]").screenshot({ path: path.join(outDir, file), animations: "disabled" });
    if (hasBar) await page.evaluate((bar) => { document.querySelector(bar).style.visibility = ""; }, BAR);
    shots.push({ name, file });
  }
  return { shots };
}

function index(shot) {
  const esc = (s) => s.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);
  const sections = Object.entries(shot).map(([rel, shots]) =>
    `<section><h2>${esc(rel)}</h2>${shots.map((s) =>
      `<figure><img src="${esc(s.file)}" alt="${esc(s.name)}"><figcaption>${esc(s.name)}</figcaption></figure>`).join("")}</section>`);
  return `<!doctype html><meta charset="utf-8"><title>shots</title>
<style>body{font:14px system-ui;margin:24px;background:#f4f4f4}figure{display:inline-block;margin:0 16px 16px 0;vertical-align:top}
img{max-width:720px;border:1px solid #ccc;display:block}figcaption{margin-top:4px}</style>
${sections.join("\n")}\n`;
}

(async () => {
  const server = await serve(pagesDir);
  let browser;
  try {
    browser = await launch();
  } catch (error) {
    server.close();
    console.error(`error: no browser to drive — install Google Chrome, or run \`npx playwright install chromium\`\n  ${error.message.split("\n")[0]}`);
    process.exit(2);
  }

  fs.rmSync(outDir, { recursive: true, force: true });
  fs.mkdirSync(outDir, { recursive: true });
  const base = `http://127.0.0.1:${server.address().port}/`;
  const shot = {};
  const broken = [];

  for (const file of pages(pagesDir)) {
    const rel = path.relative(pagesDir, file);
    const page = await browser.newPage({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: SCALE });
    await page.goto(base + rel.split(path.sep).map(encodeURIComponent).join("/"), { waitUntil: "networkidle" });
    const found = await contract(page);
    const breach = breaches(found);
    if (breach.length) {
      breach.forEach((b) => broken.push(`${rel}: ${b}`));
    } else {
      const result = await shoot(page, rel, found.states, Boolean(found.tabs));
      if (result.breach) broken.push(`${rel}: ${result.breach}`);
      else shot[rel] = result.shots;
    }
    await page.close();
  }

  await browser.close();
  server.close();
  fs.writeFileSync(path.join(outDir, "index.html"), index(shot));

  const count = Object.values(shot).reduce((n, s) => n + s.length, 0);
  console.log(`${count} shots of ${Object.keys(shot).length} pages — open ${path.join(outDir, "index.html")}`);
  if (broken.length) {
    console.error(`${broken.length} page contract breach(es) — a brief fixes them, never an edit in the mirror:`);
    broken.forEach((b) => console.error(`  ${b}`));
    process.exit(1);
  }
})();
