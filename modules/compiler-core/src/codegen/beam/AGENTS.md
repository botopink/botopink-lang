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
| `erl_ast.zig` | Erlang code model. `Expr` (`raw`, `term`, `variable`, `atom`, `lexeme_binary`, `call` local/remote, `apply`, `binop`, `unop`, `match`, `tuple`, `list`, `cons`, `map`/`map_update` with `=>`/`:=`, `list_comp`, `case_` (`block` or one-line `inline_` layout), `fun` (optionally NAMED — `fun Loop(I) -> … end`, how an unbounded loop recurses), `try_catch`, `bin` segments, `exception` `Class:Reason`, `number` (verbatim token), `paren`, `fun_clauses` (one-line multi-clause `fun`), `string` (character list), `fun_ref` (`fun f/N`), `list_block` (one element per line), `comment` (in expression position), `seq` (parts written back to back — host templates)), `Clause` (patterns, guard sequence, body, `block`/`inline_` layout), `Body` (statements, or a pre-rendered `raw_block`), `Stmt` (expr / comment), `Comment` (`level` `line`/`doc`/`module` → `%`/`%%`/`%%%`, text; `Comment.doc(text)`), `Function`, `FnRef` (`name/arity`), `Form` (`module`, `exports`, `no_auto_import`, attribute, function, comment, `blank`, raw). `raw` nodes are the migration bridge for Erlang still produced as text. `Builder` (arena, with `caseInline`/`applyParen`) copies slices and allocates child nodes for trees built from runtime values; `str`/`field`/`exactField` helpers. |
| `erl_emitter.zig` | Erlang source. **Names:** `isReserved`, `isUnquotedAtom`, `atomText(name, buf)` / `writeAtom` (bare when `[a-z][A-Za-z0-9_@]*` and not reserved, else single-quoted with `'`/`\` escaped; pre-quoted names pass through), `varName` / `writeVar` (`decl` → `Decl`), `moduleName` (`List` → `list`). **Binaries:** `writeBinaryFromBytes` (raw bytes; `"`, `\`, control bytes escaped, bytes ≥ 0x80 as `\x{HH}` so the binary is exact regardless of source encoding) and `writeBinaryFromLexeme` (a string literal's lexer content: botopink escapes map to Erlang's, `\$` → `$`, `\u{…}` → `\x{…}`, raw bytes pass through — the historical `erlang.zig` `emitBinary`); both delegate the escaping to `writeString`/`writeStringFromLexeme`, which a `bin` segment reuses — a binary-literal segment of a binary construction is written as the plain string it holds (`<<"a", X/binary>>`), never as a nested `<<<<"a">>/binary, …>>`. **Terms:** `writeFloat` (always has a `.`), `writeTerm` (lists `[a, b]`, tuples `{a, b}`, maps `#{k => v}`). **Code:** `writeExpr(w, expr, indent)` (multi-line constructs indent relative to `indent`: `case … of` clauses at +1 with block bodies at +2, `fun(…) ->` body at +1, `try`/`catch`), `writeBody` (the backend's statement rules: `,` only between real statements, comments without separator, empty body → `undefined`), `writeFunction` (clauses joined `;\n`, ending `.\n`), `writeForm`/`writeForms`; `writeString` for character lists; `writeComment` (prefix by level, one space, text). |
| `beam_emitter.zig` | `.S` operands **and instructions**. *Operands:* `Operand` (`.x`/`.y` registers, `.f` label, `.term`, `.lexeme`, `.untagged` bare int, `.number` source-token numeric) with constructors `xr`/`yr`/`lbl`/`atom`/`int`/`str`/`num`/`negNum`/`nil`; `Dest` (`.x`/`.y`); `writeArg`, plus the term-level `writeOperand` (`atom` -> `{atom, A}`, `boolean` -> `{atom, true}`, `integer` -> `{integer, N}`, `float` -> `{float, F}`, `nil`/empty list -> `nil`, binary/list/tuple/map -> `{literal, <term>}`), `writeLiteral`, `writeAtomOperand`, `writeLexemeBinaryOperand`. *Selectors:* `TestOp`, `GcBif`, `Callee` (`.local` label / `.ext` module+function), `CallKind` (`normal`/`last`/`only`). *Module preamble:* `Export` (`name`, `arity`), `writeModuleForm` (`{module, M}.`), `writeExports` (`{exports, [{Name, Arity}, …]}.`, shared atom quoting per name), `writeAttributes` (`{attributes, []}.`), `writeLabels` (`{labels, N}.`). *Instructions* (each writes one full line, indentation and trailing `.` included): `writeMove`/`writeMoveOp`, `writeLabel`, `writeJump`, `writeReturn`, `writeAllocate`, `writeDeallocate`, `writeInitYregs`, `writeTest`, `writeTestHeap`, `writeTestHeapAlloc`, `writeGcBif`, `writeCall`, `writeCallFun`, `writeMakeFun3`, `writePutList`, `writePutTuple2`, `writeGetTupleElement`, `writeGetList`, `writeGetMapElements`, `writePutMap` (+`MapPair`), `writeFunctionHeader`, `writeFuncInfo`, `writeLine`, `writeBlankLine`, `writeComment`/`writeTopComment`/`writeSourceComment`. The inner term syntax of `{literal, ...}` is the Erlang source form, so it delegates to `erl_emitter`. |

## Consumers

- `../erlang.zig` — `atomName`/`fnAtom` = `atomText`, `erlangVar` = `varName`, `erlangModule` = `moduleName`, string literals via `writeBinaryFromLexeme`.
- `../beam_asm.zig` — `atomName` = `atomText`; **every** `.S` line it writes goes
  through `beam_emitter`, the module preamble included (`emitBeamAsm` renders it
  with `writeModuleForm`/`writeExports`/`writeAttributes`/`writeLabels` and joins
  the rendered sections with `std.mem.concat`), so it has no `print`/`writeAll`
  of target syntax of its own.
  **The single documented exception** is `renderBeamTemplate`'s three writer
  calls (the `Ctx.writeByte`/`Ctx.writeAll` the shared `primOpTemplate` walker
  drives, plus the trailing `writeByte('\n')`): a `#[@External.Beam("""…""")]`
  template body is genuine host `.S` the library author wrote, so it is spliced
  verbatim — only its `$self`/`$N`/`$args` substitutions are rendered, with
  `writeArg`. `rg -n '\.(print|writeAll|writeByte)\(' ../beam_asm.zig` must
  return exactly those three.
- `../erlang.zig` — `emitComptimeModule` helper functions (`comptime_helper_forms`) and host forms; function/lambda/branch bodies (`bodyNode`), expressions (`exprNode`) and calls (`callNode`) are nodes; declarations and the module header are forms (`emitErlangModule` renders them with `writeForms`).
- `../../comptime/decorator_eval.zig`, `../../comptime/template_eval.zig` — host glue and `main/0` as `Form`s built with `Builder`; the `@Decl` handle and captures are `Term`s.

## Rules

- **The backend builds, the emitter renders.** `beam_asm.zig` owns register
  allocation, live counts, label numbering and every lowering decision; this
  directory owns how those decisions are spelled — operand shape, atom quoting,
  literal wrapping, indentation, the trailing `.`. A backend that formats target
  text itself is how a raw node slipped into a tuple and how template escapes
  leaked, so the instruction functions take `Operand`/`Dest`/`TestOp`/`GcBif`/
  `Callee`, never a preformatted string. When an instruction is missing, add it
  here rather than printing it at the call site.
- A numeric literal travels as `Operand.num(token)` — its *source token*, so
  `1.70` and `1e3` reach the `.S` unchanged instead of round-tripping through an
  `f64`.
- A BEAM `Live` count is a prefix over `x0..x_{Live-1}`; the emitter takes it as a
  number and never checks it. Deciding it — and keeping every register in that
  range written — is the backend's job.
- One quoting rule for both backends. Reserved words (`end`, `of`, `div`, …) and
  non-lowercase names are always quoted — an unquoted `{atom, end}` or
  `{atom, HOST}` does not parse.
- Use `writeBinaryFromBytes` for runtime data (handles, comptime values) and
  `writeBinaryFromLexeme` only for string literal lexemes straight from the parser.
- Tests are inline in each file and aggregated by `../tests.zig`.
