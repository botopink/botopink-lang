# Decision 788 — A module may hold top-level `comptime { … }` blocks: build bodies of the module, run once per build in the order written, after the module's declarations are known; a function whose every parameter is `comptime` is called there and expanded at the call (139's rule), so no `comptime fn` form exists.

A top-level `comptime { … }` is a build body of its module: it runs once per build, after the module's
declarations are known, the blocks of a module in the order written. A function whose every parameter is
`comptime` — here `f(comptime n: string) -> void` — is called there and expanded at the call, so the
`compiler.init` it writes is the block's: each one registered runs at program start, in the order the
blocks registered them, before `main`.

In the cell two blocks, one before `main` and one after it, each call `f`. At build they print
`first block`, `build a`, `build b` (the build's output, on stdout); the program prints `init a`,
`init b`, then `main`. `cell check` records the run alone (decision 796); the build's lines are held by a
compiler unit test.

[cells/module_comptime_block/src/main.bp](cells/module_comptime_block/src/main.bp)

A refusal inside a block names it as `comptime`: the block is a build body of its module, and no name the
compiler gives it reaches a diagnostic. In the cell `block_refusal_names_comptime` a block writes a
module-level `var`, refused at the write.

[cells/block_refusal_names_comptime/src/main.bp](cells/block_refusal_names_comptime/src/main.bp)
