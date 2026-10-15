#!/usr/bin/env bash
# `test-analysis-equivalence` over real libraries (144 B-60, guard 2): the code
# cache's level B must answer what analysing answers. For a few conformance
# cells of rakun's packages `rakun`, `rakun-bpp` and `rakun-stylesheet` — each a
# consumer of its package — every cell is built three times on every target its
# suite declares (`conformance/<package>/botopink.json`'s `targets`):
#   • `--cold`  — reads nothing;
#   • warm      — the first cell of a target writes the package's entry into
#                 an emptied `.botopinkbuild/analysis/<target>/`, the cells
#                 after it read the entry the first one wrote (one library,
#                 one entry, whichever consumer wrote it);
#   • warm again — reads every entry;
# and the three outputs are compared file by file, byte for byte. The package's
# entry must exist (`<target>/<package>.bpa`), or the run proved nothing.
# `level_b.sh` is the same check over the closure invariant's fixture, with
# the wasm targets; a field the format drops changing the output is the
# in-process test of `cli/analysis_equivalence.zig`.
#
# The packages are rakun's, the workspace sibling of botopink-lang: the first
# ancestor `D` of this repository holding `D/repository/rakun` (the meta
# checkout, a task worktree's linked siblings, or CI's `repository/` beside
# botopink-lang). A rakun that is not there fails the script. It is copied —
# its root manifest, `modules/` and the chosen cells — into a scratch directory
# whose `repository/` links the other siblings, so its dependencies resolve as
# in the checkout and nothing is written outside the scratch directory.
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

# The workspace repository the packages live in.
WORKSPACE=rakun

# package:cell,cell,… — a few cells each (`conformance/<package>/<cell>`),
# enough to read one entry under several consumers.
PACKAGES=(
  "rakun-bpp:counter_ssr,link_props"
  "rakun:scopes,provides"
  "rakun-stylesheet:alpha,bg-color"
)

# The siblings' directory: the first ancestor holding `repository/<lib>`.
siblings_of() { # <repository>
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

for spec in "${PACKAGES[@]}"; do
  lib="${spec%%:*}"   # the package
  IFS=',' read -r -a cells <<< "${spec#*:}"
  if ! from="$(siblings_of "$WORKSPACE")"; then
    fail "$lib: no repository/$WORKSPACE above $REPO_ROOT — the workspace is botopink-lang's sibling"
    continue
  fi

  # The scratch checkout: `repository/rakun` copied, every other sibling linked.
  S="$WORK/$lib"
  mkdir -p "$S/repository"
  for sib in "$from"/*/; do
    name="$(basename "$sib")"
    [[ "$name" == "$WORKSPACE" || "$name" == botopink-lang ]] && continue
    ln -s "$(cd "$sib" && pwd)" "$S/repository/$name"
  done
  L="$S/repository/$WORKSPACE"
  C="$L/conformance/$lib"
  mkdir -p "$C"
  cp "$from/$WORKSPACE/botopink.json" "$L/"
  # The root manifest's other workspace folders (`examples/*`, `starters/*`)
  # exist, empty: a workspace entry that cannot be read is a located error.
  python3 -c 'import json,os,sys
for w in json.load(open(sys.argv[1])).get("workspaces", []):
    os.makedirs(os.path.join(sys.argv[2], w.split("*")[0]), exist_ok=True)' "$L/botopink.json" "$L"
  copy_tree "$from/$WORKSPACE/modules" "$L/modules"
  cp "$from/$WORKSPACE/conformance/$lib/botopink.json" "$C/"
  for c in "${cells[@]}"; do
    [[ -d "$from/$WORKSPACE/conformance/$lib/$c" ]] || { fail "$lib: no conformance cell $c"; continue; }
    copy_tree "$from/$WORKSPACE/conformance/$lib/$c" "$C/$c"
  done
  ANALYSIS="$C/.botopinkbuild/analysis"
  targets="$(python3 -c 'import json,sys; print(" ".join(json.load(open(sys.argv[1]))["targets"]))' "$C/botopink.json")"

  for target in $targets; do
    flags=()
    [[ "$target" == commonJS ]] && flags=(--typescript)
    rm -rf "${ANALYSIS:?}/$target"
    bad=0
    for c in "${cells[@]}"; do
      cell="$C/$c"
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
echo "analysis equivalence: rakun, rakun-bpp and rakun-stylesheet read back from level B emit what analysing them emits"
