# Decision 403 — `@Decl` carries no source location: a decorator's output never depends on where its file sits.

The route reaches `#[page]` as its argument, `"blog/[slug]"`, written by the author — or, in a framework, by the route table it generates from the `app/` tree and passes the same way. Nothing of where the file sits names the page: the declaration handle has no `loc`, and moving this module to another directory changes nothing the decorator answers about the route. `compiler.src()` inside the decorator body is legal and answers the annotated declaration's location; the decorator records it beside the route as a value a diagnostic may carry. The program prints `blog/[slug]`, then `src/main.bp` and the line where `blogPost` is declared.

Cells in this repository that also bear on it: `modules/compiler_point_reads`.

[draft/main.bp](draft/main.bp) · [draft/comptime/pages.bp](draft/comptime/pages.bp)
