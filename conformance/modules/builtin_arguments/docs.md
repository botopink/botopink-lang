# builtin_arguments

The reference text this cell shows (from `conformance/docs.md`, § Builtins):

> | Builtin | Declaration | Held at the call by |
> |---|---|---|
> | `print` / `print` / `print` | `print(..values: unknown[])` (each alike) — any number of arguments (§ A variadic parameter) | the declaration |
> | `panic` | `panic(message: string = "panic") -> noreturn` | the declaration |
> | `@todo` | `todo(message: string = "not implemented") -> noreturn` | the declaration |
> | `@trap` | `trap() -> noreturn` | the declaration |
> | `@module` | `module() -> module` | refused at every call (`builtin-not-lowered`) |
> | `@field` | `field<T, F>(obj: T, comptime name: @Expr<string>) -> F` — COMPTIME-ONLY name | the declaration |
> | `@src` | `src() -> SourceLocation` — COMPTIME-ONLY (§ `@src()` and `SourceLocation`) | its own rule (`src-takes-no-arguments`) |
> | `@typeInfo` | `typeInfo<T>(comptime _: @Expr<type>) -> TypeInfo<T>` — COMPTIME-ONLY (§ Decorators) | its own rule (`typeinfo-unknown-declaration`, `typeinfo-unknown-member`) |
> | `@TypeInfo.all` | `all(with: Decorator \| Decorator[], member: ?string = null) -> Declared<unknown>[]`, a static `declare fn` of `TypeInfo<T>` — COMPTIME-ONLY | the declaration — `Decorator` is the type of a decorator's name (decision 268), so anything else in `with:` is the ordinary mismatch at the argument —, after its own shape rule (`typeinfo-all-arguments`) |
> | `@TypeOf` | `TypeOf<T>(value: T) -> T` — COMPTIME-ONLY | the declaration |
> | `@makeRecord` | `makeRecord<R>(fields: RecordField[]) -> R` — COMPTIME-ONLY | the declaration |
> | `@RecordKeys` | `RecordKeys(comptime _: @Expr<type>) -> string[]` — COMPTIME-ONLY | the declaration |
> | `@comptimeError` | `comptimeError(comptime message: @Expr<string>) -> noreturn` — COMPTIME-ONLY | its own rule (the message it raises) |
> | `@emit` | `emit(source: string)` — COMPTIME-ONLY, a decorator body | the declaration |
> | `@compilerError` | `compilerError(message: string) -> noreturn` — COMPTIME-ONLY, a decorator or template body | the declaration |
> | `@expr` / `@code` | `expr<T>(comptime value: @Expr<T>) -> Expr<T>`, `code<T>(text: string) -> Expr<T>` — COMPTIME-ONLY, a template body | the declaration |
>
> A call the declaration refuses — more arguments than it declares, a parameter
> without a default left out, a label naming no parameter — is
> `error[builtin-arguments]` at the call, naming the declaration; an argument of
> another type is the ordinary type mismatch, at the argument.
