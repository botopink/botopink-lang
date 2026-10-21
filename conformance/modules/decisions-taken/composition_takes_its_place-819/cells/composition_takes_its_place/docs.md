# composition_takes_its_place

Decision 819: `fn(scope: Scope, key: Place) -> T | Async<T>`; the place is the call's number and the
item's, or a key in the item's stead. Two written calls never share a cell (`Painel` never reads
`Login`'s); a keyed list called by hand, `Item(n)(scope, Place.key(n))`, keeps each item's memo when
reordered; a repeated key among siblings fails naming it, `key-duplicate` (819 (5)).

[src/main.bp](src/main.bp)
