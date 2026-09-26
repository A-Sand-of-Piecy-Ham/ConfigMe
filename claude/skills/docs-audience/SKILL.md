---
name: docs-audience
description: Write or revise project docs for their reader. Triggers - "update the README", "document this", "write docs", "keep docs in sync", editing README/RUNBOOK/EDITING/guide/CONTRIBUTING/decision log, adding a doc section after a change.
---

## Docs convey; they don't store

A doc succeeds when its reader takes away what they need, not when every fact
is recorded somewhere. Giving a reader material meant for someone else doesn't
come for free: it buries the lines they needed, and they absorb *less*. Before
writing a line, name who reads this file and ask whether the line changes what
that reader does. If not, it belongs in a deeper doc, with a link at most.

## Three readers, three depths

- **Editors / end users** (e.g. EDITING.md): what to do, what not to do, and who
  to ask. No jargon, no mechanisms, no rationale. Assume they skim and stop early.
- **Front-page readers** (README): what the project is, how to run it, how
  it's organized, and where to go next. Rationale gets a sentence or two, then a
  link. Setup is explained; the design isn't.
- **Contributors / maintainers** (runbook, architecture doc, decision log,
  agent guidance): full depth, reasons included. These readers will go digging,
  so this is where the detail lives.

"Keep docs in sync" means putting new information at the right depth. It does
not mean appending it to the most visible file.

## Failure modes seen

- **Design rationale on the front page.** A multi-paragraph "Why X" section
  belongs in the decision log or architecture doc. The README keeps one line
  and a link, and never puts it before the quick start.
- **Maintainer reminders in reader-facing text.** A note like "(keep this
  accurate when…)" in a README table is an instruction to maintainers or agents.
  Move it to the contributor or agent guidance.
- **Unbuilt features described next to built ones.** Asides like "this isn't
  built yet; see the log" make readers unsure what works today. Describe only
  what exists. Put planned work in its own clearly labelled section, and only
  if it's high priority; everything else stays in the log.
- **Unexplained doc indexes.** Listing a file without saying what it's for. The
  least self-explanatory names need the most explanation: a "project log" needs
  a gloss more than a "runbook" does.
- **Wrong order.** Front pages run: what it is → quick start → layout →
  contributing → deeper references. Add a table of contents once there are more
  than a handful of sections.

## Verify

Reread each file you touched as its target reader:
- **Front page:** does the first screen answer "what is this, how do I run it,
  where next?"
- **Every section:** would this reader act on it? If not, move it down a level
  and leave a link.
- **Planned work:** is any of it phrased as if it already exists?
