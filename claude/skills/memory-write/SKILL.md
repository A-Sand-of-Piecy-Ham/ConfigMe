---
name: memory-write
description: Persist a stated preference. Triggers - "always", "never", "from now on", "stop doing", "I prefer", "remember that", or the same correction given twice.
model: opus
effort: medium
---

## Complying once is not remembering

The failure this prevents: the user states a standing preference, the model
follows it for the rest of the session, and it is gone next session. Nothing
errored, the request was honoured, and the preference silently evaporated.
The user then has to restate it — which is the cost being avoided.

Any phrasing that widens scope beyond the current task is a write signal:
"always", "never", "from now on", "whenever you", "stop doing X". So is the
same correction arriving a second time, whether or not it is phrased as a rule.

Phrasing that narrows — "this time", "for now", "just here" — is not.

## Where it goes

| Content | Home |
|---|---|
| Preference or fact, no trigger phrase for "know this" | Auto memory: `~/.claude/projects/<slug>/memory/` |
| Rule that must hold in every session | `~/.claude/rules/` |
| Procedure triggered by a kind of task | A skill — see `skill-forge` |

Misfiling costs asymmetrically. A rule filed as a skill is silently absent
whenever it did not trigger, which is the same failure as not writing it. A
procedure filed as a rule taxes every session forever.

## Writing it

Write the reason, not only the instruction. A preference whose purpose is
understood survives a situation it did not anticipate; a bare rule gets applied
where it does not fit, or dropped when it seems not to.

One topic per file. Do not append unrelated lessons to an existing file because
it is open.

Write it in the same reply that engages the correction, not after the
conversation settles — an offered next step is not permission to defer.
