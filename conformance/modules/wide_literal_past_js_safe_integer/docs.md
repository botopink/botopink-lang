# wide_literal_past_js_safe_integer

The reference text this cell shows (from `conformance/docs.md`, § Numbers):

> The range is the type's on every target (decision 319). On commonJS an `i64`
> (and `isize`, `u64`, `usize`) is a JS `number` while it lies within
> ±(2^53 − 1) and a `BigInt` beyond, always in that canonical form, so `==`, a
> `Dict` key and a `Set` member compare by value across 2^53; an operation keeps
> the number's fast path and computes in `BigInt` only when its result leaves
> that range. A Node host template receives and answers such a value as
> `number | bigint` in the canonical form, and the emitted `.d.ts` types it so.
> The narrower integers stay JS numbers. An integer `/` or `%` by zero aborts on
> every target (commonJS names it `integer division by zero`). A `%` never leaves its type.
> No flag turns the check off (decision 67); wrapping arithmetic, where an
> algorithm wants it, is written with an explicit operation.

`9007199254740993l`, past 2^53, prints exactly as written on every target — commonJS holds it as a `BigInt`.
