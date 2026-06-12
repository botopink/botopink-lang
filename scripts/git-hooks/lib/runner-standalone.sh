#!/usr/bin/env bash
# runner-standalone.sh — pre-commit gate for a standalone clone of botopink-lang.
# Self-contained mirror of botopink/projects'
# scripts/git-hooks/lib/runners/botopink-lang.sh.
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

fail() { echo -e "${RED}✗ $1${NC}"; exit 1; }
pass() { echo -e "${GREEN}✓ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }

runStandaloneGate() {
    local root
    root=$(git rev-parse --show-toplevel)
    cd "$root"

    # 1. conflict markers in staged files.
    local lt7 eq7 gt7
    lt7=$(printf '<%.0s' {1..7})
    eq7=$(printf '=%.0s' {1..7})
    gt7=$(printf '>%.0s' {1..7})
    local marker_re="${lt7} |${eq7}\$|${gt7} "
    local staged
    staged=$(git diff --cached --name-only --diff-filter=ACM)
    if [ -n "$staged" ]; then
        local hits=""
        while IFS= read -r f; do
            [ -z "$f" ] && continue
            [ -f "$f" ] || continue
            if grep -nE "$marker_re" "$f" 2>/dev/null | head -1 | grep -q .; then
                hits="$hits $f"
            fi
        done <<< "$staged"
        if [ -n "$hits" ]; then
            echo "  Conflict markers in:$hits"
            fail "Conflict markers found in staged files"
        fi
        pass "No conflict markers"
    fi

    # 2. zig fmt on staged .zig files.
    local zig_files
    zig_files=$(echo "$staged" | grep '\.zig$' || true)
    if [ -n "$zig_files" ]; then
        local bad_fmt=""
        for f in $zig_files; do
            if ! zig fmt --check "$f" >/dev/null 2>&1; then
                bad_fmt="$bad_fmt  $f\n"
            fi
        done
        if [ -n "$bad_fmt" ]; then
            echo -e "${RED}✗ Formatting issues:${NC}"
            echo -e "$bad_fmt"
            echo "  Run: zig fmt <file> to fix"
            exit 1
        fi
        pass "zig fmt OK ($(echo "$zig_files" | wc -w) files)"
    fi

    # 3. zig build + zig build test.
    echo -n "  Building (botopink-lang)... "
    if ! ( cd "$root" && zig build ) 2>&1; then
        fail "zig build failed"
    fi
    pass "zig build OK"
    echo -n "  Testing (zig build test)... "
    if ! ( cd "$root" && zig build test ) 2>&1; then
        fail "zig build test failed"
    fi
    pass "zig build test OK"

    # 4. libs/<name>/ botopink test loop.
    local bin="$root/zig-out/bin/botopink"
    [ -x "$bin" ] || fail "botopink binary not found at $bin"
    local lib_fail=""
    for cfg in "$root"/libs/*/botopink.json; do
        [ -e "$cfg" ] || continue
        local dir; dir=$(dirname "$cfg")
        if [ -z "$(find "$dir/src" "$dir/test" 2>/dev/null -name '*.bp' ! -name '*.d.bp' | head -1)" ]; then
            echo "  Skipping $dir (no .bp sources)"
            continue
        fi
        echo -n "  Testing $dir (.bp)... "
        if ( cd "$dir" && "$bin" test ) >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗${NC}"
            lib_fail="$lib_fail $dir"
        fi
    done
    [ -z "$lib_fail" ] || fail "botopink .bp tests failed in:$lib_fail"
}
