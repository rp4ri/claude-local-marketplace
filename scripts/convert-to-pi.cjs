#!/usr/bin/env node
/**
 * convert-to-pi.cjs — Convert the Claude Code plugins in plugins/<studio>/ into
 * pi packages under pi-packages/<studio>/.
 *
 * Mapping (validated against earendil-works/pi docs):
 *   commands/*.md          -> prompts/*.md      (drop `allowed-tools`; $ARGUMENTS/$1/$@ work verbatim; invoked /<name>)
 *   skills/<n>/SKILL.md     -> skills/<n>/SKILL.md  (verbatim; name+description+allowed-tools all valid; invoked /skill:<n>)
 *   agents/*.md            -> skills/<n>/SKILL.md  (normalized frontmatter: name + short description; body preserved)
 *   scripts|references|schemas|data -> copied verbatim
 *   hooks/hooks.json       -> extensions/index.ts (best-effort TS; SessionStart + PreToolUse guardians)
 *   .claude-plugin/plugin.json -> package.json with `pi` manifest
 *
 * Zero dependencies — Node stdlib only.
 */
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const SRC = path.join(ROOT, "plugins");
// Output is a SEPARATE sibling repo, distributed on its own (`pi install git:...`).
const OUT = path.resolve(ROOT, "..", "pi-studios");
const STUDIOS = ["design-studio", "dev-studio", "marketing-studio", "sales-studio"];

// ---------- helpers ----------
function read(p) { return fs.readFileSync(p, "utf8"); }
function write(p, c) { fs.mkdirSync(path.dirname(p), { recursive: true }); fs.writeFileSync(p, c); }
function exists(p) { return fs.existsSync(p); }
function lsmd(dir) { return exists(dir) ? fs.readdirSync(dir).filter(f => f.endsWith(".md")) : []; }
function copyDir(src, dst) {
  if (!exists(src)) return 0;
  let n = 0;
  for (const e of fs.readdirSync(src, { withFileTypes: true })) {
    const s = path.join(src, e.name), d = path.join(dst, e.name);
    if (e.isDirectory()) n += copyDir(s, d);
    else { fs.mkdirSync(path.dirname(d), { recursive: true }); fs.copyFileSync(s, d); n++; }
  }
  return n;
}

/** Split a markdown file into {fm: string[], body: string}. fm is frontmatter lines (no fences). */
function splitFrontmatter(text) {
  const lines = text.split("\n");
  if (lines[0] !== "---") return { fm: [], body: text };
  let end = -1;
  for (let i = 1; i < lines.length; i++) { if (lines[i] === "---") { end = i; break; } }
  if (end === -1) return { fm: [], body: text };
  return { fm: lines.slice(1, end), body: lines.slice(end + 1).join("\n") };
}

/** Remove a top-level YAML key (handles single-line and indented continuation). */
function stripKey(fmLines, key) {
  const out = [];
  let skipping = false;
  for (const line of fmLines) {
    const isTop = /^[A-Za-z0-9_-]+\s*:/.test(line);
    if (isTop) skipping = line.startsWith(key + ":");
    if (skipping) continue;
    out.push(line);
  }
  return out;
}

/** Extract a scalar value for a top-level key from frontmatter lines. */
function getKey(fmLines, key) {
  for (let i = 0; i < fmLines.length; i++) {
    const m = fmLines[i].match(new RegExp("^" + key + "\\s*:\\s*(.*)$"));
    if (m) {
      let v = m[1].trim();
      // multiline block scalar (| or >) — gather indented following lines
      if (v === "|" || v === ">" || v === ">-" || v === "|-" || v === "") {
        const parts = [];
        for (let j = i + 1; j < fmLines.length; j++) {
          if (/^\s+/.test(fmLines[j]) || fmLines[j].trim() === "") parts.push(fmLines[j].trim());
          else break;
        }
        v = parts.join(" ").trim();
      }
      return v.replace(/^["']|["']$/g, "");
    }
  }
  return "";
}

/** Build a short, single-line description (<=900 chars) cut at first <example> / sentence boundary. */
function shortDesc(desc) {
  let d = desc.split("<example>")[0].replace(/\s+/g, " ").trim();
  if (d.length > 900) d = d.slice(0, 897).replace(/\s+\S*$/, "") + "...";
  return d.replace(/"/g, "'");
}

// ---------- per-studio conversion ----------
function convertStudio(studio) {
  const src = path.join(SRC, studio);
  const dst = path.join(OUT, studio);
  const stats = { prompts: 0, skills: 0, agentsAsSkills: 0, copied: {} };

  // 1) commands -> prompts (strip allowed-tools)
  for (const f of lsmd(path.join(src, "commands"))) {
    const { fm, body } = splitFrontmatter(read(path.join(src, "commands", f)));
    const newFm = stripKey(fm, "allowed-tools");
    const out = fm.length ? `---\n${newFm.join("\n")}\n---\n${body}` : body;
    write(path.join(dst, "prompts", f), out);
    stats.prompts++;
  }

  // 2) skills -> skills (verbatim, recursive copy of each skill dir)
  const skillsDir = path.join(src, "skills");
  if (exists(skillsDir)) {
    for (const e of fs.readdirSync(skillsDir, { withFileTypes: true })) {
      if (e.isDirectory()) { copyDir(path.join(skillsDir, e.name), path.join(dst, "skills", e.name)); stats.skills++; }
      else if (e.name.endsWith(".md")) { fs.mkdirSync(path.join(dst, "skills"), { recursive: true }); fs.copyFileSync(path.join(skillsDir, e.name), path.join(dst, "skills", e.name)); stats.skills++; }
    }
  }

  // 3) agents -> skills/<name>/SKILL.md (normalized frontmatter)
  for (const f of lsmd(path.join(src, "agents"))) {
    const { fm, body } = splitFrontmatter(read(path.join(src, "agents", f)));
    const name = (getKey(fm, "name") || f.replace(/\.md$/, "")).toLowerCase().replace(/[^a-z0-9-]/g, "-");
    const desc = shortDesc(getKey(fm, "description") || name);
    const skillBody = `---\nname: ${name}\ndescription: "${desc}"\n---\n${body.trimStart()}`;
    write(path.join(dst, "skills", name, "SKILL.md"), skillBody);
    stats.agentsAsSkills++;
  }

  // 4) copy auxiliary dirs verbatim
  for (const dir of ["scripts", "references", "schemas", "data", "modes", "examples"]) {
    const n = copyDir(path.join(src, dir), path.join(dst, dir));
    if (n) stats.copied[dir] = n;
  }
  // copy a couple of top-level docs if present
  for (const f of ["LICENSE", "MCP-SETUP.md"]) {
    if (exists(path.join(src, f))) fs.copyFileSync(path.join(src, f), path.join(dst, f));
  }

  return stats;
}

// ---------- root manifest generation ----------
// One aggregating package.json at the repo root, so `pi install git:<repo>` loads
// all four studios at once. Explicit per-studio paths (no glob ambiguity).
function rootManifest() {
  const skills = [], prompts = [], extensions = [];
  for (const studio of STUDIOS) {
    if (exists(path.join(OUT, studio, "skills"))) skills.push(`./${studio}/skills`);
    if (exists(path.join(OUT, studio, "prompts"))) prompts.push(`./${studio}/prompts`);
    if (exists(path.join(OUT, studio, "extensions"))) extensions.push(`./${studio}/extensions`);
  }
  const pi = { skills, prompts };
  if (extensions.length) pi.extensions = extensions;
  return JSON.stringify({
    name: "pi-studios",
    version: "1.0.0",
    description: "Design, dev, marketing, and sales studios for the pi coding agent — ported from the claude-local-marketplace plugins.",
    keywords: ["pi-package", "design", "dev", "marketing", "sales", "skills", "prompts"],
    pi
  }, null, 2) + "\n";
}

main();
function main() {
  fs.mkdirSync(OUT, { recursive: true });
  const summary = [];
  for (const studio of STUDIOS) {
    summary.push({ studio, ...convertStudio(studio) });
  }
  // Single root package.json aggregating all studios. Does NOT touch hand-written
  // extensions/index.ts or README.md.
  write(path.join(OUT, "package.json"), rootManifest());
  console.log(JSON.stringify(summary, null, 2));
}
