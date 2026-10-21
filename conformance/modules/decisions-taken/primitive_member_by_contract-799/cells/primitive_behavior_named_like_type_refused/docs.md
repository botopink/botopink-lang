# primitive_behavior_named_like_type_refused

Decision 799 (3): a lowercase `behavior string { … }` is a behavior named like a literal's type, refused at the name
as `primitive-type-redeclared` (decision 639). A program adds members to `string` through a contract of its own
implemented for it (`primitive_member_by_contract`). The parent binary accepted the declaration.
