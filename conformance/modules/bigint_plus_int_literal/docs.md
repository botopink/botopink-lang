# bigint_plus_int_literal

The reference text this cell shows (from `conformance/docs.md`, § Numbers):

> `bigint` is an integer of any size (decision 332): `+`, `-`, `*`, `/`, `%`, a
> unary `-`, `+=`, the comparisons and `==` over two `bigint`s answer exactly and
> never overflow; `/` truncates toward zero and `%` takes the dividend's sign, as
> for the other integers, and `/` or `%` by zero aborts. Its literal is suffixed
> `n` (`2n`); an unsuffixed literal is never one, and a `bigint` mixes with no
> other number — the crossing is written: `bigint.of(n)` (an `i64`) and
> `bigint.parse(text)` (`@Result<bigint, string>`, a decimal numeral of any
> length) in, `toString()`, `toI64()` and `toF64()` out, each conversion aborting
> when the value does not fit (`toI64: 9223372036854775808 does not fit i64`).
> erlang and beam hold the VM's own integer, commonJS a `BigInt` (`.d.ts`
> `bigint`), and wasm a block of 32-bit limbs its runtime computes on. A `bigint`
> does not widen to `unknown`, `is` does not test one (a value typed `bigint` is
> one), and a `comptime` does not compute one yet.
