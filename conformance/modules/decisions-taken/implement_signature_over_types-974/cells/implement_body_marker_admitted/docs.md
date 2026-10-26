# implement_body_marker_admitted

Decision 974 (3): a body marker stays outside the signature — a contract's `fn value(self: Self) -> Async<i32>`
is met by a member written `async fn value(self: Self) -> Async<i32>`. The program runs.
