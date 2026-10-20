# Decision 793 — What a top-level `comptime` block leaves open, one rule for every block; amends 788 (1)–(3).

A top-level `comptime { … }` runs to its end: a `return` or a `throw` inside it is refused
`comptime-block-exit`, located at the jump (793 (1)) — the cell `block_return_refused` writes one under an
`if`. A block in a library package runs in the build of the package that uses it, in decision 660's level
order (793 (2)): in `library_block_level_order` the package `upper` depends on `base`, so `base`'s block and
its init run first though the manifest lists `upper` first, and the program's own block last; nothing
imports either package. A `pub` function whose every parameter is `comptime`, called from another module's
block, is expanded at the call (793 (3)): in `block_calls_other_module_pub` the `compiler.init` that `cases`'s
`check` writes is the program's block's, run at program start before `main`, and the same function called
from `main` writes its executor's body there (decision 808).

A cached build replays the build output (793 (4)), and a `comptime { … }` inside a function body writes its
`print` as build output (793 (5)). `cell check` records no build line (decision 796), so both are held by
compiler unit tests: the replay of a dependency read back from its level-B entry, and the prints of a `void`
`comptime` block and of one that answers a value.

[cells/block_calls_other_module_pub/src/main.bp](cells/block_calls_other_module_pub/src/main.bp)
[cells/block_return_refused/src/main.bp](cells/block_return_refused/src/main.bp)
[cells/library_block_level_order/src/main.bp](cells/library_block_level_order/src/main.bp)
