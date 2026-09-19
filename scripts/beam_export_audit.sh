#!/usr/bin/env bash
# beam_export_audit.sh — assemble every BEAM snapshot module with every
# function exported.
#
# A recorded `.S` module carries a narrow `{exports, [...]}` form, and
# `erlc +from_asm` drops an unexported function before `beam_validator` sees
# it — so a register bug inside a function nothing exports never surfaces in
# the RUN LOG. This script extracts each `----- BEAM ASSEMBLY -- <m>.S` block
# from `modules/compiler-core/snapshots/codegen/beam/*.snap.md`, rewrites its
# exports form to name every `{function, Name, Arity, _}` form, and assembles
# it. Read-only: the snapshots are not touched.
#
# Usage:
#   scripts/beam_export_audit.sh [--jobs=N] [--keep=<dir>] [<snap.md>…]
#
#   --jobs=N     parallel `erlc` processes (default: nproc)
#   --keep=<dir> write the rewritten modules under <dir> instead of a
#                temporary directory that is deleted on exit
#   <snap.md>…   audit only these snapshots (default: the whole beam dir)
#
# Output: one `REJECTED <snapshot> <module>` block per rejected module with
# the assembler/validator diagnostics (function, offset, reason), then a
# summary line `beam_export_audit: <ok>/<total> modules assembled`.
#
# Exit codes:
#   0  every module assembled
#   1  at least one module was rejected
#   2  argument error, snapshot dir missing, or `erlc` not on PATH
set -euo pipefail

jobs=""
keep=""
files=()
for a in "$@"; do
    case "$a" in
        --jobs=*) jobs="${a#--jobs=}" ;;
        --keep=*) keep="${a#--keep=}" ;;
        -h|--help) sed -n '2,29p' "$0"; exit 0 ;;
        --*) echo "beam_export_audit: unknown argument '$a'" >&2; exit 2 ;;
        *) files+=("$a") ;;
    esac
done

command -v erlc >/dev/null 2>&1 || { echo "beam_export_audit: erlc not found on PATH" >&2; exit 2; }

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
botlang_root="$(cd "$script_dir/.." && pwd)"
snap_dir="$botlang_root/modules/compiler-core/snapshots/codegen/beam"
if [ "${#files[@]}" -eq 0 ]; then
    [ -d "$snap_dir" ] || { echo "beam_export_audit: $snap_dir not found" >&2; exit 2; }
    while IFS= read -r f; do files+=("$f"); done < <(find "$snap_dir" -name '*.snap.md' | sort)
fi
[ -n "$jobs" ] || jobs="$(nproc 2>/dev/null || echo 4)"

if [ -n "$keep" ]; then
    work="$keep"
    mkdir -p "$work"
else
    work="$(mktemp -d)"
    trap 'rm -rf "$work"' EXIT
fi

# Split every snapshot into one directory per module (`<n>/<module>.S`) with
# the exports form rewritten. The block's own module atom names the file, so
# a multi-module snapshot yields several directories; `index.tsv` maps each
# directory back to its snapshot.
: > "$work/index.tsv"
n=0
for f in "${files[@]}"; do
    slug="$(basename "$f" .snap.md)"
    # Blocks: lines between "```erlang" and "```" after a BEAM ASSEMBLY header.
    awk -v work="$work" -v slug="$slug" -v start="$n" '
        function flush(   i, out, dir, exports, sep) {
            if (nl == 0) return
            dir = work "/" idx
            system("mkdir -p \"" dir "\"")
            exports = ""; sep = ""
            for (i = 1; i <= nf; i++) { exports = exports sep fns[i]; sep = ", " }
            out = dir "/" mod ".S"
            for (i = 1; i <= nl; i++) {
                if (lines[i] ~ /^\{exports, /) print "{exports, [" exports "]}." > out
                else print lines[i] > out
            }
            close(out)
            print idx "\t" slug "\t" mod >> (work "/index.tsv")
            idx++; nl = 0; nf = 0; mod = ""
        }
        BEGIN { idx = start; in_asm = 0; want = 0; nl = 0; nf = 0 }
        /^----- BEAM ASSEMBLY -- / { want = 1; next }
        /^----- /                  { want = 0; next }
        want && /^```erlang/       { in_asm = 1; next }
        in_asm && /^```/           { in_asm = 0; want = 0; flush(); next }
        in_asm {
            lines[++nl] = $0
            if ($0 ~ /^\{module, /) {
                mod = $0; sub(/^\{module, /, "", mod); sub(/\}\.$/, "", mod)
            }
            if ($0 ~ /^\{function, /) {
                # {function, Name, Arity, Entry}. — Name may be quoted and
                # contain commas, so split from the right.
                body = $0; sub(/^\{function, /, "", body); sub(/\}\.$/, "", body)
                k = match(body, /, [0-9]+, [0-9]+$/)
                name = substr(body, 1, k - 1)
                rest = substr(body, k + 2)
                split(rest, parts, ", ")
                fns[++nf] = "{" name ", " parts[1] "}"
            }
        }
        END { print idx > (work "/.next") }
    ' "$f"
    n="$(cat "$work/.next")"
done

total="$(wc -l < "$work/index.tsv")"

# Assemble each module in its own directory; a failure leaves `erlc.out`.
assemble() {
    local dir="$1"
    local s
    s="$(cd "$dir" && ls ./*.S)"
    if ! (cd "$dir" && erlc +from_asm "$s" > erlc.out 2>&1); then
        touch "$dir/REJECTED"
    fi
}
export -f assemble
cut -f1 "$work/index.tsv" | sed "s|^|$work/|" | xargs -P "$jobs" -I{} bash -c 'assemble "$@"' _ {}

rejected=0
while IFS=$'\t' read -r idx slug mod; do
    if [ -e "$work/$idx/REJECTED" ]; then
        rejected=$((rejected + 1))
        echo "REJECTED $slug $mod"
        grep -v -E '^\s*$|Warning:' "$work/$idx/erlc.out" | sed 's/^/    /' || true
    fi
done < "$work/index.tsv"

ok=$((total - rejected))
echo "beam_export_audit: $ok/$total modules assembled"
[ "$rejected" -eq 0 ]
