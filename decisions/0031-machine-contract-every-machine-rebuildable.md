# ADR 0031 — Machine Contract: every machine is rebuildable from git + Drive; nothing lives only on one

- **Date:** 2026-09-24
- **Status:** Accepted — CEO in session cto-6ebacd0e ("Go", then the four decisions below). Extends ADR 0030 org-wide.
- **Owner:** CTO (Contabo session builds it; the Mac CTO runs and verifies the Mac verbs)
- **Relates:** ADR 0030 (tiers, gauge, Work/), ADR 0027 (claude-home in git), ADR 0028 (hq.yaml decides), IRON §54 (HQ paths), §55 (Work/), §58 (this contract); skills `disk-hygiene`, `gdrive-filing`, `session-close`
- **Config:** Agents-Core `config/machine-contract.yaml` — the per-machine keep-manifest; `config/storage-policy.yaml` keeps the gauge and tiers
- **Plan:** Agents-Core `docs/ops/machine-contract-plan-2026-09-24.md`

## Context (measured 2026-09-24)
- winbox was reset (Reset this PC) at ~04:20 with the Cookie Run backup 4 minutes into its resumed
  stream. **Lost with the disk: 84 GB** — 377 modelplay sessions (49 GB of rounds + hit frames), the
  bot's own play rounds not yet on Drive (22 GB), playset (7 GB), label_review hand labels (2.5 GB),
  the box's models, untracked bot files, ledgers. Only 16.5 GB (8 verified parts) plus the older
  archives were on Drive.
- Everything that lived in git came back in ~2 hours: code, rules, skills, memory, 48 scheduled-task
  definitions, the winget list, SSH public keys, BlueStacks settings (captured by
  `windows/winbox-reinstall/rebuild/blueprint.ps1` before the wipe).
- Nothing had a standing home for: Claude Code's own profile (`~/.claude.json` trust map,
  settings, transcripts 589 MB on Contabo alone, uploads), the Docker volumes `n8n_data` (1.55 GB)
  and `org-pgdata` (sole copies), systemd units, per-machine tool inventories. ADR 0030's tiers and
  gauge existed but were pilot-scoped to one session.
- Growth that made the reset "necessary": bot hit frames 2–4 GB/day, worker worktrees ≈ 880 MB each
  (60 GB piled on winbox), pagefile 18.5 GB, long-session transcripts (one 221 MB).
- CEO's principles, in his words: keep only "ทรัพย์สินที่ไม่มีวันสร้างใหม่หรือโหลดใหม่จากที่ไหนได้" and
  "ความจำที่ต่อไปในอนาคตจะเป็นประโยชน์"; reinstallable is never stored; garbage is not archived;
  "GDrive เราเก็บได้ 20TB"; "Winbox Mac Contabo เราจะเก็บแค่ สมอง tool และ workspace ที่เอาไว้ทำงาน";
  every machine rebuildable, rehearsed — "พร้อมเสมอ ไม่กังวลอีกต่อไป".

## Decision
1. **One registry per machine, path-level only:** `config/machine-contract.yaml`. Every row is a
   path (with `$CLAUDE_CONFIG_DIR` / `$HOME` / `%USERPROFILE%` placeholders) with a class —
   **IRREPLACEABLE** (sole copy; Drive copy verified by checksum before any wipe), **CONFIG**
   (small, restored from a captured value in git), **REBUILD** (one command recreates it; the
   command is stored, never the bytes), **DISPOSABLE** (never stored, never archived) — plus owner,
   a one-line restore, a review date, and `discovered` for paths the scan found but nobody
   classified (`class: UNCLASSIFIED`, never blank). Toolkits are rows about where they live and how
   to reinstall, never about their internals. A Claude Code or toolkit path change is a one-row edit.
2. **Two maps, no overlap:** `hq.yaml` maps HQ project folders (CEO-approved, §54, ADR 0028);
   `machine-contract.yaml` maps OS / Claude-profile / toolkit paths outside that tree and is
   CTO-maintained. CEO-personal paths (Pictures, Desktop, Downloads, iCloud) are in neither — the
   disk-hygiene never-touch list governs them.
3. **Drive is the store.** Everything kept lives under **`BACKUP/MoonieX HQ/<what-is-kept>/`**
   (CEO 2026-09-24), each subfolder defined in `gdrive-filing` so an agent cleaning up or searching
   knows where it is: `Claude-Transcripts/<machine>/<slug>/` (every session, kept forever — CEO
   decision), `Claude-Uploads/`, `Work-Archive/`, `Docker-Volumes/<machine>/<volume>/`,
   `Machine-Blueprints/<machine>/<date>/`. Cookie Run keeps `BACKUP/CookieRun Backup/`. Secrets
   never go to Drive: another machine's `Archive/` at 0600 with a sha256 list.
4. **Capture, close, doctor, restore — one verb each, per machine.** *Capture* (blueprint: installed
   software, scheduled jobs, unit files, settings, public keys, Claude trust map; text only, no
   secrets; committed to `state/<machine>-blueprint-<date>/`). *Close* (a task or session leaves the
   disk at baseline: `workdir.py close --archive`, `stream_backup_to_drive.py --delete-after-verify`,
   the daily transcript archiver; the Work ledger records `added_bytes` vs archived bytes). *Doctor*
   (`tools/machine_doctor.py`, weekly and on every `claude --version` change: registry vs disk;
   anything over 500 MB matching no row is reported `discovered` and must be classified within
   14 days; nothing is deleted without a human go). *Restore* (`scripts/<machine>_restore.sh`, the
   winbox bootstrap + rebuild scripts: ordered, idempotent, with the human-only steps — logins,
   Tailscale, OAuth re-consent — named, never automated).
5. **Bot data cap (CEO):** Cookie Run hit frames stay on the box up to 500 MB/day; the rest streams
   to Drive by the existing 30-minute archive job and is deleted after md5; `rounds.jsonl` and
   manifests are always kept.
6. **The re-OS drill is the proof.** A machine that has never been rebuilt on paper is not proven
   rebuildable. Each drill records four numbers and PASS/FAIL in `state/re-os-drills.jsonl`:
   minutes to remote access, minutes until every registry row is accounted for (present or a logged
   loss), bytes from git vs bytes from Drive, and the list of human-hand steps with durations.
   Cadence: one real drill per quarter rotating Mac → winbox → Contabo (Contabo on a disposable VPS,
   never the live box). Drill #1 = winbox 2026-09-24 (org leg PASS in ~2 h; Cookie Run rows a
   known FAIL); drill #2 = the Mac's own wipe the same week.
7. **Ownership:** the Contabo CTO writes the registry, scripts and rules; the Mac CTO runs and
   verifies the Mac verbs and reports the numbers; the CEO's own steps (game installs, logins,
   consents) carry no deadline and no PASS/FAIL.

## What is unnecessary now
- Backing up REBUILD bytes (node_modules, .venv, Docker image layers): the registry stores the
  command; `docker builder prune`, `pip install -r`, `npm ci` are the backup.
- One-off "pre-reinstall" tars per incident (the two 2026-09-24 gate rows): the standing capture /
  restore verbs replace them; the gate table grows only for genuinely new destinations.
- Hand hard-linking transcripts when a project path moves (done at the HQ move): a slug-map row
  in the registry instead.
- Deleting old transcripts: the CEO keeps them all on Drive; the cost is a few GB a month.
- Treating "queue clean" or "gauge green" as proof the machine is rebuildable: only a drill is.

## Consequences
- A reinstall or a new machine is a scored, rehearsed operation instead of tribal memory; the day
  of the drill is the day the next gap is found, on purpose.
- `n8n_data` and `org-pgdata` get their first backup routine; the Claude profile gets a home.
- Weekly classification of `discovered` paths is a standing chore with an owner; an unclassified
  pile is a finding, never a deletion.
- Free space per machine returns to its baseline after every closed task; growth that does not
  belongs to a row someone can name.
