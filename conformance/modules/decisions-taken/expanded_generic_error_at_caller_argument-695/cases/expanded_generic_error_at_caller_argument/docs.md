# expanded_generic_error_at_caller_argument

Decision 695: a caller's argument that breaks an expanded generic body (562) is refused at the caller's argument — the
argument's copy stays the caller's node. `loud.shout` takes one `comptime` parameter, so each call is expanded where it
is written, and its body calls `toUpper` on the argument itself. `shout("hi")` expands cleanly; `shout(7)` makes `T` an
`i32`, which has no `toUpper`, and the refusal is located at the `7` in `main.bp` — it used to be located inside
`loud.bp`, with the call as its `called from` line. A fault in the body's own code (`var count = value;
count.toUpper()`) stays located in the body: `modules/comptime_expand_library_type_error`.
