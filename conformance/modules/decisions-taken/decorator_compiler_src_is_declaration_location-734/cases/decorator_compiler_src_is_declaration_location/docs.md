# decorator_compiler_src_is_declaration_location

Decision 734 (a): `compiler.src()` in a decorator body is legal and answers the annotated
declaration's location — where the declaration starts, its annotations aside, in its file relative
to the package root. `#[located]` (`src/marks.bp`) records it as a `Declared` meta, and `main` reads
it at run time: `src/main.bp:8:1` for `Invoice` and `src/main.bp:11:1` for `render`. The handle
itself carries no location (`decl.loc` stays absent).
