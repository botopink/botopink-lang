# integer_conversion_to_f64_inexact_aborts

The reference text this cell shows (from `conformance/docs.md`, § Numbers):

> Crossing between integer types, and to `f64`, is written and exact:
> `toI32()`, `toI64()`, `toU32()`, `toU64()` and `toF64()` answer the value when
> the target type holds it and abort otherwise, never wrap, saturate or round
> (`toI32: 2147483648 does not fit i32`, `toF64: 9007199254740993 has no exact
> f64`). `@print` and string interpolation write an integer's digits, whatever
> its size.
