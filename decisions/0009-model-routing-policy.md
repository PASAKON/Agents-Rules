# ADR 0009 — Model routing policy: Opus / Sonnet / GLM tiers + per-role effort

- **Status**: Accepted — Implemented
- **Date**: 2026-07-01
- **Decider**: CEO ("OK", 2026-07-01)
- **Drafted by / Implemented by**: CTO session (this conversation)
- **Implementation sha**: `f7f3846`

## Context

CEO runs two active subscriptions relevant to org-spawned agents:

- **Claude Code Pro** ($20/mo) — Opus 4.8 + Sonnet 5 access, shared weekly usage cap.
  CEO downgraded from Max 20x ($214/mo) to Pro, active since 2026-06-24.
- **BytePlus ModelArk coding plan** ($10/mo) — GLM-5.1 via an Anthropic-compatible
  endpoint, fully separate quota pool. Already flag-gated and wired
  (`CXO_MODEL_PROVIDER` / `DEV_MODEL_PROVIDER`, `spawn-cto.sh --glm`); verified
  live 2026-07-01 (`BYTEPLUS_API_KEY` valid; `ZAI_API_KEY` is a placeholder,
  not usable today).

**Before this ADR, org config burned 100% Opus, at effort `max`, 100% of the
time, regardless of task difficulty:**

- `policies/agents.yaml` hardcoded `claude-opus-4-8[1m]` for every role —
  all 5 C-level (CEO has no model; CTO/CFO/CGO/CMO do) and all 9 worker
  roles (developer, tester, devops_engineer, security_engineer,
  web_designer, data_analyst, prompt_engineer, ads_manager,
  content_strategist). 14 roles total, none used Sonnet. The schema had no
  `effort:` field at all.
- `runners/dev_init.py:203` defaulted every DEV spawn to `--effort max`
  unconditionally (only dropped when a GLM override was active) — a single
  hardcoded constant, not read per-role.
- `scripts/cto-claude.sh:127` hardcoded `--model claude-opus-4-8[1m]
  --effort max` for every CTO session. This flag won over the user's
  personal `/model` default.
- `scripts/cxo-claude.sh` (the CFO/CGO/CMO + ephemeral-CTO launcher)
  **also** hardcoded the identical `--model claude-opus-4-8[1m]
  --effort max` pair, independently of `cto-claude.sh` — confirmed during
  implementation, not just suspected.
- `roles/_dev_shared.md` existed (meant to carry conventions shared by all
  9 worker roles) but was **never read** — `dev_init.py:144` only loaded
  `roles/{role}.md` into the spawn's system prompt. Orphaned file, fixed
  in this pass.

A trivial status check cost the same Opus-max tier as a hard refactor.

**Claude Code weekly-cap mechanics** (not officially published, best
available read): plan tier (Pro / Max 5x / Max 20x) scales total bucket
size only — Max 20x ≈ 20× Pro's pool. Relative per-model weighting is
presumed constant across plans. Empirical baseline from the Max-20x era:
one Opus-heavy CTO session burned 22% of the weekly cap in under a day.
Effort level compounds this independent of model choice — higher effort
burns more tokens than lower effort on any model.

**Sonnet 5 vs Opus 4.8**: Anthropic frames Sonnet 5 as "near-Opus quality
on coding and agentic work" — exactly this org's workload. Sonnet 5 is
also in its intro-pricing window through 2026-08-31 ($2/$10 per MTok vs
Opus $5/$25) — right now Opus costs ~2.5× Sonnet, vs ~1.67× after the
window closes.

**GLM-5.1 (Zhipu/Z.ai, served via BytePlus ModelArk)**: benchmarks
competitively with Opus 4.6 / Sonnet 4.6 on structured coding (SWE-Bench
Pro: GLM-5.1 58.4 vs Opus 4.6 ≈54–57) but trails on broad coding breadth
(BenchLM coding avg: Sonnet 4.6 66.4 vs GLM-5.1 58.4), multi-turn agentic
debugging (Aider polyglot: Opus ahead 6–9pts), and blind code-quality
preference (senior engineers preferred Opus output 62% vs GLM 38% in a
third-party blind A/B). GLM-5.1 is **text-only — no image input**
(explains earlier BytePlus iTerm2 image-drop API errors). All these
benchmarks are vs the prior Opus 4.6/Sonnet 4.6 generation; this org runs
4.8/5, so the real gap is likely the same or wider in Claude's favor.
GLM-5.2 has already shipped and closes much of the remaining gap to Opus
4.8 specifically — org config is still pinned to `glm-5.1`; checking
BytePlus SKU availability for `glm-5.2` is a follow-up, out of scope here.

**Effort parameter** has 5 levels: `low / medium / high / xhigh / max`.
`xhigh` is Anthropic's stated best setting for coding/agentic work and is
Claude Code's own native default — the prior org-wide `max` overshot that.
`low` fits latency-sensitive live chat, which none of this org's roles are
(everything here is an async task spawn or an interactive planning chat)
— so `low` has no role-level default; it stays available as a per-task
override for trivially scoped subtasks.

## Decision

Routing keyed by **task type**, resolved to a concrete per-role default:

| Role | Default model | Effort | Why |
|---|---|---|---|
| CEO | — (human) | — | n/a |
| CTO | **Sonnet 5** | **xhigh** | Interactive planning session with the CEO — starts light, escalates to Opus 4.8 via the `session-change-model` skill for architecture/security/prod-deploy/merge-judgment work. Mirrors how the CEO already runs his own `/model` practice. |
| CFO / CGO / CMO | **Sonnet 5** | **high** | Narrower-scope C-level sessions than CTO. Escalate to Opus via the same skill for genuine strategic calls. |
| security_engineer | **Opus 4.8** | **xhigh** | Security-sensitive work by definition — needs depth to find non-obvious edge cases. |
| devops_engineer | **Opus 4.8** | **high** | Prod-deploy-adjacent, infra blast radius, but more procedural/checklist-driven than security review — doesn't need xhigh's extra exploration depth. |
| developer | **Sonnet 5** | **xhigh** | Highest-volume role and the canonical "coding/agentic use case" xhigh is designed for — best quality-per-quota tradeoff in the whole table. |
| tester | **Sonnet 5** | **high** | Verification work, more bounded than open-ended feature dev. |
| web_designer | **Sonnet 5** | **high** | Needs real creative judgment (avoiding generic "AI slop" aesthetics). |
| data_analyst | **Sonnet 5** | **medium** | Pull metrics / compute / report — well-defined output, little open exploration. |
| prompt_engineer | **Sonnet 5** | **high** | Requires reasoning about model behavior and edge cases. |
| ads_manager | **Sonnet 5** | **medium** | Mostly playbook-templated work; real spend already gated by a separate approval-gate process regardless of model. |
| content_strategist | **Sonnet 5** | **medium** | Content is largely template-able per the org's content skill; genuinely bulk pieces route to GLM instead. |
| Any role, bulk/templated task | **GLM-5.1** (BytePlus, opt-in) | n/a — ModelArk endpoint rejects `--effort` | Not a role default — a per-task override via `--glm` (CTO) / `DEV_MODEL_PROVIDER` (workers). |

`low` and `max` are intentionally **not** assigned as any role's default:
`low` has no latency-sensitive-chat use case here (reserve for trivial
one-off subtasks, e.g. rename a variable, bump a version string); `max`
is reserved for genuine escalation (e.g. a full security audit) rather
than the blanket baseline it was before this ADR.

> **Mid-implementation correction (2026-07-01):** the first draft of this
> table had CTO defaulting to **Opus 4.8**. That contradicted the
> `session-change-model` skill (built earlier the same session, per CEO
> request) and the CEO's own stated workflow — "I talk to a CTO that IS
> Sonnet first, then it recommends escalating to Opus." An Opus-default
> CTO makes the escalation skill pointless (nothing to escalate from).
> Caught and fixed before any file was written — see the table above
> for the corrected row. `roles/cto.md`'s cheat-sheet text and the skill
> file were already written assuming the correct (Sonnet-default)
> behavior; only this table and `policies/agents.yaml` needed the fix.

### Tier criteria (what pulls a task up regardless of role default)

- Architecture/system design calls, security-sensitive code, anything
  prod-deploy-adjacent
- Final merge review / CTO go—no-go decisions
- Wiki/ADR writing requiring judgment
- Cross-project orchestration reasoning
- Any task explicitly escalated after a Sonnet attempt under-delivers

### Tier 3 — GLM-5.1 via BytePlus (separate $10/mo flat pool, zero Claude quota impact)

- High-volume/low-judgment batch work: bulk content generation,
  scaffolding, repetitive multi-file edits, templated tasks
- Fallback when Claude weekly quota is running low and the task doesn't
  need top-tier judgment
- Long-horizon unattended single-task runs (GLM-5.1 is built for 8h+
  autonomous sessions)
- **Not for**: anything needing image input (text-only model), security
  review, financial-number-sensitive work (e.g. MoonieX rebate $/lot
  figures — never let a non-Opus model recompute those), or final merge
  judgment

### C-level mid-session escalation mechanism

For CTO/CFO/CGO/CMO specifically — these are live interactive chats with
the CEO, not one-shot task spawns, so the escalation path is different
from workers (below). Use the `session-change-model` skill
(`.claude/skills/session-change-model/SKILL.md`, local-only — see
Implementation notes): it watches for the Tier criteria above, proposes a
switch with reasoning, waits for explicit CEO confirmation, then hands
over the literal `/model opus` command (no tool lets the assistant
trigger a model switch itself — only the human typing it can). Verified:
`/model` switches the live session immediately and resends full
conversation history to the new model (content is never lost); the only
cost is the old session's prompt cache, which resets on the first
post-switch turn. Effort resets to the new model's own default on first
use in a session (usually `xhigh` for Opus 4.8, which already matches the
table above).

### Per-role prompt content (cheat sheet) — implemented as written

Landed verbatim in `roles/_dev_shared.md` (shared by all 9 worker roles)
and `roles/cto.md` / `roles/cfo.md` / `roles/cgo.md` / `roles/cmo.md`
(each, per-role). So every spawned agent — not just the CTO reading this
ADR — knows its own tier, what each tier is for, and the escalation path.

## Consequences

### Positive

- Routine DEV/CTO work moved off Opus-max by default — the single
  biggest quota lever available, bigger than GLM offload alone
- Per-role effort (not just per-role model) is a second, independent
  lever — e.g. data_analyst/ads_manager/content_strategist drop to
  `medium` without changing model, compounding the savings
- GLM absorbs bulk/templated work entirely outside Claude's pool,
  preserving headroom for Tier 1 work even under Pro's tighter cap
- security_engineer / devops_engineer stay on Opus — cost savings don't
  come at the expense of the two roles with the highest blast radius
- Every spawned agent — not just the CTO — knows its own tier and the
  escalation path, via the cheat-sheet text landing in its own system
  prompt
- `scripts/cxo-claude.sh` is now data-driven (reads `policies/agents.yaml`
  per role) instead of a second hardcoded value — closes half of the
  two-source-drift risk noted below

### Negative / trade-offs

- Quality variance risk: Sonnet/GLM may need escalation to Opus more
  often than the prior blanket-Opus-max approach — acceptable,
  escalation path stays open
- GLM has no vision input — any task needing image read must stay on a
  Claude tier
- `session-change-model` skill lives under `.claude/skills/`, which is
  gitignored in this repo (consistent with the existing `session-open` /
  `session-close` / etc. skills — local-machine-only by established
  pattern, not pushed to GitHub). Fine for a single-operator setup; would
  need revisiting if a second machine/operator joins.
- Two C-level launchers (`cto-claude.sh`, `cxo-claude.sh`) still exist
  separately — `cxo-claude.sh` is now role-aware/dynamic,
  `cto-claude.sh` is a direct hardcoded `claude-sonnet-5` / `xhigh` pair
  (scoped minimally per the original plan, not refactored to be dynamic
  too) — the two-source-drift risk from
  `reference_cto_spawn_model_sources` memory is reduced but not fully
  eliminated; a future pass could make `cto-claude.sh` read from
  `agents.yaml` the same way `cxo-claude.sh` now does

## Implementation (executed 2026-07-01, sha `f7f3846`)

1. ✅ `policies/agents.yaml` — added `effort:` field per role; `model:`
   set to `claude-sonnet-5` for: CTO (corrected from the original
   Opus-default draft — see note above), CFO, CGO, CMO, developer,
   tester, web_designer, data_analyst, prompt_engineer, ads_manager,
   content_strategist (11 entries). security_engineer, devops_engineer
   stayed `claude-opus-4-8[1m]`. Effort values per the table above.
2. ✅ `runners/dev_init.py:203` — replaced the hardcoded
   `effort_args = ["--effort", "max"]` with a per-role read:
   `get_role(role).get("effort") or "high"` (using the file's existing
   `role as get_role` import alias).
3. ✅ `runners/dev_init.py:144` — now also loads `roles/_dev_shared.md`
   and prepends it to `role_doc`, fixing the orphaned-file bug.
4. ✅ `roles/_dev_shared.md` — cheat-sheet block appended.
5. ✅ `roles/cto.md`, `roles/cfo.md`, `roles/cgo.md`, `roles/cmo.md` —
   cheat-sheet block appended to each (Sonnet 5 default, per-role
   effort, escalation path).
6. ✅ `scripts/cto-claude.sh:127` — `--model claude-opus-4-8[1m]
   --effort max` → `--model claude-sonnet-5 --effort xhigh` (model AND
   effort both changed, not just effort — required once CTO's default
   moved off Opus).
7. ✅ `scripts/cxo-claude.sh` — confirmed it hardcoded the identical
   stale pair (same as cto-claude.sh, independently). Fixed by making
   it role-aware: extended the existing `display_for`/`is_c_level`
   Python resolution block to also fetch `model`/`effort` from
   `policies/agents.yaml` via `lib.config.role()`, and the final `claude`
   invocation now uses `"$MODEL"` / `"$EFFORT"` instead of hardcoded
   values. One real bug caught and fixed during this step: first attempt
   imported a non-existent `get_role` directly from `lib.config` (the
   actual function is named `role()`; `dev_init.py` aliases it via
   `role as get_role`) — would have been an `ImportError` at spawn time.
   Caught by re-running the resolution logic locally before trusting the
   edit; fixed to `from lib.config import display_for, is_c_level, role
   as get_role`.
8. ✅ No change needed to GLM plumbing — already flag-gated and verified
   working.
9. ✅ `session-change-model` skill — created earlier the same session
   (`.claude/skills/session-change-model/SKILL.md`).
10. ✅ Verification before commit: YAML parses, both bash scripts pass
    `bash -n`, `dev_init.py` passes `python3 -m py_compile`, and
    `lib.config.role()` was called for all 13 roles to confirm
    model+effort resolve exactly per the table above (including a
    simulated run of `cxo-claude.sh`'s actual inline Python block for
    role `cfo`).
11. ✅ Committed (`f7f3846`) and pushed to `main` — only the 9 files
    listed above; pre-existing unrelated working-tree changes
    (`assets/brand-refs/mooniex/BRAND.md`, `data/trader-mindset-topics.json`,
    `scripts/invoice_gen/generate_invoice.py`) were left untouched, not
    part of this change.

## Follow-ups (not done, out of scope for this ADR)

- `scripts/cto-claude.sh` could be made data-driven like `cxo-claude.sh`
  now is, fully closing the two-source-drift risk.
- Check whether BytePlus's coding-plan SKU offers `glm-5.2` yet (closes
  more of the capability gap to Opus 4.8 at the same $10/mo).

## Addendum (2026-07-25) — Opus 5 released, model literal bumped

Opus 5 shipped; `claude-opus-5` replaces `claude-opus-4-8[1m]` everywhere
in the routing table above. Tier assignment and effort levels are
**unchanged** — this is a version bump only, not a re-derivation of the
table. Updated: `policies/agents.yaml` (security_engineer,
devops_engineer + CTO comment), `runners/dev_init.py`,
`runners/dev_resume.py`, `scripts/cxo-claude.sh` (fallback literals),
`roles/cto.md` / `cfo.md` / `cgo.md` / `cmo.md` / `_dev_shared.md`
(cheat-sheet escalation text), and the local `session-change-model`
skill. Committed+pushed to `mooniex-agents` main at `e67fae8`. Not
touched: `policies/permissions.md` — already stale pre-ADR (lists a role
set that predates the current 13-role schema entirely); needs its own
refresh pass, out of scope here.

## Addendum (2026-09-23) — Opus 5.5 @ xhigh is the C-level standard; Opus workers follow

CEO order, verbatim: "ปรับ ORG Default C-Level และ worker อื่นๆ ที่ใช้ Opus อยู่
ให้เป็น 5.5 xhigh เป็นมาตรฐานได้เลย … ส่วน Worker ไหนเป็น Sonnet อยู่ ก็ใช้ต่อไป
ยังไม่เปลี่ยน".

This **supersedes the table above for C-levels** — it is a re-tiering, not a
version bump like the 2026-07-25 addendum.

| Role(s) | Before | Now |
|---|---|---|
| CTO | Sonnet 5 @ xhigh, Opus escalation via skill | **`claude-opus-5-5[1m]` @ xhigh** |
| CFO / CGO / CMO | Sonnet 5 @ high | **`claude-opus-5-5[1m]` @ xhigh** |
| security_engineer | `claude-opus-5` @ xhigh | **`claude-opus-5-5` @ xhigh** |
| devops_engineer | `claude-opus-5` @ high | **`claude-opus-5-5` @ xhigh** |
| every Sonnet 5 worker | unchanged | unchanged |

- **1M context for C-levels, 200k for workers.** C-levels get the 1M window
  because that is what the CEO picks for himself with `/model` and their
  sessions run for hours. The two Opus workers stay on the plain id: worker
  sessions are short, and a larger window only postpones compaction and grows
  per-turn cost (the open worker token-saving to-do).
- Fallback for C-levels stays `claude-fable-5`.
- Both ids answered a headless `claude -p --effort xhigh` probe on 2026-09-23
  before anything was changed.
- **Escalation is gone for C-levels** — there is no tier above the default.
  `session-change-model` now only restores the standard when a session is
  running lighter (a pre-change launch, a restart onto a stale default, a
  `/model` downgrade, a GLM offload).
- Updated: `policies/agents.yaml`, fallback literals in `scripts/cto-claude.sh`,
  `scripts/cxo-claude.sh`, `runners/worker_init.py`, `runners/worker_resume.py`;
  `roles/cto.md`, `cfo.md`, `cgo.md`, `cmo.md`, `_worker_shared.md`; the
  `session-change-model` skill (Agents-Core). Not touched: `claude-home/settings.json`
  (a separate harness rewrite owns it; launchers pass `--effort` explicitly, so
  its per-model effort map does not decide anything here).
- Applies at the next spawn/restart. Live sessions keep the model they were
  launched with until someone runs `/model claude-opus-5-5[1m]` + `/effort xhigh`
  in them.
