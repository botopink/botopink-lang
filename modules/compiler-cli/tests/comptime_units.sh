#!/usr/bin/env bash
# Decisions 1033 (3), 1035 (1), (3), 1038 (4), 1058 (2), (3) — piece C1, the `.comptime` stage,
# against the real CLI, over `comptime_units/app` (`main` declares a decorator and imports `lib`;
# `gap` writes a `comptime` the WasmGC generator refuses today):
#   • written with an `out/`: `build --target erlang` writes `out/wasm-comptime/` — `app@main.wasm`,
#     `app@lib.wasm`, the runtime core `std@__rt.wasm` and the std units they import, each std
#     file the bytes `zig build std-wasm` writes (`out/wasm/`'s) — whatever the target;
#   • a bare `build` writes no `out/` (decision 1077 (5)): its comptime units are in the unit
#     cache `.botopinkbuild/cache/unit/comptime/` alone;
#   • refusals recorded: `gap` is a `gap<TAB><the gap>` line of `refused.txt`, the build exits 0
#     and nothing of the stage is on stderr; `build --json` reports it as a `comptime_refused` event;
#   • every unit is compiled into `.botopinkbuild/cache/wasmtime/<sha256>.cwasm`;
#   • a build from a fresh `.bpr` set evaluates nothing and writes no comptime unit;
#   • `--cold` clears the folder and writes it again.
#
# BOTOPINK_BIN points the script at another binary. Exit 0 = every behaviour held.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

if [[ -z "${BOTOPINK_SKIP_BUILD:-}" && -z "${BOTOPINK_BIN:-}" ]]; then
  echo "==> building botopink CLI and std's units"
  ( cd "$REPO_ROOT" && zig build && zig build std-wasm )
fi
BP_BIN="${BOTOPINK_BIN:-$REPO_ROOT/zig-out/bin/botopink}"
if [[ ! -x "$BP_BIN" ]]; then
  echo "error: CLI binary not found at $BP_BIN" >&2
  exit 1
fi
STD_UNITS="$REPO_ROOT/zig-out/lib/std-wasm"

tmp_root="${TMPDIR:-/tmp}"
WORK="$(mktemp -d "${tmp_root%/}/botopink-comptime-units.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
cp -R "$SCRIPT_DIR/comptime_units/." "$WORK/"
APP="$WORK/app"

failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }

bp() { # <log> <command…>: the command in `app`, its stdout and stderr to <log>
  local log="$1"; shift
  ( cd "$APP" && env "$@" ) > "$log" 2>&1
}

( cd "$APP" && "$BP_BIN" build --target erlang --out "$WORK/out" ) > "$WORK/build.log" 2> "$WORK/build.err" || { fail "the build failed"; sed 's/^/      /' "$WORK/build.err" >&2; }
grep -qi 'comptime\|wasm' "$WORK/build.err" && fail "the stage printed on stderr: $(cat "$WORK/build.err")"
CT="$WORK/out/wasm-comptime"
for f in app@main.wasm app@lib.wasm std@__rt.wasm; do
  [[ -f "$CT/$f" ]] || fail "out/wasm-comptime/$f was not written"
done
grep -q $'^gap\tthe comptime unit of `gap` needs a lowering' "$CT/refused.txt" 2>/dev/null || fail "refused.txt does not record gap: $(cat "$CT/refused.txt" 2>/dev/null)"
for f in "$CT"/*.wasm; do
  name="$(basename "$f")"
  case "$name" in
    std@*) [[ -f "$STD_UNITS/$name" ]] && cmp -s "$f" "$STD_UNITS/$name" || fail "out/wasm-comptime/$name is not the bytes of zig-out/lib/std-wasm/$name" ;;
    app@main.wasm|app@lib.wasm) ;;
    *) fail "out/wasm-comptime/$name is no unit a comptime module reaches" ;;
  esac
done
n_files="$(find "$CT" -name '*.wasm' | wc -l)"
n_cwasm="$(find "$APP/.botopinkbuild/cache/wasmtime" -name '*.cwasm' 2>/dev/null | wc -l)"
(( n_cwasm >= n_files )) || fail "$n_files comptime units, $n_cwasm precompiled artifacts"

# A build from the fresh `.bpr` set the first one left analyses nothing.
rm -r "$CT"
bp "$WORK/again.log" "$BP_BIN" build --target erlang --out "$WORK/out" || fail "the build from the .bpr set failed"
[[ ! -e "$CT" ]] || fail "a build from a fresh .bpr set wrote out/wasm-comptime/"

# `--cold` clears the folder: a stray file goes, the units come back.
bp "$WORK/cold0.log" "$BP_BIN" build --target erlang --out "$WORK/out" --cold || fail "the cold build failed"
echo stray > "$CT/stray.wasm"
bp "$WORK/cold.log" "$BP_BIN" build --target erlang --out "$WORK/out" --cold || fail "the cold build failed"
[[ ! -e "$CT/stray.wasm" ]] || fail "--cold left a stray file in out/wasm-comptime/"
[[ -f "$CT/app@main.wasm" ]] || fail "--cold did not write app@main.wasm again"

# The `--json` report names the refusal.
bp "$WORK/json.log" "$BP_BIN" build --target erlang --out "$WORK/out-json" --cold --json || true
grep -q '"event":"comptime_refused","module":"gap"' "$WORK/json.log" || fail "build --json reports no comptime_refused event for gap"

# A bare build (decision 1077 (5)): no `out/`, the units in the unit cache.
BARE="$WORK/bare"
cp -R "$SCRIPT_DIR/comptime_units/app" "$BARE"
( cd "$BARE" && "$BP_BIN" build ) > "$WORK/bare.log" 2>&1 || fail "the bare build failed: $(cat "$WORK/bare.log")"
[[ ! -e "$BARE/out" ]] || fail "a bare build wrote out/"
n_units="$(find "$BARE/.botopinkbuild/cache/unit/comptime" -name '*.bpcu' 2>/dev/null | wc -l)"
(( n_units > 0 )) || fail "a bare build left no comptime unit in .botopinkbuild/cache/unit/comptime/"

if (( failures > 0 )); then
  echo "comptime_units: $failures failure(s)" >&2
  exit 1
fi
echo "comptime_units: ok"
