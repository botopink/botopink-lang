# Decision 735 — (a): an optional function-typed `comptime` argument is tested against `null` as any `?T` is — `if (rule == null) { … }` — the function type no exception.

The example's `describe` takes `rule`, an optional function known at build. It tells the call with no rule from a call with one by `rule == null`, as for any `?T`, then calls `rule!`. With `isPositive` the answer depends on the value, and with `null` it is `unchecked`. The program prints `valid`, `invalid` and `unchecked 5`.

Cells in this repository that also bear on it: none.


[cells/comptime_optional_fn_tested_against_null/src/main.bp](cells/comptime_optional_fn_tested_against_null/src/main.bp)
