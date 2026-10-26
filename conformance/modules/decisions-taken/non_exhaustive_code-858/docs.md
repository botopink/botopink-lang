# Decision 858 — Every exhaustiveness refusal carries the code `non-exhaustive`: an enum's, a union's and an open domain's.

A `case` that does not cover its subject is refused with a message that opens with the code
`non-exhaustive`, then the unchanged wording: an enum's (`enum_code`), a union's (`union_code`) and
an open domain's, which asks for `_` (`open_domain_code`).

[cases/enum_code/src/main.bp](cases/enum_code/src/main.bp)
[cases/union_code/src/main.bp](cases/union_code/src/main.bp)
[cases/open_domain_code/src/main.bp](cases/open_domain_code/src/main.bp)
