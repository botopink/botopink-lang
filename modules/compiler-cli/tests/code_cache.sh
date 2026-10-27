#!/usr/bin/env bash
# The code cache, level A (decision 509 of 1.0.12-beta, 144 B-58), and the
# workspace a cell inherits its dependencies from (decision 512), end to end
# against the real CLI:
#   • a member that writes its name alone builds against the dependency its
#     workspace declares (`"dependencies"` inherited, a `path` resolved from the
#     workspace's manifest), on erlang and on beam
#   • two members over one dependency compile it once: the second run links
#     every dependency `.beam` from the store (the entry's inode, unchanged),
#     adds no entry, and beam's runs of both keep the store in the workspace
#   • `run`, `test` and `build` share a dependency's entries: its production
#     unit is the same bytes under each (decision 513, 144 B-64)
#   • the member's own modules are compiled every time: never stored, never a
#     link to an entry
#   • a changed byte of the dependency misses: a new entry, the new answer
#   • `build --target erlang` materialises the dependencies' `.beam` into the
#     output, each the cache entry's bytes, none for the member's own modules
#     (decision 767, `build_materialises_dependency_beams`)
#   • `--cold` reads nothing (every `.beam` compiled afresh, every entry
#     rewritten) and writes what it ran
#   • two concurrent writers over one empty store leave one whole entry per
#     key, no staging file behind
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
BP="${BOTOPINK_BIN:-$REPO_ROOT/zig-out/bin/botopink}"
[[ -x "$BP" ]] || { echo "error: CLI binary not found at $BP" >&2; exit 1; }
command -v erl >/dev/null 2>&1 || { echo "error: erl is not on PATH — the erlang and beam targets need it" >&2; exit 1; }

tmp_root="${TMPDIR:-/tmp}"
WORK="$(mktemp -d "${tmp_root%/}/botopink-code-cache.XXXXXX")"
cleanup() { chmod -R u+w "$WORK" 2>/dev/null || true; rm -rf "$WORK"; }
trap cleanup EXIT

fail() { echo "  ✗ $1" >&2; exit 1; }
ok() { echo "  ✓ $1"; }

# ── the fixture: a workspace of two cells over one library ──────────────────
WS="$WORK/cells"
STORE="$WS/.botopinkbuild/cache/code"
mkdir -p "$WORK/lib/src" "$WS/one/src" "$WS/two/src"
printf '{ "name": "lib", "entry": "root.bp", "files": ["root.bp"] }\n' >"$WORK/lib/botopink.json"
# The library declares a test of its own: a consumer never emits it, so its
# production unit is the same under `build`, `run` and `test` (decision 513).
printf 'pub fn greet(n: string) -> string {\n    return "hello " + n;\n}\n\ntest "greets" {\n    assert greet("a") == "hello a";\n}\n' >"$WORK/lib/src/root.bp"
cat >"$WS/botopink.json" <<'EOF'
{
  "name": "cells",
  "version": "0.0.1",
  "workspaces": ["*"],
  "dependencies": { "lib": { "path": "../lib" } }
}
EOF
for c in one two; do
  printf '{ "name": "%s" }\n' "$c" >"$WS/$c/botopink.json"
  printf 'import {io.terminal.print} from "std";\nimport {greet} from "lib";\n\npub fn main() -> void {\n    print(greet("%s"));\n}\n' "$c" >"$WS/$c/src/main.bp"
done

run_in() { # <dir> <args…> — stdout+stderr to $OUT, status to $CODE
  local d="$1"; shift
  set +e
  OUT="$(cd "$d" && "$BP" "$@" 2>&1)"
  CODE=$?
  set -e
}
entries() { find "$STORE" -name '*.beam' 2>/dev/null | wc -l | tr -d ' '; }
inodes() { find "$STORE" -name '*.beam' -printf '%i %P\n' 2>/dev/null | sort; }
inode() { stat -c %i "$1"; }
links() { stat -c %h "$1"; }

echo "==> a member inherits its workspace's dependency"
run_in "$WS/one" run --target erlang
[[ $CODE -eq 0 ]] || { echo "$OUT" >&2; fail "run of a member that writes its name alone (exit $CODE)"; }
grep -q '^hello one$' <<<"$OUT" || { echo "$OUT" >&2; fail "the member reaches the inherited lib"; }
ok "\`{ \"name\": \"one\" }\` builds against the workspace's \`lib\`"

echo "==> the store holds the dependencies' modules, never the member's"
N1="$(entries)"
[[ "$N1" -gt 0 ]] || fail "the dependencies' .beam files are stored under the workspace root ($STORE)"
OWN="$WS/one/out/erlang/one@main.beam"
[[ -f "$OWN" ]] || fail "the member's own module was compiled ($OWN)"
[[ "$(links "$OWN")" -eq 1 ]] || fail "the member's own .beam is no link to an entry"
DEP_ERL="$(find "$WS/one/out/erlang" -name '*@*.erl' ! -name 'one@*' | wc -l | tr -d ' ')"
[[ "$N1" -eq "$DEP_ERL" ]] || fail "one entry per dependency module ($N1 entries, $DEP_ERL dependency modules)"
LIB1="$WS/one/out/erlang/lib@root.beam"
[[ "$(links "$LIB1")" -ge 2 ]] || fail "a dependency's .beam is a link to its entry"
ok "$N1 entries, each a dependency's module; the member's own module is not one"

echo "==> two members over one dependency compile it once"
BEFORE="$(inodes)"
run_in "$WS/two" run --target erlang
[[ $CODE -eq 0 ]] && grep -q '^hello two$' <<<"$OUT" || { echo "$OUT" >&2; fail "run of the second member"; }
[[ "$(entries)" -eq "$N1" ]] || fail "the second member added entries ($(entries) against $N1)"
[[ "$(inodes)" == "$BEFORE" ]] || fail "an entry was written again — the second member compiled a dependency"
[[ "$(inode "$WS/two/out/erlang/lib@root.beam")" -eq "$(inode "$LIB1")" ]] || fail "the second member's lib .beam is the entry the first stored"
[[ "$(links "$WS/two/out/erlang/two@main.beam")" -eq 1 ]] || fail "the second member's own module was compiled"
ok "the second member linked every dependency .beam, compiled its own"

echo "==> build, run and test share a dependency's entry"
BEFORE="$(inodes)"
run_in "$WS/one" test --target erlang
[[ $CODE -eq 0 ]] || { echo "$OUT" >&2; fail "test of the first member (exit $CODE)"; }
[[ "$(inodes)" == "$BEFORE" ]] || fail "test stored a dependency entry run had stored already — the dependency's production unit differs under test"
run_in "$WS/one" build --target erlang
[[ $CODE -eq 0 ]] || { echo "$OUT" >&2; fail "build of the first member (exit $CODE)"; }
[[ "$(inodes)" == "$BEFORE" ]] || fail "build stored a dependency entry run had stored already"
ok "test and build link the dependency entries run stored (decision 513)"

echo "==> build_materialises_dependency_beams: build leaves the dependencies' .beam in the output, and its own"
rm -rf "$WS/one/out"
run_in "$WS/one" build --target erlang
[[ $CODE -eq 0 ]] || { echo "$OUT" >&2; fail "build of the first member (exit $CODE)"; }
for e in "$WS"/one/out/erlang/lib@*.erl; do
  b="${e%.erl}.beam"
  [[ -f "$b" ]] || fail "build left no .beam beside $(basename "$e")"
  [[ "$(links "$b")" -ge 2 ]] || fail "$(basename "$b") is no link to its cache entry"
done
# Decision 1007 (2): the build's OTP check writes the member's own `.beam` too — never stored, no link.
OWN_BEAM="$WS/one/out/erlang/one@main.beam"
[[ -f "$OWN_BEAM" && "$(links "$OWN_BEAM")" -eq 1 && -s "$OWN_BEAM.rec" ]] || fail "build wrote no own .beam with its record, or linked it to the store"
DEP_BEAMS="$(find "$WS/one/out/erlang" -name '*@*.beam' ! -name 'one@*' | wc -l | tr -d ' ')"
[[ "$DEP_BEAMS" -eq "$(find "$WS/one/out/erlang" -name '*@*.erl' ! -name 'one@*' | wc -l | tr -d ' ')" ]] || fail "one .beam per dependency module"
ok "$DEP_BEAMS dependency .beam files, links to the entries; the member's own module compiled beside its .erl, never stored"

echo "==> beam: both members, one store in the workspace"
for m in one two; do
  run_in "$WS/$m" run --target beam
  [[ $CODE -eq 0 ]] || { echo "$OUT" >&2; fail "run --target beam of member $m (exit $CODE)"; }
  grep -q "hello $m" <<<"$OUT" || { echo "$OUT" >&2; fail "member $m prints its greeting on beam"; }
done
# erlang reads the entries the runs stored; beam adds its own (the `.S` step).
N_BEAM="$(entries)"
[[ "$N_BEAM" -gt "$N1" ]] || fail "beam's assembly of the dependencies is stored too"
AFTER_BEAM="$(inodes)"
for m in one two; do
  run_in "$WS/$m" run --target beam
  [[ $CODE -eq 0 ]] || { echo "$OUT" >&2; fail "a second beam run of member $m"; }
done
[[ "$(inodes)" == "$AFTER_BEAM" ]] || fail "a warm beam run wrote an entry again"
ok "$N_BEAM entries in the workspace's store; a warm run writes none"

echo "==> a changed byte of the dependency misses"
printf 'pub fn greet(n: string) -> string {\n    return "hullo " + n;\n}\n' >"$WORK/lib/src/root.bp"
run_in "$WS/one" run --target erlang
[[ $CODE -eq 0 ]] && grep -q '^hullo one$' <<<"$OUT" || { echo "$OUT" >&2; fail "the changed dependency's answer"; }
[[ "$(entries)" -eq $((N_BEAM + 1)) ]] || fail "one new entry for the one changed module ($(entries) against $((N_BEAM + 1)))"
ok "the changed module compiled and stored beside the old entries"

echo "==> --cold reads nothing and writes what it ran"
BEFORE="$(inodes)"
# Pin every entry's inode with a link of our own while the cold run writes:
# ext4 hands a freed inode number to the next file it creates, so an entry
# written twice by the cold run (the build's check, then `run`'s compile) can
# land on the inode it started on, and "another inode" would read as "never
# rewritten". A pinned inode is never freed, so a rewrite always shows.
PIN="$WORK/pin"
mkdir -p "$PIN"
while read -r ino rel; do ln "$STORE/$rel" "$PIN/$ino"; done <<<"$BEFORE"
# Without `out/`: a `.beam` there whose record matches is loaded as it is, `--cold` too (decision 1007 (3)).
rm -rf "$WS/one/out"
run_in "$WS/one" run --target erlang --cold
[[ $CODE -eq 0 ]] && grep -q '^hullo one$' <<<"$OUT" || { echo "$OUT" >&2; fail "a cold run"; }
[[ "$(links "$WS/one/out/erlang/lib@root.beam")" -eq 1 ]] || fail "--cold links nothing from the store"
# Entries the cold run wrote again: the same name, another inode.
REWRITTEN="$(join <(echo "$BEFORE" | awk '{print $2, $1}' | sort) <(inodes | awk '{print $2, $1}' | sort) | awk '$2 != $3' | wc -l | tr -d ' ')"
DEP_NOW="$(find "$WS/one/out/erlang" -name '*@*.erl' ! -name 'one@*' | wc -l | tr -d ' ')"
[[ "$REWRITTEN" -eq "$DEP_NOW" ]] || fail "--cold rewrote every entry of the run's dependencies ($REWRITTEN of $DEP_NOW)"
chmod -R u+w "$PIN"; rm -rf "$PIN"
ok "every dependency compiled afresh and its entry written again"

echo "==> two concurrent writers leave one whole entry"
chmod -R u+w "$WS/.botopinkbuild"; rm -rf "$WS/.botopinkbuild"
( cd "$WS/one" && "$BP" run --target erlang >"$WORK/c1.txt" 2>&1 ) &
P1=$!
( cd "$WS/two" && "$BP" run --target erlang >"$WORK/c2.txt" 2>&1 ) &
P2=$!
wait "$P1" || { cat "$WORK/c1.txt" >&2; fail "the first concurrent run"; }
wait "$P2" || { cat "$WORK/c2.txt" >&2; fail "the second concurrent run"; }
grep -q '^hullo one$' "$WORK/c1.txt" && grep -q '^hullo two$' "$WORK/c2.txt" || fail "both concurrent runs answer"
[[ "$(entries)" -eq "$DEP_NOW" ]] || fail "one entry per key ($(entries) against $DEP_NOW)"
[[ -z "$(find "$STORE" -name '*.tmp')" ]] || fail "no staging file is left behind"
BAD="$(erl -noshell -eval '[Dir] = init:get_plain_arguments(), Bad = [F || F <- filelib:wildcard(filename:join([Dir, "*", "*.beam"])), case beam_lib:info(F) of {error, _, _} -> true; _ -> false end], io:format("~p", [length(Bad)]), halt().' -extra "$STORE")"
[[ "$BAD" == "0" ]] || fail "every entry is a whole .beam ($BAD are not)"
ok "$(entries) whole entries, nothing staged"

echo "code_cache.sh: every behaviour held"
