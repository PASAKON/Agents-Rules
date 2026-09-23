# ADR 0030 — Agent storage: every byte an agent writes has a tier, an owner, and an end

- **Date:** 2026-09-23
- **Status:** Accepted in principle — CEO in session cto-0e8d80b8: "งานคุณจัดการ สถาปัตยกรรม Agent ก็พอไม่ให้บวม รวมถึงการทำงานเดียวกับ Video ด้วย — Agent ชอบสร้างไฟล์ โหลดมา ทำเสร็จแล้วไม่เคลียร์ สะสมเป็นภูเขา". The work-dir **location** (§3) is a new HQ path and waits for the CEO's approval (IRON §54). Pictures (51 GB) and iCloud (30 GB) are the CEO's, handled by the CEO.
- **Owner:** CTO
- **Relates:** skill `disk-hygiene` (the one law, Green list), `gdrive-filing` (every Drive destination), `hq-filing` (Assets), IRON §33 (stay in lane), IRON §54 (HQ paths need approval), ADR 0028 (the map decides)
- **Config:** Agents-Core `config/storage-policy.yaml` — the only place the numbers and paths live

## Context (measured 2026-09-23)
- 04:05: the Mac reached **0 bytes free**; every tool, hook and worker died at once (ENOSPC).
- One Agents-Core task worktree = **867 MB**, of which **738 MB** is media committed under `docs/`; tracked media at HEAD = 722 MB. Ten parallel workers = 8.7 GB before anyone writes a byte.
- Runners are briefed to write to `~/Desktop/banchi-*` (the CEO's iCloud-backed Desktop); a screen recording landed in `~/Downloads`; review copies of `docs/` sat in `/private/tmp/runner-review`. Nothing owns these after the task ends.
- The disk-hygiene skill clears space **after** the fact. Nothing stops the pile from forming.

## Decision
1. **Four tiers, one question each.** HOT = in use now, stays local. REBUILD = a named command recreates it → delete without asking. COLD = not regenerable, not in use → tar + manifest to Drive `BACKUP/` (gdrive-filing), md5 verified, then deleted. NEVER = the CEO's own (Pictures, iCloud, Desktop, Downloads, Movies, memory) → no agent deletes, moves or archives it.
2. **A free-space gauge, not a feeling** (`gauge` in the config): ≥ 20 GB green · < 20 yellow = daily notice + COLD candidate list · < 10 orange = REBUILD deleted automatically, no new download/video task spawns · < 5 red = delegate refuses every spawn. Zero is what happened at 04:05.
3. **Every task gets one work dir named by its task id** (`in/` downloads, `tmp/` intermediates, `out/` deliverables) and **cannot close while it holds unfiled bytes**: tmp deleted, `in/` deleted only if every file is re-downloadable from `in/SOURCES.txt` else COLD, `out/` moved to the project's Assets folder (hq-filing) else COLD. Proposed root `~/MoonieXHQ/Work/` — not created until the CEO approves.
4. **No new media into git.** A guard refuses an added media file > 1 MiB unless the repo opts the path in. The 722 MB already committed stays — no history rewrite on a shared repo.
5. **Worker worktrees are sparse** — only EXISTING tracked media files > 256 KiB are excluded, each by exact path (877 → 78 MB). Never a directory: a directory exclude makes `git add -A` exit 1 for every new report under it (304 browser_operator tasks/30 d). Roles that need media (video_editor) get a full checkout.
6. **Runners never default their output under a NEVER path** (`~/Desktop`, `~/Downloads`, `~/Movies`).
7. **The scan is the judge.** `storage scan` reports GB per tier and the UNCLASSIFIED remainder; a path nobody classified is the next thing to argue about, not something to delete.

8. **Pilot scope first** (CEO 2026-09-23: "Scope เฉพาะงานตัวเองก่อน เผื่อมีงานอื่นที่คนอื่นกำลังทำ"). Every gauge action and the sparse worktree apply only to tasks whose `owner_cto` is in `pilot_owner_cto` (today: the owning session `0e8d80b8`). At that hour 18 other CTO sessions owned 58 in-flight tasks — an org-wide floor would have refused them all. A missing key applies to nobody; widening to `"all"` is the CEO's call. A future REBUILD auto-delete touches only the pilot's own task worktrees, never another session's `node_modules`/`.venv`.

## Build (2026-09-23)
- Jules (repo Agents-Core, allowlisted; test of Jules per CEO): J1 policy loader + validator, J2 `storage scan`, J3 media guard (standalone; wired into git hooks after HQ step 4b).
- Claude worker C1: sparse worktrees + the red-band spawn refusal in delegate.
- Later, after the CEO approves the work-dir root: C2 work dir + close gate; C3 runner `--dest` defaults; C4 COLD archive command.

## Cross-machine free space
The disk hub (built by CTO a29c7576, 2026-09-23) measures the Mac, winbox and Contabo every 10 min and serves the latest numbers at `GET https://webhook.mooniex.com/disk` (container `disk-serve` on Contabo; code MoonieX-Scriptable `server/disk-monitor`, 9760b88 + b116f2e). Its Mac colours follow this ADR's gauge. Anything here that needs another machine's free space reads that endpoint — it never measures again.

## Consequences
- A task that downloads 3 GB of plates and finishes leaves 0 bytes behind, or its close fails loudly.
- Delegate can refuse work; that is the point — a refused spawn costs a retry, a full disk costs every session at once.
