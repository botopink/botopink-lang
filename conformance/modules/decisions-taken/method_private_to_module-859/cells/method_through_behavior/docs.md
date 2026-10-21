# method_through_behavior

The reference text this cell shows (from `conformance/docs.md`, § Methods without `pub`):

> A method written without `pub` is private to its module, for every type (decision 859):
> `x.m(…)` or `X.m(…)` from another module is `method-not-pub`, at the call, naming the
> type and the method. A method that implements a member of a behavior the type itself
> declares `implement` for is reached through the behavior from anywhere, with or without
> `pub`; the compiler's lowering reaches one by a mark on the call it writes (decision 830).
> std's prelude writes every member of a primitive `pub` — `pub fn`, `pub declare fn`,
> `pub val length: i32;` — and a member a decorator adds with `decl.addMember` is `pub`
> (decision 887). The `.d.ts` declares a type's `pub` methods only.
