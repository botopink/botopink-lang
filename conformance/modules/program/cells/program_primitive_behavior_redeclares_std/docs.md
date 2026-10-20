# program_primitive_behavior_redeclares_std

Decision 799 (4): a program's contract implemented for a primitive adds members to it and redeclares none. A `default
fn startsWith` of the contract `Prefixed`, a member `string` already has, is refused at the implementation
`StringPrefixed implement Prefixed for string {}`, `behavior-member-redeclared`, naming the contract, the member and
the primitive.
