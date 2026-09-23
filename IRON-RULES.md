# Iron Rules — org runtime (canonical)

**The rules that bind every agent, on every project, on every machine.** Read
these whoever you are and whatever you are working on.

Verbatim quotes from project source files. **Do not paraphrase these in code review or commit messages — quote them exactly.**

> **Here (19 sections):** §0 read-wiki-first · §1 one-repo-one-folder · §2 push
> rules · §5 env/secrets · §15 agent role memory · §17 agent messaging ·
> §23 engineering integrity · §29 visible DEV spawn · §30 DB table governance ·
> §31 one CTO per repo · §32 tab title · §33 act only on tasks you own ·
> §34 key registry · §35 session discipline · §36 CTO merges · §37 no crude
> language · §38 TOON · §39 no em dash · §40 LungNote SID tag · §41 graph-readable
> wiki · §42 browser is a C-level decision · §43 suspect the environment first ·
> §44 rules as values not adjectives · §45 no blocking prompts unattended ·
> §46 a rented GPU is watched until dead · §47 check the research library first · §48 disk and transcript hygiene: alert first, move by hand · §49 Drive: the skill is the rule · §50 every session visible, every teardown proves identity.
>
> **The other 21 are MoonieX-specific** (Vercel deploy, Supabase, migrations,
> cron, fal.ai queue, design system, Drive convention, …) and live in
> [MoonieX's Iron Rules](https://github.com/PASAKON/MoonieX-Wikis/blob/main/IRON-RULES.md)
> (`mooniex:IRON-RULES.md`). Split 2026-08-03 per ADR 0013. **Section numbers
> were deliberately NOT renumbered**, so every existing §N citation still
> resolves. §18 has never existed, and §11/§16 sit out of numeric order in the
> MoonieX half — both pre-existing quirks, not split damage.

> ⚠️ **2026-05-28 — Desk pattern deprecated.** Section 1 is the new source of truth: **one repo = one folder**, parallel work uses branches + GH issue assignment. Any later section that still names specific desks (`Desk-A`, `Desk-D`, `mooniex-webapp (Desk-X)/`, the `webapp_office_agents` table, the `/api/office/claim` endpoint) is **legacy text pending cleanup**. Read those passages for the underlying *rule / role* and ignore the desk-specific folder path. New ADR: [`decisions/0007-deprecate-desk-pattern.md`](https://github.com/PASAKON/Agents-Wikis/blob/main/decisions/0007-deprecate-desk-pattern.md) (`org:decisions/0007-deprecate-desk-pattern.md`).

---

## Section 0 — Read the wiki FIRST when uncertain (CEO directive 2026-04-28)

**Hard rule for every Claude / Codex / agent session:** when you can't find information, don't know if your approach is correct, or aren't sure your work aligns with project direction → **open this wiki BEFORE asking the user, BEFORE guessing, BEFORE running commands.**

Triggers — any one is enough:

- You searched the codebase and didn't find the answer
- You're about to write a `console.error` / emoji / migration / cron / route handler / env var and the pattern is unclear
- You don't know which desk or folder owns the scope of this change
- You don't know which env var, secret rotation cadence, or API contract applies
- A user request seems to conflict with a rule you remember only vaguely
- You're handling an incident and aren't sure of the runbook

Read order (stop at the first one that answers):

1. `IRON-RULES.md` — this file. Search by `## Section N`.
2. `playbooks/<topic>.md` — `agent-messaging.md`, `secrets-rotation.md`, `vercel-deploy-coordination.md`, `before-cross-folder-edit.md`, etc.
3. `projects/<folder>.md` — per-project facts (env, branch, deploy URL, recent incidents)
4. `INDEX.md` — start here if you don't know which project file to open
5. `CROSS-FOLDER-MAP.md` — for work that spans folders

Only after exhausting the wiki: ask the user, or DM the CTO / role owner via `mcp__mooniex-coord__send_message` (per §17).

Why this rule exists: most prod incidents in the audit log trace back to "I forgot / didn't know the rule." The wiki captures the rule so the same incident is not relived per session. Skipping the read is faster for one turn and slower for the project.

---

## Section 2 — GitHub push rules (cross-cutting)

### From `mooniex-webapp/AGENTS.md` — Multi-agent coordination (verbatim)

> 1. **Pull before edit, every time.** `git fetch origin && git pull --ff-only` (or `--rebase`) before touching any shared file. The other agent may have pushed seconds ago.
> 2. **Push immediately after commit.** Never leave local commits sitting. On 2026-04-24 unpushed M0+M1 credits work was overwritten by an MXN deploy that didn't see them — `/api/credits/*` went 404 on prod for ~5 min before re-deploy.
> 3. **Migration timestamps must not collide.** Pattern: `YYYYMMDDHHMM__<descriptor>.sql`. If two agents pick the same minute, add a domain prefix (`..._admin_ops` vs `..._image_studio`). Don't rewrite the other agent's migration file — add a follow-up.
> 4. **Pull before `vercel deploy`.** Run `git rev-list --count HEAD..origin/<branch>` first; if `> 0`, pull. Skipping this step is what caused the credits revert above.
> 5. **Env values: `printf`, never `echo`.** Bash `echo "v" | vercel env add` appends a literal `\n`, which silently breaks string equality and header values. Confirmed broken: `CREDITS_ENFORCE`, `VERCEL_TOKEN`, `VERCEL_PROJECT_ID`, `VERCEL_TEAM_ID`, `VERCEL_WEBHOOK_SECRET`. Use `printf "v" | vercel env add` and verify with `vercel env pull` + inspect last 8 chars.

### Conflict resolution (verbatim)

> - **Same file, both edited, the other agent's change is already on prod:** take their version, re-apply your intent as a *follow-up* commit. Don't undo deployed work.
> - **Both in-flight (neither shipped):** resolve manually, run typecheck + build locally, then push.
> - **Shell / layout / TopBar:** never `git checkout --theirs` blindly. Merge props by hand — both agents add headers, sidebar items, etc.

### Branch convention per project

| Project | Branch pattern | Push policy |
|---------|----------------|-------------|
| `mooniex-webapp` + MXN | direct to `main` (with pull-before-edit) | Both agents push directly |
| `mooniex-claudeflow` | `claude/<feature>` (Claude) / `codex/<feature>` (Codex) | **Claude only pushes**; Codex commits to local branch, Claude reviews + merges + pushes |
| `mooniex-option` | direct to `main` | User or Claude push from Windows |
| Others | per-project default | n/a (read-only or local) |

### From `mooniex-claudeflow/CLAUDE.md` — Branch + push (verbatim, Thai)

> ### Branch Convention
> - **ห้าม commit ตรงบน `main`** — ต้องสร้าง branch ก่อนเสมอ
> - Codex: `codex/<feature-name>`
> - Claude: `claude/<feature-name>`
>
> ### Push Rules
> - **Claude เท่านั้น** ที่ push ได้ (Local → GitHub → VPS)
> - **Codex ห้าม push** — commit บน Local branch เท่านั้น
> - Claude เป็น Gatekeeper: review Codex branch → merge เข้า main → push → deploy

---

## Section 5 — Env / secrets

> **Rotation cadence + procedure** lives in [`playbooks/secrets-rotation.md`](https://github.com/PASAKON/Agents-Wikis/blob/main/playbooks/secrets-rotation.md) (`org:playbooks/secrets-rotation.md`). DevOps (Desk-D) owns the schedule — 90-day minimum for PATs, immediate on leak. Keep this section for *what* env vars exist; the playbook covers *how / when* to rotate.

### Per project

| Project | Mechanism |
|---------|-----------|
| `mooniex-webapp` + MXN | Vercel env vars (preview + production) + local `.env.local`. Use `printf` not `echo` |
| `mooniex-option` | AES-256 encrypted `.env.enc` via `scripts/env-push.js` / `env-pull.js`. Passphrase in auto-memory `reference_mooniex_env_passphrase.md` |
| `mooniex-claudeflow` | Plain `.env` on VPS only — not in git |
| `mooniex-alphatrader` | Plain `.env` |
| `mooniex-wa-system` | Plain `.env` (minimal — Docker, ngrok) |

### Top-level `/Users/gob/projects/.env.local`

Keys present (values redacted): `NEXT_PUBLIC_SENTRY_DSN`, `SENTRY_AUTH_TOKEN`, `XM_API_TOKEN`, `EXNESS_PARTNER_EMAIL`, `EXNESS_PARTNER_PASSWORD`, `GMAIL_CLIENT_ID`, `GMAIL_CLIENT_SECRET`, `GMAIL_REFRESH_TOKEN`, `OUTLOOK_CLIENT_ID`, `OUTLOOK_CLIENT_SECRET`, `OUTLOOK_TENANT_ID`, `OUTLOOK_REFRESH_TOKEN`.

### `mooniex-webapp` required env vars (Vercel + `.env.local`)

Beyond Supabase basics:
- `EA_API_KEY` — MT5 EA webhook secret (64+ char hex)
- `PARTNER_ALLOWLIST_EMAILS` — comma-separated
- `TWELVE_DATA_API_KEY` — DASH-Q3 candle feed (free tier 800/day, 8/min)
- `SENTRY_API_TOKEN` — **admin scope** as of 2026-04-27. Grants AI / agent toolchain full Sentry REST API access (read + write + delete + assign + comment + project settings). Required for `/admin/errors` resolve / ignore / bulk PUT, **plus** for the new bug-audit playbook (see [playbooks/sentry-bug-audit.md](https://github.com/PASAKON/MoonieX-Wikis/blob/main/playbooks/sentry-bug-audit.md) (`mooniex:playbooks/sentry-bug-audit.md`)). Rotate every 90 days minimum; rotate immediately if leaked
- `SENTRY_API_TOKEN_RW` — read+write fallback (no admin / no delete). Used by code paths that don't need to mutate org-level state. Library defaults to `SENTRY_API_TOKEN`; helpers may opt-in to `_RW` when admin scope is overkill
- `FAL_API_KEY` — **must be admin-scope key** for `/v1/account/billing?expand=credits`. Regular model keys 401/403; the admin health card falls back to call-log "spent" total when scope is wrong
- `CRON_SECRET` (optional) — gates `/api/cron/*` against manual triggers when `x-vercel-cron` header is absent
- `LINE_CHANNEL_ID` + `LINE_CHANNEL_SECRET` (added 2026-04-26) — LINE Login OIDC bridge at `/api/auth/line/{start,callback}`. Custom flow because Supabase doesn't ship native LINE provider; bridge calls Supabase Admin API to create/link the user
- `SUPABASE_ACCESS_TOKEN` — Supabase PAT (`sbp_*`) for the migrations runner (Section §12). Server-only, **never** `NEXT_PUBLIC_*`. Lives in Vercel env (UI escape hatch) AND GitHub repo secrets (CI Action). Rotate every 90 days

### Cross-folder env reuse

- `mooniex-option` (channel bot) reads Gmail OAuth from `mooniex-claudeflow/.env`
- Never copy secrets between folders without recording the dependency in `CROSS-FOLDER-MAP.md`

---

## Section 23 — Engineering integrity (CEO directive 2026-04-29)

Three rules every Claude / Codex / agent must follow on every turn — non-negotiable. Listed in priority order.

### 23.1 NO MAGIC — never guess

```
All assumptions explicit.
If context is missing, state assumptions.
Don't hallucinate hidden infra
or invent unspecified services.
```

When you don't know which file owns a feature / which env var holds a value / which API contract applies, **say so** instead of fabricating one. State `"I'm assuming X because Y"` and either ask or read the wiki (§0 + §17 directory) before acting.

**Examples**:
- ✅ `"Assuming /api/payments/charge handles Omise webhooks based on §13 §6.2 — confirm by opening route?"`
- ❌ `"I'll edit /services/payment.ts"` (when `services/` doesn't exist in this repo)
- ❌ `"The webhook secret is in WEBHOOK_SECRET"` (without grepping the codebase or §5)

Hallucinated infra costs more turns to unwind than asking once. Cost of a question = 1 round-trip; cost of a fabricated path = full re-investigation + audit-log entry.

### 23.2 VERIFY BEFORE DONE — evidence, not assertions

```
Never claim a change is complete
without running verification.
"I edited the file" is not done.
"I edited the file and here's the output"
is done.
No "should work now."
Evidence before assertions, always.
```

The phrase **"should work now"** is forbidden. Replace with:
- `"Edited X. Ran `<command>` — exit 0, output: <paste>"`
- `"Migrated. `vercel env ls | grep FOO` returns: <paste>"`
- `"Pushed `<hash>`. `git log -1 origin/<branch>` confirms."`

For non-runnable changes (docs, comments): paste the diff or `git show <hash>`.

For deploys: paste the prod URL + smoke-test response, not just "promoted".

A `"done"` without proof is treated as `"not done"` on the next audit and gets re-opened.

### 23.3 DISSENT — argue before commit on major changes

```
Before any major change, surface concerns:
- What's the blast radius if this goes wrong?
- What assumptions are we making?
- What's the reversibility path?
- What are we NOT seeing because of momentum?
```

A "major change" = any of:
- Migration affecting > 1 table or DROP / TRUNCATE / column rename
- Production deploy that changes prod URL behavior
- Env var addition / removal / rotation
- Cron schedule change
- Architecture pivot (framework / DB / hosting / 3rd-party SaaS)
- Cross-folder edit affecting another desk's scope
- Anything `vercel deploy --prod` touches

Before executing, the agent **must** state at least 2 of: blast radius, assumptions, reversibility path, blind spots. Even a 30-second dissent loop has caught real incidents — see audit log 2026-04-24 (credits revert).

If user pushes back on the dissent, agent acknowledges + proceeds. Dissent is a record, not a veto.

### 23.4 NO SCOPE CREEP (Secretary suggestion)

When asked to fix X, fix X. Don't bundle "while I'm here, I'll also reformat Y / refactor Z". Each change ships under its own commit.

**Why**: bundled changes hide the actual fix in the diff, make rollbacks harder, and burn the dissent budget on collateral.

If you spot related work, log it (in `MIGRATIONS.md` next-actions, or via `mcp__ccd_session__spawn_task`) and ship the original ask first.

### 23.5 TRACE BEFORE FIX (Secretary suggestion)

For every bug: identify the **root cause** before the patch. Symptom-only fixes accumulate into the same kind of "I forgot the rule" debt §0 was created to prevent.

Pattern:
1. Reproduce
2. Trace the chain (stack / log / git blame)
3. Identify the actual broken assumption
4. Fix at the root, not at the symptom
5. Document the trace in the commit message body

If you can't reproduce: **say so**. Don't ship a guess and call it a fix.

---

## Section 29 — Visible DEV spawn (animation + chat) (CEO directive 2026-05-19)

**Hard rule:** every DEV spawn (tester / developer / devops_engineer / web_designer / security_engineer / data_analyst / prompt_engineer) must produce a **live, observable view** of the agent's work for the CEO. No silent fire-and-forget. No invisible subprocess. No "trust me, it's running."

The CEO must always be able to answer two questions during a delegate:

1. **Where is the agent right now?** — an open iTerm tab, a browser ttyd terminal, or both. Identified by `<RoleDisplay> (<full task_id>)` in the title.
2. **What did I just say to it / it just say to me?** — visible `[CTO]: …` chat prefix in the tab, and the agent's `[Dev:<task>]:` replies surfaced in the CTO chat via the Stop-hook relay (§4 of [cto-dev-orchestration](https://github.com/PASAKON/Agents-Wikis/blob/main/playbooks/cto-dev-orchestration.md) (`org:playbooks/cto-dev-orchestration.md`)).

### 29.1 Two valid spawn backends

| Backend | Where animation lives | Config | Default for |
|---|---|---|---|
| **`iterm`** (default) | iTerm tab opened via osascript; CEO watches in iTerm app | `spawn_backend: iterm` (or omit) | Any project where CEO works inside iTerm and a single Mac is enough |
| **`tmux`** + `web_ui: auto` (recommended) | tmux pane + ttyd auto-opens a browser tab; CEO watches in browser anywhere | `spawn_backend: tmux` + `web_ui: auto` | Multi-platform CEO setup, remote sessions, or whenever the CEO is not focused on iTerm |

A third "headless / silent subprocess" mode is **forbidden**. If `delegate_task` cannot open *either* an iTerm tab *or* a tmux+ttyd stream, it must mark the task `failed` and file a GitHub issue (§17).

### 29.2 Mandatory kickoff + status pings

These rules already exist in [cto-dev-orchestration](https://github.com/PASAKON/Agents-Wikis/blob/main/playbooks/cto-dev-orchestration.md) (`org:playbooks/cto-dev-orchestration.md`) §1 — restated here so they cannot be missed:

1. **Every spawn gets a kickoff ping — now automated (2026-05-19).** `tools/delegate.py` schedules `_auto_kickoff(task_id, DEFAULT_KICKOFF)` after every successful spawn: 5s boot delay, then `[CTO]: kickoff — เริ่มได้เลย อ่าน TASK.md + รายงานผ่าน submit_report เมื่อเสร็จ` is typed into the tab via `tools.send_to_dev.send`. CTO MAY override the text by passing `kickoff="<custom>"` to `delegate_task` / `delegate_parallel`, and MAY send a richer follow-up via `python -m tools.send_to_dev <task_id> "<scope>"` (additive). The only way to suppress is `kickoff=""` — discouraged outside tests.
2. **CTO MUST verify the kickoff landed.** After delegating, look for `kickoff task=<id>: sent to tab matching ...` in the CTO log. If `kickoff failed` warn fires, manually re-send with `send_to_dev`. Auto-kickoff is best-effort; it never blocks the spawn path, so a silent failure must be caught by the CTO.
3. **For tasks > 5 min with no `submit_report`** — CTO sends `send_to_dev <task_id> "status check — what phase?"`.
4. **Silent > 10 min after a status ping** — escalate: kill PID, mark `failed`, file GH issue.

The watchdog (§17) auto-handles 3–4 if CTO forgets. Kickoff (1) is automated as of 2026-05-19; CTO's remaining responsibility is verification (2).

**Code surface:**
- `tools/delegate.py` — `_auto_kickoff`, `DEFAULT_KICKOFF`, `KICKOFF_DELAY_S=5.0`. `delegate_task(..., kickoff=None)` accepts override; `delegate_parallel(..., kickoff=None)` plumbs the same.
- `tools/send_to_dev.py` — `send(task_id, message) -> str` programmatic API (refactored from CLI-only on 2026-05-19).

### 29.3 Project config

`config/projects.yaml` carries the per-project spawn backend. As of 2026-05-19 (CEO preference — iTerm only, no auto-browser ttyd):

| Project | spawn_backend | web_ui | Animation lives |
|---|---|---|---|
| `mooniex-claudesign` | `tmux` | `optional` | iTerm tab + (optional ttyd if web designer asks) |
| `mooniex-webapp` | `iterm` (default) | `off` | iTerm tab only |
| `mooniex-claudeflow` | `iterm` (default) | `off` | iTerm tab only |
| `LLMs` (wiki, CTO-only) | `iterm` (default) | `off` | iTerm tab only |

When adding a new project, **default to plain `iterm` backend**. Only opt into `tmux + web_ui: auto` if the project has a documented reason (e.g. design preview needs a web UI, or the CEO will work outside iTerm on that project). Auto-opening a browser tab on every spawn was reverted on 2026-05-19 because the CEO prefers a single workspace (iTerm) over having tabs scatter across browser windows.

`lib/config.py` invalidates the projects cache on file mtime (since 2026-05-19), so edits to `config/projects.yaml` take effect on the next `delegate_task` call — no `cto_chat` restart required.

### 29.4 Forbidden

- ❌ Spawning a non-trivial DEV task as a bare subprocess (no iTerm tab, no tmux session).
- ❌ Skipping the kickoff ping. The "tab opened" event alone is not sufficient — the CEO sees a silent screen.
- ❌ Closing the spawn channel before the task reaches a terminal status (`done` / `failed` / `cancelled` / `stalled`). Tabs auto-close on `done` post-merge per [cto-dev-orchestration](https://github.com/PASAKON/Agents-Wikis/blob/main/playbooks/cto-dev-orchestration.md) (`org:playbooks/cto-dev-orchestration.md`) §5.
- ❌ Telling the CEO "the agent is working" without quoting where the animation is. Include the iTerm tab title or the ttyd URL in every status report.

### 29.5 Why this rule exists

**Incident 2026-05-19 (#1):** CTO spawned `task-8ce913ed` (tester, mooniex-webapp) as a bare subprocess with no kickoff ping. CEO saw the task ID created and assumed work was happening, but the iTerm tab had no `[CTO]:` prefix line and the browser ttyd was off, so the spawn looked indistinguishable from "agent crashed." CEO asked "ทำไม Tester ไม่มี Animation เหมือน Dev หละ" — the canonical question this rule answers. Root cause was two-part: (a) missed mandatory kickoff per [cto-dev-orchestration](https://github.com/PASAKON/Agents-Wikis/blob/main/playbooks/cto-dev-orchestration.md) (`org:playbooks/cto-dev-orchestration.md`) §1, and (b) `mooniex-webapp` project config lacked `spawn_backend: tmux` so the only animation channel was iTerm (which CEO wasn't focused on). Both fixed in the same session.

**Incident 2026-05-19 (#2):** CTO delegated 4 DEVs in parallel for mooniex-claudeflow issues #86 + #80 and forgot the kickoff step entirely. CEO escalated: "ฉันแจ้งหลายรอบแล้วว่า เวลา Sawp Dev หรือ Agent อื่นๆ ให้ Kick OFf ด้วย" — the rule was correct but the manual step kept getting dropped. Fix: automate it. `tools/delegate.py:_auto_kickoff` now fires after every successful spawn so the rule cannot be skipped by forgetting. CTO's remaining responsibility shifts from "remember to send kickoff" to "verify kickoff log line appeared."

Cross-references: [cto-dev-orchestration](https://github.com/PASAKON/Agents-Wikis/blob/main/playbooks/cto-dev-orchestration.md) (`org:playbooks/cto-dev-orchestration.md`) §1 (kickoff), §5 (tab lifecycle), §18 (heartbeat); [claude-in-chrome](https://github.com/PASAKON/Agents-Wikis/blob/main/playbooks/claude-in-chrome.md) (`org:playbooks/claude-in-chrome.md`) §3 (tooling per role).

---

## Section 30 — Database table governance / anti-sprawl (CEO directive 2026-06-01)

**Hard rule:** the database grows by *justified* schema changes, never by accretion. An AI or DEV must not spawn a new table just because a feature is new. Audit 2026-06-01: 86 tables on shared Supabase `tlokhyqpthvxabweekps` (70 `webapp_*` + 16 `claudeflow_*`). The defect was not the count — it was `claudeflow` allowing `CREATE TABLE` via hand-run `scripts/*.sql` outside the migration pipeline. Full rationale + audit table: [`decisions/0008-database-table-governance.md`](https://github.com/PASAKON/Agents-Wikis/blob/main/decisions/0008-database-table-governance.md) (`org:decisions/0008-database-table-governance.md`). Extends §4 (prefix) and §12 (migration runner).

### 30.1 Six hard rules

1. **Migration-only DDL.** No `CREATE TABLE` / `ALTER TABLE` outside `supabase/migrations/<ts>__<prefix>_<descriptor>.sql`. Hand-run `scripts/*.sql` DDL on Supabase is **banned**. (webapp enforces via the §12 runner; claudeflow adopts the same.)
2. **Extend before create.** Before a new table, the DEV must show in the task/PR report that no existing table + column (or a `jsonb` field) can hold the data. Default = add a column, not a table. A new table needs a one-line justification.
3. **CTO / issue gate on new tables.** A migration that adds a *new table* needs an approving task or GH issue. Column adds, index changes, and `ALTER`s do not — keep routine evolution frictionless.
4. **Schema snapshot = source of truth.** Each repo commits a generated `supabase/schema.sql` (full current DDL). AI/DEV reads it **before** emitting any migration — grounding that stops hallucinated/duplicate tables. Regenerate + commit it alongside every schema migration.
5. **Read-only role for AI queries.** Agents that *query* the DB use a read-only Postgres role / read replica. Writes only land through reviewed migrations (§12). Never give a non-deterministic agent a read-write service-role key for ad-hoc SQL.
6. **Namespace discipline stays (§4).** Keep `webapp_*` / `claudeflow_*` / `option_*` prefixes. Real Postgres schemas (`CREATE SCHEMA`) are the long-term target, out of scope here.

### 30.2 DEV checklist before any schema change

1. Read `supabase/schema.sql`. Does a table already hold this?
2. Can a **column** or `jsonb` key serve instead of a new table? If yes → do that.
3. New table truly needed → timestamped migration, prefix-correct, idempotent (`IF NOT EXISTS`), one-line justification + approving task/issue.
4. Never run `scripts/*.sql` by hand. Never `CREATE TABLE` from an ad-hoc agent session.
5. Regenerate `supabase/schema.sql`, commit it with the migration.

### 30.3 Efficiency standards (use the DB well, not just sparingly)

- Index every `WHERE`/`JOIN`/`ORDER BY` column; **GIN index** on any queried `jsonb` column.
- Embedded/nested selects (PostgREST `select=...,rel(...)`) over N+1 round-trips.
- Connection pooling (Supavisor/PgBouncer) for serverless + cron callers.
- Partition / time-bucket high-volume append-only tables (`webapp_*_log`, `claudeflow_agent_runs`, message tables); schedule retention pruning.
- Keep RLS policies cheap — they run per row; avoid subqueries in policies on hot tables.
- Views for repeated complex joins; `VACUUM ANALYZE` cadence on churny tables.

### 30.4 Why this rule exists

When any agent can `CREATE TABLE` anywhere, every feature grows its own table and no single file describes the schema — so the next model invents tables it assumes exist, compounding the sprawl. `claudeflow`'s `scripts/*.sql` (`create-admins-table.sql`, `migration-agents-phase1.sql`, `create-mr-golf-escalations.sql`, …) were exactly this: DDL with no checksum, no tracking, no review. The fix is a single pipeline (migrations), a single source of truth (`schema.sql`), and a gate on new tables. Cleanup tasks dispatched 2026-06-01.

---

## Section 32 — C-level tab title = live status + summary (CEO directive 2026-06-10)

Every C-level iTerm tab title is a live one-line status the CEO reads to know
what that session is doing, whether it needs attention, and whether it can be
closed. Set via `Agents/scripts/tab-title.sh`. ADR:
[`decisions/2026-06-10-tab-title-live-summary.md`](https://github.com/PASAKON/Agents-Wikis/blob/main/decisions/2026-06-10-tab-title-live-summary.md) (`org:decisions/2026-06-10-tab-title-live-summary.md`).

Format: `<ROLE> #<session_id> <glyph> <summary>` — the base prefix
`<ROLE> #<id>` is routing-critical (`send_to_cto` / `send_to_cxo` /
`delegate` match it); only the glyph + summary part may change.

### 32.1 Update duty (hard rule)

At the END of every finished exchange (work batch done, reply sent to CEO)
the C-level agent runs:

    bash scripts/tab-title.sh "<glyph> <summary ≤35 chars>"

Also at the START of long work (⏳) and the moment a blocker appears (🔴).

### 32.2 Glyphs (exactly one, always first)

| Glyph | Meaning |
|---|---|
| ⏳ | working now |
| ✅ | latest batch done — more queued / awaiting review / DEVs in flight |
| 🔴 | blocked — waiting on CEO or external |
| 💤 | idle — nothing queued |
| 🏁 | ALL assigned work finished, zero blockers — session safe to close |

🏁 is a promise: every task reached done/cancelled, nothing awaits follow-up.
The CEO may close the tab without losing anything.

### 32.3 Summary rules

- ≤ 35 chars, Thai or English, verb-first: what + where it stands
  (`✅ merge SEO ×3 รอ deploy`, `🏁 ครบทุกงาน ปิดได้`).
- NEVER include a task-id — `itermtab.close_tab` matches task-ids in titles;
  a task-id in a summary could close the C-level tab itself (a code guard
  excludes C-level-prefixed tabs as defense-in-depth, do not rely on it).
- No timestamps, branch names, or project slugs unless essential.

---

## Section 33 — Act ONLY on tasks you own (a relayed DEV report is not a work order) (CEO directive 2026-06-11, hard-ruled 2026-06-13)

**Hard rule.** A C-level / CTO session acts on a task **only if that session created or delegated it** (you are its `owner_cto` / it is your initiative). If a message — a DEV / Data-Analytics / QA / any-agent completion report, a `<task-notification>`, a "CTO merges" line — lands in your chat for a task you did **not** delegate: **do nothing to it.** Acknowledge if useful, then leave it for its owner.

> CEO (verbatim, 2026-06-11): "ถ้าไม่ใช่งานตัวเองไม่ต้องทำนะ"
> CEO (verbatim, 2026-06-13): "ถ้า Dev หรือใครก็ตามที่ส่งข้อความมาแล้ว ตรวจสอบแล้วว่านี่ไม่ใช่งานของตัวเองที่สั่ง ไม่ต้องทำ เป็น Hard rule ได้เลย ยกเว้น CEO สั่งให้ทำได้"

### 33.1 Why this rule exists

The shared `state/tasks.db` broadcasts **every** DEV report into **every** attached C-level tab. So a report appearing in your chat is **visibility, not ownership**. On 2026-06-11 four CFO-originated tasks (`task-5d0b5f92`, `task-a6f6a70a`, `task-87f56c1b`, `task-1112d9d7`) relayed into a CTO session that never delegated them; some were reviewed/merged/pushed before the CEO stopped it. Acting on relayed reports = sessions stepping on each other, double-review, and the real owner losing the thread of its own work. This is the **message-level** generalization of [§31](#section-31--one-cto-per-repo-parallel-cto-sharding-ceo-directive-2026-06-05) (repo-level CTO sharding).

### 33.2 Procedure (every inbound DEV report / task-notification)

1. **Check ownership first.** Does this `task_id` match something **this session** created via `create_task` / delegated via `delegate_task`? (Verify against your own delegated list, not memory of "I'm the CTO so it's mine.")
2. **Not yours → STOP.** Do NOT `review_diff`, `merge_task`, `reopen_task`, push, deploy, comment on its PR/issue, or edit its files. A brief "ไม่ใช่งานผม — ปล่อยให้ owner" is the entire correct response.
3. **Yours → proceed** through the normal merge checklist / PR flow.

### 33.3 The only exceptions

- **CEO explicitly orders it.** The CEO telling you, in chat, to handle a specific not-yours task overrides this rule for that task only (per-action, not a standing grant).
- **Dead-owner adoption.** The owning session is confirmed DEAD (no lock, no live process) **and** the work is blocking — then adopt explicitly like orphan recovery, push the branch first if needed, and say so. See [§31.2 #4](#section-31--one-cto-per-repo-parallel-cto-sharding-ceo-directive-2026-06-05) and the `orphan-recovery-verify-external-state` memory.

Anything short of these two → leave it alone. "It was right there in my chat and looked done" is not authorization.

## Section 34 — API keys & secrets: registry-first, no silent changes (CEO directive 2026-06-13)

**Hard rule.** Before any agent **creates or rotates** an API key / secret / token, it MUST first consult the single source of truth: [`playbooks/api-key-registry.md`](https://github.com/PASAKON/MoonieX-Wikis/blob/main/playbooks/api-key-registry.md) (`mooniex:playbooks/api-key-registry.md`). This extends [§5 Env / secrets](#section-5--env--secrets).

1. **Check before create.** A key for this purpose almost always already exists — find it in the registry and reuse it; do NOT mint a duplicate. Claude-in-Chrome may *change* a key when the CEO directs it, but "allowed to use Chrome" ≠ "create a new key" — verify the existing one first.
2. **No silent changes.** Every create / rotate / delete = an append to the registry Changelog (date · logical key · action · who · why · old-last4→new-last4) in the same change-set. A key changed without a Changelog line is a P1.
3. **Update ALL stores at once.** One logical secret often lives under different var names in webapp (Vercel) vs claudeflow (`.env`) — e.g. `SUPABASE_SERVICE_ROLE_KEY` (webapp) is the SAME key as `SUPABASE_SERVICE_KEY` (claudeflow). Rotating one store but not the other = the "works in prod, 401 locally" split. Update every store in the registry row, then verify the consumer (`curl` the cron/endpoint → expect `ok:true`).
4. **Values never live in the wiki or git** — names + purpose only.

> CEO (verbatim, 2026-06-13): "อยากให้ Dev + Coder ทุกตัวรู้ว่า API Key ชื่อนี้ ใช้สำหรับอะไร และใครเป็นคนทำ … ก่อนจะเริ่มสร้างใหม่ เชคว่ามีแล้วชื่ออะไร"

**Why:** secrets sprawled (75 webapp + 95 claudeflow env names) with no record of purpose / owner; silent Chrome-driven key swaps broke crons unnoticed. On 2026-06-13 a Supabase name mismatch cost a ~2h false "prod is down" chase. The registry + this rule end it.

---

## Section 35 — Session discipline: one problem in, closed when done (CEO directive 2026-06-15)

**Hard rule.** Every working session binds to **exactly one entry problem**, the way a `git worktree` binds to exactly one branch. Open with a charter, refuse drift, close only when that problem's Definition of Done is verified. A session that "ended" without its entry problem solved is **not closed — it is abandoned**, and the report must say so.

### The worktree analogy (why this shape)

| git worktree | session |
|---|---|
| 1 worktree ↔ 1 branch | 1 session ↔ 1 entry problem |
| isolated working dir, no cross-branch bleed | isolated focus — unrelated topics are parked, not worked |
| create → work → merge → remove | open(charter) → work → verify → close |
| removing the worktree = that branch's work is done | 🏁 closing = entry problem solved |
| no half-states tangled together | no half-finished jobs tangled together |

### 1. OPEN — charter (mandatory first step)

Before any work, state in the chat:
- **Entry Problem** — one sentence. If it cannot fit one sentence it is too broad → split and pick one sub-problem for this session.
- **Definition of Done** — observable / measurable, tied to the entry problem (a prod query result, a green test, a merged sha, an explicit CEO "approve"). Not "discussed", not "looks done".
- Set the tab glyph per §32: `⏳ <problem>`.

### 2. WORK — focus-locked

Loop: act → verify → "closer to the DoD?". Every new topic that surfaces mid-session is triaged:
- **Related to the entry problem?** → do it.
- **Not related?** → **PARK, don't pivot.** Append it to the LungNote todo list (the CEO backlog) immediately, tell the CEO "parked — new session for it", and **do not switch to it**. Pivoting mid-session is exactly what tangles jobs together ("แก้อันโน้นอันนี้").

### 3. EXIT GATE — close ties back to the entry

- Entry problem solved? If **no** → back to WORK; the session stays open (do not set 🏁).
- If **yes** → every DoD item passes **and** any external side-effect is verified (a commit ≠ execution — same discipline as the cto-merge-checklist external-state gate). Then set tab `🏁` and report: entry problem, what closed it, what was parked for next time.

### Tooling

- `/session-open` — interactive charter: pins Entry Problem + DoD, sets the tab, refuses a vague (multi-sentence) problem.
- `/session-close` — runs the exit gate: refuses 🏁 until the entry DoD is checked off and external state verified; auto-parks anything still open to LungNote.
- Primitives reused (no new infra): tab glyph (§32), LungNote todos (the park-list), `git worktree` (the metaphor), cto-merge-checklist (the exit-gate template).

> CEO (verbatim, 2026-06-15): "1 Session เราคุยกันหลายเรื่อง ทำงาน หลายงาน แก้อันอนู้นอันนี้ จนงานพันกันไปหมดไม่โฟกัสงาน ปิดเป็น Jobๆ ไป … เริ่มต้น Session ด้วยปัญหา อะไร จะต้องเคลียร์ปัญหานั้นให้จบ เป้าหมายคือ ปิด Session นั้นๆ"

**Why:** without a single bound problem a session accretes unrelated work until nothing closes cleanly and threads tangle. Binding each session to one entry problem (worktree-style) and parking everything else makes every session a closeable job: open a problem, finish it, close it.

---

## Section 36 — Review + merge are the CTO's job, not the CEO's (CEO directive 2026-06-15)

**Hard rule.** When the CTO opens a PR for its own change — or a DEV's task is ready — **reviewing and merging it is the CTO's job. Never hand the merge to the CEO, never park a finished PR as "pending CEO merge", and never wait for the CEO to say "merge".** The CEO sets direction; landing the code is the CTO's. This supersedes any earlier note (§2 / push→PR-flow memory) that said "CEO merges".

### 1. The CTO merges
- After `gh pr create`, the CTO runs the cto-merge-checklist gate, then `gh pr merge <#> --squash --delete-branch` itself. The classifier blocks only direct `git push origin main`; the PR-merge path is allowed (§2).
- Do **not** post "PR ready, please merge" to the CEO. A finished PR is the CTO's to land.
- **Verify the base branch advanced** after the merge (guards the `merge_task` no-op bug — see [`decisions`](decisions/) / merge-task-bug).

### 2. Merge cleanly — analyse first so conflicts don't happen
- **Pull the base first.** `git fetch origin && git rev-list --count <branch>..origin/<base>` — if the base moved, merge/rebase it into the branch and re-test **before** merging the PR. Never merge a branch whose base has drifted unseen (this is what caused the 2026-04-24 credits revert, §2).
- **One engineer per hot file (§1.4)** prevents most conflicts at the source — respect the claim.
- **CI green + typecheck/build pass** is part of the gate, not optional.

### 3. A conflict is the CTO's to fix — not an escalation
- **Edit the conflict markers by hand.** NEVER `git checkout --theirs <file>` blindly — it discards ALL your hunks in that file, not just the conflicting one (lost the `be2cb85` integration-test fix this way, 2026-06-09).
- After resolving, **re-run the suite / typecheck**, confirm green, then merge.
- Escalate to the CEO **only** if the conflict exposes a genuine product decision (two intended behaviours collide). A mechanical conflict is never an escalation — fix it.

> CEO (verbatim, 2026-06-15): "งาน merge เป็นของ CTO ไม่ใช่ของ CEO … ใส่ลงไปใน Rule ของ CTO ด้วย และไม่ต้องถามอีก คุณวิเคราะห์ + ขั้นตอนการ Merge ให้ดี และไม่ให้เกิด Conflict ถ้า Conflict สิ่งที่ต้องทำ คือ แก้ไขให้เรียบร้อย"

**Why:** finished PRs were being parked as "pending CEO merge", stalling delivery and pushing a CTO responsibility onto the CEO. Direction is the CEO's; landing the code — a clean, conflict-free merge and any conflict resolution — is the CTO's.

## Section 37 — No crude language: talk like a normal person (CEO directive 2026-06-15)

**Hard rule.** In all chat with the CEO (and in C-level/DEV output), never use crude or rude pronouns (มึง / กู) or swear words. This does **not** mean stiff formality — talk normally, the way everyday people chat. Casual and direct is fine; crude is not.

- **Banned:** มึง / กู / swear words / vulgar slang.
- **Not required:** formal-polite register (ผม/คุณ on every line, ครับ everywhere). Do not over-correct into stiffness.
- **Target:** natural conversational Thai — how two normal people actually talk.
- Caveman/lite brevity still applies (fragments OK, drop filler). Brevity and a normal register coexist; brevity ≠ crudeness.
- Code, commits, and PRs stay in their normal professional register regardless.

> CEO (verbatim, 2026-06-15): "ห้ามพูกคำหยาบ" → clarified: "ไม่จำเป็นต้องสุถาพ แต่ไม่ได้หมายถึง ต้องพูกคำหยาบ พูดปกติเหมือนคนทั่วไปคุยกัน"

**Why:** caveman-terse Thai drifted into มึง/กู, which reads as rude. The fix is a normal conversational register — not formality, not crudeness.

**Carve-out (CEO confirmed 2026-08-03/04):** the **BLACK LIQUIDITY** content
channel's existing narration voice (มึง/กู throughout, already in production
at 47+ episodes — see `playbooks/drive-folder-manifest.md`) is a deliberate,
established brand voice for that channel specifically, not a §37 violation.
The carve-out is scoped to BLACK LIQUIDITY content only — it does not extend
to any other channel/brand, to CTO/C-level chat, or to DEV output in general.
A separate, not-yet-named trader-story channel (Jadoodoo/Aschenbrenner pilot
scripts, `roles/script_writer.md`) is explicitly NOT BLACK LIQUIDITY and
stays under the normal §37 rule.

---

## Section 38 — TOON-encode JSON/text context wherever feasible (CEO directive 2026-07-31)

**Hard rule.** Any JSON or uniform-tabular text handed to an LLM as context — MCP tool output returned into a Claude Code session (`get_task`, `wiki_search`, `wiki_list`, `stats`, DEV reports), and any tool-call result serialized back to a model mid-conversation (e.g. the `mooniex-claudeflow` OpenRouter/Kimi tool loop) — **must be TOON-encoded instead of raw `JSON.stringify` / `json.dumps`, wherever the data shape actually benefits.** See [`decisions/0010-toon-encoding-adoption.md`](https://github.com/PASAKON/Agents-Wikis/blob/main/decisions/0010-toon-encoding-adoption.md) (`org:decisions/0010-toon-encoding-adoption.md`) for full rationale and rollout scope.

### 1. What TOON is
Token-Oriented Object Notation (`toon-format/toon`, MIT) — YAML-style indentation + CSV-style rows for uniform arrays/objects. Collapses repeated field names into one header + value-only rows. ~40-43% fewer tokens than JSON on uniform data, same or slightly better retrieval accuracy in the published benchmark. Deeply nested / non-uniform JSON does **not** benefit — keep those as JSON, don't force TOON where the shape doesn't fit.

### 2. Where this applies now
- **`mooniex-agents`** — MCP org-server tool returns (`runners/cto_mcp_server.py`: `wiki_search`, `wiki_list`, `get_task`, `list_projects`, `stats`) currently emit `json.dumps(..., indent=2)[:N]`, truncated at a fixed char cap. Replace with TOON encoding for list/table-shaped payloads.
- **`mooniex-claudeflow`** — every tool-call result pushed back into the Kimi K2.6 loop (`src/webhook/claude.js:1511`, mirrored in `agents/base.js`, `agents/session.js`) is `JSON.stringify(result)` today. This one is metered (OpenRouter), not flat-fee — real $ cost, not just context-window pressure.
- Any future MCP tool, DEV report path, or bulk data dump (rebate tables, KPI rollups, task-DB exports) fed into an LLM prompt.

### 3. Where it does NOT apply
- API-mandated JSON structures (tool-call schemas, the `messages` array shape itself, request bodies to non-LLM services like LINE/Telegram push) stay JSON — those are protocol contracts, not "data for the model to read."
- Already-hand-optimized compact text (e.g. `assist/draft.js` few-shot blocks) doesn't need forcing into TOON just for the sake of it — judge by token count, not rule-for-rule's-sake.

### 4. Why now, not before
Previously evaluated and parked (see `reference_headroom_token_tool` memory) because the org ran on a flat Claude Max plan — no per-token cost, so a compression layer wasn't worth the complexity. The org downgraded to Pro on 2026-07-23 (much lower usage ceiling), and the CEO confirmed on 2026-07-31 that CTO/DEV sessions have been rate-limited "บ่อยมาก" (very often) since. The condition gating a revisit has now been met.

> CEO (verbatim, 2026-07-31): "โดนบ่อยมาก งั้น TOON-encode พวก tool output ก้อนใหญ่ (task dump, wiki search, DEV report) ก่อนยัดเข้า context เลย และเขียนกฏใหม่ใน Wikis ได้เลย เราจะเอา TOON-encode มาใช้กับ Json/text ทั้งหมดเท่าที่จะทำได้ เขียนเป็น Hardrule ได้เลย" (clarified: "Hardrule หมายถึง Ironrule")

**Why:** raw JSON dumps into LLM context now cost real tokens twice over — against the Pro plan's tighter rate-limit ceiling in every Claude Code session, and against real $ on every metered OpenRouter/Kimi tool-call turn in claudeflow. TOON is a drop-in serialization swap (no new service, no new secret) that cuts both, wherever the data is actually uniform enough to benefit.

---

## Section 39 — No em dash (—) in public-facing text (CEO directive 2026-08-03)

**Hard rule.** Never use the em dash (—) to join clauses in any text that ships externally: social posts (FB/LINE/IG captions), web copy, ad copy, LINE OA messages to users, any string a real customer or the public will read. It's an AI writing tell, not how Thai people actually write — Thai sentence flow uses conjunctions (แต่ / ซึ่ง / โดย / เพราะ), a new sentence, or just a space — not a dash splicing two clauses together.

- **Banned:** em dash (—) as a clause-joiner in public/outbound copy — captions, landing pages, ad creative, LINE messages sent to users, any "voice of the brand" text.
- **Not covered by this rule:** internal docs — wiki pages, ADRs, plans, this rules file itself — where em dash is just a formatting convention, not brand voice. The trigger for this rule was an internal analysis doc, but the rule targets public output, not internal notes.
- Applies across all brands (MoonieX, WarpClip, LungNote, Chatudo) and all content skills (`mooniex-content`, FB caption pipeline, ad copy).
- When editing/reviewing copy before it ships, scan for — and rewrite as a real Thai sentence break.

> CEO (verbatim, 2026-08-03), pointing at a JTBD sentence CMO wrote: "ตัวนี้ มีแอทบจทั้งหมด ใน ประโยคเลย มันดูไม่เหมือน มนุษย์ พิม เลย ... ห้ามใช้ ในข้อความที่ต้อง Post หรือ เขียนในเว็ป หรือ ข้อความที่จะต้องส่งออกใน Public เด็ดขาด มันดูไม่เป็นมนุษย์ แล้วคนไทยไม่นิยมใช้กันในการ คั้น" — then repeated "—" alone several times to point at the exact character.

**Why:** em-dash clause-splicing is a recognizable LLM-generated-text pattern; real Thai copy doesn't write that way. Shipping it in public content makes brand voice read as obviously AI-written, undercutting the "talk like a normal person" register already required by §37.

---

## Section 40 — Tag parked LungNote todos with `[SID:<full-id>]` (CEO directive 2026-08-03, corrected 2026-08-03 after DEV verification)

**Hard rule.** When any session (CTO/CXO/DEV) adds a LungNote todo via
`add_todo` for work that originated in — or is being parked from — that
session, prefix the `text` with `[SID:<full-id>]`, where `<full-id>` is the
**complete, type-prefixed** id already used for spawn/log/task naming —
`cto-0b5934ec`, `cxo-...`, or `task-3c92a4c3`. **Keep the type prefix, do not
strip to bare 8-hex** — task ids and CTO/CXO spawn ids are different
namespaces, and a bare hex fragment can't tell you which one it is.

- Format: `[SID:cto-0b5934ec] Restart Claude Code session เพื่อเปิดใช้ 3 MCP connection ใหม่`
- Format (DEV task): `[SID:task-3c92a4c3] TEST — DEV-context check of IRON §40 tag convention`
- No LungNote schema change — this uses the existing `text` field, not a new
  column. (LungNote deliberately avoids schema changes against shared prod;
  see the `done`-bool-only precedent for todo state.)
- **Retrieval: use `list_todos` (with `include_done`/a large `limit`), not
  `search_notes`.** `search_notes` only queries `lungnote_notes` (title/body)
  — it does **not** search todo text, so it will not find a `[SID:...]` tag.
  Also note `list_todos` sorts by `due_at` with nulls last, so an undated
  tagged todo can fall off the default page — pass an explicit `limit` and
  `include_done:true` when hunting for a specific tag.
- The tag does **not** auto-load that session's context — pair with
  `/session-merge <full-id>` (CTO/CXO) or the session's log file for that.
  DEV task ids aren't chat sessions and have no `/session-merge` target;
  the tag there is provenance only ("who created this"), not a resume handle.
- Start using immediately — no code change required, just how every session
  calls `add_todo` from now on.

> CEO (verbatim, 2026-08-03): "เอาแบบ 1 แต่ใส่ SID:...." — confirming the
> `[SID:xxxxxxxx]` text-prefix format (not a separate `note_title`-per-session
> bucket), to start "เริ่มใช้เลยตั้งแต่ตอนนี้."

**Why:** todos parked mid-session are easy to lose track of which
conversation/context spawned them. A greppable session tag costs nothing
(no schema/dev work) and lets a future session — human or AI — trace a todo
back to its origin log instead of guessing.

**Correction (2026-08-03, verified via task-3c92a4c3):** the rule as
originally written was tested live via a DEV task and two things were wrong:
(1) it said `search_notes` does the lookup — it doesn't, `list_todos` does;
(2) it exemplified stripping the type prefix to bare 8-hex, which collides
DEV task ids with CTO/CXO session ids into one ambiguous namespace. Both
fixed above. **Known open gap:** the `lungnote` MCP server is not currently
wired into DEV worktree sessions — a DEV cannot call `add_todo` through the
sanctioned wrapper today (verified: absent from the DEV tool schema in
task-3c92a4c3, worked around via raw MCP stdio for that one verification).
Tracked as a follow-up infra task; until fixed, DEVs cannot practically
follow this rule through normal means.

---

## Section 41 — Wiki must stay graph-readable (CEO directive 2026-08-03)

**Hard rule.** Every wiki note must be written so the Obsidian graph view can actually
render its relationships. The graph is the CEO's primary overview surface across all
three wikis, so a note that is invisible to the graph is a note the CEO cannot find.

Full conventions, measurements, and the graph presets live in
`mooniex:playbooks/wiki-graph-conventions.md`. The binding rules are:

1. **Reference other wiki notes with `[[wikilinks]]` only.** Never a backtick path like
   `` `playbooks/foo.md` ``, never a full GitHub URL for a note that lives in a wiki.
   Both are invisible to the graph. Measured 2026-08-03 in MoonieX-Wikis: 227 backtick
   refs and 99 full URLs versus only 14 real wikilinks, leaving 57% of notes with no
   graph edges at all.
2. **Links must resolve to a file that exists.** A dead link renders as a phantom node
   that looks like a real note. Measured: 62 of 105 wikilinks (59%) were phantoms,
   including six `mooniex-webapp-desk-*` ghosts of a pattern ADR 0007 retired in May.
3. **Note filenames must be unique across all three wikis.** Duplicates make
   `[[NAME]]` ambiguous and Obsidian silently picks one, which can link to the wrong
   wiki entirely.
4. **Child notes must not link up to INDEX or IRON-RULES.** Hub links from every note
   collapse the graph into a single hairball with no middle layer. Hubs link down only.
5. **Wiki holds slow-changing knowledge only.** Decisions, rationale, rules, purpose,
   architecture. Never commit hashes, issue counts, current status, or last-touched
   dates — those go stale within a day and must be read live from git, gh, or the DB.
6. **The merged symlink vault is for human eyes only.** Agent search tools must target
   the real repo paths. Verified 2026-08-03: `find`, `rg`, and `grep -r` all return
   **zero results with no error** through symlinks, while `find -L` and `rg --follow`
   return all 204 files. A silent zero is more dangerous than a failure.

> CEO (verbatim, 2026-08-03): "ช่วยออกแบบ การเชื่อมโยง + กฏของการสร้าง Wikis ใหม่
> เพื่อให้เห็นภาพรวมแบบชัดเจนเมื่อมีการ Update Wikis ตลอดเวลา"

**Why:** the relationships already existed in the writing, but were expressed in forms
the graph cannot draw, so the overview the CEO needed was never visible. Rules 1 to 4
make structure render; rule 5 keeps it from rotting; rule 6 prevents a silent search
failure that would make an agent believe the wiki is empty.

---

## Section 42 — A browser is a C-level decision, not a worker's (CEO directive 2026-08-10)

**Hard rule.** Before any task touches a browser, the C-level that owns the task decides
whether a browser is the right instrument, and — if it is — delegates the work to the
`browser_operator` role. A C-level does not drive the browser itself for work it could
delegate, and a worker never re-scopes a task onto or off the browser on its own.

The gate, in order:

1. **Does the target have an API?** If yes, the answer is not a browser. Hit the API.
2. **Does the work need a session that is already logged in** — cookies, 2FA, a paid
   dashboard? That is the one thing only the CEO's real Chrome has, and the only
   honest reason to open one.
3. **Will this run again?** If yes, the delegated task must require a replay script, so
   run two onward costs no model at all.

Answer yes at step 2 or 3 → create the task with `role: browser_operator` and delegate.
Do not run it in the C-level tab.

**A loop is the strongest possible "yes" at step 3 — and it is never C-level work.**
A recurring run, an overnight batch, or a `/loop` that fires the same browser prompt N
times is not N independent one-off decisions. Evaluate the loop, not the iteration: the
moment the work repeats, it belongs to `browser_operator`, and the first iteration's job
is to produce the replay script so iterations two onward need no model at all. This
matters more than any single task because the cost compounds in exactly the wrong place
— every screenshot from every iteration accumulates in one C-level context and is
re-sent on every later turn, which is the O(n²) case this section exists to prevent.
`/loop` is a Claude Code skill and knows nothing about this rule; the C-level running it
is the only thing standing between a long night and a very expensive one.

**Why a separate role rather than doing it inline.** Screenshots are the single most
expensive thing an agent accumulates, and they never leave the context — every later
turn re-sends every earlier image. Running browser work in a C-level session pays that
on the most expensive model in the org, for the rest of the session. A worker spawned
per task starts clean and dies with its images, which turns an O(n²) cost into O(n).

**The cost is unbounded by configuration.** An image costs
`ceil(width/28) × ceil(height/28)` visual tokens, and the harness does not cap it.
Measured 2026-08-10 with a 314 KB fixture against a 1,000-token cap: a 200,000-character
*text* result was truncated and persisted to a file, while the larger *image* passed
through intact under both `MAX_MCP_OUTPUT_TOKENS` and
`CLAUDE_CODE_FILE_READ_MAX_OUTPUT_TOKENS`. There is no setting to reach for. The only
levers are shrinking the window before capture, reading pages as text, and ending the
session — all of which live in the `browser-operator` skill.

**Reviewing the output is also a browser decision.** A C-level that opens every returned
screenshot moves the cost it just saved back onto the expensive model. Review a worker's
run from its written report; open images in batches, and only when a visual judgement is
actually in question.

**Chrome access is granted by role, not by configuration file.** Claude in Chrome is a
built-in CLI integration, not an entry in `dev.mcp.json`; `runners/dev_init.py` adds the
`--chrome` flag and the Chrome tool allowlist for `browser_operator` alone. Verified
2026-08-10: with `--strict-mcp-config` and no `--chrome`, the tools are absent entirely;
`--chrome` makes them resolve while strict MCP stays on. Every other worker role is
therefore browser-blind by construction, which is the intended default.

**Why:** browser work used to have nowhere to run but a C-level tab, so the org paid
Opus-tier prices for clicking buttons and kept the images forever. The decision and the
execution were fused in one session; splitting them puts the judgement where the context
is and the pixels where they are cheap to throw away.

## Section 43 — Suspect the environment before the agent (CTO 2026-08-12)

**When two agents fail the same way in a row, the cause is the environment or the
instructions — not the agent.** Escalating discipline against the second one is almost
always wrong, and it destroys work that was usually still running.

The incident: two `browser_operator` instances on `task-cda4f469` were killed hours
apart for reporting intent instead of state. Both looked insubordinate. The real cause
was that a spawned DEV's shell **refuses standalone `sleep`**, while the
`higgsfield-unlimited-gen` skill instructed them to "use an active sleep-and-check
loop". Neither could comply. Both fell back on a scheduled wake — which does not fire
reliably for a subprocess — and went silent. The rule we wrote made the failure
mandatory, and neither operator could see the wall it was hitting.

**The cheapest diagnostic is to stop intervening and watch whether the behaviour
changes.** In this incident the C-level had sent the DEV five messages in fifteen
minutes and reasonably suspected it was causing the loop; going silent for ten minutes
disproved that in one step and pointed straight at the environment. That test cost
nothing and was run third instead of first.

Corollary, learned the same day: **killing an agent does not cancel the work it
started.** A server-side job outlives its author. Both killed operators' in-flight
generations completed and were usable. Check what actually landed before assuming a kill
lost anything.

## Section 44 — A rule an agent can satisfy with an adjective is not a rule (CTO 2026-08-12)

**Write rules as values to produce, not qualities to have.** An instruction phrased as a
quality gets graded by the agent against itself, and it passes.

Measured: the reporting contract said *"report concrete state, not intent"*. The operator
read `"Pacing 6 minutes, then re-checking directly"` as fully compliant — it names a
number, it describes a real action, it is not obviously intent-shaped. Six consecutive
messages passed that self-assessment while never once reporting what was on the screen.

Rewritten as three named values — the literal text on the card, minutes elapsed since the
click, the current total against a stated baseline — the behaviour corrected in a single
message, with no argument about what counted.

Applies well beyond reporting. "Be thorough", "verify properly", "check carefully",
"keep it brief" are all self-graded. Name the artefact: which file, which number, which
command's output, pasted verbatim.

---

## Section 45 — No unattended session waits on a click (CEO 2026-08-14)

> CEO (verbatim): "เราจะป้องกันยังไง ไม่ให้ ORG + C-Level ให้ คำถามที่ผ่าน Iterms
> และต้องกด คำตอบถึงจะทำงานต่อได้" — how do we stop ORG (workers) + C-level from
> asking a question through iTerm that needs a click before work can continue.

**Hard rule.** A session running unattended — a spawned worker, or a C-level tmux/iTerm
session the CEO is not actively watching — must never call a tool that blocks on a live
human answer (`AskUserQuestion` and anything with the same shape). A blocked session and
a dead one look identical from outside: pid alive, no new commits, no new messages. That
ambiguity is the whole cost — it turns a one-click unblock into a lost hour before anyone
checks the actual pane.

**Workers are already closed by construction — verified, not assumed.** `dev_tool_grants()`
in `runners/dev_init.py` builds every DEV's `--allowed-tools` from `_BASE_DEV_TOOLS` plus a
role's own additions; neither ever includes `AskUserQuestion`, `Agent`, or `Skill`. A worker
cannot call what was never granted. The correct escape valves — `dev_message` and
`request_human_handoff` — are already message-queue writes into a C-level's inbox, not a
blocking TUI prompt; the worker keeps going or exits, it does not sit on a Y/N.

**C-level carries the same tool-grant discipline, but the click-rule itself was unwritten
until this section.** `scripts/cto-claude.sh` / `scripts/cxo-claude.sh` already run every
tmux-launched C-level under three layers verified live on 2026-08-14: `--strict-mcp-config`
(no ancestor-`.mcp.json` trust scan — the one real incident on record, see
`runners/dev_init.py`'s `_root_mcp_server_names` docstring), an explicit `--allowed-tools`
allowlist per role (`scripts/lib/cxo_mcp_config.py --print-allowed`), and
`--permission-mode auto`. What those three layers do not cover is a C-level *choosing* to
call `AskUserQuestion` mid-background-run — nothing technical stopped that before this
section; only the general "bias toward acting" instructions in global `CLAUDE.md` did, and
those are soft. When a real judgement call is needed and no one is watching the pane: queue
it — `mcp__lungnote__add_todo` for something only the CEO can decide (surfaced at the next
`/session-open`), or `send_to_cxo` mailbox for a question aimed at another C-level — and
keep working on whatever does not depend on the answer.

**Suspended org-wide, interactive sessions included (CEO 2026-08-14).** The first draft of
this section carved out an exception for "a session the CEO is actively driving right now."
The CEO closed that carve-out the same day:

> "งดใช้ชั่วคราวไปก่อน ถ้ามีคำถามอะไร ถามแบบ Message ใน Chat ได้ ไม่จำเป็นต้อลใช้ แบบบล็อก"

So: **do not call `AskUserQuestion` at all.** A question worth asking is worth writing as
plain text in the reply — the CEO answers in their next message, which costs them a sentence
instead of a modal and leaves the question searchable in the transcript instead of buried in
a widget. The CEO marked this temporary ("ชั่วคราว"); it stays in force until the CEO lifts
it explicitly, not until an agent decides its own situation feels special enough. A hard
question, a risky action, or a real fork in the road does not re-authorize the blocking
form — those are precisely the cases that deserve full prose rather than four option chips.

**A second, unrelated gap found during the same check: auto-update prompts sit entirely
outside `--permission-mode` and `--allowed-tools`.** `DISABLE_AUTOUPDATER` is a real env var
— confirmed present in the installed `claude` binary's strings (`/Users/gob/.local/share/
claude/versions/*`) — and as of 2026-08-14 it is set in none of `scripts/cto-claude.sh`,
`scripts/cxo-claude.sh`, or `runners/dev_init.py`. An update-available prompt is a startup-
level interrupt, not a tool-permission check, so no amount of `--allowed-tools` tuning
reaches it. Set `DISABLE_AUTOUPDATER=1` in all three launchers to close it.

**Why:** the org's whole autonomy model — mailbox+wake (§17-adjacent, `lib/mailbox.py`,
2026-08-14), no progress pings (§29's worker rules), the watchdog (GH #68) — assumes a
silent session is either working or dead, never a third state waiting on a button only a
human can press. A blocking prompt breaks that assumption invisibly.

## Section 46 — A rented GPU is watched until it is dead (CEO 2026-09-03)

> "กฏเหล็กเลย อันนี้สำคัญมาก Runpod ถ้าเลิกใช้แล้ว ให้ปิดทันที ถ้างานเสร็จให้ปิด งานค้าง
> ให้เชคตลอด ทุกๆ ... นาที ที่ตั้งไว้ ทุกครั้งที่รัน Runpod จะต้อง Loop ตัวเองเพื่อมาเชค
> จนกว่าจะปิด Pod ถึงจะ Cancel Loop ได้"
>
> "ตัวเองมีหน้าที่รับผิดชอบมัน"

Rented compute is the one thing in this org that keeps spending money after the
agent that started it has stopped paying attention. The rule is therefore not
"remember to clean up" — it is a loop that outlives the job.

**Four obligations, every time a pod is created:**

1. **Finished means terminated.** The moment the work is done, or abandoned, or
   the answer is known, the pod dies. Not at the end of the message, not after
   the next check — then.
2. **A running job is checked on a fixed interval**, and the interval is stated
   when the run starts, so "how long has this been burning" is never a guess.
3. **The check is a LOOP THAT RUNS UNTIL THE ACCOUNT IS EMPTY**, and only then
   may it be cancelled. A loop cancelled while a pod still exists has not
   finished its job; it has abandoned it.
4. **The loop is a separate process from the job.** The trainer already
   terminates on atexit, on signals, and on a hard cap — none of which fire when
   the trainer itself is killed (`tmux kill-session`, a crashed shell, a laptop
   asleep). That is precisely the case the loop exists for, so it must not
   depend on the thing it is guarding.

**When another loop is already running**, retune it to a cadence that also
covers the pod check for the duration of the run, and restore its original
cadence only after the pod is confirmed gone. The pod check takes precedence
while a pod exists.

**Implementation** (Cookie Run lane, reusable pattern):
`cookierun-bot/vision/runpod_guard.py` — `--every` seconds, `--max-age` minutes,
`--now` for a single check, `--kill-all` to empty the account. It exits only
after seeing zero pods twice in a row, because a pod that is mid-creation can
briefly not appear in the listing and stopping on that would leave it running
with nothing watching.

**Two facts learned the day this rule was written**, both worth carrying to any
provider: COMMUNITY-cloud pods can be rented, billed, and never given a public
IP (`publicIp: ""`, `machine: {}` in the API, with `supportPublicIp: true` in
the request) — they are unreachable and useless while still costing money, so
cap the wait for an SSH mapping and drop them fast. And the balance keeps
settling for a minute or two AFTER termination, so the figure read immediately
on shutdown is not the final cost.

---

## Section 47 — Research is checked before it is commissioned, and filed when it is done (CEO 2026-09-03)

> "Agentic ของเรามีที่เก็บ Research แล้วไหม ... เพราะทุกอย่างที่เรา Research มาจะได้ไม่เสียเปล่า
> ไม่ต้องไปค้นหาใหม่ หยิบจากคลังมาใช้ได้เลย"

On 2026-09-03 five research workflows ran in one session. Three left something
behind in a repo. Two existed nowhere but a temp directory — including a
ten-agent, ~1.1M-token sweep of how Seedance prompts are actually structured,
whose most valuable finding was that a "six-part formula" repeated across dozens
of sites has no primary source behind it at all. A `/tmp` cleanup would have
erased it, and the next person to ask would have paid to find it again.

**The library is `org:research/`.** One page per question answered, named
`YYYY-MM-DD-short-question.md`. Its README carries the conventions.

**Before commissioning research — any C-level, every time:**

1. **Read `org:research/` first.** If the question is answered there, use the
   answer. Spending tokens to re-derive a finding the org already owns is waste,
   and it is invisible waste, which is worse.
2. **If it is answered but the page is old enough to doubt**, re-run only the
   parts that could have moved and **update that page in place**. Do not write a
   second page on the same question — two pages disagreeing is how a library
   stops being trusted.
3. **If it is not there, commission it** — and the task is not complete until
   the finding is filed.

**Every research page states how each claim is known:** `official` (read at the
vendor's own docs), `practitioner` (a named person reporting what they did),
`secondhand` (a site repeating it without a source), `inference` (our own
reasoning). This is not bookkeeping. It is the level that revealed the six-part
formula was folklore, and it is what lets a reader six months later judge how
much weight a claim carries.

**And every page carries its provenance** — when it ran, which session, the
workflow run id, how many agents, whether findings were adversarially re-checked.
A finding about someone else's product goes stale without the file changing, so
the date is part of the claim.

**The filing is automated, not remembered.** `scripts/research-file.py` takes a
workflow run and writes the page. A rule that depends on somebody thinking of it
at the end of a long session is a rule that fails on exactly the long sessions
where it matters most.

## Section 48 — Disk and transcript hygiene on the Mac: alert first, move by hand (CEO 2026-09-05, owner CTO)

**Why this rule exists.** Between 2026-08-28 and 2026-09-05 the 8 GB Mac
kernel-panicked six mornings out of nine. Panic string: `watchdog timeout: no
checkins from watchdogd in 93 seconds`, with `8 swapfiles and LOW swap space`.
Three CTO sessions with 70-255 MB transcripts, plus Chrome, LINE and Dropbox,
filled RAM; swap grew until it hit the ~7 GB left on a 96 %-full disk; the box
stalled and the watchdog reset it. Every open session died. Claude Code
transcripts (`~/.claude/projects`) were 8.5 GB of that disk, and they only
grow: the file is append-only, and every `--resume` copies the whole parent
into a new file, so a long-lived CTO session leaves a trail of dead copies.

**Nothing deletes on its own. The machine alerts; a human archives.**

1. **The daily watch only reports.** `~/.claude/tools/prune_transcripts.py --notify`
   runs at 09:00 via launchd `com.gob.claude-prune-transcripts` and messages
   the CEO over SomPong when free space is under 20 GB, transcripts ready to
   archive reach 2 GB, Drive-gate folders reach 2 GB, or it is Monday. It
   never deletes.
2. **Archiving is a manual command, and it archives before it deletes.**
   `prune_transcripts.py --archive` tars each candidate into Google Drive
   (`ไดรฟ์ของฉัน/Claude-Transcripts/<project>/<uuid>.tar.gz`), verifies the
   archive, and only then removes the local copy. `--restore <uuid>` brings a
   session back. `--apply` (delete without archive) exists for emergencies and
   needs the CEO's word. Candidates: ordinary sessions after 30 days, sessions
   over 150 MB after 7 days, sessions whose worktree is gone after 7 days;
   under 20 GB free, 14 / 3 / 7 days. Live sessions, anything written in the
   last 24 h, `memory/` and the `keep` list are never candidates.
3. **Folders move to Drive only through the gate.** `drive-archive-gate.md`
   (next to the tool) names what may move, where it lands, and the
   copy-verify-delete order. An agent moves a folder only after the CEO says
   go on a specific alert. No automatic mover, ever.
4. **Weekly check, Monday /session-open.** Run `--report`, read
   `~/.claude/logs/prune-transcripts.log` for `FAIL`, confirm the job is loaded
   with `launchctl print gui/$(id -u)/com.gob.claude-prune-transcripts`, read
   `df -h /System/Volumes/Data`. Under 20 GB is a finding; under 10 GB is a
   same-day escalation.
5. **A live session over 200 MB gets closed and reopened, not resumed forever.**
   Finish the job, leave the hand-off in the tab title and LungNote, start a
   fresh session. A CEO-facing tab is closed only with the CEO's OK.
6. **Overnight: at most 3 live sessions and at least 20 GB free.** A session
   with a day of history costs about 1 GB of RAM here (measured 2026-09-05: a
   255 MB transcript resumed = 1.1 GB RSS). Below either number the panic above
   is the expected outcome.
7. **Worktrees die with their task.** When a task closes, remove its worktree
   (`python3 -m tools.worktree` from the Agents root). Before removing, check
   `git status --porcelain` is empty and the branch is pushed or merged; 41
   leftovers held 6.5 GB on 2026-09-05, most with unpushed commits.
8. **Never:** delete `~/.claude/projects/*/memory/`; delete a transcript that
   `~/.claude/sessions/*.json` lists as live; touch
   `~/Library/Application Support/CloudDocs/session/i` (the iCloud store for
   the CEO's Desktop, not a cache); run any cleanup on `~/Desktop`,
   `~/Downloads`, `~/Movies` or the Photos library while the CEO is
   consolidating phone data there.

**Evidence:** `/Library/Logs/DiagnosticReports/panic-full-2026-09-05-110452.0002.panic`,
`ResetCounter-2026-09-03-094156.diag` (`Boot faults: wdog`), `last reboot`.
Tool, policy and log paths above are the single source; do not copy the
numbers into other pages.

**Gate rule, filed:** [drive-archive-gate](https://github.com/PASAKON/Agents-Wikis/blob/main/playbooks/drive-archive-gate.md) (`org:playbooks/drive-archive-gate.md`) — the wiki page is the canonical copy of the `drive-archive-gate.md` named in point 3; the file next to the tool mirrors it.

## Section 49 — Google Drive: the skill is the rule, and a hook holds the door (CEO 2026-09-06, owner CTO)

On 2026-09-06 a CTO session backed up Cookie Run data to Drive after reading
Google's own limits page — and never opened `gdrive-filing`, the org's filing
skill. The tar landed in a new root folder, unasked, against the skill's first
three rules. The CEO's words: *"ถ้าจะใช้งาน Gdrive อ่าน Skills นี้ก่อนเสมอ มันเป็นกฏ"*.

1. **Before any Drive action — upload, backup, move, rename, delete, create a
   folder, by rclone, the gdrive-bridge, the Drive MCP or a synced folder —
   the session reads `.claude/skills/gdrive-filing/SKILL.md`.** Google's
   limits are facts about Google; the skill is the rule about *our* Drive.
2. **A PreToolUse hook enforces it** (`scripts/hook-gdrive-skill-gate.py`,
   registered in the Agents repo's `.claude/settings.json`): every
   Drive-touching call exits 2 until the skill has been read in that session
   (Skill tool, Read, or a Bash that opens the file); the reading expires after
   12 hours. `GDRIVE_GATE=off` is for repair only and is named in the report.
3. **What moves off a machine goes through the gate table** in
   `playbooks/drive-archive-gate.md` (Section 48): a row per source, approved
   by the CEO, copy → verify by hash → delete, one log line each.
4. **Tokens:** an agent holds the narrowest Drive credential that does the job.
   The Windows box's rclone remote is re-authorised with scope `drive.file`
   (sees only what it created); a full-scope token is a CEO decision, never a
   default.
5. **Same-turn bookkeeping:** any folder created or moved updates the skill's
   tree and ID table in the same turn, and the updated subtree is pasted back
   to the CEO (skill rule 6).

---

## Section 50 — Every session is visible, and every teardown proves identity before it kills (CEO 2026-09-11, owner CTO)

The CEO could not answer the most basic question about their own org:

> **"ให้เป็นกฎเหล็กเลย เพราะฉันเช็คไม่ได้เลยว่ามี session เปิดจริงไหม"**

Measured the same day: two live C-level sessions on Contabo (`CONTABO CTO
#bfdcf202`, `#e1e3d3ef`) appeared nowhere in the Claude app, because
`scripts/cto-claude.sh` and `scripts/cxo-claude.sh` built their `claude`
invocation without `--remote-control`. Workers had it, the Windows C-level had
it, the two bash launchers did not.

### 1. Registration is not optional

**Every session an agent can spawn passes `--remote-control`,** sourced from
`runners.worker_init.remote_control_args(host)` which reads the per-host
`remote_control` key in `config/hosts.yaml` (default true). One helper, one
switch. Never hardcode the flag and never hardcode its absence: a literal
`"--remote-control"` in a launcher means `hosts.yaml` cannot turn it off, which
is the same bug in the other direction.

### 2. The name carries the state, because there is no delete

**Verified, do not re-litigate:** `--remote-control` registers a session; on exit,
clean or killed, the entry goes *offline* within seconds but never disappears.
No CLI, flag or API deregisters it (`claude --help`'s `rm <id>` removes a `--bg`
background session, an unrelated concept). Removal is a manual UI action by the
CEO.

So state is stamped into the display name **while the session is still alive**:

| transition | name becomes |
|---|---|
| `/session-close` | `✅ <MACHINE> <ROLE> #<id> (<topic>)` |
| `/session-save`, and a force-saved close | `⏸ …` |
| `/session-merge`, the absorbed session | `⛔ MERGED→#<target> …` |
| force-killed or crashed | **no prefix** |

**The absence of a prefix is the signal.** An offline entry with no prefix means
that session died unexpectedly and is resumable. Nothing stamps that case, by
construction, and nothing should start.

### 3. A teardown proves identity before it kills

On 2026-09-11 `state/tasks.db` recorded `pid=23068` for a winbox task. That pid
had been recycled by Windows and now belonged to **`BlueStacksServices.exe`**,
the emulator the Cookie Run bot plays in around the clock. The moment that task
reached a terminal status, the reaper would have run `taskkill /PID 23068 /T /F`
and killed the CEO's bot, violating the standing rule *"อย่าให้คอมว่างแล้ว Cookie
ไม่วิ่ง เพราะเสีย Slot ที่สำคัญที่สุดคือ Slot เวลา"*. All 14 winbox rows carrying a pid
were checked: 13 pids were gone and the 14th was BlueStacks. Not one still
belonged to its task.

**Before any kill, local or remote, confirm the process is still the task's own
process** — match the task id in the command line, the same identity test the
spawner used to discover the pid. Three outcomes, never two:

- **killed** — it was ours, it is gone;
- **already gone / not ours** — issue no kill, and clear the recorded pid;
- **could not check** (ssh failed) — issue no kill, and **keep** the pid.

`None` must never collapse into `False`. "I could not check" becoming "safe to
kill" is exactly how a reaper kills the wrong process.

### 4. A retry that cannot succeed is a bug, not patience

The same half-wired teardown wrote **12,061 `SURFACE-REAPED` lines across 126
tasks, every one `ssh_ok=False`**, retrying every five minutes forever, because
`ssh_ok` was read from the ssh exit code alone and Windows `taskkill` exits
non-zero when the pid is already gone. The captured `stderr` was never printed,
so nobody could see why.

**Transport success and operation success are different facts, and both are
logged.** If a sweep cannot make progress, it must record why in a form a human
can read, and it must stop repeating the identical call.

---

## Section 51 — Structure before prompts: no scene is generated until it has earned its place (CEO 2026-09-17, owner CTO)

The CEO handed over `tig-scene-engine` — a five-element dramatic engine (Goal,
Obstacle, Tactic, Reversal, Value Shift) with bespoke definitions — and said:

> **"บังคับใช้กับ คนที่จะทำหนัง หรือ เขียน Prompt สร้าง Video ให้เลย"**

Why this is a rule and not a suggestion: unlike a screenwriter's draft, every
scene we keep costs credits, queue time and a re-shoot budget. A beautiful
prompt for a scene that should not exist is paid for twice — once to generate
it and once to discover, after the edit, that removing it costs the story
nothing. The engine's removal test runs while the work is still free.

1. **The skill is installed verbatim** at
   `.claude/skills/tig-scene-engine/SKILL.md` in the Agents repo, symlinked
   into `~/.claude/skills/` so it resolves from any project. Its body is the
   CEO's text **unchanged** — the five definitions are bespoke and must not be
   swapped for textbook craft definitions. Anyone editing it for style is
   breaking the rule, not improving it.

2. **It runs BEFORE the prompt layer, never instead of it.** The order is:
   story → **tig-scene-engine** (structure, output = screenplay) →
   `character-reference-sheet` → `seedance-scene-prompt` (shot, output =
   prompt) → generation. The engine never writes a prompt and never touches
   Higgsfield.

3. **Who must run it.** Any agent about to write, audit or order a scene for a
   multi-scene film, a branded short, or any narrative video: roles
   `script_writer`, `prompt_engineer`, `video_editor`, and `browser_operator`
   when it is being handed scenes to generate. A C-level directing a film runs
   it before briefing anyone.

4. **What it must produce before a single prompt is written.** For each scene:
   the Goal as a causal link to the story goal; the Obstacle with what is at
   risk and at what scale; the Tactic the threat forces and what its outcome
   teaches; at least one Reversal per resolved sequence; and the Value Shift —
   the audience's before-verdict and after-verdict. **If the before/after
   verdict cannot be named, the reversal is inert and the scene is not ready to
   generate.**

5. **The removal test is a gate, not a note.** If a scene can be cut and the
   chain to the story goal still holds, it does not get generated. Say so to
   the CEO and let them overrule — do not quietly generate it.

6. **Where it does not apply.** A 15-30s ad clip, a motion-graphic explainer,
   a product loop, or any single standalone shot has no room for a reversal and
   a re-judged character. Running the engine there is ceremony. Judge by whether
   the piece has a story, not by whether it has a camera.

## Section 52 — Code decisions are the C-level's: merge gate-clean PRs, do not ask (CEO 2026-09-19, owner CTO)

Verbatim, after the CTO asked which of two gate-clean PRs to merge:
"ไม่ใช่หน้าที่ฉัน ที่จะ Merge หรือ ตัดสินใจอะไร Coding คือหน้าที่คุณ คิดเห็นสมควรจัดการได้เลย ฉันมีหน้าที่วางแผน" — and then: "จริงๆ มันเป็นของคุณอยู่แล้ว".

- A PR that passes the merge gates (`cto-merge-checklist`) is merged by the
  C-level that reviewed it and reported in one line — on every repo, including
  prod-adjacent ones. "ขออนุมัติ merge" is a defect in the report, not caution.
- Unchanged: gates that exist because of consequences, not code — spending
  money (exact amount, wait for OK), prod deploys and data migrations (announce
  first, with rollback), secrets, anything outward-facing.
- Ask the CEO only when a gate is red and the fix is a planning call.
- Origin: Jules PRs #210/#211 on MoonieX-ClaudeFlow, verified on Node 20 with the
  workflow's env block (1,150/1,150) + Opus 5 review, merged 2026-09-19.

## Section 53 — งานเบราว์เซอร์ที่ทำซ้ำ = script ไม่ใช่โมเดล (CEO directive 2026-09-19)

งานเบราว์เซอร์ใดที่ต้องทำขั้นตอนเดิมซ้ำ**เกิน 3 ครั้ง** ห้ามให้โมเดลคลิกเอง โมเดลทำได้ 2 อย่างเท่านั้น:

1. **รอบแรกรอบเดียว** เพื่อสร้าง script ที่รันได้โดยไม่มีโมเดล
2. **แก้เฉพาะแถวที่ script ตัดสินเองไม่ได้** (ปฏิเสธซ้ำ, dialog ใหม่, chip ไม่ติด) — เปิดเป็นงานเล็ก context สด ไม่ใช่ให้ operator ตัวเดิมวนต่อ

**script = ไฟล์ที่ compile ผ่าน** (`python -m py_compile` / `node --check`) และมี ledger เป็นความจำ (1 แถวต่อชิ้นงาน, resume ได้, ชิ้นที่ verified แล้วไม่ทำซ้ำ) บันทึกวิธีทำเป็น prose **ไม่นับ** — `cto-merge-checklist` Gate 8 เช็คด้วย `tools/check_replay_script.py` ไม่ใช่ด้วยสายตา

**ก่อน spawn browser_operator ทุกครั้ง C-level ต้องตอบก่อนว่า runner มีอยู่แล้วไหม** — ต้นแบบ `scripts/higgsfield/gen_loop.py` (Playwright ต่อ Chrome debug port + โปรไฟล์แยก, ดัชนี resume ได้) และดีไซน์สำหรับ Flow `docs/ops/flow-operator-design.md`

**ที่มา (วัดจาก transcript):** 19 ก.ย. 69 — operator 2 ตัว 6.2 ชม. 405 screenshot **650M token → 8 คลิป (~80M/คลิป)** ขณะที่ developer สร้างระบบจริง 1 งาน = 77M. claude-in-chrome กิน 67% ของ usage 7 วัน และชน 95% ของ limit รายสัปดาห์. เหตุผลเชิงโครงสร้าง: screenshot ไม่เคยออกจาก context (§42) ฉากที่ 12 จ่ายค่าฉาก 1-11 ซ้ำทุกเทิร์น — บรีฟดีแค่ไหนก็แก้ไม่ได้ ต้องเอาโมเดลออกจากลูป

## Section 54 — MoonieX HQ: the map decides, the disk follows (CEO 2026-09-22, owner CTO)

Everything MoonieX builds lives under `~/MoonieXHQ`, described by one map (`hq.yaml` → `MAP.md`)
and enforced by `scripts/hq.py doctor`. Full rules: skill `hq-filing`, ADR 0028. Two are the
CEO's own words and bind every agent on every project:

1. **Every path created under HQ needs the CEO's approval first.** No folder without a row in the
   map, no row without a yes. Propose, wait, then create. ("Path ต่างๆ ที่จะมาสร้างใน MoonieX HQ
   ต้องผ่านการอนุมัติจาก CEO ก่อนเสมอ")
2. **One project = one folder, fully independent. Projects connect only through APIs.** Never
   import another project's code, read its files or share its tables — ClaudeFlow reads LungNote
   through LungNote's API. Every project must keep working when moved to another host.
   ("ถ้าจะเอาโปรเจค 2 อันมาเชื่อมกัน ต้องทำผ่าน API เท่านั้น")

Corollaries: `Projects/<Brand>/<Suffix>` ⇔ `PASAKON/<Brand>-<Suffix>` (ADR 0012); media never in a
code repo (→ `Assets/`); other people's code read-only in `External/`; the archive rule (on GitHub →
delete local, else Drive then delete, note stays); `UNKNOWN/` empty at every `/session-close`; inside
a project, `playbooks/project-layout.md`.

## Section 55 — Work/: a task's bytes live in its own folder and leave with it (CEO 2026-09-23, owner CTO)

**Why.** 2026-09-23 04:05 the Mac hit 0 bytes free and every tool, hook and worker died at once.
Agents download plates, render takes and write reviews, finish, and leave the pile on `~/Desktop`,
`~/Downloads`, `/tmp` and inside repos — "สะสมเป็นภูเขา". The CEO approved one place for it and
ordered strict rules: "อนุมัติสร้าง ~/MoonieXHQ/Work/ และเขียนกฎอย่างเข้มงวด".

The law is `~/MoonieXHQ/Work/RULES.md` (10 rules). The ones that bind every agent:

1. **One task = one folder `Work/<task-id>/{in,tmp,out}`; every byte the task downloads or makes
   goes there** — never Desktop / Downloads / Movies / `/tmp` / a repo / another task's folder.
2. **`in/` files carry a `SOURCES.txt` line** (file ⇥ url ⇥ sha256); **`tmp/` is deleted at close;
   `out/` goes home** (Assets via hq-filing, or Drive via gdrive-filing) and is verified there.
3. **A task cannot close while its folder exists.** Merge / done is refused until it is filed and gone.
4. **Stay in your folder** (IRON §33). Orphans are reported to the owning session, never cleaned by another.
5. **Before a download > 1 GB, leave ≥ 10 GB free or stop and report; below 5 GB nothing starts.**

Scope: pilot — enforced for `pilot_owner_cto` in Agents-Core `config/storage-policy.yaml`; the CEO
widens it. A rule binds when a tool checks it; RULES.md lists which tool checks which rule.
Full design: ADR 0030.

## Section 56 — English is the org's working language (CEO 2026-09-23, owner CTO)

**Why.** Every token an agent reads or writes is paid on every later turn, in every session, for
as long as the text lives. English is the cheapest encoding for the models the org runs, and one
language keeps skills, letters and code searchable. CEO: "อยากให้เขียนเป็น English ทั้งหมด ...
เน้น English เพื่อ Save Token In + Out ในระยะยาว ระดับองค์กร".

1. **Everything the org writes is English:** messages between agents (CTO↔CTO letters, briefs,
   TASK.md, REPORT.md, reviews), skills, memory, wiki pages, ADRs, code and code comments, commit
   messages, docs, configs, logs.
2. **Another language only where translating would destroy the meaning:** story, script and
   dialogue text; a person's own words, voice or writing style the work must keep; names and terms
   with no English equivalent; content made for a non-English audience (Thai captions, Thai posts).
   Keep it verbatim; everything around it stays English. Not fixed to Thai or English — use the
   language the content itself lives in.
3. **The CEO's own words are quoted in the original** — a quote is the person's voice (rule 2) —
   with the rule stated in English next to it.
4. **Replies to the CEO in chat follow the CEO's language.** This rule governs what the org writes
   and sends to itself, not how it answers its human.
5. **No bulk translation of existing text.** A file is converted to English the next time it is
   edited for another reason; a translation pass for its own sake costs tokens and risks meaning.
