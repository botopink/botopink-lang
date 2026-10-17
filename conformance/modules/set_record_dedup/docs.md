# set_record_dedup

The reference text this cell shows (from `conformance/docs.md`, § Imports, std's root modules):

> `collections` (`Dict`, `Set`, `Queue`, `Order` — a constructor is called on its type: `Dict.empty()`,
> `Dict.ofEntries([#("a", 1)])`, `Set.fromList(xs)`; a `Set` member is compared by `==`, so two
> structurally equal records are one member on every target, decision 210)

`Set.fromList` of three points, two equal, keeps two; `contains`, `insert`, `delete`, `union`, `intersection` and
`difference` compare by `==` alike.
