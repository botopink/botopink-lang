#!/usr/bin/env bash
# Decision 1006 (2)–(4) — a package's `.bpr` set, built once and reused while
# its key is fresh, over the cells of `conformance/modules/decisions-taken/
# module_bpr_reused_across_targets-1006/cells/` (a cell answers one run; reuse
# is a property of two runs, so this script runs them):
#   • a bare `build` writes `<cache root>/.botopinkbuild/runtime/<pkg>/` — the
#     `<pkg>.bpr` and its `<pkg>.key` — and no `out/`; a second bare `build`
#     reuses it (no build phase printed, the `.bpr` the same file);
#   • `module_bpr_reused_across_targets`: `run --target` on one target prints
#     the build phase and the answer; `run --target` on each other target then
#     answers the same with no build phase — no comptime ran — and the `.bpr`
#     is the same file (its inode, pinned by a link of its own, and its bytes);
#   • `build --cold` ignores the key and rebuilds (the build phase again, a new
#     file); `run --cold` reuses a fresh set (no build phase);
#   • the command's own output directories inside the package (`--out`,
#     `--emit-runtime`) and a `*.new` file are no part of the key (1006-b (3));
#   • `module_bpr_stale_rebuilt`: on each target in turn, a changed byte of
#     `src/greeting.bp` makes the next `run --target` build again (the build
#     phase printed, the changed answer, other `.bpr` bytes), and the run after
#     it reuses that set.
#
# BOTOPINK_BIN points the script at another binary. Exit 0 = every behaviour held.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CELLS="$REPO_ROOT/conformance/modules/decisions-taken/module_bpr_reused_across_targets-1006/cells"

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
WORK="$(mktemp -d "${tmp_root%/}/botopink-runtime-reuse.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }
show() { sed 's/^/      /' "$1" >&2; }

# The CLI in <dir>: stdout to $WORK/out, stderr to $WORK/err.
bp() { # <dir> <args…>
  local dir="$1"; shift
  ( cd "$dir" && "$BP_BIN" "$@" ) > "$WORK/out" 2> "$WORK/err"
}
# stdout equals the lines given.
says() { # <what> <line>…
  local what="$1"; shift
  if (( $# )); then printf '%s\n' "$@"; fi > "$WORK/want"
  cmp -s "$WORK/want" "$WORK/out" || { fail "$what: stdout differs"; diff "$WORK/want" "$WORK/out" | sed 's/^/      /' >&2 || true; }
}
inode() { stat -c %i "$1"; }

# ── module_bpr_reused_across_targets ─────────────────────────────────────────
C="$WORK/reused"
cp -R "$CELLS/module_bpr_reused_across_targets" "$C"
SET="$C/.botopinkbuild/runtime/module_bpr_reused_across_targets"
BPR="$SET/module_bpr_reused_across_targets.bpr"
KEY="$SET/module_bpr_reused_across_targets.key"

bp "$C" build || { fail "bare build failed"; show "$WORK/err"; }
says "bare build" "comptime ran"
[[ -f "$BPR" ]] || fail "bare build wrote no $BPR"
[[ -s "$KEY" ]] || fail "bare build wrote no key file $KEY"
[[ ! -e "$C/out" ]] || fail "bare build wrote out/"
ln "$BPR" "$WORK/pin"
bp "$C" build || { fail "second bare build failed"; show "$WORK/err"; }
says "second bare build (fresh)"
[[ "$(inode "$BPR")" == "$(inode "$WORK/pin")" ]] || fail "second bare build wrote the .bpr again"
rm -f "$WORK/pin"
rm -rf "$C/.botopinkbuild"

first=1
for target in erlang beam commonJS wasm; do
  bp "$C" run --target "$target" || { fail "$target: run failed"; show "$WORK/err"; continue; }
  if (( first )); then
    says "$target: the first run (builds)" "comptime ran" "answer 42"
    ln "$BPR" "$WORK/pin"
    first=0
  else
    says "$target: a later target's run (reuses)" "answer 42"
    [[ "$(inode "$BPR")" == "$(inode "$WORK/pin")" ]] || fail "$target: the run wrote the .bpr again"
    cmp -s "$BPR" "$WORK/pin" || fail "$target: the .bpr changed"
  fi
done

bp "$C" run --cold --target commonJS || { fail "run --cold failed"; show "$WORK/err"; }
says "run --cold (reuses a fresh set)" "answer 42"
[[ "$(inode "$BPR")" == "$(inode "$WORK/pin")" ]] || fail "run --cold wrote the .bpr again"
bp "$C" build --cold || { fail "build --cold failed"; show "$WORK/err"; }
says "build --cold (rebuilds)" "comptime ran"
[[ "$(inode "$BPR")" != "$(inode "$WORK/pin")" ]] || fail "build --cold did not write the .bpr again"
rm -f "$WORK/pin"

# Decision 1006-b (3): the command's own output directories inside the package, and a `*.new`, are no part of
# the key — a run into `--out` there, then a candidate written, and the next run still reuses the set.
ln "$BPR" "$WORK/pin"
bp "$C" run --target commonJS --out build/o || { fail "run --out build/o failed"; show "$WORK/err"; }
mkdir -p "$C/snapshot" && printf 'x\n' > "$C/snapshot/main.snap.new"
bp "$C" run --target commonJS --out build/o || { fail "the second run --out build/o failed"; show "$WORK/err"; }
says "a run after its own --out inside the package and a *.new (reuses)" "answer 42"
[[ "$(inode "$BPR")" == "$(inode "$WORK/pin")" ]] || fail "--out inside the package or a *.new moved the key"
bp "$C" build --emit-runtime rt || { fail "build --emit-runtime rt failed"; show "$WORK/err"; }
bp "$C" build --emit-runtime rt || { fail "the second build --emit-runtime rt failed"; show "$WORK/err"; }
says "a second bare build into --emit-runtime inside the package (reuses)"
rm -f "$WORK/pin"

# ── module_bpr_stale_rebuilt ─────────────────────────────────────────────────
C="$WORK/stale"
cp -R "$CELLS/module_bpr_stale_rebuilt" "$C"
BPR="$C/.botopinkbuild/runtime/module_bpr_stale_rebuilt/module_bpr_stale_rebuilt.bpr"
bp "$C" run --target commonJS || { fail "stale: the first run failed"; show "$WORK/err"; }
says "stale: the first run" "comptime ran" "hello"
for target in erlang beam commonJS wasm; do
  cp "$BPR" "$WORK/before"
  printf 'pub fn text() -> string {\n    return "hello %s";\n}\n' "$target" > "$C/src/greeting.bp"
  bp "$C" run --target "$target" || { fail "stale $target: the run after the edit failed"; show "$WORK/err"; continue; }
  says "stale $target: the run after the edit (rebuilds)" "comptime ran" "hello $target"
  cmp -s "$BPR" "$WORK/before" && fail "stale $target: the .bpr was not written again"
  bp "$C" run --target "$target" || { fail "stale $target: the run after it failed"; show "$WORK/err"; continue; }
  says "stale $target: the run after it (reuses)" "hello $target"
done

if (( failures > 0 )); then
  echo "runtime_reuse.sh: $failures failure(s)" >&2
  exit 1
fi
echo "runtime_reuse.sh: every behaviour held"
