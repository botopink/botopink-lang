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
├── syntax_params.zig    ← decisions 364, 575 (4): after the parse, a non-template function's `comptime` / `syntax` parameter keeps `T` in `Param.typeRef`, `Param.exprWrapped` set (`unwrapProgram`, run by `Parser.parse`), and a decorator's first `syntax` is the declaration handle (`declHandle`); decision 370 (1): a record field's `syntax x: T` likewise (`Field.exprWrapped`)
├── compiler_surface.zig ← decisions 575, 576: `compiler.*`, a `comptime x: T`'s bare reads and a template's returns read onto the machinery (`expandProgram`, run by `Parser.parse` unless `keep_surface`); `members` — the `Compiler` table
├── implementations.zig ← decision 575 (6): each declaration's `#[external(…)]` sources read into its `implementations` (`ast.Implementation`) after the parse — a source is `.<Variant>(…)`, its positional arguments filling `variant_fields` (held to `external.bp` by a test), its templates' markers translated (`template_markers.rewrite`), a host `${` written `\${`; lenient (the checker refuses a source's shape as the enum's constructor, `comptime/infer.zig` `checkImplementations`)
├── template_markers.zig ← decision 5: an implementation's template markers are positional over the declared parameters
│                     (`$0` is `self` on a method). `Parser.parse` runs `normalizeProgram` once: it translates each
│                     template to the renderers' receiver convention (`primOpTemplate.receiver_marker`, `$N` shifted;
│                     `self`-first top-level fns on Erlang/Beam too), keeps the source in `Annotation.source_args`
│                     (formatter, AST dump), and refuses `$self` / `$stringify(…)` (decisions 164, 239) / an
│                     out-of-range `$N` with a located `template-self-marker` / `template-stringify-marker` /
│                     `template-marker-out-of-range`
├── exprs.zig      ← expression sub-grammar: precedence climbing, primary/pipeline/local-bind/lambda/loops/range,
│                     string templates (`${…}` re-scan), tagged calls. `fn(a, b) { … }` is a function expression; decision
│                     370 (2) gives it typed parameters and a return — `fn(self: T) -> R { … }`, every parameter typed or
│                     none (`FunctionExpr.paramTypes` / `.returnType`), admitted by the checker only as a decorator's
│                     `decl.addMember(name, fn…)` (`comptime/member_fn.zig`). The loops are decision 105's three keywords,
│                     one parser each and one `LoopExpr` node (`keyword` says which): `parseForExpr` —
│                     `for [await] [:label] (iter) { x -> … }` over a collection, a range (`a..b` exclusive,
│                     `a...b` inclusive — `parseRangeExpr` reads both tokens) or a generator, binding exactly one
│                     name (`for-without-binder` / `for-binds-one-name`; `paramsLoc` locates it); `parseWhileExpr` —
│                     `while [:label] (cond) { … }`, the condition at `prec.lowest` like an `if`'s; `parseLoopExpr` —
│                     `loop [:label] { … }` (`condition` over the literal `true`); `break [:label]` and `continue [:label]`
│                     carry the label in the AST (the checker's `checkJumpLabel` reads both). A binder on `while`/`loop` is
│                     `loop-binds-nothing`; `loop (…)` is `removed-loop-parenthesised` at the keyword, naming `for`
│                     and `while`. `parseAsyncBlockAhead` reads `async { … }` (decision 124; `async` is contextual,
│                     a keyword only before `{`) as a `.function` node with `syntax = .asyncBlock`, before the
│                     call-chain path would read it as a call with a trailing lambda. `parseGenLoopExpr` reads `iter` / `stream` before `loop` /
│                     `while` / `for` (decision 125; `genLoopPrefixAhead` — the two words are contextual, an
│                     identifier anywhere else): `iter loop` is the prefixed `loop` node, `iter while` / `iter for`
│                     the prefixed `loop { <written loop>; break; }` with `prefixedKeyword` recording the keyword;
│                     `LoopExpr.generator` carries `.iterator` / `.stream`. An annotation block before a loop is
│                     `loop-annotation-not-generator` (`parseAnnotatedLoopExpr`), a removed effect annotation there
│                     `effect-annotation-removed` with the `iter` / `stream` fix-it; a removed wrapper
│                     name in a type is `effect-type-removed` (`types.zig`) — always, there is no mode
│                     that reads the old surface (decision 131). `throw new X(…)` is
│                     `removed-keyword-new` (06 N27) — `new`/`delegate`/`const` lex as identifiers. `val assert P = e;` with no `catch` (decision 8 § 9) parses:
│                     `assertFatalHandler` desugars it into the handler `@panic("assert pattern did not
│                     match")` and sets `AssertPattern.fatal`, so the AST keeps one shape and every
│                     backend's handler lowering is the fatal path; the checker reads `fatal` to tell
│                     the two forms apart. The formatter therefore re-prints the desugared `catch` —
│                     the honest AST (an optional handler) waits for the formatter front
│                     A record's spread is `..src` at the start of a call argument (`parseCallArgs`, the argument labelled
│                     `ast.record_spread_label`, decisions 359 and 529 (3)); `...src` there is the parse error
│                     `spread-dot-dot-dot` at the `...` — `...` is only the inclusive range `a...b`
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
    ├── decision280.zig   ← decision 280's parser half: a `comptime` parameter's default and location (`Param.loc`), a decorator argument as one located expression span, the trailing comma of an annotation list
    ├── decision529.zig   ← decision 529 (2)'s parser half: `..props: R` is a record parameter (`Param.recordParam`), told from a variadic by the type — a named non-primitive type against an array —, with no default (`record-param-default`); `..value: i32` stays `variadic-not-array`
    ├── decision311.zig   ← decision 311's parser half: the template annotation `#[f "…"]` / `#[f """…"""]` (`parser.zig` `parseAnnotationCall` → `Annotation.template` + `templateLoc`, the literal as written; its holes parsed by `exprs.zig` `parseStringToken`, so a malformed one is a parse error), alone and inside a list, its AST dump; a builtin `@` annotation takes no literal
    ├── decision255.zig   ← decision 255's two expression forms: a type application before a member (`Dict<string, unknown>.empty()`, the comparisons that stay comparisons) and `comptime <expr>`, each with its `botopink format` round-trip
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
`trackEmptyLines`, `semicolonPolicy`). A
block that reads something between the `{` and its first statement — a prologue
— consumes the `{` itself, reads the prologue, and then calls `parseBlockBody`:

| Block | Prologue | Policy |
|---|---|---|
| fn / `test` body, `fn (…) { … }` expression | — (`parseFnBodyInBraces`) | `requiredExceptLast`, `markTail`; a block `{ … }` ending the body is its tail (decision 541 (4), `isValueBlockExpr`) |
| a type's method, a behavior's default body | — (`parseMethodBodyStmts`, `parseSimpleBodyStmts`) | `requiredExceptLast`, `markTail` (was `required`; decision 409) — an `implement` method keeps `required`: the printer writes no `-> R` there |
| `if` else-branch | — (`parseStmtListInBraces`) | `requiredExceptLast` |
| `if` then-branch | `{ x -> ` or `{ _ -> ` — the branch's value binding | `requiredExceptLast` |
| lambda `{ a, b -> … }`, `{ -> … }` | the parameter list | `optional`, `markTail`, `bracedTail` (decision 541 (1): a lambda answers its last expression written without `;`; one with `;` is a statement and the lambda answers nothing — the checker's `discardUnwrittenTail`) |
| block `{ … }` (no `->`, decision 525) | — (`parseBlockValueBody`) | `requiredExceptLast`, `markTail`, `bracedTail` |
| `comptime { … }`, `async { … }` | — | `requiredExceptLast`, `markTail`, `bracedTail`; the tail wrapped in the block's `break` / `return` (`jumpTail`) |
| `case` arm `p { … }` / `p -> { … }` | an optional `n ->` binder (`parseLambdaBody`) | `optional` / `requiredExceptLast`, the tail marked (`markBlockTail`), a braced `if` / `case` at the end included; both forms read the arm through `parseBlockBody`, so a `//` comment between statements is kept; a `//` comment after a bare tail (no `;`) is a comment after it, never the end of the block's value (`closesAfterComments`; `ast.lastRealIndex` is the tail's index for the checker and the commonJS / wasm backends) |
| trailing lambda `f { a -> … }`, `f { -> … }` | an optional `label:` and the parameter list; neither parameters nor `->` is a block (`TrailingLambda.isBlock`, refused by the checker) | `requiredExceptLast` (was `required` — the one block whose last statement could not drop its `;`; front 15 step 4b), `markTail` |
| `for (…) { x -> … }` body | the one binder (`parseLoopBody`) | `requiredExceptLast` (was `required`; front 15 step 4b, with the trailing lambda) |
| `while (…) { … }`, `loop { … }`, `iter loop { … }` body | — (`parseLoopBody`; a binder is refused) | `requiredExceptLast` (the same `parseLoopBody`) |

**A body's tail (decision 409).** `markTail` marks a function body's last
statement written without `;` — not a comment, a binding, a `return` / `throw` / `break` /
`continue` / `yield`, a `use` or a braced `if` / `case` / loop (a value `try e` and `await e` are
tails, decision 537) — `Stmt.tail = .value`. `Parser.returnTail` then
wraps it in `return` (located at the expression, `tail = .returned`) when the
body's written return has a value — a `fn`, a type's method, a behavior's
default body, a function expression — so every later pass reads the `return`;
the printer writes the value back without `return` and without `;`
(`format.zig` `fmtStmt`). `Stmt.tail` is dumped only when set.

## Blocks (decision 525)

In every position a `{` followed by parameters and `->` (or `->` alone) is a lambda
(`exprs.lambdaHeadAt`), and a `{` without `->` is a **block** — a scope, never a closure.
`parsePrimary` reads one through `parseBlockValueBody` and lands it as
`case true { _ { body } }` with `isBlock` set (`exprs.makeBlockExpr`): a `case` arm's block is
already a scope of the enclosing function on every pass (its `return` leaves the function, a `var`
it reassigns is the function's), so the checker and the four backends read a block as they read an
arm, and the printer writes it back as `{ … }`. A block used as a value answers its last expression
written without `;` (`markTail`), a braced `if` / `case` at its end included (`bracedTail`: the `;`
after a braced statement means nothing there, decision 29 (c)) — the same tail a `case` arm marks
(`markBlockTail`), `comptime { … }` (its tail wrapped in the block's `break`, which the evaluators
read, `jumpTail`) and `async { … }` (its tail wrapped in `return`, which leaves the `async` block).
A trailing `{` without `->` is a block too (`TrailingLambda.isBlock`, located at its `{`): the
checker refuses it where the call expects a function, and `botopink format` writes it back as
`{ -> … }`. `@block` is a parse error, `removed-block-builtin`, at the builtin.

**Decision 553 (1) — the body markers.** `async`, `iter`, `async iter` and `component` stay contextual
words (the lexer reads identifiers); `decls.markerAt` reads one at an offset, `markedFnAt` one followed
by `fn`. A declaration takes it right before `fn` — `[#[…]] [pub] [default] [declare] <marker> fn`
(`checkMarkedFn` at the top level, `startsTypeMember`, a behavior body, an implement body;
`parseFnMarker` consumes it in `parseFnDecl`, `parseMethodDecl`, `parseBehaviorMethod` and
`parseImplementMethod`) — and `checkFnMarker` refuses, at the marker, one on a bodyless declaration
(`marker-on-declaration`) and one whose written return is not the wrapper it names, or no return at all
(`marker-type-mismatch`; an implement method's return is checked when written). `FnDecl.marker` /
`BehaviorMethod.marker` / `ImplementMethod.marker` keep it, and a marked `FnDecl`'s `effect` is the
marker's (an unmarked one keeps `EffectKind.ofFn`). In an expression `exprs.parseMarkedAhead` reads
`<marker> { params -> … }` and `<marker> fn(…) { … }` (`lambdaHeadAt` tells the lambda from a block):
`async { … }` without `->` stays the block, and `iter` / `async iter` / `component` before a `{`
without `->` are `marker-without-arrow` at statement start (`parseExpr`) and a name in an operand
(`parsePrimary`: `case iter { … }`). `desugarMarked` writes the marked function as the unmarked one it
means, `FunctionExpr.kind.marker` set: `async { x -> b }` is `{ x -> return async { b }; }`,
`iter { x -> b }` is `{ x -> return iter loop { b; break; }; }` and `async iter` the same with a
`stream loop` (the `return` is `tail = .returned`); `component` keeps its body. A marked trailing
lambda (`f(1) async { … }`) is not parsed. A body's tail `await e` / `try e` is its value
(`tailLeaves`, decision 537), so `returnTail` / `jumpTail` wrap it in the `return`.
A trailing lambda stays a `TrailingLambda` in the parser's tree (the formatter prints it as written); the checker
lowers it to the call's last argument (`ast.lowerTrailingLambdas`, `comptime/AGENTS.md`).

**Where a `use` may stand** is not the parser's rule: decision 357's rules of
hooks (`use-not-top-level`) are the checker's (`comptime/AGENTS.md`), which
knows the construct around a `use`. The parser's static-prefix guard of front
19 (1.0.10-beta, decision 88) — `useBranchSeen`, `useAfterBranch` — is gone.

**Five of those carried their own copy of the loop**, each written before the
options existed, and each left out comment handling and empty-line tracking — so
a `//` comment was a parse error in an `if` then-branch, a lambda body, a
trailing lambda and a `loop` body, while the same comment in a fn body or an
`if` else-branch parsed, and a blank line in any of them was lost (front 15 R4;
`16-formatter`'s G5). **A block with a prologue calls `parseBlockBody`; it does
not copy the loop.** The semicolon policy is per block and is what each copy
already applied — they are recorded above rather than unified, because
tightening one would refuse a program that compiles today.

**A braced block statement's `;` is accepted in every block** (C-13 — decision 29
(c), ordered by decision 60; decision 524). After a statement, `Parser.isBracedBlockStmt` asks
whether it is an `if` (not `a ?? b`'s desugaring), a loop or a `case` **and** the
token that ended it is its `}`; if so the `;` is matched, never required,
whatever the block's policy — `parseBlockBody`, `parseBlockExpr` and the
pre-decision-8 `case` arm block (`1 -> { … }`) alike. The test is the closing
brace, not the keyword: `if (c) return x;` keeps its `;`, and so does a binding or
a `return` whose value is braced, since the statement there is the binding.
`format.zig` prints no `;` after exactly these statements. **C-13 is formatting,
never a refusal** (decision 524): the parser accepts the `;` for good and `botopink
format` removes it — the commit hook applies the formatter, so a committed tree
does not keep it. There is no `blockStatementSemicolon` error; the refusal front
15 parked is withdrawn.

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
an `?T` condition the type error `expected bool, got ?string`. An author who
writes `_` is saying the payload is unwanted, not that the condition is a `bool`.

## A bodyless `fn` declares its return type (decision 33 (b))

A top-level `fn` with no `{ … }` body is a **declaration**, and it is accepted
in three spellings, all promoted to `isDeclare = true` in `parseFnDecl`:

| Spelling | Note |
|---|---|
| `fn f(x: string) -> void` | the arrowed form. It used to be a **parse error**, which made decision 33's own remedy ("the declarations gain `-> void`") unwritable |
| `fn f(x: string) void` | the arrowless `.d.bp` shortform, the convention in `libs/std/src/builtins.d.bp` |
| `declare fn f(x: string);` | the `declare` keyword, with its own contract; unannotated it parses as a `delegate` decl, annotated (`#[@External.…]`) as a `fn` decl |

The unannotated `declare fn` (a `DelegateDecl`, top-level shorthand or `val f =
declare fn(…)`) reads its signature with **`parseSignature`** — `parseGenericParams`,
`parseParamList`, `-> parseTypeRef` — the one a behavior's `fn` member
(`parseBehaviorMethod`, `parseMethodDecl`) reads too, from the same pieces
`parseFnBody` uses. So `pub declare fn field<T, F>(obj: T, comptime name: string) -> F;`
and `-> Component<T, any>` parse; the delegate used to take no generics and a
one-token return.

**`_` as a parameter name** (`comptime _: anytype`) is a bodyless declaration's
placeholder: `consumeParamName` accepts it and notes it in `Parser.discardParam`
(reset by `parseParamList`), and every signature that goes on to a body —
`parseFnBody`, `parseMethodDecl`, `parseImplementMethod`, a `default fn` behavior
member — calls `refuseDiscardParam` first: `discard-param-with-body`
(`discardParamWithBody`), at the `_`. A body would have nothing to bind it as,
and the backends have no discard-parameter spelling (two `_` are a duplicate in
WAT and strict JavaScript).

**`self` names a method's receiver and nothing else.** `consumeParamName` notes
the first parameter called `self` in `Parser.selfParam` (reset by
`parseParamList`), and `parseFnBody` — which parses only FREE functions (a
top-level `fn`, `declare fn`, `val name = fn …`; a method's signature goes
through `parseSignature`) — refuses it: `self-param-outside-type`
(`selfParamOutsideType`), at the name. The backends read a parameter called
`self` as a receiver and dropped it (erlang `twice/1`, commonJS `NaN`), so
`template_markers.zig` no longer shifts a free function's markers either.
The one exception, checked once the return type is read, is a template
method's signature (decisions 311 (3), 415 (1), `ast.isTemplateMethodSignature`):
`syntax self: R` first, `syntax q: string` second (the parser reads them onto the internal
`comptime self: __Expr<R>` and `comptime q: __Expr<…>`, `-> __Expr<…>`) — the receiver of
`` value.method @`…` ``, which never reaches a backend.

**A keyword where a name is declared** is `reserved-word-as-name`
(`reservedWordAsName`), with the word in the caret caption: a field
(`parseFieldList`, before `field-needs-name`), and — through `parse`'s
fallback, when the parser stopped on a keyword-shaped token followed by `:`,
`=` or `->` (`isKeywordName`) — a parameter, a binding and a lambda parameter.

`fn f(x: string)` — **no body and no return type at all** — stays a parse error,
now `bodyless-fn-needs-return-type`, located at the `)` the declaration just
closed, because "add `-> void`" means *there*. The `)` is captured into
`closeParenTok` before the return-type parse, since by the time the absence is
known the cursor has walked on to the next declaration's first token.

The arrowless shortform also stops swallowing a `fn` that is not followed by
`(`: `fn` begins a `fn(…) -> R` type, so `fn emit(source: string)` followed by
`fn main() …` used to parse the *next declaration* as this one's return type
and report the failure there.

## A default is trailing everywhere (decision 244)

`parseParamList` refuses a parameter without a default after one with a default
(`fnParamDefaultTrailingOnly`, a free `fn` and a method alike), and
`parseFieldList` refuses the same of a field — a record type's, a variant's
payload, an inline parameter type's — as `fieldDefaultTrailingOnly`
(`field-default-trailing-only`), at the required field's name. Cells:
`reject/{fn_param,method_param,record_field,variant_payload}_default_not_trailing`.

## A variadic parameter (decision 267)

`parseParam` reads `..name: T[]` (and `comptime ..name: T[]`) as a parameter
with `Param.variadic` set (dumped only when true); `matchVariadic` keeps the `..`
in `Parser.lastVariadicTok`. `checkVariadicParam` refuses a type that is not
written `T[]` (`variadicNotArray`, at the type) and a default
(`variadicDefault`, at the `=`); `parseParamList` refuses a parameter after a
variadic — `variadicTwice` at the second `..` when it is variadic too,
`variadicNotLast` at the first `..` otherwise. Codes `variadic-not-array`,
`variadic-default`, `variadic-twice`, `variadic-not-last` (`print.zig`). The
formatter writes the `..` back (`fmtParam`). Cells:
`reject/variadic_{not_last,twice,default,not_array}`.

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
- **`fn(..) -> R`, a function of any parameters** (decision 316) — the shape a
  decorator handle's `syntax decl: fn(..) -> R` names: `TypeRef.function.anyParams`, `params` empty.
  `Parser.inDeclPattern` is set for the decorator handle's type argument alone and cleared by
  `parseBaseTypeRefArm` for everything inside it, so `..` written anywhere
  else (a parameter's type, inside the pattern) is `any-params-outside-decl`
  at the `..`.
- **The removed anonymous record type** — `{ value: T, … }` in type position
  raises `removed-record-type` at the `{` (1.0.3: a labeled tuple type
  `#(value: T, …)`).

A `name: fn(…)` param is parsed through `parseTypeRef` (a `TypeRef.function`,
so its return may be an array — `fn() -> T[]`).

## The postfix chain — two copies, and why not one

`.field` / `?.field` / `.method(args)` / `(args)` links are parsed in **two**
places, and the reason is trailing lambdas:

- A tuple literal `#(…)` is an operand too (T11): `parsePrimary` reads it and
  continues into `parsePostfixChain`, so the right side of `??`
  (`hit.at(0) ?? #("", "")`) and an operator's operand take one; the
  statement-start position still reads it in `parseExpr` first.
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

The links are `.field`, `?.field`, `.method(args)`, `(args)` and `[index]`, plus
decision 330's three optional links (`parseOptionalLink`, read first by both
copies): `?.[index]` (the index carrier with `optional` set, located at the `?.`),
`?.(args)` (a `calleeExpr` call with `optional` set) and the postfix `x!` — the
builtin carrier `ast.non_null_builtin_name`, taken only when the `!` touches its
operand (`x !` is not the form; the prefix `!x` is untouched). `parseNullishExpr`
refuses `??` beside `&&` / `||` without parentheses (`nullishBesideLogical`,
`nullish-beside-logical`, at the `??`).
At its exit `parsePostfixChain` refuses a decided-against infix form by name
(`absentInfixKind`: the ternary's `?`, the bitwise operators) — see
*A decided-against form is refused by name* below.

A **builtin call** (`@name(args)`) continues with `parsePostfixChain` too
(1.0.10-beta decision 73 — `@src().line` reads a field of the record `@src()`
answers). Before that the chain after a builtin call was a parse error, so no
program that compiled changed. `@TypeInfo.all(…)` (decisions 216 (4), 248, 253) is the
one builtin with a member before its arguments: `@TypeInfo` followed by `.all(` is
the builtin call whose callee is `TypeInfo.all`, and its labelled arguments
(`with: d`) never read as an `@Name(field: value)` interface literal (no dotted
callee does). `@typeInfo.all(…)` and the lowercase `@typeinfo.all(…)` parse the
same way (callees `typeInfo.all`, `typeinfo.all`) so the checker refuses each at
its loc — `typeinfo-all-on-function` and `typeinfo-lowercase`, both naming
`@TypeInfo.all`.

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

`name<T, …>(args)` — decision 8 §1.3's explicit type arguments — is read by
`parseExplicitTypeArgs` in `parsePrimary`'s identifier arm and after a method
name in `parsePostfixChain` (`ctx.resolve<T>()`), speculatively: only
when the `<` is adjacent to the name, every item parses as a type, `>` closes the
list and `(` follows; otherwise the cursor and the parse error are restored and
`<` is a comparison. The list lands on `ast.CallExpr.call.typeArgs` (null, and
absent from the dump, when none was written).

**A type application** (decision 255 (1)) extends the identifier arm's list to
a type's member: after a **type's name** (`isTypeName` — an upper-case first
letter) a `.` after the `>` closes the list as a `(` does, and the list goes to
the chain's **first link** (`parsePostfixChainFrom`'s `receiverTypeArgs`):
`ast.CallExpr.call.receiverTypeArgs` for `Dict<string, unknown>.empty()`,
`identAccess.receiverTypeArgs` for `Opt<i32>.None` (both null and absent from
the dump when none was written; `ast.zig` frees them with `typeArgs`). That is
Kotlin's rule: the list is tried only after a type's name and only when `>` is
followed by `.` or `(`; a list that does not parse as types — `x < y && z > w`
— and a `>` followed by anything else — `f(a < b, c > d)` — leave `<` a
comparison, and so does a value's name (`a<b>.c`). The formatter prints both
lists back adjacent (`format.zig` `typeArgsDoc`; a broken method chain keeps
the `<…>` on its root's line). `tests/decision255.zig` pins the trees and the
round-trip.

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
gone, and `conformance/modules/assert_is_pattern` pins the refusal instead.

## `case` arms and patterns (decision 8 §5, 06 N22)

Two arm forms coexist, told apart by the token after the pattern and its
optional guard:

| Form | Body |
|---|---|
| `Pattern { body }` — decision 8 §5.1 | a lambda body: `{ n -> … }` binds the whole matched value (P1), the last expression written without `;` is the arm's value (P3, decision 525 — `markBlockTail`), and the arm takes no `;` (P2) |
| `pattern -> value;` — pre-decision-8 | unchanged; `libs/std` and the libraries are written this way, and 12 step 3 / 13 migrate them. A `{` after the `->` whose head is a lambda's (`->`, or `a, b ->` — `exprs.lambdaHeadAt`, the one test `parsePrimary`'s lambda arm uses) is the arm's VALUE, a lambda literal, wrapped as the one statement of a parameterless arm body (`A(x) -> { item -> f(item) }`, `language-gaps.md` row 28); any other `{` is the block arm body |

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
`literals`. `null`, `true` and `false` land on `.ident` but are not binders
(`isPlainBinder`): `Box(label: null, n: k)` is `literals`, and every backend
tests the field (`commonJS` `isKeywordLiteralPattern`, erlang's `undefined`
atom, beam's `is_eq_exact`, wasm's `eqz`) — kept as `fields` it was bound as a
name `null` (`conformance/modules/case_record_field_null`). `ast.zig` documents the node each shape lands on and what inference
owes it.

Five located refusals, all in `print.zig`: `pattern-range-exclusive` (`1..9` —
`..` is iteration), `pattern-range-missing-end`, `pattern-rest-not-last`,
`pattern-tuple-label` (a tuple pattern is positional) and, for the
`Pattern { body }` form, `case-bare-name-arm` and `case-constant-pattern`
(§5.2's two rewrites). The last two judge a name by shape — a dotted path,
`true`/`false` and the primitive type names are patterns; an all-upper-case name
is a constant; any other lower-case name is a variable. `isPrimitiveTypeName`
mirrors `Env.registerBuiltins` in `comptime/env.zig`, as the language server's
`isPrimitiveType` does; keep the three in step. The `pattern -> value` arm is
judged for `case-bare-name-arm` alone: an unguarded single pattern
(`k -> k + 1`), and every subject of a multi-subject arm, guarded or not
(decision 602: `Square(side), m -> …` is refused at `m`, `rejectArm` locating
each refusal at its own subject's first token; `conformance/modules/case_multi_subject_bare_name`).
A guarded single name (`x if x > 3 -> 1`) still binds, and an
upper-case name in the arrow form is a variant written bare (`NFKC -> true`), never a
constant (`conformance/modules/case_bare_name_arrow_arm`).

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
`x -> { 1; }` is a parameterless lambda too, so it comes back as `x { 1; }` —
the same AST, decision 8's spelling. In a `case` used as a value (any `case`
that is not a whole statement, `Formatter.nextCaseIsStatement`) the arm's last
expression is written without `;`, its tail (decision 525) — the migration of
the arms written before the rule. One residual for the formatter pass: a `case`
whose arms carry comments still loses their position.

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
of each struct, so adding one moved no snapshot. `ValDecl.typeLoc` and `localBind.typeLoc` (a `val`/`var`
annotation, module-level and local; `parseValDecl`, `parseBinding`) are the same, set only when `: T` is
written (144 B-111).

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
| `1 + if (c) { 2 } else { 3 }`, `-if (c) 1 else 2`, `(if (c) a else b).v` | `ifOperand` | `parsePrimary`'s `if` arm and the group's `(` — at the `if` (decision 137's reading applied to `if`; § *`try` and `await` begin an expression*) |
| `fn m(self: Self) { … }` inside an enum section's braces | `sectionBodyMethod` | `decls.zig`'s section body loop (`parseEnumItem`), at the `fn` — decision 151: a section holds leaves and nested sections, a method is the enum's |
| `type(…)` as a return, a field's or a `val`'s type | `inlineTypeOutsideParameter` | `types.zig` `parseBaseTypeRefArm`, at the `type` — decision 207: an inline type is a parameter's whole type, read by `decls.zig` `parseParam` into `Param.inlineFields` before `parseTypeRef` is reached |
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

## `try` and `await` are prefix operators; `catch` is infix (decision 537)

`parsePrimary` reads `try` and `await` the way it reads a unary `-`: the keyword, then the next
primary with its postfix chain (`.`, `()`, `[]`) as the operand — postfix binds tighter, so
`await t.x` is `await (t.x)` and `await f()` is `await (f())`; an `if` / `case` operand is a whole
expression of its own (`parseExpr`). So `await t * 2` is `(await t) * 2`, `await x + await y` is
`(await x) + (await y)`, `try load() + 1` is `(try load()) + 1`, `try await t` is `try (await t)`.
They stand in every operand position — under a binary operator, a unary `-` / `!`, `??`, an index
`[…]`, a range bound, a group — and in every position an expression begins; there is no
`try-await-operand` refusal (decision 137's is withdrawn).

`catch` is the infix operator of the lowest precedence (`wrapCatch`, applied where an expression
ends — `parseExpr`'s two exits and `parseExprAtStart`): its left side is the whole expression
before it, its right side (`parseExpr`) the fallback. `try await t catch 0 * 2` is
`(try await t) catch (0 * 2)`, `try await t + 1 catch 0` is `((try await t) + 1) catch 0`, and
`(try await t catch 0) * 2` doubles the result. `parseExprAtStart` — the `if` / `while` condition,
the `case` subjects, the right side of `x.f =` / `x.f +=` — hands a leading `try` / `await` to
`parseBinaryExpr` (with `noTrailingLambda` set, so `case try g() { … }` leaves the `{` to the
`case`) and then to `wrapCatch`. Pinned by `tests/effect_rejections.zig` ("decision 537: …") and
the cells `try_await_prefix_operators`, `await_postfix_binds_tighter`, `catch_lowest_precedence`.

`try e catch h` and the tail form `e catch h` (`wrapCatch`) build the same `tryCatch` node: a left
side that is itself a `try e` is unwrapped to `e` and sets
`tryCatch.tryKeyword`, which is source layout for the formatter alone (it prints `try ` only where
it was written) and is left out of the AST dump. The record-update spread of `parseCallArgs` —
`Ctor(..base, x: 1)` — is the argument labelled `ast.spread_arg_label` (`..`), which no source can
write as a label.

An **`if` expression** is read in the same place, `parseExpr`'s prefix arm, and follows the same
rule: it stands where an expression begins and is never an operand. `parsePrimary` and a group's
`(` refuse it as `ifOperand` (`if-operand`, at the `if`, fix-it "bind it first: `val x = if …;`")
— `1 + if (c) { 2 } else { 3 }` was the catch-all "this token cannot appear here". A brace-less
branch is a start position, so `if (a) x else if (b) y else z` and a nested `if` as a branch stay
legal. Pinned by `tests/effect_rejections.zig` ("an `if` expression as an operand …") and
`conformance/modules/{if_operand_of_operator,if_in_parentheses,if_operand_of_unary}`;
decisions-pending `rc3-a` holds the reading for the maintainer.

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
error. Annotation blocks are `#[…]`; `@` marks a builtin annotation inside one. A block
written one annotation per line may end with a comma (`#[\n    a(…),\n]`, decision 280’s example).
A `comptime` parameter takes a default (`comptime code: Code = .Custom`) — a decorator's; the
checker refuses one elsewhere (`comptime-default-outside-decorator`) — and every parameter records
where it starts (`Param.loc`, the refusal site of `decorator-param-not-comptime`).

## Annotations (`parseAnnotationCall`)

The annotation name may be a qualified path — `.Erlang(…)` lands as
`Annotation.name = ".Erlang"` with `is_builtin = true` (leading `@`
stripped). Arguments are kept as **raw lexemes** (`Annotation.args: []const []const u8`),
each located (`Annotation.argLocs`, `argLoc(i)`); each reader (`FnDecl.externalFor`,
`ast.parseArityBranchArg`, …) interprets them. The argument of a user
annotation — a decorator's (decision 280) — is **one expression**: parsed with
`parseExpr` (and discarded) so its extent is exact, and kept as the source span
it covers (`[1, 2]`, `Cache<Item>("x")`, `env("X")`, `.name`); the checker
parses it again at its location (`infer.zig` `parseDecoratorArg`). A builtin
annotation's (`#[@…]`) loop special-cases these shapes (vocabulary in
`libs/std/AGENTS.md`); its labels and arity branches apply to both:

- **Arity branches** — `when($argc == N): "<template>"` spans the balanced parens,
  the `:` and the value into one lexeme (`spanLexemes`).
- **Labels** — a leading `identifier :` (`module:`, `inline: true`,
  `keyed: true`) lands in `Annotation.labels[i]` (`labelOf(i)`, front 17
  step 3 — the validator and the formatter read it); the value still lands
  positionally in `args`. A labelled argument is `label: value` in every
  annotation, a builtin's and a decorator's (decision 305): `label = value`
  is `annotation-label-equals`, located at the label, the caret caption
  naming `label:`. A keyword is a label too (`fn: tanBody`, decision 481):
  before `:` it starts no expression. A binding cell's value — `fn:` on every
  `.<Target>(…)`, and `op:`, `wasi:`, `std:` on `.Wasm` —
  lands as its binding text (`ast.translateExternalCells`: `fn: tanBody` →
  `"fn:tanBody"`, `wasi: .RaceOf` → `"wasi:race_of"`), the spelling kept in
  `source_args` for the formatter and the checker.
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
reads it). An annotated binding — `#[@BeamMemory.Ets(keyed: true)] var hits:
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

**The shape is decided by what was written (decision 138).** A field list —
`()` included — makes a record; braces holding a variant or a section make an
enum. A record always writes its field list: `type X()` is the empty record,
`type X() { fn … }` one with members. Braces holding functions and nothing
else (no field list, no `implement`) declare a **namespace type** (decision
329, `TypeDecl.isNamespace`): the record shape with no field and no value — no
function in it takes `self` (`namespaceTypeSelf`, `namespace-type-self`, at the
first `self`), and the checker refuses `X()` (`namespace-type-construction`).
`parseTypeDeclRest` refuses a `type` that ends up with none of the three
(`type X {}`, a bare `type X`) as `typeWithoutFieldList`
(`type-without-field-list`), located at the token after the name and generics —
where the `()` belongs. The empty field list itself is legal (`parseFieldList`
no longer refuses `()`), and the formatter prints `()` for every record with no
fields except a namespace type. A `type` (or `pub type`) inside a type's body is
that type's associated type (decision 330 (7)): kept on its owner
(`TypeDecl.assocTypes`, its leading comments on `TypeDecl.comments`), printed first
in the body by the formatter, refused `assocTypeDuplicate` (`assoc-type-duplicate`)
at its name when the body already gives that name to a function, a variant or
another type; `comptime/nested_types.zig` hoists it as `Owner__Name` before the
checker runs.

### Member trivia and member order (front 16's carve-out)

A body member carries the layout the formatter has to print back, and a field the
parser does not record is a line the formatter deletes in silence — a deletion is
idempotent, so `format --check` then calls the thinned file clean.

| Slot | On | Written by |
|---|---|---|
| `comments` | `Field`, `BehaviorMethod`, `BehaviorField`, `EnumVariant`, `EnumSection` | `takeMemberComments` / `parseFieldList`, `""` for a blank source line |
| `typeRef` | `BehaviorField` | `parseBehaviorBody` with `parseTypeRef` — `val fields: Field[];`, `val m: Array<Method>;`, `val p: ?Decl;` (it was a single identifier, `typeName`) |
| `trailingComment` | `Field`, `BehaviorMethod`, `EnumVariant` | `takeTrailingComment`, gated on the comment sitting on the line the member ended on |
| `order` | `EnumVariant`, `EnumSection` | `parseEnumItem` / `parsePayloadVariant`, as `variants.len + sections.len` at the moment of the append |
| `trailingPerElem` | `arrayLit`, `tupleLit` (not members, but the same slot) | `takeElemTrailingComment` in `parser/exprs.zig`'s two literal loops, after the element's `,`, gated on `onPreviousTokenLine` — empty unless some element has one, and omitted from the dump then |
| `bodyComments` | `TypeDecl`, `EnumSection` | the member loop's last `takeMemberComments`, the one that meets the closing `}` — a section's was collected and freed, so `format` deleted the `// end of …` line closing it |

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
may key on `order`**: it is source layout, not a run-time encoding, and a backend
that started deriving a tag from a member's place among the sections would turn
the formatter's member-ordering into a correctness question without anything
saying so. wasm's all-unit enum *is* a variant's index among `variants` alone
(`codegen/wat.zig`), which the formatter never permutes — re-measured 2026-09-26:
an enum written with a variant after a section and with it hoisted above builds
byte-identically on all four targets.

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
- **`type T` as a union member (decision 297)**: `startsTypeRef` takes `type`,
  so `comptime s: Box<T> | type<T>` parses (a `typeparam` member) and `x is type`
  tests the meta-kind; `parseTypeRef` frees a refused union's first member
  once (it used to free it twice — a panic on `| type T` before `type` began a
  type).
- **A module's default function (decision 289)**: `[#[d]] pub default fn (…)`
  parses with an empty name (`FnDecl.anonymousDefault`, `nameLoc` at `fn`;
  analysis names it `ast.anonymous_default_name`, `comptime/default_fn.zig`);
  `pub default <name>;` (`checkDefaultName`) is no declaration — `parseDecls`
  collects it and `markDefaultNames` sets `isDefault` / `defaultBy` (and `isPub`
  with `pubByDefault`) on the module's `fn <name>`: no such `fn` is
  `default-unknown`, a function already the default is `default-twice`, both at
  the name. Two different defaults are the checker's `default-twice`.
- **Enum sections**: an `Identifier { … }` item
  inside an enum body declares a *section* — a named grouping of nested
  variants — captured as `EnumSection { name, variants, sections }` and stored
  on the enum shape of the `TypeDecl` (`TypeShape.enum_.sections`) alongside the flat `variants` slot. Sections nest
  arbitrarily deep; inside a section body, pure-digit tokens (`100`, `4`) are
  permitted as terminal variant leaves (`EnumVariant.numeric = true`) — they
  cannot open further sections nor carry payload. In expression position the
  leading-dot form takes one too (`.50`, `parsePrimary`'s dot arm, a token of
  decimal digits only), resolved by the expected section. Top-level enum bodies reject
  digit names. Disambiguation is single-token (`{` after a name = section,
  `(` = payload, `,`/`}` = bare). The comptime desugars the tree into the
  enum-of-enum form with mangled inner names; the parser only records the
  structure. A variant written twice at one level of a body is refused at the second
  (`enumVariantDuplicate`, `enum-variant-duplicate`). The same name at two
  levels — a leaf `Token.Mask.Mode.Alpha` beside a top-level
  `Token.Alpha(…)` — is legal: the path and the position's expected type
  tell them apart (`conformance/docs.md` § Sections of an enum).

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

## `comptime`, `syntax` and `compiler` (decisions 575, 576)

A parameter of the `comptime` family arrives one of two ways, and the parser keeps the internal form the
checker, the decorator and template evaluators and the comptime runtime read, with `Param.arrival` saying
what was written (`ast.Arrival`, dumped only when not `written`; the formatter prints it back):

- `comptime x: T` (`arrival = .value`) — the body holds the value, known at build. `parseParam` wraps `T`
  in the tree type (`decls.zig` `wrapTree`, `ast.expr_type_name`), so a non-template function's parameter
  ends with `typeRef = T` and `exprWrapped` set (`syntax_params.zig` `unwrapProgram`).
- `syntax x: T` (`arrival = .expr`) — the expression written, a tree. `syntax` is a modifier only when a name
  or `..` follows it (`isSyntaxModifierAt`); anywhere else it is a name. Its type may write `fn(..) -> R`
  (`inDeclPattern`). A top-level function that is no template and whose first parameter is `syntax` is a
  decorator: `syntax_params.zig` `declHandle` reads that parameter as the declaration handle
  (`ast.decl_type_name`; `syntax decl: unknown` is the handle with no pattern). A template annotation
  (decision 311) is a template whose second parameter is `syntax d: unknown`: that one is the handle.
- Decisions 577, 578 — a **template** is a function whose first parameter (after a `syntax self: R`
  receiver, for a template method) is its text `syntax q: string` (`ast.templateTextIndex`); `unwrapProgram`
  keeps its trees, and `compiler_surface.zig` reads its return — `T`, or `anyvalue` (a type parameter
  `ast.anyvalue_param_name` the built code binds at each call) — as the tree type the machinery knows. It
  is called only `` name @`…` `` / `` recv.name @`…` `` (`CallExpr.call.templateText`, the raw text) or
  `` #[name @`…`] `` (`Annotation.templateText`); any other call is `syntax-call-outside-syntax` (the checker),
  another parameter `template-signature` (`compiler_surface.zig`), and `anyvalue` elsewhere
  `anyvalue-outside-template` (the checker; std's `compiler.bp` declares `build`'s answer with it).
  `anytype` is the bare `type` (`types.zig`, a `typeparam` with no member; the printer writes it).
  `compiler.addType(name, compiler.buildType("(…)"))` hands the built type's text to `addType`;
  `buildType` elsewhere waits for B-140. `-> syntax T` is `removed-expr-type` (`decls.zig`
  `parseReturnTypeRef`), and the bare `type` is `removed-bare-type` (`types.zig`; `x is type` keeps it).
- `@Expr<T>`, `@ExprCustom<T>` and `@Decl` are gone (decision 576 (1)): `types.zig` refuses each as
  `removed-expr-type`, at the name. The tree type, the custom carrier and the handle are internal builtin
  generics no source spells — `ast.expr_type_name` (`__Expr`), `ast.expr_custom_type_name`
  (`__ExprCustom`), `ast.decl_type_name` (`__Decl`), shown without the `__` in a diagnostic.
- `type<T>` — the type of the type `T` (`types.zig`, a `typeparam` with one member; `type<A | B>` keeps
  a constraint list); `type T` is `removed-type-bare-param`, at the name. `type` alone, `type(` and
  `type {` are unchanged.
- `compiler` lexes as a name: `consumeParamName` refuses it as a parameter (`reserved-word-as-name`);
  in an expression it is the identifier `ast.compiler_keyword`.

After `unwrapProgram`, `compiler_surface.zig` `expandProgram` reads the surface onto the machinery
(`Parser.keep_surface` skips it — the formatter and the language server's formatting set it):
`compiler.<member>(…)` becomes the handle's, the template site's or a builtin's form (its table,
`members`, is held to std's `compiler.bp` by `comptime/tests/compiler_members.zig`, member for member and
each parameter's arrival — `syntax`, `comptime`, plain — for each, decision 616); a bare read of a
`comptime x: T` is `x.value` outside a member or a wrapper; a template's `return e` lifts `e`
(`@expr(e)`) unless it is a tree parameter or a call answering one; a call of a `comptime` parameter,
`rule(x)`, is `rule.value(x)` (refused for a function, 364 (3)); `compiler.custom(tree)` in a
template keeps the tree in a local, makes the template the custom carrier (the internal `__ExprCustom<T>`) and each
return `q.custom(tree, e)` (decision 576 (4)). A refusal is written at its place
as the builtin `compiler_surface.refusal_builtin` (`compiler-at-run-time` in `main` or a `test`,
`compiler-output-outside-decorator`, `syntax-captures-build` inside a member, a wrapper or an executor
(`compiler.init(f)`; one named, `compiler.init(f)` with `f` no function written there, is the tree
`{ -> f() }`, the call its tail, decision 409),
`compiler-member-unknown`), which the checker reports there (`infer.zig` `refuseSurface`).

A typed meta record's field is written `f: T`; one a decorator fills from a `syntax` parameter holds the
tree (575 (4), the checker's `treeFed`). The parameter modifier is `syntax` (decision 616 renamed 575 (4)'s
`expr`): `expr` is an ordinary name, and `syntax` one wherever no parameter name follows it.

## `defer` (decision 539)

`defer <expr>;` is a statement of a block — `parseBlockBody` (every list of statements) matches the keyword before
`parseExpr` and sets `Stmt.deferred`, which `ast.StmtOf.jsonStringify` dumps only when true, so no parser snapshot
moves. `defer { … }` is `defer` over a block expression. A deferred statement never carries a `tail` (it answers no
value, even written last without `;`: `parseBlockBody` and `markBlockTail` skip it). `defer` in expression position or at
module level is a parse error. `parser/tests/decision539.zig` pins the flag, the missing tail, the dump and the
error.
A `case` arm's block (`Pattern { … }` through `parseLambdaBody`, and `p -> { … }` in `parseCaseExpr`) matches the keyword too.

