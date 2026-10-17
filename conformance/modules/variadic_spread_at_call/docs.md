# variadic_spread_at_call

The reference text this cell shows (from `conformance/docs.md`, § A variadic parameter):

> `..name: T[]` as a function's **last** parameter takes zero or more positional
> arguments after the fixed ones, each checked against `T`, and the body reads
> `name` as a `T[]` (decision 267). It holds for a free `fn`, a method, an
> associated function and a `declare fn` alike — `@print`, `@println` and `@debug`
> are declared `(..values: unknown[])`. A function has at most one, it is the last
> parameter, its type is written `T[]` and it takes no default
> (`variadic-not-last`, `variadic-twice`, `variadic-not-array`,
> `variadic-default`, at the declaration). Its arguments are positional: a label
> on one is `variadic-label`, and there is no spread at a call — a function that
> takes an existing array declares `values: T[]`, not `..values`:
