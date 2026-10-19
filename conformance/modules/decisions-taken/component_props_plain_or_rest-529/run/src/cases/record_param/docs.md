# record_param

The reference text this cell shows (from `conformance/docs.md`, § A record parameter):

> `..props: R` with `R` a record type (or one derived by `Type.pick`, `Type.omit`
> or `Type.merge`, decision 307) makes `R`'s fields the function's parameters from
> outside (decision 529 (2)): a call passes them by label, a field with a default
> may be left out, and the body reads them as the record `props`. The record
> parameter sits beside other parameters, which a call passes as it always did —
> by position or by label.
>
> A spread (`Card(..p, featured: true)`) is legal only into a record parameter,
> `p` of its type or of one derived from it (decision 359's rule); the later
> supplier of a field wins, as in a record's construction.
