# template_lookup_meta

The reference text this cell shows (from `conformance/docs.md`, § Functions expanded at their call):

> On the handle, `compiler.meta(decl, T)` (`?T`) and `compiler.metaAll(decl, T)` (`T[]`) answer at
> build what the declaration's decorators recorded, when the record `T` is data —
> each field a string, a number, a `bool`, a variant, an array or an optional of
> those; a field the value left out reads its default. A record with a field that holds code — a function filled from a
> `syntax` (576 (12)), no data — has its read refused, naming the field
> (`template-lookup-meta-expr-field`); `compiler.typeInfo(X).meta(T)` in a template body
> stays `typeinfo-meta-at-build`.
