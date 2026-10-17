# comptime_deep_structure_equality

The reference text this cell shows (from `conformance/docs.md`, § Operators):

> At build, in a `comptime`, `==` compares two values of any depth (it walks an explicit work list, never the
> runtime's stack, so two 2,000,000-deep chains answer `true`), and an arithmetic error reads as Erlang's
> `badarith`, located at the expression: ``error: comptime-badarith: an error occurred when evaluating an
> arithmetic expression — `1.0 / 0.0` (division by zero)``, the same on every target. At run time each target
> keeps its own answer (commonJS and wasm `Infinity`, erlang and beam `badarith`). An integer division by zero
> at build is the same refusal, naming `7 / 0`:
