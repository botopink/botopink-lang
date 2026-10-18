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
├── str_slots.zig   ← decision 320's string reads hoisted per binding (the analysis)
└── ts_emitter.zig  ← the only writer of `.d.ts` text
```

## Files

| File | Role |
|---|---|
| `js_ast.zig` | `Class` carries `extends`, which only an enum's variant subclass uses. `Expr` (`lexeme_string`, `quoted`, `number`, `null_`, `ident`, `name`, `this`, `member`, `index`, `call`, `new_`, `binary`, `unary`, `ternary`, `assign`, `paren`, `arrow` (`is_async`: `async (p) => …`, decision 388 — `commonJS.zig` `buildArrow` sets it when the arrow's own body awaits, so a component's lambda running an asynchronous child is `async` and a synchronous one stays plain), `function`, `array`, `object`, `host`, `await_`, `yield_`, `comment`), `Stmt` (`syntax`, `decl`, `return_`, `throw_` (required operand), `continue_`, `continue_label`, `break_`, `yield_delegate`, `if_`, `for_of`, `while_` (+ an optional `label`), `block`, `function`, `class`, `comment`, `group`), `Pattern` (`ident`, `name`, `object` — a `Prop` binds a name or nests a pattern —, `array`), `Param` (`rest`: `...p`, decision 267's variadic), `Block` (+ `Layout`), `Class`, `Comment`, `Item`; the `.d.ts` subset `TsType` / `TsField` / `TsParam` (`rest`: `...name: T[]`) / `TsMember` / `TsDecl` / `TsNamespace` (types only — a non-instantiated namespace promises no value); and `Builder` (arena: `ptr`, `stmtPtr`, `typePtr`, `call`, `member`, `binary`, `ternary`, `arrowBlock`, `iife`, `ifStmt`, `group`, …). |
| `js_emitter.zig` | **Names:** `ident(name)` — the ES reserved-word rename (`delete` → `delete_`); the only place it happens. A property position is never renamed. A name holding a backtick identifier (decision 561, `` `not-found` ``) is no JS identifier: as a binding (`writeName` / `writeIdent`, every `.ident` / `.name`, a function, a class) each byte but a letter, a digit and `_` is written `$` and two hex digits (`$60not$2dfound$60` — only such a name holds a backtick and its `$` is escaped too, so it meets no other name); as a property (`writeKey`: an object literal's key, a pattern's, a method's, and a member read `p["`x pos`"]`) it is the string of its name, so `Object.keys` answers the botopink name and a printed record spells it as written. `commonJS.zig` `nameList` (the hidden `__bp_priv__` export and its test-unit destructuring) escapes through `writeName` too. A build site hands a botopink name as `.ident` (expression or pattern) and a final JS name as `.name`: a record's and a payload variant's constructor parameters, the assignment's right-hand side and a variant factory's arguments are the field names as `.ident` (`commonJS.zig` `buildRecord` / `buildEnum`), so `type Tag(class: string)` is `constructor(class_) { this.class = class_; }` — written `.name`, it was a `SyntaxError` before `main` ran (`conformance/modules/record_field_reserved_word`). **Strings:** `writeLexemeString` — a botopink lexeme's escape pairs pass through (the lexer validated them and the escape set is JS-compatible), raw control bytes and unescaped quotes are escaped. **Numbers:** a number literal as a member receiver is parenthesised — `(42).toString()`, because `42.` lexes as a float. **Code:** `writeExpr(w, expr, indent)`, `writeStmt(w, stmt, indent)`, `writeBlock`, `writeInline`/`writeInlineStmt`, `writePattern`, `writeComment`/`writeInlineComment`, `writeProgram(w, items)` (generated declarations separated by a blank line; runtime-support source verbatim). |
| `js_prelude.zig` | The commonJS runtime helpers for primitive methods whose native JS method disagrees with the signature, as built `Stmt.function` nodes — never a shipped file. `Helper` (`assert_fatal`: a non-test `assert` throws with message and `file:line`, marked `__bp_panic` with the message alone (std's `failure.attempt` reads it, § Aborts are marked); `string_char_at`: `String.at -> ?string` (the native method it wraps is `charAt`), a negative index counts from the end (decision 139), `null` out of range; `array_at`: `Array.at -> ?T`, native `xs.at(i) ?? null` — a negative index counts from the end (decision 139) and `null` stands for native `undefined` out of range (decision 47); `range_from`: an open-ended `a..` as the lazy generator `function* __bp_range_from(n)`; `structural_eq`: `__bp_eq(a, b, d)`, the run-time `==` for a pair whose static type this backend cannot name (a type parameter, a type another module declares, two different types) — arrays and tuples element-wise, a class instance by constructor plus own fields, two NaNs equal (decision 8 §6 T6, decisions 35, 210 and 214; § Structural equality); `show`: `__bp_show(v, shape, top, a)`, the text of one printed value under decision 8 §7 — a string, a `"f"`-shaped number as `5.0`, an array or tuple with spaces, a `__bp`-marked record or variant in the language's shape (a variant's tag read off its prototype, so a record's own field named `tag` prints as a field, not `Box.t(…)`), `Display` when the value has one, a `@Result` (the plain object `{ ok }` / `{ error }`) as `Ok(x)` / `Error(x)` with its payload shown nested (144 B-53), JavaScript's `undefined` as `null` (decision 47 — `?.` and an `if` with no `else` answer JavaScript's other none), `%O` otherwise; `f64_text`: `__bp_f64(v)`, the text of an `f64` — std-wasm's `number.shortFloat` ported (decision 521): OTP's `float_to_binary(F, [short])`, the shortest digits fixed or `D.DDDeE` whichever is shorter and `D.DDDeE` from 2^53 on (`5.0`, `1.0e3`, `1.0e21`, `1.0e-7`, `-0.0`, `9.007199254740992e15`), never the engine's number text; `show`'s `"f"` branch, a `string + f64` (so every template hole), and `toString()` on a float receiver (`forMethod(.float, …)`) share it (144 B-78); a value the backend's own reading cannot type `f64` (an imported record's field, a generic method's answer) is typed by the checker's `InstanceLowering.text_value` at the operand's loc plus `ast.text_synthetic_col` (`commonJS.zig` `textShape`), recorded for each `+` operand beside a `string` and each `@print` argument; a record or variant class whose declared fields hold a float carries their print shapes as `<Class>.prototype.__bp_s` (`commonJS.zig` `protoShapes`), which `show` hands each field; `str_trim` / `str_trim_start` / `str_trim_end`: `__bp_trim(s)` …, `String.trim` / `trimStart` / `trimEnd` over std-wasm's whitespace set (space, tab, LF, CR, VT, FF — a NBSP stays; decision 521); `str_upper` / `str_lower`: `__bp_upper(s)` / `__bp_lower(s)`, `String.toUpper` / `toLower` as std-wasm maps case (decisions 443, 521 — no final sigma), each holding std-wasm's table as text (`caseTable`: `text.mapCodepoint` over the code points below `case_limit`, base-36 runs `a,n,k,d` and full mappings `!a,x,y…`), decoded once by `case_map` (`__bp_case_map(t)`) and applied by `case_apply` (`__bp_case(s, m)`) — `declIn(arena, h)` builds the two whose table is written at emission, `decl(h)` the rest; the engine's `trim`, `toUpperCase` and `toLowerCase` are never called on a typed `string`; `text`: `__bp_text(v)`, `show`'s top-level format with its `%s` / `%O` verbs filled in — the string `@print` writes for `v`, an enum class's `toString`; `print` / `print_as`: `@print`'s `console.log` line over `show`, without / with the per-argument static shapes; `host_fail` / `host_result` / `host_result_task`: a `result: true` binding's call (decisions 431, 489, 490) — `__bp_host_result(F, f)` answers `{ ok: f() }` or, on a throw, `__bp_host_fail(F, e)`'s `{ error: new F.HostError(…) }` (an `Error` is `HostErrorName.Error` with its `message` and `stack`, any other value `Throw` with `String(e)`); `__bp_host_result_task(F, f)` is the failing task (`task`) of the same values from a Promise, its rejection included; `host_mark(f)` (decision 546) runs the call of a binding declared outside std without `result: true` and marks what it raises `__bp_host` (§ Aborts are marked); `F` is std's `failure` module; `task` / `await_task`: `__bp_task(p)` and `__bp_await(t)`, decision 432's failing task and its reading (§ Failing tasks); `yield_step`: `__bp_yield_step(r)`, a generator step `{ value, done }` as the prelude enum `YieldStep` — `.next()` by hand, decision 122 — whose class the module carries through the checker's splice; `int_check`: `__bp_int(v, lo, hi, what)`, decision 264's range check for `i8` … `u32` — `v + 0` inside `lo..hi`, else a throw (marked `__bp_panic`) of `integer overflow: <what>` (`integer division by zero: <what>` for a non-finite `v`, an integer `/` or `%` by zero), § Integer overflow in `../AGENTS.md`; `wide_norm` / `wide_add` / `wide_sub` / `wide_mul` / `wide_div` / `wide_mod` / `wide_neg`: the 64-bit operations, § 64-bit integers below; `str_surrogate` / `str_count` / `str_length` / `str_index_of` / `str_last_index_of` (and `string_char_at`): codepoint indices, § String indices below), `requires(h)` (the helpers `h`'s body calls, marked with it), `forMethod(receiver, method, argc)` (the declaration a helper answers), `name`, `decl`, `order`. `commonJS.zig`'s `Emitter.helper` returns the name **and** marks the helper, and only marked helpers are written into the module (the `wat/wat_prelude.zig` shape). |
| `str_slots.zig` | `analyze(gpa, ctx, params, body)` → `Slots` for one `fn` (`commonJS.zig` `buildFn`): the string reads (`length` / `len`, `at`, `indexOf`, `lastIndexOf`) whose receiver needs no per-read surrogate test, keyed by the receiver node's address — `.native` (a surrogate-free string literal, or a `val` bound to one: `literalSurrogateFree`) or `.slot` (`<name>$sp`) —, the `val`s whose slot is declared after them (keyed by the bound value node) and the parameters whose slot opens the body. `ctx` is the backend's `StrSlotCtx` (`plainVal`, `stringRead`). § String indices below. |
| `ts_emitter.zig` | A backtick identifier (decision 561) is spelled as the commonJS module carries it: a binding or a type by `js_emitter`'s escaped name, a member, a field and an enum member by the string of its name (`writeKey`); an exported declaration of such a name is declared under the escaped name and exported under the string (`export { $60f$60 as "`f`" };`, `writeDeclHead` / `writeExportAs`), and an import item reads it back (`import { "`f`" as $60f$60 }`, `writeImportItem`). `writeDecl`'s `namespace_` writes `export declare namespace Name { … }` over `TsNamespaceItem`s (`interface Name { … }`, a nested `namespace`), indented one level per depth and without `export`/`declare` inside — an ambient namespace exports its members (an enum's sections, `typescript.zig`). `writeType`, `writeDecl` (`import` writes each name as given — `a as b` included —, `import_namespace` writes `import * as name from "…"`), `writeProgram(w, decls)` — one declaration per typed binding, separated by a blank line, a binding with no surface (`.none`) still taking its separator. `TsMember.method` carries a `modifier` (as `field` does), which is how an enum's variant factories and methods are written `static`. A `class` / `interface` / `type_alias` / `namespace_` whose `exported` is false is written `declare …` without `export` (a module-private type a public signature names, `typescript.zig` `localTypes`), and `export_none` writes `export {};`, which keeps those from being exported implicitly. |

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

The base enum class also declares `toString() { return __bp_text(this); }`
(unless a behavior forwarder of that name is already a member): JavaScript
reads `toString` for a template hole and a `string +`, which wrote
`[object Object]`; `__bp_text` (`js_prelude.zig`'s `text`) is `__bp_show`'s
top-level text, so `"${c}"` is `Shape.Circle(radius: 2)` as `@print` writes it
(`conformance/modules/enum_value_template_hole`).

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
a float), two integer literals, or inference's `.division` naming an integer type for `/` (decision 264's checked operators answer `__bp_int`, which adds the `0` itself). Two
nonnegative literals (`2 * 3`) and a negated nonzero literal (`-1`) are left alone.
`+` and binary `-` cannot make `-0` from operands that are not. An integer this
backend cannot type (an untyped lambda parameter times a literal, a host function's
answer) is not wrapped. `conformance/modules/integer_never_negative_zero`. `conformance/modules/f64_equality_total_order` pins the zeros on
four targets; the NaN half is `tests/commonjs.zig`'s `f64 ---- NaN equals NaN under
==` RUN LOG, since erlang and beam never produce a NaN.

**A generic `T`** has one JavaScript body for every type, so a `==` between two
`T` values — `same<T>(a, b)`, `Array.unique`'s `prev != x`, `Dict`'s `p._0 == key`,
`Set.delete`'s `item != x` — is `__bp_eq(a, b, 0)`: `a === b` first (every
primitive answers there exactly as before), otherwise the constructor and the own
fields, so a record bound to `T` compares by value. `conformance/modules/record_structural_equality`.

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
| `buildIfExpr` | an `if` **used as a value** — decision 2 keeps `if` an expression; a branch that `await`s makes it `await (async () => { … })()` through `iife` (`AwaitScan`), because `await` does not parse in a plain arrow (`modules/task_await_in_if_block`) | **yes** |
| `buildGeneratorLoop` | `iter loop { … }` / `stream loop { … }` (and `iter for` / `iter while`, written as the prefixed `loop`) — a `function*` / `async function*` IIFE around `while (true)` invoked `.call(this)` (a generator cannot be an arrow, so the method's `this` (`self`) is handed in; `conformance/modules/loop_keeps_self`) (decisions 105, 125; every other loop is a statement) | **yes** |
| `buildCase` | a `case` used as a value: `const _s = …` and one statement per arm; an arm that `await`s makes it `await (async () => { … })()` (`AwaitScan`, `modules/task_await_in_case_arm`) | **yes** |

A block `{ … }` (decision 525; `@block` is removed) is a `case true { _ { … } }`
(`ast.CollectionExpr.case.isBlock`) here: `buildCase` / `caseStmtWithReturns`
lower it as any `case` — its arm's tail is its value (`buildCaseBody`, an
`if` / `try … catch` tail included unless it jumps out of the arrow), and its
`return` leaves the enclosing function through the case's `__bp_try` throw or
return box.

`Expr.host` is **not** a bridge: it carries the literal text of an
`#[@external(.JavaScript("…"))]` annotation, which is host code by definition — the
same role `raw` plays in `beam/erl_ast.zig`.

## What the prelude does not ship

**No `unwrapOrThrow`** (decision 432, which replaces 179): a botopink
`@Task<@Result<T, E>>` already rejects its Promise with `e` and resolves it
with the bare `T`, so a JavaScript caller writes `try { await t } catch (e)`
and no helper converts anything on its side; the `.d.ts` declares `Promise<T>`
under `/** @throws {E} */` (`typescript.zig` `taskError`).

## Failing tasks (decision 432)

| Site | Lowering |
|---|---|
| `fn f() -> @Task<@Result<T, E>>` (a top-level fn, a record's or an enum's method) | a plain `function` answering `__bp_task((async () => { …body… })())`: the body is built one level deeper, exactly as any `-> @Result` body (`{ ok }` / `{ error }` values, the `try` guards), and `__bp_task` turns its value into the task — resolved with `r.ok`, rejected with `r.error` (`failingTaskBody`) |
| `async { … }` whose value is a `@Result` its body builds (`InstanceLowering.failing_task_block`) | `__bp_task((async () => { … })())` — an arrow, never a `function`: the block keeps the method's `this` (`self`; `conformance/modules/async_block_keeps_self`) |
| `await t`, `t: @Task<X>` with `X` a `@Result`, `unknown` or a type parameter, or `t` not typed as a task (a record's function field) (`InstanceLowering.task_await`) | `await __bp_await(t)` — a task `__bp_task` marked reads back as `{ ok: v }` / `{ error: e }`; any other value as it is |
| `return t` of a whole `@Task<X>` wrapper, `X` as above (`InstanceLowering.task_return`) | `return __bp_await(t)` — the `async function` must not adopt the rejection |
| a `result: true` `-> @Task<@Result<…, HostError>>` host binding | `__bp_host_result_task`, a `__bp_task` over the converted Promise (a flagless binding's Promise is the host's, decision 490) |

`__bp_task` marks the task (`__bp_fails`), sets `__bp_failure` when it rejects with an `E` — a crash
(a panic, an unannounced host raise) rejects without it and stays a crash for botopink's `await` —
and attaches a handler of its own, so a failing task nobody has awaited yet is not an unhandled
rejection. A task a generic body made (`-> @Task<T>`, `T` a `@Result` at the call) is unmarked and
settles with the `@Result` value itself, which `__bp_await` leaves as it is: the mark, not the
static type, says which reading a task has. Host code that awaits botopink tasks generically
(std's `async.runAll`, `raceOf`, `race`) spells `__bp_await`'s reading inline. A lambda is never a
task body (it cannot `await`), so it returns the task it is handed.

## Aborts are marked (decisions 431, 492)

Every abort this backend raises carries a non-enumerable own property `__bp_panic`, so std's
`failure.attempt` / `attemptTask` tell a program's own abort (kind `panic`) from a host raise
(kind `host`) without wrapping any call: `@panic` / `@todo` (and so `x!`, which the checker
desugars to `@panic`) throw `Object.defineProperty(new Error(m), '__bp_panic', { value: true })`
(`registerInlineBuiltinDispatch`, the `@todo` / `@panic` fallback, `builtins_fns.d.bp`'s Node
templates — one text); `__bp_int`, `__bp_wnorm`, the 64-bit and `bigint` divisions mark their
throw the same way; `__bp_assert_fatal` marks it with the message alone (its `message` adds
` at <file:line>`), which `attempt` answers as the `Failure`'s message. A test body's
`__bp_assert` is told by its `__bp_assert_loc`. The property is not enumerable, so node prints an
uncaught abort exactly as before.

A raise of a host binding is marked `__bp_host` (decision 546, 527 (1)), on the bindings declared
outside std without `result: true` — a library's or the program's: `commonJS.zig` `collectExternals`
puts each in `marked_bindings` (`markable`: no `self` parameter, a `node` target, templates that render
over the parameters with no receiver hole and no `await` / `yield`), and `buildFnItem` emits it as a
function of its module, `function name(params) { return __bp_host_mark(() => <binding>); }`
(`buildResultBinding` with `mark`), called plainly like a `result: true` one, so its arguments are
evaluated outside the thunk and only the host's raise is marked; a host-backed method of a type
(`hostMethodMember`) does the same. `__bp_host_mark` leaves a botopink abort (`__bp_panic`,
`__bp_assert_loc`) and an already marked raise as they are, makes an `Error` of any other thrown
value, marks it, and marks the rejection of a Promise the host answers (not a botopink task). std's
own bindings are not marked (495 audits each), nor is a program's `emit`ted code: `std/failure`'s
Node forms and the abort guard (`otp.node_abort_source`) answer `host` for a marked raise and `crash`
for any other raise that is not a panic.

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

## 64-bit integers (decision 319)

`i64`, `isize`, `u64` and `usize` hold their full range here, as on erlang, beam
and wasm, in a **hybrid canonical form**: a value within ±(2^53 − 1) is a JS
`number`, one beyond it a `BigInt`, and never the other way round (`5` is never
`5n`). So `===` (and `==`, `__bp_eq`'s `Object.is`), `<`, a `Map` key and a
`Dict` / `Set` of std (`modules/i64_dict_key_across_safe_edge`) need no conversion,
and `i8` … `u32` stay plain numbers.

| Producer | What it writes |
|---|---|
| `+ - * / %`, unary `-`, `+=` on the four (`commonJS.zig` `wideOp`) | `__bp_w<op>(a, b, u, "<op> on <type> at <loc>")`: two numbers whose result is a safe integer (and not negative when `u`) answer it — the fast path, a `typeof` pair and `Number.isSafeInteger`; anything else is computed in `BigInt` and `__bp_wnorm` aborts past −2^63 … 2^63 − 1 / 0 … 2^64 − 1 and narrows a value back to a number when it fits |
| an integer literal past ±(2^53 − 1) (`numberLiteral`) | the `BigInt` literal, `9223372036854775807n` |
| `x is i64` (`wideIsTest`) | a safe-integer number (`>= 0` for the unsigned two), or a `BigInt` within the type's bounds |
| `@print`, string `+`, `toString()` | the digits: `__bp_show` writes a `BigInt` through `String(v)` (no `n`) |
| the `.d.ts` (`typescript.zig`) | `number \| bigint` (`(number \| bigint)[]` in an array) |

Cost: a tight `i64` loop below 2^53 (`acc = (acc + i * 3 - i % 7) % 1000003`,
2·10^8 iterations, best of three) ran 995 ms under the ±(2^53 − 1) `__bp_int`
build and 687 ms under the hybrid.

A primitive method of the numeric tower is patched on both prototypes —
`BigInt.prototype.m = Number.prototype.m = function…` (`commonJS.zig`
`prototypeAssign`) — so a `BigInt` receiver reaches std's `min`, `max`, `abs`,
`isEven`, `isOdd`, `clamp` and the conversions `toI32()` … `toF64()`; std's Node
forms take either kind and answer the canonical one (`libs/std/AGENTS.md`
§ Integers past 2^53, front `02/97` step 13).

## `bigint` (decision 332)

A `bigint` is always a JavaScript `BigInt` — never 319's hybrid: its literal is JavaScript's own
(`42n`, `numberLiteral` keeps the `n` the checker left on it), and an operator inference typed
`bigint` (`ArithKind.bigint`) is the native one: `+ - *`, unary `-` and `+=` as written (no range,
no `+ 0` canonicalisation — a `BigInt` mixes with no number, `NumKind.big`), `/` and `%` through
`__bp_bdiv` / `__bp_bmod` (`js_prelude` `big_div` / `big_mod`), which throw decision 264's
`integer division by zero: / on bigint at <file:line:col>` where `BigInt` would throw its own
`RangeError`. `===`, `<` and `__bp_show` read a `BigInt` natively. `bigint.of(n)` is `BigInt(n)` (an
`i64` in either form) and the methods are the prototype patches of std's `behavior BigInt`
(`isBoxedPrototype` unwraps `this`). The `.d.ts` spells it `bigint` (`typescript.zig` passes the name
through); `modules/bigint_across_modules` puts one through `scripts/tsc-check.sh`.

## `Bytes` (decision 346)

A `Bytes` is a `Uint8Array` (`jsPrototypeOwner("Bytes")`, a global namespace): `Bytes.fromUtf8(s)`
is `new TextEncoder().encode(s)`, `length()` the native property (inference's rename), and
`toUtf8`, `concat` and `slice` prototype patches of std's `behavior Bytes` — `slice` replaces
the native one, so its Node templates cut with `subarray` and copy. `==` is `__bp_eq`, which compares
two `Uint8Array`s index by index (same constructor, `Object.keys`). A `Bytes` build constant
(decisions 519, 520: `@embed`'s `Asset.bytes`, a `comptime`'s lifted `Bytes` — the AST's `bytesLit`)
is `new Uint8Array([…])` of its bytes.

## String indices count codepoints (decision 320)

`length`, `at`, `slice`, `indexOf`, `lastIndexOf` and `charCodeAt` count
codepoints, as on the three other targets. A string holding no UTF-16 surrogate
counts codepoints exactly as JavaScript counts units, so it keeps the native
index; one holding a surrogate is walked by codepoint (`Array.from`, `for…of`).
`length` (the property and the call), `at`, `indexOf` and `lastIndexOf` on a
typed string are `forMethod`'s helpers (`__bp_str_length`,
`__bp_string_char_at`, `__bp_str_index_of`, `__bp_str_last_index_of`); `slice`
and `charCodeAt` are std's own Node cells (`libs/std/src/primitives.bp`,
`stringSlice0` / `stringSlice1` / `charCodeAt`), which carry the same test
inline. A JS host template receives and answers codepoint indices.

The one test is `__bp_has_surrogate(s)`: `/[\uD800-\uDFFF]/.test(s)` costs a
call into the regexp engine (≈15 ns) whatever the string, so a cache answers a
string seen again — two ways per length (`s.length & 63`), each a pointer test
when the string is the same object (≈2 ns). Two ways keep two strings of one
length read in turn (`"alpha"`, `"delta"`) from evicting each other on every
read; a miss moves the first way to the second. The cache keeps at most 128
strings alive.

**A read tests its binding, not itself** (`str_slots.zig`). A string is
immutable, so the answer belongs to the binding. In a `fn`, a name bound
exactly once — a parameter or a `val` written as one `const` — and never
assigned gets a slot, `let <name>$sp = null;`, beside its declaration (first in
the body for a parameter; after the `const` for a `val`, so a `val` in a loop
body starts each round with an empty slot, and so does a parameter of a
self-tail-call loop). A read of it in scope is

```js
((s$sp ??= __bp_has_surrogate(s)) ? __bp_str_length(s) : s.length)
```

— one test per binding, the native read after it. A `val` bound to a string
literal with no surrogate (no four-byte UTF-8 sequence, no `\u` escape) and
such a literal read directly take the native read with no test at all
(`(s.at(1) ?? null)`, `"abc".length`). Everything else — a name with two
binders, a `var`, a `case` / loop / lambda binder (a pattern counts every name
it spells), a `try`-lowered `val`, an optional read, a body outside a `fn` —
keeps the helper call. The walks' switches have no `else`, so a new expression
kind does not compile until it is placed.

Cost, the benchmark (`commonJS`, best of three, `node` 25):

```botopink
fn reads(w: string) -> i32 {
    var n = w.length + w.indexOf("a") + w.lastIndexOf("a");
    if (w.at(1) == "l") {
        n = n + 1;
    }
    return n;
}

pub fn main() {
    val a = "alpha";
    val b = "bravo-x";
    val c = "charlie";
    val d = "delta";
    var acc = 0;
    var i = 0;
    while (i < 5000000) {
        acc = (acc + reads(a) + reads(b) + reads(c) + reads(d)) % 1000003;
        i = i + 1;
    }
    @print(acc);
}
```

— 2·10^7 calls of four reads; "native" is the same emitted module with each
helper call replaced by the bare JavaScript read. Before (one test per read,
one-way cache): native 590 ms, helpers 895 ms (+52 % — `"alpha"`/`"delta"` and
`"bravo-x"`/`"charlie"` share a length and evicted each other); with four
lengths that do not collide (`"bravos"`, `"deltaaaa"`) 583 → 662 ms (+14 %).
After: 631 ms (+7 %) and 625 ms (+7 %). Two further best-of-three rounds on a
loaded machine gave +7 % / +15 % and +9 % / +11 % — the margin left is the
one cache probe per call of `reads` (≈2 ns) plus the slot test per read.

## `defer` (decision 539)

`js_ast.Stmt.try_finally` (`TryFinally { body, finalizer }`, `try { … } finally { … }`) is the node a `defer` lowers to
(`js_emitter.zig`; the name scans in `commonJS.zig` open it like `try_catch`). `commonJS.zig`'s `buildStmts` meets a
deferred statement and lowers the REST of the block as the `try` body and the statement as the `finally`; `foldDefers`
does the same for the lists built one JS statement per statement (a lambda body, an `if` branch, a `case` arm's block,
a primitive-extension method body), and a deferred last statement is never the list's value. JS gives the rest for
free: `return f()` evaluates `f()` before `finally`, a `break` / `continue` across the `try` runs it, a
`-> @Result` `throw` / `try` is a `return` through it, an `async` body runs it after its awaits, a `for await` `break`
calls the iterator's `return()`.
