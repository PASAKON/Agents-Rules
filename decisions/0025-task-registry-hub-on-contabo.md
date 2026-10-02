# ADR 0025 — One task registry on Contabo (Postgres); the Mac and winbox are spokes

- **Date:** 2026-09-18
- **Status:** Accepted (CEO ruling 2026-09-17 #5, memory `project_org_session_architecture_2026_09`) — **implemented: the cutover (Org Mesh gate G1) ran on 2026-10-02**, see status table
- **Owner:** CTO (session e8565613, carried forward from 4a904905)
- **Supersedes:** ADR 0024 §Recommendation (Mac hub + Contabo front door), ADR 2026-07-12 §Decision 3 / Phase D (two independent `tasks.db`)
- **Partly superseded:** Decision 3 ("Contabo→Mac stays closed") by ADR 0034 once Org Mesh
  gate G2 lands: other hosts reach the Mac over ssh with one forced command
- **Keeps:** `docs/design/multi-host-workers.md` rules 2–3 (git is the only cross-machine channel for work; the hub pushes to spokes, Contabo→Mac stays closed)
- **Design + runbook:** `docs/design/tasks-db-hub.md` in the Agents repo (measured numbers, cutover steps, risks)

## Context

The org ran two `state/tasks.db` files that could not see each other (ADR 0024): the Mac's
(910 → 948 tasks, 141 sessions, 7.6k events) and Contabo's (11 tasks, all terminal, all
spawned onto winbox by a Contabo CTO). The Mac sleeps, Contabo never does, and the CEO
ruled that Contabo is the hub of the Agents repo. ADR 0024 had recommended the opposite
shape; its technical objections (SQLite cannot be shared over a network, Contabo→Mac SSH is
closed by design) are answered below rather than re-argued.

Measured before deciding (2026-09-18, all read-only): Mac→Contabo tailnet RTT 127 ms avg;
Contabo's `ts-input` chain accepts everything on `tailscale0`, so a service bound to
`100.118.171.23` is tailnet-only with no ufw change; 33 modules already go through
`lib/db.py`, 11 opened `sqlite3` themselves; SQLite-only SQL was small (32 `?`
placeholders, 1 `INSERT OR REPLACE`, 4 `PRAGMA`).

## Decision

1. **Postgres 16 on Contabo**, docker, bound to the tailnet IP only, databases `org` and
   `org_test`; credential file `/root/.config/mooniex/org-db.env` (600) mirrored to the
   Mac's `~/.config/mooniex/org-db.env`. Transactions are the reason it is Postgres and
   not rqlite: `lib/db.py` has 15 commit/rollback blocks that must stay atomic with
   three writers.
2. **`lib/db.py` selects the backend by `ORG_DB_URL`.** Unset → SQLite exactly as before
   (tests, offline fallback that is *never* silent in production: a set-but-unreachable
   URL raises). Set → psycopg 3 through `lib/db_pg.py`, which keeps callers' SQL
   unchanged (`?`→`%s`, Row parity, PRAGMA no-op, `INSERT OR REPLACE`→`ON CONFLICT`).
   The 9 modules that bypassed the layer now go through it; the two per-tool-call hooks
   fail open with a 3 s budget. `lib.db.init_schema(conn, is_pg=…)` is the one place
   both the runtime and the migration build a schema (PG DDL + the column-migration list).
3. **The Mac dials out, never the reverse.** The spoke that needs the hub opens the
   connection; Contabo→Mac stays closed. Spawning work onto the Mac from a Contabo hub
   goes through the existing relay queue (`runners/mac_agent.py`), not SSH.
4. **Cutover order:** Mac first (`scripts/hub/cutover-mac.sh`: refuse while work is in
   flight → freeze the launchd watchdog → migrate → flip `ORG_DB_URL` into the MCP
   configs, launchd plists and `cto-claude.sh` through a wrapper that reads the env file
   at spawn time, so no secret lands in a tracked file → verify → archive
   `state/tasks.db`), Contabo last (only after its two live CTO sessions are restarted:
   pull tree, import its 11 rows, flip). Live sessions keep their old backend until
   restarted, so their delta is imported afterwards. Nothing is deleted before it has
   been read (ADR 0024).
5. **Tests never reach the hub** (ADR 0021): the root `conftest.py` strips the C-level
   session env and `ORG_DB_URL` for every test; only `ORG_TEST_DB_URL` opts a test into
   a Postgres it owns. (Before this, a C-level shell leaked `CTO_SESSION_ID` into pytest
   and the charter gate failed 5 tests on main.)

## Consequences

- Every statement from the Mac costs ~127 ms; a tool call is a few statements. If it is
  ever felt, the fix is fewer statements, not a local cache.
- A Mac with no tailnet cannot write the registry. Accepted by the ruling — before this,
  the Mac was the single point of failure for the whole org.
- **The hub is only as available as Contabo's bill.** Contabo rebooted on 2026-09-16 over
  a payment problem (LungNote d7c66504, due 2026-09-19). A nightly `pg_dump` to
  `state/backups/` (shipped by the existing Drive broker) is the follow-up W2, together
  with a Contabo-side watchdog for the hours the Mac sleeps and GH #155's PATH fix.
  (Done 2026-10-02: a nightly `pg_dump` goes to Drive and a restore drill passed; see
  the status table.)
- Rollback at any point before the archive: unset `ORG_DB_URL` everywhere (the SQLite
  file is untouched until step 5); after the archive: `mv` it back and unset.
- The CTO session's auto-mode classifier refuses remote shell writes to Contabo, so hub
  provisioning is a script the CEO runs by hand (`!`) or a permission rule the CEO grants.

## Status (updated by the CTO as steps land)

| step | state | evidence |
|---|---|---|
| Design + runbook | done | `docs/design/tasks-db-hub.md` dec7edd8 |
| W1 dual backend, migrate script, bypassers, hooks fail-open | merged | main 2de97194 (1207 tests green on SQLite, 11/11 on Postgres) |
| W1b case-insensitive id prefixes on both backends | merged | main b46dbfae (2-backend smoke 6/6) |
| W1c migrate fixed (target schema, rollback-on-error, `events` identity, per-row report), pytest env isolation, `scripts/hub/cutover-mac.sh` | merged | main fa7cb56f |
| Real-data migration rehearsal on a Mac-local Postgres 16 | **passed** | 948 tasks / 141 sessions / 7588 events moved, re-apply +0, identity insert OK (CTO reproduced the DEV's run) |
| Postgres on Contabo | done | docker `org-postgres` (PG 16.15), tailnet `100.118.171.23:5432/org`; tables by an additive `db.init()` with the CEO's OK (2026-10-01) |
| Migrate Mac data + Mac cutover | done 2026-10-02 04:35 TH | `scripts/hub/cutover-mac.sh`; `state/tasks.db` is now a tombstone (`lib.db` raises `ArchivedDB`) |
| Contabo import + flip | done 2026-10-02 04:56 TH | hub at cutover: tasks 1276, c_level_sessions 198, events about 10,850 |
| Read-only fallback | done 2026-10-02 | `state/tasks.snapshot.db`, refreshed by units that start through `scripts/hub/with-org-db-env.sh` (7dfa4280) |
| Nightly backup + restore drill | done 2026-10-02 | cron 02:15 on Contabo runs `drive_leg.py state-db` (`pg_dump`, password in `PGPASSWORD`, not argv) to Drive `State-DB/contabo/`; the drill restored a dump into a throwaway database and all 8 tables matched (`docs/ops/machine-contract-drive-leg.md`, ec06c6e9) |
| Concurrent schema init | fixed | 691b7950: two org MCP servers starting together deadlocked on DDL; now an advisory lock first, and no DDL when the catalog is current |
| Hub password | rotated 2026-10-01 | `db.init()` printed the URL into a CTO transcript; `db.redact_url` (024bf79a), rotated with the CEO's OK in Infisical and both `org-db.env` files |
| Wiki changelog `projects/mooniex-agents.md` | done 2026-09-18 | see that page |
