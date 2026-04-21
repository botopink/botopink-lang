# core/src

## Files at this level

| File | Role |
|---|---|
| `root.zig` | Library entry point — exports the public API |
| `main.zig` | CLI stub (currently minimal) |
| `ast.zig` | All AST node types (`union(enum)` throughout) |
| `lexer.zig` | Lexer entry point — delegates to `lexer/token.zig` |
| `parser.zig` | Recursive-descent parser |
| `module.zig` | `Module` struct — input module representation |
| `comptime.zig` | Target-agnostic comptime compilation: `ComptimeSession`, `compile`, `evaluateComptime` |
| `format.zig` | Wadler-Lindig pretty-printer (`ast.Program → formatted source`) |
| `print.zig` | rustc-style error renderer (position + hint lines) |
| `codegen.zig` | Public codegen API — dispatches to target-specific backends, re-exports `ComptimeSession` from `comptime.zig` |

## Subdirectories

| Dir | Files |
|---|---|
| `lexer/` | `token.zig` (token definitions), `tests.zig` (snapshot tests) |
| `parser/` | `tests.zig` (parser snapshot tests) |
| `comptime/` | Type inference + comptime compilation: `types.zig`, `env.zig`, `infer.zig`, `unify.zig`, `error.zig`, `eval.zig`, `render.zig`, `snapshot.zig`, `tests.zig`, **`transform.zig`** (AST rewrite pass for specialization), **`specialize.zig`** (pure AST specialization), `runtime/` (Node.js + Erlang comptime runtimes) |
| `codegen/` | `config.zig` (configuration), `moduleOutput.zig` (output types), `commonJS.zig` (CommonJS backend), `erlang.zig` (Erlang backend), `typescript.zig` (TypeScript typedefs), `snapshot.zig` (snapshot helpers), `tests.zig` (codegen tests) |
| `format/` | `tests.zig` (formatter snapshot tests) |
| `utils/` | `snap.zig` (snapshot infrastructure), `pretty.zig` (JSON serialization), `json_diff.zig` (JSON diff output) |

## Pipeline

```
lex → parse → infer types → transform (Aggregator rewrites AST) → codegen (blind emitter) → target
```

### Phases

1. **lex/parse** — source → typed AST
2. **infer** — Hindley-Milner type inference
3. **transform** (`comptime/transform.zig`) — `Aggregator` scans for comptime calls, generates specialized `FnDecl` nodes, rewrites calls to mangled names, removes comptime args, inlines comptime values, removes fully-specialized original functions
4. **codegen** (`codegen/commonJS.zig` or `codegen/erlang.zig`) — blind emitter, only iterates `program.decls` and renders to target language

## Refactoring Guidelines

### Allocator Pattern

**Rule:** Never store `allocator` as a struct field. Always pass it as a parameter.

```zig
// ❌ WRONG
pub const Parser = struct {
    allocator: std.mem.Allocator,
};
pub fn init(tokens: []const Token, allocator: std.mem.Allocator) Parser { ... }

// ✅ CORRECT
pub const Parser = struct {
    // no allocator field
};
pub fn init(tokens: []const Token) Parser { ... }
pub fn parse(this: *This, alloc: std.mem.Allocator) ParseError!Program { ... }
```

**Parameter naming:** Always use `alloc: std.mem.Allocator` (not `allocator`).

**Exception:** Emitter structs (internal to codegen) may store `alloc` as a field, but it must always be passed in `init()`.

### Helper Functions

Create helpers to eliminate repetitive patterns:

- **`boxExpr(alloc, expr)`** — replaces `const ptr = try alloc.create(Expr); ptr.* = expr;`
- **`parseStmtListInBraces(alloc)`** — parses `{ stmt; stmt; }` blocks (single source of truth)
- **`parseCommaSeparatedIdentifiers(alloc, stopAt)`** — reusable for extends, imports, etc.
- **`reportReservedWordError()`** — centralized reserved word error creation
- **`emitBinaryOp(op, lhs, rhs)`** — replaces 6-line binary operator emission pattern

**Target:** Any pattern with 3+ similar occurrences should be considered for extraction.

## Recent Changes (v0.0.11-beta — April 2026)

### AST additions
| Node | Purpose |
|---|---|
| `ExprKind.pipeline` | `a |> b |> c` — left-associative pipeline chain |
| `ExprKind.fnExpr` | `fn(params) { body }` — anonymous function expression |
| `ExprKind.grouped` | `(expr)` — parenthesized expression (precedence) |
| `CaseArm.emptyLineBefore` | Preserves blank lines between case arms |
| `ArrayLit.trailingComma` | When true, forces multi-line array formatting |
| `Param.typeRef` | Full `TypeRef` replacing raw `typeName: []const u8` |

### Lexer additions
| Feature | Example | Implementation |
|---|---|---|
| Underscore digit separators | `1_000_000`, `0b1010_0011` | `scanNumber()` in `lexer.zig` |
| Scientific notation | `1.5e-10`, `2E+3` | `scanNumber()` exponent branch |
| Unary negation in parser | `-123`, `-1.0e5` | `parsePrimary()` detects `-` before number |

### Parser changes
| Change | Detail |
|---|---|
| `Parser.init(tokens)` | No longer stores allocator — always passed as parameter to parse methods |
| `Parser.initWithSource(tokens, source)` | No longer stores allocator |
| `boxExpr(alloc, expr)` | Helper: creates heap-allocated Expr pointer (replaces repetitive `alloc.create` pattern) |
| `parseStmtListInBraces(alloc)` | Helper: parses `{ stmt; stmt; }` blocks (replaces repetitive brace-block pattern) |
| `parseCommaSeparatedIdentifiers(alloc, stopAt)` | Helper: parses comma-separated identifier lists |
| `reportReservedWordError()` | Helper: reports reserved word error for current token |
| `parsePipelineExpr()` | New level in expression hierarchy between `parseOrExpr` and `parseAndExpr` |
| `parseCaseExpr()` | Supports multiple subjects (`case a, b, c`), detects `emptyLineBefore` |
| `parseParam()` | Uses `parseTypeRef()` instead of `consumeTypeName()` for full type support |
| `parsePrimary()` | Handles `fn(params) { body }` as `ExprKind.fnExpr`, unary `-` for negative numbers |

### Lexer changes
| Change | Detail |
|---|---|
| `Lexer.init(source)` | Never stored allocator — always passed as parameter to scan methods |
| `deinit(alloc)` | Allocator passed as parameter, not stored |
| `scanAll(alloc)` | Allocator passed as parameter |

### Codegen changes
| Change | Detail |
|---|---|
| All public functions | Renamed `allocator` parameter to `alloc` for consistency |
| `codegenEmit(alloc, outputs, config)` | Parameter renamed to `alloc` |
| `emitProgram(alloc, ...)` | Parameter renamed to `alloc` |
| `Emitter` structs (commonJS, erlang, typescript) | Field renamed from `alloc` to consistent naming, always passed in `init` |

### Formatter changes
| Feature | Behavior |
|---|---|
| Pipeline `|>` | Each `|>` on its own line with `hardline` |
| `fnExpr` | `fn(params) { stmt; }` with force-break |
| `grouped` | `(expr)` — simple parenthesized output |
| Case arms | Preserves `emptyLineBefore` as extra `hardline` |
| Case subjects | Multiple subjects joined with `, ` |
| Array literals | `trailingComma` → multi-line with `hardline`; no trailing comma → `group`/`softline` |
| Statements in body | `hardline` between each statement (was missing) |

### Codegen changes
| Target | Pipeline `|>` | `fnExpr` | `grouped` |
|---|---|---|---|
| CommonJS | `g(f(a))` nested calls | `(p) => { body }` | `(expr)` |
| Erlang | `G(F(A))` nested calls | `fun(P) -> body end` | `(expr)` |
| Node runtime | Nested `writeExprJs` | N/A | N/A |
| Erlang runtime | Nested `writeExprErl` | N/A | N/A |

### Type inference
| Addition | Detail |
|---|---|
| `.pipeline` | Returns `rhs.type_`; both sides inferred as typed expressions |
| `.fnExpr` | Returns fresh type variable; body inferred via `inferStmtsTyped` |
