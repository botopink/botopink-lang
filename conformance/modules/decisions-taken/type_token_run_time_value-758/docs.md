# Decision 758 — A type travels in two forms, and both work: `comptime t: type<T>` is the function's specialisation (a copy per type argument, `t` the type inside it, known at build — 757), and `t: type<T>` without `comptime` is a run-time value — the type's identity (603), crossing to run time as `Field(Book, "pages")` does (631) — tested with `x is t` at run time by the same rules as the literal test `x is Users`.

The example passes the type as a run-time value: `t: type<T>`, with no `comptime`. `Registry.count` is one function, compiled once, and `x is t` is decided at run time by a runtime helper over the value's tag and the token. The rules are those of the literal test `x is Users`: records, enums and behaviors by identity, primitives as each target decides them. `T` is still bound by the parameter at build, so `first`'s `-> ?T` stays typed, and `r.first(Users)?.id` reads a field of `Users`.

`summary` hands `t` on to `count` as any value. Passing a type is all a caller does: `r.count(Users)`, `r.count(Status)`. The `comptime t: type<T>` form (667) specialises a copy per type, and it stays the form of every build read (`compiler.typeInfo(t)`). `v is T` with a bare type parameter stays refused, `is-type-parameter`, and its message names both ways out.

The program prints `2`, `1 of Orders`, `1` and `1`.

Cells in this repository that bear on it: `modules/decisions-taken/comptime_param_value_or_type-297/run/src/cases/value_or_type_param`, `modules/decisions-taken/no_declaration_files_compiler_value-575/cases/typeinfo_of_value`.


[cases/is_type_parameter_refused/src/main.bp](cases/is_type_parameter_refused/src/main.bp)
[run/src/cases/type_token_handed_on_run_time/mod.bp](run/src/cases/type_token_handed_on_run_time/mod.bp)
[run/src/cases/type_token_run_time_value/mod.bp](run/src/cases/type_token_run_time_value/mod.bp)
[run/src/cases/type_token_imported_type/mod.bp](run/src/cases/type_token_imported_type/mod.bp)
[run/src/cases/type_token_method_call/mod.bp](run/src/cases/type_token_method_call/mod.bp)
