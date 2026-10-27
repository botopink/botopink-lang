#!/usr/bin/env bash
# Decision 1061 (1) — no child of the compiler outlives it. A program that
# never ends, run on the erlang target under a `timeout --foreground 8` (SIGTERM, to the compiler alone, at eight
# seconds, SIGKILL at ten), leaves no process in the job's session: no
# `beam.smp`, no `erl`. The check is the job's own session (`setsid` makes the
# job its leader, so its pid is the session id), never a pattern over
# `pgrep -f`. A second run is ended by SIGINT, the signal Ctrl+C sends. A third
# case is a package's `build --timeout 2` over an endless comptime body (decision
# 1074 (1)): stopped at the bound, named, nothing of its session left, the
# previous build's `.bpr`, key and `out/erlang/` untouched.
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
command -v erl >/dev/null || { echo "error: erl not on PATH" >&2; exit 1; }
command -v setsid >/dev/null || { echo "skip: no setsid"; exit 0; }

tmp_root="${TMPDIR:-/tmp}"
WORK="$(mktemp -d "${tmp_root%/}/botopink-child-group.XXXXXX")"
JOBS=()
cleanup() {
  local p
  for p in "${JOBS[@]:-}"; do
    [[ -n "$p" ]] || continue
    # every member of the job's session, whatever group it leads
    ps -e -o pid=,sid= | awk -v s="$p" '$2 == s { print $1 }' | xargs -r kill -KILL 2>/dev/null || true
  done
  rm -rf "$WORK"
}
trap cleanup EXIT

failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }

mkdir -p "$WORK/app/src"
printf '{ "name": "app" }\n' >"$WORK/app/botopink.json"
cat >"$WORK/app/src/main.bp" <<'BP'
pub fn main() -> void {
    while (true) { }
}
BP

# The processes of session $1 (its leader's pid) still alive, as `pid name command-line`.
session_members() {
  ps -e -o pid=,sid=,args= | awk -v s="$1" '$2 == s { n = split($3, p, "/"); printf "%s %s %s\n", $1, p[n], substr($0, index($0, $3)) }'
}

# run_case <name> <signal-after-seconds|-> <command…>: the job is a session
# leader; <command> runs in it; when it ends (or after the signal) the
# session must be empty.
run_case() {
  local name="$1"; shift
  local sig_after="$1"; shift
  ( cd "$WORK/app" && exec setsid "$@" ) >"$WORK/$name.out" 2>&1 &
  local job=$!
  JOBS+=("$job")
  # the program's erlang VM (`-pa <out>`, not the compile session's) must be up in the job, else nothing was proven
  local i
  for i in $(seq 1 100); do
    session_members "$job" | grep -q '^[0-9]* beam.smp .* -pa ' && break
    sleep 0.2
  done
  session_members "$job" | grep -q '^[0-9]* beam.smp .* -pa ' || fail "$name: the program's beam never started: $(head -c 400 "$WORK/$name.out")"
  if [[ "$sig_after" != "-" ]]; then
    # interrupt the compiler as Ctrl+C does
    local bp_pid
    bp_pid="$(session_members "$job" | awk '$2 == "botopink" { print $1; exit }')"
    [[ -n "$bp_pid" ]] && kill -INT "$bp_pid" 2>/dev/null || true
  fi
  # the job ends on its own: wait on its pid, under a deadline
  local waited=0
  while kill -0 "$job" 2>/dev/null && (( waited < 150 )); do sleep 0.2; waited=$((waited + 1)); done
  kill -0 "$job" 2>/dev/null && fail "$name: the job did not end"
  wait "$job" 2>/dev/null || true
  sleep 0.5
  local left
  left="$(session_members "$job")"
  if [[ -n "$left" ]]; then
    fail "$name: processes of the job outlived the compiler: $(echo "$left" | cut -c1-60 | tr '\n' ';')"
  fi
}

run_case timeout - timeout --foreground -k 2 8 "$BP" run --target erlang
run_case sigint 1 "$BP" run --target erlang

# Decision 1074 (1) — a package's `build --timeout 2` over an endless comptime body: the
# build stops itself at the bound, names it, exits non-zero, leaves no process of its
# session (no `beam.smp`), and leaves the previous `.bpr`, its key and `out/erlang/` whole.
mkdir -p "$WORK/spin/src"
printf '{ "name": "spin" }\n' >"$WORK/spin/botopink.json"
spin_body() { # <loop or not>
  printf 'import {io.terminal.print} from "std";\n\nval spin: i32 = comptime {\n    var i = 0;\n'
  [[ "$1" == loop ]] && printf '    while (true) {\n        i = 1 - i;\n    }\n'
  printf '    i\n};\n\npub fn main() -> void {\n    print(spin.toString());\n}\n'
}
spin_body once >"$WORK/spin/src/main.bp"
( cd "$WORK/spin" && "$BP" build --target erlang ) >"$WORK/spin-first.out" 2>&1 \
  || fail "build-timeout: the first build of the finite body failed: $(head -c 400 "$WORK/spin-first.out")"
# The target key (`<pkg>.<t>.key`, decision 1008 (1)) is withdrawn when a build starts to
# emit and written again only on success, so a stopped build leaves none and the next run
# emits again; the `.bpr` set, its key and every file of `out/` are what must stay whole.
snapshot() { ( cd "$WORK/spin" && find out .botopinkbuild/runtime -type f ! -name '*.tmp' ! -name '*.erlang.key' | sort | xargs sha256sum ) 2>/dev/null; }
before="$(snapshot)"
[[ -n "$before" ]] || fail "build-timeout: the first build wrote nothing to compare"
spin_body loop >"$WORK/spin/src/main.bp"
( cd "$WORK/spin" && exec setsid "$BP" build --target erlang --timeout 2 ) >"$WORK/spin.out" 2>&1 &
job=$!
JOBS+=("$job")
waited=0
while kill -0 "$job" 2>/dev/null && (( waited < 150 )); do sleep 0.2; waited=$((waited + 1)); done
if kill -0 "$job" 2>/dev/null; then
  fail "build-timeout: the build did not stop at its bound"
  code=0
else
  set +e; wait "$job"; code=$?; set -e
fi
[[ $code -ne 0 ]] || fail "build-timeout: the stopped build exited 0"
grep -q "the command's --timeout of 2 s was reached" "$WORK/spin.out" || fail "build-timeout: the bound is not named: $(head -c 400 "$WORK/spin.out")"
sleep 0.5
left="$(session_members "$job")"
[[ -z "$left" ]] || fail "build-timeout: processes of the build outlived it: $(echo "$left" | cut -c1-60 | tr '\n' ';')"
[[ "$(snapshot)" == "$before" ]] || fail "build-timeout: the stopped build changed the previous .bpr, key or out/erlang/"

if (( failures > 0 )); then
  echo "child_group_killed: $failures failure(s)" >&2
  exit 1
fi
echo "child_group_killed: ok"
