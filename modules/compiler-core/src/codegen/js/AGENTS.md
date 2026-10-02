# compiler-core/src/codegen/js

> Path: `modules/compiler-core/src/codegen/js/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

The JavaScript / TypeScript code model and the emitters that render it.
Everything that writes JS or `.d.ts` text goes through here, so the commonJS
backend and the typedef backend share one set of lexical and layout rules.

The split is the same one the BEAM side uses (`../beam/`):

- **the backend builds a model** — it decides what shape a botopink construct
  becomes (a `for` becomes a `for…of`; a `try` becomes `"error" in _r`
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
| `js_ast.zig` | `Class` carries `extends`, which only an enum's variant subclass uses. `Expr` (`lexeme_string`, `quoted`, `number`, `null_`, `ident`, `name`, `this`, `member`, `index`, `call`, `new_`, `binary`, `unary`, `ternary`, `assign`, `paren`, `arrow`, `function`, `array`, `object`, `host`, `await_`, `yield_`, `comment`), `Stmt` (`expr`, `decl`, `return_`, `throw_` (required operand), `continue_`, `continue_label`, `break_`, `yield_delegate`, `if_`, `for_of`, `while_` (+ an optional `label`), `block`, `function`, `class`, `comment`, `group`), `Pattern` (`ident`, `name`, `object` — a `Prop` binds a name or nests a pattern —, `array`), `Param`, `Block` (+ `Layout`), `Class`, `Comment`, `Item`; the `.d.ts` subset `TsType` / `TsField` / `TsParam` / `TsMember` / `TsDecl` / `TsNamespace` (types only — a non-instantiated namespace promises no value); and `Builder` (arena: `ptr`, `stmtPtr`, `typePtr`, `call`, `member`, `binary`, `ternary`, `arrowBlock`, `iife`, `ifStmt`, `group`, …). |
| `js_emitter.zig` | **Names:** `ident(name)` — the ES reserved-word rename (`delete` → `delete_`); the only place it happens. A property position is never renamed. **Strings:** `writeLexemeString` — a botopink lexeme's escape pairs pass through (the lexer validated them and the escape set is JS-compatible), raw control bytes and unescaped quotes are escaped. **Numbers:** a number literal as a member receiver is parenthesised — `(42).toString()`, because `42.` lexes as a float. **Code:** `writeExpr(w, expr, indent)`, `writeStmt(w, stmt, indent)`, `writeBlock`, `writeInline`/`writeInlineStmt`, `writePattern`, `writeComment`/`writeInlineComment`, `writeProgram(w, items)` (generated declarations separated by a blank line; runtime-support source verbatim). |
| `js_prelude.zig` | The commonJS runtime helpers for primitive methods whose native JS method disagrees with the signature, as built `Stmt.function` nodes — never a shipped file. `Helper` (`assert_fatal`: a non-test `assert` throws with message and `file:line`; `string_char_at`: `String.at -> ?string` (the native method it wraps is `charAt`), a negative index counts from the end (decision 139), `null` out of range; `array_at`: `Array.at -> ?T`, native `xs.at(i) ?? null` — a negative index counts from the end (decision 139) and `null` stands for native `undefined` out of range (decision 47); `range_from`: an open-ended `a..` as the lazy generator `function* __bp_range_from(n)`; `structural_eq`: `__bp_eq(a, b, d)`, the run-time `==` for a pair whose static type this backend cannot name (a type parameter, a type another module declares, two different types) — arrays and tuples element-wise, a class instance by constructor plus own fields, two NaNs equal (decision 8 §6 T6, decisions 35, 210 and 214; § Structural equality); `show`: `__bp_show(v, shape, top, a)`, the text of one printed value under decision 8 §7 — a string, a `"f"`-shaped number as `5.0`, an array or tuple with spaces, a `__bp`-marked record or variant in the language's shape, `Display` when the value has one, JavaScript's `undefined` as `null` (decision 47 — `?.` and an `if` with no `else` answer JavaScript's other none), `%O` otherwise; `print` / `print_as`: `@print`'s `console.log` line over `show`, without / with the per-argument static shapes; `yield_step`: `__bp_yield_step(r)`, a generator step `{ value, done }` as the prelude enum `YieldStep` — `.next()` by hand, decision 122 — whose class the module carries through the checker's splice), `forMethod(receiver, method, argc)` (the declaration a helper answers), `name`, `decl`, `order`. `commonJS.zig`'s `Emitter.helper` returns the name **and** marks the helper, and only marked helpers are written into the module (the `wat/wat_prelude.zig` shape). |
| `ts_emitter.zig` | `writeDecl`'s `namespace_` writes `export declare namespace Name { … }` over `TsNamespaceItem`s (`interface Name { … }`, a nested `namespace`), indented one level per depth and without `export`/`declare` inside — an ambient namespace exports its members (an enum's sections, `typescript.zig`). `writeType`, `writeDecl` (`import` writes each name as given — `a as b` included —, `import_namespace` writes `import * as name from "…"`), `writeProgram(w, decls)` — one declaration per typed binding, separated by a blank line, a binding with no surface (`.none`) still taking its separator. `TsMember.method` carries a `modifier` (as `field` does), which is how an enum's variant factories and methods are written `static`. A `class` / `interface` / `type_alias` / `namespace_` whose `exported` is false is written `declare …` without `export` (a module-private type a public signature names, `typescript.zig` `localTypes`), and `export_none` writes `export {};`, which keeps those from being exported implicitly. |

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
`fn each(self: Self) -> @Iterator<i32>` that yields the `*each()` a `for…of` can consume.

`__bp` is what the §7 formatter tests, and it is the reason the formatter needs
no `constructor` sniffing: a `Map`, a `@Result`'s `{ ok }` and any host object
keep `console.log`'s own text. An enum's methods are statics of its class, so an
enum value has no `display()` of its own — a `Display` implementation is
consulted for records, which is where the language puts one.

## Structural equality (decision 210)

`==` compares by value: two values are equal when they have the same type and
their fields are equal, field by field and recursively; `!=` is the negation, and
`==` never calls user code — a method named `equals` has no role (decision 211).
`commonJS.zig`'s `buildEquality` lowers each `==` / `!=` by its operands' static
type, which this backend reads from the untyped tree itself (`staticTypeOf`: a
literal, a parameter's or `val`'s written type or its value's, a record or variant
constructor, a field of a record declared here, a tuple / array literal, a
top-level fn's declared return, a primitive method's declared primitive return, an
operator; `eq_types` holds a name's type — cleared by each parameter list, shadowed
by an arrow's parameters, restored after the arrow):

| Operands | Lowering |
|---|---|
| either side a float (`f64`, `f32`, or `?` of one) | `Object.is(a, b)` / `!Object.is(a, b)` — decision 214's total order |
| either side another primitive (`i32`, `bool`, `string`, … or `?` of one), or a `null` literal | today's `===` / `!==` (loose `==` / `!=` against `null`) — unchanged, byte for byte |
| both one composite type this module declares or spells — a record, an enum, a tuple, an array, `?` of one | `__bp_eq_<T>(a, b)` |
| anything else — two different types, a type parameter `T`, a type declared in another module, `unknown`, a type nothing here recovers | `__bp_eq(a, b, 0)`, the run-time walk (constructor, then own fields) |

`__bp_eq_<T>` is generated the first time the module compares a `T` and only then
(`eq_fns`, written after the prelude helpers), named by prefix notation with each
constructor's arity so two types never share one (`Person`, `Array_Person`,
`Tuple2_i32_string`, `Opt_Team`; a part with no equality here is `Any`). Its first
statement is `if (a === b) return true;`, then the fields in order joined by `&&`,
so the first difference ends it:

```js
function __bp_eq_Team(a, b) {
    if (a === b) return true;
    return __bp_eq_Person(a.lead, b.lead) && a.size === b.size;
}
function __bp_eq_Shape(a, b) {
    if (a === b) return true;
    if (a.tag !== b.tag) return false;
    if (a.tag === "Circle") return a.r === b.r;
    if (a.tag === "Rect") return a.w === b.w && a.h === b.h;
    return true;
}
function __bp_eq_Array_Person(a, b) {
    if (a === b) return true;
    return a.length === b.length && a.every((e, i) => __bp_eq_Person(e, b[i]));
}
```

A field is compared by its declared type the same way: a float by `Object.is`, any
other primitive by `===`, a composite by its own
`__bp_eq_<T>`, a field written as one of the type's own parameters by `__bp_eq`. A
`?T` is equal when both are absent (`== null`, so JavaScript's `undefined` is none
too, decision 47) or both present and equal. No hash is computed at construction,
nothing is interned, and there is no global table.

**A float under `==` is a total order** (decision 214, Java's `Double.compare` and
Kotlin's data class): `0.0 == -0.0` is `false` and `NaN == NaN` is `true`, which is
`Object.is` exactly, bare and as a part alike; `<`, `>`, `<=`, `>=` keep IEEE.
Only an operand `staticTypeOf` reads as a float takes it; an integer stays `===`.
The run-time `__bp_eq`'s first test is `Object.is(a, b)` too, so a generic `T`
bound to an `f64`, and a float part of a type another module declares, follow the
same order — which is safe for a number of unknown type only because **an integer
is never `-0`** here (below).

**An integer is never `-0`** (decision 214's premise; erlang, beam and wasm have no
such value). JavaScript's `*`, `%`, unary `-` and the truncated integer `/` answer
`-0` for `0 * -1`, `-x` with `x = 0`, `-4 % 2` and `0 / -3`, and commonJS printed
`-0` for each. `intCanon` wraps those four forms as `(e + 0)` — `-0 + 0` is `0` and
every other number stays exactly itself, where `| 0` would wrap past 32 bits — when
`numKind` reads them as integer arithmetic: an operand typed as an integer (and none
a float), two integer literals, or inference's `.division == .integer` for `/`. Two
nonnegative literals (`2 * 3`) and a negated nonzero literal (`-1`) are left alone.
`+` and binary `-` cannot make `-0` from operands that are not. An integer this
backend cannot type (an untyped lambda parameter times a literal, a host function's
answer) is not wrapped. `tests/language/run/integer_never_negative_zero.bp`. `tests/language/run/f64_equality_total_order.bp` pins the zeros on
four targets; the NaN half is `tests/commonjs.zig`'s `f64 ---- NaN equals NaN under
==` RUN LOG, since erlang and beam never produce a NaN.

**A generic `T`** has one JavaScript body for every type, so a `==` between two
`T` values — `same<T>(a, b)`, `Array.unique`'s `prev != x`, `Dict`'s `p._0 == key`,
`Set.delete`'s `item != x` — is `__bp_eq(a, b, 0)`: `a === b` first (every
primitive answers there exactly as before), otherwise the constructor and the own
fields, so a record bound to `T` compares by value. `tests/language/run/record_structural_equality.bp`.

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

## Bridges

There are none left. The last one, `Pattern.match` (**JS-4** — botopink's own
pattern spelling written as a JS binding target, `const Circle(r) = s;`, a
SyntaxError), was deleted with `MatchPattern` and `writeMatchPattern` once 01 R5
made `val Circle(r) = s;` check. The checker accepts the bare form only where
the pattern cannot fail — a record's own constructor, the variant of a
one-variant `type`, a spread-only list — and refuses every refutable one as
`refutable-val-pattern`, so `buildPattern` builds a plain destructure with no
test: each binding read off the declared field at its position
(`const { radius: r } = s;`), a nested constructor as a nested object pattern
(`ObjectPattern.Prop.nested`), a list off its index. The arms a refutable
pattern would need (a literal, an alternation) are unreachable and bind `_`.
A new bridge is added here, named at its build site, or not at all.

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
| `buildIfExpr` | an `if` **used as a value** — decision 2 keeps `if` an expression; a branch that `await`s makes it `await (async function() { … })()` through `iife` (`AwaitScan`), because `await` does not parse in a plain arrow (`run/task_await_in_if_block`) | **yes** |
| `buildGeneratorLoop` | `iter loop { … }` / `stream loop { … }` (and `iter for` / `iter while`, written as the prefixed `loop`) — a `function*` / `async function*` IIFE around `while (true)` (decisions 105, 125; every other loop is a statement) | **yes** |
| `buildCase` | a `case` used as a value: `const _s = …` and one statement per arm | **yes** |
| `@block { body }` | a **block as a value** — the one site whose producer decision 2 removes | **yes, for its `return` form**; the tail form is the checker's to refuse |

So the checker row that enforces decision 2 (a block is not a value) reaches
exactly **one** of them: the other nine give a value to a construct the language
keeps as an expression.

**The `@block` site still has producers** (measured for 1.0.11-beta
`01-compiler/04-js` step 1, which was to delete it). One fixture writes it —
`js: block ---- @block builtin` (`tests/values.zig`, both runtimes' commonJS
snapshot `block_block_builtin`), `val status = @block { …; if (c) return "Alto";
return "Baixo"; }` — and no `.bp` in the checkout does. Three shapes check today:

| Program | commonJS answers | What it is |
|---|---|---|
| `val a = @block { return 3; }` | `3` | every path returns (C1: the `return`s are the block's) — a value, like a `case` whose arms all return |
| `@block { val x = 3; @print(x); };` | `3` | statement position — the IIFE scopes the block's `return`s, which a JS block would hand to the enclosing function |
| `val a = @block { 1 + 2 };` | `null` | the tail form: `inferBuiltinCallReturnType` types the block by its last expression, decision 2 says a block is not a value |

The first two keep the IIFE genuine; only the third is the dead lowering, and
its producer is the checker's (`comptime/infer.zig`, the `"block"` arm of
`inferBuiltinCallReturnType`), which still accepts it. The site stays until
that refusal lands; then the tail form has no producer and nothing here moves.

`Expr.host` is **not** a bridge: it carries the literal text of an
`#[@External.Node("…")]` annotation, which is host code by definition — the
same role `raw` plays in `beam/erl_ast.zig`.

## What the prelude does not ship

**No `unwrapOrThrow`** (1.0.11-beta decision 179, the answer to 24-h): a
botopink `@Task<@Result<T, E>>` resolves its Promise with the tagged value —
`{ ok: v }` or `{ error: e }` — and never rejects (decision 120), and a
JavaScript caller that `await`s it reads that value. No prelude helper turns an
`{ error }` back into a rejection: a Task that never fails is the one contract,
and a helper that rejected would be a second one for a single target.

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
