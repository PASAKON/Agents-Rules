# ADR 0034 — Hosts reach each other, the Mac included, over ssh with one forced command

- **Date:** 2026-10-02 (decision by the CEO on 2026-09-28)
- **Status:** Accepted. Live on Contabo since 2026-10-02. winbox waits on Org Mesh W3.4. The
  Mac waits on gate G2: the CEO at the Mac turns on Remote Login after the hardening below,
  and gives an approval sentence for the `authorized_keys` line.
- **Owner:** CTO (session e6754203, Org Mesh plan)
- **Supersedes, once G2 lands:**
  - ADR 0025 Decision 3, "The Mac dials out, never the reverse … Contabo→Mac stays closed.
    Spawning work onto the Mac from a Contabo hub goes through the existing relay queue
    (`runners/mac_agent.py`), not SSH."
  - `docs/design/org-mesh.md` §3 Security, "The Mac keeps sshd closed", and §6 decision 1,
    which recommended the pull model.
  - The threat model in the `runners/mac_agent.py` docstring: "the Mac dials out … that
    asymmetry is the security design, not a gap to fix".
- **Keeps:** ADR 0017. Nothing here picks up tasks by itself: `spawn_worker` runs only when a
  C-level calls `delegate_task`.
- **Design + runbooks (Agents-Core):** `docs/design/org-mesh.md`, `docs/ops/node-dispatch.md`,
  `docs/ops/mac-sshd-hardening.md`, `docs/ops/mesh-check.md`

## Context

On 2026-09-28 the CEO asked whether the org is connected across the Mac, Contabo and
winbox. It was not. Contabo→Mac ssh was refused (port 22 closed), and so was winbox→Mac.
A C-level on Contabo could not start a worker on the Mac, and nothing outside the Mac could
start a C-level there except through the secretary's relay queue, which only the Mac drains.

The design offered two ways (`org-mesh.md` §6 decision 1):

1. **Pull model:** a `node_agent` on every host polls the hub, and the Mac's sshd stays
   closed. This was the CTO's recommendation.
2. **Remote Login on the tailnet:** other hosts dial the Mac over ssh.

The CEO chose 2. The question was how to open the door without opening a shell.

## Decision

1. **One key, one command.** A host accepts mesh calls only through a dedicated
   `org_dispatch` key. Its `authorized_keys` line forces `tools/node_dispatch.py` as fixed
   text. The caller's text arrives only as `SSH_ORIGINAL_COMMAND`. node_dispatch splits it
   with `shlex.split` and matches it against seven verbs: `probe`, `pid_alive`,
   `spawn_worker`, `kill_worker`, `start_clevel`, `deliver_letter`, `publish_branch`. The
   argument patterns are `fullmatch`. It is never handed to a shell. A caller can name a hub
   row; it cannot send a command.
2. **The key line is fenced.** `restrict` turns off the pty, every kind of forwarding and
   `~/.ssh/rc`. `from=` holds the dispatcher's own tailnet address as a `/32`, never
   `100.64.0.0/10`. There is one key per dispatcher, so one leaked key is revoked alone.
3. **The caller uses no ssh config.** `lib.mesh.build_argv` is the only builder:
   `ssh -F none -i ~/.ssh/org_dispatch -o BatchMode=yes -o IdentitiesOnly=yes
   -o IdentityAgent=none -o StrictHostKeyChecking=yes` to `config/hosts.yaml` `mesh_ssh`
   (user@tailnet IP), never the admin alias. With a config file, `IdentitiesOnly` still
   offers every `IdentityFile` the config names, so the admin key would be tried after a
   refusal. The admin alias for Contabo dials the public IP, which `from=` refuses.
4. **The forced command reaches the hub through the wrapper.** sshd starts it with a bare
   environment, so the line runs `scripts/hub/with-org-db-env.sh` first (since G1 the
   ledger is the Postgres hub and `state/tasks.db` is a tombstone).
5. **The Mac is hardened before Remote Login goes on** (`docs/ops/mac-sshd-hardening.md`):
   - a drop-in `/etc/ssh/sshd_config.d/000-mooniex-mesh.conf`: key-only, `AllowUsers` the
     one account from the dispatchers' addresses, `DisableForwarding`, no user environment
     or rc, `MaxAuthTries 3`;
   - a pf anchor: port 22 only from loopback and the dispatchers;
   - Remote Login set to "Only these users".
   Remote Login needs the admin password, so the CEO does it at the Mac (gate G2).
6. **Every call leaves an audit row.** node_dispatch writes an `events` row with
   actor `node_dispatch` and the caller's address.

## Consequences

**What a compromised dispatcher can do to the Mac.** It can call the seven verbs and
nothing else.
- The strongest verb is `spawn_worker`: it starts a worker for a pending hub task whose
  host is `mac`. The hub runs on Contabo, so whoever controls Contabo also controls that
  task's brief. The worker still runs under its own permission settings and the auto-mode
  classifier.
- `start_clevel` and `deliver_letter` give the same reach that the relay queue already gave
  Contabo through `mac_agent`: start a C-level session, put a letter in an inbox.
- `kill_worker` keeps its own refusal rules (only review/done). `publish_branch` pushes the
  task's own branch and never forces.

**What it cannot do:** run a shell command, open a pty, forward a port, set an environment
variable, log in as another account, or connect from another address. `from=`,
`AllowUsers` and pf each refuse the last case.

**Revocation:** delete one line in `authorized_keys`. Each dispatcher has its own key.

**Upkeep:**
- Re-run `sudo sshd -T` after every macOS update; an update can rewrite `sshd_config` or
  drop the pf lines.
- pf is not on at boot unless a LaunchDaemon runs `pfctl -E`.
- `mac_agent` stays on in parallel. It retires after 24 hours of matching output from the
  mesh path, counted from the moment the relay's dispatch goes live (plan W2.5).

## Status

| step | state | evidence |
|---|---|---|
| node_dispatch verbs, key line, caller builder | merged | W2.2, W2.7 review (task-42fdcda7), W2.8 `ssh -F none` redesign 2026-10-02 |
| Contabo accepts `org_dispatch-mac` | live 2026-10-02 | Run card W2.8a: `probe` ok; 6 payloads refused with no `uid=`; `-W`/`-L`/`-R` refused; no pty; `events` rows with actor `node_dispatch` and caller `100.64.2.37` |
| winbox | waits on W3.4 | the Windows line is not verified; winbox's Infisical identity needs Agents-Core back for `org-db.env`, which the CEO set for G1 on 2026-10-01 (`tools/infisical_setup.py` MACHINES) |
| Mac | waits on gate G2 | hardening written in W2.7, nothing applied yet |
| `mac_agent` retired | after G2 + 24 h | plan W2.5 |
