#!/usr/bin/env bash
# Cell `wasm_pack_runs_standalone` (decisions 1036, 1079 (2)) — `botopink pack`
# against the real CLI, over `wasm_pack/` (a CLI behaviour, decision 1020):
#   • `one` (one module), `two` (two modules: its own `two@util` unit) and
#     `files` (`io.fs`) are packed; each writes `dist/<pkg>.wasm` at the
#     package root, and `pack` builds first when `out/wasm/` is absent;
#   • structurally, always: the packed file is a component whose every
#     top-level import is `wasi:*` — no `unit-<k>`, no `std@…`, no `bp_*` —
#     each import that is not named; and every unit file of the build
#     (`out/wasm/*.wasm`, the entry included) is embedded byte for byte;
#   • a second `pack` with nothing changed writes the same bytes;
#   • `build --target wasm` writes no `dist/` (packing is `pack` alone);
#   • run under a standalone `wasmtime run` (the CLI, not the compiler), each
#     answers what `botopink run --target wasm` answers. Without the
#     `wasmtime` CLI on PATH this half is skipped, named (decision 1079 (2):
#     CI installs it only in the job running this cell).
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
WORK="$(mktemp -d "${tmp_root%/}/botopink-wasm-pack.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
cp -R "$SCRIPT_DIR/wasm_pack/." "$WORK/"
CACHE="$WORK/cache-root"
READER="$WORK/component_imports.js"

failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }
show() { sed 's/^/      /' "$1" >&2; }
strip() { grep -v -e 'Compiling' -e 'Compiled' -e 'Created' "$1" || true; }

WASMTIME="$(command -v wasmtime || true)"
[[ -n "$WASMTIME" ]] || echo "  skip: wasmtime run half — no wasmtime CLI on PATH (decision 1079 (2))"

# <project> <args…>: the CLI in the project, its output into <project>.<n>.out.
bp() {
  local p="$1" log="$2"; shift 2
  ( cd "$WORK/$p" && "$BP_BIN" "$@" --cache-root "$CACHE" ) > "$log" 2>&1
}

check() {
  local p="$1" dist="$WORK/$1/dist/$1.wasm"
  [[ ! -e "$WORK/$p/out" ]] || fail "$p: the fixture already holds out/"
  bp "$p" "$WORK/$p-pack.out" pack || { fail "$p: pack failed"; show "$WORK/$p-pack.out"; return; }
  [[ -f "$dist" ]] || { fail "$p: no dist/$p.wasm"; return; }
  [[ -f "$WORK/$p/out/wasm/$p@main.wasm" ]] || fail "$p: pack built no out/wasm/$p@main.wasm"

  # Structure: every import wasi:*, every unit embedded.
  node "$READER" "$dist" "$WORK/$p"/out/wasm/*.wasm > "$WORK/$p-imports.out" 2>&1 \
    || { fail "$p: dist/$p.wasm does not read as a component"; show "$WORK/$p-imports.out"; return; }
  grep -q '^import wasi:' "$WORK/$p-imports.out" || fail "$p: dist/$p.wasm imports no wasi interface"
  while read -r kind name; do
    case "$kind" in
      import) [[ "$name" == wasi:* ]] || fail "$p: dist/$p.wasm imports $name, not a wasi:* interface" ;;
      missing) fail "$p: the unit ${name#"$WORK/"} is not embedded in dist/$p.wasm" ;;
    esac
  done < "$WORK/$p-imports.out"

  # Packing twice writes the same bytes.
  cp "$dist" "$WORK/$p-first.wasm"
  bp "$p" "$WORK/$p-pack2.out" pack || { fail "$p: a second pack failed"; show "$WORK/$p-pack2.out"; }
  cmp -s "$dist" "$WORK/$p-first.wasm" || fail "$p: a second pack wrote other bytes"

  # The runner's answer.
  bp "$p" "$WORK/$p-run.out" run --target wasm || { fail "$p: run --target wasm failed"; show "$WORK/$p-run.out"; return; }
  strip "$WORK/$p-run.out" > "$WORK/$p-want.out"
  [[ -s "$WORK/$p-want.out" ]] || fail "$p: run --target wasm printed nothing"

  # A standalone wasmtime run of the packed file, with the runner's preopens
  # (decision 1034 (7): `/` and the working directory, each under its own path).
  if [[ -n "$WASMTIME" ]]; then
    ( cd "$WORK/$p" && "$WASMTIME" run -W gc=y,exceptions=y,function-references=y \
        --dir /::/ --dir "$WORK/$p::$WORK/$p" "dist/$p.wasm" ) > "$WORK/$p-wt.out" 2>&1 \
      || { fail "$p: wasmtime run dist/$p.wasm failed"; show "$WORK/$p-wt.out"; return; }
    diff "$WORK/$p-want.out" "$WORK/$p-wt.out" > "$WORK/diff.log" \
      || { fail "$p: wasmtime run answers otherwise than botopink run --target wasm"; show "$WORK/diff.log"; }
  fi
}

check one
check two
check files

# `two`'s own unit is in it: a two-module program packs both modules.
[[ -f "$WORK/two/out/wasm/two@util.wasm" ]] || fail "two: no two@util.wasm unit to pack"

# `build` never packs.
rm -rf "$WORK/one/dist"
bp one "$WORK/one-build.out" build --target wasm || { fail "one: build --target wasm failed"; show "$WORK/one-build.out"; }
[[ ! -e "$WORK/one/dist" ]] || fail "one: build --target wasm wrote dist/"

if (( failures > 0 )); then
  echo "wasm_pack: $failures failure(s)" >&2
  exit 1
fi
echo "wasm_pack: ok"
