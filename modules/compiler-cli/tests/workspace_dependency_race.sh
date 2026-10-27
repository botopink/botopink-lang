#!/usr/bin/env bash
# Decision 1006 (5) with 1015 (4) — members racing on one dependency (a CLI behaviour at a
# workspace root, proven by the CLI's own script, decision 1020): the members of one
# workspace build and run side by side over its one `out/<t>/` folder, and no process ever
# sees a shared file half written. Every file a member writes there is staged under a name
# of its own and renamed over the final one: a dependency's module (`.erl`, `.S`, `.js`,
# `.d.ts`, wasm units), the `.beam` the OTP compiler makes of it (compiled in memory and
# placed, never through the compiler's one fixed `<name>.bea#`) and its record, the
# runtime units, the sidecars.
#   • eight members over one library build at once under `--cold` (every member rewrites
#     the library and compiles every `.beam` again), each its own process started by this
#     script, on erlang, beam, commonJS and wasm — twice per target;
#   • then the root's `run --target <t> --jobs 8` answers every member;
#   • on wasm each member's entry is its own `<pkg>@main` file in the folder (two members'
#     `main` never share one name);
#   • the folder holds no staged leftover (`*.tmp`, `*.bea#`); on erlang and beam every
#     `.beam` reads whole (`beam_lib:chunks`) and every record is whole; on commonJS every
#     `.js` passes `node --check`.
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
WORK="$(mktemp -d "${tmp_root%/}/botopink-ws-race.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }
ok() { echo "  ✓ $*"; }

N=8
MEMBERS=()
for i in $(seq 1 "$N"); do MEMBERS+=("m$i"); done

# ── the fixture: eight members over one library of several modules and a type ──
WS="$WORK/ws"
LIB="$WORK/lib"
mkdir -p "$LIB/src" "$WS"
printf '{ "name": "lib", "entry": "root.bp", "files": ["root.bp", "words.bp", "sums.bp", "shapes.bp"] }\n' >"$LIB/botopink.json"
printf 'pub mod words;\npub mod sums;\npub mod shapes;\n' >"$LIB/src/root.bp"
cat >"$LIB/src/words.bp" <<'BP'
pub fn join(a: string, b: string) -> string {
    return a + " " + b;
}

pub fn twice(a: string) -> string {
    return a + a;
}
BP
cat >"$LIB/src/sums.bp" <<'BP'
pub fn square(n: i32) -> i32 {
    return n * n;
}

pub fn cube(n: i32) -> i32 {
    return n * n * n;
}
BP
cat >"$LIB/src/shapes.bp" <<'BP'
pub type Point(x: i32, y: i32)

pub fn norm1(p: Point) -> i32 {
    return p.x + p.y;
}
BP
cat >"$WS/botopink.json" <<'EOF'
{ "name": "ws", "version": "0.0.1", "workspaces": ["*"] }
EOF
for m in "${MEMBERS[@]}"; do
  mkdir -p "$WS/$m/src"
  printf '{ "name": "%s", "dependencies": { "lib": { "path": "../../lib" } } }\n' "$m" >"$WS/$m/botopink.json"
  cat >"$WS/$m/src/main.bp" <<BP
import {io.terminal.print} from "std";
import {words.join, sums.square, shapes.Point, shapes.norm1} from "lib";

pub fn main() -> void {
    print(join("hello", "$m") + " " + square(norm1(Point(x: 3, y: 4))).toString());
}
BP
done

# Each member answers once alone, so the expected line is the language's, not the race's.
want_alone() { # <target> <member>
  (cd "$WS/$2" && "$BP" run --target "$1" --out "$WORK/alone" 2>/dev/null | tail -1)
}

check_folder() { # <target> <round> <build|run>
  local t="$1" r="$2" phase="$3" dir="$WS/out/$1" left
  left="$(find "$dir" \( -name '*.tmp' -o -name '*.bea#' \) | head -5)"
  [[ -z "$left" ]] || fail "$t round $r: staged leftovers in the folder: $left"
  case "$t" in
    erlang|beam)
      local beams bad
      beams="$(find "$dir" -name '*.beam' | wc -l)"
      # beam's build writes the `.S`; its `run` assembles them.
      [[ "$beams" -gt 0 ]] || { [[ "$t/$phase" == beam/build ]] || fail "$t round $r: no .beam in $dir"; return; }
      bad="$(erl -noshell -eval '
        [Dir] = init:get_plain_arguments(),
        Bad = [F || F <- filelib:wildcard(filename:join(Dir, "*.beam")),
                    case beam_lib:chunks(F, [exports]) of {ok, _} -> false; _ -> true end],
        io:format("~s", [lists:join(" ", Bad)]),
        halt().' -extra "$dir")"
      [[ -z "$bad" ]] || fail "$t round $r: .beam files that do not read whole: $bad"
      local rec
      for rec in "$dir"/*.beam.rec; do
        [[ -e "$rec" ]] || continue
        [[ "$(grep -cE '^(source|compiler|otp) ' "$rec")" -eq 3 && "$(wc -l <"$rec")" -eq 3 ]] \
          || fail "$t round $r: a record that is not whole: $rec"
      done ;;
    commonJS)
      local js
      for js in "$dir"/*.js; do
        node --check "$js" 2>/dev/null || fail "$t round $r: $js does not parse"
      done ;;
  esac
}

for target in erlang beam commonJS wasm; do
  want="$(want_alone "$target" m1)"
  [[ "$want" == "hello m1 49" ]] || { fail "$target: m1 alone answers '$want', not 'hello m1 49'"; continue; }
  for round in 1 2; do
    echo "==> $target round $round: $N members build --cold at once over one folder"
    rm -rf "$WS/out"
    pids=()
    for m in "${MEMBERS[@]}"; do
      (cd "$WS/$m" && exec "$BP" build --target "$target" --workspace-out "$WS/out" --cold >"$WORK/$m.log" 2>&1) &
      pids+=("$!")
    done
    i=0
    for m in "${MEMBERS[@]}"; do
      if ! wait "${pids[$i]}"; then
        sed 's/^/      /' "$WORK/$m.log" >&2
        fail "$target round $round: member $m's build failed"
      fi
      i=$((i + 1))
    done
    [[ "$target" == wasm || "$(find "$WS/out/$target" -maxdepth 1 -name 'lib@words.*' ! -name '*.rec' ! -name '*.beam' | wc -l)" -ge 1 ]] \
      || fail "$target round $round: lib@words is in the folder"
    check_folder "$target" "$round" build
    if [[ "$target" == wasm ]]; then
      for m in "${MEMBERS[@]}"; do
        [[ -f "$WS/out/wasm/$m@main.wat" ]] || { fail "wasm round $round: $m's entry is its own $m@main.wat"; break; }
      done
    fi

    echo "==> $target round $round: the root's run answers every member, $N at once"
    set +e
    OUT="$(cd "$WS" && "$BP" run --target "$target" --jobs "$N" 2>&1)"
    code=$?
    set -e
    [[ $code -eq 0 ]] || { echo "$OUT" >&2; fail "$target round $round: the root's run (exit $code)"; }
    for m in "${MEMBERS[@]}"; do
      grep -qxF "ok   $m" <<<"$OUT" && grep -qxF "    hello $m 49" <<<"$OUT" \
        || { echo "$OUT" >&2; fail "$target round $round: $m answers 'hello $m 49'"; break; }
    done
    grep -qxF "modules: $N checked — $N passed, 0 failed" <<<"$OUT" || fail "$target round $round: the count"
    check_folder "$target" "$round" run
    ok "$target round $round: every member answered, every shared file whole"
  done
done

if (( failures > 0 )); then
  echo "workspace_dependency_race.sh: $failures failure(s)" >&2
  exit 1
fi
echo "workspace_dependency_race.sh: every behaviour held"
