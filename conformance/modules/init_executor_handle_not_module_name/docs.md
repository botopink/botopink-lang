# init_executor_handle_not_module_name

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> On every kind the handle is the annotated declaration spliced as code and
> bound to it (decision 613), and the checker's ordinary rules apply to it: a
> type is the type in expression position — `decl.make()` is `Users.make()` —,
> a method is its owner's path, `Users.make`, a field `Config.db`; never what
> the bare name resolves to in the module. `Users` where a function is expected
> is the checker's own refusal at the annotation, the `compiler.init` call its
> `called from` line.
