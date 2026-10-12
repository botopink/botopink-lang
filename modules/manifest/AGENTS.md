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
members) and 76 (`dependencies` is the object form only) of 1.0.10-beta, and 512
of 1.0.12-beta (a workspace declares what its members share — its `dependencies`
above all — and a member declares only its own), under
decision 67 (the most restrictive behaviour, no knob): every refusal is a
`Located` error — message, file, line, column, span — rendered in the CLI's
diagnostic shape, and nothing is parsed and ignored.

The user-facing schema is [`../../conformance/docs.md`](../../conformance/docs.md) § The manifest schema;
keep the two in sync — every field and every message there is read or produced
here.

## Tree

```text
manifest/
├── AGENTS.md            ← you are here
├── src/
│   └── root.zig         ← the whole module: model, parser, workspaces, discovery, resolution + unit tests
└── tests/fixtures/      ← on-disk fixtures the unit tests read (cwd = modules/manifest); their `.bp` files are
    │                       canonical — `modules/manifest/tests` is one of `scripts/format-check.sh`'s `TREES`
    ├── workspace/       ← a good workspace: two library members, one library member without files, one example
    ├── bad/<case>/      ← one refused manifest per located error (nested-workspace, duplicate-member, otp-member, …)
    ├── otp/             ← a workspace pinning "otp": one member inheriting it, one repeating it
    ├── inherit/         ← a `"*"` workspace declaring a version, targets and two dependencies (a `path` to
    │                       vendor/lib, a `git`): `a` writes its name alone, `b` adds a dependency, restricts
    │                       the targets, keeps its version and names an inherited dependency in "bpp"
    ├── roots/           ← what `scanRoots` sees: repository/ (plain package + workspace), other/ (a second
    │                       workspace re-declaring a member, a package in the retired array form, a duplicate
    │                       plain package), named/ (an umbrella directory named like its core member), local/
    └── symlinked-store/ ← deps/ as `bpmp install` writes it: a symbolic link to packages/side, and one to a file
```

## Surface (`src/root.zig`)

| Symbol | What |
|---|---|
| `Manifest` | Every field a parser reads: `name`, `version` (`version_declared`: whether it is written), `description`, `src`, `entry`, `target`, `targets`, `files`, `dependencies`, `workspaces`, `otp`, `wasm_host`, `bpp`; `kind` (`package` / `workspace`); raw `text` + `path` so a later refusal can be located. `supportsTarget`, `dir`; `locateAt(key, message)` and `locateEntryAt(key, entry, message)` build a `Located` on this manifest's `"<key>"` / on the `"<entry>"` of its `"<key>"` object, so a caller outside this module (the CLI's sidecar shipper, say) reports a problem it found *through* a manifest in the same shape as the refusals raised here. |
| `WasmHost` · `"wasm"` | Decision 334 of 1.0.12-beta. `"wasm": { "host": "wasi" \| "browser" }` parses to `Manifest.wasm_host` (`wasi` when absent), on a package only (a workspace manifest carrying it is refused with `src`/`files`/…). `parseWasm` refuses a non-object, an object without `host`, any other field (located at it), a non-string host and a host that is neither (located at the value). The CLI's wasm build reads it on the project being built. |
| `"bpp"` · `parseBpp` | Decision 361 of 1.0.12-beta. `"bpp": "<package>"` parses to `Manifest.bpp`: one name, an entry of `dependencies` (else refused at the value, `"bpp" names "x", which is not a dependency — …`); the object form (and any non-string) is refused at the key, `"bpp" is a package name — write "bpp": "jhonstart"`; a workspace manifest carrying it is refused with `src`/`files`/…. The roles the package's declarations carry are the CLI's check (`compiler-cli/src/cli/bpp.zig`). |
| `DepEntry{name, spec, inherited}` · `DepSpec{git, path, ref, workspace, subdir}` · `DepRef` | The dependency object: exactly one source (`git` with an optional `branch`/`tag`/`rev` pin and an optional `subdir`, `path`, `workspace: true`). `inherited`: the entry is the member's workspace's (decision 512) — `Manifest.locateEntryAt("dependencies", name, …)` then points into the workspace's manifest (`Manifest.inherited_from`). |
| `inheritFrom(arena, ws, &member, member_dir, &err)` · `inheritInPlace(arena, io, &m, dir, &err)` · `Origin` | Decision 512. What a member takes from its workspace: every `dependencies` entry (a `path` rewritten from the workspace's manifest to the member's directory — `..` per segment below the workspace), its own added after them, one it redeclares refused at its entry (`"lib" is a dependency of the workspace (<ws>), which every member inherits — delete this entry: a workspace has one source per dependency`); `version` when the member writes none and the workspace does; `entry` `main.bp` when the member writes none; `targets` (inherit or restrict) and `otp` (inherit or repeat), refused as before; then `checkBpp`. `expand` applies it to every member; `read` applies `inheritInPlace` — `workspaceOf` + `inheritFrom` — to a package it reads, so every reader (the CLI's `config.load`, a `path` dependency reached by `resolveDependency`, the language server, `bpmp`) sees a member the same way. Applied once (`inherited_from` set). |
| `workspaceOf(arena, io, dir, &err)` · `listsMember(arena, ws, dir)` | The manifest of the nearest ancestor workspace whose globs list `dir` (absolute) — by the globs alone, no member read, so a sibling whose manifest is refused does not refuse this one (botopink-lang's `conformance/modules/` holds cells whose manifest refusal IS their answer). `botopink cell check` builds a member cell in a scratch workspace from it, and puts its code cache in its directory. |
| `parseWith(arena, text, path, &err, .{ .bundled_std, .defer_bpp })` · `checkBpp(arena, m, &err)` | `defer_bpp`: leave `"bpp"`'s "names a dependency" to `checkBpp`, after inheritance (a member's `"bpp"` may name an inherited dependency). `parse` checks it at once. |
| `subdirRefusal(arena, name, sub)` · `sameRepository(a, b)` · `repositoryUrl(url)` | Decision 344 of 1.0.12-beta. A `git` dependency's `"subdir"` names the package's directory inside the repository; `parse` refuses it without `git`, absolute (`/…`, `C:…`), with a `..`, `.` or empty segment or a backslash, and refuses two dependencies on one repository (`repositoryUrl`: the URL without a trailing `/` or `.git`) at two refs, on the second entry naming both. `bpmp` checks what the subdir holds (`dep/member.zig`). |
| `OTP_RELEASE` · `OtpPin{release, path, text}` · `otpRefusal(pin)` · `closureOtp(manifests, &err)` | Decision 228 of 1.0.11-beta. `OTP_RELEASE` (`"28"`) is **the** release the compiler emits for — the one constant: the CLI's `otp.zig` checks the `erl` on PATH against it, `botopink --version` prints it, `scripts/gate.sh` and botopink-lang's workflow read it from this file's source line (`pub const OTP_RELEASE = "<n>";` — keep that shape). It lives here because the manifest refusal needs it and this module is std-only. `"otp"` parses to an `OtpPin` that remembers the manifest that wrote it (a member without one inherits its workspace's in `expand`, still pointing at the workspace's line; a member naming another is refused). `parse` checks the shape only; `otpRefusal` refuses a release other than `OTP_RELEASE` (`botopink emits Erlang for OTP 28; "otp" names 26`, on the value), and `closureOtp` walks a build's manifests, project first: every pin must equal the first one (else refused at the later value naming the first file), then the first must pass `otpRefusal`. The CLI calls it on the project (`config.zig`) and on the project plus its closure (`libs.zig`). compiler-core imports this module for `OTP_RELEASE` alone (its `src/otp.zig`, the check every `erl` spawn goes through). A `path` dependency that lands on a workspace member reads that member's own manifest and does not inherit its workspace's `otp` — harmless while the compiler supports one release, since any pin must name it; revisit when a second release is supported. |
| `Located` | A refusal with a place; `render(w)` / `renderAlloc` / `print` produce `error: … / --> file:L:C / caret`. `print` writes to stderr, or to `sink` when a caller set it — `botopink cell check` (`compiler-cli/src/cli/cell.zig`) reads a cell's refusals back from the text a build prints, a manifest's and a sidecar's included. |
| `parse(arena, text, path, &err)` · `read(arena, io, dir, &err)` | Parse a manifest; `error.Invalid` with `err` set. A workspace manifest may not carry `src`/`files`/`entry`/`wasm`/`bpp`; its `dependencies` are its members' (decision 512), a `{ "workspace": true }` among them refused; the string-array `dependencies` is refused naming the fix; a dependency needs exactly one source and at most one pin. `read` inherits (`inheritInPlace`). |
| `parse` · `parseBundledStd` · `isBundledStd(io, dir)` · `STD_NAME` | Decision 453 of 1.0.12-beta. A package named `std` is refused at the `name` key (`the package name \`std\` is the bundled standard library's — choose another name`) unless it is the bundled `libs/std`: `isBundledStd` judges the directory by its real path (`<checkout>/libs/std`, `<checkout>` holding `modules/compiler-core`), never by the name. `read(dir)` asks it; `parseBundledStd` is the parser for a caller that already asked (the CLI's `config.load` on the cwd); `parse` alone always refuses the name. |
| `nameRefusal(name)` | Why a `name` cannot name a package, or null: it must start with a lowercase letter and may not be `bp` — every erlang/BEAM module atom starts with the package name (decision 109 of 1.0.10-beta) and is never quoted, and `bp` is the compiler's own namespace. `parse` refuses such a `name`, located at the key; `botopink new` asks it before scaffolding. |
| `expand(arena, io, m, &err)` → `Workspace{dir, manifest, members}` | Expand `workspaces` globs (`<dir>/*`, `*` — the workspace's own children, decision 512 (5) — and literal `<dir>` only) into `Member{name, dir, manifest}`, each through `inheritFrom`; refuses a nested workspace, two members with one name, a member widening `targets` (a member without `targets` inherits), `{ "workspace": true }` naming no sibling, a `path` to a sibling or to the workspace itself, a self dependency. |
| `isWorkspaceDir(io, dir)` | The cheap probe the three root walk-ups use to add an ancestor workspace as a root. |
| `isCheckoutRoot(io, dir)` | True when `dir` holds `repository/` — the enclosing checkout (the meta workspace, a worktree of it under `.tasks/<name>`, CI's `botopink-lang` with the libraries cloned into `repository/`). The three root walk-ups add that directory's roots and stop: an ancestor belongs to another checkout, whose libraries would be every name a second time (decision 143). |
| `enclosingWorkspace(arena, io, project_dir, &err)` | The nearest ancestor workspace that lists `project_dir` as a member, or null. |
| `CACHE_DIR` · `cacheRoot(project_dir, workspace)` · `findCacheRoot(arena, io, project_dir, &err)` · `cacheDir(arena, root, store)` | Where every cache lives (decision 225): `<root>/.botopinkbuild/cache/<store>`, `<root>` the workspace the package is a member of, else the package's directory. The one answer the CLI (`libs.cacheRoot`, with the workspace `config.load` found), the runner (`schedule.cacheRoot`) and the language server (`ProjectGraph`'s `cache_root`, store `lsp`, decision 233) give; nothing reads the environment. |
| `isLibraryPackage(io, m)` · `shipsNothing(io, m)` | A library (`root.bp`, not `main.bp`) member with no `files` ships nothing — the refusal `botopink test` and the runner report. |
| `scanRoots(arena, io, roots)` → `[]Entry` | The shared discovery: a root that is a workspace contributes its members; otherwise each child holding a manifest — a directory, or a symbolic link that resolves to one (the `.botopinkbuild/deps/` store `bpmp install` writes) — is a package (named by directory) or a workspace (its members, named by manifest; the umbrella entry follows them with `is_workspace`). One directory reached twice is one entry. A refused manifest marks only its own `Entry.problem`. Two **members** with one name (or a member and a package) are both refused; two plain packages keep first-root-wins. |
| `find(entries, name)` | The package or member so named; the umbrella only when no package is. |
| `resolveDependency(arena, io, project, project_dir, dep, tiers, &err)` | One `dependencies` entry → `{dir, manifest}`: `workspace` via the enclosing workspace, `path` from the project directory (must hold a package of that name; a sibling member or a workspace is refused), `git` by name from the first of `tiers` that carries it (decision 483 — each tier one `scanRoots`, so a name in two tiers is the earlier one's, never "declared by two libraries"; a workspace so named is refused with its member list); `null` when no tier carries the name. The CLI (`libs.dependencyTiers`) and the language server (`ProjectGraph.dependencyTiers`) pass `BOTOPINK_LIB_ROOTS`, then each of `depsRoots`, then the walk-up roots; `bpmp` passes none (`path` / `workspace` only). |
| `DEPS_DIR` · `depsRoots(arena, io, project_dir)` | Decision 483. `.botopinkbuild/deps` — where `bpmp install` and `bpmp link` write one link per `git` dependency. `depsRoots` lists the link directories a `git` dependency of the project is looked up in before the walk-up: `<project_dir>/.botopinkbuild/deps`, then — for a workspace member — `<workspace root>/.botopinkbuild/deps` (`bpmp install` writes the first, from the manifest in its working directory; `bpmp link` at a workspace root writes the second, one link per name for every member). A workspace that does not expand contributes nothing (the reading command reports it). |

## Tests

`zig build test` runs `src/root.zig`'s tests with cwd `modules/manifest` (the
fixtures are read relatively). Every located error has a test that shows its
message; `zig build test -Dtest-filter=manifest` is not a thing — filter by a
test name substring (`-Dtest-filter=expand`).

## Rules

- Add a field only when a named reader consumes it, and document it in
  `conformance/docs.md` § The manifest schema in the same commit.
- A new refusal is a `Located` error with a test that shows the rendered
  message, and a row in the schema document.
- Never accept two spellings of one thing (decision 67): the string-array
  `dependencies`, a `ref` beside `branch`/`tag`/`rev`, a second glob form — each
  is a refusal, not an alias.
- No `compiler-core` import, ever — the runner and `bpmp` depend on it.
