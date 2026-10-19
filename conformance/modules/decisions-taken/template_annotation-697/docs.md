# Decision 697 — A type's or a behavior's methods' decorators run before the owner's; a method's `compiler.setMeta` / `addMeta` is kept for its owner (one value per type and method, `decorator-meta-twice`), and the owner's body reads it through `compiler.methods(decl)` — `compiler.meta<Query>(m)` / `compiler.metaAll<Query>(m)` (576 (8), 313, 298).

The example puts a decorator on each of `Users`'s methods and one on `Users` itself, all declared in the build layer ([draft/comptime/repository.bp](draft/comptime/repository.bp)). The methods' decorators run first: each `#[query(…)]` records a typed `Query` meta on its method, one per method. That meta is kept for the owner, and a second `setMeta` of a `Query` on one method would be refused, `decorator-meta-twice`. The owner's `#[repository]` then walks `compiler.methods(decl)`, reads each method's meta with `compiler.meta<Query>(m)` and adds the member `queries()`, which lists them. `plain` has no meta and is left out. String meta on a method stays refused, and a field's decorator records no meta.

The program prints `byId: select * from users where id = ?; count: select count(*) from users`.

Cells in this repository that bear on it: `modules/decisions-taken/decorator_four_output_places-216/cases/decorator_meta_on_member`, `modules/decisions-taken/typed_member_reads_own_meta-395/cases/member_reads_own_meta`.

[draft/main.bp](draft/main.bp)
