# optional_chain_lambda_param

The reference text this cell shows (from `conformance/docs.md`, § Optionals):

> A `?.` makes the rest of its chain conditional: at the first absent link the whole
> chain is absent, and a member after the link runs only on a present value — also when
> the chain starts at a lambda's parameter typed `?T`.

The chain `h?.entry?.name ?? "none"` over a parameter `h: ?Holder` answers `a` when every
link is present and `none` at the first absent one, as it does outside the lambda, even
when another record declares a field of the same name (`Other.entry`).
