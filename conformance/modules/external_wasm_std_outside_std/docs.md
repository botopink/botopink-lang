# external_wasm_std_outside_std

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> **A `std:` cell is std's alone** (decision 445). std-wasm's export names are
> internal to std, and std's botopink API is the public contract: a `std:` cell
> written anywhere outside `libs/std` is refused at the annotation, on every
> target, naming the std function to call instead. std's own `hash.contentHash`
> carries one; the same declaration in a program is refused:
