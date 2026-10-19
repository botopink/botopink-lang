# tag_decl_meta_read

The reference text this cell shows (from `conformance/docs.md`, § A tag is a `@Decl` (decision 302)):

> In the annotation, `compiler.attr(decl, name)` is a static attribute as written (`null`
> when the tag has none, and on every declaration) and `compiler.component(decl)` the
> component's own handle (`null` on an element). The template body reads the
> meta back by type, `compiler.meta<T>(d)` (`?T`).
