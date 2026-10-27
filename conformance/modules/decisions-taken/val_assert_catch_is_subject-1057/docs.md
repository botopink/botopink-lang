# Decision 1057 — The value after `catch` in a `val assert` stands for the subject: it has the subject's type or is a jump, and is matched against the pattern again; answers 1021-e (a); amends decision 8 § 9.

`val assert P = s catch X`: when `s` does not match `P`, `X` is taken as the subject and matched again, so `X` has the
subject's type or is a jump. A value of another type (`catch_wrong_type`, `assert-catch-type`) and a constructor of
another variant (`catch_other_variant`, `assert-catch-never-matches`) are refused at the value; a jump is accepted
(`catch_jump`); a substitute of the pattern's variant binds its names (`catch_substitute_matches`); a substitute that
still does not match is the handler-less form's fatal failure on every target (`catch_substitute_fails`).

[cases/catch_wrong_type/src/main.bp](cases/catch_wrong_type/src/main.bp)
[cases/catch_other_variant/src/main.bp](cases/catch_other_variant/src/main.bp)
[cases/catch_jump/src/main.bp](cases/catch_jump/src/main.bp)
[cases/catch_substitute_matches/src/main.bp](cases/catch_substitute_matches/src/main.bp)
[cases/catch_substitute_fails/src/main.bp](cases/catch_substitute_fails/src/main.bp)
