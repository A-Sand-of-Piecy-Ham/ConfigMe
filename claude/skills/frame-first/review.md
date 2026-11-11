# Checkpoint review

Read this when a checkpoint is reached, or when asked to review what another
model built inside a frame. It is not needed while designing or building one.

## What a checkpoint decides

Two things, in this order of importance:

1. **What in the frame or the process made the work worse or dearer than it
   had to be.** A flaw in the frame repeats on every milestone after this
   one. Fix it now, in this session, without waiting to be asked. The user's
   rule (2026-11-10): "Improving future work is always priority over current
   work."
2. **Whether this milestone's work is accepted.**

The steps below are the current way of getting those two answers. Drop a step
that is not producing findings on the task at hand, and say so.

## Before reading anything

- **Tier.** `frame.toml` gives the checkpoint's tier, normally T1. If this
  session is a lower tier (`~/.claude/rules/model-tiers.md` says which model
  is which), tell the user and wait for a yes. The steps here are written so
  that a T2 model can follow them when it is the top one.
- **Session.** Review in a fresh session, never the implementer's. Its
  context is the wrong model's cache and is full of the work being judged.
  One review session may take several milestones in a row, but do not keep
  it alive across days: what it knows belongs in this file and the research
  log, where the next session can read it.
- **Re-read this file after a compaction.** The summary keeps the task and
  drops the steps. The second review ran its last third from the summary
  alone and skipped the tool rule below.
- **Do not load `introspection` or `research-log` yet.** Each is loaded at
  Finishing, and only if the review found something for it (step 4 there
  says what). Loaded at the start, both bodies rode through every call of
  the M3 review before either had anything to file. Neither fires by
  itself in a review turn (first checkpoint, 2026-11-10), so step 4 is the
  trigger: do not skip it.
- **Few calls.** `~/.claude/rules/call-economy.md` applies in full: batch
  reads, bound output, checks once at the end, upkeep in one batch.
- **Effort: medium.** At the first checkpoint every finding came from reading
  the diff or running a command, none from thinking longer. Spend on another
  check, not on deeper thought. One observation; revise it.

## What to read, in this order

1. `git log --oneline main..<branch>` and `git diff main...<branch>`. A
   milestone merged before its checkpoint (allowed, so that what needs it
   could start) is read from its merge commit: `git log --merges --oneline
   <last checkpoint>..main` lists them, and `git diff <merge>^1 <merge>` is
   one milestone's diff. Work committed straight onto `main` with no branch
   is a process finding; diff it from the last checkpoint commit.
2. The open log rows:
   `jq -c 'select(.settled == null)' docs/log.jsonl`. Gaps, disputes,
   subtasks, deviations and friction are all there.
3. Not the finish check, yet. It runs once, at Finishing, with your tests
   in: that run covers the implementer's claim as well. Run it now only for
   a reported `HELD`, or when the report and the log disagree.
4. The contract (module docs and doc comments) of each file in the diff.
5. For `HELD`: the disputed test against its contract, before anything
   else. Work it out by hand or run it; decide who is right. The milestone
   cannot be judged until that is settled.

Do not read the implementer's prose summary beyond its fixed report lines,
and do not read files outside the diff unless a finding sends you there. A
weak model's words are a strong model's input tokens.

## Code review

Look for each of these. For every one, the check is something you can point
at in the diff:

- edited, skipped or deleted tests
- bodies special-cased to the test inputs
- stubs still present (grep for the stub marker)
- helpers duplicated across modules
- contract clauses no test covers
- frozen signatures changed with no log entry
- **gaps filled with no log row.** For each branch in the diff that handles a
  special case (a zero, a missing item, a conflict), find the contract clause
  that asks for it. No clause and no row in the log means the implementer
  guessed silently. At the first checkpoint the log said "nothing needed
  guessing" and the diff held four such branches. At the second, with rows
  required by the check, all four gaps had rows written before the code.
- **rows that do not match the code.** A log row is the implementer's claim
  about its code, not evidence. For each row that describes behaviour, find
  the lines that do it. A reviewer that took a row on trust reported "both
  runs chose the same" where one run's code did something else (M3, 2026-11).

Where two readings of the code disagree, or a finding rests on what the code
does over several ticks, run it instead of reasoning about it: a throwaway
test in a scratch clone (`git clone <repo> <scratchpad>/rc`), run against
the branch, printed with `--nocapture`, never committed. In the M3 reviewer
comparison one such test of about 70 lines produced the only finding the
other reviewer missed and put numbers on three more.

## Process review

Run this at every checkpoint without being asked. The implementer's session
transcript is the evidence; list its tool calls instead of reading it:

```bash
jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use")
  | [.name, ((.input.file_path // .input.command // .input.skill // "") | tostring | gsub("\n";" ") | .[0:90])]
  | @tsv' ~/.claude/projects/<project-slug>/<session-id>.jsonl
```

The slug is the session's folder with every `/` turned into `-`, so it
starts with a dash: write `ls -t ~/.claude/projects/./-home-...`, or `ls`
reads it as an option. Both M3 reviewers spent three calls on that. The
newest `.jsonl` files in that directory are the recent sessions. If the
transcript cannot be found, use the commit, the log and the report, and say
the process review was partial.

| Look for | How it shows | Fix goes in |
|---|---|---|
| Wasted reads | `Read` of a file the milestone's files do not use. Reading the types and helpers they use is expected: the second milestone needed four such files | A tighter reading list for the next milestones |
| Noise reported | Report lines beyond the fixed format; remarks on things that are normal in a frame | The "normal here" list in the rules file |
| Undocumented guesses | The code-review item above | Backfill the rows; if the rules did not make logging mechanical, fix the rules |
| Skills or hooks bypassed | Files changed through `Bash` (`sed -i`, a heredoc, a redirect); a `Skill` call that should be there and is not; commits on the default branch | The rules file, or a hook when a rule would not be enough |
| Shared checkout | Commits made on a milestone branch in the main checkout (the check's `tree` gate should have refused it); two branches with edits to one file | The worktree step in the rules file; a missing entry in a `needs` list |
| Finish condition not passable | The implementer explains failures, or stops short of the stated command | The check command |
| Friction rows | `friction` rows in the log, the implementer's and your own (`"by":"review"`, see "What the method itself costs") | The cause; then settle the row |
| Subtask rows | `subtask` rows in the log, and files in the diff outside the milestone's list with no row | Keep it, or undo it when it departs from the plan. Several in one area mean the milestone's file list or the frame is wrong there |
| Effort and tier | The report's `Model:` line against `frame.toml` | The milestone's `effort`, and a row in the research log's table |

Each fix goes into the repo's rules file. When it would recur in another
repo, it also goes into `template/` or `SKILL.md` here, in the same session,
with one clause of evidence. The same question goes to every change the
repo has made to a file it copied from `template/` (`scripts/check`,
`AGENTS.md`): would another repo want it? Tell the user each fix in one
line. Note each fix as you find it and make them all in one batch at
Finishing, with the template copies, this skill's status notes and the
research log: they do not depend on each other, and one at a time they
cost the M3 review about fifteen calls.

The reviewer follows the implementer's tool rule: project docs change
through Edit and Write, never `sed`, a heredoc or a redirect. The second
review broke it twice and the docs hook caught it.

Ask first only when a fix would reverse something the user decided (a frozen
item, a model assignment, a push or branch rule). Otherwise make it.

Cutting noise never means dropping a finding. A finding is anything that
changes what someone does next; it stays in the report however short the
report is.

## What the method itself costs

Every rule in a frame is paid for on every milestone: tokens to read it,
calls to obey it, the user's attention to answer it. The reviewer is the one
session that sees both the rules and what they cost, so it keeps that account.
The aim is fewer steps, not more records: this section earns its place only
by getting something else cut.

1. **Friction rows of your own.** When a step of this file, the rules file,
   a hook or a command costs you time or produces nothing, add a row (with
   the other rows you write, in one edit at Finishing):

   ```json
   {"kind":"friction","milestone":"M3","by":"review","what":"Three calls to find the implementer transcript: the slug starts with a dash"}
   ```

   `by` marks it as the reviewer's. `milestone` is the one under review, or
   the checkpoint's id. Optional, as for implementers: no row when nothing
   cost anything.
2. **Measure, at the end.** For your session and each implementer session
   (`<id>` is `$CLAUDE_CODE_SESSION_ID` for your own; the `*` spares you the
   project slug):

   ```bash
   t=$(ls ~/.claude/projects/*/<id>.jsonl)
   jq -s -c '[.[]|select(.type=="assistant")|{id:.message.id,u:.message.usage}]|unique_by(.id)
     |{calls:length, out:(map(.u.output_tokens)|add), start:(.[0].u|.input_tokens+.cache_read_input_tokens+.cache_creation_input_tokens),
       peak:(map(.u|.input_tokens+.cache_read_input_tokens+.cache_creation_input_tokens)|max)}' "$t"
   ```

   `start` is what the session held before its first tool call: rules,
   tool definitions, skill list. `peak` near the compaction threshold means
   the milestone or the review is too big for one session. For the user's
   effort, count the times they had to answer something that was not a
   decision about the product ("go on", a permission, a restated rule).
3. **Name one thing to cut.** From the rows and the numbers, pick the rule,
   step or required output that cost the most for the least, and cut or
   merge it in this session, with one clause of evidence. A step of this
   file that produced no finding in two reviews running is a candidate by
   default. Ask first only where the cut reverses a user decision. "Nothing
   to cut" is an allowed answer; say what you looked at.
4. **A weak tier that drops a rule needs a check, not a longer rule.** When
   an implementer ignored something the rules file states (rows written
   late, files changed through the shell, unformatted code), do not restate
   it more firmly. Move it into `scripts/check` or a hook, where it cannot
   be skipped, and then shorten the rule to one line. The smallest tier
   followed every gate in the M3 comparison and dropped three rules that
   had none.

The numbers go in the research log's table (Finishing, step 4) and in one
line of the report.

## Write the findings down before fixing anything

Once the reading is done, put the findings in the repo: a `settled` field on
each log row that is already decided, and a short list in the project log's
TODO for everything else. Then fix. A review's context is at its largest
exactly when the fixing starts, and a compaction or a usage limit there
loses findings that exist only in the conversation.

Hold automatic compaction while the findings are only in the conversation.
At the start of the review:

```bash
mkdir -p ~/.claude/compact-notes && echo "review of Mx: findings not yet written" > ~/.claude/compact-notes/"${CLAUDE_CODE_SESSION_ID:?}".hold
```

and as soon as the findings are in the repo, delete that file. The
PreCompact hook refuses an automatic compaction while it exists (a manual
`/compact` still works, and the hold expires after two hours). The second
review was compacted mid-task and lost its place in this file. Built
2026-11-10 and tested on the hook's exit codes only: not yet seen against a
real automatic compaction.

When the context is large at that point (over about 150k tokens) and the
fixes are more than a few edits, stop after writing the findings and tell
the user to start a fresh session for the fixes. The findings file is its
brief.

## What to do with each finding

Every log row ends the review with a `settled` field: a phrase saying what
was decided ("kept; contract now states it", "undone", "test corrected").

| Finding | Do |
|---|---|
| A gap the implementer filled soundly | State it in the contract, add a test that pins it, settle the row as kept |
| A gap filled badly | Settle the contract, add a test that fails, send the milestone back |
| A dispute the implementer got right | Correct the frozen thing, add a case that would have caught it, settle the row. Set the milestone's status from `"held"` to `"done"` once the check prints PASS |
| A dispute the implementer got wrong | Say why in the row's `settled` field and send the milestone back |
| A subtask that departs from the plan | Undo it, or move it to where the plan wants it; say which in the row |
| A wrong or missing test | Fix or add it. Tests are the reviewer's |
| A bug the tests missed | Add a test that fails and send it back to the implementer's tier |
| Small code-quality points (repetition, a missing private doc comment, an unreachable branch) | Accept and record them in the log, or list them as a clean-up item at the head of the next milestone of the same tier. Do not hand-fix |
| The architecture is wrong | Change the frame. Do not let patches collect around it |

Hand-fixing implementation in the review tier ends the cheap loop: T1 costs
several times the implementer's tier.

A test added for behaviour that already exists must pass against the current
code. Run it; a test that was never run is a guess.

**Sending a milestone back** (first done in the M3 review, 2026-11-11):

1. Change the contract (the doc comment) first, then add the failing test
   for it. Bundle the small code-quality points into the same send-back.
2. In the milestone's entry in the milestone doc, add a "Sent back" table:
   failing test, contract clause, what to change. That table is the
   implementer's whole brief.
3. Set the milestone's `status` back to `""` and delete its merged branch
   (`git branch -d`), or the list shows it as `busy` and names something
   else as next.
4. `scripts/check Mx` must end in `FAIL Mx` on exactly the tests you added,
   with every other gate ok.
5. Prove each failing test can pass: apply the fixes in a throwaway clone
   and run the suite. A send-back test that cannot pass costs the
   implementer's tier a whole session.
6. **A proven patch under about 50 lines is applied, not sent back** (the
   user's decision, 2026-11-11: M3's was 25 lines and a second session for
   it was not worth its cost). Steps 2 to 4 are then skipped: write the
   tests, apply, PASS. Send back only what is too large to prove this way.

**One review per milestone.** M3 had a second build, two findings-only
reviewers and then the real review: three T1 sessions for one milestone,
which the user called too much. A second build or a second reviewer is an
experiment on the method. Run one only when the user asks for it, and fold
its reading into the one real review.

**Where a review's tokens go** (measured on the M3 review, 82 calls over
two sessions; weights: cache read 0.1, one-hour cache write 2, output 5
times input). The first turn: cache writes about 590k, cached re-reading
of the conversation about 507k, output about 335k. So the count of calls
and the size of the context at each one matter more than what is written.
No single file was to blame. The largest results, about 10k tokens each,
were Bash output too big for the harness (several source files in one
`cat`), spilled to a file and then read back whole. Forty-one calls ran at
high effort in a session set to medium, because a skill's header pinned it
(`skill-forge` now forbids that). What moves it: the call rules in
`~/.claude/rules/call-economy.md`.

## Finishing

1. The finish check prints PASS with your changes in. For a milestone sent
   back it prints FAIL on the send-back tests only, and the newest finished
   milestone before it prints PASS.
2. Commit, then merge any milestone branch not yet in the default branch,
   with `--no-ff`. Held milestones are merged too; what the review owes
   them is a settled dispute. Remove the worktrees of merged branches
   (`git worktree list`, then `git worktree remove <path>`; look for
   uncommitted files in each first). Push only as the user's standing rules
   allow.
3. Set the checkpoint's `status` in `frame.toml`. No open rows are left:
   `jq -c 'select(.settled == null)' docs/log.jsonl` prints nothing.
4. Upkeep, in one batch. Always: the cost measurement, and one row per
   reviewed milestone and one for this review in the research log's
   "Effort and tier, measured" table (the table needs no skill loaded).
   Load `research-log` when the review saw something about a skill, hook or
   rule that is not already in the log. Load `introspection` when the
   process review found an implementer dropping or misreading a rule, or
   the user corrected this session: its filing table says where each
   finding goes. Nothing of either kind: load neither.
5. Report: verdict, findings that need the user's decision, frame changes
   made, and one line on cost: this review's calls, output tokens and peak
   context, and what was cut. Then give the `Next:` line `scripts/check` prints, which names the
   tier the next milestone needs. If a coming milestone meets the
   conditions in `SKILL.md` for a second run on a cheaper setting, say so
   in one line.

## Review ladder (untested)

Where several T3 milestones sit between two checkpoints, a T2 session can
review each one with the code-review list alone, leaving the process review
and anything frozen to the checkpoint. This was proposed on 2026-11-10 and
has not been run. Try it on the first such stretch and record whether the
T2 review caught what the checkpoint then found.
