#!/usr/bin/env bash
# Decision 798 (2), (3), (5) — `build_modes_same_answer`, a CLI case (the cell
# suite builds each package one way; it cannot express a build in two modes):
# over `build_modes/app`, a package with a decorator (an added member and a
# `compiler.init` executor), a template, a top-level `comptime` block and a
# folded value,
#   • on commonJS, erlang, beam and wasm, the program built directly (from
#     its sources: the package's own `.bpr` set removed first, decision 1006) and the program built from its intermediate
#     (`build --emit-runtime <dir>`, then `build` over `<dir>/app.bpr`) are
#     the same files, byte for byte, and the run after the direct `run` (from the package's own `.bpr` set,
#     decisions 1006, 1009) prints
#     what the direct `run` prints, byte for byte;
#   • refused: `--emit-runtime` / `--emit-resolved` with no directory — the
#     flag last, the flag before another flag, an empty `=` value —, exit 1 and
#     `flag '<flag>' needs a value`, nothing written.
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
WORK="$(mktemp -d "${tmp_root%/}/botopink-build-modes.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
cp -R "$SCRIPT_DIR/build_modes/." "$WORK/"
APP="$WORK/app"

failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }

# The CLI in `app`: stdout to <out>, stderr to <err>.
bp() { # <out> <err> <args…>
  local out="$1" err="$2"; shift 2
  ( cd "$APP" && "$BP_BIN" "$@" ) > "$out" 2> "$err"
}
show() { sed 's/^/      /' "$1" >&2; }

RT="$WORK/rt"
if ! bp "$WORK/emit.out" "$WORK/emit.err" build --target commonJS --out "$WORK/emit-out" --emit-runtime "$RT"; then
  fail "the build writing the intermediate failed"; show "$WORK/emit.err"
fi
[[ -f "$RT/app.bpr" ]] || fail "--emit-runtime wrote no app.bpr"

for target in commonJS erlang beam wasm; do
  # Direct: no `.bpr` set of the project's own to reuse (decision 1006 (2)).
  rm -rf "$APP/.botopinkbuild/runtime"
  if ! bp "$WORK/direct.out" "$WORK/direct.err" build --target "$target" --out "$WORK/direct-$target"; then
    fail "$target: the direct build failed"; show "$WORK/direct.err"; continue
  fi
  if ! bp "$WORK/bpr.out" "$WORK/bpr.err" build --target "$target" --out "$WORK/bpr-$target" "$RT/app.bpr"; then
    fail "$target: the build from app.bpr failed"; show "$WORK/bpr.err"; continue
  fi
  diff -r "$WORK/direct-$target" "$WORK/bpr-$target" > "$WORK/diff.log" \
    || { fail "$target: built from app.bpr differs from the direct build"; show "$WORK/diff.log"; }

  rm -rf "$APP/.botopinkbuild/runtime"
  bp "$WORK/run-direct.out" "$WORK/run-direct.err" run --target "$target" --out "$WORK/run-direct-$target" \
    || { fail "$target: the direct run failed"; show "$WORK/run-direct.err"; continue; }
  grep -qx 'block,own' "$WORK/run-direct.out" || { fail "$target: the direct run did not run the executors"; show "$WORK/run-direct.out"; }
  grep -qx 'towns own 42' "$WORK/run-direct.out" || { fail "$target: the direct run did not read the member and the folded value"; show "$WORK/run-direct.out"; }
  # The run after it: from the package's own `.bpr` set (decisions 1006, 1009).
  bp "$WORK/run-bpr.out" "$WORK/run-bpr.err" run --target "$target" --out "$WORK/run-bpr-$target" \
    || { fail "$target: the run from its own .bpr failed"; show "$WORK/run-bpr.err"; continue; }
  cmp -s "$WORK/run-direct.out" "$WORK/run-bpr.out" \
    || { fail "$target: the run from its own .bpr answers otherwise"; diff "$WORK/run-direct.out" "$WORK/run-bpr.out" | sed 's/^/      /' >&2 || true; }
done

# The directory is required (798 (3)).
for flag in --emit-runtime --emit-resolved; do
  for form in last before-flag empty; do
    case "$form" in
      last) args=(build --target commonJS --out "$WORK/o" "$flag") ;;
      before-flag) args=(build "$flag" --target commonJS --out "$WORK/o") ;;
      empty) args=(build --target commonJS --out "$WORK/o" "$flag=") ;;
    esac
    if bp "$WORK/refused.out" "$WORK/refused.err" "${args[@]}"; then
      fail "$flag ($form): exit 0"
    elif ! grep -qF "flag '$flag' needs a value" "$WORK/refused.err"; then
      fail "$flag ($form): not refused as a flag with no directory"; show "$WORK/refused.err"
    fi
    [[ ! -e "$WORK/o" ]] || fail "$flag ($form): the refused build wrote its output"
    [[ ! -e "$APP/--target" ]] || fail "$flag ($form): a directory named --target was written"
    rm -rf "$WORK/o" "$APP/--target"
  done
done

if (( failures > 0 )); then
  echo "build_modes_same_answer.sh: $failures failure(s)" >&2
  exit 1
fi
echo "build_modes_same_answer.sh: every behaviour held"
