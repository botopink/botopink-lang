#!/usr/bin/env bash
# The cell-result store of the gate's three big stages (decisions 229 and 249 of
# 1.0.11-beta, front 00-gate/133-gate-speed), end to end against the installed
# binaries: `tests/language/run.sh` (stage 9), `botopink-lib-test` (stage 8,
# through its JSON) and `scripts/check-docs.sh` (stage 10), each over a
# synthetic suite in a scratch directory with its own `--store-root`.
#
# The compiler part of a key is its build configuration and its SOURCES,
# partitioned by backend (`modules/compiler-core/src/codegen/backend-partition.txt`).
# To edit them without rebuilding, the runners are handed a shim `botopink` that
# runs the real binary and names, on its `--version` `build:` line, a copy of
# the source set in the scratch directory with that copy's own hash — exactly
# what a binary rebuilt from the edited copy would print.
#
# For each runner:
#   • a run with an empty store runs every job; the next run with no change
#     answers every pass from the store and runs every failure;
#   • one byte of a cell's source runs that cell, and only it;
#   • one byte of the library root (`libs/std/src/collections.bp` of a copy)
#     runs every cell;
#   • one line of the wasm emitter (`codegen/wat.zig`, listed under wasm) runs
#     the wasm cells only (and the target-independent `check` jobs); one line of
#     the checker (`comptime/infer.zig`, shared) runs every cell; a new file
#     under `codegen/js/` that the partition does not list is shared: every
#     cell runs;
#   • a shared file that uses a listed one fails the partition's audit, and a
#     binary whose `build:` hash is not its sources': nothing is stored, and the
#     run says why;
#   • `node`, the OTP release (`erl`) or `wasmtime` reporting another version
#     runs every cell — every runtime is in every key;
#   • `--cold` runs every cell and WRITES its passes (decision 249), so the
#     next warm run answers them; a deleted store answers nothing;
#   • a cell whose inputs cannot be enumerated (a symbolic link, a dependency
#     path that leaves the cell) is run every time and named as never stored.
#
# Exit 0 = every behaviour held.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

if [[ -z "${BOTOPINK_SKIP_BUILD:-}" ]]; then
  echo "==> building the binaries"
  ( cd "$REPO_ROOT" && zig build )
fi
BP_BIN="$REPO_ROOT/zig-out/bin/botopink"
LIB_TEST_BIN="$REPO_ROOT/zig-out/bin/botopink-lib-test"
STORE_JS="$REPO_ROOT/scripts/lib/result-store.js"
fail() { echo "  ✗ $1" >&2; exit 1; }
[[ -x "$BP_BIN" ]] || fail "botopink not found at $BP_BIN"
[[ -x "$LIB_TEST_BIN" ]] || fail "botopink-lib-test not found at $LIB_TEST_BIN"
# The store's keys probe every runtime; a machine without one cannot run the
# gate (decision 67: a missing runtime fails, it is never skipped).
for tool in node erl wasmtime; do
  command -v "$tool" >/dev/null 2>&1 || fail "$tool is not on PATH"
done

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# ── the compiler's sources, in a copy the test may edit ──────────────────────
SRC="$WORK/checkout"
mkdir -p "$SRC/modules"
cp "$REPO_ROOT/build.zig" "$SRC/"
for d in compiler-cli/src compiler-core/src manifest/src lib-test-runner/src source-stamp/src wasm3; do
  mkdir -p "$SRC/modules/$(dirname "$d")"
  cp -R "$REPO_ROOT/modules/$d" "$SRC/modules/$d"
done
cp -R "$REPO_ROOT/libs" "$SRC/libs"
rm -rf "$SRC"/libs/*/.botopinkbuild
BUILD_LINE="$("$BP_BIN" --version | grep '^build: ')" || fail "botopink --version prints no build: line"
BUILD_CONF="$(cut -d' ' -f2-5 <<<"$BUILD_LINE")"
SHIM="$WORK/shim-compiler/botopink"
mkdir -p "$(dirname "$SHIM")"
# shim [<hash>] — answer `--version` as a binary built from $SRC as it is now
# would (or with <hash>, as one built from other sources).
shim() {
  local hash
  hash="${1:-$(node "$STORE_JS" source-hash --root "$SRC")}"
  cat >"$SHIM" <<SH
#!/usr/bin/env bash
if [ "\$*" = "--version" ]; then printf 'botopink shim\nbuild: %s %s %s\n' "$BUILD_CONF" "$hash" "$SRC"; exit 0; fi
exec "$BP_BIN" "\$@"
SH
  chmod +x "$SHIM"
}
shim
edit() { printf '\n// one line more\n' >>"$SRC/$1"; shim; }

# ── shims: one runtime reporting another version ─────────────────────────────
REAL_NODE="$(command -v node)"; REAL_ERL="$(command -v erl)"; REAL_WASMTIME="$(command -v wasmtime)"
mkdir -p "$WORK/shim-node" "$WORK/shim-erl" "$WORK/shim-wasmtime"
cat >"$WORK/shim-node/node" <<SH
#!/usr/bin/env bash
[ "\$*" = "--version" ] && { echo v0.0.0-shim; exit 0; }
exec "$REAL_NODE" "\$@"
SH
cat >"$WORK/shim-erl/erl" <<SH
#!/usr/bin/env bash
case "\$*" in *code:root_dir*) echo "99 99.0 /nonexistent"; exit 0 ;; esac
exec "$REAL_ERL" "\$@"
SH
cat >"$WORK/shim-wasmtime/wasmtime" <<SH
#!/usr/bin/env bash
[ "\$*" = "--version" ] && { echo "wasmtime 0.0.0-shim"; exit 0; }
exec "$REAL_WASMTIME" "\$@"
SH
chmod +x "$WORK"/shim-*/*

# A copy of the library root (`from "std"`), outside every walk-up path. Every
# runner is handed it: the default roots of `check-docs.sh` are this
# checkout's `libs/` and every sibling under the meta workspace's
# `repository/`, hashed whole into each key — a sibling's install (a symbolic
# link in `vscode-extension/node_modules`) made every fence unstorable.
mkdir -p "$WORK/lang"
cp -R "$REPO_ROOT/libs" "$WORK/lang/libs"
rm -rf "$WORK"/lang/libs/*/.botopinkbuild

# expect <what> <output> <total> <run> <from store> — the runner's store line.
expect() {
  local line
  line="$(sed "s/$(printf '\033')\[[0-9;]*m//g" <<<"$2" | grep -E '^result store: [0-9]+ (jobs|fences) — ' | tail -1)"
  [[ "$line" =~ ^result\ store:\ $3\ (jobs|fences)\ —\ $4\ run,\ $5\ from\ store ]] ||
    { echo "$2" >&2; fail "$1: expected $3 — $4 run, $5 from store; got: ${line:-no result store line}"; }
}

# ── tests/language/run.sh ────────────────────────────────────────────────────
echo "==> [language] tests/language/run.sh answers a pass from the store only on an equal key"
SUITE="$WORK/suite"
mkdir -p "$SUITE/run"
for c in alpha beta; do
  printf '// v1\npub fn main() {\n    @print("%s");\n}\n' "$c" >"$SUITE/run/$c.bp"
  printf '%s\n' "$c" >"$SUITE/run/$c.out"
done
printf 'pub fn main() {\n    @print("red");\n}\n' >"$SUITE/run/red.bp"
printf 'not what it prints\n' >"$SUITE/run/red.out"
lang() { # lang [<run.sh args>…] — every target over the synthetic suite; output in $out
  set +e
  out="$(bash "$REPO_ROOT/tests/language/run.sh" --suite "$SUITE" --target all --compiler "$SHIM" \
    --lib-root "$WORK/lang/libs" --store-root "$WORK/store-language" "$@" 2>&1)"
  code=$?
  set -e
}
# 3 cells × 4 targets; run/red is red on every one.
lang; expect "first run" "$out" 12 12 0
[[ $code -eq 1 ]] || fail "run/red is red: the run must fail (exit $code)"
lang; expect "no change" "$out" 12 4 8
[[ $code -eq 1 ]] || fail "a failure is never answered from the store: the run must still fail (exit $code)"
grep -q 'FAIL.*run/red.bp' <<<"$out" || fail "run/red ran again and is reported red"
sed -i.bak 's#// v1#// v2#' "$SUITE/run/alpha.bp" && rm -f "$SUITE/run/alpha.bp.bak"
lang; expect "one byte of run/alpha.bp" "$out" 12 8 4
printf '// one byte more\n' >>"$WORK/lang/libs/std/src/collections.bp"
lang; expect "one byte of the library root's collections.bp" "$out" 12 12 0
edit modules/compiler-core/src/codegen/wat.zig
lang; expect "one line of the wasm emitter: the wasm cells and the reds" "$out" 12 6 6
! grep -q 'never stored' <<<"$out" || fail "nothing should be unstorable"
edit modules/compiler-core/src/comptime/infer.zig
lang; expect "one line of the checker (shared)" "$out" 12 12 0
printf 'pub const fresh = 1;\n' >"$SRC/modules/compiler-core/src/codegen/js/fresh_unlisted.zig"; shim
lang; expect "a file under codegen/js/ the partition does not list (shared)" "$out" 12 12 0
for t in node erl wasmtime; do
  PATH="$WORK/shim-$t:$PATH" lang; expect "another $t version" "$out" 12 12 0
done
rm -rf "$WORK/store-language"
lang --cold; expect "--cold" "$out" 12 12 0
grep -q -- '--cold: nothing read from the store' <<<"$out" || fail "--cold should say nothing was read"
lang; expect "a warm run after --cold answers what --cold wrote" "$out" 12 4 8
rm -rf "$WORK/store-language"
lang; expect "a deleted store" "$out" 12 12 0
# The compiler part of the key cannot be trusted: nothing is read or written.
shim 0000000000000000000000000000000000000000000000000000000000000000
lang; lang; expect "a binary not built from the checkout's sources" "$out" 12 12 0
grep -q 'never stored — .*was not built from the sources' <<<"$out" || fail "the stale binary should be named as the reason"
printf 'const leak = @import("codegen/wat.zig");\npub fn leakUse() void {\n    _ = leak.codegenEmit;\n}\n' >>"$SRC/modules/compiler-core/src/parser.zig"; shim
lang; lang; expect "a shared file using the wasm emitter" "$out" 12 12 0
grep -q 'never stored — modules/compiler-core/src/parser.zig uses modules/compiler-core/src/codegen/wat.zig, which .* gives to wasm alone' <<<"$out" ||
  fail "the partition's audit should name the shared file that uses a listed one"
cp "$REPO_ROOT/modules/compiler-core/src/parser.zig" "$SRC/modules/compiler-core/src/parser.zig"; shim
# Inputs that cannot be enumerated: a symbolic link, a dependency path that
# leaves the cell. Each is run every time and named.
mkdir -p "$SUITE/modules/linked/src" "$SUITE/modules/escapes/src"
for c in linked escapes; do printf 'pub fn main() {\n    @print("%s");\n}\n' "$c" >"$SUITE/modules/$c/src/main.bp"; printf '%s\n' "$c" >"$SUITE/modules/$c/expected.out"; done
printf '{ "name": "language_tests", "version": "0.0.1", "src": "src/" }\n' >"$SUITE/modules/linked/botopink.json"
ln -s main.bp "$SUITE/modules/linked/src/alias.bp.txt"
printf '{ "name": "language_tests", "version": "0.0.1", "src": "src/", "dependencies": { "up": { "path": "../../run" } } }\n' >"$SUITE/modules/escapes/botopink.json"
lang --only modules/linked --target commonJS; lang --only modules/linked --target commonJS
expect "a cell holding a symbolic link" "$out" 1 1 0
grep -q 'never stored — modules/linked/src/alias.bp.txt is a symbolic link' <<<"$out" || fail "the symbolic link should be named as the reason"
lang --only modules/escapes --target commonJS; lang --only modules/escapes --target commonJS
expect "a cell whose dependency leaves it" "$out" 1 1 0
grep -q 'never stored — modules/escapes: dependency `up` has a path outside the cell' <<<"$out" || fail "the escaping dependency should be named as the reason"
rm -rf "$SUITE/modules"

# ── botopink-lib-test ────────────────────────────────────────────────────────
echo "==> [libs] botopink-lib-test answers a pass from the store only on an equal key"
LROOT="$WORK/lroot"
for l in okl redl; do
  mkdir -p "$LROOT/$l/src"
  printf '{ "name": "%s", "version": "0.0.1", "target": "commonJS", "src": "src/" }\n' "$l" >"$LROOT/$l/botopink.json"
done
printf '// v1\nfn one() -> i32 {\n    return 1;\n}\n\ntest "one" {\n    assert one() == 1;\n}\n' >"$LROOT/okl/src/main.bp"
printf 'fn one() -> i32 {\n    return 1;\n}\n\ntest "one is two" {\n    assert one() == 2;\n}\n' >"$LROOT/redl/src/main.bp"
libs() { # libs [<runner args>…] — JSON run of both libraries on commonJS; output in $out
  set +e
  out="$(cd "$WORK" && "$LIB_TEST_BIN" --json --bin "$SHIM" --lib-root "$LROOT" --target commonJS \
    --store-root "$WORK/store-libs" "$@" 2>&1)"
  code=$?
  set -e
  # The runner's record, in the wrappers' words.
  local rec
  rec="$(grep '^{"event":"result_store"' <<<"$out" | tail -1)"
  out="$out
result store: $(sed -n 's/.*"jobs":\([0-9]*\).*/\1/p' <<<"$rec") jobs — $(sed -n 's/.*"ran":\([0-9]*\).*/\1/p' <<<"$rec") run, $(sed -n 's/.*"from_store":\([0-9]*\).*/\1/p' <<<"$rec") from store"
}
libs; expect "first run" "$out" 2 2 0
[[ $code -eq 1 ]] || fail "redl is red: the run must fail (exit $code)"
grep -q '"written":1' <<<"$out" || fail "the one pass should be written"
libs; expect "no change" "$out" 2 1 1
grep -q '"event":"cell_summary","lib":"okl","target":"commonJS","status":"pass","failed":0,"ran":true,"from_store":true' <<<"$out" ||
  fail "okl's pass should come back from the store, with its test count"
grep -q '"event":"cell_summary","lib":"redl","target":"commonJS","status":"fail".*"from_store":false' <<<"$out" || fail "redl must run again"
grep -q '"lib":"okl","target":"commonJS","event":"test"' <<<"$out" || fail "the stored pass should replay the cell's test records"
sed -i.bak 's#// v1#// v2#' "$LROOT/okl/src/main.bp" && rm -f "$LROOT/okl/src/main.bp.bak"
libs; expect "one byte of okl's source" "$out" 2 2 0
libs; expect "after it" "$out" 2 1 1
printf '// one byte more\n' >>"$LROOT/redl/src/main.bp"
libs; expect "one byte of another library (every library is in every key)" "$out" 2 2 0
edit modules/compiler-core/src/codegen/wat.zig
libs; expect "one line of the wasm emitter (no wasm cell here)" "$out" 2 1 1
edit modules/compiler-core/src/codegen/js/js_emitter.zig
libs; expect "one line of the commonJS emitter" "$out" 2 2 0
for t in node erl wasmtime; do
  PATH="$WORK/shim-$t:$PATH" libs; expect "another $t version" "$out" 2 2 0
done
rm -rf "$WORK/store-libs"
libs --cold; expect "--cold" "$out" 2 2 0
grep -q '"written":1' <<<"$out" || fail "--cold writes the pass it ran"
libs; expect "a warm run after --cold" "$out" 2 1 1
rm -rf "$WORK/store-libs"
libs; expect "a deleted store" "$out" 2 2 0
shim 0000000000000000000000000000000000000000000000000000000000000000
libs; libs; expect "a binary not built from the checkout's sources" "$out" 2 2 0
grep -q '"note":"never stored: .*was not built from the sources' <<<"$out" || fail "the stale binary should be named"
shim
# Text mode prints the same line after the matrix. `--json` changes what the
# child prints, so it is part of the key: the first text run runs both cells.
textrun() {
  set +e
  text="$(cd "$WORK" && "$LIB_TEST_BIN" --bin "$SHIM" --lib-root "$LROOT" --target commonJS --store-root "$WORK/store-libs" 2>&1)"
  set -e
}
textrun; expect "text mode, first" "$text" 2 2 0
textrun; expect "text mode, again" "$text" 2 1 1
grep -q 'okl · commonJS (from store)' <<<"$text" || fail "a cell answered from the store says so in its header"

# ── scripts/check-docs.sh ────────────────────────────────────────────────────
echo "==> [docs] scripts/check-docs.sh answers a fence from the store only on an equal key"
DOC="$WORK/doc.md"
cat >"$DOC" <<'MD'
# doc

```botopink
fn one() -> i32 { return 1; }
```

<!-- docs-check: reject body unbound variable 'nope' -->
```botopink
nope();
```
MD
docs() {
  set +e
  out="$(bash "$REPO_ROOT/scripts/check-docs.sh" --doc "$DOC" --compiler "$SHIM" --store-root "$WORK/store-docs" \
    --lib-root "$WORK/lang/libs" "$@" 2>&1)"
  code=$?
  set -e
  [[ $code -eq 0 ]] || { echo "$out" >&2; fail "check-docs.sh failed (exit $code)"; }
}
docs; expect "first run" "$out" 2 2 0
docs; expect "no change" "$out" 2 0 2
sed -i.bak 's#return 1;#return 2;#' "$DOC" && rm -f "$DOC.bak"
docs; expect "one byte of one fence" "$out" 2 1 1
edit modules/compiler-core/src/codegen/wat.zig
docs; expect "one line of the wasm emitter (check is target-independent: every backend is in its key)" "$out" 2 2 0
for t in node erl wasmtime; do
  PATH="$WORK/shim-$t:$PATH" docs; expect "another $t version" "$out" 2 2 0
done
docs --cold; expect "--cold" "$out" 2 2 0
docs; expect "a warm run after --cold" "$out" 2 0 2
rm -rf "$WORK/store-docs"
docs; expect "a deleted store" "$out" 2 2 0

echo "==> result store: OK"
