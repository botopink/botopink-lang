# Decision 726 — A type argument's `compiler.Info<unknown>` in a `HookUse` carries the type's whole declaration.

The example's `Post` component writes `use params<BlogParams>(…)`, and the decorator `#[args]` reads the hooks list of `Post`. The `use`'s type argument is `BlogParams`'s whole declaration: `compiler.fields(t)` gives `slug` with its `#[trimmed]` annotation and `id` with none, and `compiler.methods(t)` gives its one method, `label`. `#[args]` records them as `HookArgs`, and `main` reads that meta at build. The program prints `slug[trimmed] id[] methods:1`.

Cells in this repository that also bear on it: `modules/decisions-taken/route_read_through_hooks-293/cells/decl_hooks_type_args`.

[draft/main.bp](draft/main.bp)
[draft/pages.bp](draft/pages.bp)
