# `botopink.json` — the manifest

Every project, library and workspace carries a `botopink.json` at its root. One
reader parses it for every tool — `modules/manifest/src/root.zig`, imported by
the compiler (`botopink build/check/run/test`), the language server, the lib-test
runner (`botopink-lib-test`, `zig build test-libs`) and `bpmp` — so the fields,
the shapes and the refusals below are the same everywhere. A refusal is always a
**located error**: the message, the manifest file and the line and column of the
entry that is wrong, in the compiler's diagnostic shape:

```text
error: "dependencies" must be an object, not an array — …
 --> botopink.json:2:3
  |
2 |   "dependencies": ["erika"] }
  |   ^^^^^^^^^^^^^^
```

Nothing is parsed and ignored, and no field switches a refusal off (decision 67
of 1.0.5-beta). Two kinds of manifest exist: a **package** and a **workspace**
(decision 75 of 1.0.10-beta).

## A package

```json
{
  "name": "acme-web",
  "version": "0.0.1",
  "description": "Rakun-style web layer — commonJS and erlang",
  "src": "src/",
  "entry": "root.bp",
  "target": "commonJS",
  "targets": ["commonJS", "erlang"],
  "files": ["root.bp", "router.bp"],
  "dependencies": {
    "acme": { "workspace": true },
    "jhonstart": { "git": "https://github.com/botopink/jhonstart.git", "branch": "feat" },
    "local-tool": { "path": "../../tools/local-tool" }
  }
}
```

| Field | Type | Default | Read by | Meaning |
|---|---|---|---|---|
| `name` | string, **required** | — | every reader | The package's **import name**: `from "acme-web"` resolves to the package named so. A workspace member is reached by this name, never by its directory. It also starts every erlang/BEAM module atom of the package (`acme_web@main`, `std@math@@PI` — decision 109 of 1.0.10-beta), so it must start with a lowercase letter, and `bp` (the compiler's own namespace) is refused. |
| `version` | string | `"0.1.0"` | compiler, `bpmp` (`pack`, the auto-tag) | The package version. |
| `description` | string | — | — (documentation) | One line. |
| `src` | string | `"src/"` | compiler, LSP, loader | The source directory, relative to the manifest. `"."` roots the module tree at the manifest's own directory; `test/`, hidden directories and nested packages there are not modules of the tree. |
| `entry` | string | detected | compiler's resolver (`compiler-cli/src/cli/resolver.zig`) | The module-tree root under `src`: `main.bp` for an application, `root.bp` for a library. When absent, `main.bp` is used if present, else `root.bp`. `entry` is followed when **this** package is built or tested; a consumer never follows it. |
| `target` | string | `"commonJS"` | `botopink build/run/test` | The default target of `botopink build`, `run` and `test`. One of `commonJS`, `erlang`, `beam`, `wasm`; another value is refused (never degraded). |
| `targets` | array of strings | every target | `botopink-lib-test` | The targets the runner may run this package on. Absent: every requested target. A target the list leaves out is not a cell — nothing runs it — and the exclusion is audited on every run: `botopink build --target <excluded>` must be refused for a missing host binding (`has no #[@External.<Target>(…)]`), so a package may exclude only a target it structurally cannot run on; one that builds there, or fails for another reason, fails the run. A member of a workspace inherits the workspace's `targets` when it declares none, and may only **restrict** them (below). |
| `files` | array of strings | `[]` | the loader (`compiler-cli/src/cli/libs.zig`, `language-server/src/project_graph.zig`), `bpmp pack` | The modules a **consumer** may import, each relative to `src`; shipped as `<name>/<stem>` (`acme-web/router` → `import { … } from "acme-web.router"` / the root `root.bp` → `from "acme-web"`). The only thing a dependency's consumer sees — a library that lists no `files` ships nothing. `libs/std` uses it for the modules the compiler build embeds. |
| `dependencies` | **object** | `{}` | compiler, LSP, runner, `bpmp` | The object form only — below. |
| `otp` | string | the compiler's | `botopink build/check/run/test` (`compiler-cli/src/cli/config.zig`, `libs.zig`) | The Erlang/OTP release the package is built for (decision 228 of 1.0.11-beta). The compiler emits for one release (`botopink --version` prints it: `otp: 28`), and `otp` may only name that one — another value is refused, located at the value. Every package of a build's closure that declares it must declare the same release; a mismatch is refused at the later value, naming the first manifest. A member of a workspace inherits the workspace's `otp` when it declares none, and may not name another. Absent everywhere: the compiler's release applies. Whatever the manifests say, `botopink build/run/test --target erlang\|beam` refuses an `erl` on `PATH` of another release before writing anything: `` botopink emits Erlang for OTP 28, and `erl` on PATH is OTP 29 — install OTP 28 and put it on PATH ``. |
| `botopink`, `requires` | string · object | — | `bpmp` only | `botopink`: the compiler-version constraint. `requires`: the per-dependency version constraint `bpmp install <name>@<spec>` records. The compiler passes both through unread. |

Unknown fields are preserved by `bpmp` (it rewrites the file) and not read by
anyone else.

## `dependencies` — the object form (decision 76)

```json
"dependencies": {
  "<name>": { "path": "<relative directory>" },
  "<name>": { "git": "<url>", "branch": "<b>" | "tag": "<t>" | "rev": "<sha>", "subdir": "<dir>" },
  "<name>": { "workspace": true }
}
```

The key is the dependency's **import name** (`from "<name>"`) and each entry
declares **exactly one source**:

| Source | Resolves to | Notes |
|---|---|---|
| `{ "path": "…" }` | `<project directory>/<path>`, which must hold a `botopink.json` whose `name` is the key | Honoured by the compiler and the LSP directly — no library root is consulted. `bpmp install` links it under `.botopinkbuild/deps/<name>`. |
| `{ "git": "…", pin }` | The library named `<name>` under the **library roots** (below), then the `bpmp install` store `<project>/.botopinkbuild/deps/<name>/` | The pin is one of `branch`, `tag` or `rev` — `bpmp install` clones it; the compiler resolves by name and does not fetch. A pin without `git` is refused. |
| `{ "workspace": true }` | The **sibling member** of the enclosing workspace named `<name>` | The only way a member depends on a sibling (decision 75). Outside a workspace it is refused. |

**`"subdir"` — a package inside a git repository (decision 344).** A `git`
dependency may name a package that is not at the repository's root:

```json
"dependencies": {
  "rakun-web": { "git": "https://github.com/botopink/rakun", "tag": "v1.0", "subdir": "modules/rakun-web" }
}
```

`bpmp install` clones the repository once at the pin into its store and links
`.botopinkbuild/deps/<name>` to `<checkout>/<subdir>`, which must hold a
package (not a workspace) whose `name` is the key. That package's `path` and
`{ "workspace": true }` dependencies resolve from its directory inside the
checkout (the compiler follows the link), so its siblings come at the same pin;
each must stay inside the checkout. Two dependencies on one repository — one
URL once a trailing `/` and `.git` are dropped — share one checkout and must
name one pin. The compiler still resolves the dependency by name.

`std` is embedded in the compiler and is never listed — it is the one package
the compiler ships (decision 326). Every other library is declared here,
`routing` as any other:

```json
"dependencies": {
  "routing": { "git": "https://github.com/botopink/routing.git", "branch": "feat" }
}
```

Without the entry, `from "routing"` is refused at the import:
`unresolved import source "routing" — declare it in botopink.json "dependencies"`.

**Library roots** (where a `git` dependency is found by name, in order):
`BOTOPINK_LIB_ROOTS` entries (`:`-separated on POSIX); then, for each ancestor
`D` of the project directory, nearest first: `D` itself when `D/botopink.json`
is a workspace (its members), `D/repository/botopink-lang/libs` (the embedded
`std`), `D/repository` (sibling libraries), `D/libs`; then
`<project>/.botopinkbuild/deps` (the `bpmp install` store). A root contributes
every immediate child directory holding a `botopink.json` — as a package named
by the directory — and every **member** of a workspace found there, named by
its manifest. The same directory reached through two roots is one library.

### Refusals

| Manifest | Message |
|---|---|
| `"dependencies": ["erika"]` (the retired string array, empty included) | `"dependencies" must be an object, not an array — write { "<name>": { "path": "…" } \| { "git": "…", "branch"\|"tag"\|"rev": "…" } \| { "workspace": true } }; for example ["erika"] becomes { "erika": { "path": "../erika" } }` |
| `"dependencies": "nope"` | `"dependencies" must be an object — { … }` |
| `"x": "feat"` (an entry that is not an object) | `dependency "x" must be an object — { … }` |
| `"x": { "branch": "feat" }` | `dependency "x" declares no source — one of "git", "path" or "workspace": true is required` |
| `"x": { "path": "../x", "workspace": true }` | `dependency "x" declares more than one source — exactly one of "git", "path" or "workspace": true` |
| `"x": { "git": "…", "branch": "feat", "rev": "…" }` | `dependency "x" declares more than one pin — exactly one of "branch", "tag" or "rev"` |
| `"x": { "path": "../x", "tag": "v1" }` | `dependency "x" pins a ref without a "git" source — a pin applies to a git dependency only` |
| `"x": { "workspace": false }` | `dependency "x": "workspace" can only be true — { "workspace": true } names the sibling member of the enclosing workspace` |
| `"x": { "git": 1 }` (and `path`, `branch`, `tag`, `rev`, `subdir`) | `dependency "x": "git" must be a string` |
| `"x": { "path": "../r", "subdir": "modules/x" }` (a `subdir` beside `path` or `workspace`) | `dependency "x" names a "subdir" without a "git" source — a subdir names a package inside a git repository` |
| `"x": { "git": "…", "subdir": "/modules/x" }` (also `C:/…`) | `dependency "x": "subdir" "/modules/x" is absolute — it names a directory of the repository, relative to its root` |
| `"x": { "git": "…", "subdir": "modules/../../x" }` | `dependency "x": "subdir" "modules/../../x" leaves the repository — ".." is not a segment of a subdir` |
| `"x": { "git": "…", "subdir": "./modules/x" }` (also `modules//x`, a trailing `/`) | `dependency "x": "subdir" "./modules/x" has an empty or "." segment — write the directory as plain segments separated by "/"` |
| `"x": { "git": "…", "subdir": "modules\\x" }` | `dependency "x": "subdir" "modules\x" holds a backslash — segments are separated by "/"` |
| `"x": { "git": "…", "subdir": "" }` | `dependency "x": "subdir" is empty — omit "subdir" for the package at the repository's root` |
| `"a": { "git": "<r>", "tag": "v1" }, "b": { "git": "<r>.git", "branch": "feat" }` | `dependencies "a" and "b" name one repository (<r>.git) at two refs (tag "v1" and branch "feat") — one repository is one checkout; pin both at one ref` (on the second entry) |
| `"otp": "26"` (any release but the compiler's) | `botopink emits Erlang for OTP 28; "otp" names 26` (on the value) |
| a dependency of the closure whose `"otp"` differs from the project's (or the first pin's) | `"otp" names 29 here, but 28 in <first>/botopink.json — every package of a build pins one OTP release` (on the dependency's value) |

Refusals at resolution time (the compiler and the LSP — and `bpmp install`
where a row names it — located on the project's `dependencies` entry unless a
row says otherwise):

| Situation | Message |
|---|---|
| `{ "workspace": true }` in a project no workspace lists | `"x": { "workspace": true } but <project>/botopink.json is not a member of any workspace — no ancestor botopink.json lists this directory under "workspaces"` |
| `{ "workspace": true }` naming no sibling | `"x": { "workspace": true } names no member of <workspace>/botopink.json (members: a, b, c)` |
| `{ "path": … }` holding no manifest | `"x": path "../x" holds no botopink.json (looked at <abs>/botopink.json)` |
| `{ "path": … }` whose package has another `name` | `"x": path "../y" holds a package named "y" — the dependency key is the import name and must match` |
| `{ "path": … }` pointing at a sibling member | `"x": path "../x" points at the sibling member "x" — use { "workspace": true }` |
| `{ "path": … }` pointing at a workspace | `"x": path "../ws" is a workspace, not a package — depend on one of its members: a, b, c` |
| `{ "git": … }` whose name is a workspace under a root | `"x" is a workspace, not a package — import one of its members: a, b, c` |
| `{ "git": … }` whose name no root carries | `dependency 'x' was not found under any library root` |
| a `files` entry of the resolved dependency that does not exist | `dependency 'x' lists "gone.bp" in ` files `, but <path> does not exist` (located on the dependency's manifest) |
| `bpmp install`: a `subdir` holding no manifest | `"x": subdir "modules/x" holds no botopink.json in <git> at <rev12> (looked at <checkout>/modules/x/botopink.json)` |
| `bpmp install`: a `subdir` holding a workspace | `"x": subdir "modules/ws" is a workspace, not a package — name one of its members' subdirs: modules/ws/a, modules/ws/b` |
| `bpmp install`: a `subdir` holding another package | `"x": subdir "modules/y" holds a package named "y" — the dependency key is the import name and must match` |
| `bpmp install`: a `path` dependency of the package (or of its in-checkout closure) leaving the checkout, by spelling or through a symbolic link | `"y": path "../../../y" leaves the checkout of <git> — a package of a git dependency names by path only packages of its own repository` (on that package's own manifest) |
| `bpmp install`: `botopink.lock` pinning two dependencies on one repository at two commits | `install: botopink.lock pins 'a' and 'b' at two commits of one repository — one repository is one checkout (decision 344)` (`bpmp install --update` re-pins) |
| a host sidecar the resolved dependency does not carry | `dependency 'x' requires "./x.mjs" from module 'x/root', but no such file is in its sources (looked at <src>/sidecars/x.mjs, then <src>/x.mjs)` |

### Host sidecars

A `#[@External.Node("./x.mjs", "f")]` lowers to a relative `require("./x.mjs")`
in the emitted module. The file is the library's, not the consumer's, so
`botopink build` and `botopink test` copy it next to the emitted JS —
`<out>/<name>/x.mjs` for a dependency's module, `<out>/x.mjs` for the project's
own — and rewrite the `require` when the authored path would escape the output
directory. The `.erl` host module of an `#[@External.Erlang("host", "f")]` is
copied the same way.

Which directory a sidecar is copied *from* is the dependency this manifest
resolved, by the rules of the table above — **not** a directory of that name
under the library roots. A `{ "path": … }` dependency outside every root, and a
name two checkouts of one library both declare (which the roots refuse to
resolve, deliberately), are therefore shipped correctly. Inside that directory
the file is looked for under the dependency's own `src`, first as
`<src>/sidecars/<file>` and then as `<src>/<file>`. Only a library the project
does not declare as a dependency — the embedded `std` — is found by name across
the roots.

A sidecar a module requires and the build cannot ship ends the build with a
located error on the `dependencies` entry that named the library. There is no
flag, environment variable or manifest field that reduces it to a warning: a
build that exits 0 having shipped nothing is a program that dies on its first
run instead.

## A workspace (decision 75)

```json
{
  "name": "rakun",
  "version": "0.0.1",
  "description": "The rakun libraries",
  "targets": ["commonJS", "erlang"],
  "workspaces": ["modules/*", "examples/*"]
}
```

A manifest with `"workspaces"` is a workspace: it declares **members** and is
never a package. `npm`'s field name, `npm`'s meaning.

| Field | Meaning |
|---|---|
| `name`, `version`, `description` | As for a package. The name is what a lookup answers with when something imports the umbrella by mistake. |
| `targets` | The default every member inherits when it declares none; a member may only **restrict** it. |
| `otp` | The release every member inherits when it declares none; a member may only repeat it. |
| `workspaces` | The member globs. Two forms: `"<dir>/*"` — every child directory of `<dir>` that holds a `botopink.json` (a child without one is not a member); `"<dir>"` — one directory, which **must** hold a `botopink.json`. Paths are inside the workspace (no `..`, no absolute path, no other `*`). |
| `src`, `files`, `entry`, `dependencies` | **Refused** — a workspace compiles nothing and ships nothing. |

Each member is a package whose `name` is its import name (`from "rakun-web"`).
The runner runs every member — examples included — one row per member, and the
umbrella has no row. A member depends on a sibling with `{ "workspace": true }`
only. Workspaces do not nest.

A member that is a **library** (its module tree is rooted at `root.bp`, not
`main.bp`) and lists no `files` **ships nothing**: `botopink test` inside it
fails, and the runner marks every cell `✗`, with

```text
error: ships nothing: manifest has no "files" — a workspace member that is a library lists every module a consumer may import
 --> modules/rakun-web/botopink.json:2:3
```

An example member (`entry: main.bp`, or `src/main.bp` present) is an
application; nothing is shipped from it by design.

### Refusals

| Manifest | Message |
|---|---|
| a workspace with `files` (or `src`, `entry`, `dependencies`) | `a workspace manifest cannot carry "files" — a workspace declares members, it is not a package; move "files" to the member's own botopink.json` |
| `"workspaces": ["modules/**"]` (or `"*/src"`, `"../x"`, `"/abs"`, `""`) | `workspaces entry "modules/**" is not a supported form — use "<dir>/*" (every child of <dir> holding a botopink.json) or a literal "<dir>" inside the workspace` |
| `"modules/*"` when `modules/` does not exist | `workspaces entry "modules/*": <ws>/modules is not a directory that can be read` |
| `"modules/ghost"` with no manifest there | `workspaces entry "modules/ghost": <ws>/modules/ghost/botopink.json does not exist — a literal entry names a directory holding a botopink.json` |
| a member that is itself a workspace | `"inner" is a member of <ws>/botopink.json and cannot itself be a workspace — workspaces do not nest` (on the member's `workspaces`) |
| two members with one `name` | `member name "dup" is declared twice in <ws>/botopink.json: <a>/botopink.json and <b>/botopink.json` (on the second member's `name`) |
| a member naming another `otp` | `"otp" names 29 here, but 28 in <ws>/botopink.json — every package of a build pins one OTP release` (on the member's value) |
| a member widening `targets` | `"erlang" is not one of the workspace's targets ["commonJS"] (<ws>/botopink.json) — a member may only restrict the workspace's targets` (on the member's entry) |
| a member depending on itself | `"web" cannot depend on itself` |
| a member's `{ "workspace": true }` naming no sibling | `"ghost": { "workspace": true } names no member of <ws>/botopink.json (members: a, b)` |
| a member's `path` to a sibling | `"core": path "../core" points at the sibling member "core" — use { "workspace": true }` |
| a member's `path` to the workspace | `"umbrella": path "../../" points at the workspace itself — a workspace is not a package; depend on one of its members with { "workspace": true } (members: a, b)` |
| `botopink build/check/run/test` in the workspace directory | `<ws>/botopink.json is a workspace, not a package — run this command inside one of its members: a, b, c` |
| two **members** with one `name` in different directories across the library roots (or a member and a package) | `"x" is declared by two libraries: <dirA> and <dirB> — a name resolves to one library; rename one of them` — on both, so neither is used (first-root-wins is what decision 75 retires; two plain packages with one name keep first-root-wins). |

## Refusals common to every manifest

| Manifest | Message |
|---|---|
| not JSON | `botopink.json is not valid JSON` |
| not an object | `botopink.json must be a JSON object` |
| no `name` | `botopink.json has no "name"` |
| `"name": 1` (any string field that is not a string) | `"name" must be a string` |
| `"name": "MyApp"` (a name that does not start with a lowercase letter) | `"name" must start with a lowercase letter — every erlang module atom of the package starts with it` |
| `"name": "bp"` | `"name" cannot be "bp" — it is the compiler's own namespace, the package of a module compiled outside any botopink.json` |
| `"files": "root.bp"` (any array field that is not an array of strings) | `"files" must be an array of strings` · `"files" must be an array of strings — entry 2 is not a string` |

## Where each tool meets the manifest

| Tool | Reads | Path |
|---|---|---|
| `botopink build/check/run/test` | the project's manifest (cwd), the enclosing workspace, each dependency's manifest | `modules/compiler-cli/src/cli/config.zig`, `libs.zig` |
| `botopink-lsp` | the nearest manifest above the open file, the enclosing workspace, each dependency's manifest — refusals are editor diagnostics on the manifest | `modules/language-server/src/project_graph.zig` |
| `botopink-lib-test` | every package and every workspace member under the library roots; `targets`; `files` of a library member | `modules/lib-test-runner/src/discovery.zig` |
| `bpmp` | `dependencies` (to install), `files` (to pack), `botopink`, `requires`; writes `dependencies` entries as `{ "git": … }` | `modules/bpmp/src/manifest.zig`, `dep/spec.zig` |
| the shared model | everything above | `modules/manifest/src/root.zig` |
