# Decision 913 — `unicode`'s generated tables stay the flat private sibling `libs/std/src/unicode_tables.bp` until 144 B-75; then the file is `libs/std/src/internal/unicode_tables.bp`, `unicode.bp` writes `import {internal.unicode_tables as tables};`, and a consumer's `import {unicode_tables} from "std"` — or any import of std's `internal/` — is refused, located (592 (8), 703); 97's compiler residual 11 closes so.

[cases/std_internal_import_refused/src/main.bp](cases/std_internal_import_refused/src/main.bp)
