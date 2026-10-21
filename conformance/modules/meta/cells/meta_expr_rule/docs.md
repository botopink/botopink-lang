# meta_expr_rule

The reference text this cell shows (from `conformance/docs.md`, § Typed meta (decision 298)):

> A meta record may hold `@Expr<T>` fields (decision 370 (1)): the decorator
> hands one of its `syntax x: T` parameters on as it is, and the value
> is built in the reading program with the expression spliced where the
> annotation wrote it — a rule is called, a message evaluated, at run time, never
> while the program compiles. Such a field takes a parameter and nothing else,
> and a parameter goes to no other field (`decorator-meta-expr-arg`; a plain field
> reads `x.value`). The expressions resolve their names where the annotation
> wrote them, wherever the value is read (decision 385): a private rule of the
> annotation's module is reached, a same-named function of the reader is not.
