# fold_split_join_lambda

The reference text this cell shows (from `conformance/docs.md`, § Lambdas and method chains):

> A lambda handed to `fold` reads its accumulator as the initial value's type:
> over a string, `{ acc, c -> acc.split(c).join("") }` chains string and array
> methods on `acc`.
