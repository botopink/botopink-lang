# Decision 974 — 800's "identical" is over types, not spellings; a member's type parameter inside `Self<…>` takes the clause's argument and the member's own type parameter is not counted; a parameter's `comptime` marker is part of the signature and a body marker is not; restates 871 with 883 (4) folded in, replacing it.

The signature check of decision 800 compares types, not their spellings: `array<T>` and `T[]`, an alias and its target, `Self<U>` under a clause that gives `U` are one type, and an implementor written either way meets the contract. A parameter's `comptime` marker is part of the signature: a contract's `comptime n: i32` is not met by `n: i32`, nor the reverse, refused at the member, `implement-signature-differs`, the marker shown in both signatures. A body marker (`component`, `async`, `iter`) is not: a contract's `fn value(self: Self) -> Async<i32>` is met by `async fn value`.

[cells/implement_comptime_marker_dropped/src/main.bp](cells/implement_comptime_marker_dropped/src/main.bp)
[cells/implement_comptime_marker_added/src/main.bp](cells/implement_comptime_marker_added/src/main.bp)
[cells/implement_signature_spellings_met/src/main.bp](cells/implement_signature_spellings_met/src/main.bp)
[cases/implement_body_marker_admitted/src/main.bp](cases/implement_body_marker_admitted/src/main.bp)
