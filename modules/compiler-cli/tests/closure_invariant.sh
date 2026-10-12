#!/usr/bin/env bash
# The closure invariant of decision 509 (2): a package's analysis and generated
# code depend on its dependency closure alone, never on its consumer. Level B of
# the code cache (144 B-60) stores a dependency's interface and code under its
# closure key, so it may only be built once this holds.
#
# The fixture (`closure_invariant/`): the library `shelf` (std only) and two
# consumers of it —
#   • `plain`   — one function of `shelf`, nothing else in its program;
#   • `crowded` — every kind of use of `shelf` (a generic at two types, its
#                 template, its decorator, its enum's variants, a method), plus
#                 a second dependency `rival`, its own module `local` and
#                 `std/collections`, all declaring `shelf`'s names again with
#                 other fields.
# `shelf`'s closure is the same in both builds, so on every target
# (commonJS — `.js` and the `.d.ts` interface —, erlang, beam, wasm) every file
# `shelf` emits is the same set of files with the same bytes. Each file that
# differs is printed with its diff; the script fails when any does.
#
# Exit 0 = the invariant held on every target.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

if [[ -z "${BOTOPINK_SKIP_BUILD:-}" ]]; then
  echo "==> building botopink CLI"
  ( cd "$REPO_ROOT" && zig build )
fi
BP_BIN="${BOTOPINK_BIN:-$REPO_ROOT/zig-out/bin/botopink}"
if [[ ! -x "$BP_BIN" ]]; then
  echo "error: CLI binary not found at $BP_BIN" >&2
  exit 1
fi

tmp_root="${TMPDIR:-/tmp}"
WORK="$(mktemp -d "${tmp_root%/}/botopink-closure-invariant.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
cp -R "$SCRIPT_DIR/closure_invariant/." "$WORK/"

# The library's files of one build: commonJS and wasm write a package's modules
# under `<package>/`, erlang and beam name each module `<package>@<path>`.
shelf_files() { # <consumer> <target>
  ( cd "$WORK/$1/out-$2" && find . -type f \( -path './shelf/*' -o -name 'shelf@*' \) | sed 's|^\./||' | LC_ALL=C sort )
}

failures=0
for target in commonJS erlang beam wasm; do
  for consumer in plain crowded; do
    flags=()
    [[ "$target" == commonJS ]] && flags=(--typescript)
    if ! ( cd "$WORK/$consumer" && "$BP_BIN" build --target "$target" --out "out-$target" "${flags[@]}" ) > "$WORK/$consumer-$target.log" 2>&1; then
      echo "  ✗ $target: \`botopink build\` of $consumer failed" >&2
      sed 's/^/      /' "$WORK/$consumer-$target.log" >&2
      failures=$((failures + 1))
      continue 2
    fi
  done
  shelf_files plain "$target" > "$WORK/plain-$target.list"
  shelf_files crowded "$target" > "$WORK/crowded-$target.list"
  if [[ ! -s "$WORK/plain-$target.list" ]]; then
    echo "  ✗ $target: \`shelf\` emitted no file under plain" >&2
    failures=$((failures + 1))
    continue
  fi
  bad=0
  while read -r f; do
    echo "  ✗ $target: $f is emitted under plain only" >&2; bad=$((bad + 1))
  done < <(comm -23 "$WORK/plain-$target.list" "$WORK/crowded-$target.list")
  while read -r f; do
    echo "  ✗ $target: $f is emitted under crowded only" >&2; bad=$((bad + 1))
  done < <(comm -13 "$WORK/plain-$target.list" "$WORK/crowded-$target.list")
  while read -r f; do
    if ! cmp -s "$WORK/plain/out-$target/$f" "$WORK/crowded/out-$target/$f"; then
      echo "  ✗ $target: $f differs between plain and crowded" >&2
      diff "$WORK/plain/out-$target/$f" "$WORK/crowded/out-$target/$f" | head -20 | sed 's/^/      /' >&2 || true
      bad=$((bad + 1))
    fi
  done < <(comm -12 "$WORK/plain-$target.list" "$WORK/crowded-$target.list")
  if [[ "$bad" -eq 0 ]]; then
    echo "  ✓ $target: shelf's $(wc -l < "$WORK/plain-$target.list" | tr -d ' ') file(s) identical under both consumers"
  fi
  failures=$((failures + bad))
done

if [[ "$failures" -ne 0 ]]; then
  echo "closure invariant: $failures difference(s) — shelf's code depends on its consumer" >&2
  exit 1
fi
echo "closure invariant: shelf's code and interface are its closure's alone on every target"
