# Decision 410 — `use` is refused as the right operand of `&&`, `||` and `??`

`Banner` reads the hook `flag` twice. The first read, `val shown = use flag();`, is at the top level of the component body, where every `use` runs on every call. The second sits in the right operand of `&&`: when `ready` is `false` the operand never runs, so the hook would run on some calls and not others, and its slot in the body's hook list would move. The program is refused at that `use` with ``use-not-top-level: `use` inside the right operand of `&&` ``; `||` and `??` refuse it alike. The fix reads the hook first and combines after: `val f = use flag(); val both = ready && f;`.

Cells in this repository that also bear on it: `modules/use_in_if`, `modules/use_in_lambda`, `modules/use_in_loop`, `modules/use_after_early_return`.

[draft/main.bp](draft/main.bp)
