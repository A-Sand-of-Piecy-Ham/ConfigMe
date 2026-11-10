---
name: skill-forge
description: Write or revise a skill. Triggers - "make a skill", "turn this into a skill", "shim for", "remember this workflow", "you should always do X when Y", a workflow was corrected twice, or a skill in use turned out wrong, stale or incomplete.
effort: high
---

## What a skill is for

A skill carries a lesson from the session that learned it to a session that has
not, at the moment it is needed, for the least context cost. Two things follow,
and everything else here is the current way of serving them:

- **Skills are drafts.** The session using a skill knows something its author
  did not. That goes back into the skill or it is lost.
- **The reader may be a weaker model than the writer.** A skill only the top
  model can follow fails silently in the sessions that most need it.

## Amend skills in use

When a skill turns out wrong, stale or incomplete while it is being used, fix
it in that session. Working around it leaves the next session to hit the same
thing.

| Change | Who makes it |
|---|---|
| Add a failure case, a missing step or a verification; correct a stale command or path; update a status note | Any session, at once. Tell the user in one line. |
| Rewrite a description, merge, split, delete, restructure, remove or reverse a rule | The strongest model available, or the user. |

The split exists because an added line is cheap to check and revert, while a
structural change alters when the skill fires and what it no longer says, and a
wrong one fails silently. A session not on the strongest model that sees a
structural problem adds one line under a `## Pending` heading at the end of
that skill (what it saw, what it would change) and tells the user. The next
strong session that loads the skill resolves the line and deletes it.

Each amendment carries one clause of evidence: what happened that showed the
need. A later reader can then judge whether the rule still holds.

Amending is not appending. Tighten or replace before adding. Cut a rule whose
reason no longer holds, because every extra line lowers adherence to the rest.

Where part of a skill was designed but never run, mark it in a short status
note so it reads as a hypothesis. Update or delete the note after the run.

## Write for the weakest model likely to load it

- **Open with intent.** Say what the method is for and that the steps are the
  current way of getting it. A strong reader uses that to drop a step that is
  not helping. This is not preamble: preamble restates the title.
- **Give every judgment call a condition and a default**: "skip X when Y,
  otherwise do it". A mid-tier reader follows explicit steps well but is
  unreliable at noticing that a step does not apply, so "use judgment" only
  works at the top tier.
- **Put the decisive content first.** Adherence falls off down a long body.
- **Make verification observable**: a command or check and the result that
  means success, especially where success and failure look alike.
- **Give the reason with the step.** A step whose purpose is understood
  survives a situation the skill did not anticipate.
- **Pair a prohibition with what to do instead.**
- **Examples get copied literally.** Give two that differ, or say what varies.
- **Mark a step that needs the strongest model at that step**, with what a
  weaker one does instead (stop and say so, or do only the mechanical part).
- **Never pin a model in frontmatter.** This skill carried `model: opus` to
  force the strongest model. A stronger one shipped, and the pin then silently
  downgraded every session that loaded it. Names go stale; put the requirement
  in the body.

Skip restated titles and closing summaries. The reader is already doing the
task, which is why the skill loaded.

## Descriptions are permanent cost; bodies are not

A description sits in context for every session whether or not the skill
fires. The body loads only on trigger. So compress the description hard and
keep prose for the body.

Write descriptions as fragments. Drop articles, "Use when" and "This skill".
Lead with the verb, then a bare list of trigger phrases in the user's own
words, sloppy ones included. Grammar is expendable; a missed trigger is not.

```
description: Capture task to TickTick. Triggers - "create todo", "add task",
  "remind me", "put on my list", deferred work mentioned mid-task.
```

Cover the moment a lesson is produced, not only the moment it is sought.
`doc-lookup` listed lookup phrasings only and did not fire when a debugging
session produced exactly the answer it exists to cache.

## What earns a skill

A workflow found the hard way that would otherwise be rediscovered. Signals:

- The same correction landed twice.
- A step fails silently: nothing errors, the result is quietly wrong.

Not a skill: a one-off fix, something the tool does by default, or a fact
(memory) or an always-true rule (`rules/`). The `memory-write` skill has the
routing table.

## Two shapes

**Procedure**: a workflow with steps that are easy to get wrong. The body
carries the steps, the failure modes and the verification. `dotfiles-change`
is one.

**Shim**: the capability exists but nothing surfaces it at the right moment.
The body is short and nearly all the value is in the trigger list.
`todo-capture` is one: the TickTick tools were always callable, yet a task
mentioned in passing got "noted" and nothing was created. Shims are the higher
leverage, because a missing capability announces itself and an unused one does
not.

## Redundancy, merging, splitting

Read the existing descriptions before writing. Two skills competing for the
same triggers both pay permanent cost, and which one fires becomes arbitrary.
Extend an existing skill before adding a second.

`CLAUDE.md` and `~/.claude/rules/` load every session. Point at them; do not
restate them. `git-workflow` once duplicated the never-push rule and had to be
cut back to a pointer.

**Merge** when two skills share most of their triggers and a reader of one
needs the other. Trigger overlap is the test, not topic: two git skills that
fire at different moments stay apart. Where merging would force a choice
between conflicting rules, stop and ask. A silently resolved conflict is a rule
that quietly stopped applying.

**Split** when most invocations load material irrelevant to the task: sections
that never co-occur, a description collecting unrelated triggers, or a body
long enough that loading it is a cost. Split along the trigger seam, so each
half owns phrases the other does not want, then re-check both descriptions for
competition.

## Placement

`~/projects/ConfigMe/claude/skills/<name>/SKILL.md`, symlinked to
`~/.claude/skills`. New skills register live, with no restart. Run
`bin/claude-config-check` and expect `ok  skills have valid frontmatter`, then
commit through the `dotfiles-change` workflow.

## Status

The amend-in-use table, the `## Pending` convention and the weaker-reader
guidance were written on 2026-11-10 from reasoning and one incident (the model
pin). None has been measured against a mid-tier session following a skill.
Revise from the first cases where one does, or fails to.
