# init_executor_binder_shadows_local

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> The executor is a tree (575 (4)): run-time code whose names resolve where the decorator wrote it — a private helper
> of the decorator's module included, a library's too —, each `syntax` parameter spliced as the expression written,
> each `comptime` parameter and each `val` of the body spliced as the literal of its value.
