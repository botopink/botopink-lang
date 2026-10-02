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

# macOS sets TMPDIR with a trailing slash; the compiler prints normalised
# paths, so the scratch root is spelled without it.
tmp_root="${TMPDIR:-/tmp}"
WORK="$(mktemp -d "${tmp_root%/}/botopink-cli-contract.XXXXXX")"
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
expect_file_out() { # <file> <fixed-string> <label>
  if grep -qF -- "$2" "$1"; then ok "$3"; else fail "$3: $1 lacks '$2'"; sed 's/^/      /' "$1" >&2; fi
}

# project <name> [target] — a fresh project directory with a botopink.json.
project() {
  local dir="$WORK/$1"
  rm -rf "$dir"; mkdir -p "$dir/src"
  printf '{ "name": "%s", "version": "0.1.0", "target": "%s" }\n' "$1" "${2:-commonJS}" >"$dir/botopink.json"
  echo "$dir"
}

MAIN_OK='pub fn main() {
    @print("hello");
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
printf 'pub fn main() {\n    @print("stale build v1");\n}\n' >"$P/src/main.bp"
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
# erlang and beam are the targets whose build spawns anything, and it is one
# `erl` — never running the program: the command's session (`otp.zig`), which
# first prints its OTP release (decision 228); in the same VM the erlang build
# then compiles every emitted `.erl` in memory with the OTP compiler
# (`build.zig`, `checkErlang`), and both ask the Erlang code path about the
# host modules no shipped sidecar answers (`libs.zig`, `shipErlSidecars`).
# With a failing `erl` first on PATH the session is the one spawn, and the
# build fails rather than claim what it did not check.
echo "==> build emits without running the program (no runtime spawn, no runtime cache)"
SHIMS="$WORK/shims"; SPAWNED="$WORK/spawned.log"
mkdir -p "$SHIMS"; : >"$SPAWNED"
for tool in node erl erlc escript wasmtime; do
  # One line per spawn, whatever newlines an argument carries.
  printf '#!/bin/sh\necho "%s $*" | tr "\\n" " " >>"%s"\necho >>"%s"\nexit 1\n' "$tool" "$SPAWNED" "$SPAWNED" >"$SHIMS/$tool"
  chmod +x "$SHIMS/$tool"
done
for target in commonJS erlang beam wasm; do
  P="$(project exec-$target "$target")"
  printf 'pub fn main() {\n    @print("side effect at build time");\n}\n' >"$P/src/main.bp"
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
  if [[ $target == erlang || $target == beam ]]; then
    expect_code 1 "build --target $target with a failing erl on PATH (the OTP release probe cannot run)"
    expect_out "and \`erl\` on PATH did not name its release (exit 1) — install OTP" "build --target $target names the failed release probe"
  else
    expect_code 0 "build --target $target with runtime shims on PATH"
  fi
done
# The session (`erl +sbwt none … +S <n>:1 -noshell -eval <SESSION_EVAL>`,
# whose first act is to print `otp_release`) is the only spawn allowed: a
# failing `erl` stops the build there.
OTP_PROBE='^erl \+sbwt none \+sbwtdcpu none \+sbwtdio none \+S [0-9]+:1 -noshell -eval io:put_chars\(\[erlang:system_info\(otp_release\), '
OTHER="$(grep -vE -e "$OTP_PROBE" "$SPAWNED" || true)"
[[ -z "$OTHER" ]] && ok "no node/erl/erlc/escript/wasmtime spawned by build but the OTP session" || fail "build spawned a runtime: $(tr '\n' ';' <<<"$OTHER")"
[[ "$(grep -cE -e "$OTP_PROBE" "$SPAWNED")" -eq 2 ]] && ok "the erlang and the beam build each started one session, and a failing erl stopped it there" || fail "the erlang and the beam build did not start one session each: $(grep -c '^erl ' "$SPAWNED") erl spawn(s)"

# ── the OTP release the compiler emits for (decision 228) ────────────────────
# `botopink --version` names the release; an erlang or beam build with another
# `erl` first on PATH is refused before any `.erl` is written, and one with the
# release builds. The OTP 29 shim answers any `erl` that asks for
# `otp_release` (the session's first line) with 29; the OTP 28 one, and every
# other call, is the `erl` of the PATH the script started with.
echo "==> the OTP release: --version names it, another erl on PATH is refused"
run "$WORK" --version
expect_code 0 "--version"
expect_out "otp: 28" "--version prints the OTP release"
for v in 28 29; do
  mkdir -p "$WORK/otp$v"
  if [[ $v == 29 ]]; then answer='case "$*" in *otp_release*) printf "29\n"; exit 0;; esac'; else answer=''; fi
  printf '#!/bin/sh\n%s\nPATH=%s exec erl "$@"\n' "$answer" "'$PATH'" >"$WORK/otp$v/erl"
  chmod +x "$WORK/otp$v/erl"
done
for target in erlang beam; do
  P="$(project otp-$target "$target")"
  printf '%s' "$MAIN_OK" >"$P/src/main.bp"
  set +e
  OUT="$(cd "$P" && PATH="$WORK/otp29:$PATH" "$BP" build 2>&1)"
  CODE=$?
  set -e
  expect_code 1 "build --target $target with OTP 29 first on PATH"
  expect_out "botopink emits Erlang for OTP 28, and \`erl\` on PATH is OTP 29 — install OTP 28 and put it on PATH" "names both releases"
  [[ ! -e "$P/out" ]] && ok "$target: nothing written before the refusal" || fail "$target: the refused build wrote $(find "$P/out" -type f | head -1)"
  set +e
  OUT="$(cd "$P" && PATH="$WORK/otp28:$PATH" "$BP" build 2>&1)"
  CODE=$?
  set -e
  expect_code 0 "build --target $target with OTP 28 first on PATH"
done
P="$(project otp-test erlang)"
printf '%s' "$MAIN_OK" >"$P/src/main.bp"
set +e
OUT="$(cd "$P" && PATH="$WORK/otp29:$PATH" "$BP" test 2>&1)"
CODE=$?
set -e
expect_code 1 "test --target erlang with OTP 29 first on PATH"
expect_out "and \`erl\` on PATH is OTP 29" "test names the refused release"

# The comptime node goes through the same check (compiler-core `otp.zig`), and
# only an erlang / beam build starts it: decision 84 evaluates a commonJS
# build's comptime on the in-process wat runtime. So a commonJS build that runs
# a template spawns no `erl` at all — not even the probe — and builds with OTP
# 29 first on PATH, while the same program on erlang is refused.
echo "==> the OTP release: comptime on commonJS spawns no erl; on erlang it is refused"
P="$(project otp-comptime)"
printf '%s\n' 'pub fn twice(comptime q: @Expr<string>) -> @Expr<i32> {' '    val n = q.text().length;' '    return @expr(n * 2);' '}' '' 'pub fn main() {' '    @print(twice "abcd");' '}' >"$P/src/main.bp"
mkdir -p "$WORK/otp29rec"; : >"$WORK/otp29rec.log"
printf '#!/bin/sh\necho "erl $*" >>"%s"\nprintf 29\n' "$WORK/otp29rec.log" >"$WORK/otp29rec/erl"
chmod +x "$WORK/otp29rec/erl"
set +e
OUT="$(cd "$P" && PATH="$WORK/otp29rec:$PATH" "$BP" build 2>&1)"
CODE=$?
set -e
expect_code 0 "commonJS build running a template, OTP 29 first on PATH"
[[ ! -s "$WORK/otp29rec.log" ]] && ok "commonJS comptime spawned no erl" || fail "commonJS comptime spawned: $(tr '\n' ';' <"$WORK/otp29rec.log")"
expect_file_out "$P/out/main.js" "__bp_print(8)" "the template ran (wat runtime)"
set +e
OUT="$(cd "$P" && PATH="$WORK/otp29rec:$PATH" "$BP" build --target erlang 2>&1)"
CODE=$?
set -e
expect_code 1 "erlang build of the same program, OTP 29 first on PATH"
expect_out "and \`erl\` on PATH is OTP 29" "refused before the comptime node starts"

# A manifest may pin the release, within what the compiler emits for.
echo "==> the OTP release: a manifest's \"otp\" names 28, and a closure agrees"
P="$(project otp-pin)"
printf '{ "name": "otppin", "otp": "26" }\n' >"$P/botopink.json"
printf '%s' "$MAIN_OK" >"$P/src/main.bp"
run "$P" build
expect_code 1 "build with \"otp\": \"26\""
expect_out 'botopink emits Erlang for OTP 28; "otp" names 26' "the unsupported pin is refused"
expect_out "botopink.json:1:" "located in the manifest"
mkdir -p "$WORK/otp-dep/src"
printf '{ "name": "otpdep", "otp": "29", "files": ["root.bp"] }\n' >"$WORK/otp-dep/botopink.json"
printf 'pub fn one() -> i32 { return 1; }\n' >"$WORK/otp-dep/src/root.bp"
printf '{ "name": "otppin", "otp": "28", "dependencies": { "otpdep": { "path": "../otp-dep" } } }\n' >"$P/botopink.json"
run "$P" build
expect_code 1 "build of a closure pinning 28 and 29"
expect_out '"otp" names 29 here, but 28 in' "the disagreement is refused"
expect_out "otp-dep/botopink.json:1:" "located at the dependency's pin"
expect_out "but 28 in botopink.json" "naming the project's manifest"

# ── build --target erlang compiles what it emits ─────────────────────────────
# A build that only transpiled proved nothing about erlang: a module the OTP
# compiler rejects was written and the build exited 0. A host template that is
# not Erlang (`lists:reverse($0 ++)`) is emitted as written, so its module is
# one `erlc` refuses — the build must fail and name the refusal.
echo "==> build --target erlang refuses emitted erlang the OTP compiler rejects"
P="$(project erlcrefused erlang)"
printf '#[@External.Erlang("lists:reverse($0 ++)")]\ndeclare fn bad(xs: i32[]) -> i32[];\n\npub fn main() {\n    @print(bad([1]).length);\n}\n' >"$P/src/main.bp"
run "$P" build
expect_code 1 "build --target erlang of a module erlc rejects"
expect_out "erlcrefused@main.erl:" "names the refused module"
expect_out "the OTP compiler refused emitted erlang" "says the build is not a program"

# ── the erlang check remembers acceptances, never refusals ───────────────────
# `checkErlang` keeps an empty marker per accepted source, keyed by its bytes
# and the OTP compiler, under the cache root's `.botopinkbuild/cache/erlcheck/`
# (`build.zig`, `libs.cacheDir`, decision 225). A refusal is compiled and
# printed every time, and a source that changed is a new key: the cache
# answers only for bytes it has already seen accepted. HOME and XDG_CACHE_HOME
# point at a scratch directory where `botopink` may write nothing (other tools
# on PATH — a version manager's `erl` shim — keep their own caches there): no
# cache of the compiler lives outside the project.
echo "==> the erlang check's verdict cache: acceptances only, keyed by the bytes, inside .botopinkbuild"
USER_CACHE="$WORK/user-home"
mkdir -p "$USER_CACHE"
bp_isolated() { HOME="$USER_CACHE" XDG_CACHE_HOME="$USER_CACHE/.cache" "$BP" "$@"; }
# `botopink-lsp` too (decision 233): its old home was `~/.cache/botopink-lsp`.
user_cache_files() { { find "$USER_CACHE/.cache/botopink" "$USER_CACHE/.cache/botopink-lsp" -type f 2>/dev/null || true; } | wc -l | tr -d " "; }
P="$(project erlcache erlang)"
printf 'pub fn main() {\n    @print("one");\n}\n' >"$P/src/main.bp"
markers() { { find "$1/.botopinkbuild/cache/erlcheck" -name "*.ok" 2>/dev/null || true; } | wc -l | tr -d " "; }
( cd "$P" && bp_isolated build >/dev/null 2>&1 ) && ok "an accepted build" || fail "the erlang build of a plain program failed"
m1="$(markers "$P")"
[[ "$m1" -gt 0 ]] && ok "accepted sources are remembered under .botopinkbuild/cache/erlcheck/ ($m1 marker(s))" || fail "no verdict marker was written under $P/.botopinkbuild/cache/erlcheck"
( cd "$P" && bp_isolated build >/dev/null 2>&1 ) && ok "the same build again" || fail "the cached build failed"
[[ "$(markers "$P")" == "$m1" ]] && ok "the same bytes are the same keys" || fail "a rebuild of the same bytes wrote new markers ($(markers "$P") vs $m1)"
rm -rf "$P/.botopinkbuild"
( cd "$P" && bp_isolated build >/dev/null 2>&1 ) && ok "a build after rm -rf .botopinkbuild" || fail "the build after deleting .botopinkbuild failed"
[[ "$(markers "$P")" == "$m1" ]] && ok "deleting .botopinkbuild deleted every verdict: each module was compiled again ($m1 marker(s) rewritten)" || fail "after rm -rf .botopinkbuild the build wrote $(markers "$P") marker(s), not $m1 — a verdict was answered from elsewhere"
printf 'pub fn main() {\n    @print("two");\n}\n' >"$P/src/main.bp"
( cd "$P" && bp_isolated build >/dev/null 2>&1 ) && ok "a changed source builds" || fail "the changed build failed"
[[ "$(markers "$P")" -gt "$m1" ]] && ok "a changed source is a new key, checked again" || fail "a changed source was answered from the cache"
[[ "$(user_cache_files)" -eq 0 ]] && ok "nothing was written under HOME/.cache/botopink" || fail "a build wrote under HOME/.cache/botopink: $(find "$USER_CACHE/.cache/botopink" -type f | head -3 | tr '\n' ' ')"
run "$P" clean
expect_code 0 "clean"
[[ ! -e "$P/.botopinkbuild" ]] && ok "clean leaves no .botopinkbuild/" || fail "clean left $P/.botopinkbuild"
[[ "$(user_cache_files)" -eq 0 ]] && ok "no file under HOME/.cache/botopink after clean" || fail "files remain under the user cache"
P="$(project erlcacherefused erlang)"
printf '#[@External.Erlang("lists:reverse($0 ++)")]\ndeclare fn bad(xs: i32[]) -> i32[];\n\npub fn main() {\n    @print(bad([1]).length);\n}\n' >"$P/src/main.bp"
for i in 1 2; do
  set +e
  OUT="$(cd "$P" && bp_isolated build 2>&1)"
  CODE=$?
  set -e
  [[ $CODE -eq 1 ]] && grep -qF "the OTP compiler refused emitted erlang" <<<"$OUT" \
    && ok "refused again on build $i — a refusal is never remembered" \
    || fail "build $i of a module erlc rejects: exit $CODE, refusal not printed"
done

# The cache root of a workspace member is the workspace root: every member of
# one library repository shares its `.botopinkbuild/cache/`, and a clean in a
# member deletes it with the member's own `.botopinkbuild/`.
echo "==> a workspace member caches under the workspace root; clean deletes it"
WS="$WORK/wscache"
rm -rf "$WS"; mkdir -p "$WS/modules/wsapp/src"
printf '{ "name": "wscache", "version": "0.1.0", "workspaces": ["modules/*"] }\n' >"$WS/botopink.json"
printf '{ "name": "wsapp", "version": "0.1.0", "target": "erlang" }\n' >"$WS/modules/wsapp/botopink.json"
printf 'pub fn main() {\n    @print("ws");\n}\n' >"$WS/modules/wsapp/src/main.bp"
( cd "$WS/modules/wsapp" && bp_isolated build >/dev/null 2>&1 ) && ok "a member builds" || fail "the workspace member's erlang build failed"
[[ "$(markers "$WS")" -gt 0 ]] && ok "its verdicts are under the workspace root's .botopinkbuild/cache/erlcheck/" || fail "no verdict marker under $WS/.botopinkbuild/cache/erlcheck"
[[ ! -e "$WS/modules/wsapp/.botopinkbuild/cache" ]] && ok "none under the member's own .botopinkbuild/" || fail "the member kept a cache of its own"
run "$WS/modules/wsapp" clean
expect_code 0 "clean in a member"
[[ ! -e "$WS/.botopinkbuild/cache" && ! -e "$WS/modules/wsapp/.botopinkbuild" ]] && ok "clean deleted the member's .botopinkbuild/ and the workspace's cache" || fail "clean left a cache: $(find "$WS" -path '*/.botopinkbuild*' -maxdepth 4 | head -3 | tr '\n' ' ')"
expect_out " $WS/.botopinkbuild/cache/" "clean names the workspace cache it deleted"

# The language server keeps its state in the same root (decision 233): a
# go-to-definition into an embedded std module writes it under the workspace
# root's `.botopinkbuild/cache/lsp/std/`, nothing under the member and nothing
# under HOME; a file outside every project gets no cache and writes nothing.
echo "==> botopink-lsp caches under the project's .botopinkbuild/cache/lsp/, never under HOME"
LSP="$(dirname "$BP")/botopink-lsp"
if [[ ! -x "$LSP" ]]; then
  skip "botopink-lsp not found beside $BP"
else
  lsp_frame() { printf 'Content-Length: %d\r\n\r\n%s' "$(LC_ALL=C; printf '%s' "$1" | wc -c | tr -d " ")" "$1"; }
  # lsp_definition <file> <line> <character> — opens <file>, asks the
  # definition at the position, prints the server's whole output.
  lsp_definition() {
    local text
    text="$(sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' "$1" | awk '{ printf "%s\\n", $0 }')"
    {
      lsp_frame '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"capabilities":{}}}'
      lsp_frame "{\"jsonrpc\":\"2.0\",\"method\":\"textDocument/didOpen\",\"params\":{\"textDocument\":{\"uri\":\"file://$1\",\"languageId\":\"botopink\",\"version\":1,\"text\":\"$text\"}}}"
      lsp_frame "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"textDocument/definition\",\"params\":{\"textDocument\":{\"uri\":\"file://$1\"},\"position\":{\"line\":$2,\"character\":$3}}}"
      lsp_frame '{"jsonrpc":"2.0","id":3,"method":"shutdown"}'
      lsp_frame '{"jsonrpc":"2.0","method":"exit"}'
    } | HOME="$USER_CACHE" XDG_CACHE_HOME="$USER_CACHE/.cache" "$LSP" 2>/dev/null | tr -d '\r'
  }
  STD_SRC='import {collections} from "std";\nval n = collections.toInt(collections.lt());\n'
  mkdir -p "$WS/modules/wsapp/src"
  printf "$STD_SRC" >"$WS/modules/wsapp/src/main.bp"
  OUT="$(lsp_definition "$WS/modules/wsapp/src/main.bp" 1 20)"
  expect_out "$WS/.botopinkbuild/cache/lsp/std/collections.bp" "a member's std definition lands under the workspace root's .botopinkbuild/cache/lsp/std/"
  [[ -f "$WS/.botopinkbuild/cache/lsp/std/collections.bp" ]] && ok "the std module is written there" || fail "no $WS/.botopinkbuild/cache/lsp/std/collections.bp"
  [[ ! -e "$WS/modules/wsapp/.botopinkbuild" ]] && ok "nothing under the member's own .botopinkbuild/" || fail "the language server wrote under the member: $(find "$WS/modules/wsapp/.botopinkbuild" -type f | head -3 | tr '\n' ' ')"
  rm -rf "$WS/.botopinkbuild"
  OUT="$(lsp_definition "$WS/modules/wsapp/src/main.bp" 1 20)"
  [[ -f "$WS/.botopinkbuild/cache/lsp/std/collections.bp" ]] && ok "after rm -rf .botopinkbuild the next request writes it again" || fail "the language server did not recreate its cache after rm -rf .botopinkbuild"
  LOOSE="$WORK/lsploose"
  rm -rf "$LOOSE"; mkdir -p "$LOOSE"
  printf "$STD_SRC" >"$LOOSE/main.bp"
  OUT="$(lsp_definition "$LOOSE/main.bp" 1 20)"
  expect_out '"id":2,"result":null' "a file outside every project gets no std jump (no cache to write it to)"
  [[ "$(find "$LOOSE" -type f | wc -l | tr -d " ")" -eq 1 ]] && ok "nothing written beside a file outside every project" || fail "the language server wrote beside a loose file: $(find "$LOOSE" -type f | tr '\n' ' ')"
  [[ "$(user_cache_files)" -eq 0 ]] && ok "nothing under HOME/.cache/botopink-lsp" || fail "the language server wrote under HOME: $(find "$USER_CACHE/.cache" -type f | head -3 | tr '\n' ' ')"
fi

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
  mkdir -p "$P/.botopinkbuild/test-out/commonJS" && echo 'stale' >"$P/.botopinkbuild/test-out/commonJS/broken_test.js"
  run "$P" test
  expect_code 1 "test"
  expect_out "ok   one" "healthy test one ran"
  expect_out "ok   two" "healthy test two ran"
  expect_out "failed to compile: broken_test" "names the broken module"
  expect_out "test/broken_test.bp:2:12" "prints the located diagnostic, not a count"
  # A run writes into its own `test-out/<target>/<id>/` and removes it when it
  # ends, so a previous run's artifact of a module that no longer compiles is
  # never in the tree this run reads — structurally, not by emptying a shared
  # directory another run may be using (C3b). Nothing of this run survives it,
  # and the planted files are neither read nor deleted: they are not in it.
  [[ -z "$(find "$P/.botopinkbuild/test-out" -mindepth 3 -print -quit)" ]] \
    && ok "the run left no artifact tree behind" \
    || fail "the run's test-out directory survived it"
  expect_no_out "stale" "no stale artifact was read"

  # ── C3b — two runs in one checkout must not empty each other's output ──────
  # `botopink test` used to write to one `.botopinkbuild/test-out/` in the
  # project's own directory and empty it on the way in, while
  # `botopink-lib-test` runs every cell with `cwd = <lib dir>`. Two gates over
  # one library checkout therefore wiped each other's artifacts mid-run, and the
  # loser reported a library red owned by nobody: modules missing under node
  # (`Cannot find module …/x_test.js`), or an `{error,undef}` storm under
  # escript once another target's `.js` had replaced the `.erl` siblings its
  # runner loads. Both targets of one project, started together, must pass.
  if have escript; then
    echo "==> C3b concurrent runs in one checkout keep their own output"
    P="$(project c3b)"
    # Target-neutral source: the row runs commonJS AND erlang, and `$MAIN_OK`'s
    # `print` is a commonJS builtin (`print/1 undefined` under erlang).
    printf 'pub fn double(n: i32) -> i32 {\n    return n * 2;\n}\n\ntest "double" {\n    assert double(2) == 4;\n}\n' >"$P/src/main.bp"
    mkdir -p "$P/test"
    for m in a b c d e f; do
      printf 'test "suite %s" {\n    assert 1 == 1;\n    assert 2 == 2;\n}\n' "$m" >"$P/test/${m}_test.bp"
    done
    c3b_failed=0
    for i in 1 2 3; do
      # `set +e` inside each subshell: the script's own `set -e` is inherited,
      # and a failing run would end the subshell before it recorded its code.
      ( set +e; cd "$P"; "$BP" test --target commonJS >"$WORK/c3b-$i-js.log" 2>&1; echo "$?" >"$WORK/c3b-$i-js.code" ) &
      ( set +e; cd "$P"; "$BP" test --target erlang >"$WORK/c3b-$i-erl.log" 2>&1; echo "$?" >"$WORK/c3b-$i-erl.code" ) &
      wait
      for t in js erl; do
        if [[ "$(cat "$WORK/c3b-$i-$t.code")" != 0 ]]; then
          c3b_failed=1
          fail "concurrent pair $i: the $t run failed"
          sed 's/^/      /' "$WORK/c3b-$i-$t.log" | tail -20 >&2
        elif grep -qE 'Cannot find module|\{error,undef\}|Failed to open file' "$WORK/c3b-$i-$t.log"; then
          c3b_failed=1
          fail "concurrent pair $i: the $t run lost artifacts to the other run"
        fi
      done
    done
    [[ "$c3b_failed" -eq 0 ]] && ok "three concurrent commonJS/erlang pairs, none clobbered"
    [[ -z "$(find "$P/.botopinkbuild/test-out" -mindepth 3 -print -quit)" ]] \
      && ok "every run removed its own output directory" \
      || fail "a run's test-out directory survived it"
    # The deterministic half of the row: a run writes NOTHING into the shared
    # root — every artifact lives under its own `<target>/<id>/`, which is what
    # makes two runs unable to reach each other's. A pre-fix binary leaves
    # `test-out/main.js` here and reds this line on every run, concurrent or not.
    [[ -z "$(find "$P/.botopinkbuild/test-out" -maxdepth 1 -type f -print -quit)" ]] \
      && ok "nothing was written to the shared test-out root" \
      || fail "an artifact was written to the shared test-out root"
  else
    skip "C3b concurrent runs (escript not installed)"
  fi

  # ── C3c — a test's scratch directory is the run's own ──────────────────────
  # `botopink test` names `<run dir>/tmp` in `BOTOPINK_TEST_TMPDIR` for every
  # runner it spawns. rakun's build tests wrote their fixture projects under
  # the member's own `.botopinkbuild/tmp/`, which its commonJS and erlang cells
  # (run side by side, same cwd) both `rm -rf` and rewrite: the pinned counts of
  # `rakun-data·commonJS` read 6, `build`, 1 on three consecutive gates. Each
  # test here writes its target's name into the directory and prints the path;
  # the two concurrent runs must see two different, absolute, existing
  # directories, and neither may survive its run.
  if have escript; then
    echo "==> C3c BOTOPINK_TEST_TMPDIR is absolute, per run, and removed with it"
    P="$(project c3c)"
    printf '%s\n' \
      'import {io: {env, fs}} from "std";' '' \
      'test "scratch" {' \
      '    val d = env.read("BOTOPINK_TEST_TMPDIR").unwrapOr("");' \
      '    @print("scratch=" + d);' \
      '    assert d.startsWith("/");' \
      '    val _w = fs.writeText(d + "/mine.txt", "x");' \
      '    assert fs.readText(d + "/mine.txt").unwrapOr("") == "x";' \
      '}' >"$P/src/main.bp"
    ( set +e; cd "$P"; "$BP" test --target commonJS >"$WORK/c3c-js.log" 2>&1; echo "$?" >"$WORK/c3c-js.code" ) &
    ( set +e; cd "$P"; "$BP" test --target erlang >"$WORK/c3c-erl.log" 2>&1; echo "$?" >"$WORK/c3c-erl.code" ) &
    wait
    c3c_js="$(sed -n 's/^scratch=//p' "$WORK/c3c-js.log")"
    c3c_erl="$(sed -n 's/^scratch=//p' "$WORK/c3c-erl.log")"
    for t in js erl; do
      if [[ "$(cat "$WORK/c3c-$t.code")" == 0 ]]; then
        ok "the $t run's test wrote and read its scratch file"
      else
        fail "the $t run failed"; sed 's/^/      /' "$WORK/c3c-$t.log" | tail -20 >&2
      fi
    done
    [[ -n "$c3c_js" && -n "$c3c_erl" && "$c3c_js" != "$c3c_erl" ]] \
      && ok "two concurrent runs got two scratch directories" \
      || fail "scratch directories not distinct: '$c3c_js' vs '$c3c_erl'"
    c3c_real="$(cd "$P" && pwd -P)"
    [[ "$c3c_js" == "$c3c_real"/.botopinkbuild/test-out/commonJS/*.tmp && "$c3c_erl" == "$c3c_real"/.botopinkbuild/test-out/erlang/*.tmp ]] \
      && ok "each is the <id>.tmp beside its own run directory" \
      || fail "scratch directories outside their run: '$c3c_js' / '$c3c_erl'"
    [[ ! -e "$c3c_js" && ! -e "$c3c_erl" ]] \
      && ok "both scratch directories were removed with their runs" \
      || fail "a scratch directory survived its run"
  else
    skip "C3c test scratch directory (escript not installed)"
  fi

  # ── C3d — what a test writes to its scratch is not one of the run's modules ─
  # An erlang runner loads every `.erl` under its own directory before its
  # tests run (`'__bp_load_siblings'/0`). The scratch directory used to be the
  # run directory's `tmp/`, so a fixture project a test built there — its
  # `out/erl/` — was compiled and loaded by every test module that ran after
  # it: ~6 500 sources per module in rakun-scheduling, five CPU-minutes each,
  # and a fixture's module loaded over the run's own. Each test module here
  # leaves an `.erl` the OTP compiler refuses in the scratch directory; if any
  # runner reached it, that module would refuse to run.
  if have escript; then
    echo "==> C3d the scratch directory is outside every runner's sibling walk"
    P="$(project c3d)"
    printf 'pub fn one() -> i32 {\n    return 1;\n}\n' >"$P/src/main.bp"
    mkdir -p "$P/test"
    for m in a b c; do
      printf '%s\n' \
        'import {io: {env, fs}} from "std";' \
        'import {main.one};' '' \
        "test \"leaves a broken source in the scratch ($m)\" {" \
        '    val d = env.read("BOTOPINK_TEST_TMPDIR").unwrapOr("");' \
        "    val _w = fs.writeText(d + \"/junk_$m.erl\", \"-module(junk_$m). this is not erlang\");" \
        '    assert one() == 1;' \
        '}' >"$P/test/${m}_test.bp"
    done
    run "$P" test --target erlang
    expect_code 0 "erlang test with broken sources in the scratch directory"
    expect_no_out "does not compile" "no runner compiled a scratch file"
  else
    skip "C3d scratch outside the sibling walk (escript not installed)"
  fi

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
printf 'import { greet } from "sidelib";\n\npub fn main() {\n    @print(greet());\n}\n' >"$P/src/main.bp"
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
# 13 half 1: an erlang artifact lands at `<out>/erl/<module atom><ext>`, and the
# atom starts with the package (decision 109) — this project is named `c11`.
[[ -f "$P/out-eq/erl/c11@main.erl" && ! -e "$P/out-eq/main.js" ]] && ok "--target=erlang honoured" || fail "--target=erlang did not produce out-eq/erl/c11@main.erl"
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

echo "==> clean --help says what clean deletes"
run "$WORK" clean --help
expect_code 0 "clean --help"
expect_out "It deletes out/ and .botopinkbuild/ whole" "names both directories"
expect_out ".botopinkbuild/deps/" "names the bpmp links it takes with it"
run "$WORK" run -- --help
expect_no_out "It deletes out/" "a --help after -- is the program's, not the CLI's"

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
printf 'import { core } from "acme";\n\npub fn main() {\n    @print(core());\n}\n' >"$WS/examples/acme-app/src/main.bp"

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
printf 'import { answer } from "pathlib";\n\npub fn main() {\n    @print(answer());\n}\n' >"$P/src/main.bp"
run "$P" build
expect_code 0 "build with a path dependency (no library root involved)"

# ── `.mjs` sidecars (00 · 10-cli-residuals) ──────────────────────────────────
# A `#[@External.Node("./x.mjs", …)]` lowers to a relative `require` in the
# emitted module, and the CLI copies the source `.mjs` next to it. The owner of
# that file is the dependency the build RESOLVED — not the first directory of
# that name across the library roots — and a sidecar that cannot be shipped is
# a located error, never a silent exit 0 (decision 67: no flag turns it off).

# One library with a sidecar, as a workspace member, plus a decoy checkout that
# declares the same library name on another root.
sidecar_lib() { # <dir> <marker>
  mkdir -p "$1/src"
  cat >"$1/botopink.json" <<'JSON'
{ "name": "side", "version": "0.0.1", "target": "commonJS", "entry": "root.bp", "files": ["root.bp"] }
JSON
  printf '#[@External.Node("./side.mjs", "mark")]\npub declare fn mark() -> string;\n' >"$1/src/root.bp"
  printf 'module.exports = { mark: () => "%s" };\n' "$2" >"$1/src/side.mjs"
}
sidecar_app() { # <dir> <dependency-json>
  mkdir -p "$1/src"
  printf '{ "name": "side-app", "version": "0.0.1", "target": "commonJS", "entry": "main.bp",\n  "dependencies": { "side": %s } }\n' "$2" >"$1/botopink.json"
  printf 'import { mark } from "side";\n\npub fn main() {\n    @print(mark());\n}\n' >"$1/src/main.bp"
}

SWS="$WORK/sidews"; rm -rf "$SWS"
mkdir -p "$SWS/modules" "$SWS/examples"
cat >"$SWS/botopink.json" <<'JSON'
{ "name": "sidews", "version": "0.0.1", "targets": ["commonJS"],
  "workspaces": ["modules/*", "examples/*"] }
JSON
sidecar_lib "$SWS/modules/side" "from the workspace member"
sidecar_app "$SWS/examples/side-app" '{ "workspace": true }'

DECOY="$WORK/decoyroot"; rm -rf "$DECOY"
sidecar_lib "$DECOY/side" "from the decoy checkout"

echo "==> a workspace member's sidecar is shipped through the resolved dependency"
run "$SWS/examples/side-app" build
expect_code 0 "build of a member-dependency with a sidecar"
if [[ -f "$SWS/examples/side-app/out/side/side.mjs" ]]; then
  ok "out/side/side.mjs shipped"
  expect_file_out "$SWS/examples/side-app/out/side/side.mjs" "from the workspace member" "shipped from the resolved member, not by name"
else
  fail "out/side/side.mjs was not shipped"
fi

echo "==> a second checkout declaring the same name does not silence the shipper"
# Both entries named "side" are marked as a duplicate by `scanRoots`, so the
# by-name lookup answers nothing; the resolved `{ workspace: true }` dependency
# still does.
rm -rf "$SWS/examples/side-app/out"
set +e
OUT="$(cd "$SWS/examples/side-app" && BOTOPINK_LIB_ROOTS="$DECOY" "$BP" build 2>&1)"
CODE=$?
set -e
expect_code 0 "build with the library name declared twice across roots"
if [[ -f "$SWS/examples/side-app/out/side/side.mjs" ]]; then
  ok "out/side/side.mjs shipped despite the duplicate name"
  expect_file_out "$SWS/examples/side-app/out/side/side.mjs" "from the workspace member" "the resolved dependency wins over the decoy"
else
  fail "the duplicate name silenced the sidecar shipper"
fi

echo "==> a path dependency outside every library root ships its sidecar"
PLIB="$WORK/sidepath"; rm -rf "$PLIB"; sidecar_lib "$PLIB" "from the path dependency"
PAPP="$WORK/sidepathapp"; rm -rf "$PAPP"; sidecar_app "$PAPP" "{ \"path\": \"$PLIB\" }"
run "$PAPP" build
expect_code 0 "build with a path dependency carrying a sidecar"
if [[ -f "$PAPP/out/side/side.mjs" ]]; then
  ok "out/side/side.mjs shipped from the path dependency"
  expect_file_out "$PAPP/out/side/side.mjs" "from the path dependency" "shipped from the directory the build resolved"
else
  fail "a path dependency's sidecar was not shipped"
fi

echo "==> a sidecar that cannot be shipped is a located error, not exit 0"
rm -f "$PLIB/src/side.mjs"
rm -rf "$PAPP/out"
run "$PAPP" build
expect_code 1 "build whose dependency has no sidecar to ship"
expect_out 'dependency '"'"'side'"'"' requires "./side.mjs" from module '"'"'side/root'"'"'' "names the dependency, the require and the module"
expect_out "$PLIB/src/side.mjs" "names the last path it looked at"
expect_out "botopink.json:2:21" "locates the dependency entry of the project manifest"
[[ ! -e "$PAPP/out/side/side.mjs" ]] && ok "nothing half-shipped" || fail "a sidecar was written by the refused build"

# ── a built erlang / beam program loads its `.erl` sidecar ───────────────────
# `botopink run` is not the only way to start a build: `out/<target>/` is the
# program, and `erl -pa out/<target>` has to run it from any directory. The
# build ships the project's `src/sidecars/*.erl` beside the emitted modules
# (`libs.shipErlSidecars`). On beam the assembled entry's
# `'__bp_load_siblings'/0` compiles that `.erl` itself, so only the `.S` files
# are assembled here; on erlang every `.erl` of `out/erl/` is compiled, because
# a plain erlang build carries no sibling loader yet (02-erlang step 9).
# The program is `tests/language/modules/erlang_host_sidecar_shipped`.
echo "==> a built erlang / beam program loads its .erl sidecar under erl -pa"
if have erl && have erlc; then
  for T in erlang beam; do
    P="$WORK/built-sidecar-$T"; rm -rf "$P"
    cp -R "$REPO_ROOT/tests/language/modules/erlang_host_sidecar_shipped" "$P"
    run "$P" build --target "$T"
    expect_code 0 "build --target $T"
    D="$P/out/$([[ "$T" == erlang ]] && echo erl || echo beam)"
    [[ -f "$D/lt_greeter.erl" ]] && ok "$T: the sidecar is shipped into $(basename "$D")/" || fail "$T: $D/lt_greeter.erl was not shipped"
    set +e
    if [[ "$T" == erlang ]]; then
      COMPILE="$(erlc -o "$D" "$D"/*.erl 2>&1)"
    else
      COMPILE="$(erlc +from_asm -o "$D" "$D"/*.S 2>&1)"
    fi
    CC=$?
    OUT="$(cd "$WORK" && erl -noshell -pa "$D" -eval "'language_tests@main':main([]), halt()." 2>&1)"
    CODE=$?
    set -e
    [[ "$CC" -eq 0 ]] && ok "$T: the emitted modules compile with the OTP tools" || { fail "$T: erlc refused the build"; echo "$COMPILE" | sed 's/^/      /' >&2; }
    expect_code 0 "$T: erl -pa out runs the built program"
    if [[ "$OUT" == "$(cat "$P/expected.out")" ]]; then ok "$T: prints expected.out"; else fail "$T: printed '$OUT'"; fi
  done
else
  skip "built erlang / beam program (erl / erlc not on PATH)"
fi

# ── no command line grows with the number of modules ─────────────────────────
# `checkErlang` put every emitted `.erl` on `erl`'s argv and `run` every `.erl`
# / `.S` on `erlc`'s: a 203-module build with a 167-char `--out` passed
# macOS's 1 MiB ARG_MAX (execve E2BIG, reported as `SystemResources`) and the
# onze-cli builds failed on macos-14 only. The lists now go through a file
# (`cli/arglist.zig`). `ulimit -s 4096` sets Linux's ARG_MAX to 1 MiB, the
# macOS figure. 1 200 modules under a ~900-char `--out` (macOS's PATH_MAX is
# 1 024, so the depth stays below it) are ~1.1 MB of artifact paths, which the
# parent binary cannot hand to `erl` or `erlc` on either system.
echo "==> 1 200 modules under a deep --out build and run within a 1 MiB ARG_MAX"
if have erl && have erlc; then
  P="$(project manymods erlang)"
  {
    for i in $(seq 0 1199); do echo "pub mod m$i;"; done
    printf 'import {m7.f7};\n\npub fn main() {\n    @print(f7());\n}\n'
  } >"$P/src/main.bp"
  for i in $(seq 0 1199); do printf 'pub fn f%d() -> i32 {\n    return %d;\n}\n' "$i" "$i" >"$P/src/m$i.bp"; done
  SEG="$(printf 'd%.0s' $(seq 1 100))"
  DEEP="$P/out"; while [[ ${#DEEP} -lt 880 ]]; do DEEP="$DEEP/$SEG"; done
  for args in "run --target erlang" "run --target beam"; do
    set +e
    # shellcheck disable=SC2086
    OUT="$(cd "$P" && { ulimit -s 4096 2>/dev/null || true; "$BP" $args --out "$DEEP" 2>&1; })"
    CODE=$?
    set -e
    expect_code 0 "$args --out <${#DEEP} chars> with 1 200 modules"
    expect_no_out "SystemResources" "$args: no spawn failed"
    [[ "$(tail -n 1 <<<"$OUT")" == "7" ]] && ok "$args prints the program's output" || fail "$args: last line is '$(tail -n 1 <<<"$OUT")', not 7"
  done
  [[ -z "$(ls -A "$P/.botopinkbuild/tmp/arglist" 2>/dev/null)" ]] && ok "no list file is left behind" || fail "list files left in .botopinkbuild/tmp/arglist"
else
  skip "1 200 modules under a deep --out (erl / erlc not on PATH)"
fi

echo
if [[ "$failures" -gt 0 ]]; then
  echo "==> cli contract: $failures assertion(s) FAILED" >&2
  exit 1
fi
echo "==> cli contract: OK"
