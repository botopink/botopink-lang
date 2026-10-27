#!/usr/bin/env bash
# Decision 1008 (2) — a dependency's units per target (the proof of the row's
# unit cache: reuse is a property of two packages' builds, which no cell
# expresses), its fixture written inline: a workspace of two members, `one`
# and `two`, over one library `lib`, on erlang, beam, commonJS and wasm (run
# in process, decisions 1032, 1034):
#   • the first member's build writes the library's entry
#     `.botopinkbuild/cache/unit/<target>/lib.bpu` under the workspace root;
#   • the second member's build emits none of the library's units: no entry
#     of the target's directory is written again (every file's inode and
#     modification time the same), and its output holds the library's files
#     with the bytes the first member's holds;
#   • a changed byte of the library's source writes its entry anew, and the
#     program answers the changed library;
#   • `build --cold` rewrites every entry;
#   • the answers are the same as a cold build's.
# On wasm a program's build emits only its entry's component (decisions 1008
# (3), 1017 (5)): no dependency unit is emitted at all, so only the answers
# and the untouched directory are checked there.
#
# BOTOPINK_BIN points the script at another binary (the parent's, to see it
# red). Exit 0 = every behaviour held.

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
WORK="$(mktemp -d "${tmp_root%/}/botopink-unit-cache.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/home"

failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }
ok() { echo "  ✓ $*"; }
show() { sed 's/^/      /' "$1" >&2; }

# The CLI in <dir>: stdout to $WORK/out, stderr to $WORK/err.
bp() { # <dir> <args…>
  local dir="$1"; shift
  ( cd "$dir" && HOME="$WORK/home" "$BP_BIN" "$@" ) > "$WORK/out" 2> "$WORK/err"
}
says() { # <what> <line>
  printf '%s\n' "$2" > "$WORK/want"
  cmp -s "$WORK/want" "$WORK/out" || { fail "$1: stdout differs"; diff "$WORK/want" "$WORK/out" | sed 's/^/      /' >&2 || true; }
}
# Every file of <dir> with its inode and modification time (ns).
listing() { ( cd "$1" 2>/dev/null && find . -type f -printf '%p %i %T@\n' | sort ) || true; }

# ── the fixture ──────────────────────────────────────────────────────────────
WS="$WORK/ws"
LIB="$WORK/lib"
mkdir -p "$LIB/src" "$WS/one/src" "$WS/two/src"
printf '{ "name": "lib", "entry": "root.bp", "files": ["root.bp", "util.bp"] }\n' > "$LIB/botopink.json"
cat > "$LIB/src/root.bp" <<'EOF'
pub mod util;

pub fn greet(n: string) -> string {
    return "hello " + n;
}
EOF
cat > "$LIB/src/util.bp" <<'EOF'
pub fn label(name: string) -> string {
    return name + " 42";
}
EOF
cat > "$WS/botopink.json" <<'EOF'
{
  "name": "ws",
  "version": "0.0.1",
  "workspaces": ["one", "two"],
  "dependencies": { "lib": { "path": "../lib" } }
}
EOF
for m in one two; do
  printf '{ "name": "%s" }\n' "$m" > "$WS/$m/botopink.json"
  cat > "$WS/$m/src/main.bp" <<EOF
import {io.terminal.print} from "std";
import {greet} from "lib";
import {util.label} from "lib";

pub fn main() -> void {
    print(greet("$m"));
    print(label("answer"));
}
EOF
done

targets=(erlang beam commonJS wasm)

for target in "${targets[@]}"; do
  echo "==> $target"
  UNITS="$WS/.botopinkbuild/cache/unit/$target"
  OUT="o-$target"
  sed -i 's/"hi "/"hello "/' "$LIB/src/root.bp"

  # The answers of a cold build, to compare with.
  for m in one two; do
    bp "$WS/$m" build --cold --target "$target" --out "$OUT" || { fail "$target: $m: the cold build failed"; show "$WORK/err"; continue 2; }
    bp "$WS/$m" run --target "$target" --out "$OUT" || { fail "$target: $m: the cold run failed"; show "$WORK/err"; continue 2; }
    cp "$WORK/out" "$WORK/cold-$m"
  done
  printf 'hello one\nanswer 42\n' > "$WORK/want-one"
  cmp -s "$WORK/want-one" "$WORK/cold-one" || { fail "$target: one answers otherwise"; show "$WORK/cold-one"; }

  # The first member writes the library's entry; the second emits none of it.
  rm -rf "$WS/.botopinkbuild/cache/unit" "$WS/one/$OUT" "$WS/two/$OUT"
  bp "$WS/one" build --target "$target" --out "$OUT" || { fail "$target: one's build failed"; show "$WORK/err"; continue; }
  if [[ "$target" != wasm ]]; then
    [[ -s "$UNITS/lib.bpu" ]] || { fail "$target: one's build wrote no $UNITS/lib.bpu"; continue; }
    ok "$target: the first member's build wrote lib.bpu"
  fi
  listing "$UNITS" > "$WORK/before"
  bp "$WS/two" build --target "$target" --out "$OUT" || { fail "$target: two's build failed"; show "$WORK/err"; continue; }
  listing "$UNITS" > "$WORK/after"
  if cmp -s "$WORK/before" "$WORK/after"; then
    ok "$target: the second member's build wrote no entry again"
  else
    fail "$target: the second member's build rewrote an entry"; diff "$WORK/before" "$WORK/after" | sed 's/^/      /' >&2 || true
  fi
  if [[ "$target" != wasm ]]; then
    for f in "$WS/one/$OUT"/*/lib@* "$WS/one/$OUT"/lib@*; do
      [[ -f "$f" ]] || continue
      rel="${f#"$WS/one/$OUT"/}"
      cmp -s "$f" "$WS/two/$OUT/$rel" || fail "$target: two's $rel differs from one's"
    done
  fi
  for m in one two; do
    bp "$WS/$m" run --target "$target" --out "$OUT" || { fail "$target: $m's run failed"; show "$WORK/err"; continue; }
    cmp -s "$WORK/cold-$m" "$WORK/out" || { fail "$target: $m answers otherwise than cold"; show "$WORK/out"; }
  done

  # A changed byte of the library: its entry written anew, the new answer.
  if [[ "$target" != wasm ]]; then before_lib="$(stat -c '%i %Y.%N' "$UNITS/lib.bpu" 2>/dev/null || true)"; fi
  sed -i 's/"hello "/"hi "/' "$LIB/src/root.bp"
  bp "$WS/two" run --target "$target" --out "$OUT" || { fail "$target: two's run after the edit failed"; show "$WORK/err"; continue; }
  says "$target: two after the library's edit" "hi two
answer 42"
  if [[ "$target" != wasm ]]; then
    after_lib="$(stat -c '%i %Y.%N' "$UNITS/lib.bpu" 2>/dev/null || true)"
    [[ -n "$after_lib" && "$after_lib" != "$before_lib" ]] || fail "$target: the library's edit did not write lib.bpu anew"
  fi

  # `build --cold` rewrites every entry.
  listing "$UNITS" > "$WORK/before"
  bp "$WS/one" build --cold --target "$target" --out "$OUT" || { fail "$target: build --cold failed"; show "$WORK/err"; continue; }
  listing "$UNITS" > "$WORK/after"
  if [[ "$target" != wasm ]]; then
    while read -r path _; do
      grep -q "^$path " "$WORK/after" || continue
      if grep -qxF "$(grep "^$path " "$WORK/before")" "$WORK/after"; then fail "$target: build --cold left $path as it was"; fi
    done < <(grep -E '^\./(lib|std/)' "$WORK/before")
    ok "$target: build --cold rewrote every entry it reached"
  fi
  bp "$WS/one" run --target "$target" --out "$OUT" || { fail "$target: one's run after build --cold failed"; show "$WORK/err"; continue; }
  says "$target: one after build --cold" "hi one
answer 42"
done
sed -i 's/"hi "/"hello "/' "$LIB/src/root.bp"

if (( failures > 0 )); then
  echo "unit_cache.sh: $failures failure(s)" >&2
  exit 1
fi
echo "unit_cache.sh: every behaviour held"
