#!/usr/bin/env bash
# Test-tooling behaviours of `botopink test` (Front-C C1) that the Zig unit tests
# can't reach because they need the real CLI + commonJS runner:
#   • an empty `test "x" {}` block passes
#   • `--filter` matching MULTIPLE tests runs all of them
#   • `--filter` matching NONE produces a clear `0 passed, 0 failed` and exits 0
#   • a failing `assert cond, "msg"` surfaces the custom message, a failing
#     `try` the error string, each at the package-relative `src/main.bp:<line>`
#     (commonJS, and erlang when `escript` is on PATH)
#   • a mixed pass/fail run still runs every test AND exits non-zero
#   • a run lists every `*.snap.new` snapshot candidate it leaves
#   • the LAST line of a run is its total, `total: <P> passed, <F> failed in
#     <N> module(s)` — never the last module's own summary
#   • a test reads the compiler that runs it from `BOTOPINK_BIN`, unless the
#     caller set the variable
#   • a module's tests are a unit of their own (decision 513): a test reads a
#     private fn and `val` of its module on commonJS, erlang, beam and wasm,
#     the module's `main` is not run, a dependency's tests never run, and
#     `botopink build` writes none
#   • `botopink test` reads a dependency's level B entry with its CODE as
#     `build` does (144 B-60): the first run writes the entry, the next reads
#     it without writing it again (its inode), with the same results, on
#     every target; the package under test is never stored
#
# What `assert cond, "msg"` and `try` mean in the language — an assertion that
# holds does nothing, one that fails aborts naming its message, a `try` on a
# value answers it — is the conformance suite's since 144 B-29 step H
# (`conformance/modules/assert/cells/assert_message_aborts`, `conformance/test/assert_and_try.bp`);
# this script keeps how the runner reports them.
#
# Exit 0 = every behaviour held. Recorded (not asserted here): an arbitrary
# *uncaught* (non-assert) throw → FAIL — pure botopink has no portable
# runtime-throwing construct (`arr[index]` is a compile error, no `@panic`); the
# failing-assert case below already shows the runner catches a thrown assertion
# and reports FAIL rather than crashing. wasm-target lib execution stays
# skipped-unsupported; `botopink
# test --target wasm` runs a module's test unit, a failing assert trapping the
# run (decision 513). See
# front-c-runtime.md C1.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

if [[ -z "${BOTOPINK_SKIP_BUILD:-}" ]]; then
  echo "==> building botopink CLI"
  ( cd "$REPO_ROOT" && zig build )
fi
BP_BIN="$REPO_ROOT/zig-out/bin/botopink"
if [[ ! -x "$BP_BIN" ]]; then
  echo "error: CLI binary not found at $BP_BIN" >&2
  exit 1
fi
if ! command -v node >/dev/null 2>&1; then
  echo "==> SKIPPED (node not on PATH — the commonJS runner is required)"
  exit 0
fi

PASS="$SCRIPT_DIR/test_tooling/pass"
FAIL="$SCRIPT_DIR/test_tooling/fail"

fail() { echo "  ✗ $1" >&2; exit 1; }
# count_tests <output> — the runner prints one `TEST <file>:<line> <name>` line
# per test it runs (there is no `running N tests` banner).
count_tests() { grep -c '^TEST ' <<<"$1" || true; }

# ── empty test + a clean all-pass run ────────────────────────────────────────
echo "==> [pass] botopink test (4 tests incl. an empty body)"
out="$( cd "$PASS" && "$BP_BIN" test --target commonJS )"
echo "$out"
[[ "$(count_tests "$out")" -eq 4 ]] || fail "expected 4 TEST lines, got $(count_tests "$out")"
grep -q "ok   empty body still passes" <<<"$out" || fail "empty test block should pass"
grep -q "4 passed, 0 failed" <<<"$out" || fail "expected all four to pass"

# ── --filter matching MULTIPLE tests ─────────────────────────────────────────
echo "==> [pass] botopink test --filter math (matches two tests)"
out="$( cd "$PASS" && "$BP_BIN" test --target commonJS --filter math )"
echo "$out"
[[ "$(count_tests "$out")" -eq 2 ]] || fail "--filter math should run exactly two tests, ran $(count_tests "$out")"
grep -q "2 passed, 0 failed" <<<"$out" || fail "both filtered tests should pass"

# ── --filter matching NONE → a clear report, exit 0 ──────────────────────────
echo "==> [pass] botopink test --filter zzz_no_such_test (matches none)"
set +e
out="$( cd "$PASS" && "$BP_BIN" test --target commonJS --filter zzz_no_such_test )"
code=$?
set -e
echo "$out"
[[ $code -eq 0 ]] || fail "a no-match filter should still exit 0 (got $code)"
[[ "$(count_tests "$out")" -eq 0 ]] || fail "a no-match filter should run no test"
grep -q "0 passed, 0 failed" <<<"$out" || fail "a no-match filter should report '0 passed, 0 failed'"

# ── failing assert / try surface their message at src/<file>; mixed run exits non-zero
# The FAIL line names the package-relative path (`src/main.bp:<line>`), the
# spelling `@src().file` and every diagnostic use — not the bare `main.bp`.
failrun() { # failrun <target>
  echo "==> [fail] botopink test --target $1 (one pass, a failing assert, a failing try)"
  set +e
  out="$( cd "$FAIL" && "$BP_BIN" test --target "$1" )"
  code=$?
  set -e
  echo "$out"
  [[ $code -ne 0 ]] || fail "$1: a run with a failing test must exit non-zero"
  grep -q "ok   this one passes" <<<"$out" || fail "$1: the passing test should still run"
  grep -qF "FAIL this one fails with a custom message  (double(2) should be five)  at src/main.bp:25" <<<"$out" ||
    fail "$1: the assert's FAIL line should carry its message at src/main.bp:25"
  grep -qF "FAIL t: fails  (went wrong)  at src/main.bp:28" <<<"$out" ||
    fail "$1: the try's FAIL line should carry the error string at src/main.bp:28"
  grep -qF "TEST src/main.bp:20 this one passes" <<<"$out" || fail "$1: the TEST line should name src/main.bp"
  grep -qF "FAIL t: panics  (boom)  at src/main.bp:" <<<"$out" ||
    fail "$1: a panic's FAIL line should carry the plain message, not the raw term"
  grep -q "1 passed, 3 failed" <<<"$out" || fail "$1: expected a 1-pass / 3-fail summary"
  [[ "$(tail -1 <<<"$out")" == "total: 1 passed, 3 failed in 1 module(s)" ]] || fail "$1: the last line should be the run's total, got: $(tail -1 <<<"$out")"
}
failrun commonJS
if command -v escript >/dev/null 2>&1; then failrun erlang; failrun beam; fi

# ── botopink test names every snapshot candidate it leaves ─────────────────────
# The `snap` library writes `<path>.new` for a missing or a mismatched snapshot;
# the run lists each one after the results (stderr under --json). The test
# below writes the candidate itself with std's `io.fs`, so the run needs no
# library.
echo "==> [snapshots] botopink test lists the .snap.new candidates"
SNAPWORK="$(mktemp -d)"
mkdir -p "$SNAPWORK/src"
printf '{ "name": "snapdemo", "version": "0.0.1", "src": "src/" }\n' >"$SNAPWORK/botopink.json"
cat >"$SNAPWORK/src/main.bp" <<'BP'
import {io.fs} from "std";

test "snap: first" {
    try fs.mkdirRecursive("src/__snapshots__/snap");
    try fs.writeText("src/__snapshots__/snap/first.snap.new", "hello");
}
BP
set +e
out="$( cd "$SNAPWORK" && "$BP_BIN" test --target commonJS )"
set -e
echo "$out"
grep -qF "SNAPSHOT CANDIDATES" <<<"$out" || fail "the run should announce its snapshot candidates"
grep -qxF "  src/__snapshots__/snap/first.snap.new" <<<"$out" || fail "the candidate's package-relative path should be listed"
set +e
err="$( cd "$SNAPWORK" && "$BP_BIN" test --target commonJS --json 2>&1 >/dev/null )"
set -e
grep -qxF "  src/__snapshots__/snap/first.snap.new" <<<"$err" || fail "under --json the candidates go to stderr"
rm -rf "$SNAPWORK"

# ── two modules: two module summaries, then ONE total as the last line ───────
MULTI="$SCRIPT_DIR/test_tooling/multi"
for t in commonJS erlang; do
  if [[ $t == erlang ]] && ! command -v escript >/dev/null 2>&1; then continue; fi
  echo "==> [multi] botopink test --target $t (two modules: 2 + 1 tests)"
  out="$( cd "$MULTI" && "$BP_BIN" test --target "$t" )"
  echo "$out"
  grep -qx "2 passed, 0 failed" <<<"$out" || fail "$t: main's own summary is missing"
  grep -qx "1 passed, 0 failed" <<<"$out" || fail "$t: other's own summary is missing"
  [[ "$(tail -1 <<<"$out")" == "total: 3 passed, 0 failed in 2 module(s)" ]] || fail "$t: the last line should be the run's total, got: $(tail -1 <<<"$out")"
done

LIBWORK="$(mktemp -d)"
trap 'rm -rf "$LIBWORK"' EXIT

# ── `botopink test` names its own binary to the tests it runs ────────────────
# A test that builds a fixture project spawns "the compiler running me". It
# reads that from BOTOPINK_BIN, which `botopink test` sets to its own
# executable when the variable is unset; a value the caller set passes through.
echo "==> [env] BOTOPINK_BIN in a test is the running compiler, unless the caller set it"
mkdir -p "$LIBWORK/binprobe/src"
printf '{ "name": "binprobe", "version": "0.0.1", "target": "commonJS", "src": "src/" }\n' >"$LIBWORK/binprobe/botopink.json"
cat >"$LIBWORK/binprobe/src/main.bp" <<'BP'
import {io.env, io.terminal.print} from "std";

test "the compiler names itself" {
    print(env.read("BOTOPINK_BIN") ?? "unset");
}
BP
BP_REAL="$(cd "$(dirname "$BP_BIN")" && pwd -P)/$(basename "$BP_BIN")"
binprobe_targets=(commonJS)
command -v escript >/dev/null 2>&1 && binprobe_targets+=(erlang)
for t in "${binprobe_targets[@]}"; do
  out="$( cd "$LIBWORK/binprobe" && env -u BOTOPINK_BIN "$BP_BIN" test --target "$t" )"
  echo "$out"
  grep -qxF "$BP_REAL" <<<"$out" || fail "$t: with BOTOPINK_BIN unset the test should read the running binary ($BP_REAL)"
  out="$( cd "$LIBWORK/binprobe" && BOTOPINK_BIN=/caller/chose/this "$BP_BIN" test --target "$t" )"
  echo "$out"
  grep -qxF "/caller/chose/this" <<<"$out" || fail "$t: a BOTOPINK_BIN the caller set must pass through untouched"
  ! grep -qxF "$BP_REAL" <<<"$out" || fail "$t: the caller's BOTOPINK_BIN was overwritten"
done

# ── a library ships its erlang host module ───────────────────────────────────
# `#[@external(.Erlang("host:fn($0)"))]` lowers to `host:fn(…)`. `host` is a module
# the library authors in erlang and keeps beside its `.bp` sources; nothing
# copied it into the output, so the call died with `{error,undef}` — only `.mjs`
# sidecars were ever shipped. `libs.shipErlSidecars` is the `.erl` counterpart.
if command -v escript >/dev/null 2>&1; then
  echo "==> [libs] a dependency's erlang host module is shipped into the test output"
  ERLWORK="$(mktemp -d)"
  mkdir -p "$ERLWORK/root/hostlib/src" "$ERLWORK/app/src"
  cat >"$ERLWORK/root/hostlib/botopink.json" <<'JSON'
{ "name": "hostlib", "version": "0.0.1", "src": "src/", "files": ["hostlib.bp"] }
JSON
  cat >"$ERLWORK/root/hostlib/src/hostlib.bp" <<'BP'
import {compiler} from "std";

#[compiler.external(.Erlang("hostlib_native:greet($0)"))]
pub declare fn greet(name: string) -> string;
BP
  cat >"$ERLWORK/root/hostlib/src/hostlib_native.erl" <<'ERL'
-module(hostlib_native).
-export([greet/1]).

greet(Name) -> <<"hello from the host, ", Name/binary>>.
ERL
  cat >"$ERLWORK/app/botopink.json" <<'JSON'
{ "name": "app", "version": "0.0.1", "target": "erlang", "dependencies": { "hostlib": { "git": "https://example.invalid/hostlib.git" } } }
JSON
  cat >"$ERLWORK/app/src/main.bp" <<'BP'
import {greet} from "hostlib";

test "the host module answers" {
  assert greet("world") == "hello from the host, world";
}
BP
  set +e
  out="$( cd "$ERLWORK/app" && BOTOPINK_LIB_ROOTS="$ERLWORK/root" "$BP_BIN" test --target erlang 2>&1 )"
  code=$?
  set -e
  echo "$out"
  rm -rf "$ERLWORK"
  [[ $code -eq 0 ]] || fail "the host-module test must pass (exit $code)"
  grep -q "ok   the host module answers" <<<"$out" || fail "the erlang host module was not reachable"
  ! grep -qF "{error,undef}" <<<"$out" || fail "the host module was not shipped — the call was undefined"
else
  echo "==> SKIPPED: the erlang host-module cell (escript not on PATH)"
fi

# ── a module's tests are a unit of their own (decision 513, 144 B-64) ────────
# A test reads a private fn and a private module-level `val` of its module
# through the production unit's reserved export, on every target; the
# production module's `main` is not run by the test unit; a dependency's own
# tests are never run; and `botopink build` writes no test of the module.
echo "==> [units] a test reads its module's privates on every target; a dependency's tests never run"
UNITWORK="$(mktemp -d)"
mkdir -p "$UNITWORK/app/src" "$UNITWORK/lib/src"
cat >"$UNITWORK/lib/botopink.json" <<'JSON'
{ "name": "unitlib", "version": "0.0.1", "src": "src/", "files": ["lib.bp"] }
JSON
cat >"$UNITWORK/lib/src/lib.bp" <<'BP'
pub fn one() -> i32 {
    return 1;
}

test "the dependency's own test" {
    assert one() == 2, "a dependency's test ran";
}
BP
cat >"$UNITWORK/app/botopink.json" <<'JSON'
{ "name": "unitapp", "version": "0.0.1", "src": "src/", "dependencies": { "unitlib": { "path": "../lib" } } }
JSON
cat >"$UNITWORK/app/src/main.bp" <<'BP'
import {one} from "unitlib";
import {io.terminal.print} from "std";

fn helper(x: i32) -> i32 {
    return x * 2;
}

val secret = 21;

fn main() -> void {
    print("main ran");
}

test "reads a private fn and a private val" {
    assert helper(secret) + one() == 43;
}
BP
for t in commonJS erlang beam wasm; do
  case "$t" in
    erlang|beam) command -v escript >/dev/null 2>&1 || { echo "  (skipped $t: no escript)"; continue; } ;;
    wasm) command -v wasmtime >/dev/null 2>&1 || { echo "  (skipped $t: no wasmtime)"; continue; } ;;
  esac
  set +e
  out="$( cd "$UNITWORK/app" && "$BP_BIN" test --target "$t" 2>&1 )"
  code=$?
  set -e
  echo "$out"
  [[ $code -eq 0 ]] || { rm -rf "$UNITWORK"; fail "$t: the test reading the module's privates must pass (exit $code)"; }
  grep -q "ok   reads a private fn and a private val" <<<"$out" || { rm -rf "$UNITWORK"; fail "$t: the private fn and val were not reached"; }
  ! grep -q "main ran" <<<"$out" || { rm -rf "$UNITWORK"; fail "$t: the test unit ran the production module's main"; }
  ! grep -q "dependency's own test" <<<"$out" || { rm -rf "$UNITWORK"; fail "$t: a dependency's test ran"; }
  [[ "$(tail -1 <<<"$out")" == "total: 1 passed, 0 failed in 1 module(s)" ]] || { rm -rf "$UNITWORK"; fail "$t: expected one module with one test, got: $(tail -1 <<<"$out")"; }
  # Level B (144 B-60): that run wrote unitlib's entry with its CODE (a
  # dependency's unit is the same bytes under `test`, decision 513); the next
  # run reads it — not written again — and its results are the same.
  lib_entry="$(find "$UNITWORK" -path "*/.botopinkbuild/analysis/$t/unitlib.bpa" | head -1)"
  [[ -n "$lib_entry" ]] || { rm -rf "$UNITWORK"; fail "$t: \`botopink test\` wrote no level B entry for its dependency"; }
  ! find "$UNITWORK" -path "*/.botopinkbuild/analysis/$t/unitapp.bpa" | grep -q . || { rm -rf "$UNITWORK"; fail "$t: the package under test was stored"; }
  entry_inode="$(stat -c %i "$lib_entry" 2>/dev/null || stat -f %i "$lib_entry")"
  # Pinned by a link of our own: a rewrite can never land on the freed inode
  # (ext4 reuses one at once) and read as "not written again".
  ln -f "$lib_entry" "$UNITWORK/.pin-$t"
  set +e
  again="$( cd "$UNITWORK/app" && "$BP_BIN" test --target "$t" 2>&1 )"
  code=$?
  set -e
  [[ $code -eq 0 ]] || { echo "$again"; rm -rf "$UNITWORK"; fail "$t: the test run reading the dependency's entry must pass (exit $code)"; }
  [[ "$(stat -c %i "$lib_entry" 2>/dev/null || stat -f %i "$lib_entry")" == "$entry_inode" ]] || { rm -rf "$UNITWORK"; fail "$t: the second test run wrote the dependency's entry again (its CODE was not read)"; }
  [[ "$(grep -E '^(ok|FAIL|total:)' <<<"$out")" == "$(grep -E '^(ok|FAIL|total:)' <<<"$again")" ]] || { echo "$again"; rm -rf "$UNITWORK"; fail "$t: the results differ once the dependency's CODE is read"; }
done
( cd "$UNITWORK/app" && "$BP_BIN" build --target commonJS --out out >/dev/null )
! grep -rq "__bp_test_" "$UNITWORK/app/out" || { rm -rf "$UNITWORK"; fail "botopink build wrote a test of the module"; }
rm -rf "$UNITWORK"

echo "==> test-tooling behaviours: OK"
