# compiler-core/src/parser

> Path: `modules/compiler-core/src/parser/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Parser sub-grammars + tests. The `Parser` struct (state, token cursor, shared
helpers) lives at `../parser.zig`; each weakly-coupled sub-grammar is split into
a sibling module here.

## Free-function-on-`*Parser` convention

Zig has no `usingnamespace`, so the split uses free functions on `*Parser`
instead of methods. Each sibling module declares
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
├── types.zig      ← type-ref sub-grammar: parseTypeRef/BaseTypeRef/GenericParams/ImplementClause
├── patterns.zig   ← case/pattern sub-grammar: parseCaseExpr/parsePattern/SimplePattern/ListPattern
├── decls.zig      ← declaration sub-grammar: val/fn/test/type/behavior/implement/extend/delegate/import + params;
│                     the 1.0.3 `type`/`behavior` declarations: `parseTypeDecl`/`parseShorthandTypeDecl`
│                     (shared `parseFieldList`, shape resolution, `type-*` diagnostics), `parseBehaviorDecl`/`parseShorthandBehaviorDecl`
│                     (member separators: bodyless members end with `;` — `member-comma-separator` / `member-missing-semicolon`)
├── template_markers.zig ← decision 5: `@External` template markers are positional over the declared parameters
│                     (`$0` is `self` on a method). `Parser.parse` runs `normalizeProgram` once: it translates each
│                     template to the renderers' receiver convention (`primOpTemplate.receiver_marker`, `$N` shifted;
│                     `self`-first top-level fns on Erlang/Beam too), keeps the source in `Annotation.source_args`
│                     (formatter, AST dump), and refuses `$self` / an out-of-range `$N` with a located
│                     `template-self-marker` / `template-marker-out-of-range`
├── exprs.zig      ← expression sub-grammar: precedence climbing, primary/pipeline/local-bind/lambda/loop/range,
│                     string templates (`${…}` re-scan), tagged calls. `loop` has four forms (decision 8 §10):
│                     `loop (xs) { x -> }`, `loop (0..n) { i -> }`, `loop (cond) { … }` (a body that does not
│                     open with `name ->` takes no parameter; `LoopExpr.paramsLoc` locates the first one) and
│                     `loop { … }` (the condition `true`). `LoopExpr.condition` is set here for `loop { … }` and a
│                     syntactically boolean condition (a comparison, `&&`/`||`, `not`, `true`/`false`); the comptime
│                     transform sets it for any other `iter` inference typed `bool` (`env.conditionLoops`). `while (…)` is `removed-keyword-while` and
│                     `throw new X(…)` is `removed-keyword-new` (06 N26, N27) — `new`/`delegate`/`const` lex
│                     as identifiers. `val assert P = e;` with no `catch` (decision 8 § 9) parses:
│                     `assertFatalHandler` desugars it into the handler `@panic("assert pattern did not
│                     match")` and sets `AssertPattern.fatal`, so the AST keeps one shape and every
│                     backend's handler lowering is the fatal path; the checker reads `fatal` to tell
│                     the two forms apart. The formatter therefore re-prints the desugared `catch` —
│                     the honest AST (an optional handler) waits for the formatter front
├── tests.zig      ← barrel: aggregates tests/<feature>.zig for test_root.zig
└── tests/         ← parser tests, split by feature
    ├── helpers.zig       ← shared harness (`assertParser`/`expectParseError`/…)
    ├── imports.zig       ← import/activate/delegate declarations
    ├── declarations.zig  ← record/enum/interface/implement, val/pub/fn, effect fns, test blocks
    ├── expressions.zig   ← operator/lambda/array/tuple/case/builtin/control-flow
    ├── destructuring.zig ← destructure/shorthand/assign
    ├── errors.zig        ← parse errors & cross-stage error-message units
    ├── surface.zig       ← the 1.0.3 surface: `type` shapes, the field list, `behavior`, separators, and old-vs-new AST equality
    └── effect_rejections.zig ← parser-level `#[@<effect>]` rejections (R1/R2/R5…)
```

## Testing pattern

```zig
test "import decl" {
    try assertParser(std.testing.allocator, @src(), "import {std.List as L, X*};");
}
```

- Snapshot path: `modules/compiler-core/snapshots/parser/<slug>.snap.md` (slug from the test name)
- Error tests: `expectParseError(alloc, "expected rendered message", source)` — it FAILS when the parse produced no `parseError` (nothing would be rendered), so the expected text is always compared; `expectParseFails(alloc, source)` only checks that parsing fails

## Type-ref grammar (`types.zig`)

`parseBaseTypeRef` handles `?T`, `#(…)` tuples, `fn(…) -> R` function types,
`@Name<…>` builtins, `type` meta-kinds, plain names with `<…>`/`[]` wraps, and
two additions for record/builder ergonomics:

- **Function-type params may be named** — `fn(next: T)` parses alongside the
  bare `fn(T)`; the name is documentation-only (function types are positional)
  and is discarded.
- **The removed anonymous record type** — `{ value: T, … }` in type position
  raises `removed-record-type` at the `{` (1.0.3: a labeled tuple type
  `#(value: T, …)`).

A non-`syntax` `name: fn(…)` param is parsed through `parseTypeRef` (a
`TypeRef.function`, so its return may be an array — `fn() -> T[]`);
`Param.fnType` (`ast.FnType`) is set **only** for `syntax fn(…)` params.

## Postfix-chain locs

Each link in a `.field` / `?.field` / `.method(args)` postfix chain carries the
loc of **its own member token**, never the shared base loc. Downstream lowering
is loc-keyed (e.g. `instanceLowerings` records `arr.length` → host length op by
the access loc), so two links sharing a loc collide — `self.pairs.length` would
emit `length(length(Self))`. `parsePostfixChain` and the identifier postfix loop
both use `locFromToken(fieldTok)` for this reason.

## Type guards (`-> x is T`)

`fn f(x: ?string) -> x is string` parses to `typeGuardParam = "x"`, `typeGuardType = string` and
`returnType = bool` — a guard answers a `bool` (06 C5). The narrowed type is dumped only when it is
there: `stringifyOmitting`'s `omitIfEmpty` list now also skips a null optional, so the slot costs no
line in the dump of a fn that is not a guard.

## Type-annotation locations

`Param.typeLoc`, `Field.typeLoc` and `FnDecl`/`BehaviorMethod`'s `returnTypeLoc` hold the first token
of the annotation (`x: Foo` → `Foo`'s column, `-> Foo` → `Foo`'s). `decls.zig` sets them next to
every `parseTypeRef` call; `{0,0}` means the declaration was synthesised. They exist so an unknown
type name reds at the annotation (06 N30) and are kept out of the AST dumps by the `jsonStringify`
of each struct, so adding one moved no snapshot.

## Error locations (`ParseErrorInfo`)

Build every diagnostic with `ParseErrorInfo.fromToken(kind, tok)` (or
`fromTokenDetail` / `fromTokenSpan`) — never by filling the struct inline.
`start`/`end` are **byte offsets**: `print.render` resolves the rendered line
by scanning the source up to `start`, and `lsp_types.spanToRange` builds the
LSP range from the same pair. The 20 sites used to store `tok.col - 1` there,
so every error in a file with more than one line rendered on line 1 with the
carets under whatever happened to sit at that column.

`line`/`col` are carried too, for callers that have no source text.

## `${…}` interpolation holes

A hole's source is sub-lexed and sub-parsed on its own (`makeStringExpr` in
`exprs.zig`), so its tokens come back positioned from 1:1 of the hole slice.
`retargetHoleTokens` maps them back through `contentPos` before the sub-parse:
a hole token's offset inside the hole is its displacement inside the literal's
content, and content line `k` is source line `tok.line + k` (for a `\\ …` line
string, plus that line's stripped `<indent>\\` prefix). Without it every
interpolated expression claimed 1:1.

## Tagged calls

`html """…"""` lowers to a call located at the head identifier; `db.sql "…"`
lowers to a call located at the **member** (`sql`), via `makeCallAt`, exactly
like an ordinary method-call link — see "Postfix-chain locs" above. The same
rule applies to the pipeline RHS `|> Recv.method(args)`.

## Retired surface

The `@[name(…)]` annotation-block opener (spec 05 §5.12) is **rejected** with
`ParseErrorType.retiredAnnotationBlock`. The lookaheads still recognise `@[`
so the stale form reaches that diagnostic instead of a bare unexpected-token
error. Annotation blocks are `#[…]`; `@` marks a builtin annotation inside one.

## Annotations (`parseAnnotationCall`)

The annotation name may be a qualified path — `@External.Erlang(…)` lands as
`Annotation.name = "External.Erlang"` with `is_builtin = true` (leading `@`
stripped). Arguments are kept as **raw lexemes** (`Annotation.args: []const []const u8`),
not parsed expressions; each reader (`FnDecl.externalFor`,
`ast.parseArityBranchArg`, …) interprets them. The arg loop special-cases three
shapes (vocabulary in `libs/std/AGENTS.md`):

- **Arity branches** — `when($argc == N): "<template>"` spans the balanced parens,
  the `:` and the value into one lexeme (`spanLexemes`).
- **Labels** — a leading `identifier :` or `identifier =` (`module:`,
  `inline = true`) is dropped; the value lands positionally.
- **Enum/member chains** — `.Erlang`, `Target.Erlang`: adjacent `.`/identifier
  tokens fold into one lexeme spanning the source bytes. A bare identifier or
  string literal goes through unchanged.

## Comments and declaration ids

At top level a comment is its **own** declaration (`DeclKind.comment`, with
`is_module` / `is_doc`); the `docComment` / `comment` / `moduleComment` fields
on the neighbouring declaration are left null by this path. Inside a fn body a
comment is a statement carrying a loc. `nextId` is a **per-kind** counter:
records and enums are both `TypeDecl`s and share the `type` counter;
interfaces are `BehaviorDecl`s on the `behavior` counter. Each starts at 1.
Records and enums parse into one `DeclKind.type_` (`TypeDecl`, whose `shape` is
`.record` fields or `.enum_` variants + sections); interfaces into
`DeclKind.behavior` (`BehaviorDecl`). The surface syntax is still
`record`/`enum`/`interface` (1.0.4-beta front 12 step 1).
Both are pinned by snapshots (`comments_…`, `decl_ids_…`).

## Notes

- AST nodes are `union(enum)`; always call `deinit(alloc)` on heap-allocated
  branches.
- `Parser.init(tokens)` does **not** store an allocator; parse methods receive
  `alloc: std.mem.Allocator`.
- **Package default**: `pub default mod Name;` parses
  at any module top level (`checkDefaultMod` mirrors `checkDefaultFn`;
  `parseModDecl` in `parser.zig` reads the optional `default` modifier →
  `ModDecl.isDefault`).
  Pairs with `pub default fn` (`FnDecl.isDefault`) and the package-namespace
  `import pkg [, { … }] [from "…"]` form (`ImportDecl.package`, parsed in
  `decls.zig`). The parser only records the modifier — uniqueness is validated in
  inference, and the resolver/driver (`comptime.zig`) binds the handle.
- **Enum sections**: an `Identifier { … }` item
  inside an enum body declares a *section* — a named grouping of nested
  variants — captured as `EnumSection { name, variants, sections }` and stored
  on the enum shape of the `TypeDecl` (`TypeShape.enum_.sections`) alongside the flat `variants` slot. Sections nest
  arbitrarily deep; inside a section body, pure-digit tokens (`100`, `4`) are
  permitted as terminal variant leaves (`EnumVariant.numeric = true`) — they
  cannot open further sections nor carry payload. Top-level enum bodies reject
  digit names. Disambiguation is single-token (`{` after a name = section,
  `(` = payload, `,`/`}` = bare). The comptime desugars the tree into the
  enum-of-enum form with mangled inner names; the parser only records the
  structure.

## The removed 1.0.2 surface (front 12 step 4)

`record`, `enum` and `interface` lex as identifiers. Where a declaration would
start — top level, after annotations, after `pub`, or as a val-form body —
`Parser.removedDeclKeywordAt` recognises the word when a name, `{`, `<` or `fn`
follows, and `failRemovedDeclKeyword` records a located diagnostic:
`removed-keyword-record`, `removed-keyword-enum`, `removed-keyword-interface`.
`record {` in an expression (and `val lower = record { … }`) is
`removed-record-literal`; `{` in type position is `removed-record-type`. The
messages (`print.zig`) name the 1.0.3 spelling. The words stay usable as
ordinary identifiers (`val record = 1`).
