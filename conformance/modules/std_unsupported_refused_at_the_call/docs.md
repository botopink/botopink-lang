# std_unsupported_refused_at_the_call

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> **std is refused at the call, never at the import** (decision 518 (4)). Every
> std module is importable on every target; a call of a std function that
> reaches a host declaration with no binding for the target — the function
> itself, or one its body reaches through its module's own functions — is
> `std-unsupported-on-target`, located at the call and naming the function (and
> the declaration it reaches, when that is another).
