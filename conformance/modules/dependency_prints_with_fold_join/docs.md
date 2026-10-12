# dependency_prints_with_fold_join

A cell with a `path` dependency prints like any other, on every target, whether or not it calls the dependency: the
dependency's functions are linked whole, so a body the backend cannot lower there (`acc.split(c).join("")` inside a
`fold` lambda) must not stop `main` from running.
