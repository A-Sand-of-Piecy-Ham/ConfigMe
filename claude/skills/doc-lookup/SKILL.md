---
name: doc-lookup
description: Look up library, framework, API, or CLI docs, and cache what was hard to find. Triggers - "how does X work in <lib>", version/migration questions, config syntax, an API guess about to be made from training data, OR a debugging session just produced a reusable answer.
---

## Never answer library questions from training data

Training data goes stale silently — the answer is confidently wrong rather than
absent, which is the expensive failure. Look it up.

Order:

1. `context7` — resolve the library id, then query. Fastest, purpose-built.
2. `WebFetch` on the canonical docs URL when context7 lacks the library or the
   answer is version-specific.
3. Bundled local docs. Many tools ship them and they match the installed
   version exactly, which web docs may not — kitty's `share/doc/kitty/html` and
   `man` pages have both settled questions here that the web answered wrongly.
4. Reading the installed source. Authoritative, and the only option for
   behaviour that is not documented at all.

## Cache what was hard to find

This applies to answers *produced* by debugging, not only answers *sought* by a
lookup. A long bisect that ends somewhere non-obvious is the highest-value thing
to cache and the easiest to walk away from, because by then the problem feels
solved. If the next session would repeat the search, write it down.

When a lookup was slow, took several attempts, or ended somewhere non-obvious,
record it in `references.md` beside this file. The next lookup starts from the
answer rather than repeating the search.

Write an entry when any of these hold:

- The obvious source was wrong or absent and the real one was elsewhere.
- A better method was found than the one used first.
- The answer came from reading source or bundled docs rather than the web.

Format, one per line:

```
<topic> | <where> | <verified YYYY-MM-DD> | <note>
```

Do not cache what context7 answers on the first try. That is not a miss, and
caching it just adds a stale copy of something already reliable.

## Tombstoning

A cached pointer is a claim about the world, and the world moves. Every entry
carries the date it was verified. Treat an entry older than roughly six months
as a hint rather than a fact: follow it, but confirm the answer still holds
before relying on it, and restamp the date when it does.

When an entry turns out to be wrong, do not delete it silently. Mark it:

```
~~<topic>~~ | DEAD as of <date> | <what is true now, or "unknown">
```

The tombstone is worth more than the empty space. Deleting the entry invites
the next session to rediscover the same dead end and re-add it. The tombstone
says the path was tried and where it led.

Drop a tombstone only once the thing it describes is gone entirely — the
library removed, the tool no longer used.
