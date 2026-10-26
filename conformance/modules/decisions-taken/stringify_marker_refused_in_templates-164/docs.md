# Decision 164 — `$stringify` is refused in every user template, located, naming the marker; the documented markers are `$self`, `$N`, `$

The first two bindings use the markers a template has. `larger` names its parameters by position, `$0` and `$1`, and
`smallest` hands all of them to the host at once with `$args`. The third binding, `shown`, writes `$stringify($0)`,
which no template recognises. The parser refuses it at the template with `template-stringify-marker`, located at the
marker, and the label asks for the host's own conversion. So the program never builds, and neither earlier line
prints. No backend renders the marker, std's templates included: std's `Array.join` Erlang template does without it.

Cells in this repository that also bear on it: `modules/decisions-taken/parser_refuses_stringify-239/cases/template_stringify_marker`.

[draft/main.bp](draft/main.bp)
