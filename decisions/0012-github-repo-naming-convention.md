# ADR-0012: GitHub Repo Naming Convention — `Brand-PascalCase`

| | |
|---|---|
| **Status** | ✅ Ratified + fully applied (CEO 2026-08-03) · verified no breakage same day |
| **Applies to** | Every `mooniex-*`/`MoonieX-*` repo, plus WarpClip, LungNote, Chatudo, LinkReed |
| **Owner** | PASAKON GitHub org |

---

## Rule

```
<Brand>-<Suffix>
```

- **One hyphen only** — between brand and suffix. Never inside the suffix.
- **Brand** keeps its own internal capitalization (MoonieX, WarpClip, LungNote, Chatudo, LinkReed).
- **Suffix** is PascalCase. Multi-word suffixes lose their internal hyphens and get
  each word capitalized instead: `claude skills` → `ClaudeSkills`, `lunar agent` →
  `LunarAgent`, `line automation` → `LineAutomation`. Short single-word suffixes
  (webapp, wikis, design, agents) also get capitalized.

### Full mapping (before → after), all executed 2026-08-03

| Old | New |
|---|---|
| `mooniex-webapp` | `MoonieX-Webapp` |
| `mooniex-llms-wiki` | `MoonieX-Wikis` |
| `mooniex-claudesign` | `MoonieX-ClaudeSign` |
| `mooniex-website-templete` | **`MoonieX-Design`** ← the actual live site-template repo, not claudesign |
| `mooniex-claude-skills` | `MoonieX-ClaudeSkills` |
| `mooniex-lunar-agent` | `MoonieX-LunarAgent` |
| `mooniex-agents` | `MoonieX-Agents` (this org-runtime repo itself) |
| `mooniex-claudeflow` | `MoonieX-ClaudeFlow` |
| `mooniex-line-automation` | `MoonieX-LineAutomation` |
| `mooniex-option` | `MoonieX-Option` |
| `mooniex-scriptable` | `MoonieX-Scriptable` |
| `mooniex-wa-system` | `MoonieX-WaSystem` |
| `mooniex-website` | `MoonieX-Website` |
| `mooniex-website-main` | `MoonieX-WebsiteMain` |
| `LungNote-webapp/design/wikis` | `LungNote-Webapp/Design/Wikis` |
| `WarpClip-webapp/design/wikis` | `WarpClip-Webapp/Design/Wikis` |
| *(new)* | `LinkReed-Webapp/Design/Wikis` |
| *(new, scaffold only)* | `Chatudo-Webapp/Design/Wikis` |

**Naming gotcha worth remembering:** `MoonieX-Design` is the live website-template
repo (was `mooniex-website-templete`), **not** the claudesign fork. The claudesign
fork/tool repo is `MoonieX-ClaudeSign`. Don't confuse the two — "Design" now means
"the actual site," ClaudeSign means "the design tool we build it with."

Left untouched (not `mooniex-*`, not one of the 5 brands): `arna-ai`,
`desktop-tutorial`, `gacp-certify-flow`, `git-moonez-bot`, `git-mymoonfx-project`,
`mxn`.

---

## Verification — 2026-08-03, same day

Checked whether the rename swept broke anything already running. Full pass:

**Fixed (real stale references found):**
- 9 local Mac clones still pointed at old repo names (`LLMs`, `WarpClip-design`,
  `WarpClip-webapp`, `mooniex-claude-skills`, `mooniex-claudeflow`,
  `mooniex-lunar-agent`, `mooniex-scriptable`, `mooniex-webapp`,
  `mooniex-website-templete`) — `git remote set-url` on all, confirmed reachable
  via `git ls-remote`.
- 2 local clones (`mooniex-option`, `mooniex-wa-system`) were **already stale
  from before today** — still pointed at the old GitHub username
  (`golfmaichai1`) from before the PASAKON account rename. Fixed opportunistically.
- VPS-side (`/root/projects/mooniex-claudeflow`, via `ssh mooniex-vps`) remote
  was stale too — fixed, confirmed reachable over SSH protocol.

**Checked, nothing broken:**
- `scripts/deploy.sh` (ClaudeFlow prod deploy) — doesn't hardcode any GitHub URL;
  relies on the already-fixed `git pull origin main`, and its docker/pm2 names
  are local identifiers independent of the GitHub repo name.
- GitHub Actions workflows across all 7 repos that have CI — no hardcoded old
  repo-name references (one grep hit was an unrelated deploy-target file path
  that happens to share a substring, not a GitHub reference).
- Live prod sites post-rename: `www.mooniex.com` → 200, `warpclip.com` → 200,
  `lungnote.com` → 307 (normal redirect). `chatudo.com` → no response (expected,
  nothing built there yet).

**Noted, unrelated to today:** `/opt/mooniex-agents` and `/opt/mooniex-console`
on the VPS have no `.git` at all — deployed via archive-sync, not git clone.
Pre-existing, not caused by this rename.

---

## Chatudo status note (2026-08-03)

Scaffold done: `Chatudo-Webapp`, `Chatudo-Design`, `Chatudo-Wikis` created with
seed READMEs, matching `LinkReed`'s pattern. **Actual code is still deferred** —
`Chatudo-Webapp` will be built fresh later, using `MoonieX-LunarAgent` as the
prototype/reference, not a migration of it. Brand identity assets (logo,
wordmark, Fraunces/Pridi type system — finalized 2026-07-30) still live as task
output inside `MoonieX-ClaudeSign`, not yet moved into `Chatudo-Design`. The
extraction plan and gate history still live at
[`projects/mooniex-lunar-agent-extraction.md`](https://github.com/PASAKON/MoonieX-Wikis/blob/main/projects/mooniex-lunar-agent-extraction.md) (`mooniex:projects/mooniex-lunar-agent-extraction.md`)
until that page gets migrated too — its internal repo references are stale
(`mooniex-lunar-agent` → `MoonieX-LunarAgent`, `mooniex-claudeflow` →
`MoonieX-ClaudeFlow`).

## LinkReed status note (2026-08-03)

`LinkReed-Webapp`, `LinkReed-Design`, `LinkReed-Wikis` created with seed READMEs.
Same as Chatudo: scaffold only, actual code extraction from `MoonieX-Webapp`'s
`/links` + `/links/pasakon` has not started.

---

## Addendum 2026-09-22 — HQ renames (ADR 0028), same rule, new brand family `Agents-*`

| Old | New | why |
|---|---|---|
| `Agents-Wikis` | **`Agents-Rules`** | it holds the rules (IRON-RULES, roles, playbooks, ADRs), not product knowledge |
| `MoonieX-Wikis` (local `LLMs/`) | **`Agents-Wikis`** | the knowledge every agent reads — the old name was reused, so its redirect is gone; the Mac clone was repointed the same day |
| `MoonieX-ClaudeSkills` | **`Agents-Skills`** | |
| `MoonieX-Agents` | **`Agents-Core`** | the runtime |
| `MoonieX-Webapp` | **`MoonieX-WebApp`** | case |
| `MoonieX-Design` | **`MoonieX-WebDesign`** | says what it is (the site templates), ends the ClaudeSign confusion |
| `MoonieX-CookieRun` | **`MoonieX-CookierunBot`** | |
| *(GiordanoSouza remote)* | **`MoonieX-AlphaTrader`** | new — fork home for 29 local edits |
| *(no remote)* | **`MoonieX-ComfyRunpod`** | new |
| *(not a repo)* | **`MoonieX-NoHumanCompany`** | new, retired project, brand assets kept |

HQ folder ⇔ repo: `Agents/<Suffix>` ⇔ `Agents-<Suffix>`, `Projects/<Brand>/<Suffix>` ⇔ `<Brand>-<Suffix>`.
