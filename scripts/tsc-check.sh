#!/usr/bin/env bash
# tsc-check.sh — every `.d.ts` the commonJS backend emits is a declaration file
# `tsc` accepts, and every `.js` it emits is a module `node --check` parses
# (1.0.11-beta 01-compiler/04-js step 3 and its gate, C-18 of 1.0.10-beta).
#
# A scratch `botopink build --target commonJS --typescript` of the library
# the compiler ships (`libs/std/` — decision 326: std alone; its `.d.ts` is
# what a host TypeScript consumer of a botopink build reads), of the project
# erika's consumer cell `generic_loader_binding` (the sibling checkout's
# `conformance/modules/`, the three ways `from "erika"` reaches a library), of every
# conformance cell
# (`conformance/modules/<cell>/`, decision 475: each a project with its own
# manifest) and of every project suite under `conformance/test/`, then
# `tsc --noEmit --strict --lib es2022 --module commonjs` over each build's
# non-empty `.d.ts` files, one `tsc` per project (two projects' modules would
# otherwise share one program), and `node --check` over each build's `.js` files.
# A typedef `tsc` refuses is a defect of `compiler-core/src/codegen/typescript.zig`,
# a module `node` cannot parse one of `commonJS.zig` (or of the host template a
# library wrote); each is fixed there. The run cells execute their module under
# node; this check reaches the modules nothing runs — the libraries' and the
# erika cell's — and reads them all the way through.
#
# What the walk leaves out is structural, the same reading `botopink cell check`
# makes of a cell: a cell whose commonJS answer refuses a module (a `refused`
# record in `snapshot/targets/commonJS/`, or in `snapshot/output/` where
# commonJS has no departure of its own), and a project (a library included)
# whose `botopink.json` `"targets"` list does not name commonJS. A project that should build and does not is red, as is one whose
# build emits no `.d.ts` or no `.js` at all. There is no skip list (decision 67).
#
# `tsc` comes from `npx -p typescript@<TS_VERSION>` — pinned, so the verdict is
# a function of the tree; `npx` ships with `node`. No `npx` is a refusal, never a
# silent skip.
#
# Usage: scripts/tsc-check.sh             (from anywhere in the checkout; needs `zig build`)
#        scripts/tsc-check.sh <dir>…      (check those projects only)
#        scripts/tsc-check.sh --jobs <n> […]   (`node --check` processes at once;
#                                         default one per CPU — the gate passes its share, gate.sh § job budget)
set -euo pipefail

TS_VERSION=7.0.2

jobs=""
if [ "${1:-}" = "--jobs" ]; then
    jobs="${2:-}"
    case "$jobs" in ''|*[!0-9]*|0) echo "tsc-check: --jobs must be a positive count (got '$jobs')" >&2; exit 2 ;; esac
    shift 2
fi

root="$(git rev-parse --show-toplevel)"
cd "$root"

bin="$root/zig-out/bin/botopink"
[ -x "$bin" ] || bin="$bin.exe"
[ -x "$bin" ] || { echo "tsc-check: $bin is not built (run: zig build)" >&2; exit 1; }
command -v node >/dev/null 2>&1 || { echo "tsc-check: node is not on PATH (https://nodejs.org/en/download)" >&2; exit 1; }
command -v npx >/dev/null 2>&1 || { echo "tsc-check: npx is not on PATH (it ships with node: https://nodejs.org/en/download)" >&2; exit 1; }

tsc="$(npx -y -p "typescript@$TS_VERSION" -c 'command -v tsc' 2>/dev/null)" || true
[ -n "$tsc" ] && [ -x "$tsc" ] || { echo "tsc-check: npx could not provide typescript@$TS_VERSION" >&2; exit 1; }

scratch="$(mktemp -d "${TMPDIR:-/tmp}/bp-tsc-check.XXXXXX")"
trap 'rm -rf "$scratch"' EXIT

# Does the cell's manifest narrow it away from commonJS?
excludes_commonjs() { # <manifest>
    local targets
    targets="$(tr -d '\n' <"$1" | grep -o '"targets"[[:space:]]*:[[:space:]]*\[[^]]*\]' || true)"
    [ -n "$targets" ] && ! printf '%s' "$targets" | grep -q '"commonJS"'
}

# Does the cell refuse a module on commonJS? Its departure says so, or the
# answer every target gives does and commonJS does not depart from it.
refused_on_commonjs() { # <cell dir>
    local snap rel
    [ -d "$1/snapshot" ] || return 1
    if [ -d "$1/snapshot/targets/commonJS" ] && grep -rqs '^refused ' "$1/snapshot/targets/commonJS"; then return 0; fi
    [ -d "$1/snapshot/output" ] || return 1
    while IFS= read -r snap; do
        rel="${snap#"$1/snapshot/output/"}"
        [ -f "$1/snapshot/targets/commonJS/$rel" ] && continue
        grep -qs '^refused ' "$snap" && return 0
    done < <(find "$1/snapshot/output" -name '*.snap')
    return 1
}

# erika's consumer cell: a sibling checkout — `../erika` beside this repository in the
# meta checkout, `repository/erika` inside it on CI. Neither is an error, never a skip.
erika_cell=""
for d in ../erika repository/erika; do
    [ -d "$d/conformance/modules/generic_loader_binding" ] && { erika_cell="$d/conformance/modules/generic_loader_binding"; break; }
done
projects=()
if [ "$#" -gt 0 ]; then
    projects=("$@")
else
    [ -n "$erika_cell" ] || { echo "tsc-check: erika's generic_loader_binding cell not found under ../erika or repository/erika" >&2; exit 1; }
    for p in libs/std/ "$erika_cell/" conformance/modules/*/ conformance/test/*/; do
        p="${p%/}"
        [ -f "$p/botopink.json" ] || continue
        refused_on_commonjs "$p" && continue
        excludes_commonjs "$p/botopink.json" && continue
        projects+=("$p")
    done
fi

# `node --check` on each file, in parallel; prints every file it refuses.
node_check() { # <out dir> <file>…
    local dir="$1"
    shift
    (cd "$dir" && printf '%s\0' "$@" | xargs -0 -P "$jobs" -n 8 sh -c '
        for f in "$@"; do node --check "$f" 2>&1 || echo "node --check refused $f"; done
    ' sh)
}

[ -n "$jobs" ] || jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)"
status=0
checked=0
modules=0
for p in "${projects[@]}"; do
    out="$scratch/$(printf '%s' "$p" | tr '/' '_')"
    if ! log="$(cd "$p" && "$bin" build --target commonJS --typescript --out "$out" 2>&1)"; then
        printf '%s\n' "$log" | tail -5 >&2
        printf '  ✗ %s (does not build on commonJS)\n' "$p" >&2
        status=1
        continue
    fi
    files=()
    while IFS= read -r f; do files+=("$f"); done < <(cd "$out" && find . -name '*.d.ts' -size +0 | sort)
    if [ "${#files[@]}" -eq 0 ]; then
        printf '  ✗ %s (the build emitted no .d.ts)\n' "$p" >&2
        status=1
        continue
    fi
    js=()
    while IFS= read -r f; do js+=("$f"); done < <(cd "$out" && find . -name '*.js' | sort)
    if [ "${#js[@]}" -eq 0 ]; then
        printf '  ✗ %s (the build emitted no .js)\n' "$p" >&2
        status=1
        continue
    fi
    ok=1
    if ! res="$(cd "$out" && "$tsc" --noEmit --strict --lib es2022 --module commonjs "${files[@]}" 2>&1)"; then
        printf '%s\n' "$res" | sed "s|^|  $p: |" >&2
        ok=0
    fi
    res="$(node_check "$out" "${js[@]}")"
    if [ -n "$res" ]; then
        printf '%s\n' "$res" | sed "s|^|  $p: |" >&2
        ok=0
    fi
    if [ "$ok" -eq 1 ]; then
        checked=$((checked + 1))
        modules=$((modules + ${#js[@]}))
    else
        printf '  ✗ %s\n' "$p" >&2
        status=1
    fi
done

[ "$status" -eq 0 ] && printf '  ✓ %d projects, every .d.ts accepted by tsc %s, %d modules parsed by node --check\n' "$checked" "$TS_VERSION" "$modules"
exit "$status"
