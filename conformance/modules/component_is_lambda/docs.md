# component_is_lambda

The reference text this cell shows (from `conformance/docs.md`, § use — imports, activation, and hooks):

> A component is a lambda over a render scope (decision 388): `fn C(…) ->
> Component<R>` answers a function of std's opaque `RenderScope`, and calling
> `C` runs nothing (`itens.map(Card)` answers lambdas, which the render runs with
> the scope of the body that places them). In the body, `use provide(ctx)` makes
> the scope its children receive, `use context(T)` finds `T`'s identity in the
> scope the body received, else `T`'s declared default, and `await c` runs `c`
> with the children's scope. Outside every body — `main`, a test, a plain
> function, a lambda — `await c` runs `c` with `RenderScope.root()`, and
> `c.run(scope)` answers the result and the children's scope, so a render
> library holds the scopes explicitly; `RenderScope(…)` is refused
> (`comptime/context_lower.zig`). A `Context<T>` is its value at run time. A
> lambda written in a body is outside it: it takes the scope of the call that
> runs it. erlang, beam, commonJS and wasm run it — on wasm a value crosses the
> scope as its own word, typed where it is read back by the checker's type the
> lowering carries (decision 504); a value of any type crosses it, an `f64` or
> an `i64` provided or rendered there included — and a `?f64` or a `?i64`, with
> its number or `null`. The comptime runtimes do not run this lowering: a
> `comptime` that reaches a `use` is refused (`language-gaps.md` row
> 354-comptime).
