#!/usr/bin/env bash
# Decision 805 (1)–(3), 798 (5) — the build's reusable intermediate end to end
# against the real CLI, over `runtime_file/`: `app`, whose `main.bp` holds a
# decorator and a template of its dependency `lib`, a top-level `comptime`
# block, a folded value and a std module.
#   • `build --emit-runtime <dir>` writes `<dir>/<package>.bpr` per package —
#     `app.bpr`, `lib.bpr`, std's one per module under `std/` —, creating the
#     directory, each file named on stderr;
#   • on commonJS (with the `.d.ts`), erlang, beam and wasm, the program built
#     from `app.bpr` writes every file of the direct build, byte for byte, and
#     the run after the direct `run` — from the package's own `.bpr` set, which
#     `run` finds itself and takes no path to (decisions 1006, 1009) — prints what
#     the direct `run` prints, nothing of the build phase (the top-level block's
#     `print`); on wasm the direct build, the build from `app.bpr` and the runs
#     write the same files, the entry `app@main.wasm` and its units, each
#     `<pkg>@<path>` (decisions 1032 (1), 1065 (2)), the run that builds the
#     package's own set included (1006-b (5)) — and `run` over the build's own folder (in process, decisions
#     1032 (3), 1034) answers the run's answer and leaves the folder as it was;
#   • the `.bpr` one target's build wrote builds every other target;
#   • a dependency's `.bpr` is the same bytes whichever build wrote it;
#   • the manifest's wasm host (decision 334 (2)) is in the root's `.bpr`: over
#     `web/`, a `"host": "browser"` project, the wasm build from the `.bpr` is
#     the direct build byte for byte (the `.mjs` loader included) and the run
#     from its own set goes through the loader under node, answering the direct run;
#   • a module reading `@TypeInfo.all` is filed in the root's `.bpr`, whatever
#     its package (805 (1)): over `cat/`, two programs `a` and `b` over one
#     `lib` whose module reads the catalogue, both emitted into one directory,
#     each builds from its own `.bpr` as its direct build does and `lib.bpr`
#     holds no such module and is the same bytes after both;
#   • a module expanding a template that queries the catalogue is filed there too
#     (805 (1)): over `tpl/`, programs `a` and `b` over one `mid` whose `card`
#     module expands `looks`'s template, `mid.bpr` the same bytes after both and
#     each program's run from its own set reading its own `#[theme]`;
#   • `run` over a `.bpr` path is refused as any unexpected argument (decision 1009);
#   • refused: `build` over a `.bpr` without `--target`
#     (`runtime-target-required`), a `.bpr` of another compiler
#     (`runtime-other-compiler`), a dependency's `.bpr` as the program
#     (`runtime-not-a-program`), a package's `.bpr` missing beside the root's
#     (`runtime-missing`), `--emit-runtime` without its directory;
#   • a `.bpr` is built from the directory of the project that wrote it (decision
#     838 (3)): `app.bpr` over a directory with no `botopink.json` or over `lib/`
#     is `runtime-other-project`, naming both.
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
WORK="$(mktemp -d "${tmp_root%/}/botopink-runtime-file.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
cp -R "$SCRIPT_DIR/runtime_file/." "$WORK/"
APP="$WORK/app"

failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }

bp() { # <log> <args…>: the CLI in `app`, its stdout and stderr to <log>
  local log="$1"; shift
  ( cd "$APP" && "$BP_BIN" "$@" ) > "$log" 2>&1
}
bpin() { # <dir> <log> <args…>: the CLI in <dir>
  local dir="$1" log="$2"; shift 2
  ( cd "$dir" && "$BP_BIN" "$@" ) > "$log" 2>&1
}

# A refusal: exit 1 and the coded line.
refused() { # <what> <code> <args…>
  local what="$1" code="$2"; shift 2
  if bp "$WORK/refused.log" "$@"; then
    fail "$what: exit 0"
  elif ! grep -q "error\[$code\]" "$WORK/refused.log"; then
    fail "$what: no error[$code]"
    sed 's/^/      /' "$WORK/refused.log" >&2
  fi
}

RT="$WORK/rt"
for target in commonJS erlang beam wasm; do
  rt="$RT-$target"
  if ! bp "$WORK/direct.log" build --target "$target" --out "$WORK/direct-$target" --emit-runtime "$rt"; then
    fail "$target: the direct build failed"; sed 's/^/      /' "$WORK/direct.log" >&2; continue
  fi
  for f in app.bpr lib.bpr std/math.bpr; do
    [[ -f "$rt/$f" ]] || fail "$target: --emit-runtime wrote no $f"
    grep -q "wrote $rt/$f" "$WORK/direct.log" || fail "$target: --emit-runtime did not name $f"
  done
  if ! bp "$WORK/bpr.log" build --target "$target" --out "$WORK/bpr-$target" "$rt/app.bpr"; then
    fail "$target: the build from app.bpr failed"; sed 's/^/      /' "$WORK/bpr.log" >&2; continue
  fi
  diff -r "$WORK/direct-$target" "$WORK/bpr-$target" > "$WORK/diff.log" \
    || { fail "$target: built from app.bpr differs from the direct build"; sed 's/^/      /' "$WORK/diff.log" >&2; }
  cmp -s "$RT-commonJS/lib.bpr" "$rt/lib.bpr" || fail "$target: lib.bpr differs from the one the commonJS build wrote"

  # `run`: the direct run prints the build phase, the run from the `.bpr` does not.
  # Direct: no `.bpr` set of the project's own to reuse (decision 1006 (2)).
  rm -rf "$APP/.botopinkbuild/runtime"
  bp "$WORK/run-direct.out" run --target "$target" --out "$WORK/run-direct-$target" || fail "$target: the direct run failed"
  grep -v -e 'Compiling' -e 'Compiled' -e '^build a$' "$WORK/run-direct.out" > "$WORK/want.out"
  grep -q '^build a$' "$WORK/run-direct.out" || fail "$target: the direct run printed no build output"
  # The run after it: from the package's own `.bpr` set (decisions 1006, 1009).
  bp "$WORK/run-bpr.out" run --target "$target" --out "$WORK/run-bpr-$target" || fail "$target: the run from the package's own .bpr failed"
  diff "$WORK/want.out" "$WORK/run-bpr.out" > "$WORK/diff.log" \
    || { fail "$target: the run from the package's own .bpr answers otherwise"; sed 's/^/      /' "$WORK/diff.log" >&2; }
  # Decisions 1032 (1), 1065 (2): on wasm the build, the build from a `.bpr` and the runs write
  # the entry `app@main.wasm` and its units, each `<pkg>@<path>`, the same files.
  if [[ "$target" == wasm ]]; then
    for d in direct bpr; do
      files="$(cd "$WORK/$d-$target/wasm" && ls | LC_ALL=C sort | tr '\n' ' ')"
      [[ -f "$WORK/$d-$target/wasm/app@main.wasm" ]] || fail "wasm: the $d build wrote no entry app@main.wasm ($files)"
      [[ ! -e "$WORK/$d-$target/wasm/main.wat" ]] || fail "wasm: the $d build still wrote main.wat"
    done
    # The build's own folder run in process (decisions 1032 (3), 1034): `run` over it
    # rewrites nothing and answers the run's answer.
    bp "$WORK/run-built.out" run --target wasm --out "$WORK/direct-$target" || fail "wasm: the run over the build's folder failed"
    diff <(grep -v -e 'Compiling' -e 'Compiled' -e '^build a$' "$WORK/run-built.out") "$WORK/want.out" > "$WORK/diff.log" \
      || { fail "wasm: the build's folder answers otherwise when run"; sed 's/^/      /' "$WORK/diff.log" >&2; }
    diff -r "$WORK/direct-$target/wasm" "$WORK/bpr-$target/wasm" > "$WORK/diff.log" \
      || { fail "wasm: the run over the build's folder changed it"; sed 's/^/      /' "$WORK/diff.log" >&2; }
    # Decision 1006-b (5): the run that builds the set, and the run from its own `.bpr`,
    # write the build's files.
    for d in run-direct run-bpr; do
      diff -r "$WORK/$d-$target/wasm" "$WORK/bpr-$target/wasm" > "$WORK/diff.log" \
        || { fail "wasm: the $d run's files differ from the build's"; sed 's/^/      /' "$WORK/diff.log" >&2; }
    done
  fi
done

refused "build over a .bpr without --target" runtime-target-required build "$RT-commonJS/app.bpr"
# `run` takes no `.bpr` path (decision 1009): refused as any unexpected argument.
if bp "$WORK/refused.log" run --target commonJS "$RT-commonJS/app.bpr"; then
  fail "run over a .bpr path: exit 0"
elif ! grep -qF "\`run\`: unexpected argument '$RT-commonJS/app.bpr'" "$WORK/refused.log"; then
  fail "run over a .bpr path: not refused as an unexpected argument"; sed 's/^/      /' "$WORK/refused.log" >&2
fi
cp "$RT-commonJS/app.bpr" "$WORK/foreign.bpr"
# The compiler's stamp: bytes 16–47 (after the two magics).
printf '\xff\xff\xff\xff' | dd of="$WORK/foreign.bpr" bs=1 seek=20 conv=notrunc 2>/dev/null
refused "a .bpr of another compiler" runtime-other-compiler build --target commonJS --out "$WORK/o" "$WORK/foreign.bpr"
refused "a dependency's .bpr as the program" runtime-not-a-program build --target commonJS --out "$WORK/o" "$RT-commonJS/lib.bpr"
mkdir -p "$WORK/lone" && cp "$RT-commonJS/app.bpr" "$WORK/lone/"
refused "a package's .bpr missing beside the root's" runtime-missing build --target commonJS --out "$WORK/o" "$WORK/lone/app.bpr"
# The project's directory (838 (3)): `app.bpr` from a directory with no manifest and from `lib/`.
mkdir -p "$WORK/nowhere"
for from in "$WORK/nowhere" "$WORK/lib"; do
  for cmd in build; do
    if bpin "$from" "$WORK/other.log" "$cmd" --target commonJS --out "$WORK/o" "$RT-commonJS/app.bpr"; then
      fail "$cmd over app.bpr from ${from#$WORK/}: exit 0"
    elif ! grep -q 'error\[runtime-other-project\]' "$WORK/other.log" || ! grep -q '`app`' "$WORK/other.log"; then
      fail "$cmd over app.bpr from ${from#$WORK/}: no error[runtime-other-project] naming app"
      sed 's/^/      /' "$WORK/other.log" >&2
    fi
  done
done
grep -q '`lib`' "$WORK/other.log" || fail "runtime-other-project from lib/ does not name the directory's project"
if bp "$WORK/refused.log" build --emit-runtime; then fail "--emit-runtime without its directory: exit 0"; fi

# The wasm host: `web` declares `"wasm": { "host": "browser" }`.
WEB="$WORK/web"
if ! bpin "$WEB" "$WORK/direct.log" build --target wasm --out "$WORK/direct-web" --emit-runtime "$WORK/rt-web"; then
  fail "web: the direct build failed"; sed 's/^/      /' "$WORK/direct.log" >&2
else
  [[ -f "$WORK/direct-web/wasm/main.mjs" ]] || fail "web: the direct build wrote no main.mjs loader"
  if ! bpin "$WEB" "$WORK/bpr.log" build --target wasm --out "$WORK/bpr-web" "$WORK/rt-web/web.bpr"; then
    fail "web: the build from web.bpr failed"; sed 's/^/      /' "$WORK/bpr.log" >&2
  else
    diff -r "$WORK/direct-web" "$WORK/bpr-web" > "$WORK/diff.log" \
      || { fail "web: built from web.bpr differs from the direct build"; sed 's/^/      /' "$WORK/diff.log" >&2; }
  fi
  bpin "$WEB" "$WORK/run-direct.out" run --target wasm --out "$WORK/run-direct-web" || fail "web: the direct run failed"
  grep -v -e 'Compiling' -e 'Compiled' "$WORK/run-direct.out" > "$WORK/want.out"
  grep -q '^hello from the browser host$' "$WORK/want.out" || fail "web: the direct run printed no greeting"
  bpin "$WEB" "$WORK/run-bpr.out" run --target wasm --out "$WORK/run-bpr-web" || fail "web: the run from its own .bpr failed"
  diff "$WORK/want.out" "$WORK/run-bpr.out" > "$WORK/diff.log" \
    || { fail "web: the run from its own .bpr answers otherwise"; sed 's/^/      /' "$WORK/diff.log" >&2; }
fi

# A catalogue reader's file: two programs over one `lib` whose `catalog` reads
# `@TypeInfo.all`, both emitted into one directory.
CAT="$WORK/cat"
for prog in a b; do
  if ! bpin "$CAT/$prog" "$WORK/direct.log" build --target commonJS --out "$WORK/direct-cat-$prog" --emit-runtime "$WORK/rt-cat"; then
    fail "cat/$prog: the direct build failed"; sed 's/^/      /' "$WORK/direct.log" >&2; continue
  fi
  cp "$WORK/rt-cat/lib.bpr" "$WORK/lib-$prog.bpr"
  grep -aq 'src/catalog.bp' "$WORK/lib-$prog.bpr" && fail "cat/$prog: lib.bpr holds the module reading @TypeInfo.all"
  grep -aq 'src/catalog.bp' "$WORK/rt-cat/$prog.bpr" || fail "cat/$prog: $prog.bpr does not hold the module reading @TypeInfo.all"
done
cmp -s "$WORK/lib-a.bpr" "$WORK/lib-b.bpr" || fail "cat: lib.bpr differs between the two programs"
cmp -s "$WORK/lib-b.bpr" "$WORK/rt-cat/lib.bpr" || fail "cat: lib.bpr differs after both"
for prog in a b; do
  [[ -f "$WORK/rt-cat/$prog.bpr" ]] || continue
  if ! bpin "$CAT/$prog" "$WORK/bpr.log" build --target commonJS --out "$WORK/bpr-cat-$prog" "$WORK/rt-cat/$prog.bpr"; then
    fail "cat/$prog: the build from $prog.bpr failed"; sed 's/^/      /' "$WORK/bpr.log" >&2; continue
  fi
  diff -r "$WORK/direct-cat-$prog" "$WORK/bpr-cat-$prog" > "$WORK/diff.log" \
    || { fail "cat/$prog: built from $prog.bpr differs from the direct build"; sed 's/^/      /' "$WORK/diff.log" >&2; }
  bpin "$CAT/$prog" "$WORK/run-direct.out" run --target commonJS --out "$WORK/run-direct-cat-$prog" || fail "cat/$prog: the direct run failed"
  grep -v -e 'Compiling' -e 'Compiled' "$WORK/run-direct.out" > "$WORK/want.out"
  bpin "$CAT/$prog" "$WORK/run-bpr.out" run --target commonJS --out "$WORK/run-bpr-cat-$prog" || fail "cat/$prog: the run from its own .bpr failed"
  diff "$WORK/want.out" "$WORK/run-bpr.out" > "$WORK/diff.log" \
    || { fail "cat/$prog: the run from its own .bpr answers otherwise"; sed 's/^/      /' "$WORK/diff.log" >&2; }
done

# A template expansion's file: two programs over one `mid` whose `card` module
# expands `looks`'s template, which queries the catalogue; each program's
# `#[theme]` is what the expansion reads, so `card` is filed in the root's file.
TPL="$WORK/tpl"
for prog in a b; do
  if ! bpin "$TPL/$prog" "$WORK/direct.log" build --target commonJS --out "$WORK/direct-tpl-$prog" --emit-runtime "$WORK/rt-tpl"; then
    fail "tpl/$prog: the direct build failed"; sed 's/^/      /' "$WORK/direct.log" >&2; continue
  fi
  cp "$WORK/rt-tpl/mid.bpr" "$WORK/mid-$prog.bpr"
  grep -aq 'src/card.bp' "$WORK/mid-$prog.bpr" && fail "tpl/$prog: mid.bpr holds the module expanding a catalogue template"
  grep -aq 'src/card.bp' "$WORK/rt-tpl/$prog.bpr" || fail "tpl/$prog: $prog.bpr does not hold the module expanding a catalogue template"
done
cmp -s "$WORK/mid-a.bpr" "$WORK/mid-b.bpr" || fail "tpl: mid.bpr differs between the two programs"
cmp -s "$WORK/mid-b.bpr" "$WORK/rt-tpl/mid.bpr" || fail "tpl: mid.bpr differs after both"
for prog in a b; do
  [[ -f "$WORK/rt-tpl/$prog.bpr" ]] || continue
  bpin "$TPL/$prog" "$WORK/run-direct.out" run --target commonJS --out "$WORK/run-direct-tpl-$prog" || fail "tpl/$prog: the direct run failed"
  grep -v -e 'Compiling' -e 'Compiled' "$WORK/run-direct.out" > "$WORK/want.out"
  grep -q "main\.${prog}theme" "$WORK/want.out" || fail "tpl/$prog: the direct run does not read its own #[theme]"
  bpin "$TPL/$prog" "$WORK/run-bpr.out" run --target commonJS --out "$WORK/run-bpr-tpl-$prog" || fail "tpl/$prog: the run from its own .bpr failed"
  diff "$WORK/want.out" "$WORK/run-bpr.out" > "$WORK/diff.log" \
    || { fail "tpl/$prog: the run from its own .bpr answers otherwise"; sed 's/^/      /' "$WORK/diff.log" >&2; }
done

if (( failures > 0 )); then
  echo "runtime_file.sh: $failures failure(s)" >&2
  exit 1
fi
echo "runtime_file.sh: every behaviour held"
