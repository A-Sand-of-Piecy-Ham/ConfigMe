---
name: todo-capture
description: Capture task to TickTick. Triggers - "create todo", "add task", "make a ticket", "remind me", "put on my list", deferred work mentioned mid-task.
---

## Why this exists

TickTick is reachable through connector tools, but nothing announces them when
a task is mentioned in passing. The failure mode is answering "noted" and
creating nothing, which loses the item entirely -- the user believes it was
captured. If a request is plausibly a capture request, capture it.

## Before creating

Call `list_projects` once and choose the project that fits. Do not default to
the inbox when an obviously matching project exists; an item in the wrong list
is nearly as lost as one never created. Reuse the result for the rest of the
session rather than listing again per task.

File by what the task is *for*, not the subject it touches. An academic-sounding
task is not automatically a Study task:

| Project | Holds |
|---|---|
| `📖Study` | Coursework and learning |
| `🎓Career` | Professional and research: academic outreach, collaborations, publications, networking |
| `🎯Applications` | Job applications specifically |
| `💼Homework` | Assignments |

Emailing a professor about co-authoring a paper is Career, not Study.

Search first with `search_task` when the item sounds recurring or previously
mentioned. Duplicates are worse than a missing task, because both copies then
drift.

## Writing the task

The title is what will be read months later with no memory of this
conversation. "Fix the thing we discussed" is useless; "Fix escape-time lag in
tmux config" is not.

Put the context in the task content, not the title: the file path, the repo, a
PR or issue URL, the specific error. A captured task without a pointer back to
its source usually has to be re-investigated from scratch.

Set a due date only when the user gave one. An invented deadline turns into a
false overdue item later. Map their words honestly: "urgent" or "today" to high
priority, plain requests to none. Do not inflate.

## After creating

Confirm in one line -- what was created and where. Do not restate the task body
or explain the fields chosen.

If several tasks come out of one request, use `batch_add_tasks` rather than
creating them one at a time.
