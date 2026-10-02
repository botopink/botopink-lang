#!/usr/bin/env bash
# tsc-check.sh — every `.d.ts` the commonJS backend emits is a declaration file
# `tsc` accepts (1.0.11-beta 01-compiler/04-js step 3, C-18 of 1.0.10-beta).
#
# A scratch `botopink build --target commonJS --typescript` of every project
# under `examples/` and of every `tests/language/modules/<cell>/`, then
# `tsc --noEmit --strict --lib es2022 --module commonjs` over each build's
# non-empty `.d.ts` files, one `tsc` per project (two projects' modules would
# otherwise share one program). A typedef `tsc` refuses is a defect of
# `compiler-core/src/codegen/typescript.zig`, fixed there.
#
# What the walk leaves out is structural, the same reading `tests/language/run.sh`
# makes of a cell: a cell whose `commonJS.expect` says the program is refused on
# commonJS, and a cell whose `botopink.json` `"targets"` list does not name
# commonJS. A project that should build and does not is red, as is one whose
# build emits no `.d.ts` at all. There is no skip list (decision 67).
#
# `tsc` comes from `npx -p typescript@<TS_VERSION>` — pinned, so the verdict is
# a function of the tree; `npx` ships with `node`. No `npx` is a refusal, never a
# silent skip.
#
# Usage: scripts/tsc-check.sh             (from anywhere in the checkout; needs `zig build`)
#        scripts/tsc-check.sh <dir>…      (check those projects only)
set -euo pipefail

TS_VERSION=7.0.2

root="$(git rev-parse --show-toplevel)"
cd "$root"

bin="$root/zig-out/bin/botopink"
[ -x "$bin" ] || bin="$bin.exe"
[ -x "$bin" ] || { echo "tsc-check: $bin is not built (run: zig build)" >&2; exit 1; }
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

projects=()
if [ "$#" -gt 0 ]; then
    projects=("$@")
else
    for p in examples/*/ tests/language/modules/*/; do
        p="${p%/}"
        [ -f "$p/botopink.json" ] || continue
        [ -f "$p/commonJS.expect" ] && continue
        excludes_commonjs "$p/botopink.json" && continue
        projects+=("$p")
    done
fi

status=0
checked=0
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
    if res="$(cd "$out" && "$tsc" --noEmit --strict --lib es2022 --module commonjs "${files[@]}" 2>&1)"; then
        checked=$((checked + 1))
    else
        printf '%s\n' "$res" | sed "s|^|  $p: |" >&2
        printf '  ✗ %s\n' "$p" >&2
        status=1
    fi
done

[ "$status" -eq 0 ] && printf '  ✓ %d projects, every .d.ts accepted by tsc %s\n' "$checked" "$TS_VERSION"
exit "$status"
