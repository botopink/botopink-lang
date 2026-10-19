# Decision 190 — The library decides which types an embedded expression may have: the template function accepts or refuses it with a comp

Which types a template accepts in its holes is the template's decision, not the compiler's: the compiler hands each
hole over typed in the caller's scope and with its position, and the template accepts it or refuses it with a located
error. `money`, in [draft/comptime/money.bp](draft/comptime/money.bp), takes one hole and answers code that passes it to
`cents(amount: i32)`, so `` money @`${price}` `` with an `i32` builds and would print `12.50`. `` money @`${label}` ``
holds a `string`, and the code `money` built for that call is refused at the hole — `label` is no `i32` — the error
landing on the caller's `${label}`, where the expression was written. A template that wants another rule says so with
`compiler.fail(…, at: …)`, as `money` does for a text without exactly one hole; the compiler keeps no list of types a
hole may have. The program does not run.

Cells that also bear on it: `modules/compiler_template_forms`, `modules/anyvalue_outside_template`.

[draft/main.bp](draft/main.bp)
