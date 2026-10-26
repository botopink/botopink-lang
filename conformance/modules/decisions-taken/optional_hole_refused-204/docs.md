# Decision 204 — A hole of type `?T` is a comptime error at the hole (`error: a hole of type ?string — write {subtitle ??

The template `card`, declared in the build layer ([draft/comptime/markup.bp](draft/comptime/markup.bp)), splices each of its two holes into `text(…)`, which takes a `string`. That is how the template decides which types a hole may have: the compiler fixes no list. `title` is a `string`, so the first hole is fine. `subtitle` is a `?string`, so the second hole is a type mismatch at the hole, carrying the template's reason through `compiler.note`: the author writes what an absent value shows, `${subtitle ?? ""}`. That holds even though `string` itself is accepted, because a hole never prints `null` silently. The program never builds. Written with `${subtitle ?? ""}` it would print `<h1>Hi</h1><p></p>`.

Cells in this repository that bear on it: `modules/decisions-taken/template_called_with_raw_text-577/refused/src/cases/template_hole_typed_at_caller`, `modules/decisions-taken/template_hole_error_at_column-691/cases/template_hole_error_at_column`.

[draft/main.bp](draft/main.bp)
