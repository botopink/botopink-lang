# compiler-core/src/parser

> Path: `modules/compiler-core/src/parser/`
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Docs: [`./docs.md`](docs.md) · Examples: [`./examples.md`](examples.md)

Parser sub-grammars + tests. The `Parser` struct (state, token cursor, shared
helpers) lives at `../parser.zig`; each weakly-coupled sub-grammar is split into
a sibling module here.

## Free-function-on-`*Parser` convention

`usingnamespace` was removed in Zig 0.15, so the split uses free functions on
`*Parser` instead of methods. Each sibling module declares
`pub fn parseX(this: *Parser, …)` and `parser.zig` re-exports it as a thin alias:

```zig
// in parser.zig, inside the Parser struct:
pub const parseTypeRef = types.parseTypeRef;
```

That alias keeps method-call syntax (`this.parseTypeRef(alloc)`) resolving at
every call site — internal and external (LSP, codegen, `parse`) — with zero
churn. The `Parser` struct + all state + the token cursor stay **only** in
`parser.zig`; sibling modules `@import("../parser.zig")` and alias the types /
shared static helpers they reference. The `parser.zig` ↔ `parser/*.zig` import
cycle is fine because no struct-layout depends on it.

## Tree

```text
parser/
├── AGENTS.md      ← you are here
├── docs.md        ← parser strategy, helpers, error policy
├── examples.md    ← `.bp` declarations / expressions / statements
├── types.zig      ← type-ref sub-grammar: parseTypeRef/BaseTypeRef/GenericParams/ImplementClause
├── patterns.zig   ← case/pattern sub-grammar: parseCaseExpr/parsePattern/SimplePattern/ListPattern
├── decls.zig      ← declaration sub-grammar: val/fn/test/struct/record/enum/interface/implement/extend/delegate/import + params
├── exprs.zig      ← expression sub-grammar: precedence climbing, primary/pipeline/local-bind/lambda/loop/range,
│                     string templates (`${…}` re-scan), tagged calls
├── tests.zig      ← barrel: aggregates tests/<feature>.zig for test_root.zig
└── tests/         ← parser tests, split by feature
    ├── helpers.zig       ← shared harness (`assertParser`/`expectParseError`/…)
    ├── imports.zig       ← import/activate/delegate/star declarations
    ├── declarations.zig  ← struct/record/enum/interface/implement, val/pub/fn, test blocks
    ├── expressions.zig   ← operator/lambda/array/tuple/case/builtin/control-flow
    ├── destructuring.zig ← destructure/shorthand/assign
    └── errors.zig        ← parse errors & cross-stage error-message units
```

## Testing pattern

```zig
test "import decl" {
    try assertParser(std.testing.allocator, @src(), "import {std.List as L, X*};");
}
```

- Snapshot path: `../../snapshots/parser/<slug>.snap.md`
- Error tests: `expectParseError(source, "expected message")`

## Type-ref grammar (`types.zig`)

`parseBaseTypeRef` handles `?T`, `#(…)` tuples, `fn(…) -> R` function types,
`@Name<…>` builtins, `type` meta-kinds, plain names with `<…>`/`[]` wraps, and
two additions for record/builder ergonomics:

- **Function-type params may be named** — `fn(next: T)` parses alongside the
  bare `fn(T)`; the name is documentation-only (function types are positional)
  and is discarded.
- **Anonymous record types** — `{ value: T, set: fn(T) }` parses to
  `TypeRef.record_type` (a `[]RecordTypeField`), usable as any annotation /
  return type; inference resolves it to a structural `Type.record`.

A non-`syntax` `name: fn(…)` param is parsed through `parseTypeRef` (a
`TypeRef.function`, so its return may be an array — `fn() -> T[]`); the legacy
string-based `Param.fnType` is kept **only** for `syntax fn(…)` params.

## Soft keywords `get` / `set`

`get`/`set` introduce struct getters/setters only at the **start** of a struct
member; everywhere else they are ordinary names. `Parser.isMemberName` /
`consumeMemberName` accept `identifier`/`get`/`set` and back the record field
names, record-literal labels, destructuring names, member access, method-call
names, and named-call labels — so a hook can return the shape `{ value, set }`
with `set` a function field (`s.set(x)`).

## Postfix-chain locs

Each link in a `.field` / `?.field` / `.method(args)` postfix chain carries the
loc of **its own member token**, never the shared base loc. Downstream lowering
is loc-keyed (e.g. `instanceLowerings` records `arr.length` → host length op by
the access loc), so two links sharing a loc collide — `self.pairs.length` would
emit `length(length(Self))`. `parsePostfixChain` and the identifier postfix loop
both use `locFromToken(fieldTok)` for this reason.

## Annotation arguments (`parseAnnotationCall`)

`#[name(arg, …)]` / `@name(…)` arguments are kept as **raw lexemes**
(`Annotation.args: [][]const u8`), not parsed expressions. The arg loop special-cases
two shapes so the `#[@external]` vocabulary stays expressible (see §A,
`libs/std/AGENTS.md`):

- **Enum/member chains** — `.Erlang`, `Target.Erlang`: a run of adjacent
  `.`/identifier tokens is folded into a single argument lexeme spanning the source
  bytes (`spanLexemes`). The bare single identifier (`erlang`) and string literals
  go through unchanged.
- **Keyword labels** — `runtime:`/`module:`/`method:`: a leading `identifier :` is
  dropped, so the labeled Form B and positional Form A produce the same `args`.

## Notes

- AST nodes are `union(enum)`; always call `deinit(alloc)` on heap-allocated
  branches.
- `Parser.init(tokens)` does **not** store an allocator; parse methods receive
  `alloc: std.mem.Allocator`.
- **Package-default DSL** (`package-default-dsl`): `pub default mod Name;` parses
  at any module top level (`checkDefaultMod` mirrors `checkDefaultFn`;
  `parseModDecl` reads the optional `default` modifier → `ModDecl.isDefault`).
  Pairs with `pub default fn` (`FnDecl.isDefault`) and the package-namespace
  `import pkg [, { … }] [from "…"]` form (`ImportDecl.package`, parsed in
  `decls.zig`). The parser only records the modifier — uniqueness is validated in
  inference, and the resolver/driver (`comptime.zig`) binds the handle.
