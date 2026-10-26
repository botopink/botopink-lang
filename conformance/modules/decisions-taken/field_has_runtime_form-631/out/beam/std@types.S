{module, std@types}.
{exports, []}.
{attributes, []}.
{labels, 2}.
%%% std's `Type` (decisions 307, 308) — the derived types: a compile-time
%%% function answers a NEW record type, bound by a module-level `val` and
%%% named after it (`pub val RecipePatch = Type.partial(Recipe);`), nominal,
%%% usable in every type position, exported and imported like any type, and
%%% annotatable (`#[validated] pub val RecipePatch = Type.partial(Recipe);`);
%%% the source fields' markers come with them. A plain alias
%%% (`type Id = i32`) stays transparent.
%%% 
%%% Every function here runs only at compile time and takes every parameter
%%% `comptime x: T`, so a call needs no `comptime`
%%% keyword. The bodies are the
%%% compiler's: bodyless, without `#[compiler.external(.<Target>)]`, because no target
%%% runs them — the compiler answers `partial`, `required`, `pick`, `omit` and
%%% `merge` with the record declaration they derive, keyed on this `Type`
%%% (`comptime/derived_types.zig`).
%%% 
%%% `Type` is a namespace type (decision 329): no field list, no value, every
%%% function associated. `Field<T>` is declared in its body, so it is its
%%% associated type `Type.Field<T>` (decision 330 (7)). `pick` and `omit`
%%% take the fields as a variadic (`comptime ..fields: Type.Field<T>[]`,
%%% decision 267): `Type.pick(Recipe, .title, .servings)`.
