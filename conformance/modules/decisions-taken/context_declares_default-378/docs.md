# Decision 378 — A context always declares its default; a read answers the nearest provider above or the default; `context-unbound` goes.

`themeContext` is made with its default, `Theme(primary: "#e11d48", radius: 4)`, and `comptime` computes it at build.
`Swatch` reads it with `use context(themeContext)`. Rendered with nothing above it, the read answers the default, and
the first line is `#e11d48/4`. No `context-unbound` exists to fall into. `Dark` provides another `Theme` and renders a
`Swatch` below it, which answers that value: `dark #111827/0`. `Outer` provides a third `Theme` and renders `Dark`
inside it. The `Swatch` under `Dark` still sees `#111827`, the nearest provider winning, while `Outer`'s own `Swatch`
sees `#2563eb/8`. The last line comes from a component called at build. `swatchAtBuild` runs `Swatch` on the comptime
runtime with `RenderScope.root()`, where no provider exists, so its read is the default, known at build, and the
module `val` is the string constant `#e11d48/4`.

Cells in this repository that also bear on it: `modules/decisions-taken/context_named_by_value_type-379/cases/context_default`,
`modules/decisions-taken/context_read_by_value-722/cases/context_default_imported`.

[draft/main.bp](draft/main.bp)
