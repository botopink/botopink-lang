# Comptime Type Evaluation & First-Class Types

**Version:** 1.0.0-beta
**Status:** planning
**Created:** 2026-06-30
**Author:** ericfillipe
**Depends on:** `1_0_0_beta.comptime-type-introspection.md`

---

## Status

**Current:** planning

| Step | Title | Status |
|------|-------|--------|
| Step 1 | `type` as first-class comptime value | pending |
| Step 2 | `@typeInfo(T)` value evaluation | pending |
| Step 3 | `@TypeOf(v)` returning concrete type | pending |
| Step 4 | `@Field(v, name)` comptime evaluation | pending |
| Step 5 | `@RecordKeys(T)` string array evaluation | pending |
| Step 6 | `mapFields` with lambda evaluation | pending |
| Step 7 | Comptime evaluation loop for std functions | pending |
| Step 8 | `.bp` std files compiling as modules | pending |
| Step 9 | `@make` shorthand for named-arg type construction | pending |

## Objective

Complete the comptime type introspection system by making `type` a first-class
comptime value and building the evaluation infrastructure needed for:

1. Builtins that compute VALUES (`@typeInfo`, `@RecordKeys`, `@Field`)
2. Builtins that compute TYPES (`@TypeOf`)
3. Std functions in `.bp` files (`mergeRecords`, `mapFields`, `partial`, `omit`, `pick`)

## Prerequisites

- `zig build test` passing (current)
- TypeInfo/RecordField types registered (done in previous spec)
- `makeSyntheticRecordType` available (done)
- Inference-time type manipulation builtins working (done)

---

## Step 1 — `type` as first-class comptime value

`type` becomes a valid type annotation and value at comptime. A binding can
hold a type value:

```botopink
val T = i32;              // T: type = i32
val Point = record { x: i32, y: i32 };  // Point: type
val Result_i32_string = @Result<i32, string>;  // generic instantiation
```

Types can be passed as `comptime T: type` params and returned from functions:

```botopink
fn identityType(comptime T: type) -> type {
    break T;
}
val SameType = identityType(i32);  // i32
```

### Implementation

- Register `"type"` as a builtin type in `Env.registerBuiltins`
- The type of a type is `type`
- `type` values unify with `"type"` named type
- Parser: support `val x: type = ...` and `comptime x: type` in param lists
- `env.bind(name, typeValue)` sets the binding type to `type`

---

## Step 2 — `@typeInfo(T)` value evaluation

When `T` is a concrete type known at inference time, compute the actual TypeInfo
enum variant value.

```botopink
val info = @typeInfo(i32);         // TypeInfo.Int
val info2 = @typeInfo(Point);      // TypeInfo.Record(fields: [...])
```

### Implementation

- In `inferBuiltinCallReturnType` or a new comptime evaluation hook:
  - Check T's type definition via `env.lookupTypeDef`
  - For primitives: return `TypeInfo.Int/Float/Bool/String`
  - For records: build `TypeInfo.Record` with field descriptors
  - For enums: build `TypeInfo.Enum` with variant descriptors
  - For fns: build `TypeInfo.Fn` with param/return type descriptors
- The result is a TypedExpr holding a TypeInfo literal value
- Codegen: emit the TypeInfo enum variant as a constant

---

## Step 3 — `@TypeOf(v)` returning concrete type

When `v` is a value expression, return its actual type as a `type` value.

```botopink
val x: i32 = 42;
val T = @TypeOf(x);  // T: type = i32
```

Requires Step 1 (`type` as value).

---

## Step 4 — `@Field(v, name)` comptime evaluation

Access a record field by compile-time-known name. Returns the field VALUE.

```botopink
val p = Point(x: 1, y: 2);
val xVal = @Field(p, "x");  // 1
```

### Implementation

- Look up the record type of `v`
- Find the field by name
- Return a TypedExpr representing the field access
- Codegen: emit field access expression

---

## Step 5 — `@RecordKeys(T)` string array evaluation

Return the field names of a record type as a comptime string array.

```botopink
record Point { x: i32, y: string }
val keys = @RecordKeys(Point);  // ["x", "y"]
```

### Implementation

- Look up T's type definition
- Get field names from the TypeDef
- Return a literal string array value

---

## Step 6 — `mapFields` with lambda evaluation

Implement `mapFields(T, transform)` where `transform` is a comptime lambda
that takes a `RecordField` and returns a `RecordField`.

```botopink
val NullablePoint = mapFields(Point, { f -> RecordField(
    name: f.name, typeName: "?" + f.typeName,
) });
```

### Implementation

- During inference, when `mapFields` is called:
  - Get T's fields
  - For each field, evaluate the lambda body with the field substituted
  - Collect results into a new field list
  - Call `@makeRecord` on the result
- Requires comptime evaluation of lambda bodies with variable substitution

---

## Step 7 — Comptime evaluation loop for std functions

Enable `.bp` functions with `comptime` params to be evaluated during inference
by building an evaluation loop that:

1. Resolves comptime params to their concrete values
2. Evaluates the function body expression by expression
3. Handles builtins (`@typeInfo`, `@RecordKeys`, `@makeRecord`, `@comptimeError`)
4. Handles loops over comptime arrays
5. Handles `break` with a type value
6. Handles if/else with comptime conditions

### Implementation

- Extend `specialize.zig` or create a new `comptime/eval_types.zig`
- When a comptime function returns `type`, evaluate the body and return the computed type
- When a comptime function returns a value, evaluate and return

---

## Step 8 — `.bp` std files compiling as modules

Once Steps 1-7 are complete, the `.bp` std files (`libs/std/src/reflect.bp`,
`libs/std/src/types.bp`) should compile as regular std modules:

```botopink
import { mergeRecords } from "std/reflect";
import { partial, omit, pick } from "std/types";
```

### Implementation

- Register `reflect.bp` and `types.bp` in `build.zig` `std_pkg_files`
- The comptime evaluation loop handles the function bodies
- Existing inference-time builtins handle the calls if evaluation is not ready

---

## Step 9 — `@make` builder pattern (replaces `@makeRecord`)

`@make` takes an enum variant describing the type to construct. The enum acts
as a type-constructor DSL — one variant per type shape. This replaces the
separate `@makeRecord` builtin.

```botopink
// Builder enum — one variant per type shape
enum TypeCtor {
    Record(fields: RecordField[]),
    Optional(inner: type),
    Array(elem: type),
}

// Literal usage: pass Record variant with named args
val Point = @make(TypeCtor.Record(fields: [
    RecordField(name: "x", typeName: "i32"),
    RecordField(name: "y", typeName: "i32"),
]));

// Computed usage (from @typeInfo results):
fn mergeRecords(comptime A: type, comptime B: type) -> type {
    // ... compute fields ...
    break @make(TypeCtor.Record(fields: mergedFields));
}
```

### Implementation

- Parser: `@make(Variant(args))` as builtin call form
- At inference time: dispatch on variant name
  - `TypeCtor.Record` → `makeSyntheticRecordType` with extracted fields
  - `TypeCtor.Optional` → wrap inner type
  - `TypeCtor.Array` → create array type
- `@makeRecord` is deprecated/removed in favor of `@make(TypeCtor.Record(...))`

---

## Summary

| Metric | Count |
|--------|-------|
| New type | 1 (`type` as first-class value) |
| Enhanced builtins | 5 (value evaluation for existing builtins) |
| New builtin | 1 (`@make` shorthand) |
| Evaluation infrastructure | 1 (comptime evaluation loop) |
| Compilable `.bp` modules | 2 (`reflect.bp`, `types.bp`) |

## Notes

- Steps 1-5 are small, individually implementable features
- Steps 6-7 are the major work: comptime evaluation infrastructure
- Step 8 is the integration point that proves everything works
- Step 9 is optional polish
