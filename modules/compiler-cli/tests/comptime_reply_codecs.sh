#!/usr/bin/env bash
# Decisions 550, 1035 (4), 1038 (3), 1058 (1), 1060 — the comptime crossing's
# codecs written in botopink (`libs/std/src/compiler.bp` § the crossing),
# against what the Erlang path records:
#   • every distinct `COMPTIME REPLY` section of compiler-core's snapshots (its
#     evaluator's kind and its JSON) is read by `compiler.jsonRead` into the
#     typed reply of its dialect (`decoratorReplyOf` / `templateReplyOf` /
#     `blockReplyOf`), written back by that dialect's encoder and rendered by
#     `compiler.jsonPretty` — the oracle of C2: the reply the botopink encoder
#     writes is the reply the Erlang path recorded, the float texts of
#     `comptime_floats_in_a_block_reply` and the `null` of an index out of
#     range (`comptime_index_out_of_range_answers_null`, 1060 (3)) included;
#   • every distinct argument a snapshot lists (`;; ArgN = <term>`, a
#     decorator's handle, a template's capture, a plain argument), written as
#     the crossing's JSON by `term_json.js`, read by `compiler.argOf` into its
#     typed slot (`Decl`, `Capture`, a plain value) and written back by
#     `argJson`, is that JSON — and so are the hand-written inputs of
#     `inputs.txt` (the shapes no snapshot lists: hooks, typed meta, a lookup
#     handle, a tag, holes, tag answers, a whole `Input`);
#   • a block's reply writes each float as the Erlang path does,
#     `float_to_binary(F, [short])` (1060 (2)): `1.5`, `0.30000000000000004`,
#     `1.0e21`, `1.0e-7`, `-0.0`;
#   • `compiler.raisedText` writes the runtime errors 1038 (3) keeps
#     (division by zero, a `case` no arm matched, `badarith`) as the matchers
#     of `comptime/block_eval.zig` read them; `decoratorEnd` / `blockEnd`
#     write `printed` only when the body printed (1059 (2)).
# The program's output is all of it byte for byte on erlang and commonJS.
# wasm joins the loop once the GC lowering hosts the codecs (two gaps of
# front 144 stop it: an optional of an enum — `xs.at(i)` over `Json[]` — has
# no GC conversion, and an array bound by a `case` arm and mapped by a lambda
# reads the wrong slot).
#
# The cases are generated from the snapshots at each run, so a re-recorded
# section is checked as it is. BOTOPINK_BIN points the script at another
# binary. Exit 0 = every case equal on every target.

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
WORK="$(mktemp -d "${tmp_root%/}/botopink-comptime-reply-codecs.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
cp -R "$SCRIPT_DIR/comptime_reply_codecs/." "$WORK/"
APP="$WORK/codecs"
SNAP="$REPO_ROOT/modules/compiler-core/snapshots"

failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }

# Every `COMPTIME REPLY` section: `<kind>` on its first line, its JSON after.
mkdir -p "$WORK/sections"
grep -rl --include='*.snap.md' -e '^----- COMPTIME REPLY -- ' "$SNAP" | LC_ALL=C sort | xargs cat | awk -v out="$WORK/sections" '
  /^----- COMPTIME REPLY -- / { kind = $5; want = 1; next }
  want == 1 && /^```json$/ { n++; file = sprintf("%s/%04d", out, n); print kind > file; want = 2; next }
  want == 1 { want = 0; next }
  want == 2 && /^```$/ { close(file); want = 0; next }
  want == 2 { print > file }
'
total="$(find "$WORK/sections" -type f | wc -l)"
(( total > 0 )) || { echo "error: no COMPTIME REPLY section under $SNAP" >&2; exit 1; }

# The distinct ones, in the order first met.
mkdir -p "$WORK/distinct"
declare -A seen=()
for f in "$WORK/sections"/*; do
  sum="$(md5sum < "$f" | cut -d' ' -f1)"
  [[ -n "${seen[$sum]:-}" ]] && continue
  seen[$sum]=1
  cp "$f" "$WORK/distinct/$(basename "$f")"
done
distinct="$(find "$WORK/distinct" -type f | wc -l)"

# Every argument a snapshot lists, one term a line, then the hand-written
# inputs: `<kind>\t<json>` (`arg` a slot, `input` a whole `Input`).
grep -rl --include='*.snap.md' -e '^;; Arg[0-9]* = ' "$SNAP" | LC_ALL=C sort | xargs cat | awk '
  function flush() { if (term != "") print term; term = "" }
  /^;; Arg[0-9]+ = / { flush(); sub(/^;; Arg[0-9]+ = /, ""); term = $0; inarg = 1; next }
  inarg && /^;; main\/1/ { flush(); inarg = 0; next }
  inarg && /^;;/ { sub(/^;; */, " "); term = term $0; next }
  inarg { flush(); inarg = 0 }
  END { flush() }
' | LC_ALL=C sort -u > "$WORK/terms.txt"
args="$(wc -l < "$WORK/terms.txt")"
(( args > 0 )) || { echo "error: no argument listing under $SNAP" >&2; exit 1; }
node "$SCRIPT_DIR/comptime_reply_codecs/term_json.js" < "$WORK/terms.txt" | sed 's/^/arg\t/' > "$WORK/inputs.txt"
cut -f1 "$SCRIPT_DIR/comptime_reply_codecs/inputs.txt" > "$WORK/kinds.txt"
cut -f2- "$SCRIPT_DIR/comptime_reply_codecs/inputs.txt" | node "$SCRIPT_DIR/comptime_reply_codecs/term_json.js" --json | paste "$WORK/kinds.txt" - >> "$WORK/inputs.txt"
handwritten="$(wc -l < "$SCRIPT_DIR/comptime_reply_codecs/inputs.txt")"

# A botopink string literal of stdin's text.
literal() { sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\$/\\$/g' | awk 'BEGIN { ORS = "" } NR > 1 { print "\\n" } { print }'; }

# `cases.bp`: each section and each input as a botopink string literal, and
# what the program must print for it.
{
  echo '//// Generated by comptime_reply_codecs.sh from the COMPTIME REPLY sections.'
  echo ''
  echo 'pub type Recorded(dialect: string, text: string)'
  echo ''
  echo 'pub fn recorded() -> Recorded[] {'
  echo '    return ['
  for f in "$WORK/distinct"/*; do
    kind="$(head -1 "$f")"
    dialect="block"
    [[ "$kind" == "template" ]] && dialect="template"
    [[ "$kind" == "decorator" ]] && dialect="decorator"
    text="$(tail -n +2 "$f" | literal)"
    printf '        Recorded(dialect: "%s", text: "%s"),\n' "$dialect" "$text"
  done
  echo '    ];'
  echo '}'
  echo ''
  echo 'pub fn inputs() -> Recorded[] {'
  echo '    return ['
  while IFS=$'\t' read -r kind json; do
    printf '        Recorded(dialect: "%s", text: "%s"),\n' "$kind" "$(printf '%s' "$json" | literal)"
  done < "$WORK/inputs.txt"
  echo '    ];'
  echo '}'
} > "$APP/src/cases.bp"
{
  for f in "$WORK/distinct"/*; do
    tail -n +2 "$f"
    echo '----- end'
  done
  cut -f2- "$WORK/inputs.txt"
  echo '----- floats'
  echo '{"float":1.5}'
  echo '{"float":0.30000000000000004}'
  echo '{"float":1.0e21}'
  echo '{"float":1.0e-7}'
  echo '{"float":-0.0}'
  echo '----- errors'
  echo '{error,{bp_wat_runtime,<<"division by zero">>}}'
  echo '{error,{case_clause,#{label => <<"x">>,size => 3}}}'
  echo '{error,badarith}'
  echo '----- printed'
  echo '{"kind":"value","value":null}'
  echo '{"kind":"value","printed":"hi\n","value":null}'
  echo '{"contributions":[],"kind":"ok"}'
  echo '{"contributions":[],"kind":"ok","printed":"a\nb\n"}'
} > "$WORK/want.out"

for target in erlang commonJS; do
  if ( cd "$APP" && "$BP_BIN" run --target "$target" --out "$WORK/out-$target" ) > "$WORK/$target.log" 2>&1; then
    grep -v -e 'Compiling' -e 'Compiled' "$WORK/$target.log" > "$WORK/$target.out" || true
    if diff "$WORK/want.out" "$WORK/$target.out" > "$WORK/$target.diff"; then
      echo "  ✓ $target: $distinct of $distinct distinct replies ($total sections) and $((args + handwritten)) inputs ($args listed, $handwritten hand-written) written back byte for byte"
    else
      fail "$target: the replies the botopink encoder writes differ from the recorded ones"
      sed 's/^/      /' "$WORK/$target.diff" | head -60 >&2
    fi
  else
    fail "the $target run failed"
    sed 's/^/      /' "$WORK/$target.log" | head -40 >&2
  fi
done

if (( failures > 0 )); then
  echo "comptime_reply_codecs: $failures failure(s)" >&2
  exit 1
fi
echo "comptime_reply_codecs: ok"
