# abort_text_overflow

The reference text this cell shows (from `conformance/docs.md`, § Builtins):

> What an uncaught abort writes is the `Failure` an `attempt` would have answered
> (decisions 535, 527), one line, `<kind>: <message>`, on every target: `panic: <message>` for
> `panic`, a failed `assert`, an overflow or a division by zero, `host: <message>` for a raise of a
> host binding without `result: true`, `crash: <reason>` for any raise nothing marked — a `case` no arm
> matches, `badarith`. Never the runtime's raw `Class:Reason` term. A target that does not abort where
> another does (a float division by zero: commonJS and wasm answer `Infinity`) declares that departure; the
> text of an abort is not one.
