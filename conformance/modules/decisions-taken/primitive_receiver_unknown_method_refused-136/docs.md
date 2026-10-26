# Decision 136 — A primitive receiver answers only the methods it declares

A method call on a primitive receiver is legal only when the receiver's type in `primitives.bp` declares the method.
`word.toUpper()` and `xs.length()` are declared and would print `ABC` and `3`, but the program never runs:
`word.toUpperCase()` is refused at `toUpperCase`, `unknown-primitive-method` — `string` has no such method. The name is
JavaScript's own spelling of `toUpper`, the host template behind the declared method, and a host spelling adds no name to
the language; the refusal suggests `toUpper` because that is the declared method whose host spelling was written. Before
this rule the call typed as anything and each target answered differently.

Cells that also bear on it: `modules/primitive/cases/primitive_method_undeclared`, `modules/primitive/cases/primitive_method_unknown`.

[draft/main.bp](draft/main.bp)
