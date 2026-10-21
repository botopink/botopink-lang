# val_cannot_be_assigned

The reference text this cell shows (from `conformance/docs.md`, § val — immutable binding):

> A `val` is immutable: assigning to it — a local or a module-level `val`, from
> any `fn` body — is a compile-time error. The rule is the same one node already
> enforced at run time (`const`); it now holds on every target before any code
> is emitted.
