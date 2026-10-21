# Decision 871 — 800's "identical" is over types, not spellings; a member's type parameter inside `Self<…>` takes the clause's argument; a parameter's `comptime` marker is part of the signature.

The signature check of decision 800 compares types, not their spellings: `array<T>` and `T[]`, an alias and its target, `Self<U>` under a clause that gives `U` are one type, and an implementor written either way meets the contract. A parameter's `comptime` marker is part of the signature: a contract's `comptime n: i32` is not met by `n: i32`, nor the reverse, refused at the member, `implement-signature-differs`, the marker shown in both signatures.

[cells/implement_comptime_marker_dropped/src/main.bp](cells/implement_comptime_marker_dropped/src/main.bp)
[cells/implement_comptime_marker_added/src/main.bp](cells/implement_comptime_marker_added/src/main.bp)
[cells/implement_signature_spellings_met/src/main.bp](cells/implement_signature_spellings_met/src/main.bp)
