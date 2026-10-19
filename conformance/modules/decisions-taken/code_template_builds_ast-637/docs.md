# Decision 637 — Neither option: `code.bp` is built first, inside B-149, and a template answers the code it builds through `code` — the caller's holes are `syntax` values it splices, so no `Hole(index)` node exists.

A template builds its answer as code through std's `code` template, and the caller's holes reach it as `syntax` values.
`box`, in [draft/comptime/box.bp](draft/comptime/box.bp), reads two things of the text it is called with: the raw text,
through `compiler.text(t)`, whose first word becomes the build value `tag`; and the holes, through
`compiler.holes(t)` — the i-th the i-th `${…}` written by the caller, opaque. Its answer is
`` code @`Box(tag: ${tag}, kids: [Text(value: ${h[0]!}), Text(value: ${h[1]!})])` ``: `${tag}` splices a build value as
the literal `"section"`, while `${h[0]!}` and `${h[1]!}` splice the caller's expressions as written, typed in `main`'s
scope where `name` is bound. No string is parsed back into code and no `Hole(index)` node exists. `main` prints
`section` and `hello Ana | ANA`, the holes evaluated at run time.

Cells that also bear on it: `modules/decisions-taken/template_called_with_raw_text-577/cases/compiler_template_forms`, `modules/decisions-taken/template_marked_by_syntax_text-578/cases/compiler_template_expr_return`.

[draft/main.bp](draft/main.bp)
