#!/usr/bin/env bash
# Decisions 1006 (5), (7), 1066, 1067, 1065 (4) — `workspace_run_one_process_per_member` (a CLI
# behaviour at a workspace root, proven by the CLI's own script, decision 1020): `build` and
# `run --target <t>` at a workspace root run one child process per member, one after another in
# the workspace's order (the compiler decides no parallelism, 1066), the whole command bounded
# by `--timeout` when it is passed (1067):
#   • a member that throws and one that does not compile are each their own
#     `FAIL <member> — <reason>` line; the members that answer are `ok   <member>`; each
#     member's whole output sits under its own line, never another's (1065 (4));
#   • the member running when the bound fires is stopped with everything it spawned (no
#     process of it outlives the command), the members after it are reported not run, and
#     the command exits 1 naming the bound;
#   • then `modules: N checked — P passed, F failed`, N the member count;
#   • the verdicts are the ones `conformance/run.sh`'s spawner gives running the same members
#     side by side (1066 (2));
#   • a bare `build` at the root writes each member's `.bpr` set, one process each;
#   • a package's own `run --timeout` stops its program (wasm at the runner's epoch deadline);
#   • `--jobs` is no flag (1066 (1)); `--timeout` takes a positive count;
#   • `check` and `test` keep refusing a workspace.
#
# BOTOPINK_BIN points the script at another binary. Exit 0 = every behaviour held.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

if [[ -z "${BOTOPINK_SKIP_BUILD:-}" && -z "${BOTOPINK_BIN:-}" ]]; then
  echo "==> building botopink CLI"
  ( cd "$REPO_ROOT" && zig build )
fi
BP="${BOTOPINK_BIN:-$REPO_ROOT/zig-out/bin/botopink}"
[[ -x "$BP" ]] || { echo "error: CLI binary not found at $BP" >&2; exit 1; }

tmp_root="${TMPDIR:-/tmp}"
WORK="$(mktemp -d "${tmp_root%/}/botopink-ws-fanout.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }
ok() { echo "  ✓ $*"; }
run_in() { # <dir> <args…> — stdout+stderr to $OUT, status to $CODE
  local d="$1"; shift
  set +e
  OUT="$(cd "$d" && "$BP" "$@" 2>&1)"
  CODE=$?
  set -e
}
has_line() { grep -qxF -- "$1" <<<"$OUT"; }
verdicts() { grep -E '^(ok   |FAIL |modules: )' <<<"$OUT"; }

# ── the fixture: five members — two answer, one throws, one hangs, one does not compile ──
WS="$WORK/ws"
mkdir -p "$WS"
printf '{ "name": "ws", "version": "0.0.1", "workspaces": ["*"] }\n' >"$WS/botopink.json"
member() { # <name> — src/main.bp on stdin
  mkdir -p "$WS/$1/src"
  printf '{ "name": "%s" }\n' "$1" >"$WS/$1/botopink.json"
  cat >"$WS/$1/src/main.bp"
}
member alpha <<'BP'
import {io.terminal.print} from "std";

pub fn main() -> void {
    print("hello alpha");
}
BP
member broken <<'BP'
pub fn main() -> void {
    val x: i32 = nowhere;
}
BP
member omega <<'BP'
import {io.terminal.print} from "std";

pub fn main() -> void {
    print("hello omega");
}
BP
member thrower <<'BP'
import {failure.panic, io.terminal.print} from "std";

pub fn main() -> void {
    print("before the panic");
    panic("thrower gives up");
}
BP

member zhang <<'BP'
import {io.terminal.print} from "std";

pub fn main() -> void {
    print("hang starts");
    var i = 0;
    loop {
        i = 1 - i;
    }
}
BP
member zlast <<'BP'
import {io.terminal.print} from "std";

pub fn main() -> void {
    print("never reached");
}
BP

# The bound holds the four members before `zhang`, run one after another, and stops `zhang`.
TIMEOUT=90
for target in commonJS erlang; do
  echo "==> $target: run at the root — one process per member, in order, the whole under --timeout"
  rm -rf "$WS/out"
  run_in "$WS" run --target "$target" --timeout "$TIMEOUT"
  [[ $CODE -eq 1 ]] || fail "$target: the root's run exits 1 (exit $CODE)"
  has_line "ok   alpha" && has_line "    hello alpha" || { echo "$OUT" >&2; fail "$target: alpha answers, its output indented"; }
  has_line "ok   omega" && has_line "    hello omega" || { echo "$OUT" >&2; fail "$target: omega answers, its output indented"; }
  grep -qE '^FAIL thrower — exit [0-9]+$' <<<"$OUT" && has_line "    before the panic" && grep -qE '^    .*thrower gives up' <<<"$OUT" \
    || { echo "$OUT" >&2; fail "$target: thrower is one FAIL line, its output (the print, the panic) indented"; }
  grep -qE '^FAIL broken — exit [0-9]+$' <<<"$OUT" && grep -qE '^    .*nowhere' <<<"$OUT" \
    || { echo "$OUT" >&2; fail "$target: broken is one FAIL line, its refusal indented"; }
  has_line "FAIL zhang — stopped: the command's --timeout of $TIMEOUT s was reached" \
    || { echo "$OUT" >&2; fail "$target: zhang is stopped when the bound fires"; }
  has_line "FAIL zlast — not run: the command's --timeout of $TIMEOUT s was reached" \
    || { echo "$OUT" >&2; fail "$target: zlast, after the bound, is reported not run"; }
  grep -q "the command's --timeout of $TIMEOUT s was reached: the running member was stopped and 1 member(s) not run" <<<"$OUT" \
    || { echo "$OUT" >&2; fail "$target: the command names the bound"; }
  has_line "modules: 6 checked — 2 passed, 4 failed" || { echo "$OUT" >&2; fail "$target: the count holds the six members"; }
  # Decision 1065 (4): each member's whole output under its own verdict, never another's.
  block() { awk -v v="$1" '/^(ok   |FAIL |modules: )/ { on = index($0, v) == 1; next } on' <<<"$OUT"; }
  grep -qxF "    hello alpha" <(block "ok   alpha") && ! grep -q "omega\|panic" <(block "ok   alpha") \
    || fail "$target: alpha's output sits under alpha's verdict alone"
  grep -qxF "    before the panic" <(block "FAIL thrower") && ! grep -q "hello" <(block "FAIL thrower") \
    || fail "$target: thrower's output sits under thrower's verdict alone"
  ! grep -q "never reached" <<<"$OUT" || fail "$target: zlast ran"
  order="$(verdicts | sed -E 's/^(ok   |FAIL )([a-z]+).*/\2/;s/^modules:.*/count/' | tr '\n' ' ')"
  [[ "$order" == "alpha broken omega thrower zhang zlast count " ]] || fail "$target: the lines in the workspace's order (got: $order)"
  if pgrep -f -- "$WS/out" >/dev/null; then
    fail "$target: a process of the stopped member outlived the command: $(pgrep -af -- "$WS/out" | head -3)"
  fi
  ok "$target: alpha and omega ok, thrower and broken FAIL alone, zhang stopped, zlast not run, 6 counted, nothing left running"
done

echo "==> a package's run --timeout stops its program, wasm at the epoch deadline"
for target in commonJS wasm; do
  rm -rf "$WS/zhang/out"
  run_in "$WS/zhang" run --target "$target" --timeout 20
  [[ $CODE -eq 1 ]] && grep -q "the command's --timeout of 20 s was reached: the program was stopped" <<<"$OUT" \
    || { echo "$OUT" >&2; fail "$target: zhang alone under --timeout 20 is stopped, the bound named (exit $CODE)"; }
  if pgrep -f -- "$WS/zhang/out" >/dev/null; then fail "$target: zhang's program outlived the command"; fi
done
ok "stopped on commonJS and wasm, nothing left running"

echo "==> without --timeout no member is bounded"
rm -rf "$WS/out"
QUICK="$WORK/quick"
mkdir -p "$QUICK"
printf '{ "name": "quick", "version": "0.0.1", "workspaces": ["*"] }\n' >"$QUICK/botopink.json"
cp -R "$WS/alpha" "$WS/omega" "$QUICK/"
run_in "$QUICK" run --target commonJS
[[ $CODE -eq 0 ]] && has_line "modules: 2 checked — 2 passed, 0 failed" || { echo "$OUT" >&2; fail "two members with no bound (exit $CODE)"; }
ok "both answered"

echo "==> the same verdicts as conformance/run.sh's spawner, the members side by side"
SUITE="$WORK/suite"
mkdir -p "$SUITE/modules"
printf '{ "name": "conformance", "version": "0.0.1", "workspaces": ["*"] }\n' >"$SUITE/modules/botopink.json"
cp -R "$WS/alpha" "$WS/broken" "$WS/omega" "$WS/thrower" "$SUITE/modules/"
run_in "$SUITE/modules" run --target erlang
serial="$(grep -E '^FAIL ' <<<"$OUT" | sed -E 's/^FAIL ([^ ]+) — (.*)$/[erlang] modules\/\1 — \2/' | sort)"
has_line "modules: 4 checked — 2 passed, 2 failed" || { echo "$OUT" >&2; fail "the serial root's count"; }
set +e
SPAWNED="$(bash "$REPO_ROOT/conformance/run.sh" --suite "$SUITE" --only modules --target erlang --compiler "$BP" --jobs 4 2>&1 \
  | sed 's/\x1b\[[0-9;]*m//g')"
set -e
spawned="$(grep -oE '\[erlang\] modules/[^ ]+ — .*$' <<<"$SPAWNED" | sort)"
[[ -n "$serial" && "$serial" == "$spawned" ]] \
  || { echo "serial:"; echo "$serial"; echo "spawned:"; echo "$SPAWNED"; fail "run.sh's spawner gives other verdicts than the serial root"; } >&2
ok "broken and thrower red alike, alpha and omega green alike"

echo "==> a bare build at the root writes each member's .bpr set, one process each"
rm -rf "$WS/.botopinkbuild" "$WS/out"
run_in "$WS" build
[[ $CODE -eq 1 ]] || { echo "$OUT" >&2; fail "the bare build exits 1 (broken does not compile) (exit $CODE)"; }
for m in alpha omega thrower zhang zlast; do
  has_line "ok   $m" || { echo "$OUT" >&2; fail "bare build: ok   $m"; }
  [[ -s "$WS/.botopinkbuild/runtime/$m/$m.key" ]] || fail "bare build: $m's .bpr key under the root's .botopinkbuild/runtime/$m/"
done
grep -qE '^FAIL broken — exit [0-9]+$' <<<"$OUT" || { echo "$OUT" >&2; fail "bare build: broken is one FAIL line"; }
has_line "modules: 6 checked — 5 passed, 1 failed" || { echo "$OUT" >&2; fail "bare build: the count"; }
[[ ! -e "$WS/out" ]] || fail "the bare build wrote an out/"
ok "five sets written, broken red alone, no out/"

echo "==> --jobs is no flag; --timeout takes a positive count"
run_in "$WS" run --target commonJS --jobs 4
[[ $CODE -ne 0 ]] && grep -q "unknown flag '--jobs'" <<<"$OUT" || fail "--jobs is an unknown flag (exit $CODE)"
run_in "$WS" build --jobs 4
[[ $CODE -ne 0 ]] && grep -q "unknown flag '--jobs'" <<<"$OUT" || fail "build --jobs is an unknown flag (exit $CODE)"
for bad in 0 x -1; do
  run_in "$WS" build --timeout "$bad"
  [[ $CODE -ne 0 ]] && grep -q "unexpected argument '$bad'" <<<"$OUT" || fail "--timeout $bad is a usage error (exit $CODE)"
done
ok "--jobs refused, --timeout 0, x and -1 refused"

echo "==> check and test keep refusing a workspace"
for cmd in check test; do
  run_in "$WS" "$cmd"
  [[ $CODE -eq 1 ]] && grep -q "is a workspace, not a package — run this command inside one of its members: alpha, broken, omega, thrower, zhang, zlast" <<<"$OUT" \
    || { echo "$OUT" >&2; fail "$cmd at the root is refused, naming the members (exit $CODE)"; }
done
ok "check and test refused"

if (( failures > 0 )); then
  echo "workspace_run_one_process_per_member.sh: $failures failure(s)" >&2
  exit 1
fi
echo "workspace_run_one_process_per_member.sh: every behaviour held"
