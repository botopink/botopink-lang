#!/usr/bin/env bash
# Decisions 1021 (2), 1026 — the runtime core `std@__rt.wasm` and std's units, against the real CLI,
# over `wasm_runtime_unit/hello`, a one-module program that prints a string, an
# integer, a float (std-wasm's `number.floatToString`) and a split string
# (std-wasm's `text.split`):
#   • `build --target wasm` writes the entry's `main.wat`, `std@__rt.wasm` and
#     the two std units it reaches, `std@number.wasm` and `std@string.wasm`, and
#     nothing else;
#   • the core holds no std module's function (no `std:` export in `$rt`);
#   • `std@__rt.wasm` is the core's bytes, the same for any program:
#     the build of a second program writes the same file, and a build over an
#     output directory that already holds it leaves it as it is (written once);
#   • the program answers under `wasmtime run` what the erlang run answers (the
#     one-module program answers as before);
#   • the entry's own core module (`$main` in the component) imports
#     `number.floatToString` from `std@number`, its memory and its heap from
#     `std@__rt`, carries none of std-wasm's decoded functions, and its text is
#     under 50 KB.
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
if ! command -v wasmtime >/dev/null 2>&1; then
  echo "error: wasmtime is not on PATH (decision 67: a missing runtime fails)" >&2
  exit 1
fi

tmp_root="${TMPDIR:-/tmp}"
WORK="$(mktemp -d "${tmp_root%/}/botopink-wasm-runtime-unit.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
cp -R "$SCRIPT_DIR/wasm_runtime_unit/." "$WORK/"
APP="$WORK/hello"

failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }

bp() { # <log> <args…>: the CLI in `hello`, its stdout and stderr to <log>
  local log="$1"; shift
  ( cd "$APP" && "$BP_BIN" "$@" ) > "$log" 2>&1
}

OUT="$WORK/out-wasm"
bp "$WORK/build.log" build --target wasm --out "$OUT" || { fail "the wasm build failed"; sed 's/^/      /' "$WORK/build.log" >&2; }
files="$(cd "$OUT" && find . -type f | LC_ALL=C sort | tr '\n' ' ')"
[[ "$files" == "./main.wat ./std@__rt.wasm ./std@number.wasm ./std@string.wasm " ]] || fail "the build wrote ${files:-nothing}, not main.wat, std@__rt.wasm, std@number.wasm and std@string.wasm"

# The erlang run is the answer.
bp "$WORK/erl.out" run --target erlang --out "$WORK/out-erl" || fail "the erlang run failed"
grep -v -e 'Compiling' -e 'Compiled' "$WORK/erl.out" > "$WORK/want.out"
wasmtime run -W gc=y -W exceptions=y "$OUT/main.wat" > "$WORK/wt.out" 2>&1 || fail "wasmtime failed on main.wat"
diff "$WORK/want.out" "$WORK/wt.out" > "$WORK/diff.log" \
  || { fail "main.wat answers otherwise under wasmtime than the erlang run"; sed 's/^/      /' "$WORK/diff.log" >&2; }
bp "$WORK/run.out" run --target wasm --out "$WORK/out-run" || fail "the wasm run failed"
diff "$WORK/want.out" <(grep -v -e 'Compiling' -e 'Compiled' "$WORK/run.out") > "$WORK/diff.log" \
  || { fail "the wasm run answers otherwise than the erlang run"; sed 's/^/      /' "$WORK/diff.log" >&2; }
cmp -s "$OUT/std@__rt.wasm" "$WORK/out-run/std@__rt.wasm" || fail "the run's std@__rt.wasm differs from the build's"

# The entry's own core module.
awk '/^  \(core module \$main$/{f=1} /^  \(core module \$p1_shim$/{f=0} f' "$OUT/main.wat" > "$WORK/entry.wat"
[[ -s "$WORK/entry.wat" ]] || fail "main.wat holds no core module \$main"
grep -q '^  (core module \$rt$' "$OUT/main.wat" || fail "main.wat holds no core module \$rt (the runtime unit)"
grep -q '(import "std@number" "std:number.floatToString"' "$WORK/entry.wat" || fail "the entry does not import std:number.floatToString from std@number"
awk '/^  \(core module \$rt$/{f=1; next} /^  \(core module /{f=0} f' "$OUT/main.wat" > "$WORK/core.wat"
if grep -q '(export "std:' "$WORK/core.wat"; then fail "the core exports a std module's function"; fi
grep -q '(memory (export "memory") (import "std@__rt" "memory")' "$WORK/entry.wat" || fail "the entry does not import its memory from std@__rt"
grep -q '(global $__heap_ptr (import "std@__rt" "__heap_ptr")' "$WORK/entry.wat" || fail "the entry does not import the heap pointer from std@__rt"
# std-wasm's decoded functions (`std_wasm.wasm`'s); its `.wat` leaves stay with the
# unit that calls them until the canonical type groups let the runtime unit hold them.
if grep -q -e 'std-wasm (decision 440)' -e '^  (func \$__std_f[0-9]' -e '^  (func \$__std_number_floatToString' "$WORK/entry.wat"; then fail "the entry carries std-wasm's functions"; fi
size="$(wc -c < "$WORK/entry.wat")"
(( size < 50000 )) || fail "the entry's core module is $size bytes, not under 50 KB"

# Written once: a build over an output directory that holds the unit leaves it
# as it is; another program's build writes the same bytes.
touch -d '2000-01-01 00:00:00' "$OUT/std@__rt.wasm"
before="$(stat -c %Y "$OUT/std@__rt.wasm")"
bp "$WORK/build2.log" build --target wasm --out "$OUT" || fail "the second wasm build failed"
[[ "$(stat -c %Y "$OUT/std@__rt.wasm")" == "$before" ]] || fail "the second build wrote std@__rt.wasm again"
printf 'import {io.terminal.print} from "std";\n\nfn main() -> void {\n    print(7);\n}\n' > "$APP/src/main.bp"
bp "$WORK/build3.log" build --target wasm --out "$WORK/out-other" || fail "the other program's wasm build failed"
cmp -s "$OUT/std@__rt.wasm" "$WORK/out-other/std@__rt.wasm" || fail "another program's std@__rt.wasm differs"

if (( failures > 0 )); then
  echo "wasm_runtime_unit: $failures failure(s)" >&2
  exit 1
fi
echo "wasm_runtime_unit: ok"
