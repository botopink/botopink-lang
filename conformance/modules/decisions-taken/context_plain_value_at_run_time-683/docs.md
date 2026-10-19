# Decision 683 — std's `Context<T>` holds `contextValue: T`, and at run time a context is its plain value — an `f64` / `i64` context crosses wasm's scope as any value.

The example declares two contexts whose values are bare numbers: `rateContext` over an `f64` and `limitContext` over an `i64`. std's `Context<T>` is a record that holds `contextValue: T`, so `rateContext.contextValue` reads `1.5` directly. At run time a context is its plain value. When `Page` provides `createContext(2.25)` and `Price` reads it with `use context(rateContext)`, the number crosses the render scope as any value would, on wasm as on the other targets, and wide integers are not boxed. `Price` prints both numbers, `2.25 x 100` under `Page` and the defaults' `1.5 x 100` when rendered alone.

The program prints `1.5`, `1.5 x 100` and `2.25 x 100`.

Cells in this repository that bear on it: `modules/context_wide_number_through_scope`, `modules/context_optional_wide_number_through_scope`, `modules/context_default`.

[draft/main.bp](draft/main.bp)
