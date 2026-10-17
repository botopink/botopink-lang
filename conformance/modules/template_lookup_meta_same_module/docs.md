# template_lookup_meta_same_module

The reference text this cell shows (from `conformance/docs.md`, § Template functions):

> The looked-up declaration's decorators run before the template body. A
> declaration of another module carries what its module's decorators recorded;
> in one module the decorators run before the bodies and the `val`s, so a call
> written above the annotated declaration reads its meta — except a decorator
> that reads `.hooks`, which runs after the bodies (decision 372): its meta read
> before it ran is refused at the call's literal (`typeinfo-meta-hooks-pending`).
