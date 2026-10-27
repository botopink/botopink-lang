#!/usr/bin/env bash
# Decision 993 (2) — `botopink packages --list` against the real CLI, over a
# throwaway checkout: a library (`alpha`, its own targets), a workspace `ws`
# declaring targets with two members (`ws-one` inheriting them, `ws-two`
# declaring its own), a directory with no manifest (`plain`), a library whose
# manifest is refused (`broken`), and std under
# `repository/botopink-lang/libs`. Checked: the exact output (tab-separated
# `<name> <dir> <targets> <kind>`, sorted by name then dir; `all` when no
# targets are declared; the umbrella and the manifest-less directory absent;
# `not-a-package` for the refused manifest), the help, and the usage
# errors. `packages --check-docs` (decision 993 (7), the old runner's doc_quotes): green on a workspace
# document quoting the member list as the tool prints it (wrapped, or elided), red — exit 1, `<file>:<line>` — on
# one that lost a member.
#
# BOTOPINK_BIN points the script at another binary. Exit 0 = every behaviour held.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

if [[ -z "${BOTOPINK_SKIP_BUILD:-}" && -z "${BOTOPINK_BIN:-}" ]]; then
  echo "==> building botopink CLI"
  ( cd "$REPO_ROOT" && zig build )
fi
BP_BIN="${BOTOPINK_BIN:-$REPO_ROOT/zig-out/bin/botopink}"
if [[ ! -x "$BP_BIN" ]]; then
  echo "error: CLI binary not found at $BP_BIN" >&2
  exit 1
fi

tmp_root="${TMPDIR:-/tmp}"
WORK="$(mktemp -d "${tmp_root%/}/botopink-packages-list.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }

mk() { # <dir> <json>
  mkdir -p "$WORK/$1/src"
  printf '%s\n' "$2" > "$WORK/$1/botopink.json"
  echo 'pub fn f() -> i32 { return 1; }' > "$WORK/$1/src/root.bp"
}
mk repository/alpha '{"name":"alpha","src":"src/","entry":"root.bp","files":["root.bp"],"targets":["commonJS","erlang"]}'
mk repository/ws '{"name":"ws","targets":["erlang","beam"],"workspaces":["modules/*"]}'
mk repository/ws/modules/ws-one '{"name":"ws-one","src":"src/","entry":"root.bp","files":["root.bp"]}'
mk repository/ws/modules/ws-two '{"name":"ws-two","src":"src/","entry":"root.bp","files":["root.bp"],"targets":["beam"]}'
mk repository/broken '{"name":"broken",'
mkdir -p "$WORK/repository/plain/src"
mkdir -p "$WORK/repository/botopink-lang/modules/compiler-core/src"
touch "$WORK/repository/botopink-lang/modules/compiler-core/src/root.zig"
mk repository/botopink-lang/libs/std '{"name":"std","src":"src/","entry":"root.bp","files":["root.bp"]}'

want=$'alpha\trepository/alpha\tcommonJS,erlang\tpackage
broken\trepository/broken\tall\tnot-a-package
std\trepository/botopink-lang/libs/std\tall\tpackage
ws-one\trepository/ws/modules/ws-one\terlang,beam\tpackage
ws-two\trepository/ws/modules/ws-two\tbeam\tpackage'

got="$(cd "$WORK" && env -u BOTOPINK_LIB_ROOTS "$BP_BIN" packages --list)"
if [[ "$got" != "$want" ]]; then
  fail "packages --list differs"
  diff <(printf '%s\n' "$want") <(printf '%s\n' "$got") | sed 's/^/      /' >&2 || true
fi

# From a subdirectory the checkout root is the same.
got2="$(cd "$WORK/repository/alpha" && env -u BOTOPINK_LIB_ROOTS "$BP_BIN" packages --list)"
[[ "$got2" == "$want" ]] || fail "from inside a package the list differs"

# The help names the command, and the command's own.
"$BP_BIN" --help | grep -q '^  packages ' || fail "botopink --help does not list packages"
"$BP_BIN" packages --help | grep -q 'Options for `packages`' || fail "packages --help does not describe it"

# --check-docs: a workspace document that quotes the member list.
QUOTE='run this command inside one of its members:'
printf 'the refusal `botopink.json is a workspace — %s ws-one,\nws-two`, and later `%s …`.\n' "$QUOTE" "$QUOTE" > "$WORK/repository/ws/AGENTS.md"
(cd "$WORK" && env -u BOTOPINK_LIB_ROOTS "$BP_BIN" packages --check-docs) || fail "packages --check-docs red on a document that agrees"
printf 'intro\n`%s ws-one`\n' "$QUOTE" > "$WORK/repository/ws/AGENTS.md"
if docs_err="$(cd "$WORK" && env -u BOTOPINK_LIB_ROOTS "$BP_BIN" packages --check-docs 2>&1)"; then
  fail "packages --check-docs green on a document that lost a member"
else
  case "$docs_err" in
    *"repository/ws/AGENTS.md:2: the workspace refusal is quoted with the members \`ws-one\`, but the tool prints \`ws-one, ws-two\`"*) ;;
    *) fail "packages --check-docs did not name the stale quote: $docs_err" ;;
  esac
fi

# Usage errors: no --list, an unknown flag, a stray argument.
for args in "" "--nope" "--list x" "--list --check-docs"; do
  # shellcheck disable=SC2086
  if "$BP_BIN" packages $args > /dev/null 2>&1; then fail "packages $args exited 0"; fi
done

if (( failures > 0 )); then
  echo "packages_list: $failures failure(s)" >&2
  exit 1
fi
echo "packages_list: ok"
