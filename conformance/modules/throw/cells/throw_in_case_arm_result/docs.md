# throw_in_case_arm_result

The reference text this cell shows (from `conformance/docs.md`, § Results):

> A `throw` in a `case` arm is the enclosing function's: in an expression arm
> (`_ -> throw e;`) and in a block arm (`_ { …; throw e; }`), whether the `case` is
> returned, bound by a `val`, passed as an argument or written as a statement, the
> function answers `Error(e)` on that path and the other arms' value on the rest.
