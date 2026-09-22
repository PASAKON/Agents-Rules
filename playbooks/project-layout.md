# Project layout — the standard inside every repo (CEO approved 2026-09-22)

One layout for every project, any language, so an agent that has never seen the repo knows where
things are, and a human can read it. Folder names say **what the folder is for**, not what file
type it holds. Top level splits by **layer**; split by feature *inside* a layer only when it grows.
Three doors, same facts: `CLAUDE.md` (AI), `README.md` (humans), `docs/INDEX.md` (knowledge).

```
<Project>/                      PascalCase folder (HQ rule); everything inside is lowercase per the language
├── CLAUDE.md                   AI entry: what this is, how to run, where things are — ≤ 1 page
├── README.md                   humans: what / why / quickstart
├── docs/                       knowledge, never code
│   ├── INDEX.md                map of docs/
│   ├── API.md                  the contract other projects call (or openapi.yaml) — REQUIRED: cross-project = API only
│   ├── adr/                    decisions, numbered
│   ├── research/               cached research (one question = one file; see Agents/Wikis/research/README.md)
│   └── runbooks/               how to operate it in prod
├── src/                        product code, one language root
│   ├── api/                    the only door other projects use (HTTP / RPC / MCP)
│   ├── core/                   domain logic — pure, no I/O
│   ├── services/               integrations: db, external APIs, queues
│   ├── ui/  (or app/, cli/)    presentation — keep framework-dictated names (Next.js app/) under src/, do not fight them
│   ├── lib/                    small shared helpers
│   └── types/                  schemas / contracts — what api/ publishes
├── tests/                      mirrors src/ paths
├── scripts/                    runnable ops / one-off scripts — src/ never imports from here
├── config/                     declarative config (yaml / json) — no secrets
├── assets/                     small static media the code ships (icons, fonts); anything big → HQ Assets/
├── data/                       local data, gitignored except data/fixtures/ (tiny)
├── state/                      runtime state: db, logs, caches — gitignored, machine-local
├── infra/                      Dockerfile, compose, CI, launchd / systemd units
└── .env.example                key NAMES only — secrets live in Infisical
```

## Rules
1. **`src/api/` is the border.** Another project may call it; nothing else in `src/` is reachable
   from outside. Document the contract in `docs/API.md`; `hq.yaml` records the API's base URL per machine.
2. **`core/` has no I/O.** If it needs the database or the network, that code is a `service`.
3. **Layer first, feature second.** `core/rebates/`, `core/posting/` only once `core/` is too big to read in one sitting.
4. **Framework dirs stay where the framework wants them** (Next.js `app/`, Django `manage.py`), inside `src/` where possible.
5. **Big media, datasets, venvs are not project content** — HQ `Assets/`, hq-filing rule 5.
6. **Existing projects are not rewritten to match.** Each gets a row in the HQ map now and is brought to this
   layout the next time it is touched, one project at a time; `hq doctor` checks the three doors
   (`CLAUDE.md`, `README.md`, `docs/INDEX.md`) + `docs/API.md` on every project.

Related: `hq-filing` skill · IRON-RULES §54 · ADR 0028.
