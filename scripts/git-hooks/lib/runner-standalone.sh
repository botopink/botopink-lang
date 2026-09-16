#!/usr/bin/env bash
# runner-standalone.sh — pre-commit gate for a checkout of botopink-lang that is
# not driven by a superproject runner. Delegates to scripts/gate.sh, the single
# definition of the gate (staged-file checks, zig build, zig build test,
# zig build test-cli, zig build test-libs).
set -euo pipefail

runStandaloneGate() {
    local root
    root=$(git rev-parse --show-toplevel)
    bash "$root/scripts/gate.sh" --staged
}
