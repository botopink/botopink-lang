# mod_namespace_reexport

The reference text this cell shows (from `conformance/docs.md`, § Modules):

> **`mod` binds the module it declares** (decision 337). In the module that
> declares it, `mod config;` (or `pub mod config;`) binds `config` as a namespace,
> as `import {config};` binds it elsewhere — `config.splitPath(x)`, a type
> `config.Pair` in a signature, a constructor `config.Pair(…)`, a variant path,
> a function as a value, with no import. The namespace walks a folder module's
> tree: with `src/text/mod.bp` declaring `pub mod split;`, `mod text;` alone
> reaches `text.split.splitPath(x)` — each step a `pub mod` and the leaf `pub`; a
> plain `mod split;` is private to `text`'s subtree, and `text.split` from outside
> it is `private-module` at `split`. A sibling or nested module reaches `config`
> only by import (`import {config};`, `import {text.split};`). There is no
> combined form and no re-export syntax: a folder's `mod.bp` exposes a
> submodule's declaration with a value or a type of the same name — `pub val
> splitPath = split.splitPath;`, `pub type Pair = split.Pair;` — which is that
> declaration, not a second one, so the name has one public path
> (`text.splitPath`) and the submodule can stay private.
