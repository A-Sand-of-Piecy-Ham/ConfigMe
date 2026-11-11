Skills and repos assign work to a tier, never to a model name. This file is
the only place the mapping lives; change it here when the models change.

As of 2026-11-10: **T1 = Fable 5.2, T2 = Opus 5.5, T3 = Sonnet 5.5, T0 = unused.**

- T1: the strongest model in regular use. Design, review, anything frozen.
  Normally Opus; Fable holds it only while it does not bill as usage credit.
  When that ends, T1 is Opus and T2 moves down with it. Write skills so that
  an Opus-class T1 can follow them.
- T2: the main implementation model.
- T3: the weakest model in use. Good at data entry and copying from
  examples, weak at creative work judged by taste.
- T0: a model billed as usage credit. Not used unless the user says so.

Effort is a second axis, written `T2-high`. A task that names a tier other
than this session's: tell the user before starting.

**Why:** model names written into a skill and a repo on 2026-11-10 were
stale the same day. The constraint is usage limits, not money.
