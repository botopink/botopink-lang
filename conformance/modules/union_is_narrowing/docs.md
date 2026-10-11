# union_is_narrowing

The reference text this cell shows (from `conformance/docs.md`, § Union types, `unknown`, and `is`):

> A union type is written `A | B`. `unknown` holds any value and, unlike a union,
> cannot be used as another type until it has been tested — `val b: i32 = a;` on an
> `unknown` reports "an `unknown` value cannot be used as another type without
> testing it". `x is <Type>` answers a `bool` and narrows `x` inside the branch it
> guards.
