# Decision 771 — (a): a component instance is the value one `Page(…)` call makes; the compiler allocates one slot per `use memo` position in the body when that value is made, the first render fills it and later renders of the same value read it

The example's cell shows `use memo({ -> make })` as decision 816 amends it: the slot is a cell's of the render's tree, not a value's — the first render of the memo's cell runs `make` and fills it, a later render over the same root reads it, and a value made by another call stands at another place with a slot of its own.
[cells/memo_computed_once_per_instance/src/main.bp](cells/memo_computed_once_per_instance/src/main.bp)
