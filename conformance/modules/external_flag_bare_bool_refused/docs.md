# external_flag_bare_bool_refused

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> **An `@External` variant's flags are labelled** (decision 487): `result:` on
> every variant, `inline:` on `External.Erlang`, each a `bool` read by its label in
> any order among the arguments (`@External.Erlang(result: true, "json:decode($0)")`
> is the same binding as `@External.Erlang("json:decode($0)", result: true)`). A
> bare `true` or `false` names no flag, so it is refused at the argument:
