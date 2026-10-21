# use_refused_in_short_circuit_operand

Decision 410: a `use` as the right operand of `&&`, `||` or `??` runs on some calls only, so it is refused
`use-not-top-level` at the `use` (357 (1)). `val both = ready && use flag();` is that refusal, at its `use`; it used to
be a parse error that named no rule. Written `val f = use flag(); val both = ready && f;` it builds.
