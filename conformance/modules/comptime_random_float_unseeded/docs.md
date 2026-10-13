# comptime_random_float_unseeded

The reference text this cell shows (from `conformance/docs.md`, § Compile-time evaluation):

> A `comptime` whose evaluation raises is refused at the call that raised
> (decision 451 (3)) — the innermost of this module's calls the raise leaves,
> `@panic` in a function the `comptime` called — not at the `comptime`
> expression, which the hint names as the frame that ran it:

`comptime io.random.float()` draws unseeded: refused at the call, 9:28, with the seeded stream's message (decision 456).
