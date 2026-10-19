# Decision 590 — (a), as built.

`compiler.hooks(decl)` answers one `HookNode` per function reachable from the annotated one, and its fields hold
declaration handles: `function` is the node's own declaration, and each `HookUse`'s `context` the context value the
`use` reads or provides, `null` when the hook takes none. `#[graph]` in [draft/comptime/graph.bp](draft/comptime/graph.bp)
walks the list of `App` in [draft/pages.bp](draft/pages.bp) and names each handle with `compiler.name` — the field is
called `function`, never `fn`, a reserved word. `App` provides `themeContext` and composes `Label`, which reads it, so
the meta holds `App uses themeContext` and `Label uses themeContext`, and `main` prints those two lines, reading the meta
from another module under `comptime`.

Cells that also bear on it: `modules/decisions-taken/context_named_by_value_type-379/cases/decl_hooks_context`, `modules/decisions-taken/decl_hooks_reachable_components-277/cases/decl_hooks_direct`, `modules/decl/cases/decl_hooks_graph`,
`modules/decisions-taken/decl_hooks_reachable_components-277/cases/decl_hooks_all_nodes`.

[draft/main.bp](draft/main.bp)
