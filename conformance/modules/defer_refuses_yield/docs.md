# defer_refuses_yield

The reference text this cell shows (from `conformance/docs.md`, § Blocks):

> Its body cannot leave the path it runs on: `return`, a `break` or `continue` that leaves it, `yield`
> and `await` in it are refused, located (a loop wholly inside the body may `break`). The value of the
> deferred expression is discarded, and the compiler checks nothing about what is deferred: a value
> that is never closed compiles (decision 539 (6)).
