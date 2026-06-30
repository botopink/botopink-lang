# Comptime Type Introspection & Manipulation

**Version:** 1.0.0-beta
**Status:** in progress
**Created:** 2026-06-30
**Author:** ericfillipe

---

## Status

**Current:** in progress — inference-time type resolution done; comptime value evaluation + std functions remain

> **What's actually done:** 5 builtins (`@typeInfo`, `@TypeOf`, `@makeRecord`, `@RecordKeys`, `@Field`) are registered and resolve correct return types during inference. Types are embedded in compiler as Zig source. No comptime value evaluation yet — the builtins know the *shape* of what they return but don't compute *values*. Std functions are inference-time type manipulators; their `.bp` implementations are stubs.

| Step | Title | Status | Assignee |
|------|-------|--------|----------|
| Step 1 | Design `@typeInfo` builtin schema | completed | ericfillipe |
| Step 2 | Register builtins + inference-time type resolution | completed | ericfillipe |
| Step 3 | Implement comptime value evaluation for all builtins | pending | |
| Step 4 | Implement std `mergeRecords` in .bp (needs eval) | pending | |
| Step 5 | Implement std `partial` / `omit` / `pick` in .bp (needs eval) | pending | |
| Step 6 | Comptime tests for all builtins (value-level) | pending | |
| Step 7 | Comptime tests for all std functions | pending | |
| _Step 5-old_ | _mapFields (mapped types)_ | _deferred_ | — |

## Objective

Give botopink comptime the ability to inspect and construct types
programmatically — the foundation for generic type-level programming. This
requires three builtins (`@typeInfo`, `@TypeOf`, `@makeRecord`) and two
helper builtins (`@RecordKeys`, `@Field`). Standard library functions
(`mergeRecords`, `partial`, `omit`, `pick`) are then built purely in
user-space `.bp` code, proving the builtins are sufficient.

Codegen tests for these features are deferred to
[`1_0_0_beta.codegen-test-gap.md`](./1_0_0_beta.codegen-test-gap.md).

## Prerequisites

- `zig build test` passing
- [**BLOCKING**] `erl-comptime-gaps` — comptime value evaluation needs the erl runtime decompiler to execute `.bp` code inside template bodies. See [Gap 1](./1_0_0_beta.erl-comptime-gaps.md#1-template-body-decompiler-is-incomplete).
- `@comptimeError` builtin (not yet implemented — needed for std function error reporting)

---

## Step 1 — Design `@typeInfo` builtin schema

**Status:** completed **Assignee:** ericfillipe

Design of all 5 builtins, the `TypeInfo` enum, `RecordField`, `EnumVariant` records. Schema is stable.

---

## Step 2 — Register builtins + inference-time type resolution

**Status:** completed **Assignee:** ericfillipe

Builtins are registered in `comptime.zig` and resolve correct *types* during inference:

**Done:**
- [x] `@typeInfo(T)` returns `TypeInfo` type for primitive, record, enum, fn types
- [x] `@TypeOf(value)` returns the type of the value argument
- [x] `@makeRecord(fields)` returns a fresh type variable
- [x] `@RecordKeys(T)` returns `string[]` type; `@Field(value, name)` resolves field type
- [x] TypeInfo, RecordField, EnumVariant, TypeInfoKind types registered globally via embedded Zig source
- [x] `zig build test` passes

**Not done (moved to Step 3):**
- [ ] `@typeInfo(T)` computes actual TypeInfo enum variant **value** at comptime
- [ ] `@makeRecord(fields)` creates a concrete record **type** from field descriptors
- [ ] `@RecordKeys(T)` returns actual **string array** at comptime
- [ ] `@Field(value, name)` returns actual **field value** at comptime

### Implementation notes

- Types registered in `comptime.zig` as embedded Zig source, parsed + inferred during `registerStdlib`
- `RecordField.typeName` (not `type` — keyword conflict)
- Builtins dispatch in `inferBuiltinCallReturnType`; inference-time resolution only

### Files modified

| File | Purpose |
|------|---------|
| `modules/compiler-core/src/comptime.zig` | Embedded type info source + builtin registration |
| `modules/compiler-core/src/comptime/infer.zig` | `inferBuiltinCallReturnType` dispatch |
| `modules/compiler-core/src/comptime/tests.zig` | 23 snapshot tests for type resolution |
| `libs/std/src/reflect.bp` | Stub std library file |

---

## Step 3 — Implement comptime value evaluation for all builtins

**Status:** pending **Assignee:**

Implement actual comptime evaluation for all 5 builtins — they must compute
values, not just types. This is the gate for all remaining steps.

### Builtin: `@typeInfo(T: type) -> TypeInfo`

Returns a comptime `TypeInfo` enum variant describing the structure of type `T`.

```botopink
enum TypeInfoKind { Int, Float, Bool, String, Array, Record, Enum, Fn, Optional, Generic }
record RecordField { name: string, typeName: type }   // typeName because 'type' is keyword
record EnumVariant { name: string, fields: RecordField[] }

enum TypeInfo {
    Int, Float, Bool, String,
    Array(element: type),
    Record(fields: RecordField[]),
    Enum(variants: EnumVariant[]),
    Fn(params: RecordField[], returnType: type),
    Optional(inner: type),
    Generic(name: string, params: type[]),
}
```

### Builtin: `@TypeOf(value: any) -> type`

Returns the type of any value/binding. Already resolves correctly during inference; needs comptime eval to return the actual type as a value.

### Builtin: `@makeRecord(fields: RecordField[]) -> type`

Creates a new record type from field descriptors. Currently returns a fresh type variable — must produce a concrete structural record type.

### Builtin: `@RecordKeys(T: type) -> string[]`

Returns field names of a record type as a comptime string array.

### Builtin: `@Field(value: any, comptime name: string) -> any`

Accesses a record field by comptime-known name.

**Acceptance criteria:**
- [ ] `@typeInfo(i32)` → `TypeInfo.Int` (value, not just type)
- [ ] `@typeInfo(string)` → `TypeInfo.String`
- [ ] `@typeInfo(?i32)` → `TypeInfo.Optional(inner: i32)`
- [ ] `@typeInfo(record { x: i32, y: string })` → `TypeInfo.Record(fields: [...])`
- [ ] `@typeInfo(enum { A, B(x: i32) })` → `TypeInfo.Enum(variants: [...])`
- [ ] `@TypeOf(42)` → `i32` type value
- [ ] `@makeRecord([RecordField("a", i32)])` creates usable record type
- [ ] `@RecordKeys(record { x: i32, y: string })` → `["x", "y"]`
- [ ] `@Field(record { x: 1, y: 2 }, "x")` → `1`
- [ ] `zig build test` passes

### Files to modify

| File | Purpose |
|------|---------|
| `modules/compiler-core/src/comptime/eval.zig` | Value-level evaluation for each builtin |
| `modules/compiler-core/src/comptime/infer.zig` | Wire eval results into inference |

---

## Step 4 — Implement std `mergeRecords` in .bp

**Status:** pending **Assignee:**

`mergeRecords(A, B)` merges two record types. Conflicting field names with different types produce `@comptimeError`.

**Depends on:** Step 3 (comptime eval), `@comptimeError` builtin.

```botopink
// libs/std/src/reflect.bp
fn mergeRecords(comptime A: type, comptime B: type) -> type {
    val infoA = @typeInfo(A);
    val infoB = @typeInfo(B);
    // conflict detection + field join → @makeRecord
}
```

**Acceptance criteria:**
- [ ] `mergeRecords(User, Timestamps)` produces correct merged record
- [ ] Same-name same-type fields → no duplicate
- [ ] Same-name different-type fields → `@comptimeError`
- [ ] `zig build test` passes

---

## Step 5 — Implement std `partial` / `omit` / `pick` in .bp

**Status:** pending **Assignee:**

Three standard type-manipulation functions: `partial` (all fields optional), `omit` (remove field), `pick` (keep named fields).

**Depends on:** Steps 3-4.

**Acceptance criteria:**
- [ ] `partial(Config)` → all fields become `?type`
- [ ] `omit(FullUser, "password")` → field removed
- [ ] `pick(FullUser, ["name", "id"])` → only specified fields kept
- [ ] `zig build test` passes

---

## Step 6 — Comptime tests for all builtins (value-level)

**Status:** pending **Assignee:**

Test each builtin's value-level evaluation in isolation.

**Depends on:** Step 3.

**Acceptance criteria:**
- [ ] ~15 comptime tests in `comptime/tests/builtins_typeinfo.zig`
- [ ] Each builtin tested with multiple input types
- [ ] `zig build test` passes

### Files to create

| File | Purpose |
|------|---------|
| `modules/compiler-core/src/comptime/tests/builtins_typeinfo.zig` | Builtin value eval tests |

---

## Step 7 — Comptime tests for all std functions

**Status:** pending **Assignee:**

Test each std function at comptime level.

**Depends on:** Steps 4-5.

**Acceptance criteria:**
- [ ] Tests for `mergeRecords`, `partial`, `omit`, `pick`
- [ ] Both success and error (`@comptimeError`) paths covered
- [ ] `zig build test` passes

---

## Summary

| Metric | Count |
|--------|-------|
| New builtins | 5 (`@typeInfo`, `@TypeOf`, `@makeRecord`, `@RecordKeys`, `@Field`) |
| New std functions | 4 (`mergeRecords`, `partial`, `omit`, `pick`) |
| Builtins registered (inference-time) | 5 ✅ |
| Builtins with value evaluation | 0 |
| Std functions implemented | 0 (stubs only) |

### Key findings

1. **Inference-time type resolution is solid** — the builtins know what types they return. The gap is comptime value computation.

2. **Blocked on erl decompiler** — comptime eval runs in the erl subprocess. Template body decompiler must handle the constructs used in std function `.bp` code (loops, if/else, field access). See `erl-comptime-gaps.md` Gap 1.

3. **`@comptimeError` doesn't exist yet** — needed for std function error reporting (conflicting fields, invalid inputs).

4. **`mapFields` deferred** — requires comptime lambda evaluation, which is a separate capability.

5. **No codegen tests in this spec** — std functions produce types at comptime. Runtime tests for values produced by these types go in `codegen-test-gap.md`.

## Changelog

| Date | Change | Author |
|------|--------|--------|
| 2026-06-30 | Spec created | ericfillipe |
| 2026-06-30 | Steps 1-2 completed: builtins registered, inference-time type resolution working, 23 snapshot tests | ericfillipe |
| 2026-06-30 | RecordField.type → typeName; TypeInfo types via embedded Zig source | ericfillipe |
| 2026-06-30 | mapFields deferred; @comptimeError not yet implemented | ericfillipe |
| 2026-06-30 | Rewritten: fixed status table vs body inconsistency; clarified inference-time vs value-level split; added blocking deps | ericfillipe |
