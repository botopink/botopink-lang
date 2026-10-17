# catch_lowest_precedence

The reference text this cell shows (from `conformance/docs.md`, § Results):

> **`catch` is an infix operator of the lowest precedence**: its right side is evaluated first and is
> the fallback, its left side is the whole expression before it. `try await t catch 0 * 2` is
> `(try await t) catch (0 * 2)`, and parentheses group as anywhere —
> `(try await t catch 0) * 2` doubles the result:
