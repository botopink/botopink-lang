# component_default_fn_sync

The reference text this cell shows (from `conformance/docs.md`, § use — imports, activation, and hooks):

> **Lowering.** `use f(x)` is `f(x)` on erlang, wasm and beam. On commonJS a
> `@Component` function whose hooks node is asynchronous (`HookNode.async`,
> decision 375 — it writes `await` or `async { … }`, or reaches an asynchronous
> hook, component or host task) is an `async function`, and a `use` or call of
> it is awaited (`await f(x)`); a synchronous one is a plain `function`, and a
> `use` or call of it is not awaited, written or not — `await` stays legal on
> any component, a no-op on a synchronous one. A method answering `@Component`
> — a type's, an enum's, a behavior's `default fn` — is marked by its own body
> as a top-level function is, and a call of a `default fn` follows the adopting
> type's `implement` to the behavior's mark (decision 375, question 04s12-a); a
> lambda is an `async` arrow only when its own body awaits. The prefix is the activation the
> checker validated, not a rename: nothing is turned into `useState`, no
> dependency array is inferred — a function that takes one declares it as a
> parameter (`memo(compute, deps)`). A client runtime supplies hook semantics
> through what `f` does; the pure body above is what every backend runs, and what
> the server renders.
