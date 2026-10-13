# lambda_last_statement_semicolon

The reference text this cell shows (from `conformance/docs.md`, § Lambdas and method chains):

> A braced lambda's and an untyped `fn(x) { … }`'s last expression written with `;` is still its
> value (`{ x -> x + 1; }`, `fn(x) { x * 2; }`); a typed function expression with `-> R` refuses it
> as above:
