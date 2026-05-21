# botopink-lang · root AGENTS.md

Guidance for AI agents working on the botopink language workspace.

> Convention: source, comments, commit messages and docs are all in **English**.
> Each directory ships its own `AGENTS.md` — read the closest one first, then
> walk up the tree.

## Repository tree

```text
botopink-lang/
├── AGENTS.md                  ← you are here (workspace overview)
├── README.md                  ← public-facing intro
├── CHANGELOG.md               ← release notes (current: v0.0.11-beta)
├── docs.md                    ← language reference
├── build.zig                  ← workspace build graph (CLI + LSP)
├── test_format.zig            ← ad-hoc formatter smoke
├── test_pub.zig               ← ad-hoc pub-decl smoke
├── modules/                   ← all Zig packages — see modules/AGENTS.md
│   ├── compiler-cli/          ← `botopink` CLI
│   ├── compiler-core/         ← lexer, parser, AST, infer, comptime, codegen
│   ├── language-server/       ← `botopink-lsp` LSP server
│   └── stdlib/                ← .bp stdlib declarations (loaded at infer time)
└── snapshots/                 ← workspace-level codegen snapshots
    └── codegen/{erlang,node}/ ← target-specific outputs
```

## Workspace commands

Run from the repository root:

```bash
zig build           # compile CLI + language-server
zig build test      # run compiler-core + language-server tests
zig build run       # run the CLI entry point
```

Per-package commands live in each package's `build.zig`. See:

- [`modules/compiler-cli/AGENTS.md`](modules/compiler-cli/AGENTS.md)
- [`modules/compiler-core/AGENTS.md`](modules/compiler-core/AGENTS.md)
- [`modules/language-server/AGENTS.md`](modules/language-server/AGENTS.md)
- [`modules/stdlib/AGENTS.md`](modules/stdlib/AGENTS.md)

## Compiler pipeline (one-line summary)

```text
source → lexer → parser → AST → infer (HM) → comptime transform → codegen → target
                                                          ↘ format.zig (formatter)
                                                          ↘ print.zig (diagnostics)
```

Public API entry points (in `modules/compiler-core/src/`):

| Entry point | File |
|---|---|
| Lexer | `lexer.zig` → `lexer/token.zig` |
| Parser | `parser.zig` |
| AST types | `ast.zig` |
| Type inference + comptime | `comptime.zig` (delegates to `comptime/`) |
| Formatter | `format.zig` |
| Diagnostics renderer | `print.zig` |
| Codegen façade | `codegen.zig` (`compile` / `codegenEmit` / `generate`) |

## AGENTS index (44 files)

```text
.                                              AGENTS.md   ← root
modules/                                       AGENTS.md
modules/compiler-cli/                          AGENTS.md
  └── src/                                     AGENTS.md
      └── cli/                                 AGENTS.md
modules/compiler-core/                         AGENTS.md
  ├── src/                                     AGENTS.md
  │   ├── codegen/                             AGENTS.md
  │   ├── comptime/                            AGENTS.md
  │   │   └── runtime/                         AGENTS.md
  │   ├── format/                              AGENTS.md
  │   ├── lexer/                               AGENTS.md
  │   ├── parser/                              AGENTS.md
  │   └── utils/                               AGENTS.md
  └── snapshots/                               AGENTS.md
      ├── codegen/                             AGENTS.md
      │   ├── erlang/                          AGENTS.md
      │   │   └── erlang/                      AGENTS.md
      │   ├── errors/                          AGENTS.md
      │   │   ├── erlang/                      AGENTS.md
      │   │   │   └── erlang/                  AGENTS.md
      │   │   └── node/                        AGENTS.md
      │   │       └── commonJS/                AGENTS.md
      │   └── node/                            AGENTS.md
      │       └── commonJS/                    AGENTS.md
      ├── comptime/                            AGENTS.md
      │   ├── erlang/                          AGENTS.md
      │   │   └── errors/                      AGENTS.md
      │   └── node/                            AGENTS.md
      │       └── errors/                      AGENTS.md
      └── parser/                              AGENTS.md
modules/language-server/                       AGENTS.md
  ├── src/                                     AGENTS.md
  │   └── tests/                               AGENTS.md
  └── snapshots/                               AGENTS.md
      └── lsp/                                 AGENTS.md
modules/stdlib/                                AGENTS.md
  └── src/                                     AGENTS.md
snapshots/                                     AGENTS.md
  └── codegen/                                 AGENTS.md
      ├── erlang/                              AGENTS.md
      │   └── erlang/                          AGENTS.md
      └── node/                                AGENTS.md
          └── commonJS/                        AGENTS.md
```

## AST model (current categories)

`ExprOf(phase)` is organized by expression family:

- `literal`, `identifier`
- `binaryOp`, `unaryOp`
- `jump` (`return`, `throw`, `try`, `break`, `yield`, `continue`)
- `branch` (`if`, `tryCatch`)
- `loop`
- `binding`, `call`, `function`, `collection`, `comptime_`

Legacy variants (`controlFlow`, `staticCall`) are gone — do not reintroduce them.

## Snapshot testing

- Parser snapshots: `modules/compiler-core/snapshots/parser/*.snap.md`
- Codegen snapshots: `modules/compiler-core/snapshots/codegen/**/`
- Comptime snapshots: `modules/compiler-core/snapshots/comptime/**/`
- LSP snapshots: `modules/language-server/snapshots/lsp/`
- Workspace smoke snapshots: `snapshots/codegen/**/`

On mismatch, tests emit `*.snap.md.new` next to the original. Review and either
promote (replace the `.snap.md`) or discard.

## Conventions

- **AGENTS.md must always be kept up to date.** Whenever code, layout, or
  pipeline behaviour changes (new file, renamed module, added/removed
  subcommand, new pipeline phase, changed conventions, etc.), update the
  affected `AGENTS.md` in the same change. Each directory's `AGENTS.md` is
  the contract for that directory — stale docs are worse than missing docs.
- **`README.md` and `docs.md` must also stay in sync.** Whenever a language
  feature, CLI flag, syntax form, or compiler-visible behaviour changes,
  update both files in the same change as the code:
  - `README.md` — top-level summary of features and recent updates.
  - `docs.md` — full language reference / examples for every feature.
  Don't merge a change that adds or modifies a feature without also touching
  the matching section of `docs.md` (and `README.md` if the feature is
  user-facing enough to belong in the high-level summary).
- **English only** in source, comments, commits, AGENTS.md docs.
- `Parser.init(tokens)` and `Lexer.init(source)` do **not** store an allocator —
  it is always passed as `alloc: std.mem.Allocator` to the method that needs it.
- Type annotations always use `TypeRef` (`named`, `array`, `tuple_`, `optional`,
  `errorUnion`, `function`).
- Record/struct/enum/interface shorthand decls map to the same AST nodes as
  long-form declarations.
- Formatter must be round-trip stable: `format(parse(src))` must re-parse to an
  equivalent AST.
- Pipeline `|>` is left-associative — preserve stable formatting across cycles.

## Recent commit context

| Commit | Summary |
|---|---|
| `5f4c9dc` | fix: comptime inference regressions, snapshot refresh |
| `3d08365` | refactor: compiler expression flow + snapshot refresh |
| `e98f4f5` | chore: ignore compiled `.a` library files |
| `e61ba77` | test: snapshot updates for Zig 0.16.0 API |
| `9b93b5c` | refactor: remove `staticCall` variant for Zig 0.16.0 |
| `787e5c0` | fix: Zig 0.16.0 compat + parser consistency |
| `6d5e8f5` | refactor: unify builtin calls with regular calls |
| `ceb6cfe` | feat(lsp): comment guard + completion tests |
| `717ce5e` | feat: structured AST `TypeRef`, universal catch, LSP, workspace build |
| `e97f0ca` | feat: initial commit |

Current release: see [`CHANGELOG.md`](CHANGELOG.md) (v0.0.13-beta, May 2026).

When editing files: consult the closest `AGENTS.md` first, then parent docs up
to this root file.
