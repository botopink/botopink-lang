# comptime_attempt_at_build

The reference text this cell shows (from `conformance/docs.md`, § Results):

> `attempt` answers the same at build: a `comptime` body, a template or a
> decorator that calls it gets `Ok` of the thunk's value, or
> `Error(Failure(message, "panic"))` for the abort the thunk raised — as a wasm
> program does, on every target (decisions 518, 543).
