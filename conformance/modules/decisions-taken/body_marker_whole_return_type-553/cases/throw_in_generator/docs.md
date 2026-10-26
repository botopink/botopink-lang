# throw_in_generator

The reference text this cell shows (from `conformance/docs.md`, § Results):

> A `throw` or a propagating `try` needs a `Result` in some layer of the
> enclosing function's return (`Result<T, E>`, `Async<Result<T, E>>`,
> `Iter<Result<T, E>>`, …); in a function with none, and in a lambda whose
> expected return has none, both are `effect-try-without-fallible-channel`. The
> message names the two ways out: `try … catch` handles the failure on the spot,
> in any function, and needs no channel; a host binding answers a `Result` with
> `result: true` (§ Host bindings). The refusal is located at the `throw` or the
> `try`, and its middle part names the return that lacks the channel — a plain
> `fn`, an `Async<T>`, a `Component`, the item of an `Iter<T>`, a lambda's
> expected return:
