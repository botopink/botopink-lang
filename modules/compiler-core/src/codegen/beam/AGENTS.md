# compiler-core/src/codegen/beam

> Path: `modules/compiler-core/src/codegen/beam/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

The BEAM term data model and the two emitters that render it. Everything that
writes an Erlang *value* or *name* for the BEAM VM goes through here, so the
`.erl` backend, the `.S` backend and the comptime evaluators share one set of
lexical rules.

## Tree

```text
beam/
├── AGENTS.md          ← you are here
├── term.zig           ← `Term` — the value model (atom/binary/integer/float/boolean/nil/list/tuple/map)
├── erl_emitter.zig    ← Term + names → Erlang source
└── beam_emitter.zig   ← Term → BEAM asm (`.S`) operands / instructions
```

## Files

| File | Role |
|---|---|
| `term.zig` | `Term` union + `Term.MapEntry { key: Term, value: Term }` and small constructors (`atomOf`, `str`, `int`, `listOf`, `tupleOf`, `mapOf`, `field`). Atoms hold the *unquoted* name; binaries hold raw runtime bytes. Terms borrow their slices — build them in an arena that outlives emission. |
| `erl_emitter.zig` | Erlang source. **Names:** `isReserved`, `isUnquotedAtom`, `atomText(name, buf)` / `writeAtom` (bare when `[a-z][A-Za-z0-9_@]*` and not reserved, else single-quoted with `'`/`\` escaped; pre-quoted names pass through), `varName` / `writeVar` (`decl` → `Decl`), `moduleName` (`List` → `list`). **Binaries:** `writeBinaryFromBytes` (raw bytes; `"`, `\`, control bytes escaped, bytes ≥ 0x80 as `\x{HH}` so the binary is exact regardless of source encoding) and `writeBinaryFromLexeme` (a string literal's lexer content: botopink escapes map to Erlang's, `\$` → `$`, `\u{…}` → `\x{…}`, raw bytes pass through — the historical `erlang.zig` `emitBinary`). **Terms:** `writeFloat` (always has a `.`), `writeTerm` (lists `[a, b]`, tuples `{a, b}`, maps `#{k => v}`). |
| `beam_emitter.zig` | `.S` operands for the same model: `writeOperand` (`atom` → `{atom, A}`, `boolean` → `{atom, true}`, `integer` → `{integer, N}`, `float` → `{float, F}`, `nil`/empty list → `nil`, binary/list/tuple/map → `{literal, <term>}`), `writeLiteral`, `writeAtomOperand`, `writeLexemeBinaryOperand`, `writeMove(term, dest)` (`    {move, <operand>, {x, D}}.\n`). The inner term syntax of `{literal, …}` is the Erlang source form, so it delegates to `erl_emitter`. |

## Consumers

- `../erlang.zig` — `atomName`/`fnAtom` = `atomText`, `erlangVar` = `varName`, `erlangModule` = `moduleName`, string literals via `writeBinaryFromLexeme`.
- `../beam_asm.zig` — `atomName` = `atomText`; string literals (`emitStringLiteral`), `{literal, #{}}`, `put_map_assoc` keys and atom `move`s via `beam_emitter`.
- `../../comptime/decorator_eval.zig` — the `@Decl` handle is built as a `Term` (`handleToTerm`) and written with `writeTerm`.

## Rules

- One quoting rule for both backends. Reserved words (`end`, `of`, `div`, …) and
  non-lowercase names are always quoted — an unquoted `{atom, end}` or
  `{atom, HOST}` does not parse.
- Use `writeBinaryFromBytes` for runtime data (handles, comptime values) and
  `writeBinaryFromLexeme` only for string literal lexemes straight from the parser.
- Tests are inline in each file and aggregated by `../tests.zig`.
