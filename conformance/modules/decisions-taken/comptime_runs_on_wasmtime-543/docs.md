# Decision 543 — The comptime runtime's engine: wasmtime in the native compiler, the page's engine on the web; wasm3 removed

Three module `val`s are computed at build. The comptime runtime runs them on the host's engine: wasmtime inside the
native compiler, the page's `WebAssembly` in `compiler-web`. `builtOk` and `builtCaught` call `failure.attempt` inside
a `comptime` body. Under wasm3 that was refused at build, because it lacked exception handling, and the compiled
engine runs it now. So `builtOk` is `Ok 20`, and `builtCaught` holds the `panic` the thunk raised,
`Error panic: too deep at 3`. `builtLabel` runs ordinary std string code at build, `toUpper` and a codepoint
`length`, and is `AÇÃO (4)`. The fourth line runs the same `attempt` at run time. The last line compares it with the
value made at build and prints `true`. The build and a wasm program run the same std code on one engine, so the
answer is the same on every target.

Cells in this repository that also bear on it: `modules/decisions-taken/wasm_attempt_by_exception_handling-518/cases/comptime_attempt_at_build`.

[draft/main.bp](draft/main.bp)
