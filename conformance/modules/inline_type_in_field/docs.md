# inline_type_in_field

The reference text this cell shows (from `conformance/docs.md`, § An inline parameter type):

> parameter itself. One parameter of a function may have an inline type, and none
> of its fields is named like another parameter. It is a top-level `fn`'s only — a
> return, a field, a `val` annotation and a method's parameter refuse it — and it
> is not exported: a call from another module that writes its fields is refused.
> A diagnostic names it by its owner: ``the props of `link` ``. An inline type written anywhere but a parameter's type is `inline-type-outside-parameter`, refused at the type.
