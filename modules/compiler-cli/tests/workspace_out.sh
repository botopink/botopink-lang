#!/usr/bin/env bash
# Decision 1015 (4) — a workspace root's one output folder per target (a CLI
# behaviour, proven by the CLI's own script, decision 1020 (7)):
#   • `build --target <t>` at the root builds every member, each in its own
#     process, into the root's `out/` — each member's own modules and each
#     dependency once, no member's own `out/`; `run --target <t>` at the root
#     answers every member's program over that folder;
#   • a dependency is written once per its key: a member handed
#     `--workspace-out` writes the dependency's files (staged, renamed) and its
#     key file `.<pkg>.key`; the second member over the same dependency writes
#     none of them (their inodes, pinned by a link of their own, kept), nor does
#     the root's next build; a key file that does not match is written again,
#     and so is everything under `build --cold`;
#   • two packages of one name at two directories (two members' dependencies)
#     are refused before anything is built, naming both directories; so are
#     two members of one package name (decision 1013 (2)), naming both.
# erlang and beam (their files are `<pkg>@<path>` already); commonJS's flat
# names are codegen's (1015 (1)).
#   • the folder is named by the target, literally (decision 1023): the root's
#     `build --target <t>` lays exactly `out/<t>/` on each of the four targets.
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
WORK="$(mktemp -d "${tmp_root%/}/botopink-workspace-out.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }
ok() { echo "  ✓ $*"; }
run_in() { # <dir> <args…> — stdout+stderr to $OUT, status to $CODE
  local d="$1"; shift
  set +e
  OUT="$(cd "$d" && "$BP" "$@" 2>&1)"
  CODE=$?
  set -e
}
inode() { stat -c %i "$1"; }

# ── the fixture: a workspace of two members over one library ───────────────
WS="$WORK/ws"
mkdir -p "$WORK/lib/src" "$WS/one/src" "$WS/two/src"
printf '{ "name": "lib", "entry": "root.bp", "files": ["root.bp"] }\n' >"$WORK/lib/botopink.json"
printf 'pub fn greet(n: string) -> string {\n    return "hello " + n;\n}\n' >"$WORK/lib/src/root.bp"
cat >"$WS/botopink.json" <<'EOF'
{
  "name": "ws",
  "version": "0.0.1",
  "workspaces": ["*"],
  "dependencies": { "lib": { "path": "../lib" } }
}
EOF
for c in one two; do
  printf '{ "name": "%s" }\n' "$c" >"$WS/$c/botopink.json"
  printf 'import {io.terminal.print} from "std";\nimport {greet} from "lib";\n\npub fn main() -> void {\n    print(greet("%s"));\n}\n' "$c" >"$WS/$c/src/main.bp"
done

for target in erlang beam; do
  case "$target" in erlang) sub=erlang; ext=erl ;; beam) sub=beam; ext=S ;; esac
  DIR="$WS/out/$sub"
  LIB="$DIR/lib@root.$ext"
  rm -rf "$WS/out" "$WS/one/out" "$WS/two/out"

  echo "==> $target: a member handed --workspace-out writes the dependency once"
  run_in "$WS/one" build --target "$target" --workspace-out "$WS/out"
  [[ $CODE -eq 0 ]] || { echo "$OUT" >&2; fail "$target: member one's build (exit $CODE)"; continue; }
  [[ -f "$LIB" && -f "$DIR/one@main.$ext" ]] || fail "$target: member one wrote its module and lib's into $DIR"
  [[ -s "$DIR/.lib.key" && -s "$DIR/.std.key" ]] || fail "$target: the key files of lib and std ($DIR/.lib.key, .std.key)"
  [[ ! -e "$WS/one/out" ]] || fail "$target: member one wrote its own out/"
  # A line only this script writes: a process that wrote lib's file again
  # would drop it, whatever way it wrote.
  echo '% written once' >>"$LIB"
  ln "$LIB" "$WORK/pin-lib"
  STD="$(find "$DIR" -maxdepth 1 -name "std@*.$ext" | head -1)"
  [[ -n "$STD" ]] && ln "$STD" "$WORK/pin-std"
  run_in "$WS/two" build --target "$target" --workspace-out "$WS/out"
  [[ $CODE -eq 0 ]] || { echo "$OUT" >&2; fail "$target: member two's build (exit $CODE)"; }
  [[ -f "$DIR/two@main.$ext" ]] || fail "$target: member two wrote its own module"
  [[ "$(inode "$LIB")" == "$(inode "$WORK/pin-lib")" ]] && grep -qx '% written once' "$LIB" || fail "$target: member two wrote lib's file again"
  [[ -z "$STD" || "$(inode "$STD")" == "$(inode "$WORK/pin-std")" ]] || fail "$target: member two wrote std's file again"
  ok "$target: the second member over lib and std wrote none of their files"

  echo "==> $target: the root's build lays one folder, each module once"
  run_in "$WS" build --target "$target"
  [[ $CODE -eq 0 ]] || { echo "$OUT" >&2; fail "$target: the root's build (exit $CODE)"; }
  [[ "$(inode "$LIB")" == "$(inode "$WORK/pin-lib")" ]] && grep -qx '% written once' "$LIB" || fail "$target: the root's build wrote lib's file again"
  [[ "$(find "$WS/out" -name "lib@root.$ext" | wc -l)" -eq 1 ]] || fail "$target: lib@root.$ext once under out/"
  [[ "$(find "$DIR" -mindepth 1 -type d | wc -l)" -eq 0 ]] || fail "$target: $DIR has subfolders"
  [[ ! -e "$WS/one/out" && ! -e "$WS/two/out" ]] || fail "$target: a member wrote its own out/"
  ok "$target: one/, two/ and lib in $DIR, no member's out/"

  run_in "$WS" run --target "$target"
  [[ $CODE -eq 0 ]] || { echo "$OUT" >&2; fail "$target: the root's run (exit $CODE)"; }
  grep -qx '    hello one' <<<"$OUT" && grep -qx '    hello two' <<<"$OUT" || { echo "$OUT" >&2; fail "$target: the root's run answers both members"; }
  [[ "$(inode "$LIB")" == "$(inode "$WORK/pin-lib")" ]] || fail "$target: the root's run wrote lib's file again"
  ok "$target: the root's run answers each member over the one folder"

  echo "==> $target: a key that does not match, and --cold, write it again"
  echo stale >"$DIR/.lib.key"
  run_in "$WS" build --target "$target"
  [[ $CODE -eq 0 ]] || { echo "$OUT" >&2; fail "$target: the build over a stale key (exit $CODE)"; }
  [[ "$(inode "$LIB")" != "$(inode "$WORK/pin-lib")" ]] && ! grep -qx '% written once' "$LIB" || fail "$target: a stale key left lib's file as it was"
  grep -qvx stale "$DIR/.lib.key" || fail "$target: the key file was not written again"
  rm -f "$WORK/pin-lib"; ln "$LIB" "$WORK/pin-lib"
  run_in "$WS" build --target "$target" --cold
  [[ $CODE -eq 0 ]] || { echo "$OUT" >&2; fail "$target: build --cold (exit $CODE)"; }
  [[ "$(inode "$LIB")" != "$(inode "$WORK/pin-lib")" ]] || fail "$target: build --cold left lib's file as it was"
  ok "$target: a stale key and --cold rewrite the dependency"
  rm -f "$WORK/pin-lib" "$WORK/pin-std"
done

# ── the folder named by the target (decision 1023) ─────────────────────────
for target in commonJS erlang beam wasm; do
  echo "==> $target: the root's build lays exactly out/$target/"
  rm -rf "$WS/out" "$WS/one/out" "$WS/two/out"
  run_in "$WS" build --target "$target"
  [[ $CODE -eq 0 ]] || { echo "$OUT" >&2; fail "$target: the root's build (exit $CODE)"; continue; }
  laid="$(cd "$WS/out" && ls -A)"
  [[ "$laid" == "$target" ]] || fail "$target: out/ holds '$(tr '\n' ' ' <<<"$laid")', not exactly $target/"
  [[ ! -e "$WS/one/out" && ! -e "$WS/two/out" ]] || fail "$target: a member wrote its own out/"
  ok "$target: out/$target/ alone"
done

# ── two packages of one name at two directories ─────────────────────────────
echo "==> two members' dependencies of one name at two directories are refused"
DUP="$WORK/dup"
for l in json1 json2; do
  mkdir -p "$WORK/$l/src"
  printf '{ "name": "json", "entry": "root.bp", "files": ["root.bp"] }\n' >"$WORK/$l/botopink.json"
  printf 'pub fn tag() -> string {\n    return "%s";\n}\n' "$l" >"$WORK/$l/src/root.bp"
done
mkdir -p "$DUP/c/src" "$DUP/d/src"
printf '{ "name": "dup", "version": "0.0.1", "workspaces": ["*"] }\n' >"$DUP/botopink.json"
printf '{ "name": "c", "dependencies": { "json": { "path": "../../json1" } } }\n' >"$DUP/c/botopink.json"
printf '{ "name": "d", "dependencies": { "json": { "path": "../../json2" } } }\n' >"$DUP/d/botopink.json"
for c in c d; do
  printf 'import {io.terminal.print} from "std";\nimport {tag} from "json";\n\npub fn main() -> void {\n    print(tag());\n}\n' >"$DUP/$c/src/main.bp"
done
run_in "$DUP" build --target erlang
[[ $CODE -eq 1 ]] || fail "the root's build over two \`json\` packages exits 1 (exit $CODE)"
grep -q 'json1' <<<"$OUT" && grep -q 'json2' <<<"$OUT" || { echo "$OUT" >&2; fail "the refusal names both directories"; }
[[ ! -e "$DUP/out" && ! -e "$DUP/c/out" && ! -e "$DUP/d/out" ]] || fail "the refused build wrote an out/"
ok "refused, naming json1 and json2, nothing written"

# Each member alone builds: the refusal is the shared folder's.
run_in "$DUP/c" build --target erlang
[[ $CODE -eq 0 ]] || { echo "$OUT" >&2; fail "member c alone builds (exit $CODE)"; }

# ── two members of one package name (decision 1013 (2)) ─────────────────────
echo "==> two members of one name are refused at the root, named"
SAME="$WORK/same"
mkdir -p "$SAME/e/src" "$SAME/f/src"
printf '{ "name": "same", "version": "0.0.1", "workspaces": ["*"] }\n' >"$SAME/botopink.json"
for c in e f; do
  printf '{ "name": "twin" }\n' >"$SAME/$c/botopink.json"
  printf 'import {io.terminal.print} from "std";\n\npub fn main() -> void {\n    print("%s");\n}\n' "$c" >"$SAME/$c/src/main.bp"
done
for target in commonJS erlang; do
  run_in "$SAME" build --target "$target"
  [[ $CODE -eq 1 ]] || fail "$target: the root's build over two members named \`twin\` exits 1 (exit $CODE)"
  grep -q '"twin"' <<<"$OUT" && grep -q 'e/botopink.json' <<<"$OUT" && grep -q 'f/botopink.json' <<<"$OUT" \
    || { echo "$OUT" >&2; fail "$target: the refusal names twin and both members"; }
  [[ ! -e "$SAME/out" && ! -e "$SAME/e/out" && ! -e "$SAME/f/out" ]] || fail "$target: the refused build wrote an out/"
done
ok "refused, naming twin and both members' manifests, nothing written"

if (( failures > 0 )); then
  echo "workspace_out.sh: $failures failure(s)" >&2
  exit 1
fi
echo "workspace_out.sh: every behaviour held"
