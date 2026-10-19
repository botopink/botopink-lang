# Decision 734 — (a): `compiler.src()` in a decorator body is legal and answers the annotated declaration's location (718, 575 (3)); 403 survives as "no route from a file's location".

Inside a decorator's body `compiler.src()` is legal, and it answers the annotated declaration's location — not the
decorator's own line. `#[located]`, in [cells/decorator_compiler_src_is_declaration_location/src/marks.bp](cells/decorator_compiler_src_is_declaration_location/src/marks.bp), records that location as
a `Declared` meta, and `main` reads it at run time: `src/main.bp:7:1` for `Invoice` and `src/main.bp:10:1` for
`render`, the file relative to the package root and the column 1-based, as diagnostics print it. A decorator's output
may carry a location this way — a diagnostic, a snapshot, a meta — while nothing of a file's place names a page: a
route still reaches `#[page]` as an argument. The handle itself has no `decl.loc`; the location is `compiler`'s member.

[cells/decorator_compiler_src_is_declaration_location/src/main.bp](cells/decorator_compiler_src_is_declaration_location/src/main.bp)
