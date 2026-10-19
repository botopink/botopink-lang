# Decision 291 — A page reads the request and writes the response through two hooks:

The example reads the request and writes the response through two hooks, `request()` and `response()`, both `#[serverOnly]` ([draft/pages.bp](draft/pages.bp)). `NotFound` writes `val req = use request();` and `val res = use response();`, then `res.status(404)` and `res.header("Cache-Control", "no-store")`. These are methods of the response handle, and every value stays immutable. Because it reaches a `#[serverOnly]` hook, the `page` decorator of the build layer ([draft/comptime/stages.bp](draft/comptime/stages.bp)) reads its hooks list and records it as dynamic, `D`. `About` reaches neither hook and is prerendered, `S`. The stage is typed meta of the page, read at build, so no `isPrerendered()` is needed at run time. The plain calls `responseStatus` / `responseHeader` do not exist. Status and headers are legal until the response head is written; after that they are a located run-time error, like `redirect`.

The program prints `no page at /missing`, `status 404, Cache-Control: no-store`, `D` and `S`.

Cells in this repository that bear on it: `modules/decisions-taken/context_named_by_value_type-379/cells/decl_hooks_context`.

[draft/main.bp](draft/main.bp)
