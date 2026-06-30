# Erl comptime — remaining gaps

**Version:** 1.0.0-beta
**Status:** planning
**Created:** 2026-06-30
**Author:** ericfillipe

---

## What was delivered (erl-comptime-speed spec)

- Persistent erl subprocess as sole comptime runtime
- BEAM bytecode cache
- Binary framing protocol
- AST-to-BP-source decompiler for template bodies
- `#[@Host]` lowering via post-processing of `template_runtime.erl`
- Node.js, wasm3, WAT, AtomVM — all removed

## Remaining gaps

### 1. Template body decompiler is incomplete

`emitBpExpr` in `template_eval.zig` only handles:
- Literals (string, number, null)
- Simple identifiers
- Function calls (`.call.call`)
- Binary ops
- Return/throw

**Missing:** `if/else`, `match`/`case`, loops, `identAccess` (field access), `dotIdent`, `pipeline`, string templates. Template bodies using these constructs will produce `"null"` in the decompiled BP source, which compiles but produces wrong results.

**Fix:** extend `emitBpExpr` with proper handling for each missing Expr variant. The AST types are documented in `modules/compiler-core/src/ast.zig` §ExprOf.

### 2. Decorator eval is a stub

`decorator_eval.zig:evaluateErl()` returns `error.EvalFailed`. There is no decompiler for decorator bodies like there is for template bodies. Decorator tests fail (10 failures in `zig build test`).

**Fix:** implement `emitBpStmt`/`emitBpExpr` equivalents in `decorator_eval.zig`, or share the decompiler from `template_eval.zig`.

### 3. Record layout assumption in patchHostMethods

`comptime.zig:patchHostMethods()` uses `element(2, Self)` to extract the descriptor from the Capture record. This assumes Capture is a tuple with descriptor at position 2. If the Erlang codegen changes the record representation (maps vs tuples, field reordering), this breaks silently.

**Fix:** either inspect the actual Erlang output for `template_runtime.bp` to verify the tuple layout, or add a test that validates the descriptor extraction.

### 4. 36 test failures in `zig build test`

| Category | Count | Root cause |
|----------|-------|------------|
| Decorator eval | 10 | Gap 2 |
| Template eval (complex bodies) | 5 | Gap 1 |
| Codegen snapshots (RUN LOG empty) | 5 | wasm3 removed, executeWat returns "" |
| LSP sublanguage tests | 9 | Templates not executing on erl |
| Memory leak | 1 | Unrelated |
| Snapshot diffs | 6 | WAT → Erlang output change |

### 5. WAT codegen RUN LOG is empty

`codegen/runtime.zig:executeWat()` returns `""` because wasm3 was removed. WAT codegen snapshots that previously showed RUN LOG output now show empty. The WAT backend itself is intact — only the in-process execution is gone.

**Fix:** either restore wasmtime-based WAT execution (requires wasmtime on PATH), or accept empty RUN LOGs as the new baseline.

### 6. Template eval latency not benchmarked

The spec's latency targets (~0.3ms comptime val, ~1ms template body) were never measured. The infrastructure supports it (BEAM cache, binary protocol, persistent process) but no benchmarks exist.

---

## Priority

1. **Gap 1 + 2** (decompiler completeness) — unblocks template/decorator tests
2. **Gap 4** (test failures) — consequence of gaps 1-3
3. **Gap 3** (record layout) — potential silent bug
4. **Gap 5** (WAT RUN LOG) — cosmetic, snapshots can be regenerated
5. **Gap 6** (benchmarks) — nice to have

## Notes

- The infrastructure is solid: persistent erl, binary protocol, BEAM cache, single runtime. The gaps are in the **decompiler** (AST → BP source), not in the runtime.
- An alternative to fixing the decompiler: instead of decompiling the AST back to BP source, compile the template body directly to Erlang via the `erlang.zig` codegen. This avoids the round-trip (BP → AST → BP → Erlang) and goes straight (BP → AST → Erlang). But it requires `erlang.zig` to handle `#[@Host]` method lowering at the call site, which the post-processing approach was designed to avoid.
