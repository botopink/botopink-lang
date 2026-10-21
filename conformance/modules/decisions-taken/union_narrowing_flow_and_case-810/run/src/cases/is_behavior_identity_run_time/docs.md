# is_behavior_identity_run_time

The reference text this cell shows (from `conformance/docs.md`, § Union types, `unknown`, and `is`):

> At run time it tests `X` alone — a record's, an enum's or a behavior's identity, as `v is X<unknown>` does —, the argument coming from `v`'s type. A behavior's identity is the value's type implementing it: `v is Shown<unknown>` holds for a value of a type written `implement Shown<T>`, on every target (decision 810 (1)).

<!-- example: modules/decisions-taken/union_narrowing_flow_and_case-810/run/src/cases/is_behavior_identity_run_time -->
