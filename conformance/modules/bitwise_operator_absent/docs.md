# bitwise_operator_absent

The reference text this cell shows (from `conformance/docs.md`, § Decided, not yet implemented):

> These forms are **deliberately absent**, so that none reads as unfinished work:
>
> | Form | What the compiler says |
> |---|---|
> | `<<` `>>` `&` `^` | `error[bitwise-operator-absent]` — there are no bitwise operators; `&&` and `\|\|` are the boolean ones, and a bit operation is a host function |
