# compiler-core/src/codegen/js

> Path: `modules/compiler-core/src/codegen/js/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

The JavaScript / TypeScript code model and the emitters that render it.
Everything that writes JS or `.d.ts` text goes through here, so the commonJS
backend and the typedef backend share one set of lexical and layout rules.

The split is the same one the BEAM side uses (`../beam/`):

- **the backend builds a model** — it decides what shape a botopink construct
  becomes (a `loop` becomes a `for…of`; a `try` becomes `"error" in _r`
  matching; a `record` becomes a `class`);
- **the emitter renders it** — it decides how that shape is spelled (quoting,
  escaping, the reserved-word rename, parentheses, indentation, semicolons).

A backend that writes target text by hand is a bug, not a shortcut.

## Tree

```text
js/
├── AGENTS.md       ← you are here
├── js_ast.zig      ← the model: JS `Expr`/`Stmt`/`Pattern`/`Block`/`Class`/`Item`,
│                     the `.d.ts` `TsDecl`/`TsMember`/`TsType`, and `Builder`
├── js_emitter.zig  ← the only writer of JavaScript text
├── js_prelude.zig  ← the runtime helpers a module may call, as built nodes
└── ts_emitter.zig  ← the only writer of `.d.ts` text
```

## Files

| File | Role |
|---|---|
| `js_ast.zig` | `Class` carries `extends`, which only an enum's variant subclass uses. `Expr` (`lexeme_string`, `quoted`, `number`, `null_`, `ident`, `name`, `this`, `member`, `index`, `call`, `new_`, `binary`, `unary`, `ternary`, `assign`, `paren`, `arrow`, `function`, `array`, `object`, `host`, `await_`, `yield_`, `comment`), `Stmt` (`expr`, `decl`, `return_`, `throw_` (required operand), `continue_`, `continue_label`, `break_`, `yield_delegate`, `if_`, `for_of`, `while_` (+ an optional `label`), `block`, `function`, `class`, `comment`, `group`), `Pattern` (`ident`, `name`, `object`, `array`, `match`), `Param`, `Block` (+ `Layout`), `Class`, `Comment`, `Item`; the `.d.ts` subset `TsType` / `TsField` / `TsParam` / `TsMember` / `TsDecl`; and `Builder` (arena: `ptr`, `stmtPtr`, `typePtr`, `call`, `member`, `binary`, `ternary`, `arrowBlock`, `iife`, `ifStmt`, `group`, …). |
| `js_emitter.zig` | **Names:** `ident(name)` — the ES reserved-word rename (`delete` → `delete_`); the only place it happens. A property position is never renamed. **Strings:** `writeLexemeString` — a botopink lexeme's escape pairs pass through (the lexer validated them and the escape set is JS-compatible), raw control bytes and unescaped quotes are escaped. **Code:** `writeExpr(w, expr, indent)`, `writeStmt(w, stmt, indent)`, `writeBlock`, `writeInline`/`writeInlineStmt`, `writePattern`, `writeComment`/`writeInlineComment`, `writeProgram(w, items)` (generated declarations separated by a blank line; runtime-support source verbatim). |
| `js_prelude.zig` | The commonJS runtime helpers for primitive methods whose native JS method disagrees with the signature, as built `Stmt.function` nodes — never a shipped file. `Helper` (`assert_fatal`: a non-test `assert` throws with message and `file:line`; `string_char_at`: `String.at -> ?string` (the native method it wraps is `charAt`), `null` out of range; `range_from`: an open-ended `a..` as the lazy generator `function* __bp_range_from(n)`; `structural_eq`: `__bp_eq(a, b, d)`, `==` between composite values — arrays and tuples element-wise, a class instance by constructor plus own fields (decision 8 §6 T6 and decision 35); `show`: `__bp_show(v, shape, top, a)`, the text of one printed value under decision 8 §7 — a string, a `"f"`-shaped number as `5.0`, an array or tuple with spaces, a `__bp`-marked record or variant in the language's shape, `Display` when the value has one, `%O` otherwise; `print` / `print_as`: `@print`'s `console.log` line over `show`, without / with the per-argument static shapes), `forMethod(receiver, method, argc)` (the declaration a helper answers), `name`, `decl`, `order`. `commonJS.zig`'s `Emitter.helper` returns the name **and** marks the helper, and only marked helpers are written into the module (the `wat/wat_prelude.zig` shape). |
| `ts_emitter.zig` | `writeType`, `writeDecl`, `writeProgram(w, decls)` — one declaration per typed binding, separated by a blank line, a binding with no surface (`.none`) still taking its separator. `TsMember.method` carries a `modifier` (as `field` does), which is how an enum's variant factories and methods are written `static`. |

## A comment never ends a line something else still needs

A comment written in the SOURCE reaches codegen as an **expression**
(`literal.comment`), so one standing where a statement stands arrives as an
expression statement wrapping it. The backend writes some blocks on ONE line
(`Block.Layout.spaced` / `.tight`), and `// …` runs to the end of the physical
line: on that line the statements after the comment, the block's own `}` and
whatever closes the expression the block is inside — `})();` for an IIFE — are
all still to come, and `//` deleted every one of them. The module was left
unterminated and node answered `SyntaxError: Unexpected end of input` at exit 1,
where erlang printed the program's answer (D9 of 1.0.10-beta `00 · 04-js`).

`writeInlineStmt` is the rule: on a one-line block a line comment is spelled
`/* … */`, with any `*/` in the text broken up so it cannot close early, and the
expression statement's own `;` goes with it. Multi-line layouts keep `//`, where
it owns its line. It belongs here and not in the backend — which layout a block
takes is the backend's decision, but what a comment is SPELLED as, given the
line it lands on, is lexical, and lexical rules live in the emitter.

## What a value is (1.0.5-beta decision 5)

Every botopink value with a declared type is an **instance of a class this
backend emits**, so the value's prototype is its identity:

| botopink | commonJS |
|---|---|
| `type Person(name: string, age: i32)` | `class Person { constructor(name, age) { … } }` |
| `type Shape { Circle(radius: i32), Dot }` | `class Shape {}` + `class Shape$Circle extends Shape` + `class Shape$Dot extends Shape` |
| `Shape.Circle(5)` | `Shape.Circle(5)` — a `static` factory returning `new Shape$Circle(5)` |
| `Shape.Dot` | a **singleton**, `Shape.Dot = new Shape$Dot()` — no longer the bare string `"Dot"` |
| an enum method | a `static` of the enum's class (`Shape.area(value)`) |
| a method carrying an effect | the same member with `ClassMember.is_async` / `.is_generator` — `async name()`, `*name()`, `static async *name()` |

Two prototype properties carry what the instance itself does not:

- **`<Class>.prototype.__bp`** — the source name of the type (`"Point"`,
  `"Shape"`), written for every record class and every **base** enum class. It
  is the marker the §7 formatter tests, so a host object (a `Map`, a JSON
  object, a `@Result`'s `{ ok }`) never takes the botopink-value branch.
- **`<Variant>.prototype.tag`** — the variant's own name, written on each
  variant subclass. On the prototype, so `Object.keys(value)` answers exactly
  the payload fields in declaration order, which is what the formatter prints
  and what a `case` arm destructures.

A `case` arm names its variant with whatever path it was written with
(`Shape.Circle`, `.Circle`, `Circle`), and the path is dropped before anything
is looked up — the class, the `tag` and the declared field order all key on the
bare name the constructor wrote.

A `case` arm over a payload-less variant tests `instanceof` when the variant's
bare name names exactly one class in the module, and falls back to the `tag`
test when two enums in the module share that name (`Token.Text.Bold` and
`Token.Font.Weight.Bold` in emilia) or when the enum is declared in another
module — the emitter knows the arm's spelling, not the subject's type. The
`tag` test is exactly as ambiguous as the string compare it replaced, and no
more; a checker that hands the emitter the subject's enum would let every arm
be an `instanceof`.

`Object.freeze` is gone with the enum object: an enum is a class, and its
payload-less singletons are assigned onto it after its subclasses exist.

A method's effect is **two flags, not a keyword string.** A declaration spells
its modifiers as one word (`async function*`); a method spells the same two
without the `function` word and in a fixed order — `static`, then `async`, then
`*` — so `ClassMember` carries `is_async` and `is_generator` and `writeClass`
writes them in that order. The backend fills them from one table
(`commonJS.zig`'s `effectShape` / `methodEffect`), which is what makes
`#[@iterator] fn each(self: Self)` the `*each()` a `for…of` can consume.

`__bp` is what the §7 formatter tests, and it is the reason the formatter needs
no `constructor` sniffing: a `Map`, a `@Result`'s `{ ok }` and any host object
keep `console.log`'s own text. An enum's methods are statics of its class, so an
enum value has no `display()` of its own — a `Display` implementation is
consulted for records, which is where the language puts one.

## Model rules

- **`Expr` and `Stmt` are different types.** A statement cannot be built where
  an expression is required (no `return for (…)` by accident), and vice versa.
- **A rest element is a field of the pattern, not an element of its list**
  (`ObjectPattern.rest`, `ArrayPattern.rest`), so "a rest only at the end" is a
  property of the model, not a rule a build site has to remember.
- **An `if` carries an `Expr` condition**, so there is no empty condition to
  forget to fill in.
- **A `.d.ts` parameter carries a `TsType`**, never a string, so a parameter
  always has a type: `typescript.zig` builds it from the parameter's
  `TypeRef` (`any` where the source wrote none), never an empty string that
  renders as `x: `.
- **Layout is part of the model where the emitted bytes depend on it**
  (`Block.Layout`, `Array.Layout`, `Object.Layout`) — the same rule
  `beam/erl_ast.zig` follows for clause and case layout.

## Bridges (the known defects, pinned)

One form exists only because the current lowering still produces a shape the
model would otherwise forbid. It is the **complete** list of ways a JS
backend can emit something illegal; it has to be named explicitly at the
build site, so `rg '\.match = '`
finds every one. Fixing a defect means deleting its build site, not its node.

| Bridge | Renders | Defect |
|---|---|---|
| `Pattern.match` | botopink's own pattern spelling | **JS-4** a match pattern used as a JS binding target (`const Circle(r) = …`). **Unblocked by 01 R5:** `val Circle(r) = s;` now checks when the pattern cannot fail (a one-variant `type`, a record's constructor, a spread-only list) and every refutable one is `refutable-val-pattern` at check time — so the lowering is a plain destructure with no test; `val [a, b] = xs;` is refused, and `assert x is Some(n)` is still a parse error (`narrow_assert_pattern_with_print`). Once they type-check, a `ctor` / `list` destructuring lowers to a real test-plus-destructure and the eight `buildPattern` sites, `MatchPattern` and `writeMatchPattern` go |

## The IIFE build sites, classified

A `(() => { … })()` is how this backend gives a **statement sequence** a value.
`grep -cF '(() =>'` over `commonJS.zig` counts text, not build sites: it answers
**11**, of which seven are `@todo`/`@panic` host templates and four are doc
comments. The build sites are `Builder.iife` and
`b.call(b.paren(b.arrowBlock(&.{}, …)))`, and there are **ten**; each is named
here so a later row that removes one knows what it is removing:

| Site | What it wraps | Genuine? |
|---|---|---|
| `buildExpr` `.throw_` | `throw` in value position — unwinding crosses a function boundary | **yes** |
| `buildExpr` `__bp_future_rejected` | the same `throw`, as a rejected `@Future` | **yes** |
| `buildExpr` `.try_` | a nested `try` in expression position: bind, propagate the error, unwrap `ok` | **yes** |
| `buildExpr` `try … catch` | the same with a handler | **yes** |
| `buildExpr` `val assert … catch` | bind `_match`, test the pattern, run the handler (decision 8 §9) | **yes** |
| `buildIfExpr` | an `if` **used as a value** — decision 2 keeps `if` an expression | **yes** |
| `buildLoop` (collection) | a `loop` used as a value: the accumulator and its `for…of` | **yes** |
| `buildLoop` (condition) | the same for `loop (cond)`, including the `break <value>` form | **yes** |
| `buildCase` | a `case` used as a value: `const _s = …` and one statement per arm | **yes** |
| `@block { body }` | a **block as a value** — the one site whose producer decision 2 removes | **no** |

So the checker row that enforces decision 2 (a block is not a value) reaches
exactly **one** of them: the other nine give a value to a construct the language
keeps as an expression.

`Expr.host` is **not** a bridge: it carries the literal text of an
`#[@External.Node("…")]` annotation, which is host code by definition — the
same role `raw` plays in `beam/erl_ast.zig`.

## Layout quirks kept for byte-identity

`Block.Layout.fixed` writes one literal level of indentation and closes at
column 0 whatever the nesting — that is what arrow and `for…of` bodies have
always emitted (`}` at column 0 inside an indented function body). Its `indent`
field still carries the ambient level, because a statement that spans lines
(`Stmt.group`, the `try` lowering) indents its continuation lines from there.
`Block.Layout.indented` is the nesting-correct form used by function, method
and class bodies. The one-line layouts (`.spaced`, `.tight`) flatten a
`Stmt.group` into their own statement sequence, so a construct that lowers to
several statements (`_acc.push(v); continue;`) stays on the line.

## Rules

- No `print`/`writeAll` of target syntax outside these emitters.
- Tests are inline in each file and aggregated by `../tests.zig`.
