# template_own_raise_located

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> A template declared in the module that uses it is located the same way: its body's raising call is refused in
> that module's own file, and the use is its `called from` line.

`shout` is declared in the module that uses it and panics at `src/main.bp:8:5`; that call is refused, in the module's own file, and the call `shout "hi"` at `src/main.bp:13:12` is its `called from` line, on every target.
