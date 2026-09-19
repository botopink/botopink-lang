#!/usr/bin/env bash
# runner-standalone.sh — botopink-lang's pre-commit gate. Delegates to
# scripts/gate.sh, the single definition of the gate (staged-file checks, zig
# build, zig build test, test-bpmp, the beam export audit, test-cli, test-libs).
set -euo pipefail

runStandaloneGate() {
    local root
    root=$(git rev-parse --show-toplevel)
    bash "$root/scripts/gate.sh" --staged
}
