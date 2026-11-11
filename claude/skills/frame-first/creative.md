# Creative milestones

Read this when a frame has work judged by taste: item and part
descriptions, plot, dialogue, jokes, names, art direction. It is not needed
for milestones a test can judge.

**Draft, never run** (see Status). Every step here is a guess to correct
from the first use.

## What this is for

A frame works because tests tell a cheap model when it is done. Taste has
no test, so a creative milestone swaps the oracle for four things: a
rulebook distilled from examples the user likes and dislikes, a table of
how the world's things relate, several candidates where code would have one
answer, and the user's pick. Each pick is kept, so the rulebook gets better
with use.

Charm mostly lives between things, not in them: an item description that is
funny because of what another item says, a part whose maker has a
reputation the player has pieced together. That is why the relation table
comes before the writing and is the main input to it.

## The designation: `T1C`, `T2C`

A tier with a `C` in `frame.toml` (`tier = "T2C"`) marks a creative
milestone. `~/.claude/rules/model-tiers.md` says which model that is. It
tells the implementer three things:

- load the repo's creative rulebook before anything else;
- the finish is a set of candidates, not green tests;
- the user reviews it, not T1.

The letter belongs to the tier only. Say "creative milestone", never "C
milestone": frames name their checkpoints A, B, C.

There is no `T3C`: the smallest tier is weak at work judged by taste. It can
still do the mechanical end (formatting accepted text into data files) as an
ordinary T3 milestone.

## The three files in the repo

| File | Holds | Who changes it |
|---|---|---|
| `docs/CREATIVE.md` | The rulebook: the voice, what is funny here and why, what to avoid, two or three accepted pieces as models | The user, or T1 after a taste study |
| `docs/lore.toml` | The relation table: each maker, place, person and item family, and how each relates to the others (rival of, built by, afraid of, owes money to) | Creative milestones, before the text that depends on a new row |
| `docs/taste.jsonl` | One row per judged piece: the text, `+` or `-`, and the user's reason in their words | Appended after each pick |

A reason is worth more than the verdict. "Too pleased with itself" teaches;
a bare `-` does not.

## Step 0: the taste study (T1, once per project)

The user names games, shows or books they find well written or good
looking, with what works and what does not in each. A T1 session looks for
what the liked ones share and the disliked ones lack.

- Work only from text and images the user supplied or the session fetched
  and can quote. A model's memory of a game's item descriptions is
  unreliable, and a misremembered line is invented evidence.
- Each pattern claimed cites at least two examples that show it and one
  that lacks it. A pattern with one example is an anecdote.
- The user corrects the list. What survives becomes `docs/CREATIVE.md`.
- The examples teach the pattern. Their text, names and characters are
  never reused in the project.

## A creative milestone

1. Read the rulebook, the lore rows the brief names, and the last twenty or
   so rows of `taste.jsonl`.
2. If the piece needs a relation the table lacks, add the row first.
3. Write several candidates per slot (three unless the brief says
   otherwise) that differ in approach, not in wording. Under each, one line
   naming the lore relation it leans on. A candidate that leans on none is
   allowed, and says so.
4. Do not explain the joke inside the text, and do not sand a candidate
   down until nothing in it could be disliked.
5. The user picks, edits or rejects. Append every judged candidate to
   `taste.jsonl` with the reason given.
6. The accepted text goes into the data files, by this session or a T3
   milestone.

## What the check can still do

`scripts/check` cannot judge the writing, but it can refuse what is
mechanically wrong: text over its length limit, a reference to a lore id
that does not exist, a slot with fewer candidates than asked, a candidate
identical to a rejected row. `PASS` on a creative milestone means "ready for the
user to judge", never "accepted".

## Status

Written 2026-11-11 from a conversation, before any project had content to
write. Nothing here has run: not the taste study, not the three files, not
a creative milestone, and the template's check has no creative gate yet. The
user's view at the time: lore tables are a well-worn practice in games and
animation, so there are existing formats to copy before inventing one.
First use is expected after a project's first playable checkpoint.
