# template_raise_names_body_file

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> A template's body runs the same way: one declared in another
> module whose body raises is refused at the call that raised, in the template's
> file (`src/tpl.bp:3:5`), with the call that expanded it as the `called from`
> line. A call inside a template's expansion takes the place of the template's
> use, the one line the expansion has in the file.

`tpl`'s `shout` panics at `src/tpl.bp:3:5`; that call is refused, in `tpl`'s file, and the call `shout "hi"` in `main` is its `called from` line, on every target.
