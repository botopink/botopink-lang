# compiler-core/src/format

> Path: `modules/compiler-core/src/format/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Formatter tests. The Wadler-Lindig pretty-printer itself is at `../format.zig`.

## Tree

```text
format/
├── AGENTS.md     ← you are here
├── tests.zig     ← barrel: aggregates tests/<feature>.zig for test_root.zig
└── tests/        ← format tests, split by feature
    ├── helpers.zig      ← shared harness (`assertFormat`/`assertFormatAs`/`assertIdempotent`)
    ├── imports.zig      ← import formatting
    ├── declarations.zig ← val/var/const/let, type/behavior/implement/extend, the 1.0.3 separator rule, fn/pub fn, test blocks, empty lines
    ├── expressions.zig  ← binary/call/access/lambda/precedence/pipeline/tagged calls
    ├── literals.zig     ← list/tuple/array/float/int/string literals
    ├── patterns.zig     ← case / pattern / assert
    ├── comments.zig     ← comments / doc / todo
    ├── idempotent.zig   ← idempotent round-trips
    └── predicate.zig    ← `fits` / `fitsPinned` on hand-built documents (decision 65)
```

## Round-trip contract

`format(parse(src))` must produce output that re-parses to an equivalent AST,
and running `format` twice in a row must produce identical text.

## `fits` measures width; the value constructs are enabled, the rest still pinned

Two predicates decide a `group` ([decision 65](../../../../specs/1.0.5-beta/decisions-taken.md)).
`fits` is the Wadler-Lindig one: it walks the candidate's flat spelling on its own
stack, charging every `text`, one column per `line`, and what the render still owes
the same line after the group (the `;`, the `)`, the ` {`) — a `hardline` or a
`forceBreak` *inside* the candidate means the flat spelling does not exist, a break
*after* it means the line ends there. A `group` asks it only when built with
`groupMeasured`; a plain `group` asks `fitsPinned`, the scan this formatter always
had, which stops at the first `concat` and answers "fits" for any non-negative
budget — so every construct whose canonical broken form has not been written down
renders exactly the text it always rendered. Pinning is a phase, not a setting:
nothing in a source file, a flag or the environment reaches it, and the last
construct to be enabled deletes `fitsPinned` and the `measured` field with it.
`Doc.widthChoice { flat, broken, flatWidth }` predates the repair and stays for the
`fn` signature (decision 61 rule 4): its flat width is measured when the node is
built and compared against the real column. `Doc.ifBreak(s)` is text that exists
only in the enclosing group's broken spelling — the trailing comma of an open
argument list — so a flat and a broken form share one document; `fits` never
charges it flat and charges it in the trailing half when the group it sits in is
broken. `Doc.markColumn` / `Doc.alignToMark` are zero-width to both predicates (a
pad only ever follows a line break): the first records the render's column, the
second pads a later line to it. `tests/predicate.zig` exercises both predicates on hand-built documents —
the exact boundary, the trailing text, the break after the group, the hardline
inside it, a pinned group past the width, and `ifBreak` flat, broken and trailing.

**The method chain is the first construct enabled, and its landing was measured
rather than assumed** (2026-09-20, C-12's acceptance). Three binaries — `d55a3b87`
(before the repair), `f9cf2ace` (the repair + the chain, merged as-is) and HEAD —
each formatted a scratch copy of the six trees (`libs/std` and the five libraries
under `repository/`, their nested example projects included: 85 `.bp` files) and
the copies were diffed: `d55a3b87 → f9cf2ace` moved **6 files** — `libs/std`'s
`path.bp` and `querystring.bp`, and four in three of the five sibling libraries
(a `src/` file in each, plus one nested example project's `main.bp`) — in **18
hunks**, every one of them a chain opened by the rule: **29 chain sites** (`libs/std`
2; the three libraries 1, 19 and 7; the other two 0) plus 3 in the compiler's own
`examples/**` — and **0 hunks of any other kind**: each moved file is byte-equal to its `d55a3b87`
output once whitespace is removed, so the pinned groups did not move. `f9cf2ace →
HEAD` moved **0 bytes** in the six trees. Decision 65 predicted 44 chains from a
grep of the lines past 80 columns; 32 opened, and the rest of that grep's lines
are not chains the formatter can break: 8 are JavaScript inside
`#[@External.Node("""…""")]` strings (std 7, emilia 1), 1 is a comment, and 1
(`libs/std/src/asserts.bp:51`) is a chain in an `if` condition whose trailing
`@panic(…)` arguments sit in a pinned group — `fits` reads a trailing group in
the enclosing break mode, as Wadler's does, so the chain fits and the
still-pinned argument list is what runs long. The HEAD output is idempotent
(`format --check` over it reports only the files that never parsed) and every
tree still parses. Commands: `zig build` in three worktrees, `find . -name '*.bp'
| sort | xargs botopink format` per copy, `diff -ru`.

**The value constructs are enabled together, enclosing ones first** (2026-09-26,
C-12). The argument list could not be enabled alone: measured 2026-09-25 over the
six trees it opened ~1 480 of ~2 770 lists for what *followed* them (`) != -1;`,
`) + "…"`) because the binary expression around it was pinned — the wrong middle
decision 65 names. The order chosen is the enclosing constructs with it, in one
change: a **binary run**, a **brace-less `if`**, the **argument list**, and the
**array, tuple and behavior literals** (which enclose calls too — `[ThemeEntry(`
opened inside a pinned list). Each is one `groupMeasured`, all-or-nothing; the
outer decides first and the inner is measured where the outer put it, so a list
never breaks for what follows it: the enclosing binary breaks first
(`assert doc.indexOf(…)` / `    != -1;`) and the list is measured on its own
line. Measured over the compiler's trees (`libs/std`, the three bundled
libraries, `examples/`) and the five sibling libraries at their pinned commits —
248 files, formatted as scratch copies with the parent commit's binary and this
one: **140 files, 1 079 hunks, +20 319 −6 776 lines**; lines past 80 columns
**5 973 → 1 840** (the rest are strings and comments no rule breaks); lines that
open with `)` and go on with an operator **192 → 8** (the 8 are `) implement …`,
a `), // comment` and one call argument ending a pinned pattern list); a second
pass moves **0** files; every file keeps every token and comment
(`assertLossless`' property, run lexically over the copies). What stays pinned:
`commaList` — generic, parameter, pattern, import and type lists, none of which
can hold a call — and the single-step pipeline. The array literal's open form is
one element per line: keeping elements written on one source line together made
the layout a function of the source's (decision 65 part 2) and was not idempotent
once the list measured width. A trailing comma still opens a list (the canonical
form has always done that); whether it should is a question, recorded in
`decisions-pending.md` beside this landing.

## Formatting rules

| Construct | Rule |
|---|---|
| Declarations | Only the 1.0.3 surface is printed, whatever the source spelled (`record`/`enum`/`interface` included): `type`, `behavior`; no `;` after them |
| Module-level `val` / `var` | `fmtValDecl` prints the keyword the binding was declared with (`var` when `ValDecl.mutable`, decision 48's arm) and its annotations above it, as a `fn`'s print — without the arm `format` deleted `var` and `#[@BeamMemory.Ets]` and reported the file clean |
| Annotation arguments | A labelled argument prints `label = value` (`#[@BeamMemory.Ets(keyed = true)]`, `#[@External.Erlang("string:slice($0, 0, 1)", inline = true)]` — on the two targets whose emitters read the flag, front 20 F9); `label: value` is read and printed in that one canonical form — before `Annotation.labels` it printed `("charAt", true)` |
| Record (`type`) | Field list in parentheses, no `val` → `type Point(x: i32, y: i32)`; compact without a trailing comma (even past the width), open one field per line with the trailing comma when the source had one or a field carries a `//` comment; field annotations and defaults inline; no body when there are no methods; ` implement B` after the field list |
| Enum (`type`) | `type Color { Red, Rgb(r: i32, g: i32, b: i32) }` compact; open (one item per line, trailing comma added) with a trailing comma, a section or a method; a blank line before the first method |
| Behavior | `behavior Name<G> extends B { … }`; `val x: T;`, bodyless `fn …;`, `default fn … { }`; a blank line between the field, signature and default-method groups; `{}` when empty |
| `fn` signatures | A signature that does not fit breaks **one parameter per line, with a trailing comma**, closing on its own line, with the return type and the body's `{` after the `)` ([decision 61](../../../../specs/1.0.5-beta/decisions-taken.md) rule 4). It covers all five signature printers — `fn`, `declare fn`, a `type`'s method, a behavior method bodyless or not, and an `implement`/`extend` method. `fmtParams`' `commaList` is a `group` that was meant to do this and never once did: `fits` stops at the first `concat`, so a signature joined past the width (the decision's own example reached **104** columns against 80). `fmtSignature` decides from a flat width measured at build time against the column the render has really reached, which is why a method four columns in breaks four columns earlier; the `;` or ` {` that follows the signature is counted too, so the boundary is exact — 80 columns stays on one line, 81 breaks. A parameter default that itself needs a line (a lambda) has no flat width and keeps whatever it printed before |
| Pipeline `\|>` | A single step with no comments stays inline if it fits; multi-step chains (or any step comment) put each `\|>` on its own line |
| Array / list / tuple literals | One `groupMeasured`: on one line when it fits, what follows counted; otherwise one element per line, `+4`, the trailing comma of the open form (`ifBreak(",")`), `]` / `)` on its own line. A trailing comma or a comment in the source opens it; the open form puts **one element per line** — elements written on one source line are no longer kept together |
| Binary expressions | A run of operands at one precedence level (`a + b - c`) is one `groupMeasured`; broken, the first operand stays on the line and every other one starts a line of its own **operator first**, `+4` from the statement — the method chain's shape, the operator where the chain puts its `.`. A run at another level is its own group, measured where the outer run put it |
| Behavior literal | `@Decl(kind: …, fields: […])` — the argument list's shape |
| Call arguments | One `groupMeasured` (decision 61 rule 4's shape, C-12): one line when it fits, else one argument per line `+4`, trailing comma, `)` on its own line — a hand-opened list that fits is joined. A **lambda argument hugs the call** ([decision 61](../../../../specs/1.0.5-beta/decisions-taken.md) rule 1): the argument list drops its `nest(INDENT)` and its softlines, so the lambda's own `forceBreak` opens at the call's indentation — body at +4 from the call line, `});` level with the call. It applies to a lambda in **any** argument position (`throws({ -> … }, "expected")` puts it first) and only when that lambda's own printing breaks; a one-line lambda, an argument carrying a `//` comment and a multiline-string argument all keep the grouped/open forms. Before this the two nests compounded: one line break paid +8 for the body and +4 for the brace |
| Blank lines | `emptyLinesBefore` on statements and case arms is preserved as blank lines |
| Test blocks | `test { … }` / `test "name" { … }` — no trailing semicolon, body formatted like a `fn` body |
| Lambdas | A parameterless lambda in expression position keeps `{ -> … }` (the braces alone re-parse as a block); a trailing lambda `f { … }` and a `case` arm's block body (a parameterless lambda in the AST) print `{ … }`. An **empty** body stays inline — `{ next -> }`, `{ -> }`, and `{}` where no arrow is printed ([decision 61](../../../../specs/1.0.5-beta/decisions-taken.md) rule 2). The open form had nothing to put between its two hardlines, so it printed the body's indentation and then a newline: a line of eight spaces and nothing else, in a printer that emits a bare `"\n"` for a blank statement line precisely to avoid that |
| `case` arms | An arm whose body is a lambda prints decision 8 §5.1's `Pattern [when (…)] { body }` — no arrow, no `;`, the whole-value binder kept (`_ { n -> … }`); every other body keeps `pattern [if …] -> value;`. The pre-decision-8 block arm `1 -> { … };` is the same node, so it comes back in decision 8's spelling |
| Patterns | `ast.PatternShape` decides the spelling: a tuple pattern prints `#(…)`, an inclusive range `A...B`, a payload label `name: p`, and a pattern that ignores the rest ends in `..` |
| `if` branches | A **bare** (single-expression) then-branch makes the `if` one `groupMeasured` (C-12): when its line does not fit the branch moves to the next line `+4`, a bare `else` branch likewise under an `else` of its own line, and an `else if` chain breaks at every `else` or at none — so a condition never breaks for the branch that follows it. A braced `else { … }` stays outside the group (its block always breaks). A single-expression branch prints bare; a multi-statement branch prints its statements through the same `fmtStmtSeq` a `fn`, `test`, loop and lambda body use — one per line, each ended by `;`, keeping a blank line and a trailing comment on its own statement's line |
| String literals | `"""…"""` when the content spans lines or holds an unescaped `"`; `"…"` otherwise |
| Loops | Decision 105's three keywords print back as written, from `LoopExpr.keyword`: `for [await] [:label] (iter) { x ->`, `while [:label] (cond) {`, `loop [:label] {` — and the `iter` / `stream` prefix from `LoopExpr.generator` (decision 125): `iter loop {` as it stands, and a prefixed `while` / `for` — held as `loop { <written loop>; break; }` with `LoopExpr.prefixedKeyword` set — printed as `iter ` / `stream ` followed by the written loop (`body[0]`). The prefix arm is front 24's carve-out of front 16, and so is the `async { … }` arm of a `.function` node with `syntax = .asyncBlock` (decision 124). A range prints `a..b` or, when `inclusive`, `a...b`. An empty body stays inline (`for (xs) { x -> }`); otherwise one statement per line, each ended by `;` (the body shares `fmtStmtSeq` with `fn`, lambda and `if`-branch bodies, including a trailing comment on its statement's line). The `while`/`for` arms are front 22's carve-out of front 16; their width and breaking are 16's |
| Imports | `import {a, b} from "m"`; the package-namespace forms keep the handle: `import pkg`, `import pkg from "m"`, `import pkg, {a} from "m"` |
| Package default | `[pub] default mod Name;` and `[pub] default fn f(…)` keep the `default` keyword, in the parser's order (`pub`, `default`, `declare`). It is not decoration: `default mod` names the package handle `import <pkg>` resolves to and `default fn` names the handler aliased under it (`comptime.zig`'s package-default DSL). Dropping it unbinds every consumer of a package whose handle and handler have different names, and — a deletion being idempotent — `format --check` then reports the broken file as clean |
| Parser desugarings | Printed back in the spelling that was **written**, never as the call the parser built: `xs[0]` (and `xs[0..2]`, `d["k"]`, `t[0]` — one node, decision 30) rather than `@[](xs, 0)`; `x is T` (decision 8 §4) rather than `@is(x)`, which deleted the tested type outright; `a ?? b` (decision 28) rather than `if (a) { __bp_nullish -> __bp_nullish } else { b }`. The reserved callees cannot be written by hand (`is` is a keyword, `@[]` does not lex) and the binding name is the reserved `__bp` prefix, so a node carrying one is always the desugaring. `nullishDefaultFallback` tests all four parts of the `if`, so an `if` that binds a name of its own is untouched |
| Method chain | Two or more method calls in a row (`a.b().c()`) are **one** `groupMeasured`, all-or-nothing ([decision 65](../../../../specs/1.0.5-beta/decisions-taken.md)): one line when the flat spelling fits — what follows on the line (`;`, `)`) counted, so 80 columns stay and 81 break — otherwise the root (`of(people)`, `self.items`, `xs`) on the statement's line and **every** call on its own line, `+4` from the statement and never aligned under the receiver (a rename must not re-indent a chain). No two calls share a line in the broken form. The output is a pure function of the content: a hand-broken chain that fits is joined, a one-line chain that does not fit is opened, and a link holding a lambda that breaks (`.forEach({ x ->` with a statement body) breaks the whole chain, because its flat spelling does not exist. A link is `recv.name(…)` / `recv?.name(…)`; a plain call, a builtin, a tagged call and `adder(3)(4)` are not links, and a single method call is not a chain (it keeps the flat/hug printing it always had). This was the first construct enabled under the fixed `fits` |
| Chained call | `adder(3)(4)` — calling what a call returned. There is no name, so the callee is an **expression** (`ast.CallExpr.call.calleeExpr`, `callee` is `""`) and `receiver` stays null: a chained call is not a method call. Reading only `receiver` and `callee` printed the empty name and dropped the receiver — `adder(3)(4)` came back as `(4)` |
| Type references | A parenthesis is printed exactly where it is load-bearing. `parser/types.zig` binds `[]`, `?` and `\|` to a **base** type and does not keep `(T)` in the AST (`(T)` *is* `T`), so `fmtTypeRefIn` decides from the shape: an array of a union, an optional or a function type (`(i32 \| string)[]`, `(?i32)[]`, `(fn(i32) -> i32)[]`), an optional of a union (`?(i32 \| string)`), and a union or constraint-list member that is a function type (`(fn() -> i32) \| string`). Everywhere else the shortest spelling is the canonical one — `?i32[]`, `i32[] \| string[]`, `i32 \| string[]`. Printing the parentheses away gave **a different type**, and idempotently, so `format --check` reported it clean |
| One-line lambda value | Rendered flat as one text (it may run past the width); a value that needs a line break of its own prints the open form — so a second `format` pass decides the same way. Whether the lambda **binds a name** takes no part: `{ -> 3 + 4 }` stays on one line exactly as `{ n -> n * 2 }` does ([decision 61](../../../../specs/1.0.5-beta/decisions-taken.md) rule 3). The rule stops at `arrow_when_empty`, and the reason is the parser's, measured: a **trailing** lambda's body is a statement block, so its statements keep their `;` and `executar { ok }` answers *unexpected `}`* — as does `calcular(fator: 2) { a, b -> a + b }` — while `{ -> 42 }` and `{ n -> n * 2 }` in argument position both parse |

## Layout the formatter keeps (front 12 step 4)

- **A behavior `val` member and a `declare fn` delegate print whole types** — `fmtBehavior`
  prints `BehaviorField.typeRef` through `fmtTypeRef` (`val fields: Field[];`), and
  `fmtDelegate` prints the generic list and `fmtReturnTypeRef`
  (`pub declare fn getContext<T>(comptime _: type) -> Component<T, any>;`) — front 20.
- **Comments inside a `type`/`behavior` body** — the parser attaches the `//` lines above a
  member to `BehaviorMethod.comments` / `BehaviorField.comments` (and the lines before `}` to
  `bodyComments`), with `""` for a blank source line; the formatter prints them above the
  member (`withMemberComments`, `fmtMemberBlock`).
- **Blank lines** — between body members (`""` in `comments`) and between top-level
  declarations (`Program.blankLineBefore`, filled by `parseDecls`).
- **A trailing comment's continuation lines** — `f(); // one` followed by `// two` starting in the
  **source** column `// one` starts in, on the very next line, is a continuation: it prints under
  `// one`'s **printed** column, which moves when the code before it does (`Doc.markColumn` records
  the column, `Doc.alignToMark` pads to it; `CommentChain` decides). A statement comment's column is
  its `loc`; a top-level one's is `DeclKind.comment.loc`, which the parser now records. A comment in
  another column or after a blank line is an ordinary comment, printed at the indentation. Before
  this every continuation was re-emitted at the statement's column — `09-ecosystem-residuals`' last
  R1 class (a sibling library's `runtime.bp:13`, whose earlier revision now round-trips).
- **Trailing comments** — a comment on the line of the previous statement or declaration
  (`f(); // note`, `pub mod x; // note`) sets `trailing` and stays on that line. A **member's**
  is its own slot, `trailingComment` on `Field`, `EnumVariant` and `BehaviorMethod`, filled by the
  parser's same-line test: `x: i32, // horizontal` keeps its line, where before it was re-attached
  to the next field — saying something false — and on the last field deleted outright.
- **Member order of an enum-shaped `type`** — `variants` and `sections` are two parallel slices and
  a body may interleave them, so each member carries its position in `order` and `fmtEnumMembers`
  merges the two lists by it. Printing all of one and then all of the other hoisted every variant
  written after a section above it. Nothing in `src/codegen/` may key on a variant's position in
  `TypeShape.EnumShape.variants` beyond its index among the variants (wasm's all-unit ordinal) —
  `order`, the interleaving with sections, is source layout, not a run-time encoding.
- **Comments on an enum variant or section** — `EnumVariant.comments` / `EnumSection.comments`
  (leading, `""` for a blank line) and `EnumVariant.trailingComment`. Either one forces the enum
  body open: the compact `{ Red, Blue }` has nowhere to put a `//`. The lines before a body's
  closing `}` are `TypeDecl.bodyComments` (an enum's as well as a record's) and
  `EnumSection.bodyComments`, printed after the last member — emilia's `tokens.bp` closes four
  sections with `// ── end front NN ──`, and all four were deleted until 2026-09-26.
- **The handler-less `val assert P = e;`** (decision 8 § 9) prints no `catch`: `assertPattern.fatal`
  marks the `@panic(…)` handler the parser desugared it to. Printing it wrote a `catch` the checker
  refuses, so `format` stopped 15 packages of a sibling library from compiling.
- **One-line lambdas** — `{ n -> n * 2 }` written on one line with a single value expression
  stays inline (`fmtLambdaAt`).
- **Blank lines and comments in every block** — including an `if` **then**-branch and a lambda
  body, which is every `for (…) { x -> … }` body. Those two were the last blocks whose statements
  came from an inlined loop in `parser/exprs.zig` that recorded no `emptyLinesBefore` and made a
  `//` there a parse error; `15-language-surface`'s `28e447e` routed them through
  `parseStmtListInBraces`, and this printer has read the field all along (one `fmtStmtSeq` for every
  block since `9d1d067`), so all three — then-branch, else-branch and `loop` body — keep a blank
  line and a comment now. Measured, not assumed: a blank line plus a `//` in each of the three
  round-trips byte-identically.
- An empty `////` line prints without a trailing space; `botopink format` (CLI) ends a file with
  one newline.
- None of these fields reach the parser snapshots: `jsonStringify` omits them when empty/false
  (`Program.blankLineBefore` always).

`botopink format --check` at a project root reaches **every** `.bp` and `.d.bp` the project owns —
`src/**`, `test/**`, `examples/**` and the projects nested inside — and structurally leaves out hidden
directories, `node_modules` and a `reject/<n>.bp` beside its `<n>.expect` (decision 66;
`modules/compiler-cli/src/cli/format_cmd.zig`). Measured with that walk at HEAD (2026-09-20), the
reds and their causes: **`libs/std`** — `src/path.bp:82` and `src/querystring.bp:38` are method
chains decision 65 opens (09's reformat); `src/builtins.d.bp` and `src/builtins_fns.d.bp` are
canonical and in `scripts/format-check.sh` since front 20. **`examples/generic-loader-binding`** (two chains) and **`examples/stdlib-tour`** (one
chain and two lambda arguments that hug the call, decision 61 rule 1). **`tests/language`** — never
formatted: `modules/*` 7 of 7 files (C-16's row), `run/` 8 of 15, `test/` 41 of 49; two cells do not
parse, `run/optional_null_pattern.bp:21` (`null` as a `case` pattern) and `test/case_arms.bp:21`
(`1..9`, the named error `pattern-range-exclusive`) — the suite's rows. **`modules/compiler-cli/tests`**
— 5 fixtures at two-space indent. Of the five sibling libraries under `repository/`, two are
canonical whole and three are red, none of it losing text: the CSS library (one chain in `src/`; its
example project's `main.bp` — import spacing, blank lines between declarations, an array-literal
argument's indent), the query library (12 chains in `src/`, 4 in its example project) and the frontend
library (7 chains in `src/html.bp`; its `test/html_test.bp` and three example projects — import
spacing, an `html """…"""` with no newline printed `html "…"`, single-statement `if` braces,
array-literal argument indent). Three files of the frontend library's `examples/*-app/app/**` cannot
be formatted at all: `h1 { "my blog" }` — a trailing lambda whose one-line body is a statement block
— answers *unexpected `}`* (the `arrow_when_empty` row below; front 15's parser surface). `scripts/format-check.sh`, stage
3 of the gate, calls `format --check` over the trees that are canonical (`examples/modules` today)
and names the rest with their owners. Canonical rewrites that remain (no content lost): a `#[a, b]`
annotation list prints as one `#[…]` per annotation, a method chain that fits joins onto one line and
one that does not opens, a single-expression `if` block drops its braces, a `\\` line string prints
as `"""…"""`.

- **End-of-line comments on an array or tuple element** (G7) — `trailingPerElem[i]`, the comment
  written on element `i`'s own line after it and its `,`, prints there (`1, // one`) and forces the
  open form. Before, the literal counted it among the *next* element's leading comments and the
  printer put it above that element, where it is false — idempotently.

## Layout the parser does not record (formatter cannot keep)

Nothing known, as of 2026-09-26: the five sibling libraries formatted as scratch copies lose no
token and no comment (a lexical multiset comparison per file), and every package `check`s as before.
