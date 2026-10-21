# lambda_arg_generic_param_method

The reference text this cell shows (from `conformance/docs.md`, § Lambdas and method chains):

> A lambda passed where a parameter receives it is typed by that parameter,
> a type parameter of the callee included: `{ req, chain -> chain.next(req) }`
> handed to `register<Rq, Ch>(…, entry: fn(req: Rq, chain: Ch) -> string)` is
> not refused.
