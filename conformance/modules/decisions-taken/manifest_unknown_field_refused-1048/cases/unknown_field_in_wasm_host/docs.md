# unknown_field_in_wasm_host

The reference text this case shows (from `conformance/docs.md`, § The manifest schema — `botopink.json`):

> A manifest refuses every key it does not know, in every object it reads — the
> root, each `dependencies.<name>`, a workspace and the `wasm` host object —,
> located at the key: `error[manifest-unknown-field]: botopink.json has no field
> "typings"`. The file holds no editor metadata (`$schema` included). A program
> sees it as a `Diagnostic` with `file: botopink.json`, alike on all four targets.
