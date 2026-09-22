# Obsidian retired from the Mac — 2026-09-22

CEO ruling (session cto-0e8d80b8): humans no longer need Obsidian; the AI never used
it — every agent reads the wikis as plain markdown through `wiki_search` / grep on the
real repo paths. Removed the same day, per the HQ archive rule ("not on GitHub → put it
on GitHub or Drive, then delete, leave a restore note").

## What was removed (all moved to the Mac's Trash, reversible until emptied)
| item | what it was | knowledge inside? |
|---|---|---|
| `/Applications/Obsidian.app` (482 MB) | the app, not a brew cask | no — reinstall from obsidian.md |
| `~/Library/Application Support/obsidian` (53 MB), `Preferences/md.obsidian.plist`, `Saved Application State/md.obsidian.savedState` | cache + vault registry (3 vaults: `~/projects/LLMs`, `Wiki-Vault-TEST` (renamed `Wiki-Vault`), `~/Documents/Obsidian Vault` (missing)) | no |
| `~/Projects/Wiki-Vault/` | symlink hub (agents → Agents-Rules, mooniex → Agents-Wikis, lungnote → LungNote-Wikis) + a test note + graph presets | the test note and presets are kept here |
| `~/Documents/เอกสาร - MacBook Pro ของ GoB /Obsidian Vault` | empty vault, 5 config files, 0 bytes | no |
| `.obsidian/` inside `Agents-Wikis` (was `MoonieX-Wikis`, local `LLMs/`) and `LungNote-Wikis` | per-vault config (app/appearance/core-plugins/graph/workspace) | no — removed from both repos the same day |

Every wiki is a git repo and was never inside Obsidian — nothing to merge, no conflicts found.

## The one finding worth keeping (from the test note)
`find`, `rg`, `grep -r` do **not** follow symlinks by default: searching through a symlink hub
returned **0 files with no error** where `find -L` / `rg --follow` returned 204. Agents must
search the real repo path, never a hub of links. (Carried into the `hq-filing` skill.)

## If someone ever wants Obsidian back
Download from obsidian.md, "Open folder as vault" on any wiki repo (`Agents/Rules`, `Agents/Wikis`,
`Projects/LungNote/Wikis` under MoonieX HQ). `graph-presets/` holds the three graph views the CEO
used (`swap.sh A|B|C` swaps `.obsidian/graph.json` — close Obsidian first, it rewrites the file on exit).
