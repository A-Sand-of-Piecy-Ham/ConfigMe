# Project log

Decisions made, what is still to do, and what has been finished. Newest
first within each section.

## Decisions

| Date | Decision | Why |
|---|---|---|
| 2026-11-11 | The tests drive the installer under `env -i` in scratch homes, with shims that block downloads and `sudo`, and install AdaptiveDesign from a local clone, never from GitHub | Nothing a test does may reach the real home or the network. The GitHub clone path is left to the owner (TODO below) |
| 2026-11-11 | The Claude configuration moves to AdaptiveDesign; ConfigMe's installer clones it beside this repo and calls its installer | Owner's call. Details and reasons in [SPLIT.md](SPLIT.md) |

## Rows written during the work

What implementers record while building (contract gaps they filled, frozen
things they dispute, work outside their milestone, public items they added,
friction) is not in this file. It is one JSON object per line in
[log.jsonl](log.jsonl), so that `scripts/check` can read it and it can be
queried:

```bash
jq -c 'select(.settled == null)' docs/log.jsonl        # still open
jq -r 'select(.kind == "gap") | [.milestone, .where, .chose, .settled] | @tsv' docs/log.jsonl
```

The row format is in [AGENTS.md](../AGENTS.md#log-rows). At each checkpoint
the reviewer adds a `settled` field to every open row. A ruling that needs
more than a phrase goes in "Decisions" above.

## TODO

- No test runs M1's clone of AdaptiveDesign from GitHub: every case sets
  `CONFIGME_NO_CLONE=1`. The owner checks it on a fresh machine before
  Checkpoint C.
- Two frozen files still name the old paths (`scripts/check` line 11 and
  M3's `what` in `frame.toml`), so M3's `no_dangling_refs` cannot pass as
  written. Settle the second dispute row of milestone T before M3 starts.

## Done

- 2026-11-11: M3, `claude/`, `github-templates/` and the Claude hooks in
  `bin/` removed: they live in AdaptiveDesign now. Both installers always
  pass `--include core` (`-Include core`) ahead of the boxes' includes. The
  README says where the Claude configuration lives and how it is fetched.
- 2026-11-11: M2, `install.ps1` delegates its claude section to
  AdaptiveDesign's `install.ps1` the same way, with `-Include` per
  `claude-*` box. Unrun: no PowerShell here; read at Checkpoint C and tried
  by the owner on Windows.
- 2026-11-11: M1, `install.sh` delegates its claude section to
  AdaptiveDesign: clones it beside this repo, runs its `install.sh` with one
  `--include` per `claude-*` box, and the doctor shows its `--check`. Three
  new boxes in `features.md`: `claude-calendar`, `claude-ticktick`,
  `claude-dotfiles`.
- 2026-11-11: T, the oracle: `scripts/test` with the `delegate` and
  `removed` suites, and the `AGENTS.md` slots filled.
- 2026-11-11: frame written.
