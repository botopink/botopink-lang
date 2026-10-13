# decorator_imported_builds_private_record

A decorator's body runs in its own module wherever it annotates: an imported
decorator may build a record private to that module.

`#[entity("cities")]` from `orm`, whose body builds `orm`'s private `Note` — `cities`, typed and by key.
