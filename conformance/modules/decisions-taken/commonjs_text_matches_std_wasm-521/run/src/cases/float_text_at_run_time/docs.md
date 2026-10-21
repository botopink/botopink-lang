# float_text_at_run_time

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> **Every target writes std-wasm's text** (decisions 441, 521). Where std-wasm's
> answer differs from a JS engine's, a program answers std-wasm's on every
> target — the text of erlang, beam and the comptime: a float is OTP's
> `float_to_binary(F, [short])`, the shortest digits that read back as the same
> `f64`, in fixed notation or as `D.DDDeE` when that is shorter, and as
> `D.DDDeE` from 2^53 on (`"${5.0}"` and `5.0.toString()` are `5.0`, `1000.0`
> is `1.0e3`, `1e21` is `1.0e21`, `0.000001` is `1.0e-6`,
> `9007199254740992.0` is `9.007199254740992e15`; `NaN`, `Infinity`,
> `-Infinity`, which only a wasm or commonJS program's arithmetic makes, are
> those words), and `trim` removes space, tab, LF, CR, VT and FF (a no-break
> space stays). A wasm program and its own comptime agree. commonJS writes the
> same text through its helpers, never the JS engine's number text, `trim` or
> case mapping — a string method reached through `?.`, or after a `?.` link in
> the same chain, included.
