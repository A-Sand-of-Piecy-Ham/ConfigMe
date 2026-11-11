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
exists. The measurement is of what that tier does with the frame as an
ordinary implementer; a model that knows it is being compared logs and
reports for the comparison. Nothing it writes can leak into the real
history unasked: its log rows and its commit exist only on its branch, and
only the branch that wins is merged.

Expected in the second session, and not a fault:

- It names the tier mismatch and may go on without waiting for an answer.
  The first second run did, and put the mismatch in its report, not the log.
- A push at the end fails, when the user's standing rules tell agents to
  push feature branches. The sealed copy has no remote. That is the seal.

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
| Tokens | the `usage` records of each session's transcript, in `~/.claude/projects/<slug>/` (the sealed copy has its own slug): `jq -s '[.[]\|select(.type=="assistant")\|{id:.message.id,u:.message.usage}]\|unique_by(.id)\|map(.u.output_tokens)\|add' <session>.jsonl`. Output tokens and the number of calls are the ones that differ |
| Things no gate checks | the formatter in check mode, in each worktree; how each run wrote its log rows (list the transcript's tool calls as `review.md` shows: Edit, or a shell redirect after the code was done) |
| Quiet gaps | each `gap` row one run has and the other lacks: grep the quiet run's diff for the function named in the row's `where` and see which way it went |

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

## Two reviewers

The same idea measures a review tier: would a T2 review have found what the
T1 review found? It matters because T1 is whichever model is strongest and
affordable, and that changes.

A review cannot be compared the way a build is. A full review fixes the
frame, settles rows, merges, and edits this skill and the research log,
which the other reviewer would then read. So both reviewers do the first
half only: read, and write the findings down.

1. Cut one sealed copy per reviewer, each holding the branches under review:

   ```bash
   ~/.claude/skills/frame-first/ab-clone <repo> ../ab/review-<tier> "" main <branch>...
   ```

2. The user starts one fresh session per copy, on the tier under test, and
   gives both the same request. Vary the milestone and branch names:

   > Review M3. It was built twice from the same commit: branch `m3-combat`
   > (T2, medium effort) and branch `ab/m3-t3` (T3, medium effort). Follow
   > the frame-first review file, and `ab.md` from its step 4. Stop where
   > the review file says to write the findings down: put every finding,
   > and which branch you would merge, in `docs/review-M3.md`, commit it on
   > a branch named `review-m3`, and change nothing else in this repo or
   > outside it.

   Neither session is told about the other. The lower tier will say the
   review names T1; the user answers: go on.
3. In the original repo, fetch both findings files
   (`git fetch ../ab/review-<tier> review-m3:ab/review-m3-<tier>`). A third
   session, on the strongest tier and not either reviewer, lists every
   finding from both files and checks each against the code: real or not.
4. Score: real findings only one reviewer made, findings that were not
   real, whether the verdicts agree, output tokens of each. Record a row
   per reviewer in the research log's table.
5. The real review then runs once, in the original repo, with the checked
   list as its brief.

Leave the mechanical findings of an earlier build comparison out of this
skill's status notes until the reviewers have run: both read these files.
The first run broke this: the Status below named three of them, and one
reviewer pointed out that neither could then be credited with finding them.

Three more things the first run got wrong; do them next time:

- **Same effort for both.** The first pair ran T1 at low against T2 at
  medium, so the result does not separate tier from effort. Say the effort
  in step 2's request to the user, and check it afterwards
  (`grep -o '"effort":"[a-z]*"' <session>.jsonl | sort | uniq -c`).
- **Let the request allow the compaction hold.** "Change nothing else in
  this repo or outside it" made both reviewers skip the hold file
  `review.md` asks for, and one was compacted. Add: "the hold file in
  `review.md` is allowed".
- **Expect about 150k tokens of context** for a two-branch review: both
  sessions started near 64k before reading anything and added 85k to 95k.
  That is at the automatic compaction threshold. Have each reviewer commit
  the findings file before its last checks, as both happened to.

## Status

Written 2026-11-10 for a second run of a combat milestone first done on T2
at medium effort. `ab-clone` was run and its seal checked. Steps 2 to 4 then ran
once, with T3 at medium as the second run: both passed with the same test
count, so the mechanical measures did not decide it. What told the runs
apart was outside the check: the T3 run left unlogged several gaps the T2 run logged, wrote its rows through a shell
redirect after the code, and left unformatted code. The last three rows of
the table come from that. The T1 read and the decision ran 2026-11-11: the
T2 build was merged, the T3 build dropped.

"Two reviewers" was written 2026-11-11. Steps 1 to 4 ran once on that
build pair (T1 at low effort against T2 at medium; rows in the research
log). Both reached the same verdict. The T1 run made the one finding that
changes a decision and the other missed; the T2 run stated two things the
code contradicts. Step 5 then ran once, from the checked list; its cost is
a row in the research log. The clean-up in "5. Record and clean up" was
left to the user: the app's auto mode refuses deletions.
