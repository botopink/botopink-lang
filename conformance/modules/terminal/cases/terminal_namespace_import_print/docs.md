# terminal_namespace_import_print

The reference text this cell shows (from `conformance/docs.md`, § `print` and `panic`):

> The namespace form reaches them too (`import {io.terminal}; terminal.print("x")`): a namespace the program uses for
> nothing else links none of the module's other members, so the hosts they bind (stdin's, which wasm has no cell for)
> are not linked, on wasm as on the other targets.
