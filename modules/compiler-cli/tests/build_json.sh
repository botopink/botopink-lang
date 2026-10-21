#!/usr/bin/env bash
# Decision 798 (6) — `botopink build --json` and `--cache-root <dir>` against the real CLI.
#   • a clean build: stdout is JSON lines only — `targets` (the target built and the
#     manifest's `"targets"`), one `build` per line a build body printed (in order),
#     a `summary` last (`ok` true, `exit` 0); stderr is what it is without `--json`
#     (`Compiling …`, `Compiled …`);
#   • a refused build: one `refused` per refusal (`module`, `message`, `at`, `label`,
#     `from`), the `called from` lines of a raise at build in `from`, `summary` `ok`
#     false and `exit` 1; stderr still holds the rendering;
#   • `--emit-runtime <dir>`: a `runtime` event with the path of each `.bpr` written,
#     the root package's flagged;
#   • `--cache-root <dir>`: the level-B cache is filed under <dir>, not the project.
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
WORK="$(mktemp -d "${tmp_root%/}/botopink-build-json.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }
ok() { echo "  ✓ $*"; }

# Every line of $1 is one JSON object (python3 -I reads it).
only_json() {
  python3 -I - "$1" <<'PY'
import json, sys
for n, line in enumerate(open(sys.argv[1]), 1):
    json.loads(line)
PY
}
# events <file> <event>: the lines of that event, compact JSON.
events() {
  python3 -I - "$1" "$2" <<'PY'
import json, sys
for line in open(sys.argv[1]):
    e = json.loads(line)
    if e["event"] == sys.argv[2]:
        print(json.dumps(e, sort_keys=True))
PY
}
order() { # <file>: the event names in order, one per line
  python3 -I -c 'import json,sys
for l in open(sys.argv[1]): print(json.loads(l)["event"])' "$1"
}
expect_eq() { # <what> <want> <got>
  [[ "$2" == "$3" ]] && ok "$1" || fail "$1: wanted [$2], got [$3]"
}

mkproj() { # <dir> <name> [targets json]
  mkdir -p "$1/src"
  if [[ -n "${3:-}" ]]; then
    printf '{ "name": "%s", "version": "0.1.0", "targets": %s }\n' "$2" "$3" >"$1/botopink.json"
  else
    printf '{ "name": "%s", "version": "0.1.0" }\n' "$2" >"$1/botopink.json"
  fi
}

# ── a clean build ─────────────────────────────────────────────────────────────
echo "==> a clean build: targets, build prints in order, summary"
P="$WORK/clean"
mkproj "$P" clean '["commonJS", "erlang"]'
cat >"$P/src/main.bp" <<'BP'
import {io.terminal.print} from "std";

comptime {
    print("first");
    print("second");
}

pub fn main() -> void {
    print("run");
}
BP
set +e
( cd "$P" && "$BP_BIN" build --json --target commonJS ) >"$WORK/clean.out" 2>"$WORK/clean.err"
CODE=$?
set -e
expect_eq "exit status" 0 "$CODE"
only_json "$WORK/clean.out" && ok "stdout is JSON lines only" || fail "stdout holds a line that is no JSON"
expect_eq "event order" $'targets\nbuild\nbuild\nsummary' "$(order "$WORK/clean.out")"
expect_eq "targets" '{"event": "targets", "target": "commonJS", "targets": ["commonJS", "erlang"]}' "$(events "$WORK/clean.out" targets)"
expect_eq "build prints" $'{"event": "build", "text": "first"}\n{"event": "build", "text": "second"}' "$(events "$WORK/clean.out" build)"
expect_eq "summary" '{"event": "summary", "exit": 0, "ok": true, "refused": 0}' "$(events "$WORK/clean.out" summary)"
grep -q "Compiling" "$WORK/clean.err" && ok "stderr keeps the CLI's messages" || fail "stderr lost 'Compiling'"
( cd "$P" && "$BP_BIN" build --target commonJS --out "$WORK/plain-out" ) >"$WORK/plain.out" 2>"$WORK/plain.err"
expect_eq "stdout without --json is the raw prints" $'first\nsecond' "$(cat "$WORK/plain.out")"
[[ -e "$P/out/main.js" ]] && ok "the artifact is written" || fail "no out/main.js"

# ── a refused build ───────────────────────────────────────────────────────────
echo "==> a refused build: each refusal with its from lines"
P="$WORK/refused"
mkproj "$P" refused
cat >"$P/src/main.bp" <<'BP'
import {compiler, failure.panic, io.terminal.print} from "std";

pub fn shout(syntax t: string) -> string {
    val s = compiler.text(t);
    panic("boom " + s);
    return compiler.build("\"" + s + "\"");
}

pub fn main() -> void {
    print(shout @`hi`);
}
BP
set +e
( cd "$P" && "$BP_BIN" build --json --target commonJS ) >"$WORK/refused.out" 2>"$WORK/refused.err"
CODE=$?
set -e
expect_eq "exit status" 1 "$CODE"
only_json "$WORK/refused.out" && ok "stdout is JSON lines only" || fail "stdout holds a line that is no JSON"
[[ "$(order "$WORK/refused.out" | tail -n 1)" == summary ]] && ok "summary last" || fail "summary is not last"
events "$WORK/refused.out" refused >"$WORK/refused.events"
[[ -s "$WORK/refused.events" ]] && ok "a refused event" || fail "no refused event"
python3 -I - "$WORK/refused.events" <<'PY' && ok "refused carries message, at and from" || fail "refused events lack message / at / from"
import json, sys
es = [json.loads(l) for l in open(sys.argv[1])]
e = es[0]
assert e["message"].startswith("error"), e
assert e["at"] and ".bp:" in e["at"], e
assert "label" in e and "module" in e, e
assert isinstance(e["from"], list), e
assert any(x["from"] for x in es), es
PY
expect_eq "summary is red" '{"event": "summary", "exit": 1, "ok": false, "refused": '"$(wc -l <"$WORK/refused.events" | tr -d ' ')"'}' "$(events "$WORK/refused.out" summary)"
grep -q "error" "$WORK/refused.err" && ok "stderr keeps the rendering" || fail "stderr lost the rendering"

# ── --emit-runtime ────────────────────────────────────────────────────────────
echo "==> --emit-runtime: the path of the intermediate"
P="$WORK/clean"
set +e
( cd "$P" && "$BP_BIN" build --json --target commonJS --emit-runtime "$WORK/rt" ) >"$WORK/rt.out" 2>"$WORK/rt.err"
CODE=$?
set -e
expect_eq "exit status" 0 "$CODE"
only_json "$WORK/rt.out" && ok "stdout is JSON lines only" || fail "stdout holds a line that is no JSON"
ROOT_PATH="$(python3 -I -c 'import json,sys
for l in open(sys.argv[1]):
    e = json.loads(l)
    if e["event"] == "runtime" and e["root"]: print(e["path"])' "$WORK/rt.out")"
expect_eq "the root package's .bpr" "$WORK/rt/clean.bpr" "$ROOT_PATH"
[[ -f "$ROOT_PATH" ]] && ok "the path exists" || fail "the .bpr is not there"
expect_eq "runtime before summary" summary "$(order "$WORK/rt.out" | tail -n 1)"

# ── --cache-root ──────────────────────────────────────────────────────────────
echo "==> --cache-root: the cache is filed under the directory given"
P="$WORK/cache"
mkproj "$P" cache
cp "$WORK/clean/src/main.bp" "$P/src/main.bp"
( cd "$P" && "$BP_BIN" build --json --target commonJS --cache-root "$WORK/croot" ) >"$WORK/cache.out" 2>"$WORK/cache.err" || fail "build with --cache-root failed"
[[ -d "$WORK/croot/.botopinkbuild" ]] && ok "level B filed under --cache-root" || fail "nothing under $WORK/croot/.botopinkbuild"
[[ ! -d "$P/.botopinkbuild/analysis" ]] && ok "the project's own cache untouched" || fail "the project's .botopinkbuild/analysis was written"
( cd "$P" && "$BP_BIN" run --target commonJS --cache-root "$WORK/croot2" ) >"$WORK/run.out" 2>"$WORK/run.err" || fail "run with --cache-root failed"
[[ -d "$WORK/croot2/.botopinkbuild" ]] && ok "run files its cache under --cache-root" || fail "run wrote nothing under $WORK/croot2"
set +e
( cd "$P" && "$BP_BIN" build --cache-root ) >/dev/null 2>"$WORK/cr.err"
CODE=$?
set -e
expect_eq "--cache-root without a directory is refused" 1 "$CODE"

if (( failures > 0 )); then
  echo "build_json.sh: $failures failure(s)" >&2
  exit 1
fi
echo "build_json.sh: every behaviour held"
