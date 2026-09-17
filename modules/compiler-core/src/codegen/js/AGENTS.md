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
| `js_ast.zig` | `Expr` (`lexeme_string`, `quoted`, `number`, `null_`, `ident`, `name`, `this`, `member`, `index`, `call`, `new_`, `binary`, `unary`, `ternary`, `assign`, `paren`, `arrow`, `function`, `array`, `object`, `host`, `await_`, `yield_`, `comment`), `Stmt` (`expr`, `decl`, `return_`, `throw_` (required operand), `continue_`, `break_`, `yield_delegate`, `if_`, `for_of`, `block`, `function`, `class`, `comment`, `group`), `Pattern` (`ident`, `name`, `object`, `array`, `match`), `Param`, `Block` (+ `Layout`), `Class`, `Comment`, `Item`; the `.d.ts` subset `TsType` / `TsField` / `TsParam` / `TsMember` / `TsDecl`; and `Builder` (arena: `ptr`, `stmtPtr`, `typePtr`, `call`, `member`, `binary`, `ternary`, `arrowBlock`, `iife`, `ifStmt`, `group`, …). |
| `js_emitter.zig` | **Names:** `ident(name)` — the ES reserved-word rename (`delete` → `delete_`); the only place it happens. A property position is never renamed. **Strings:** `writeLexemeString` — a botopink lexeme's escape pairs pass through (the lexer validated them and the escape set is JS-compatible), raw control bytes and unescaped quotes are escaped. **Code:** `writeExpr(w, expr, indent)`, `writeStmt(w, stmt, indent)`, `writeBlock`, `writePattern`, `writeComment`, `writeProgram(w, items)` (generated declarations separated by a blank line; runtime-support source verbatim). |
| `js_prelude.zig` | The commonJS runtime helpers for primitive methods whose native JS method disagrees with the signature, as built `Stmt.function` nodes — never a shipped file. `Helper` (`string_char_at`: `String.charAt -> ?string`, `null` out of range), `forMethod(receiver, method, argc)` (the declaration a helper answers), `name`, `decl`, `order`. `commonJS.zig`'s `Emitter.helper` returns the name **and** marks the helper, and only marked helpers are written into the module (the `wat/wat_prelude.zig` shape). |
| `ts_emitter.zig` | `writeType`, `writeDecl`, `writeProgram(w, decls)` — one declaration per typed binding, separated by a blank line, a binding with no surface (`.none`) still taking its separator. |

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
| `Pattern.match` | botopink's own pattern spelling | **JS-4** a match pattern used as a JS binding target (`const Circle(r) = …`) |

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
