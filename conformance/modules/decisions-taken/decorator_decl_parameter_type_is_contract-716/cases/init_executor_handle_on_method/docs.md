# init_executor_handle_on_method

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> On every kind the handle is the annotated declaration spliced as code and
> bound to it (decision 613), and the checker's ordinary rules apply to it: a
> type is the type in expression position — `decl.make()` is `Users.make()` —,
> a method is its owner's path, `Users.make`, a field `Config.db`; never what
> the bare name resolves to in the module. A type annotated by a decorator
> whose `syntax decl` is a function type does not meet the contract and is
> refused at the annotation.
