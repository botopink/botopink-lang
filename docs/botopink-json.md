# `botopink.json` — project / library manifest

Every botopink project or library carries a `botopink.json` at its root. The
compiler reads it to find source files and declared dependencies; bpmp (the
package manager) reads it to resolve dependency versions and a minimum
compiler constraint. All unknown fields are ignored by both — additions stay
backwards-compatible.

## Schema

```jsonc
{
  // ── compiler-facing ────────────────────────────────────────────────────────
  "name":         "myapp",            // string,  required for a project
  "version":      "0.1.0",            // string,  recommended (semver)
  "description":  "…",                // string,  optional
  "target":       "commonJS",         // string,  optional   ("commonJS"|"erlang"|"beam"|"wasm")
  "targets":      ["commonJS"],       // []string,optional   — per-lib supported-target whitelist
                                      //                       (botopink-lib-test skip filter; absent = all)
  "src":          "src/",             // string,  default "src/"
  "files":        ["root.bp"],        // []string  — libs only (entry modules exposed to consumers)
  "entry":        "src/main.bp",      // string,  projects only
  "dependencies": ["erika"],          // []string  — name-only; compiler resolves through root list

  // ── bpmp-facing (introduced v0.beta.18; optional, compiler ignores) ────────
  "botopink":     ">=0.0.1",          // string,  minimum compiler tag (SemVer constraint)
  "requires":     {                   // {string: string} — per-dep version constraint
    "erika":     "^0.0.1",
    "jhonstart": "0.1.0",
    "onze":      "*"
  }
}
```

## Field reference

### Compiler-facing (always read)

| Field          | Type       | Default   | Used by                                                    |
| -------------- | ---------- | --------- | ---------------------------------------------------------- |
| `name`         | string     | (req)     | project identity, default tarball name                     |
| `version`      | string     | —         | informational; bpmp pack stamps it into the artifact name  |
| `description`  | string     | —         | informational                                              |
| `target`       | string     | `commonJS` | default codegen target (overridable per-command)          |
| `targets`      | []string   | —         | **libs only** — `botopink-lib-test` per-lib supported-target whitelist; absent = run every requested target (historic behaviour). Used by commonJS-only libs (`onze`, `emilia`) so the matrix reports `~` for erlang/beam/wasm instead of `✗`. |
| `src`          | string     | `src/`    | directory under which the loader walks for sources         |
| `files`        | []string   | `[]`      | **libs only** — entry modules exposed to consumers         |
| `entry`        | string     | —         | **projects only** — main module path                       |
| `dependencies` | []string   | `[]`      | external libs the compiler resolves via the root list      |

### bpmp-facing (optional)

| Field      | Type            | Used by                                                          |
| ---------- | --------------- | ---------------------------------------------------------------- |
| `botopink` | string          | minimum compiler tag (SemVer constraint, e.g. `>=0.0.1`, `^0.1`) |
| `requires` | {string,string} | dependency version constraints (`name → constraint`)             |

Both `botopink` and `requires` are **optional**. With no `requires`, bpmp
treats every name in `dependencies` as `"*"` and refuses to install without
an explicit version unless `--allow-unlocked` is passed.

The compiler **never** parses `botopink` or `requires` — they are purely
deployment metadata for bpmp. A user without bpmp can compile a project as
long as `dependencies` resolves through the root list (vendored under
`libs/` or `repository/`, or surfaced via `BOTOPINK_LIB_ROOTS`).

### SemVer constraints accepted by bpmp

```text
constraint := "*"                        // any version
            | exact_version              // "0.1.0"  → exactly 0.1.0
            | "^" version                // "^0.1.0" → >=0.1.0, <0.2.0   (0.x: minor bumps)
            | "~" version                // "~0.1.0" → >=0.1.0, <0.2.0
            | ">=" version               // ">=0.1.0"
```

No backtracking — bpmp picks the **highest tag on the project's GitHub
Releases page satisfying the constraint**. Two packages disagreeing on a
common transitive dep produce a conflict report with both edges named; the
user pins manually in `requires`.

## `BOTOPINK_LIB_ROOTS` — env hook

`BOTOPINK_LIB_ROOTS` extends the compiler's dependency root list without
symlinking. Entries are colon-separated on POSIX, semicolon-separated on
Windows (matching `PATH`). When set, env entries are prepended to the
walk-up roots and de-duplicated first-occurrence-wins.

```bash
BOTOPINK_LIB_ROOTS=/home/u/.bpmp/packages:/opt/site-libs botopink build
```

Behaviour:

- **Unset / empty value** — byte-identical to the legacy walk-up resolver.
- **Non-existent entry** — silently dropped. A typo must not break a build
  that does not need the missing root.
- **Empty entries** (`a::b` or trailing `:`) — dropped.
- **Relative entry** — resolved against the process cwd.
- **Duplicate of a walk-up root** — env copy wins, kept first.

The same hook is honoured by `botopink` (CLI), the language server
(`botopink-lsp`), and the lib-test runner (`botopink-lib-test`) so all three
see the same roots. bpmp uses it to point each command at its package store
(`$BPMP_HOME/packages/<name>/versions/<v>`).

## Examples

### Minimal project

```jsonc
{
  "name": "hello",
  "version": "0.1.0",
  "entry": "src/main.bp"
}
```

### Library exporting two modules

```jsonc
{
  "name":  "rakun",
  "version": "0.0.1",
  "files": ["rakun.bp", "http.bp"]
}
```

### Project depending on two libs, pinned via bpmp

```jsonc
{
  "name":  "myapp",
  "version": "0.2.0",
  "entry": "src/main.bp",
  "dependencies": ["erika", "rakun"],
  "botopink": "^0.1",
  "requires": {
    "erika": "^0.0.3",
    "rakun": ">=0.1.0"
  }
}
```

## See also

- [`compiler-cli`](../modules/compiler-cli/AGENTS.md) — env contract details
- [`language-server`](../modules/language-server/AGENTS.md) — LSP root mirror
- [`lib-test-runner`](../modules/lib-test-runner/AGENTS.md) — runner root mirror
