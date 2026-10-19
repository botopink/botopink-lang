# Decision 616 — The parameter modifier `expr` is renamed `syntax`: a parameter marked `syntax` receives the code as it was written — a declaration, an argument expression, a lambda — and `comptime` one receives a value known at build.

The example has one parameter of each modifier. `traced(syntax value: i32)` receives the code its caller wrote, not the value. Its body is a build body: it reads the text with `compiler.text(value)` and returns, through std's `code` template, the code that stands at the call, where the hole `${text}` is spliced as a literal and the hole `${value}` as the expression it holds. So `traced(next())` becomes `"next() = " + next().toString()` at the call. `next()` runs once, where it is spliced, never at the capturing call: the counter goes from 0 to 1 and the line prints `next() = 1`. `traced(2 + 3)` prints `2 + 3 = 5`.

`times(comptime n: i32, s: string)` receives a value known at build, `3`, and is specialised for it. The program prints `ababab`. A run-time argument there (`times(count, "ab")`) is refused `comptime-arg-not-known`.

A decorator's first parameter is a `syntax` parameter too, `syntax decl: unknown`, the annotated declaration as written. The modifier is `syntax` in every position, a declaration, an expression or a lambda, and the older `expr` no longer exists.

Cells in this repository that bear on it: `modules/comptime/cases/comptime_value_or_type_param`, `modules/decisions-taken/syntax_node_spliced_as_written-638/cases/ast_syntax_node_typed_at_splice`.

[draft/main.bp](draft/main.bp)
