# opaque_type_through_methods

The reference text this cell shows (from `conformance/docs.md`, § `opaque` types):

> `opaque`, written before `type` (`[pub] opaque type X(…) { … }`, as `component` is
> before `fn`), closes a record to everything outside its own methods (decisions 811,
> 814): `X(…)` is written only inside `X`'s methods, and a field is read only there —
> not elsewhere in `X`'s module either; outside, an `X` is named, passed, stored,
> compared with `==` and tested with `is`, never built nor opened. A method written
> without `pub` is called anywhere in `X`'s module, as every declaration without `pub`
> is, and from no other — the compiler's own lowering reaches one from any module,
> under a name no source spells. A method may share a field's name: outside,
> `t.value()` is the method.
