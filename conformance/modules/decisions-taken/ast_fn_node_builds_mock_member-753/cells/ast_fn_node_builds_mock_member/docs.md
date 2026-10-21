> Decision 753 — `Fn(params, ret, body)` is a typed function, `fn(a: A) -> R
> { … }`: each parameter an `FnParam(name, annotation)`, its annotation and
> `ret` type nodes — one record per kind of the parser's type grammar —, its
> body the statements in order, `Return(result)` among them. `Lambda` stays the
> untyped one.
