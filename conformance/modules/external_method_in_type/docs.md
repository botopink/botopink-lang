# external_method_in_type

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> **A host function that operates on a value of one type is a method of that
> type.** It is declared inside the type's body with `declare fn`, `self` first,
> and called like any other method — `sock.recv(16, 1000)`, never a free
> `recv(sock, 16, 1000)`. The binding's `$0` is the receiver and `$1`, `$2`, … the
> arguments after it; the plain `("module", "symbol")` form hands the host
> function the receiver first. A host function with no such owner (`listen(port,
> backlog)`, `now()`) stays at module level.
