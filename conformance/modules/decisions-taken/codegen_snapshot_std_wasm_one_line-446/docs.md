# Decision 446 — A codegen snapshot shows a transpiled std-wasm function as one line, never its body.

The program calls a std function whose wasm body is not the program's own code — `hash.contentHash` — and prints the length of its digest, that the same text hashes to the same digest (`true`), and that a different text does not (`false`). The cell's answer is what the run prints, on every target; it says nothing about how std's function is written. The decision is about the other record of this program, the wasm codegen snapshot in compiler-core: there `contentHash` appears as one line naming it with the hash of its bytes, its body omitted, while the module the program compiles to — the one that ran here — stays complete. The run proves the behaviour; std's own tests prove the implementation.

[draft/main.bp](draft/main.bp)
