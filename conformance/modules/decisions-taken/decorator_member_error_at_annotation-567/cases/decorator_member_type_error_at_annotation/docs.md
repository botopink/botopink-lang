# decorator_member_type_error_at_annotation

A type error inside a member a decorator wrote (`compiler.addMember`) is located at the
annotation on the declaration that added it, with the decorator's call as the
`called from` line.
