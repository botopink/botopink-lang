# Decision 667 — `v is T` with `T` a type parameter is refused; a type to test against travels as a `comptime t: type<T>` parameter, and `v is t` is the concrete type's test in the function specialised for it.

The example writes the same search twice. `firstOf<T>` tests `x is T` with `T` a type parameter. Type parameters are erased at run time, so no target can decide that test, and it is refused at `x is T`, located, `is-type-parameter`. The message names the parameter and the forms that work.

`Registry.get` is the first of those forms, Java's class token: the type travels as a parameter, `comptime t: type<T>`, and the body tests `e is t`. The call `r.get(Users)` binds `T` from `t`, so the type is never written twice. Because `t` is `comptime`, the function is specialised for it: in the copy `get(Users)` compiles to, `e is t` is `e is Users`, an ordinary run-time test that gives one answer on every target. The other form is the run-time token, `t: type<T>` without `comptime` (758). A comparison by name, such as `compiler.name(t)`, is never the language's answer.

The program is refused at `firstOf`; without it, `main` would print `1` and `0`.

Cells in this repository that bear on it: `modules/decisions-taken/comptime_param_value_or_type-297/cases/is_type_outside_value_or_type`, `modules/decisions-taken/no_declaration_files_compiler_value-575/cases/type_param_generic_form`.

[draft/main.bp](draft/main.bp)
