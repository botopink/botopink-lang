#!/usr/bin/env bash
# Decision 1008 (1), (4), (5) — each target's output folder carries a key, and a
# matching one means `run --target <t>` only executes (the proof of the ledger
# row: reuse is a property of two runs, which no cell expresses), over its
# fixture `target_reuse/` (a package and one dependency), on erlang, beam,
# commonJS and wasm:
#   • the second `run --target <t>` rewrites no file of the output folder (every
#     file's inode and modification time the same) and answers the same;
#   • a changed source file makes the next run emit again, and it answers the
#     changed program;
#   • `build --cold --target <t>` rewrites the output folder;
#   • `run --cold --target <t>` reuses a fresh `.bpr` but reads no target key: its first reach emits
#     again and answers the same (decision 1043 (4));
#   • on wasm the program runs in process and its compiled code is
#     `.botopinkbuild/cache/wasmtime/<sha256>.cwasm` (decisions 1008 (5), 1034
#     (5), (8)): a run with nothing changed compiles nothing (no `.cwasm`
#     rewritten), nothing goes under `$HOME/.cache` (HOME is a temporary
#     directory), and `--cold` reads none and writes it again.
#
# BOTOPINK_BIN points the script at another binary. Exit 0 = every behaviour held.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
FIXTURE="$SCRIPT_DIR/target_reuse"

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
WORK="$(mktemp -d "${tmp_root%/}/botopink-target-reuse.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/home"

failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }
show() { sed 's/^/      /' "$1" >&2; }

# The CLI in <dir>, with a HOME of its own: stdout to $WORK/out, stderr to $WORK/err.
bp() { # <dir> <args…>
  local dir="$1"; shift
  ( cd "$dir" && HOME="$WORK/home" "$BP_BIN" "$@" ) > "$WORK/out" 2> "$WORK/err"
}
says() { # <what> <line>
  printf '%s\n' "$2" > "$WORK/want"
  cmp -s "$WORK/want" "$WORK/out" || { fail "$1: stdout differs"; diff "$WORK/want" "$WORK/out" | sed 's/^/      /' >&2 || true; }
}
# Every file of <dir> with its inode and modification time (ns): the folder's state.
listing() { ( cd "$1" && find . -type f -printf '%p %i %T@\n' | sort ); }

C="$WORK/pkg"
mkdir -p "$C"
cp -R "$FIXTURE/app" "$FIXTURE/lib" "$C/"
APP="$C/app"

targets=(erlang beam commonJS wasm)

for target in "${targets[@]}"; do
  OUT="o-$target"
  # The first run emits; the second only executes.
  bp "$APP" run --target "$target" --out "$OUT" || { fail "$target: the first run failed"; show "$WORK/err"; continue; }
  says "$target: the first run" "answer 42"
  listing "$APP/$OUT" > "$WORK/before"
  [[ -s "$WORK/before" ]] || fail "$target: the first run wrote nothing under $OUT"
  bp "$APP" run --target "$target" --out "$OUT" || { fail "$target: the second run failed"; show "$WORK/err"; continue; }
  says "$target: the second run (reuses)" "answer 42"
  listing "$APP/$OUT" > "$WORK/after"
  cmp -s "$WORK/before" "$WORK/after" || { fail "$target: the second run rewrote a file of $OUT"; diff "$WORK/before" "$WORK/after" | sed 's/^/      /' >&2 || true; }
  [[ -s "$APP/.botopinkbuild/runtime/app/app.$target.key" ]] || fail "$target: no target key under .botopinkbuild/runtime/app/"

  # `run --cold` reuses a fresh `.bpr` and reads no target key (1043 (4)): it emits again.
  sleep 1
  bp "$APP" run --cold --target "$target" --out "$OUT" || { fail "$target: run --cold failed"; show "$WORK/err"; continue; }
  says "$target: run --cold (emits again)" "answer 42"
  listing "$APP/$OUT" > "$WORK/after"
  if cmp -s "$WORK/before" "$WORK/after"; then fail "$target: run --cold rewrote nothing (it read the target key)"; fi
  [[ -s "$APP/.botopinkbuild/runtime/app/app.$target.key" ]] || fail "$target: no target key after run --cold"
  # The key is still written at the end of a cold run (1046): a warm run after it only executes.
  listing "$APP/$OUT" > "$WORK/before"
  bp "$APP" run --target "$target" --out "$OUT" || { fail "$target: the run after run --cold failed"; show "$WORK/err"; continue; }
  says "$target: the run after run --cold (reuses)" "answer 42"
  listing "$APP/$OUT" > "$WORK/after"
  cmp -s "$WORK/before" "$WORK/after" || fail "$target: the run after run --cold rewrote a file of $OUT (the cold run left no key)"

  # `build --cold` rewrites everything.
  bp "$APP" build --cold --target "$target" --out "$OUT" || { fail "$target: build --cold failed"; show "$WORK/err"; continue; }
  listing "$APP/$OUT" > "$WORK/after"
  if cmp -s "$WORK/before" "$WORK/after"; then fail "$target: build --cold rewrote nothing"; fi
  bp "$APP" run --target "$target" --out "$OUT" || { fail "$target: the run after build --cold failed"; show "$WORK/err"; continue; }
  says "$target: the run after build --cold" "answer 42"
  listing "$APP/$OUT" > "$WORK/before"

  # A changed source file: the next run emits again and answers the changed program.
  sed -i 's/label("answer")/label("changed")/' "$APP/src/main.bp"
  bp "$APP" run --target "$target" --out "$OUT" || { fail "$target: the run after the edit failed"; show "$WORK/err"; }
  says "$target: the run after the edit (emits)" "changed 42"
  listing "$APP/$OUT" > "$WORK/after"
  if cmp -s "$WORK/before" "$WORK/after"; then fail "$target: the run after the edit rewrote nothing"; fi
  listing "$APP/$OUT" > "$WORK/before"
  bp "$APP" run --target "$target" --out "$OUT" || { fail "$target: the run after it failed"; show "$WORK/err"; }
  says "$target: the run after it (reuses)" "changed 42"
  listing "$APP/$OUT" > "$WORK/after"
  cmp -s "$WORK/before" "$WORK/after" || fail "$target: the run after the edit's rewrote a file of $OUT"
  sed -i 's/label("changed")/label("answer")/' "$APP/src/main.bp"
done

# The compiled code is the build folder's (decisions 1008 (5), 1034 (8)).
WT="$APP/.botopinkbuild/cache/wasmtime"
[[ -n "$(find "$WT" -maxdepth 1 -name '*.cwasm' -print -quit 2>/dev/null)" ]] || fail "wasm: no .cwasm under .botopinkbuild/cache/wasmtime"
[[ ! -e "$WORK/home/.cache/wasmtime" ]] || fail "wasm: wasmtime wrote its cache under \$HOME/.cache"
if [[ -d "$WORK/home/.cache" ]] && [[ -n "$(find "$WORK/home/.cache" -type f -print -quit)" ]]; then
  fail "wasm: something was written under \$HOME/.cache"
fi
# A run with nothing changed compiles nothing (1034 (5)).
listing "$WT" > "$WORK/cw-before"
bp "$APP" run --target wasm --out o-wasm || { fail "wasm: the warm run failed"; show "$WORK/err"; }
listing "$WT" > "$WORK/cw-after"
cmp -s "$WORK/cw-before" "$WORK/cw-after" || { fail "wasm: a run with nothing changed rewrote a .cwasm"; diff "$WORK/cw-before" "$WORK/cw-after" | sed 's/^/      /' >&2 || true; }
# `--cold` reads none and writes what it compiled.
bp "$APP" run --cold --target wasm --out o-wasm || { fail "wasm: run --cold failed"; show "$WORK/err"; }
says "wasm: run --cold" "answer 42"
listing "$WT" > "$WORK/cw-after"
if cmp -s "$WORK/cw-before" "$WORK/cw-after"; then fail "wasm: run --cold rewrote no .cwasm"; fi

if (( failures > 0 )); then
  echo "target_reuse.sh: $failures failure(s)" >&2
  exit 1
fi
echo "target_reuse.sh: every behaviour held"
