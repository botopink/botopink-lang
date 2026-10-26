# module_comptime_block

The reference text this cell shows (decision 788):

> A module may hold top-level `comptime { … }` blocks — build bodies run once per build in the order
> written, after the module's declarations are known; a function whose every parameter is `comptime` is
> called there and expanded at the call; each `compiler.init` registered there runs at program start in
> that order; a `print` reached there is the build phase's output.
