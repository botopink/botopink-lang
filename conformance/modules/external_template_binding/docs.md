# external_template_binding

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> A declaration takes the signature a `fn` does — generic parameters, `comptime`
> parameters, any return type — with or without an annotation. A parameter it
> has no name for is written `_` (`declare fn typeInfo<T>(comptime _: @Expr<type>) ->
> TypeInfo<T>;`); `_` is a bodyless declaration's placeholder, and a
> function with a body refuses it (`discard-param-with-body`).
>
> A binding may also be a template, where `$0`, `$1`, … are the declared
> parameters — on a method, `self` is `$0`:
