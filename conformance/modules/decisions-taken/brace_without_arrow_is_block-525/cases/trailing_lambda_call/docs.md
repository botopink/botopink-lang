# trailing_lambda_call

The reference text this cell shows (from `conformance/docs.md`, § Blocks):

> A trailing lambda is the call's last argument: it fills the parameter after the written arguments, of
> a method or of a plain function, with parameters (`f(3) { n -> n * 3 }`) or with none (`b.run { -> 10 }`,
> `twice { -> 4 }`), and the parameter is checked and bound as any lambda argument's is:
