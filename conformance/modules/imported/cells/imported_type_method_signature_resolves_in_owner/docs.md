# imported_type_method_signature_resolves_in_owner

A method of an imported type is typed by its signature as the type's own module reads it: the names its
parameters and its return name resolve in that module, whether or not the importer imports them — as a
type's fields do (`imported_type_field_closure`). `main` calls `Shop`'s `tag` and `missing`, whose `Tag` and
`Missing` only `shop` imports, on a `Shop` it names and on one `corner()` answers.
