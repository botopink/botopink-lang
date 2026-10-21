# assert_is_pattern

The reference text this cell shows (from `conformance/docs.md`, § Decided, not yet implemented):

> These forms are **deliberately absent**, so that none reads as unfinished work:
>
> | Form | What the compiler says |
> |---|---|
> | `assert x is Some(n)` — `is` binding a payload | `error[is-variant-binding]`: `is` tests a type; it does not bind. Read the payload in a `case` arm |
