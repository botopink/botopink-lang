# decorator_raise_names_body_file

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> A decorator's body runs in its own module wherever it annotates: an imported
> decorator may build a record private to that module. A body that raises is
> refused at the call that raised, in the file that call is written in
> (`src/deco.bp:3:5`), and every call of the chain is a `called from <file>:<line>:<column>`
> line under it, innermost first, down to the annotation that ran the body
> (decision 532).

`deco`'s `check` panics at `src/deco.bp:3:5`; that call is refused, in `deco`'s file, and the annotation in `main` is its `called from` line, on every target.
