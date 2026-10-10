# test-shard

> Path: `modules/test-shard/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

The test runner of the compiler-core suite. Not a package with a module of its
own: `build.zig` hands `runner.zig` to `b.addTest(.{ .test_runner = … })` for
`core_tests`, and runs that one binary as `-Dtest-shards` processes side by side
(default: CPUs, at most 8).

## Tree

```text
test-shard/
├── AGENTS.md    ← you are here
└── runner.zig   ← zig 0.16's default test runner, restricted to one shard
```

## Contract

- **`BOTOPINK_TEST_SHARD=<i>/<n>`** selects the tests whose index in
  `builtin.test_functions` is `i` modulo `n`. Unset, the shard is `0/1` — every
  test, the default runner's behaviour. A malformed value panics rather than
  running the whole suite `n` times. `build.zig` sets `0/n … (n-1)/n` on the `n`
  run steps, so every test runs exactly once over them: the build summary's
  `N/N tests passed` is the unsharded count (2426 at `82e32e36`, as before).
- **Everything else is the default runner's.** Under the build runner
  (`--listen=-`) it answers `query_test_metadata` with the shard's names and
  maps `run_test <k>` to the shard's k-th test, so a failure, a leak, a test
  that logs at `err` and a timeout are reported per test, by name, exactly as
  before; run by hand, it prints the default terminal report for its shard.
  `--seed` seeds `std.testing.random_seed`. Fuzzing is not carried (no test here
  uses it).
- **Why shards are safe here.** The suite already runs as several concurrent
  processes over one checkout (two gates, or a gate and an editor): every test
  path under `.botopinkbuild` comes from `test_scratch`, whose root is per
  process ([`../test-scratch/AGENTS.md`](../test-scratch/AGENTS.md)), the
  runtime cache is content-keyed and written by rename, and each shard has its
  own persistent `erl`. A test that needed another test to have run first would
  red under the shards — none does (the full suite is green at 1 and at 8 shards).
- **Why it pays.** The default runner is serial inside one process, and most of
  this suite's time is a snapshot's RUN LOG waiting on the `node` / `erl` /
  `wasmtime` it spawns — ≈ 1.9 CPUs used of 16 from a cold runtime cache. The
  numbers are in the meta workspace's
  `specs/1.0.10-beta/00-compiler-carry-over/25-gate-perf/README.md` § Measurements.

## Commands

```bash
zig build test                    # compiler-core as min(CPUs, 8) shards, the other suites as before
zig build test -Dtest-shards=1    # one process — the pre-shard run
# one shard by hand, from modules/compiler-core (the binary is .zig-cache/o/<hash>/test):
BOTOPINK_TEST_SHARD=3/8 ../../.zig-cache/o/<hash>/test
```

`-Dtest-filter` still filters at compile time; the shards partition what is left.
