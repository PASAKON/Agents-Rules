# ADR 0026 — Skill learning loop: a sighting is a note, a rule needs two witnesses

- **Date:** 2026-09-22
- **Status:** Accepted — CEO "OK ✅" 2026-09-22 (session cto-0e8d80b8) on both open points: the ≥2-run bar before a rule changes, and CONTESTED = frozen until the CEO rules
- **Owner:** CTO
- **Amends:** [ADR 0022](0022-skill-governance-visibility-authorship-audit.md) — keeps every decision there (open authorship, no approval gate, git is the ledger, objections are one event + one to-do); adds the missing path from *what a run learned* to *what the skill says*
- **Implements:** CEO 2026-09-18 "ส่วน Worker ให้เรียนรู้ไป Update Skill ไปนะ ให้คุณคอยกำกับดูแลตลอด" — the `## Skill learning` report section every role already carries

## Context

Since 2026-09-18 every report ends with WRONG / MISSING / COSTLY lines. Measured
2026-09-22: **nothing parses that section** (0 hits across tools/ scripts/ lib/
runners/), worker reports at least sit on disk in `docs/reports/*/REPORT.md` for
the CTO to fold, but a C-level's own lines went nowhere — chat only, gone at
session end. The CEO's two fears, both real:

1. **An agent writes something wrong into a skill** and every later worker
   inherits it. Root cause seen in our own history: n=1 → rule
   (memory `refire-before-rewrite`: a refusal cause "proven" from one fire per
   arm; the identical prompt rendered on the next try).
2. **Edit, revert, edit again.** Root cause: the old rule's evidence is deleted
   when the rule changes, so the next agent flips it back on weaker evidence
   without knowing what it is overturning.

An approval gate would address neither and is forbidden by ADR 0022 §9.

## Decision

### 1. Every learning line names the skill and the section
```
- WRONG   [<skill> §<section>] : <rule that proved false> · evidence: <task-id / sha / path> · fix: <one line>
- MISSING [<skill> §<section>] : <what the skill should have said> · evidence: <...>
- COSTLY  [<skill> | no owner]  : <the step that ate the time> · evidence: <...> · prevented by: <one line>
```
The CEO reads this in chat and sees which skill was touched and which was wrong.
`[no owner]` → memory or a new-skill proposal, never an unrelated skill.

### 2. Two tiers — a Field note is not a rule
- **Field note** (one run saw it): one bullet under `## Field notes` at the
  bottom of the named skill — `- YYYY-MM-DD [KIND] <what> · evidence: <…> · status: pending`.
  Anyone may append (ADR 0022 open authorship). Labelled as a sighting, a
  wrong note costs nothing.
- **Rule change** (the body above the heading) only on **(a) ≥2 independent
  runs agreeing, (b) a CEO ruling, or (c) an artefact proving the old rule
  cannot work** — not "it didn't work for me". **n=1 never edits a rule.**

### 3. Never delete evidence — supersede; two flips = CONTESTED
The replaced line moves to Field notes as `[SUPERSEDED] … · evidence: <what beat it> · status: superseded`.
A rule flipped twice inside 30 days (`skill(<name>): flip` commits) is
**CONTESTED — frozen; only the CEO unfreezes**. Counted from `git log`, no new store.

### 4. One writer per skill body — the `owner`
Frontmatter `owner:` (already the objection address, 19/33 skills carry it;
absent → CTO) is the only role that edits the body. Everyone else appends a
Field note or `raise_objection`. A C-level folds its own lines in the same
turn under the same tiers.

### 5. Ledger = git + chat; gate = lint, not approval
- Commit subject: `skill(<name>): note|rule|flip — <what> — evidence <task-id>`
- `scripts/skill-lint.py` codes **8** (malformed Field note), **9** (`--staged`:
  body edited, no note in the same diff), **10** (CONTESTED). Lint only —
  pre-commit runs `check --staged` and never blocks (ADR 0022 §9).
- `scripts/skill-curator.py notes` — pending / PROMOTE? / STALE / CONTESTED / MALFORMED per skill.
- `/session-close` gate 2b: unfiled learning lines → no 🏁 (force_saved, lines named).

## Consequences
- The learning loop closes for C-levels too; the first Field note landed in
  `session-open` the same day.
- `## Field notes` sections are created lazily on the first note — no backfill.
- Cost: ~120 lines across lint + curator, 19 role templates, 2 skill docs.

## Explicitly not doing
- No approval or review queue for skill edits (ADR 0022 §9 stands).
- No automatic promotion of notes to rules — a human (or the owner, with the
  evidence in hand) does that, one at a time.
- No daemon that scans reports — `notes` is a verb someone runs (ADR 0017).
