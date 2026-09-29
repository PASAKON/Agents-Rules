# Delegate by usage — which runner does a worker's job

**Rule:** IRON-RULES §59 (CEO 2026-09-29). **Owner:** the router, CTO #24ca1c0a.
**Code:** Agents-Core `config/plans.yaml`, `tools/quota.py`, `tools/route.py`,
`tools/model_stats.py`, the runner hook in `tools/delegate.py`.
**Cross-machine side** (where a worker runs, how its report comes back): Agents-Core
`docs/design/runner-routing/CONTRACT.md`, owned by the mesh CTO.

## Why

From 2026-09-29 17:00 BKK the Claude plan drops from $200 to $20 a month, while Google is $100 and
OpenAI $20. Every C-level session runs on Claude. A worker that spends Claude quota by habit starves
the sessions that plan, review and merge. The CEO's order: send worker jobs to whichever provider
has headroom, prove it on real tasks, and keep Claude for the jobs only Claude should do.

## 1. The order — the router applies it, you do not re-decide it

For a job class, `tools/route.py` ranks the candidates in `plans.yaml roles:`:

1. **Weekly quota remaining**, highest first.
2. Within `router.tie_points` (5 percentage points) of each other: **daily quota remaining**.
3. Still tied: **skill score** from review history (`tools/model_stats.py`). A score counts only
   after `router.min_samples` (5) reviewed tasks; below that it is unknown and neutral.
4. Still tied: **the CEO's order** in the `roles:` list.

A candidate whose runner is not installed on the target host (`config/hosts.yaml runners:`) is
skipped. A provider inside an active `bonuses:` window counts as weekly = 100%.

## 2. Plans and classes today

| provider | runner | plan / month | since |
|---|---|---|---|
| anthropic | claude | $20 (was $200) | 2026-09-29 17:00 BKK |
| google | agy | $100 | 2026-09-01 |
| openai | codex | $20 | 2026-09-01 |

| class | candidates, CEO order | used for |
|---|---|---|
| `dev_general` | agy Gemini 3.8 Flash High, then claude Sonnet | general developer and tester work |
| `c_level` | claude Opus 5.5 xhigh | C-level sessions (launcher, not the router) |
| `c_level_openai` | codex Sol xhigh | C-level stand-in when Claude is out |
| `complex` | claude Fable 5.1, codex Astra xhigh | very complex work, CEO or C-level asks for it |

Worker roles map to a class in `plans.yaml role_classes:` (`developer`, `tester` → `dev_general`).
A role with no mapping stays on claude and is not routed.

## 3. How to delegate

1. `create_task` as usual, with `touches`. **Leave `runner` empty.**
2. `delegate_task`. The hook (CONTRACT §3) calls `route.pick_runner(role, host)`, writes
   `tasks.runner`, and logs `router: <runner> — <reason>`. Read that line; it is the record of why.
   - Until the hook is live (CONTRACT §4 says so), do it by hand:
     `.venv/bin/python tools/route.py --role dev_general --host <host>`, then
     `UPDATE tasks SET runner='<runner>' WHERE id='task-…'` before `delegate_task`.
3. An explicit `runner` on the row is never overridden. Set one only for an A/B test or a CEO order,
   and say which in the task description.

### Force Claude only for these, with the reason written in the task description

`UPDATE tasks SET model_hint='claude' WHERE id='task-…'` when the job is:

- reviewing, finishing or repairing another agent's code (including a worker that died mid-task);
- security-sensitive: auth, secrets, tokens, permissions;
- a job where a silent wrong answer ships (no test can fail on the mistake);
- a job that needs a Claude-only tool: the org MCP tools, Claude in Chrome, a browser operator,
  the Artifact tool, Claude skills.

"Claude is the default" and "the other lane might be slower" are not reasons.

## 4. Writing a brief for agy or codex

External CLIs get no org MCP tools, no Claude skills and no mailbox wake. The brief carries
everything (`CXO_Protocol_DelegateExternal` has the field notes):

- **agy is edit-only.** It runs as `agy -p … --mode accept-edits` with no permission allow-list, so
  every shell command is auto-denied, and the run then fails whole: it writes nothing
  (task-e2306d6e; `mooniex:research/2026-09-30-agy-cli-permissions-headless.md`). An agy brief
  asks for file edits only; the reviewer runs the tests. A job that must run commands goes to codex.
- **Acceptance as commands** (codex): the exact test command and the expected result.
- **Tests on fixtures only:** `tmp_path`, never the real `state/`, `.env` or a live service.
- **The interpreter by absolute path** (a worktree has no `.venv`).
- **Scope:** only the files in `touches`; anything else is a report line, not an edit.
- **How it ends:** agy on the Mac edits only, and the hub commits and reads `REPORT.md` into the row.
  codex on Contabo ends with a final message; the launcher commits and pushes `agent/codex-<task>`.
- **Short.** The whole brief is the prompt; every extra line is paid on every turn.

## 5. Review: the same gate, never a discount

- Every external worker's output goes through the same gate as a Claude worker's: read the diff,
  run the tests **in a worktree**, `CTO_Gate_MergeChecklist`, then merge.
- The runner that wrote the code never reviews it. Review is a force-Claude job (§3).
- A reopen with feedback is a real result: it raises `iteration`, and `model_stats` scores a pass as
  `1 / (1 + iteration)`, a fail as 0. Do not close a bad result as done to spare the lane its score.
- Remote rows (codex, agy on Contabo) may stay `in_progress` after the push. Done = the branch on
  origin plus the report; flip the row yourself (CONTRACT §1.3 until the mesh returns reports).

## 6. Keep the inputs true

| input | when | how |
|---|---|---|
| plans | the same day a plan changes | append to `plans.yaml providers:`; never delete an old entry |
| free grant or surprise reset | when it starts | `plans.yaml bonuses:` with `from`, `to`, `note` |
| quota history | any time; daily is enough | `.venv/bin/python tools/quota.py --record` |
| skill table | before changing a `roles:` order | `.venv/bin/python tools/model_stats.py --by-class` |
| runners per host | after a CLI install, login or machine reset | `config/hosts.yaml runners:` (mesh W4 probe replaces it) |

## 7. Where each runner works today

CONTRACT §4 holds the live table. On 2026-09-29: Mac hub to Mac agy and Mac hub to Contabo codex are
proven on real tasks; Contabo agy is wired, not yet run; winbox lost both CLIs in its reset. Only the
Mac is a hub until the mesh ships.

## 8. Turning the router off

`ORG_ROUTER=off` in the delegating session's environment skips the hook. Use it only to repair the
router or a quota reader, and write why in the task description. It is never a way to put a job on
Claude; §3 is the way.
