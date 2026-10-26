# syntax_fn_text_of_expression

The reference text this cell shows (from `conformance/docs.md`, § Functions expanded at their call):

> `compiler.text(value)` is the expression as written, `compiler.source(value)`
> the call's `Source(file, line, col)`.

`expect(a == b)` prints `a == b` from `compiler.text` beside the value the expression has at the call.
