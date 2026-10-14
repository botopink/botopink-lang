# try_await_prefix_operators

The reference text this cell shows (from `conformance/docs.md`, § Results):

> **`try` and `await` are prefix operators**, binding as the unary `-` does (decision 537).
> They stand wherever an operand does: `await t * 2` is `(await t) * 2`, `await x + await y` is
> `(await x) + (await y)`, `try load() + 1` is `(try load()) + 1`, and `total + try r`, `-try x`,
> `(try r).length` and `!await t` each have one reading. Postfix (`.`, `()`, `[]`) binds tighter than
> the prefixes, as `-t.x` is `-(t.x)`: `await t.x` is `await (t.x)` and `await f()` is
> `await (f())`. `try await f()` is `try (await f())`. There is no `try-await-operand` refusal:
