# added_member_handed_as_value

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> A member a decorator adds and then needs is held as a value (decision 842
> (1)): the decorator writes the `fn` literal once in a `val` of its body, adds it
> (`compiler.addMember("make", make)`) and hands the same value to its other
> members and its executor (`make().host()`), never reading it back through
> `decl`. A `fn` literal is a literal (759), and a tree spliced into a tree
> (575 (4)): each read of the `val` is the literal itself. A local holding any
> other value, handed to `addMember`, is `decorator-member-local-not-literal`
> at the read.
