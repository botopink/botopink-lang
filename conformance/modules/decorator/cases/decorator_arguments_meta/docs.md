# decorator_arguments_meta

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> 1. **Every parameter after `@Decl` is `comptime x: @Expr<T>`**, written out —
>    the argument is the user's expression, checked against `T` where it is
>    written (decision 364); what runs later comes from the decorator's outputs.
>    A parameter without `comptime` is `decorator-param-not-comptime` at the
>    parameter, and one without `@Expr` `comptime-param-not-expr`. A `comptime` parameter may
>    take a default, which an annotation that leaves it out gets — a literal,
>    `null`, a variant `.Name`, or an array or tuple of those; outside a
>    decorator no call fills one, and a `comptime` default there is
>    `comptime-default-outside-decorator` at the default.
> 2. **An argument may be of any type** — a string, a number, an array, a
>    record built by its constructor (directly or through a module `val`), a
>    variant, a function, a type (`comptime t: @Expr<type>`), a field. It is checked
>    against its parameter's type at the argument (an integer literal takes the
>    integer type asked for, decision 247), positional arguments first and
>    labelled ones by name (`at: .confirm`); a variadic last parameter (decision
>    267) takes the positional arguments left. The body reads each argument's
>    value with `x.value`, as it is: `[1, 2]`'s has length 2. An argument not
>    known at compile time — a function call such as `env("X")`, a module `var`
>    — is refused at it (`decorator-value-not-comptime`) when the body reads the
>    parameter; a body that never reads it accepts any expression of `T`.
>    `x.fail("…")` refuses the declaration at `x`'s argument, not at the
>    annotation.
> 3. **`@Decl<P>` names the shape of the annotated declaration** — a type, a
>    field's type, a function's type — and binds the type parameters `P` names,
>    through a pattern too: `@Decl<fn(e: E) -> unknown>` binds `E` to the
>    function's parameter type. A declaration that does not fit is refused at the
>    annotation, both shapes spelled; `@Decl` alone is `@Decl<unknown>`.
> 4. **`Type.Field<T>` and `.name`** — a field of `T` (decision 308, std's
>    `types.bp`); `.name` resolves against the `T` the parameter expects, a field
>    `T` does not declare is refused at the `.name`, and the body reads it as the
>    record `decl.fields` hands out (`name`, `typeName`, `annotations`). A
>    variant against an enum parameter resolves the same way. Either is named
>    exactly as declared, case included: `.custom` against `Custom` is the
>    missing-name error. A name that points at botopink code is a reference; a
>    name of another system (a table, a URL, a cache key, text for a user) stays
>    a string.
