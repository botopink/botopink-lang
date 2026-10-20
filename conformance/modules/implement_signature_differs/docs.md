# implement_signature_differs

The reference text this cell shows (from `conformance/docs.md`, § behavior):

> Every implementor of a behavior is checked against it, on every member it writes
> that the behavior (or one it extends) declares — a required member and an
> overridden `default fn` alike, a type's own `implement` clause and an extension
> block (`Sym implement B for T`) alike, std's types and a program's (decision
> 800): the same number of parameters, and each parameter's type and the return
> type identical, `Self` read as the implementing type. Labels, parameter names
> and defaults are free; there is no variance — a contract's `-> ?string` is not
> met by `-> string`. A difference is refused at the member,
> `implement-signature-differs`, naming both signatures.
