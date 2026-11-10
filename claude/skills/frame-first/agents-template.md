# Rules-file template

For the frame's author. Copy the part below the line into the repo's agent
rules file (`AGENTS.md`), fill the `<...>` slots, and delete what does not
apply. The implementer's rules file is the only tier file every model loads;
the reviewer's instructions stay in this skill (`review.md`), so an
implementer never pays for them. Do not pull other files in with `@` links:
those load for every model, every session.

Each section exists because the first handoff (2026-11-10, a small model on
one milestone) went wrong without it:

| Section | What happened without it |
|---|---|
| Normal here | The report was mostly about stubs failing and the repo being a frame |
| Branch per milestone | Work was committed on the default branch; the reviewer had no `main...branch` diff |
| Reading list | The implementer read the whole architecture doc; the milestone used none of it |
| Edit tool, not shell | Files were changed with `sed` and a script, so the hook that loads the docs guidance never ran |
| Gaps filled, logged when made | Four silent contract choices; the log said there were none |
| One check command | The stated finish command (the full test run) could not pass until the last milestone |
| Fixed report | Free-form summary, read later by the dearer model |

The frame must also contain, before handoff:

- **A check command** taking a milestone name. It runs the tests of that
  milestone and every earlier one, and nothing later. Gates: tests, no stub
  marker left for the milestone, lints, a gaps row in the log. One line per
  gate, detail only on failure, last line `PASS <milestone>` or
  `FAIL <milestone>`. Run it against the bare frame for the first milestone
  and confirm it fails only on that milestone's stubs.
- **A reading list per milestone** in the milestone file: its files, its test
  file, and the named sections of the design doc it depends on.
- **Log sections** the implementer writes one capped line into: gaps filled,
  friction, decisions needed, deviations.

---

# Rules for agents

This repo is a **frame**: the design is fixed, most bodies are stubs, and
tests say when each one is right. Your job is to fill bodies in, one
milestone at a time. You do not see the conversation that designed this; the
reasons are in <design doc>.

Asked to **review** a milestone or run a checkpoint instead? These are the
implementer's rules. Load the `frame-first` skill and follow its review file.

## Normal here: do not report, do not fix

- Most bodies are `<stub marker>`. That is the design.
- `<full test command>` fails for every milestone after yours. Use
  `<check command>`, which runs only what should pass.
- <anything else that looks broken and is not>

## The loop

1. Open <milestone file>. Take the lowest-numbered unfinished milestone. One
   per session. If it names a different model from you, tell the user first.
2. Make a branch from `<default branch>` named for the milestone. Never
   commit on `<default branch>`; the reviewer merges at the checkpoint.
3. Read exactly: the milestone's entry, the files it lists, its test file,
   and the design-doc sections on its `Read:` line. Nothing else until one of
   those sends you further.
4. Replace each stub for the milestone. Change files with the Edit and Write
   tools, not `sed`, a script or a shell redirect.
5. When a contract or test does not say what to do and you have to choose,
   add a row under "Gaps filled" in <log> at that moment, before the code.
   None needed: one row saying `none`. Anything in the rules, docs or
   commands that cost you time: one line under "Friction".
6. Run `<check command> <milestone>` until its last line is `PASS`.
7. Update only: the milestone's status cell, and <status table> in the
   README.
8. Commit on your branch: subject `<milestone>: <what>`; body one line per
   gap and per friction row, or "none"; then the attribution line your
   session supplies.
9. Report these lines and nothing more:

   ```
   Milestone:  <id>, branch <name>, commit <short hash>
   Check:      PASS <id> (<n> tests)
   Gaps:       <count>
   Decisions:  <count waiting>, or none
   Friction:   <count>, or none
   Next:       <checkpoint name: review first | next milestone, new session>
   ```

   If the milestone ends in a checkpoint, stop there.

## Frozen

- <tests, fixtures, public signatures, conventions, the check command>

If a frozen thing looks wrong: stop work on that item, add an entry under
"Decisions needed" in <log> (what you found, what you would change), and
carry on with the rest. Never bend code to fit a test you believe is wrong,
and never special-case a test's inputs. The tests were written before the
code ran; some are probably wrong, and that is the reviewer's to fix.

You may add private functions, modules and fields freely. A new public item
is allowed when a contract cannot be met without it; note it under
"Deviations".

## <Project rules>

<determinism, where numbers live, what may depend on what; each with its
reason>

## Commands

| What | Command |
|---|---|
| The finish check | `<check command> <milestone>` |
| One suite while working | `<...>` |
| One test with output | `<...>` |
