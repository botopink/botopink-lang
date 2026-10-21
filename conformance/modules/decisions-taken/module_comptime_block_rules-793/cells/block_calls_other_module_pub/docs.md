# block_calls_other_module_pub

The reference text this cell shows (from `conformance/docs.md`, § A top-level `comptime { … }`):

> A function whose every parameter is `comptime` is expanded at the call also when it is `pub` and called from another module's block (decision 793 (3)): the `compiler.init` it writes is the block's.

<!-- example: modules/decisions-taken/module_comptime_block_rules-793/cells/block_calls_other_module_pub -->
