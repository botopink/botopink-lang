#!/usr/bin/env bash
# Decision 1050 — import aliases do not exist (a CLI behaviour, proven by the
# CLI's own script, decision 1020): `import {readPost} from "@/lib.db"` is
# refused by `check` as any unresolved import source is, and an `"alias"` key in
# `botopink.json` is an unknown manifest key (decision 1048).
#
# BOTOPINK_BIN points the script at another binary. Exit 0 = every behaviour held.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

if [[ -z "${BOTOPINK_SKIP_BUILD:-}" && -z "${BOTOPINK_BIN:-}" ]]; then
  echo "==> building botopink CLI"
  ( cd "$REPO_ROOT" && zig build )
fi
BP="${BOTOPINK_BIN:-$REPO_ROOT/zig-out/bin/botopink}"
[[ -x "$BP" ]] || { echo "error: CLI binary not found at $BP" >&2; exit 1; }

tmp_root="${TMPDIR:-/tmp}"
WORK="$(mktemp -d "${tmp_root%/}/botopink-import-alias.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }

mkdir -p "$WORK/app/src"
printf '{ "name": "app" }\n' >"$WORK/app/botopink.json"
cat >"$WORK/app/src/main.bp" <<'BP'
import {readPost} from "@/lib.db";

pub fn main() -> void {
    readPost();
}
BP
out="$(cd "$WORK/app" && "$BP" check 2>&1)" && fail "an import from \"@/lib.db\" was accepted" || true
grep -q 'unresolved import source "@/lib.db"' <<<"$out" || fail "the alias import is not an unresolved import source: $out"

printf '{ "name": "app", "alias": { "@/lib": "lib" } }\n' >"$WORK/app/botopink.json"
out="$(cd "$WORK/app" && "$BP" check 2>&1)" && fail "a manifest with \"alias\" was accepted" || true
grep -q 'error\[manifest-unknown-field\]: botopink.json has no field "alias"' <<<"$out" || fail "\"alias\" is not an unknown manifest key: $out"

if [[ "$failures" -ne 0 ]]; then echo "FAIL: $failures" >&2; exit 1; fi
echo "ok: import aliases do not exist (decision 1050)"
