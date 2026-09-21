#!/usr/bin/env bash
# check-test-scratch.sh — a test may not spell a cwd-anchored scratch path.
#
# Usage:
#   scripts/check-test-scratch.sh [<dir>…]      # default: modules
#
# `zig build test` runs each test binary with its package directory as cwd, so
# every test in the tree writes into ONE shared checkout. A path that is fixed
# — scoped per test name but not per run — is therefore shared with every other
# process running the suite: a second `zig build test` over the same checkout
# empties the first one's fixtures on its way into the same test, and reds a
# run nobody owns. Measured on the untouched tree: one `modules/compiler-cli`
# test binary is 89/89 green; four concurrent copies red 1–5 tests each.
#
# The one way a test may name a path it writes to is the `test_scratch` module
# (`modules/test-scratch/src/root.zig`), whose root carries a per-process
# segment. This gate is the other half: a string literal that begins
# `.botopinkbuild` inside a `test` block is refused here, so the fixed path
# cannot come back silently.
#
# Decision 67: it refuses, it does not warn, and no flag or environment
# variable turns it off. The only exemption is structural — a literal that does
# not start at the cwd (`"/.botopinkbuild/…"` as fixture *content* under a
# scratch root, or a reference to a production constant such as
# `runtime.TMP_ROOT`) is not a cwd-anchored path and is not matched.
set -euo pipefail

cd "$(dirname "$0")/.."

roots=("$@")
if [ ${#roots[@]} -eq 0 ]; then roots=(modules); fi

found=0
while IFS= read -r -d '' file; do
  hits=$(awk '
    /^test "/ || /^test \{/ { in_test = 1 }
    in_test && /^\}/        { in_test = 0 }
    in_test && /"\.botopinkbuild/ { printf "%d: %s\n", NR, $0 }
  ' "$file")
  if [ -n "$hits" ]; then
    found=1
    while IFS= read -r line; do
      printf '%s:%s\n' "$file" "$line"
    done <<< "$hits"
  fi
done < <(find "${roots[@]}" -name '*.zig' -not -path '*/.zig-cache/*' -print0 | sort -z)

if [ "$found" -ne 0 ]; then
  cat >&2 <<'MSG'

error: a test names a cwd-anchored `.botopinkbuild` path.

`zig build test` gives every test binary a shared checkout as its cwd, so a
fixed path is shared with every other process running the suite — the second
one deletes the first one's fixtures mid-test.

Use the `test_scratch` module instead; its root carries a per-process segment:

    const test_scratch = @import("test_scratch");

    test "…" {
        const io = std.testing.io;
        test_scratch.remove(io, "my-case");
        defer test_scratch.remove(io, "my-case");
        try writeFileP(io, test_scratch.path(io, "my-case/ws/botopink.json"), "{}");
    }

See modules/test-scratch/src/root.zig.
MSG
  exit 1
fi
