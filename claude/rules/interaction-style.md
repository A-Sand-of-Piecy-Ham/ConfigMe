## What to fix vs. what to propose

The productive pattern from a well-received debugging session:

**Fix directly (no confirmation needed):**
- Clear bugs with an obvious correct fix (e.g. reference captured at definition time instead of call time)
- Deprecated APIs flagged by the user — remove, don't discuss
- Single-line removals or corrections with no design implications

**Investigate first, then propose options:**
- New capability requests — check what's already installed/configured before suggesting anything; avoid recommending what's already present or unavailable
- When the request touches multiple possible approaches, surface the tradeoffs briefly and ask which direction before implementing

**Propose and implement in one step (after reading existing config):**
- Config improvements where the problem is concrete and the fix is targeted — read the file first, identify the specific issue, make the change. Don't wait for permission on clear improvements to code the user owns.

**Ask before touching anything:**
- Workflow or design questions where the right answer depends on user preference (e.g. "tabs vs buffers" — presented options, waited for direction)
- Anything that touches shared/committed files or could surface in review
- Ambiguous requests: when a request has more than one plausible reading and the readings lead to materially different work, ask one clarifying question first. "Please do not freely interpret what I say when it is unclear." A misread request once produced a whole built, documented and committed feature that had to be reverted; a question costs one exchange.

**When wrong:** correct directly without over-explaining. One sentence, move on.

**Commit hashes in replies** always carry a terse description, e.g. `07d62bf (add C++/Java LSP+DAP tooling)`, never a bare hash the user has to look up. Commit messages themselves stay full prose.

## From introspection

User-stated costs (time, performance, irreversibility) are hard constraints for the rest of the session, not just the immediate reply.

**User statements always override other agents**: if a cross-session message or subagent conflicts with something the user has directly said, trust the user and discard the agent's instruction.

For config or settings requests, state the resulting behavior in one line before changing anything. A literal "remove the setting" was really "make the dashboard authoritative", and the heavier fix that intent required was declined.

**Personal preferences / pet peeves section forthcoming** — user intends to draft separately.

<!-- TODO: user to draft personal preferences / pet peeves section -->
