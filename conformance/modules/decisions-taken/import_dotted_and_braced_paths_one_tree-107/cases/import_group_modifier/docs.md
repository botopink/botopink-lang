# import_group_modifier

The reference text this cell shows (from `conformance/docs.md`, § Imports):

> prefix is a leaf if listed: `io: {fs, fs: {readText}}`). `*` and `as` belong
> to the leaf in either spelling — `io: {fs: {readText as read}}` is
> `io.fs.readText as read`, `collections: {ArraySets*}` activates the same
> extension as `collections.ArraySets*` — and on a node that opens braces they
> are a syntax error (`import-group-modifier`). Two items binding one name are
