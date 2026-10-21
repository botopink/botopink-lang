# embed_through_comptime_param

The reference text this cell shows (from `conformance/docs.md`, § `Asset`):

> The path is relative to the `botopink.json` of the package that writes it; a
> path passed on through a `comptime` parameter is read in the caller's package —
> the function takes the caller's `Asset`, read where the call is written.
