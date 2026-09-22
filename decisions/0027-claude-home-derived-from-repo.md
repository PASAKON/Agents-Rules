# ADR 0027 — `~/.claude` is derived from the repo, never the place things live

- **Date:** 2026-09-22
- **Status:** Accepted — CEO "Ok ✅ ลุยได้" 2026-09-22 (session cto-0e8d80b8). **Migration itself is CEO-run** (the auto-mode classifier refuses to move private config into a pushed repo on the CTO's own authority — correct behaviour)
- **Owner:** CTO
- **Relates:** ADR 0022 (skills: git is the ledger), ADR 0012 (repo naming), the MoonieX HQ design (same session, pending CEO picks) — `claude-home/` is the first HQ-shaped folder: a map plus an installer, disk follows the map

## Context — what a `rm -rf ~/.claude` would have cost (measured 2026-09-22)

No copy anywhere: `settings.json` (11 hooks — GateGuard ×2, tab_guard, skill-log,
caveman ×2, allowlist ×2, cost-guardian ×2 — statusline, 4 plugins, 69
permission rules, model), the global `CLAUDE.md`, `hooks/` (10 files),
`commands/spawn-*.md` (4), `mcp/mooniex-coord`, `tools/prune_transcripts.py`
(a launchd job points at it), and **12 real skill dirs** — among them the
org-owned `cookierun-labeling` (CTO), `mooniex-video-editor` (CMO) and
`reel-editor-th` (the video_editor tool: 140 KB of code, 210 MB of b-roll,
1.2 GB venv) — plus 14 per-project memory dirs. The 11 `settings.json.bak`
copies all sat in the same folder.

Already safe: 33 skill symlinks into repos, the Agents memory symlink into
Agents-Memory, credentials in the macOS Keychain, and every C-level MCP config
(`config/cto.mcp.json --strict-mcp-config`) — which is why Contabo's empty
`~/.claude` works.

## Decision

1. **`Agents/claude-home/` is the source.** `CLAUDE.md`, `settings.json`,
   `hooks/`, `commands/`, `mcp/`, `tools/`, `launchd/`, `assets/`, plus two
   maps: `skills.txt` (name → target for every `~/.claude/skills` link) and
   `plugins.txt` (marketplaces + plugins).
2. **`scripts/install-claude-home.sh` links it into `~/.claude`.** Idempotent.
   A real file where a link belongs is DRIFT; a differing `settings.json` is
   CAPTURED into the repo before relinking, so `/config` edits are never lost.
   `--check` is the doctor: reports, changes nothing, exit 1 on drift.
3. **No row, no link.** A real dir in `~/.claude/skills` with no `skills.txt`
   row is UNMAPPED and reported — the map decides, not the disk (gdrive-filing
   rule 6, HQ rule 1).
4. **Org skills live in `.claude/skills/`** under skill-lint; the 12 real
   user-level skills move there (owners stamped on the three org-owned ones).
5. **Not tracked, on purpose:** transcripts (9.5 GB, history not config),
   plugins/cache (reinstallable), `daemon/` (Claude Code's own), `reel-editor-th`
   venv (rebuilt from `requirements.txt`) and b-roll (media → Assets/ + Drive).
6. **Legacy memory** of 14 retired projects copied once into
   `Agents-Memory/legacy/<slug>/` by the same migration script.

Recovery recipe: `claude login` → `bash scripts/install-claude-home.sh`.
One-time migration: `python3 scripts/claude_home_migrate.py` (reversible from its manifest).

## Consequences
- `settings.json` changes show in `git status` of the Agents repo — commit them.
- Mac only for now; Contabo/winbox have no org content in `~/.claude`.
- The 210 MB b-roll still has one copy (local, gitignored) until it lands on Drive — open item.
