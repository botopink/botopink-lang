# syntax_fn_run_time_return

The reference text this cell shows (from `conformance/docs.md`, § Functions expanded at their call):

> Such a function returns any written type `T` — `void` included —, `anyvalue`
> (the built code, typed at the call) or `anytype` (a built type): its build
> body returns code, and `-> T` is code of type `T`, checked where it is spliced,
> as a template's is (841).

`twice(n * 2)` answers an `i32` at its call (`12`); `log("sum", n + 4)`, declared `-> void`, stands as a statement that prints `sum: n + 4 = 7`.
