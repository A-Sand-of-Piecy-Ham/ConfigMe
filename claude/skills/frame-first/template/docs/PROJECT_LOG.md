# Project log

Decisions made, what is still to do, and what has been finished. Newest
first within each section.

## Decisions

| Date | Decision | Why |
|---|---|---|
| <date> | <decision> | <why; "Owner's call" where it was> |

## Rows written during the work

What implementers record while building (contract gaps they filled, frozen
things they dispute, work outside their milestone, public items they added,
friction) is not in this file. It is one JSON object per line in
[log.jsonl](log.jsonl), so that `scripts/check` can read it and it can be
queried:

```bash
jq -c 'select(.settled == null)' docs/log.jsonl        # still open
jq -r 'select(.kind == "gap") | [.milestone, .where, .chose, .settled] | @tsv' docs/log.jsonl
```

The row format is in [AGENTS.md](../AGENTS.md#log-rows). At each checkpoint
the reviewer adds a `settled` field to every open row. A ruling that needs
more than a phrase goes in "Decisions" above.

## TODO

- <what is known to be missing and not in any milestone>

## Done

- <date>: frame written.
