# import_qualified_type_alias_beside_std_name

Decision 107: a dotted item names the module its prefix spells, and only the leaf enters scope.
`import {plugin.Json};` names `plugin` of this package, so the `pub` `Json` that std's `compiler`
and `json` each declare is never a candidate for it — even when `plugin`'s `Json` is a type alias,
which the backends never see.
