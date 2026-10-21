# external_wasm_fn_cell_string

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> Each cell holds a value of the kind it names (decision 481), and a value of another kind is refused
> at the argument, naming the form to write: `body: "tanBody"` (a string where an identifier goes),
> `op: floor` (a name where the opcode's text goes), `wasi: "RandomF64"` (a string where an enum
> value goes), `std: hash.contentHash` (a name where std-wasm's string goes):
