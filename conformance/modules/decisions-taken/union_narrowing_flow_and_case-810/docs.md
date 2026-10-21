# Decision 810 — A type test may name a type parameter bound by the tested value's own type; a union narrows by the flow of an `is` and by an exhaustive `case` with type patterns, both in force; std's `resolve<T>` is ordinary botopink; amends 25's reading of `is`, 8 §5.2, 667's `is-type-parameter`.

A union narrows by the flow of an `is` (810 (2)): past `if (s is Dot) return 0;` `s` is the union
without `Dot`, each further test removing one more, in the `else` too, for a parameter, a `val`, a
loop's binder and a `var` until it is assigned (`union_narrowing_flow_and_case`), and a field read on the narrowed value answers the field (`union_narrowed_field_read`); a member forgotten is
refused where the rest is used (`union_narrowing_forgotten_member_use`). `v is Box<T>` is accepted where
`Box<T>` is a member of `v`'s type (810 (1)), and a `case` covers a union with a type pattern per
member, a generic one included, `Box<T> { b -> … }` (810 (3)); a member left out is refused at the
`case`, named (`union_case_forgotten_member`). A parameter nothing binds stays `is-type-parameter`
(`is_unbound_type_argument`). At run time `is` tests a type's identity alone — a record's, a
behavior's (the value's type implements it), a function type's arity — on every target, and so does a
behavior type pattern (`is_behavior_identity_run_time`). Std's `resolve` (810 (5)) is 809 (6)'s.

[run/src/cases/union_narrowing_flow_and_case/mod.bp](run/src/cases/union_narrowing_flow_and_case/mod.bp)
[run/src/cases/union_narrowed_field_read/mod.bp](run/src/cases/union_narrowed_field_read/mod.bp)
[run/src/cases/is_behavior_identity_run_time/mod.bp](run/src/cases/is_behavior_identity_run_time/mod.bp)
[refused/src/cases/union_narrowing_forgotten_member_use/mod.bp](refused/src/cases/union_narrowing_forgotten_member_use/mod.bp)
[refused/src/cases/union_case_forgotten_member/mod.bp](refused/src/cases/union_case_forgotten_member/mod.bp)
[refused/src/cases/is_unbound_type_argument/mod.bp](refused/src/cases/is_unbound_type_argument/mod.bp)
