# try_in_parentheses

The reference text this cell shows (from `conformance/docs.md`, § Results):

> **`try` and `await` begin an expression.** They stand where an expression
> starts — a statement, a `val` / `var` initializer, the right side of `=`, a
> `return` / `yield` / `break` / `throw` operand, a call argument, an element of
> an array, tuple or record literal, an `if` / `while` condition, a `case`
> subject, a `for` iterable — and take the whole expression after them:
> `try a + b` is `try (a + b)`, and `try await f()` is `try (await f())`. Neither
> is ever the operand of an operator, of a unary `-` / `!`, of parentheses or of
> a `.` chain; `total + try r`, `-try x` and `(try r).length` are
> `try-await-operand`, and the fix is to bind the value first:
