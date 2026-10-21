# render_scope_construction

The reference text this cell shows (from `conformance/docs.md`, § use — imports, activation, and hooks):

> Outside every body — `main`, a test, a plain function, a lambda — a root runs
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
