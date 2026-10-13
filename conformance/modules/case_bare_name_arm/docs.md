# case_bare_name_arm

The reference text this cell shows (from `conformance/docs.md`, § Case (pattern matching)):

> A name alone is not a pattern: to give the matched value a name, bind it in the
> body (`_ { n -> … }`). The one exception is the optional, below, where the name
> after the `null` arm *is* the pattern. `n { … }` is `case-bare-name-arm`, the
> label under it naming the binder to write:
