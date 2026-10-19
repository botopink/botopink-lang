# Decision 695 — A caller's argument that breaks an expanded generic body (562) is refused at the caller's argument — the argument's copy stays the caller's node.

The example is refused. `loud.shout` takes one `comptime` parameter, so each call is expanded where it is written, and its generic body calls `toUpper` on the argument. `shout("hi")` expands cleanly. `shout(7)` makes `T` an `i32`, and `i32` has no `toUpper`. The value at fault is the caller's `7`, so the refusal is located at that argument in `main.bp`, not inside `loud.bp`.

Cells in this repository that also bear on it: `modules/decisions-taken/comptime_parameter_call_expanded-562/cases/comptime_expand_library_type_error` (the fault in the library's own code, located there).

[draft/main.bp](draft/main.bp)
[draft/loud.bp](draft/loud.bp)
