#!/usr/bin/env bash
# Decisions 1033 (3), 1035 (1), (3), 1038 (4) — piece C1, the `.comptime` stage, against the real
# CLI, over `comptime_units/app` (`main` declares a decorator and imports `lib`):
#   • with BOTOPINK_COMPTIME_UNITS=1, `build --target erlang` writes `out/wasm-comptime/`:
#     `app@main.wasm` (the decorator's module), `app@lib.wasm` (the program unit it imports),
#     the runtime core `std@__rt.wasm` and the std units they import — whatever the target;
#   • each std file there is the bytes `zig build std-wasm` writes (`zig-out/lib/std-wasm/`),
#     the ones `out/wasm/` holds;
#   • every file of the folder is compiled into `.botopinkbuild/cache/wasmtime/<sha256>.cwasm`;
#   • the program's own output is the build's without the switch, and without it no
#     `wasm-comptime/` folder is written.
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

bp() { # <log> <env…> -- <args…>: the CLI in `app`, its stdout and stderr to <log>
  local log="$1"; shift
  ( cd "$APP" && env "$@" ) > "$log" 2>&1
}

bp "$WORK/on.log" BOTOPINK_COMPTIME_UNITS=1 "$BP_BIN" build --target erlang --out "$WORK/out-on" || { fail "the build with the switch failed"; sed 's/^/      /' "$WORK/on.log" >&2; }
CT="$WORK/out-on/wasm-comptime"
for f in app@main.wasm app@lib.wasm std@__rt.wasm; do
  [[ -f "$CT/$f" ]] || fail "out/wasm-comptime/$f was not written"
done
for f in "$CT"/*.wasm; do
  name="$(basename "$f")"
  case "$name" in
    std@*) [[ -f "$STD_UNITS/$name" ]] && cmp -s "$f" "$STD_UNITS/$name" || fail "out/wasm-comptime/$name is not the bytes of zig-out/lib/std-wasm/$name" ;;
    app@main.wasm|app@lib.wasm) ;;
    *) fail "out/wasm-comptime/$name is no unit a comptime module reaches" ;;
  esac
done
# The stage runs where comptime runs: the build with the switch came first, from
# nothing; this one emits from the `.bpr` set it left.
bp "$WORK/off.log" "$BP_BIN" build --target erlang --out "$WORK/out-off" || { fail "the build without the switch failed"; sed 's/^/      /' "$WORK/off.log" >&2; }
[[ ! -e "$WORK/out-off/wasm-comptime" ]] || fail "the build without the switch wrote out/wasm-comptime/"

n_files="$(find "$CT" -name '*.wasm' | wc -l)"
n_cwasm="$(find "$APP/.botopinkbuild/cache/wasmtime" -name '*.cwasm' 2>/dev/null | wc -l)"
(( n_cwasm >= n_files )) || fail "$n_files comptime units, $n_cwasm precompiled artifacts"

diff -r "$WORK/out-off/erlang" "$WORK/out-on/erlang" > /dev/null || fail "the switch changed the program's own output"

if (( failures > 0 )); then
  echo "comptime_units: $failures failure(s)" >&2
  exit 1
fi
echo "comptime_units: ok"
