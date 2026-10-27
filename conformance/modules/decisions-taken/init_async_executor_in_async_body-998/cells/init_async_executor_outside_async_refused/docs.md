# init_async_executor_outside_async_refused

The reference text this cell shows (from `conformance/docs.md`, § A top-level `comptime { … }`):

> At a decorator, in a top-level `comptime` block, in a body that is not `async`, or in a `comptime { … }` inside
> such a body, nothing awaits it, and it is refused `init-async-executor-outside-async` at the `async`, the message
> naming the plain form.
