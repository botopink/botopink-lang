# init_executor_handle_on_instance_method

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> On every kind the handle is the annotated declaration spliced as code and
> bound to it (decision 613), and the checker's ordinary rules apply to it: a
> type is the type in expression position — `decl.make()` is `Users.make()` —,
> a method is its owner's path, `Users.make`, a field `Config.db`; never what
> the bare name resolves to in the module. An INSTANCE method's owner's path
> (`self` its first declared parameter) is the method unbound: `self` an
> explicit argument like any other, so the value calls on whatever instance it
> is handed (144 B-147), not the one the annotation decorated.
