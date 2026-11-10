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

- **Model.** If the milestone table names a review tier above this session's
  model, tell the user and wait for a yes. "Strongest" means strongest
  available today; the steps here are written to be followed by a mid-tier
  model when that is the top one.
- **Session.** Review in a fresh session, never the implementer's. Its
  context is the wrong model's cache and is full of the work being judged.
- **Load `introspection` and `research-log` now.** Neither fires by itself
  in a review turn: this skill takes the trigger (first checkpoint,
  2026-11-10, both were missed until the user asked why). A checkpoint is a
  skill being tested, which is what both exist to record.
- **Effort: medium.** At the first checkpoint every finding came from reading
  the diff or running a command, none from thinking longer. Spend on another
  check, not on deeper thought. One observation; revise it.

## What to read, in this order

1. `git log --oneline main..<branch>` and `git diff main...<branch>`. If the
   work was committed on `main`, diff from the last checkpoint commit, and
   record the missing branch as a process finding.
2. The project log's agent-written sections: gaps filled, decisions needed,
   friction, deviations.
3. The finish check, run by you. Expected: its PASS line. Do not take the
   implementer's word for it.
4. The contract (module docs and doc comments) of each file in the diff.

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
  guessing" and the diff held four such branches.

## Process review

Run this at every checkpoint without being asked. The implementer's session
transcript is the evidence; list its tool calls instead of reading it:

```bash
jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use")
  | [.name, ((.input.file_path // .input.command // .input.skill // "") | tostring | gsub("\n";" ") | .[0:90])]
  | @tsv' ~/.claude/projects/<project-slug>/<session-id>.jsonl
```

The newest `.jsonl` files in that directory are the recent sessions. If the
transcript cannot be found, use the commit, the log and the report, and say
the process review was partial.

| Look for | How it shows | Fix goes in |
|---|---|---|
| Wasted reads | `Read` of a file not on the milestone's reading list | A tighter reading list for the next milestones |
| Noise reported | Report lines beyond the fixed format; remarks on things that are normal in a frame | The "normal here" list in the rules file |
| Undocumented guesses | The code-review item above | Backfill the rows; if the rules did not make logging mechanical, fix the rules |
| Skills or hooks bypassed | Files changed through `Bash` (`sed -i`, a heredoc, a redirect); a `Skill` call that should be there and is not; commits on the default branch | The rules file, or a hook when a rule would not be enough |
| Finish condition not passable | The implementer explains failures, or stops short of the stated command | The check command |
| Friction rows | The log's friction section | The cause; then delete the row |

Each fix goes into the repo's rules file. When it would recur in another
repo, it also goes into `agents-template.md` or `SKILL.md` here, in the same
session, with one clause of evidence. Tell the user each fix in one line.

Ask first only when a fix would reverse something the user decided (a frozen
item, a model assignment, a push or branch rule). Otherwise make it.

Cutting noise never means dropping a finding. A finding is anything that
changes what someone does next; it stays in the report however short the
report is.

## What to do with each finding

| Finding | Do |
|---|---|
| A gap the implementer filled soundly | State it in the contract, add a test that pins it, mark the log row kept |
| A gap filled badly | Settle the contract, add a test that fails, send the milestone back |
| A wrong or missing test | Fix or add it. Tests are the reviewer's |
| A bug the tests missed | Add a test that fails and send it back to the implementer's tier |
| Small code-quality points (repetition, a missing private doc comment, an unreachable branch) | Accept and record them in the log, or list them as a clean-up item at the head of the next milestone of the same tier. Do not hand-fix |
| The architecture is wrong | Change the frame. Do not let patches collect around it |

Hand-fixing implementation in the review model ends the cheap loop: the
review tier costs several times the implementer's.

A test added for behaviour that already exists must pass against the current
code. Run it; a test that was never run is a guess.

## Finishing

1. The finish check prints PASS with your changes in.
2. Commit, then merge the milestone branch into the default branch. Push only
   as the user's standing rules allow.
3. Tick the checkpoint in the milestone list.
4. File what `research-log` and `introspection` turned up.
5. Report: verdict, findings that need the user's decision, frame changes
   made. Then say which model the next milestone needs.

## Review ladder (untested)

Where several small-model milestones sit between two checkpoints, a mid-tier
session can review each one with the code-review list alone, leaving the
process review and anything frozen to the checkpoint. This was proposed on
2026-11-10 and has not been run. Try it on the first such stretch and record
whether the mid-tier review caught what the checkpoint then found.
