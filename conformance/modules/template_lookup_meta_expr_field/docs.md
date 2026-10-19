# template_lookup_meta_expr_field

The reference text this cell shows (from `conformance/docs.md`, § Functions expanded at their call):

> On the handle, `decl.meta(T)` (`?T`) and `decl.metaAll(T)` (`T[]`) answer at
> build what the declaration's decorators recorded, when the record `T` is data —
> each field a string, a number, a `bool`, a variant, an array or an optional of
> those; a field the value left out reads its default. A record with an `@Expr`
> field holds code the program runs, and its read is refused, naming the field
> (`template-lookup-meta-expr-field`); `@typeInfo(X).meta(T)` in a template body
> stays `typeinfo-meta-at-build`.
