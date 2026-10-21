> Decision 751 — `Node` is a closed union alias of its kinds: a record that
> is none of them is no node. In a node's field typed `Node` the checker
> refuses it where it is written; handed whole to `compiler.ast`, whose
> argument is checked in the reply, it is `ast-ill-formed` at the `ast` call.
