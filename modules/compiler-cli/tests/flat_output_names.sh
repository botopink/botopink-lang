#!/usr/bin/env bash
# Decision 1015 — every target's output is one flat folder, each module once,
# named `<pkg>@<path>` (decision 109's module atom). A throwaway `app` (modules
# `main`, `util`, `models/user`) over a dependency `lib` (modules `root`,
# `util` — named like the app's) is built on commonJS (with `--typescript`),
# erlang and beam. Checked: the exact list of module files of each target's
# folder (no subfolder, `app@models@user.js`, `lib@util.js` beside
# `app@util.js`, each `.d.ts` beside its `.js`); a commonJS module requiring
# another by its flat name (`require("./lib@util")`), its `.d.ts` importing
# `"./lib@root"`; the entry keeping decision 870's `require.main === module`;
# and the program answering alike on the three targets.
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
WORK="$(mktemp -d "${tmp_root%/}/botopink-flat-output.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }

mkdir -p "$WORK/app/src/models" "$WORK/lib/src"
printf '%s\n' '{ "name": "app", "src": "src/", "dependencies": { "lib": { "path": "../lib" } } }' > "$WORK/app/botopink.json"
cat > "$WORK/app/src/main.bp" <<'EOF'
pub mod util;
pub mod models;

import {util.shout};
import {models.user.User};
import {greet} from "lib";
import {io.terminal.print} from "std";

pub fn main() -> void {
    print(shout("app"));
    print(greet(User(name: "bia").name));
}
EOF
cat > "$WORK/app/src/util.bp" <<'EOF'
pub fn shout(s: string) -> string {
    return s + "!";
}
EOF
cat > "$WORK/app/src/models/mod.bp" <<'EOF'
pub mod user;
EOF
cat > "$WORK/app/src/models/user.bp" <<'EOF'
pub type User(name: string)
EOF
printf '%s\n' '{ "name": "lib", "version": "0.0.1", "src": "src/", "entry": "root.bp", "files": ["root.bp", "util.bp"] }' > "$WORK/lib/botopink.json"
cat > "$WORK/lib/src/root.bp" <<'EOF'
pub mod util;

import {util.wrap};

pub fn greet(name: string) -> string {
    return wrap(name);
}
EOF
cat > "$WORK/lib/src/util.bp" <<'EOF'
pub fn wrap(s: string) -> string {
    return "<" + s + ">";
}
EOF

# The module files of a target's folder, std's left out: `<dir>` relative to
# `out/<target>`, one name per line, sorted.
listing() { # <target> <subdir> <ext…>
  local target="$1" sub="$2"; shift 2
  local dir="$WORK/app/out/$target${sub:+/$sub}"
  local pattern=""
  for e in "$@"; do pattern+="${pattern:+|}\\$e\$"; done
  ( cd "$dir" && find . -type f | sed 's|^\./||' | grep -E "$pattern" | grep -v '^std@' | sort )
}

want_answer=$'app!\n<bia>'
for target in commonJS erlang beam; do
  flags=()
  [[ "$target" == commonJS ]] && flags=(--typescript)
  if ! (cd "$WORK/app" && "$BP_BIN" build --target "$target" --out "out/$target" "${flags[@]}" >/dev/null 2>"$WORK/build-$target.log"); then
    fail "$target: build failed"; sed 's/^/      /' "$WORK/build-$target.log" >&2; continue
  fi
  case "$target" in
    commonJS)
      want=$'app@main.d.ts\napp@main.js\napp@models.d.ts\napp@models.js\napp@models@user.d.ts\napp@models@user.js\napp@util.d.ts\napp@util.js\nlib@root.d.ts\nlib@root.js\nlib@util.d.ts\nlib@util.js'
      got="$(listing commonJS "" .js .d.ts)"
      # No subfolder at all: every file of the folder sits at its root.
      nested="$(cd "$WORK/app/out/commonJS" && find . -mindepth 2 -type f | head -3)"
      [[ -z "$nested" ]] || fail "commonJS: files under a subfolder: $nested"
      ;;
    erlang)
      want=$'app@main.erl\napp@models.erl\napp@models@user.erl\napp@util.erl\nlib@root.erl\nlib@util.erl'
      got="$(listing erlang erl .erl | grep -v '@@')"
      ;;
    beam)
      want=$'app@main.S\napp@models.S\napp@models@user.S\napp@util.S\nlib@root.S\nlib@util.S'
      got="$(listing beam beam .S | grep -v '@@')"
      ;;
  esac
  if [[ "$got" != "$want" ]]; then
    fail "$target: the folder's module files differ"
    diff <(printf '%s\n' "$want") <(printf '%s\n' "$got") | sed 's/^/      /' >&2 || true
  fi
  answer="$(cd "$WORK/app" && "$BP_BIN" run --target "$target" 2>/dev/null | grep -v '^\s*$' | grep -v 'Compil' || true)"
  [[ "$answer" == "$want_answer" ]] || fail "$target: the program answered '$answer', not '$want_answer'"
done

js="$WORK/app/out/commonJS"
if [[ -f "$js/lib@root.js" ]]; then
  grep -q 'require("./lib@util")' "$js/lib@root.js" || fail 'lib@root.js does not require its sibling "./lib@util"'
  grep -q 'require("./lib@root")' "$js/app@main.js" || fail 'app@main.js does not require "./lib@root"'
  grep -q 'require("./app@util")' "$js/app@main.js" || fail 'app@main.js does not require "./app@util"'
  grep -q 'require.main === module' "$js/app@main.js" || fail 'the entry lost `require.main === module` (decision 870)'
  ! grep -q 'require("\.\./' "$js/lib@root.js" "$js/app@main.js" || fail 'a require still climbs a folder ("../")'
  grep -q 'from "./lib@util"' "$js/lib@root.d.ts" || fail 'lib@root.d.ts does not import "./lib@util"'
fi

if [[ "$failures" -gt 0 ]]; then
  echo "flat_output_names.sh: $failures failure(s)" >&2
  exit 1
fi
echo "flat_output_names.sh: ok"
