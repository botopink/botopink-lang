# modules/test-scratch/

> Path: `modules/test-scratch/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

The `test_scratch` module — **the one way a test spells a path it writes to.**
`std` only; no compiler-core, no manifest.

## Tree

```text
test-scratch/
├── AGENTS.md         ← you are here
└── src/root.zig      ← the whole module (root / path / uri / remove + its own tests)
```

## Why it exists

`zig build test` runs each test binary with its **package directory** as cwd
(`build.zig`, `run_*_tests.setCwd(…)`), so every test in the tree writes into
ONE shared checkout. A scratch path scoped per *test name* but not per *run* is
therefore shared with every other process running the suite — a second
`zig build test` over the same checkout (another worktree's gate, a hand-run
binary, CI and a developer at once). Each test opens by `deleteTree`-ing its own
root, so the second process empties the first one's fixtures mid-test.

Measured on the tree before this module existed (one binary per row, run
directly with its package directory as cwd):

| binary | 1 process | 2 processes | 4 processes |
|---|---|---|---|
| `compiler-cli` (89 tests) | 89/89 | 5/5 trials red | 5/5 trials red, up to 5 failed per process |
| `language-server` (209) | 209/209 | — | 3/3 trials red |
| `lib-test-runner` (48) | 48/48 | — | 3/3 trials red |

It is the same root cause as `botopink test`'s old shared
`.botopinkbuild/test-out/` ([`../compiler-cli/src/cli/test_cmd.zig`](../compiler-cli/src/cli/test_cmd.zig))
and as the comptime runtime's scratch dirs
([`../compiler-core/src/codegen/runtime.zig`](../compiler-core/src/codegen/runtime.zig),
`makeScratchDir`): a fixed path under a shared checkout. Same remedy, same
shape — a per-process segment.

## API

```zig
const test_scratch = @import("test_scratch");

test "…" {
    const io = std.testing.io;
    test_scratch.remove(io, "my-case");            // opening line
    defer test_scratch.remove(io, "my-case");      // and the defer
    const ws = test_scratch.path(io, "my-case/ws");
    try writeFileP(io, test_scratch.path(io, "my-case/ws/botopink.json"), "{}");
}
```

| Function | Answers |
|---|---|
| `root(io)` | `.botopinkbuild/test-scratch/<id>` — `<id>` is 64 random bits (`io.random`) drawn **once per process** |
| `path(io, comptime rel)` | `<root>/<rel>` |
| `uri(io, comptime rel)` | `file://<root>/<rel>` — the same path as the LSP speaks it |
| `remove(io, comptime rel)` | `deleteTree` of `<root>/<rel>`, best effort |

`rel` is **comptime**: it keys a static buffer sized exactly `<root>/<rel>`,
filled once behind an atomic spin-lock (the same shape
`comptime/runtime/persistent_erl.zig` uses — a test binary's tests may run on
several threads, and two of them drawing the root would give one process two
roots). So nothing is allocated, nothing leaks under `std.testing.allocator`,
and the slice is valid for the whole process — it can sit in an array beside
other paths. Two call sites spelling the same `rel` share one instantiation and
therefore one buffer; the bytes are the same either way.

`rel` is also **checked at compile time**: empty, absolute, trailing-separator,
leading-dot, `..`, an empty segment, or a `{`/`}` are each a `@compileError`. A
path that could escape the per-process root would put the shared path back.

## Two rules, both refusals (decision 67)

1. **It is not reachable from production code.** `build.zig` gives this module
   to the TEST modules only (`core_test_mod`, `lsp_test_mod`, `cli_test_mod`,
   the lib-test-runner's and bpmp's test modules). A reference from outside a
   `test` block is analysed by the executable build too, where the module does
   not exist — so it does not compile.
2. **A test may not spell a cwd-anchored `.botopinkbuild` path by hand.**
   [`../../scripts/check-test-scratch.sh`](../../scripts/check-test-scratch.sh)
   scans every `modules/**/*.zig` and refuses a string literal beginning
   `.botopinkbuild` inside a `test` block. `zig build test` depends on it.

Neither has a flag, an environment variable or a skip list. The only exemption
is structural: a literal that does not start at the cwd
(`"…/.botopinkbuild/tmp/scratch.bp"` as fixture *content* under a scratch root,
or a reference to a production constant such as `runtime.TMP_ROOT`) is not a
cwd-anchored path and is not matched.

## Leftovers

A test removes its own subtree on the way out, so what survives a run is an
empty `modules/<pkg>/.botopinkbuild/test-scratch/<id>/` — one per run, and one
per *crashed* run with its fixtures still in it. `zig build clean-tmp` (which
also runs before `zig build test`) reaps them at the same 1-day TTL the
comptime scratch dirs use: a live run's root is minutes old, never a day, so
the reap is safe next to a concurrent `zig build test`.
