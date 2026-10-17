# external_wasm_needs_unknown

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> **A binding declares the host features it needs** (decision 518):
> `#[.Wasm(wasi: .Attempt, needs: [.Exceptions])]`, each a value of
> std's closed enum `WasmNeed { Exceptions, Http }`. […] A value outside
> `WasmNeed`, or `needs:` on another `External` variant, is an error at the
> annotation, on every target.
