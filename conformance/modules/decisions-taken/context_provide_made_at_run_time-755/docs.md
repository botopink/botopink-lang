# Decision 755 — (a): `use memo` is std's hook `memo<T>(make: fn() -> T) -> Component<T>` — computed on the component's first render, kept for that component instance, never recomputed; no dependency list.

The example's `App` makes the context it provides from its own parameter `dark`. `use memo({ -> … })` runs `make` on the instance's first render and keeps the context, and `use provide(c)` hands it to `Label` below, which reads it with `use context(themeContext)`. Each of the two instances makes its own context once. The program prints `context made for night`, `night: dark`, `context made for day` and `day: light`.

Cells in this repository that also bear on it: `modules/decisions-taken/component_wrapper_and_contexts-354/cells/context_provide_read`, `modules/decisions-taken/component_wrapper_and_contexts-354/cells/context_provide_bound`.

[draft/main.bp](draft/main.bp)
