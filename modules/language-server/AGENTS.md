# language-server

> Path: `modules/language-server/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../AGENTS.md`](../../AGENTS.md)
> Docs: [`./docs.md`](docs.md)

Package that builds the `botopink-lsp` executable. Wraps `compiler-core` and
implements the JSON-RPC / LSP protocol.

## Tree

```text
language-server/
├── AGENTS.md          ← you are here
├── docs.md            ← feature inventory, transport, dev loop
├── build.zig          ← build graph (`run`, `test`)
├── build.zig.zon      ← deps (compiler-core)
├── src/               ← server + protocol + features + tests
│   ├── AGENTS.md
│   ├── docs.md
│   ├── project_index.zig ← project-level pub symbol index (workspace scan)
│   └── project_graph.zig ← per-project dependency graph (libs + mod siblings)
└── snapshots/
    └── lsp/           ← LSP feature snapshots
        └── AGENTS.md
```

## Commands (run from this directory)

```bash
zig build               # produce ./zig-out/bin/botopink-lsp
zig build run           # launch over stdio
zig build test          # run LSP feature tests + snapshots
```

## Feature scope

The server currently handles `initialize` / `shutdown` plus these
`textDocument/*` methods:

- `publishDiagnostics` (with `$/progress`), `formatting`,
  `hover` (full signature + doc comments, incl. qualified `std` members and
  builtin interface methods on primitives/arrays/strings),
  `definition` (same-file, cross-module, embedded `std` modules, plus type-aware
  member access — record fields/methods, builtin methods into `primitives.d.bp`,
  `self.field`, `Name(field:)` labels, and `mod` refs to their backing file),
  `typeDefinition`,
  `documentSymbol` (hierarchical, incl. `test "name"` blocks as `Method`),
  `completion` (prefix + dot-trigger + `list.`/`io.` std members + builtin
  interface methods on primitive/array/string receivers + labeled args +
  sortText + module names),
  `references` (cross-module with exact positions), `rename` (cross-module multi-file, with `prepareRename`, rejects keywords),
  `signatureHelp` (incl. builtin interface methods, `self` dropped),
  `inlayHint` (inferred `val` types, call-site parameter names, lambda parameter types; `workspace/inlayHint/refresh` on edits),
  `semanticTokens` (`full` + `range`; token-driven legend distinguishing builtin `@Type`s, interface/struct methods vs free fns, `*fn` effect marker, comptime params, enum members; **plus a sub-language overlay inside string literals — see below**),
  `codeAction` (add type annotation, remove unused import, add missing case patterns, add missing import),
  `foldingRange` (incl. `test` blocks).

The server maintains a **project index** (`src/project_index.zig`) that scans
`.bp` files from the workspace `rootUri`, caching `pub` symbols for cross-module
features (import suggestions, references, module completion).

### Project-graph compile (lsp-project-awareness)

Every handler compiles the active document **together with its module graph**,
not alone (`Server.compileWithGraph` → `buildModuleEntries`). `src/project_graph.zig`
resolves the dependency set with the same rules the CLI driver uses:

- `from "<lib>"` → the lib's own `botopink.json` (`src` + `files`), read from the
  first entry of the resolved **root list** (`resolveRoots`: bundled
  `repository/botopink-lang/libs`, sibling `repository/`, or legacy flat `libs/`,
  de-duped nearest-first) that carries `<lib>`. On the flat tree the list is
  `[<ancestor>/libs]`, byte-identical to the former single-root walk. `.d.bp`
  declaration files are kept for go-to-def but excluded from the compile (the CLI
  drops them too).
- `mod` / `pub mod` siblings → every `.bp` under the project's `src/`.
- `from "std"` → embedded, expanded inside the compiler.

The active document stays the hot in-memory copy (appended **last** so it can
import from every dep); open buffers overlay their dependency on disk; closed
files are read from disk. The resolved deps are **cached per project root**
(`ProjectGraph`), so a keystroke reuses them (cache hit) instead of re-walking
the tree — `invalidateAll` runs on `didOpen`/`didClose` (save/watch), never on a
keystroke. No `botopink.json` walking up from the file ⇒ single-document
fallback (the old behavior, so isolated buffers and tests still work). The
compiler core still names no lib: the resolver feeds it ordinary `(uri, source)`
pairs and `resolveImports` binds `from "<lib>"` generically by symbol name.

`definition` resolves in tiers: **typed member/`mod` path** (`needsTypedDefinition`
→ `definitionMember`, see below) → same file → **project graph** (`from "<lib>"`
surface, incl. member access like `Response.created`, the source of truth from
`botopink.json`) → workspace `pub` symbols (project index) → embedded "std"
package modules (`engine.definitionInStdModules`). Std hits are materialized to
`<XDG_CACHE_HOME|~/.cache>/botopink-lsp/std/<name>.bp` so the editor can open
them (needs `environ_map` from `std.process.Init`, plumbed through `Server.init`).

**Type-aware member / module go-to-def (lsp-definition-completeness)** —
`findDeclLocation`'s keyword scan is blind to anything that is *part of a type*: a
record field has no declaration keyword, a method jump landed on the first
same-named `fn` (receiver-blind), builtin methods have no `fn` in the file, and a
`mod` name's "declaration" *is* a sibling file. `engine.definitionMember`
(gated by the cheap `needsTypedDefinition` so the plain name scan stays
compile-free) covers these by reusing the receiver-type machinery completion/hover
already have:
- **`recv.field` / `recv.method`** — `receiverChain` parses the dotted receiver,
  `resolveChainType` walks it to a named type (a value binding's inferred type, an
  integer/bool literal, or `self` → the lexically `enclosingTypeName`), narrowing
  through record fields (`stepField`). The member is then located by token-scanning
  that type's `{…}` body (`findMemberInTokens`) — type-aware, so a same-named method
  on another record no longer wins.
- **Builtin receivers** (`xs.reverse()`, `s.split(…)`) route through
  `builtinInterfaceForType` to the embedded `primitives.d.bp` and return a
  `TypedDefinition.builtin` (source + range) the server materializes like a std hit.
- **`Name(field: …)` labels** — `ctorCalleeBefore` finds the constructor callee and
  jumps to the field decl.
- **Cross-module fields** (`findMemberDeclAcross`) search the `others` graph deps,
  requiring the owning type be `pub`.
- **`mod` / `pub mod <name>;`** — `modRefNameAt` + `findModuleFile` map the name to
  the backing dep file (`<name>.bp` / `<name>/mod.bp`) and jump to its top.

### Local-scope binding model (lsp-project-awareness)

The typed `bindings` slice is module-level only — it never holds function
parameters, `comptime` params, `val`/`var` locals, or closure binders
(`{ f -> … }`). `engine.collectLocalScope` reconstructs the bindings visible at
the cursor with a **pure token walk** (no typed body needed, so it survives a
type error — completion degrades, not vanishes). `engine.completion` merges
these ahead of the module bindings (inner scope shadows outer, `Variable` kind);
`engine.definition`/`definitionInModules` try `localDefinition` first so a nearer
param/local/binder wins over a same-named top-level decl. `findDeclLocation`
includes `var` in its keyword set so `var`-locals resolve at all.

**Builtin interface methods** — `completion`/`hover`/`signatureHelp` on a
primitive/array/string receiver (`n.abs()`, `true.to_string()`, `xs.map(…)`,
`"s".len()`) resolve against the embedded interface declarations exposed by
`comptime_pipeline.{primitive_interfaces_src,array_interface_src,string_interface_src}`
(the `.d.bp` sources). The receiver's inferred type name (`i32`→`I32`,
`bool`→`Bool`, `array`→`Array`, `string`→`String`) selects the interface;
integer literals default to `I32`, `true`/`false` to `Bool`. `signatureHelp`
drops the leading `self`. Note: an integer *literal* receiver (`42.`) only
surfaces through the text-based engine path — a buffer containing `42.method()`
does not compile (the lexer reads `42.` as a float), so the editor reaches this
via a variable (`val n = 42; n.`).

**Sub-languages (`@ExprCustom`)** — an embedded query/markup literal like
`erika "select name from users"` or `html """…"""` lights up *from the
compiler*, not a hand-written SQL/HTML grammar. A template lib returns
`@ExprCustom<T> { code, ast }`; the `ast` is a generic `CustomNode` tree
(`{ kind, span, label, ref?, children }`) the lib built at comptime. The LSP
knows only `CustomNode` — it never branches on any sub-language:

- **Expansion** — `LspCompiler` runs with an opt-in template-eval context
  (`compileTypesOnly(…, eval_ctx)`), so `@ExprCustom` template bodies actually
  execute via `node` and surface their trees on `OkData.custom_ast`. The scratch
  root is `<XDG_CACHE_HOME|~/.cache>/botopink-lsp/template` (or `.botopinkbuild/lsp`).
  Spawning `node` per compile is the documented latency cost; tooling that must
  not touch the runtime passes `eval_ctx = null`. Because the compile now runs
  over the **project graph**, a template fn reached via `from "<lib>"` (a
  cross-module `erika "…"`) resolves and expands too — `customAstFor` is no
  longer empty on real app files.
- **Semantic tokens (F1)** — `engine.customSemanticTokens` maps each node's
  `label` (`keyword`/`property`/`string`/`number`/`operator` → legend indices
  11–13 appended in `protocol.zig`) and `span` (a byte offset into the literal)
  to an absolute range, then `mergeSemanticTokens` re-sorts them into the lexer
  stream. Unknown labels stay the opaque `string` token; a plain string is
  untouched.
- **Diagnostics (F2)** — a template's `q.failAt(span, msg)` maps through
  `template.failDiagnostic` to a `typeError` located **inside** the literal, so
  it surfaces as an ordinary diagnostic squiggle on the offending token.
- **Hover / go-to-definition (F3)** — a node may carry `ref` (a `q.lookup`
  result tying it to a caller-scope symbol). `engine.customRefNameAt` finds the
  deepest covering node under the cursor and resolves `ref.name` against the
  normal symbol table — `hoverCustomRef` renders the bound symbol's card,
  `definitionCustomRef` jumps to its declaration. Go-to-def is gated on
  `cursorInString` so the common path skips the extra compile.

The whole path is generic: any lib returning `@ExprCustom` lights up for free.
See [`src/tests/sublanguage.zig`](src/tests/sublanguage.zig).

Add a new feature → implement it in [`src/engine.zig`](src/AGENTS.md), add a
test under [`src/tests/`](src/tests/AGENTS.md) and a snapshot under
[`snapshots/lsp/`](snapshots/lsp/AGENTS.md).
