# defer_panic_attempt_catches

The reference text this cell shows (from `conformance/docs.md`, § Blocks):

> `defer <expr>;` runs `<expr>` when the block it is written in ends (decision 539) — block scope, as in
> Zig and Swift. Several run in reverse order, and each runs on every exit of the block: the end,
> `return`, `break`, `continue`, a propagating `try`, a `throw`, a panic `attempt` catches:
