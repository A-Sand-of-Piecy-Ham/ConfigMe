# Rules for agents

This repo is a **frame**: the design is fixed, most bodies are stubs, and
tests say when each one is right. Your job is to fill bodies in, one
milestone at a time. You do not see the conversation that designed this; the
reasons are in <design doc>.

Asked to **review** a milestone or run a checkpoint instead? These are the
implementer's rules. Load the `frame-first` skill and follow its review file;
read this page only to know what the implementer was told.

## Normal here: do not report, do not fix

- Most bodies are `<stub marker>`. That is the design.
- `<full test command>` fails for every milestone after yours. Use
  `scripts/check`, which runs only what should pass.
- <anything else that looks broken and is not>

## The loop

1. Run `scripts/check` with no argument. Its last line names the next
   milestone with its tier and effort, for example `Next: M3 (T2, effort
   medium)`. One milestone per session.
   - Tiers (T1, T2, T3) say which model does the work. If you are a different
     tier, or do not know your tier, tell the user before starting.
   - If the line names a checkpoint, stop: that is a review, not yours.
2. Make a branch from `<default branch>` named for the milestone, for example
   `git switch -c m3-<name> <default branch>`. Never commit on
   `<default branch>`; the reviewer merges your branch at the checkpoint.
3. Read these first:
   - the milestone's entry in <milestone doc>;
   - the files it lists (the contract for each function is its doc comment);
   - the milestone's test file;
   - the <design doc> sections named on its `Read:` line, if it has one.

   Then read what those send you to: the types, constants and helpers your
   files use. Leave the rest of the repo unread.
4. Replace each stub for the milestone. Change files with the Edit and Write
   tools, not with `sed`, a script or a shell redirect: the tools show the
   reviewer a clean diff and trigger the project's checks.
5. Keep the log as you go. `docs/log.jsonl` holds one JSON object per line;
   add yours at the end, **at the moment the thing happens**, before writing
   the code it concerns. The kinds are under [Log rows](#log-rows). Every
   milestone needs at least one `gap` row.
6. Run `scripts/check Mx` (x = your milestone) until its last line is
   `PASS Mx`, or `HELD Mx` (see [Frozen](#frozen)).
7. Update the docs the change made wrong: your milestone's `status` in
   `frame.toml` (`"done"` after PASS, `"held"` after HELD) and its row in
   <status table>. Do not rewrite anything else in them.
8. Commit on your branch, in this form:

   ```
   M3: <what, imperative>

   Gaps: <one line per gap row, or "none">.
   Disputes: <one line per dispute row, or "none">.
   Subtasks: <one line per subtask row, or "none">.

   <the Co-Authored-By line your session gives you>
   ```

9. Report to the user with these lines and nothing more:

   ```
   Milestone:  M3, branch <name>, commit <short hash>
   Model:      <your model>, effort <level, or "not known">
   Check:      PASS M3 (<n> tests), after <n> runs of scripts/check
   Gaps:       <count>
   Disputes:   <count>, or none
   Subtasks:   <count>, or none
   Friction:   <count>, or none
   Next:       <the "Next:" line scripts/check prints now>
   ```

   If the next thing is a **checkpoint**, or your milestone is HELD, stop
   there; do not start the next milestone.

## Log rows

One object per line in `docs/log.jsonl`. Keep each field under 300
characters. Leave out `settled`; the reviewer adds it.

| `kind` | Add one when | Fields besides `kind` and `milestone` |
|---|---|---|
| `gap` | A contract or test does not say what to do and you have to choose | `where`, `silent_on`, `chose` |
| `dispute` | A frozen thing looks wrong (see [Frozen](#frozen)) | `found`, `would_change`, and `test` if it is a test |
| `subtask` | You did work outside the milestone's file list | `what`, `why` |
| `deviation` | You added a public item or <a tuning value> | `what`, `why` |
| `friction` | The rules, docs, commands or tests cost you time | `what` |

Two examples; yours will differ in every field but `kind`:

```json
{"kind":"gap","milestone":"M2","where":"<file and function>","silent_on":"<the case the contract did not cover>","chose":"<what the code now does>"}
{"kind":"dispute","milestone":"M2","test":"<test function name>","found":"<why the test contradicts its contract>","would_change":"<the fix you would make>"}
```

A milestone that needed no choices gets
`{"kind":"gap","milestone":"M3","chose":"none"}`.

## Frozen

Do not change these. Each is something the rest of the frame was built on,
and a quiet change breaks work that has not been written yet.

- <tests and fixtures>
- <public signatures, fields, variants>
- <conventions and orders other code depends on>
- `scripts/check` and the `[check]` table of `frame.toml`.

If a frozen thing looks wrong (a test that contradicts its contract, a
signature you cannot implement, a formula that gives nonsense): **stop work
on that item**, add a `dispute` row saying what you found and what you would
change, and carry on with the rest of the milestone. Never bend the code to
fit a test you believe is wrong, and never special-case a test's inputs. The
tests were written before any of this code ran, so some of them probably are
wrong. That is expected, and it is the reviewer's to fix.

When the disputed thing is a test, name it in the row's `test` field.
`scripts/check` then ends in `HELD Mx` instead of `FAIL Mx` once that test
is the only thing failing. HELD is a finished milestone waiting on the
reviewer: set its status to `"held"`, commit, report, stop.

## Work outside the milestone

The file list is where the work is expected, not a fence. If the milestone
cannot be finished without something else (a private helper in another
module, a bug in an earlier milestone's body), do it, keep it as small as
will work, and add a `subtask` row saying what and why. Do not wait for a
review to ask. The reviewer reads the rows at the next checkpoint and may
undo one that departs from the plan, so prefer the smallest change that lets
you continue.

This does not unfreeze anything: a frozen item that is in your way is a
`dispute`, not a subtask.

You may freely add private functions, modules and fields; those need no row.
A new public item is allowed when a contract cannot be met without it, with
a `deviation` row.

## <Project rules>

<determinism, where numbers live, what may depend on what; each with its
reason>

## Commands

| What | Command |
|---|---|
| What is next | `scripts/check` |
| The finish check for a milestone | `scripts/check M3` |
| One suite while working | the milestone's `test` line in `frame.toml` |
| One test, with its output | `<...>` |
| Open log rows | `jq -c 'select(.settled == null)' docs/log.jsonl` |
