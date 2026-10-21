# defer_return_value_before_defers

The reference text this cell shows (from `conformance/docs.md`, § Blocks):

> The deferred expression is evaluated when it runs, not when `defer` is written (`var f = open("a");
> defer f.close(); f = open("b");` closes `b`), and a `return <expr>`'s value is computed before the
> block's defers run:
