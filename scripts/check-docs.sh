#!/usr/bin/env bash
# check-docs.sh — every example of the language reference names a conformance
# cell that exists (`zig build test-docs`; decisions 461, 462).
#
# Usage:
#   scripts/check-docs.sh [--doc <file>]… [--list] [--self-test]
#
#   --doc       a markdown file to check (relative to the repository, or
#               absolute); repeatable, default `conformance/docs.md`,
#               every `conformance/modules/*/docs.md`, every
#               `conformance/modules/*/cases/*/docs.md` and `README.md`
#   --list      print every reference, `<doc>:<line>\t<path>`, and exit
#   --self-test run only the harness's own contract (below) and exit
#
# The reference holds no example of its own (decision 461 (2)): an example is
# a line
#
#   <!-- example: modules/<cell> -->     a cell of conformance/modules/
#   <!-- example: modules/<m>/cases/<c> -->  a case of a module (decision 765)
#   <!-- example: test/<suite> -->       a suite of conformance/test/
#
# whose path is relative to `conformance/`, rendered from the cell's `src/` and
# its `snapshot/` (decision 457). What the example answers is the cell's, and
# `zig build test-conformance` checks it on every target; this script checks
# that the reference and the suite agree on what exists:
#
#   - a `modules/<cell>` or `modules/<m>/cases/<c>` reference names a directory holding `botopink.json`
#     and `src/main.bp`, and a `docs.md` that is not empty — beside each cell
#     the reference names, the reference text it shows (decision 462); a
#     `test/<suite>` reference names a `.bp` file or a directory holding
#     `botopink.json` under `conformance/test/`;
#   - a ```botopink fence is refused: a program in the reference is a cell, and
#     a table, a grammar or a layout sample is fenced as ```text;
#   - a line opening with `<!-- docs-check:` (the directive of the inline
#     fences this script compiled until 144 B-29 step I), and a line opening
#     with `<!-- example:` in any other shape, are refused.
#
# Every refusal is printed `✗ <doc>:<line> <why>`, and the run exits 1 when
# there is one. The last line is `docs: <N> references — <M> missing, <F>
# refused lines` (§ counts in scripts/gate.sh holds N to `--list`).
#
# Every run starts with the harness's own contract — a synthetic doc whose
# lines must get known verdicts (a reference to a cell that exists ✓, to one
# that does not ✗, to a cell whose docs.md is empty ✗, to a suite ✓, a
# ```botopink fence ✗, a `docs-check` comment ✗, an `example:` line with no
# path ✗). A verdict that differs fails
# the run before the docs are judged; `--self-test` runs only it.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$here/.." && pwd)"

docs=()
have_docs=0    # `${#docs[@]}` on an empty array is an unbound variable in bash 3.2
list=0
self_test_only=0
while [ $# -gt 0 ]; do
    case "$1" in
        --doc) docs+=("$2"); have_docs=1; shift 2 ;;
        --doc=*) docs+=("${1#*=}"); have_docs=1; shift ;;
        --list) list=1; shift ;;
        --self-test) self_test_only=1; shift ;;
        -h|--help) sed -n '2,42p' "$0"; exit 0 ;;
        *) echo "check-docs.sh: unknown argument '$1'" >&2; exit 2 ;;
    esac
done
if [ "$have_docs" -eq 0 ]; then
    docs=(conformance/docs.md)
    for d in "$repo"/conformance/modules/*/docs.md; do
        [ -f "$d" ] && docs+=("${d#"$repo"/}")
    done
    for d in "$repo"/conformance/modules/*/cases/*/docs.md; do
        [ -f "$d" ] && docs+=("${d#"$repo"/}")
    done
    docs+=(README.md)
fi

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; NC=$'\033[0m'

# scan <doc path> <doc label> <conformance root> — one line per finding:
#   `ref\t<label>:<line>\t<path>` for a well-formed reference,
#   `bad\t<label>:<line>\t<why>` for a refused line.
scan() {
    awk -v doc="$2" '
        /^```/ {
            if (!infence) {
                infence = 1
                lang = $0; sub(/^```/, "", lang); sub(/[[:space:]]*$/, "", lang)
                if (lang == "botopink")
                    printf "bad\t%s:%d\ta ```botopink fence — a program in the reference is a cell, named by <!-- example: modules/<cell> --> (decision 461)\n", doc, NR
            } else if ($0 ~ /^```[[:space:]]*$/) {
                infence = 0
            }
            next
        }
        infence { next }
        /^<!--[[:space:]]*docs-check:/ {
            printf "bad\t%s:%d\ta docs-check directive — the reference names cells, it compiles nothing (decision 461)\n", doc, NR
            next
        }
        /^<!--[[:space:]]*example:/ {
            line = $0
            if (line ~ /^<!-- example: (modules\/[A-Za-z0-9_.-]+\/cases\/[A-Za-z0-9_.-]+|modules\/[A-Za-z0-9_.-]+|test\/[A-Za-z0-9_.-]+) -->[[:space:]]*$/) {
                sub(/^<!-- example: /, "", line); sub(/ -->[[:space:]]*$/, "", line)
                printf "ref\t%s:%d\t%s\n", doc, NR, line
            } else {
                printf "bad\t%s:%d\tan example line is `<!-- example: modules/<cell> -->` or `<!-- example: test/<suite> -->`, alone on its line\n", doc, NR
            }
        }
    ' "$1"
}

# exists <conformance root> <path> → prints why on failure
exists() {
    local root="$1" p="$2"
    case "$p" in
        modules/*)  # modules/<cell> or modules/<m>/cases/<c> (decision 765)
            if [ -f "$root/$p/botopink.json" ] && [ -f "$root/$p/src/main.bp" ]; then
                [ -s "$root/$p/docs.md" ] && return 0
                printf 'names a cell whose docs.md is empty or missing: conformance/%s/docs.md quotes the reference text the cell shows (decision 462)' "$p"
                return 1
            fi
            printf 'names no cell: conformance/%s has no botopink.json and src/main.bp' "$p" ;;
        test/*)
            { [ -f "$root/$p" ] && [ "${p%.bp}" != "$p" ]; } && return 0
            [ -f "$root/$p/botopink.json" ] && return 0
            printf 'names no suite: conformance/%s is no test/<name>.bp and no test/<project>/' "$p" ;;
    esac
    return 1
}

# check <conformance root> <doc path> <doc label> — prints the verdicts, and
# appends `<refs> <missing> <bad>` to $tally.
check() {
    local root="$1" kind where what why refs=0 missing=0 bad=0
    while IFS=$'\t' read -r kind where what; do
        case "$kind" in
            ref)
                refs=$((refs + 1))
                if why="$(exists "$root" "$what")"; then
                    :
                else
                    missing=$((missing + 1))
                    printf '%s✗ %s %s%s\n' "$RED" "$where" "$why" "$NC"
                fi ;;
            bad)
                bad=$((bad + 1))
                printf '%s✗ %s %s%s\n' "$RED" "$where" "$what" "$NC" ;;
        esac
    done < <(scan "$2" "$3")
    echo "$refs $missing $bad" >>"$tally"
}

work="$(mktemp -d "${TMPDIR:-/tmp}/bp-check-docs.XXXXXX")"
trap 'rm -rf "$work"' EXIT

# ── the harness's own contract ──────────────────────────────────────────────
self_test() {
    local root="$work/self/conformance" doc="$work/self/doc.md" out expected
    mkdir -p "$root/modules/there/src" "$root/modules/bare/src" "$root/test" "$root/modules/m/cases/c/src"
    echo '{ "name": "c", "version": "0.0.1", "src": "src/" }' >"$root/modules/m/cases/c/botopink.json"
    echo 'pub fn main() {}' >"$root/modules/m/cases/c/src/main.bp"
    echo '> the case text' >"$root/modules/m/cases/c/docs.md"
    echo '{ "name": "there", "version": "0.0.1", "src": "src/" }' >"$root/modules/there/botopink.json"
    echo 'pub fn main() {}' >"$root/modules/there/src/main.bp"
    echo '> the reference text' >"$root/modules/there/docs.md"
    echo '{ "name": "bare", "version": "0.0.1", "src": "src/" }' >"$root/modules/bare/botopink.json"
    echo 'pub fn main() {}' >"$root/modules/bare/src/main.bp"
    : >"$root/modules/bare/docs.md"
    echo 'test "t" { assert true; }' >"$root/test/suite.bp"
    cat >"$doc" <<'MD'
<!-- example: modules/there -->
<!-- example: modules/gone -->
<!-- example: test/suite.bp -->
<!-- example: modules/bare -->
```botopink
fn f() {}
```
<!-- docs-check: body -->
<!-- example: -->
```text
<!-- example: modules/gone -->
```
<!-- example: modules/m/cases/c -->
MD
    tally="$work/self/tally"
    : >"$tally"
    out="$(check "$root" "$doc" doc.md | sed "s/$(printf '\033')\[[0-9;]*m//g" | cut -d' ' -f2)"
    expected='doc.md:2
doc.md:4
doc.md:5
doc.md:8
doc.md:9'
    if [ "$out" != "$expected" ] || [ "$(cat "$tally")" != "5 2 3" ]; then
        printf '%s✗ check-docs.sh: the harness contract failed — refused lines:\n%s\ntally: %s%s\n' \
            "$RED" "$out" "$(cat "$tally")" "$NC" >&2
        return 1
    fi
    echo "check-docs.sh: harness contract — 8 verdicts as expected"
}

if [ "$list" -eq 1 ]; then
    for d in "${docs[@]}"; do
        case "$d" in /*) p="$d" ;; *) p="$repo/$d" ;; esac
        [ -f "$p" ] || { echo "check-docs.sh: no such doc: $d" >&2; exit 2; }
        scan "$p" "$d" | awk -F'\t' '$1 == "ref" { printf "%s\t%s\n", $2, $3 }'
    done
    exit 0
fi

self_test || exit 1
[ "$self_test_only" -eq 0 ] || exit 0

tally="$work/tally"
: >"$tally"
for d in "${docs[@]}"; do
    case "$d" in /*) p="$d" ;; *) p="$repo/$d" ;; esac
    [ -f "$p" ] || { echo "check-docs.sh: no such doc: $d" >&2; exit 2; }
    check "$repo/conformance" "$p" "$d"
done
read -r refs missing bad < <(awk '{ r += $1; m += $2; b += $3 } END { printf "%d %d %d\n", r, m, b }' "$tally")
echo "docs: $refs references — $missing missing, $bad refused lines"
if [ "$missing" -eq 0 ] && [ "$bad" -eq 0 ]; then
    printf '%s✓ every example names a conformance cell%s\n' "$GREEN" "$NC"
    exit 0
fi
exit 1
