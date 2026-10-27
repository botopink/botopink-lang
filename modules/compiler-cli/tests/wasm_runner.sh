#!/usr/bin/env bash
# Decisions 1032 (2), (3), (7), 1034 (5), (6), (8) — the in-process runner composing a
# `wasi` program from its separate units, against the real CLI, over `wasm_runner/`
# (a CLI behaviour a program cannot see, decisions 1020, 1064 (3): row 1032's proof,
# and the io.fs half of `wasm_runner_keeps_wasi_p2`). Every wasm command runs
# with `wasmtime` off `PATH`:
#   • `one` and `two` (a two-module program: its own `two@util` unit linked) both
#     reach `std@string`; run under one cache root, `run --target wasm` answers
#     what the erlang run answers, the build writes the entry `<pkg>@main.wasm`
#     and each unit `botopink.units` names beside it (no component), and
#     `.botopinkbuild/cache/wasmtime/` holds one `.cwasm` per unit and one per
#     frame: the second program compiles only what the first did not reach
#     (its own units and its frame), every file of the first left as it was
#     (inode and mtime) — `std@string` compiled once;
#   • a second `run` of `two` compiles nothing (no `.cwasm` written or changed);
#   • `files` (`io.fs`: writes and reads a file) runs with the file system
#     given (decision 1034 (7)) and answers what the erlang run answers;
#   • `test --target wasm` over `two` runs `util`'s test entry composed with its
#     units and passes.
# The `wasi:http` half of `wasm_runner_keeps_wasi_p2` is the runner's zig test
# (`tests/wat.zig`, `runner.runEntry`, decision 1064 (1)): no std binding reaches
# `wasi:http` on the `wasi` host today. A unit is compiled once per cache root
# (1064 (2)), so the two programs share `--cache-root`. Until P4c-std, std's
# `.bp` is linked into importers (decision 1072 (2)): `std@string` here is
# std-wasm's unit, and this is not yet the whole proof of
# `wasm_units_precompiled_once`.
#
# BOTOPINK_BIN points the script at another binary. Exit 0 = every behaviour held.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

if [[ -z "${BOTOPINK_SKIP_BUILD:-}" && -z "${BOTOPINK_BIN:-}" ]]; then
  echo "==> building botopink CLI"
  ( cd "$REPO_ROOT" && zig build )
fi
BP_BIN="${BOTOPINK_BIN:-$REPO_ROOT/zig-out/bin/botopink}"
if [[ ! -x "$BP_BIN" ]]; then
  echo "error: CLI binary not found at $BP_BIN" >&2
  exit 1
fi

tmp_root="${TMPDIR:-/tmp}"
WORK="$(mktemp -d "${tmp_root%/}/botopink-wasm-runner.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
cp -R "$SCRIPT_DIR/wasm_runner/." "$WORK/"
CACHE="$WORK/cache-root"
WT="$CACHE/.botopinkbuild/cache/wasmtime"

failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }
show() { sed 's/^/      /' "$1" >&2; }

# PATH without any directory holding `wasmtime`.
NOWT_PATH=""
IFS=: read -r -a dirs <<< "$PATH"
for d in "${dirs[@]}"; do
  [[ -n "$d" && ! -x "$d/wasmtime" ]] && NOWT_PATH="${NOWT_PATH:+$NOWT_PATH:}$d"
done
if PATH="$NOWT_PATH" command -v wasmtime >/dev/null 2>&1; then
  fail "wasmtime is still on the stripped PATH"
fi

# <project> <log> <args…>: the CLI in the project, wasmtime off PATH.
bp() {
  local p="$1" log="$2"; shift 2
  ( cd "$WORK/$p" && PATH="$NOWT_PATH" "$BP_BIN" "$@" ) > "$log" 2>&1
}
# The erlang run's answer of <project>, into <file>.
want() {
  ( cd "$WORK/$1" && "$BP_BIN" run --target erlang --out "$WORK/erl-$1" ) > "$WORK/$1-erl.out" 2>&1 || fail "$1: the erlang run failed"
  grep -v -e 'Compiling' -e 'Compiled' "$WORK/$1-erl.out" > "$2"
}
# Every `.cwasm` with its inode and mtime, sorted.
cwasms() { ( cd "$WT" 2>/dev/null && find . -maxdepth 1 -name '*.cwasm' -printf '%f %i %T@\n' | LC_ALL=C sort ) || true; }
count() { cwasms | grep -c . || true; }

# <project>: run on wasm under the shared cache root; the answer is erlang's.
run_wasm() {
  local p="$1"
  bp "$p" "$WORK/$p-wasm.out" run --target wasm --cache-root "$CACHE" --out "$WORK/out-$p" \
    || { fail "$p: the wasm run failed"; show "$WORK/$p-wasm.out"; return; }
  want "$p" "$WORK/$p-want.out"
  diff "$WORK/$p-want.out" <(grep -v -e 'Compiling' -e 'Compiled' "$WORK/$p-wasm.out") > "$WORK/diff.log" \
    || { fail "$p: the wasm run answers otherwise than the erlang run"; show "$WORK/diff.log"; }
}
# The stems of the unit files beside <project>'s entry, sorted.
units_of() { ( cd "$WORK/out-$1/wasm" && ls *.wasm | sed 's/\.wasm$//' | LC_ALL=C sort ) || true; }

# ── one, then two: std@string compiled once ──────────────────────────────────
run_wasm one
units_one="$(units_of one)"
[[ -f "$WORK/out-one/wasm/one@main.wasm" ]] || fail "one: no entry one@main.wasm"
grep -qx 'std@string' <<< "$units_one" || fail "one: no std@string.wasm beside the entry (units: $(echo $units_one))"
n_one="$(count)"
[[ "$n_one" == "$(( $(grep -c . <<< "$units_one") + 1 ))" ]] \
  || fail "one: $n_one .cwasm, not one per unit ($(echo $units_one)) and one for the frame"
cwasms > "$WORK/cw-one"

run_wasm two
units_two="$(units_of two)"
grep -qx 'two@util' <<< "$units_two" || fail "two: its own module's unit two@util.wasm is not beside the entry"
grep -qx 'std@string' <<< "$units_two" || fail "two: no std@string.wasm beside the entry"
shared=0
for s in $units_two; do
  if [[ -f "$WORK/out-one/wasm/$s.wasm" ]] && cmp -s "$WORK/out-one/wasm/$s.wasm" "$WORK/out-two/wasm/$s.wasm"; then shared=$((shared + 1)); fi
done
(( shared >= 2 )) || fail "two: shares $shared unit file(s) with one, not the core and std@string at least"
n_two="$(count)"
[[ "$n_two" == "$(( n_one + $(grep -c . <<< "$units_two") - shared + 1 ))" ]] \
  || fail "two: $n_two .cwasm after it, not $n_one plus its units one did not reach and its frame"
cwasms > "$WORK/cw-two"
missing="$(LC_ALL=C comm -23 "$WORK/cw-one" "$WORK/cw-two")"
[[ -z "$missing" ]] || { fail "two: a .cwasm of one was compiled again or removed"; echo "$missing" | sed 's/^/      /' >&2; }

# A run with nothing changed compiles nothing.
run_wasm two
cwasms > "$WORK/cw-again"
cmp -s "$WORK/cw-two" "$WORK/cw-again" || { fail "two: a run with nothing changed wrote a .cwasm"; diff "$WORK/cw-two" "$WORK/cw-again" | sed 's/^/      /' >&2 || true; }
[[ ! -e "$HOME/.cache/wasmtime" || -z "$(find "$HOME/.cache/wasmtime" -newer "$WORK/cw-one" -print -quit 2>/dev/null)" ]] \
  || fail "wasmtime wrote under \$HOME/.cache"

# ── files: io.fs through the runner ──────────────────────────────────────────
run_wasm files
grep -qx 'std@io@fs' <<< "$(units_of files)" || fail "files: no std@io@fs.wasm beside the entry"

# ── test on wasm through the runner ──────────────────────────────────────────
bp two "$WORK/two-test.out" test --target wasm || { fail "two: test --target wasm failed"; show "$WORK/two-test.out"; }
grep -q 'ok   greet says hi' "$WORK/two-test.out" || { fail "two: util's test did not pass on wasm"; show "$WORK/two-test.out"; }

if (( failures > 0 )); then
  echo "wasm_runner: $failures failure(s)" >&2
  exit 1
fi
echo "wasm_runner: ok"
