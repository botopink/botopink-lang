# Decision 758 — A type travels in two forms, and both work: `comptime t: type<T>` is the function's specialisation (a copy per type argument, `t` the type inside it, known at build — 757), and `t: type<T>` without `comptime` is a run-time value — the type's identity (603), crossing to run time as `Field(Book, "pages")` does (631) — tested with `x is t` at run time by the same rules as the literal test `x is Users`.

Cells in this repository that bear on it: `modules/value_or_type_param`, `modules/typeinfo_of_value`.

[cases/type_token_handed_on_run_time/src/main.bp](cases/type_token_handed_on_run_time/src/main.bp)
[cases/type_token_run_time_value/src/main.bp](cases/type_token_run_time_value/src/main.bp)
