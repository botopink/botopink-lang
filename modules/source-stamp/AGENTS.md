# modules/source-stamp/

> Path: `modules/source-stamp/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

The `source_stamp` module — **a library run refuses a stale compiler binary.**
`std` only; no compiler-core, no manifest.

## Tree

```text
source-stamp/
├── AGENTS.md         ← you are here
└── src/root.zig      ← hash / partitionHashes / checkFresh / render + its own tests
```

## Why it exists

Library threads measure against a compiler binary they rebuilt by hand. A
binary one commit behind its checkout compiles the library with the previous
compiler and reports the previous compiler's reds — a measurement nobody can
tell from a real one.

## The contract

- `build.zig` imports this file at **configure** time, hashes the checkout
  (`hash`) and embeds the hex digest and the checkout's absolute path in
  `botopink` and `botopink-lib-test` as the `build_stamp` options module
  (`source_root`, `source_hash`). The hash only changes when the bytes change,
  and then `zig build` rebuilds both binaries.
- `botopink test` (`compiler-cli/src/cli/test_cmd.zig`) and `botopink-lib-test`
  (`lib-test-runner/src/main.zig`) call `checkFresh` before anything else: when
  `source_root` still holds a checkout (`build.zig`) and its hash differs from
  `source_hash`, they print `render`'s refusal — the checkout, both hashes, and
  `run zig build there first` — and exit 1. An installed binary built on another
  machine has no checkout at `source_root` and is never refused.
- **A content hash, not a modification time.** `zig build` caches by content:
  touching a source rebuilds nothing, so the installed binary keeps its old
  mtime, and "binary older than a source" would refuse a current binary with no
  command that fixes it.
- **The file set** (`ROOTS`, `SKIP_DIRS`): `build.zig`, the `src/` trees of
  compiler-cli, compiler-core, manifest, lib-test-runner and this module,
  `modules/wasm3`, and `libs/` — every regular file except `*.md`, skipping
  hidden directories and `tests`, `test`, `snapshots`, `out`, `zig-out`,
  `node_modules`. Sorted, each hashed as `<path> NUL <bytes> NUL`.

- **By backend** (`partitionHashes`, `partitionHash`, `PARTITION`, `TARGETS`):
  the same file set hashed once per target, each file read once — the shared
  sources and the ones `modules/compiler-core/src/codegen/backend-partition.txt`
  lists under that target (decision 249 of 1.0.11-beta), a listed file of
  another backend left out. `build.zig` embeds them as
  `build_stamp.partition_hash_<target>`: the compiler's part of the code
  cache's closure key (decision 509 (3), `compiler-cli/src/cli/code_cache.zig`
  `compilerKey`).

There is no flag or environment variable that skips the check (decision 67).

## Tests

`zig build test` runs `src/root.zig`'s tests: the hash moves with a source's
bytes and not with a skipped tree, a document or a hidden directory;
`checkFresh` answers null for agreeing hashes and for a missing checkout, and a
`Stale` once a source moved; a backend's file moves its target's partition hash
alone, a shared file every one.
