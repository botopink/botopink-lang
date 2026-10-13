#!/usr/bin/env bash
# check-packaging.sh — the packaging rule, checked across the library repositories
# (front 98 step 2; 144 B-27). Every library is a workspace with a core, a `-test`
# member exposing `assert<Subject>(loc, …)` helpers and examples as members; four
# checks, each failing path named, exit 1 when any fails:
#
#   1. every example member (`examples/<name>/botopink.json`) carries a
#      `README.md` beside its manifest;
#   2. every `-test` member (`modules/<name>-test/`) declares at least one
#      `pub fn assert<Subject>(loc: SourceLocation, …)` under its `src/`;
#   3. no example manifest names an ecosystem library by `"git"` (an example
#      reaches its library by `{ "workspace": true }`);
#   4. `botopink-lib-test --list` lists every member of every library.
#
# The libraries are this checkout's siblings — `../<name>` in the meta checkout,
# `repository/<name>` inside it on CI — every directory there holding a workspace
# `botopink.json`. Calling it from `gate.sh` is the gate's call, not this script's.
#
# Usage: scripts/check-packaging.sh [<library root>]   (needs `zig build` for check 4)
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
cd "$root"

libs_root="${1:-}"
if [ -z "$libs_root" ]; then
    for d in .. repository; do
        if [ -d "$d" ] && ls "$d"/*/botopink.json >/dev/null 2>&1; then libs_root="$d"; break; fi
    done
fi
[ -n "$libs_root" ] || { echo "check-packaging: no library root (../ or repository/) holds a library" >&2; exit 1; }

ecosystem="rakun|jhonstart|emilia|onze|erika"
fail=0
red() { printf '  ✗ %s\n' "$1" >&2; fail=1; }

libraries=()
for m in "$libs_root"/*/botopink.json; do
    lib="$(dirname "$m")"
    grep -q '"workspaces"' "$m" || continue
    libraries+=("$lib")
done
[ "${#libraries[@]}" -gt 0 ] || { echo "check-packaging: no workspace library under $libs_root" >&2; exit 1; }

# 1 · every example member carries a README.md.
for lib in "${libraries[@]}"; do
    for ex in "$lib"/examples/*/botopink.json; do
        [ -e "$ex" ] || continue
        dir="$(dirname "$ex")"
        [ -f "$dir/README.md" ] || red "$dir: an example member without README.md"
    done
done

# 2 · every -test member exposes an assert<Subject>(loc: SourceLocation, …) helper.
for lib in "${libraries[@]}"; do
    for member in "$lib"/modules/*-test; do
        [ -f "$member/botopink.json" ] || continue
        if ! grep -rqE 'pub fn assert[A-Z][A-Za-z0-9]*(<[^>]*>)?\(loc: SourceLocation' "$member/src" 2>/dev/null; then
            red "$member: a -test member with no pub fn assert<Subject>(loc: SourceLocation, …)"
        fi
    done
done

# 3 · no example manifest names an ecosystem library by "git".
for lib in "${libraries[@]}"; do
    for ex in "$lib"/examples/*/botopink.json; do
        [ -e "$ex" ] || continue
        if grep -qE "\"($ecosystem)[a-z-]*\"[[:space:]]*:[[:space:]]*\{[^}]*\"git\"" "$ex"; then
            red "$ex: an example reaching an ecosystem library by \"git\""
        fi
    done
done

# 4 · the lib-test runner lists every member.
runner="zig-out/bin/botopink-lib-test"
[ -x "$runner" ] || runner="$runner.exe"
if [ ! -x "$runner" ]; then
    red "$runner is not built (run: zig build) — the member list cannot be read"
else
    listed="$("$runner" --list 2>&1)" || { printf '%s\n' "$listed" >&2; red "$runner --list failed"; listed=""; }
    for lib in "${libraries[@]}"; do
        for glob in modules examples; do
            for mm in "$lib"/$glob/*/botopink.json; do
                [ -e "$mm" ] || continue
                name="$(sed -n 's/^[[:space:]]*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$mm" | head -n 1)"
                [ -n "$name" ] || { red "$mm: a member without a name"; continue; }
                printf '%s\n' "$listed" | grep -qw -- "$name" || red "$(dirname "$mm"): member \"$name\" is not listed by botopink-lib-test --list"
            done
        done
    done
fi

if [ "$fail" -eq 0 ]; then
    printf '  ✓ packaging: %d libraries\n' "${#libraries[@]}"
fi
exit "$fail"
