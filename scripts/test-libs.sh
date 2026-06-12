#!/usr/bin/env bash
# test-libs.sh — wrapper around the workspace-aware botopink-lib-test that
# pre-flights the runtime requirements and bails out with a clean error
# instead of letting `node`/`escript`/`erlc`/`wasmtime` failures surface as
# cryptic mid-test crashes.
#
# Usage:
#   scripts/test-libs.sh [-- <args forwarded to botopink-lib-test>]
#
# Same invocation the `zig build test-libs` step uses (K1 of v0.beta.19
# frente-c-distribution). Exit codes:
#   0  — pre-flight passed and the runner exited 0
#   1  — pre-flight failed (a required runtime is missing)
#   N  — whatever exit code the runner returned
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

if [ -f repository/botopink-lang/build.zig ]; then
    core_dir="repository/botopink-lang"
elif [ -f build.zig ]; then
    core_dir="."
else
    echo "test-libs: build.zig not found at repository/botopink-lang or repo root" >&2
    exit 1
fi

runner="$core_dir/zig-out/bin/botopink-lib-test"
if [ ! -x "$runner" ]; then
    echo "test-libs: runner not built yet ($runner)" >&2
    echo "         → run \`zig build install\` in $core_dir first." >&2
    exit 1
fi

# Pre-flight env. Every backend covered by the workspace lib-test runner needs
# a host runtime — the lib-test runner currently exits early but the error
# message doesn't point the user at the install command. Keep this check
# advisory (does not gate the run) so a partial environment still tests
# whatever it can; the runner's per-target skip-or-fail is the authority.
need_warn() {
    local tool="$1" backend="$2" hint="$3"
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf '\033[1;33mwarning:\033[0m %s missing — backend %s will fail.\n' "$tool" "$backend" >&2
        printf '         install hint: %s\n' "$hint" >&2
    fi
}

need_warn node "commonJS"        "https://nodejs.org/en/download (or your distro's package manager)"
need_warn escript "erlang/beam"  "apt-get install erlang (linux) · brew install erlang (macOS)"
need_warn erlc    "beam"         "apt-get install erlang (linux) · brew install erlang (macOS)"
need_warn wasmtime "wasm"        "curl https://wasmtime.dev/install.sh | bash"

exec "$runner" "$@"
