# generator_handle_stateful

The reference text this cell shows (from `conformance/docs.md`, § Iterators and streams):

> A generator handle is stateful, whatever its body: a second `for` over a handle the
> first one exhausted reads nothing — on an `iter fn`, whether its body is only
> literal `yield`s or runs code, and on an `iter loop`.
