# integer_literal_never_fits_f64

The reference text this cell shows (from `conformance/docs.md`, § Numeric literals):

> A literal never changes type to fit: an integer literal where a float is
> expected is an error, and so is `1.5` where an `f32` is — write `1d` or `1.0`,
> and `1.5f`. `f` and `d` go on decimal literals only (in `0x…` they are hex
> digits); a radix literal takes an integer suffix (`0xFFul`). An uppercase
> suffix (`42L`), letters that are no suffix (`10px`) and an exponent without
> digits (`1e`) are refused at the suffix. A number pattern matches a subject of
> its own type. `n` makes an integer literal a `bigint` of any size (§ Numbers);
> it takes no fraction or exponent (`1.5n` is refused at the suffix).
