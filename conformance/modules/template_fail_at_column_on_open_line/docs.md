# template_fail_at_column_on_open_line

The reference text this cell shows (from `conformance/docs.md`, § Template functions):

> A template refuses its call with `q.fail(message)`, located at the literal,
> or with `q.failAt(Span(start, end, line), message)`, located at that span of
> its text in the caller's file: on the opening line of a `"""…"""` literal the
> text begins after the three quotes.
