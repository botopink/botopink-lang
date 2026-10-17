# typeinfo_all_duplicate_at_entry

The reference text this cell shows (from `conformance/docs.md`, § Compile-time evaluation):

> A `comptime` whose evaluation raises is refused at the call that raised
> (decision 451 (3)) — the innermost of this module's calls the raise leaves,
> `@panic` in a function the `comptime` called — not at the `comptime`
> expression, which the hint names as the frame that ran it:

The duplicate is refused at the entry point, at compile time, naming both declarations (decision 343); the refusal is
located at the `@panic` in `uniqueCommands`, 29:21.
