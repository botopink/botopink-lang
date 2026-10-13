# decorator_raise_names_body_file

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> A decorator's body runs in its own module wherever it annotates: an imported
> decorator may build a record private to that module. A body that raises is
> refused at the annotation that ran it, and the message names the call that
> raised in the body's own file (``raised at src/deco.bp:3:5 while `#[check]` ran
> the decorator's body``).

`deco`'s `check` panics at `src/deco.bp:3:5`; the annotation in `main` is refused, naming that call in the body's file, on every target.
