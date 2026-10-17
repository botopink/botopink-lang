# list_spread_not_last

The reference text this cell shows (from `conformance/docs.md`, § Decided, not yet implemented):

> These forms are **deliberately absent**, so that none reads as unfinished work:
>
> | Form | What the compiler says |
> |---|---|
> | `[..a, 3]` | `error[list-spread-not-last]` — the spread of an array literal comes last: `[3, ..a]` |
