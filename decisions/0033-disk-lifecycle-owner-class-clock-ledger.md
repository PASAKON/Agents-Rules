# ADR 0033 — Disk lifecycle: every byte has an owner, a class, a clock and a ledger row

- **Date:** 2026-10-01
- **Status:** Accepted. The CEO answered 11 numbered proposals in one message: "1. ใช้ มีราวๆ 20TB 2. ตามนั้น 3. ได้เลย 4. ตามนั้น 5. ตามนั้น 6. OK 7. OK 8. OK 9. OK 10. OK 11. OK". The proposals are listed under "The CEO's decisions" below. The design they came with (classes, clocks, audit, crash steps) is adopted with them.
- **Owner:** CTO. Rule text lives here and in IRON §61. Code lives in Agents-Core (its CTO builds it). On winbox the Cookie Run steward executes (`cookierun-bot/docs/DATA-STEWARD.md` stays the authority for Cookie Run data).
- **Extends:** ADR 0030 (tiers, gauge, Work/), ADR 0031 (registry classes, Drive as the store). **Supersedes:** IRON §48 rules 1-4 (the disk and transcript part).
- **Rule:** IRON §61. **Audit procedure:** `playbooks/disk-audit.md`.
- **Config:** Agents-Core `config/storage-policy.yaml` holds every number below. `config/machine-contract.yaml` holds the class of every path. Neither number nor class is copied into prose elsewhere.

## Context

The CEO's question (2026-10-01), in his words:
"ให้แยกว่าอันไหนคือขยะ ยิ่งสะสมนานยิ่ง เป็นขยะ และอันไหนคือ ทรัพสินที่เอามาย้อนกลับมาดูได้ ... Rule สร้างมาเพื่อให้ Agents ทำงานเป็นระบบ ระเบียบมากขึ้นสามารถทำงานระยะยาวได้ผลดีโดยที่ Disk คงที่ ไม่เติบโตโดยไม่ จำเป็น ... ใครจะเป็นคนเครียนหลังจากนั้น เจ้าของเอง แล้สถ้าเขาไม่ทำตามกฏจะทำยังไง ... มีคนอื่นที่กลับมาอ่านกฏสามารถตรวจย้อนหลังได้ กี่ Step เพื่อป้องกัน Worker ตายละหว่างทางบ้าง"

In short: the disk must stay flat over months, someone named must clean, there must be a consequence when they do not, a third party must be able to audit afterwards, and a worker dying mid-task must not leak bytes.

What a read of both repos found on 2026-10-01. Ten read-only agents checked 55 claims against the code: 49 held and 6 held in part, and those 6 were corrected before this ADR.
- **Only four things refuse.** The spawn floor refuses below 5 GB (Agents-Core `tools/delegate.py:2030-2088`). The merge gate refuses while `Work/<task>` holds unfiled bytes (`tools/git_ops.py:472-497`). The media-guard pre-commit hook runs only in Agents-Core and is installed by hand. `space_check` runs only in `flow_shoot` and `gen_loop`.
- **Only three things delete on their own.** `storage_reclaim` removes REBUILD dirs inside task worktrees, and only during a local spawn below 10 GB free. Worktrees are removed at a local merge (`gc_stale_tasks --reap --go` is manual). Contabo's weekly cron archives transcripts. Everything else only alerts, or exists only in prose.
- **One gauge serves all three machines.** `storage-policy.yaml:13-17` holds the Mac's numbers. When the remote probe fails, the spawn floor lets the task through (`delegate.py:315-345`), and on winbox `ssh df` most likely always fails.
- **No step reclaims a dead worker's bytes.** Once a task is `stalled`, its `Work/` folder drops out of every watch: `_ORPHAN_STATUSES` at `tools/workdir.py:64` lists only done, merged, cancelled and failed. A remote respawn deletes the old worktree's untracked files and its branch (`scripts/spawn-worker-remote.sh:236-239`, `windows/spawn-worker.ps1:155-175`). Unpushed commits go with the branch.
- **The audit trail does not survive a wipe.** Every ledger is a local file on one machine. `$CLAUDE_CONFIG_DIR/logs/**`, which holds `drive-archive.log`, is classed DISPOSABLE (`machine-contract.yaml:54`). Green deletes write no row at all.
- **The written rules contradict each other.** §48 says "nothing deletes on its own"; ADR 0030 deletes REBUILD bytes automatically, and §58 rule 8 names a daily archiver. Transcripts are 30 days in §48 and 7 days elsewhere. The Drive transcript path moved. Chrome profiles are REBUILD in the registry and NEVER in the policy. `memory/` is REBUILD in the registry and NEVER in the policy. The skill both calls the journal Green and says it still asks. `Work/**` is IRREPLACEABLE in the registry, yet `tmp/` is deleted at close.
- **Measured piles.** Contabo had 7.9 GB free on 2026-09-28: 17.5 GB of full-checkout worktrees (0 of 22 sparse) and 6.3 GB of dead-session scratch. winbox holds 26.6 GB of dead worker worktrees. The 500 MB/day hit-frame cap still adds about 15 GB a month to winbox with no end. The Mac's Trash held 76 GB of already-backed-up files on 2026-09-25 while the disk sat at 1.8 GB free.

## The CEO's decisions (2026-10-01)

| # | Proposal | Answer |
|---|---|---|
| 1 | "Assets go on a disk" means Google Drive. The plan is about 20 TB, not the 2 TB that `drive-archive-gate.md` records. | "ใช้ มีราวๆ 20TB" |
| 2 | Free-space bands per machine (yellow / orange / red, GB free): Mac 20/10/5, Contabo 20/12/8, winbox 80/50/30. | "ตามนั้น" |
| 3 | A janitor (a tool, not a session) closes an owner's abandoned container at 72 h (24 h at orange or red). This replaces the 14-day abandoned-Work rule and amends §55 rule 4. | "ได้เลย" |
| 4 | Debt is closed at the owner's next spawn. The spawn is refused if more than 2 GB or more than 3 containers cannot be closed, and the CEO can override. 3 janitor closes in 7 days names the role in the CEO's weekly report and opens a fix task on its skill. | "ตามนั้น" |
| 5 | Mid-task, over the live budget (Mac 5 GB, Contabo 3 GB), the local copies of pieces already verified on Drive are evicted and leave a restore stub. | "ตามนั้น" |
| 6 | Scratch of a session closed for more than 7 days is garbage. Files with no Drive md5 match are archived first. | "OK" |
| 7 | The Mac archives transcripts automatically every day, as Contabo does. This replaces §48. | "OK" |
| 8 | winbox keeps hit frames locally for the last 30 days only. | "OK" |
| 9 | On the Mac, files verified on Drive by md5 are deleted outright, not moved to the Trash. This changes the 2026-09-27 film clean-up. | "OK" |
| 10 | §58 rule 1 binds a wipe or reinstall. A single-item delete needs that item's own verified copy. | "OK" |
| 11 | A weekly Green sweep is scheduled on all three machines. | "OK" |

## Decision

### 1. Five classes, asked in this order; the first yes wins

| Class | The one question | During the work | After the work | Who deletes |
|---|---|---|---|---|
| **PROTECTED** | Is it the CEO's own (Pictures, Desktop, Downloads, Movies, iCloud/CloudDocs), login state, a secret, `memory/`, live service data (Docker volumes, `tasks.db`, `rounds.jsonl`), or Cookie Run data on winbox? | read only | stays | the CEO; Cookie Run data: only the steward |
| **WORKING** | Does a live owner hold the container it sits in: an active task, a live session (pid alive and identity matching), or the machine itself (a CONFIG row, an installed toolkit)? | stays in its container | split into ASSET and GARBAGE at close | nobody while it is live |
| **ASSET** | If every copy vanished, would no stored command or durable URL bring it back (money spent, a paid generation, human time, a record of what happened)? | `out/` | Drive, md5 read back by file id, then the local copy is deleted | the tool that read the md5 back; anything ON Drive: the CEO |
| **GARBAGE** | Does a stored command, a durable URL or a verified Drive copy bring it back, with no live owner using it? | a cache dir, `tmp/`, the worktree | deleted at its maximum age (§2), never written to Drive (§58 rule 6) | janitor@machine, or any agent inside its own lane |
| **UNCLASSIFIED** | None of the above | not a place to work | the weekly doctor reports it; classified within 14 days | only on a human go (§58 rule 2) |

Three traps with fixed answers:
- **A worktree's unique bytes are an ASSET, the rest is GARBAGE.** Unique bytes are unpushed commits and dirty or untracked files. They are bundled first (`git bundle --branches --not --remotes` + `dirty.patch` + `untracked.tar`, to the approved `BACKUP/Agents-worktrees-<date>.tar`). This keeps §58 rule 6 true: what is archived is not garbage.
- **An `in/` file is GARBAGE only if its `SOURCES.txt` URL is durable.** Signed or expiring CDN links, such as paid-generation downloads, make the file an ASSET.
- **Login state is found by its files, not by the container's name.** Any tool deleting a directory first checks that no descendant matches a login-state glob (`Cookies`, `Login Data`, `Local State`, `Local Storage`, `IndexedDB`, `Session Storage`, `.credentials.json`, `rclone.conf`). A hit means skip and report. This is HARD (CEO 2026-09-28: login state is deleted only after asking him).

### 2. Garbage has a maximum age

The keys go under `clocks:` in `storage-policy.yaml`.

| Garbage | Maximum age |
|---|---|
| `Work/<task>/tmp`, and `in/` files whose source is durable | deleted at close |
| A merged worktree | deleted at merge |
| The worktree of a task that ended any other way (cancelled, failed, stalled, reverted) | 24 h; unique bytes bundled first |
| Dormant `node_modules` / `.venv` / `.next` / `dist` / `build` | 14 d (the existing dormancy test) |
| Package, model and browser caches (pip, npm and `_npx`, Homebrew, huggingface, torch, `Cache` / `Code Cache` / `GPUCache`) | weekly (the Sunday sweep), and at once at orange |
| Docker build cache (Contabo) | `docker builder prune --filter until=168h` weekly; never images or volumes |
| systemd journal (Contabo) | `journalctl --vacuum-size=500M` daily |
| Transcripts on the machine | 7 d, then archived to Drive (kept on Drive forever) |
| Scratch of a closed session (`/tmp/claude-0/<slug>/<uuid>`, `/private/tmp/claude-501/...`) | 7 d after the session closed; files with no Drive md5 match archived first. Paused (`force_saved`) sessions are exempt. |
| Leftover `work-archive-*` scratch tars | 24 h |

### 3. Where work bytes live

- **Before.** A task carries `expect_gb`. It proceeds only if (free − `expect_gb`) stays at least `max(min_free_after_gb = 5, the host's red band)`; the 5 GB is the CEO's 2026-09-23 ruling. The check moves out of the two runners into one library (`lib/space_check.py`) that every runner and `workdir.py fetch` call. A media task expecting more than 3 GB is refused on Contabo. This is a refusal, not routing: §59 keeps deciding where work runs.
- **During.** Every byte is written in `Work/<task-id>/` on the executing host, with `TMPDIR` pointed at `tmp/`, so an agent that forgets still writes in the right place. Downloads of 1 GB or more go through `workdir.py fetch`, which reserves the space and writes the `SOURCES.txt` line.
- **When it gets too big.** The live budget per task is Mac 5 GB and Contabo 3 GB. winbox has no org budget, because it is the steward's lane.
  1. **Checkpoint.** A finished `out/` file of 100 MB or more that has been unchanged for 30 minutes and is not open is copied to its final Drive home. Its md5 is read back by id, and a line goes into `out/DRIVE.txt`. The local copy is kept.
  2. **Evict** (decision 5). Over the budget, or at orange, checkpointed files lose their local copy and leave `<name>.ondrive.json` behind; `workdir.py fetch --back` restores one.
  3. **Stop.** At 2× the budget, or at red, the worker is told to stop writing new bytes: it finishes without new bytes or exits with a `BLOCKER.md`. Nothing is killed, and the owner gets one letter naming the bytes.
  - **Exempt from checkpoint and eviction (CEO filing rules, 2026-09-23):** an assembled cut, which goes to Drive only when signed off or as the last cut of the day, and clips held on disk for the CEO's review. If exempt files alone exceed the budget, step 3 applies.
- **After.** `out/` goes to the project's Drive branch, or to `BACKUP/MoonieX HQ/Work-Archive/` when no home was filed. Files already listed in `DRIVE.txt` count as filed. `tmp/` is deleted. Checkpoint tars use the existing Work-Archive naming (`Agents-Work-<task>-<date>-ckptNN.tar`), with no new sub-folder. An owner who files to the local `Assets/<Brand>` (hq-filing) keeps those bytes on the machine by choice. They are counted as the project's, not as a leak.

### 4. Per-machine bands (decision 2)

The bands replace the single `gauge:` with `gauge_by_machine:`. Free space is read from the disk hub (ADR 0030). A failed probe now refuses instead of letting the task through.

| Machine | Yellow below | Orange below | Red below |
|---|---|---|---|
| Mac (256 GB) | 20 | 10 | 5 |
| Contabo (72 GB) | 20 | 12 | 8 |
| winbox (512 GB) | 80 | 50 | 30 (the steward's floor) |

Each band keeps the actions of the bands above it:
- **Yellow:** a daily notice naming the top 10 holders by bytes, and on the Mac the size of the Trash.
- **Orange:** the Green sweep runs now, no download or video task spawns, and the janitor's grace drops to 24 h.
- **Red:** every spawn is refused and queued, and the janitor closes terminal containers now, smallest first. The queue drains against the target host's free space, not the local one.

### 5. Who cleans, and what happens when they do not

**Owners.** Task bytes (`Work/<task>`, the worktree, checkpoints) belong to `tasks.owner_cto`; a worker never owns bytes. Session scratch, transcripts and uploads belong to the session named in the path. Caches, the journal and the build cache belong to the machine. This binds C-level sessions as much as workers: the two biggest recent leaks (`/tmp/ilag-*`, 6.8 GB, and B-roll left in a scratchpad) came from C-level sessions.

**The ladder** (decisions 3 and 4):
1. **The owner closes.** Merge is refused while `Work/` is unfiled (exists today). At `/session-close`, `disk_audit --session <id>` must report 0 bytes held by ended containers, or a hand-off naming each one.
2. **Any other end starts the clock (T0).** Cancelled, failed, stalled and reverted all count. `tmp/` and durable-source `in/` go the same tick, and the owner is told, or a LungNote [CRITICAL] is filed when the owner is gone. `review` and `blocked_human` do not start the clock.
3. **T0 + 48 h is debt.** At the owner's next `delegate_task`, its terminal containers are closed first through its own close. The spawn is refused only if more than 2 GB or more than 3 containers cannot be closed. A CEO override flag is logged.
4. **T0 + 72 h (24 h at orange or red): janitor@machine closes.** It is a scheduled tool, not another session, running the owner's own `workdir.py close --archive`. Archive goes first and md5 is read back before any delete. The ledger row reads `actor=janitor@<machine>, charged_to=<owner>`. The owner loses the choice of destination: unfiled `out/` goes to Work-Archive.
5. **Repeat offender.** 3 janitor closes charged to one role or project in 7 days names that role in the CEO's weekly report and opens a fix task on its skill.

**Owner gone.** An owner is gone when its session is closed or abandoned, or its lock pid has been dead for 24 h. The janitor closes on the same clock and writes an `adopt` row naming the previous owner; `tasks.owner_cto` is never rewritten. A task with no `owner_cto` is charged to the dispatching host's standing CTO.

**What the janitor cannot close** (upload error, md5 mismatch, Drive relay down): it keeps every local byte, renames the Drive object `BROKEN-` (filing rule 10), writes a `stuck` row, and files a LungNote with a GitHub-issue fallback. It retries after 24 h, never in a loop.

**Limits on the janitor.** It never touches PROTECTED or UNCLASSIFIED paths, a task id unknown to the local database, or a row owned by another host. It runs `--dry-run` for its first 7 days, writing "would delete" rows that are read before `--apply`. On winbox it only plans, and the steward executes.

### 6. Standing changes for specific kinds

- **Transcripts (decision 7).** A scheduled job on every machine archives sessions untouched for 7 days, every day: `tools/drive_leg.py transcripts --machine <m>`. It never takes a session that `~/.claude/sessions/*.json` lists as live. This makes §58 rule 8's "daily archiver" real. `prune_transcripts.py --archive` retires; `--restore` stays for the 112 Mac archives already under `Claude-Transcripts/mac/`.
- **Session scratch (decision 6).** It moves from NEVER to its own class: HOT while the session lives, GARBAGE 7 days after the session closed, with archive-first for anything not on Drive.
- **Hit frames (decision 8).** The 500 MB/day cap still applies; the local window is the last 30 days. Older kept days stream to `BACKUP/CookieRun Backup/` and are deleted after md5 by the steward's loop. The steward records this in `DATA-STEWARD.md`, which stays the authority. `rounds.jsonl` never leaves the box.
- **The Mac Trash (decision 9).** A file whose Drive md5 has been read back is deleted, not trashed: moving to `~/.Trash` frees nothing on APFS. Files without that proof still go to the Trash or stay. Emptying the Trash stays the CEO's.
- **§58 rule 1 scope (decision 10).** Rule 1 binds an OS reinstall, a disk wipe, or deleting a registry row's whole path on a machine. A single-item delete needs that item's own Drive copy verified by checksum, or the item is GARBAGE.
- **The Green sweep (decision 11).** It runs weekly on Sunday and at once at orange. On the Mac and Contabo the janitor runs it. On winbox the steward runs it, inside the org lanes of `references/winbox.md` only: Temp, the Recycle Bin and anything else of the CEO's stay "report only".

### 7. The ledger, and the audit it makes possible

- **One appender, one schema** (`lib/byte_ledger.py`). Fields: `{seq, ts, machine, kind, container, task_id, session_uuid, actor, charged_to, class, bytes, files, md5_local, drive_id, md5_drive, policy_version}`. `kind` is one of `create`, `checkpoint`, `close`, `close_partial`, `archive`, `verified`, `delete`, `reclaim`, `sweep`, `death`, `adopt`, `stuck`, `refuse`, `debt` or `janitor_run`. Every tool that creates, archives or deletes calls it, including Green deletes, as one aggregate `sweep` row per run. It replaces the four incompatible formats in `drive-archive.log`. A ledger failure never blocks a worker; it is a doctor failure.
- **Ledgers are IRREPLACEABLE** (`machine-contract.yaml` rows, splitting `logs/**`). They leave the machine weekly, as one gzip per machine per week on Drive. The destination folder `BACKUP/MoonieX HQ/Ledgers/<machine>/` is **proposed**: under the filing rules it waits for the CEO's yes. They go to a hub table once the ADR 0025 hub is live.
- **The audit** is `playbooks/disk-audit.md`: 9 steps that any session can run from git, Drive and the ledger, plus the reduced procedure that works before the ledger exists.

### 8. A worker that dies mid-task: 13 steps

| # | Step | Today |
|---|---|---|
| 1 | Floor before birth: per-host bands, a probe that refuses on failure, `expect_gb` reserved, a queue that drains against the target host | exists at 5 GB; the probe lets tasks through and the drain measures the local disk |
| 2 | Birth record before the first byte: task row, `.org-task.json`, `Work/<task>`, a `create` ledger row, remote spawns included | local spawns only |
| 3 | Claim check at 25 s | exists |
| 4 | Heartbeat; STALLED at 30 min. Heartbeat from a PostToolUse hook, so silence counts from the last tool call | exists on the Mac; Contabo's watchdog unit must be confirmed running |
| 5 | Remote death detection, plus a counter for unreachable hosts (one LungNote after 2 h naming the rows and bytes stranded) | exists, without the counter |
| 6 | A silent live pid gets an identity check every tick. A mismatch (recycled pid) counts as dead. A match is never reaped (the CEO's rule), and gets one LungNote at 6 h naming the bytes held | new |
| 7 | Death becomes visible: `stalled`, `reverted` and `blocked_host` join the orphan statuses; the Work/ pass runs before the stall pass; a `death` row with the bytes held; the owner is told | new (`workdir.py:64`) |
| 8 | Checkpoint finished pieces to Drive during the work (§3) | new |
| 9 | Archive as a re-runnable sequence: manifest, tar, upload, md5 read back, `verified` row, local delete, `delete` row; scratch tars cleaned on every exit | verify-before-delete exists; a failed run leaves its tar in `mkdtemp` (`tools/work_archive.py:223`) |
| 10 | Resume without loss: a remote respawn bundles unpushed commits and untracked files before it removes anything; `worker_resume` exports `WORK_DIR`; a reap clears `tasks.worktree` | local resume exists; a remote respawn deletes them |
| 11 | Clocked reapers through the janitor (§2, §5) | new |
| 12 | The ledger leaves the machine (§7) | new |
| 13 | The weekly reconcile (`disk_audit --weekly`, run by the doctor) fails loudly on ownerless bytes, on a leak older than 72 h, or on an enforcer silent for 26 h | the doctor exists, reports only, and is not installed on the Mac |

Today 7 of the 13 exist in full or in part, and none of the 7 returns a dead worker's bytes. With all 13, a worker that dies between any two instructions loses at most the piece it was writing, and its bytes are back to baseline within 72 h, with a ledger trail.

## Build (Agents-Core; this wiki ships first)

**P0: bug fixes, no further decision needed**
- `tools/workdir.py:64`: add `stalled`, `reverted` and `blocked_host` to `_ORPHAN_STATUSES`. In `runners/watchdog.py`, run the `work_watch` pass (`:1088`) before the stall pass.
- `scripts/spawn-worker-remote.sh:236-239` and `windows/spawn-worker.ps1:155-175`: bundle unpushed commits and untracked files to Drive before `rm -rf` / `git branch -D`. Better, stop deleting the branch, as `drive-archive-gate.md` says branches are never deleted.
- `tools/delegate.py:315-345`: refuse when the probe fails, and read the disk hub (ADR 0030) instead of `ssh df`.
- `tools/work_archive.py:223`: tar inside the task's own folder, or remove the `mkdtemp` dir on every exit; rename to `BROKEN-` on an md5 mismatch.
- `tools/storage_policy.py:95` skips every glob containing `<...>`, so `Work/` is UNCLASSIFIED. Use concrete `~/MoonieXHQ/Work/**` and `/opt/MoonieXHQ/Work/**`.
- `tools/git_ops.py:485`: pass `by=task.owner_cto`, not the literal `"cto"`.
- `deploy/systemd/mooniex-watchdog.service`: set `LUNGNOTE_MCP_NODE` (node 22). Confirm the unit is enabled on Contabo. Install the Mac `machine_doctor` LaunchAgent.

**P1: built on this ADR's decisions**
- `config/storage-policy.yaml`:
  - `gauge_by_machine`, `clocks`, `work_dir.live_budget_gb {mac: 5, contabo: 3}`, `checkpoint_file_mb: 100`, `checkpoint_idle_min: 30`, `debt_gate_gb: 2`, `debt_gate_containers: 3`.
  - `abandon_days` is replaced by `janitor_archive_h: 72` / `janitor_archive_h_orange: 24`.
  - Session scratch moves out of NEVER into its own class.
- `config/machine-contract.yaml`:
  - Split `Work/**`: `out/` and unsourced `in/` IRREPLACEABLE; `tmp/` and sourced `in/` REBUILD.
  - Split `logs/**`: the ledgers and `drive-archive.log` IRREPLACEABLE.
  - Chrome and automation profiles become NEVER, to agree with the policy.
  - `memory/**` agrees with the policy (NEVER).
  - Add rows for `/var/log/journal`, `.claude/worktrees`, `/tmp/claude-*` and `C:/mooniex`.
  - Add `baseline_used_gb` per machine.
- New `tools/disk_janitor.py` (`--tick` from the watchdog, `--band`, `--notify` daily, `--plan`). It adds no delete logic of its own: it orchestrates `workdir.close --archive`, `gc_stale_tasks.reap_worktrees` with bundle-first, the scratch reaper, `storage_reclaim` in machine-cache mode, the journal vacuum and `docker builder prune`. `--notify` replaces `prune_transcripts --notify`.
- New `lib/byte_ledger.py` and `tools/disk_audit.py` (`scan`, `--path`, `--session`, `--owner` read by delegate, `--weekly` writing the git-tracked `state/disk-audits.jsonl`).
- `tools/workdir.py` gets the verbs `is-live`, `reserve`, `fetch`, `fetch --back` and `checkpoint`, plus `close_partial` rows.
- `tools/delegate.py`: the per-host bands, the debt step, `expect_gb`, the `TMPDIR` export, a `Work/` dir for remote spawns, a sparse checkout for launcher spawns, and the media-task refusal on Contabo.
- `tools/drive_leg.py`: `--machine` instead of the hard-coded `contabo`, transcripts daily on every machine, and a live-session skip.
- `tools/machine_doctor.py`: scan `/tmp`, `/private/tmp`, `/var/log` and `C:/mooniex`; fill the owner from `.owner.json`; notify on failure.
- New `scripts/hook-write-guard.py` (warn-only for 7 days, then exit 2 for writes under PROTECTED globs, Desktop/Downloads/Movies, bare `/tmp` or another task's folder) and `scripts/hook-heartbeat.py`.
- New `tools/policy_lint.py` in CI. It fails on a config key with no reader, on a path classed differently by the two YAML files, and on a number in a rule that differs from the YAML.
- Skills, same change set:
  - `ALL_Rules_DiskHygiene` (and its `references/*.md`): the agent card at the top, a ledger row for Green deletes, the journal settled as Green, the abandoned-Work row executed by the janitor at 72 h, the winbox floor from the bands, the 30-day hit window.
  - `CXO_Rules_GDrive_Filing` and the folder map: film clean-up deletes Drive-verified files instead of trashing them; Work-Archive's definition gains checkpoint and scratch tars.
  - `session-close`: a disk step.

**P2: waits on the ADR 0025 hub cutover.** The ledger moves to a hub table. The owner-gone test reads `c_level_sessions` from the hub. The debt gate reads the hub. Until then the gates read the local database, and a task unknown to it is reported, never cleaned.

## Superseded (fixed in the change sets above)
- IRON §48 rules 1-4: a banner is added under §48. Rules 5, 6 and 8 still bind; rule 7 is executed by the janitor.
- `ALL_Rules_DiskHygiene` lines that call transcript archiving manual, keep "the journal still asks", give abandoned Work 14 days, or send VPS backups to `Archive/Backups`. `references/winbox.md` "hit frames are never deleted".
- `config/storage-policy.yaml` NEVER entries for the two scratch roots. The `<work_root>` COLD row.
- `drive-archive-gate.md` "nothing in this file runs on its own" and "2 TB plan": amended in this change.

## Open (not decided here)
- The Drive folder `BACKUP/MoonieX HQ/Ledgers/<machine>/` (filing rule 3: needs the CEO's yes).
- Contabo's Docker images (14.93 GB) have no clock; only the build cache does.
- Whether an org janitor may ever act directly on winbox. The default stays: the janitor plans, the steward executes.
- The ADR 0025 hub cutover, on which P2 waits.

## Consequences
- An agent makes one disk decision, keep (`out/`) or not (`tmp/`); every later step runs on a clock.
- A disk that grows has a name attached: the ledger says which container, whose, and since when.
- The janitor can archive something a wrong status called dead. The identity check, archive-first, the restore line in every manifest and the 7-day dry run are the guard.
- Rule drift has a test: `policy_lint` fails the build when prose, policy and registry disagree.
