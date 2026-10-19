# i64_full_range

The reference text this cell shows (from `conformance/docs.md`, § Numbers):

> An integer never wraps and never widens. `+`, `-`, `*`, `/`, a unary `-` and
> `+=` over `i8`, `i16`, `i32`, `i64`, `u8`, `u16`, `u32`, `u64`, `isize` and
> `usize` answer a value of the operands' type, and a result outside the type's
> range aborts the program on every target — `2147483647 + 1` on `i32`, `0 - 1`
> on `u32`, `-x` of an `i32` at its minimum, `i32`'s minimum `/ -1` (decision
> 264). The abort names the operator, the type and the place on stderr:
>
> ```text
> integer overflow: + on i32 at src/main.bp:7:14
> ```
>
> | Type | Range |
> |---|---|
> | `i8` / `u8` | −128 … 127 / 0 … 255 |
> | `i16` / `u16` | −32768 … 32767 / 0 … 65535 |
> | `i32` / `u32` | −2^31 … 2^31 − 1 / 0 … 2^32 − 1 |
> | `i64`, `isize` / `u64`, `usize` | −2^63 … 2^63 − 1 / 0 … 2^64 − 1 |
> | `bigint` | any integer: no range, never an overflow (below) |
>
> The range is the type's on every target (decision 319). On commonJS an `i64`
> (and `isize`, `u64`, `usize`) is a JS `number` while it lies within
> ±(2^53 − 1) and a `BigInt` beyond, always in that canonical form, so `==`, a
> `Dict` key and a `Set` member compare by value across 2^53; an operation keeps
> the number's fast path and computes in `BigInt` only when its result leaves
> that range. A JavaScript host template receives and answers such a value as
> `number | bigint` in the canonical form, and the emitted `.d.ts` types it so.
> The narrower integers stay JS numbers. An integer `/` or `%` by zero aborts on
> every target (commonJS names it `integer division by zero`). A `%` never leaves its type.
> No flag turns the check off (decision 67); wrapping arithmetic, where an
> algorithm wants it, is written with an explicit operation.
