# compiler_name_of_lambda

The reference text this cell shows (from `conformance/docs.md`, § `compiler`):

> `compiler.name(e)` answers a `?string` (decision 643): the name a declaration,
> a named function or a type is written as, and `null` for an expression that
> has no name — a lambda, a literal, a call, an operator expression. What a
> `null` means is the decorator's choice: `compiler.name(key) ?? "anonymous"`. On
> a declaration the answer is never `null`, and `compiler.name(decl)!` reads it
> as the `string` it is.
