# iterator_vs_factory

The reference text this cell shows (from `conformance/docs.md`, § Iterators and streams):

> **Iterator or factory.** A function with an `Iterator` or `Stream` return is
> an iterator if its own body has `yield` or `break v` (not counting closures and
> inner `iter` / `stream` loops); otherwise it is an ordinary function that
> **returns** a ready-made iterator. Mixing the two in one body is
> `iter-mixed-yield-return`.
