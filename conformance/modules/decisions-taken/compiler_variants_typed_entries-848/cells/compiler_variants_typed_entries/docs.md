# compiler_variants_typed_entries

The reference text this cell shows (from `conformance/docs.md`, § Functions expanded at their call):

> `compiler.variants(d)` answers `compiler.Variant[]`, one entry per constructible variant:
> `name`, the payload `fields` (empty for a unit variant), the variant's own
> `annotations` and its `section` — the enclosing sections' names joined by `.`,
> `null` at the top level. A section is no entry, but its wrapper constructor is.
