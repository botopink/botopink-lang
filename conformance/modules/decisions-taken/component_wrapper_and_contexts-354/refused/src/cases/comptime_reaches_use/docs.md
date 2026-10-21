# comptime_reaches_use

The reference text this cell shows (from `conformance/docs.md`, § use — imports, activation, and hooks):

> A component is a function over a scope and a place (decisions 809, 815, 819):
> `Composition<T>` is `fn(scope: Scope, key: Place) -> T | Async<T>`,
> `Composable<T>` the behavior a type implements, and `Component<T>` their
> union — three prelude names written bare (decision 826), `Scope` and `Place`
> std's `context` module's. `fn C(…) -> Component<R>` answers its
> `Composition`, and calling `C` runs nothing (`itens.map(Card)` answers
> components) — in a component body too, where the call answers `Component<R>`
> as anywhere else (decision 791 (1)): Each component body opens its own cell, `scope.childAt(key)`, a child of the
> cell it was handed (decision 819 (1)). In the body, `use provide(ctx)` writes
> that cell, `use context(ctx)` finds the identity of `ctx`'s type in the
> contexts the cell held when the body entered, else `ctx`'s own default, and
> `use c` (decisions 791 (3), 812 (1)) resolves `c` under a child cell of the
> body's: `await c` over a component is refused at the `await`, in a body or outside
> every body, `await-component` (decision 791 (4)): `await` takes an `Async<T>`
> alone, and the message names `use c` and `c` placed in the tree as a child. Outside every body — `main`, a test, a plain function, a lambda — a root runs
> with std's `run`: `val page = await run(App());` resolves `App()` over a root
> of its own, `Scope.root()`, awaits it only when it answered a task (`is
> Async<unknown>`, decision 823) and closes the root when it settles (decisions
> 822, 825); handed a scope, `await run(c, scope)` runs over it and leaves the
> closing to whoever made it. std's `resolve(c, scope, key)` is the one way a
> component runs, its answer handed back as it came (decision 809 (6)). `Scope`
> is opaque — made by `Scope.root()`, a cell's `childAt` and `detach` —
> (`opaque-construction`); on erlang and beam a root's tree is one
> process-dictionary entry `{bp_scope, Ref}` of the process that made it, a
> scope crosses a process only as `scope.detach()` (`scope-foreign` otherwise),
> and a scope used after its root's `close()` fails `scope-closed` on every
> target (decisions 824, 825) (`comptime/context_lower.zig`).
> A `Context<T>` is its value at run time. A
> lambda written in a body is outside it: it takes the scope of the call that
> runs it. erlang, beam, commonJS and wasm run it — on wasm a value crosses the
> scope as its own word, typed where it is read back by the checker's type the
> lowering carries (decision 504); a value of any type crosses it, an `f64` or
> an `i64` provided or rendered there included — and a `?f64` or a `?i64`, with
> its number or `null`. The comptime runtimes do not run this lowering: a
> `comptime` that reaches a `use` is refused (`language-gaps.md` row
> 354-comptime).
