# function_value_prints

A function value prints `fn/<arity>`, the arity it is declared with (a default parameter counted): a top-level
`fn` (`fn/1`, `fn/0`, and `fn/2` for `scaled(x, by = 3)`), a closure, an associated function named without a
call, a record field (`Handler(name: "x", run: fn/2)`), an array's elements, a template hole, and the same text
printed by a `comptime` body at build — no name, no `#Fun<…>`, no `[Function]`, no source text.
