# builtin_arguments

The reference text this cell shows (from `conformance/docs.md`, § Builtins):

> | Builtin | Declaration | Held at the call by |
> |---|---|---|
> | `print` (`io/terminal.bp`, imported) | `print(..values: unknown[])` — any number of arguments (§ A variadic parameter) | the declaration |
> | `panic` (`failure.bp`, imported) | `panic(message: string = "panic") -> noreturn` | the declaration |
> | `@embed` (until 607's box removes it) | `embed(comptime path: string) -> Asset` — a `Build` builtin, computed where it is written (§ `@embed` and `Asset`) | its own rule (`embed-arguments`, `comptime-arg-not-known`, `embed-path-absolute`, `embed-path-outside-package`, `embed-file-missing`) |
> | `@TypeInfo.all` (until B-137's `compiler.find` removes it) | `all(with: Decorator \| Decorator[], member: ?string = null) -> Declared<unknown>[]` (`Declared<B>[]` when the decorators' `syntax decl: B` share the behavior `B`, decision 564), a static `declare fn` of `TypeInfo<T>` — COMPTIME-ONLY | the declaration — `Decorator` is the type of a decorator's name (decision 268), so anything else in `with:` is the ordinary mismatch at the argument —, after its own shape rule (`typeinfo-all-arguments`) |
> | `@emit` (until 605's box removes it) | `emit(source: string)` — COMPTIME-ONLY, a decorator body | the declaration |
> | `@code` (until 605's box removes it) | `code<T>(text: string)` — COMPTIME-ONLY, a template body, answering the code `text` parses | the declaration |
>
> A call the declaration refuses — more arguments than it declares, a parameter
> without a default left out, a label naming no parameter — is
> `error[builtin-arguments]` at the call, naming the declaration; an argument of
> another type is the ordinary type mismatch, at the argument.
