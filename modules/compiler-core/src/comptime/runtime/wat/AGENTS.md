# compiler-core/src/comptime/runtime/wat

> Path: `modules/compiler-core/src/comptime/runtime/wat/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

The wat comptime runtime's compiler half (front 18 step 2): the Erlang module a
decorator or template body was lowered to — **the same text the BEAM runtime
compiles** — read back, lowered to one wasm module and linked into an embedded
term library. Because both runtimes run one program, the only way they can
disagree is through a BIF implemented twice (`rt.zig` vs OTP), and
`../parity.zig` / the codegen harness measure exactly that.

## Tree

```text
wat/
├── AGENTS.md       ← you are here
├── erl_parse.zig   ← tokenizer + parser of the generated Erlang subset → a small tree
├── lower.zig       ← that tree → a `codegen/wat/wat_ast.zig` module over `rt` terms
├── link.zig        ← splices a lowered module into the runtime's bytes: one wasm module
├── program.zig     ← parse + lower + link for one generated module, cached by module atom
└── rt.zig          ← the term library, compiled to wasm32-freestanding at `zig build` (`bp_wat_rt.wasm`)
```

## Files

| File | Role |
|---|---|
| `erl_parse.zig` | `parseModule(arena, src, *Failure) → Module{ name, exports, imports, functions }`. The subset `codegen/beam/erl_emitter.zig` writes plus the host templates of `libs/std/src/primitives.bp`: attributes (`-module`, `-export`, `-import`; others skipped), function clauses with guard sequences (`;` alternatives of `,` tests), `case`/`if`/`try … of … catch … after`/`begin`, `fun` (anonymous, named `fun F(…)`, `fun f/A`, `fun m:f/A`), list comprehensions with list and **binary** generators (`<<C/utf8>> <= S`), maps and `M#{…}` updates, binaries with segment types and sizes, strings (as code points — `<<"é">>` is the one byte 233, as `erlc` reads a UTF-8 source), char literals, `Base#digits`, the whole operator table. `receive`, records, macros, the old-style `catch E` and `!` are refused by name (`error.Unsupported`, `Failure.message` + line). Parses all 420 comptime modules on disk at the time of writing (the compiler's tests and the five libraries). **Zig result-location gotcha, fixed here once:** `e = .{ .call = .{ .fun = try p.box(e), … } }` lets Zig write the new union into `e` before `box` copies it — every such site boxes into a temporary first. |
| `lower.zig` | `lowerProgram(arena, Program{ modules }, *Failure) → Output{ module, data }`. The generated module is `modules[0]`, the preludes it `-import`s follow; only what `main/1` reaches is lowered (a work queue by `name/arity`). Every value is an `i32` term of `rt.zig`; a variable is a local; a call that can raise is followed by `rt_pending` + `br_if` to the innermost handler — a `try`'s catch block, a guard's failure (which clears the exception: a raising guard fails), or the function's exit (`block $raise … return`, then `i32.const 0`). Clauses: `block $next` per clause, patterns and guards `br $next` on failure, the body `br $done`; no clause → `function_clause` / `{case_clause, V}` / `if_clause` / `{try_clause, V}` / re-raise, as the BEAM raises them. Patterns: variables (bind when unbound, compare when bound; a fun head and a generator bind fresh — `renames`), literals, tuples by arity, lists and `"prefix" ++ Tail`, maps by `:=` key, binary literals and `<<Lit, Rest/binary>>`, `=` aliases. Funs are lifted to `(Self, A1…An) → i32` in the table (`__tbase + slot`), their captures in an environment tuple read back at entry; `fun f/A` gets a wrapper. `andalso`/`orelse` short-circuit and raise `{badarg, V}` on a non-boolean left side. List comprehensions are loops that cons in reverse and `lists:reverse`. BIFs: `bifs` maps `module:name/arity` to the `rt` export (erlang, lists, maps, string, binary, unicode, math, io, io_lib, json); an unqualified call reaches a local function, an `-import`ed prelude function or an auto-imported erlang BIF; anything else — `self/0`, `apply/3`, `maps:iterator/1` — is a **refusal naming it**, which the evaluator reports as the module not compiling. Output: `(import "rt" "rt_*" …)` for the runtime calls used, the linker's globals `__lit`/`__lit_end`/`__tbase`, the table, the functions, `bp_init` and `bp_main(ptr, len)`; literal bytes (atom names, binaries) in `data`, 8-aligned, addressed as `__lit + offset`. |
| `link.zig` | `link(alloc, rt_bytes, program, data) → []u8`. Reads the runtime's sections once (`Runtime.parse`: types, imported functions, function types, exports, globals, table and memory limits, and where static memory ends — the larger of the data segments' end, the stack top and **`__heap_base`**, which the build exports because `.bss` has no data segment) and writes one module: the runtime's type section plus the program's new signatures; its imports, functions, globals, exports, element segment, code bodies and data segments **byte for byte**, with the program's appended — table grown by the program's closures, memory grown to hold its literals at `__lit` (16-aligned past static memory), `__lit`/`__lit_end`/`__tbase` defined as constants. The program's `"rt"` imports resolve to the runtime's exported functions (an import the runtime does not export is `error.UnknownRuntimeFunction`); its bodies are encoded by `codegen/wat/wasm_binary_emitter.zig`'s `Encoder` pre-seeded with the runtime's index spaces. Custom sections are dropped. |
| `program.zig` | `build(module, code) → Built{ ok: { wasm, listing }, refused }`: parse the generated text, add the prelude it imports (the two preludes are `../prelude.zig`'s rendering, parsed once per process), lower, render the `.wat` listing, link with `runtime_bytes` (`@embedFile("bp_wat_rt.wasm")`). Cached process-wide by module atom — the atom is the content hash of the text, so a hit is the same program. Refusals carry the construct and where (the lowering's `Failure`, the parser's line). |
| `rt.zig` | **Compiled for `wasm32-freestanding`, MVP features, `ReleaseSmall`, `rdynamic`, `__heap_base` exported** (root `build.zig`, `bp_wat_rt`); also compiled natively into the test binary for its pure helpers' tests. The Erlang term shapes on linear memory: `Hdr{tag}`-prefixed cells for i64 integers (a bignum raises `{bp_wat_runtime, …}`), floats, interned atoms, binaries (a literal is referenced, never copied), cons cells and `[]`, tuples, maps (keys kept in iteration order, `keyOrder`), funs, and a binary builder. One bump arena per evaluation (`rt_init(start)` — past the program's literals), grown by `memory.grow`, never freed. Exceptions are `pending` + class + reason; every export that can raise returns `[]` with the exception recorded. Term order and `==`/`=:=` as Erlang defines them; the BIFs the lowering maps, with the BEAM's error reasons (`badarg`, `{badkey, K}`, `badarith`, `function_clause`, `{badmap, M}` …); `json:encode` byte-compatible with OTP 27+'s (escapes, `float_to_binary(F, [short])` floats — `shortFloat`: shortest digits, fixed notation unless the exponent form is shorter); `io_lib:format` `~p`/`~w`/`~s`/`~n`/`~~` (without `~p`'s 80-column line breaking); ETF decoding of exactly the tags `../etf.zig` writes; `io:format` into a buffer in the module (`rt_printed`), since the module imports nothing. `rt_describe(class, reason)` is `Class:Reason` as `~p` writes them. Map key order: atoms by `rank` (a short list of atoms the OTP release has at boot, then creation order) — an approximation of the BEAM's atom-table order, which is why replies are compared and recorded in sorted key order (`../reply_order.zig`). |

## What it does not do yet

- `~p`'s line breaking past 80 columns (`io_lib_pretty`): an error text built by
  `'__bp_text'` of a long term differs from the BEAM's. No fixture carries one.
- Unicode case mapping: `string:uppercase`/`lowercase` of a non-ASCII letter
  raises `{bp_wat_runtime, …}` rather than answering differently from OTP.
- Tail calls: an Erlang loop is recursion, so a body's depth is its iteration
  count (the executor gives wasm3 an 8 MiB stack).
