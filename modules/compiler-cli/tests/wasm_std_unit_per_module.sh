#!/usr/bin/env bash
# Decision 1026 — std split per module on wasm, cell `wasm_std_unit_per_module`, against the real
# CLI (a wasm conformance module cannot check its build's files), over `wasm_std_unit_per_module/`:
#   • `hello` (`print("hello, world")`) composes the runtime core and only the std units it
#     reaches: `build --target wasm` writes `hello@main.wasm` / `.wat` and `std@__rt.wasm` and no
#     other std unit, and `run` (the runner composing them) answers what the erlang run answers;
#   • `files` (writes and reads a file through `io.fs`) adds `std@io@fs` and the units it imports:
#     the std units the entry's `botopink.units` names are exactly the ones the build wrote,
#     `std@io@fs` among them, the core first and the entry last, and it answers what the erlang
#     run answers.
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
WORK="$(mktemp -d "${tmp_root%/}/botopink-wasm-std-units.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
cp -R "$SCRIPT_DIR/wasm_std_unit_per_module/." "$WORK/"

failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }

# <project>: build for wasm into out-<project>, run on erlang and on wasm, compare the answers.
answer() {
  local p="$1" dir="$WORK/$1"
  ( cd "$dir" && "$BP_BIN" build --target wasm --out "$WORK/out-$p" ) > "$WORK/$p-build.log" 2>&1 \
    || { fail "$p: the wasm build failed"; sed 's/^/      /' "$WORK/$p-build.log" >&2; return; }
  ( cd "$dir" && "$BP_BIN" run --target erlang --out "$WORK/erl-$p" ) > "$WORK/$p-erl.out" 2>&1 || fail "$p: the erlang run failed"
  grep -v -e 'Compiling' -e 'Compiled' "$WORK/$p-erl.out" > "$WORK/$p-want.out"
  ( cd "$dir" && "$BP_BIN" run --target wasm --out "$WORK/run-$p" ) > "$WORK/$p-wasm.out" 2>&1 || fail "$p: the wasm run failed"
  diff "$WORK/$p-want.out" <(grep -v -e 'Compiling' -e 'Compiled' "$WORK/$p-wasm.out") > "$WORK/diff.log" \
    || { fail "$p: the wasm run answers otherwise than the erlang run"; sed 's/^/      /' "$WORK/diff.log" >&2; }
  diff -r "$WORK/run-$p" "$WORK/out-$p" > /dev/null || fail "$p: the run's files differ from the build's"
}
# The units the entry's `botopink.units` names, in order, one per line.
named() { grep -o '(@custom "botopink.units" "[^"]*")' "$1" | sed 's/^(@custom "botopink.units" "//; s/")$//; s/\\0a/\n/g' | grep .; }
# The std unit files a build wrote, sorted (the core's apart).
written() { ( cd "$1" && ls std@*.wasm 2>/dev/null | grep -v '^std@__rt\.wasm$' | sed 's/\.wasm$//' | LC_ALL=C sort | tr '\n' ' ' ) || true; }

answer hello
W="$WORK/out-hello/wasm"
if [[ -f "$W/hello@main.wat" ]]; then
  files="$(cd "$W" && ls | LC_ALL=C sort | tr '\n' ' ')"
  [[ "$files" == "hello@main.wasm hello@main.wat std@__rt.wasm " ]] || fail "hello: the build wrote ${files:-nothing}, not hello@main.wasm / .wat and std@__rt.wasm alone"
  [[ "$(named "$W/hello@main.wat" | tr '\n' ' ')" == "std@__rt hello@main " ]] || fail "hello: botopink.units names $(named "$W/hello@main.wat" | tr '\n' ' ')"
fi

answer files
W="$WORK/out-files/wasm"
if [[ -f "$W/files@main.wat" ]]; then
  units="$(named "$W/files@main.wat")"
  [[ "$(head -1 <<< "$units")" == std@__rt && "$(tail -1 <<< "$units")" == files@main ]] || fail "files: botopink.units does not open with the core and end with the entry"
  stds="$(grep '^std@' <<< "$units" | grep -v '^std@__rt$' | LC_ALL=C sort | tr '\n' ' ')"
  [[ " $stds" == *" std@io@fs "* ]] || fail "files: botopink.units names no std@io@fs (it names: ${stds:-none})"
  [[ "$stds" == "$(written "$W")" ]] || fail "files: botopink.units names ${stds:-none}, the build wrote $(written "$W")"
fi

if (( failures > 0 )); then
  echo "wasm_std_unit_per_module: $failures failure(s)" >&2
  exit 1
fi
echo "wasm_std_unit_per_module: ok"
