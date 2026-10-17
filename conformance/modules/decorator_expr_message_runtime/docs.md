# decorator_expr_message_runtime

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> A function or a type argument is checked at the argument and never run at
> build (decision 364 (3)): its `@Expr` has no `.value` (`expr-value-of-function`,
> `expr-value-of-type`, at the read). The body hands an `@Expr` on to the program
> through a typed member (decision 370 (2)) — `decl.addMember(name, fn…)` with
> the member written as a function expression at the call, its parameters and
> its return typed:
