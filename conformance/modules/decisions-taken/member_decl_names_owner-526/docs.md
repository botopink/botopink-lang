# Decision 526 — A member's `@Decl` names its owner: `owner: ?Declared<unknown>` (`null` at module level), set by the checker when it runs a member's decorator.

`#[query]` annotates two methods that share the name `all`, one on `Users` and one on `Orders`, and a module-level function `ping`. The decorator reads `compiler.owner(decl)` — the handle of the type that declares the annotated method, `null` at module level — and builds its registration key from the owner's name and the method's own: `Users_all`, `Orders_all`, `module_ping`. The key is the declaration's identity, with no hashing and no accidental collision between the two `all`s. Each key enters the `compiler.init` executor as a literal, and `main` prints the three registrations in declaration order, each with its SQL.

Cells in this repository that also bear on it: `modules/decisions-taken/decorator_registry_gathers_marked_declarations-665/cells/decl_member_owner`.

[draft/main.bp](draft/main.bp) · [draft/comptime/queries.bp](draft/comptime/queries.bp) · [draft/comptime/registry.bp](draft/comptime/registry.bp)
