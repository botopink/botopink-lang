> Decision 752 — a tree carries no location of its own: a type error inside
> the code a `compiler.ast` tree builds is reported at the call that expanded
> the template, its message naming the `file:line:col` of the `ast` call and
> the node. The caller's code a `Syntax(e)` splices keeps its own location.
