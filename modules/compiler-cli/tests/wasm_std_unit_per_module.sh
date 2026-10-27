#!/usr/bin/env bash
# Decision 1026 — std split per module on wasm, cell `wasm_std_unit_per_module`,
# against the real CLI (a wasm conformance module cannot check its build's
# files), over `wasm_std_unit_per_module/`:
#   • `hello` (`print("hello, world")`) composes the runtime core and only the
#     std units it reaches: `build --target wasm` writes `main.wat` and
#     `std@__rt.wasm` and no other std unit, `main.wat`'s core modules are `$rt`
#     and `$main` (and the component's own adapters), and `run` (wasmtime over
#     the same `main.wat`) answers what the erlang run answers;
#   • `files` (writes and reads a file through `io.fs`) adds `std@io@fs` and the
#     units it imports: every std unit `main.wat` holds is one the build wrote,
#     `$std@io@fs` among them, each instantiated after the units it imports and
#     before `$main`, and it answers what the erlang run answers.
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
WORK="$(mktemp -d "${tmp_root%/}/botopink-wasm-std-units.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
cp -R "$SCRIPT_DIR/wasm_std_unit_per_module/." "$WORK/"

failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }

# <project>: build for wasm into out-<project>, run on erlang and under wasmtime,
# compare the answers.
answer() {
  local p="$1" dir="$WORK/$1"
  ( cd "$dir" && "$BP_BIN" build --target wasm --out "$WORK/out-$p" ) > "$WORK/$p-build.log" 2>&1 \
    || { fail "$p: the wasm build failed"; sed 's/^/      /' "$WORK/$p-build.log" >&2; return; }
  ( cd "$dir" && "$BP_BIN" run --target erlang --out "$WORK/erl-$p" ) > "$WORK/$p-erl.out" 2>&1 || fail "$p: the erlang run failed"
  grep -v -e 'Compiling' -e 'Compiled' "$WORK/$p-erl.out" > "$WORK/$p-want.out"
  # `run` runs the composed `main.wat` under wasmtime with the flags its needs
  # name (the file system's preopens for `files`).
  ( cd "$dir" && "$BP_BIN" run --target wasm --out "$WORK/run-$p" ) > "$WORK/$p-wasm.out" 2>&1 || fail "$p: the wasm run failed"
  diff "$WORK/$p-want.out" <(grep -v -e 'Compiling' -e 'Compiled' "$WORK/$p-wasm.out") > "$WORK/diff.log" \
    || { fail "$p: the wasm run answers otherwise than the erlang run"; sed 's/^/      /' "$WORK/diff.log" >&2; }
  cmp -s "$WORK/run-$p/main.wat" "$WORK/out-$p/main.wat" || fail "$p: the run's main.wat differs from the build's"
}

# The `$std@…` core modules `main.wat` holds, sorted.
held() { grep -oE '^  \(core module \$std@[^ ]+$' "$1" | sed 's/^  (core module \$//' | sort | tr '\n' ' '; }
# The std unit files a build wrote, sorted (the core's apart).
written() { ( cd "$1" && ls std@*.wasm 2>/dev/null | grep -v '^std@__rt\.wasm$' | sed 's/\.wasm$//' | sort | tr '\n' ' ' ) || true; }

answer hello
if [[ -f "$WORK/out-hello/main.wat" ]]; then
  files="$(cd "$WORK/out-hello" && find . -type f | sort | tr '\n' ' ')"
  [[ "$files" == "./main.wat ./std@__rt.wasm " ]] || fail "hello: the build wrote ${files:-nothing}, not main.wat and std@__rt.wasm alone"
  grep -q '^  (core module \$rt$' "$WORK/out-hello/main.wat" || fail "hello: main.wat holds no runtime core \$rt"
  [[ -z "$(held "$WORK/out-hello/main.wat")" ]] || fail "hello: main.wat holds std units it does not reach: $(held "$WORK/out-hello/main.wat")"
fi

answer files
if [[ -f "$WORK/out-files/main.wat" ]]; then
  units="$(held "$WORK/out-files/main.wat")"
  [[ " $units" == *" std@io@fs "* ]] || fail "files: main.wat holds no std@io@fs (it holds: ${units:-none})"
  [[ "$units" == "$(written "$WORK/out-files")" ]] || fail "files: main.wat holds ${units:-none}, the build wrote $(written "$WORK/out-files")"
  # Each unit instantiated after what it imports, all before $main.
  order="$(grep -oE '^  \(core instance \$[^ ]+' "$WORK/out-files/main.wat" | sed 's/^  (core instance \$//')"
  pos() { echo "$order" | grep -nx "$1" | cut -d: -f1; }
  for u in $units; do
    [[ -n "$(pos "$u")" && "$(pos "$u")" -lt "$(pos main)" ]] || fail "files: $u is not instantiated before \$main"
    deps="$(awk -v u="  (core instance \$$u (instantiate \$$u" 'index($0, u) == 1' "$WORK/out-files/main.wat" | grep -oE '\(with "std@[^"]+"' | sed 's/(with "//; s/"//' | grep -v '^std@__rt$' || true)"
    for d in $deps; do
      [[ " $units" == *" $d "* ]] || fail "files: $u imports $d, which main.wat does not hold"
      [[ "$(pos "$d")" -lt "$(pos "$u")" ]] || fail "files: $u is instantiated before $d, which it imports"
    done
  done
fi

if (( failures > 0 )); then
  echo "wasm_std_unit_per_module: $failures failure(s)" >&2
  exit 1
fi
echo "wasm_std_unit_per_module: ok"
