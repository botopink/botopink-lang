# try_catch_host_raise_propagates

The reference text this cell shows (from `conformance/docs.md`, § Results):

> `try e catch f` handles the `Error` of its operand's `@Result` on the spot. A raise that does not
> arrive as one — a host binding's, a `@panic` — leaves the `try … catch`; only `attempt` contains it.
> A `result: true` binding answers its failure as an `Error`, so that one reaches the `catch`.
