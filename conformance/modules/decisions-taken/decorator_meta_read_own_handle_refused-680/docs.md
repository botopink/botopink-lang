# Decision 680 — Inside a decorator, `compiler.meta<T>(decl)` on its own handle is refused; a declaration's meta is read by the code that consumes it, after every annotation ran.

A declaration's meta is read by the code that consumes it, once every annotation of the declaration has run, so no
annotation depends on the order the annotations are written in. `#[entity("users")]` records an `Entity` meta on
`User`, and `main` reads it at build, under `comptime`, as a consumer: `users`. `#[register]` is written before
`#[entity]` and still reads the settled value, because its read stands inside its `compiler.init` executor, which is
folded after every annotation of `User` ran — before `main`, the program prints `registered users`. `#[peek]` reads
`compiler.meta(decl, Entity)` in its own body, on its own handle, which would make its answer depend on whether
`#[entity]` ran first; that read is refused, located at the call in
[draft/comptime/entity.bp](draft/comptime/entity.bp), and the program does not run.

Cells that also bear on it: `modules/decisions-taken/hooks_decorator_runs_last-372/refused/src/cases/decorator_hooks_output`.

[draft/main.bp](draft/main.bp)
