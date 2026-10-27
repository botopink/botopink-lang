# function_value_prints

A function value prints `fn/<arity>`, the arity it is declared with (a default parameter counted): a top-level
`fn` (`fn/1`, `fn/0`, and `fn/2` for `scaled(x, by = 3)`), a closure, an associated function named without a
call, a record field (`Handler(name: "x", run: fn/2)`), an array's elements, a template hole, and the same text
printed by a `comptime` body at build — no name, no `#Fun<…>`, no `[Function]`, no source text.

Each shape a backend may lower a function to answers its declared arity (decision 1062): `Box.all(first, ..rest)`
is `fn/2` (a rest parameter), `Box.make(n, k = 1)` `fn/2`, an `async fn` of two parameters `fn/2`, a component with
no parameter and one that `use`s a hook `fn/0` and `fn/1`, and a generic `shown<T>(x)` (which takes its type's print
shape too on commonJS) `fn/1`. A template hole of a function in a `comptime` body (`"hole ${scaled}"`, and
`comptime "${twice}"`) writes `fn/2` and `fn/1`.
