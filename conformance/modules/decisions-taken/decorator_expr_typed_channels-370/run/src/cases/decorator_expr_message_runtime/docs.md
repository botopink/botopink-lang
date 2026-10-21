# decorator_expr_message_runtime

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> A function or a type argument is checked at the argument and never run at
> build (decision 364 (3)). The body hands a `syntax` on to the program through a
> typed member (decision 370 (2)) — `compiler.addMember(name, fn…)` with
> the member written as a function expression at the call, its parameters and
> its return typed:
