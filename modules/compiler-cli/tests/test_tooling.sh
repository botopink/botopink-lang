#!/usr/bin/env bash
# Test-tooling behaviours of `botopink test` (Front-C C1) that the Zig unit tests
# can't reach because they need the real CLI + commonJS runner:
#   • an empty `test "x" {}` block passes
#   • `--filter` matching MULTIPLE tests runs all of them
#   • `--filter` matching NONE produces a clear `0 passed, 0 failed` and exits 0
#   • a failing `assert cond, "msg"` surfaces the custom message
#   • a mixed pass/fail run still runs every test AND exits non-zero
#   • botopink-lib-test compiles a library with no test block (`–` when it
#     compiles, `✗` when it does not)
#
# Exit 0 = every behaviour held. Recorded (not asserted here): an arbitrary
# *uncaught* (non-assert) throw → FAIL — pure botopink has no portable
# runtime-throwing construct (`arr[index]` is a compile error, no `@panic`); the
# failing-assert case below already shows the runner catches a thrown assertion
# and reports FAIL rather than crashing. wasm-target lib execution stays
# skipped-unsupported (lib-test-runner runs commonJS/erlang only). See
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

# ── failing assert surfaces its message; mixed run exits non-zero ────────────
echo "==> [fail] botopink test (one pass, one failing assert with a message)"
set +e
out="$( cd "$FAIL" && "$BP_BIN" test --target commonJS )"
code=$?
set -e
echo "$out"
[[ $code -ne 0 ]] || fail "a run with a failing test must exit non-zero"
grep -q "ok   this one passes" <<<"$out" || fail "the passing test should still run"
grep -q "double(2) should be five" <<<"$out" || fail "the custom assert message should surface"
grep -q "1 passed, 1 failed" <<<"$out" || fail "expected a 1-pass / 1-fail summary"

# ── botopink-lib-test compiles a library that has no test block ──────────────
echo "==> [libs] a test-less library is still compiled: – when it compiles, ✗ when it does not"
LIB_TEST_BIN="$REPO_ROOT/zig-out/bin/botopink-lib-test"
[[ -x "$LIB_TEST_BIN" ]] || fail "botopink-lib-test not found at $LIB_TEST_BIN"
LIBWORK="$(mktemp -d)"
trap 'rm -rf "$LIBWORK"' EXIT
mkdir -p "$LIBWORK/root/quietok/src" "$LIBWORK/root/quietbad/src"
for lib in quietok quietbad; do
  printf '{ "name": "%s", "version": "0.0.1", "src": "src/", "files": ["%s.bp"] }\n' "$lib" "$lib" >"$LIBWORK/root/$lib/botopink.json"
  printf 'pub mod %s;\n' "$lib" >"$LIBWORK/root/$lib/src/root.bp"
done
printf 'pub fn quiet() -> i32 {\n    return 1;\n}\n' >"$LIBWORK/root/quietok/src/quietok.bp"
printf 'pub fn quiet() -> i32 {\n    return (1;\n}\n' >"$LIBWORK/root/quietbad/src/quietbad.bp"
libtest() { # libtest <lib> — JSON run from a directory with no walk-up roots
  set +e
  out="$( cd "$LIBWORK" && "$LIB_TEST_BIN" --json --bin "$BP_BIN" --lib-root "$LIBWORK/root" --target commonJS --lib "$1" 2>&1 )"
  code=$?
  set -e
  echo "$out"
}
libtest quietok
[[ $code -eq 0 ]] || fail "a test-less library that compiles must not fail test-libs (exit $code)"
grep -q '"lib":"quietok","target":"commonJS","status":"no_tests"' <<<"$out" || fail "quietok should be no_tests"
[[ -d "$LIBWORK/root/quietok/.botopinkbuild/lib-test-build/commonJS" ]] || fail "quietok was not compiled"
libtest quietbad
[[ $code -eq 1 ]] || fail "a test-less library that does not compile must fail test-libs (exit $code)"
grep -q '"lib":"quietbad","target":"commonJS","status":"fail"' <<<"$out" || fail "quietbad should be fail"
grep -q 'quietbad.bp' <<<"$out" || fail "the compile diagnostic should name quietbad.bp"

# ── a library ships its erlang host module ───────────────────────────────────
# `#[@External.Erlang("host", "fn")]` lowers to `host:fn(…)`. `host` is a module
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
#[@External.Erlang("hostlib_native", "greet")]
pub declare fn greet(name: string) -> string;
BP
  cat >"$ERLWORK/root/hostlib/src/hostlib_native.erl" <<'ERL'
-module(hostlib_native).
-export([greet/1]).

greet(Name) -> <<"hello from the host, ", Name/binary>>.
ERL
  cat >"$ERLWORK/app/botopink.json" <<'JSON'
{ "name": "app", "version": "0.0.1", "target": "erlang", "dependencies": ["hostlib"] }
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

echo "==> test-tooling behaviours: OK"
