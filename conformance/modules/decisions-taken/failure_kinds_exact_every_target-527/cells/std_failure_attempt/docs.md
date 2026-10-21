# std_failure_attempt

The reference text this cell shows (from `conformance/docs.md`, § Results):

> On wasm `attempt` runs the thunk under wasm exception
> handling (decision 518): a program reaching it raises its aborts as an
> exception, which `attempt` catches as `panic`; a trap is no exception and
> ends the program.
