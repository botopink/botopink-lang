# if_operand_of_operator

The reference text this cell shows (from `conformance/docs.md`, § If / else):

> An `if` used as a value needs its `else`: `val s = if (x > 0) { "positive" };` has no value when
> the condition is false and is refused at the `if`. It stands where an expression begins — a `val` /
> `var` initializer, the right side of `=`, a `return`, a call argument, a literal's element — and is
> never an operand: `1 + if (c) { 2 } else { 3 }`, `-if (c) 1 else 2` and `(if (c) a else b).v` are
> `error[if-operand]` at the `if`; bind it first (`val x = if (c) { 2 } else { 3 }; 1 + x`).
