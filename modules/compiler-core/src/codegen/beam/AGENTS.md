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
| `erl_ast.zig` | Erlang code model. `Expr` (`raw`, `term`, `variable`, `atom`, `lexeme_binary`, `call` local/remote, `apply`, `binop`, `unop`, `match`, `tuple`, `list`, `cons`, `map`/`map_update` with `=>`/`:=`, `list_comp`, `case_` (`block` or one-line `inline_` layout), `fun` (optionally NAMED — `fun Loop(I) -> … end`, how an unbounded loop recurses), `try_catch`, `bin` segments, `exception` `Class:Reason`, `number` (verbatim token), `paren`, `fun_clauses` (one-line multi-clause `fun`), `string` (character list), `fun_ref` (`fun f/N`), `list_block` (one element per line), `comment` (in expression position), `seq` (parts written back to back — host templates)), `Clause` (patterns, guard sequence, body, `block`/`inline_` layout), `Body` (statements), `Stmt` (expr / comment), `Comment` (`level` `line`/`doc`/`module` → `%`/`%%`/`%%%`, text; `Comment.doc(text)`), `Function`, `FnRef` (`name/arity`), `Form` (`module`, `exports`, `import` (`Import{module, funs}` → `-import(m, [f/1])`, how a comptime module reaches the resident prelude), `no_auto_import`, function, comment, `blank`). `raw` carries host template text only (see Rules). `Builder` (arena, with `caseInline`/`applyParen`) copies slices and allocates child nodes for trees built from runtime values; `str`/`field`/`exactField` helpers. |
| `erl_emitter.zig` | Erlang source. **Names:** `isReserved`, `isUnquotedAtom`, `atomText(name, buf)` / `writeAtom` (bare when `[a-z][A-Za-z0-9_@]*` and not reserved, else single-quoted with `'`/`\` escaped; pre-quoted names pass through), `varName` / `writeVar` (`decl` → `Decl`), `moduleName` (`List` → `list`). **Binaries:** `writeBinaryFromBytes` (raw bytes; `"`, `\`, control bytes escaped, bytes ≥ 0x80 as `\x{HH}` so the binary is exact regardless of source encoding) and `writeBinaryFromLexeme` (a string literal's lexer content: botopink escapes map to Erlang's, `\$` → `$`, `\u{…}` → `\x{…}`, raw bytes pass through — the historical `erlang.zig` `emitBinary`); both delegate the escaping to `writeString`/`writeStringFromLexeme`, which a `bin` segment reuses — a binary-literal segment of a binary construction is written as the plain string it holds (`<<"a", X/binary>>`), never as a nested `<<<<"a">>/binary, …>>`. **Terms:** `writeFloat` (always has a `.`), `writeTerm` (lists `[a, b]`, tuples `{a, b}`, maps `#{k => v}`). **Code:** `writeExpr(w, expr, indent)` (multi-line constructs indent relative to `indent`: `case … of` clauses at +1 with block bodies at +2, `fun(…) ->` body at +1, `try`/`catch`), `writeBody` (the backend's statement rules: `,` only between real statements, comments without separator, empty body → `undefined`), `writeFunction` (clauses joined `;\n`, ending `.\n`), `writeForm`/`writeForms`; `writeString` for character lists; `writeComment` (prefix by level, one space, text). |
| `beam_emitter.zig` | `.S` operands **and instructions**. *Operands:* `Operand` (`.x`/`.y` registers, `.f` label, `.term`, `.lexeme`, `.untagged` bare int, `.number` source-token numeric) with constructors `xr`/`yr`/`lbl`/`atom`/`int`/`str`/`num`/`negNum`/`nil`; `Dest` (`.x`/`.y`); `writeArg`, plus the term-level `writeOperand` (`atom` -> `{atom, A}`, `boolean` -> `{atom, true}`, `integer` -> `{integer, N}`, `float` -> `{float, F}`, `nil`/empty list -> `nil`, binary/list/tuple/map -> `{literal, <term>}`), `writeLiteral`, `writeAtomOperand`, `writeLexemeBinaryOperand`. *Selectors:* `TestOp` (`is_list`/`is_float`/`is_boolean` added for the run-time primitive dispatch shim `beam_asm.zig` synthesises), `GcBif` (`div_` is `'div'`, `fdiv` is float `'/'`), `Callee` (`.local` label / `.ext` module+function), `CallKind` (`normal`/`last`/`only`). *Module preamble:* `Export` (`name`, `arity`), `writeModuleForm` (`{module, M}.`), `writeExports` (`{exports, [{Name, Arity}, …]}.`, shared atom quoting per name), `writeAttributes` (`{attributes, []}.`), `writeLabels` (`{labels, N}.`). *Instructions* (each writes one full line, indentation and trailing `.` included): `writeMove`/`writeMoveOp`, `writeLabel`, `writeJump`, `writeReturn`, `writeAllocate`, `writeDeallocate`, `writeInitYregs`, `writeTest`, `writeTestHeap`, `writeTestHeapAlloc`, `writeGcBif`, `writeCall`, `writeCallFun`, `writeMakeFun3` (with the closure environment operands), `writeBif` (a non-allocating guard BIF such as `element/2`), `writeTry`/`writeTryEnd`/`writeTryCase` (a catch section), `writePutList`, `writePutTuple2`, `writeGetTupleElement`, `writeGetList`, `writeGetMapElements`, `writePutMap` (+`MapPair`), `writeFunctionHeader`, `writeFuncInfo`, `writeLine`, `writeBlankLine`, `writeComment`/`writeTopComment`/`writeSourceComment`. The inner term syntax of `{literal, ...}` is the Erlang source form, so it delegates to `erl_emitter`. |

## Consumers

- `../erlang.zig` — `varName` (spelled into the module arena by `versionedVar`), `erlangModule` = `moduleName`; atoms are quoted by `writeAtom` when rendered; string literals via `writeBinaryFromLexeme`.
- `../beam_asm.zig` — `atomName` = `atomText`; **every** `.S` line it writes goes
  through `beam_emitter`, the module preamble included (`emitBeamAsm` renders it
  with `writeModuleForm`/`writeExports`/`writeAttributes`/`writeLabels` and joins
  the rendered sections with `std.mem.concat`), so it has no `print`/`writeAll`
  of target syntax of its own.
  **The single documented exception** is `renderBeamTemplate`'s three writer
  calls (the `Ctx.writeByte`/`Ctx.writeAll` the shared `primOpTemplate` walker
  drives, plus the trailing `writeByte('\n')`): a `#[@External.Beam("""…""")]`
  template body is genuine host `.S` the library author wrote, so it is spliced
  verbatim — only its receiver/`$N`/`$args` substitutions are rendered, with
  `writeArg`. `rg -n '\.(print|writeAll|writeByte)\(' ../beam_asm.zig` must
  return exactly those three.
- `../erlang.zig` — `emitComptimeModule` helper functions (`comptime_helper_forms`) and host forms; function/lambda/branch bodies (`bodyNode`), expressions (`exprNode`) and calls (`callNode`) are nodes; declarations and the module header are forms (`emitErlangModule` renders them with `writeForms`).
- `../../comptime/decorator_eval.zig`, `../../comptime/template_eval.zig` — `main/0` as a `Form` built with `Builder`; the `@Decl` handle and captures are `Term`s.
- `../../comptime/runtime/prelude.zig` — the resident host glue as `Form`s, rendered to Erlang source with `writeForms`; the generated module reaches it through a `Form.import`.

## Run-time evaluation of `@External.Erlang` templates (open decision)

`../beam_asm.zig` lowers a host-backed call three ways. An
`#[@External.Beam("""…""")]` body is `.S` spliced at the call site
(`renderBeamTemplate`), and an `#[@External.Erlang("mod", "sym")]` pair is a
plain `call_ext`. An `#[@External.Erlang("…")]` **template** — Erlang *source*
with receiver/`$N`/`$stringify(…)` holes (`"base64:encode($0)"`, the arity-branch
form, a primitive method's template reached through `primErlangTemplate`) —
has no `.S` form, so it is **evaluated at run time** (`evalTemplate`):

- at build time the holes become variables (the receiver → `__BpSelf`, `$N` →
  `__BpAN`, `$stringify(e)` → `iolist_to_binary(io_lib:format("~p", [e]))`) and
  the text, ended with `.`, is a binary literal operand;
- at the call site the operands are staged into a bindings map
  (`put_map_assoc`, `#{'__BpSelf' => Recv, '__BpA0' => A0, …}`) and the
  module-local `'__bp_erl_eval'(Source, Bindings)` is called — synthesised once
  per module by `ensureEvalHelper`: `binary_to_list` → `erl_scan:string` →
  `erl_parse:parse_exprs` → `erl_eval:exprs`, the value of the last expression;
  a step that does not answer `{ok, …}`/`{value, …}` raises its answer with
  `erlang:error/1`.

It is correct — the ten beam snapshots that reach it print what erlang prints
(`string_slice_*`, `external_a2_*`, `external_a3_result_template_owned_declare_fn`,
`external_1_arg_host_expression_…`, `bool_instance_default_fn_methods`,
`array_zip_via_external_node_template`, `string_methods_map_to_native_js_names`).
**Its cost:**

- **Speed.** Every call re-scans, re-parses and *interprets* the template;
  nothing is cached. Measured on OTP (2026-09-17, 100 000 calls each):
  `base64:encode(X)` direct ≈ 0.1 µs/call, through the eval path ≈ 5.2 µs/call
  (≈ 50×); a `string:slice($0, $1, $2 - $1)` template ≈ 6.9 µs/call. In a
  loop over a list (`String.slice` per element) that dominates the run time.
- **Errors surface late.** A template that does not scan or parse, or names an
  undefined function, compiles cleanly and fails only when the call runs, as
  `erlang:error({error, …})` from inside the helper, not as a located build
  error.
- **Code size and dependencies.** Each call site carries its template as a
  binary literal plus a map build; the module depends on `erl_scan`,
  `erl_parse` and `erl_eval` (stdlib, always present on a BEAM node).

**Open for the maintainer (1.0.4-beta 01 BR4):** keep it as written here, or
ask for build-time compilation of the template — lower the template text to
code once, at build time (for example through the erlang backend's template
lowering into a helper function or aux module assembled next to the `.S`), so a
call is a local/remote call with no interpretation. The second answer becomes a
row in `specs/1.0.4-beta/01-backend-residuals/`.

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
- **`erl_ast.Expr.raw` has exactly one producer**: `erlang.zig`'s `templateNode`,
  for the text of a host template — an `#[@External.Erlang("…")]` body (or a
  primitive/builtin annotation) written by the program or library author, which
  the compiler has no business restructuring; the receiver/argument holes around
  it are real nodes (`seq`). Everything the compiler itself decides — calls,
  heads, the `$stringify(…)` wrap, missing values — is a node. Do not add a
  second `raw`: a value `raw("")` rendered as nothing and produced modules that
  did not compile, and a pre-spelled call head skipped atom quoting.
- Use `writeBinaryFromBytes` for runtime data (handles, comptime values) and
  `writeBinaryFromLexeme` only for string literal lexemes straight from the parser.
- Tests are inline in each file and aggregated by `../tests.zig`.
