# opaque_pattern

The reference text this cell shows (from `conformance/docs.md`, § `opaque` types):

> `X(…)` written outside `X`'s methods is `opaque-construction`, at the call, naming
> the `pub` methods that make one; a field read there, or a pattern of the fields
> (`case t { X(f: v) -> … }`), is `opaque-field`; a method without `pub` called from
> another module is `method-not-pub`, at the call, as any type's is (§ Methods without `pub`).
