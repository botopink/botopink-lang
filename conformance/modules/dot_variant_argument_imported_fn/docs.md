# dot_variant_argument_imported_fn

The reference text this cell shows (from `conformance/docs.md`, § Types — enums):

> A variant written with the leading dot is resolved by the declared type of the
> parameter it is passed to, whichever module declares the function:
> `phase.describe(.Slow)` with `describe(p: Phase)` in `phase`.
