# Disk audit: check afterwards that every machine stayed flat (IRON §61, ADR 0033)

Any session can run this. The audited machine does not need to be alive, because the inputs are git, Drive and the
byte ledger. The output is one line in Agents-Core `state/disk-audits.jsonl`, which is git-tracked (the same pattern
as `state/re-os-drills.jsonl`).

There are two procedures:
- **The full audit** needs `lib/byte_ledger.py` and `tools/disk_audit.py`. Both are on ADR 0033's build list.
- **The reduced audit** works today with what already exists. Run it until the ledger ships, and say in the result
  which one you ran.

## The full audit: 9 steps

1. **Policy in force.** In a non-shallow clone of Agents-Core, run
   `git log -p -- config/storage-policy.yaml config/machine-contract.yaml` over the window. Use the version in force
   on each day, not today's.
2. **Fetch the ledger.** Run `python tools/disk_audit.py fetch --machine <m> --from <d1> --to <d2>`. It reads the
   weekly Drive copies (the hub table once the ADR 0025 hub is live). A gap in `seq` means rows were lost:
   **finding F1**.
3. **Flatness.** Measure only the org's bytes. The CEO's own paths, the Trash, swap and live Chrome code-sign clones
   are excluded. Compare against `baseline_used_gb` in `machine-contract.yaml`.
   - PASS when the drift per week is at most Mac 5 GB, Contabo 3 GB, winbox 10 GB (plus the hit-frame window).
   - On FAIL, list the top 10 containers by bytes.
4. **Attribution.** Run `disk_audit scan`. Every container of 100 MB or more must have a `create` row or an
   `.owner.json`. One without either is OWNERLESS: **finding F2**.
5. **Closure.** Every task or session that ended in the window must have a `close` row (or a janitor `close`) whose
   remaining local bytes are 0 within 72 h, except bytes filed to the local `Assets/` on purpose. Count each container
   once. Do not add archived and deleted bytes together, because an asset is both. A container still open after 72 h
   with no `stuck` row is a LEAK: **finding F3**, listed with owner, host and bytes.
6. **Proof of copy.** For EVERY `delete` row of an ASSET, read `md5Checksum` from Drive by `drive_id` and compare it
   with the row and with the manifest's file count. Check every row, never a sample, because deletes are
   irreversible. A mismatch is **finding F4 (critical)**: rename the Drive object `BROKEN-` and tell the owner.
7. **Legality.** Re-run `storage_policy classify` on every deleted path, at the policy version in force on that day.
   - A GARBAGE delete must have met its clock.
   - An ASSET delete must follow a `verified` row.
   - Critical **finding F5** if any delete touched a PROTECTED path or a directory holding login state, if a winbox
     delete was not made by the steward, or if a Drive delete was not made by the CEO.
8. **The watchman.** Every machine must show `janitor_run`, transcript-archive and ledger-copy rows less than 26 h
   apart through the whole window. A longer gap means enforcement was dead for that span. Every `death`, `stuck`,
   `adopt` or `refuse` row needs a resolution within 72 h.
9. **Record.** Append `{date, auditor_session, machine, window, procedure: "full", F1-F5 counts, flat_delta_gb,
   verdict}` to `state/disk-audits.jsonl`, then commit and push. File each LEAK or `stuck` item as a LungNote to its
   current owner, and send the CEO one line. Rerunning on the same inputs gives the same result.

## The reduced audit: works today

What it cannot see:
- Green deletes write no row today.
- Logs live on one machine each.
- Who created a byte can be answered only inside a container whose name carries an id: `Work/<task-id>`, an org
  worktree `<project>__<role>__<task-id>`, `<slug>/<uuid>.jsonl`, or `/tmp/claude-*/<slug>/<uuid>`.

1. **Policy in force:** as step 1 above.
2. **Free space:** read the disk hub (`GET https://webhook.mooniex.com/disk`, ADR 0030), which keeps the latest numbers
   only, or measure on the box:
   - Mac: `df -h /System/Volumes/Data`
   - Contabo: `df -h /`
   - winbox: `Get-PSDrive C`

   Compare with the bands in `storage-policy.yaml`.
3. **Containers:** run `du -sh` on `Work/*`, the task worktrees, the harness `.claude/worktrees/*` and the session
   scratch roots. Join each task id to `tasks.db` (`status`, `owner_cto`) on the box that owns the row (ADR 0024 split
   brain). Anything of 100 MB or more with no id in its path is OWNERLESS.
4. **Orphans:** run `python tools/workdir.py orphans` and `python tools/gc_stale_tasks.py --reap` (no `--go`, so it
   only lists). Until the ADR 0033 P0 fix, `orphans` does not list stalled tasks, so check those rows by hand.
5. **Proof of copy:** for each archive named in that box's `~/.claude/logs/drive-archive.log`, read the `.manifest.json`
   next to the tar on Drive, and `md5Checksum` by file id.
6. **Doctor:** run `python tools/machine_doctor.py --machine <m> check` and list DISCOVERED paths with their age against
   the 14-day clock.
7. **Record:** as step 9 above, with `procedure: "reduced"` and the limits above named in the line.
