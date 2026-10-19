# external_returns_record

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> **A host that answers a record may build it either way.** A value knows its own
> type (§ *A value knows its own type*), and a host is the one writer the compiler
> does not own — a `.erl` sidecar shipped by a library, a template written before
> the rule existed. So the boundary accepts both shapes and the declared return
> type decides which record the answer becomes: a plain object or map is adopted
> into the record the declaration names, field by declared name, and an answer
> that already carries its type is left exactly as it is. The same holds one
> container deep — `?T`, `T[]`, `Result<T, E>` and `Async<T>` are looked
> through — and no deeper.
