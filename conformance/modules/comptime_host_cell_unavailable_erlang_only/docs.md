# comptime_host_cell_unavailable_erlang_only

The reference text this cell shows (from `conformance/docs.md`, § Host functions at compile time (decision 341)):

> What a decorator may call is decided when its package is compiled, never at a
> consumer's build, and whatever the package's `targets` (decisions 434, 452): a
> host function it reaches — in its body, in a function of its module, through a
> std or an imported function — needs one of the two cells the comptime runtime
> answers by: its `std:` cell (std-wasm) or its `.Wasm(body: …)` cell.
> Neither is refused at the call (`comptime-host-cell-unavailable`), naming the
> function and both cells; an `.Erlang` cell beside them is ignored,
> never tried.
