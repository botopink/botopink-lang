# syntax_fn_expanded_at_call

The reference text this cell shows (from `conformance/docs.md`, § Functions expanded at their call):

> **A `syntax` expression.** `fn matches(syntax value: unknown) -> anyvalue`
> is called `matches(render(page))`: the argument is checked once, against the
> parameter's declared type (716), and is never executed at the call (720) — the
> compiler holds the code and evaluates it only where the answer splices it.
> `compiler.text(value)` is the expression as written, `compiler.source(value)`
> the call's `Source(file, line, col)`, so the body can write the caller's
> location into the run-time call it answers while the caller writes nothing but
> the expression. The answer's code is spliced where the call stands and typed
> there (638).

`matches` writes the call's module and line into the run-time call `matchesAt` it answers: `main:32`, the line of `matches(render("page"))`, then the value `render` gave there.
