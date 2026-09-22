# ADR 0029 — The decision layer: typed decisions leave the big model's context and become a tool, chosen by measured tokens

- **Date:** 2026-09-22
- **Status:** Accepted — CEO rulings in session cto-0e8d80b8: all six candidate sites approved; browser-runner residual decisions are the focus and the org's core + skill for browser_operator; Jev-shaped work becomes a tool the agent calls, chosen per job by tokens in/out, never speed; budget `DECIDE_BUDGET_USD=5`/month approved
- **Owner:** CTO
- **Relates:** IRON §53 (repeatable browser work = script), ADR 0015/0016 (context budgets), ADR 0022 §7 (HARD rules carry `Why hard:`), ADR 0028 §6 (research cache), IRON §54 rule 2 (projects independent → other projects implement a thin client to the spec)
- **Spec + tool:** Agents-Core `docs/design/decision-layer.md`, `tools/decide.py`, `config/decisions/*.yaml`, MCP tool `decide` · research: Agents-Wikis `research/2026-09-22-typesafe-jev-system-one-models.md`

## Context (measured 2026-09-22)
- The last five browser_operator transcripts took **343 / 239 / 147 / 139 / 3 screenshots** per task (≈814 tokens each, re-sent every later turn) against 1–5 text reads — the operators were answering typed questions ("still generating?", "is that a refusal?", "signed out?") from pictures.
- Other frontier-model decision points: SomPong routes every message with a full `claude -p`; LungNote classifies email in Gemini batches; ClaudeFlow's compliance rules live inside the writer's prompt and the writer picks b-roll from an 84-clip catalogue itself; the skill-routing hook is regex.
- TypeSafe's Jev ("System One") answers a typed question with calibrated per-option probabilities, no free text, $0.042/MTok in, $0 out. It is live on OpenRouter as `typesafe/jev-1.13` via `POST /api/alpha/decisions` (not in the `/models` list); one page-state decision measured at **$0.00002**.

## Decision
1. **A decision site is declared, never ad hoc**: `config/decisions/<site>.yaml` = question, ≤255 options with meanings, regex rules, `max_state_chars`, provider policy, counterfactual basis. First sites: `browser.page_state`, `browser.moderation_action`, `sompong.route`, `skill.route`.
2. **Provider ladder `rules → jev → haiku`**, highest paid rung set by `DECIDE_PROVIDER`; every paid call counted against `DECIDE_BUDGET_USD` per month (default 0 = no paid call). Keys and budget read from env, then the gitignored `.env`.
3. **Every call writes a ledger row** (`state/decisions/<month>.jsonl`): tokens in/out, exact `usage.cost` when the provider returns it, latency, and a **labelled estimate** of what the same decision would have cost inside the big model. `decide report` ranks sites by saved cost — that report, not speed, decides where the tool stays.
4. **The cost is the input state size.** Runners extract the smallest sufficient text (button label, toast/banner, newest card, sign-in indicator; ≤1500 chars) before asking. Nothing answered inside a long session is cheap: it is re-sent every later turn.
5. **Conservative action mapping (money guard):** act only on `provider == rules` (p = 1.0) or `p ≥ 0.9`; `unknown` and anything softer = keep waiting or stop — **never re-fire a paid generation on a guess** (a refusal is refunded, a wrongly re-fired generation is not). `escalate_ceo` exits non-zero; humans decide Face/IP and rights cases.
6. **Wired into both runners** (`tools/flow_shoot.py`, `scripts/higgsfield/gen_loop.py`) and granted to every worker (`mcp__org__decide`). `browser-operator` carries the HARD rule: a typed question about the page is answered by `decide`, never by a screenshot.
7. **Not through `decide`:** open-ended generation; anything that needs an image (Jev has none — that stays on runners/vision); a per-prompt hook may never make a paid call (`skill.route` is rules-only until a free-rung provider exists).
8. **Other projects (ClaudeFlow, LungNote) implement a thin client to the spec** — they do not import Agents-Core (IRON §54).

## Consequences / next
- T3 SomPong routing → `decide` (Agents-Core); T5 ClaudeFlow compliance post-check + b-roll scoring; T6 LungNote triage A/B vs Gemini Flash on the K2.6 eval set. Each gets a ledger row per call from day one.
- A wrong "not available" from a catalogue scan cost half an hour today; the research file now says: verify absence with the provider's per-model endpoint, never a list.
