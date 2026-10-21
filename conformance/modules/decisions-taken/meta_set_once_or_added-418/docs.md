# Decision 418 — One meta type is set once or added, never both, and `meta(T)` over several values is refused.

The example records `Entity` meta on `City` twice. The build layer ([draft/comptime/entity.bp](draft/comptime/entity.bp)) has `entity`, which sets it once with `setMeta`, and `alias`, which adds one with `addMeta`. One meta type is either set once or added, never both, so the second annotation is refused, `decorator-meta-twice`, located there. Reading is held to the same rule. Had both decorators added (`addMeta`), `compiler.typeInfo(City).meta(Entity)` over the two values would be refused `typeinfo-meta-several` at the read, and they would be read with `metaAll`. `metaAll` over a set-once value answers a one-element array, so the line in `main` would print `cities` for a type annotated with `entity` alone.

Cells in this repository that bear on it: `modules/decisions-taken/decorator_meta_keyed_by_type-298/refused/src/cases/meta_twice`, `modules/decisions-taken/decorator_meta_keyed_by_type-298/refused/src/cases/meta_several`.

[draft/main.bp](draft/main.bp)
