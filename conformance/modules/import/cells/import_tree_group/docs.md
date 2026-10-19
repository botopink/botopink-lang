# import_tree_group

The reference text this cell shows (from `conformance/docs.md`, § Imports):

> **A path and a group are one tree, and only the leaf enters scope.** An item
> may walk into a module (`shapes.circle.name`), and several items under one
> prefix may be grouped (`shapes: {circle: {name}, helpers: {seven}}`) — both
> spellings bind exactly the same names: `a: {b: {c}}` is `a.b.c`. The dot serves
> one leaf, the braces several under one prefix, and `botopink format` flattens a
> group into its dotted leaves — `collections: {Dict as D, lt}` is printed
> `collections.Dict as D, collections.lt`. What an item binds is its **leaf** — `name`,
> `seven` — never the segments before it: `import {io.fs.readText}` brings
> `readText`, neither `io` nor `fs`; whoever wants both writes both
> (`import {io, io.fs.readText}`). An intermediate node may itself be a leaf
> (`import {io.fs}` binds the module `fs` as a namespace; inside a group the
> prefix is a leaf if listed: `io: {fs, fs: {readText}}`). `*` and `as` belong
> to the leaf in either spelling — `io: {fs: {readText as read}}` is
> `io.fs.readText as read`, `collections: {ArraySets*}` activates the same
> extension as `collections.ArraySets*` — and on a node that opens braces they
> are a syntax error (`import-group-modifier`). Two items binding one name are
> `import-name-collision` at the second item (`import {url.parse, querystring.parse}`);
> an alias on either side clears it (`url.parse as parseUrl, querystring: {parse as
> parseQuery}`). One item that reaches two declarations — `import {parse} from
> "kit"` while two modules of the package `kit` declare `pub fn parse` — is not
> refused itself: every **use** of the name is, where it is written, naming both
> (`ambiguous-import-use`), and the item that names the module (`import
> {a.parse} from "kit"`) is the way out. An alias reaches a type and a type alias too (decision 110):
> `import {collections.Dict as D}` brings `D`, a name for `Dict` in the program's
> own text — the emitted code keeps `Dict`. An activation cannot be renamed
> (`import-alias-on-activation`). A leaf that names a folder is a namespace of
> its submodules (decision 110): after `import {io} from "std"`, `io.fs.readText(p)`
> calls `io/fs`'s `readText` — only the modules the program reaches are imported —
> and a module namespace reaches its types, so `import {collections} from "std"`
> allows `collections.Dict.empty()` beside `collections.lt()` (decision 111's
> constructors are type-scoped).
