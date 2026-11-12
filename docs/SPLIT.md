# Splitting the Claude configuration out

ConfigMe's `claude/`, its Claude hooks in `bin/` and `github-templates/`
moved to a repo of their own, AdaptiveDesign, cut from commit `2c468f3` on
2026-11-11. ConfigMe depends on it: the installer clones it beside this
repo and calls its installer. This file is the design and the milestone
list for ConfigMe's side. The other side, including the installer contract
ConfigMe calls, is in `../AdaptiveDesign/docs/DESIGN.md`.

Order, needs, tier and status are in `frame.toml`. This file is frozen.

## Decisions

| Decision | Why |
|---|---|
| Sibling clone at `${ADAPTIVE_DESIGN_DIR:-<ConfigMe's parent>/AdaptiveDesign}` | Owner's call. A submodule would make every skill amendment two commits |
| ConfigMe passes the includes; AdaptiveDesign does the linking | One place knows the link rules |
| Three new feature boxes, `claude-calendar`, `claude-ticktick`, `claude-dotfiles`, default on | The owner's machines have all three today; a box is how every other choice here is made |
| Work merges into `frame/split`, not `main` | Nothing is pushed to the default branch. `main` receives one PR at the end |
| `claude/` is removed only after the live `~/.claude` has been cut over | `~/.claude` links into this checkout; removing first would break every running session |

## Rules for every milestone

- Never run the installer against the real home directory. Tests set
  `HOME`, `XDG_CONFIG_HOME`, `CONFIGME_FEATURES` and `ADAPTIVE_DESIGN_DIR`
  to scratch paths, and turn every feature off except the ones under test:
  the installer downloads and installs things when features are on.
- Work in a worktree branched from `frame/split`.
- A need written `AD:M2` is a milestone of AdaptiveDesign's frame. Check
  it with `scripts/check` there; `frame.toml` here cannot express it.

## T: the oracle and the rules file

Tier T2, high. Files: `scripts/test`, `AGENTS.md`, `frame.toml` (`[check]`
only).

As milestone T in AdaptiveDesign: write `scripts/test` in the same form
(`t_<name>` functions, `ok`/`FAIL` lines, `<n> passed`), with the cases
below, and fill the `AGENTS.md` slots. Design and milestone doc are both
this file; default branch `frame/split`; frozen: this file, `scripts/test`,
`scripts/check`.

## M1: install.sh delegates

Tier T2, high. Needs T and `AD:M2`. Files: `install.sh`, `features.md`.

The `==> claude` section (near line 907) stops linking and instead: finds
the clone, clones it with `git clone` from
`https://github.com/A-Sand-of-Piecy-Ham/AdaptiveDesign` when it is absent
and `CONFIGME_NO_CLONE` is unset, and runs its `install.sh` with one
`--include` per enabled `claude-*` box. ConfigMe's checking mode is
`--doctor` (corrected at Checkpoint A; the frame first called it
`--check`). Its claude section (near line
550) runs AdaptiveDesign's `install.sh --check` and passes its `ok`/`bad` lines through
the existing `ok`/`bad` helpers. A missing clone is one `bad` line with a
`fix`, and the rest of the installer carries on. The loop that links
`bin/*` is unchanged.

Suite `delegate`:

| Case | Asserts |
|---|---|
| `links_made` | with `claude` on, the sandbox home has `~/.claude/CLAUDE.md` resolving into the AdaptiveDesign checkout |
| `feature_off_skips` | with `claude` off, nothing under `~/.claude` is created |
| `includes_follow_boxes` | `claude-calendar` off: `calendar-check` not linked; on: linked |
| `missing_clone_reported` | clone absent and `CONFIGME_NO_CLONE=1`: a `bad` line names the path, exit status as for any other failed feature, later sections still run |
| `check_delegates` | `--doctor` after an install shows AdaptiveDesign's `ok` lines in its claude section, with no `bad` line there that AdaptiveDesign's own `--check` lacks |
| `check_fails_unlinked` | `--doctor` on an empty home with `claude` on reports `bad` |
| `other_bin_links_kept` | `kitty-nvim` and `tmux-attach-or-new` are still linked |

## M2: install.ps1 delegates

Tier T2, medium. Needs T and `AD:M5`. Files: `install.ps1`.

The same change in PowerShell (the section near line 306). No PowerShell
on this machine, so no suite: checked by reading at Checkpoint C and by the
owner on Windows.

## M3: remove what moved

Tier T2, medium. Needs M1, M2 and `AD:B` (the cut-over). Files: `claude/`,
the Claude files in `bin/`, `github-templates/`, `README.md`,
`features.md`, `docs/windows.md`, `.gitignore`.

Added at AdaptiveDesign's Checkpoint B, to be done first: `install.sh`
and `install.ps1` always pass `--include core` (`-Include core`) ahead of
the boxes' includes, so that the boxes alone decide and AdaptiveDesign's
includes file is never the fallback. Correct the comment on
`claude_includes` to match.

Delete `claude/`, `github-templates/` and every file in `bin/` that
AdaptiveDesign's `core/bin` now holds. Before deleting, confirm with
`readlink -f` that no path under `~/.claude` or `~/.local/bin` still
resolves into them; if one does, stop and report. Update the docs to say
where the Claude configuration lives and how it is installed. Drop the
`claude/skills/synced/` line from `.gitignore`.

Suite `removed`:

| Case | Asserts |
|---|---|
| `moved_paths_gone` | no tracked file under `claude/` or `github-templates/`; none of AdaptiveDesign's `core/bin` names in `bin/` |
| `no_dangling_refs` | no `claude/skills`, `claude/rules`, `github-templates/` or `bin/claude-` in tracked files outside `docs/SPLIT.md`, `docs/PROJECT_LOG.md`, `docs/log.jsonl` |
| `readme_names_dependency` | `README.md` names AdaptiveDesign and how it is fetched |
| `delegate_still_passes` | the `delegate` suite passes |

## C: checkpoint

T1 reads every merge, runs both suites, and opens the PR to `main`.
PR #1 (`claude/parallel-loop-t3-review`) is the base of `frame/split` and
is still waiting for its T1 proofread; it merges first.
