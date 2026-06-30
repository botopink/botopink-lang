# Wave 3 — Codegen Hardening

**Version:** 1.0.0-beta
**Status:** in progress
**Created:** 2026-06-30
**Author:** ericfillipe
**Depends on:** Wave 1 (`01-erl-fixes.md` Step 1 for template/comptime eval tests)

---

## Status

**Current:** in progress — audit done; runtime crash fixes + new tests pending

| Step | Title | Status | Assignee |
|------|-------|--------|----------|
| Step 1 | Fix runtime crashes (all backends) | pending | |
| Step 2 | Remove 76 orphaned snapshot files | pending | |
| Step 3 | New codegen tests: optional, imports, records, enums, generics, interfaces, lambdas, operators | pending | |
| Step 4 | New codegen tests: template/@Expr + comptime eval | pending | |
| Step 5 | Regenerate snapshots, verify full suite | pending | |

## Context

Only ~10% of comptime-verified features have codegen runtime tests. 120 snapshots have `@print` but empty RUN LOG (runtime crashed). 13 show `undefined` from known gaps. 191 parser features (91.8%) have zero codegen tests.

### Audit summary (done)

| Backend | OK | Limitations | Crashes |
|---------|-----|-------------|---------|
| node/commonJS | 246 | 8 | 13 |
| erlang/erlang | 251 | 2 | 38 |
| beam/beam | 248 | 4 | 21 |
| wasm/wasm | 252 | 0 | 48 |
| **Total** | **997** | **14** | **120** |

### Coverage gaps (all backends)

| Category | Comptime tests | Codegen tests | Gap |
|----------|---------------|---------------|-----|
| optional/null | 8 | 0 | 8 |
| template/@Expr | 11 | 0 | 11 |
| import/cross-module | 8 | 0 | 8 |
| interface/implement | 16 | 0 | 16 |
| generic types | 3 | 0 | 3 |
| record/enum | 28 | 2 | 26 |
| operators | 30 | 2 | 28 |

---

## Step 1 — Fix runtime crashes (all backends)

**Status:** pending **Assignee:**
**Parallel per backend** — each backend's crashes are in different files.

### commonJS (13 crashes + 8 limitations) — `codegen/commonJS.zig`

1. **Fix `.len` → `.length`** — Resolves 6 `undefined` limitations
2. **`if` without `else`** — Emit ternary `cond ? value : undefined`
3. **String methods dispatch** — Fix native method name mapping
4. **Array operations** — Fix `slice`, `zip` lowering
5. **try/catch propagation** — Result-unwrapping at runtime
6. **Record destructuring in fn params**

### Erlang (38 crashes) — `codegen/erlang.zig`

7. **Template system** — 6 `template_end_to_end_*` tests (may need Wave 1)
8. **Pipeline operator** — `|>` lowering doesn't thread args correctly
9. **Instance methods** — External functions not compiled into module
10. **try/catch propagation** — Same as commonJS

### BEAM (21 crashes) — `codegen/beam_asm.zig`

11. **try/catch** — `@Result` unwrapping broken in BEAM blocks
12. **Anonymous record literal** — Implement or skip runtime execution
13. **String `.len` in arithmetic** — Tagged integer doesn't work in BEAM ops

### WASM (48 crashes) — `codegen/wat.zig` + `codegen/runtime.zig`

14. **External host functions** — 8 tests crash. Skip RUN LOG for `external_*` on WASM (WAT lowering still verified by source snapshot)
15. **Template system** — 5 tests crash
16. **Iterator `yield`** — No coroutine support in wasmtime → skip or document
17. **Case/switch on literals** — BR_TABLE doesn't produce working code
18. **Instance methods + Array builtins** — Host functions not in wasmtime → skip

**Acceptance criteria:**
- [ ] All 13 commonJS crashes/limitations fixed or documented
- [ ] All 38 Erlang crashes fixed or documented
- [ ] All 21 BEAM crashes fixed or documented
- [ ] All 48 WASM crashes fixed or documented (intentional skips allowed)
- [ ] `zig build test` passes
- [ ] Empty RUN LOGs replaced with actual output

---

## Step 2 — Remove 76 orphaned snapshot files

**Status:** pending **Assignee:**
**Parallel-safe:** Yes — zero risk, independent.

76 empty files (19 per backend) unchanged since `0c30a38`. No test references them. Delete manually.

**Acceptance criteria:**
- [ ] 76 orphaned files deleted from `snapshots/codegen/{node,erlang,beam,wasm}/`
- [ ] `zig build test` passes

---

## Step 3 — New codegen tests: optional, imports, records, enums, generics, interfaces, lambdas, operators

**Status:** pending **Assignee:**
**Parallel-safe:** Yes — independent per category.

**Depends on:** Step 1 (crash fixes) for existing tests to pass first.

### 3.1 — Optional/null (6 tests)

```botopink
// slug: optional_if_null_check_print
fn greet(x: ?string) -> string {
    if (x) { s -> return "hello " + s; }; return "nobody";
}
fn main() { @print(greet("world")); @print(greet(null)); }
// RUN LOG: hello world\nnobody
```

### 3.2 — Cross-module imports (5 tests)

Multi-file tests: import val, function, record constructor, 3-level import chain.

### 3.3 — Interface/implement (4 tests)

Method dispatch, interface with field, multiple abstract methods, two impls with qualified dispatch.

### 3.4 — Record/enum (6 tests)

Constructor with field access, record method using self, enum constructor with case, enum payload variant, enum sections nested, record field update (immutable).

### 3.5 — Generics (3 tests)

Generic record Pair, identity function, generic enum Option.

### 3.6 — Lambda, operators, annotations (3 tests)

Lambda as map argument, operator precedence, string interpolation edge cases.

**Acceptance criteria:**
- [ ] 27 codegen tests added across `codegen/tests/{values,features,aggregates}.zig`
- [ ] Each test runs on all 4 backends (with per-backend skips where documented)
- [ ] RUN LOG captures correct output
- [ ] `zig build test` passes

---

## Step 4 — New codegen tests: template/@Expr + comptime eval

**Status:** pending **Assignee:**
**Depends on:** Wave 1 Step 1 (decompiler fix)

### 4.1 — Template/@Expr (4 tests)

```botopink
// slug: template_expr_hole_with_runtime_value
pub fn greet(comptime q: @Expr<string>) -> @Expr<string> { return q; }
fn main() {
    val name = "botopink";
    val msg = greet "hello ${name}!";
    @print(msg);
}
// RUN LOG: hello botopink!
```

### 4.2 — Comptime eval (3 tests)

Comptime block yields constant, comptime params with specialization, type-meta specialization.

**Acceptance criteria:**
- [ ] 7 tests added to `codegen/tests/comptime.zig` + `codegen/tests/features.zig`
- [ ] Each test runs on all 4 backends

---

## Step 5 — Regenerate snapshots, verify full suite

**Status:** pending **Assignee:**

Final sweep:
```bash
zig build test
zig build test-libs
zig build test-backends
```

Regenerate all affected snapshots. Verify zero test failures.

**Acceptance criteria:**
- [ ] Full test suite passes
- [ ] ≥37 new codegen tests with correct RUN LOG
- [ ] ≥120 previously-crashed tests fixed or documented
- [ ] All snapshot files regenerated

---

## Execution order

```
Step 2 (orphans) ──────────────────────►  (independent)
Step 1 (crash fixes) ──┬─ commonJS ────►  
                        ├─ Erlang ──────►  
                        ├─ BEAM ────────►  
                        └─ WASM ────────►  
                             │
Step 3 (new tests) ◄────────┘  (after Step 1)
Step 4 (template/comptime tests) ── needs Wave 1 Step 1
Step 5 (final sweep) ◄── after all steps
```

### Quick wins (no deps, low risk, parallel-safe)

| # | Action | Time |
|---|--------|------|
| 1 | Delete 76 orphaned snapshots (Step 2) | ~10 min |
| 2 | Fix `.len` → `.length` in JS codegen | ~30 min |
| 3 | Fix `if` without `else` in JS codegen | ~20 min |
| 4 | Skip WASM RUN LOG for `external_*` tests | ~15 min |

## Summary

| Metric | Count |
|--------|-------|
| Runtime crashes to fix | 120 |
| Orphaned files to remove | 76 |
| New codegen tests | 34 (27 + 7) |
| Current comptime→codegen coverage | ~10% |
| Target coverage | ~25% |

## Changelog

| Date | Change | Author |
|------|--------|--------|
| 2026-06-30 | Created from codegen-test-gap consolidation | ericfillipe |
