# implement_comptime_marker_dropped

Decision 871 (3): a contract's `comptime n: i32` is not met by a member's `n: i32` — the marker is part
of the signature. Refused at the member, `implement-signature-differs`.
