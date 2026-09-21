# manifest

> Path: `modules/manifest/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

The one reading of `botopink.json` every tool shares: the compiler CLI
(`compiler-cli/src/cli/config.zig`, `libs.zig`), the language server
(`language-server/src/project_graph.zig`), the lib-test runner
(`lib-test-runner/src/discovery.zig`) and `bpmp` (`bpmp/src/manifest.zig`,
`dep/spec.zig`) import it as `@import("manifest")` (wired by the workspace
`build.zig`). It depends on `std` only — no `compiler-core` — so the runner and
`bpmp` keep their "no compiler-core" contract.

It implements decisions 75 (a `workspaces` manifest declares a library's
members) and 76 (`dependencies` is the object form only) of 1.0.10-beta, under
decision 67 (the most restrictive behaviour, no knob): every refusal is a
`Located` error — message, file, line, column, span — rendered in the CLI's
diagnostic shape, and nothing is parsed and ignored.

The user-facing schema is [`../../docs/botopink-json.md`](../../docs/botopink-json.md);
keep the two in sync — every field and every message there is read or produced
here.

## Tree

```text
manifest/
├── AGENTS.md            ← you are here
├── src/
│   └── root.zig         ← the whole module: model, parser, workspaces, discovery, resolution + unit tests
└── tests/fixtures/      ← on-disk fixtures the unit tests read (cwd = modules/manifest)
    ├── workspace/       ← a good workspace: two library members, one library member without files, one example
    ├── bad/<case>/      ← one refused manifest per located error (nested-workspace, duplicate-member, …)
    └── roots/           ← what `scanRoots` sees: repository/ (plain package + workspace), other/ (a second
                            workspace re-declaring a member, a package in the retired array form, a duplicate
                            plain package), named/ (an umbrella directory named like its core member), local/
```

## Surface (`src/root.zig`)

| Symbol | What |
|---|---|
| `Manifest` | Every field a parser reads: `name`, `version`, `description`, `src`, `entry`, `target`, `targets`, `files`, `dependencies`, `workspaces`; `kind` (`package` / `workspace`); raw `text` + `path` so a later refusal can be located. `supportsTarget`, `dir`; `locateAt(key, message)` and `locateEntryAt(key, entry, message)` build a `Located` on this manifest's `"<key>"` / on the `"<entry>"` of its `"<key>"` object, so a caller outside this module (the CLI's sidecar shipper, say) reports a problem it found *through* a manifest in the same shape as the refusals raised here. |
| `DepEntry{name, spec}` · `DepSpec{git, path, ref, workspace}` · `DepRef` | The dependency object: exactly one source (`git` with an optional `branch`/`tag`/`rev` pin, `path`, `workspace: true`). |
| `Located` | A refusal with a place; `render(w)` / `renderAlloc` / `print` produce `error: … / --> file:L:C / caret`. |
| `parse(arena, text, path, &err)` · `read(arena, io, dir, &err)` | Parse a manifest; `error.Invalid` with `err` set. A workspace manifest may not carry `src`/`files`/`entry`/`dependencies`; the string-array `dependencies` is refused naming the fix; a dependency needs exactly one source and at most one pin. |
| `expand(arena, io, m, &err)` → `Workspace{dir, manifest, members}` | Expand `workspaces` globs (`<dir>/*` and literal `<dir>` only) into `Member{name, dir, manifest}`; refuses a nested workspace, two members with one name, a member widening `targets` (a member without `targets` inherits), `{ "workspace": true }` naming no sibling, a `path` to a sibling or to the workspace itself, a self dependency. |
| `isWorkspaceDir(io, dir)` | The cheap probe the three root walk-ups use to add an ancestor workspace as a root. |
| `enclosingWorkspace(arena, io, project_dir, &err)` | The nearest ancestor workspace that lists `project_dir` as a member, or null. |
| `isLibraryPackage(io, m)` · `shipsNothing(io, m)` | A library (`root.bp`, not `main.bp`) member with no `files` ships nothing — the refusal `botopink test` and the runner report. |
| `scanRoots(arena, io, roots)` → `[]Entry` | The shared discovery: a root that is a workspace contributes its members; otherwise each child holding a manifest is a package (named by directory) or a workspace (its members, named by manifest; the umbrella entry follows them with `is_workspace`). One directory reached twice is one entry. A refused manifest marks only its own `Entry.problem`. Two **members** with one name (or a member and a package) are both refused; two plain packages keep first-root-wins. |
| `find(entries, name)` | The package or member so named; the umbrella only when no package is. |
| `resolveDependency(arena, io, project, project_dir, dep, entries, fallback, &err)` | One `dependencies` entry → `{dir, manifest}`: `workspace` via the enclosing workspace, `path` from the project directory (must hold a package of that name; a sibling member or a workspace is refused), `git` by name across `entries` then `fallback` (a workspace so named is refused with its member list); `null` when nothing carries the name. |

## Tests

`zig build test` runs `src/root.zig`'s tests with cwd `modules/manifest` (the
fixtures are read relatively). Every located error has a test that shows its
message; `zig build test -Dtest-filter=manifest` is not a thing — filter by a
test name substring (`-Dtest-filter=expand`).

## Rules

- Add a field only when a named reader consumes it, and document it in
  `docs/botopink-json.md` in the same commit.
- A new refusal is a `Located` error with a test that shows the rendered
  message, and a row in the schema document.
- Never accept two spellings of one thing (decision 67): the string-array
  `dependencies`, a `ref` beside `branch`/`tag`/`rev`, a second glob form — each
  is a refusal, not an alias.
- No `compiler-core` import, ever — the runner and `bpmp` depend on it.
