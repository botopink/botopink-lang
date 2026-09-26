# libs/validation/

> Path: `libs/validation/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

The bundled `validation` library (decision 116 rule 5): constraint markers,
`#[validated]`, the violation report, the constraint table and typed coercion.
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
│   ├── root.bp         pub mod report; table; messages; spi; constraints; binding; decorators
│   ├── report.bp       Violation, ValidationReport (isValid, merge, toJson, toProblemDetail, empty, of),
│   │                   violationJson, violation, noViolation, oneViolation
│   ├── table.bp        constraintTableJson and the blob grammar (splitBlob, paramNames, paramIsNumber,
│   │                   renderParam, constraintJson, fieldJson)
│   ├── messages.bp     Arg, arg, noArgs, MessageSource, setMessageSource, builtInOnly, messageSource,
│   │                   currentLocale, templateFor, interpolate, message, builtInTemplate, showI32/I64/F64
│   ├── spi.bp          Constraint, registerConstraint, constraintRegistered, registeredConstraints,
│   │                   clearConstraints, unknownConstraintMessage, vConstraint   (registry: templates)
│   ├── constraints.bp  the v* predicates (std `regex`, `io.clock`), emailPattern
│   ├── binding.bp      bindInt, bindBool, bindRequired, bindEpochMillis, bindingReport, bindingCount,
│   │                   bindingReset, bindingIsolated, isIntegerText, parseI32, parseI64   (accumulator: templates)
│   └── decorators.bp   #[validated] and the thirteen constraint markers
└── test/             binding · constraints · messages · parity · report · spi · table   (suite `validation:`)
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

## Consuming it

`#[validated]` emits `validate<TypeName>` and `constraintsOf<TypeName>` at the
application site, so the application imports the names the emission references
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

Tests import sibling modules by name (`from "report"`, `from "messages"`), as
any package's tests do. Every test that depends on message templates sets its
own source first (`setMessageSource(builtInOnly())` or a table source) — the
source is global host state and outlives a test. Every expected text is a
literal.

## Language notes (measured)

- A record field of fn type is callable directly (`src.locale()`) on both
  targets; `messages.bp` binds it to a local first only for readability.
- A decorator body cannot call a sibling function; the per-marker rules in
  `decorators.bp` are written out inline.
- A declared parameter default is not applied at a call site; every call passes
  every argument (hence `#[sizeBetween(min, max)]`).
- An integer literal does not widen to `i64` in arithmetic; `rawToI64` is the
  one host cell in the coercion path, reached only for text `isIntegerText`
  accepted.
