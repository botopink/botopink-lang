#!/usr/bin/env bash
# Decision 1006 (5), (7) — `workspace_run_one_process_per_member` (a CLI behaviour at a
# workspace root, proven by the CLI's own script, decision 1020): `build` and
# `run --target <t>` at a workspace root run one child process per member, in the
# workspace's order, on `--jobs`, each under `--timeout`:
#   • a member that throws, one that hangs past `--timeout`, one that does not compile
#     are each their own `FAIL <member> — <reason>` line, with their output indented;
#     the members that answer are `ok   <member>`, their output indented;
#   • then `modules: N checked — P passed, F failed`, N the member count; exit 1 on any red;
#   • the hung member is stopped with everything it spawned: no process of it outlives
#     the command;
#   • the lines are in the workspace's order whatever order the members end in:
#     `--jobs 1` prints the same lines as `--jobs 4`;
#   • a bare `build` at the root writes each member's `.bpr` set, one process each;
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
member hang <<'BP'
import {io.terminal.print} from "std";

pub fn main() -> void {
    print("hang starts");
    var i = 0;
    loop {
        i = 1 - i;
    }
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

TIMEOUT=12
for target in commonJS erlang; do
  echo "==> $target: run at the root — one process per member, each its own line"
  rm -rf "$WS/out"
  run_in "$WS" run --target "$target" --jobs 4 --timeout "$TIMEOUT"
  [[ $CODE -eq 1 ]] || fail "$target: the root's run exits 1 on a red (exit $CODE)"
  has_line "ok   alpha" && has_line "    hello alpha" || { echo "$OUT" >&2; fail "$target: alpha answers, its output indented"; }
  has_line "ok   omega" && has_line "    hello omega" || { echo "$OUT" >&2; fail "$target: omega answers, its output indented"; }
  grep -qE '^FAIL thrower — exit [0-9]+$' <<<"$OUT" && has_line "    before the panic" && grep -qE '^    .*thrower gives up' <<<"$OUT" \
    || { echo "$OUT" >&2; fail "$target: thrower is one FAIL line, its output (the print, the panic) indented"; }
  has_line "FAIL hang — no answer within $TIMEOUT s (a hang): stopped" \
    || { echo "$OUT" >&2; fail "$target: hang is stopped at --timeout, one FAIL line"; }
  grep -qE '^FAIL broken — exit [0-9]+$' <<<"$OUT" && grep -qE '^    .*nowhere' <<<"$OUT" \
    || { echo "$OUT" >&2; fail "$target: broken is one FAIL line, its refusal indented"; }
  has_line "modules: 5 checked — 2 passed, 3 failed" || { echo "$OUT" >&2; fail "$target: the count holds the five members"; }
  order="$(verdicts | sed -E 's/^(ok   |FAIL )([a-z]+).*/\2/;s/^modules:.*/count/' | tr '\n' ' ')"
  [[ "$order" == "alpha broken hang omega thrower count " ]] || fail "$target: the lines in the workspace's order (got: $order)"
  if pgrep -f -- "$WS/out" >/dev/null; then
    fail "$target: a process of the hung member outlived the command: $(pgrep -af -- "$WS/out" | head -3)"
  fi
  ok "$target: alpha and omega ok, thrower, hang and broken each FAIL alone, 5 counted, nothing left running"
done

echo "==> --jobs 1 prints the same lines as --jobs 4"
run_in "$WS" run --target commonJS --jobs 4 --timeout "$TIMEOUT"
four="$(verdicts)"
run_in "$WS" run --target commonJS --jobs 1 --timeout "$TIMEOUT"
one="$(verdicts)"
[[ "$four" == "$one" ]] || { diff <(echo "$four") <(echo "$one") >&2 || true; fail "--jobs 1 and --jobs 4 print different lines"; }
ok "the same lines, in the workspace's order"

echo "==> a bare build at the root writes each member's .bpr set, one process each"
rm -rf "$WS/.botopinkbuild" "$WS/out"
run_in "$WS" build --jobs 3
[[ $CODE -eq 1 ]] || { echo "$OUT" >&2; fail "the bare build exits 1 (broken does not compile) (exit $CODE)"; }
for m in alpha hang omega thrower; do
  has_line "ok   $m" || { echo "$OUT" >&2; fail "bare build: ok   $m"; }
  [[ -s "$WS/.botopinkbuild/runtime/$m/$m.key" ]] || fail "bare build: $m's .bpr key under the root's .botopinkbuild/runtime/$m/"
done
grep -qE '^FAIL broken — exit [0-9]+$' <<<"$OUT" || { echo "$OUT" >&2; fail "bare build: broken is one FAIL line"; }
has_line "modules: 5 checked — 4 passed, 1 failed" || { echo "$OUT" >&2; fail "bare build: the count"; }
[[ ! -e "$WS/out" ]] || fail "the bare build wrote an out/"
ok "four sets written, broken red alone, no out/"

echo "==> --jobs and --timeout take a positive count"
for bad in 0 x -1; do
  run_in "$WS" run --target commonJS --jobs "$bad"
  [[ $CODE -ne 0 ]] && grep -q "unexpected argument '$bad'" <<<"$OUT" || fail "--jobs $bad is a usage error (exit $CODE)"
  run_in "$WS" build --timeout "$bad"
  [[ $CODE -ne 0 ]] && grep -q "unexpected argument '$bad'" <<<"$OUT" || fail "--timeout $bad is a usage error (exit $CODE)"
done
ok "0, x and -1 refused"

echo "==> check and test keep refusing a workspace"
for cmd in check test; do
  run_in "$WS" "$cmd"
  [[ $CODE -eq 1 ]] && grep -q "is a workspace, not a package — run this command inside one of its members: alpha, broken, hang, omega, thrower" <<<"$OUT" \
    || { echo "$OUT" >&2; fail "$cmd at the root is refused, naming the members (exit $CODE)"; }
done
ok "check and test refused"

if (( failures > 0 )); then
  echo "workspace_run_one_process_per_member.sh: $failures failure(s)" >&2
  exit 1
fi
echo "workspace_run_one_process_per_member.sh: every behaviour held"
