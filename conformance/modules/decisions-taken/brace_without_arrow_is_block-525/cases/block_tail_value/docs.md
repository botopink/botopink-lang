# block_tail_value

The reference text this cell shows (from `conformance/docs.md`, § Blocks):

> A `{` followed by parameters and `->` (or `->` alone) is a lambda; a `{` without `->` is a
> **block** — a scope of the enclosing function, never a closure (decision 525). A block used as a
> value answers its last expression written without `;` (decision 409), as a function and a lambda
> do; a braced `if` / `case` at its end is that expression too:
