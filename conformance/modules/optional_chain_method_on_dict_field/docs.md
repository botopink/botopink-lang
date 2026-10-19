# optional_chain_method_on_dict_field

The reference text this cell shows (from `conformance/docs.md`, § Optionals):

> A link that continues a `?.` chain runs under the chain's guard, and its method is the payload's: `post?.params.at(k)`
> is the `Dict`'s `at` on every target, `null` when `post` is.
