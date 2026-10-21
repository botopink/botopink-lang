#!/usr/bin/env bash
# proof.sh — the proof of decision 790 (3): the CLI's `botopink cell check` and the program of
# `conformance/check/` run over the same paths, and their reports and the `.snap.new` candidates they
# write are compared byte for byte. It leaves with the CLI's `cell check` at B-161's switch (798 (6)).
#
# Usage (from the directory the paths are relative to, e.g. the repository root):
#   conformance/check/proof.sh [--jobs <N>] [--compiler <botopink>] <cell|directory>…
#
#   --jobs      cells checked at once by each of the two; default the CLI's own default
#   --compiler  the `botopink` binary; default <repo>/zig-out/bin/botopink
#
# Each run starts from no candidate (both delete a cell's old `*.snap.new` before checking it); the
# candidates each run wrote are moved into the proof's scratch directory, so the tree is left with
# none, and compared there. Prints the two wall times, then the differences; exits 0 when there is
# none, 1 otherwise.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
compiler="$repo/zig-out/bin/botopink"
jobs=()
paths=()
while [ $# -gt 0 ]; do
    case "$1" in
        --jobs) jobs=(--jobs "$2"); shift 2 ;;
        --jobs=*) jobs=(--jobs "${1#*=}"); shift ;;
        --compiler) compiler="$2"; shift 2 ;;
        --compiler=*) compiler="${1#*=}"; shift ;;
        -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
        -*) echo "proof.sh: unknown argument '$1'" >&2; exit 2 ;;
        *) paths+=("$1"); shift ;;
    esac
done
[ ${#paths[@]} -gt 0 ] || { echo "proof.sh: name the cells or directories to check" >&2; exit 2; }
[ -x "$compiler" ] || { echo "proof.sh: compiler not found or not executable: $compiler" >&2; exit 2; }
compiler="$(cd "$(dirname "$compiler")" && pwd)/$(basename "$compiler")"

work="$(mktemp -d "${TMPDIR:-/tmp}/bp-proof.XXXXXX")" || exit 2
trap 'rm -rf "$work"' EXIT

# The candidates under the paths, moved to <dir> by their path.
collect() { # <dir>
    local f
    while IFS= read -r f; do
        mkdir -p "$1/$(dirname "$f")"
        mv "$f" "$1/$f"
    done < <(find "${paths[@]}" -name '*.snap.new' -not -path '*/.botopinkbuild/*' 2>/dev/null | sort)
}

( cd "$here" && "$compiler" build --target commonJS --out "$work/program" ) >"$work/program-build.txt" 2>&1 \
    || { echo "proof.sh: the program does not build:" >&2; cat "$work/program-build.txt" >&2; exit 2; }

start=$(date +%s%N)
"$compiler" cell check "${jobs[@]}" "${paths[@]}" >"$work/cli.txt" 2>"$work/cli.err"
cli_code=$?
cli_time=$(( ($(date +%s%N) - start) / 1000000 ))
collect "$work/cli-new"

start=$(date +%s%N)
BOTOPINK_BIN="$compiler" node "$work/program/main.js" "${paths[@]}" "${jobs[@]}" >"$work/program.txt" 2>"$work/program.err"
program_code=$?
program_time=$(( ($(date +%s%N) - start) / 1000000 ))
collect "$work/program-new"

echo "wall time: cli ${cli_time} ms (exit $cli_code), program ${program_time} ms (exit $program_code)"
differ=0
if ! diff -u --label cli --label program "$work/cli.txt" "$work/program.txt"; then differ=1; fi
mkdir -p "$work/cli-new" "$work/program-new"
if ! diff -ru "$work/cli-new" "$work/program-new" >"$work/new.diff"; then differ=1; sed "s#$work/##g" "$work/new.diff"; fi
if [ "$cli_code" -ne "$program_code" ]; then echo "exit status: cli $cli_code, program $program_code"; differ=1; fi
if [ -s "$work/program.err" ]; then echo "the program's stderr:"; sed 's/^/    /' "$work/program.err"; fi
[ $differ -eq 0 ] && echo "proof: the reports and the candidates agree byte for byte"
exit $differ
