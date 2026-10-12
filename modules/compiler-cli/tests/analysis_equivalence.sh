#!/usr/bin/env bash
# `test-analysis-equivalence` over real libraries (144 B-60, guard 2): the code
# cache's level B must answer what analysing answers. For a few conformance
# cells of jhonstart, rakun and emilia — each a consumer of its library —
# every cell is built three times on every target its suite declares
# (`conformance/modules/botopink.json`'s `targets`):
#   • `--cold`  — reads nothing;
#   • warm      — the first cell of a target writes the library's entry into
#                 an emptied `.botopinkbuild/analysis/<target>/`, the cells
#                 after it read the entry the first one wrote (one library,
#                 one entry, whichever consumer wrote it);
#   • warm again — reads every entry;
# and the three outputs are compared file by file, byte for byte. The library's
# entry must exist (`<target>/<library>.bpa`), or the run proved nothing.
# `level_b.sh` is the same check over the closure invariant's fixture, with
# the wasm targets; a field the format drops changing the output is the
# in-process test of `cli/analysis_equivalence.zig`.
#
# The libraries are the checkout's siblings: the first ancestor `D` of this
# repository holding `D/repository/<library>` (the meta checkout, a task
# worktree's linked siblings, or CI's `repository/` beside botopink-lang). A
# library that is not there fails the script. Each one is copied — its root
# manifest, `modules/` and the chosen cells — into a scratch directory whose
# `repository/` links the other siblings, so its dependencies resolve as in
# the checkout and nothing is written outside the scratch directory.
#
# BOTOPINK_BIN points the script at another binary. Exit 0 = every output the
# same bytes.

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

# library:cell,cell,… — a few cells each, enough to read one entry under
# several consumers.
LIBRARIES=(
  "jhonstart:counter_ssr,link_props"
  "rakun:scopes,provides"
  "emilia:alpha,bg-color"
)

# The siblings' directory: the first ancestor holding `repository/<lib>`.
siblings_of() { # <library>
  local d="$REPO_ROOT"
  while :; do
    if [[ -d "$d/repository/$1/modules" ]]; then echo "$d/repository"; return 0; fi
    [[ "$d" == / ]] && return 1
    d="$(dirname "$d")"
  done
}

tmp_root="${TMPDIR:-/tmp}"
WORK="$(mktemp -d "${tmp_root%/}/botopink-analysis-equivalence.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }

# A copy without build products: no `.botopinkbuild/`, no `out/`, no `.git`.
copy_tree() { # <from> <to>
  mkdir -p "$2"
  tar -C "$1" --exclude=.botopinkbuild --exclude=./out --exclude='*/out' --exclude=.git -cf - . | tar -C "$2" -xf -
}

build() { # <cell dir> <target> <out> [flags…]
  local cell="$1" target="$2" out="$3"; shift 3
  if ! ( cd "$cell" && "$BP_BIN" build --target "$target" --out "$out" "$@" ) > "$WORK/build.log" 2>&1; then
    fail "\`botopink build --target $target $*\` of $(basename "$cell") failed"
    sed 's/^/      /' "$WORK/build.log" >&2
    return 1
  fi
}

for spec in "${LIBRARIES[@]}"; do
  lib="${spec%%:*}"
  IFS=',' read -r -a cells <<< "${spec#*:}"
  if ! from="$(siblings_of "$lib")"; then
    fail "$lib: no repository/$lib above $REPO_ROOT — the libraries are botopink-lang's siblings"
    continue
  fi

  # The scratch checkout: `repository/<lib>` copied, every other sibling linked.
  S="$WORK/$lib"
  mkdir -p "$S/repository"
  for sib in "$from"/*/; do
    name="$(basename "$sib")"
    [[ "$name" == "$lib" || "$name" == botopink-lang ]] && continue
    ln -s "$(cd "$sib" && pwd)" "$S/repository/$name"
  done
  L="$S/repository/$lib"
  mkdir -p "$L/conformance/modules"
  cp "$from/$lib/botopink.json" "$L/"
  # The root manifest's other workspace folders (`examples/*`, `starters/*`)
  # exist, empty: a workspace entry that cannot be read is a located error.
  python3 -c 'import json,os,sys
for w in json.load(open(sys.argv[1])).get("workspaces", []):
    os.makedirs(os.path.join(sys.argv[2], w.split("*")[0]), exist_ok=True)' "$L/botopink.json" "$L"
  copy_tree "$from/$lib/modules" "$L/modules"
  cp "$from/$lib/conformance/modules/botopink.json" "$L/conformance/modules/"
  for c in "${cells[@]}"; do
    [[ -d "$from/$lib/conformance/modules/$c" ]] || { fail "$lib: no conformance cell $c"; continue; }
    copy_tree "$from/$lib/conformance/modules/$c" "$L/conformance/modules/$c"
  done
  ANALYSIS="$L/conformance/modules/.botopinkbuild/analysis"
  targets="$(python3 -c 'import json,sys; print(" ".join(json.load(open(sys.argv[1]))["targets"]))' "$L/conformance/modules/botopink.json")"

  for target in $targets; do
    flags=()
    [[ "$target" == commonJS ]] && flags=(--typescript)
    rm -rf "${ANALYSIS:?}/$target"
    bad=0
    for c in "${cells[@]}"; do
      cell="$L/conformance/modules/$c"
      [[ -d "$cell" ]] || continue
      build "$cell" "$target" "out-cold" --cold ${flags[@]+"${flags[@]}"} || { bad=1; continue; }
      build "$cell" "$target" "out-warm" ${flags[@]+"${flags[@]}"} || { bad=1; continue; }
      build "$cell" "$target" "out-read" ${flags[@]+"${flags[@]}"} || { bad=1; continue; }
      for run in warm read; do
        if ! diff -r "$cell/out-cold" "$cell/out-$run" > "$WORK/diff.log"; then
          fail "$lib/$target: $c's output built through level B ($run) differs from its --cold build"
          head -20 "$WORK/diff.log" | sed 's/^/      /' >&2
          bad=1
        fi
      done
      rm -rf "$cell/out-cold" "$cell/out-warm" "$cell/out-read"
    done
    [[ -f "$ANALYSIS/$target/$lib.bpa" ]] || { fail "$lib/$target: no $lib entry under .botopinkbuild/analysis/$target/"; bad=1; }
    [[ "$bad" -eq 0 ]] && echo "  ✓ $lib/$target: ${#cells[@]} consumers built --cold, writing and reading the entry emit the same bytes"
  done
done

if [[ "$failures" -ne 0 ]]; then
  echo "analysis equivalence: $failures failure(s)" >&2
  exit 1
fi
echo "analysis equivalence: jhonstart, rakun and emilia read back from level B emit what analysing them emits"
