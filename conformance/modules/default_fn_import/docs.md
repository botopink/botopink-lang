# default_fn_import

The reference text this cell shows (from `conformance/docs.md`, § A module's default function):

> A module may have one **default function**, which its importer names
> (decision 289). `pub default fn (…) -> R { … }` binds no name in its own
> module; `pub default <name>;` makes a function the module declares its default
> (it keeps its name there, e.g. for a recursive call); `pub default fn
> Name(…)` is the shorthand of both. `import {m.card};` — whose path names the
> module, not an item of it — binds the default under the path's last segment,
> `import {m.card as Card};` under the alias. A decorator on an anonymous
> default reads the file's name as `decl.name`. A second default is
> `default-twice`; `pub default nope;` naming no function is `default-unknown`.
