# optional_chain_lambda_array_method

The reference text this cell shows (from `conformance/docs.md`, § Optionals):

> A `?.` makes the rest of its chain conditional: at the first absent link the whole
> chain is absent, and a member after the link runs only on a present value — also when
> the chain starts at a lambda's parameter typed `?T`.

An untyped lambda `{ a -> a?.length() ?? 0 }` handed to a parameter typed `fn(h: ?Holder[]) -> i32` answers the
array's length when it is present and `0` when it is absent, as the typed `fn(h: ?Holder[]) -> i32 { … }` form does.
