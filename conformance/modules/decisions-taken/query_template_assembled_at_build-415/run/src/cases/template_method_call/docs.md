# template_method_call

The reference text this cell shows (from `conformance/docs.md`, § Functions expanded at their call):

> **A template method** (decisions 311 (3), 397 (3), 415 (1)). A template whose
> first parameter is `syntax self: R` and whose second is
> `syntax q: string` is called on a value, `` value.method @`…` ``, as
> `` f @`…` `` is. The receiver is the call site's code,
> its type checked against `R` as an argument's is (a behavior accepts a type
> that implements it); `self.text()` is the receiver as written, so the code the
> template builds runs on the receiver where the call stands. The literal is
> captured as at any call. The template method is a name of the call site's
> scope, declared there or imported; a method of the receiver's own type of that
> name is the type's.
