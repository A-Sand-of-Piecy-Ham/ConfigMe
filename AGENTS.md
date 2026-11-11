# Rules for agents

This repo is under a **frame**: the design is fixed, and tests say when each
change is right. The work is moving the Claude configuration out to
AdaptiveDesign, one milestone at a time. You do not see the conversation
that designed this; the reasons are in `docs/SPLIT.md`, which is both the
design and the milestone list.

Asked to **review** a milestone or run a checkpoint instead? These are the
implementer's rules. Load the `frame-first` skill and follow its review file;
read this page only to know what the implementer was told.

## Normal here: do not report, do not fix

- Nothing is stubbed. The work is changes to `install.sh`, `install.ps1` and
  the docs, and `scripts/test` is the oracle: its cases fail until their
  milestone is done. That is the design.
- `scripts/test` fails for every milestone not finished in your checkout.
  Use `scripts/check`, which runs only what should pass.
- A milestone listed as `busy` is being built on another branch. Its changes
  are not in your checkout.
- A `ready` milestone whose check fails on tests although its work looks
  done. A review sent it back. Its entry in `docs/SPLIT.md` has a "Sent
  back" list: that list is the work, and step 4 of the loop does not apply.
- A `tests` line that ends `held earlier: <test name>`. That test belongs to
  a finished milestone and waits on the reviewer. It is not yours to fix or
  to dispute again.
- The `delegate` suite fails while AdaptiveDesign's installer is unfinished.
  The tests install from a clone of the AdaptiveDesign checkout beside this
  repo's main checkout, at its HEAD commit. To test against an AdaptiveDesign
  branch that is not merged yet, set `CONFIGME_TEST_AD_SOURCE` to its
  worktree.
- `install.sh --doctor` exits non-zero in a test's scratch home (no fonts,
  no tmux plugins, no instruction-load log). The tests read only its
  `claude` section.
- The `claude` and `github-templates` directories and the Claude hooks in
  `bin` look like they should be gone. They stay until M3: running sessions
  load from them.

## The loop

1. Run `scripts/check` with no argument. Its last line names the next
   milestone with its tier and effort, for example `Next: M3 (T2, effort
   medium)`. One milestone per session.
   - If the user named a milestone, take that one instead, provided its row
     in the list says `ready`. `busy` means another agent has it; `waits`
     means something it needs is not merged yet. Take neither.
   - Tiers (T1, T2, T3) say which model does the work. If you are a different
     tier, or do not know your tier, tell the user before starting.
   - If the line names a checkpoint, stop: that is a review, not yours.
2. Make a worktree with a branch named for the milestone, and work only
   there. Other agents may be working in this repo at the same time, and
   two agents in one directory overwrite each other.

   ```
   git worktree add .claude/worktrees/m3-<name> -b m3-<name> frame/split
   ```

   Then move into it: with the `EnterWorktree` tool, giving it that path, if
   your session has the tool; otherwise `cd` there and use that path for
   every file and command. If `git rev-parse --git-dir` already prints a
   path with `/worktrees/` in it, your session started in a worktree: stay,
   and only make the branch (`git switch -c m3-<name> frame/split`).

   Never commit on `frame/split` or `main`, do not push, and do not merge
   your branch: the user, the reviewer or the session that handed you the
   milestone merges it into `frame/split`. `main` receives one PR, at
   Checkpoint C. `docs/log.jsonl` never conflicts in a merge, because
   `.gitattributes` merges it by union.
3. Read these first:
   - the milestone's entry in `docs/SPLIT.md`, and its "Decisions" and
     "Rules for every milestone";
   - the files it lists;
   - the milestone's cases in `scripts/test` (the `t_<case>` functions of
     its suite, and the helpers they call);
   - for M1 and M2, "Installer contract" in
     `../AdaptiveDesign/docs/DESIGN.md`: the interface you call.

   Then read what those send you to: the functions and helpers your change
   touches (in `install.sh`: `feature_on`, `link`, `ok`/`bad`/`fix`).
   Leave the rest of the repo unread.
4. Make the milestone's change. Change files with the Edit and Write tools,
   not with `sed`, a script or a shell redirect: the tools show the reviewer
   a clean diff and trigger the project's checks. File moves and deletions
   are `git mv` and `git rm`.
5. Keep the log as you go. `docs/log.jsonl` holds one JSON object per line;
   add yours at the end, **at the moment the thing happens**, before writing
   the code it concerns. The kinds are under [Log rows](#log-rows). Every
   milestone needs at least one `gap` row.
6. Run `scripts/check Mx` (x = your milestone) until its last line is
   `PASS Mx`, or `HELD Mx` (see [Frozen](#frozen)). Besides the tests it
   checks the log. There is no lint or format gate (no shellcheck on the
   machine that built the frame), and no stub gate to speak of. M2 has no
   tests: no PowerShell here. Its check passes on the log alone, and the
   reviewer reads it at Checkpoint C.
7. Update the docs the change made wrong: your milestone's `status` in
   `frame.toml` (`"done"` after PASS, `"held"` after HELD) and a dated line
   under "Done" in `docs/PROJECT_LOG.md`. Do not rewrite anything else in
   them.
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
   Check:      PASS M3 (<n> tests)
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
| `deviation` | You added a flag, an environment variable or a feature box | `what`, `why` |
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

- `docs/SPLIT.md`: the design, the milestones and their case lists.
- `scripts/test`: the oracle.
- The installer's interface: its flags, the environment variables
  `CONFIGME_FEATURES`, `ADAPTIVE_DESIGN_DIR` and `CONFIGME_NO_CLONE`, and
  the feature box names. AdaptiveDesign's installer contract belongs to that
  repo; a disagreement with it is a `dispute` here and is never fixed there.
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

## Project rules

- **Never run an installer against the real home.** Not `install.sh`, not
  `install.ps1`, not AdaptiveDesign's, not with a flag that sounds harmless.
  `scripts/test` runs them under `env -i` with `HOME`, `XDG_CONFIG_HOME`,
  `CONFIGME_FEATURES` and `ADAPTIVE_DESIGN_DIR` in scratch directories and
  every feature box off except the case's, because the installer downloads
  and installs software when features are on. To try something by hand,
  run one case with `CONFIGME_TEST_KEEP=1` and look in the scratch directory
  it prints.
- **Do not touch the `claude` or `github-templates` directories, or the
  Claude hooks in `bin`, before M3**, and M3 only after its `readlink -f`
  check. `~/.claude` and `~/.local/bin` link into this checkout, and every
  running Claude session loads its rules, skills and hooks through them.
- **Do not edit AdaptiveDesign.** It is another frame with its own agents.
  When ConfigMe needs something of it, log a `dispute` or a `gap` here.
- **Work in a worktree branched from `frame/split`.** Nothing goes to `main`
  until Checkpoint C.

## Commands

| What | Command |
|---|---|
| What is next | `scripts/check` |
| The finish check for a milestone | `scripts/check M3` |
| One suite while working | the milestone's `test` line in `frame.toml` |
| Every suite | `scripts/test` |
| One test, with its output | `scripts/test <case>`, e.g. `scripts/test links_made`; add `CONFIGME_TEST_KEEP=1` to keep its scratch home |
| Against an unmerged AdaptiveDesign branch | `CONFIGME_TEST_AD_SOURCE=<its worktree> scripts/test delegate` |
| Open log rows | `jq -c 'select(.settled == null)' docs/log.jsonl` |
