# init_output_outside_decorator

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> A `compiler.*` call inside the executor is evaluated at build and enters the
> executor as a literal, exactly as a `val` read before it does (decision 614):
> `compiler.init({ -> register(compiler.name(decl)) })` and `val name =
> compiler.name(decl); compiler.init({ -> register(name) })` compile to the same
> init statement. So does a call inside a member or a wrapper (decision 642). A
> `syntax` argument of the call is taken as written, so `compiler.name(x)` over a
> parameter `x` of a lambda in the tree is `"x"`; a `comptime` argument of the call
> (`typeInfo(comptime t)`) that is a run-time value of the tree — a parameter of a
> lambda in it, a value it binds — is `compiler-arg-at-run-time`, at the argument,
> naming the parameter and the value. `compiler.init` in a function that is no
> decorator is `compiler-output-outside-decorator`, at the member.
