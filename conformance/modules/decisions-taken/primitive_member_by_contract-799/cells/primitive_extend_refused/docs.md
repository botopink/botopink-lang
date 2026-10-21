# primitive_extend_refused

Decision 799 (3): `extend` adds no member to a primitive. `StringExtras extend string { … }` keeps its refusal, at
`extend`, naming `implement <Behavior> for string`, the form that does (`primitive_member_by_contract`).
