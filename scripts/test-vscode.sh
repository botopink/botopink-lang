#!/usr/bin/env bash
# test-vscode.sh — run the VS Code extension's unit suite (`npm test`: a `tsc`
# typecheck, then Node's built-in test runner) for `zig build test-vscode`.
#
# The extension is a sibling repository, not part of botopink-lang. It is found
# at, in order:
#   1. $BOTOPINK_VSCODE_DIR
#   2. <ancestor>/repository/vscode-extension  (the meta workspace layout)
#   3. <ancestor>/vscode-extension             (a flat sibling checkout)
# walking up from this repository's root. Not finding it is a failure, never a
# silent pass. The first run does `npm ci`; later runs reuse node_modules/.
#
# Exit codes: 0 the suite passed · 1 extension or npm not found, or the suite
# failed.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ext_dir="${BOTOPINK_VSCODE_DIR:-}"
if [ -z "$ext_dir" ]; then
    d="$root"
    while [ "$d" != "/" ]; do
        for cand in "$d/repository/vscode-extension" "$d/vscode-extension"; do
            if [ -f "$cand/package.json" ]; then ext_dir="$cand"; break 2; fi
        done
        d="$(dirname "$d")"
    done
fi

if [ -z "$ext_dir" ] || [ ! -f "$ext_dir/package.json" ]; then
    echo "test-vscode: vscode-extension checkout not found" >&2
    echo "            → set BOTOPINK_VSCODE_DIR, or check it out as repository/vscode-extension" >&2
    exit 1
fi
if ! command -v npm >/dev/null 2>&1; then
    echo "test-vscode: npm not on PATH" >&2
    exit 1
fi

cd "$ext_dir"
echo "==> vscode-extension at $ext_dir"
if [ ! -d node_modules ]; then
    echo "==> npm ci"
    npm ci --no-audit --no-fund
fi
exec npm test
