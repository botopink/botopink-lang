# language-server/src

> Path: `modules/language-server/src/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../../AGENTS.md`](../../../AGENTS.md)

JSON-RPC server, protocol types, feature engine and test harness.

## Tree

```text
src/
├── AGENTS.md          ← you are here
├── main.zig           ← process entry — constructs and runs Server
├── server.zig         ← JSON-RPC message loop + LSP method dispatch
├── messages.zig       ← frame parser/writer (Content-Length protocol)
├── protocol.zig       ← LSP + JSON-RPC serializable types
├── engine.zig         ← LSP feature implementations
├── compiler.zig       ← thin wrapper around compiler-core (`LspCompiler`, `CompileResult`)
├── files.zig          ← in-memory cache for open document contents
├── feedback.zig       ← tracks active diagnostics → clears stale editor feedback
├── lsp_types.zig      ← position/offset, URI ↔ path helpers
├── project_index.zig  ← lazy project-wide pub symbol index (cross-module features)
├── project_graph.zig  ← per-project dependency graph (libs + mod siblings) for the project-graph compile
├── test_root.zig      ← test aggregator used by both build.zig files
└── tests/             ← feature-level tests — see tests/AGENTS.md
```

## Layered design

```text
main.zig
  └─ server.zig         ← JSON-RPC dispatch
        ├─ messages.zig ← transport
        ├─ protocol.zig ← types
        ├─ project_graph.zig / project_index.zig
        └─ engine.zig   ← feature impl
              ├─ compiler.zig
              ├─ files.zig
              ├─ feedback.zig
              └─ lsp_types.zig
```

Keep these boundaries strict:

- **Transport** (`messages.zig`) and **protocol** (`protocol.zig`) must not
  contain feature logic.
- **Feature logic** belongs in `engine.zig`; use `compiler.zig` to call into
  compiler-core's compile pipeline.
- Return a graceful null response when a request payload is unsupported or
  malformed — don't panic.

When adding a new LSP method: add the dispatch arm in `server.zig`, implement it
in `engine.zig`, add a test in [`tests/`](tests/AGENTS.md) (register it in
`test_root.zig`) and a snapshot under `../snapshots/lsp/`.

## Gotchas

- `protocol.zig`'s `SemanticTokenTypes` / `SemanticTokenModifiers` indices **are**
  the legend advertised to the client. Append only — never reorder, and extend
  the matching `legend` array in the same edit (`async`, bit 3, is the newest
  modifier: it marks effect fns).
- `engine.documentSymbols` returns owned names **and owned children**; free a
  result with `engine.freeSymbol` per symbol, never `gpa.free(sym.name)` alone,
  or every child leaks.
- **A section of an enum-shaped `type` is a type, not a member** (decision 8
  §5.3b): `type Token { Text { Bold, Italic } }` declares `Token.Text`, so
  `collectChildren` gives `Text` `SymbolKind.Enum` and recurses into its body
  instead of emitting one `EnumMember` whose contents the nested-block skip threw
  away. A member position is a PascalCase identifier **outside every `(…)` and
  right after the body's `{` or a `,`** — the same test the semantic-token walk
  makes. Without it a method's return type (`-> Color {`) was read as a section
  and a positional payload element as a variant.
- **Completion never answers `null` because the module failed to compile.**
  `Server.completionItems` (the testable half of `textDocument/completion`)
  completes against the module's typed bindings when it type-checks and against
  **none** when it does not; `engine.completion` then falls back to the token
  walk — locals from `collectLocalScope` plus the module's own declarations from
  `moduleDecls`. Answering `null` there left the editor with no completion for
  any file carrying a type error, or being typed (front 14 step 1).
- **Two word lists mirror the compiler and must not drift.** `isKeyword` is
  `keywordOrIdent` in `compiler-core/src/lexer.zig` (plus `true`/`false`, which
  the lexer reads as identifiers) — it decides what `prepareRename` refuses and
  what the import quick-fix skips, so a word that left the table must leave it
  here or a legal rename is refused. `isPrimitiveType` is
  `Env.registerBuiltins` in `comptime/env.zig` minus `Self` — it decides what
  semantic tokens paint `type [defaultLibrary]`, so a name that is registered
  nowhere must not be in it. `unknown` (decision 8 §2) became a keyword token with
  06 N19 — it is in `isKeyword` now, and the keyword branch of the semantic-token
  walk paints it `type [defaultLibrary]` like `Self`, so `isPrimitiveType` never
  sees it; `any` stays while the checker still registers it.
- **Completion hides what the cursor cannot see** (`cursorScope`): the binding
  whose own initialiser the cursor sits in (`val x = ▮` never offers `x`) and
  every `val`/`var` declared below it. A `fn` is not hidden — it may be called
  above the line that defines it.
- **Completion never offers a member the compiler rejects.** `appendDeclMembers`
  takes a `DotReceiver`: on the **type name** (`Color.`) an enum-shaped `type`
  offers its variants and its methods; on a **value** (`c.`) only its methods —
  `fn a(c: Color) -> Color { return c.Red; }` is
  `error: unknown field 'Red' on type 'Color'`, and a value receiver used to
  resolve to its named type and then reuse the type-name list unchanged.
- **`type` and `behavior` are the only keywords completion offers**, and only
  where a declaration may start (`atDeclarationStart`: outside every `(…)`/`[…]`,
  right after nothing, `;`, `{`, `}` or `pub`), sorted after the names in scope.
  They are the two words the surface cutover introduced; `record`, `enum` and
  `interface` have never been offered (the "keyword completion list" front 14
  located at `engine.zig:1847–1855` was `isKeyword`, the rename-refusal list).
  The rest of the table is deliberately not offered — a front that wants it takes
  the whole set at once.
- **A hover card is source the user could write back.** `renderBindingHover`
  renders a declaration in the 1.0.3 surface — `pub type Point(x: i32, y: i32)`
  (a record with no fields keeps no parentheses), `pub type Shape { Circle(...),
  Square }` (a section prints `Name { ... }`, decision 8 §5.3b) and
  `pub behavior Mappable<T>` — with the type parameters a written generic type
  always carries (decision 8 §1.1, `appendGenericParams`). `record`, `enum` and
  `interface` are parse errors; a card must never print one.
- **`renderType` writes a type the way the source writes it**, not the way the
  checker names it: `array<i32>` → `i32[]`, `optional<i32>` → `?i32`,
  `tuple<…>` → `#(i32, string)` and,
  with labels, `#(name: string, pop: i32)` (a label is a name for the compiler
  only — decision 8 §6 — but a written type keeps it). The structural-record
  shape prints `#(x: i32)` for the same reason: `record { … }` no longer parses.
  The `optional` arm is the one that was missing (front 11): `?T` is the only
  spelling the surface has for an optional (decision 2 — `Option<T>` is not one),
  and every consumer of `renderType` printed the checker's name instead — hover,
  the inlay hint, the `signatureHelp` parameter label, and the `Add type
  annotation` code action, which wrote `: optional<i32>` **into the user's file**
  one line under a declaration that spelled the same type `?i32`.
  What it cannot fix is a type **name** the checker built: a `type` declaration's
  constructor binding is *named* `record { name: string, count: i32 }` by
  `comptime/infer.zig`'s `buildRecordDeclName` (and `enum {` / `interface ` by
  its two siblings), and `renderType` prints a name verbatim. That is front 06's
  file — reported, not patched (`completion_decorator_record.snap.md` still shows it).
- The hover footer of a builtin method names the **declaring** behavior and the
  receiver's when they differ (`*from \`behavior Signed\` (via I32)*`):
  `InterfaceMember.owner` records which link of the `extends` chain declared the
  member.
- `semanticTokens` is a single token walk with a little state: `fn_params` /
  `fn_generics` (names in scope for the body being scanned, cleared when it
  closes), `generic_depth` (only a `<` right after a *declaration name* opens a
  type-parameter list — everywhere else `<` stays a comparison), and
  `pending_effect_fn` (set by `*` or a `#[@effect]` attribute before the `fn`).
