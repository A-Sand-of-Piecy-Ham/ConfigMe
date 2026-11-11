Every model call re-reads the whole conversation, so a call costs about a
tenth of the context size before it does anything: 15k tokens' worth at a
150k context. Count calls, not only tokens. A draft: amend it from what
sessions measure, as with the skills.

- **Send everything independent in one message.** Before a lone tool call,
  name the call that would follow it. If that one does not need this
  result, it goes out now, beside it.
- **Unused information is cheaper than a second call.** Unsure whether a
  second file, a neighbouring section or one more command's output will be
  needed: fetch it now. Up to about 2k tokens of maybe-useful output costs
  less than the call that would go back for it.
- **Bash: one command, several questions.** Join independent commands with
  `;` and an `echo ---` between them (`&&` hides everything after the first
  failure). Status, log, diff, grep and `wc` belong in one call, not five.
- **Bound what comes back.** No tool result over about 4k tokens unless all
  of it is needed. Unknown size: put `wc -c` in the same command, or pipe
  through `head -c`, `tail` or `grep`. A file over about 400 lines: `grep
  -n` for the section, then `Read` with `offset` and `limit`. Never `cat`
  several source files into one result: over the limit it spills to a file,
  and reading that back pays for it twice.
- **Edits together, then one check.** All edits that do not depend on each
  other go in one message. Tests, lint, format and any finish check run
  once, after the last edit, in one command. Run one earlier only when its
  result decides what to do next.
- **Upkeep is one batch at the end.** Logs, status notes, docs kept in
  sync, cost measurement and memory are independent of each other: write
  them together after the work, not one call each as things happen. A
  measurement that misses the last few calls is fine.
- **Load a skill when its content is about to be used**, not at the start
  in case it is. Its body stays in context for every later call.
- **A hook note that the user corrected you** joins the end batch: load
  `introspection` then and file the lesson. Nothing else triggers it.
- **Do not suggest a fresh session unless it pays.** Starting one costs
  about 100k (a 48k start, written to cache at twice price). Staying costs
  a tenth of the context per call. So it pays only when the remaining
  calls times the context exceed about a million, say 10 calls at 100k,
  and what is needed is already in files. The user asked for this
  (2026-11-11) after being sent to a fresh session for a five-call job.

Evidence: 2026-11-11, one review turn made 46 model calls for 110 tool
calls, 18 of them a single Bash command and about 15 for upkeep done one
item at a time. Re-reading the conversation cost more than all its output,
and the user's five-hour limit lost a third.
