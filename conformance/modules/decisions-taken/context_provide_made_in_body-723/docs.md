# Decision 723 — `use provide(ctx)` takes a context value alone — there is no `(ctx, value)` form; a component that provides another value makes a context of the same type in its body, `val c = comptime createContext(Theme(…));` (a build value) or `val c = use memo({ -> createContext(Theme(…)) });` (run time, memoised with the component), then `use provide(c)`; `use context(ctx)` answers the nearest context of `ctx`'s type provided above, else `ctx`'s own default.

The example reads one context, `themeContext`, in `Card`, and provides it three ways. `use provide(ctx)` takes a context value alone, so a component that provides another value first makes a context of the same type in its body. `Dark` makes one at build, `val c = comptime createContext(Theme(cls: "dark"));`, and provides it. `Live` makes one at run time, `use memo({ -> createContext(Theme(cls: cls)) })`, which is computed on the component's first render and kept for that instance. `Plain` provides `themeContext` itself, which provides the declared default again.

`Card` reads `use context(themeContext)`, the handle that supplies both the type and the default. It answers the nearest `Theme` context provided above, so it prints `dark` under `Dark` and `live` under `Live`. Rendered alone, or under `Plain`, it prints the default, `plain`. A context's identity is its type, so the three provided values all reach the `Card` that reads `themeContext`.

The program prints `plain`, `dark`, `live` and `plain`.

Cells in this repository that bear on it: `modules/context_provide_read`, `modules/context_nearest_wins`, `modules/context_default_imported`.

[draft/main.bp](draft/main.bp)
