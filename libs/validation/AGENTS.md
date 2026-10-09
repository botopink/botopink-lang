# libs/validation/

> Path: `libs/validation/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

The bundled `validation` library (decision 116 rule 5): constraint markers,
`#[validated]`, the violation report, the constraint table, typed coercion, and
— since `specs/1.0.11-beta/07-bundled-libs/125-validation-zod` — `#[schema]`,
the decoder from a `Json` document to a typed record.
One source compiled for erlang and commonJS, so the server's handler and the
client's form run the same predicate. Moved from rakun front 14's validation
member (`repository/rakun/modules/rakun-validation`) by
`specs/1.0.10-beta/01-std/06-validation-lib`.

Imports `std` and nothing else. Ships `.bp` files only — no `.erl`, no `.mjs`;
target-native code is inline `#[@External.<Target>(…)]` templates (decision 117
rule 8). Module atoms follow decision 109: `validation@report`,
`validation@report@@ValidationReport`.

**Bundled.** `build.zig`'s `bundled_packages` names it: any program's
`from "validation"` loads the copy embedded in the compiler (as
`validation/<module>`), with no `dependencies` entry and never from this
directory; listing `validation` in `dependencies` is refused. A `#[validated]`
record in a consumer imports only `from "validation"` and `from "std"` and
answers the same report on erlang and commonJS (measured on a scratch
consumer). An edit here reaches a consumer only through a rebuilt compiler.

## Tree

```text
libs/validation/
├── botopink.json     "name": "validation", "target": "erlang", "targets": ["erlang", "commonJS"], no dependencies
├── AGENTS.md         ← you are here
├── src/
│   ├── root.bp         pub mod path; report; table; messages; schemas; spi; formats; constraints; binding; decorators
│   ├── path.bp         root, key, index, segments, head — the path a violation's `field` is
│   ├── report.bp       Violation, ValidationReport (isValid, merge, toJson, toProblemDetail, empty, of),
│   │                   violationJson, violation, noViolation, oneViolation
│   ├── table.bp        constraintTableJson and the blob grammar (splitBlob, paramNames, paramIsNumber,
│   │                   renderParam, constraintJson, fieldJson)
│   ├── messages.bp     Arg, arg, noArgs, MessageSource, setMessageSource, builtInOnly, messageSource,
│   │                   currentLocale, templateFor, interpolate, message, builtInTemplate, showI32/I64/F64
│   ├── schemas.bp      Schema<T> (parse, parseAt, decode, accepts, optional, array), of, text, int, long,
│   │                   float, boolean, anyJson; the decoders decodeString/Int/Long/Float/Bool/Json,
│   │                   optionalOf, decodeArrayOf; what `#[schema]` calls: memberPath,
│   │                   objectProblems, unknownKeys, violationsOf, under, decodeText; kindOf, isNull, shown
│   │                   (three conversion cells: wholeI32, wholeI64, isWhole)
│   ├── spi.bp          Constraint, registerConstraint, constraintRegistered, registeredConstraints,
│   │                   clearConstraints, unknownConstraintMessage, vConstraint   (registry: templates)
│   ├── formats.bp      the string formats as walks or intersection-grammar regexes: is<Format>(s) for every
│   │                   format marker, <name>Pattern() per regex format, urlParts, digitsValue (no host cell)
│   ├── constraints.bp  the v* predicates (std `regex`, `unicode`, `io.clock`, `formats.bp`), emailPattern
│   ├── binding.bp      bindInt, bindBool, bindRequired, bindEpochMillis, bindingReport, bindingCount,
│   │                   bindingReset, bindingIsolated, isIntegerText, parseI32   (accumulator: templates)
│   └── decorators.bp   #[validated], the 71 constraint markers (`markerNames()`), markerRule; #[schema]
└── test/             binding · checks_and_formats_example · constraints · messages · nested_and_arrays_example · parity · path ·
                      platform · refusal · report · schema · schema_parity · signup_schema_example ·
                      spi · table   (suite `validation:`)
```

`botopink.json`'s `files` order is a dependency order: a module is listed before
the siblings that import it.

## The message source

The library spells no property key. A framework hands it where templates come
from:

```bp
pub type MessageSource(locale: fn() -> string, template: fn(key: string) -> string)
pub fn setMessageSource(source: MessageSource) -> i32
pub fn builtInOnly() -> MessageSource      // in force until a source is set
```

`templateFor(code, builtIn)` asks `template(locale() + "." + code)` when the
locale is not `""`, then `template(code)`, then answers `builtIn`. A `""` from
the source means "no entry". rakun installs a source over its own property keys
at boot (rakun front 14 Step 7); onze installs the browser's in the entry it
generates (front 68).

## Host cells

`schemas.bp` has three host cells that hold no state — `wholeI32`, `wholeI64`
(an `f64` already known whole and in range, as the integer it is) and `isWhole`
— because the language has no `f64` → integer conversion. The decision of
whether a number fits is botopink; the cells convert.

Three pieces of host state, all inline templates:

| State | Erlang | Node |
|---|---|---|
| constraint registry (`spi.bp`, 7 cells) | one `persistent_term` entry `{validation, constraints}` = `{Order, Funs, Codes}` | `constraints` / `codes` Maps on `globalThis.__bp_validation` |
| binding accumulator (`binding.bp`, 5 cells) | the process dictionary, key `{validation, acc}` | `acc` array on `globalThis.__bp_validation` |
| message source (`messages.bp`, 2 cells) | `persistent_term` entry `{validation, messages}` | `messages` on `globalThis.__bp_validation` |

The node cell is created lazily by whichever template runs first, so **every
node template carries the identical init literal**
`{ constraints: new Map(), codes: new Map(), acc: [], messages: null }` — a
cell with a different literal leaves the object without the fields the others
read (measured: `__V.constraints.has is not a function`). Erlang template
variables are spelled `Va<Name>__` and every template is a `fun` applied in
place, so two inlined cells in one function never share a binding.

`bindingIsolated()` is MEASURED on erlang (spawn a process, push two
violations there, compare its count and this process's) and stated on node
(one request runs to completion before the next).

## The markers

`decorators.markerNames()` lists the 71 markers `#[validated]` reads, in file
order: the thirteen of step 2 and the 58 of front 125 step 3 — string checks
(`minLength`, `maxLength`, `length`, `startsWith`, `endsWith`, `includes`,
`uppercase`, `lowercase`), string formats (`emailHtml5` … `isoDuration`, rules
in `formats.bp`), numbers (`gt`, `lt`, `negative`, `negativeOrZero`,
`multipleOf`, `safeInt`, `float32`) and date bounds (`afterIso`, `beforeIso`).

- **Field types.** Every marker names the types it checks; on any other it is a
  located compile error (`test/refusal_test.bp`: one row per marker, and the
  count is `markerNames()`'s). The length markers read `string` (code points),
  `Array<T>`, `Dict<K, V>` and `Set<T>` (items); `gt` / `lt` / `negative*` /
  `multipleOf` one predicate per width (`I32`, `I64`, `F64`).
- **Optional fields.** A marker other than `#[notNull]` on `?string`, `?i32`,
  `?i64` or `?f64` checks the value when it is present and nothing when it is
  null (`if (v.f != null) …`); on any other optional type it is refused.
- **Numeric bounds.** The bound of `gt` / `lt` / `multipleOf` is the field's
  type: a fraction on an integer field is refused; on an `f64` field `5` is
  emitted as `5.0`, and the message shows the bound as written (a whole `f64`
  renders `2.0` on erlang and `2` on node). `minValue` / `maxValue` on `f64`
  take the same widening.
- **Messages.** A parameter is never named `value` (the field's value is
  `{value}` in every template): `gt` / `lt` say `{bound}`, `multipleOf`
  `{step}`.
- **Arguments.** Text arguments may not be empty nor carry `;`, `|` or `"`
  (the table's separators, the lexeme's delimiter); a bound that could never
  fail is refused (`#[minLength(0)]`, `#[multipleOf(0)]`); `afterIso` /
  `beforeIso` take RFC 3339 text with its zone; `#[isoDatetimePrecision]` needs
  one of `isoDatetime`, `isoDatetimeOffset`, `isoDatetimeLocal` beside it,
  which say the zones it takes.
- **Every marker parameter is `comptime`**, as decision 280 (0) writes it.

## `#[schema]` — a document in, a record out

`validate<TypeName>` checks a value that is already a record. `#[schema]` emits
the step before it, named after the type as `#[validated]`'s functions are:

```bp
pub fn parse<TypeName>At(input: Json, at: string) -> @Result<TypeName, ValidationReport>
pub fn parse<TypeName>(input: Json) -> @Result<TypeName, ValidationReport>
pub fn decode<TypeName>(text: string) -> @Result<TypeName, ValidationReport>
pub fn schemaOf<TypeName>() -> Schema<TypeName>
```

- **Fields it decodes:** `string`, `i32`, `i64`, `f64`, `bool`, `Json`, `?T`,
  `Array<T>` / `T[]` in any nesting, and another `#[schema]` record — the
  record itself included — reached by calling `parse<ThatType>At` by name. Any
  other field type is a located compile error naming the field and the type.
- **Every violation, at its path.** Each field is decoded, every violation is
  collected, and the record is constructed only when there are none.
  `Violation.field` is a path (`path.bp`): `ship.zip`, `lines[1].sku`, `` for
  the document itself. A flat record's path is its field's name.
- **Members are read with std's `Json` methods**: the emitted decoder reads
  `input.field("name") ?? Json.Null`; `schemas.bp` walks `input.items()` and
  `input.members()` and keeps no reader of its own.
- **Absent is one value.** A missing key and `null` decode the same: `null` for
  a `?T`, `required` for a `T`.
- **Numbers.** A JSON number is an `f64`. An `i32` field takes a whole number in
  range (`7.0` is whole, `1.5` and `2147483648` are `invalidType`); an `i64`
  field takes a whole number within ±(2^53 − 1).
- **An undeclared key is refused** (`unrecognizedKey`; decision 144), at its own path, after the declared fields.
- **The checks are `#[validated]`'s.** A type that carries constraint markers
  is also `#[validated]`; the emitted decoder calls `validate<TypeName>` on the
  record it built and re-roots the report under the record's path
  (`schemas.under`). A marker on a `#[schema]` type that is not `#[validated]`
  is a compile error.
- **Structural codes** (built-in templates in `messages.bp`): `invalidType`
  (`{expected}`, `{received}`), `required`, `unrecognizedKey` (`{key}`,
  `{type}`), `invalidJson` (`{reason}`); `invalidUnion`, `invalidValue`,
  `duplicate` and `custom` are declared for the steps that follow.

What the application has in scope — the emitted code names the library through
ONE namespace, and the types its signatures spell are leaves:

```bp
import {decorators.schema} from "validation";
import {schemas, schemas.Schema, report.ValidationReport, report.Violation} from "validation";
import {json.Json} from "std";
```

A wrapper level under a field (`Array<Array<i32>>`, `?Array<string>`) gets one
emitted function, `__decode<Record>_<field>_<depth>`, because a library decoder
cannot be passed as a value from emitted code (see *Language notes*).

`#[validated]` still emits bare names (`vNotBlank(…)`), so a type that carries
both imports the predicates too. Decision 145 moves `#[validated]` to the
namespaced form; that change edits rakun's import lines and lands with them.

## Consuming it

`#[validated]` reads each field's type from `f.typeName`, the type as the source
spells it: a list is `Array<…>` or `…[]`, a nullable field `?…`. It gives the
type the members `validate(self) -> ValidationReport` (`req.validate()`) and
`constraints() -> string` (`T.constraints()`) — `decl.addMember`, decision 216 —
declared at the application site, so the application imports the names the members reference
(decision 107 — the leaf is bound):

```bp
import {decorators.validated, decorators.notBlank, decorators.sizeBetween} from "validation";
import {report.ValidationReport, report.Violation} from "validation";
import {constraints.vNotBlank, constraints.vSizeBetween, table.constraintTableJson} from "validation";
```

Measured before bundling with a scratch consumer declaring the library as a
`{ "path": … }` dependency: green on erlang and commonJS. Import `validated`
from here, never rakun's placement-only `#[validated]`, and never both.

## Testing

```sh
../../zig-out/bin/botopink test --target erlang
../../zig-out/bin/botopink test --target commonJS
../../zig-out/bin/botopink format --check src test
```

`*_example_test.bp` are the front's `examples/` files as suite cases, byte for
byte but for the import lines (a module of this package cannot name it
`from "validation"` — the namespace is unbound in emitted code). A refusal is a
case of `refusal_test.bp`: it writes a one-file project under
`BOTOPINK_TEST_TMPDIR`, runs `botopink check` on it (`BOTOPINK_BIN`, else the
checkout's `zig-out/bin/botopink`) and asserts status, message and location.

Tests import the package's modules by their path inside the braces
(`import {report.Violation};`, decision 206), as any package's tests do. Every test that depends on message templates sets its
own source first (`setMessageSource(builtInOnly())` or a table source) — the
source is global host state and outlives a test. Every expected text is a
literal.

## Language notes (measured)

Re-measured on 2026-10-01 against this checkout's compiler, on erlang and
commonJS. What holds is a case of `test/platform_test.bp`; what is refused or
miscompiled cannot be a green test and is listed here with the form this
library writes instead.

**Holds on both targets** (`platform_test.bp`):

- A generic record carries a function field and a generic method
  (`Schema<T>`); a record field of fn type is called through a local
  (`val f = self.run; f(x)`).
- A union is a generic argument (`Holder<i32 | string>`) and `x is T` tells its
  arms apart at run time.
- A decorator body calls a bodied function of its own module, recursion
  included, and a decorator parameter's default is applied (`#[maker]` for
  `maker(decl, suffix: string = "X")`). The per-marker rules of `#[validated]`
  are written out inline for historical reasons, not because they must be.
- Emitted code names a module through its namespace (`constraints.vNotBlank(…)`).
- `json.decode` keeps member order, refuses a duplicate member and refuses
  `NaN`; a JSON number is an `f64`.
- An `f32` is written `1.5f` (a bare `1.5` is an `f64` and does not fit one)
  and is held as a double on both targets: `0.1f` reads back `0.1`, so the
  single-precision range is a marker's check, not a rounding.
- `std/url.parse` answers every input and normalizes nothing: it keeps the
  case WHATWG lowers, keeps a default port, reads `mailto:a@b.c` as one
  scheme, splits `[::1]:8080` at its first colon (host `[`) and answers
  `not a url`, `http://`, `http://a b.com/`, `http://a.com:abc/` where WHATWG
  refuses. A URL check splits the authority and checks scheme, host and port
  itself.

**Refused or miscompiled — and what is written instead:**

- `Ok(v)` / `Error(e)` are patterns, not constructors (`unbound variable 'Ok'`).
  A `@Result` comes out of a function through `return` and `throw`, so every
  decoder is a named function and a lambda only calls one.
- A `throw` inside a `case` arm does not become the function's `Error` — an
  uncaught throw on node, `nocatch` on erlang. Test first, `throw` from a
  top-level `if`.
- `val assert Ok(v) = r;` inside an `if` inside a `while` leaves `v` undefined
  on commonJS. Use a `case` as an expression:
  `out = case r { Ok(v) -> out.append([v]); Error(_) -> out; };`.
- A function named like a primitive type (`pub fn string()`) shadows the type
  in every annotation of its module; the mismatch is reported far from the
  cause ("expected string, got function"). Hence `schemas.text()`.
- A type cannot be named through a namespace (`report.ValidationReport` in an
  annotation is "unknown type"); the emitted signatures need the type imported
  as a leaf.
- A namespace member is resolved where it is called, not where it is passed:
  `schemas.of(schemas.decodeString)` is "unbound variable 'schemas'".
- In a module of THIS package — the tests — a namespace bound by the bare
  `import {schemas};` is not resolved inside a lambda of emitted code
  (`schemas is not defined` on node, `decodeString/3 undefined` on erlang). A
  consumer's `from "validation"` namespace is. `#[schema]` emits named
  functions instead of lambdas, which works in both.
- A method called on a lambda parameter whose type arrives through a generic
  (`box.map({ s -> s.length() })`) is emitted verbatim on commonJS
  (`s.length is not a function`). Pass a named function.
- **A string's `length()` is not one number**: `"😀".length()` is 2 on commonJS
  (UTF-16 units) and 1 on erlang (code points); `indexOf` counts bytes on
  erlang. `vSizeBetween` inherits it for text outside the BMP. The portable
  count is `unicode.codepoints(s).length`, which the length markers of the next
  step are written against.
- There is no `f64` → integer conversion in `std/math` (hence `schemas.bp`'s
  three conversion cells).
- A helper cannot take a `@Decl` (the call lowers to a run-time module that
  does not exist): every marker body calls `decl.fail` itself. Inside a
  decorator body an optional has no `unwrapOr` (`xs.slice(0, 1).join("")`
  instead), and a top-level `val` is not readable from a function a decorator
  calls (`formats.bp`'s character sets are functions).
- An `i64` beyond ±(2^53 − 1) cannot be built on commonJS (the arithmetic is
  refused as an overflow), so `#[safeInt]`'s refusal is reached on erlang only.
- An integer literal does not widen to `i64` in arithmetic; `wholeI64`
  (`schemas.bp`) is the host cell that produces one. `bindEpochMillis` reads its
  `i64` with std's `String.parseInt` over the trimmed text (front 97), so a
  numeral beyond ±(2^53 − 1) is a `typeMismatch` on both targets.
