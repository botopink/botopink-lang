# component_run_root

Decision 388 (2), (4) as 908 states it: a child is resolved inside the body whose cell holds its contexts — by `use c`, or by hand, `resolve(c, scope, Place.none())` in a `{ scope -> … }` lambda (819 (3), 888). Outside every body the root runs with `run(c)` (822, 825).

[src/main.bp](src/main.bp)
