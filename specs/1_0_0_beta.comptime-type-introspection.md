# Comptime Type Introspection & Manipulation

**Version:** 1.0.0-beta
**Status:** planning
**Created:** 2026-06-30
**Author:** ericfillipe
**Replaces:** `1_0_0_beta.ts-advanced-types-bp.md` (reframed: no TS mapping, focus on builtins + std functions)

---

## Status

**Current:** in progress

| Step | Title | Status | Assignee |
|------|-------|--------|----------|
| Step 1 | Design `@typeInfo` builtin schema | completed | ericfillipe |
| Step 2 | Implement `@typeInfo` + `@TypeOf` + `@makeRecord` builtins | completed | ericfillipe |
| Step 3 | Implement `@RecordKeys` + `@Field` builtins | completed | ericfillipe |
| Step 4 | Design & implement std `mergeRecords` (record intersection) | completed | ericfillipe |
| Step 5 | Design & implement std `mapFields` (mapped types) | deferred | |
| Step 6 | Design & implement std `partial` / `omit` / `pick` | completed | ericfillipe |
| Step 7 | Comptime tests for all builtins | completed | ericfillipe |
| Step 8 | Comptime tests for all std functions | pending | |

## Objective

Give botopink comptime the ability to inspect and construct types
programmatically — the foundation for generic type-level programming. This
requires three builtins (`@typeInfo`, `@TypeOf`, `@makeRecord`) and two
helper builtins (`@RecordKeys`, `@Field`). Standard library functions
(`mergeRecords`, `mapFields`, `partial`, `omit`, `pick`) are then built
purely in user-space `.bp` code, proving the builtins are sufficient.

Codegen tests for these features are deferred to
`1_0_0_beta.codegen-test-gap.md` (the std functions need the builtins to
exist first).

## Prerequisites

- `zig build test` passing
- Comptime eval loop supporting `break value` with type values
- `@Expr<T>` template system (used in some std function patterns)

---

## Step 1 — Design `@typeInfo` builtin schema

**Status:** completed
**Assignee:** ericfillipe

### Builtin: `@typeInfo(T: type) -> TypeInfo`

Returns a comptime record describing the structure of type `T`.

```botopink
// @typeInfo returns a TypeInfo enum variant:
enum TypeInfoKind { Int, Float, Bool, String, Array, Record, Enum, Fn, Optional, Generic }

record RecordField { name: string, type: type }
record EnumVariant { name: string, fields: RecordField[] }

enum TypeInfo {
    Int,
    Float,
    Bool,
    String,
    Array(element: type),
    Record(fields: RecordField[]),
    Enum(variants: EnumVariant[]),
    Fn(params: RecordField[], returnType: type),
    Optional(inner: type),
    Generic(name: string, params: type[]),
}
```

**Specification:**

| Aspect | Detail |
|--------|--------|
| Type | `fn(comptime T: type) -> TypeInfo` |
| Input | Any type (primitive, record, enum, fn, array, optional, generic) |
| Output | `TypeInfo` enum variant describing the type's structure |
| Scope | Comptime only — evaluates at compile time |
| Immutable | The returned `TypeInfo` is a value, not a mutable reference |

### Builtin: `@TypeOf(value: any) -> type`

Returns the type of any value or binding at comptime. Lighter than `@typeInfo`
— just the type identity, not the full structure.

```botopink
val answer: i32 = 42;
val AnswerType = @TypeOf(answer);  // i32

fn clone<T>(x: T) -> T { return x; }
val original: record { x: i32, y: i32 } = record { x: 1, y: 2 };
val cloned = clone(original);  // type inferred automatically
```

**Specification:**

| Aspect | Detail |
|--------|--------|
| Type | `fn(value: any) -> type` |
| Input | Any value or binding in scope |
| Output | The type of the value (usable in annotations) |
| Scope | Comptime only |

### Builtin: `@makeRecord(fields: RecordField[]) -> type`

Creates a new record type from a list of field descriptors at comptime. The
inverse of reading `@typeInfo(T).Record.fields`.

```botopink
val fields: RecordField[] = [
    RecordField(name: "x", type: i32),
    RecordField(name: "y", type: i32),
];
val Point = @makeRecord(fields);
// Point is equivalent to: record { x: i32, y: i32 }
```

**Specification:**

| Aspect | Detail |
|--------|--------|
| Type | `fn(fields: RecordField[]) -> type` |
| Input | Array of `RecordField` descriptors |
| Output | A new record type |
| Scope | Comptime only |
| Uniqueness | Each call creates a structurally unique type |

---

## Step 2 — Implement `@typeInfo` + `@TypeOf` + `@makeRecord` builtins

**Status:** completed
**Assignee:** ericfillipe

Register and implement the three core builtins in the compiler. Builtins resolve
correct return types during inference. Comptime evaluation (computing actual
TypeInfo values / record types from field arrays) is deferred.

**Acceptance criteria:**
- [x] `@typeInfo(T)` returns `TypeInfo` type for primitive, record, enum, fn types
- [x] `@TypeOf(value)` returns the type of the value argument
- [x] `@makeRecord(fields)` returns a fresh type variable (structural record type deferred)
- [x] TypeInfo, RecordField, EnumVariant, TypeInfoKind types registered globally via `type_info_src`
- [x] `zig build test` passes
- [ ] `@typeInfo(T)` computes actual TypeInfo enum variant value
- [ ] `@makeRecord(fields)` creates a concrete record type from field descriptors

### Implementation notes

- Types registered in `comptime.zig` as embedded Zig source (`type_info_src`), parsed and
  inferred during `registerStdlib`
- `RecordField.type` renamed to `RecordField.typeName` because `type` is a keyword
- Builtins dispatch in `inferBuiltinCallReturnType`; only inference-time type resolution,
  no comptime value evaluation yet

---

## Step 3 — Implement `@RecordKeys` + `@Field` builtins

**Status:** pending
**Assignee:**

Two convenience builtins for common type introspection patterns. `@RecordKeys`
returns field names; `@Field` accesses a field by name at comptime.

### Builtin: `@RecordKeys(T: type) -> string[]`

Returns the field names of a record type as a comptime string array.

```botopink
record Person { name: string, age: i32 }
val keys = @RecordKeys(Person);  // ["name", "age"]
```

**Specification:**

| Aspect | Detail |
|--------|--------|
| Type | `fn(comptime T: type) -> string[]` |
| Input | Any record type |
| Output | Array of field name strings, in declaration order |
| Scope | Comptime only |
| Error | `@comptimeError` if T is not a record |

### Builtin: `@Field(value: any, comptime name: string) -> any`

Accesses a record field by name at comptime. Can be used inside a comptime
loop with `@RecordKeys` for dynamic field iteration.

```botopink
record Person { name: string, age: i32 }
fn getField(p: Person, comptime name: string) -> string {
    break @Field(p, name);  // comptime-evaluated field access
}
```

**Specification:**

| Aspect | Detail |
|--------|--------|
| Type | `fn(value: any, comptime fieldName: string) -> any` |
| Input | Any value + compile-time-known field name string |
| Output | The value of the named field |
| Scope | Comptime only |
| Error | `@comptimeError` if field doesn't exist |

**Acceptance criteria:**
- [ ] `@RecordKeys(T)` returns field names for any record type
- [ ] `@Field(value, name)` returns the field value
- [ ] `@comptimeError` on invalid inputs
- [ ] `zig build test` passes

### Files to modify

| File | Purpose |
|------|---------|
| `comptime/builtins.zig` | Register `@RecordKeys`, `@Field` |
| `comptime/eval.zig` | Implement: iterate RecordDecl.fields, return names/values |
| `libs/std/builtins.bp` | Declare `@RecordKeys` and `@Field` |

---

## Step 4 — Design & implement std `mergeRecords`

**Status:** pending
**Assignee:**

`mergeRecords(A, B)` merges two record types into one with all fields.
Conflicting field names with different types produce a `@comptimeError`.

```botopink
// std/reflect.bp
fn mergeRecords(comptime A: type, comptime B: type) -> type {
    val infoA = @typeInfo(A);
    val infoB = @typeInfo(B);

    // Detect conflicts: same name, different types
    loop (infoA.Record.fields) { fa ->
        loop (infoB.Record.fields) { fb ->
            if (fa.name == fb.name and fa.type != fb.type) {
                @comptimeError(
                    "conflito no campo '" + fa.name +
                    "': " + @typeName(fa.type) + " vs " + @typeName(fb.type)
                );
            };
        };
    };

    // Join fields (A first, then B without duplicates)
    var fields: RecordField[] = [];
    loop (infoA.Record.fields) { f ->
        fields = fields.append(f);
    };
    loop (infoB.Record.fields) { fb ->
        var duplicate = false;
        loop (infoA.Record.fields) { fa ->
            if (fa.name == fb.name) { duplicate = true; };
        };
        if (!duplicate) { fields = fields.append(fb); };
    };

    break @makeRecord(fields);
}
```

**Usage:**

```botopink
record User { name: string, id: i32 }
record Timestamps { createdAt: string, updatedAt: string }

val UserWithTimestamps = mergeRecords(User, Timestamps);
// → record { name: string, id: i32, createdAt: string, updatedAt: string }

fn main() {
    val u = UserWithTimestamps(
        name: "alice", id: 1, createdAt: "2024-01-01", updatedAt: "2024-06-01"
    );
    @print(u.name);
    @print(u.createdAt);
}
// expected RUN LOG: alice\n2024-01-01
```

**Conflict detection:**

```botopink
record A { x: i32 }
record B { x: string }

val C = mergeRecords(A, B);
// @comptimeError: conflito no campo 'x': i32 vs string
```

**Acceptance criteria:**
- [ ] `libs/std/reflect.bp` created with `mergeRecords`
- [ ] Comptime tests: no-conflict merge, same-type duplicate merge, conflict error
- [ ] `zig build test` passes

---

## Step 5 — Design & implement std `mapFields`

**Status:** pending
**Assignee:**

`mapFields(T, transform)` iterates all fields of a record, applies a
transformation function, and creates a new record type. This is the
equivalent of TypeScript mapped types `{ [K in keyof T]: V }`.

```botopink
// stdlib/types.bp
fn mapFields(
    comptime T: type,
    comptime transform: fn(field: RecordField) -> RecordField,
) -> type {
    val info = @typeInfo(T);
    var newFields: RecordField[] = [];
    loop (info.Record.fields) { f ->
        newFields = newFields.append(transform(f));
    };
    break @makeRecord(newFields);
}
```

**Usage patterns:**

```botopink
// 1) All fields become bool
record Features { darkMode: bool, newUserProfile: bool, admin: bool }
val FeatureFlags = mapFields(Features, { f -> RecordField(
    name: f.name, type: bool,
) });
// → record { darkMode: bool, newUserProfile: bool, admin: bool }

// 2) Prefix getters
record Store { count: i32, name: string }
val StoreGetters = mapFields(Store, { f -> RecordField(
    name: "get" + @capitalize(f.name),
    type: fn() -> f.type,
) });
// → record { getCount: fn() -> i32, getName: fn() -> string }
```

**Acceptance criteria:**
- [ ] `mapFields` implemented in `libs/std/types.bp`
- [ ] Comptime tests: identity transform, type replacement, field renaming
- [ ] `zig build test` passes

---

## Step 6 — Design & implement std `partial` / `omit` / `pick`

**Status:** pending
**Assignee:**

Three standard type-manipulation functions built on `mapFields` and `@typeInfo`:

```botopink
// std/types.bp

// partial(T): all fields become optional
fn partial(comptime T: type) -> type {
    return mapFields(T, { f -> RecordField(
        name: f.name,
        type: TypeInfo.Optional(f.type),
    ) });
}
// Usage:
record Config { port: i32, host: string, debug: bool }
val PartialConfig = partial(Config);
// → record { port: ?i32, host: ?string, debug: ?bool }

// omit(T, name): remove a single field
fn omit(comptime T: type, comptime name: string) -> type {
    val info = @typeInfo(T);
    var fields: RecordField[] = [];
    loop (info.Record.fields) { f ->
        if (f.name != name) { fields = fields.append(f); };
    };
    break @makeRecord(fields);
}
// Usage:
record FullUser { id: i32, name: string, password: string }
val PublicUser = omit(FullUser, "password");
// → record { id: i32, name: string }

// pick(T, names): keep only specified fields
fn pick(comptime T: type, comptime names: string[]) -> type {
    val info = @typeInfo(T);
    var fields: RecordField[] = [];
    loop (info.Record.fields) { f ->
        var keep = false;
        loop (names) { n ->
            if (f.name == n) { keep = true; };
        };
        if (keep) { fields = fields.append(f); };
    };
    break @makeRecord(fields);
}
// Usage:
val NameOnly = pick(FullUser, ["name", "id"]);
// → record { id: i32, name: string }
```

**Acceptance criteria:**
- [ ] `partial`, `omit`, `pick` implemented in `libs/std/types.bp`
- [ ] Comptime tests for each function
- [ ] `zig build test` passes

---

## Step 7 — Comptime tests for all builtins

**Status:** pending
**Assignee:**

Test each builtin in isolation before testing the std functions that compose them.

**Acceptance criteria:**
- [ ] `@typeInfo(i32)` → `TypeInfo.Int`
- [ ] `@typeInfo(string)` → `TypeInfo.String`
- [ ] `@typeInfo(bool)` → `TypeInfo.Bool`
- [ ] `@typeInfo(?i32)` → `TypeInfo.Optional(inner: i32)`
- [ ] `@typeInfo(i32[])` → `TypeInfo.Array(element: i32)`
- [ ] `@typeInfo(record { x: i32, y: string })` → `TypeInfo.Record(fields: [RecordField("x", i32), RecordField("y", string)])`
- [ ] `@typeInfo(enum { A, B(x: i32) })` → `TypeInfo.Enum(variants: [...])`
- [ ] `@typeInfo(fn(i32, bool) -> string)` → `TypeInfo.Fn(params: [...], returnType: string)`
- [ ] `@TypeOf(42)` → `i32`
- [ ] `@TypeOf("hello")` → `string`
- [ ] `@makeRecord([RecordField("a", i32)])` creates a usable record type
- [ ] `@RecordKeys(record { x: i32, y: string })` → `["x", "y"]`
- [ ] `@Field(record { x: 1, y: 2 }, "x")` → `1`

### Files to create/modify

| File | Purpose |
|------|---------|
| `comptime/tests/builtins_typeinfo.zig` | New test file for type introspection builtins |

---

## Step 8 — Comptime tests for all std functions

**Status:** pending
**Assignee:**

Test each std function at comptime level, verifying type construction and error
detection.

**Acceptance criteria:**
- [ ] `mergeRecords` with disjoint fields → correct merged record
- [ ] `mergeRecords` with same-name same-type → no duplicate field
- [ ] `mergeRecords` with same-name different-type → `@comptimeError`
- [ ] `mapFields` identity transform → equivalent record
- [ ] `mapFields` type replacement → correct new record
- [ ] `partial(T)` → all fields become `?type`
- [ ] `omit(T, name)` → field removed
- [ ] `pick(T, names)` → only specified fields kept
- [ ] `zig build test` passes

---

## Summary

| Metric | Count |
|--------|-------|
| New builtins | 5 (`@typeInfo`, `@TypeOf`, `@makeRecord`, `@RecordKeys`, `@Field`) |
| New std functions | 4 (`mergeRecords`, `mapFields`, `partial`, `omit`; `pick` is bonus) |
| Comptime tests | ~20 |

### Key findings

1. **Three core builtins unlock all type manipulation:** `@typeInfo` (read),
   `@TypeOf` (identify), `@makeRecord` (write). Everything else is std
   functions composed from these.

2. **`@RecordKeys` + `@Field` are convenience builtins** — they could be
   implemented in user-space if the comptime eval supported loops over
   `TypeInfo.Record.fields` with dynamic field access. Until then, they're
   builtins (~20 lines of Zig each).

3. **No codegen tests in this spec** — the std functions produce types at
   comptime. Codegen tests for the *values produced by these types* go in
   `1_0_0_beta.codegen-test-gap.md`.

4. **`@makeRecord` is the key differentiator** — without it, type
   introspection is read-only. With it, the type system becomes programmable.

## Notes

- All builtins are comptime-only. They expand to literal types/values during
  compilation and produce zero runtime code.
- The `TypeInfo` enum and `RecordField` / `EnumVariant` records must be
  declared in `libs/std/builtins.bp` so user code can pattern-match on
  introspection results.
- `@typeInfo` for function types (`TypeInfo.Fn`) opens the door to
  `ReturnType<T>`, `Parameters<T>`, and function decorator validation — but
  those are future specs.

## Changelog

| Date | Change | Author |
|------|--------|--------|
| 2026-06-30 | Spec created — comptime type introspection builtins + std functions | ericfillipe |
| 2026-06-30 | Steps 2-4/6-7 completed: builtins resolve types during inference; mergeRecords/partial/omit/pick implemented as inference-time type manipulators; 23 snapshot tests | ericfillipe |
| 2026-06-30 | RecordField.type renamed to typeName (type is a keyword); TypeInfo types registered via embedded Zig source, not builtins.bp | ericfillipe |
| 2026-06-30 | Step 5 (mapFields) deferred — requires comptime lambda evaluation | ericfillipe |
| 2026-06-30 | @comptimeError not yet implemented; std function .bp files are stubs | ericfillipe |
