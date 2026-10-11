# examples/

> Path: `examples/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

One project waiting to leave: `generic-loader-binding/` — the three ways `from "erika"` reaches a
library off disk (a bare value `of(xs)`, the bare template fn `erika "…"`, the namespace member
`erika.of(…)`), with `test {}` blocks. It shows a library, not the language, so it belongs in
`repository/erika/examples/` as a member of erika's workspace (144 B-29 step H, rule 10's consumer
commit). It cannot move yet: erika's gate runs every member on erlang too, and on erlang the
namespace-member form emits an unbound `Erika` variable (`erlc`: `variable 'Erika' is unbound`) —
a botopink-lang defect no gate saw while the example was only built on commonJS here. It moves
with the front that fixes that lowering.

The rest of what lived here is the conformance suite's since 144 B-29 step H (decisions 457, 461):
`hello.bp` → `conformance/modules/hello`, `modules/` → `conformance/modules/modules`,
`yamlconf/` → `conformance/modules/yamlconf` and `conformance/modules/yamlconf_unknown_label`,
`stdlib-tour/` → the project suite `conformance/test/stdlib-tour`.

## What checks it

`scripts/tsc-check.sh` builds it on commonJS with `--typescript` (its `.d.ts` through `tsc`, its
`.js` through `node --check`) and `scripts/format-check.sh` holds it canonical; its
`{ "git": … }` dependency on erika resolves by name to the sibling `repository/erika/`, so the
checkout needs that submodule.
