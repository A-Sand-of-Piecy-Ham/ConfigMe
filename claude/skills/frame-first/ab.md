# Running one milestone twice

Read this when the user wants to know whether a cheaper tier, or a lower
effort, could have done a milestone. It is not needed to design, build or
review a frame.

## What this is for

The tier and effort written in `frame.toml` are guesses made before any code
ran. Running one real milestone a second time on something cheaper, from the
same starting commit and the same rules, turns one guess into a measurement.
The steps below are the current way of doing that. Nothing here has been run
to its end yet (see Status); correct it from the first run.

Change one thing per run: the tier or the effort, never both, and never the
rules file. Two changes and the result says nothing about either.

Pick a milestone where a wrong answer shows: tight tests, formulas in the
contracts. On a milestone the tests leave open (AI behaviour, feel), both
runs pass and the difference is a matter of taste that only a T1 read can
judge, which costs more than the experiment saves.

## 1. Seal the second run off

The second run must not be able to read the first. A worktree is not
enough: it shares the repo's branches, and `git show m3-combat:<file>` is
one command away. Cut a sealed copy instead:

```bash
~/.claude/skills/frame-first/ab-clone <repo> <new dir> [base commit]
```

`<new dir>`: outside the repo, for example `../ab/<repo name>`. Give the
base commit when the default branch has moved since the first run started:
`git merge-base main <first run's branch>`. Success is a line starting
`sealed copy:`; the script checks the seal itself and exits non-zero when
the copy can still read anything later than the base.

Two things the copy does not seal, so do them by hand:

- Keep the original repo's main checkout on the default branch until the
  second run has finished. On the first run's branch, its code is an
  ordinary file a wandering `Read` could open.
- Do not merge the first run before the second has finished, for the same
  reason.

## 2. Run it

The user starts a new session with the sealed copy as its folder, on the
tier or effort under test, and gives it the same request the first run got.
The agent will say that the milestone names another tier, as its rules tell
it to. The user answers: go on.

Do not tell the second session that it is a comparison or that another run
exists.

## 3. Bring the result back

In the original repo, with `<branch>` the branch the second run made:

```bash
git fetch <sealed copy dir> <branch>:ab/<milestone>-<what changed>
```

For example `git fetch ../ab/armor_core m3-combat:ab/m3-t3`.

## 4. Compare without reading code

For each of the two branches, in a worktree of the original repo
(`git worktree add .claude/worktrees/<name> <branch>`):

| Measure | How |
|---|---|
| Finished? | `scripts/check Mx`: PASS, HELD or FAIL, and the pass count |
| Runs of the check | the `Check:` line of the agent's report |
| Size | `git diff --shortstat <base> <branch>` |
| Rows | `git diff <base> <branch> -- docs/log.jsonl \| grep -c '^+{"kind":"gap"'`, and the same for `dispute`, `subtask`, `friction` |
| Tokens | the `usage` records of each session's transcript, in `~/.claude/projects/<slug>/`; output tokens are the ones that differ |

Each branch runs its own copy of `scripts/check`. Both started from the
same commit, so it is the same script and the two results compare.

Then decide:

- **The cheaper run failed or was held, and the first passed.** Done. The
  milestone's tier stands. Record it.
- **Both pass.** Now the cheaper diff is worth a T1 read, with the code
  checklist in `review.md`. Read it before the dearer one, and read the
  dearer one only where the two disagree: the same gap filled two ways is a
  contract that needs a sentence, whichever run wins.
- **Both pass and the cheaper holds up.** Merge the cheaper one. Lower the
  tier or effort of the remaining milestones of that kind in `frame.toml`.

A gap one run logged and the other did not is a finding about the quiet
run: it met the same silence and chose without saying so.

## 5. Record and clean up

- One row per run in the research log's "Effort and tier, measured" table.
- Settle the log rows of the branch that is merged. Rows of the branch that
  is dropped are not merged, but a gap found only there goes into the
  contract.
- Delete the losing branch and the sealed copy once the row is written.
  Look at what is in the copy before deleting it.

## Status

Written 2026-11-10 for a second run of a combat milestone first done on T2
at medium effort. `ab-clone` was run and its seal checked. Steps 2 to 5 have
not been run: revise them from that comparison, including whether the
mechanical measures in step 4 were enough to decide without reading both
diffs.
