> A decorator's body calls `compiler.ast(node)` too (decisions 640 (3), 627): the
> code the tree builds is a build value that enters a member or an executor as
> the code it is, where the tree reads it — a `val` of the body
> (`val client = compiler.ast(…)`), or the call written inside the member's `fn`
> literal, evaluated at build and spliced as its answer (decision 642). The names
> the decorator's tree writes resolve where its member's names do: in the
> decorator's module (decision 384), a name the member binds as that binding.
