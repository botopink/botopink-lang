# template_raise_names_body_file

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> A template's body runs the same way: one declared in
> another module whose body raises is refused at the call that expanded it, and
> the message names the call that raised in the template's file (``raised at
> src/tpl.bp:3:5 while `shout` ran the template's body``).

`tpl`'s `shout` panics at `src/tpl.bp:3:5`; the call `shout "hi"` in `main` is refused, naming that call in the template's file, on every target.
