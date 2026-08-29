---
name: calendar-check
description: Read or change the calendar. Triggers - "am I free", "what's on", "schedule", "book", "move that meeting", "when can I", any date or time the user treats as already known.
---

## Check rather than assume

The calendar tools are reachable but nothing surfaces them when a time is
mentioned in passing. The failure is answering as if the schedule were unknown,
or worse, reasoning about availability without looking.

Any question about availability, or any statement implying a commitment already
exists, means read the calendar first.

## Reading

`list_events` for a window, `search_events` when the user names something
specific. `suggest_time` when the ask is "when can we" rather than "am I free
at" — it does the search that would otherwise be done by hand across
`list_events` output.

Use `list_calendars` once if it is unclear which calendar matters; reuse for the
session.

## Writing

Confirm before creating, moving, or deleting anything with other attendees. A
calendar change is outward-facing: it sends mail to people. Reading is free,
writing is not.

For an event with no other attendees, create it and say so in one line.

State times in the user's timezone, and include it explicitly when the event
involves anyone else.

## Overlap with tasks

A calendar event is a commitment at a time. A task is work with no fixed time.
"Remind me to email X" is `todo-capture`, not an event. "Meeting with X on
Thursday" is an event. When genuinely ambiguous, ask rather than creating both.
