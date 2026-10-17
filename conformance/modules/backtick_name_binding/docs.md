# backtick_name_binding

The reference text this cell shows (from `conformance/docs.md`, § Bindings):

> A name written between backticks is an identifier, anywhere a name goes
> (decision 561, Kotlin's escaped identifier): `` `text` `` names the text between
> the backticks — any characters but a backtick and a line break, a keyword
> included — as a binding, a parameter, a function, a type, a variant, a field, a
> module path's segment, an import item and its alias. `` `not-found` `` and
> `not-found` never meet: the plain spelling stays `not - found`. A name that is
> already an identifier means the same written either way — `` `count` `` is
> `count`, and `botopink format` writes it `count`. A diagnostic prints such a
> name as written, between its backticks; each backend gives it a name of its own
> that meets no other name of the module (erlang a quoted atom, commonJS and wasm
> an escaped name), and a printed value spells it as written.
