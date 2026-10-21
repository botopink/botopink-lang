# missing_required_argument

The reference text this cell shows (from `conformance/docs.md`, § Parameters with defaults):

> Only the parameters a call leaves out take their defaults. A parameter the call
> names by label keeps the argument it was given, whichever position it is in —
> `Port(number: 8080, host: "a")` reorders to the declaration —
> and a parameter with no default is still **required**: leaving one out is the
> arity error it has always been.
