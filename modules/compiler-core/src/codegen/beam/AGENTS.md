# compiler-core/src/codegen/beam

> Path: `modules/compiler-core/src/codegen/beam/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

The BEAM term data model, the Erlang code model, and the emitters that render
them. Everything that writes an Erlang *value*, *name* or *code* for the BEAM VM
goes through here, so the `.erl` backend, the `.S` backend and the comptime
evaluators share one set of lexical and layout rules.

## Tree

```text
beam/
├── AGENTS.md          ← you are here
├── term.zig           ← `Term` — the value model (atom/binary/integer/float/boolean/nil/list/tuple/map)
├── erl_ast.zig        ← Erlang code model (expressions, clauses, functions, forms) + `Builder`
├── erl_emitter.zig    ← Term + names + erl_ast → Erlang source
└── beam_emitter.zig   ← Term → BEAM asm (`.S`) operands / instructions
```

## Files

| File | Role |
|---|---|
| `term.zig` | `Term` union + `Term.MapEntry { key: Term, value: Term }` and small constructors (`atomOf`, `str`, `int`, `listOf`, `tupleOf`, `mapOf`, `field`). Atoms hold the *unquoted* name; binaries hold raw runtime bytes. Terms borrow their slices — build them in an arena that outlives emission. |
| `erl_ast.zig` | Erlang code model. `Expr` (`raw`, `term`, `variable`, `atom`, `lexeme_binary`, `call` local/remote, `apply`, `binop`, `unop`, `match`, `tuple`, `list`, `cons`, `map`/`map_update` with `=>`/`:=`, `list_comp`, `case_` (`block` or one-line `inline_` layout), `fun`, `try_catch`, `bin` segments, `exception` `Class:Reason`, `number` (verbatim token), `paren`, `fun_clauses` (one-line multi-clause `fun`), `string` (character list), `fun_ref` (`fun f/N`), `list_block` (one element per line), `comment` (in expression position), `seq` (parts written back to back — host templates)), `Clause` (patterns, guard sequence, body, `block`/`inline_` layout), `Body` (statements, or a pre-rendered `raw_block`), `Stmt` (expr / comment), `Comment` (`level` `line`/`doc`/`module` → `%`/`%%`/`%%%`, text; `Comment.doc(text)`), `Function`, `FnRef` (`name/arity`), `Form` (`module`, `exports`, `no_auto_import`, attribute, function, comment, `blank`, raw). `raw` nodes are the migration bridge for Erlang still produced as text. `Builder` (arena, with `caseInline`/`applyParen`) copies slices and allocates child nodes for trees built from runtime values; `str`/`field`/`exactField` helpers. |
| `erl_emitter.zig` | Erlang source. **Names:** `isReserved`, `isUnquotedAtom`, `atomText(name, buf)` / `writeAtom` (bare when `[a-z][A-Za-z0-9_@]*` and not reserved, else single-quoted with `'`/`\` escaped; pre-quoted names pass through), `varName` / `writeVar` (`decl` → `Decl`), `moduleName` (`List` → `list`). **Binaries:** `writeBinaryFromBytes` (raw bytes; `"`, `\`, control bytes escaped, bytes ≥ 0x80 as `\x{HH}` so the binary is exact regardless of source encoding) and `writeBinaryFromLexeme` (a string literal's lexer content: botopink escapes map to Erlang's, `\$` → `$`, `\u{…}` → `\x{…}`, raw bytes pass through — the historical `erlang.zig` `emitBinary`). **Terms:** `writeFloat` (always has a `.`), `writeTerm` (lists `[a, b]`, tuples `{a, b}`, maps `#{k => v}`). **Code:** `writeExpr(w, expr, indent)` (multi-line constructs indent relative to `indent`: `case … of` clauses at +1 with block bodies at +2, `fun(…) ->` body at +1, `try`/`catch`), `writeBody` (the backend's statement rules: `,` only between real statements, comments without separator, empty body → `undefined`), `writeFunction` (clauses joined `;\n`, ending `.\n`), `writeForm`/`writeForms`; `writeString` for character lists; `writeComment` (prefix by level, one space, text). |
| `beam_emitter.zig` | `.S` operands for the same model: `writeOperand` (`atom` → `{atom, A}`, `boolean` → `{atom, true}`, `integer` → `{integer, N}`, `float` → `{float, F}`, `nil`/empty list → `nil`, binary/list/tuple/map → `{literal, <term>}`), `writeLiteral`, `writeAtomOperand`, `writeLexemeBinaryOperand`, `writeMove(term, dest)` (`    {move, <operand>, {x, D}}.\n`). The inner term syntax of `{literal, …}` is the Erlang source form, so it delegates to `erl_emitter`. |

## Consumers

- `../erlang.zig` — `atomName`/`fnAtom` = `atomText`, `erlangVar` = `varName`, `erlangModule` = `moduleName`, string literals via `writeBinaryFromLexeme`.
- `../beam_asm.zig` — `atomName` = `atomText`; string literals (`emitStringLiteral`), `{literal, #{}}`, `put_map_assoc` keys and atom `move`s via `beam_emitter`.
- `../erlang.zig` — `emitComptimeModule` helper functions (`comptime_helper_forms`) and host forms; function/lambda/branch bodies (`bodyNode`), expressions (`exprNode`) and calls (`callNode`) are nodes; declarations and the module header are forms (`emitErlangModule` renders them with `writeForms`).
- `../../comptime/decorator_eval.zig`, `../../comptime/template_eval.zig` — host glue and `main/0` as `Form`s built with `Builder`; the `@Decl` handle and captures are `Term`s.

## Rules

- One quoting rule for both backends. Reserved words (`end`, `of`, `div`, …) and
  non-lowercase names are always quoted — an unquoted `{atom, end}` or
  `{atom, HOST}` does not parse.
- Use `writeBinaryFromBytes` for runtime data (handles, comptime values) and
  `writeBinaryFromLexeme` only for string literal lexemes straight from the parser.
- Tests are inline in each file and aggregated by `../tests.zig`.
