#!/usr/bin/env bash
# The CLI command contract, end to end (specs/1.0.2-beta/02-cli-gate,
# command-contract.md rows C1–C13). Each row builds a throwaway project, runs
# the real `botopink` binary against it and asserts the exit code, the output
# and what is (or is not) on disk. The flag-parser rows (C8, C10–C12, C14) also
# have unit tests in `src/main.zig`; they are repeated here against the binary.
# One row beyond C1–C13 pins that `build` does not execute the program it
# compiles (no runtime spawn, no runtime-cache entry — 1.0.4-beta cli-residuals).
#
# Every assertion is a hard assert. A row that needs a runtime which is absent
# (node for `botopink test`, a non-root user for the undeletable-directory row)
# is skipped by name — never silently.
#
# Exit 0 = every reachable row held.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# BOTOPINK_BIN points the script at another binary (e.g. one built from the
# commit before a fix, to prove a row reds there); it implies no build.
if [[ -z "${BOTOPINK_SKIP_BUILD:-}" && -z "${BOTOPINK_BIN:-}" ]]; then
  echo "==> building botopink CLI"
  ( cd "$REPO_ROOT" && zig build )
fi
BP="${BOTOPINK_BIN:-$REPO_ROOT/zig-out/bin/botopink}"
if [[ ! -x "$BP" ]]; then
  echo "error: CLI binary not found at $BP" >&2
  exit 1
fi

WORK="$(mktemp -d "${TMPDIR:-/tmp}/botopink-cli-contract.XXXXXX")"
cleanup() { chmod -R u+w "$WORK" 2>/dev/null || true; rm -rf "$WORK"; }
trap cleanup EXIT

failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }
ok() { echo "  ✓ $*"; }
skip() { echo "  ~ SKIPPED: $*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# run <dir> <args…> — runs the CLI in <dir>, captures combined output in $OUT
# and the exit code in $CODE (never aborts the script).
run() {
  local dir="$1"; shift
  set +e
  OUT="$(cd "$dir" && "$BP" "$@" 2>&1)"
  CODE=$?
  set -e
}

expect_code() { # <want> <label>
  if [[ "$CODE" -eq "$1" ]]; then ok "$2 (exit $CODE)"; else fail "$2: expected exit $1, got $CODE"; echo "$OUT" | sed 's/^/      /' >&2; fi
}
expect_out() { # <fixed-string> <label>
  if grep -qF -- "$1" <<<"$OUT"; then ok "$2"; else fail "$2: output lacks '$1'"; echo "$OUT" | sed 's/^/      /' >&2; fi
}
expect_no_out() { # <fixed-string> <label>
  if grep -qF -- "$1" <<<"$OUT"; then fail "$2: output unexpectedly has '$1'"; else ok "$2"; fi
}

# project <name> [target] — a fresh project directory with a botopink.json.
project() {
  local dir="$WORK/$1"
  rm -rf "$dir"; mkdir -p "$dir/src"
  printf '{ "name": "%s", "version": "0.1.0", "target": "%s" }\n' "$1" "${2:-commonJS}" >"$dir/botopink.json"
  echo "$dir"
}

MAIN_OK='pub fn main() {
    print("hello");
}
'
BROKEN='pub fn f() {
    noSuchFunction();
}
'

# ── C1 — build fails, naming the module that produced no artifact ────────────
echo "==> C1 build exits 1 after a module fails to type-check"
P="$(project c1)"
printf 'pub mod broken;\n\n%s' "$MAIN_OK" >"$P/src/main.bp"
printf '%s' "$BROKEN" >"$P/src/broken.bp"
run "$P" build
expect_code 1 "build"
expect_out "failed to compile: broken" "names the dropped module"
expect_out "src/broken.bp:2:5" "locates the diagnostic"
expect_out "unbound variable 'noSuchFunction'" "renders the type error"

# ── C2 — no stale artifact survives a failed build ───────────────────────────
echo "==> C2 a failed rebuild leaves no stale artifact for run"
P="$(project c2)"
printf 'pub fn main() {\n    print("stale build v1");\n}\n' >"$P/src/main.bp"
run "$P" build
expect_code 0 "v1 build"
printf 'pub fn main() {\n    noSuchFunction();\n}\n' >"$P/src/main.bp"
run "$P" build
expect_code 1 "broken rebuild"
[[ ! -e "$P/out/main.js" ]] && ok "out/main.js removed" || fail "out/main.js from v1 survived the failed build"
run "$P" run
expect_code 1 "run after a failed build"
expect_no_out "stale build v1" "run does not execute the stale artifact"

# ── build does not execute the program it compiles ───────────────────────────
echo "==> build emits without running the program (no runtime spawn, no runtime cache)"
SHIMS="$WORK/shims"; SPAWNED="$WORK/spawned.log"
mkdir -p "$SHIMS"; : >"$SPAWNED"
for tool in node erl erlc escript wasmtime; do
  printf '#!/bin/sh\necho "%s $*" >>"%s"\nexit 1\n' "$tool" "$SPAWNED" >"$SHIMS/$tool"
  chmod +x "$SHIMS/$tool"
done
for target in commonJS erlang beam wasm; do
  P="$(project exec-$target "$target")"
  printf 'pub fn main() {\n    print("side effect at build time");\n}\n' >"$P/src/main.bp"
  # With the real runtimes on PATH: nothing is executed, so nothing is cached.
  run "$P" build
  expect_code 0 "build --target $target"
  [[ ! -e "$P/.botopinkbuild/runtime-cache" ]] && ok "$target: no runtime-cache entry" || fail "$target: build left .botopinkbuild/runtime-cache ($(ls "$P/.botopinkbuild/runtime-cache" | head -1))"
  # With recording shims first on PATH: no runtime is spawned at all.
  rm -rf "$P/out" "$P/.botopinkbuild"
  set +e
  OUT="$(cd "$P" && PATH="$SHIMS:$PATH" "$BP" build 2>&1)"
  CODE=$?
  set -e
  expect_code 0 "build --target $target with runtime shims on PATH"
done
[[ ! -s "$SPAWNED" ]] && ok "no node/erl/erlc/escript/wasmtime spawned by build" || fail "build spawned a runtime: $(tr '\n' ';' <"$SPAWNED")"

# ── C5 / C6 / C7 — check covers test/, lex and parse errors are located ──────
echo "==> C6 a lex error renders with file, line and excerpt on build/check/test"
P="$(project c6)"
printf 'pub fn main() {\n    print("unterminated);\n}\n' >"$P/src/main.bp"
for cmd in build check test; do
  run "$P" "$cmd"
  expect_code 1 "$cmd on a lex error"
  expect_out "src/main.bp:2:11" "$cmd locates the lex error"
  expect_out 'print("unterminated);' "$cmd quotes the source line"
done

echo "==> C7 a parse error renders with file, line and excerpt on build/check/test"
P="$(project c7)"
printf 'pub fn main() {\n    print((1);\n}\n' >"$P/src/main.bp"
for cmd in build check test; do
  run "$P" "$cmd"
  expect_code 1 "$cmd on a parse error"
  expect_out "src/main.bp:2:14" "$cmd locates the parse error at the token it stopped on"
  expect_out "print((1);" "$cmd quotes the source line"
done

echo "==> C6/C7 lex, parse and type errors in three modules are all located in one run"
P="$(project c67)"
printf 'pub mod lexbad;\npub mod parsebad;\npub mod typebad;\n\n%s' "$MAIN_OK" >"$P/src/main.bp"
printf 'pub fn g() {\n    print("abc);\n}\n' >"$P/src/lexbad.bp"
printf 'pub fn h() {\n    print((1);\n}\n' >"$P/src/parsebad.bp"
printf '%s' "$BROKEN" >"$P/src/typebad.bp"
for cmd in build check test; do
  run "$P" "$cmd"
  expect_code 1 "$cmd on three broken modules"
  expect_out "src/lexbad.bp:2:11" "$cmd locates the lex error"
  expect_out "src/parsebad.bp:2:14" "$cmd locates the parse error"
  expect_out "src/typebad.bp:2:5" "$cmd still type-checks past the lex and parse errors"
  expect_out "3 module(s) failed to compile: lexbad, parsebad, typebad" "$cmd names all three"
done

echo "==> C5 check loads test/ as well as src/"
P="$(project c5)"
printf '%s' "$MAIN_OK" >"$P/src/main.bp"
mkdir -p "$P/test"
printf 'test "broken" {\n    assert nope();\n}\n' >"$P/test/broken_test.bp"
run "$P" check
expect_code 1 "check on a broken test/ module"
expect_out "test/broken_test.bp:2:12" "check locates the test/ diagnostic"

# ── C3 / C4 — test runs what compiles and still fails the run ────────────────
if have node; then
  echo "==> C3 test runs the healthy tests and exits 1 on a broken module"
  P="$(project c3)"
  printf '%s\ntest "one" {\n    assert 1 == 1;\n}\n\ntest "two" {\n    assert 2 == 2;\n}\n' "$MAIN_OK" >"$P/src/main.bp"
  mkdir -p "$P/test"
  printf 'test "broken" {\n    assert nope();\n}\n' >"$P/test/broken_test.bp"
  mkdir -p "$P/.botopinkbuild/test-out" && echo 'stale' >"$P/.botopinkbuild/test-out/stale.js"
  run "$P" test
  expect_code 1 "test"
  expect_out "ok   one" "healthy test one ran"
  expect_out "ok   two" "healthy test two ran"
  expect_out "failed to compile: broken_test" "names the broken module"
  expect_out "test/broken_test.bp:2:12" "prints the located diagnostic, not a count"
  [[ ! -e "$P/.botopinkbuild/test-out/stale.js" ]] && ok "previous test-out artifacts removed" || fail "stale test-out artifact survived"

  echo "==> C4 a from \"std\" import does not mask a broken module"
  P="$(project c4)"
  printf 'import {math} from "std";\npub mod broken;\n\n%s\ntest "passes" {\n    assert 1 == 1;\n}\n' "$MAIN_OK" >"$P/src/main.bp"
  printf '%s' "$BROKEN" >"$P/src/broken.bp"
  run "$P" test
  expect_code 1 "test with one std import and one broken module"
  expect_out "failed to compile: broken" "names the broken module"

  echo "==> C4 no test blocks on a project that does not compile still reds"
  P="$(project c4b)"
  printf 'pub mod broken;\n\n%s' "$MAIN_OK" >"$P/src/main.bp"
  printf '%s' "$BROKEN" >"$P/src/broken.bp"
  run "$P" test
  expect_code 1 "test without test blocks"
else
  skip "C3/C4 (node not on PATH — botopink test runs commonJS through node)"
fi

# ── build / check / test agree ───────────────────────────────────────────────
echo "==> build, check and test agree on the same tree"
P="$(project agree)"
printf 'pub mod broken;\n\n%s' "$MAIN_OK" >"$P/src/main.bp"
printf '%s' "$BROKEN" >"$P/src/broken.bp"
codes=""
for cmd in build check test; do run "$P" "$cmd"; codes="$codes$CODE"; done
[[ "$codes" == "111" ]] && ok "broken tree: all three exit 1" || fail "broken tree: build/check/test exited $codes"
printf '%s' "$MAIN_OK" >"$P/src/main.bp"; rm "$P/src/broken.bp"
codes=""
for cmd in build check test; do run "$P" "$cmd"; codes="$codes$CODE"; done
[[ "$codes" == "000" ]] && ok "healthy tree: all three exit 0" || fail "healthy tree: build/check/test exited $codes"

# ── a dependency's missing `files` entry is named, with the manifest line ────
echo "==> a missing files entry of a dependency names the path and the manifest entry"
P="$(project missingfile)"
printf '{ "name": "missingfile", "version": "0.1.0", "target": "commonJS", "dependencies": { "gonelib": { "git": "https://example.invalid/gonelib.git" } } }\n' >"$P/botopink.json"
printf '%s' "$MAIN_OK" >"$P/src/main.bp"
LIBROOT="$WORK/libroot"; mkdir -p "$LIBROOT/gonelib/src"
printf '{ "name": "gonelib",\n  "src": "src/",\n  "files": ["gonelib.bp", "gone.bp"] }\n' >"$LIBROOT/gonelib/botopink.json"
printf 'pub fn g() -> i32 {\n    return 1;\n}\n' >"$LIBROOT/gonelib/src/gonelib.bp"
for cmd in build check test; do
  set +e
  OUT="$(cd "$P" && BOTOPINK_LIB_ROOTS="$LIBROOT" "$BP" "$cmd" 2>&1)"
  CODE=$?
  set -e
  expect_code 1 "$cmd with a missing files entry"
  expect_out "gonelib/src/gone.bp does not exist" "$cmd names the path it looked for"
  expect_out "gonelib/botopink.json:3:27" "$cmd locates the manifest entry"
done

# ── a dependency's .mjs sidecar ships inside --out, never beside it ─────────
echo "==> a dependency's .mjs sidecar ships inside --out and the build runs"
P="$(project sidecar)"
printf '{ "name": "sidecar", "version": "0.1.0", "target": "commonJS", "dependencies": { "sidelib": { "git": "https://example.invalid/sidelib.git" } } }\n' >"$P/botopink.json"
printf 'import { greet } from "sidelib";\n\npub fn main() {\n    print(greet());\n}\n' >"$P/src/main.bp"
LIBROOT="$WORK/sideroot"; mkdir -p "$LIBROOT/sidelib/src"
printf '{ "name": "sidelib", "src": "src/", "files": ["sidelib.bp"] }\n' >"$LIBROOT/sidelib/botopink.json"
# Authored relative to the lib's own build output, like onze's `../../src/onze.mjs`.
printf '#[@External.Node("../../src/side.mjs", "greet")]\npub declare fn greet() -> string;\n' >"$LIBROOT/sidelib/src/sidelib.bp"
printf 'export function greet() {\n    return "from the sidecar";\n}\n' >"$LIBROOT/sidelib/src/side.mjs"
OUTDIR="$WORK/sidecar-build/out"; mkdir -p "$WORK/sidecar-build"
set +e
OUT="$(cd "$P" && BOTOPINK_LIB_ROOTS="$LIBROOT" "$BP" build --out "$OUTDIR" 2>&1)"
CODE=$?
set -e
expect_code 0 "build with a dependency sidecar"
[[ -f "$OUTDIR/sidelib/side.mjs" ]] && ok "the sidecar is inside --out" || fail "the sidecar is not at $OUTDIR/sidelib/side.mjs"
[[ ! -e "$WORK/sidecar-build/src/side.mjs" ]] && ok "nothing is written beside --out" || fail "a sidecar was written beside --out"
if have node; then
  set +e
  OUT="$(cd "$OUTDIR" && node main.js 2>&1)"
  CODE=$?
  set -e
  expect_code 0 "the built program runs"
  expect_out "from the sidecar" "it reaches the relocated sidecar"
else
  skip "node not on PATH"
fi

# ── C8 — migrate --dry-run writes nothing, wherever the flag appears ─────────
echo "==> C8 migrate --dry-run writes nothing"
P="$(project c8)"
printf '%s' "$MAIN_OK" >"$P/src/main.bp"
mkdir -p "$P/src/shapes" && printf 'pub fn area() -> i32 {\n    return 1;\n}\n' >"$P/src/shapes/circle.bp"
before="$(cd "$P" && find src -type f | sort | xargs cat | cksum)"
run "$P" migrate src --dry-run
expect_code 1 "migrate with a positional is a usage error"
run "$P" migrate --dry-run
expect_code 0 "migrate --dry-run"
after="$(cd "$P" && find src -type f | sort | xargs cat | cksum)"
[[ "$before" == "$after" ]] && [[ ! -e "$P/src/shapes/mod.bp" ]] && ok "src/ untouched" || fail "migrate --dry-run wrote into src/"

# ── C9 — format / format --check count an unparseable file as an error ──────
echo "==> C9 format and format --check fail on unlexable or unparseable source"
P="$(project c9)"
printf 'pub fn main() {\n    print((1);\n}\n' >"$P/src/main.bp"
run "$P" format --check
expect_code 1 "format --check on a parse error"
expect_out "src/main.bp:2:" "format --check locates the parse error"
run "$P" format
expect_code 1 "format on a parse error"
printf 'pub fn main() {\n    print("unterminated);\n}\n' >"$P/src/main.bp"
run "$P" format --check
expect_code 1 "format --check on a lex error"

# ── decision 66 — format --check reaches the whole project; reject/ is exempt by shape ──
# No argument: every `.bp` and `.d.bp` under the project — src/, test/, examples/
# and the projects nested inside — is checked. Not entered: hidden directories and
# node_modules. Not reached: `reject/<n>.bp` beside its `<n>.expect`, the language
# suite's rejected program (decision 67: the exemption is the directory's shape,
# never a skip list, a pragma or an environment variable).
echo "==> format --check walks src/, test/, examples/ and nested projects; reject/<n>.bp beside <n>.expect is exempt"
P="$(project fmt66)"
printf '%s' "$MAIN_OK" >"$P/src/main.bp"
mkdir -p "$P/test" "$P/examples/nested/src" "$P/reject" "$P/.botopinkbuild" "$P/node_modules/dep"
printf 'test "t" {\n    assert 1 == 1;\n}\n' >"$P/test/main_test.bp"
printf '{ "name": "nested", "version": "0.1.0", "target": "commonJS" }\n' >"$P/examples/nested/botopink.json"
printf 'pub fn f() {\n  print("x");\n}\n' >"$P/examples/nested/src/main.bp"   # two-space indent: not canonical
printf 'pub fn g( {\n' >"$P/reject/bad.bp"                                     # refused on purpose …
printf 'this token cannot appear here\n' >"$P/reject/bad.expect"               # … and paired: the fixture
printf 'pub fn h() {\n  print("y");\n}\n' >"$P/.botopinkbuild/scratch.bp"
printf 'pub fn h() {\n  print("y");\n}\n' >"$P/node_modules/dep/dep.bp"
before="$(cd "$P" && find . -type f | sort | xargs cat | cksum)"
run "$P" format --check
expect_code 1 "format --check with one non-canonical file in a nested project"
expect_out "examples/nested/src/main.bp" "the nested project's file is named"
expect_out "1 file(s) would be reformatted" "exactly one file is counted"
expect_out "test/main_test.bp" "test/ is reached"
expect_no_out "reject/bad.bp" "reject/<n>.bp beside its .expect is not reached"
expect_no_out ".botopinkbuild" "a hidden directory is not entered"
expect_no_out "node_modules" "node_modules is not entered"
after="$(cd "$P" && find . -type f | sort | xargs cat | cksum)"
[[ "$before" == "$after" ]] && ok "--check wrote nothing" || fail "--check wrote into the project"
run "$P" format
expect_code 0 "format rewrites the whole project"
run "$P" format --check
expect_code 0 "format --check is green after format"
printf 'pub fn g( {\n' >"$P/reject/lone.bp"                                    # no .expect: not the fixture
run "$P" format --check
expect_code 1 "a reject/ .bp without its .expect is not the fixture and is reached"
expect_out "--> reject/lone.bp:" "and its parse error is located"
run "$P" format --check examples/nested
expect_code 0 "a directory argument is walked the same way"
expect_out "examples/nested/src/main.bp" "the walked path keeps the argument as its prefix"

# ── C10 — check <path> ───────────────────────────────────────────────────────
echo "==> C10 check forwards its path argument"
P="$(project c10)"
printf '%s' "$BROKEN" >"$P/src/main.bp"
run "$WORK" check /nonexistent/botopink/path
expect_code 1 "check on a missing path"
expect_out "/nonexistent/botopink/path" "names the path it could not enter"
run "$WORK" check "$P"
expect_code 1 "check <broken project>"
expect_out "noSuchFunction" "checks the named project, not the cwd"

# ── C11 — unknown flags and --flag=value ─────────────────────────────────────
echo "==> C11 flags are never silently dropped"
P="$(project c11)"
printf '%s' "$MAIN_OK" >"$P/src/main.bp"
run "$P" build --frobnicate
expect_code 1 "build --frobnicate"
expect_out "unknown flag '--frobnicate'" "names the unknown flag"
run "$P" build --target=erlang --out out-eq
expect_code 0 "build --target=erlang"
# 13 half 1: an erlang artifact lands at `<out>/erl/<module atom><ext>`.
[[ -f "$P/out-eq/erl/main.erl" && ! -e "$P/out-eq/main.js" ]] && ok "--target=erlang honoured" || fail "--target=erlang did not produce out-eq/erl/main.erl"
run "$P" test --target wasm2
expect_code 1 "test --target wasm2"

# ── C12 — new --target and an unsupported manifest target ────────────────────
echo "==> C12 unsupported targets are rejected"
run "$WORK" new badtarget --target frobnicate
expect_code 1 "new --target frobnicate"
[[ ! -e "$WORK/badtarget" ]] && ok "nothing scaffolded" || fail "new scaffolded a project with an unsupported target"
P="$(project c12 frobnicate)"
printf '%s' "$MAIN_OK" >"$P/src/main.bp"
run "$P" build
expect_code 1 "build with \"target\": \"frobnicate\""
expect_out "unsupported target 'frobnicate'" "names the manifest target"
[[ ! -e "$P/out/main.js" ]] && ok "no commonJS fallback artifact" || fail "unsupported manifest target degraded to commonJS"

# ── C13 — clean reports a failed delete ──────────────────────────────────────
echo "==> C13 clean exits 1 when a delete fails"
if [[ "$(id -u)" -eq 0 ]]; then
  skip "C13 (running as root — permissions cannot make a directory undeletable)"
else
  P="$WORK/c13"; mkdir -p "$P/out/sub"
  chmod 555 "$P/out"
  run "$P" clean
  chmod 755 "$P/out"
  expect_code 1 "clean with an undeletable out/"
  expect_no_out "Removed out/" "does not claim out/ was removed"
fi

# ── the `new` scaffold is a working program ──────────────────────────────────
# A block's value is its `break` (semantics decision 2), so the old template —
# a body whose only statement was the literal "Hello, world!" — compiled, ran
# and printed nothing: the README's quick start had no visible effect.
echo "==> botopink new scaffolds a project that prints when run"
run "$WORK" new scaffolded
expect_code 0 "new scaffolded"
grep -qF '@print' "$WORK/scaffolded/src/main.bp" \
  && ok "the template prints" \
  || fail 'the scaffolded src/main.bp has no @print — botopink run would show nothing'
if have node; then
  run "$WORK/scaffolded" run
  expect_code 0 "run of the scaffolded project"
  expect_out "Hello, world!" "the scaffolded program prints on stdout"
else
  skip "the scaffold's run row (node not installed)"
fi

# ── workspaces (decision 75) and the dependency object (decision 76) ─────────
# An umbrella `botopink.json` with `"workspaces"` declares members; a member
# depends on a sibling with `{ "workspace": true }`, and the enclosing
# workspace is found from the member's own directory — no root export.
echo "==> a workspace member resolves a sibling with { workspace: true }"
WS="$WORK/acme"; rm -rf "$WS"
mkdir -p "$WS/modules/acme/src" "$WS/modules/acme-web/src" "$WS/modules/acme-web/test" "$WS/modules/acme-empty/src" "$WS/examples/acme-app/src"
cat >"$WS/botopink.json" <<'JSON'
{ "name": "acme", "version": "0.0.1", "targets": ["commonJS"],
  "workspaces": ["modules/*", "examples/*"] }
JSON
cat >"$WS/modules/acme/botopink.json" <<'JSON'
{ "name": "acme", "version": "0.0.1", "target": "commonJS", "entry": "root.bp", "files": ["root.bp"] }
JSON
printf 'pub fn core() -> i32 {\n    return 41;\n}\n' >"$WS/modules/acme/src/root.bp"
cat >"$WS/modules/acme-web/botopink.json" <<'JSON'
{ "name": "acme-web", "version": "0.0.1", "target": "commonJS", "entry": "root.bp", "files": ["root.bp"],
  "dependencies": { "acme": { "workspace": true } } }
JSON
printf 'import { core } from "acme";\n\npub fn web() -> i32 {\n    return core() + 1;\n}\n' >"$WS/modules/acme-web/src/root.bp"
# The flat `test/` suite imports the package it tests with a bare import.
printf 'import { web };\n\ntest "the sibling member is reachable" {\n    assert web() == 42;\n}\n' >"$WS/modules/acme-web/test/web_test.bp"
cat >"$WS/modules/acme-empty/botopink.json" <<'JSON'
{
  "name": "acme-empty", "version": "0.0.1", "target": "commonJS", "entry": "root.bp" }
JSON
printf '// ships nothing\n' >"$WS/modules/acme-empty/src/root.bp"
cat >"$WS/examples/acme-app/botopink.json" <<'JSON'
{ "name": "acme-app", "version": "0.0.1", "target": "commonJS", "entry": "main.bp",
  "dependencies": { "acme": { "workspace": true } } }
JSON
printf 'import { core } from "acme";\n\npub fn main() {\n    print(core());\n}\n' >"$WS/examples/acme-app/src/main.bp"

run "$WS/modules/acme-web" build
expect_code 0 "build of a member depending on a sibling"
run "$WS/examples/acme-app" build
expect_code 0 "build of an example member depending on a core member"
if have node; then
  run "$WS/modules/acme-web" test
  expect_code 0 "test of a member depending on a sibling"
  expect_out "ok   the sibling member is reachable" "the sibling's symbol resolved"
else
  skip "the member's test row (node not installed)"
fi

echo "==> a library member without files ships nothing — its own test fails"
run "$WS/modules/acme-empty" test
expect_code 1 "test inside a library member with no files"
expect_out 'ships nothing: manifest has no "files"' "names the refusal"
expect_out "botopink.json:2:3" "locates it on the member manifest"

echo "==> a package command on the workspace itself is refused, listing the members"
for cmd in build check test; do
  run "$WS" "$cmd"
  expect_code 1 "$cmd on the umbrella"
  expect_out "is a workspace, not a package — run this command inside one of its members: acme, acme-empty, acme-web, acme-app" "$cmd names the members"
done

echo "==> a path to a sibling member is refused: use { workspace: true }"
cat >"$WS/modules/acme-web/botopink.json" <<'JSON'
{ "name": "acme-web", "version": "0.0.1", "target": "commonJS", "entry": "root.bp", "files": ["root.bp"],
  "dependencies": { "acme": { "path": "../acme" } } }
JSON
run "$WS/modules/acme-web" build
expect_code 1 "build with a path to a sibling"
expect_out '"acme": path "../acme" points at the sibling member "acme" — use { "workspace": true }' "names the fix"
expect_out "botopink.json:2:21" "locates the dependency entry"

echo "==> the string-array dependencies form is refused, naming the fix"
P="$(project arraydeps)"
printf '{ "name": "arraydeps", "version": "0.1.0", "target": "commonJS",\n  "dependencies": ["erika"] }\n' >"$P/botopink.json"
printf '%s' "$MAIN_OK" >"$P/src/main.bp"
run "$P" build
expect_code 1 "build with array-form dependencies"
expect_out '"dependencies" must be an object, not an array' "names the retired shape"
expect_out '["erika"] becomes { "erika": { "path": "../erika" } }' "names the rewrite"
expect_out "botopink.json:2:3" "locates the field"

echo "==> a path dependency is honoured from the project directory"
P="$(project pathdep)"
mkdir -p "$WORK/pathlib/src"
printf '{ "name": "pathlib", "files": ["pathlib.bp"] }\n' >"$WORK/pathlib/botopink.json"
printf 'pub fn answer() -> i32 {\n    return 7;\n}\n' >"$WORK/pathlib/src/pathlib.bp"
printf '{ "name": "pathdep", "version": "0.1.0", "target": "commonJS", "dependencies": { "pathlib": { "path": "../pathlib" } } }\n' >"$P/botopink.json"
printf 'import { answer } from "pathlib";\n\npub fn main() {\n    print(answer());\n}\n' >"$P/src/main.bp"
run "$P" build
expect_code 0 "build with a path dependency (no library root involved)"

echo
if [[ "$failures" -gt 0 ]]; then
  echo "==> cli contract: $failures assertion(s) FAILED" >&2
  exit 1
fi
echo "==> cli contract: OK"
