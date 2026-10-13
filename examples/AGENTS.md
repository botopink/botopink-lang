# examples/

> Path: `examples/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

One project waiting to leave: `generic-loader-binding/` — the three ways `from "erika"` reaches a
library off disk (a bare value `of(xs)`, the bare template fn `erika "…"`, the namespace member
`erika.of(…)`), with `test {}` blocks. It shows a library, not the language, so it belongs in
`repository/erika/examples/` as a member of erika's workspace (144 B-29 step H, rule 10's consumer
commit). It is no longer held by botopink-lang on erlang or beam: the namespace-member form
`erika.of(…)` reaches the library on both since 144 B-45 and B-50 (`conformance/modules/default_handle_member`),
and its three tests pass there as on commonJS. On wasm it does not compile — the wasm backend cannot
resolve `.join("-")` on the `toArray()` of an erika `Query` (`join/1`) — and erika's manifest names no
`"targets"`, so its gate would run the member there too. It moves with erika's consumer commit once that
lowering is fixed or the member's manifest is narrowed; this repository never edits erika.

The rest of what lived here is the conformance suite's since 144 B-29 step H (decisions 457, 461):
`hello.bp` → `conformance/modules/hello`, `modules/` → `conformance/modules/modules`,
`yamlconf/` → `conformance/modules/yamlconf` and `conformance/modules/yamlconf_unknown_label`,
`stdlib-tour/` → the project suite `conformance/test/stdlib-tour`.

## What checks it

`scripts/tsc-check.sh` builds it on commonJS with `--typescript` (its `.d.ts` through `tsc`, its
`.js` through `node --check`) and `scripts/format-check.sh` holds it canonical; its
`{ "git": … }` dependency on erika resolves by name to the sibling `repository/erika/`, so the
checkout needs that submodule.
