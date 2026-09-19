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
    ├── declarations.zig ← val/const/let, type/behavior/implement/extend, the 1.0.3 separator rule, fn/pub fn, test blocks, empty lines
    ├── expressions.zig  ← binary/call/access/lambda/precedence/pipeline/tagged calls
    ├── literals.zig     ← list/tuple/array/float/int/string literals
    ├── patterns.zig     ← case / pattern / assert
    ├── comments.zig     ← comments / doc / todo
    └── idempotent.zig   ← idempotent round-trips
```

## Round-trip contract

`format(parse(src))` must produce output that re-parses to an equivalent AST,
and running `format` twice in a row must produce identical text.

## Formatting rules

| Construct | Rule |
|---|---|
| Declarations | Only the 1.0.3 surface is printed, whatever the source spelled (`record`/`enum`/`interface` included): `type`, `behavior`; no `;` after them |
| Record (`type`) | Field list in parentheses, no `val` → `type Point(x: i32, y: i32)`; compact without a trailing comma (even past the width), open one field per line with the trailing comma when the source had one or a field carries a `//` comment; field annotations and defaults inline; no body when there are no methods; ` implement B` after the field list |
| Enum (`type`) | `type Color { Red, Rgb(r: i32, g: i32, b: i32) }` compact; open (one item per line, trailing comma added) with a trailing comma, a section or a method; a blank line before the first method |
| Behavior | `behavior Name<G> extends B { … }`; `val x: T;`, bodyless `fn …;`, `default fn … { }`; a blank line between the field, signature and default-method groups; `{}` when empty |
| Pipeline `\|>` | A single step with no comments stays inline if it fits; multi-step chains (or any step comment) put each `\|>` on its own line |
| Array / list literals | Trailing comma or comments → multi-line; otherwise inline if it fits |
| Blank lines | `emptyLinesBefore` on statements and case arms is preserved as blank lines |
| Test blocks | `test { … }` / `test "name" { … }` — no trailing semicolon, body formatted like a `fn` body |
| Lambdas | A parameterless lambda in expression position keeps `{ -> … }` (the braces alone re-parse as a block); a trailing lambda `f { … }` and a `case` arm's block body (a parameterless lambda in the AST) print `{ … }`. An **empty** body stays inline — `{ next -> }`, `{ -> }`, and `{}` where no arrow is printed ([decision 61](../../../../specs/1.0.5-beta/decisions-taken.md) rule 2). The open form had nothing to put between its two hardlines, so it printed the body's indentation and then a newline: a line of eight spaces and nothing else, in a printer that emits a bare `"\n"` for a blank statement line precisely to avoid that |
| `case` arms | An arm whose body is a lambda prints decision 8 §5.1's `Pattern [when (…)] { body }` — no arrow, no `;`, the whole-value binder kept (`_ { n -> … }`); every other body keeps `pattern [if …] -> value;`. The pre-decision-8 block arm `1 -> { … };` is the same node, so it comes back in decision 8's spelling |
| Patterns | `ast.PatternShape` decides the spelling: a tuple pattern prints `#(…)`, an inclusive range `A...B`, a payload label `name: p`, and a pattern that ignores the rest ends in `..` |
| `if` branches | A single-expression branch prints bare; a multi-statement branch prints its statements through the same `fmtStmtSeq` a `fn`, `test`, `loop` and lambda body use — one per line, each ended by `;`, keeping a blank line and a trailing comment on its own statement's line |
| String literals | `"""…"""` when the content spans lines or holds an unescaped `"`; `"…"` otherwise |
| `loop` body | `loop (…) { x ->` then one statement per line, each ended by `;` (the body shares `fmtStmtSeq` with `fn`, lambda and `if`-branch bodies, including a trailing comment on its statement's line) |
| Imports | `import {a, b} from "m"`; the package-namespace forms keep the handle: `import pkg`, `import pkg from "m"`, `import pkg, {a} from "m"` |
| Package default | `[pub] default mod Name;` and `[pub] default fn f(…)` keep the `default` keyword, in the parser's order (`pub`, `default`, `declare`). It is not decoration: `default mod` names the package handle `import <pkg>` resolves to and `default fn` names the handler aliased under it (`comptime.zig`'s package-default DSL). Dropping it unbinds every consumer of a package whose handle and handler have different names, and — a deletion being idempotent — `format --check` then reports the broken file as clean |
| Parser desugarings | Printed back in the spelling that was **written**, never as the call the parser built: `xs[0]` (and `xs[0..2]`, `d["k"]`, `t[0]` — one node, decision 30) rather than `@[](xs, 0)`; `x is T` (decision 8 §4) rather than `@is(x)`, which deleted the tested type outright; `a ?? b` (decision 28) rather than `if (a) { __bp_nullish -> __bp_nullish } else { b }`. The reserved callees cannot be written by hand (`is` is a keyword, `@[]` does not lex) and the binding name is the reserved `__bp` prefix, so a node carrying one is always the desugaring. `nullishDefaultFallback` tests all four parts of the `if`, so an `if` that binds a name of its own is untouched |
| Chained call | `adder(3)(4)` — calling what a call returned. There is no name, so the callee is an **expression** (`ast.CallExpr.call.calleeExpr`, `callee` is `""`) and `receiver` stays null: a chained call is not a method call. Reading only `receiver` and `callee` printed the empty name and dropped the receiver — `adder(3)(4)` came back as `(4)` |
| Type references | A parenthesis is printed exactly where it is load-bearing. `parser/types.zig` binds `[]`, `?` and `\|` to a **base** type and does not keep `(T)` in the AST (`(T)` *is* `T`), so `fmtTypeRefIn` decides from the shape: an array of a union, an optional or a function type (`(i32 \| string)[]`, `(?i32)[]`, `(fn(i32) -> i32)[]`), an optional of a union (`?(i32 \| string)`), and a union or constraint-list member that is a function type (`(fn() -> i32) \| string`). Everywhere else the shortest spelling is the canonical one — `?i32[]`, `i32[] \| string[]`, `i32 \| string[]`. Printing the parentheses away gave **a different type**, and idempotently, so `format --check` reported it clean |
| One-line lambda value | Rendered flat as one text (it may run past the width); a value that needs a line break of its own prints the open form — so a second `format` pass decides the same way. Whether the lambda **binds a name** takes no part: `{ -> 3 + 4 }` stays on one line exactly as `{ n -> n * 2 }` does ([decision 61](../../../../specs/1.0.5-beta/decisions-taken.md) rule 3). The rule stops at `arrow_when_empty`, and the reason is the parser's, measured: a **trailing** lambda's body is a statement block, so its statements keep their `;` and `executar { ok }` answers *unexpected `}`* — as does `calcular(fator: 2) { a, b -> a + b }` — while `{ -> 42 }` and `{ n -> n * 2 }` in argument position both parse |

## Layout the formatter keeps (front 12 step 4)

- **Comments inside a `type`/`behavior` body** — the parser attaches the `//` lines above a
  member to `BehaviorMethod.comments` / `BehaviorField.comments` (and the lines before `}` to
  `bodyComments`), with `""` for a blank source line; the formatter prints them above the
  member (`withMemberComments`, `fmtMemberBlock`).
- **Blank lines** — between body members (`""` in `comments`) and between top-level
  declarations (`Program.blankLineBefore`, filled by `parseDecls`).
- **Trailing comments** — a comment on the line of the previous statement or declaration
  (`f(); // note`, `pub mod x; // note`) sets `trailing` and stays on that line. A **member's**
  is its own slot, `trailingComment` on `Field`, `EnumVariant` and `BehaviorMethod`, filled by the
  parser's same-line test: `x: i32, // horizontal` keeps its line, where before it was re-attached
  to the next field — saying something false — and on the last field deleted outright.
- **Member order of an enum-shaped `type`** — `variants` and `sections` are two parallel slices and
  a body may interleave them, so each member carries its position in `order` and `fmtEnumMembers`
  merges the two lists by it. Printing all of one and then all of the other hoisted every variant
  written after a section above it. Nothing in `src/codegen/` may key on a variant's position in
  `TypeShape.EnumShape.variants` — `order` is source layout, not a run-time encoding.
- **Comments on an enum variant or section** — `EnumVariant.comments` / `EnumSection.comments`
  (leading, `""` for a blank line) and `EnumVariant.trailingComment`. Either one forces the enum
  body open: the compact `{ Red, Blue }` has nowhere to put a `//`.
- **One-line lambdas** — `{ n -> n * 2 }` written on one line with a single value expression
  stays inline (`fmtLambdaAt`).
- **Blank lines and comments in every block** — including an `if` **then**-branch and a lambda
  body, which is every `loop (…) { x -> … }` body. Those two were the last blocks whose statements
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

`botopink format --check` passes on `examples/**` and — since `09-ecosystem-residuals` committed the
formatted text (2026-09-18) — on all five sibling libraries under `repository/`: formatted, they
compile, pass the same tests, and a second pass changes nothing. **`libs/std` has two files that
would be reformatted** as of `f8d97f95`: `src/primitives.bp:549` (a braced single-statement `if`
inside a `loop`) and `src/querystring.bp:37` (a method chain that now fits on one line). Both are the
canonical rules below and neither loses text; the drift is from edits made after the last sweep, and
`libs/std` is not this front's directory. Canonical rewrites that remain (no content lost): a
`#[a, b]` annotation list prints as one `#[…]` per annotation, a method chain split over lines
joins onto one, a single-expression `if` block drops its braces, a `\\` line string prints as
`"""…"""`. `.d.bp` files are not reached by `format` (the loader never scans them into the
module tree); `libs/std/src/builtins.d.bp` does not parse (`fn await(…)`, `fn module() module`
shortforms) and is documentation only.

## Layout the parser does not record (formatter cannot keep)

- **End-of-line comments on an array element** — the array literal attaches a comment to the *next*
  item, with no line information, so the formatter prints it above that item. A **field's** is kept
  (`Field.trailingComment`), and so are a statement's, a variant's and a method's.
- **The indentation of a comment's continuation line** — a `//` line the author indented to align
  under the comment above it (one site, in a sibling library under `repository/`) re-emits at the
  statement's own column. The text is intact; the alignment is not. A comment reaches the AST as text
  with no column, so keeping it needs a recorded column, not a printer arm — it is the last live
  member of `09-ecosystem-residuals`' R1 classes and the only fidelity loss left after formatting all
  five libraries.

Each needs a parser/AST change (`parser/decls.zig`, `parser/exprs.zig`) before the formatter can
print it back.
