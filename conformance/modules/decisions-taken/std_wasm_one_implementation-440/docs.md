# Decision 440 — std-wasm is the wasm codegen's and the comptime's one implementation, transpiled into the program, bound by `@External.Wasm("std:…")`.

A std function that std-wasm implements has one implementation for two uses: the wasm codegen and the comptime. Its
`.Wasm(std: "<module>.<function>")` cell names the std-wasm export. A `--target wasm` program gets that function
transpiled into its own module, and the build evaluates it the same way on every target. Only std writes a `std:` cell
(445), and the compiler matches no function by name.

The example calls `hash.contentHash` twice. The `comptime` call runs at build, where the answer comes from std-wasm.
The second call hashes a text the build cannot know, because it comes out of `split` at run time. On wasm that call runs
the same std-wasm function, now part of the program. On commonJS, erlang and beam it runs the host cell. The two hashes
print the same and `==` answers `true`. A `std:` naming no std-wasm export, or one whose types differ from the
declaration's, is refused at the annotation.

Cells that also bear on it:
`modules/decisions-taken/std_cell_is_std_only-445/cells/external_wasm_std_outside_std`,
`modules/decisions-taken/wasm_prints_std_wasm_text-441/cells/float_shortest_text`.

[draft/main.bp](draft/main.bp)
