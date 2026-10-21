# tag_decl_meta

The reference text this cell shows (from `conformance/docs.md`, § A tag is a `@Decl` (decision 302)):

> A template function hands each annotated tag of its text to the annotation as
> a declaration handle — the same function shape as a declaration's decorator, named by no
> library. `compiler.tagDecl(kind, name, attrs)` builds the tag's handle; `compiler.annotate(decl,
> at)` runs the annotation written at the span `at` of the text over it. Typed
> meta is the one channel: the template body reads it back by type, `compiler.meta(d, T)`
> and `compiler.metaAll(d, T)`, so one annotation function serves a tag and a declaration
> alike.
