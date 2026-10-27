# Decision 899 — On commonJS a call into a bodied, non-host generic fn of another module hands it the print shape of each type parameter, judged by the callee's declared signature alone; settles B-115 box 2 under 673.

A bodied generic function of another module, or of a dependency, that writes its `T` as text answers the same on
every target: `lib.show(2.0)` writes `2.0` and `lib.show(2)` writes `2`. On commonJS the caller reads the callee's
declared signature from the export info (generic, bodied, no host binding) and hands it one trailing print shape per
type parameter, at a call of the exact arity; the answer depends on the signature alone, never on the callee's body,
so a cached dependant stays sound (509 (2)). The `.d.ts`, the `T` values and the other targets are unchanged.

[cases/generic_fn_of_other_module_takes_shape/src/main.bp](cases/generic_fn_of_other_module_takes_shape/src/main.bp)
[cells/generic_fn_of_dependency_takes_shape/src/main.bp](cells/generic_fn_of_dependency_takes_shape/src/main.bp)
