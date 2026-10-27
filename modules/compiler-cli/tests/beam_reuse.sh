#!/usr/bin/env bash
# Decision 1007 — on erlang and beam a module's `.beam` is loaded as it is while
# its emitted source is unchanged, over its fixture `beam_reuse/` (the proof of
# decision 1007's ledger row: reuse is a property of two runs, which no cell
# expresses):
#   • `beam_reused_when_source_unchanged`: on erlang and on beam, a second
#     `run --target <t>` compiles no module — every `.beam` in `out/erlang/` /
#     `out/beam/` the same file (its inode, pinned by a link of its own) — and
#     answers the same; beside each `.beam` its record `<atom>.beam.rec` (the
#     source's hash, the compiler's source stamp, the OTP release);
#     `run --cold` reuses them too, `build --cold --target erlang` compiles
#     every module again;
#   • `beam_recompiled_when_source_changes`: on erlang and on beam, after a
#     change to `src/greeting.bp` the next run writes that module's `.beam`
#     again and no other, and answers the changed program.
#
# BOTOPINK_BIN points the script at another binary. Exit 0 = every behaviour held.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CELLS="$SCRIPT_DIR/beam_reuse"

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
WORK="$(mktemp -d "${tmp_root%/}/botopink-beam-reuse.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }
show() { sed 's/^/      /' "$1" >&2; }

bp() { # <dir> <args…>: stdout to $WORK/out, stderr to $WORK/err
  local dir="$1"; shift
  ( cd "$dir" && "$BP_BIN" "$@" ) > "$WORK/out" 2> "$WORK/err"
}
says() { # <what> <line>
  printf '%s\n' "$2" > "$WORK/want"
  cmp -s "$WORK/want" "$WORK/out" || { fail "$1: stdout differs"; diff "$WORK/want" "$WORK/out" | sed 's/^/      /' >&2 || true; }
}
sub() { [[ "$1" == erlang ]] && echo erlang || echo beam; }
# pin <dir> <tag>: a link to every `.beam` of <dir>, so its inode is not reused.
pin() {
  rm -rf "$WORK/pin-$2"; mkdir -p "$WORK/pin-$2"
  local f; for f in "$1"/*.beam; do ln "$f" "$WORK/pin-$2/$(basename "$f")"; done
}
# same <dir> <tag> <name>: the `.beam` <name> of <dir> is the pinned file.
same() { [[ "$(stat -c %i "$1/$3")" == "$(stat -c %i "$WORK/pin-$2/$3")" ]]; }

# ── beam_reused_when_source_unchanged ────────────────────────────────────────
C="$WORK/reused"
cp -R "$CELLS/beam_reused_when_source_unchanged" "$C"
for target in erlang beam; do
  D="$C/out/$(sub "$target")"
  bp "$C" run --target "$target" || { fail "$target: the first run failed"; show "$WORK/err"; continue; }
  says "$target: the first run" "area 12"
  n=0; for f in "$D"/*.beam; do n=$((n + 1)); [[ -s "$f.rec" ]] || fail "$target: no record beside $(basename "$f")"; done
  (( n >= 2 )) || fail "$target: $n .beam in $D"
  grep -q "^otp " "$D/beam_reused_when_source_unchanged@main.beam.rec" 2>/dev/null || fail "$target: the record names no OTP release"
  pin "$D" "$target"
  bp "$C" run --target "$target" || { fail "$target: the second run failed"; show "$WORK/err"; continue; }
  says "$target: the second run" "area 12"
  for f in "$WORK/pin-$target"/*.beam; do same "$D" "$target" "$(basename "$f")" || fail "$target: the second run compiled $(basename "$f") again"; done
  bp "$C" run --cold --target "$target" || { fail "$target: run --cold failed"; show "$WORK/err"; continue; }
  says "$target: run --cold" "area 12"
  for f in "$WORK/pin-$target"/*.beam; do same "$D" "$target" "$(basename "$f")" || fail "$target: run --cold compiled $(basename "$f") again"; done
done
D="$C/out/erlang"
bp "$C" build --cold --target erlang || { fail "build --cold failed"; show "$WORK/err"; }
for f in "$WORK/pin-erlang"/*.beam; do same "$D" erlang "$(basename "$f")" && fail "build --cold reused $(basename "$f")"; done

# ── beam_recompiled_when_source_changes ──────────────────────────────────────
C="$WORK/changed"
cp -R "$CELLS/beam_recompiled_when_source_changes" "$C"
for target in erlang beam; do
  D="$C/out/$(sub "$target")"
  bp "$C" run --target "$target" || { fail "changed $target: the first run failed"; show "$WORK/err"; continue; }
  pin "$D" "c-$target"
  printf 'pub fn text() -> string {\n    return "hi %s";\n}\n' "$target" > "$C/src/greeting.bp"
  bp "$C" run --target "$target" || { fail "changed $target: the run after the edit failed"; show "$WORK/err"; continue; }
  says "changed $target: the run after the edit" "hi $target 12"
  same "$D" "c-$target" "beam_recompiled_when_source_changes@greeting.beam" && fail "changed $target: greeting's .beam was not compiled again"
  for m in main shapes; do
    same "$D" "c-$target" "beam_recompiled_when_source_changes@$m.beam" || fail "changed $target: $m's .beam was compiled again"
  done
done

if (( failures > 0 )); then
  echo "beam_reuse.sh: $failures failure(s)" >&2
  exit 1
fi
echo "beam_reuse.sh: every behaviour held"
