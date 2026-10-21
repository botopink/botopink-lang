# union_narrowing_flow_and_case

The reference text this cell shows (from `conformance/docs.md`, § Narrowing):

> A union narrows by the flow of an `is` (decision 810 (2)): inside `if (v is A)` `v` is `A`; in its `else`, and after it when the branch leaves (`return`, `throw`, `break`, `continue`), `v` is its union without `A`, each further test removing one more. It holds for a parameter, a `val`, a loop's binder and a `var` until it is assigned. A `case` over a union is exhaustive with a type pattern per member, a generic one included (`Box<T> { b -> … }`, 810 (3)).

<!-- example: modules/decisions-taken/union_narrowing_flow_and_case-810/run/src/cases/union_narrowing_flow_and_case -->
