> Decisions 575 (3), (4) — a decorator's parameters arrive three ways. Its
> first `expr` is the annotated declaration (`decl`, read through
> `compiler.name`); `comptime label: string` holds the value at build
> (`label.toUpper()`); `expr rule: fn(v: T) -> bool` holds the expression
> written, spliced into the member the program runs, where `label` is
> spliced as a literal.
