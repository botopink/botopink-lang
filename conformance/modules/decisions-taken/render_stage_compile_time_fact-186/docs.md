# Decision 186 — The stage a page renders in is a compile-time fact.

The example decides at build which stage each page renders in. The build layer ([draft/comptime/stages.bp](draft/comptime/stages.bp)) declares the marker `serverOnly` and the decorator `page`. `page` reads the page's hooks list, `compiler.hooks(decl)`: every function the page reaches through components, with each `use` and the annotations of the hook it uses. It records `Stage("D")` when a `use` reaches a `#[serverOnly]` hook, and `Stage("S")` otherwise.

In [draft/pages.bp](draft/pages.bp), `Search` uses `searchParams`, a `#[serverOnly]` hook, so it is dynamic and renders per request. `Home` reaches none, so it is prerendered. No page declares or forces its own stage. The hooks list carries everything the decision needs, and the compiler names no stage, marker or library. `main` reads both stages from another module, after the decorator that reads the hooks has run.

The program prints `S` and `D`. Written by the markup library, the same reading refuses a `#[serverOnly]` hook used inside a `#[client]` component, at the `use`.

Cells in this repository that bear on it: `modules/decisions-taken/context_named_by_value_type-379/cases/decl_hooks_context`, `modules/decisions-taken/query_template_assembled_at_build-415/cases/template_lookup_meta_hooks_pending`.

[draft/main.bp](draft/main.bp)
