# docs/

> Path: `docs/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

User-facing reference documents that are not the language reference
([`../docs.md`](../docs.md) is that, and every `botopink` fence of it compiles
under `zig build test-docs`).

| File | What | Kept in sync with |
|---|---|---|
| `botopink-json.md` | The manifest schema: every field a tool reads, the package and the workspace forms, the dependency object, every located refusal with its message | [`../modules/manifest/src/root.zig`](../modules/manifest/AGENTS.md) — a field is documented only when a named parser reads it; a refusal is documented with the message a test shows |

Rules: English; a table row per field or refusal; no field that nothing reads.
