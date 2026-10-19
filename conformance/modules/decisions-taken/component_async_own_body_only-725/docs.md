# Decision 725 — A component is never asynchronous because of its children: 375's mark counts the node's own body only.

A component is asynchronous because of what its own body writes, never because of its children. `#[marks]`, in
[draft/comptime/marks.bp](draft/comptime/marks.bp), records each node of `compiler.hooks(Page)` with its mark, and
`main` prints them. In [draft/pages.bp](draft/pages.bp), `Comments` writes `await` and `Pause` awaits a host function
answering `Async`, so both are `async`. `Header` writes nothing that waits, and `Counted` calls `count()`, a botopink
function answering `Async<i32>`, without awaiting it — neither is marked: `direct`. `Page` composes all four, but
composing only puts their lambdas in the tree it answers, so `Page` is `direct` too. A marked component's run answers a
task of its tree and every other answers the tree at once; the root is always asynchronous, the renderer awaiting only
the marked lambdas it meets while descending. The program prints `Page: direct`, `Header: direct`, `Comments: async`,
`Pause: async`, `Counted: direct`.

Cells that also bear on it: `modules/decisions-taken/async_marked_by_hooks_list-375/cases/decl_hooks_async`, `modules/decisions-taken/async_marked_by_hooks_list-375/cases/decl_hooks_async_imported`,
`modules/decisions-taken/component_value_is_hooks_node-389/cases/decl_hooks_component_value`, `modules/decisions-taken/decl_hooks_reachable_components-277/cases/decl_hooks_function_value`.

[draft/main.bp](draft/main.bp)
