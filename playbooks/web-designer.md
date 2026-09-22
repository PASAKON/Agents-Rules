# Playbook — Web Designer (mooniex-claudesign)

**Role key:** `web_designer`
**Display:** Web Designer
**Project scope:** `mooniex-claudesign` (and other design-content projects as added)
**Created:** 2026-05-18
**Updated:** 2026-06-15 — §4 spawn model rewritten (autonomous claude TUI on iterm, sha d92cb09)
**Owner:** CTO

---

## 1. Mission

Author and maintain **design content** (design systems, design templates,
skills, brand craft rules) inside the local-first design product fork at
`/Users/gob/MoonieXHQ/Projects/MoonieX/ClaudeSign/`.

Web Designer does **not** touch upstream application code. The fork
absorbs upstream releases regularly; agent work must merge cleanly.

## 2. Allowed paths (content zone)

| Path prefix | Purpose |
| --- | --- |
| `design-systems/**` | Brand `DESIGN.md` files, tokens, themes |
| `design-templates/**` | Decks, prototypes, image/video/audio templates |
| `skills/**` | Functional design skills (utilities, briefs, packagers) |
| `craft/**` | Universal brand-agnostic craft rules |
| `.agents/**` | Agent scratch + per-project notes |
| `README.mooniex.md` | Fork-specific README (does not exist upstream) |

Source of truth: `Agents/config/projects.yaml → mooniex-claudesign.content_zone`.
A pre-commit hook (`.git/hooks/pre-commit` inside the claudesign repo)
**blocks** any commit that stages a path outside this list.

## 3. Forbidden paths

Everything else, especially:

- `apps/**` (web, daemon, desktop, packaged)
- `packages/**`
- `tools/**`, `e2e/**`
- Root configs: `package.json`, `pnpm-workspace.yaml`, `tsconfig*.json`,
  `.github/**`, `CHANGELOG.md`, `CONTRIBUTING*.md`, `README*.md`,
  `MAINTAINERS*.md`, `QUICKSTART*.md`, `AGENTS.md`, `LICENSE`

These belong to the upstream project (`nexu-io/open-design`). The fork
follows upstream releases via `git merge upstream/main`; touching them
in agent commits guarantees conflicts.

If a real bug must be fixed in core code, CTO escalates manually:
file an upstream PR, then sync once it merges.

## 4. Spawn model — THREE modes (UPDATED 2026-06-15, sha d92cb09)

`mooniex-claudesign` uses the default **iterm** backend (no `spawn_backend`
key in `projects.yaml` — see line ~51 "default backend = iterm"). There are
three distinct ways a Web Designer runs. **Pick by who drives.**

### 4a. CTO-delegated → autonomous claude TUI ← the normal path now

`delegate_task` on a `web_designer` task spawns an **autonomous `claude`
agent in an iTerm2 tab, exactly like a `developer`** — it reads TASK.md,
builds the design artifact in its worktree, commits, and `submit_report`s.
**No human drives anything.**

- `tools/delegate.py` opens an iTerm tab running `runners.dev_init web_designer <task>`.
- `runners/dev_init.py` execs:
  `claude -n "Web Designer (task-…)" --model claude-opus-4-8[1m] --effort max
  --append-system-prompt <roles/web_designer.md> --allowed-tools … Skill <TASK.md>`.
- The project UUID in the task description is resolved to the `.od` design
  source and appended to the prompt (`lib/db.designer_kickoff_suffix`), so
  the agent knows which brand/theme to match.
- The **`Skill` tool is enabled** for this role → it can lean on the org's
  UI-craft skills (frontend-design / mooniex-tool-builder).
- Drive it mid-task with `tools/send_to_dev.py` (types into the tab) — same
  as any DEV. (`tools/cto_chat_designer.py` is a now-redundant workaround
  from the viewer era; `send_to_dev` is enough.)
- **REQUIRED spawn input:** the claudesign **project UUID in the task
  description** (see §9). Without it the agent can't resolve the `.od` theme.

> **History — the "spawn dies" bug:** before sha d92cb09 (2026-06-15)
> `dev_init` short-circuited EVERY web_designer to a passive `tail -F
> /tmp/mooniex-mirror-<task>.log` viewer (the legacy 4c bridge). The agent
> never came up live — 0-byte mirror, no `claude` process, tab printed
> "Type prompts in the claudesign Web UI." Both CFO and CTO hit this.
> Now the viewer is gated to `spawn_backend == "tmux"` only. **Verify any
> web_designer spawn by checking the process IS a `claude` TUI (not a
> `tail`)**, not just `status=in_progress`.

### 4b. CEO-driven Web UI → interactive design surface

For hands-on design by the CEO (not autonomous), run **in the Agents repo**:

```bash
bash scripts/spawn-web-designer.sh        # boots daemon :7456 + web :3000, opens browser
bash scripts/spawn-web-designer.sh --status   # / --stop / --restart
```

It starts the open-design daemon + web UI; the CEO prompts the design
interactively at `http://localhost:3000`. This path is **separate** from
CTO delegation and is unchanged by the d92cb09 fix. Use it when the CEO
says "spawn web designer" and wants to work on the design themselves.

### 4c. Legacy tmux + ttyd bridge (only if `spawn_backend: tmux`)

If `mooniex-claudesign` is ever switched back to `spawn_backend: tmux`,
`dev_init` boots a **passive viewer** that tails the claudesign daemon's
bridge mirror; the Web UI chat then drives a real `claude` per message via
`tools/claudesign_tmux_bin.py`. The iTerm tab runs `tmux attach -t
wd-<id>`; optional `ttyd` wraps it on `127.0.0.1:8700+` when `web_ui:
auto/true`. **Not the current setup** — documented for completeness.

## 5. Worktree workflow

Same as other workers:

- CTO calls `tools/worktree.create_worktree(...)` → `agent/<role>-<task>` branch
  off `mooniex-main`.
- Agent commits inside the worktree only.
- CTO reviews; merge target = `mooniex-main` (never `main` — that
  tracks upstream).
- `auto_push: false` on this project — manual push only.

## 6. Upstream sync (CTO responsibility)

```bash
cd /Users/gob/Projects/mooniex-claudesign
git fetch upstream
git checkout mooniex-main
git merge upstream/main          # conflicts unlikely if zone respected
git push mooniex mooniex-main    # if mooniex remote configured
```

Cadence: weekly, or when watchdog detects `upstream/main` ahead.

## 7. Definition of done

- Files committed are all inside the content zone (pre-commit gate
  enforces).
- New skill / template includes a `SKILL.md` or `TEMPLATE.md` describing
  inputs, outputs, and craft rules it implements.
- Linter clean: `pnpm i18n:check` if i18n strings touched.
- `submit_report` MCP call sent with files-changed list and any
  blockers.

## 8. Related docs

- Project page: `projects/mooniex-claudesign.md`
- ADR: `decisions/ADR-001-claudesign-fork-strategy.md`
- ADR: `decisions/2026-06-15-web-designer-autonomous-spawn.md` (the d92cb09 fix)
- Spec inside the repo: `docs/spec.md`, `docs/architecture.md`,
  `specs/current/skills-and-design-templates.md`

## 9. Spawn inputs — Project ID + paths (REQUIRED, CEO directive 2026-06-04)

Every Designer spawn MUST carry these four fields in the kickoff brief.
With them, handing just the **Project ID** is enough — the agent resolves
name / skill / design from the ID and writes to the named target. Without
them the agent guesses.

1. **Project ID** — the claudesign (open-design) project UUID.
   Example: `7b4becb9-65dd-4b89-b15f-b7b0ec35c607`.

2. **Design source (read-only reference)** — resolved from the ID:
   - dir: `/Users/gob/MoonieXHQ/Projects/MoonieX/ClaudeSign/.od/projects/{ID}/`
   - name + skill:
     `sqlite3 /Users/gob/MoonieXHQ/Projects/MoonieX/ClaudeSign/.od/app.sqlite "select name,skill_id from projects where id='{ID}'"`
     (verified: `7b4becb9…` → name `MoonieX`, skill `blog-post`)
   - design artifact(s): `.od/projects/{ID}/.od-skills/{skill}/example.html`
     (+ `SKILL.md`)
   - **`.od/` is gitignored — local-only, NOT in any worktree clone.** The
     agent reads it by **absolute path** on this machine. **Read-only** —
     never write into `.od/`.

3. **Target repo + path** — where the agent WRITES the deliverable: the
   GitHub repo (e.g. `PASAKON/mooniex-webapp` or `PASAKON/mooniex-claudesign`)
   and the exact path(s), stating which path is for what. Becomes the org
   `touches`.

4. **Deliverable** — what to build (the requirement). Visual design is the
   agent's call.

**Kickoff brief template line:**
> Project: {name} (`{ID}`) · Design ref (read-only):
> `…/.od/projects/{ID}/.od-skills/{skill}/example.html` ·
> Target: repo `{repo}` path `{path}` · Build: {deliverable}

The in-app Designer (`mooniex-tmux`, per `.od/app-config.json`) already has
`.od` access, so the **ID alone** is enough there. An org-spawned
`web_designer` needs the absolute design-source path in the brief (its
worktree omits `.od/`) — and the autonomous spawn (§4a) auto-resolves it
from the UUID via `designer_kickoff_suffix`.
