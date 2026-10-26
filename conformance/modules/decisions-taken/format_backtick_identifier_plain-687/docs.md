# Decision 687 — `botopink format` writes a backtick name that is already an identifier as the plain name (`` `count` `` → `count`); backticks stay only where the name needs them.

The program as `botopink format` writes it. `count` was written `` `count` `` — backticks around a name that is already an identifier — and the formatter wrote it plain, field, binding and argument alike: one spelling for one name. The backticks stay only where the name needs them: `` `default` `` is a reserved word used as a field name, and `` `max-age` `` holds a character no identifier can. The program prints `10 2 3600`.

Cells in this repository that also bear on it: `modules/decisions-taken/backtick_escaped_identifier-561/run/src/cases/backtick_name_binding`, `modules/decisions-taken/backtick_escaped_identifier-561/run/src/cases/backtick_name_field`, `modules/decisions-taken/backtick_escaped_identifier-561/cases/backtick_name_in_diagnostic`.

[draft/main.bp](draft/main.bp)
