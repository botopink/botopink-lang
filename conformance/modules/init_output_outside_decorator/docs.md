# init_output_outside_decorator

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> A `compiler.*` call inside the executor is evaluated at build and enters the
> executor as a literal, exactly as a `val` read before it does (decision 614):
> `compiler.init({ -> register(compiler.name(decl)) })` and `val name =
> compiler.name(decl); compiler.init({ -> register(name) })` compile to the same
> init statement. A `compiler.*` argument that is a run-time value of the
> executor — a parameter of a lambda in it, a value it binds — is
> `compiler-arg-at-run-time`, at the argument, naming the value. `compiler.init`
> in a function that is no decorator is `compiler-output-outside-decorator`, at
> the member.
