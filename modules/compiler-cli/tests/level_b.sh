#!/usr/bin/env bash
# The code cache's level B (decision 509 (1), 144 B-60) end to end against the
# real CLI, over the closure invariant's fixture (`closure_invariant/`):
#   • `test-analysis-equivalence` (guard 2): `build --cold`, then `build` with
#     an empty `.botopinkbuild/analysis/` (it writes), then `build` again (it
#     reads) — every file of the three outputs the same bytes, on commonJS
#     (with the `.d.ts`), erlang, beam, wasm and wasm's browser host, for each
#     consumer (`plain` reading the `shelf` entry `crowded` wrote — one
#     library, one entry, whichever consumer wrote it);
#   • an unchanged library's entry is read, never rewritten (its inode stays);
#     `check` and `test` read it too; a changed byte of the library writes a
#     new one;
#   • CODE (S4): an entry `check` wrote (no unit) is written again, larger, by
#     the next build and read, not rewritten, by the ones after (with and
#     without `--typescript`) — the same bytes as `--cold`;
#   • the entries live under the workspace's cache root,
#     `.botopinkbuild/analysis/<target>/<package>.bpa`, std's one per module
#     under `std/`, `wasm` and `wasm.browser` apart.
# The in-process twins (the counters of what was analysed and read, another
# compiler key, a truncated entry) are `cli/analysis_equivalence.zig`'s tests.
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
WORK="$(mktemp -d "${tmp_root%/}/botopink-level-b.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
# The consumers and the libraries sit side by side in one workspace-less
# directory; each consumer is its own cache root. A shared root makes `plain`
# read what `crowded` wrote: both point theirs at `$WORK/cache` through a
# workspace manifest.
cp -R "$SCRIPT_DIR/closure_invariant/." "$WORK/"
cat > "$WORK/botopink.json" <<'JSON'
{ "name": "level_b_fixture", "workspaces": ["plain", "crowded"] }
JSON

failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }

build() { # <consumer> <target> <out> [flags…]
  local consumer="$1" target="$2" out="$3"; shift 3
  if ! ( cd "$WORK/$consumer" && "$BP_BIN" build --target "$target" --out "$out" "$@" ) > "$WORK/build.log" 2>&1; then
    fail "\`botopink build --target $target $*\` of $consumer failed"
    sed 's/^/      /' "$WORK/build.log" >&2
    return 1
  fi
}

browser() { # <consumer>: the consumer's manifest with the browser host
  python3 - "$WORK/$1/botopink.json" <<'PY'
import json, sys
p = sys.argv[1]
m = json.load(open(p))
m["wasm"] = {"host": "browser"}
json.dump(m, open(p, "w"))
PY
}

ANALYSIS="$WORK/.botopinkbuild/analysis"

for variant in commonJS erlang beam wasm wasm.browser; do
  target="$variant"; flags=()
  [[ "$variant" == commonJS ]] && flags=(--typescript)
  if [[ "$variant" == wasm.browser ]]; then
    target=wasm
    for c in crowded plain; do cp "$WORK/$c/botopink.json" "$WORK/$c/botopink.json.orig"; browser "$c"; done
  fi
  bad=0
  for consumer in crowded plain; do
    build "$consumer" "$target" "out-cold-$variant" --cold ${flags[@]+"${flags[@]}"} || { bad=1; continue; }
    if [[ "$consumer" == crowded ]]; then rm -rf "$ANALYSIS/$variant"; fi
    build "$consumer" "$target" "out-write-$variant" ${flags[@]+"${flags[@]}"} || { bad=1; continue; }
    build "$consumer" "$target" "out-read-$variant" ${flags[@]+"${flags[@]}"} || { bad=1; continue; }
    for run in write read; do
      if ! diff -r "$WORK/$consumer/out-cold-$variant" "$WORK/$consumer/out-$run-$variant" > "$WORK/diff.log"; then
        fail "$variant: $consumer's output built through level B ($run) differs from its --cold build"
        head -20 "$WORK/diff.log" | sed 's/^/      /' >&2
        bad=1
      fi
    done
  done
  [[ -f "$ANALYSIS/$variant/shelf.bpa" ]] || { fail "$variant: no shelf entry under .botopinkbuild/analysis/$variant/"; bad=1; }
  [[ -f "$ANALYSIS/$variant/rival.bpa" ]] || { fail "$variant: no rival entry under .botopinkbuild/analysis/$variant/"; bad=1; }
  [[ -f "$ANALYSIS/$variant/std/collections.bpa" ]] || { fail "$variant: no std/collections entry under .botopinkbuild/analysis/$variant/std/"; bad=1; }
  [[ ! -e "$ANALYSIS/$variant/crowded.bpa" && ! -e "$ANALYSIS/$variant/plain.bpa" ]] || { fail "$variant: the package under build was stored"; bad=1; }
  if [[ "$variant" == wasm.browser ]]; then
    for c in crowded plain; do mv "$WORK/$c/botopink.json.orig" "$WORK/$c/botopink.json"; done
  fi
  [[ "$bad" -eq 0 ]] && echo "  ✓ $variant: --cold, writing and reading builds emit the same bytes; one entry per library and std module"
done

# Read, not rewritten: the entry's inode survives a warm build, `check` and
# `test`; a changed byte of shelf writes a new one.
inode() { stat -c %i "$1" 2>/dev/null || stat -f %i "$1"; }
entry="$ANALYSIS/erlang/shelf.bpa"
before="$(inode "$entry")"
build plain erlang out-again || true
( cd "$WORK/plain" && "$BP_BIN" check ) > "$WORK/check.log" 2>&1 || { fail "\`botopink check\` of plain failed"; sed 's/^/      /' "$WORK/check.log" >&2; }
[[ "$(inode "$entry")" == "$before" ]] || fail "erlang: shelf's entry was rewritten by a build or a check that should have read it"
mkdir -p "$WORK/plain/test"
cat > "$WORK/plain/test/plain_test.bp" <<'BP'
import {items.Queue, items.describe} from "shelf";

test "describe reads the library" {
    assert describe(Queue(label: "t", size: 1)) == "t:1";
}
BP
( cd "$WORK/plain" && "$BP_BIN" test --target erlang ) > "$WORK/test.log" 2>&1 || { fail "\`botopink test\` of plain failed"; sed 's/^/      /' "$WORK/test.log" >&2; }
[[ "$(inode "$entry")" == "$before" ]] || fail "erlang: shelf's entry was rewritten by \`botopink test\`"
printf '\n' >> "$WORK/shelf/src/tools.bp"
build plain erlang out-changed || true
[[ "$(inode "$entry")" != "$before" ]] || fail "erlang: a changed byte of shelf left its entry as it was"
[[ "$failures" -eq 0 ]] && echo "  ✓ an unchanged library's entry is read by build, check and test, never rewritten; a changed byte writes a new one"

# CODE (S4): an entry `check` (commonJS) wrote holds no unit; the next build
# emits the dependencies and writes the entry again, larger, with its CODE —
# the `.d.ts` in it although that build asked for none; the builds after read
# it and write nothing, with or without `--typescript` — every output the
# same bytes as `--cold`. (That a reading build emitted no dependency module
# is `Stats.modules_code_read`, `cli/analysis_equivalence.zig`'s.)
size() { stat -c %s "$1" 2>/dev/null || stat -f %z "$1"; }
code_failures=$failures
cjs_entry="$ANALYSIS/commonJS/shelf.bpa"
build plain commonJS out-code-cold --cold || true
build plain commonJS out-code-cold-ts --cold --typescript || true
rm -rf "$ANALYSIS/commonJS"
( cd "$WORK/plain" && "$BP_BIN" check ) > "$WORK/check.log" 2>&1 || { fail "\`botopink check\` of plain failed"; sed 's/^/      /' "$WORK/check.log" >&2; }
if [[ -f "$cjs_entry" ]]; then
  checked_inode="$(inode "$cjs_entry")"; checked_size="$(size "$cjs_entry")"
  build plain commonJS out-code-first || true
  [[ "$(inode "$cjs_entry")" != "$checked_inode" && "$(size "$cjs_entry")" -gt "$checked_size" ]] \
    || fail "commonJS: the build after \`check\` did not write shelf's entry again with its CODE"
  coded_inode="$(inode "$cjs_entry")"
  build plain commonJS out-code-second || true
  build plain commonJS out-code-second-ts --typescript || true
  [[ "$(inode "$cjs_entry")" == "$coded_inode" ]] || fail "commonJS: a build reading shelf's entry with its CODE wrote it again"
  for run in first second second-ts; do
    cold="out-code-cold"; [[ "$run" == *-ts ]] && cold="out-code-cold-ts"
    diff -r "$WORK/plain/$cold" "$WORK/plain/out-code-$run" > "$WORK/diff.log" \
      || { fail "commonJS: plain's $run build through CODE differs from its --cold build"; head -20 "$WORK/diff.log" | sed 's/^/      /' >&2; }
  done
else
  fail "commonJS: \`check\` wrote no shelf entry"
fi
[[ "$failures" -eq "$code_failures" ]] && echo "  ✓ an entry \`check\` wrote gets its CODE (the .d.ts in it) from the next build, once; reading it emits the same bytes, with or without --typescript"

if [[ "$failures" -ne 0 ]]; then
  echo "level B: $failures failure(s)" >&2
  exit 1
fi
echo "level B: a dependency's analysis read back emits what analysing it emits, on every target"
