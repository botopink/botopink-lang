# decl_hooks_graph

The reference text this cell shows (from `conformance/docs.md`, § The hooks a function reaches — `decl.hooks`):

> **Comparing decorators** (decision 371). `a.decorator.same(other)` answers
> whether two decorators are one declaration: `other` is a decorator's name — an
> alias and a namespace resolved where it is written — or another `Decorator`
> (`b.decorator`); a same-named decorator of another module or package is
> `false`, and anything else is no `Decorator` (a string spelling the name is a
> type mismatch at the argument). `is` stays a keyword and `==` on two
> `Decorator`s has no meaning.
