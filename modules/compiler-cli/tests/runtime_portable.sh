#!/usr/bin/env bash
# Decisions 1006 (6) P4, 1030 (3) — a workspace's `.bpr` sets carry no absolute
# path, so the sets one checkout builds run in another checkout at another path
# (CI builds them once and hands them to the per-target rows as an artifact).
# The fixture is written inline: a workspace `ws/` whose member `app` loads the
# library `greeter` by name (`compiler.load(package:)`, found through
# `BOTOPINK_LIB_ROOTS` outside the workspace) and runs it.
#   • a bare `build` at the workspace root (the gate's build stage) writes the
#     member's set under `ws/.botopinkbuild/runtime/`; no file name and no byte of
#     any file there names the checkout's directory — the loaded package is
#     named by its directory relative to the workspace root, never by its
#     absolute path (the group file `bp_load___x2e_x2e__libs__greeter.bpr`);
#   • the sets are packed (the artifact), the checkout's sources copied to
#     another directory with no `.botopinkbuild/`, the sets unpacked there, and
#     `run --target <t>` (and `run --cold`, as CI's rows run) in the member on
#     commonJS, erlang, beam and wasm reuses them — no comptime runs, the
#     member's `.bpr` is the unpacked file (its inode) — and answers what a run
#     in the first checkout answers.
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
WORK="$(mktemp -d "${tmp_root%/}/botopink-runtime-portable.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }
show() { sed 's/^/      /' "$1" >&2; }
inode() { stat -c %i "$1"; }

# ── the fixture: a workspace whose member loads a library by name ───────────
A="$WORK/first"
mkdir -p "$A/ws/app/src" "$A/libs/greeter/src"
printf '{ "name": "ws", "workspaces": ["*"] }\n' > "$A/ws/botopink.json"
printf '{ "name": "app" }\n' > "$A/ws/app/botopink.json"
cat > "$A/ws/app/src/main.bp" <<'EOF'
import {compiler, compiler.RunFailure, io.terminal.print} from "std";

fn show(answer: Result<string, RunFailure>) -> void {
    case answer {
        Ok(text) -> print("ran [" + text + "]");
        Error(r) -> print("failed " + r.message);
    }
}

comptime {
    print("comptime ran");
    val greeter = comptime compiler.load(package: "greeter");
    case greeter {
        Ok(m) -> compiler.init({ ->
            print("loaded " + m.name());
            show(m.run());
        });
        Error(r) -> compiler.init({ -> print("refused"); });
    }
}

pub fn main() -> void {}
EOF
printf '{ "name": "greeter" }\n' > "$A/libs/greeter/botopink.json"
cat > "$A/libs/greeter/src/main.bp" <<'EOF'
import {io.terminal.print} from "std";

pub fn main() -> void {
    print("hello");
}
EOF

# The CLI in <dir> with <checkout>/libs as the library roots: stdout to
# $WORK/out, stderr to $WORK/err.
bp() { # <checkout> <dir> <args…>
  local co="$1" dir="$2"; shift 2
  ( cd "$dir" && BOTOPINK_LIB_ROOTS="$co/libs" "$BP_BIN" "$@" ) > "$WORK/out" 2> "$WORK/err"
}

# ── the build stage: a bare build at the workspace root ─────────────────────
bp "$A" "$A/ws" build || { fail "the bare build at the workspace root failed"; show "$WORK/out"; show "$WORK/err"; }
SETS="$A/ws/.botopinkbuild/runtime"
[[ -f "$SETS/app/app.bpr" && -s "$SETS/app/app.key" ]] || fail "the bare build wrote no set for app under $SETS/app/"
# The checkout's directory, as written and as a loaded package's name spells it
# (`/` → `__`, any other byte not a letter, a digit or `_` → `_x<hex>`).
mangled="$(printf '%s' "$A" | od -An -v -tx1 | tr -s ' \n' '  ' | awk '{
  for (i = 1; i <= NF; i++) { c = $i; n = strtonum("0x" c)
    if (c == "2f") printf "__"
    else if ((n >= 48 && n <= 57) || (n >= 65 && n <= 90) || (n >= 97 && n <= 122) || n == 95) printf "%c", n
    else printf "_x%s", c } }')"
names="$(cd "$SETS" && find . -mindepth 1 | grep -F -e "$A" -e "$mangled" || true)"
[[ -z "$names" ]] || { fail "a file of the sets is named by the checkout's absolute path"; printf '%s\n' "$names" | sed 's/^/      /' >&2; }
held="$(grep -r -l -a -F -e "$A" -e "$mangled" "$SETS" || true)"
[[ -z "$held" ]] || { fail "a file of the sets holds the checkout's absolute path"; printf '%s\n' "${held//$SETS\//}" | sed 's/^/      /' >&2; }
ls "$SETS/app"/bp_load__*.bpr > /dev/null 2>&1 || fail "the loaded package has no group file in app's set"

# The artifact: the sets alone, packed before any run writes a target key.
tar -C "$A/ws" -cf "$WORK/sets.tar" .botopinkbuild/runtime

# What the first checkout answers.
targets=(commonJS erlang beam wasm)
for t in "${targets[@]}"; do
  bp "$A" "$A/ws/app" run --target "$t" || { fail "$t: the run in the first checkout failed"; show "$WORK/err"; }
  cp "$WORK/out" "$WORK/answer-$t"
  grep -qx 'loaded greeter' "$WORK/answer-$t" || { fail "$t: the first checkout's run did not run the loaded library"; show "$WORK/answer-$t"; }
  grep -qx 'comptime ran' "$WORK/answer-$t" && fail "$t: the run in the first checkout ran comptime again over the fresh set"
done

# ── another checkout at another path: the sources, then the artifact ────────
B="$WORK/second/elsewhere"
mkdir -p "$B"
( cd "$A" && tar -cf - --exclude=.botopinkbuild --exclude=out . ) | ( cd "$B" && tar -xf - )
[[ ! -e "$B/ws/.botopinkbuild" ]] || fail "the copied sources hold a .botopinkbuild/"
tar -C "$B/ws" -xf "$WORK/sets.tar"
BPR="$B/ws/.botopinkbuild/runtime/app/app.bpr"
[[ -f "$BPR" ]] && ln "$BPR" "$WORK/pin"
for t in "${targets[@]}"; do
  for cold in "" --cold; do
    bp "$B" "$B/ws/app" run $cold --target "$t" || { fail "$t${cold:+ $cold}: the run in the other checkout failed"; show "$WORK/err"; continue; }
    grep -qx 'comptime ran' "$WORK/out" && fail "$t${cold:+ $cold}: the other checkout built the set again (comptime ran)"
    cmp -s "$WORK/out" "$WORK/answer-$t" || { fail "$t${cold:+ $cold}: the other checkout answers differently"; diff "$WORK/answer-$t" "$WORK/out" | sed 's/^/      /' >&2 || true; }
    [[ -f "$WORK/pin" && "$(inode "$BPR")" == "$(inode "$WORK/pin")" ]] || fail "$t${cold:+ $cold}: the other checkout wrote app's .bpr again"
  done
done
rm -f "$WORK/pin"

if (( failures > 0 )); then
  echo "runtime_portable.sh: $failures failure(s)" >&2
  exit 1
fi
echo "runtime_portable.sh: every behaviour held"
