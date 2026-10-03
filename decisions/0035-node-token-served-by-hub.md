# ADR 0035 — A joined node gets its Claude token from the hub, not from Infisical

- **Date:** 2026-10-03 (decision by the CEO the same day)
- **Status:** Accepted. Build: task-edc8d76f (Org Mesh W4.2b). Not live until its deploy cards
  run on Contabo and join drill run 6 passes.
- **Owner:** CTO (session e6754203, Org Mesh plan)
- **Supersedes:** `docs/design/org-mesh.md` §6 decision 4 as ruled on 2026-09-29: "W4.2 uses one
  shared identity, `org-node`. Each joining node gets its own Universal Auth client secret
  under it".
- **Keeps:** ADR 0034. The join door stays closed by default (CEO 2026-10-01). Every join still
  needs the CEO's approval of the node's key fingerprint.

## Context

Join drill run 5 (Run card RUN-20261003-1425-1343) reached `provision`, and Infisical refused to
create the `org-node` identity (`POST /api/v1/identities` → HTTP 400). Infisical Free allows 5
identities, and the CEO's own user account counts as one. `contabo`, `mac`, `winbox` and
`setup` hold the other four. `tools/infisical_setup.py` counted machine identities only, so it
believed a slot was free.

The fifth slot is not free for long either. After `setup` retires on 2026-10-10, secret writes
use an identity minted for one task and deleted after it (skill `CTO_Procedure_KeyFetch`,
step 4). A permanent `org-node` would take that slot for good.

The CEO was offered three ways:

1. **The hub serves the token.** No new identity. Free. One build task and a security review.
2. **Infisical Pro.** No code. The price recorded on 2026-09-25 (not re-checked): $20 per
   identity per month billed yearly, $23 monthly. For about 6 identities that is roughly
   $120–138 a month.
3. **Retire `setup` and give its slot to `org-node`.** Free. After that, no identity can write a
   secret, so KeyFetch and key rotation would be done by hand in the Infisical web page.

## Decision

CEO, 2026-10-03, picked option 1 ("Hub ส่ง token ให้"):

- No new Infisical identity. `contabo` becomes a viewer on project `Org-Node`.
- The hub serves a node its token only when the CEO approved the node and it has not left or
  started leaving.
- The token is never written to a file on the node. The node fetches it when it starts a
  process and gives it to that process's environment only.
- A node that has left can never get it again.
- This is an exception, granted by the CEO for nodes only, to the secrets rule "a service reads
  its secrets through `infisical run` with its machine identity" (2026-09-25/26). The hub
  itself still reads the token through `infisical run`.

## Design (W4.2b)

- **Hub service.** `tools/node_token_api.py` runs on Contabo as `org-node-token.service`, always
  on, bound to the tailnet address only.
  - `GET /v1/token?host=H` answers with the token sealed by age to H's recipient
    (`hosts.pubkey`), so only H can open it. The tailnet-only bind is the second wall.
  - Unknown, unapproved, pending, leaving and left hosts get 403.
- **Database role.** `org_node_token` can only read `hosts(host, status, pubkey, approved_at)`.
- **Node side.** `tools/node_token.py run -- <command>` opens the answer with the node's age key
  and puts the value into the child's environment only.
- **Leave.** `hq_join leave` first sets the row to `leaving`, so issuing stops even when a later
  revocation step fails. The row becomes `left` only when every step succeeded, as before.

## Consequences

- **More on the hub.** One more always-on service on Contabo, holding one secret. A root process
  on Contabo can read it. That was already true of the C-level sessions running there.
- **Rotation.** The first fetch after a rotation gets the new value, and no node holds the old
  one at rest.
- **Hub outage.** Losing the hub stops new node processes from starting. Running ones keep their
  token until they exit. The pull model already depends on the hub for the ledger.
- **Tailnet ACL.** If the policy is not allow-all, it must let `tag:org-node` reach the token
  port.
