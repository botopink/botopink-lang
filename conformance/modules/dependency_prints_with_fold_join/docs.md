# dependency_prints_with_fold_join

The reference text this cell shows (from `conformance/docs.md`, § Lambdas and method chains):

> A dependency's module holding such a function builds as the
> program's own does, so a program importing it prints the same whether or not
> it calls the function:

`strip`'s `residue` chains `split` and `join` on a `fold` accumulator; `main` imports it, calls nothing of it and prints
`hello` on every target.
