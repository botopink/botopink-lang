# decorator_wraps_function

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> A decorator on a function or a method may wrap it (decision 316):
> `decl.wrapWith({ call -> … })`, the wrapper a lambda written at the call. It
> receives the call value — `call.args`, the arguments as a tuple, and
> `call.run()`, which runs the original body with them — and answers the
> function's return type. Several wrappers compose in annotation order, the
> first written outermost. The function keeps its name, signature and
> annotations: every call of it, an importer's included, runs the wrapper, and
> its original body is reachable only through `call.run()`.
