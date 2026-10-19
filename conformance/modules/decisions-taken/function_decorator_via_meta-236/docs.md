# Decision 236 — A function decorator's per-function code is generic library code fed by meta: `#[page]` records its route in typed meta

`#[page]` is one generic decorator for every page. It writes nothing beside the function — no member, no generated name, no fifth place: it records the route as the typed meta `Route(pattern: …)` and registers the annotated function through `compiler.init`, whose executor reads that meta back (`compiler.meta<Route>(decl)` inside the executor is read after every annotation ran) and hands the pattern and the function to the registry. The pages stay plain functions. `dispatch` is generic code over the registry: it matches `blog/hello-world` against `blog/[slug]` and calls `post` with the segment, printing `post hello-world`, then `about us`, and `404 blog` for a path no route matches. In rakun the page reads its segments with `use params<P>()`, checked against the route; the decorator's part is the same — typed meta in, generic code out.

Cells in this repository that also bear on it: `modules/decisions-taken/decorator_decl_parameter_type_is_contract-716/run/src/cases/init_executor_handle_typed`, `modules/decisions-taken/compiler_call_in_executor_literal-614/cells/init_executor_reads_compiler`.

[draft/main.bp](draft/main.bp) · [draft/comptime/pages.bp](draft/comptime/pages.bp) · [draft/comptime/routes.bp](draft/comptime/routes.bp)
