# LungNote stray worktree copy — retired 2026-09-22 (HQ step ②, task-ad534f86)

`/Users/gob/LungNote Projects/.claude/worktrees/fervent-noether-9ebf32` was a 703 MB plain copy
of the LungNote umbrella (CLAUDE.md, README.md, webapp/, wikis/) made by an `EnterWorktree` on a
folder that was never a git repo — so it was not a worktree, just a snapshot. Against the live
repos (now `~/MoonieXHQ/Projects/LungNote/{Webapp,Wikis}`) it differed by 91 lines: the live
repos had files the copy lacked (`admin/`, `liff/`, `legal/`, `MascotMark.tsx`, newer
`40-Decisions/*.md`) and a few files differed (`layout.tsx`, `globals.css`, `icon.svg`, some
decisions docs). `stray-vs-live.patch` is the full `diff -ru` (left = the stray copy, right =
live), kept here so the copy could go: archive rule — not on GitHub → put the unique part on
GitHub, then delete. The 703 MB went to `~/.Trash/hq-step2-stray-lungnote-20260922/`.
