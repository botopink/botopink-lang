# comptime_expand_library_names

The reference text this cell shows (from `conformance/docs.md`, § Typed meta (decision 298), The hooks a function reaches — `decl.hooks`):

> The code a function of another module emits resolves every name as in the
> module that wrote it: its types (a private one too), its functions and values
> (private ones too — the module shares its privates) and its namespace imports
> (`path` of `import {path} from "std"`) are reached under aliases no source
> writes, though the caller imports none of them. A type of the same name the
> caller holds from elsewhere is `import-name-collision` at the call: one module
> holds one type of a name.

`marquee("home")` and `marquee("news")` are expanded in `main`; the code they emit builds the library's private `Label`, calls its private `shout` and its `path.relative`, none imported by `main`, on every target.

<!-- example: modules/comptime_expand_library_names -->
