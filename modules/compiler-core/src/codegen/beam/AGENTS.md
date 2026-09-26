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
├── beam_emitter.zig   ← Term → BEAM asm (`.S`) operands / instructions
├── beam_file.zig      ← instruction model → `.beam` bytes (the container `code:load_binary/3` loads), no `erlc`
├── asm_text.zig       ← the same instruction model → `.S` text (the `COMPTIME BEAM ASSEMBLY` listing)
├── opcodes.zig        ← GENERATED: the BEAM opcode table pinned to OTP 28 (decision 86); `Op`, `Info`, `emittable`
└── gen_opcodes.sh     ← regenerates `opcodes.zig` from OTP's `genop.tab`, cross-checked against the installed `beam_opcodes`
```

## Files

| File | Role |
|---|---|
| `term.zig` | `Term` union + `Term.MapEntry { key: Term, value: Term }` and small constructors (`atomOf`, `str`, `int`, `listOf`, `tupleOf`, `mapOf`, `field`). Atoms hold the *unquoted* name; binaries hold raw runtime bytes. Terms borrow their slices — build them in an arena that outlives emission. |
| `erl_ast.zig` | Erlang code model. `Expr` (`raw`, `term`, `variable`, `atom`, `lexeme_binary`, `call` local/remote, `apply`, `binop`, `unop`, `match`, `tuple`, `list`, `cons`, `map`/`map_update` with `=>`/`:=`, `list_comp`, `case_` (`block` or one-line `inline_` layout), `fun` (optionally NAMED — `fun Loop(I) -> … end`, how an unbounded loop recurses), `try_catch`, `bin` segments, `exception` `Class:Reason`, `number` (verbatim token), `paren`, `fun_clauses` (one-line multi-clause `fun`), `string` (character list), `fun_ref` (`fun f/N`), `list_block` (one element per line), `comment` (in expression position), `seq` (parts written back to back — host templates)), `Clause` (patterns, guard sequence, body, `block`/`inline_` layout), `Body` (statements), `Stmt` (expr / comment), `Comment` (`level` `line`/`doc`/`module` → `%`/`%%`/`%%%`, text; `Comment.doc(text)`), `Function`, `FnRef` (`name/arity`), `Form` (`module`, `exports`, `import` (`Import{module, funs}` → `-import(m, [f/1])`, how a comptime module reaches the resident prelude), `no_auto_import`, `on_load` (`-on_load(f/0).`, front 17 — where a `PersistentTerm` var is put), function, comment, `blank`). `raw` carries host template text only (see Rules). `Builder` (arena, with `caseInline`/`applyParen`) copies slices and allocates child nodes for trees built from runtime values; `str`/`field`/`exactField` helpers. |
| `erl_emitter.zig` | Erlang source. **Names:** `isReserved`, `isUnquotedAtom`, `atomText(name, buf)` / `writeAtom` (bare when `[a-z][A-Za-z0-9_@]*` and not reserved, else single-quoted with `'`/`\` escaped; pre-quoted names pass through), `varName` / `writeVar` (`decl` → `Decl`), `moduleName` (`List` → `list`). **Binaries:** `writeBinaryFromBytes` (raw bytes; `"`, `\`, control bytes escaped, bytes ≥ 0x80 as `\x{HH}` so the binary is exact regardless of source encoding) and `writeBinaryFromLexeme` (a string literal's lexer content: botopink escapes map to Erlang's, `\$` → `$`, `\u{…}` → its UTF-8 bytes each as `\x{HH}`, and a raw byte ≥ 0x80 → `\x{HH}` — a plain `<<"…">>` keeps only the low 8 bits of a character, so `\x{2028}` was `<<40>>` and a raw `ç` one latin1 byte; the historical `erlang.zig` `emitBinary`); both delegate the escaping to `writeString`/`writeStringFromLexeme`, which a `bin` segment reuses — a binary-literal segment of a binary construction is written as the plain string it holds (`<<"a", X/binary>>`), never as a nested `<<<<"a">>/binary, …>>`. **Terms:** `writeFloat` (always has a `.`), `writeTerm` (lists `[a, b]`, tuples `{a, b}`, maps `#{k => v}`). **Code:** `writeExpr(w, expr, indent)` (multi-line constructs indent relative to `indent`: `case … of` clauses at +1 with block bodies at +2, `fun(…) ->` body at +1, `try`/`catch`), `writeBody` (the backend's statement rules: `,` only between real statements, comments without separator, empty body → `undefined`), `writeFunction` (clauses joined `;\n`, ending `.\n`), `writeForm`/`writeForms`; `writeString` for character lists; `writeComment` (prefix by level, one space, text). |
| `beam_emitter.zig` | `.S` operands **and instructions**. *Operands:* `Operand` (`.x`/`.y` registers, `.f` label, `.term`, `.lexeme`, `.untagged` bare int, `.number` source-token numeric) with constructors `xr`/`yr`/`lbl`/`atom`/`int`/`str`/`num`/`negNum`/`nil`; `Dest` (`.x`/`.y`); `writeArg`, plus the term-level `writeOperand` (`atom` -> `{atom, A}`, `boolean` -> `{atom, true}`, `integer` -> `{integer, N}`, `float` -> `{float, F}`, `nil`/empty list -> `nil`, binary/list/tuple/map -> `{literal, <term>}`), `writeLiteral`, `writeAtomOperand`, `writeLexemeBinaryOperand`. *Selectors:* `TestOp` (`is_list`/`is_float`/`is_boolean` added for the run-time primitive dispatch shim `beam_asm.zig` synthesises; `is_number` and `is_ne` for decision 8 §4.1 / §2.3, `is_pid` for the `Ets` owner's wait loop), `GcBif` (`div_` is `'div'`, `fdiv` is float `'/'`, `trunc`/`float` the §4.1 conversions), `Callee` (`.local` label / `.ext` module+function), `CallKind` (`normal`/`last`/`only`). *Module preamble:* `Export` (`name`, `arity`), `writeModuleForm` (`{module, M}.`), `writeExports` (`{exports, [{Name, Arity}, …]}.`, shared atom quoting per name), `writeAttributes` (`{attributes, []}.`), `writeOnLoadAttributes` (`{attributes, [{on_load, [{F, 0}]}]}.`, front 17), `writeLabels` (`{labels, N}.`). *Instructions* (each writes one full line, indentation and trailing `.` included): `writeMove`/`writeMoveOp`, `writeLabel`, `writeJump`, `writeReturn`, `writeAllocate`, `writeDeallocate`, `writeInitYregs`, `writeTest`, `writeTestHeap`, `writeTestHeapAlloc`, `writeGcBif`, `writeCall`, `writeCallFun`, `writeMakeFun3` (with the closure environment operands), `writeBif` (a non-allocating guard BIF such as `element/2`), `writeTry`/`writeTryEnd`/`writeTryCase` (a catch section), `writePutList`, `writePutTuple2`, `writeGetTupleElement`, `writeGetList`, `writeGetMapElements`, `writePutMap` (+`MapPair`), `writeFunctionHeader`, `writeFuncInfo`, `writeLine`, `writeBlankLine`, `writeComment`/`writeTopComment`/`writeSourceComment`. The inner term syntax of `{literal, ...}` is the Erlang source form, so it delegates to `erl_emitter`. |
| `beam_file.zig` | **The `.beam` container writer** (front 18 step 1a, decisions 83/86). Input: `Module { name, functions, source_file }` → `Function { name, arity, entry, exported, code }` → `Instr { op: Op, args }` → `Arg` (`u` bare unsigned, `i` integer, `atom`, `nil`, `x`/`y`/`f`, `literal: Term`, `ext: ExtFunc` `{extfunc, M, F, A}`, `list`, `alloc`, `line`) — one variant per compact-term operand kind of `beam_asm.erl`'s `encode_arg/2`, so the adapter from `beam_emitter`'s `Operand`/`Dest`/`TestOp`/`GcBif`/`Callee` (step 1c's untyped `beam_asm.zig` mode, not written yet) is a mapping (`## Adapter` in the file header). `assemble(alloc, module)` → bytes: `FOR1`/`BEAM` with `AtU8` (module atom at index 1, first-insertion order), `Code` (16-byte sub-header; `label_count` = highest label + 1; `function_count`; the stream closed by `int_code_end`), `StrT` (empty), `ImpT` (first-use `(M, F, A)` rows — `Arg.ext` encodes the row index), `ExpT` (exported functions with entry labels), `FunT` (only when `make_fun3` is used: its first operand is the fun's **entry label**, resolved here to the row index; `old_uniq` = 27 bits of a Wyhash of the code), `LitT` (only when a compound literal exists; ETF via `comptime/runtime/etf.zig`, deduplicated by bytes, framed as a **zlib stream of stored blocks** — valid on every OTP, where OTP 28's own uncompressed-behind-a-zero-word form is 28+ only), `Line` (one item per distinct `(file, line)`; `source_file` is fname 1 so a stack trace's `{file, …}` names the `.bp`). **`{f, N}` is the label number** — the loader resolves labels, nothing is patched. **`opcode_max` in the `Code` header is a version stamp**: the loader refuses `< swap` (169) as "compiled for an old version", so the writer stamps `opcodes.opcode_max` (184, OTP 28) whatever the module uses — a VM below decision 86's floor refuses it with the loader's own "compiled for a later version" message. Refusals (`Error`): `OpcodeNotEmittable` (obsolete, or newer than OTP 24), `ArityMismatch` (operand count ≠ `genop.tab` arity), `UndefinedLabel`, `DuplicateLabel`, `EntryIsNotALabel`, `FunEntryIsNotAFunction`, `InvalidAtom` (empty or > 255 bytes), `LineOperand`, `NoFunctions`. No `beam_validator` pass: a register misuse the loader accepts is a run-time crash of the body. Tests: compact-term byte vectors read off `beam_asm:encode/2`; a stored zlib stream's adler32; and three `erl -noshell -eval` round trips — `-module(t). main() -> ok.` through `beam_lib:info/1` + `beam_lib:chunks/2` (`atoms`, `imports`, `labeled_exports`) + `code:load_binary/3` + `t:main()`; a module with a `<<"hello">>` literal, `erlang:'+'/2` (`gc_bif2`) and `erlang:error/1` (`call_ext_only`) imports and a `Line` chunk whose stack frame reads `{file,"t2.bp"},{line,7}`; and three one-byte flips (form id → `beam_lib:info` refuses; `AtU8` id → `beam_lib` refuses; an opcode → `{error, badfile}`). The tests are reached through `comptime/runtime/persistent_beam.zig` (which imports this file) until `../tests.zig` lists them. |
| `asm_text.zig` | `writeModule(w, beam_file.Module)`: the model as BEAM assembly in the generic shapes `erlc -S` writes and `erlc +from_asm` reads (`{test, is_eq_exact, {f, L}, [A, B]}`, `{bif, Name, {f, L}, Args, Dst}`, `{gc_bif, Name, {f, L}, Live, Args, Dst}`, `{make_fun3, {f, L}, Index, 0, Dst, {list, Env}}`, `{'try', Y, {f, L}}`, `{literal, T}` with atoms/integers/`[]` folded and floats as `{float, F}` as the assembler folds them); an opcode it has no shape for is `error.UnrenderedOpcode`. It exists so one model has two renderers — the bytes the node loads and the listing a snapshot shows cannot describe different programs — and so `scripts/beam_export_audit.sh` can put the listing through `beam_validator`, which the load path does not run |
| `opcodes.zig` | **Generated** by `gen_opcodes.sh` from OTP-28.0's `lib/compiler/src/genop.tab` (`BEAM_FORMAT_NUMBER=0`, 184 opcodes): `otp_release = 28`, `format_number`, `opcode_max = 184`, `stable_floor = 24`; `Op` (one variant per opcode, valued by number — `@"return"`, `@"catch"`, `@"try"` are quoted), `Info { name, arity, since, obsolete }`, `table` indexed by number, `Op.info()`, `Op.emittable()` = decision 86's subset: not obsolete (`genop.tab`'s leading `-`) and `since <= 24` — **118** of 184. Tests: the table is dense and the enum agrees with it; `make_fun3`/`init_yregs`/`call_ext` in, `bs_create_bin`/`update_record`/`debug_line` (newer) and `allocate_zero`/`put_tuple`/`fclearerror` (obsolete) out. |
| `gen_opcodes.sh` | `bash gen_opcodes.sh [genop.tab]` — fetches the pinned tag's `genop.tab` when no path is given, parses `N: [-]name/arity` rows and the `# OTP NN` section markers (`since`), cross-checks every row against the installed `beam_opcodes:opname/1` (a disagreeing name/arity is a hard failure; opcodes only the installed release knows are listed and left out), writes `opcodes.zig` and runs `zig fmt` on it. Re-run only when the pin moves. |

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
  BR5's template helpers (`lowerTemplateFn`) are not an exception: their `.S`
  is `asm_text.writeModule`'s rendering of the `beam_file` model
  `comptime/runtime/beam/lower.zig` built, spliced function by function; the
  only text the backend assembles there is the helper's Erlang *source* for the
  reader.
- `../erlang.zig` — `emitComptimeModule` helper functions (`comptime_helper_forms`) and host forms; function/lambda/branch bodies (`bodyNode`), expressions (`exprNode`) and calls (`callNode`) are nodes; declarations and the module header are forms (`emitErlangModule` renders them with `writeForms`).
- `../../comptime/decorator_eval.zig`, `../../comptime/template_eval.zig` — `main/0` as a `Form` built with `Builder`; the `@Decl` handle and captures are `Term`s.
- `../../comptime/runtime/prelude.zig` — the resident host glue as `Form`s, rendered to Erlang source with `writeForms`; the generated module reaches it through a `Form.import`.
- `../../comptime/runtime/persistent_beam.zig` — `beam_file.assemble` output is what its cmd 4 loads (`evalBeamWithArg`); its inline test assembles `main(X) -> X.` with this model.
- `../../comptime/runtime/beam/` — the comptime lowering (below): builds `beam_file` modules, assembles them with `beam_file.assemble` and lists them with `asm_text.writeModule`.

## Comptime lowering (front 14 step 3, front 18 step 1b)

A template or decorator body reaches the resident node as `.beam` bytes built
in Zig — `../../comptime/runtime/beam/lower.zig` lowers the generated Erlang
module (as `../../comptime/runtime/wat/erl_parse.zig` reads it) to this
directory's instruction model — not as `.erl` source for `compile:file`. It is
**not** a mode of `../beam_asm.zig`: that backend lowers typed botopink; a
comptime body is untyped, and its meaning is already decided by `../erlang.zig`'s
untyped mode, which the wat runtime lowers too. So there is one lowering of the
body and three consumers of its Erlang, instead of a second lowering of every
comptime construct in `beam_asm.zig` (front 14 README, "the risk worth
naming").

**What it refuses, by name — a refusal is a compile error of that comptime
module naming the construct (`the BEAM runtime does not take …`), exactly as
the wat runtime refuses; there is no `.erl` fallback any more:** from the reader, `receive`, `maybe`, the old `catch Expr`,
records (`#name{…}`), macros (`?NAME`), `!`; from the lowering, `try … of`,
`try … after`, a call through a computed module or function name, a `fun`
with no clause, unary operators other than `-`/`not`/`bnot`, a map update or
a computed/unbound key in a pattern, a binary pattern other than literal bytes
plus an optional `Rest/binary` tail, a string `++` pattern with a non-literal
prefix, a binary segment that is sized (other than `integer:8`), `/float`, or
of any type but `binary`/`bytes`/`integer`/`utf8`, a binary generator other
than `<<C/utf8>>` / `<<B>>` over one segment, a guard expression that is not a
guard BIF, operator, variable or literal, a stack pattern that is not a
variable, a call to a function the module neither defines, imports nor
auto-imports (`erlc` refused it too). **Measured: none of these occurs in the
suite's or the libraries' comptime modules** (37
distinct modules — 17 template and 19 decorator bodies, plus the parity
divergence fixture — all lowered, 0 fallbacks; `zig build test`,
`tests/language/run.sh --target all`; 63 more — 61 decorator and 2 template
bodies — in `zig build test-libs`'s erlang cells, all lowered), nor in 377 of
389 modules on disk from
older builds of the libraries (the 12 refused are modules `erlc` rejects too:
undefined functions, unsafe variables, a `receive`).

## `@External.Erlang` templates compiled at build time (BR5, C-24)

`../beam_asm.zig` lowers a host-backed call three ways. An
`#[@External.Beam("""…""")]` body is `.S` spliced at the call site
(`renderBeamTemplate`), and an `#[@External.Erlang("mod", "sym")]` pair is a
plain `call_ext`. An `#[@External.Erlang("…")]` **template** — Erlang *source*
with receiver/`$N`/`$stringify(…)` holes (`"base64:encode($0)"`, the arity-branch
form, a primitive method's template reached through `primErlangTemplate`) — is
**compiled at build time** into a helper function of the module
(`evalTemplate` → `compiledTemplate` → `lowerTemplateFn`):

- the holes become the helper's parameters (the receiver → `__BpSelf`, `$N` →
  `__BpAN`, `$stringify(e)` → `iolist_to_binary(io_lib:format("~p", [e]))`) and
  the text is the body of `t(__BpSelf, __BpA0, …) -> <template>.`;
- that one-function module is read by `../../comptime/runtime/wat/erl_parse.zig`
  and lowered by `../../comptime/runtime/beam/lower.zig` — **the reader and the
  lowering the comptime BEAM runtime already runs every template and decorator
  body through** (front 14), so this compiler has one Erlang front end, not a
  second template language;
- the lowered `beam_file.Module` is relabelled into the module's label space
  (`L - 1 + next_label`, `{f, 0}` kept), its functions renamed `'__bp_tpl_<k>'`
  (lifted funs `'__bp_tpl_<k>-t/N-fun-M-'`), rendered by `asm_text.zig` and
  appended to the module; the call site stages its operands into `x0..` and
  `call`s it. One helper per distinct template text and arity per module
  (`template_fns`, set aside per type unit like the other helper caches).

**What still reaches `'__bp_erl_eval'/2`, and why:** a template the reader or
the lowering refuses — the constructs `lower.zig` names (`receive`, `!`, the old
`catch Expr`, `try … of`, `try … after`, records, macros; the list is in
§ Comptime lowering above). The helper `ensureEvalHelper` stays for exactly
those, so a refused template is still correct, only interpreted. **Measured
2026-09-26:** no beam snapshot carries `'__bp_erl_eval'` any more (15 moved,
every RUN LOG unchanged, `beam_export_audit` 475/475); the 82 primitive-method
calls of the audit in `../AGENTS.md` § Primitive methods compile with none; of
the 159 templates in `libs/std/src`, at most 6 carry a refused construct by
text (`async` `allOf`/`raceOf` — `receive`, `!`; `encoding`'s percent-decode and
one `json` reader — `try … of`; `http`'s `get` — `catch Expr`; `process`'s run —
`receive`), and those keep the run-time path.

**Cost, re-measured** (OTP 29, 1 000 000 iterations of a recursive loop whose
body is `base64:encode(<<"hello">>)` plus `string:length/1`, three runs):
through the compiled helper **0.25–0.39 µs** per iteration, the same loop
written directly in Erlang **0.24–0.34 µs** — 1.06–1.16×, the local call. Through
`'__bp_erl_eval'/2` it was **5.722 µs** per call against 0.113 direct (50.6×,
2026-09-18). A template that does not parse is now a build-time `null` from the
reader (and the run-time path), never a helper that compiles and fails later.

## Closure values (`make_fun3`) — every build site, classified

`specs/1.0.5-beta/03-beam/README.md` step 5 expects decision 2 (a block is not a
value) to leave dead `make_fun3` sites behind, and counted **12** with
`grep -c make_fun3 ../beam_asm.zig`. That grep counts **text**, not build sites,
and at this HEAD it answers **13** — every one of which is a **comment**:
`beam_asm.zig` never writes the instruction itself, `beam_emitter.writeMakeFun3`
does. The number to classify is therefore the count of places that emit a fun
value, and it is **8** — four direct `writeMakeFun3` calls into a prelude
helper's own writer, and four through `emitMakeFun` (which prefixes the
`test_heap` the loader demands):

| # | Site in `../beam_asm.zig` | The fun | Why a fun is needed |
|---|---|---|---|
| 1 | `ensureJoinHelper` (direct) | `fun '-bp_stringify-'/1` | `lists:map/2` takes one |
| 2 | `lowerStringSegments` | `fun '-bp_stringify-'/1` | the same |
| 3 | `ensurePrintHelper` (direct) | `fun '-bp_show_top-'/1` | the same |
| 4 | `emitShowJoin` (direct) | `fun '-bp_show_elem-'/1` | the same |
| 5 | `lowerLambda` | the written lambda `{ x -> … }` | a lambda **is** a fun value |
| 6 | `lowerMutatingFold` | the loop body | `lists:foldl/3` takes one |
| 7 | `lowerMutatingClosure` | `val f = { p -> … }` that reassigns the frame's names | a closure the frame then calls |
| 8 | `lowerLoop` | the loop body | `lists:foreach` (or `lists:map` for a yielding body outside a generator scope's frame) takes one |

**None of the eight is a block as a value**, so decision 2's R7 has no producer
to remove on this backend. Two reasons, both checkable:

- `@block { … }` already runs its statements **in the current frame** here — the
  `"block"` arm of `lowerBuiltinCall`, with `countLocalsRec` reserving the block's
  locals in the enclosing frame. commonJS wraps the same form in an IIFE, which is
  the one block-as-value site front 04 found in its twin sweep (11 text hits / 10
  build sites / 1 block-as-value).
- beam's other block-as-value producer was **already removed**, by this front's
  `ae813cc8`: a `case` arm written `Pattern { body }` reaches the backend as a
  lambda (`ast.Expr.function`, `.lambda`), and lowering it as an expression used
  to build a `make_fun3` and throw it away — which is why 01's defect 2 printed
  nothing from a `case` arm and why `break r * r` reached `integer_to_binary/1`
  as a `#Fun<…>`. `armBlock` + the arm-value path run it in the arm's own frame.

For scale rather than for the row: 182 of the 314 beam snapshots carry
`make_fun3`, 586 occurrences — most of them site 3, the print prelude, which 163
snapshots carry.

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
