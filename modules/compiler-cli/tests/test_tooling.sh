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
  grep -qF "FAIL this one fails with a custom message  (double(2) should be five)  at src/main.bp:22" <<<"$out" ||
    fail "$1: the assert's FAIL line should carry its message at src/main.bp:22"
  grep -qF "FAIL t: fails  (went wrong)  at src/main.bp:25" <<<"$out" ||
    fail "$1: the try's FAIL line should carry the error string at src/main.bp:25"
  grep -qF "TEST src/main.bp:17 this one passes" <<<"$out" || fail "$1: the TEST line should name src/main.bp"
  grep -q "1 passed, 2 failed" <<<"$out" || fail "$1: expected a 1-pass / 2-fail summary"
  [[ "$(tail -1 <<<"$out")" == "total: 1 passed, 2 failed in 1 module(s)" ]] || fail "$1: the last line should be the run's total, got: $(tail -1 <<<"$out")"
}
failrun commonJS
if command -v escript >/dev/null 2>&1; then failrun erlang; fi

# ── botopink test names every snapshot candidate it leaves ─────────────────────
# `testing.snapshots` writes `<path>.new` for a missing or a mismatched snapshot;
# the run lists each one after the results (stderr under --json).
echo "==> [snapshots] botopink test lists the .snap.new candidates"
SNAPWORK="$(mktemp -d)"
mkdir -p "$SNAPWORK/src"
printf '{ "name": "snapdemo", "version": "0.0.1", "src": "src/" }\n' >"$SNAPWORK/botopink.json"
cat >"$SNAPWORK/src/main.bp" <<'BP'
import {testing.snapshots} from "std";

test "snap: first" {
    try snapshots.assertText(@src(), "hello");
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
# The compile's output is this run's own directory (`<target>/<id>`), removed
# when the cell ends — two gates over one checkout never share it.
[[ -z "$(ls -A "$LIBWORK/root/quietok/.botopinkbuild/lib-test-build/commonJS")" ]] || fail "the compile-only cell left its per-run output behind"
libtest quietbad
[[ $code -eq 1 ]] || fail "a test-less library that does not compile must fail test-libs (exit $code)"
grep -q '"lib":"quietbad","target":"commonJS","status":"fail"' <<<"$out" || fail "quietbad should be fail"
grep -q 'quietbad.bp' <<<"$out" || fail "the compile diagnostic should name quietbad.bp"

# ── botopink-lib-test runs cells in parallel and prints them as --jobs 1 does ─
# The pool changes when a cell runs, never what is printed: every cell is
# emitted in discovery order by one thread, from the child's captured output.
echo "==> [libs] --jobs 4 prints, byte for byte, what --jobs 1 prints"
jobsrun() { # jobsrun <n> — every lib of the work root, both targets, merged streams
  set +e
  ( cd "$LIBWORK" && "$LIB_TEST_BIN" --json --bin "$BP_BIN" --lib-root "$LIBWORK/root" --jobs "$1" 2>&1 ) |
    sed -E 's/ in [0-9.]+m?s/ in <t>/'
  set -e
}
serial="$(jobsrun 1)"
pooled="$(jobsrun 4)"
[[ -n "$serial" ]] || fail "the serial run printed nothing"
[[ "$serial" == "$pooled" ]] || { diff <(echo "$serial") <(echo "$pooled"); fail "--jobs 4 printed something --jobs 1 did not"; }

# ── a known-red line is a measurement of one library commit ─────────────────
# `scripts/test-libs.sh` reads `<lib> <target> <commit> <owner> <reason…>`: the
# cell is a known red only while the library's checkout is at `<commit>`; once
# the library moves, the line is stale and fails the run, red or green.
echo "==> [libs] a known-red line pins the library commit it measured; a moved library fails it"
TEST_LIBS="$REPO_ROOT/scripts/test-libs.sh"
gitq() { git -C "$LIBWORK/root/quietbad" -c user.email=t@t -c user.name=t "$@" >/dev/null; }
gitq init -q
gitq add -A
gitq commit -q -m one
pin="$(git -C "$LIBWORK/root/quietbad" rev-parse HEAD)"
KNOWN="$LIBWORK/known-red.txt"
redrun() { # redrun — the wrapper over quietbad·commonJS, the known-red list at $KNOWN
  set +e
  out="$( BOTOPINK_KNOWN_RED_LIBS="$KNOWN" bash "$TEST_LIBS" --lib-root "$LIBWORK/root" --lib quietbad --target commonJS 2>&1 )"
  code=$?
  set -e
  echo "$out"
}
printf 'quietbad commonJS %s probe-front does not parse\n' "${pin:0:12}" >"$KNOWN"
redrun
[[ $code -eq 0 ]] || fail "a known red at its pinned commit must not fail the run (exit $code)"
grep -q "quietbad · commonJS: known red — probe-front" <<<"$out" || fail "the cell should read as a known red"
printf 'quietbad commonJS probe-front does not parse\n' >"$KNOWN"
redrun
[[ $code -eq 1 ]] || fail "a known-red line that names no commit must fail the run (exit $code)"
grep -q "names no library commit" <<<"$out" || fail "the refusal should say the line names no commit"
printf 'quietbad commonJS %s probe-front does not parse\n' "${pin:0:12}" >"$KNOWN"
printf '// moved\n' >>"$LIBWORK/root/quietbad/src/root.bp"
gitq commit -q -am two
redrun
[[ $code -eq 1 ]] || fail "a known-red line whose library moved must fail the run (exit $code)"
grep -q "known-red line stale — pinned at ${pin:0:12}, but the library is at" <<<"$out" || fail "the refusal should name both commits"

# ── a workspace document that quotes the tool is checked against it ─────────
echo "==> [libs] a workspace AGENTS.md quoting a stale member list fails the run"
mkdir -p "$LIBWORK/ws/umbrella/modules/um-core/src" "$LIBWORK/ws/umbrella/modules/um-extra/src"
printf '{ "name": "umbrella", "workspaces": ["modules/*"] }\n' >"$LIBWORK/ws/umbrella/botopink.json"
for m in um-core um-extra; do
  printf '{ "name": "%s", "version": "0.0.1", "src": "src/", "files": ["um.bp"] }\n' "$m" >"$LIBWORK/ws/umbrella/modules/$m/botopink.json"
  printf 'pub mod um;\n' >"$LIBWORK/ws/umbrella/modules/$m/src/root.bp"
  printf 'pub fn one() -> i32 {\n    return 1;\n}\n' >"$LIBWORK/ws/umbrella/modules/$m/src/um.bp"
done
wsrun() {
  set +e
  out="$( cd "$LIBWORK" && "$LIB_TEST_BIN" --bin "$BP_BIN" --lib-root "$LIBWORK/ws" --target commonJS 2>&1 )"
  code=$?
  set -e
  echo "$out"
}
printf 'The refusal: `run this command inside one of its members: um-core,\num-extra`.\n' >"$LIBWORK/ws/umbrella/AGENTS.md"
wsrun
[[ $code -eq 0 ]] || fail "a quote that agrees with the tool must not fail the run (exit $code)"
printf 'The refusal: `run this command inside one of its members: um-core`.\n' >"$LIBWORK/ws/umbrella/AGENTS.md"
wsrun
[[ $code -eq 1 ]] || fail "a quote that dropped a member must fail the run (exit $code)"
grep -q "umbrella/AGENTS.md:1: the workspace refusal is quoted with the members \`um-core\`, but the tool prints \`um-core, um-extra\`" <<<"$out" ||
  fail "the refusal should name the file, the quote and the tool's list"

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

echo "==> test-tooling behaviours: OK"
