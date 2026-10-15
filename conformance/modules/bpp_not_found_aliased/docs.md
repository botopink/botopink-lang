# bpp_not_found_aliased

The reference text this cell shows (from `conformance/docs.md`, § A `.bpp` file):

> A file whose name is no identifier is declared
> and imported by it between backticks (decision 561, § Bindings): `` pub mod
> `not-found`; `` resolves `not-found.bpp`, `` import {pages.`not-found` as
> NotFound}; `` binds its default function as `NotFound`, and without an alias
> (`` import {pages.`not-found`}; ``) the bound name is `` `not-found` `` — an
> alias is optional.
