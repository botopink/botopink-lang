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
| Lambdas | A parameterless lambda in expression position keeps `{ -> … }` (the braces alone re-parse as a block); a trailing lambda `f { … }` and a `case` arm's block body (a parameterless lambda in the AST) print `{ … }` |
| `case` arms | An arm whose body is a lambda prints decision 8 §5.1's `Pattern [when (…)] { body }` — no arrow, no `;`, the whole-value binder kept (`_ { n -> … }`); every other body keeps `pattern [if …] -> value;`. The pre-decision-8 block arm `1 -> { … };` is the same node, so it comes back in decision 8's spelling |
| Patterns | `ast.PatternShape` decides the spelling: a tuple pattern prints `#(…)`, an inclusive range `A...B`, a payload label `name: p`, and a pattern that ignores the rest ends in `..` |
| `if` branches | A single-expression branch prints bare; a multi-statement branch prints its statements one per line, each ended by `;` |
| String literals | `"""…"""` when the content spans lines or holds an unescaped `"`; `"…"` otherwise |
| `loop` body | `loop (…) { x ->` then one statement per line, each ended by `;` (the body shares `fmtStmtSeq` with `fn` and lambda bodies, including a trailing comment on its statement's line) |
| Imports | `import {a, b} from "m"`; the package-namespace forms keep the handle: `import pkg`, `import pkg from "m"`, `import pkg, {a} from "m"` |
| One-line lambda value | Rendered flat as one text (it may run past the width); a value that needs a line break of its own prints the open form — so a second `format` pass decides the same way |

## Layout the formatter keeps (front 12 step 4)

- **Comments inside a `type`/`behavior` body** — the parser attaches the `//` lines above a
  member to `BehaviorMethod.comments` / `BehaviorField.comments` (and the lines before `}` to
  `bodyComments`), with `""` for a blank source line; the formatter prints them above the
  member (`withMemberComments`, `fmtMemberBlock`).
- **Blank lines** — between body members (`""` in `comments`) and between top-level
  declarations (`Program.blankLineBefore`, filled by `parseDecls`).
- **Trailing comments** — a comment on the line of the previous statement or declaration
  (`f(); // note`, `pub mod x; // note`) sets `trailing` and stays on that line.
- **One-line lambdas** — `{ n -> n * 2 }` written on one line with a single value expression
  stays inline (`fmtLambdaAt`).
- An empty `////` line prints without a trailing space; `botopink format` (CLI) ends a file with
  one newline.
- None of these fields reach the parser snapshots: `jsonStringify` omits them when empty/false
  (`Program.blankLineBefore` always).

`botopink format --check` passes on `libs/std/**` and `examples/**`, and — since the formatter
follow-up of 2026-09-17 — on the five sibling libraries under `repository/`: formatted, they compile, pass
the same tests, and a second pass changes nothing. Canonical rewrites that remain (no content lost): a
`#[a, b]` annotation list prints as one `#[…]` per annotation, a method chain split over lines
joins onto one, a single-expression `if` block drops its braces, a `\\` line string prints as
`"""…"""`. `.d.bp` files are not reached by `format` (the loader never scans them into the
module tree); `libs/std/src/builtins.d.bp` does not parse (`fn await(…)`, `fn module() module`
shortforms) and is documentation only.

## Layout the parser does not record (formatter cannot keep)

- **Member order of an enum-shaped `type`** — `TypeShape.EnumShape` keeps `variants` and `sections`
  in two lists with no position, so the formatter prints every variant before every section
  (a type whose sections come before its payload variants is reordered; the program is unchanged).
- **End-of-line comments on a field or an array element** — `parseFieldList` and the array literal
  attach a comment to the *next* item (the last one's is dropped by `skipComments`), with no line
  information; the formatter prints it above the next item. Statement trailing comments are kept.
- **Blank lines inside a `loop` body or an `if` branch** — no `emptyLinesBefore` is recorded there.

Each needs a parser/AST change (`parser/decls.zig`, `parser/exprs.zig`) before the formatter can
print it back.
