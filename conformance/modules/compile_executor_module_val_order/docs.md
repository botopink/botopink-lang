# compile_executor_module_val_order

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> An executor is a statement of its module's body at the annotated
> declaration's position (decision 580): a module's `val`s, `var`s, `_`
> statements and executors run in one order, source order, so a `val` written
> below an annotated declaration reads what that declaration's executor did.

A `val` written above the annotated declaration reads the registry before that executor ran, on every target, because a `push` rebinds the registry's `var` and leaves the array the `val` read alone.
