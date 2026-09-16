#!/usr/bin/env bash
# install-hooks.sh — install botopink-lang's pre-commit hook.
#
# Writes `<git hooks dir>/pre-commit`, a two-line shim that runs the tracked
# `scripts/git-hooks/pre-commit` of whichever checkout is committing. The hooks
# directory is shared by every worktree of the repository, so the shim resolves
# the tracked hook through `git rev-parse --show-toplevel` at commit time rather
# than pointing at one checkout; a worktree whose tree has no tracked hook commits
# unchecked, with a warning.
#
# Usage: scripts/install-hooks.sh [--force]
#   --force   replace an existing pre-commit hook that is not this shim
set -euo pipefail

force=0
[ "${1:-}" = "--force" ] && force=1

hooks_dir="$(git rev-parse --path-format=absolute --git-common-dir)/hooks"
target="$hooks_dir/pre-commit"
marker="# botopink-lang pre-commit shim"

if [ -e "$target" ] && ! grep -qF "$marker" "$target" 2>/dev/null && [ "$force" -eq 0 ]; then
    echo "install-hooks: $target exists and is not the botopink-lang shim" >&2
    echo "               → re-run with --force to replace it" >&2
    exit 1
fi

mkdir -p "$hooks_dir"
cat >"$target" <<'HOOK'
#!/usr/bin/env bash
# botopink-lang pre-commit shim — installed by scripts/install-hooks.sh.
hook="$(git rev-parse --show-toplevel)/scripts/git-hooks/pre-commit"
if [ -x "$hook" ] || [ -f "$hook" ]; then exec bash "$hook" "$@"; fi
echo "pre-commit: $hook not found in this checkout — commit not gated" >&2
HOOK
chmod +x "$target"
echo "install-hooks: wrote $target"
