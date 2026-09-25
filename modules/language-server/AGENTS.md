# language-server

> Path: `modules/language-server/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../AGENTS.md`](../../AGENTS.md)

Package that builds the `botopink-lsp` executable. Wraps `compiler-core` and
implements the JSON-RPC / LSP protocol.

## Tree

```text
language-server/
├── AGENTS.md          ← you are here
├── src/               ← server + protocol + features + tests — see src/AGENTS.md
└── snapshots/
    └── lsp/           ← LSP feature snapshots (*.snap.md)
```

## Commands

```bash
# from the workspace root (the package has no build.zig of its own)
zig build               # produce zig-out/bin/botopink-lsp
zig build test          # includes the LSP feature tests + snapshots
                        # (cwd = modules/language-server)
```

## Feature scope

The server handles `initialize` / `shutdown`, `didOpen` / `didChange` /
`didClose`, and these `textDocument/*` methods:

- `publishDiagnostics` (with `$/progress`), `formatting`,
  `hover` (full signature + doc comments, incl. qualified `std` members and
  builtin interface methods on primitives/arrays/strings),
  `definition` (same-file, cross-module, embedded `std` modules, plus type-aware
  member access — see below),
  `typeDefinition`,
  `documentSymbol` (hierarchical, incl. `test "name"` blocks; `val X = enum/record/interface`
  reports the container kind, not `Variable`; a 1.0.3 `type` reports `Struct` or `Enum` by its
  shape and lists the `(…)` field list's fields; a **section** of an enum-shaped `type`
  is itself an `Enum` carrying its own members — decision 8 §5.3b; a method of a `type`, an
  `enum` or a `behavior` is `Method`, and so is a `test "name"` block — see below),
  `completion` (prefix + dot-trigger + std members + builtin interface methods
  on primitive/array/string receivers + labeled args + sortText + module names),
  `references` (cross-module), `rename` (cross-module multi-file, with
  `prepareRename`, rejects keywords),
  `signatureHelp` (incl. builtin interface methods, `self` dropped; parameter
  labels are `name: Type`, never the bare type — see below),
  `inlayHint` (inferred `val` types, call-site parameter names, lambda parameter
  types; `workspace/inlayHint/refresh` on edits),
  `semanticTokens/full` + `semanticTokens/range` (legend distinguishing builtin
  types, interface methods vs free fns, the `*fn` effect marker, comptime params,
  enum members, record fields (`property`), generic type parameters, parameter
  *uses* inside the body, named-argument labels and `true`/`false`; effect fns
  (a `-> @Task` / `@Iterator` / … return; the annotation that used to mark them left
  with decision 118, so the modifier is the tooling thread's to restore) carry the
  `async` modifier; plus a sub-language overlay
  inside string literals — see below),
  `codeAction` (add type annotation, remove unused import, add missing case
  patterns, add missing import),
  `foldingRange` (incl. `test` blocks).

The server maintains a **project index** (`src/project_index.zig`) that scans
`.bp` files from the workspace `rootUri`, caching `pub` symbols for cross-module
features (import suggestions, references, module completion). An import in
either spelling of decision 107 (`import {dict.empty as newDict}`,
`import {dict: {empty as newDict}}`) binds the same leaf here as in the CLI —
the server compiles with the compiler's own `resolveImports`, and
`importsStdModule` (`engine.zig`) splits on `.` and `:` so both spellings
name the module for std completion.

### Project-graph compile

Every handler compiles the active document **together with its module graph**
(`Server.compileWithGraph` → `buildModuleEntries`). `src/project_graph.zig`
resolves the dependency set with the same rules the CLI driver uses:

- `from "<lib>"` → the lib's own `botopink.json` (`src` + `files`), found by the
  shared `manifest.resolveDependency` (`modules/manifest`, the CLI's resolver):
  a `{ "path": … }` dependency from the project directory, `{ "workspace": true }`
  from the enclosing workspace, a `{ "git": … }` one by name across the resolved
  **root list** (`BOTOPINK_LIB_ROOTS` env entries, then for each ancestor `D` of
  the project: `D` itself when it holds a workspace manifest,
  `D/repository/botopink-lang/libs`, `D/repository`, `D/libs`; de-duped
  first-occurrence-wins; every workspace found there contributes its members)
  and then `<project>/.botopinkbuild/deps/`. `.d.bp` declaration files are kept
  for go-to-def but excluded from the compile (the CLI drops them too).
- `mod` / `pub mod` siblings → every `.bp` under the project's `src/`.
- `from "std"` → embedded, expanded inside the compiler.

The active document stays the hot in-memory copy (appended **last** so it can
import from every dep); open buffers overlay their file on disk; closed files are
read from disk. The resolved deps are **cached per project root**
(`ProjectGraph`), so a keystroke is a cache hit; `invalidateAll` runs on
`didOpen`/`didClose`, never on a keystroke. No `botopink.json` walking up from
the file ⇒ single-document compile (isolated buffers and tests). The compiler
core still names no lib: the resolver feeds it ordinary `(uri, source)` pairs.

**`documentSymbol` gives a member function the kind it has, and the tree is what
identifies a test.** `collectChildren` emits `proto.SymbolKind.Method` for a
method of a `type`, of an `enum` (including a §5.3b section) and of a `behavior`,
and a `test "name"` block is a `Method` too. They are not ambiguous: a `test`
block is a child of the **file**, a method is a child of the declaration it
belongs to. Before decision 7 of 1.0.5-beta the three method sites emitted
`Function` on purpose, because
[`vscode-extension`](../../../vscode-extension/src/symbolNodes.ts) classified
every `Method` symbol as a runnable test and the LSP protocol has no `Test`
kind — the outline was wrong so that the Test Explorer would be right. The
extension now reads the parent (`isTestSymbolNode(symbol, parent)` /
`testSymbolNodes`), so **the two repositories move together**: never flip a
symbol kind here without the consumer's commit in the same sweep.

**A source the graph cannot follow is a diagnostic, not a silent gap.** Three
reads were `catch continue`: a dependency no root carries, a `files` entry that
cannot be read, and a `.bp` under the project's own `src` that cannot be read.
A fourth is a manifest the shared model refuses (the string-array
`dependencies`, a `path` to a sibling member, a workspace where a package is
needed, … — `docs/botopink-json.md`): the same located error the CLI prints,
published on the manifest it is in (`problemFromLocated`).
Each left the graph a module short and the editor blamed the *user's* file —
every symbol the missing module exports "unbound", pointing nowhere near the line
that is actually wrong. `ProjectGraph` collects all three as `Problem`s; the two
manifest ones carry the CLI's message word for word
(`compiler-cli/src/cli/libs.zig`) and are located at the `"<entry>"` string
inside the manifest that declares it — the project's own `botopink.json` for a
missing dependency, the library's for an unreadable `files` entry. The third is
located on **the unreadable file itself**, first character, because no manifest
line names it (`loadSrcTree`; the walk then continues, so one unreadable file
does not cost the project the rest of its tree).
`Server.publishGraphProblems` groups by whatever URI the `Problem` carries and
publishes **against that URI**, not the open document's (a manifest line to fix
would otherwise repeat on every file of the project), and `clearGraphProblems`
empties a file the server flagged once it is fixed — the LSP clears a file only
by publishing an empty list for it, and a manifest is never a document the client
opened.

`definition` resolves in tiers: sub-language `ref` (cursor inside a string, see
below) → **typed member/`mod` path** (`needsTypedDefinition` →
`engine.definitionMember`) → local scope → same file → **project graph**
(`from "<lib>"` surface, incl. member access like `Response.created`) →
workspace `pub` symbols (project index) → embedded `std` package modules
(`engine.definitionInStdModules`). Std hits (and builtin-method hits) are
materialized to `<XDG_CACHE_HOME|~/.cache>/botopink-lsp/std/<name>.bp`
(`Server.materializeStdModule`) so the editor can open them.

**Type-aware member / module go-to-def** — `findDeclLocation`'s keyword scan is
blind to anything that is *part of a type*. `engine.definitionMember` (gated by
the cheap `needsTypedDefinition` so the plain name scan stays compile-free)
covers these by reusing the receiver-type machinery of completion/hover:

- **`recv.field` / `recv.method`** — `receiverChain` parses the dotted receiver,
  `resolveChainType` walks it to a named type (a value binding's inferred type, an
  integer/bool literal, or `self` → the lexically `enclosingTypeName`), narrowing
  through record fields (`stepField`). The member is located by token-scanning
  that type's `{…}` body — and a 1.0.3 `type`'s `(…)` field list (`findMemberInTokens`), so a same-named method on another
  record does not win.
- **`recv._N` (tuple elements)** — `resolveHead` keeps a tuple binding's element
  types in `ReceiverType.tuple`; `stepField`'s `_<digits>` arm picks element `N`
  via `tupleMemberIndex` and lifts its type back via `receiverFromType`. A request
  *on* `_N` itself returns null; a chained `t._0.field` resolves `field` against
  element 0's record.
- **`Iface.method(...)` (interface assoc-fn)** — when `resolveChainType` returns
  `.unknown`, `findInterfaceMethodAcross` scans the active file then the project
  graph for `interface <head> { … }` / `behavior <head> { … }` and returns the inner `default fn` /
  `declare fn` location. Cross-module requires the interface be `pub`.
- **Builtin receivers** (`xs.reverse()`, `s.split(…)`) route through
  `builtinInterfaceForType` to the embedded std `primitives.bp` and return a
  `TypedDefinition.builtin` (source + range) the server materializes like a std hit.
- **`Name(field: …)` labels** — `ctorCalleeBefore` finds the constructor callee and
  jumps to the field decl.
- **Cross-module fields** (`findMemberDeclAcross`) search the graph deps,
  requiring the owning type be `pub`.
- **`mod` / `pub mod <name>;`** — `modRefNameAt` + `findModuleFile` map the name to
  the backing file (`<name>.bp` / `<name>/mod.bp`) and jump to its top.

### Local-scope binding model

The typed `bindings` slice is module-level only — it never holds function
parameters, `comptime` params, `val`/`var` locals, or closure binders
(`{ f -> … }`). `engine.collectLocalScope` reconstructs the bindings visible at
the cursor with a **pure token walk** (no typed body needed, so it survives a
type error — completion degrades, not vanishes). `engine.completion` merges
these ahead of the module bindings (inner scope shadows outer, `Variable` kind);
`engine.definition` / `definitionInModules` try `localDefinition` first so a
nearer param/local/binder wins over a same-named top-level decl.
`findDeclLocation` includes `var` in its keyword set.

**Builtin interface methods** — `completion`/`hover`/`signatureHelp` on a
primitive/array/string receiver (`n.abs()`, `true.toString()`, `xs.map(…)`,
`"s".length()`) resolve against the embedded interface declarations exposed by
`comptime_pipeline.{primitive_interfaces_src,array_interface_src,string_interface_src}`
(all three are `libs/std/src/primitives.bp`). The receiver's inferred type name
(`i32`→`I32`, `bool`→`Bool`, `array`→`Array`, `string`→`String`) selects the
interface; integer literals default to `I32`, `true`/`false` to `Bool`.
`signatureHelp` drops the leading `self`. Gotcha: an integer *literal* receiver
(`42.`) only surfaces through the text-based engine path — the lexer reads `42.`
as a float, so the editor reaches this via a variable (`val n = 42; n.`).

A member's `detail` is a **single-line signature** sliced out of that embedded
source by `collectInterfaceMembers`. The slice stops at a comment, at
`default`/`pub`/`private`/`declare`, at a `#[` attribute, at the next `fn`/`val`,
and at any token on a later line; a `default fn` body is skipped whole, so its
locals are not mistaken for members. `#` only ends a signature when it opens
`#[` — a bare `#` is the tuple sigil in `Array<#(T, U)>`. Members whose first
parameter is not `self` (`Array.range`, `Array.repeat`) are associated fns and
are hidden from instance completion (`xs.`).

`signatureHelp` builds each `ParameterInformation.label` as `name: Type`, with
the names recovered from the `fn` declaration in the document
(`fnDeclParamNames`). Clients highlight a parameter by locating its label as a
**substring** of the signature label, so two bare `i32` labels would make the
client underline the first parameter for both.

### Sub-languages (`@ExprCustom`)

An embedded query/markup literal (e.g. `erika "select name from users"`) lights
up *from the compiler*, not a hand-written grammar. A template lib returns
`@ExprCustom<T> { code, ast }`; the `ast` is a generic `CustomNode` tree
(`{ kind, span, label, ref?, children }`) the lib built at comptime. The LSP
knows only `CustomNode` — it never branches on any sub-language:

- **Expansion** — `LspCompiler` is created with an `eval_root`, which becomes a
  `TemplateEvalCtx` passed to `comptime_pipeline.compileTypesOnly`, so template
  bodies are evaluated (through compiler-core's persistent `erl` comptime
  runtime) and their trees surface on `OkData.custom_ast`
  (`CompileResult.customAstFor`). The scratch root is
  `<XDG_CACHE_HOME|~/.cache>/botopink-lsp/template` (fallback
  `.botopinkbuild/lsp`), computed by `server.zig:computeTemplateRoot`. Tooling
  that must not evaluate templates passes a null `eval_root`. Because the compile
  runs over the project graph, a template fn reached via `from "<lib>"` expands too.
- **Semantic tokens** — `engine.customSemanticTokens` maps each node's `label`
  (`keyword`/`property`/`string`/`number`/`operator`; `string`/`number`/`operator`
  are legend indices 11–13 in `protocol.zig`) and `span` (a byte offset into the
  literal) to an absolute range; `mergeSemanticTokens` re-sorts them into the
  lexer stream. Unknown labels stay the opaque `string` token.
- **Diagnostics** — a template's `failAt(span, msg)` maps through compiler-core's
  `template.failDiagnostic` to a type error located **inside** the literal.
- **Hover / go-to-definition** — a node may carry `ref` (a `q.lookup` result tying
  it to a caller-scope symbol). `engine.customRefNameAt` finds the deepest
  covering node under the cursor; `hoverCustomRef` renders the bound symbol's
  card, `definitionCustomRef` jumps to its declaration. Go-to-def is gated on
  `engine.cursorInString` so the common path skips the extra compile.

Any lib returning `@ExprCustom` lights up for free. See
[`src/tests/sublanguage.zig`](src/tests/sublanguage.zig).

Add a new feature → implement it in [`src/engine.zig`](src/AGENTS.md), add a
test under [`src/tests/`](src/tests/AGENTS.md) and a snapshot under
`snapshots/lsp/`.

## Env

| Variable              | Read by                                  | Effect                                                                  |
| --------------------- | ---------------------------------------- | ----------------------------------------------------------------------- |
| `BOTOPINK_LIB_ROOTS`  | `src/project_graph.zig` (`resolveRoots`) | Prepends extra lib roots before the walk-up roots. Same contract as the |
|                       |                                          | CLI driver — server and CLI must see the same root list or go-to-def    |
|                       |                                          | misroutes when bpmp is in play.                                         |
| `XDG_CACHE_HOME` / `HOME` | `src/server.zig` (`computeTemplateRoot`, std materialization) | Cache root for template-eval scratch and materialized std files. |

**`BOTOPINK_LIB_ROOTS` contract** (mirrors
[`compiler-cli`](../compiler-cli/AGENTS.md#env)):

- Path separator: `:` on POSIX, `;` on Windows (via `std.fs.path.delimiter`).
- Entries prepended to the walk-up result, combined list de-duplicated
  first-occurrence-wins (env always shadows a duplicate walk-up root).
- Non-existent and empty entries silently dropped (a typo must not break the LSP);
  relative paths resolved against the process cwd.
- Unset / empty value → walk-up roots only.
- Threaded via `Server.init(environ_map)` → `ProjectGraph.init(env_map)`;
  test code passes `null` (or uses `resolveRootsForTesting`).

## Two declaration surfaces (front 12, until its step 4)

The token scanners accept both spellings: `record`/`enum`/`interface` and the
1.0.3 `type`/`behavior`. `declKindAt` maps a keyword to the legacy kind the
scanners key on (`type` by its shape, `behavior` → `.interface`), and
`typeDeclSpan` gives a `type`'s field list, body and last token — a `type`
without a body has no `{` to search for, and `comptime T: type` / `-> type`
open no declaration. Semantic tokens paint a field list's `name:` as
`property`; `project_index.zig`'s `typeDeclIsEnum` decides a `pub type`'s kind.

What the scanners accept is **not** what the user is shown. Every text the
editor renders is written in the 1.0.3 surface only — `renderBindingHover`
prints `pub type Point(x: i32, y: i32)`, `pub type Shape { Circle(...) }` and
`pub behavior Mappable<T>`, never `record` / `enum` / `interface`, so a hover
card is a line the user could paste back into the file (front 14 step 1).

The same rule binds `renderType`, which writes an inferred type rather than a
declaration: `i32[]`, `?i32`, `#(name: string, pop: i32)` — never the checker's
`array<…>` / `optional<…>` / `tuple<…>`. It is the one surface that also gets
**written back**: the `Add type annotation` code action inserts exactly what
`renderType` returned.

## Scratch paths in tests

A unit test in this package that writes to disk takes its path from the
`test_scratch` module — `test_scratch.path(io, "<case>/…")`,
`test_scratch.remove(io, "<case>")` — never a hand-spelled
`.botopinkbuild/<case>` (`scripts/check-test-scratch.sh` refuses that, decision 67, no flag).
The test cwd is this package's directory, shared by every process running the
suite; a per-case-but-not-per-run path let a second `zig build test` empty the
first one's fixtures mid-test. See
[../test-scratch/AGENTS.md](../test-scratch/AGENTS.md).
