# Decision 413 — For now, a member function reads only the decorator's parameters, its own locals and `@typeInfo(T)` — never a local of the decorator's body nor the `@Decl` handle.

The decision limited what a member a decorator adds may read; the rule in force is the one that replaced it (642,
716 (3)), and the example shows that reading. The member `describe`, added by `#[describe("record")]` in
[draft/comptime/describe.bp](draft/comptime/describe.bp), reads the decorator's `comptime` parameter `prefix` and the
body's literal local `sep`, both spliced into the member as literals; it calls `compiler.name(decl)`, evaluated at build
and spliced as `"City"`; and it reads the type's reflection in its own body, under `comptime`, through the decorator's
type parameter `T`, which names the annotated type. The program prints `record: City with 2 fields`. A local whose
value is no literal — a record, a handle — read inside the member stays refused (759).

Cells that also bear on it: `modules/decisions-taken/no_declaration_files_compiler_value-575/run/src/cases/decorator_member_captures`.

[draft/main.bp](draft/main.bp)
