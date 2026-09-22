# ADR 0028 — MoonieX HQ: one root, one map, the disk follows

- **Date:** 2026-09-22
- **Status:** Accepted — CEO approvals in session cto-0e8d80b8: the 6 design picks ("ลุยได้เลย"), the 4 follow-ups (Agents/ family at root · retire Wiki-Vault/Obsidian · research cache · project-layout playbook), and every row of `hq.yaml` v1 (the numbered tree, names 1–17)
- **Owner:** CTO
- **Relates:** ADR 0007 (one clone per repo), ADR 0012 (repo naming), ADR 0013 (wiki namespaces), ADR 0027 (claude-home — the first HQ-shaped folder), IRON-RULES §54
- **Map + tools:** github.com/PASAKON/MoonieX-HQ (`hq.yaml`, `MAP.md`, `scripts/hq.py`)

## Context (measured 2026-09-22)
Three roots (`~/Projects` 25 entries, `~/LungNote Projects`, `~/WarpClip Projects`), 11 naming styles,
folder ≠ repo for 6 repos, WarpClip cloned twice, 4.4 GB of media inside the Agents repo (972 files
tracked, `.git` 3.8 GB), 3 GB of stale worktrees, four things that were not repos, one repo with 29
edits on someone else's remote. Nothing told an agent where anything was or who owned it.

## Decision
1. **Root `~/MoonieXHQ`**, thin repo `PASAKON/MoonieX-HQ` tracking only `CLAUDE.md`, `MAP.md`, `hq.yaml`, `scripts/`.
   Every other folder is its own repo or data, gitignored here.
2. **`hq.yaml` is the map**; `MAP.md` is rendered from it; `hq.py doctor` is the judge (missing paths, wrong
   remotes, duplicates, unmapped repos under the legacy roots, unmapped folders under HQ).
3. **Layout:** `Agents/{Rules,Wikis,Memory,Skills,Core}` (the org brain, read first) ·
   `Projects/<Brand>/<Suffix>` ⇔ `PASAKON/<Brand>-<Suffix>` · `External/` · `Assets/` · `Archive/` · `UNKNOWN/`.
4. **Repo renames executed 2026-09-22:** Agents-Wikis→Agents-Rules, MoonieX-Wikis→Agents-Wikis,
   MoonieX-ClaudeSkills→Agents-Skills, MoonieX-Agents→Agents-Core, MoonieX-Webapp→MoonieX-WebApp,
   MoonieX-Design→MoonieX-WebDesign, MoonieX-CookieRun→MoonieX-CookierunBot. New: MoonieX-AlphaTrader (fork home),
   MoonieX-ComfyRunpod, MoonieX-NoHumanCompany (retired, brand kept). Redirects hold except the reused name
   `Agents-Wikis`; every Mac clone repointed the same day.
5. **Two standing rules** (IRON §54): CEO approves every HQ path; projects are independent and connect only through APIs.
6. **Research cache** in `Agents/Wikis/research/` — one question one file, dated, sourced, `refresh_after` by class
   (prices/quotas 30 d · API docs 90 d · law/history 1 y · our own measurements never expire but carry a date);
   searched before any web search; a gate hook follows at step ②.
7. **Inside a project:** `playbooks/project-layout.md`; existing projects adopt it when next touched.
8. **Migration in four steps**, nothing moves outside its step: ① map only (done) → ② LungNote + WarpClip →
   ③ MoonieX products → ④ Agents last with a `~/Projects` compatibility symlink.
9. **Obsidian retired** (reference/obsidian-retired-2026-09-22): agents never used it; humans no longer do.

## Consequences
- 222 hardcoded `/Users/gob/Projects` lines in Agents-Core, 7 in `~/.claude/settings.json`, 5 launchd plists and
  `config/{projects,wikis}.yaml` retire step by step; the symlink keeps them alive meanwhile.
- Media in Agents' git history (3.45 GiB pack) is a separate decision — stop the bleeding first (hook + Assets/).
- Contabo and winbox layouts are unchanged; the map records their paths per row.
