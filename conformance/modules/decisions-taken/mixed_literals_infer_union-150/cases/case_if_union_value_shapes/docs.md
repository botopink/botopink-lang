# case_if_union_value_shapes

The reference text this cell shows (from `conformance/docs.md`, § Union types, `unknown`, and `is`):

> A `case` whose arms disagree is the union of their types, and so is an `if` /
> `else` whose branches do — whatever shape an arm is written in (a value, a
> block, a lambda arm, over an `unknown` subject, in an `async` body that
> awaits) and wherever the value goes (a `val`, a `return` from a function
> answering the union, an argument of a parameter of it); each value read back
> is the member it is:
