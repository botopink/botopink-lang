# Decision 771 — (a): a component instance is the value one `Page(…)` call makes; the compiler allocates one slot per `use memo` position in the body when that value is made, the first render fills it and later renders of the same value read it

The example's cell shows `use memo({ -> make })` computed once per component instance: the first render of a `Page(…)` value runs `make` and fills the slot, a later render of the same value reads it.
[cells/memo_computed_once_per_instance/src/main.bp](cells/memo_computed_once_per_instance/src/main.bp)
