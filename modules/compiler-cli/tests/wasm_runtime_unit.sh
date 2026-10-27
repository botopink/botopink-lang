#!/usr/bin/env bash
# Decisions 1021 (2), 1026, 1032 (1) — the runtime core `std@__rt.wasm` and std's units, against
# the real CLI, over `wasm_runtime_unit/hello`, a one-module program that prints a string, an
# integer, a float (std-wasm's `number.floatToString`) and a split string (`text.split`):
#   • `build --target wasm` writes the entry `hello@main.wasm` (and its `.wat`), `std@__rt.wasm`
#     and the two std units it reaches, `std@number.wasm` and `std@string.wasm`, and nothing else;
#     the entry's `botopink.units` names them, the core first and the entry last;
#   • the core exports no std module's function (no `std:` export);
#   • `std@__rt.wasm` is the core's bytes, the same for any program: another program's build
#     writes the same file, and a build over a folder that already holds it leaves it as it is;
#   • `run --target wasm` (the runner composing the units) answers what the erlang run answers;
#   • the entry imports `number.floatToString` from `std@number` and its memory from `std@__rt`,
#     and its text is under 50 KB (std's `.bp` bodies are linked into importers until P4c-std,
#     decision 1072 (2)).
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
W="$OUT/wasm"
bp "$WORK/build.log" build --target wasm --out "$OUT" || { fail "the wasm build failed"; sed 's/^/      /' "$WORK/build.log" >&2; }
files="$(cd "$W" && ls | LC_ALL=C sort | tr '\n' ' ')"
[[ "$files" == "hello@main.wasm hello@main.wat std@__rt.wasm std@number.wasm std@string.wasm " ]] \
  || fail "the build wrote ${files:-nothing}, not hello@main.wasm / .wat, std@__rt.wasm, std@number.wasm and std@string.wasm"
grep -q '(@custom "botopink.units" "std@__rt\\0astd@number\\0astd@string\\0ahello@main\\0a")' "$W/hello@main.wat" \
  || fail "the entry's botopink.units is not std@__rt, std@number, std@string, hello@main"

# The erlang run is the answer.
bp "$WORK/erl.out" run --target erlang --out "$WORK/out-erl" || fail "the erlang run failed"
grep -v -e 'Compiling' -e 'Compiled' "$WORK/erl.out" > "$WORK/want.out"
bp "$WORK/run.out" run --target wasm --out "$WORK/out-run" || fail "the wasm run failed"
diff "$WORK/want.out" <(grep -v -e 'Compiling' -e 'Compiled' "$WORK/run.out") > "$WORK/diff.log" \
  || { fail "the wasm run answers otherwise than the erlang run"; sed 's/^/      /' "$WORK/diff.log" >&2; }
cmp -s "$W/std@__rt.wasm" "$WORK/out-run/wasm/std@__rt.wasm" || fail "the run's std@__rt.wasm differs from the build's"

# The entry and the core.
grep -q '(import "std@number" "std:number.floatToString"' "$W/hello@main.wat" || fail "the entry does not import std:number.floatToString from std@number"
grep -q '(memory (export "memory") (import "std@__rt" "memory")' "$W/hello@main.wat" || fail "the entry does not import its memory from std@__rt"
if strings "$W/std@__rt.wasm" | grep -q '^std:'; then fail "the core exports a std module's function"; fi
size="$(wc -c < "$W/hello@main.wat")"
(( size < 50000 )) || fail "the entry's text is $size bytes, not under 50 KB"

# Written once: a build over a folder that holds the core leaves it as it is;
# another program's build writes the same bytes.
touch -d '2000-01-01 00:00:00' "$W/std@__rt.wasm"
before="$(stat -c %Y "$W/std@__rt.wasm")"
bp "$WORK/build2.log" build --target wasm --out "$OUT" || fail "the second wasm build failed"
[[ "$(stat -c %Y "$W/std@__rt.wasm")" == "$before" ]] || fail "the second build wrote std@__rt.wasm again"
printf 'import {io.terminal.print} from "std";\n\nfn main() -> void {\n    print(7);\n}\n' > "$APP/src/main.bp"
bp "$WORK/build3.log" build --target wasm --out "$WORK/out-other" || fail "the other program's wasm build failed"
cmp -s "$W/std@__rt.wasm" "$WORK/out-other/wasm/std@__rt.wasm" || fail "another program's std@__rt.wasm differs"

if (( failures > 0 )); then
  echo "wasm_runtime_unit: $failures failure(s)" >&2
  exit 1
fi
echo "wasm_runtime_unit: ok"
