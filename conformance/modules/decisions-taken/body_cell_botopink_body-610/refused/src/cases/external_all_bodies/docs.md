# external_all_bodies

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> The cell exists for the per-target split — `.Erlang("lists:reverse($0)")`
> beside `.Wasm(body: reverseBody)`. A declaration whose every source is a
> `body:` — on every target, or `.Wasm(body: f)` alone on a wasm-only function —
> runs the botopink body wherever it runs, so it is a bodied `fn`, one form:
> the annotation is refused, `external-all-bodies`, "write the function with
> that body" (std's `pow` is such a `fn`):
