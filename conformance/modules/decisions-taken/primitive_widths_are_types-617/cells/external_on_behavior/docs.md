# external_on_behavior

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> A behavior is a contract (decision 617 (2), (3)): its members are signatures and `default fn` bodies, and
> host code lives on the type that implements it — `#[compiler.external(…)] declare fn toString(self: Self) ->
> string;` inside `pub type i32 implement Signed { … }`, `Self` the type. An implementation on a behavior's
> member is refused at the annotation, `external-on-behavior`.
