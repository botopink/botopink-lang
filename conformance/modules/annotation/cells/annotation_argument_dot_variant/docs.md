# annotation_argument_dot_variant

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> A variant against an enum parameter resolves the same way. Either is named
> exactly as declared, case included.
>
> The enum is the one the decorator's own module declares, though the annotating
> module imports none: a decorator another package declares takes
> `#[kit.m(lifecycle: .Manual)]`, and an enum of the same name the annotating
> module declares never supplies its variants.
