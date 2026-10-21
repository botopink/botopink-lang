# implement_comptime_marker_added

Decision 871 (3): a contract's `n: i32` is not met by a member's `comptime n: i32` — the
marker is part of the signature either way. Refused at the member, `implement-signature-differs`.
