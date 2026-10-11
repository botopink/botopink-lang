# float_text_and_trim

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> **A wasm program writes std-wasm's text** (decision 441). Where std-wasm's
> answer differs from a JS engine's, a `--target wasm` program answers
> std-wasm's — the text of erlang, beam and the comptime: a float is OTP's
> `float_to_binary(F, [short])`, the shortest digits that read back as the same
> `f64`, in fixed notation or as `D.DDDeE` when that is shorter (`"${5.0}"` and
> `5.0.toString()` are `5.0`, `1e21` is `1.0e21`, `0.000001` is `1.0e-6`; `NaN`,
> `Infinity`, `-Infinity`, which only a wasm program's arithmetic makes, are
> those words), and `trim` removes space, tab, LF, CR, VT and FF (a no-break
> space stays). A wasm program and its own comptime agree. commonJS prints with
> the JS engine and keeps its text (`5`, `1e+21`).
