# Decision 1048 — A manifest refuses every key it does not know, in every object it reads, located at the key; a CLI behaviour a program cannot see is proven by its CLI script, never by a cell that cannot go red; answers 1013-b (1) (a), (2) (a), (3) (a).

A package whose `botopink.json` carries a key no object of the manifest reads — `"typings"` in the root or in the `wasm` host object, `"version"` in a dependency entry — is refused at the key, `manifest-unknown-field`, naming it; the program that loads it sees a `Diagnostic` with `file: botopink.json`, alike on all four targets. There is no list of removed fields: `typings` is one unknown key. The workspace object is proven by the manifest module's zig test, the duplicate-member refusal by `modules/compiler-cli/tests/workspace_out.sh`, the `.d.ts` beside each `.js` by `tests/cli_contract.sh`.

[cases/unknown_field_in_root/src/main.bp](cases/unknown_field_in_root/src/main.bp)
[cases/unknown_field_in_dependency/src/main.bp](cases/unknown_field_in_dependency/src/main.bp)
[cases/unknown_field_in_wasm_host/src/main.bp](cases/unknown_field_in_wasm_host/src/main.bp)
