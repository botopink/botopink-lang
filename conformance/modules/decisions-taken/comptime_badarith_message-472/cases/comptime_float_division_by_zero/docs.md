# comptime_float_division_by_zero

The reference text this cell shows (from `conformance/docs.md`, § Operators):

> At build, in a `comptime`, `==` compares two values of any depth (it walks an explicit work list, never the
> runtime's stack, so two 2,000,000-deep chains answer `true`), and an arithmetic error reads as Erlang's
> `badarith`: ``error: comptime-badarith: an error occurred when evaluating an arithmetic expression — `1.0 / 0.0`
> (division by zero)``, the same on every target. Every division and remainder by zero reads so — `/` and `%`,
> integer and float, alone, inside a larger expression, or in a function the `comptime` calls — and is located at
> the operator that divides, never at the whole expression. At run time each target keeps its own answer
> (commonJS and wasm `Infinity`, erlang and beam `badarith`). An integer division by zero at build is the same
> refusal, naming `7 / 0`:
