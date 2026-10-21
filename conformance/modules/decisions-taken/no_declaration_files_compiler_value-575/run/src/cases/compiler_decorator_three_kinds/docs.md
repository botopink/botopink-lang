> Decisions 575 (3), (4) — a decorator's parameters arrive three ways. Its
> first `syntax` is the annotated declaration (`decl`, read through
> `compiler.name`); `comptime label: string` holds the value at build
> (`label.toUpper()`); `syntax rule: fn(v: T) -> bool` holds the expression
> written, read at build as the annotation wrote it (`compiler.text(rule)`)
> and spliced into the member the program runs. In the member, `label` and
> the body's `val shown` are spliced as literals (the tree rule).
