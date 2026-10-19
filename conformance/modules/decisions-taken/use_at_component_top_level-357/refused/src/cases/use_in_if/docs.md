# use_in_if

The reference text this cell shows (from `conformance/docs.md`, § use — imports, activation, and hooks):

> - **Only a `Component<R>` return grants `use`** (decisions 104 and 118). A
>   `use` in any other body — a plain `fn`, a `Async` one whatever it wraps — is
>   refused at the `use`: `` use-without-component: `use` needs a
>   `-> Component<R>` return on the enclosing fn 'Widget' (it returns 'Element') ``.
>   Nothing is unwrapped to find one: the server component that awaits and
>   uses is `fn Page() -> Component<Element>`, which the chain lets `await`
>   (`Component ⊃ Async`). An `async { }` block is not the `Component` body
>   either: `use` is not inherited by it, as `await` is not.
> - **The wrapper takes one type argument.** `Component<C, R>` — decision
>   128's base — is refused where it is written, at the base: `` `Component`
>   takes one type argument, `Component<R>` — its base parameter was removed
>   (decision 354) `` (`generic-arg-count-exceeded`). The owner marker
>   `@Context<C>` left with it (`context-marker-removed`, naming `implement
>   Renderable`), and `Renderable` takes no type argument. An aliased return
>   (`type Comp<T> = Component<T>`) types the function but grants nothing
>   (`effect-wrapper-behind-alias`).
> - **A component never propagates** (decision 121). `throw` and `try` are legal
>   in a `Component` body only when `R` is a `Result`; a component returns
>   `Element`, so it handles a failure in its own body — `try await load() catch
>   fallback`, a `case`, a navigation signal or an error screen. A bare `try` there
>   is `effect-try-without-fallible-channel`. One read with `use` may return
>   `Component<Result<T, E>>`, and then its body may `try`.
> - **The operand is read with `use`.** `use plain()` where `plain : -> User` is
>   `` use-of-non-context-fn: `use` takes a hook: 'User' is not a hook `Component<R>` ``,
>   and `use Card()` where `Card` is a component (its `R` implements
>   `Renderable`) is refused: a component is called, not `use`d.
> - **The rules of hooks** (decision 357). A `use` is written at the top level of
>   its `Component` body and runs on every call, in the same order and the same
>   number. One inside an `if` / `else`, a `case` arm, a `for` / `while` /
>   `loop` (or an `iter` / `stream` loop), a lambda, a `catch` handler, the right
>   operand of `&&` / `||` / `??`, or after a statement that may `return`,
>   `throw` or `try` early is refused at the `use`, naming what encloses it:
>   `` use-not-top-level: `use` inside an `if` / `else` — a `use` is written at the
>   top level of a `Component` body and runs on every call (decision 357) ``. A
>   condition goes inside the argument, never around the `use` (the example
>   below the list).
> - **The type is `R`.** `val c = use state(0)` binds `c : State`, and
>   `val {value, set} = use state(0)` binds each name to the field of `R` it
>   names. A tuple `R` destructures positionally: with `optimistic : (i32, fn(i32,
>   i32) -> i32) -> Component<#(i32, fn(action: i32) -> i32)>`,
>   `val #(shown, push) = use optimistic(12, addLike)` binds `shown : i32` and
>   `push : fn(action: i32) -> i32`. The pattern's arity is the tuple's, and the
>   `R` has to be a tuple; either failing is refused at the binding —
>   `` use-tuple-arity: `val #(…)` binds 1 name(s) but the hook yields a tuple
>   of 2 `` and `` use-tuple-arity: `val #(…)` binds 2 name(s) but the hook
>   yields 'i32', which is not a tuple `` — with no flag (decision 67).
> - **`use` exists only where there is a render tree** (decision 354 (3)). A
>   decorator body, a template body and a `comptime { … }` are compile-time
>   evaluation with none: `use` there is `use-outside-render-tree`; what they
>   need of the program's marked declarations is the registry each decorator
>   writes with `compiler.init`, read when the program runs — nothing reads that
>   set at build (665).
> - **`use` never leaves a function body.** There is no module-level `use` and no
>   `use client;` / `use server;` directive (decision 87 of 1.0.10-beta): a
>   framework's boundary markers are its own decorators (`#[client]`).
>
> A condition inside the argument is at the top level; around the `use`, it is
> refused:
