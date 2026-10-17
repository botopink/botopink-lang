# val_nested_ctor_pattern

The reference text this cell shows (from `conformance/docs.md`, § val — immutable binding):

> A `val` may bind a pattern instead of a name when the pattern matches every
> value of the initialiser's type, so the binding has no failure path: a list
> pattern that is only a spread (`val [..rest] = xs;` binds the whole list), and
> the constructor of a one-variant `type` or a record's own constructor whose
> every argument is a name, a `_` or such a constructor in turn — so constructors
> nest (`val Pair(Circle(r), n) = p;`). Any other pattern is
> `refutable-val-pattern`; `val assert` and `case` say what a mismatch does.
