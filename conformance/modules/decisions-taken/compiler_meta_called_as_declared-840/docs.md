# Decision 840 — `compiler.meta` and `compiler.metaAll` are called as declared, `compiler.meta(d, Entity)` / `compiler.metaAll(d, Index)`; `compiler.meta<M>(d)` is no spelling; amends 298's and 576 (3)'s spelling, 727.

[cases/meta_called_as_declared/src/main.bp](cases/meta_called_as_declared/src/main.bp)

`#[entity]` records an `Entity` and two `Index` values on `User`. The template `describe` reads them back with the
declared call, the type passed as the argument: `compiler.meta(decl, Entity)` answers `?Entity`,
`compiler.metaAll(decl, Index)` answers `Index[]`. The generic spelling `compiler.meta<Entity>(decl)` is no spelling: it
is the ordinary missing-argument refusal.
