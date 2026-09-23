<!-- Filed 2026-09-05 from ~/.claude/tools/drive-archive-gate.md per IRON-RULES §48 (CEO order). The copy next to the tool mirrors this page; edit here first. -->

# Drive archive gate (CEO 2026-09-05)

Rule for any agent asked to move data from the Mac to Google Drive. Nothing in
this file runs on its own: the daily disk watch only *reports* candidates, and
an agent moves them only after the CEO says go on a specific alert.

## What may move (and where)

| Source on the Mac | Destination in Google Drive (`ไดรฟ์ของฉัน/`) | Note |
|---|---|---|
| `~/Backups/**` | `Archive/Backups/<same relative path>` | VPS backups; keep folder names and dates |
| `~/Projects/Agents/output/**` | `Archive/Agents-output/<same relative path>` | generated deliverables (b-roll, prompts) |
| Claude transcripts | `Claude-Transcripts/<project>/<uuid>.tar.gz` | only via `prune_transcripts.py --archive`, never by hand |
| `winbox: Documents/CookieRunScript/play_rec/<take>/` (CEO's recorded Cookie Run takes) | `BACKUP/CookieRun Backup/play_rec/<take>.tar` + `<take>.manifest.json` | CEO-approved 2026-09-06; one tar per take (never loose frames), sha256 manifest, uploaded from the box with rclone (`gdrive:` remote, scope drive.file), verified with `rclone check`; steward brief `cookierun-bot/docs/DATA-STEWARD.md` |
| `winbox: Documents/CookieRunScript/play_rec/bot_session-*/`, `playset/*` (bot recordings, training sets) | `BACKUP/CookieRun Backup/bot_sessions/`, `.../playsets/` | same rules; proposed 2026-09-06, file only after the CEO OKs each batch |
| `~/Projects/Agents/worktrees/<wt>/` — the unmerged commits + dirty/untracked files of task worktrees being removed to reclaim disk | `BACKUP/Agents-worktrees-<YYYY-MM-DD>.tar` + `.manifest.json` at the BACKUP root (a `BACKUP/Agents Backup/` sub-folder is PROPOSED, not yet approved — move the tar there server-side once the CEO names it) | CEO-approved in chat 2026-09-10 ("สำรองถ้าไม่มั่นใจ ใน Skill google drive filling"). Staged with `~/Backups/agents-worktrees-<date>/wt_backup.py`: per worktree a git bundle of `base..branch`, `dirty.patch`, `untracked.tar`, `TASK.md`, `manifest.json`; one outer tar + sha256/md5 manifest; uploaded from the Mac through the Drive REST resumable upload (`scripts/gdrive-bridge/ilag_sync.py` `upload()`), `md5Checksum` checked against Drive BEFORE any worktree was removed; dirty files were additionally `git stash`ed into the owning repo (`git stash list \| grep 'CTO disk reclaim'`). Branches are never deleted. First item 2026-09-10: 38 worktrees, 48.8 MB, ~13.5 GB reclaimed. |
| `~/MoonieXHQ/Work/<task-id>/` — the unfiled `in/` (no SOURCES line) and `out/` files of a task being closed (IRON §55, Work/RULES.md rule 6) | `BACKUP/Agents-Work-<task-id>-<YYYYMMDD>.tar` + `.manifest.json` at the BACKUP root (same precedent as `Agents-worktrees-*`) | CEO-approved in chat 2026-09-23 ("ส่งไฟล์ขึ้น Drive ครั้งแรก (workdir.py close --archive) … จัดการได้เลย"). Tool: `python tools/workdir.py close <task> --archive` → `tools/work_archive.py`: one tar + manifest (sha256/md5, source paths, restore line), Drive REST resumable upload in 8 MiB chunks from the Mac (never the Drive-for-Desktop mount — it keeps local copies), `md5Checksum` read back by file id and compared BEFORE the local files are deleted; one line in `~/.claude/logs/drive-archive.log` + `Work/_ledger.jsonl`. |
| `~/Projects/PARKED-*/` gitignored data only (the tracked code lives on GitHub `PASAKON/PARKED-*`, archived) | `BACKUP/PARKED-<repo>-ignored.tar.gz` + `.manifest.json` at the BACKUP root | same approval 2026-09-10. tar.gz of the ignored dirs only (moonx: `backtest/data`, `backtest/out_*`; video-engine: `output/`), md5 verified on Drive, then the local clone deleted. Restore: `git clone <origin>` + `tar xzf` (the manifest carries both). Copies also under `~/Backups/parked-repos-<date>/`. |
| `~/Projects/cookierun-bot/vision/from_pod/` — trained models that exist ONLY on the Mac (the rest of that directory is byte-identical to winbox and needs no backup) | `BACKUP/CookieRun Backup/from_pod-mac-only-<YYYY-MM-DD>.tar` + `.manifest.json` | CEO-approved in chat 2026-09-13 ("ถ้า เทรนแล้ว และ สำรองข้อมูลแล้ว ลบได้เลย ถ้ายังไม่สำรอง เอาไว้ใน Google drive"). Filed at the `CookieRun Backup` root, not a new sub-folder — a `models/` sub-folder is PROPOSED, not approved. **Decide what to back up by md5, not by name:** the first pass compared every file against winbox's own `from_pod` and found 29 identical, 2 identical under a different name, and 27 genuinely Mac-only (463.6 MB) — backing up all 58 would have uploaded 763 MB to save 464 MB of real content. The Mac cannot upload this itself: the rclone token lives only on winbox (`%APPDATA%\rclone\rclone.conf`) and `gdrive-filing` forbids copying it, so the tar is scp'd to the box and `rclone copy`'d from there, then `rclone check --one-way` before the Mac copy is deleted. |
| `~/Desktop/BL-voice-tests/**` — 60 TTS takes of one BL50 excerpt (30 Gemini 3.1 Thai voices + audition reel + Chirp 3 HD / Gemini 2.5 Pro / MiniMax comparisons + docs), 85.3 MB | `ALL DRAFT/ASSETS/Audio/Voice Library/` (flat, no sub-folders) | CEO named the path himself 2026-09-18 ("ALL DRAFT/ASSETS/Audio/Voice Library/ Drop file here") after being asked, because no audio folder existed anywhere under ASSETS. Loose files on purpose, same reason as the B-roll rows: the point is to open one file and listen. Uploaded with `ilag_sync.upload()`, **60/60 verified** by `md5Checksum` + size + parent, every one logged in `~/.claude/logs/drive-archive.log`. Local copies stay on the Desktop — they are small and they are the evidence behind the engine choice. |
| `Agents/prototypes/bl-model-bakeoff/out/BL-*-Wan*.mp4` — 5 Wan 3.0 clips from the 2026-09-18 Kling-vs-Wan bake-off (1080x1920, 5.00 s, ~52 MB total) | `ALL DRAFT/ASSETS/AI Assets/BLACK LIQUIDITY (9:16)/(purpose) (D-M-YYYY) (Wan 3.0).mp4` | CEO-approved in chat 2026-09-18 ("เก็บ B-roll Wan 3.0 ไว้ใช้ต่อได้เลย เอาเก็บไว้ใน Google Drive"). Same loose-file EXCEPTION and the same reason as the Seedance row below: a worker fetches one clip at a time by Drive id out of `bl-broll-catalog/CATALOG.md`. Uploaded with `ilag_sync.upload()`, each verified by `md5Checksum` + size + parent (5/5), logged in `~/.claude/logs/drive-archive.log`, and registered as catalogue rows 85-89 with a 4-frame `sheets/<drive_id>.jpg` each. **Three carry baked-in ENGLISH text** ('RETURN 35% / MONTH', 'NOTICE OF SEIZURE', 'TRANSFER FAILED') — their `caution` column says to use them only for that claim and to keep the frame tight, because the secondary labels are gibberish. Local copies stay: they are 52 MB and also the bake-off evidence. |
| `~/Desktop/archive/*.mp4` — 65 Seedance 2.0 B-roll clips (Higgsfield Unlimited, 3–7 Aug 2026, 1080x1920 8.08 s, 1.59 GB) | `ALL DRAFT/ASSETS/AI Assets/BLACK LIQUIDITY (9:16)/(purpose) (D-M-YYYY) (Seedance 2.0).mp4` | CEO-approved in chat 2026-09-18 ("ใช้ตามนี้ อัปขึ้น Drive ได้เลย" + "หลังจาก Up ลง Gdrive แล้วฝากลบในเครื่องด้วย เช็คให้ชัวร์ก่อนลบ"). **EXCEPTION to "one tar per item", deliberate:** loose files, because a video worker fetches clips one at a time by Drive id from the catalogue (`Agents/prototypes/bl-broll-catalog/CATALOG.md`, drive ids in `drive-manifest.json`). Uploaded from the Mac via `ilag_sync.upload()` (Drive REST resumable), `md5Checksum` + size + parent verified per file (`upload_broll.py`), then the local copy removed one file at a time only after a FRESH Drive md5 re-check (`delete_verified.py`, refuses unless all 65 verified). Every file logged in `~/.claude/logs/drive-archive.log`. |

Anything not in this table needs a new row approved by the CEO first. The
Drive folder is `/Users/gob/Library/CloudStorage/GoogleDrive-pass.gob1@gmail.com/ไดรฟ์ของฉัน`
(stream mode, 2 TB plan, ~1.8 TB free on 2026-09-05).

## Never touch

- `~/.claude/projects/*/memory/` (auto-memory), any live session's files
  (`~/.claude/sessions/*.json` lists them)
- `~/Library/Application Support/CloudDocs/session/i` — the iCloud store for
  the CEO's Desktop, not a cache (29 GB of .mov/.MP4 on 2026-09-10 — leave it)
- `~/Pictures/Photos Library.photoslibrary` — only the Photos app or Drive's
  own Photos backup may read it
- `~/Desktop`, `~/Downloads`, `~/Movies` — CEO is consolidating phone data
  there (2026-09); parked until he says otherwise
- any `.git` directory, any `.venv` / `node_modules`
- Dropbox, iCloud Drive, or any other cloud folder as a destination

## How to move (copy, verify, then delete — in that order)

1. Confirm the go covers exactly this source path and this alert date.
2. `rsync -a --info=progress2 "<source>/" "<drive-dest>/"` — copy, never `mv`.
   Without the stream-mode folder (or for anything bigger than a few files) use
   the Drive REST resumable upload from `scripts/gdrive-bridge/ilag_sync.py`
   (`upload(path, name, parent_id)`), then read back `size,md5Checksum` and
   compare with a local md5 — that is the verification (used 2026-09-10).
3. Wait until Drive has uploaded: the Drive menu-bar icon shows no pending
   items and every file in the destination opens. Do not proceed while
   "uploading" is still showing.
4. Verify: `cd <source> && find . -type f -exec shasum -a 256 {} + | sort -k2 > /tmp/src.sha`
   and the same in the destination; `diff` must be empty. Size alone is not
   verification.
5. Only now delete the source, and Empty Trash so the space actually returns.
6. Append one line per source to `~/.claude/logs/drive-archive.log`:
   date, source, destination, file count, bytes, sha-list checksum.
7. Tell the CEO over SomPong what moved, how much came back, and the
   destination path (`lib.telegram_out.send_to_ceo` from the Agents repo).

### When the data is on winbox, or the Mac lacks the credential

The rclone token is deliberately confined to winbox, so a Mac-side item that
needs Drive goes: **scp the tar to the box → `rclone copy` from the box →
`rclone check --one-way` → delete the Mac copy.** Two traps measured 2026-09-13
on that hop:

- **macOS `tar` writes AppleDouble `._*` companions.** A 15,825-file transfer
  arrived as 26,306 files; the 10,481 extras were pure metadata (1.7 MB) and made
  a manifest comparison fail for no real reason. Use `COPYFILE_DISABLE=1 tar …`,
  or strip `._*` and `.DS_Store` on the far side before verifying.
- **Verify with a manifest hash, not a byte count.** Walk both trees, md5 every
  file, sort `relpath\tmd5\tsize` and hash the joined list. One number on each
  side either matches or does not — and it names the difference when it does not.

## Restore

Copy the folder back from the same Drive path to the original Mac path.
Transcripts: `python3 ~/.claude/tools/prune_transcripts.py --restore <uuid>`.
Worktrees / PARKED repos: follow the `restore` line inside the tar's manifest.

## Alerting

`~/.claude/tools/prune_transcripts.py --notify` runs daily 09:00 via launchd
(`com.gob.claude-prune-transcripts`). It messages the CEO (SomPong) when free
space < 20 GB, transcripts ready to archive ≥ 2 GB, gate candidates ≥ 2 GB,
or every Monday. Thresholds live in `~/.claude/prune-transcripts.json`.
