# yamlconf

The reference text this cell shows (from `conformance/docs.md`, § Functions expanded at their call):

> A function taking `comptime q: @Expr<…>` expands at the call site; `@expr`
> lifts a comptime value back into code. `q.value` is the literal's value when
> it has no `${…}` hole (decision 364 (2)); a holed literal is not known at
> build, and a template that reads `q.value` refuses it at the argument
> (`template-value-not-known`) — its parts are read with `q.parts()`.
