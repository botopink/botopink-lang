#!/usr/bin/env bash
# Decision 1006 (6) P5 — the `.bpr` key covers `compiler.load(package:)`, so a
# library loaded by name reuses its `.bpr`, over the fixture `load_reuse/`: the
# program `app/` loads the library `greeter` by name (found through
# `BOTOPINK_LIB_ROOTS=libs/`) and runs it. The library's set is the one a bare
# `botopink build` in its directory writes, under its own cache root
# (`libs/greeter/.botopinkbuild/runtime/greeter/`):
#   • the first run of the program writes the library's set; a later run whose
#     program changed builds the program again and reuses the library's set —
#     the `.bpr` the same file (its inode, pinned by a link of its own);
#   • a changed byte of the library makes the program's set stale (its key
#     covers the library's) and the library's set is written again, the
#     changed answer printed; the run after it reuses both;
#   • a bare `build` in the library's directory reuses the set the load wrote
#     (nothing printed, the same file), and a load reuses the set a bare
#     `build` there wrote — one file, byte for byte what a bare build writes.
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
WORK="$(mktemp -d "${tmp_root%/}/botopink-load-reuse.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }
show() { sed 's/^/      /' "$1" >&2; }

# The CLI in <dir>: stdout to $WORK/out, stderr to $WORK/err.
bp() { # <dir> <args…>
  local dir="$1"; shift
  ( cd "$dir" && BOTOPINK_LIB_ROOTS="$W/libs" "$BP_BIN" "$@" ) > "$WORK/out" 2> "$WORK/err"
}
# stdout equals the lines given.
says() { # <what> <line>…
  local what="$1"; shift
  if (( $# )); then printf '%s\n' "$@"; fi > "$WORK/want"
  cmp -s "$WORK/want" "$WORK/out" || { fail "$what: stdout differs"; diff "$WORK/want" "$WORK/out" | sed 's/^/      /' >&2 || true; }
}
inode() { stat -c %i "$1"; }
same_file() { [[ -f "$1" && -f "$WORK/pin" && "$(inode "$1")" == "$(inode "$WORK/pin")" ]]; }

W="$WORK/w"
cp -R "$SCRIPT_DIR/load_reuse" "$W"
APP="$W/app"
LIB="$W/libs/greeter"
BPR="$LIB/.botopinkbuild/runtime/greeter/greeter.bpr"
KEY="$LIB/.botopinkbuild/runtime/greeter/greeter.key"

# ── a library loaded by name, across two runs ────────────────────────────────
bp "$APP" run --target commonJS || { fail "the first run failed"; show "$WORK/err"; }
says "the first run (builds the program and the library)" "comptime ran" "ran [hello" "]"
[[ -f "$BPR" ]] || fail "the load wrote no $BPR"
[[ -s "$KEY" ]] || fail "the load wrote no key file $KEY"
[[ -f "$BPR" ]] && ln "$BPR" "$WORK/pin"
printf '\n// the program changed\n' >> "$APP/src/main.bp"
bp "$APP" run --target commonJS || { fail "the run after the program changed failed"; show "$WORK/err"; }
says "the run after the program changed (builds the program)" "comptime ran" "ran [hello" "]"
same_file "$BPR" || fail "the second load wrote the library's .bpr again"
bp "$APP" run --target erlang || { fail "the erlang run failed"; show "$WORK/err"; }
says "a run on another target (reuses the program)" "ran [hello" "]"
same_file "$BPR" || fail "the erlang run wrote the library's .bpr again"
rm -f "$WORK/pin"

# ── a changed library makes the loader stale ────────────────────────────────
cp "$BPR" "$WORK/before" 2>/dev/null || : > "$WORK/before"
sed -i 's/print("hello")/print("hello again")/' "$LIB/src/main.bp"
bp "$APP" run --target commonJS || { fail "the run after the library changed failed"; show "$WORK/err"; }
says "the run after the library changed (builds both)" "comptime ran" "ran [hello again" "]"
cmp -s "$BPR" "$WORK/before" && fail "the library's .bpr was not written again"
rm -f "$WORK/pin"; [[ -f "$BPR" ]] && ln "$BPR" "$WORK/pin"
bp "$APP" run --target commonJS || { fail "the run after it failed"; show "$WORK/err"; }
says "the run after it (reuses both)" "ran [hello again" "]"
same_file "$BPR" || fail "the run after it wrote the library's .bpr again"

# ── a bare build and the load share one set ─────────────────────────────────
bp "$LIB" build || { fail "the bare build in the library failed"; show "$WORK/err"; }
says "a bare build in the library (reuses the load's set)"
same_file "$BPR" || fail "the bare build wrote the library's .bpr again"
cp "$BPR" "$WORK/loaded" 2>/dev/null || : > "$WORK/loaded"
rm -f "$WORK/pin"
rm -rf "$LIB/.botopinkbuild"
bp "$LIB" build || { fail "the bare build from nothing failed"; show "$WORK/err"; }
cmp -s "$BPR" "$WORK/loaded" || fail "the bare build's .bpr differs from the one the load wrote"
rm -f "$WORK/pin"; [[ -f "$BPR" ]] && ln "$BPR" "$WORK/pin"
printf '// the program changed again\n' >> "$APP/src/main.bp"
bp "$APP" run --target commonJS || { fail "the run after the bare build failed"; show "$WORK/err"; }
says "a load after the bare build (reuses its set)" "comptime ran" "ran [hello again" "]"
same_file "$BPR" || fail "the load wrote the .bpr the bare build had written"
rm -f "$WORK/pin"

if (( failures > 0 )); then
  echo "load_reuse.sh: $failures failure(s)" >&2
  exit 1
fi
echo "load_reuse.sh: every behaviour held"
