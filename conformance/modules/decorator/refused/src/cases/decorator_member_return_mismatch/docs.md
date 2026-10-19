# decorator_member_return_mismatch

A member a decorator wrote (`compiler.addMember`) whose body returns the wrong type is refused
like a hand-written method's, located at the annotation that added it with the decorator's
call as the `called from` line.
