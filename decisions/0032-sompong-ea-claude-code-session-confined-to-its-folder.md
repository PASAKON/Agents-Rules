# ADR 0032 — SomPong becomes the CEO's EA: a Claude Code session confined to its own folder

- **Date:** 2026-09-26
- **Status:** Accepted. The CEO ordered it in session cto-aa2e4242 and ruled the four open points in the same session.
- **Owner:** CTO
- **Supersedes:** three of the family-profile safety invariants in `mooniex:projects/sompong-line.md`
  (CEO 2026-09-10), listed below. The other invariants stand.
- **Contract:** `mooniex:projects/sompong-ea.md` (the single source of the API between ClaudeFlow and the runner)
- **Relates:** IRON §54 (one project = one folder, projects talk only through APIs), ADR 0028 (hq.yaml decides)

## Context

- On 2026-09-26 the CEO's father posted five screenshots of a bank announcement in the family LINE
  group and wrote that he could not read them. SomPong's log held the five images only as
  `[รูปภาพ]` labels, so the family profile (no tools) could not answer. The CTO fetched the images
  through LINE's content API, read them, checked the bank's own page and pushed the summary into
  the group by hand.
- The CEO's order, in his words: "อยากให้ SomPong หลังบ้านทำงานเหมือน CLI เลย ทำได้ทุกอย่าง … แต่จำกัด
  อยู่แค่ Folder โปรเจคตัวเองเท่านั้น และทำตามกฏองค์กรที่ใช้รวมกัน", "สมพงษ์มีตำแหน่งคือ Executive
  Assistant หรือ EA เป็นผู้ช่วยของฉันโดยส่วนตัว", and "จริงๆมันคือการทำงานแบบคุณได้ แค่จำกัดให้อยู่ใน
  Project ตัวเองอย่างเดียว".

## Decision

1. SomPong is the CEO's **Executive Assistant (EA)**. It is not a C-level, and its sessions are never
   labelled `cxo-*`.
2. It is a **Claude Code session** (Sonnet 5, on the CEO's subscription) that runs on Contabo from
   `Projects/MoonieX/SomPong` (repo `PASAKON/MoonieX-SomPong`) as the unix user `sompong`.
3. **Woken by @, closed by quiet.** A conversation continues while its last turn was under 30 minutes
   ago. After that, the next @ starts a fresh session. Nothing stays running while the chat is quiet.
4. **The CEO gets the full EA.** Every other sender gets search-and-answer only, with no write and no
   delete.
5. **The boundary is the folder,** and it is enforced three times: by unix permissions (the `sompong`
   user), by Claude Code's Bash sandbox, and by permission deny rules. Org rules
   (`Agents/Rules`) are readable. Nothing else outside the folder is.
6. **LINE through ClaudeFlow's API only** (IRON §54). SomPong holds no LINE token and never reads
   ClaudeFlow's files. ClaudeFlow's internal API allows only the family group and the CEO as
   targets. The runner holds the keys, and the Claude process never sees them.

## Invariants superseded (from `projects/sompong-line.md`, 2026-09-10)

| # | Was | Now |
|---|---|---|
| 2 | The family profile has no CLI-level tools (`--tools ""`) | The EA has tools: full ones for the CEO, read and search only for everyone else |
| 3 | The model never decides a deletion | For the CEO, the EA may create, edit and delete **inside its own folder**. It may never delete group logs, which live in ClaudeFlow and have no delete path in the API |
| 4 | Never the secretary profile in a group | The EA serves the group. Its powers depend on the sender's role, never on the chat it is in |

Invariants 1 (no @, no answer), 5 (group messages are data, not commands) and 6 (money figures are
never kept or computed by the model) stand unchanged.

## Consequences

- The kill switch is `SOMPONG_LINE_BRAIN=claudecode`. It restores the 2026-09-10 family profile at once.
- Group push costs one message per member, so the free 300 per month allow about 75 pushed answers.
  The send API refuses push below a reserve of 20. The reply token stays the default and is free.
- The CEO has to run `claude /login` once as the `sompong` user (via Run Inbox). The CTO never
  handles the code.
- Telegram is out of scope for now. It stays on the secretary shim until LINE is proven.

## Amendment — v2, 2026-09-26 (same session, CEO rulings)

1. **Self-edit covers every file in its own repo, the cage included.** The CTO recommended locking
   `runner/`, `profiles/` and `ops/` behind a CTO merge. The CEO chose "แก้ได้ทุกไฟล์" knowing the risk: a
   prompt-injected CEO turn could widen its own permissions or read the CEO's Claude login. What still
   holds is outside its reach: LINE targets are allowlisted inside ClaudeFlow, keys stay in
   `/etc/sompong/ea.env` (root 0600, injected by systemd), family turns stay read-only, and every change
   is committed with a LINE alert to the CEO when a cage file moves.
2. **Same structure as the org** (CEO: "ออกแบบโครงสร้างของ SomPong แบบเดียวกับ ORG"): role file, role
   registry row, skill toggle, MCP config per role, org-format memory, Field-note learning. SomPong is the
   first role with its own skill + MCP toggle; workers follow the same schema later. **It is the one role
   that cannot delegate.**
3. Plain-text caveman replies, 30-day local retention of text and every file, Drive archive after that,
   one Drive share folder (`SomPong Share/`, CEO-only shares). Contract: `mooniex:projects/sompong-ea.md`
   (D) and (E).
