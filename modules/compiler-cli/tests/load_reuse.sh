#!/usr/bin/env bash
# Decisions 1006 (6) P5, 1030 — the `.bpr` key covers `compiler.load(package:)`,
# so a library loaded by name reuses its `.bpr`, over the fixture `load_reuse/`:
# the program `app/` loads the library `greeter` by name (found through
# `BOTOPINK_LIB_ROOTS`) and runs it. The library's set lives under the LOADING
# build's cache root, one per load directory, named by its key
# (`app/.botopinkbuild/runtime/greeter@<key>/`), never in the library's
# directory (1030 (1), (2)):
#   • the first run of the program writes the library's set there and nothing
#     in the library; a later run whose program changed builds the program
#     again and reuses the library's set — the `.bpr` the same file (its inode,
#     pinned by a link of its own); a run on another target reuses it too;
#   • the library is analysed with its load directory as `root` (1003 (2)): the
#     `root` its comptime prints at build and the one its program prints at run
#     are both that directory;
#   • a changed byte of the library makes the program's set stale (its key
#     covers the library's) and the library's set is written again, under a
#     name of its own, the changed answer printed; the run after it reuses both;
#   • a bare `build` in the library's directory writes its own set under its
#     own cache root and leaves the loader's alone; a load after it reuses the
#     loader's set;
#   • the same library loaded from another directory gets a set of its own
#     (its load directory is part of the key), its `root` that directory, and
#     the first directory's set is reused when the load goes back to it.
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
SETS="$APP/.botopinkbuild/runtime"
ROOTS="$W/libs"

# The CLI in <dir> with $ROOTS as the library roots: stdout to $WORK/out, stderr
# to $WORK/err.
bp() { # <dir> <args…>
  local dir="$1"; shift
  ( cd "$dir" && BOTOPINK_LIB_ROOTS="$ROOTS" "$BP_BIN" "$@" ) > "$WORK/out" 2> "$WORK/err"
}
# The loader's sets of `greeter`, one per line.
sets() { find "$SETS" -mindepth 1 -maxdepth 1 -type d -name 'greeter@*' 2>/dev/null | sort; }
# The one set of `greeter` not listed in $WORK/seen (the one a load just wrote).
new_set() { sets > "$WORK/now"; comm -13 "$WORK/seen" "$WORK/now"; }
# A run's stdout: when the program is built (`built`), the library's build
# print and the program's; then the library's run.
loaded() { # <what> <greeting> <load dir> [built]
  local what="$1" greeting="$2" dir="$3"
  if [[ "${4:-}" == "built" ]]; then
    says "$what" "built root [$dir]" "comptime ran" "ran [$greeting" "root $dir" "]"
  else
    says "$what" "ran [$greeting" "root $dir" "]"
  fi
}

# ── a library loaded by name, across two runs ────────────────────────────────
: > "$WORK/seen"
bp "$APP" run --target commonJS || { fail "the first run failed"; show "$WORK/err"; }
loaded "the first run (builds the program and the library)" hello "$LIB" built
SET="$(new_set)"
if [[ -z "$SET" || "$(printf '%s\n' "$SET" | wc -l)" -ne 1 ]]; then
  fail "the load wrote no one set under the loader's cache root ($SETS/greeter@<key>/): [$SET]"
  SET="$SETS/greeter@none"
fi
BPR="$SET/greeter.bpr"
KEY="$SET/greeter.key"
[[ -f "$BPR" ]] || fail "the load wrote no $BPR"
[[ -s "$KEY" ]] || fail "the load wrote no key file $KEY"
[[ "$(basename "$SET")" == "greeter@$(head -n1 "$KEY" 2>/dev/null)" ]] || fail "the set's directory is not named by its key"
[[ -e "$LIB/.botopinkbuild" ]] && fail "the load wrote into the library's directory ($LIB/.botopinkbuild)"
[[ -f "$BPR" ]] && ln "$BPR" "$WORK/pin"
printf '\n// the program changed\n' >> "$APP/src/main.bp"
bp "$APP" run --target commonJS || { fail "the run after the program changed failed"; show "$WORK/err"; }
loaded "the run after the program changed (builds the program)" hello "$LIB" built
same_file "$BPR" || fail "the second load wrote the library's .bpr again"
bp "$APP" run --target erlang || { fail "the erlang run failed"; show "$WORK/err"; }
loaded "a run on another target (reuses the program)" hello "$LIB"
same_file "$BPR" || fail "the erlang run wrote the library's .bpr again"
rm -f "$WORK/pin"

# ── a changed library makes the loader stale ────────────────────────────────
sets > "$WORK/seen"
sed -i 's/print("hello")/print("hello again")/' "$LIB/src/main.bp"
bp "$APP" run --target commonJS || { fail "the run after the library changed failed"; show "$WORK/err"; }
loaded "the run after the library changed (builds both)" "hello again" "$LIB" built
SET="$(new_set)"
[[ -n "$SET" && "$(printf '%s\n' "$SET" | wc -l)" -eq 1 ]] || { fail "the changed library's set was not written under a name of its own: [$SET]"; SET="$SETS/greeter@none"; }
BPR="$SET/greeter.bpr"
[[ -f "$BPR" ]] && ln "$BPR" "$WORK/pin"
bp "$APP" run --target commonJS || { fail "the run after it failed"; show "$WORK/err"; }
loaded "the run after it (reuses both)" "hello again" "$LIB"
same_file "$BPR" || fail "the run after it wrote the library's .bpr again"

# ── a bare build keeps its own set ──────────────────────────────────────────
bp "$LIB" build || { fail "the bare build in the library failed"; show "$WORK/err"; }
says "a bare build in the library (its own analysis, root \"\")" "built root []"
[[ -f "$LIB/.botopinkbuild/runtime/greeter/greeter.bpr" ]] || fail "the bare build wrote no set under its own cache root"
same_file "$BPR" || fail "the bare build wrote the loader's .bpr"
printf '// the program changed again\n' >> "$APP/src/main.bp"
bp "$APP" run --target commonJS || { fail "the run after the bare build failed"; show "$WORK/err"; }
loaded "a load after the bare build (reuses the loader's set)" "hello again" "$LIB" built
same_file "$BPR" || fail "the load after the bare build wrote its .bpr again"

# ── another load directory, another set ─────────────────────────────────────
mkdir -p "$W/other"
cp -R "$LIB" "$W/other/greeter"
rm -rf "$W/other/greeter/.botopinkbuild"
sets > "$WORK/seen"
# Where a name resolves is no input of the program's key: the program changes,
# so it is built again and its load resolves anew.
ROOTS="$W/other"
printf '// the program changed for the other directory\n' >> "$APP/src/main.bp"
bp "$APP" run --target commonJS || { fail "the run from the other directory failed"; show "$WORK/err"; }
loaded "a load from another directory (its own set, its own root)" "hello again" "$W/other/greeter" built
OTHER="$(new_set)"
[[ -n "$OTHER" && "$(printf '%s\n' "$OTHER" | wc -l)" -eq 1 ]] || fail "the load from another directory wrote no set of its own: [$OTHER]"
same_file "$BPR" || fail "the load from another directory wrote the first directory's .bpr"
ROOTS="$W/libs"
printf '// the program changed back\n' >> "$APP/src/main.bp"
bp "$APP" run --target commonJS || { fail "the run back from the first directory failed"; show "$WORK/err"; }
loaded "a load back from the first directory (reuses its set)" "hello again" "$LIB" built
same_file "$BPR" || fail "the load back from the first directory wrote its .bpr again"
rm -f "$WORK/pin"

if (( failures > 0 )); then
  echo "load_reuse.sh: $failures failure(s)" >&2
  exit 1
fi
echo "load_reuse.sh: every behaviour held"
