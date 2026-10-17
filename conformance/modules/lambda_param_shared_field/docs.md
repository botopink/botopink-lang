# lambda_param_shared_field

The reference text this cell shows (from `conformance/docs.md`, § Lambdas and method chains):

> A lambda passed for a function's parameter reads its parameters as the
> parameter's function type says: `{ p -> p.nome }` for `fn(Pessoa) -> Pessoa`
> reads `Pessoa`'s `nome` though another record declares a field of the name,
> and `Pessoa(..p, idade: 31)` spreads a `Pessoa`.
