#!/usr/bin/env bash
# Test-tooling behaviours of `botopink test` (Front-C C1) that the Zig unit tests
# can't reach because they need the real CLI + commonJS runner:
#   • an empty `test "x" {}` block passes
#   • `--filter` matching MULTIPLE tests runs all of them
#   • `--filter` matching NONE produces a clear report and exits 0
#   • a failing `assert cond, "msg"` surfaces the custom message
#   • a mixed pass/fail run still runs every test AND exits non-zero
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

# ── empty test + a clean all-pass run ────────────────────────────────────────
echo "==> [pass] botopink test (4 tests incl. an empty body)"
out="$( cd "$PASS" && "$BP_BIN" test --target commonJS )"
echo "$out"
grep -q "running 4 tests" <<<"$out" || fail "expected 'running 4 tests'"
grep -q "ok   empty body still passes" <<<"$out" || fail "empty test block should pass"
grep -q "4 passed, 0 failed" <<<"$out" || fail "expected all four to pass"

# ── --filter matching MULTIPLE tests ─────────────────────────────────────────
echo "==> [pass] botopink test --filter math (matches two tests)"
out="$( cd "$PASS" && "$BP_BIN" test --target commonJS --filter math )"
echo "$out"
grep -q "running 2 tests" <<<"$out" || fail "--filter math should run exactly two tests"
grep -q "2 passed, 0 failed" <<<"$out" || fail "both filtered tests should pass"

# ── --filter matching NONE → a clear report, exit 0 ──────────────────────────
echo "==> [pass] botopink test --filter zzz_no_such_test (matches none)"
set +e
out="$( cd "$PASS" && "$BP_BIN" test --target commonJS --filter zzz_no_such_test )"
code=$?
set -e
echo "$out"
[[ $code -eq 0 ]] || fail "a no-match filter should still exit 0 (got $code)"
grep -q "running 0 tests" <<<"$out" || fail "a no-match filter should report 'running 0 tests'"

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

echo "==> test-tooling behaviours: OK"
