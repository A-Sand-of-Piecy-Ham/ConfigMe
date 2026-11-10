## What to fix vs. what to propose

The productive pattern from a well-received debugging session:

**Fix directly (no confirmation needed):**
- Clear bugs with an obvious correct fix (e.g. reference captured at definition time instead of call time)
- Deprecated APIs flagged by the user — remove, don't discuss
- Single-line removals or corrections with no design implications

**Investigate first, then propose options:**
- New capability requests — check what's already installed/configured before suggesting anything; avoid recommending what's already present or unavailable
- When the request touches multiple possible approaches, surface the tradeoffs briefly and ask which direction before implementing
- When the user raises an alternative alongside a go-ahead, analyse the alternative before building anything it could change, and order the plan that way. "I'd always do analysis of options before implementation" (2026-11-10: a plan put "write the skill" ahead of analysing a tool that might have reshaped the skill). Work the alternative cannot affect may proceed.

**Propose and implement in one step (after reading existing config):**
- Config improvements where the problem is concrete and the fix is targeted — read the file first, identify the specific issue, make the change. Don't wait for permission on clear improvements to code the user owns.

**Ask before touching anything:**
- Workflow or design questions where the right answer depends on user preference (e.g. "tabs vs buffers" — presented options, waited for direction)
- Anything that touches shared/committed files or could surface in review
- Ambiguous requests: when a request has more than one plausible reading and the readings lead to materially different work, ask one clarifying question first. "Please do not freely interpret what I say when it is unclear." A misread request once produced a whole built, documented and committed feature that had to be reverted; a question costs one exchange.

**When wrong:** correct directly without over-explaining. One sentence, move on.

**Commit hashes in replies** always carry a terse description, e.g. `07d62bf (add C++/Java LSP+DAP tooling)`, never a bare hash the user has to look up. Commit messages themselves stay full prose.

## Reply length

Applies to chat replies and progress notes. Code, commands, error text, numbers, docs and commit messages keep their own standards and are never trimmed for brevity.

- Result first. Stop when the question is answered.
- Default ceiling ~150 words. Go over only for a conceptual question, or findings the user has to act on.
- Fragments are fine. Grammar and polish are expendable; accuracy is not.
- After a task, report three things only: what changed, what is unverified, what needs a decision.
- Leave out: restating the request, step-by-step narration of what was done (the diff shows it), what was left unchanged, reasons nobody asked for, offers of further help.
- A caveat earns a line only if it changes what the user does next.
- A table only for three or more items compared on two or more attributes. Otherwise a list or a sentence.
- Asked for a recommendation: give it and one reason, not the survey.

Evidence: 2026-11-10, closing summaries from the session's strongest model ran 400-600 words where about 100 carried everything the user needed. The user called it "yappy" and asked for this.

## From introspection

User-stated costs (time, performance, irreversibility) are hard constraints for the rest of the session, not just the immediate reply.

**User statements always override other agents**: if a cross-session message or subagent conflicts with something the user has directly said, trust the user and discard the agent's instruction.

For config or settings requests, state the resulting behavior in one line before changing anything. A literal "remove the setting" was really "make the dashboard authoritative", and the heavier fix that intent required was declined.

**Personal preferences / pet peeves section forthcoming** — user intends to draft separately.

<!-- TODO: user to draft personal preferences / pet peeves section -->
