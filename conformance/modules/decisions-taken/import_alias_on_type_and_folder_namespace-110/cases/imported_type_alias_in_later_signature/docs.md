# imported_type_alias_in_later_signature

The reference text this cell shows (from `conformance/docs.md`, § Imports):

> The alias names the type in the whole module: a function declared after the one that calls it
> takes the alias in its signature (`fn hostOf(u: U)` below `main`, after `import {url.Url as U} from "std"`):
