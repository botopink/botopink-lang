# Decision 487 — `result:` and `inline:` are labelled, read by label in any order; a bare positional `bool` is refused.

Each `Implementation` cell keeps its template as its one positional argument and writes every flag by its label.
`decodeInt` puts `result: true` before the template on `.JavaScript` and after it on `.Erlang`. The two spellings mean
the same, since a flag is read by its label and not its place. `byteCount` writes `inline: false` on `.Erlang`, the one
variant that has the flag, likewise by label. `upper` writes a bare `true` after its template. That argument names no
flag, `result:` or `inline:`, so it is refused at the argument (`external-field-unlabelled`), naming the labels a
`bool` fits on `.Erlang`. The program does not build, and nothing prints.

Cells in this repository that also bear on it: `modules/decisions-taken/external_fields_written_by_label-621/refused/src/cases/external_flag_bare_bool_refused`,
`modules/decisions-taken/external_fields_written_by_label-621/refused/src/cases/external_flag_bare_fn_refused`,
`modules/decisions-taken/external_erlang_binds_beam-437/refused/src/cases/external_inline_unread`.

[draft/main.bp](draft/main.bp)
