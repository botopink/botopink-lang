# Decision 557 — A refusal prints `error[<code>]: <message>`

`word.fooBar()` is refused by the checker — `string` declares no method `fooBar` (136). What this decision fixes is how
the refusal is printed: `` error[unknown-primitive-method]: `string` has no method `fooBar` ``, the code inside the brackets
and the message after the colon, the same printer as a parse error's `error[…]: …`. A cell pins that line as its
`refused` record, at `src/main.bp:7:16`.

Cells that also bear on it: `modules/primitive_method_unknown`.

[draft/main.bp](draft/main.bp)
