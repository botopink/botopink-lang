# Decision 406 — 244 holds for decorators: `#[check]`'s `message` comes first and is required; on a field the rule is `#[refine(rule)]`, a field marker like the others.

A decorator's parameters follow the rule every function follows (244): the required ones first, every default
trailing. So `check`, in [draft/comptime/checks.bp](draft/comptime/checks.bp), takes the annotated declaration, then
`message` — first and required, a check without its text does not compile —, then `rule`, `at` and `code` with their
defaults, an absent function tested against `null` as any `?T` is. `Account` carries three checks in one list: the
first two name a rule and the field the violation is reported at, written `.confirm` and `.handle` and checked against
`Account`'s fields; the second also names its `code`; the third is the message alone. A rule over one field is no
`check` but a field marker, `#[refine(isEven)]` on `seats`. `main` reads the checks at build through the type's typed
meta and applies each rule: the first account breaks nothing and prints `[]`, the second prints
`["confirm: The passwords differ", "handle: That handle is taken"]`.

Cells that also bear on it: `modules/annotation/cells/annotation_argument_dot_variant`, `modules/decisions-taken/compiler_annotation_labelled_arguments-305/cases/annotation_label_equals_decorator`.

[draft/main.bp](draft/main.bp)
