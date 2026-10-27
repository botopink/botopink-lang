#!/usr/bin/env bash
# Decisions 1077 (3), 1078 — cell `by_name_set_moves`, proved here (decision
# 1020): a program cell cannot move its own library, so the move is this
# script's. The fixture is written inline: a workspace `ws/` whose member `app`
# loads the library `greeter` by name (outside the workspace, through
# `BOTOPINK_LIB_ROOTS`) and runs it; `greeter` prints its `root` at build (a
# comptime print, kept as the stored build output) and at run (a folded
# `compiler.src().root`).
#   • a bare `build` at the workspace root prints the real load directory, and
#     the sets it writes hold it nowhere — not in a file name, not in a byte:
#     the set codec writes the directory as its symbol (`bp-root:<64 hex>`,
#     `load.rootSymbol`) and the key file maps the symbol to the directory
#     relative to the cache root;
#   • the sets packed, the sources copied to another directory with no
#     `.botopinkbuild/`, the sets unpacked there: `run --target <t>` (and `run
#     --cold`) on commonJS, erlang, beam and wasm reuses them — no comptime, the
#     member's `.bpr` the unpacked file — and the program prints the NEW
#     directory at run, and its build output the new one too; never the symbol;
#   • the library moved alone (the name resolving elsewhere, 1039 (3)): the
#     program is built again and prints the directory it moved to;
#   • a program whose text already holds a root symbol is refused at its set's
#     write, naming the module and the field (1078 (3)); nothing is written.
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
WORK="$(mktemp -d "${tmp_root%/}/botopink-by-name-set-moves.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }
show() { sed 's/^/      /' "$1" >&2; }
inode() { stat -c %i "$1"; }

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
            print("built [" + m.buildOutput() + "]");
            show(m.run());
        });
        Error(r) -> compiler.init({ -> print("refused"); });
    }
}

pub fn main() -> void {}
EOF
printf '{ "name": "greeter" }\n' > "$A/libs/greeter/botopink.json"
cat > "$A/libs/greeter/src/main.bp" <<'EOF'
import {compiler, io.terminal.print} from "std";

comptime {
    print("root at build " + compiler.src().root);
}

pub fn main() -> void {
    print("root at run " + (comptime compiler.src()).root);
}
EOF

# The CLI in <dir> with <roots> as the library roots: stdout to $WORK/out, stderr to $WORK/err.
bp() { # <roots> <dir> <args…>
  local roots="$1" dir="$2"; shift 2
  ( cd "$dir" && BOTOPINK_LIB_ROOTS="$roots" "$BP_BIN" "$@" ) > "$WORK/out" 2> "$WORK/err"
}
# What the program answers when its library is at <dir>.
want() { # <dir>
  printf '%s\n' "built [root at build $1" "]" "ran [root at run $1" "]"
}
mangle() { # a directory as a loaded package's name spells it
  printf '%s' "$1" | od -An -v -tx1 | tr -s ' \n' '  ' | awk '{
    for (i = 1; i <= NF; i++) { c = $i; n = strtonum("0x" c)
      if (c == "2f") printf "__"
      else if ((n >= 48 && n <= 57) || (n >= 65 && n <= 90) || (n >= 97 && n <= 122) || n == 95) printf "%c", n
      else printf "_x%s", c } }'
}

# ── the build: the real directory printed, none in the sets ─────────────────
bp "$A/libs" "$A/ws" build || { fail "the bare build at the workspace root failed"; show "$WORK/out"; show "$WORK/err"; }
grep -qF "root at build $A/libs/greeter" "$WORK/out" || { fail "the build did not print the real load directory"; show "$WORK/out"; }
grep -qF 'bp-root:' "$WORK/out" "$WORK/err" && fail "the build printed a root symbol"
SETS="$A/ws/.botopinkbuild/runtime"
[[ -f "$SETS/app/app.bpr" ]] || fail "the bare build wrote no set for app"
mangled="$(mangle "$A")"
names="$(cd "$SETS" && find . -mindepth 1 | grep -F -e "$A" -e "$mangled" || true)"
[[ -z "$names" ]] || { fail "a file of the sets is named by an absolute path"; printf '%s\n' "$names" | sed 's/^/      /' >&2; }
held="$(grep -r -l -a -F -e "$A" -e "$mangled" "$SETS" || true)"
[[ -z "$held" ]] || { fail "a file of the sets holds an absolute path"; printf '%s\n' "${held//$SETS\//}" | sed 's/^/      /' >&2; }
grep -r -q -a 'bp-root:[0-9a-f]\{64\}' "$SETS/app" || fail "app's set holds no root symbol in place of the load directory"
grep -q -x 'bp-root:[0-9a-f]\{64\}	\.\./libs/greeter' "$SETS/app/app.key" || { fail "app's key file maps no symbol to ../libs/greeter"; show "$SETS/app/app.key"; }
tar -C "$A/ws" -cf "$WORK/sets.tar" .botopinkbuild/runtime

targets=(commonJS erlang beam wasm)
for t in "${targets[@]}"; do
  bp "$A/libs" "$A/ws/app" run --target "$t" || { fail "$t: the run in the first checkout failed"; show "$WORK/err"; continue; }
  want "$A/libs/greeter" > "$WORK/want"
  cmp -s "$WORK/want" "$WORK/out" || { fail "$t: the first checkout's answer"; diff "$WORK/want" "$WORK/out" | sed 's/^/      /' >&2 || true; }
done

# ── the sets moved with a copy of the checkout ──────────────────────────────
B="$WORK/second/elsewhere"
mkdir -p "$B"
( cd "$A" && tar -cf - --exclude=.botopinkbuild --exclude=out . ) | ( cd "$B" && tar -xf - )
tar -C "$B/ws" -xf "$WORK/sets.tar"
BPR="$B/ws/.botopinkbuild/runtime/app/app.bpr"
[[ -f "$BPR" ]] && ln "$BPR" "$WORK/pin"
want "$B/libs/greeter" > "$WORK/want"
for t in "${targets[@]}"; do
  for cold in "" --cold; do
    what="$t${cold:+ $cold}"
    bp "$B/libs" "$B/ws/app" run $cold --target "$t" || { fail "$what: the run in the other checkout failed"; show "$WORK/err"; continue; }
    grep -qx 'comptime ran' "$WORK/out" && fail "$what: the other checkout built the set again"
    grep -v -x 'comptime ran' "$WORK/out" > "$WORK/got" || true
    cmp -s "$WORK/want" "$WORK/got" || { fail "$what: the moved set does not answer the new directory"; diff "$WORK/want" "$WORK/got" | sed 's/^/      /' >&2 || true; }
    [[ -f "$WORK/pin" && "$(inode "$BPR")" == "$(inode "$WORK/pin")" ]] || fail "$what: the other checkout wrote app's .bpr again"
  done
done
rm -f "$WORK/pin"

# ── the library moved alone ─────────────────────────────────────────────────
mkdir -p "$B/moved"
mv "$B/libs/greeter" "$B/moved/greeter"
bp "$B/moved" "$B/ws/app" run --target commonJS || { fail "the run after the library moved failed"; show "$WORK/err"; }
grep -qx 'comptime ran' "$WORK/out" || fail "the library moved alone and the program was not built again (1039 (3))"
grep -qxF "root at build $B/moved/greeter" "$WORK/out" || fail "the build after the move did not print the directory the library moved to"
grep -v -x -e 'comptime ran' -e "root at build $B/moved/greeter" "$WORK/out" > "$WORK/got" || true
want "$B/moved/greeter" > "$WORK/want"
cmp -s "$WORK/want" "$WORK/got" || { fail "the program does not answer the directory its library moved to"; diff "$WORK/want" "$WORK/got" | sed 's/^/      /' >&2 || true; }

# ── a text that already holds a root symbol ─────────────────────────────────
C="$WORK/holds"
mkdir -p "$C/src"
printf '{ "name": "holds" }\n' > "$C/botopink.json"
printf 'import {io.terminal.print} from "std";\n\npub fn main() -> void {\n    print("bp-root:%s");\n}\n' "$(printf '0%.0s' $(seq 64))" > "$C/src/main.bp"
if bp "$WORK" "$C" build; then
  fail "a program whose text holds a root symbol was written into a set"
else
  grep -qF 'already holds a root symbol' "$WORK/err" && grep -qF 'module `main`' "$WORK/err" && grep -qF 'field `' "$WORK/err" \
    || { fail "the refusal does not name the root symbol, the module and the field"; show "$WORK/err"; }
fi
[[ ! -e "$C/.botopinkbuild/runtime/holds/holds.key" ]] || fail "the refused set left a key file"

if (( failures > 0 )); then
  echo "by_name_set_moves.sh: $failures failure(s)" >&2
  exit 1
fi
echo "by_name_set_moves.sh: every behaviour held"
