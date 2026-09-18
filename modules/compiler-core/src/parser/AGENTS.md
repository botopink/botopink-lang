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
│                     as identifiers
├── tests.zig      ← barrel: aggregates tests/<feature>.zig for test_root.zig
└── tests/         ← parser tests, split by feature
    ├── helpers.zig       ← shared harness (`assertParser`/`expectParseError`/…)
    ├── imports.zig       ← import/activate/delegate declarations
    ├── declarations.zig  ← record/enum/interface/implement, val/pub/fn, effect fns, test blocks
    ├── expressions.zig   ← operator/lambda/array/tuple/case/builtin/control-flow
    ├── destructuring.zig ← destructure/shorthand/assign
    ├── errors.zig        ← parse errors & cross-stage error-message units
    ├── surface.zig       ← the 1.0.3 surface: `type` shapes, the field list, `behavior`, separators, and old-vs-new AST equality
    ├── decision8.zig     ← decision 8's grammar, one section per row: `unknown` (N19), union types (N20), `is` (N21), `case` arms (N22)
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

## `unknown` in type position (decision 8 §2, 06 N19)

`unknown` arrives as its own keyword token, so `parseBaseTypeRef` handles it
before `consumeTypeName` and no user type can shadow it. It lands as
`TypeRef.named = ast.unknown_type_name` (`ast.zig` documents what inference owes
it) and takes the ordinary `[]` wraps — `unknown[]`, `?unknown`, `Box<unknown>`
all parse. `unknown<…>` / `unknown(…)` is refused at the `<` / `(` with
`unknown-takes-no-arguments`: it is one type, not a constructor.

## Union types `A | B` (decision 8 §3, 06 N20)

`parseTypeRef` is the alternation: it parses one member through
`parseTypeRefMember` — everything a type can be except a `|` chain — and keeps
going while a `|` follows. So `|` binds looser than every other type operator:
`i32 | string[]` is "`i32`, or an array of `string`", and an array of the union
is written `(i32 | string)[]`. Two or more members land as
`TypeRef.generic{ .name = ast.union_type_name, .args = <members> }` — a spelling
no source can write, documented in `ast.zig` with what inference owes it. A `|`
with nothing usable after it is `union-member-missing`, located at the bar.

The `type A | B` meta-kind keeps its own `|`: `parseGenericParams`' constraint
loop calls `parseTypeRefMember`, so each constraint stays one type.

## `x is T` as an expression (decision 8 §4, 06 N21)

`parseIsExpr` sits at the tightest level of the expression grammar, between
`parseBinaryExpr`'s last precedence level and `parsePrimary`: `a is i32 == b` is
`(a is i32) == b`, and `if (v is string)` needs no parentheses of its own. The
right side is a full type — `i32`, `Point`, `#(i32, string)`, `Box<unknown>`, a
union — parsed by `parseTypeRef`.

It lands as the `is` builtin call (`ast.is_builtin_name`) with the value as its
only argument and the tested type on the node's `isType`, since a type is not an
expression; `ast.zig` documents what inference owes it, and the slot is left out
of the AST dump when null, so no call snapshot moved. `is` with no type after it
is `is-missing-type`; the payload-binding form `x is Some(v)` (§4.2) is
`is-variant-binding`, located at the `(` — the node carries a type, so the
binding form is refused where it starts instead of failing further along.

## `case` arms and patterns (decision 8 §5, 06 N22)

Two arm forms coexist, told apart by the token after the pattern and its
optional guard:

| Form | Body |
|---|---|
| `Pattern { body }` — decision 8 §5.1 | a lambda body: `{ n -> … }` binds the whole matched value (P1), the last expression is the arm's value (P3), and the arm takes no `;` (P2) |
| `pattern -> value;` — pre-decision-8 | unchanged; `libs/std` and the libraries are written this way, and 12 step 3 / 13 migrate them |

The guard is `when (…)` (§5.3) or the older `if <expr>`. `when` is **not** a
keyword: it is special only after an arm's pattern, matched by lexeme, so a
variable called `when` is untouched. `checkWhenGuard` also keeps the two-name
pattern `Ok ok` from swallowing it.

The pattern grammar (`parseSimplePattern`) reads, beyond the pre-decision-8
forms: a dotted variant path (`Shape.Circle`), the dot shorthand (`.Some`,
`.None` — the leading `.` stays in the name, which is what tells a variant path
from a binding), labelled payload elements (`Rect(width: w, height: h)`), a
trailing `..` (P7), a `#(…)` tuple pattern (P6), an `A...B` inclusive range
(§5.2) and a pattern nested inside a payload (`.Some(#(a, b))`). One payload
production serves variants and tuples; a payload of nothing but plain binders
keeps the `fields` shape every existing consumer knows, anything else becomes
`literals`. `ast.zig` documents the node each shape lands on and what inference
owes it.

Five located refusals, all in `print.zig`: `pattern-range-exclusive` (`1..9` —
`..` is iteration), `pattern-range-missing-end`, `pattern-rest-not-last`,
`pattern-tuple-label` (a tuple pattern is positional) and, for the
`Pattern { body }` form only, `case-bare-name-arm` and `case-constant-pattern`
(§5.2's two rewrites). The last two judge a name by shape — a dotted path,
`true`/`false` and the primitive type names are patterns; an all-upper-case name
is a constant; any other lower-case name is a variable. `isPrimitiveTypeName`
mirrors `Env.registerBuiltins` in `comptime/env.zig`, as the language server's
`isPrimitiveType` does; keep the three in step. The arrow arm is never judged:
binding the matched value with a bare name is exactly how it is written today.

### What the formatter does with an arm

`format.zig` writes an arm back in the form its body carries: a lambda body is
decision 8's `Pattern [when (…)] { body }` (no arrow, no `;`, the binder kept),
anything else the older `pattern [if …] -> value;`. The pre-decision-8 block arm
`x -> { 1; }` is a parameterless lambda too, so it comes back as `x { 1 }` —
the same AST, decision 8's spelling; no library writes one today. Two residuals
for the formatter pass: a lambda body's last expression is still written with a
trailing `;`, which §5.1 P3 does not want, and a `case` whose arms carry
comments still loses their position.

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
