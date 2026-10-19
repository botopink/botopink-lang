# Decision 609 — (a): `Result<R, E>` is declared once, in `primitives.bp` (606 (1)), with its five methods as `case` bodies over `Ok` / `Error` (575 (7)); the checker binds the type form to that declaration; every backend keeps 118's value shape for this one enum.

[cells/result_wide_payloads/src/main.bp](cells/result_wide_payloads/src/main.bp)
