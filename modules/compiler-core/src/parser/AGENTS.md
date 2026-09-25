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
├── decls.zig      ← declaration sub-grammar: val/var/fn/test/type/behavior/implement/extend/delegate/import + params;
│                     the import list of decision 107 (`parseImportItems` / `parseImportItemInto`): a dotted path
│                     (`a.b.c ("*" | "as" x)?`) and a braced group (`a: {b: {c}}`) flatten to the same `ImportPath`
│                     per leaf, the group's prefix written into `segments`; `*`/`as` on a node that opens braces
│                     is `importGroupModifier`; `parseImportItem` (one leaf) serves the `X*;` activation statement
│                     the type alias `[pub] type Name<A> = T;` (`isTypeAliasAt` lookahead — `=` after the name and its
│                     `<…>` —, `parseTypeAliasDecl`; plain parameter names, `;` required, no annotation),
│                     the 1.0.3 `type`/`behavior` declarations: `parseTypeDecl`/`parseShorthandTypeDecl`
│                     (shared `parseFieldList`, shape resolution, `type-*` diagnostics), `parseBehaviorDecl`/`parseShorthandBehaviorDecl`
│                     (member separators: bodyless members end with `;` — `member-comma-separator` / `member-missing-semicolon`)
├── template_markers.zig ← decision 5: `@External` template markers are positional over the declared parameters
│                     (`$0` is `self` on a method). `Parser.parse` runs `normalizeProgram` once: it translates each
│                     template to the renderers' receiver convention (`primOpTemplate.receiver_marker`, `$N` shifted;
│                     `self`-first top-level fns on Erlang/Beam too), keeps the source in `Annotation.source_args`
│                     (formatter, AST dump), and refuses `$self` / an out-of-range `$N` with a located
│                     `template-self-marker` / `template-marker-out-of-range`
├── exprs.zig      ← expression sub-grammar: precedence climbing, primary/pipeline/local-bind/lambda/loops/range,
│                     string templates (`${…}` re-scan), tagged calls. The loops are decision 105's three keywords,
│                     one parser each and one `LoopExpr` node (`keyword` says which): `parseForExpr` —
│                     `for [await] [:label] (iter) { x -> … }` over a collection, a range (`a..b` exclusive,
│                     `a...b` inclusive — `parseRangeExpr` reads both tokens) or a generator, binding exactly one
│                     name (`for-without-binder` / `for-binds-one-name`; `paramsLoc` locates it); `parseWhileExpr` —
│                     `while [:label] (cond) { … }`, the condition at `prec.lowest` like an `if`'s; `parseLoopExpr` —
│                     `loop [:label] { … }` (`condition` over the literal `true`). A binder on `while`/`loop` is
│                     `loop-binds-nothing`; `loop (…)` is `removed-loop-parenthesised` at the keyword, naming `for`
│                     and `while`. `parseGenLoopExpr` reads `iter` / `stream` before `loop` /
│                     `while` / `for` (decision 125; `genLoopPrefixAhead` — the two words are contextual, an
│                     identifier anywhere else): `iter loop` is the prefixed `loop` node, `iter while` / `iter for`
│                     the prefixed `loop { <written loop>; break; }` with `prefixedKeyword` recording the keyword;
│                     `LoopExpr.generator` carries `.iterator` / `.stream`. An annotation block before a loop is
│                     `loop-annotation-not-generator` (`parseAnnotatedLoopExpr`), a removed effect annotation there
│                     `effect-annotation-removed` with the `iter` / `stream` fix-it. `throw new X(…)` is
│                     `removed-keyword-new` (06 N27) — `new`/`delegate`/`const` lex as identifiers. `val assert P = e;` with no `catch` (decision 8 § 9) parses:
│                     `assertFatalHandler` desugars it into the handler `@panic("assert pattern did not
│                     match")` and sets `AssertPattern.fatal`, so the AST keeps one shape and every
│                     backend's handler lowering is the fatal path; the checker reads `fatal` to tell
│                     the two forms apart. The formatter therefore re-prints the desugared `catch` —
│                     the honest AST (an optional handler) waits for the formatter front
├── tests.zig      ← barrel: aggregates tests/<feature>.zig for test_root.zig
└── tests/         ← parser tests, split by feature
    ├── helpers.zig       ← shared harness (`assertParser`/`expectParseError`/`expectErrorAt(src, kind, line, col)`/…)
    ├── imports.zig       ← import/activate/delegate declarations
    ├── declarations.zig  ← record/enum/interface/implement, val/pub/fn, effect fns, test blocks
    ├── expressions.zig   ← operator/lambda/array/tuple/case/builtin/control-flow
    ├── destructuring.zig ← destructure/shorthand/assign
    ├── errors.zig        ← parse errors & cross-stage error-message units
    ├── surface.zig       ← the 1.0.3 surface: `type` shapes, the field list, `behavior`, separators, and old-vs-new AST equality
    ├── decision8.zig     ← decision 8's grammar, one section per row: `unknown` (N19), union types (N20), `is` (N21), `case` arms (N22)
    ├── effect_rejections.zig ← parser-level `#[@<effect>]` rejections (R1/R2/R5…; R5 carets the second annotation, 01 R9)
    └── language_surface.zig  ← front 15's rows: the forms the documents write against the grammar (R1 the `T[]` suffix, R2 the postfix chain, R3 a number as a receiver, R4 the shared block body, R5 the index expression, R7 a bodyless `fn`, R8 `??`, R9 the catch-all names its token, R10 the decided-against forms refused by name)
```

## Testing pattern

```zig
test "import decl" {
    try assertParser(std.testing.allocator, @src(), "import {std.List as L, X*, io: {fs: {readText as read}}};");
}
```

- Snapshot path: `modules/compiler-core/snapshots/parser/<slug>.snap.md` (slug from the test name)
- Error tests: `expectParseError(alloc, "expected rendered message", source)` — it FAILS when the parse produced no `parseError` (nothing would be rendered), so the expected text is always compared; `expectParseFails(alloc, source)` only checks that parsing fails

## One block body, and the prologue that used to fork it

`parseBlock` consumes the `{` and delegates to **`parseBlockBody`**, which runs
the statement loop under `BlockParseOptions` (`handleComments`,
`trackEmptyLines`, `semicolonPolicy`, `useAfterBranchGuard`, `freshUseScope`). A
block that reads something between the `{` and its first statement — a prologue
— consumes the `{` itself, reads the prologue, and then calls `parseBlockBody`:

| Block | Prologue | Policy | `use` scope |
|---|---|---|---|
| fn / `test` body, `fn (…) { … }` expression | — (`parseFnBodyInBraces`) | `requiredExceptLast` | fresh |
| `if` else-branch, `case` arm | — (`parseStmtListInBraces`) | `requiredExceptLast` | inherits |
| `if` then-branch | `{ x -> ` or `{ _ -> ` — the branch's value binding | `requiredExceptLast` | inherits |
| lambda `{ a, b -> … }` | the parameter list | `optional` | fresh |
| trailing lambda `f { a -> … }` | an optional `label:` and the parameter list | `requiredExceptLast` (was `required` — the one block whose last statement could not drop its `;`; front 15 step 4b) | fresh |
| `for (…) { x -> … }` body | the one binder (`parseLoopBody`) | `requiredExceptLast` (was `required`; front 15 step 4b, with the trailing lambda) | inherits |
| `while (…) { … }`, `loop { … }`, `iter loop { … }` body | — (`parseLoopBody`; a binder is refused) | `requiredExceptLast` (the same `parseLoopBody`) | inherits |

**The static prefix of `use`** (front 19 of 1.0.10-beta, decision 88) is a
property of the *function body*: every `use` precedes every `if`, `case`, loop
(`for`/`while`/`loop`) and `return` of that body, at any nesting.
`Parser.useBranchSeen` is set by the constructs themselves when they are parsed (`parser/exprs.zig`), so a
branch's own block sees the branch it is in (`if (a) { use … }` is refused) and
a `val m = if (…) …` counts as a branch. `parseBlockBody` saves and restores the
flag around every block; `freshUseScope` clears it on entry — a lambda body is
another function, so `use memo { -> return … }` keeps the enclosing prefix. Under
`useAfterBranchGuard` a statement is tested by its **shape**, not its first
token: a bare `use …;` at its own token before the parse, and a `val`/`var`
(plain or destructuring) whose value is the `use` prefix after it
(`bindingUseLoc`, reported at the `use` token found by `tokenAt`). Both are
`useAfterBranch` (`print.zig`).

**Five of those carried their own copy of the loop**, each written before the
options existed, and each left out comment handling and empty-line tracking — so
a `//` comment was a parse error in an `if` then-branch, a lambda body, a
trailing lambda and a `loop` body, while the same comment in a fn body or an
`if` else-branch parsed, and a blank line in any of them was lost (front 15 R4;
`16-formatter`'s G5). **A block with a prologue calls `parseBlockBody`; it does
not copy the loop.** The semicolon policy is per block and is what each copy
already applied — they are recorded above rather than unified, because
tightening one would refuse a program that compiles today.

## The `if` condition and its binder (C-08)

The condition parses at **`prec.lowest`**, not `prec.equality`: `if (a && b)`
and `if (a || b)` are the conditions they look like, and no compound boolean has
to be bound to a `val` first. This is the one `prec.equality` call site the
widening reaches, and the reason is the delimiter — the grammar's own `(` … `)`
closes the condition, so a looser operator has nowhere to run to. The other
eleven sites (`comptime <expr>`, the value after `yield [:label]`,
`ident.field = / += <expr>`, both ends of `parseRangeExpr`, three default-value
sites in `parser/decls.zig`, the two `case`-subject sites in `parser/patterns.zig`)
are open-ended and **stay at `prec.equality`**; widening one of them would swallow
the token that ends the form.

The then-branch's binder accepts `_` as well as a name, and `_` binds the name
`"_"` — the same discard `val _ = …` records. It is deliberately not a null
`binding`: a null binding means "this `if` has no binder", and that is what makes
an `?T` condition the type error `expected bool, got optional`. An author who
writes `_` is saying the payload is unwanted, not that the condition is a `bool`.

## A bodyless `fn` declares its return type (decision 33 (b))

A top-level `fn` with no `{ … }` body is a **declaration**, and it is accepted
in three spellings, all promoted to `isDeclare = true` in `parseFnDecl`:

| Spelling | Note |
|---|---|
| `fn f(x: string) -> void` | the arrowed form. It used to be a **parse error**, which made decision 33's own remedy ("the declarations gain `-> void`") unwritable |
| `fn f(x: string) void` | the arrowless `.d.bp` shortform, the convention in `libs/std/src/builtins.d.bp` |
| `declare fn f(x: string);` | the `declare` keyword, with its own contract; it parses as a `delegate` decl |

`fn f(x: string)` — **no body and no return type at all** — stays a parse error,
now `bodyless-fn-needs-return-type`, located at the `)` the declaration just
closed, because "add `-> void`" means *there*. The `)` is captured into
`closeParenTok` before the return-type parse, since by the time the absence is
known the cursor has walked on to the next declaration's first token.

The arrowless shortform also stops swallowing a `fn` that is not followed by
`(`: `fn` begins a `fn(…) -> R` type, so `fn emit(source: string)` followed by
`fn main() …` used to parse the *next declaration* as this one's return type
and report the failure there.

## A field and a variant payload are `name: Type` (decision 12, C-08)

`parseFieldList` serves both `type Name(…)` and a variant payload `Variant(…)`,
and it refuses an element that is not `name: Type` **where the element starts**,
with `fieldNeedsName` — the diagnostic names `Variant(field: T)`. The test is
"the current token is a member name AND the one after it is `:`", so the bare
type (`Circle(i32)`, `Circle(Point)`, `Circle(Box<i32>)`) and the forms that
cannot even begin with a name (`Circle(?i32)`, `Circle(#(a, b))`) are refused
alike. Reading past the element instead would report the missing `:` as a stray
token, which is the unlocated-in-practice diagnostic this replaced: `Circle(i32)`
used to red at the `)` two tokens later, naming nothing.

The rule is the decision's own reason: a payload nobody can name is a payload no
`case` arm can bind.

## Type-ref grammar (`types.zig`)

**The `T[]` suffix is applied once, at the single exit, and never per-arm.**
`parseBaseTypeRef` is a two-line wrapper: it calls `parseBaseTypeRefArm` for the
arm and then runs the array-wrap loop for all of them. It used to be written at
the end of the named-type path and **copied** into the `unknown` arm, so the
tuple arm and the builtin-generic arm — which `return` before either — refused
`#(a: i32)[]` and `@Result<i32, E>[]` while `unknown[]` and `Box<i32>[]` parsed
(front 15, decision 14). **A new arm goes in `parseBaseTypeRefArm` and inherits
the suffix; never re-add a wrap loop to an arm.**

`parseBaseTypeRefArm` handles `?T`, `#(…)` tuples, `(T)` parenthesised types,
`fn(…) -> R` function types, `@Name<…>` builtins, `type` meta-kinds, plain names
with `<…>` wraps, and two additions for record/builder ergonomics:

- **`(T)` is a grouping, not a node** — it returns the inner `TypeRef` unchanged.
  `|` binds looser than every other type operator, so `decision-8:141` writes
  `(i32 | string)[]` for an array of a union: the parentheses are what make the
  suffix apply to the whole alternation. `startsTypeRef` accepts `(` for the
  same reason, so a union member and an `is` type may be parenthesised too.
  Since the grouping is dropped, `format.zig` has to re-introduce it when it
  prints an `array` of a union — front 16's printer arm.

- **Function-type params may be named** — `fn(next: T)` parses alongside the
  bare `fn(T)`; the name is documentation-only (function types are positional)
  and is discarded.
- **The removed anonymous record type** — `{ value: T, … }` in type position
  raises `removed-record-type` at the `{` (1.0.3: a labeled tuple type
  `#(value: T, …)`).

A non-`syntax` `name: fn(…)` param is parsed through `parseTypeRef` (a
`TypeRef.function`, so its return may be an array — `fn() -> T[]`);
`Param.fnType` (`ast.FnType`) is set **only** for `syntax fn(…)` params.

## The postfix chain — two copies, and why not one

`.field` / `?.field` / `.method(args)` / `(args)` links are parsed in **two**
places, and the reason is trailing lambdas:

- `parsePostfixChain` (`exprs.zig`) is the operand-position chain. It does
  **not** consume a trailing `{ … }` — in an operand a `{` belongs to the
  enclosing construct. Every literal receiver goes through it, the grouped
  expression `(…)` included: it used to `return` on its own, which is why
  `("ab").length` and `(a == b).toString()` were `Unexpected token` at the `.`
  while `[1, 2].map(f)` parsed (front 15, decision 14). `parsePrimary`'s
  identifier path calls it too — that path used to carry a **verbatim copy** of
  the loop, and the copy is gone.
- `parseExpr`'s call path carries the statement-position chain, which **does**
  consume trailing lambdas (`xs.forEach { … }`).

The links are `.field`, `?.field`, `.method(args)`, `(args)` and `[index]`.
At its exit `parsePostfixChain` refuses a decided-against infix form by name
(`absentInfixKind`: the ternary's `?`, the bitwise operators) — see
*A decided-against form is refused by name* below.

A **builtin call** (`@name(args)`) continues with `parsePostfixChain` too
(1.0.10-beta decision 73 — `@src().line` reads a field of the record `@src()`
answers). Before that the chain after a builtin call was a parse error, so no
program that compiled changed.

A bare **`return;`** (or `return` closing a block) parses with no operand — the
`ok` position of a `-> @Result<void, E>` fn (decision 74). Only `;`, `}` and end
of input end it: `return` followed by a newline still takes the expression on
the next line.

**A link added to one must be added to the other.** `adder(3)(4)` is the case
that proved it: adding the `(` link to `parsePostfixChain` alone closed
`("ab").length(…)` and not `adder(3)(4)`, because the two forms reach two
copies. A chained call has no name for its callee, so the callee travels as an
expression on `ast.CallExpr.call.calleeExpr` with `callee = ""` and
`receiver = null` — a chained call is **not** a method call, and a consumer that
reads `receiver` to mean "the value before the `.`" must not see one.

`xs[i]` is the `[index]` link, built by `makeIndexExpr` for both copies
(decision 30). It is the reserved builtin call `ast.index_builtin_name` over
`(receiver, index)` and **not** a new AST variant — `ast.zig` states the rule
that `x is T` follows for the same reason. The index is parsed with
`parseRangeExpr`, so `xs[0..2]` and `xs[0..]` are the same node with a `range`
inside: one node for indexing and for slicing, as `decision-8:447` reads them.
`parseRangeExpr` stops an open end at `]` the way it already stops it at `)`.
Typing the call is `01-checker`'s and lowering it is each backend's; until then
it reaches the same unrecognised-builtin path `x is T` reached.

## Postfix-chain locs

Each link in a `.field` / `?.field` / `.method(args)` postfix chain carries the
loc of **its own member token**, never the shared base loc. Downstream lowering
is loc-keyed (e.g. `instanceLowerings` records `arr.length` → host length op by
the access loc), so two links sharing a loc collide — `self.pairs.length` would
emit `length(length(Self))`. `parsePostfixChain` and the identifier postfix loop
both use `locFromToken(fieldTok)` for this reason.

## `unknown` in type position (decision 8 §2, 06 N19)

`unknown` arrives as its own keyword token, so `parseBaseTypeRefArm` handles it
before `consumeTypeName` and no user type can shadow it. It lands as
`TypeRef.named = ast.unknown_type_name` (`ast.zig` documents what inference owes
it) and takes the ordinary `[]` wraps from the shared suffix loop — `unknown[]`,
`?unknown`, `Box<unknown>` all parse. `unknown<…>` / `unknown(…)` is refused at the `<` / `(` with
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

`assert <expr> is <Pattern>` has **no production and is not getting one**
(C-08). `is` answers a `bool`; the form that binds a pattern's names into the
enclosing scope is `val assert <Pattern> = <expr>;` (decision 8 §9), and a
second spelling for one meaning is what decision 67 refuses. Three DOCUMENTED
SKIPs used to pin the parse error and promise the form —
`comptime/tests/narrowing.zig` ×2 and `codegen/tests/narrowing.zig` ×1; they are
gone, and `tests/language/reject/assert_is_pattern.bp` pins the refusal instead.

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

### Decision 54 — an optional is matched by `null` and a binder

`null` is a pattern: `parseSimplePattern` lands it as `.ident` carrying the
keyword's own lexeme, the way `true` and `false` already do. No new `Pattern`
variant, so no consumer has to learn one — and `null` is a keyword token, so no
binding can ever carry that name and be mistaken for it.

The arm after a `null` arm is the optional's binder, which is the one place a
bare lower-case name *is* a pattern. `parseCaseExpr` carries `sawNullArm` and
passes it to `rejectNonPatternArm`; only the bare-name rewrite is lifted (a
constant arm is still `case-constant-pattern`). The order is the form: a binder
written first would match the absent value too, so `null` comes first and the
parser accepts the binder only after it.

Everything else about the form is the checker's, because it needs the subject's
type: `optionalNullCaseBinder` (`comptime/infer.zig`) requires the subject to be
a `?T` and the arms to be exactly two, unguarded, `null` then a binder, and
narrows the binder to the payload; `refuseVariantPatternOverOptional` refuses
`.Some(v)` / `.None`. Below inference nothing learns a new pattern at all — the
comptime transform swaps the whole `case` for the `if (x) { v -> … } else { … }`
that every backend already lowers (`comptime/transform.zig`
`rewriteOptionalNullCase`), so the four code generators were not touched.

`CaseArm.patternLoc` exists for this: `Pattern` carries no location, and each of
the refusals above has to point at the arm. It is left out of the AST dump
(`jsonStringify`, `omitAlways`), so no `case` snapshot moved.

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

## A decided-against form is refused by name (front 15 step 3)

`unexpectedToken` is the catch-all, and a form the language decided against
must never reach it: a reader cannot tell a deliberate absence from a gap when
both say "this token cannot appear here" (`surface-gaps.md` of
`specs/1.0.10-beta/00-compiler-carry-over/15-language-surface/`). Each such
form has its own `ParseErrorType`, an `errorMessages` arm in `print.zig` that
names the replacement — or says there is none — and an
`expectErrorAt(src, kind, line, col)` case in `tests/language_surface.zig`
(R10). The refusal is raised **once, at the site every spelling of the form
reaches**, never per arm:

| Form | Kind | Raised at |
|---|---|---|
| `c ? a : b` | `ternaryAbsent` | `parsePostfixChain`'s exit (`absentInfixKind`) — at the `?` |
| `1 << 2`, `a >> 1`, `a & b`, `a ^ b` | `bitwiseOperatorAbsent` | same exit — at the operator |
| `'a'` | `charLiteralAbsent` | `parsePrimary`, at the literal (`lexer.zig` hands it over as one `charLiteral` token) |
| `fn inner(…) { … }` in a body | `nestedFnDecl` | `parsePrimary`'s `fn` arm, at the `fn` |
| `[..a, 3]` | `listSpreadNotLast` | `parseArrayLitExpr`, at the element after the spread (the kind existed; nothing raised it) |
| `[...a]` | `listSpreadDotDotDot` | `parseArrayLitExpr`, at the `...` |
| `type P(…)` then `implement A for P { … }` | `implementClauseFor` | `types.zig` `parseImplementClause`, at the `for` — the bodyless type took `implement A` as its clause |
| `#(x: 1, y: 2)` | `tupleLiteralLabel` | `parseTupleLitExpr`, at the label — the labeled construction is `01-checker`'s §6, and this replaces `novalBinding` at the value |

**The infix refusals are hoisted the way the chain links are.** Every receiver
ends at `parsePostfixChain`'s exit, so that is where `absentInfixKind` is
asked, once; `parseExpr`'s call path (the statement-position chain, which
returns before the climber when no operator follows) treats the same tokens as
"the expression continues" in `isBinaryOpNext`, rolls back, and reaches the one
site — `g(1) ? 1 : 2` was the case that proved a second copy would be needed
otherwise. Nothing that parses puts `?`, `<<`, `>>`, `&` or `^` after a
complete operand: `?` in a type is `parseTypeRef`'s, `>>` closing two generic
lists is `parseTypeRef`'s, a pattern's `|` is `patterns.zig`'s.

**Adding one:** a new decided-against form gets a variant beside these, an arm
in `print.zig` (`removedErrorUnion` and `patternRangeExclusive` are the
models), the check at the one site its every spelling reaches, and an R10 case.
`grep -c unexpectedToken` over `src/parser/**` does not grow.

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
  `inline = true`) lands in `Annotation.labels[i]` (`labelOf(i)`, front 17
  step 3 — the validator and the formatter read it); the value still lands
  positionally in `args`.
- **Enum/member chains** — `.Erlang`, `Target.Erlang`: adjacent `.`/identifier
  tokens fold into one lexeme spanning the source bytes. A bare identifier or
  string literal goes through unchanged.
- **A negative literal** — `#[mark(-20)]`: the `-` and the digits span into one
  lexeme, `"-20"`, so the reader that evaluates the argument sees the number
  (front 15 step 4b). It used to be the catch-all at the digits, with the `-`
  taken as the whole argument.

## Module-level `var` (front 17, decision 38)

`parseValDecl` reads `var name[: T] = v;` as a `ValDecl` with `mutable = true`;
`parseValForm` sends `var` straight there (no `val Name = fn …`-style shorthand
reads it). An annotated binding — `#[@BeamMemory.Ets(keyed = true)] var hits:
i32 = 0;` — is dispatched from the annotation branch of the top-level loop, and
the annotations land on `ValDecl.annotations`; only the plain form takes them
(an annotated shorthand is `UnexpectedToken`, located at the annotation's first
token rather than at whatever follows the form). What the annotation may say is
checked by inference, not here.

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

### Member trivia and member order (front 16's carve-out)

A body member carries the layout the formatter has to print back, and a field the
parser does not record is a line the formatter deletes in silence — a deletion is
idempotent, so `format --check` then calls the thinned file clean.

| Slot | On | Written by |
|---|---|---|
| `comments` | `Field`, `BehaviorMethod`, `BehaviorField`, `EnumVariant`, `EnumSection` | `takeMemberComments` / `parseFieldList`, `""` for a blank source line |
| `trailingComment` | `Field`, `BehaviorMethod`, `EnumVariant` | `takeTrailingComment`, gated on the comment sitting on the line the member ended on |
| `order` | `EnumVariant`, `EnumSection` | `parseEnumItem` / `parsePayloadVariant`, as `variants.len + sections.len` at the moment of the append |

`takeTrailingComment`'s same-line test is the whole of the distinction between a
member's own trailing comment and the **next** member's leading one. Collected at
the top of the next iteration instead — which is what happened before it existed
— the comment is re-attached to the following member, where it says something
false about the program, and on the **last** member there is no following member,
so `parseFieldList` freed it outright.

`order` exists because `TypeShape.EnumShape` keeps `variants` and `sections` in
two parallel slices: an enum body may interleave them, and without an ordinal the
interleaving is gone before any reader sees the AST, so a printer can only emit
all of one list and then all of the other. It is additive on purpose — the 35
`.variants()` / `.sections()` call sites across the five emitters, `comptime/` and
`format.zig` keep reading the two slices unchanged. **Nothing in `src/codegen/`
may key on a variant's position in `TypeShape.EnumShape.variants`**: `order` is
source layout, not a run-time encoding, and a backend that started deriving a tag
from a position would turn the formatter's member-ordering into a correctness
question without anything saying so.

None of the three reaches a snapshot: `order` is in `stringifyOmitting`'s
`omitAlways` list and the two trivia slots in its `omitIfEmpty` list, so a member
that uses none of them dumps exactly as it did before they existed.

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
