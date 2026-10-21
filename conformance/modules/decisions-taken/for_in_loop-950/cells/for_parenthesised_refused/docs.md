# for_parenthesised_refused

The reference text this cell shows (from `conformance/docs.md`, § Loops):

> The collection loop names its item before `in` (decision 950): `for x in xs { … }`, `for await x in s { … }`,
> the body a block — a loop body, never a lambda. 105's parenthesised `for (xs) { x -> … }` and
> `for await (s) { x -> … }` are `for-parenthesised`, refused at the `(` naming the new form; `botopink format`
> rewrites them.
