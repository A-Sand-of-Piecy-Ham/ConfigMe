---
name: skill-forge
description: Write or revise a skill. Triggers - "make a skill", "turn this into a skill", "shim for", "remember this workflow", "you should always do X when Y", or a workflow was corrected twice.
---

## Descriptions are permanent cost; bodies are not

Every skill's description sits in context for every session whether or not the
skill fires. The body loads only on trigger. So the description is the one thing
worth compressing hard, and the body is where prose belongs.

Write descriptions as fragments. Drop articles, drop "Use when", drop
"This skill". Lead with the verb, then a bare list of trigger phrases in the
user's own words. Grammar is expendable; a missed trigger is not.

```
description: Capture task to TickTick. Triggers - "create todo", "add task",
  "remind me", "put on my list", deferred work mentioned mid-task.
```

not

```
description: >
  Capture a task into TickTick rather than replying that it has been noted.
  Use whenever asked to create a todo, add a task, make a ticket...
```

Same triggers, roughly a third the tokens.

Include the phrases the user actually says, including sloppy ones. A trigger
list is not a definition and does not need to read well.

## What earns a skill

A skill is worth writing when a workflow was found the hard way and would
otherwise be rediscovered. Two signals:

- The same correction landed twice.
- A step fails silently — nothing errors, the result is just quietly wrong.

Not worth a skill: a one-off fix, something the tool already does by default,
or knowledge that belongs in project memory because it is a fact rather than a
procedure.

## Two shapes

**Procedure skill** — a workflow with steps that are easy to get wrong. Body
carries the steps, the failure modes, and how to verify. `dotfiles-change` is
one.

**Shim skill** — capability already exists but nothing surfaces it at the right
moment. The body is short; nearly all the value is in the trigger list. The
failure being prevented is the model answering plausibly instead of acting.
`todo-capture` is one: the TickTick tools were always callable, but a task
mentioned in passing got "noted" and nothing was created.

Shims are the higher-leverage of the two, because a missing capability
announces itself and an unused one does not.

## Body rules

State what fails and why, not just what to do. A step whose purpose is
understood survives a situation the skill did not anticipate; a bare
instruction does not.

Include verification, especially where success and failure look alike.

Skip preamble, restated titles, and closing summaries. Assume the reader is
already doing the task — the skill only loaded because they are.

## Placement

`~/projects/ConfigMe/claude/skills/<name>/SKILL.md`, symlinked to
`~/.claude/skills`. New skills register live; no restart. Commit through the
`dotfiles-change` workflow.

Check for an existing skill first. Extending one beats adding a second whose
description competes with it for the same triggers.
