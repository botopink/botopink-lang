----- SOURCE CODE -- std/path.bp
```botopink
//// std/path — pure-botopink path manipulation (posix forward-slash).
////
//// Reference:
////   Node.js  — https://nodejs.org/api/path.html
////   Erlang   — https://www.erlang.org/doc/apps/stdlib/filename.html
////
//// Lib-self-contained: every operation composes `String` methods (`split`,
//// `slice`, `length`, `startsWith`), so the module works on every backend
//// including wat. Forward-slash separator only — Windows backslash paths
//// are not normalised here (the spec keeps `path` posix-shaped; a
//// `path_win32` sibling can land later if a target needs it).

pub val separator: string = "/";

pub val delimiter: string = ":";

// Split a path into its non-empty components. Leading-`/` paths drop the
// empty head; trailing-`/` paths drop the empty tail. A path made of pure
// separators yields the empty array. Uses `filter` rather than
// `forEach` + `push`: a `var` + `push` pattern lowers to a dead-store
// (`out ++ [p]` discarded) on Erlang because the immutable runtime never
// rebinds `Out`; `filter` round-trips through `lists:filter/2` and
// `Array.prototype.filter` directly.
pub fn split(path: string) -> string[] {
    val raw = path.split(separator);
    return raw.filter({ p -> p != "" });
}

// True when `path` starts with `/` — the posix absolute-path marker.
pub fn isAbsolute(path: string) -> bool {
    return path.startsWith(separator);
}

// The last non-empty component of `path` (the file name, in the common
// case). Returns "" for the empty path and for pure-separator paths.
pub fn basename(path: string) -> string {
    val parts = split(path);
    val n = parts.length;
    if (n == 0) return "";
    return parts.at(n - 1) ?? "";
}

// Everything except the basename — the parent directory portion. For an
// absolute path this preserves the leading `/`. For a path with no
// separator (`"foo"`), returns `""`.
pub fn dirname(path: string) -> string {
    val parts = split(path);
    val n = parts.length;
    if (n <= 1) return if (isAbsolute(path)) separator else "";
    val head = parts.slice(0, n - 1);
    val joined = head.join(separator);
    // String `+` lowers to numeric `+` on Erlang (badarith on binaries);
    // use a 2-element array `.join("")` to concat instead — that goes
    // through `lists:join("", …)` + `iolist_to_binary` on Erlang and
    // `Array.prototype.join("")` on Node, both string-safe.
    return if (isAbsolute(path)) [separator, joined].join("") else joined;
}

// The trailing extension on the basename — the substring from the LAST
// `.` to the end, including the dot. Returns `""` when the basename has
// no extension (or is a dotfile with no further `.`s, e.g. `.bashrc`).
pub fn extname(path: string) -> string {
    val base = basename(path);
    val pieces = base.split(".");
    val n = pieces.length;
    if (n <= 1) return "";
    val head = pieces.at(0) ?? "";
    val tail = pieces.at(n - 1) ?? "";
    // Dotfiles like ".bashrc" split into ["", "bashrc"] — no extension.
    val isDotfile = head == "" && n == 2;
    return if (isDotfile) "" else [".", tail].join("");
}

// Join a list of path segments with the separator. Leading separator on
// the first segment is preserved; intra-segment slashes are normalised
// (`"foo/" + "/bar"` joins to `"foo/bar"`, never `"foo//bar"`). Uses
// `map` + `filter` + `join` rather than `fold` / `flatMap`: those land
// on `array<T>` default-fn bodies that lower to a `var` + `push` shape,
// which lowers to a dead store on Erlang's immutable runtime (the same
// trap `split` sidesteps).
pub fn join(parts: string[]) -> string {
    val isAbs = if (parts.length == 0) false else isAbsolute(parts.at(0) ?? "");
    val collapsed = parts.map({ p -> split(p).join(separator) });
    val joined = collapsed.filter({ p -> p != "" }).join(separator);
    return if (isAbs) [separator, joined].join("") else joined;
}

// Collapse `//` and drop `.` segments via a `filter` over the split
// pieces. Full `..` pop semantics are deferred: they need a stack-shaped
// accumulator and `var` reassignment, which lowers to a dead store on
// Erlang's immutable runtime (the same trap `split`/`join` sidestep with
// `filter`/`flatMap`).
pub fn normalize(path: string) -> string {
    if (path == "") return ".";
    val isAbs = isAbsolute(path);
    val pieces = split(path).filter({ p -> p != "." });
    val joined = pieces.join(separator);
    return if (isAbs)
        [separator, joined].join("")
    else if (joined == "")
        "."
    else
        joined;
}

// Internal: count how many leading components two split paths share. Tail-
// recursive on `i` so the accumulator never needs a `var` rebind (which
// lowers to a dead store on Erlang's immutable runtime).
fn commonPrefixCount(a: string[], b: string[], i: i32) -> i32 {
    if (i >= a.length) return i;
    if (i >= b.length) return i;
    val ai = a.at(i) ?? "";
    val bi = b.at(i) ?? "";
    return if (ai == bi) commonPrefixCount(a, b, i + 1) else i;
}

// Internal: build an array of `n` ".." strings via head/tail recursion.
// Avoids a `var` + `push` accumulator (the Erlang dead-store trap).
fn makeUps(n: i32) -> string[] {
    return if (n <= 0) [] else makeUps(n - 1).prepend("..");
}

// The relative path from `src` to `dst` — the path you would prefix to
// `src` to reach `dst`. Both inputs are treated structurally (no `cwd()`
// fallback — that belongs in `process` once it lands). Returns "." when
// the paths point at the same location.
//
// `src` is named `src` rather than `from` because `from` is a reserved
// keyword (the `import { … } from "<lib>"` syntax) — it does not parse
// as a parameter name.
pub fn relative(src: string, dst: string) -> string {
    val srcParts = split(src);
    val dstParts = split(dst);
    val common = commonPrefixCount(srcParts, dstParts, 0);
    val ups = makeUps(srcParts.length - common);
    val downs = dstParts.slice(common, dstParts.length);
    val combined = ups.append(downs);
    val joined = combined.join(separator);
    return if (joined == "") "." else joined;
}

// Internal accumulator for `resolve`: a list of normalised path parts
// plus whether the resolved-so-far path is absolute. The record carries
// the state through the tail-recursive `resolveAll` so no `var` is
// needed.
type PathAccum(
    isAbs: bool,
    parts: string[],
)

// Internal: apply each component of one segment (post-split) to the
// accumulator, popping for `..` and appending the rest. Head/tail
// recursive — no `var` rebinds.
fn applyPieces(acc: string[], pieces: string[]) -> string[] {
    if (pieces.length == 0) return acc;
    val p = pieces.at(0) ?? "";
    val rest = pieces.slice(1, pieces.length);
    val nextAcc = if (p == "..") {
        if (acc.length == 0) acc else acc.slice(0, acc.length - 1);
    } else acc.append([p]);
    return applyPieces(nextAcc, rest);
}

fn resolveStep(state: PathAccum, seg: string) -> PathAccum {
    val pieces = split(seg);
    val nextIsAbs = isAbsolute(seg) || state.isAbs;
    val baseParts = if (isAbsolute(seg)) [] else state.parts;
    return PathAccum(isAbs: nextIsAbs, parts: applyPieces(baseParts, pieces));
}

fn resolveAll(segments: string[], i: i32, state: PathAccum) -> PathAccum {
    if (i >= segments.length) return state;
    val seg = segments.at(i) ?? "";
    val next = resolveStep(state, seg);
    return resolveAll(segments, i + 1, next);
}

// Resolve a list of path segments into a single normalised path.
// Absolute segments restart the accumulator (matches Node's
// `path.resolve`); `..` pops one component; `.` drops out (already
// filtered by `split`). The empty input resolves to ".".
pub fn resolve(segments: string[]) -> string {
    val finalState = resolveAll(
        segments,
        0,
        PathAccum(isAbs: false, parts: []),
    );
    val joined = finalState.parts.join(separator);
    return if (finalState.isAbs)
        [separator, joined].join("")
    else if (joined == "")
        "."
    else
        joined;
}

// ── 1.0.10-beta front 01 additions ───────────────────────────────────────────

// `p` without its trailing extension: `page.bp` → `page`, `archive.tar.gz`
// → `archive.tar`, `noext` → `noext`. The extension is what `extname`
// answers, so a dotfile keeps its name.
pub fn withoutExtension(p: string) -> string {
    val ext = extname(p);
    val n = p.length;
    val stem = if (ext == "") p else p.slice(0, n - ext.length);
    return stem;
}

// True when `child` resolves inside `parent` — the traversal guard front 22
// applies before it turns a request path into a file path. Both sides go
// through `resolve`, which pops `..` (`normalize` does not), and a relative
// `child` is resolved against `parent`, so `isInside("/app", "blog/x")` is
// true and `isInside("/app", "blog/../../etc")` is false. A parent is inside
// itself. The check reads the first component of the relative path: `..`
// exactly, or `../…` — a component that merely starts with two dots
// (`..foo`) is a name, not an escape.
pub fn isInside(parent: string, child: string) -> bool {
    val up = resolve([parent]);
    val down = resolve([parent, child]);
    val rel = relative(up, down);
    val escapes = rel == ".." || rel.startsWith("../");
    return escapes == false;
}

// ── tests ────────────────────────────────────────────────────────────────────

test "path.separator is forward slash" {
    assert separator == "/";
}

test "path.isAbsolute distinguishes leading slash" {
    assert isAbsolute("/usr/bin");
    assert isAbsolute("foo/bar").negate();
}

test "path.split drops empties" {
    val s = split("/usr//bin/");
    assert s.length == 2;
    assert s.at(0) ?? "" == "usr";
    assert s.at(1) ?? "" == "bin";
}

test "path.basename returns the last component" {
    assert basename("/usr/bin/zig") == "zig";
    assert basename("foo") == "foo";
    assert basename("") == "";
}

test "path.dirname returns the parent" {
    assert dirname("/usr/bin/zig") == "/usr/bin";
    assert dirname("foo/bar") == "foo";
    assert dirname("foo") == "";
    assert dirname("/foo") == "/";
}

test "path.extname returns the trailing suffix" {
    assert extname("file.txt") == ".txt";
    assert extname("archive.tar.gz") == ".gz";
    assert extname("README") == "";
    assert extname(".bashrc") == "";
}

test "path.join concatenates with separator" {
    assert join(["foo", "bar", "baz"]) == "foo/bar/baz";
    assert join(["/foo", "bar"]) == "/foo/bar";
    assert join(["foo/", "/bar"]) == "foo/bar";
}

test "path.normalize collapses doubles" {
    assert normalize("/foo//bar") == "/foo/bar";
    assert normalize("foo/./bar") == "foo/bar";
}

test "path.normalize on empty is dot" {
    assert normalize("") == ".";
}

test "path.relative same dir" {
    assert relative("/a/b/c", "/a/b/c") == ".";
}

test "path.relative up one" {
    assert relative("/a/b/c", "/a/b") == "..";
}

test "path.resolve absolute" {
    assert resolve(["/a", "b", "c"]) == "/a/b/c";
}

test "path.resolve with double-dot" {
    assert resolve(["/a", "b", "..", "c"]) == "/a/c";
}

test "path.withoutExtension strips the trailing extension only" {
    assert withoutExtension("page.bp") == "page";
    assert withoutExtension("archive.tar.gz") == "archive.tar";
    assert withoutExtension("noext") == "noext";
    assert withoutExtension(".bashrc") == ".bashrc";
    assert withoutExtension("app/blog/page.bp") == "app/blog/page";
}

test "path.isInside accepts a descendant and the parent itself" {
    assert isInside("/app", "/app/blog/page.bp");
    assert isInside("/app", "blog/page.bp");
    assert isInside("/app", "/app");
}

test "path.isInside rejects a path that escapes the parent" {
    assert isInside("/app", "/app/../etc/passwd").negate();
    assert isInside("/app", "/app/blog/../../etc").negate();
    assert isInside("/app", "/application/x").negate();
    assert isInside("/app", "/etc").negate();
}

test "path.isInside treats a name starting with two dots as a name" {
    assert isInside("/app", "/app/..hidden/x");
}

```

----- BEAM ASSEMBLY -- std/path.S
```erlang
{module, std@path}.
{exports, [{separator, 0}, {delimiter, 0}, {split, 1}, {isAbsolute, 1}, {basename, 1}, {dirname, 1}, {extname, 1}, {join, 1}, {normalize, 1}, {relative, 2}, {resolve, 1}, {withoutExtension, 1}, {isInside, 2}, {'__bp_priv__array_range', 2}, {'__bp_priv__array_repeat', 2}, {'__bp_priv__string_slice', 3}, {'__bp_priv__applyPieces', 2}, {'__bp_priv__commonPrefixCount', 3}, {'__bp_priv__makeUps', 1}, {'__bp_priv__resolveAll', 3}, {'__bp_priv__resolveStep', 2}]}.
{attributes, []}.
{labels, 284}.

{function, 'array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "std@path.erl", 1}]}.
    {func_info, {atom, std@path}, {atom, 'array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 42}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 43}}.
  {label, 42}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 44}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 45}}.
  {label, 44}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 47}}.
  {label, 45}.
  {label, 43}.
    {deallocate, 6}.
    return.

{function, 'array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "std@path.erl", 2}]}.
    {func_info, {atom, std@path}, {atom, 'array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 48}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 49}}.
  {label, 48}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 50}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 47}}.
    {jump, {f, 51}}.
  {label, 50}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 47}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 47}}.
  {label, 51}.
  {label, 49}.
    {deallocate, 6}.
    return.
%%% std/path — pure-botopink path manipulation (posix forward-slash).
%%% 
%%% Reference:
%%%   Node.js  — https://nodejs.org/api/path.html
%%%   Erlang   — https://www.erlang.org/doc/apps/stdlib/filename.html
%%% 
%%% Lib-self-contained: every operation composes `String` methods (`split`,
%%% `slice`, `length`, `startsWith`), so the module works on every backend
%%% including wat. Forward-slash separator only — Windows backslash paths
%%% are not normalised here (the spec keeps `path` posix-shaped; a
%%% `path_win32` sibling can land later if a target needs it).

{function, separator, 0, 7}.
  {label, 6}.
    {line, [{location, "std@path.erl", 3}]}.
    {func_info, {atom, std@path}, {atom, separator}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {literal, <<"/">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, delimiter, 0, 9}.
  {label, 8}.
    {line, [{location, "std@path.erl", 4}]}.
    {func_info, {atom, std@path}, {atom, delimiter}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {move, {literal, <<":">>}, {x, 0}}.
    {deallocate, 0}.
    return.
% Split a path into its non-empty components. Leading-`/` paths drop the
% empty head; trailing-`/` paths drop the empty tail. A path made of pure
% separators yields the empty array. Uses `filter` rather than
% `forEach` + `push`: a `var` + `push` pattern lowers to a dead-store
% (`out ++ [p]` discarded) on Erlang because the immutable runtime never
% rebinds `Out`; `filter` round-trips through `lists:filter/2` and
% `Array.prototype.filter` directly.

{function, split, 1, 11}.
  {label, 10}.
    {line, [{location, "std@path.erl", 5}]}.
    {func_info, {atom, std@path}, {atom, split}, 1}.
  {label, 11}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 53}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 70}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, filter, 2}, 4}.
% True when `path` starts with `/` — the posix absolute-path marker.

{function, isAbsolute, 1, 13}.
  {label, 12}.
    {line, [{location, "std@path.erl", 6}]}.
    {func_info, {atom, std@path}, {atom, isAbsolute}, 1}.
  {label, 13}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 73}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 74}}.
  {label, 73}.
    {move, {atom, true}, {x, 0}}.
  {label, 74}.
    {deallocate, 3}.
    return.
% The last non-empty component of `path` (the file name, in the common
% case). Returns "" for the empty path and for pure-separator paths.

{function, basename, 1, 15}.
  {label, 14}.
    {line, [{location, "std@path.erl", 7}]}.
    {func_info, {atom, std@path}, {atom, basename}, 1}.
  {label, 15}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_eq_exact, {f, 75}, [{y, 2}, {integer, 0}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 75}.
    {gc_bif, '-', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 77}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 77}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 78}}.
  {label, 77}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/path.bp:40:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 78}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 80}}.
    {test, is_ne_exact, {f, 76}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 83}}.
  {label, 76}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 83}.
    {deallocate, 4}.
    return.
% Everything except the basename — the parent directory portion. For an
% absolute path this preserves the leading `/`. For a path with no
% separator (`"foo"`), returns `""`.

{function, dirname, 1, 17}.
  {label, 16}.
    {line, [{location, "std@path.erl", 8}]}.
    {func_info, {atom, std@path}, {atom, dirname}, 1}.
  {label, 17}.
    {allocate, 10, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_ge, {f, 84}, [{integer, 1}, {y, 2}]}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 13}}.
    {test, is_eq, {f, 85}, [{x, 0}, {atom, true}]}.
    {call, 0, {f, 7}}.
    {jump, {f, 86}}.
  {label, 85}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 86}.
    {deallocate, 10}.
    return.
  {label, 84}.
    {gc_bif, '-', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 87}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 87}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 88}}.
  {label, 87}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/path.bp:50:33">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 88}.
    {test, is_ne_exact, {f, 89}, [{x, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 0}, {integer, 1}], {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {integer, 0}], {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 90}}.
  {label, 89}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 90}.
    {move, {x, 0}, {y, 3}}.
    {call, 0, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {call, 2, {f, 92}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 13}}.
    {test, is_eq, {f, 125}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {call, 0, {f, 7}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 92}}.
    {jump, {f, 126}}.
  {label, 125}.
    {move, {y, 4}, {x, 0}}.
  {label, 126}.
    {deallocate, 10}.
    return.
% The trailing extension on the basename — the substring from the LAST
% `.` to the end, including the dot. Returns `""` when the basename has
% no extension (or is a dotfile with no further `.`s, e.g. `.bashrc`).

{function, extname, 1, 19}.
  {label, 18}.
    {line, [{location, "std@path.erl", 9}]}.
    {func_info, {atom, std@path}, {atom, extname}, 1}.
  {label, 19}.
    {allocate, 10, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 15}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<".">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 53}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {test, is_ge, {f, 127}, [{integer, 1}, {y, 3}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 127}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 80}}.
    {test, is_ne_exact, {f, 128}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {jump, {f, 129}}.
  {label, 128}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 129}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 3}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 131}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 131}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 132}}.
  {label, 131}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/path.bp:68:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 132}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call, 2, {f, 80}}.
    {test, is_ne_exact, {f, 130}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {jump, {f, 133}}.
  {label, 130}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 133}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 134}, [{y, 5}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 135}}.
  {label, 134}.
    {move, {atom, false}, {x, 0}}.
  {label, 135}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 136}, [{x, 1}, {atom, true}]}.
    {test, is_eq_exact, {f, 138}, [{y, 3}, {integer, 2}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 139}}.
  {label, 138}.
    {move, {atom, false}, {x, 0}}.
  {label, 139}.
    {jump, {f, 137}}.
  {label, 136}.
    {move, {atom, false}, {x, 0}}.
  {label, 137}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq, {f, 140}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {jump, {f, 141}}.
  {label, 140}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 7}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, <<".">>}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 92}}.
  {label, 141}.
    {deallocate, 10}.
    return.
% Join a list of path segments with the separator. Leading separator on
% the first segment is preserved; intra-segment slashes are normalised
% (`"foo/" + "/bar"` joins to `"foo/bar"`, never `"foo//bar"`). Uses
% `map` + `filter` + `join` rather than `fold` / `flatMap`: those land
% on `array<T>` default-fn bodies that lower to a `var` + `push` shape,
% which lowers to a dead store on Erlang's immutable runtime (the same
% trap `split` sidesteps).

{function, join, 1, 21}.
  {label, 20}.
    {line, [{location, "std@path.erl", 10}]}.
    {func_info, {atom, std@path}, {atom, join}, 1}.
  {label, 21}.
    {allocate, 10, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 142}, [{x, 0}, {integer, 0}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 143}}.
  {label, 142}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 80}}.
    {test, is_ne_exact, {f, 144}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 145}}.
  {label, 144}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 145}.
    {call, 1, {f, 13}}.
  {label, 143}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 147}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 149}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {move, {x, 0}, {y, 4}}.
    {call, 0, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call, 2, {f, 92}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq, {f, 152}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {call, 0, {f, 7}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 92}}.
    {jump, {f, 153}}.
  {label, 152}.
    {move, {y, 5}, {x, 0}}.
  {label, 153}.
    {deallocate, 10}.
    return.
% Collapse `//` and drop `.` segments via a `filter` over the split
% pieces. Full `..` pop semantics are deferred: they need a stack-shaped
% accumulator and `var` reassignment, which lowers to a dead store on
% Erlang's immutable runtime (the same trap `split`/`join` sidestep with
% `filter`/`flatMap`).

{function, normalize, 1, 23}.
  {label, 22}.
    {line, [{location, "std@path.erl", 11}]}.
    {func_info, {atom, std@path}, {atom, normalize}, 1}.
  {label, 23}.
    {allocate, 11, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 154}, [{y, 0}, {x, 0}]}.
    {move, {literal, <<".">>}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 154}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 13}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 156}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {move, {x, 0}, {y, 2}}.
    {call, 0, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call, 2, {f, 92}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq, {f, 159}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {call, 0, {f, 7}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 92}}.
    {jump, {f, 160}}.
  {label, 159}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 161}, [{y, 3}, {x, 0}]}.
    {move, {literal, <<".">>}, {x, 0}}.
    {jump, {f, 162}}.
  {label, 161}.
    {move, {y, 3}, {x, 0}}.
  {label, 162}.
  {label, 160}.
    {deallocate, 11}.
    return.
% Internal: count how many leading components two split paths share. Tail-
% recursive on `i` so the accumulator never needs a `var` rebind (which
% lowers to a dead store on Erlang's immutable runtime).

{function, commonPrefixCount, 3, 25}.
  {label, 24}.
    {line, [{location, "std@path.erl", 12}]}.
    {func_info, {atom, std@path}, {atom, commonPrefixCount}, 3}.
  {label, 25}.
    {allocate, 7, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ge, {f, 163}, [{y, 2}, {x, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 163}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ge, {f, 164}, [{y, 2}, {x, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 164}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 80}}.
    {test, is_ne_exact, {f, 165}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 166}}.
  {label, 165}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 166}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 80}}.
    {test, is_ne_exact, {f, 167}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {jump, {f, 168}}.
  {label, 167}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 168}.
    {move, {x, 0}, {y, 6}}.
    {test, is_eq_exact, {f, 169}, [{y, 4}, {y, 6}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 171}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 171}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 172}}.
  {label, 171}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/path.bp:114:52">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 172}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 25}}.
    {jump, {f, 170}}.
  {label, 169}.
    {move, {y, 2}, {x, 0}}.
  {label, 170}.
    {deallocate, 7}.
    return.
% Internal: build an array of `n` ".." strings via head/tail recursion.
% Avoids a `var` + `push` accumulator (the Erlang dead-store trap).

{function, makeUps, 1, 27}.
  {label, 26}.
    {line, [{location, "std@path.erl", 13}]}.
    {func_info, {atom, std@path}, {atom, makeUps}, 1}.
  {label, 27}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_ge, {f, 173}, [{integer, 0}, {y, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 174}}.
  {label, 173}.
    {gc_bif, '-', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 175}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 175}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 176}}.
  {label, 175}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/path.bp:120:42">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 176}.
    {call, 1, {f, 27}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"..">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
  {label, 174}.
    {deallocate, 3}.
    return.
% The relative path from `src` to `dst` — the path you would prefix to
% `src` to reach `dst`. Both inputs are treated structurally (no `cwd()`
% fallback — that belongs in `process` once it lands). Returns "." when
% the paths point at the same location.
% 
% `src` is named `src` rather than `from` because `from` is a reserved
% keyword (the `import { … } from "<lib>"` syntax) — it does not parse
% as a parameter name.

{function, relative, 2, 29}.
  {label, 28}.
    {line, [{location, "std@path.erl", 14}]}.
    {func_info, {atom, std@path}, {atom, relative}, 2}.
  {label, 29}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 0}, {x, 2}}.
    {move, {y, 3}, {x, 1}}.
    {call, 3, {f, 25}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 2}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {y, 4}], {x, 0}}.
    {test, is_ge, {f, 177}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 177}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 178}}.
  {label, 177}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/path.bp:135:39">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 178}.
    {call, 1, {f, 27}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ne_exact, {f, 179}, [{x, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 1, [{y, 4}, {integer, 1}], {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {y, 4}], {x, 2}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 180}}.
  {label, 179}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 180}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 7}}.
    {call, 0, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 7}, {x, 0}}.
    {call, 2, {f, 92}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 181}, [{y, 8}, {x, 0}]}.
    {move, {literal, <<".">>}, {x, 0}}.
    {jump, {f, 182}}.
  {label, 181}.
    {move, {y, 8}, {x, 0}}.
  {label, 182}.
    {deallocate, 11}.
    return.
% Internal accumulator for `resolve`: a list of normalised path parts
% plus whether the resolved-so-far path is absolute. The record carries
% the state through the tail-recursive `resolveAll` so no `var` is
% needed.
% Internal: apply each component of one segment (post-split) to the
% accumulator, popping for `..` and appending the rest. Head/tail
% recursive — no `var` rebinds.

{function, applyPieces, 2, 31}.
  {label, 30}.
    {line, [{location, "std@path.erl", 15}]}.
    {func_info, {atom, std@path}, {atom, applyPieces}, 2}.
  {label, 31}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 183}, [{x, 0}, {integer, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 183}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 80}}.
    {test, is_ne_exact, {f, 184}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 185}}.
  {label, 184}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 185}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ne_exact, {f, 186}, [{x, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 1}, {integer, 1}], {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {integer, 1}], {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 187}}.
  {label, 186}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 187}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"..">>}, {x, 0}}.
    {test, is_eq_exact, {f, 188}, [{y, 3}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 190}, [{x, 0}, {integer, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {jump, {f, 191}}.
  {label, 190}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 192}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 192}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 193}}.
  {label, 192}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/path.bp:159:63">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 193}.
    {test, is_ne_exact, {f, 194}, [{x, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 0}, {integer, 1}], {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {integer, 0}], {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 195}}.
  {label, 194}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 195}.
  {label, 191}.
    {jump, {f, 189}}.
  {label, 188}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
  {label, 189}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_last, 2, {f, 31}, 7}.

{function, resolveStep, 2, 33}.
  {label, 32}.
    {line, [{location, "std@path.erl", 16}]}.
    {func_info, {atom, std@path}, {atom, resolveStep}, 2}.
  {label, 33}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 13}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 196}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 198}, [{x, 0}, 3, {atom, std@path@@PathAccum}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 198}.
    {jump, {f, 197}}.
  {label, 196}.
    {move, {atom, true}, {x, 0}}.
  {label, 197}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 13}}.
    {test, is_eq, {f, 199}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 200}}.
  {label, 199}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 201}, [{x, 0}, 3, {atom, std@path@@PathAccum}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 201}.
  {label, 200}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 31}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@path@@PathAccum}, {y, 3}, {x, 0}]}}.
    {deallocate, 7}.
    return.

{function, resolveAll, 3, 35}.
  {label, 34}.
    {line, [{location, "std@path.erl", 17}]}.
    {func_info, {atom, std@path}, {atom, resolveAll}, 3}.
  {label, 35}.
    {allocate, 6, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ge, {f, 202}, [{y, 1}, {x, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 202}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 80}}.
    {test, is_ne_exact, {f, 203}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 204}}.
  {label, 203}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 204}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call, 2, {f, 33}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 205}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 205}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 206}}.
  {label, 205}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/path.bp:175:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 206}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 3, {f, 35}, 6}.
% Resolve a list of path segments into a single normalised path.
% Absolute segments restart the accumulator (matches Node's
% `path.resolve`); `..` pops one component; `.` drops out (already
% filtered by `split`). The empty input resolves to ".".

{function, resolve, 1, 37}.
  {label, 36}.
    {line, [{location, "std@path.erl", 18}]}.
    {func_info, {atom, std@path}, {atom, resolve}, 1}.
  {label, 37}.
    {allocate, 11, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@path@@PathAccum}, {x, 1}, {x, 0}]}}.
    {move, {integer, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 35}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 207}, [{x, 0}, 3, {atom, std@path@@PathAccum}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 207}.
    {move, {x, 0}, {y, 2}}.
    {call, 0, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call, 2, {f, 92}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 209}, [{x, 0}, 3, {atom, std@path@@PathAccum}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 209}.
    {test, is_eq, {f, 208}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {call, 0, {f, 7}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 92}}.
    {jump, {f, 210}}.
  {label, 208}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 211}, [{y, 3}, {x, 0}]}.
    {move, {literal, <<".">>}, {x, 0}}.
    {jump, {f, 212}}.
  {label, 211}.
    {move, {y, 3}, {x, 0}}.
  {label, 212}.
  {label, 210}.
    {deallocate, 11}.
    return.
% ── 1.0.10-beta front 01 additions ───────────────────────────────────────────
% `p` without its trailing extension: `page.bp` → `page`, `archive.tar.gz`
% → `archive.tar`, `noext` → `noext`. The extension is what `extname`
% answers, so a dotfile keeps its name.

{function, withoutExtension, 1, 39}.
  {label, 38}.
    {line, [{location, "std@path.erl", 19}]}.
    {func_info, {atom, std@path}, {atom, withoutExtension}, 1}.
  {label, 39}.
    {allocate, 9, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 19}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 213}, [{y, 1}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {jump, {f, 214}}.
  {label, 213}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 2}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 217}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 217}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 218}}.
  {label, 217}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/path.bp:205:51">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 218}.
    {move, {integer, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 216}}.
  {label, 214}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 9}.
    return.
% True when `child` resolves inside `parent` — the traversal guard front 22
% applies before it turns a request path into a file path. Both sides go
% through `resolve`, which pops `..` (`normalize` does not), and a relative
% `child` is resolved against `parent`, so `isInside("/app", "blog/x")` is
% true and `isInside("/app", "blog/../../etc")` is false. A parent is inside
% itself. The check reads the first component of the relative path: `..`
% exactly, or `../…` — a component that merely starts with two dots
% (`..foo`) is a name, not an escape.

{function, isInside, 2, 41}.
  {label, 40}.
    {line, [{location, "std@path.erl", 20}]}.
    {func_info, {atom, std@path}, {atom, isInside}, 2}.
  {label, 41}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 37}}.
    {move, {x, 0}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 37}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 29}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"..">>}, {x, 0}}.
    {test, is_eq_exact, {f, 219}, [{y, 6}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 220}}.
  {label, 219}.
    {move, {atom, false}, {x, 0}}.
  {label, 220}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 221}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"../">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 223}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 224}}.
  {label, 223}.
    {move, {atom, true}, {x, 0}}.
  {label, 224}.
    {jump, {f, 222}}.
  {label, 221}.
    {move, {atom, true}, {x, 0}}.
  {label, 222}.
    {move, {x, 0}, {y, 7}}.
    {move, {atom, false}, {x, 0}}.
    {test, is_eq_exact, {f, 225}, [{y, 7}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 226}}.
  {label, 225}.
    {move, {atom, false}, {x, 0}}.
  {label, 226}.
    {deallocate, 10}.
    return.
% ── tests ────────────────────────────────────────────────────────────────────

{function, 'string_slice', 3, 216}.
  {label, 215}.
    {line, [{location, "std@path.erl", 21}]}.
    {func_info, {atom, std@path}, {atom, 'string_slice'}, 3}.
  {label, 216}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_ne_exact, {f, 227}, [{y, 2}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 229}, 3}.
  {label, 227}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 251}, 3}.

{function, '__bp_priv__array_range', 2, 269}.
  {label, 268}.
    {line, [{location, "std@path.erl", 23}]}.
    {func_info, {atom, std@path}, {atom, '__bp_priv__array_range'}, 2}.
  {label, 269}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__array_repeat', 2, 271}.
  {label, 270}.
    {line, [{location, "std@path.erl", 24}]}.
    {func_info, {atom, std@path}, {atom, '__bp_priv__array_repeat'}, 2}.
  {label, 271}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__string_slice', 3, 273}.
  {label, 272}.
    {line, [{location, "std@path.erl", 25}]}.
    {func_info, {atom, std@path}, {atom, '__bp_priv__string_slice'}, 3}.
  {label, 273}.
    {call_only, 3, {f, 216}}.

{function, '__bp_priv__applyPieces', 2, 275}.
  {label, 274}.
    {line, [{location, "std@path.erl", 26}]}.
    {func_info, {atom, std@path}, {atom, '__bp_priv__applyPieces'}, 2}.
  {label, 275}.
    {call_only, 2, {f, 31}}.

{function, '__bp_priv__commonPrefixCount', 3, 277}.
  {label, 276}.
    {line, [{location, "std@path.erl", 27}]}.
    {func_info, {atom, std@path}, {atom, '__bp_priv__commonPrefixCount'}, 3}.
  {label, 277}.
    {call_only, 3, {f, 25}}.

{function, '__bp_priv__makeUps', 1, 279}.
  {label, 278}.
    {line, [{location, "std@path.erl", 28}]}.
    {func_info, {atom, std@path}, {atom, '__bp_priv__makeUps'}, 1}.
  {label, 279}.
    {call_only, 1, {f, 27}}.

{function, '__bp_priv__resolveAll', 3, 281}.
  {label, 280}.
    {line, [{location, "std@path.erl", 29}]}.
    {func_info, {atom, std@path}, {atom, '__bp_priv__resolveAll'}, 3}.
  {label, 281}.
    {call_only, 3, {f, 35}}.

{function, '__bp_priv__resolveStep', 2, 283}.
  {label, 282}.
    {line, [{location, "std@path.erl", 30}]}.
    {func_info, {atom, std@path}, {atom, '__bp_priv__resolveStep'}, 2}.
  {label, 283}.
    {call_only, 2, {f, 33}}.

{function, '__bp_tpl_0-t/2-fun-0-', 2, 57}.
  {label, 56}.
    {func_info, {atom, std@path}, {atom, '__bp_tpl_0-t/2-fun-0-'}, 2}.
  {label, 57}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 59}, [{x, 0}, {literal, <<"">>}]}.
    {move, nil, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {test, is_list, {f, 61}, [{x, 0}]}.
    {jump, {f, 62}}.
  {label, 61}.
    {test, is_tuple, {f, 63}, [{x, 0}]}.
    {test, test_arity, {f, 63}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 62}}.
  {label, 63}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 1}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 62}.
    {move, {x, 0}, {y, 4}}.
  {label, 64}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 65}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 4}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 67}, [{x, 0}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {test, is_binary, {f, 67}, [{x, 0}]}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 68}}.
  {label, 67}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 68}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 64}}.
  {label, 65}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nil, {f, 66}, [{x, 0}]}.
    {jump, {f, 60}}.
  {label, 66}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 60}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 59}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {atom, all}, {x, 2}}.
    {call_ext_last, 3, {extfunc, string, split, 3}, 7}.

{function, '__bp_tpl_0', 2, 53}.
  {label, 52}.
    {func_info, {atom, std@path}, {atom, '__bp_tpl_0'}, 2}.
  {label, 53}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 57}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-split/1-fun-0-', 1, 70}.
  {label, 69}.
    {line, [{location, "std@path.erl", 6}]}.
    {func_info, {atom, std@path}, {atom, '-split/1-fun-0-'}, 1}.
  {label, 70}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 71}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 72}}.
  {label, 71}.
    {move, {atom, false}, {x, 0}}.
  {label, 72}.
    {deallocate, 1}.
    return.

{function, '-bp_at-', 2, 80}.
  {label, 79}.
    {line, [{location, "std@path.erl", 8}]}.
    {func_info, {atom, std@path}, {atom, '-bp_at-'}, 2}.
  {label, 80}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 82}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 81}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 82}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 81}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 81}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_print', 1, 94}.
  {label, 93}.
    {line, [{location, "std@path.erl", 9}]}.
    {func_info, {atom, std@path}, {atom, '__bp_print'}, 1}.
  {label, 94}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 98}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 98}.
  {label, 97}.
    {line, [{location, "std@path.erl", 9}]}.
    {func_info, {atom, std@path}, {atom, '-bp_show_top-'}, 1}.
  {label, 98}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 96}}.

{function, '-bp_show_elem-', 1, 100}.
  {label, 99}.
    {line, [{location, "std@path.erl", 9}]}.
    {func_info, {atom, std@path}, {atom, '-bp_show_elem-'}, 1}.
  {label, 100}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 96}}.

{function, '__bp_show', 2, 96}.
  {label, 95}.
    {line, [{location, "std@path.erl", 9}]}.
    {func_info, {atom, std@path}, {atom, '__bp_show'}, 2}.
  {label, 96}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 108}, [{x, 0}]}.
    {test, is_eq, {f, 107}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 107}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 108}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 109}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 100}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 93}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 91}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 109}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 111}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 110}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 110}, [{x, 0}]}.
    {test, is_ne_exact, {f, 110}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 110}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 110}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 115}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 116}}.
  {label, 115}.
    {test, is_eq_exact, {f, 112}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 116}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 96}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 110}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 100}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 40}, {x, 0}, {x, 0}}.
    {put_list, {integer, 35}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 111}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 113}, [{x, 0}]}.
    {test, is_ne_exact, {f, 113}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 113}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 114}, [{x, 0}, {atom, undefined}]}.
  {label, 112}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 102}, 2}.
  {label, 113}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 114}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 102}.
  {label, 101}.
    {line, [{location, "std@path.erl", 9}]}.
    {func_info, {atom, std@path}, {atom, '__bp_tagged'}, 2}.
  {label, 102}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 117}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 117}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 117}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 118}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 104}, 3}.
  {label, 118}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 104}.
  {label, 103}.
    {line, [{location, "std@path.erl", 9}]}.
    {func_info, {atom, std@path}, {atom, '__bp_render'}, 1}.
  {label, 104}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 119}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 119}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 120}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 120}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 106}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {y, 1}, {x, 1}, {x, 1}}.
    {put_list, {integer, 40}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_render_pair-', 1, 106}.
  {label, 105}.
    {line, [{location, "std@path.erl", 9}]}.
    {func_info, {atom, std@path}, {atom, '-bp_render_pair-'}, 1}.
  {label, 106}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 96}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 6, 1}.
    {put_list, {y, 1}, nil, {x, 1}}.
    {put_list, {literal, <<": ">>}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_stringify-', 1, 122}.
  {label, 121}.
    {line, [{location, "std@path.erl", 9}]}.
    {func_info, {atom, std@path}, {atom, '-bp_stringify-'}, 1}.
  {label, 122}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 123}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 123}.
    {test, is_integer, {f, 124}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 124}.
    {call, 1, {f, 98}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '-bp_join-', 2, 92}.
  {label, 91}.
    {line, [{location, "std@path.erl", 9}]}.
    {func_info, {atom, std@path}, {atom, '-bp_join-'}, 2}.
  {label, 92}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 122}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 1}.

{function, '-join/1-fun-1-', 1, 147}.
  {label, 146}.
    {line, [{location, "std@path.erl", 11}]}.
    {func_info, {atom, std@path}, {atom, '-join/1-fun-1-'}, 1}.
  {label, 147}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {x, 0}, {y, 1}}.
    {call, 0, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 92}}.
    {deallocate, 3}.
    return.

{function, '-join/1-fun-2-', 1, 149}.
  {label, 148}.
    {line, [{location, "std@path.erl", 11}]}.
    {func_info, {atom, std@path}, {atom, '-join/1-fun-2-'}, 1}.
  {label, 149}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 150}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 151}}.
  {label, 150}.
    {move, {atom, false}, {x, 0}}.
  {label, 151}.
    {deallocate, 1}.
    return.

{function, '-normalize/1-fun-3-', 1, 156}.
  {label, 155}.
    {line, [{location, "std@path.erl", 12}]}.
    {func_info, {atom, std@path}, {atom, '-normalize/1-fun-3-'}, 1}.
  {label, 156}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<".">>}, {x, 0}}.
    {test, is_ne_exact, {f, 157}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 158}}.
  {label, 157}.
    {move, {atom, false}, {x, 0}}.
  {label, 158}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_1-t/3-fun-0-', 3, 233}.
  {label, 232}.
    {func_info, {atom, std@path}, {atom, '__bp_tpl_1-t/3-fun-0-'}, 3}.
  {label, 233}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 237}}.
  {label, 237}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 1}}.
    {jump, {f, 239}}.
  {label, 239}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 241}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 240}}.
  {label, 241}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 242}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 240}}.
  {label, 242}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 240}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 244}}.
  {label, 244}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 246}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 245}}.
  {label, 246}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 247}, [{x, 0}, {atom, false}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 245}}.
  {label, 247}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 245}.
    {move, {y, 7}, {y, 1}}.
    {jump, {f, 249}}.
  {label, 249}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 7}, {x, 2}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 9}.

{function, '__bp_tpl_1', 3, 229}.
  {label, 228}.
    {func_info, {atom, std@path}, {atom, '__bp_tpl_1'}, 3}.
  {label, 229}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 233}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_2-t/2-fun-0-', 2, 255}.
  {label, 254}.
    {func_info, {atom, std@path}, {atom, '__bp_tpl_2-t/2-fun-0-'}, 2}.
  {label, 255}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 259}}.
  {label, 259}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 261}}.
  {label, 261}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 263}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 262}}.
  {label, 263}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 264}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 262}}.
  {label, 264}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 262}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 266}}.
  {label, 266}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 7}.

{function, '__bp_tpl_2', 2, 251}.
  {label, 250}.
    {func_info, {atom, std@path}, {atom, '__bp_tpl_2'}, 2}.
  {label, 251}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 255}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_prim_append', 2, 47}.
  {label, 46}.
    {line, [{location, "std@path.erl", 22}]}.
    {func_info, {atom, std@path}, {atom, '__bp_prim_append'}, 2}.
  {label, 47}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 267}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 267}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@path@@PathAccum.S
```erlang
{module, std@path@@PathAccum}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 8}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "std@path@@PathAccum.erl", 15}]}.
    {func_info, {atom, std@path@@PathAccum}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, isAbs}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {test, is_eq_exact, {f, 5}, [{x, 1}, {atom, parts}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 5}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 7}.
  {label, 6}.
    {line, [{location, "std@path@@PathAccum.erl", 15}]}.
    {func_info, {atom, std@path@@PathAccum}, {atom, '__bp_format'}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"parts">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"isAbs">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"PathAccum">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- std/failure.bp
```botopink
//// std/failure — the two records a failure that is not a typed error carries
//// (decisions 431, 492).
////
//// `HostError` is what a host binding that writes `result: true` answers on
//// the `Error` side: the host's message and `kind`, always `"host"`.
//// `Failure` is what `attempt` answers on the `Error` side: `kind` is `panic`
//// (`panic`, `@todo`, `x!`, an overflow, a division by zero), `host` (a raise
//// from a binding without `result: true`) or `crash` (a VM or emitted-code
//// fault, a wasm trap).
////
//// `attempt(f)` runs `f` and answers `Ok` of its value, or `Error(Failure)`
//// for a raise it caught — the one way to contain a crash (decision 431 (3)).
//// `attemptTask(f)` is its `Async` form (decision 494): the task `f` answers,
//// awaited, or the `Failure` it crashed with — a `Async<Result<…>>` read
//// back by `await` like any failing task (decision 432). The kinds
//// (decision 492): a `panic` / `@todo` (and so `x!`), a failed `assert`
//// and an integer overflow or division by zero are `panic`, their message
//// the text the program wrote. A raise of a binding declared outside std without
//// `result: true` is `host` (decision 546), its message the host's text — on
//// commonJS an `Error`'s `message`, else `String(e)`, the call run through
//// `__bp_host_mark`, which marks it `__bp_host`; any raise nothing marked is
//// `crash`, its message the same text. On erlang and beam a
//// host raise is the raise of a binding declared outside std without `result:
//// true` — a library's or the program's, whose calls are wrapped to mark it
//// (decision 546) — its message the reason by `~tp` (decision 489's reading);
//// a raise nothing marked, a failing match or a std binding's, is `crash`,
//// its message the reason by `~tp` too.
////
//// Both are bodyless: each backend wraps the call (a JavaScript `try` /
//// rejection handler, an erlang `try … catch`; beam compiles the erlang
//// form). On wasm (decision 518) each is a private body over `caught`, the
//// `wasi: .Attempt` adapter: the thunk runs inside a `try_table` that
//// catches the program's aborts (wasm exception handling), so the binding
//// declares `needs: [.Exceptions]` and a program reaching it runs with the
//// host's exceptions on (`-W exceptions=y` on wasmtime). On wasm an abort
//// is `panic`; a trap (an overflow or a division by zero there, a host
//// fault) is no exception and is not caught. `attemptTask` contains what
//// the thunk raises before the task's first `await`.

import {compiler};

pub type HostErrorName {
    Error,
    Throw,
    Exit,
}

pub type HostError(message: string, kind: string, name: HostErrorName, detail: ?string)

pub type Failure(message: string, kind: string)

// Decision 606 (2) — the abort `attempt` catches as a `panic` `Failure`: the program stops
// with `panic: <message>` (decision 535) unless an `attempt` above it answers the `Failure`.
// Imported where it is used, `import {failure.panic} from "std";` (`import {failure.panic};`
// inside std); `panic("not implemented")` is what `todo` was.
#[compiler.external(
    .Erlang("erlang:error({panic, $0})"),
    .JavaScript("(() => { throw Object.defineProperty(new Error($0), '__bp_panic', { value: true }) })()"),
)]
pub declare fn panic(message: string = "panic") -> noreturn;

// The Node forms read an abort by the `__bp_panic` mark the backend puts on
// every one it raises — `panic`, `@todo`, an integer overflow or division
// by zero, a failed `assert` (whose mark carries its message) — or a test
// body's `assert` (`__bp_assert_loc`); the Erlang forms by the reasons the
// backends raise for them (`{panic, M}`, `{todo, M}`, `{integer_overflow,
// M}`, `{bp_assert, M, Where}`). `attemptTask` answers a failing task
// (decision 432): marked `__bp_fails`, resolved with the value, rejected with
// the `Failure` (`__bp_failure`); a failing task `f` answers is read as
// `await` reads it.
#[compiler.external(
    .JavaScript("""((__f, __k) => { try { return { ok: __f() }; } catch (__e) { return { error: __k(__e) }; } })($0, ((__e) => (__e != null && __e.__bp_panic != null) ? new Failure(typeof __e.__bp_panic === "string" ? __e.__bp_panic : __e.message, "panic") : (__e != null && typeof __e.__bp_assert_loc === "string") ? new Failure(__e.message, "panic") : new Failure((__e instanceof Error) ? __e.message : String(__e), (__e != null && __e.__bp_host === true) ? "host" : "crash")))"""),
    .Erlang("""(fun(__F) -> try {ok, __F()} catch error:{__T, __M} when (__T =:= panic orelse __T =:= todo orelse __T =:= integer_overflow) andalso (is_binary(__M) orelse is_list(__M)) -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, _, _, __M} -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, __M, _} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"panic">>}}; error:{bp_host, __M} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"host">>}}; _:__R -> {error, {'std@failure@@Failure', unicode:characters_to_binary(io_lib:format("~tp", [__R])), <<"crash">>}} end end)($0)"""),
    .Wasm(body: attemptOnWasm),
)]
pub declare fn attempt<T>(f: fn() -> T) -> Result<T, Failure>;

#[compiler.external(
    .JavaScript("""((__f, __k) => { const __t = (async () => { const __x = __f(); return (__x != null && __x.__bp_fails === true) ? await __x.then((__v) => ({ ok: __v }), (__e) => { if (__x.__bp_failure === true) { return { error: __e }; } throw __e; }) : await __x; })().then((__v) => __v, (__e) => { __t.__bp_failure = true; throw __k(__e); }); __t.__bp_fails = true; __t.catch(() => {}); return __t; })($0, ((__e) => (__e != null && __e.__bp_panic != null) ? new Failure(typeof __e.__bp_panic === "string" ? __e.__bp_panic : __e.message, "panic") : (__e != null && typeof __e.__bp_assert_loc === "string") ? new Failure(__e.message, "panic") : new Failure((__e instanceof Error) ? __e.message : String(__e), (__e != null && __e.__bp_host === true) ? "host" : "crash")))"""),
    .Erlang("""(fun(__F) -> try {ok, __F()} catch error:{__T, __M} when (__T =:= panic orelse __T =:= todo orelse __T =:= integer_overflow) andalso (is_binary(__M) orelse is_list(__M)) -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, _, _, __M} -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, __M, _} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"panic">>}}; error:{bp_host, __M} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"host">>}}; _:__R -> {error, {'std@failure@@Failure', unicode:characters_to_binary(io_lib:format("~tp", [__R])), <<"crash">>}} end end)($0)"""),
    .Wasm(body: attemptTaskOnWasm),
)]
pub declare fn attemptTask<T>(f: fn() -> Async<T>) -> Async<Result<T, Failure>>;

// wasm's form (decision 518): the thunk's value, or the message of the abort
// it raised — `Error` of the abort's text, which `attempt` makes a `panic`.
// The bodies over it are compiled on every target, so it has a form on each;
// only wasm calls it (`attempt`'s own forms answer elsewhere).
#[compiler.external(
    .JavaScript("""((__f) => { try { return { ok: __f() }; } catch (__e) { return { error: (__e instanceof Error) ? __e.message : String(__e) }; } })($0)"""),
    .Erlang("""(fun(__F) -> try {ok, __F()} catch _:__R -> {error, unicode:characters_to_binary(io_lib:format("~tp", [__R]))} end end)($0)"""),
    .Wasm(wasi: .Attempt, needs: [.Exceptions]),
)]
declare fn caught<T>(f: fn() -> T) -> Result<T, string>;

fn attemptOnWasm<T>(f: fn() -> T) -> Result<T, Failure> {
    case caught(f) {
        Ok(v) -> return v;
        Error(m) -> throw Failure(message: m, kind: "panic");
    }
}

// The task the thunk started — or the `Failure` it raised before its first
// `await` — and then its value.
async fn attemptTaskOnWasm<T>(f: fn() -> Async<T>) -> Async<Result<T, Failure>> {
    case caught(f) {
        Ok(t) -> return await t;
        Error(m) -> throw Failure(message: m, kind: "panic");
    }
}

```

----- BEAM ASSEMBLY -- std/failure.S
```erlang
{module, std@failure}.
{exports, [{panic, 1}, {attempt, 1}, {attemptTask, 1}, {'__bp_priv__attemptOnWasm', 1}, {'__bp_priv__attemptTaskOnWasm', 1}]}.
{attributes, []}.
{labels, 59}.
%%% std/failure — the two records a failure that is not a typed error carries
%%% (decisions 431, 492).
%%% 
%%% `HostError` is what a host binding that writes `result: true` answers on
%%% the `Error` side: the host's message and `kind`, always `"host"`.
%%% `Failure` is what `attempt` answers on the `Error` side: `kind` is `panic`
%%% (`panic`, `@todo`, `x!`, an overflow, a division by zero), `host` (a raise
%%% from a binding without `result: true`) or `crash` (a VM or emitted-code
%%% fault, a wasm trap).
%%% 
%%% `attempt(f)` runs `f` and answers `Ok` of its value, or `Error(Failure)`
%%% for a raise it caught — the one way to contain a crash (decision 431 (3)).
%%% `attemptTask(f)` is its `Async` form (decision 494): the task `f` answers,
%%% awaited, or the `Failure` it crashed with — a `Async<Result<…>>` read
%%% back by `await` like any failing task (decision 432). The kinds
%%% (decision 492): a `panic` / `@todo` (and so `x!`), a failed `assert`
%%% and an integer overflow or division by zero are `panic`, their message
%%% the text the program wrote. A raise of a binding declared outside std without
%%% `result: true` is `host` (decision 546), its message the host's text — on
%%% commonJS an `Error`'s `message`, else `String(e)`, the call run through
%%% `__bp_host_mark`, which marks it `__bp_host`; any raise nothing marked is
%%% `crash`, its message the same text. On erlang and beam a
%%% host raise is the raise of a binding declared outside std without `result:
%%% true` — a library's or the program's, whose calls are wrapped to mark it
%%% (decision 546) — its message the reason by `~tp` (decision 489's reading);
%%% a raise nothing marked, a failing match or a std binding's, is `crash`,
%%% its message the reason by `~tp` too.
%%% 
%%% Both are bodyless: each backend wraps the call (a JavaScript `try` /
%%% rejection handler, an erlang `try … catch`; beam compiles the erlang
%%% form). On wasm (decision 518) each is a private body over `caught`, the
%%% `wasi: .Attempt` adapter: the thunk runs inside a `try_table` that
%%% catches the program's aborts (wasm exception handling), so the binding
%%% declares `needs: [.Exceptions]` and a program reaching it runs with the
%%% host's exceptions on (`-W exceptions=y` on wasmtime). On wasm an abort
%%% is `panic`; a trap (an overflow or a division by zero there, a host
%%% fault) is no exception and is not caught. `attemptTask` contains what
%%% the thunk raises before the task's first `await`.
% Decision 606 (2) — the abort `attempt` catches as a `panic` `Failure`: the program stops
% with `panic: <message>` (decision 535) unless an `attempt` above it answers the `Failure`.
% Imported where it is used, `import {failure.panic} from "std";` (`import {failure.panic};`
% inside std); `panic("not implemented")` is what `todo` was.

{function, panic, 1, 9}.
  {label, 8}.
    {line, [{location, "std@failure.erl", 1}]}.
    {func_info, {atom, std@failure}, {atom, panic}, 1}.
  {label, 9}.
    {call_only, 1, {f, 7}}.
% The Node forms read an abort by the `__bp_panic` mark the backend puts on
% every one it raises — `panic`, `@todo`, an integer overflow or division
% by zero, a failed `assert` (whose mark carries its message) — or a test
% body's `assert` (`__bp_assert_loc`); the Erlang forms by the reasons the
% backends raise for them (`{panic, M}`, `{todo, M}`, `{integer_overflow,
% M}`, `{bp_assert, M, Where}`). `attemptTask` answers a failing task
% (decision 432): marked `__bp_fails`, resolved with the value, rejected with
% the `Failure` (`__bp_failure`); a failing task `f` answers is read as
% `await` reads it.

{function, attempt, 1, 35}.
  {label, 34}.
    {line, [{location, "std@failure.erl", 2}]}.
    {func_info, {atom, std@failure}, {atom, attempt}, 1}.
  {label, 35}.
    {call_only, 1, {f, 11}}.

{function, attemptTask, 1, 37}.
  {label, 36}.
    {line, [{location, "std@failure.erl", 3}]}.
    {func_info, {atom, std@failure}, {atom, attemptTask}, 1}.
  {label, 37}.
    {call_only, 1, {f, 11}}.
% wasm's form (decision 518): the thunk's value, or the message of the abort
% it raised — `Error` of the abort's text, which `attempt` makes a `panic`.
% The bodies over it are compiled on every target, so it has a form on each;
% only wasm calls it (`attempt`'s own forms answer elsewhere).

{function, attemptOnWasm, 1, 3}.
  {label, 2}.
    {line, [{location, "std@failure.erl", 4}]}.
    {func_info, {atom, std@failure}, {atom, attemptOnWasm}, 1}.
  {label, 3}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 39}}.
    {test, is_tagged_tuple, {f, 50}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.
    {jump, {f, 49}}.
  {label, 50}.
    {test, is_tagged_tuple, {f, 51}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {literal, <<"panic">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@Failure}, {y, 2}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 3}.
    return.
    {jump, {f, 49}}.
  {label, 51}.
    {case_end, {x, 0}}.
  {label, 49}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.
% The task the thunk started — or the `Failure` it raised before its first
% `await` — and then its value.

%% @Async — eager lowering
{function, attemptTaskOnWasm, 1, 5}.
  {label, 4}.
    {line, [{location, "std@failure.erl", 5}]}.
    {func_info, {atom, std@failure}, {atom, attemptTaskOnWasm}, 1}.
  {label, 5}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 39}}.
    {test, is_tagged_tuple, {f, 53}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.
    {jump, {f, 52}}.
  {label, 53}.
    {test, is_tagged_tuple, {f, 54}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {literal, <<"panic">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@Failure}, {y, 2}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 3}.
    return.
    {jump, {f, 52}}.
  {label, 54}.
    {case_end, {x, 0}}.
  {label, 52}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_priv__attemptOnWasm', 1, 56}.
  {label, 55}.
    {line, [{location, "std@failure.erl", 6}]}.
    {func_info, {atom, std@failure}, {atom, '__bp_priv__attemptOnWasm'}, 1}.
  {label, 56}.
    {call_only, 1, {f, 3}}.

{function, '__bp_priv__attemptTaskOnWasm', 1, 58}.
  {label, 57}.
    {line, [{location, "std@failure.erl", 7}]}.
    {func_info, {atom, std@failure}, {atom, '__bp_priv__attemptTaskOnWasm'}, 1}.
  {label, 58}.
    {call_only, 1, {f, 5}}.

{function, '__bp_tpl_0', 1, 7}.
  {label, 6}.
    {func_info, {atom, std@failure}, {atom, '__bp_tpl_0'}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.

{function, '__bp_tpl_1-t/1-fun-0-', 1, 15}.
  {label, 14}.
    {func_info, {atom, std@failure}, {atom, '__bp_tpl_1-t/1-fun-0-'}, 1}.
  {label, 15}.
    {allocate, 11, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 2}}.
    {'try', {y, 10}, {f, 18}}.
    {move, {y, 2}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 4}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
    {try_end, {y, 10}}.
    {jump, {f, 19}}.
  {label, 18}.
    {try_case, {y, 10}}.
    {move, {x, 0}, {y, 4}}.
    {move, {x, 1}, {y, 5}}.
    {move, {x, 2}, {y, 6}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 21}, [{x, 0}, {atom, error}]}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 21}, [{x, 0}]}.
    {test, test_arity, {f, 21}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {y, 0}}.
    {move, {y, 8}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, panic}, {x, 1}}.
    {test, is_eq_exact, {f, 23}, [{x, 0}, {x, 1}]}.
    {jump, {f, 24}}.
  {label, 23}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, todo}, {x, 1}}.
    {test, is_eq_exact, {f, 25}, [{x, 0}, {x, 1}]}.
    {jump, {f, 26}}.
  {label, 25}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, integer_overflow}, {x, 1}}.
    {test, is_eq_exact, {f, 21}, [{x, 0}, {x, 1}]}.
  {label, 26}.
  {label, 24}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 27}, [{x, 0}]}.
    {jump, {f, 28}}.
  {label, 27}.
    {move, {y, 1}, {x, 0}}.
    {test, is_list, {f, 21}, [{x, 0}]}.
  {label, 28}.
    {jump, {f, 22}}.
  {label, 22}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@Failure}, {y, 9}, {literal, <<"panic">>}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 3}}.
    {jump, {f, 20}}.
  {label, 21}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 29}, [{x, 0}, {atom, error}]}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 29}, [{x, 0}]}.
    {test, test_arity, {f, 29}, [{x, 0}, 4]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 3, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 29}, [{x, 0}, {atom, bp_assert}]}.
    {move, {y, 8}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@Failure}, {y, 9}, {literal, <<"panic">>}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 3}}.
    {jump, {f, 20}}.
  {label, 29}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 30}, [{x, 0}, {atom, error}]}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 30}, [{x, 0}]}.
    {test, test_arity, {f, 30}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 30}, [{x, 0}, {atom, bp_assert}]}.
    {move, {y, 8}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 30}, [{x, 0}]}.
    {jump, {f, 31}}.
  {label, 31}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@Failure}, {y, 1}, {literal, <<"panic">>}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 3}}.
    {jump, {f, 20}}.
  {label, 30}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, {atom, error}]}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 32}, [{x, 0}]}.
    {test, test_arity, {f, 32}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, {atom, bp_host}]}.
    {move, {y, 8}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 32}, [{x, 0}]}.
    {jump, {f, 33}}.
  {label, 33}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@Failure}, {y, 1}, {literal, <<"host">>}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 3}}.
    {jump, {f, 20}}.
  {label, 32}.
    {move, {y, 5}, {y, 0}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@Failure}, {y, 7}, {literal, <<"crash">>}]}}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 7}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 3}}.
    {jump, {f, 20}}.
  {label, 20}.
  {label, 19}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 11}.
    return.

{function, '__bp_tpl_1', 1, 11}.
  {label, 10}.
    {func_info, {atom, std@failure}, {atom, '__bp_tpl_1'}, 1}.
  {label, 11}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 15}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_2-t/1-fun-0-', 1, 43}.
  {label, 42}.
    {func_info, {atom, std@failure}, {atom, '__bp_tpl_2-t/1-fun-0-'}, 1}.
  {label, 43}.
    {allocate, 8, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 1}}.
    {'try', {y, 7}, {f, 46}}.
    {move, {y, 1}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 3}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 2}}.
    {try_end, {y, 7}}.
    {jump, {f, 47}}.
  {label, 46}.
    {try_case, {y, 7}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 6}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 2}}.
    {jump, {f, 48}}.
  {label, 48}.
  {label, 47}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, '__bp_tpl_2', 1, 39}.
  {label, 38}.
    {func_info, {atom, std@failure}, {atom, '__bp_tpl_2'}, 1}.
  {label, 39}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 43}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@failure@@HostErrorName.S
```erlang
{module, std@failure@@HostErrorName}.
{exports, [{'__bp_format', 1}]}.
{attributes, []}.
{labels, 7}.

{function, '__bp_format', 1, 3}.
  {label, 2}.
    {line, [{location, "std@failure@@HostErrorName.erl", 1}]}.
    {func_info, {atom, std@failure@@HostErrorName}, {atom, '__bp_format'}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 4}, [{x, 0}, {atom, std@failure@@HostErrorName__v__error}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"HostErrorName.Error">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 4}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 5}, [{x, 0}, {atom, std@failure@@HostErrorName__v__throw}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"HostErrorName.Throw">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 5}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 6}, [{x, 0}, {atom, std@failure@@HostErrorName__v__exit}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"HostErrorName.Exit">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 6}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"HostErrorName">>}, nil]}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@failure@@HostError.S
```erlang
{module, std@failure@@HostError}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 10}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "std@failure@@HostError.erl", 1}]}.
    {func_info, {atom, std@failure@@HostError}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, message}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {test, is_eq_exact, {f, 5}, [{x, 1}, {atom, kind}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 5}.
    {test, is_eq_exact, {f, 6}, [{x, 1}, {atom, name}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 6}.
    {test, is_eq_exact, {f, 7}, [{x, 1}, {atom, detail}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 5}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 7}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 9}.
  {label, 8}.
    {line, [{location, "std@failure@@HostError.erl", 1}]}.
    {func_info, {atom, std@failure@@HostError}, {atom, '__bp_format'}, 1}.
  {label, 9}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 5}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"detail">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"name">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"kind">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"message">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"HostError">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@failure@@Failure.S
```erlang
{module, std@failure@@Failure}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 8}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "std@failure@@Failure.erl", 1}]}.
    {func_info, {atom, std@failure@@Failure}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, message}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {test, is_eq_exact, {f, 5}, [{x, 1}, {atom, kind}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 5}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 7}.
  {label, 6}.
    {line, [{location, "std@failure@@Failure.erl", 1}]}.
    {func_info, {atom, std@failure@@Failure}, {atom, '__bp_format'}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"kind">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"message">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Failure">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- std/io/random.bp
```botopink
//// std/io/random — pseudo-random number primitives (cross-backend).
////
//// Reference:
////   Node.js  — https://nodejs.org/api/  (the `Math.random` global)
////   Erlang   — https://www.erlang.org/doc/apps/stdlib/rand.html
////
//// `float()` returns a uniform `[0.0, 1.0)` sample on every backend.
//// Higher-level helpers (`coin`/`pick`) compose `float()` — portable +
//// no host call beyond the uniform sample. Seedable RNGs are deferred:
//// Node has no built-in seedable PRNG behind `Math.random`, so any
//// seed/state surface needs a userland PRNG; ship that in a follow-up
//// once the test infra is ready for reproducible draws.
////
//// NOT A CSPRNG: everything above `secureToken` is `Math.random` /
//// `rand:uniform`, predictable to anyone who sees enough draws. A token, a
//// session id, a nonce or a UUID comes from `secureToken` / `uuidV4`, which
//// read the host's cryptographic source (`crypto.randomBytes`,
//// `crypto:strong_rand_bytes/1`) — or `crypto.randomBytes` for hex.

import {compiler};

#[compiler.external(.JavaScript("Math.random()"), .Erlang("rand:uniform()"), .Wasm(std: "random.float"))]
pub declare fn float() -> f64;

// Seed the Node-side userland PRNG (Mulberry32) shipped via the sidecar
// at `libs/std/src/sidecars/random.mjs`. After seeding, `seededFloat()`
// draws from the reproducible stream. `float()` itself stays on
// `Math.random`; explicit-stream callers opt into determinism by using
// `seededFloat` after `seed`.
// Node: `require('./sidecars/random.mjs').seed($0)` — the CLI's sidecar
// shipper copies the `.mjs` next to the emitted module.
// Erlang: `rand:seed/2` with the `exsplus` algorithm + a `{S, S, S}`
// triple. `S` is folded to an integer via the i64 input.
#[compiler.external(
    .JavaScript("""require('./sidecars/random.mjs').seed($0)"""),
    .Erlang("""(fun(__S) -> rand:seed(exsplus, {__S, __S, __S}) end)($0)"""),
    .Wasm(std: "random.seed"),
)]
pub declare fn seed(s: i32) -> void;

// Draw from the seeded PRNG when a `seed` call has been made; otherwise
// falls through to the unseeded `float()` baseline. Erlang's `rand`
// module reads from the process dictionary's seed state directly, so
// the same `rand:uniform/0` call after `seed` produces the reproducible
// stream automatically.
#[compiler.external(
    .JavaScript("""require('./sidecars/random.mjs').seededFloat()"""),
    .Erlang("rand:uniform()"),
    .Wasm(std: "random.seededFloat"),
)]
pub declare fn seededFloat() -> f64;

// 50/50 boolean draw. `float() >= 0.5` picks the upper half of the
// uniform sample — identically distributed on every backend that has
// a uniform `float()`.
pub fn coin() -> bool {
    return float() >= 0.5;
}

// Random integer in the closed interval `[lo, hi]`. When `lo > hi` the
// range is empty and the result is `lo` (a defensive default — the
// alternative is to `panic`, which the @assert-style tests would
// rather catch at the call site).
pub fn intInRange(lo: i32, hi: i32) -> i32 {
    if (lo >= hi) return lo;
    val span = (hi - lo) + 1;
    val product = float() * span;
    val offset = floorWalk(0, 1.0, product, span);
    return lo + offset;
}

// Pick a random element from a non-empty array. Returns `null` for the
// empty array — the call site should default with `?? …` rather
// than panic. Uses a walk-up integer floor (no `Math.floor` import) so
// the body stays self-contained.
pub fn pick<T>(xs: array<T>) -> ?T {
    val n = xs.length;
    if (n == 0) return null;
    // `float() * n` mixes f64 × i32 — inference promotes to f64.
    val product = float() * n;
    val idx = floorWalk(0, 1.0, product, n);
    return xs.at(idx);
}

// Internal: integer floor of a non-negative `product` < `upper`. Walks
// `start` up from 0 while `threshold (= start + 1)` still fits below
// `product`. O(upper) — fine for the small `array<T>` arities `pick`
// targets in tests.
fn floorWalk(start: i32, threshold: f64, product: f64, upper: i32) -> i32 {
    if (start + 1 > upper) return start;
    if (threshold > product) return start;
    return floorWalk(start + 1, threshold + 1.0, product, upper);
}

// Fisher-Yates shuffle. Returns a fresh array whose elements are a
// permutation of `xs`. The pure-bp shape was deferred (the deferral
// note used to live here) because `array<T>::at(i)` returns `?T` and
// extracting T without a sentinel value of T is circular. Solution:
// host-backed `pub declare fn shuffle<T>(xs)` — the host owns the
// in-place swap; the bp side only declares the signature and the
// per-target template.
//
// Node: classic Fisher-Yates over the input array, returning a fresh
// copy (the input is not mutated — matches the immutable-by-default
// botopink contract for return values). `random.seed` from this same
// module seeds the sidecar PRNG; subsequent `shuffle` draws are
// reproducible after `seed(s)`.
//
// Erlang: `[X || {_, X} <- lists:sort([{rand:uniform(), Y} || Y <- $0])]`
// — the Schwartzian-transform shuffle: pair each element with a
// random key, sort by key, strip the keys. Stable across `rand:seed`
// state (the same `rand` server `seed/2` controls both `uniform/0`
// here and `seededFloat()` above).
//
// Beam/wasm: out of scope at v1 (no `lists:sort` template, no
// `Math.random` equivalent in wat3); the matrix will report
// `MissingExternalTarget` on a `shuffle(...)` call from those backends
// until the corresponding shim lands.
#[compiler.external(
    .JavaScript("""(function(__A){ var __O = __A.slice(); for (var __I = __O.length - 1; __I > 0; __I--) { var __J = Math.floor(Math.random() * (__I + 1)); var __T = __O[__I]; __O[__I] = __O[__J]; __O[__J] = __T; } return __O; })($0)"""),
    .Erlang("""[__X || {_, __X} <- lists:sort([{rand:uniform(), __Y} || __Y <- $0])]"""),
    .Wasm(body: shuffleBody),
)]
pub declare fn shuffle<T>(xs: array<T>) -> array<T>;

// ── 1.0.10-beta front 01 additions ──────────────────────────────────────────
//
// The CSPRNG half. Everything ABOVE is `Math.random` / `rand:uniform` — fine
// for a shuffle, wrong for anything an attacker must not guess. A token, a
// session id, a nonce or a UUID comes from the two functions below, which
// read the host's cryptographically strong source.

// `bytes` strong random bytes as base64url without padding — URL-, cookie-
// and header-safe. 32 bytes answer 43 characters.
// Node: `crypto.randomBytes(n).toString('base64url')`.
// Erlang: `crypto:strong_rand_bytes/1` + `base64:encode/2` in `urlsafe`
// mode without padding (OTP 26+).
#[compiler.external(
    .JavaScript("""require('crypto').randomBytes($0).toString('base64url')"""),
    .Erlang("""base64:encode(crypto:strong_rand_bytes($0), #{mode => urlsafe, padding => false})"""),
    .Wasm(body: secureTokenBody),
)]
pub declare fn secureToken(bytes: i32) -> string;

// A random (version 4) UUID, lowercase: 122 strong random bits with the
// version nibble set to `4` and the variant bits to `10` (RFC 9562 §5.4).
// Node: `crypto.randomUUID()`.
// Erlang: 16 strong random bytes, the version/variant bits rewritten in the
// binary pattern — the bit work lives in the template because botopink has
// no bitwise operators (`language-gaps.md`).
#[compiler.external(
    .JavaScript("""require('crypto').randomUUID()"""),
    .Erlang("""(fun() -> <<__A:32, __B:16, _:4, __C:12, _:2, __D:14, __E:48>> = crypto:strong_rand_bytes(16), iolist_to_binary(io_lib:format("~8.16.0b-~4.16.0b-4~3.16.0b-~4.16.0b-~12.16.0b", [__A, __B, __C, __D bor 16#8000, __E])) end)()"""),
    .Wasm(body: uuidV4Body),
)]
pub declare fn uuidV4() -> string;

// ── tests ────────────────────────────────────────────────────────────────────

test "random.float lies in [0.0, 1.0)" {
    val r = float();
    assert r >= 0.0;
    assert r < 1.0;
}

test "random.coin draws either truth value" {
    val b = coin();
    assert b == true || b == false;
}

test "random.pick from non-empty array returns a member" {
    val xs = [1, 2, 3];
    val r = pick(xs) ?? 99;
    assert r >= 1;
    assert r <= 3;
}

test "random.pick from empty array returns null" {
    val empty: array<i32> = [];
    assert pick(empty) ?? 99 == 99;
}

test "random.intInRange yields a value in the closed interval" {
    val r = intInRange(1, 6);
    assert r >= 1;
    assert r <= 6;
}

test "random.intInRange on a one-element range returns that element" {
    assert intInRange(7, 7) == 7;
}

test "random.intInRange on an inverted range returns the low bound" {
    assert intInRange(10, 5) == 10;
}

test "random.seed + seededFloat draws are reproducible" {
    seed(42);
    val a = seededFloat();
    seed(42);
    val b = seededFloat();
    assert a == b;
}

test "random.seededFloat lies in [0.0, 1.0)" {
    val r = seededFloat();
    assert r >= 0.0;
    assert r < 1.0;
}

test "random.shuffle preserves length" {
    val xs = [1, 2, 3, 4, 5];
    val ys = shuffle(xs);
    assert ys.length == 5;
}

test "random.shuffle preserves the multiset (sum)" {
    val xs = [1, 2, 3, 4, 5];
    val ys = shuffle(xs);
    // Sum is permutation-invariant — every element still appears once.
    var s = 0;
    ys.forEach({ y ->
        s = s + y;
    });
    assert s == 15;
}

test "random.shuffle of an empty array is empty" {
    val empty: array<i32> = [];
    assert shuffle(empty).length == 0;
}

test "random.shuffle of a single-element array preserves it" {
    val xs = [42];
    val ys = shuffle(xs);
    assert ys.length == 1;
    assert ys.at(0) ?? 0 == 42;
}

test "random.secureToken(32) is 43 base64url characters" {
    val t = secureToken(32);
    assert t.length == 43;
    assert t.contains("+").negate();
    assert t.contains("/").negate();
    assert t.contains("=").negate();
}

test "random.secureToken draws differ" {
    assert secureToken(16) != secureToken(16);
    assert secureToken(0) == "";
}

test "random.uuidV4 has the version 4 layout" {
    val u = uuidV4();
    val groups = u.split("-");
    assert u.length == 36;
    assert groups.length == 5;
    assert (groups.at(0) ?? "").length == 8;
    assert (groups.at(1) ?? "").length == 4;
    assert (groups.at(2) ?? "").length == 4;
    assert (groups.at(3) ?? "").length == 4;
    assert (groups.at(4) ?? "").length == 12;
    assert (groups.at(2) ?? "").startsWith("4");
    val variant = (groups.at(3) ?? "").slice(0, 1);
    assert "89ab".contains(variant);
    assert u.split("").filter({ c -> "0123456789abcdef-".contains(c) }).length
        == 36;
    assert uuidV4() != u;
}

// ── randomBytes (was `crypto.randomBytes`) ───────────────────────────────────

// `n` cryptographically-secure random bytes as a hex string of length
// `2 * n` (each byte rendered as two lowercase hex chars). The hex shape
// sidesteps the `array<u8>` cross-backend representation gap — Node
// `Buffer` and Erlang `binary()` don't share a bp-side type. Callers
// that need bytes parse the hex back themselves.
// Node: `require('crypto').randomBytes(n).toString('hex')`.
// Erlang: `crypto:strong_rand_bytes/1` + the same per-byte hex format
// string used by the hashes above.
#[compiler.external(
    .JavaScript("""require('crypto').randomBytes($0).toString('hex')"""),
    .Erlang("""list_to_binary([io_lib:format("~2.16.0b", [__B]) || __B <- binary_to_list(crypto:strong_rand_bytes($0))])"""),
    .Wasm(body: randomBytesBody),
)]
pub declare fn randomBytes(n: i32) -> string;

test "random.randomBytes(16) returns 32 hex chars" {
    val h = randomBytes(16);
    assert h.length == 32;
}

test "random.randomBytes(0) is empty" {
    val h = randomBytes(0);
    assert h.length == 0;
}

// ── the wasm bodies (decision 238) ──────────────────────────────────────────
// wasm has no host for these cells, so each names one of the private bodies
// below with `#[compiler.external(.Wasm(fn: …))]`; commonJS and erlang call their
// host. On wasm `float()` is `std: "random.float"` — 53 bits of WASI's
// `random_get`, the host's cryptographic source — so the token, UUID and
// byte bodies draw from it a byte at a time (`randomByte`: ⌊u · 256⌋ of a
// 53-bit uniform `u` is exactly uniform). `seed` / `seededFloat` are
// std-wasm's seeded stream (decision 451, `std: "random.…"`), drawn as the
// commonJS sidecar does (Mulberry32): the same draws after the same `seed`; a
// draw before any seed is the host's (`float()`'s source). At comptime the
// same cells answer, and a draw before any seed is refused — a build has no
// entropy.

// Selection shuffle: each step moves a uniformly drawn element of what is
// left to the output — a uniform permutation, as the Node cell's
// Fisher-Yates; the elements are moved as one-element slices, never read.
fn shuffleBody<T>(xs: array<T>) -> array<T> {
    var rest = xs;
    var out = xs.slice(0, 0);
    while (rest.length > 0) {
        val j = wholeOf((float() * rest.length).floor());
        out = out.append(rest.slice(j, j + 1));
        rest = rest.slice(0, j).append(rest.slice(j + 1, rest.length));
    }
    return out;
}

fn secureTokenBody(bytes: i32) -> string {
    return base64UrlOf(randomBytesOf(bytes));
}

// RFC 9562 §5.4: 16 random bytes, the version nibble 4, the variant `10`.
fn uuidV4Body() -> string {
    val b = randomBytesOf(16);
    val version = 64 + b.at(6) ?? 0 % 16;
    val variant = 128 + b.at(8) ?? 0 % 64;
    return hexOf(b.slice(0, 4))
        + "-"
        + hexOf(b.slice(4, 6))
        + "-"
        + hexOf([version, b.at(7) ?? 0])
        + "-"
        + hexOf([variant, b.at(9) ?? 0])
        + "-"
        + hexOf(b.slice(10, 16));
}

fn randomBytesBody(n: i32) -> string {
    return hexOf(randomBytesOf(n));
}

fn randomByte() -> i32 {
    return wholeOf((float() * 256.0).floor());
}

fn randomBytesOf(n: i32) -> array<i32> {
    var out: array<i32> = [];
    var i = 0;
    while (i < n) {
        out = out.append([randomByte()]);
        i = i + 1;
    }
    return out;
}

fn hexDigit(n: i32) -> string {
    return "0123456789abcdef".at(n) ?? "";
}

fn hexOf(bytes: array<i32>) -> string {
    return bytes.map({ b -> hexDigit(b / 16) + hexDigit(b % 16) }).join("");
}

// RFC 4648 §5 base64url, unpadded.
fn base64UrlOf(bytes: array<i32>) -> string {
    val alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
    var out = "";
    var g = 0;
    while (3 * g < bytes.length) {
        val n = bytes.length - 3 * g;
        val b0 = bytes.at(3 * g) ?? 0;
        val b1 = if (n > 1) {
            bytes.at(3 * g + 1) ?? 0;
        } else 0;
        val b2 = if (n > 2) {
            bytes.at(3 * g + 2) ?? 0;
        } else 0;
        out = out
            + alphabet.at(b0 / 4) ?? ""
            + alphabet.at((b0 % 4) * 16 + b1 / 16) ?? "";
        if (n > 1) out = out + alphabet.at((b1 % 16) * 4 + b2 / 64) ?? "";
        if (n > 2) out = out + alphabet.at(b2 % 64) ?? "";
        g = g + 1;
    }
    return out;
}

// A whole `v` in [0, 2^31) as an `i32`.
fn wholeOf(v: f64) -> i32 {
    var r = 0;
    var rest = v;
    var bit = 1073741824;
    var weight = 1073741824.0;
    while (bit > 0) {
        if (rest >= weight) {
            r = r + bit;
            rest = rest - weight;
        }
        bit = bit / 2;
        weight = weight / 2.0;
    }
    return r;
}

```

----- BEAM ASSEMBLY -- std/io/random.S
```erlang
{module, std@io@random}.
{exports, [{float, 0}, {seed, 1}, {seededFloat, 0}, {coin, 0}, {intInRange, 2}, {pick, 1}, {shuffle, 1}, {secureToken, 1}, {uuidV4, 0}, {randomBytes, 1}, {'__bp_priv__array_range', 2}, {'__bp_priv__array_repeat', 2}, {'__bp_priv__base64UrlOf', 1}, {'__bp_priv__floorWalk', 4}, {'__bp_priv__hexDigit', 1}, {'__bp_priv__hexOf', 1}, {'__bp_priv__randomByte', 0}, {'__bp_priv__randomBytesBody', 1}, {'__bp_priv__randomBytesOf', 1}, {'__bp_priv__secureTokenBody', 1}, {'__bp_priv__shuffleBody', 1}, {'__bp_priv__uuidV4Body', 0}, {'__bp_priv__wholeOf', 1}]}.
{attributes, []}.
{labels, 298}.

{function, 'array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "std@io@random.erl", 1}]}.
    {func_info, {atom, std@io@random}, {atom, 'array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 86}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 87}}.
  {label, 86}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 88}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 89}}.
  {label, 88}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 91}}.
  {label, 89}.
  {label, 87}.
    {deallocate, 6}.
    return.

{function, 'array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "std@io@random.erl", 2}]}.
    {func_info, {atom, std@io@random}, {atom, 'array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 92}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 93}}.
  {label, 92}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 94}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 91}}.
    {jump, {f, 95}}.
  {label, 94}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 91}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 91}}.
  {label, 95}.
  {label, 93}.
    {deallocate, 6}.
    return.
%%% std/io/random — pseudo-random number primitives (cross-backend).
%%% 
%%% Reference:
%%%   Node.js  — https://nodejs.org/api/  (the `Math.random` global)
%%%   Erlang   — https://www.erlang.org/doc/apps/stdlib/rand.html
%%% 
%%% `float()` returns a uniform `[0.0, 1.0)` sample on every backend.
%%% Higher-level helpers (`coin`/`pick`) compose `float()` — portable +
%%% no host call beyond the uniform sample. Seedable RNGs are deferred:
%%% Node has no built-in seedable PRNG behind `Math.random`, so any
%%% seed/state surface needs a userland PRNG; ship that in a follow-up
%%% once the test infra is ready for reproducible draws.
%%% 
%%% NOT A CSPRNG: everything above `secureToken` is `Math.random` /
%%% `rand:uniform`, predictable to anyone who sees enough draws. A token, a
%%% session id, a nonce or a UUID comes from `secureToken` / `uuidV4`, which
%%% read the host's cryptographic source (`crypto.randomBytes`,
%%% `crypto:strong_rand_bytes/1`) — or `crypto.randomBytes` for hex.

{function, float, 0, 35}.
  {label, 34}.
    {line, [{location, "std@io@random.erl", 3}]}.
    {func_info, {atom, std@io@random}, {atom, float}, 0}.
  {label, 35}.
    {call_ext_only, 0, {extfunc, rand, uniform, 0}}.
% Seed the Node-side userland PRNG (Mulberry32) shipped via the sidecar
% at `libs/std/src/sidecars/random.mjs`. After seeding, `seededFloat()`
% draws from the reproducible stream. `float()` itself stays on
% `Math.random`; explicit-stream callers opt into determinism by using
% `seededFloat` after `seed`.
% Node: `require('./sidecars/random.mjs').seed($0)` — the CLI's sidecar
% shipper copies the `.mjs` next to the emitted module.
% Erlang: `rand:seed/2` with the `exsplus` algorithm + a `{S, S, S}`
% triple. `S` is folded to an integer via the i64 input.

{function, seed, 1, 43}.
  {label, 42}.
    {line, [{location, "std@io@random.erl", 4}]}.
    {func_info, {atom, std@io@random}, {atom, seed}, 1}.
  {label, 43}.
    {call_only, 1, {f, 37}}.
% Draw from the seeded PRNG when a `seed` call has been made; otherwise
% falls through to the unseeded `float()` baseline. Erlang's `rand`
% module reads from the process dictionary's seed state directly, so
% the same `rand:uniform/0` call after `seed` produces the reproducible
% stream automatically.

{function, seededFloat, 0, 45}.
  {label, 44}.
    {line, [{location, "std@io@random.erl", 5}]}.
    {func_info, {atom, std@io@random}, {atom, seededFloat}, 0}.
  {label, 45}.
    {call_ext_only, 0, {extfunc, rand, uniform, 0}}.
% 50/50 boolean draw. `float() >= 0.5` picks the upper half of the
% uniform sample — identically distributed on every backend that has
% a uniform `float()`.

{function, coin, 0, 7}.
  {label, 6}.
    {line, [{location, "std@io@random.erl", 6}]}.
    {func_info, {atom, std@io@random}, {atom, coin}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {call_ext, 0, {extfunc, rand, uniform, 0}}.
    {test, is_ge, {f, 96}, [{x, 0}, {float, 0.5}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 97}}.
  {label, 96}.
    {move, {atom, false}, {x, 0}}.
  {label, 97}.
    {deallocate, 0}.
    return.
% Random integer in the closed interval `[lo, hi]`. When `lo > hi` the
% range is empty and the result is `lo` (a defensive default — the
% alternative is to `panic`, which the @assert-style tests would
% rather catch at the call site).

{function, intInRange, 2, 9}.
  {label, 8}.
    {line, [{location, "std@io@random.erl", 7}]}.
    {func_info, {atom, std@io@random}, {atom, intInRange}, 2}.
  {label, 9}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 98}, [{y, 0}, {y, 1}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 98}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 99}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 99}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 100}}.
  {label, 99}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/random.bp:66:20">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 100}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 101}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 101}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 102}}.
  {label, 101}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:66:26">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 102}.
    {move, {x, 0}, {y, 2}}.
    {call_ext, 0, {extfunc, rand, uniform, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {y, 2}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 2}, {x, 3}}.
    {move, {y, 3}, {x, 2}}.
    {move, {float, 1.0}, {x, 1}}.
    {call, 4, {f, 13}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {y, 4}], {x, 0}}.
    {test, is_ge, {f, 103}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 103}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 104}}.
  {label, 103}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:69:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 104}.
    {deallocate, 5}.
    return.
% Pick a random element from a non-empty array. Returns `null` for the
% empty array — the call site should default with `?? …` rather
% than panic. Uses a walk-up integer floor (no `Math.floor` import) so
% the body stays self-contained.

{function, pick, 1, 11}.
  {label, 10}.
    {line, [{location, "std@io@random.erl", 8}]}.
    {func_info, {atom, std@io@random}, {atom, pick}, 1}.
  {label, 11}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 105}, [{y, 1}, {integer, 0}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 105}.
    {call_ext, 0, {extfunc, rand, uniform, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {y, 1}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 1}, {x, 3}}.
    {move, {y, 2}, {x, 2}}.
    {move, {float, 1.0}, {x, 1}}.
    {call, 4, {f, 13}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_last, 2, {f, 107}, 4}.
% Internal: integer floor of a non-negative `product` < `upper`. Walks
% `start` up from 0 while `threshold (= start + 1)` still fits below
% `product`. O(upper) — fine for the small `array<T>` arities `pick`
% targets in tests.

{function, floorWalk, 4, 13}.
  {label, 12}.
    {line, [{location, "std@io@random.erl", 9}]}.
    {func_info, {atom, std@io@random}, {atom, floorWalk}, 4}.
  {label, 13}.
    {allocate, 4, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 111}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 111}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 112}}.
  {label, 111}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:90:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 112}.
    {test, is_lt, {f, 110}, [{y, 3}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 110}.
    {test, is_lt, {f, 113}, [{y, 2}, {y, 1}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 113}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 114}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 114}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 115}}.
  {label, 114}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:92:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 115}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 1}, {float, 1.0}], {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {move, {x, 1}, {x, 4}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 4}, {x, 0}}.
    {call_last, 4, {f, 13}, 4}.
% Fisher-Yates shuffle. Returns a fresh array whose elements are a
% permutation of `xs`. The pure-bp shape was deferred (the deferral
% note used to live here) because `array<T>::at(i)` returns `?T` and
% extracting T without a sentinel value of T is circular. Solution:
% host-backed `pub declare fn shuffle<T>(xs)` — the host owns the
% in-place swap; the bp side only declares the signature and the
% per-target template.
% 
% Node: classic Fisher-Yates over the input array, returning a fresh
% copy (the input is not mutated — matches the immutable-by-default
% botopink contract for return values). `random.seed` from this same
% module seeds the sidecar PRNG; subsequent `shuffle` draws are
% reproducible after `seed(s)`.
% 
% Erlang: `[X || {_, X} <- lists:sort([{rand:uniform(), Y} || Y <- $0])]`
% — the Schwartzian-transform shuffle: pair each element with a
% random key, sort by key, strip the keys. Stable across `rand:seed`
% state (the same `rand` server `seed/2` controls both `uniform/0`
% here and `seededFloat()` above).
% 
% Beam/wasm: out of scope at v1 (no `lists:sort` template, no
% `Math.random` equivalent in wat3); the matrix will report
% `MissingExternalTarget` on a `shuffle(...)` call from those backends
% until the corresponding shim lands.

{function, shuffle, 1, 59}.
  {label, 58}.
    {line, [{location, "std@io@random.erl", 10}]}.
    {func_info, {atom, std@io@random}, {atom, shuffle}, 1}.
  {label, 59}.
    {call_only, 1, {f, 47}}.
% ── 1.0.10-beta front 01 additions ──────────────────────────────────────────
% 
% The CSPRNG half. Everything ABOVE is `Math.random` / `rand:uniform` — fine
% for a shuffle, wrong for anything an attacker must not guess. A token, a
% session id, a nonce or a UUID comes from the two functions below, which
% read the host's cryptographically strong source.
% `bytes` strong random bytes as base64url without padding — URL-, cookie-
% and header-safe. 32 bytes answer 43 characters.
% Node: `crypto.randomBytes(n).toString('base64url')`.
% Erlang: `crypto:strong_rand_bytes/1` + `base64:encode/2` in `urlsafe`
% mode without padding (OTP 26+).

{function, secureToken, 1, 63}.
  {label, 62}.
    {line, [{location, "std@io@random.erl", 11}]}.
    {func_info, {atom, std@io@random}, {atom, secureToken}, 1}.
  {label, 63}.
    {call_only, 1, {f, 61}}.
% A random (version 4) UUID, lowercase: 122 strong random bits with the
% version nibble set to `4` and the variant bits to `10` (RFC 9562 §5.4).
% Node: `crypto.randomUUID()`.
% Erlang: 16 strong random bytes, the version/variant bits rewritten in the
% binary pattern — the bit work lives in the template because botopink has
% no bitwise operators (`language-gaps.md`).

{function, uuidV4, 0, 75}.
  {label, 74}.
    {line, [{location, "std@io@random.erl", 12}]}.
    {func_info, {atom, std@io@random}, {atom, uuidV4}, 0}.
  {label, 75}.
    {call_only, 0, {f, 65}}.
% ── tests ────────────────────────────────────────────────────────────────────
% ── randomBytes (was `crypto.randomBytes`) ───────────────────────────────────
% `n` cryptographically-secure random bytes as a hex string of length
% `2 * n` (each byte rendered as two lowercase hex chars). The hex shape
% sidesteps the `array<u8>` cross-backend representation gap — Node
% `Buffer` and Erlang `binary()` don't share a bp-side type. Callers
% that need bytes parse the hex back themselves.
% Node: `require('crypto').randomBytes(n).toString('hex')`.
% Erlang: `crypto:strong_rand_bytes/1` + the same per-byte hex format
% string used by the hashes above.

{function, randomBytes, 1, 85}.
  {label, 84}.
    {line, [{location, "std@io@random.erl", 13}]}.
    {func_info, {atom, std@io@random}, {atom, randomBytes}, 1}.
  {label, 85}.
    {call_only, 1, {f, 77}}.
% ── the wasm bodies (decision 238) ──────────────────────────────────────────
% wasm has no host for these cells, so each names one of the private bodies
% below with `#[compiler.external(.Wasm(fn: …))]`; commonJS and erlang call their
% host. On wasm `float()` is `std: "random.float"` — 53 bits of WASI's
% `random_get`, the host's cryptographic source — so the token, UUID and
% byte bodies draw from it a byte at a time (`randomByte`: ⌊u · 256⌋ of a
% 53-bit uniform `u` is exactly uniform). `seed` / `seededFloat` are
% std-wasm's seeded stream (decision 451, `std: "random.…"`), drawn as the
% commonJS sidecar does (Mulberry32): the same draws after the same `seed`; a
% draw before any seed is the host's (`float()`'s source). At comptime the
% same cells answer, and a draw before any seed is refused — a build has no
% entropy.
% Selection shuffle: each step moves a uniformly drawn element of what is
% left to the output — a uniform permutation, as the Node cell's
% Fisher-Yates; the elements are moved as one-element slices, never read.

{function, shuffleBody, 1, 15}.
  {label, 14}.
    {line, [{location, "std@io@random.erl", 14}]}.
    {func_info, {atom, std@io@random}, {atom, shuffleBody}, 1}.
  {label, 15}.
    {allocate, 9, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '+', {f, 0}, 0, [{integer, 0}, {integer, 1}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{integer, 0}, {integer, 0}], {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {move, {x, 0}, {y, 2}}.
    {line, [{location, "std@io@random.erl", 15}]}.
  {label, 116}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 117}, [{integer, 0}, {x, 0}]}.
    {call_ext, 0, {extfunc, rand, uniform, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 2, [{x, 0}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {call, 1, {f, 33}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 118}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 118}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 119}}.
  {label, 118}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:319:42">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 119}.
    {test, is_ne_exact, {f, 120}, [{x, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 1, [{y, 3}, {integer, 1}], {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {y, 3}], {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 121}}.
  {label, 120}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 121}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_ne_exact, {f, 122}, [{y, 3}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 0, [{integer, 0}, {integer, 1}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 3}, {integer, 0}], {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 123}}.
  {label, 122}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 123}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 124}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 124}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 125}}.
  {label, 124}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:320:53">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 125}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 2, [{x, 0}], {x, 0}}.
    {test, is_ne_exact, {f, 126}, [{x, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {integer, 1}], {x, 2}}.
    {gc_bif, '-', {f, 0}, 3, [{x, 0}, {x, 1}], {x, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 3}, {x, 2}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 127}}.
  {label, 126}.
    {move, {x, 1}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 127}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 116}}.
  {label, 117}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 9}.
    return.

{function, secureTokenBody, 1, 17}.
  {label, 16}.
    {line, [{location, "std@io@random.erl", 15}]}.
    {func_info, {atom, std@io@random}, {atom, secureTokenBody}, 1}.
  {label, 17}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 25}}.
    {call_last, 1, {f, 31}, 1}.
% RFC 9562 §5.4: 16 random bytes, the version nibble 4, the variant `10`.

{function, uuidV4Body, 0, 19}.
  {label, 18}.
    {line, [{location, "std@io@random.erl", 16}]}.
    {func_info, {atom, std@io@random}, {atom, uuidV4Body}, 0}.
  {label, 19}.
    {allocate, 14, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}]}}.
    {move, {integer, 16}, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 6}, {x, 1}}.
    {call, 2, {f, 107}}.
    {test, is_ne_exact, {f, 128}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 129}}.
  {label, 128}.
    {move, {integer, 0}, {x, 0}}.
  {label, 129}.
    {gc_bif, 'rem', {f, 0}, 1, [{x, 0}, {integer, 16}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 64}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 130}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 130}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 131}}.
  {label, 130}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:332:22">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 131}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 8}, {x, 1}}.
    {call, 2, {f, 107}}.
    {test, is_ne_exact, {f, 132}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 133}}.
  {label, 132}.
    {move, {integer, 0}, {x, 0}}.
  {label, 133}.
    {gc_bif, 'rem', {f, 0}, 1, [{x, 0}, {integer, 64}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 128}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 134}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 134}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 135}}.
  {label, 134}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:333:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 135}.
    {move, {x, 0}, {y, 4}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '+', {f, 0}, 0, [{integer, 10}, {integer, 1}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{integer, 16}, {integer, 10}], {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {call, 1, {f, 29}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"-">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 9}, {x, 1}}.
    {call, 2, {f, 107}}.
    {test, is_ne_exact, {f, 136}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {jump, {f, 137}}.
  {label, 136}.
    {move, {integer, 0}, {x, 0}}.
  {label, 137}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 29}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"-">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 7}, {x, 1}}.
    {call, 2, {f, 107}}.
    {test, is_ne_exact, {f, 138}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {jump, {f, 139}}.
  {label, 138}.
    {move, {integer, 0}, {x, 0}}.
  {label, 139}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 29}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"-">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '+', {f, 0}, 0, [{integer, 4}, {integer, 1}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{integer, 6}, {integer, 4}], {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {call, 1, {f, 29}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"-">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '+', {f, 0}, 0, [{integer, 0}, {integer, 1}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{integer, 4}, {integer, 0}], {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {call, 1, {f, 29}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 169}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 14}.
    return.

{function, randomBytesBody, 1, 21}.
  {label, 20}.
    {line, [{location, "std@io@random.erl", 17}]}.
    {func_info, {atom, std@io@random}, {atom, randomBytesBody}, 1}.
  {label, 21}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 25}}.
    {call_last, 1, {f, 29}, 1}.

{function, randomByte, 0, 23}.
  {label, 22}.
    {line, [{location, "std@io@random.erl", 18}]}.
    {func_info, {atom, std@io@random}, {atom, randomByte}, 0}.
  {label, 23}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {call_ext, 0, {extfunc, rand, uniform, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 256.0}], {x, 0}}.
    {call_ext, 1, {extfunc, math, floor, 1}}.
    {call_last, 1, {f, 33}, 1}.

{function, randomBytesOf, 1, 25}.
  {label, 24}.
    {line, [{location, "std@io@random.erl", 19}]}.
    {func_info, {atom, std@io@random}, {atom, randomBytesOf}, 1}.
  {label, 25}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {line, [{location, "std@io@random.erl", 20}]}.
  {label, 172}.
    {test, is_lt, {f, 173}, [{y, 2}, {y, 0}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {call, 0, {f, 23}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 174}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 174}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 175}}.
  {label, 174}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:358:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 175}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 172}}.
  {label, 173}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 6}.
    return.

{function, hexDigit, 1, 27}.
  {label, 26}.
    {line, [{location, "std@io@random.erl", 20}]}.
    {func_info, {atom, std@io@random}, {atom, hexDigit}, 1}.
  {label, 27}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"0123456789abcdef">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call, 2, {f, 178}}.
    {test, is_ne_exact, {f, 176}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 200}}.
  {label, 176}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 200}.
    {deallocate, 2}.
    return.

{function, hexOf, 1, 29}.
  {label, 28}.
    {line, [{location, "std@io@random.erl", 21}]}.
    {func_info, {atom, std@io@random}, {atom, hexOf}, 1}.
  {label, 29}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 202}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 206}, 3}.
% RFC 4648 §5 base64url, unpadded.

{function, base64UrlOf, 1, 31}.
  {label, 30}.
    {line, [{location, "std@io@random.erl", 22}]}.
    {func_info, {atom, std@io@random}, {atom, base64UrlOf}, 1}.
  {label, 31}.
    {allocate, 18, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_">>}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {line, [{location, "std@io@random.erl", 23}]}.
  {label, 207}.
    {gc_bif, '*', {f, 0}, 0, [{integer, 3}, {y, 3}], {x, 0}}.
    {test, is_ge, {f, 209}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 209}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 210}}.
  {label, 209}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/io/random.bp:376:14">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 210}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 2, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 208}, [{x, 1}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '*', {f, 0}, 2, [{integer, 3}, {y, 3}], {x, 0}}.
    {test, is_ge, {f, 211}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 211}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 212}}.
  {label, 211}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/io/random.bp:377:34">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 212}.
    {gc_bif, '-', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 213}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 213}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 214}}.
  {label, 213}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/random.bp:377:30">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 214}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '*', {f, 0}, 0, [{integer, 3}, {y, 3}], {x, 0}}.
    {test, is_ge, {f, 216}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 216}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 217}}.
  {label, 216}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/io/random.bp:378:29">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 217}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 107}}.
    {test, is_ne_exact, {f, 215}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {jump, {f, 218}}.
  {label, 215}.
    {move, {integer, 0}, {x, 0}}.
  {label, 218}.
    {move, {x, 0}, {y, 6}}.
    {test, is_lt, {f, 219}, [{integer, 1}, {y, 4}]}.
    {gc_bif, '*', {f, 0}, 0, [{integer, 3}, {y, 3}], {x, 0}}.
    {test, is_ge, {f, 222}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 222}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 223}}.
  {label, 222}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/io/random.bp:380:24">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 223}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 224}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 224}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 225}}.
  {label, 224}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:380:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 225}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 107}}.
    {test, is_ne_exact, {f, 221}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {jump, {f, 226}}.
  {label, 221}.
    {move, {integer, 0}, {x, 0}}.
  {label, 226}.
    {jump, {f, 220}}.
  {label, 219}.
    {move, {integer, 0}, {x, 0}}.
  {label, 220}.
    {move, {x, 0}, {y, 8}}.
    {test, is_lt, {f, 227}, [{integer, 2}, {y, 4}]}.
    {gc_bif, '*', {f, 0}, 0, [{integer, 3}, {y, 3}], {x, 0}}.
    {test, is_ge, {f, 230}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 230}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 231}}.
  {label, 230}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/io/random.bp:383:24">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 231}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 232}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 232}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 233}}.
  {label, 232}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:383:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 233}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 107}}.
    {test, is_ne_exact, {f, 229}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {jump, {f, 234}}.
  {label, 229}.
    {move, {integer, 0}, {x, 0}}.
  {label, 234}.
    {jump, {f, 228}}.
  {label, 227}.
    {move, {integer, 0}, {x, 0}}.
  {label, 228}.
    {move, {x, 0}, {y, 10}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 6}, {integer, 4}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {integer, 16}], {x, 0}}.
    {test, is_ge, {f, 236}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 236}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 237}}.
  {label, 236}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/io/random.bp:387:36">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 237}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, 'div', {f, 0}, 2, [{y, 8}, {integer, 16}], {x, 0}}.
    {test, is_ge, {f, 238}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 238}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 239}}.
  {label, 238}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/io/random.bp:387:46">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 239}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 240}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 240}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 241}}.
  {label, 240}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:387:41">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 241}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 178}}.
    {test, is_ne_exact, {f, 235}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {jump, {f, 242}}.
  {label, 235}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 242}.
    {move, {y, 11}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 6}, {integer, 4}], {x, 0}}.
    {test, is_ge, {f, 244}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 244}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 245}}.
  {label, 244}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/io/random.bp:386:30">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 245}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 178}}.
    {test, is_ne_exact, {f, 243}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {jump, {f, 246}}.
  {label, 243}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 246}.
    {move, {y, 11}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 169}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_lt, {f, 247}, [{integer, 1}, {y, 4}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 8}, {integer, 16}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {integer, 4}], {x, 0}}.
    {test, is_ge, {f, 249}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 249}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 250}}.
  {label, 249}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/io/random.bp:388:54">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 250}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, 'div', {f, 0}, 2, [{y, 10}, {integer, 64}], {x, 0}}.
    {test, is_ge, {f, 251}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 251}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 252}}.
  {label, 251}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/io/random.bp:388:63">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 252}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 253}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 253}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 254}}.
  {label, 253}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:388:58">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 254}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 178}}.
    {test, is_ne_exact, {f, 248}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {jump, {f, 255}}.
  {label, 248}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 255}.
    {move, {y, 12}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 12}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 169}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 256}}.
  {label, 247}.
  {label, 256}.
    {test, is_lt, {f, 257}, [{integer, 2}, {y, 4}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 10}, {integer, 64}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 178}}.
    {test, is_ne_exact, {f, 258}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {x, 0}}.
    {jump, {f, 259}}.
  {label, 258}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 259}.
    {move, {y, 13}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 13}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 169}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 260}}.
  {label, 257}.
  {label, 260}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 261}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 261}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 262}}.
  {label, 261}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:390:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 262}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 207}}.
  {label, 208}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 18}.
    return.
% A whole `v` in [0, 2^31) as an `i32`.

{function, wholeOf, 1, 33}.
  {label, 32}.
    {line, [{location, "std@io@random.erl", 23}]}.
    {func_info, {atom, std@io@random}, {atom, wholeOf}, 1}.
  {label, 33}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 1073741824}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {float, 1073741824.0}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {line, [{location, "std@io@random.erl", 24}]}.
  {label, 263}.
    {test, is_lt, {f, 264}, [{integer, 0}, {y, 3}]}.
    {test, is_ge, {f, 265}, [{y, 2}, {y, 4}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {y, 3}], {x, 0}}.
    {test, is_ge, {f, 266}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 266}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 267}}.
  {label, 266}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/random.bp:403:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 267}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 2}, {y, 4}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 268}}.
  {label, 265}.
  {label, 268}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 269}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 269}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 270}}.
  {label, 269}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/io/random.bp:406:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 270}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 4}, {float, 2.0}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 263}}.
  {label, 264}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '__bp_priv__array_range', 2, 273}.
  {label, 272}.
    {line, [{location, "std@io@random.erl", 25}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_priv__array_range'}, 2}.
  {label, 273}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__array_repeat', 2, 275}.
  {label, 274}.
    {line, [{location, "std@io@random.erl", 26}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_priv__array_repeat'}, 2}.
  {label, 275}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__base64UrlOf', 1, 277}.
  {label, 276}.
    {line, [{location, "std@io@random.erl", 27}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_priv__base64UrlOf'}, 1}.
  {label, 277}.
    {call_only, 1, {f, 31}}.

{function, '__bp_priv__floorWalk', 4, 279}.
  {label, 278}.
    {line, [{location, "std@io@random.erl", 28}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_priv__floorWalk'}, 4}.
  {label, 279}.
    {call_only, 4, {f, 13}}.

{function, '__bp_priv__hexDigit', 1, 281}.
  {label, 280}.
    {line, [{location, "std@io@random.erl", 29}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_priv__hexDigit'}, 1}.
  {label, 281}.
    {call_only, 1, {f, 27}}.

{function, '__bp_priv__hexOf', 1, 283}.
  {label, 282}.
    {line, [{location, "std@io@random.erl", 30}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_priv__hexOf'}, 1}.
  {label, 283}.
    {call_only, 1, {f, 29}}.

{function, '__bp_priv__randomByte', 0, 285}.
  {label, 284}.
    {line, [{location, "std@io@random.erl", 31}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_priv__randomByte'}, 0}.
  {label, 285}.
    {call_only, 0, {f, 23}}.

{function, '__bp_priv__randomBytesBody', 1, 287}.
  {label, 286}.
    {line, [{location, "std@io@random.erl", 32}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_priv__randomBytesBody'}, 1}.
  {label, 287}.
    {call_only, 1, {f, 21}}.

{function, '__bp_priv__randomBytesOf', 1, 289}.
  {label, 288}.
    {line, [{location, "std@io@random.erl", 33}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_priv__randomBytesOf'}, 1}.
  {label, 289}.
    {call_only, 1, {f, 25}}.

{function, '__bp_priv__secureTokenBody', 1, 291}.
  {label, 290}.
    {line, [{location, "std@io@random.erl", 34}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_priv__secureTokenBody'}, 1}.
  {label, 291}.
    {call_only, 1, {f, 17}}.

{function, '__bp_priv__shuffleBody', 1, 293}.
  {label, 292}.
    {line, [{location, "std@io@random.erl", 35}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_priv__shuffleBody'}, 1}.
  {label, 293}.
    {call_only, 1, {f, 15}}.

{function, '__bp_priv__uuidV4Body', 0, 295}.
  {label, 294}.
    {line, [{location, "std@io@random.erl", 36}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_priv__uuidV4Body'}, 0}.
  {label, 295}.
    {call_only, 0, {f, 19}}.

{function, '__bp_priv__wholeOf', 1, 297}.
  {label, 296}.
    {line, [{location, "std@io@random.erl", 37}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_priv__wholeOf'}, 1}.
  {label, 297}.
    {call_only, 1, {f, 33}}.

{function, '__bp_tpl_0-t/1-fun-0-', 1, 41}.
  {label, 40}.
    {func_info, {atom, std@io@random}, {atom, '__bp_tpl_0-t/1-fun-0-'}, 1}.
  {label, 41}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 0}, {y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {atom, exsplus}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, rand, seed, 2}, 2}.

{function, '__bp_tpl_0', 1, 37}.
  {label, 36}.
    {func_info, {atom, std@io@random}, {atom, '__bp_tpl_0'}, 1}.
  {label, 37}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 41}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_1', 1, 47}.
  {label, 46}.
    {func_info, {atom, std@io@random}, {atom, '__bp_tpl_1'}, 1}.
  {label, 47}.
    {allocate, 8, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {y, 2}}.
    {move, nil, {y, 4}}.
    {move, {y, 1}, {y, 5}}.
  {label, 52}.
    {move, {y, 5}, {x, 0}}.
    {test, is_nonempty_list, {f, 53}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 6}, {y, 5}}.
    {move, {y, 6}, {y, 0}}.
    {call_ext, 0, {extfunc, rand, uniform, 0}}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 7}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 2, 0}.
    {put_list, {y, 7}, {y, 4}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 52}}.
  {label, 53}.
    {move, {y, 5}, {x, 0}}.
    {test, is_nil, {f, 54}, [{x, 0}]}.
    {jump, {f, 51}}.
  {label, 54}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 5}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 51}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, sort, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
  {label, 55}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nonempty_list, {f, 56}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 3}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 55}, [{x, 0}]}.
    {test, test_arity, {f, 55}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 1, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, {y, 2}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 55}}.
  {label, 56}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nil, {f, 57}, [{x, 0}]}.
    {jump, {f, 50}}.
  {label, 57}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 3}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 50}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, '__bp_tpl_2', 1, 61}.
  {label, 60}.
    {func_info, {atom, std@io@random}, {atom, '__bp_tpl_2'}, 1}.
  {label, 61}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, crypto, strong_rand_bytes, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {literal, #{mode => urlsafe, padding => false}}, {x, 1}}.
    {call_ext_last, 2, {extfunc, base64, encode, 2}, 2}.

{function, '__bp_tpl_3-t/0-fun-0-', 0, 69}.
  {label, 68}.
    {func_info, {atom, std@io@random}, {atom, '__bp_tpl_3-t/0-fun-0-'}, 0}.
  {label, 69}.
    {allocate, 13, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {integer, 16}, {x, 0}}.
    {call_ext, 1, {extfunc, crypto, strong_rand_bytes, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_binary, {f, 72}, [{x, 0}]}.
    {gc_bif, byte_size, {f, 72}, 1, [{x, 0}], {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 72}, [{x, 0}, {integer, 16}]}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, binary, decode_unsigned, 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 96}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'bsr', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 4294967295}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'band', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 0}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 80}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'bsr', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {move, {integer, 65535}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'band', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 64}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'bsr', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {move, {integer, 4095}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'band', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 2}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 48}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'bsr', 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {move, {integer, 16383}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'band', 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {y, 3}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'bsr', 2}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {move, {integer, 281474976710655}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'band', 2}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {y, 4}}.
    {jump, {f, 73}}.
  {label, 72}.
    {move, {y, 5}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 73}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 32768}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'bor', 2}}.
    {move, {x, 0}, {y, 5}}.
    {test_heap, 10, 0}.
    {put_list, {y, 4}, nil, {x, 0}}.
    {put_list, {y, 5}, {x, 0}, {x, 0}}.
    {put_list, {y, 2}, {x, 0}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {put_list, {y, 0}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, [126, 56, 46, 49, 54, 46, 48, 98, 45, 126, 52, 46, 49, 54, 46, 48, 98, 45, 52, 126, 51, 46, 49, 54, 46, 48, 98, 45, 126, 52, 46, 49, 54, 46, 48, 98, 45, 126, 49, 50, 46, 49, 54, 46, 48, 98]}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 13}.

{function, '__bp_tpl_3', 0, 65}.
  {label, 64}.
    {func_info, {atom, std@io@random}, {atom, '__bp_tpl_3'}, 0}.
  {label, 65}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 69}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_4', 1, 77}.
  {label, 76}.
    {func_info, {atom, std@io@random}, {atom, '__bp_tpl_4'}, 1}.
  {label, 77}.
    {allocate, 7, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, crypto, strong_rand_bytes, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
  {label, 81}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nonempty_list, {f, 82}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 3}}.
    {move, {y, 5}, {y, 0}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, [126, 50, 46, 49, 54, 46, 48, 98]}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 2}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 81}}.
  {label, 82}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nil, {f, 83}, [{x, 0}]}.
    {jump, {f, 80}}.
  {label, 83}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 3}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 80}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, list_to_binary, 1}, 7}.

{function, '-bp_at-', 2, 107}.
  {label, 106}.
    {line, [{location, "std@io@random.erl", 9}]}.
    {func_info, {atom, std@io@random}, {atom, '-bp_at-'}, 2}.
  {label, 107}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 109}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 108}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 109}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 108}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 108}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_print', 1, 141}.
  {label, 140}.
    {line, [{location, "std@io@random.erl", 17}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_print'}, 1}.
  {label, 141}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 145}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 145}.
  {label, 144}.
    {line, [{location, "std@io@random.erl", 17}]}.
    {func_info, {atom, std@io@random}, {atom, '-bp_show_top-'}, 1}.
  {label, 145}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 143}}.

{function, '-bp_show_elem-', 1, 147}.
  {label, 146}.
    {line, [{location, "std@io@random.erl", 17}]}.
    {func_info, {atom, std@io@random}, {atom, '-bp_show_elem-'}, 1}.
  {label, 147}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 143}}.

{function, '__bp_show', 2, 143}.
  {label, 142}.
    {line, [{location, "std@io@random.erl", 17}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_show'}, 2}.
  {label, 143}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 155}, [{x, 0}]}.
    {test, is_eq, {f, 154}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 154}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 155}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 156}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 147}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 93}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 91}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 156}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 158}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 157}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 157}, [{x, 0}]}.
    {test, is_ne_exact, {f, 157}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 157}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 157}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 162}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 163}}.
  {label, 162}.
    {test, is_eq_exact, {f, 159}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 163}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 143}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 157}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 147}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 40}, {x, 0}, {x, 0}}.
    {put_list, {integer, 35}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 158}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 160}, [{x, 0}]}.
    {test, is_ne_exact, {f, 160}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 160}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 161}, [{x, 0}, {atom, undefined}]}.
  {label, 159}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 149}, 2}.
  {label, 160}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 161}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 149}.
  {label, 148}.
    {line, [{location, "std@io@random.erl", 17}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_tagged'}, 2}.
  {label, 149}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 164}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 164}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 164}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 165}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 151}, 3}.
  {label, 165}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 151}.
  {label, 150}.
    {line, [{location, "std@io@random.erl", 17}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_render'}, 1}.
  {label, 151}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 166}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 166}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 167}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 167}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 153}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {y, 1}, {x, 1}, {x, 1}}.
    {put_list, {integer, 40}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_render_pair-', 1, 153}.
  {label, 152}.
    {line, [{location, "std@io@random.erl", 17}]}.
    {func_info, {atom, std@io@random}, {atom, '-bp_render_pair-'}, 1}.
  {label, 153}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 143}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 6, 1}.
    {put_list, {y, 1}, nil, {x, 1}}.
    {put_list, {literal, <<": ">>}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_stringify-', 1, 169}.
  {label, 168}.
    {line, [{location, "std@io@random.erl", 17}]}.
    {func_info, {atom, std@io@random}, {atom, '-bp_stringify-'}, 1}.
  {label, 169}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 170}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 170}.
    {test, is_integer, {f, 171}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 171}.
    {call, 1, {f, 145}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '__bp_tpl_5-t/2-fun-0-', 2, 182}.
  {label, 181}.
    {func_info, {atom, std@io@random}, {atom, '__bp_tpl_5-t/2-fun-0-'}, 2}.
  {label, 182}.
    {allocate, 8, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 0}}.
    {jump, {f, 186}}.
  {label, 186}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 188}}.
  {label, 188}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 190}, [{x, 0}, {atom, true}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 6}}.
    {jump, {f, 189}}.
  {label, 190}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 191}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {y, 6}}.
    {jump, {f, 189}}.
  {label, 191}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 189}.
    {move, {y, 6}, {y, 2}}.
    {jump, {f, 193}}.
  {label, 193}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 194}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 5}}.
    {jump, {f, 196}}.
  {label, 194}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 195}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 5}}.
    {jump, {f, 196}}.
  {label, 195}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 6}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 196}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 198}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nth, 2}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 8}.
  {label, 198}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 199}, [{x, 0}, {atom, false}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 199}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_5', 2, 178}.
  {label, 177}.
    {func_info, {atom, std@io@random}, {atom, '__bp_tpl_5'}, 2}.
  {label, 178}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 182}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-hexOf/1-fun-0-', 1, 202}.
  {label, 201}.
    {line, [{location, "std@io@random.erl", 22}]}.
    {func_info, {atom, std@io@random}, {atom, '-hexOf/1-fun-0-'}, 1}.
  {label, 202}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 0}, {integer, 16}], {x, 0}}.
    {call, 1, {f, 27}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 0}, {integer, 16}], {x, 0}}.
    {test, is_ge, {f, 203}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 203}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 204}}.
  {label, 203}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/io/random.bp:368:40">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 204}.
    {call, 1, {f, 27}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 169}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 2}.
    return.

{function, '-bp_join-', 2, 206}.
  {label, 205}.
    {line, [{location, "std@io@random.erl", 22}]}.
    {func_info, {atom, std@io@random}, {atom, '-bp_join-'}, 2}.
  {label, 206}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 169}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 1}.

{function, '__bp_prim_append', 2, 91}.
  {label, 90}.
    {line, [{location, "std@io@random.erl", 24}]}.
    {func_info, {atom, std@io@random}, {atom, '__bp_prim_append'}, 2}.
  {label, 91}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 271}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 271}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- std/io/fs.bp
```botopink
//// std/io/fs — the file system, cross-backend (decision 540).
////
//// Reference:
////   Rust     — https://doc.rust-lang.org/std/fs/ (`read`, `read_to_string`,
////              `File`, `io::ErrorKind`)
////   Java     — https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/nio/file/Files.html
////   Erlang   — https://www.erlang.org/doc/man/file.html
////   Node.js  — https://nodejs.org/api/fs.html
////
//// Every function that can fail answers `Result<…, FsError>`: the same OS error is
//// the same `FsError` variant on every target (`ENOENT`, `enoent` → `NotFound`),
//// and `Other.message` is the host's own text. The whole-file shortcuts
//// (`readBytes`, `readText`, `writeBytes`, `writeText`, `appendText`), `stat`, and
//// the directory functions (`exists`, `list`, `mkdir`, `mkdirRecursive`, `rm`,
//// `removeTree`, `copy`, `walk`, `glob`) are followed by the handle: `open`
//// and `create` answer a `File`, a `Closeable` closed by the writer with `defer`.
////
//// The host cells (`raw…`) write `result: true` (decisions 431, 490) and answer
//// `Result<R, HostError>` — Node's `ENOENT: …`, erlang's `enoent` as its `message` —
//// and `lift` reads that message as the `FsError` of the path the caller wrote
//// (decision 486); no cell catches by hand. All operations are synchronous
//// (`*Sync` on Node, blocking BIFs on Erlang, `wasi:filesystem` on wasm: the runner
//// preopens the root and the working directory, decision 992), and a path is read as
//// the process reads it — a relative one against the working directory — on every target.

import {path.relative, failure, failure.HostError, failure.HostErrorName, io.random, compiler};

// The error of every `io.fs` function (decision 540). `path` is the path the
// caller wrote (for `copy`, the source; for `walk`, the root).
pub type FsError {
    NotFound(path: string),
    PermissionDenied(path: string),
    IsDirectory(path: string),
    NotDirectory(path: string),
    AlreadyExists(path: string),
    // `readText` / `text` / `lines` on bytes that are not UTF-8: `offset` is
    // the byte, in what was read, where the first invalid sequence starts.
    InvalidUtf8(path: string, offset: i64),
    // Any other host error; `message` is the host's text.
    Other(path: string, message: string),

    // The error's text (decision 563): `<what>: <path>`, the same on every target.
    pub fn message(self: Self) -> string {
        return case self {
            NotFound(path: path) -> "not found: " + path;
            PermissionDenied(path: path) -> "permission denied: " + path;
            IsDirectory(path: path) -> "is a directory: " + path;
            NotDirectory(path: path) -> "not a directory: " + path;
            AlreadyExists(path: path) -> "already exists: " + path;
            InvalidUtf8(path: path, offset: offset) -> "not UTF-8: "
                + path
                + " at byte "
                + offset.toString();
            Other(path: path, message: message) -> path + ": " + message;
        };
    }
}

pub type FileStat(
    size: i64,
    mtime: i64,
    isDir: bool,
)

// Read the whole file as bytes.
// Node: `readFileSync($0)` copied into a plain `Uint8Array`.
// Erlang: `file:read_file/1`.
#[compiler.external(
    .JavaScript("""(() => { return new Uint8Array(require('fs').readFileSync($0)) })()""", result: true),
    .Erlang("""(fun(__P) -> case file:read_file(__P) of {ok, __B} -> {ok, __B}; {error, __R} -> {error, __R} end end)($0)""", result: true),
    .Wasm(body: readBytesWasm),
)]
declare fn rawReadBytes(path: string) -> Result<bytes, HostError>;

// Write `contents` to `path`, creating or truncating.
// Node: `writeFileSync($0, $1)`. Erlang: `file:write_file/2`.
#[compiler.external(
    .JavaScript("""(() => { require('fs').writeFileSync($0, $1); return 0 })()""", result: true),
    .Erlang("""(fun(__P, __C) -> case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)($0, $1)""", result: true),
    .Wasm(body: writeBytesWasm),
)]
declare fn rawWriteBytes(path: string, contents: bytes) -> Result<i32, HostError>;

// Append `contents` to `path`, creating it when it is not there.
// Node: `appendFileSync($0, $1)`. Erlang: `file:write_file/3` with `append`.
#[compiler.external(
    .JavaScript("""(() => { require('fs').appendFileSync($0, $1); return 0 })()""", result: true),
    .Erlang("""(fun(__P, __C) -> case file:write_file(__P, __C, [append]) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)($0, $1)""", result: true),
    .Wasm(body: appendTextWasm),
)]
declare fn rawAppendText(path: string, contents: string) -> Result<i32, HostError>;

// The offset of the first byte that starts a sequence that is not UTF-8 (a byte no sequence
// starts with, a sequence cut short, an overlong form, a surrogate, a code point past U+10FFFF),
// or -1 when every byte is part of a valid sequence — the same offset on every target.
// Node: a scan of the bytes. Erlang: `unicode:characters_to_binary/3`, whose `Good` prefix is the offset.
#[compiler.external(
    .JavaScript("""((__b) => { const __n = __b.length; let __i = 0; while (__i < __n) { const __c = __b[__i]; if (__c < 128) { __i++; continue } let __k; if (__c >= 194 && __c <= 223) __k = 1; else if (__c >= 224 && __c <= 239) __k = 2; else if (__c >= 240 && __c <= 244) __k = 3; else return __i; if (__i + __k >= __n) return __i; let __lo = 128, __hi = 191; if (__c === 224) __lo = 160; else if (__c === 237) __hi = 159; else if (__c === 240) __lo = 144; else if (__c === 244) __hi = 143; const __d = __b[__i + 1]; if (__d < __lo || __d > __hi) return __i; for (let __j = 2; __j <= __k; __j++) { const __e = __b[__i + __j]; if (__e < 128 || __e > 191) return __i } __i += __k + 1 } return -1 })($0)"""),
    .Erlang("""(fun(__B) -> case unicode:characters_to_binary(__B, utf8, utf8) of __S when is_binary(__S) -> -1; {error, __G, _} -> byte_size(__G); {incomplete, __G, _} -> byte_size(__G) end end)($0)"""),
    .Wasm(body: utf8OffsetWasm),
)]
declare fn utf8Offset(bytes: bytes) -> i64;

// `line` without its line terminator: one trailing `\n`, and the `\r` before it.
// Node: `subarray`. Erlang: `binary:part/3`.
#[compiler.external(
    .JavaScript("""((__b) => { let __n = __b.length; if (__n > 0 && __b[__n - 1] === 10) { __n--; if (__n > 0 && __b[__n - 1] === 13) __n-- } return __b.subarray(0, __n) })($0)"""),
    .Erlang("""(fun(__B) -> __N = byte_size(__B), if __N >= 2 -> case binary:part(__B, __N - 2, 2) of <<13, 10>> -> binary:part(__B, 0, __N - 2); <<_, 10>> -> binary:part(__B, 0, __N - 1); _ -> __B end; __N =:= 1 -> case __B of <<10>> -> <<>>; _ -> __B end; true -> __B end end)($0)"""),
    .Wasm(body: stripEolWasm),
)]
declare fn stripEol(line: bytes) -> bytes;

// The handle of the file at `path`, open for reading. A directory is `isdir` on both hosts
// (Node opens one; the template refuses it). The handle is host-owned and opaque: a `{ fd,
// mem, pos, buf }` object on Node, an io device on Erlang (a stream reads it in its own process).
#[compiler.external(
    .JavaScript("""(() => { const __fs = require('fs'); const __p = $0; const __fd = __fs.openSync(__p, 'r'); if (__fs.fstatSync(__fd).isDirectory()) { __fs.closeSync(__fd); throw new Error('EISDIR: illegal operation on a directory, open ' + JSON.stringify(__p)) } return { fd: __fd, mem: null, pos: 0, buf: new Uint8Array(0) } })()""", result: true),
    .Erlang("""(fun(__P) -> case file:open(__P, [read, binary, read_ahead]) of {ok, __F} -> {ok, __F}; {error, __R} -> {error, __R} end end)($0)""", result: true),
    .Wasm(body: openWasm),
)]
declare fn rawOpen(path: string) -> Result<unknown, HostError>;

// The handle of the file at `path`, open for writing: created, or truncated.
#[compiler.external(
    .JavaScript("""(() => { const __fd = require('fs').openSync($0, 'w'); return { fd: __fd, mem: null, pos: 0, buf: new Uint8Array(0) } })()""", result: true),
    .Erlang("""(fun(__P) -> case file:open(__P, [write, binary, raw]) of {ok, __F} -> {ok, __F}; {error, __R} -> {error, __R} end end)($0)""", result: true),
    .Wasm(body: createWasm),
)]
declare fn rawCreate(path: string) -> Result<unknown, HostError>;

// A handle over bytes held in memory — what an `Asset` opens as. The position is a field
// on Node and a `counters` cell on Erlang.
#[compiler.external(
    .JavaScript("""({ fd: -1, mem: $0, pos: 0, buf: new Uint8Array(0) })"""),
    .Erlang("""{mem, $0, counters:new(1, [])}"""),
    .Wasm(body: memHandleWasm),
)]
declare fn memHandle(bytes: bytes) -> unknown;

// The size of the file behind `handle`, in bytes. On Erlang it reads `path`.
#[compiler.external(
    .JavaScript("""(() => { const __h = $0; return __h.mem ? __h.mem.length : require('fs').fstatSync(__h.fd).size })()""", result: true),
    .Erlang("""(fun(__H, __P) -> case __H of {mem, __B, _} -> {ok, byte_size(__B)}; _ -> case file:read_file_info(__P) of {ok, __I} -> {ok, element(2, __I)}; {error, __R} -> {error, __R} end end end)($0, $1)""", result: true),
    .Wasm(body: sizeWasm),
)]
declare fn rawSize(handle: unknown, path: string) -> Result<i64, HostError>;

// Up to `n` bytes (n > 0) from the handle's position; empty at the end.
#[compiler.external(
    .JavaScript("""(() => { const __more = (h, n) => { if (h.mem) { const r = h.mem.subarray(h.pos, h.pos + n); h.pos += r.length; return r } const b = new Uint8Array(n); const k = require('fs').readSync(h.fd, b, 0, n, null); return b.subarray(0, k) }; const __h = $0; const __n = $1; if (__h.buf.length > 0) { const __k = Math.min(__n, __h.buf.length); const __o = new Uint8Array(__h.buf.subarray(0, __k)); __h.buf = __h.buf.subarray(__k); return __o } return new Uint8Array(__more(__h, __n)) })()""", result: true),
    .Erlang("""(fun(__H, __N) -> case __H of {mem, __B, __C} -> __Pos = counters:get(__C, 1), __Len = min(__N, byte_size(__B) - __Pos), counters:add(__C, 1, __Len), {ok, binary:part(__B, __Pos, __Len)}; _ -> case file:read(__H, __N) of {ok, __D} -> {ok, __D}; eof -> {ok, <<>>}; {error, __R} -> {error, __R} end end end)($0, $1)""", result: true),
    .Wasm(body: readWasm),
)]
declare fn rawRead(handle: unknown, n: i32) -> Result<bytes, HostError>;

// Every byte from the handle's position to the end.
#[compiler.external(
    .JavaScript("""(() => { const __more = (h, n) => { if (h.mem) { const r = h.mem.subarray(h.pos, h.pos + n); h.pos += r.length; return r } const b = new Uint8Array(n); const k = require('fs').readSync(h.fd, b, 0, n, null); return b.subarray(0, k) }; const __h = $0; const __parts = []; if (__h.buf.length > 0) { __parts.push(__h.buf); __h.buf = new Uint8Array(0) } for (;;) { const __r = __more(__h, 65536); if (__r.length === 0) break; __parts.push(new Uint8Array(__r)) } let __t = 0; for (const __x of __parts) __t += __x.length; const __o = new Uint8Array(__t); let __p = 0; for (const __x of __parts) { __o.set(__x, __p); __p += __x.length } return __o })()""", result: true),
    .Erlang("""(fun(__H) -> case __H of {mem, __B, __C} -> __Pos = counters:get(__C, 1), counters:add(__C, 1, byte_size(__B) - __Pos), {ok, binary:part(__B, __Pos, byte_size(__B) - __Pos)}; _ -> (fun __L(__Acc) -> case file:read(__H, 65536) of {ok, __D} -> __L([__Acc, __D]); eof -> {ok, iolist_to_binary(__Acc)}; {error, __R} -> {error, __R} end end)([]) end end)($0)""", result: true),
    .Wasm(body: readAllWasm),
)]
declare fn rawReadAll(handle: unknown) -> Result<bytes, HostError>;

// The next line, terminator included; empty at the end.
#[compiler.external(
    .JavaScript("""(() => { const __more = (h, n) => { if (h.mem) { const r = h.mem.subarray(h.pos, h.pos + n); h.pos += r.length; return r } const b = new Uint8Array(n); const k = require('fs').readSync(h.fd, b, 0, n, null); return b.subarray(0, k) }; const __h = $0; for (;;) { const __i = __h.buf.indexOf(10); if (__i >= 0) { const __l = new Uint8Array(__h.buf.subarray(0, __i + 1)); __h.buf = __h.buf.subarray(__i + 1); return __l } const __r = __more(__h, 65536); if (__r.length === 0) { const __l = __h.buf; __h.buf = new Uint8Array(0); return __l } const __nb = new Uint8Array(__h.buf.length + __r.length); __nb.set(__h.buf, 0); __nb.set(__r, __h.buf.length); __h.buf = __nb } })()""", result: true),
    .Erlang("""(fun(__H) -> case __H of {mem, __B, __C} -> __Pos = counters:get(__C, 1), __Rest = binary:part(__B, __Pos, byte_size(__B) - __Pos), case binary:match(__Rest, <<10>>) of nomatch -> counters:add(__C, 1, byte_size(__Rest)), {ok, __Rest}; {__At, _} -> counters:add(__C, 1, __At + 1), {ok, binary:part(__Rest, 0, __At + 1)} end; _ -> case file:read_line(__H) of {ok, __D} -> {ok, __D}; eof -> {ok, <<>>}; {error, __R} -> {error, __R} end end end)($0)""", result: true),
    .Wasm(body: readLineWasm),
)]
declare fn rawReadLine(handle: unknown) -> Result<bytes, HostError>;

// The SHA-256 of the whole file behind the handle, lowercase hex — from its first byte,
// whatever the position, which it leaves where it was. On Erlang `file:pread` leaves the
// position undefined (OTP moves it), so the position is read first and restored.
#[compiler.external(
    .JavaScript("""(() => { const __h = $0; const __hs = require('crypto').createHash('sha256'); if (__h.mem) { __hs.update(__h.mem) } else { const __b = new Uint8Array(65536); let __pos = 0; for (;;) { const __k = require('fs').readSync(__h.fd, __b, 0, 65536, __pos); if (__k === 0) break; __hs.update(__b.subarray(0, __k)); __pos += __k } } return __hs.digest('hex') })()""", result: true),
    .Erlang("""(fun(__H) -> case __H of {mem, __B, _} -> {ok, string:lowercase(binary:encode_hex(crypto:hash(sha256, __B)))}; _ -> {ok, __Cur} = file:position(__H, cur), __L = fun __Lp(__Pos, __Ctx) -> case file:pread(__H, __Pos, 65536) of {ok, __D} -> __Lp(__Pos + byte_size(__D), crypto:hash_update(__Ctx, __D)); eof -> crypto:hash_final(__Ctx); {error, __R} -> erlang:error(__R) end end, __Digest = __L(0, crypto:hash_init(sha256)), {ok, _} = file:position(__H, __Cur), {ok, string:lowercase(binary:encode_hex(__Digest))} end end)($0)""", result: true),
    .Wasm(body: hashWasm),
)]
declare fn rawHash(handle: unknown) -> Result<string, HostError>;

// Write `bytes` at the handle's position; answers how many.
#[compiler.external(
    .JavaScript("""(() => { const __h = $0; const __b = $1; let __o = 0; while (__o < __b.length) __o += require('fs').writeSync(__h.fd, __b, __o, __b.length - __o); return __b.length })()""", result: true),
    .Erlang("""(fun(__H, __B) -> case file:write(__H, __B) of ok -> {ok, byte_size(__B)}; {error, __R} -> {error, __R} end end)($0, $1)""", result: true),
    .Wasm(body: writeWasm),
)]
declare fn rawWrite(handle: unknown, bytes: bytes) -> Result<i32, HostError>;

// Close the handle. A failure to close is not reported (a `Closeable`'s `close` answers nothing).
#[compiler.external(
    .JavaScript("""(() => { const __h = $0; if (!__h.mem) require('fs').closeSync(__h.fd); return 0 })()""", result: true),
    .Erlang("""(fun(__H) -> case __H of {mem, _, _} -> {ok, 0}; _ -> case file:close(__H) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end end)($0)""", result: true),
    .Wasm(body: closeWasm),
)]
declare fn rawClose(handle: unknown) -> Result<i32, HostError>;

// Write `contents` to `path`, creating or truncating. Reds with the
// host's I/O error message.
// Node: `require('fs').writeFileSync($0, $1)`.
// Erlang: `file:write_file/2`.
#[compiler.external(
    .JavaScript("""(() => { require('fs').writeFileSync($0, $1); return 0 })()""", result: true),
    .Erlang("""(fun(__P, __C) -> case file:write_file(__P, __C) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)($0, $1)""", result: true),
    .Wasm(body: writeTextWasm),
)]
declare fn rawWriteText(
    path: string,
    contents: string,
) -> Result<i32, HostError>;

// Whether a path exists, of any kind: a regular file, a directory, a
// character or block device (`/dev/null`), a FIFO or a socket. A symbolic
// link is followed — one whose target is missing is `false`, the answer
// every read through it would give.
// Node: `require('fs').existsSync($0)` (a `stat`).
// Erlang: `file:read_file_info/1` (a `stat`; `filelib:is_file/1`, which it
// replaces, answers only regular files and directories, so `/dev/null`
// was `false` on erlang and `true` on commonJS).
#[compiler.external(
    .JavaScript("""require('fs').existsSync($0)"""),
    .Erlang("""(case file:read_file_info($0) of {ok, _} -> true; _ -> false end)"""),
    .Wasm(body: existsWasm),
)]
pub declare fn exists(path: string) -> bool;

// List the names of the directory entries at `path` (relative).
// Node: `require('fs').readdirSync($0)`.
// Erlang: `file:list_dir/1` returns `{ok, [string()]}`, in the directory's
// order: sorted here by bytes (`lists:sort` on binaries), as `readdirSync` and
// wasm's `listWasm` answer them, so every target lists one order (decision 992).
#[compiler.external(
    .JavaScript("""(() => { return require('fs').readdirSync($0) })()""", result: true),
    .Erlang("""(fun(__P) -> case file:list_dir(__P) of {ok, __L} -> {ok, lists:sort([list_to_binary(__N) || __N <- __L])}; {error, __R} -> {error, __R} end end)($0)""", result: true),
    .Wasm(body: listWasm),
)]
declare fn rawList(path: string) -> Result<string[], HostError>;

// Create directory at `path`. Use `mkdirRecursive` to create
// intermediate parents.
// Node: `require('fs').mkdirSync($0)`.
// Erlang: `file:make_dir/1`.
#[compiler.external(
    .JavaScript("""(() => { require('fs').mkdirSync($0); return 0 })()""", result: true),
    .Erlang("""(fun(__P) -> case file:make_dir(__P) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)($0)""", result: true),
    .Wasm(body: mkdirWasm),
)]
declare fn rawMkdir(path: string) -> Result<i32, HostError>;

// Create the directory at `path` and every missing directory above it. A
// directory that is already there is `Ok` too; a path that exists as anything
// else (a file) is an `Error`. What the snapshot library (`snap`) makes the
// directory of a `.snap` with (decision 391).
// Node: `require('fs').mkdirSync($0, { recursive: true })`.
// Erlang: `filelib:ensure_path/1`.
#[compiler.external(
    .JavaScript("""(() => { require('fs').mkdirSync($0, { recursive: true }); return 0 })()""", result: true),
    .Erlang("""(fun(__P) -> case filelib:ensure_path(__P) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end)($0)""", result: true),
    .Wasm(body: mkdirRecursiveWasm),
)]
declare fn rawMkdirRecursive(path: string) -> Result<i32, HostError>;

// Delete the FILE at `path`. A directory — empty or not — is `IsDirectory` on
// both hosts (Node's `ERR_FS_EISDIR`; Erlang's `eperm` is read as `eisdir` after
// a `read_link_info`, so the variant is the same); `removeTree` removes one.
// Node: `require('fs').rmSync($0)`.
// Erlang: `file:delete/1`.
#[compiler.external(
    .JavaScript("""(() => { require('fs').rmSync($0); return 0 })()""", result: true),
    .Erlang("""(fun(__P) -> case file:read_link_info(__P) of {ok, __I} when element(3, __I) =:= directory -> {error, eisdir}; _ -> case file:delete(__P) of ok -> {ok, 0}; {error, __R} -> {error, __R} end end end)($0)""", result: true),
    .Wasm(body: rmWasm),
)]
declare fn rawRm(path: string) -> Result<i32, HostError>;

// Copy file from `src` to `dest`. Reds when `src` is missing or
// `dest` already exists (Node's default `copyFileSync` semantics).
// Node: `require('fs').copyFileSync($0, $1)`.
// Erlang: `file:copy/2` (returns `{ok, BytesCopied}` or `{error, _}`).
#[compiler.external(
    .JavaScript("""(() => { require('fs').copyFileSync($0, $1); return 0 })()""", result: true),
    .Erlang("""(fun(__S, __D) -> case file:copy(__S, __D) of {ok, _} -> {ok, 0}; {error, __R} -> {error, __R} end end)($0, $1)""", result: true),
    .Wasm(body: copyWasm),
)]
declare fn rawCopy(src: string, dest: string) -> Result<i32, HostError>;

// File metadata. Returns a `FileStat { size, mtime, isDir }` on
// success. `mtime` is epoch milliseconds (matching `time.nowMillis()`);
// `size` is in bytes.
// Node: `statSync($0, { bigint: true })`, so `size` and the nanosecond
// `mtimeNs` arrive exact at any size; `mtime` is `mtimeNs` floored to whole
// seconds, × 1000, and both answer decision 319's canonical form (a `number`
// within ±(2^53 − 1), a `BigInt` beyond) — never a `number` rounded past 2^53.
// Erlang: `file:read_file_info/1` returns a `#file_info` record; the
// template projects the `size`, `mtime`, and `type` fields. Its `mtime` is
// whole seconds × 1000. One value on every target: whole seconds (decision 499).
#[compiler.external(
    .JavaScript("""(() => { const __s = require('fs').statSync($0, { bigint: true }); const __c = (__v) => (__v >= -9007199254740991n && __v <= 9007199254740991n) ? Number(__v) : __v; const __ns = __s.mtimeNs; return { size: __c(__s.size), mtime: __c(((__ns - (((__ns % 1000000000n) + 1000000000n) % 1000000000n)) / 1000000000n) * 1000n), isDir: __s.isDirectory() } })()""", result: true),
    .Erlang("""(fun(__P) -> case file:read_file_info(__P, [{time, posix}]) of {ok, {file_info, __Sz, __Ty, _, _, __Mt, _, _, _, _, _, _, _, _}} -> {ok, #{size => __Sz, mtime => __Mt * 1000, isDir => (__Ty =:= directory)}}; {error, __R} -> {error, __R} end end)($0)""", result: true),
    .Wasm(body: statWasm),
)]
declare fn rawStat(path: string) -> Result<FileStat, HostError>;

// ── 1.0.10-beta front 01 additions ──────────────────────────────────────────

// Every REGULAR FILE under `root`, recursively, as paths relative to `root`
// with `/` separators, sorted — the same set on both targets (the two hosts
// walk in different orders, so the list is sorted rather than left as found),
// and the same paths however the root is spelled: `dir`, `dir/`, `dir/.`,
// `./dir`, `dir/sub/..`, absolute or relative to the working directory.
// Directories are not listed; a link is followed (a link to a file is listed
// under its own name, a link to a directory is walked). An `Error`: a missing
// or non-directory `root`, a directory under it that cannot be read, and a
// DANGLING link (decision 178) — `fs.walk: dangling link "<relative path>"`,
// the same text on both targets, naming the first one in sorted order.
// Node: `readdirSync(root, { recursive: true })` answers files AND directories
// relative to `root`; the template sorts them, keeps the entries `statSync`
// says are files, and answers the dangling-link `Error` for the first entry
// `statSync` cannot find (`throwIfNoEntry: false`).
// Erlang: the template walks `file:list_dir/1` itself and BUILDS each relative
// path from the names it descended through. It never cuts a prefix off a full
// path: `filelib:fold_files/5` answers full paths `filename:join/2` has
// normalised (`dir/.` + `app` is `dir/app`), so a prefix measured on the root
// as written cut two characters too many when the root ended in `/.`.
#[compiler.external(
    .JavaScript("""(() => { const __fs = require('fs'); const __p = require('path'); const __all = __fs.readdirSync($0, { recursive: true }).map(__f => String(__f).split(__p.sep).join('/')).sort(); const __out = []; const __dng = []; for (const __f of __all) { const __s = __fs.statSync(__p.join($0, __f), { throwIfNoEntry: false }); if (__s === undefined) { __dng.push(__f); continue } if (__s.isFile()) __out.push(__f) } return { files: __out, dangling: __dng } })()""", result: true),
    .Erlang("""(fun(__R) -> __Root = unicode:characters_to_list(__R), case filelib:is_dir(__Root) of false -> {error, case file:read_file_info(__Root) of {ok, _} -> enotdir; {error, __X0} -> __X0 end}; true -> __Walk = fun __W(__Dir, __Rel, __Acc) -> case file:list_dir(__Dir) of {error, __E} -> erlang:error(__E); {ok, __Names} -> lists:foldl(fun(__Name, __A) -> __Full = filename:join(__Dir, __Name), __Sub = case __Rel of [] -> __Name; _ -> __Rel ++ "/" ++ __Name end, case file:read_file_info(__Full) of {ok, __I} when element(3, __I) =:= directory -> __W(__Full, __Sub, __A); {ok, __I} when element(3, __I) =:= regular -> [{file, unicode:characters_to_binary(__Sub)} | __A]; {ok, _} -> __A; {error, enoent} -> [{dangling, unicode:characters_to_binary(__Sub)} | __A]; {error, __X} -> erlang:error(__X) end end, __Acc, __Names) end end, __Found = __Walk(__Root, [], []), {ok, #{files => lists:sort([__F || {file, __F} <- __Found]), dangling => lists:sort([__D || {dangling, __D} <- __Found])}} end end)($0)""", result: true),
    .Wasm(body: walkWasm),
)]
declare fn rawWalk(root: string) -> Result<Walked, HostError>;

// The entries under `root` matching the glob `pattern`, as paths relative to
// `root` with `/` separators, sorted, each once. The pattern is read segment
// by segment, by ONE rule on both targets (decision 177 — the narrower of what
// the two hosts did):
//   - `**` is zero or more directories; a segment with `*`, `?`, `[…]` or
//     `{a,b}` matches the names of one directory; any other segment is a name.
//   - `*` and `**` (and `?`, `[…]`, `{…}`) do NOT match a name that starts
//     with `.` — a segment matches one only when the segment itself starts
//     with the dot (`.*`, `.config/*.json`).
//   - the walk does NOT descend through a link to a directory: `**` and a
//     wildcard segment continue into real directories only. The link is still
//     a NAME — `*` lists it — and a segment that names it (`linked/*.bp`) goes
//     through it, because the pattern wrote it.
//   - the last segment matches an entry of any kind (file, directory, link,
//     dangling or not); a final `**` is every entry at every depth; a trailing
//     `/` keeps real directories only.
// An alternative of `{a,b}` cannot hold a `/` (the pattern is split first). A
// root that does not exist answers `Ok([])`; so does a directory that cannot
// be read. Both cells are the same walk; only the match of ONE segment against
// ONE directory is the host's — `fs.globSync(segment, { cwd })` (Node 22+),
// `filelib:wildcard/2` — with the dot rule applied over its answer, since
// `filelib:wildcard` matches dot names and `globSync` matches `{.a,b}`.
#[compiler.external(
    .JavaScript("""(() => { const __fs = require('fs'); const __p = require('path'); const __root = $1; const __pat = String($0); const __segs = __pat.split('/').filter(__s => __s !== '' && __s !== '.'); const __dirsOnly = __pat.endsWith('/'); const __lst = (__f) => { try { return __fs.lstatSync(__f, { throwIfNoEntry: false }) } catch (__e) { return undefined } }; const __realDir = (__f) => { const __s = __lst(__f); return __s !== undefined && __s.isDirectory() }; const __linkedDir = (__f) => { try { const __s = __fs.statSync(__f, { throwIfNoEntry: false }); return __s !== undefined && __s.isDirectory() } catch (__e) { return false } }; const __magic = (__s) => __s.includes('*') || __s.includes('?') || __s.includes('[') || __s.includes('{'); const __names = (__dir, __seg) => { let __all; try { __all = (__seg === '*' ? __fs.readdirSync(__dir) : __fs.globSync(__seg, { cwd: __dir })).map(String) } catch (__e) { __all = [] } return __all.filter(__n => !__n.startsWith('.') || __seg.startsWith('.')) }; const __join = (__rel, __n) => __rel === '' ? __n : __rel + '/' + __n; const __out = new Set(); const __walk = (__i, __dir, __rel) => { if (__i === __segs.length) { if (__rel !== '') __out.add(__rel); return } const __seg = __segs[__i]; const __last = __i === __segs.length - 1; if (__seg === '**') { if (!__last) __walk(__i + 1, __dir, __rel); for (const __n of __names(__dir, '*')) { const __f = __p.join(__dir, __n); const __sub = __join(__rel, __n); if (__last) __out.add(__sub); if (__realDir(__f)) __walk(__i, __f, __sub) } return } if (!__magic(__seg)) { const __f = __p.join(__dir, __seg); const __sub = __join(__rel, __seg); if (__last) { if (__lst(__f) !== undefined) __out.add(__sub) } else if (__linkedDir(__f)) __walk(__i + 1, __f, __sub); return } for (const __n of __names(__dir, __seg)) { const __f = __p.join(__dir, __n); const __sub = __join(__rel, __n); if (__last) __out.add(__sub); else if (__realDir(__f)) __walk(__i + 1, __f, __sub) } }; __walk(0, __root, ''); return Array.from(__out).filter(__r => !__dirsOnly || __realDir(__p.join(__root, __r))).sort() })()"""),
    .Erlang("""(fun(__P, __R) -> __Root = unicode:characters_to_list(__R), __Pat = unicode:characters_to_list(__P), __Segs = [__S || __S <- string:split(__Pat, "/", all), __S =/= [], __S =/= "."], __DirsOnly = lists:suffix("/", __Pat), __RealDir = fun(__F) -> case file:read_link_info(__F) of {ok, __I} -> element(3, __I) =:= directory; _ -> false end end, __Magic = fun(__S) -> lists:any(fun(__C) -> lists:member(__C, "*?[{") end, __S) end, __Names = fun(__Dir, __Seg) -> __All = case __Seg of "*" -> case file:list_dir(__Dir) of {ok, __L} -> __L; _ -> [] end; _ -> try filelib:wildcard(__Seg, __Dir) catch _:_ -> [] end end, [__N || __N <- __All, (hd(__N) =/= 46) orelse (hd(__Seg) =:= 46)] end, __Join = fun([], __N) -> __N; (__Rel, __N) -> __Rel ++ "/" ++ __N end, __Walk = fun __W([], _, [], __Acc) -> __Acc; __W([], _, __Rel, __Acc) -> [__Rel | __Acc]; __W(["**"], __Dir, __Rel, __Acc) -> lists:foldl(fun(__N, __A) -> __F = filename:join(__Dir, __N), __Sub = __Join(__Rel, __N), case __RealDir(__F) of true -> __W(["**"], __F, __Sub, [__Sub | __A]); false -> [__Sub | __A] end end, __Acc, __Names(__Dir, "*")); __W(["**" | __Rest] = __Pattern, __Dir, __Rel, __Acc) -> lists:foldl(fun(__N, __A) -> __F = filename:join(__Dir, __N), case __RealDir(__F) of true -> __W(__Pattern, __F, __Join(__Rel, __N), __A); false -> __A end end, __W(__Rest, __Dir, __Rel, __Acc), __Names(__Dir, "*")); __W([__Seg | __Rest], __Dir, __Rel, __Acc) -> case __Magic(__Seg) of false -> __F = filename:join(__Dir, __Seg), __Sub = __Join(__Rel, __Seg), case __Rest of [] -> case file:read_link_info(__F) of {ok, _} -> [__Sub | __Acc]; _ -> __Acc end; _ -> case filelib:is_dir(__F) of true -> __W(__Rest, __F, __Sub, __Acc); false -> __Acc end end; true -> lists:foldl(fun(__N, __A) -> __G = filename:join(__Dir, __N), __Under = __Join(__Rel, __N), case __Rest of [] -> [__Under | __A]; _ -> case __RealDir(__G) of true -> __W(__Rest, __G, __Under, __A); false -> __A end end end, __Acc, __Names(__Dir, __Seg)) end end, [unicode:characters_to_binary(__X) || __X <- lists:usort(__Walk(__Segs, __Root, [], [])), (not __DirsOnly) orelse __RealDir(filename:join(__Root, __X))] end)($0, $1)"""),
    .Wasm(body: globWasm),
)]
declare fn rawGlob(pattern: string, root: string) -> string[];

// Remove `path` and everything under it: a file, a link (the link, never its
// target) or a directory tree. A path that is not there is `Ok` too — the
// caller wanted it gone. What a test fixture is cleared with, and what the
// snapshot engine's tests clear their scratch directories with (1.0.11-beta
// front 97).
// Node: `rmSync(path, { recursive: true, force: true })`.
// Erlang: `file:del_dir_r/1`.
#[compiler.external(
    .JavaScript("""(() => { require('fs').rmSync($0, { recursive: true, force: true }); return 0 })()""", result: true),
    .Erlang("""(fun(__P) -> case file:del_dir_r(__P) of ok -> {ok, 0}; {error, enoent} -> {ok, 0}; {error, __R} -> {error, __R} end end)($0)""", result: true),
    .Wasm(body: removeTreeWasm),
)]
declare fn rawRemoveTree(path: string) -> Result<i32, HostError>;

// Internal, test scaffolding: a fresh, unique, empty directory under the
// host's tmpdir. Private — every `walk`/`glob` test makes its fixture tree in
// one of these and removes it with `removeTree`, so a run leaves nothing under
// the host's tmpdir.
#[compiler.external(
    .JavaScript("""require('fs').mkdtempSync(require('path').join(require('os').tmpdir(), 'bp-std-fs-'))"""),
    .Erlang("""(fun() -> __T = case os:getenv("TMPDIR") of false -> "/tmp"; __V -> __V end, __D = filename:join(__T, "bp-std-fs-" ++ integer_to_list(erlang:unique_integer([positive]))), ok = file:make_dir(__D), unicode:characters_to_binary(__D) end)()"""),
    .Wasm(body: scratchDirWasm),
)]
declare fn scratchDir() -> string;

// Internal, test scaffolding: the working directory (what a relative root is
// read against) and a symbolic link `link` → `target`.
#[compiler.external(
    .JavaScript("process.cwd()"),
    .Erlang("""(fun() -> {ok, __D} = file:get_cwd(), unicode:characters_to_binary(__D) end)()"""),
    .Wasm(body: workingDirWasm),
)]
declare fn workingDir() -> string;

#[compiler.external(
    .JavaScript("""require('fs').symlinkSync($0, $1)"""),
    .Erlang("""(fun(__T, __L) -> ok = file:make_symlink(__T, __L), ok end)($0, $1)"""),
    .Wasm(body: linkToWasm),
)]
declare fn linkTo(target: string, link: string) -> void;

// ── the typed error ──────────────────────────────────────────────────────────

// The `FsError` of `path` a host's failure is (decision 486), read from its code: Node's `ENOENT: …`, erlang's `enoent`.
fn fsError(path: string, e: HostError) -> FsError {
    val u = e.message.toUpper();
    if (u.startsWith("ENOENT")) return FsError.NotFound(path: path);
    if (u.startsWith("EACCES") || u.startsWith("EPERM"))
        return FsError.PermissionDenied(path: path);
    if (u.startsWith("EISDIR") || u.startsWith("PATH IS A DIRECTORY"))
        return FsError.IsDirectory(path: path);
    if (u.startsWith("ENOTDIR")) return FsError.NotDirectory(path: path);
    if (u.startsWith("EEXIST")) return FsError.AlreadyExists(path: path);
    return FsError.Other(path: path, message: e.message);
}

// A host cell's answer, its failure read as an `FsError` of `path`.
fn lift<T>(path: string, r: Result<T, HostError>) -> Result<T, FsError> {
    case r {
        Ok(v) -> return v;
        Error(e) -> throw fsError(path, e);
    }
}

// `lift` for each answer type: the generic one is the wasm backend's to specialise, and a
// `bytes` or a handle it does not (decision 992).
fn liftBytes(path: string, r: Result<bytes, HostError>) -> Result<bytes, FsError> {
    case r {
        Ok(v) -> return v;
        Error(e) -> throw fsError(path, e);
    }
}

fn liftI32(path: string, r: Result<i32, HostError>) -> Result<i32, FsError> {
    case r {
        Ok(v) -> return v;
        Error(e) -> throw fsError(path, e);
    }
}

fn liftI64(path: string, r: Result<i64, HostError>) -> Result<i64, FsError> {
    case r {
        Ok(v) -> return v;
        Error(e) -> throw fsError(path, e);
    }
}

fn liftString(path: string, r: Result<string, HostError>) -> Result<string, FsError> {
    case r {
        Ok(v) -> return v;
        Error(e) -> throw fsError(path, e);
    }
}

fn liftStrings(path: string, r: Result<string[], HostError>) -> Result<string[], FsError> {
    case r {
        Ok(v) -> return v;
        Error(e) -> throw fsError(path, e);
    }
}

fn liftStat(path: string, r: Result<FileStat, HostError>) -> Result<FileStat, FsError> {
    case r {
        Ok(v) -> return v;
        Error(e) -> throw fsError(path, e);
    }
}

fn liftWalked(path: string, r: Result<Walked, HostError>) -> Result<Walked, FsError> {
    case r {
        Ok(v) -> return v;
        Error(e) -> throw fsError(path, e);
    }
}

fn liftHandle(path: string, r: Result<unknown, HostError>) -> Result<unknown, FsError> {
    case r {
        Ok(v) -> return v;
        Error(e) -> throw fsError(path, e);
    }
}

// The text of `b`, or `InvalidUtf8` at the first invalid byte.
fn decode(path: string, b: bytes) -> Result<string, FsError> {
    val offset = utf8Offset(b);
    if (offset >= 0l) throw FsError.InvalidUtf8(path: path, offset: offset);
    return b.toUtf8().unwrapOr("");
}

// What `rawWalk` finds under a root: the regular files, and the links whose
// target is missing, both as paths relative to the root, sorted.
type Walked(
    files: string[],
    dangling: string[],
)

// Whether the handle is one over bytes held in memory (an `Asset`'s), which cannot be written.
#[compiler.external(
    .JavaScript("""(($0).mem != null)"""),
    .Erlang("""(case $0 of {mem, _, _} -> true; _ -> false end)"""),
    .Wasm(body: readOnlyWasm),
)]
declare fn rawReadOnly(handle: unknown) -> bool;

// ── whole-file shortcuts ─────────────────────────────────────────────────────

// The file's bytes.
pub fn readBytes(path: string) -> Result<bytes, FsError> {
    val b = try liftBytes(path, rawReadBytes(path));
    return b;
}

// The file as UTF-8 text. Bytes that are not UTF-8 are `InvalidUtf8` on every
// target — never node's silent U+FFFD nor erlang's unchecked binary.
pub fn readText(path: string) -> Result<string, FsError> {
    val b = try readBytes(path);
    val s = try decode(path, b);
    return s;
}

// Write `contents` to `path`, creating or truncating.
pub fn writeBytes(path: string, contents: bytes) -> Result<i32, FsError> {
    val n = try liftI32(path, rawWriteBytes(path, contents));
    return n;
}

pub fn writeText(path: string, contents: string) -> Result<i32, FsError> {
    val n = try liftI32(path, rawWriteText(path, contents));
    return n;
}

// Append `contents`, creating the file when it is not there.
pub fn appendText(path: string, contents: string) -> Result<i32, FsError> {
    val n = try liftI32(path, rawAppendText(path, contents));
    return n;
}

// ── metadata and directories ─────────────────────────────────────────────────

pub fn stat(path: string) -> Result<FileStat, FsError> {
    val s = try liftStat(path, rawStat(path));
    return s;
}

pub fn list(path: string) -> Result<string[], FsError> {
    val names = try liftStrings(path, rawList(path));
    return names;
}

pub fn mkdir(path: string) -> Result<i32, FsError> {
    val n = try liftI32(path, rawMkdir(path));
    return n;
}

pub fn mkdirRecursive(path: string) -> Result<i32, FsError> {
    val n = try liftI32(path, rawMkdirRecursive(path));
    return n;
}

pub fn rm(path: string) -> Result<i32, FsError> {
    val n = try liftI32(path, rawRm(path));
    return n;
}

pub fn removeTree(path: string) -> Result<i32, FsError> {
    val n = try liftI32(path, rawRemoveTree(path));
    return n;
}

pub fn copy(src: string, dest: string) -> Result<i32, FsError> {
    val n = try liftI32(src, rawCopy(src, dest));
    return n;
}

pub fn walk(root: string) -> Result<string[], FsError> {
    val found = try liftWalked(root, rawWalk(root));
    if (found.dangling.length > 0) {
        val first = found.dangling.at(0) ?? "";
        throw FsError.Other(path: root, message: ["fs.walk: dangling link \"", first, "\""].join(""));
    }
    return found.files;
}

pub fn glob(pattern: string, root: string) -> Result<string[], FsError> {
    return rawGlob(pattern, root);
}

// The host's handle over embedded bytes: read like a file, never closed on disk.
#[compiler.external(
    .JavaScript("""({ fd: -1, mem: $0, pos: 0, buf: new Uint8Array(0) })"""),
    .Erlang("""{mem, $0, counters:new(1, [])}"""),
    .Wasm(body: memHandleWasm),
)]
declare fn memoryHandle(bytes: bytes) -> unknown;

// ── the handle ───────────────────────────────────────────────────────────────

// An open file (decision 540 (3)). `location` is the path it was opened with and
// `handle` the host's — opaque, never read by a program. Closed by the writer:
// `val f = try fs.open(p); defer f.close();`.
pub type File(location: string, handle: unknown) implement Closeable {
    // The path the file was opened with.
    pub fn path(self: Self) -> string {
        return self.location;
    }

    // The file's size in bytes.
    pub fn size(self: Self) -> Result<i64, FsError> {
        val n = try liftI64(self.location, rawSize(self.handle, self.location));
        return n;
    }

    // Up to `n` bytes from the position; empty at the end of the file.
    pub fn read(self: Self, n: i32) -> Result<bytes, FsError> {
        if (n <= 0) return bytes.fromUtf8("");
        val b = try liftBytes(self.location, rawRead(self.handle, n));
        return b;
    }

    // Every byte from the position to the end.
    pub fn bytes(self: Self) -> Result<bytes, FsError> {
        val b = try liftBytes(self.location, rawReadAll(self.handle));
        return b;
    }

    // The rest of the file as UTF-8 text (`InvalidUtf8` otherwise).
    pub fn text(self: Self) -> Result<string, FsError> {
        val b = try self.bytes();
        val s = try decode(self.location, b);
        return s;
    }

    // The rest of the file in pieces of at most `size` bytes. An error ends the stream.
    pub async iter fn chunks(self: Self, size: i32 = 65536) -> AsyncIter<Result<bytes, FsError>> {
        while (true) {
            val b = try self.read(size);
            if (b.length == 0) break;
            yield b;
        }
    }

    // The rest of the file line by line, `\n` and `\r\n` stripped. A line that is not
    // UTF-8 ends the stream with `InvalidUtf8`, its offset counted from the first
    // line this call read.
    pub async iter fn lines(self: Self) -> AsyncIter<Result<string, FsError>> {
        var consumed = 0;
        while (true) {
            val raw = try liftBytes(self.location, rawReadLine(self.handle));
            if (raw.length == 0) break;
            val line = stripEol(raw);
            val offset = utf8Offset(line);
            if (offset >= 0l)
                throw FsError.InvalidUtf8(path: self.location, offset: consumed.toI64()
                    + offset);
            val width: i32 = raw.length;
            consumed = consumed + width;
            yield line.toUtf8().unwrapOr("");
        }
    }

    // The SHA-256 of the whole file, lowercase hex.
    pub fn hash(self: Self) -> Result<string, FsError> {
        val h = try liftString(self.location, rawHash(self.handle));
        return h;
    }

    // Write `b` at the position; answers the number of bytes written.
    pub fn write(self: Self, b: bytes) -> Result<i32, FsError> {
        if (rawReadOnly(self.handle))
            throw FsError.Other(path: self.location, message: "the file is open for reading");
        val n = try liftI32(self.location, rawWrite(self.handle, b));
        return n;
    }

    // Close the file. Closing twice is harmless; a failure to close is not reported.
    pub fn close(self: Self) -> void {
        val closed = rawClose(self.handle);
    }
}

// Open the file at `path` for reading. A directory is `IsDirectory` on every target.
pub fn open(path: string) -> Result<File, FsError> {
    val h = try liftHandle(path, rawOpen(path));
    return File(location: path, handle: h);
}

// Open the file at `path` for writing: created, or truncated.
pub fn create(path: string) -> Result<File, FsError> {
    val h = try liftHandle(path, rawCreate(path));
    return File(location: path, handle: h);
}

// An `Asset` (`@embed`, decisions 519, 538) as a `File`: the embedded bytes, read
// like a file on disk — no `Result`, the build proved the file exists — and
// closing it is a no-op.
pub fn openAsset(asset: Asset) -> File {
    return File(location: asset.path, handle: memoryHandle(asset.bytes));
}

// ── the wasm bodies (decision 992) ───────────────────────────────────────────
// `io.fs` on wasm answers what it answers on commonJS, erlang and beam: the same functions
// over the file system of the process, the same paths (a relative one is read against the
// working directory, an absolute one as it is), the same answers and the same errors. The
// host is `wasi:filesystem`, reached through std-wasm's leaves (`modules/std-wasm/wat/fs.wat`;
// the `wasi…` declarations below), which the runner serves with the root and the working
// directory preopened (`needs: [.Filesystem]`, no flag). A leaf answers a host failure as
// `-(1 + code)`, `code` the ordinal of `wasi:filesystem`'s `error-code`, or as the `Error`
// of a `Result<_, i32>` holding the code; `wasiError` writes it as Node's text
// (`ENOENT: …`), which `fsError` reads as it reads every target's.

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.cwd", needs: [.Filesystem]),
)]
declare fn wasiCwd() -> string;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.getenv", needs: [.Filesystem]),
)]
declare fn wasiGetenv(name: string) -> string;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.open", needs: [.Filesystem]),
)]
declare fn wasiOpen(path: string, mode: i32) -> i32;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.openMem", needs: [.Filesystem]),
)]
declare fn wasiOpenMem(data: bytes) -> i32;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.close", needs: [.Filesystem]),
)]
declare fn wasiClose(block: i32) -> void;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.isMem", needs: [.Filesystem]),
)]
declare fn wasiIsMem(block: i32) -> bool;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.tell", needs: [.Filesystem]),
)]
declare fn wasiTell(block: i32) -> i64;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.seek", needs: [.Filesystem]),
)]
declare fn wasiSeek(block: i32, position: i64) -> void;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.size", needs: [.Filesystem]),
)]
declare fn wasiSize(block: i32) -> Result<i64, i32>;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.sizeRaw", needs: [.Filesystem]),
)]
declare fn wasiSizeRaw(block: i32) -> i64;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.read", needs: [.Filesystem]),
)]
declare fn wasiRead(block: i32, n: i32) -> Result<bytes, i32>;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.readAll", needs: [.Filesystem]),
)]
declare fn wasiReadAll(block: i32) -> Result<bytes, i32>;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.readLine", needs: [.Filesystem]),
)]
declare fn wasiReadLine(block: i32) -> Result<bytes, i32>;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.write", needs: [.Filesystem]),
)]
declare fn wasiWrite(block: i32, data: bytes) -> i32;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.statKind", needs: [.Filesystem]),
)]
declare fn wasiStatKind(path: string, follow: i32) -> i32;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.statSize", needs: [.Filesystem]),
)]
declare fn wasiStatSize(path: string) -> Result<i64, i32>;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.statMtime", needs: [.Filesystem]),
)]
declare fn wasiStatMtime(path: string) -> Result<i64, i32>;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.list", needs: [.Filesystem]),
)]
declare fn wasiList(path: string) -> Result<string[], i32>;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.mkdir", needs: [.Filesystem]),
)]
declare fn wasiMkdir(path: string) -> i32;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.rmdir", needs: [.Filesystem]),
)]
declare fn wasiRmdir(path: string) -> i32;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.unlink", needs: [.Filesystem]),
)]
declare fn wasiUnlink(path: string) -> i32;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "fs.symlink", needs: [.Filesystem]),
)]
declare fn wasiSymlink(target: string, link: string) -> i32;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "bytes.at"),
)]
declare fn wasiByteAt(data: bytes, index: i32) -> i32;

#[compiler.external(
    .JavaScript("""(() => { throw new Error('io.fs: a cell of the wasm build') })()"""),
    .Erlang("""erlang:error(wasm_only)"""),
    .Wasm(std: "hash.sha256Hex"),
)]
declare fn wasiSha256(data: bytes) -> string;

// The POSIX name of the host's error `code`, and its text.
fn wasiName(code: i32) -> string {
    val names = [
        "EACCES", "EAGAIN", "EALREADY", "EBADF", "EBUSY", "EDEADLK", "EDQUOT", "EEXIST",
        "EFBIG", "EILSEQ", "EINPROGRESS", "EINTR", "EINVAL", "EIO", "EISDIR", "ELOOP",
        "EMLINK", "EMSGSIZE", "ENAMETOOLONG", "ENODEV", "ENOENT", "ENOLCK", "ENOMEM",
        "ENOSPC", "ENOTDIR", "ENOTEMPTY", "ENOTRECOVERABLE", "ENOTSUP", "ENOTTY",
        "ENXIO", "EOVERFLOW", "EPERM", "EPIPE", "EROFS", "ESPIPE", "ETXTBSY", "EXDEV",
    ];
    return names.at(code) ?? "EIO";
}

fn wasiText(code: i32) -> string {
    val texts = [
        "permission denied", "resource temporarily unavailable",
        "connection already in progress", "bad file descriptor", "resource busy or locked",
        "resource deadlock avoided", "disk quota exceeded", "file already exists",
        "file too large", "illegal byte sequence", "operation in progress",
        "interrupted system call", "invalid argument", "i/o error",
        "illegal operation on a directory", "too many symbolic links encountered",
        "too many links", "message too long", "name too long", "no such device",
        "no such file or directory", "no locks available", "not enough memory",
        "no space left on device", "not a directory", "directory not empty",
        "state not recoverable", "operation not supported",
        "inappropriate ioctl for device", "no such device or address",
        "value too large for defined data type", "operation not permitted", "broken pipe",
        "read-only file system", "invalid seek", "text file busy",
        "cross-device link not permitted",
    ];
    return texts.at(code) ?? "i/o error";
}

// The `HostError` of the host's error `code`: `ENOENT: no such file or directory`.
fn wasiError(code: i32) -> HostError {
    return HostError(
        message: wasiName(code) + ": " + wasiText(code),
        kind: "host",
        name: HostErrorName.Error,
        detail: null,
    );
}

// The `Ok` of a leaf's answer, its `Error` the `HostError` of the code.
fn okBytes(r: Result<bytes, i32>) -> Result<bytes, HostError> {
    case r {
        Ok(b) -> return b;
        Error(code) -> throw wasiError(code);
    }
}

fn okStrings(r: Result<string[], i32>) -> Result<string[], HostError> {
    case r {
        Ok(xs) -> return xs;
        Error(code) -> throw wasiError(code);
    }
}

fn okSize(r: Result<i64, i32>) -> Result<i64, HostError> {
    case r {
        Ok(n) -> return n;
        Error(code) -> throw wasiError(code);
    }
}

// `path` without the slashes it begins with: the host reads a path relative to the root it preopens.
fn withoutRoot(path: string) -> string {
    var p = path;
    while (p.startsWith("/")) {
        p = p.slice(1);
    }
    return p;
}

// `name` inside `dir`, `dir` empty being the root.
fn joinPath(dir: string, name: string) -> string {
    if (dir == "") return name;
    return dir + "/" + name;
}

// `path` as the host reads it: absolute, as it is; relative, from the working directory. The empty
// path is no file (`ENOENT`), as it is on every target.
fn resolve(path: string) -> Result<string, HostError> {
    if (path == "") throw wasiError(20);
    if (path.startsWith("/")) return withoutRoot(path);
    val cwd = wasiCwd();
    if (cwd == "" || cwd == "/") return path;
    return withoutRoot(cwd + "/" + path);
}

// The file a handle holds: the handle block `rawOpen`, `rawCreate` and `memHandle` answered.
fn blockOf(handle: unknown) -> i32 {
    var block = 0;
    if (handle is i32) {
        val b: i32 = handle;
        block = b;
    }
    return block;
}

// Whether `a` sorts before `b` by the bytes of their UTF-8 (string `<` is not a wasm GC operation).
fn bytesBefore(a: string, b: string) -> bool {
    val x = bytes.fromUtf8(a);
    val y = bytes.fromUtf8(b);
    val nx = x.length();
    val ny = y.length();
    var i = 0;
    while (i < nx && i < ny) {
        val cx = wasiByteAt(x, i);
        val cy = wasiByteAt(y, i);
        if (cx != cy) return cx < cy;
        i = i + 1;
    }
    return nx < ny;
}

// The names sorted by the bytes of their UTF-8, none twice: what `readdirSync` answers on Node.
fn sortedStrings(xs: array<string>) -> array<string> {
    var out: array<string> = [];
    var i = 0;
    while (i < xs.length) {
        val x = xs.at(i) ?? "";
        i = i + 1;
        var j = 0;
        while (j < out.length && bytesBefore(out.at(j) ?? "", x)) {
            j = j + 1;
        }
        if (j < out.length && (out.at(j) ?? "") == x) continue;
        out = out.slice(0, j).append([x]).append(out.slice(j));
    }
    return out;
}

fn readBytesWasm(path: string) -> Result<bytes, HostError> {
    val p = try resolve(path);
    val h = wasiOpen(p, 0);
    if (h < 0) throw wasiError(-1 - h);
    val r = wasiReadAll(h);
    wasiClose(h);
    val b = try okBytes(r);
    return b;
}

fn writeBytesWasm(path: string, contents: bytes) -> Result<i32, HostError> {
    val p = try resolve(path);
    val h = wasiOpen(p, 1);
    if (h < 0) throw wasiError(-1 - h);
    val n = wasiWrite(h, contents);
    wasiClose(h);
    if (n < 0) throw wasiError(-1 - n);
    return 0;
}

fn writeTextWasm(path: string, contents: string) -> Result<i32, HostError> {
    val n = try writeBytesWasm(path, bytes.fromUtf8(contents));
    return n;
}

fn appendTextWasm(path: string, contents: string) -> Result<i32, HostError> {
    val p = try resolve(path);
    val h = wasiOpen(p, 2);
    if (h < 0) throw wasiError(-1 - h);
    val at = wasiSizeRaw(h);
    if (at < 0l) {
        wasiClose(h);
        throw wasiError(13);
    }
    wasiSeek(h, at);
    val n = wasiWrite(h, bytes.fromUtf8(contents));
    wasiClose(h);
    if (n < 0) throw wasiError(-1 - n);
    return 0;
}

// The offset of the first byte that starts a sequence that is not UTF-8, `-1` when there is none.
fn utf8OffsetWasm(data: bytes) -> i64 {
    val n = data.length();
    var i = 0;
    while (i < n) {
        val c = wasiByteAt(data, i);
        if (c < 128) {
            i = i + 1;
            continue;
        }
        var k = 0;
        if (c >= 194 && c <= 223) {
            k = 1;
        } else if (c >= 224 && c <= 239) {
            k = 2;
        } else if (c >= 240 && c <= 244) {
            k = 3;
        } else {
            return i.toI64();
        }
        if (i + k >= n) return i.toI64();
        var lo = 128;
        var hi = 191;
        if (c == 224) {
            lo = 160;
        } else if (c == 237) {
            hi = 159;
        } else if (c == 240) {
            lo = 144;
        } else if (c == 244) {
            hi = 143;
        }
        val d = wasiByteAt(data, i + 1);
        if (d < lo || d > hi) return i.toI64();
        var j = 2;
        while (j <= k) {
            val e = wasiByteAt(data, i + j);
            if (e < 128 || e > 191) return i.toI64();
            j = j + 1;
        }
        i = i + k + 1;
    }
    return -1l;
}

fn stripEolWasm(line: bytes) -> bytes {
    var n = line.length();
    if (n > 0 && wasiByteAt(line, n - 1) == 10) {
        n = n - 1;
        if (n > 0 && wasiByteAt(line, n - 1) == 13) n = n - 1;
    }
    return line.slice(0, n);
}

fn openWasm(path: string) -> Result<unknown, HostError> {
    val p = try resolve(path);
    val h = wasiOpen(p, 0);
    if (h < 0) throw wasiError(-1 - h);
    val handle: unknown = h;
    return handle;
}

fn createWasm(path: string) -> Result<unknown, HostError> {
    val p = try resolve(path);
    val h = wasiOpen(p, 1);
    if (h < 0) throw wasiError(-1 - h);
    val handle: unknown = h;
    return handle;
}

fn memHandleWasm(data: bytes) -> unknown {
    val handle: unknown = wasiOpenMem(data);
    return handle;
}

fn sizeWasm(handle: unknown, path: string) -> Result<i64, HostError> {
    val n = try okSize(wasiSize(blockOf(handle)));
    return n;
}

fn readWasm(handle: unknown, n: i32) -> Result<bytes, HostError> {
    val b = try okBytes(wasiRead(blockOf(handle), n));
    return b;
}

fn readAllWasm(handle: unknown) -> Result<bytes, HostError> {
    val b = try okBytes(wasiReadAll(blockOf(handle)));
    return b;
}

fn readLineWasm(handle: unknown) -> Result<bytes, HostError> {
    val b = try okBytes(wasiReadLine(blockOf(handle)));
    return b;
}

// The SHA-256 of the whole file, the position where it was.
fn hashWasm(handle: unknown) -> Result<string, HostError> {
    val block = blockOf(handle);
    val at = wasiTell(block);
    wasiSeek(block, 0l);
    val r = wasiReadAll(block);
    wasiSeek(block, at);
    val b = try okBytes(r);
    return wasiSha256(b);
}

fn writeWasm(handle: unknown, data: bytes) -> Result<i32, HostError> {
    val n = wasiWrite(blockOf(handle), data);
    if (n < 0) throw wasiError(-1 - n);
    return n;
}

fn closeWasm(handle: unknown) -> Result<i32, HostError> {
    wasiClose(blockOf(handle));
    return 0;
}

fn readOnlyWasm(handle: unknown) -> bool {
    return wasiIsMem(blockOf(handle));
}

fn existsWasm(path: string) -> bool {
    return case resolve(path) {
        Ok(p) -> wasiStatKind(p, 1) >= 0;
        Error(_) -> false;
    };
}

fn listWasm(path: string) -> Result<string[], HostError> {
    val p = try resolve(path);
    val names = try okStrings(wasiList(p));
    return sortedStrings(names);
}

fn mkdirWasm(path: string) -> Result<i32, HostError> {
    val p = try resolve(path);
    val r = wasiMkdir(p);
    if (r < 0) throw wasiError(-1 - r);
    return 0;
}

// The directory and every missing one above it. One that is there is `Ok`; a file in the way is
// `EEXIST` when it is the directory asked for, `ENOTDIR` when it is above it.
fn mkdirRecursiveWasm(path: string) -> Result<i32, HostError> {
    val p = try resolve(path);
    var parts: array<string> = [];
    val pieces = p.split("/");
    var i = 0;
    while (i < pieces.length) {
        val piece = pieces.at(i) ?? "";
        i = i + 1;
        if (piece != "" && piece != ".") parts = parts.append([piece]);
    }
    var prefix = "";
    var k = 0;
    while (k < parts.length) {
        prefix = joinPath(prefix, parts.at(k) ?? "");
        k = k + 1;
        val kind = wasiStatKind(prefix, 1);
        if (kind == 3) continue;
        if (kind >= 0) {
            if (k == parts.length) throw wasiError(7);
            throw wasiError(24);
        }
        val made = wasiMkdir(prefix);
        if (made < 0) throw wasiError(-1 - made);
    }
    return 0;
}

// The FILE at `path`: a directory is `EISDIR`, whatever it holds.
fn rmWasm(path: string) -> Result<i32, HostError> {
    val p = try resolve(path);
    val kind = wasiStatKind(p, 0);
    if (kind < 0) throw wasiError(-1 - kind);
    if (kind == 3) throw wasiError(14);
    val r = wasiUnlink(p);
    if (r < 0) throw wasiError(-1 - r);
    return 0;
}

fn copyWasm(src: string, dest: string) -> Result<i32, HostError> {
    val contents = try readBytesWasm(src);
    val written = try writeBytesWasm(dest, contents);
    return 0;
}

fn statWasm(path: string) -> Result<FileStat, HostError> {
    val p = try resolve(path);
    val kind = wasiStatKind(p, 1);
    if (kind < 0) throw wasiError(-1 - kind);
    val size = try okSize(wasiStatSize(p));
    val seconds = try okSize(wasiStatMtime(p));
    return FileStat(size: size, mtime: seconds * 1000l, isDir: kind == 3);
}

// The regular files under `root` and the links whose target is missing, as paths relative to it, in
// directory order: a work list of directories, not a recursion (a recursive `try` is not lowered on wasm).
fn walkWasm(root: string) -> Result<Walked, HostError> {
    val p = try resolve(root);
    val kind = wasiStatKind(p, 1);
    if (kind < 0) throw wasiError(-1 - kind);
    if (kind != 3) throw wasiError(24);
    var dirs: array<string> = [p];
    var rels: array<string> = [""];
    var files: array<string> = [];
    var dangling: array<string> = [];
    var next = 0;
    while (next < dirs.length) {
        val dir = dirs.at(next) ?? "";
        val rel = rels.at(next) ?? "";
        next = next + 1;
        val names = try okStrings(wasiList(dir));
        var i = 0;
        while (i < names.length) {
            val name = names.at(i) ?? "";
            i = i + 1;
            val full = joinPath(dir, name);
            val sub = joinPath(rel, name);
            val entry = wasiStatKind(full, 1);
            if (entry < 0 && entry != -21) throw wasiError(-1 - entry);
            if (entry == 3) {
                dirs = dirs.append([full]);
                rels = rels.append([sub]);
            }
            if (entry == 6) files = files.append([sub]);
            if (entry == -21) dangling = dangling.append([sub]);
        }
    }
    return Walked(files: sortedStrings(files), dangling: sortedStrings(dangling));
}

// Whether the segment holds a wildcard.
fn isMagic(seg: string) -> bool {
    return seg.contains("*") || seg.contains("?") || seg.contains("[") || seg.contains("{");
}

// A segment with its `{a,b}` alternatives written out, nested ones too; one that is never closed is a name.
fn expandBraces(seg: string) -> array<string> {
    val cs = seg.chars();
    var open = -1;
    var i = 0;
    while (i < cs.length) {
        if ((cs.at(i) ?? "") == "{") {
            open = i;
            break;
        }
        i = i + 1;
    }
    if (open < 0) return [seg];
    var depth = 0;
    var close = -1;
    var cuts: array<i32> = [];
    var j = open;
    var closed = false;
    while (j < cs.length && !closed) {
        val c = cs.at(j) ?? "";
        // Separate `if`s, not an `else if` chain: wasm's GC lowering refuses
        // an `if` nesting one beside an `else if` that appends (B-170).
        if (c == "{") depth = depth + 1;
        if (c == "}") depth = depth - 1;
        if (c == "}" && depth == 0) {
            close = j;
            closed = true;
        }
        if (c == "," && depth == 1) cuts = cuts.append([j]);
        j = j + 1;
    }
    if (close < 0) return [seg];
    val head = cs.slice(0, open).join("");
    val tail = cs.slice(close + 1).join("");
    var out: array<string> = [];
    var start = open + 1;
    var k = 0;
    while (k <= cuts.length) {
        var stop = close;
        if (k < cuts.length) stop = cuts.at(k) ?? close;
        val alt = cs.slice(start, stop).join("");
        out = out.append(expandBraces(head + alt + tail));
        start = stop + 1;
        k = k + 1;
    }
    return out;
}

// The `]` that closes the class opened at `at`, `-1` when there is none (the `[` is then a name).
fn classEnd(pat: array<string>, at: i32) -> i32 {
    var j = at + 1;
    if (j < pat.length && ((pat.at(j) ?? "") == "!" || (pat.at(j) ?? "") == "^")) j = j + 1;
    if (j < pat.length && (pat.at(j) ?? "") == "]") j = j + 1;
    while (j < pat.length) {
        if ((pat.at(j) ?? "") == "]") return j;
        j = j + 1;
    }
    return -1;
}

// Whether `ch` is in the class written between `first` and `stop` (`!` or `^` first negates it, `a-z` is a range).
fn classHas(pat: array<string>, first: i32, stop: i32, ch: string) -> bool {
    var i = first;
    var negate = false;
    if (i < stop && ((pat.at(i) ?? "") == "!" || (pat.at(i) ?? "") == "^")) {
        negate = true;
        i = i + 1;
    }
    var found = false;
    while (i < stop) {
        val lo = pat.at(i) ?? "";
        if (i + 2 < stop && (pat.at(i + 1) ?? "") == "-") {
            val hi = pat.at(i + 2) ?? "";
            // By code point: a class range is one character each side, and
            // wasm lowers no ordering of strings (B-170).
            val c = ch.charCodeAt(0);
            if (lo.charCodeAt(0) <= c && c <= hi.charCodeAt(0)) found = true;
            i = i + 3;
        } else {
            if (lo == ch) found = true;
            i = i + 1;
        }
    }
    return found != negate;
}

// `name` against one pattern without braces: `*`, `?`, `[…]`.
fn globMatch(pat: array<string>, begin: i32, name: array<string>, offset: i32) -> bool {
    var p = begin;
    var n = offset;
    while (p < pat.length) {
        val c = pat.at(p) ?? "";
        if (c == "*") {
            while (p < pat.length && (pat.at(p) ?? "") == "*") {
                p = p + 1;
            }
            if (p == pat.length) return true;
            var k = n;
            while (k <= name.length) {
                if (globMatch(pat, p, name, k)) return true;
                k = k + 1;
            }
            return false;
        }
        if (n >= name.length) return false;
        val ch = name.at(n) ?? "";
        if (c == "?") {
            p = p + 1;
            n = n + 1;
        } else if (c == "[") {
            val end = classEnd(pat, p);
            if (end < 0) {
                if (ch != "[") return false;
                p = p + 1;
                n = n + 1;
            } else {
                if (!classHas(pat, p + 1, end, ch)) return false;
                p = end + 1;
                n = n + 1;
            }
        } else {
            if (c != ch) return false;
            p = p + 1;
            n = n + 1;
        }
    }
    return n == name.length;
}

fn segmentMatches(seg: string, name: string) -> bool {
    val alts = expandBraces(seg);
    val chars = name.chars();
    var i = 0;
    while (i < alts.length) {
        if (globMatch((alts.at(i) ?? "").chars(), 0, chars, 0)) return true;
        i = i + 1;
    }
    return false;
}

// The names in `dir` the segment matches; a dot name only when the segment itself begins with the dot.
fn globNames(dir: string, seg: string) -> array<string> {
    val listed: array<string> = case wasiList(dir) {
        Ok(xs) -> xs;
        Error(_) -> [];
    };
    var out: array<string> = [];
    var i = 0;
    while (i < listed.length) {
        val name = listed.at(i) ?? "";
        i = i + 1;
        if (name.startsWith(".") && !seg.startsWith(".")) continue;
        if (seg == "*" || segmentMatches(seg, name)) out = out.append([name]);
    }
    return out;
}

// The entries `segs` from `i` match under `dir` (`rel` its path from the root of the glob), added to `out`. A
// wildcard continues into real directories only; a name goes through a link.
fn globWalk(segs: array<string>, i: i32, dir: string, rel: string, out: array<string>) -> array<string> {
    var acc = out;
    if (i == segs.length) {
        if (rel != "") acc = acc.append([rel]);
        return acc;
    }
    val seg = segs.at(i) ?? "";
    val last = i == segs.length - 1;
    if (seg == "**") {
        if (!last) acc = globWalk(segs, i + 1, dir, rel, acc);
        val names = globNames(dir, "*");
        var k = 0;
        while (k < names.length) {
            val name = names.at(k) ?? "";
            k = k + 1;
            val full = joinPath(dir, name);
            val sub = joinPath(rel, name);
            if (last) acc = acc.append([sub]);
            if (wasiStatKind(full, 0) == 3) acc = globWalk(segs, i, full, sub, acc);
        }
        return acc;
    }
    if (!isMagic(seg)) {
        val full = joinPath(dir, seg);
        val sub = joinPath(rel, seg);
        if (last) {
            if (wasiStatKind(full, 0) >= 0) acc = acc.append([sub]);
        } else if (wasiStatKind(full, 1) == 3) {
            acc = globWalk(segs, i + 1, full, sub, acc);
        }
        return acc;
    }
    val names = globNames(dir, seg);
    var k = 0;
    while (k < names.length) {
        val name = names.at(k) ?? "";
        k = k + 1;
        val full = joinPath(dir, name);
        val sub = joinPath(rel, name);
        if (last) {
            acc = acc.append([sub]);
        } else if (wasiStatKind(full, 0) == 3) {
            acc = globWalk(segs, i + 1, full, sub, acc);
        }
    }
    return acc;
}

fn globWasm(pattern: string, root: string) -> string[] {
    val resolved = resolve(root);
    if (resolved.isError()) return [];
    val base = resolved.unwrapOr("");
    var segs: array<string> = [];
    val pieces = pattern.split("/");
    var i = 0;
    while (i < pieces.length) {
        val piece = pieces.at(i) ?? "";
        i = i + 1;
        if (piece != "" && piece != ".") segs = segs.append([piece]);
    }
    val found = globWalk(segs, 0, base, "", []);
    var kept: array<string> = [];
    var k = 0;
    while (k < found.length) {
        val entry = found.at(k) ?? "";
        k = k + 1;
        if (!pattern.endsWith("/") || wasiStatKind(joinPath(base, entry), 0) == 3) kept = kept.append([entry]);
    }
    return sortedStrings(kept);
}

// A path that is not there is `Ok`: the caller wanted it gone. A link is removed, never followed. The
// directories are found first, then the files removed, then the directories from the deepest.
fn removeTreeWasm(path: string) -> Result<i32, HostError> {
    val p = try resolve(path);
    val top = wasiStatKind(p, 0);
    if (top == -21) return 0;
    if (top < 0) throw wasiError(-1 - top);
    if (top != 3) {
        val r = wasiUnlink(p);
        if (r < 0) throw wasiError(-1 - r);
        return 0;
    }
    var dirs: array<string> = [p];
    var next = 0;
    while (next < dirs.length) {
        val dir = dirs.at(next) ?? "";
        next = next + 1;
        val names = try okStrings(wasiList(dir));
        var i = 0;
        while (i < names.length) {
            val full = joinPath(dir, names.at(i) ?? "");
            i = i + 1;
            val kind = wasiStatKind(full, 0);
            if (kind < 0 && kind != -21) throw wasiError(-1 - kind);
            if (kind == 3) dirs = dirs.append([full]);
            if (kind >= 0 && kind != 3) {
                val r = wasiUnlink(full);
                if (r < 0) throw wasiError(-1 - r);
            }
        }
    }
    var k = dirs.length;
    while (k > 0) {
        k = k - 1;
        val r = wasiRmdir(dirs.at(k) ?? "");
        if (r < 0) throw wasiError(-1 - r);
    }
    return 0;
}

// A fresh, unique, empty directory under the host's temporary directory.
fn scratchDirWasm() -> string {
    var base = wasiGetenv("TMPDIR");
    if (base == "") base = "/tmp";
    var attempt = 0;
    while (attempt < 100) {
        val dir = base + "/bp-std-fs-" + random.randomBytes(6);
        if (wasiMkdir(withoutRoot(dir)) == 0) return dir;
        attempt = attempt + 1;
    }
    failure.panic("io.fs: no scratch directory could be made");
    return base;
}

fn workingDirWasm() -> string {
    val cwd = wasiCwd();
    if (cwd == "") return "/";
    return cwd;
}

fn linkToWasm(target: string, link: string) -> void {
    val l = resolve(link);
    if (l.isError()) failure.panic("io.fs: no link path");
    val r = wasiSymlink(target, l.unwrapOr(""));
    if (r < 0) failure.panic(wasiError(-1 - r).message);
    return;
}

// A host without `chmod` denies this user nothing: the permission tests have nothing to check there.
fn denyAllWasm(path: string) -> bool {
    return false;
}

fn allowAllWasm(path: string) -> void {
    return;
}

// ── tests ────────────────────────────────────────────────────────────────────
// (Inline tests are smoke-grade — they require the host filesystem to be
// writable at the host's `tmpdir()`. The lib-test harness runs each
// inline test as a separate process; the temp filenames are seeded with
// `time.nowMillis()` for cross-run uniqueness.)

test "fs.exists is false for a fixed-name path that doesn't exist" {
    val e = exists("/__bp_std_fs_definitely_not_a_real_path_xyz__");
    assert e.negate();
}

test "fs.exists is true for a path of any kind" {
    assert exists("/");
    assert exists("/dev/null");
    val dir = scratchDir();
    writeText([dir, "/file.txt"].join(""), "x");
    assert exists([dir, "/file.txt"].join(""));
    assert exists(dir);
    removeTree(dir);
    assert exists(dir).negate();
}

test "fs.removeTree removes a tree, a file and a link, and a missing path is Ok" {
    val dir = scratchDir();
    makeFixtureTree(dir);
    linkTo("blog", [dir, "/app/linked"].join(""));
    assert removeTree([dir, "/app/linked"].join("")).isOk();
    assert exists([dir, "/app/linked"].join("")).negate();
    assert exists([dir, "/app/blog/page.bp"].join(""));
    assert removeTree([dir, "/app/page.bp"].join("")).isOk();
    assert exists([dir, "/app/page.bp"].join("")).negate();
    assert removeTree([dir, "/app"].join("")).isOk();
    assert exists([dir, "/app"].join("")).negate();
    assert removeTree([dir, "/app"].join("")).isOk();
    assert removeTree(dir).isOk();
    assert exists(dir).negate();
}

test "fs.mkdirRecursive makes a directory with its parents and is Ok on one that is there" {
    val dir = scratchDir();
    val deep = [dir, "/a/b/c"].join("");
    assert mkdirRecursive(deep).isOk();
    assert stat(deep).unwrapOr(
        FileStat(size: 0l, mtime: 0l, isDir: false),
    ).isDir;
    assert mkdirRecursive(deep).isOk();
    writeText([dir, "/file.txt"].join(""), "x");
    assert mkdirRecursive([dir, "/file.txt"].join("")).isError();
    assert mkdirRecursive([dir, "/file.txt/sub"].join("")).isError();
    removeTree(dir);
}

test "fs.list of the host '/' resolves Ok" {
    val r = list("/");
    assert r.isOk();
}

// Internal, test scaffolding: `stat(p)`, or a stat no file has.
fn statOr(p: string) -> FileStat {
    return case stat(p) {
        Ok(s) -> s;
        Error(_) -> FileStat(size: -1l, mtime: -1l, isDir: false);
    };
}

test "fs.stat answers a file's size, a directory's kind and the mtime in epoch milliseconds" {
    val dir = scratchDir();
    writeText([dir, "/five.txt"].join(""), "12345");
    val file = statOr([dir, "/five.txt"].join(""));
    assert file.size == 5l;
    assert file.isDir == false;
    // After 2020-01-01T00:00:00Z and before 2100-01-01T00:00:00Z.
    assert file.mtime > 1577836800000l;
    assert file.mtime < 4102444800000l;
    // Whole seconds on every target (decision 499).
    assert file.mtime % 1000l == 0l;
    assert statOr(dir).isDir;
    assert stat([dir, "/missing.txt"].join("")).isError();
    removeTree(dir);
}

// Internal, test scaffolding: `<dir>/app/page.bp`, `<dir>/app/blog/page.bp`,
// `<dir>/app/blog/notes.md` — the fixture tree every walk/glob test reads.
fn makeFixtureTree(dir: string) -> void {
    mkdir([dir, "/app"].join(""));
    mkdir([dir, "/app/blog"].join(""));
    writeText([dir, "/app/page.bp"].join(""), "root page");
    writeText([dir, "/app/blog/page.bp"].join(""), "blog page");
    writeText([dir, "/app/blog/notes.md"].join(""), "notes");
}

// Internal, test scaffolding: what `walk` answers for the fixture tree when
// its root is spelled `<scratch dir><suffix>` — every spelling of one root has
// to answer the same three relative paths.
fn walkFixture(suffix: string) -> string {
    val dir = scratchDir();
    makeFixtureTree(dir);
    val walked = walk([dir, suffix].join("")).unwrapOr(["<error>"]);
    removeTree(dir);
    return walked.join(",");
}

// Internal, test scaffolding: the same, with the root spelled relative to the
// working directory — `<prefix><path from the cwd to the fixture>`.
fn walkFixtureFromCwd(prefix: string) -> string {
    val dir = scratchDir();
    makeFixtureTree(dir);
    val root = [prefix, relative(workingDir(), dir), "/app"].join("");
    val walked = walk(root).unwrapOr(["<error>"]);
    removeTree(dir);
    return walked.join(",");
}

test "fs.walk lists every regular file relative to the root, sorted" {
    assert walkFixture("/app") == "blog/notes.md,blog/page.bp,page.bp";
}

test "fs.walk of a root with a trailing slash answers the same paths" {
    assert walkFixture("/app/") == "blog/notes.md,blog/page.bp,page.bp";
}

test "fs.walk of a root ending in a dot segment answers the same paths" {
    assert walkFixture("/app/.") == "blog/notes.md,blog/page.bp,page.bp";
}

test "fs.walk of a root with a dot segment inside answers the same paths" {
    assert walkFixture("/./app") == "blog/notes.md,blog/page.bp,page.bp";
}

test "fs.walk of a root with a doubled separator answers the same paths" {
    assert walkFixture("//app//") == "blog/notes.md,blog/page.bp,page.bp";
}

test "fs.walk of a root ending in a parent segment answers the same paths" {
    assert walkFixture("/app/blog/..") == "blog/notes.md,blog/page.bp,page.bp";
}

test "fs.walk of a relative root answers the same paths" {
    assert walkFixtureFromCwd("") == "blog/notes.md,blog/page.bp,page.bp";
}

test "fs.walk of a relative root spelled with a leading dot answers the same paths" {
    assert walkFixtureFromCwd("./") == "blog/notes.md,blog/page.bp,page.bp";
}

test "fs.walk follows a link to a file and a link to a directory" {
    val dir = scratchDir();
    makeFixtureTree(dir);
    linkTo("blog", [dir, "/app/linked"].join(""));
    linkTo("page.bp", [dir, "/app/alias.bp"].join(""));
    val walked = walk([dir, "/app"].join("")).unwrapOr(["<error>"]);
    removeTree(dir);
    assert walked.join(",")
        == "alias.bp,blog/notes.md,blog/page.bp,linked/notes.md,linked/page.bp,page.bp";
}

// Internal, test scaffolding: the `Error` of `walk(root)`, `""` when it walked.
fn walkRefusal(root: string) -> string {
    return case walk(root) {
        Ok(_) -> "";
        Error(e) -> describe(e);
    };
}

// Internal, test scaffolding: an `FsError` as one line — the variant, the path
// and the message where it holds one (a dangling link is `Other`, decision 178).
fn describe(e: FsError) -> string {
    return case e {
        FsError.NotFound(p) -> "NotFound " + p;
        FsError.PermissionDenied(p) -> "PermissionDenied " + p;
        FsError.IsDirectory(p) -> "IsDirectory " + p;
        FsError.NotDirectory(p) -> "NotDirectory " + p;
        FsError.AlreadyExists(p) -> "AlreadyExists " + p;
        FsError.InvalidUtf8(p, offset) -> "InvalidUtf8 "
            + p
            + " "
            + offset.toString();
        FsError.Other(p, message) -> message;
    };
}

test "fs.walk of a tree with a dangling link is an Error naming the link" {
    val dir = scratchDir();
    makeFixtureTree(dir);
    linkTo("missing.bp", [dir, "/app/gone.bp"].join(""));
    val refusal = walkRefusal([dir, "/app"].join(""));
    val dotted = walkRefusal([dir, "/app/."].join(""));
    removeTree(dir);
    assert refusal == "fs.walk: dangling link \"gone.bp\"";
    assert dotted == "fs.walk: dangling link \"gone.bp\"";
}

test "fs.walk names the first dangling link in sorted order, by its relative path" {
    val dir = scratchDir();
    makeFixtureTree(dir);
    linkTo("missing.bp", [dir, "/app/zz-gone.bp"].join(""));
    linkTo("missing.md", [dir, "/app/blog/gone.md"].join(""));
    val refusal = walkRefusal([dir, "/app"].join(""));
    removeTree(dir);
    assert refusal == "fs.walk: dangling link \"blog/gone.md\"";
}

test "fs.walk of a regular file is an Error" {
    val dir = scratchDir();
    makeFixtureTree(dir);
    val r = walk([dir, "/app/page.bp"].join(""));
    removeTree(dir);
    assert r.isError();
}

test "fs.walk of a missing root is an Error" {
    val r = walk("/__bp_std_fs_definitely_not_a_real_path_xyz__");
    assert r.isError();
}

test "fs.glob finds a nested file through a double-star pattern" {
    val dir = scratchDir();
    makeFixtureTree(dir);
    val found = glob("**/page.bp", [dir, "/app"].join("")).unwrapOr([]);
    removeTree(dir);
    assert found.join(",") == "blog/page.bp,page.bp";
}

test "fs.glob answers the empty list when nothing matches" {
    val dir = scratchDir();
    val found = glob("*.nothing", dir).unwrapOr(["x"]);
    removeTree(dir);
    assert found.length == 0;
}

// Internal, test scaffolding: the fixture tree plus the names decision 177 is
// about — a dot file and a dot directory, a link to a directory, a link to a
// file and a dangling link, all under `<dir>/app`.
fn makeGlobTree(dir: string) -> void {
    makeFixtureTree(dir);
    mkdir([dir, "/app/.cache"].join(""));
    writeText([dir, "/app/.cache/page.bp"].join(""), "cached");
    writeText([dir, "/app/.hidden.bp"].join(""), "hidden");
    writeText([dir, "/app/blog/.draft.md"].join(""), "draft");
    linkTo("blog", [dir, "/app/linked"].join(""));
    linkTo("page.bp", [dir, "/app/alias.bp"].join(""));
    linkTo("missing.bp", [dir, "/app/gone.bp"].join(""));
}

// Internal, test scaffolding: what `glob(pattern, <dir>/app)` answers over
// `makeGlobTree`, joined by `,`.
fn globbed(pattern: string) -> string {
    val dir = scratchDir();
    makeGlobTree(dir);
    val found = glob(pattern, [dir, "/app"].join("")).unwrapOr(["<error>"]);
    removeTree(dir);
    return found.join(",");
}

test "fs.glob star matches every name but one that starts with a dot" {
    assert globbed("*") == "alias.bp,blog,gone.bp,linked,page.bp";
    assert globbed("*.bp") == "alias.bp,gone.bp,page.bp";
    assert globbed("blog/*") == "blog/notes.md,blog/page.bp";
}

test "fs.glob matches a dot name only when the segment writes the dot" {
    assert globbed(".*") == ".cache,.hidden.bp";
    assert globbed(".hidden.bp") == ".hidden.bp";
    assert globbed(".cache/*.bp") == ".cache/page.bp";
    assert globbed("blog/.*") == "blog/.draft.md";
    assert globbed("?hidden.bp") == "";
    assert globbed("[.]hidden.bp") == "";
    assert globbed("{.hidden,page}.bp") == "page.bp";
}

test "fs.glob double star does not enter a directory that starts with a dot" {
    assert globbed("**/page.bp") == "blog/page.bp,page.bp";
    assert globbed("**/*.md") == "blog/notes.md";
    assert globbed("**/.*") == ".cache,.hidden.bp,blog/.draft.md";
    assert globbed(".cache/**/*.bp") == ".cache/page.bp";
}

test "fs.glob does not descend through a link to a directory" {
    assert globbed("**/notes.md") == "blog/notes.md";
    assert globbed("*/notes.md") == "blog/notes.md";
    assert globbed("l*/notes.md") == "";
    assert globbed("**/*/notes.md") == "blog/notes.md";
}

test "fs.glob goes through a link the pattern names, and lists a link as a name" {
    assert globbed("linked/*.md") == "linked/notes.md";
    assert globbed("linked/**/*.bp") == "linked/page.bp";
    assert globbed("**/linked/*.md") == "linked/notes.md";
    assert globbed("linked") == "linked";
    assert globbed("l*") == "linked";
    assert globbed("gone.bp") == "gone.bp";
}

test "fs.glob final double star is every entry at every depth" {
    assert globbed("**")
        == "alias.bp,blog,blog/notes.md,blog/page.bp,gone.bp,linked,page.bp";
    assert globbed("blog/**") == "blog/notes.md,blog/page.bp";
}

test "fs.glob reads the classes, the alternatives and a trailing slash" {
    assert globbed("blo?/[np]*.md") == "blog/notes.md";
    assert globbed("{blog,nowhere}/page.bp") == "blog/page.bp";
    assert globbed("**/{notes,page}.*") == "blog/notes.md,blog/page.bp,page.bp";
    assert globbed("*/") == "blog";
    assert globbed("./blog//page.bp") == "blog/page.bp";
}

test "fs.glob of a root that does not exist answers the empty list" {
    val found = glob("**/*", "/__bp_std_fs_definitely_not_a_real_path_xyz__");
    assert found.unwrapOr(["x"]).length == 0;
}

// ── FsError, readText and the handle ─────────────────────────────────────────

// Internal, test scaffolding: the variant of an `Error`, `"ok"` for an `Ok`.
fn variantOf<T>(r: Result<T, FsError>) -> string {
    return case r {
        Ok(_) -> "ok";
        Error(e) -> describe(e);
    };
}

test "fs answers the same FsError variant for the same OS error" {
    val dir = scratchDir();
    writeText([dir, "/file.txt"].join(""), "x");
    val missing = [dir, "/missing"].join("");
    val file = [dir, "/file.txt"].join("");
    assert variantOf(readText(missing)) == "NotFound " + missing;
    assert variantOf(readText(dir)) == "IsDirectory " + dir;
    assert variantOf(list(file)) == "NotDirectory " + file;
    assert variantOf(mkdir(dir)) == "AlreadyExists " + dir;
    assert variantOf(mkdir([dir, "/a/b"].join("")))
        == "NotFound " + [dir, "/a/b"].join("");
    assert variantOf(rm(dir)) == "IsDirectory " + dir;
    assert variantOf(open(missing)) == "NotFound " + missing;
    assert variantOf(open(dir)) == "IsDirectory " + dir;
    assert variantOf(create(dir)) == "IsDirectory " + dir;
    removeTree(dir);
}

test "fs.readText of bytes that are not UTF-8 is InvalidUtf8 at the first invalid byte" {
    val dir = scratchDir();
    val path = [dir, "/bad.bin"].join("");
    // "ok", then the first byte of a two-byte sequence, then "z".
    writeBytes(path, bytes
        .fromUtf8("ok")
        .concat(bytes.fromUtf8("é").slice(0, 1))
        .concat(bytes.fromUtf8("z")));
    assert variantOf(readText(path)) == "InvalidUtf8 " + path + " 2";
    assert readBytes(path).isOk();
    // A sequence cut short at the end of the file.
    writeBytes(path, bytes.fromUtf8("é").slice(0, 1));
    assert variantOf(readText(path)) == "InvalidUtf8 " + path + " 0";
    // A well-formed multi-byte file reads back whole.
    writeText(path, "héllo ✓");
    assert readText(path).unwrapOr("") == "héllo ✓";
    removeTree(dir);
}

test "fs.appendText adds to the end and creates the file" {
    val dir = scratchDir();
    val path = [dir, "/log.txt"].join("");
    appendText(path, "a");
    appendText(path, "b");
    assert readText(path).unwrapOr("") == "ab";
    removeTree(dir);
}

// Internal, test scaffolding: the file a failed `open` falls back to.
fn noFile() -> File {
    return File(location: "", handle: memHandle(bytes.fromUtf8("")));
}

test "fs.File writes, then reads bytes, text, a size and a hash" {
    val dir = scratchDir();
    val path = [dir, "/data.txt"].join("");
    val w = create(path).unwrapOr(noFile());
    assert w.write(bytes.fromUtf8("hello ")).unwrapOr(-1) == 6;
    assert w.write(bytes.fromUtf8("world")).unwrapOr(-1) == 5;
    w.close();
    val r = open(path).unwrapOr(w);
    assert r.path() == path;
    assert r.size().unwrapOr(-1l) == 11l;
    assert r.read(5).unwrapOr(bytes.fromUtf8("")).toUtf8().unwrapOr("")
        == "hello";
    assert r.text().unwrapOr("") == " world";
    assert r.read(5).unwrapOr(bytes.fromUtf8("x")).length == 0;
    assert r.hash().unwrapOr("")
        == "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9";
    r.close();
    removeTree(dir);
}

test "fs.File's hash leaves the position where it was" {
    val dir = scratchDir();
    val path = [dir, "/pos.txt"].join("");
    val w = create(path).unwrapOr(noFile());
    assert w.write(bytes.fromUtf8("hello world")).unwrapOr(-1) == 11;
    w.close();
    val r = open(path).unwrapOr(w);
    assert r.read(5).unwrapOr(bytes.fromUtf8("")).length == 5;
    assert r.hash().unwrapOr("")
        == "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9";
    assert r.text().unwrapOr("") == " world";
    r.close();
    removeTree(dir);
}

// Internal, test scaffolding: take every permission from `path`; whether that
// denies this user anything (root is denied nothing), and give them back.
#[compiler.external(
    .JavaScript("""(() => { require('fs').chmodSync($0, 0); return typeof process.getuid === 'function' ? process.getuid() !== 0 : false })()"""),
    .Erlang("""(fun(__P) -> ok = file:change_mode(__P, 0), string:trim(os:cmd("id -u")) =/= "0" end)($0)"""),
    .Wasm(body: denyAllWasm),
)]
declare fn denyAll(path: string) -> bool;

#[compiler.external(
    .JavaScript("""require('fs').chmodSync($0, 0o700)"""),
    .Erlang("""(fun(__P) -> ok = file:change_mode(__P, 8#700), ok end)($0)"""),
    .Wasm(body: allowAllWasm),
)]
declare fn allowAll(path: string) -> void;

test "fs answers PermissionDenied for an OS permission error" {
    val dir = scratchDir();
    val locked = [dir, "/locked"].join("");
    mkdir(locked);
    writeText([locked, "/f.txt"].join(""), "x");
    val denied = denyAll(locked);
    val listed = variantOf(list(locked));
    val read = variantOf(readText([locked, "/f.txt"].join("")));
    allowAll(locked);
    removeTree(dir);
    // Run as root nothing is denied, and there is nothing to read.
    if (denied) {
        assert listed == "PermissionDenied " + locked;
        assert read == "PermissionDenied " + [locked, "/f.txt"].join("");
    }
}

```

----- BEAM ASSEMBLY -- std/io/fs.S
```erlang
{module, std@io@fs}.
{exports, [{exists, 1}, {readBytes, 1}, {readText, 1}, {writeBytes, 2}, {writeText, 2}, {appendText, 2}, {stat, 1}, {list, 1}, {mkdir, 1}, {mkdirRecursive, 1}, {rm, 1}, {removeTree, 1}, {copy, 2}, {walk, 1}, {glob, 2}, {open, 1}, {create, 1}, {openAsset, 1}, {liftI64, 2}, {liftBytes, 2}, {decode, 2}, {liftString, 2}, {liftI32, 2}, {'__bp_priv__array_range', 2}, {'__bp_priv__array_repeat', 2}, {'__bp_priv__bytes_slice', 3}, {'__bp_priv__string_slice', 3}, {'__bp_priv__allowAllWasm', 1}, {'__bp_priv__appendTextWasm', 2}, {'__bp_priv__blockOf', 1}, {'__bp_priv__bytesBefore', 2}, {'__bp_priv__classEnd', 2}, {'__bp_priv__classHas', 4}, {'__bp_priv__closeWasm', 1}, {'__bp_priv__copyWasm', 2}, {'__bp_priv__createWasm', 1}, {'__bp_priv__denyAllWasm', 1}, {'__bp_priv__describe', 1}, {'__bp_priv__existsWasm', 1}, {'__bp_priv__expandBraces', 1}, {'__bp_priv__fsError', 2}, {'__bp_priv__globMatch', 4}, {'__bp_priv__globNames', 2}, {'__bp_priv__globWalk', 5}, {'__bp_priv__globWasm', 2}, {'__bp_priv__globbed', 1}, {'__bp_priv__hashWasm', 1}, {'__bp_priv__isMagic', 1}, {'__bp_priv__joinPath', 2}, {'__bp_priv__lift', 2}, {'__bp_priv__liftHandle', 2}, {'__bp_priv__liftStat', 2}, {'__bp_priv__liftStrings', 2}, {'__bp_priv__liftWalked', 2}, {'__bp_priv__linkToWasm', 2}, {'__bp_priv__listWasm', 1}, {'__bp_priv__makeFixtureTree', 1}, {'__bp_priv__makeGlobTree', 1}, {'__bp_priv__memHandleWasm', 1}, {'__bp_priv__mkdirRecursiveWasm', 1}, {'__bp_priv__mkdirWasm', 1}, {'__bp_priv__noFile', 0}, {'__bp_priv__okBytes', 1}, {'__bp_priv__okSize', 1}, {'__bp_priv__okStrings', 1}, {'__bp_priv__openWasm', 1}, {'__bp_priv__readAllWasm', 1}, {'__bp_priv__readBytesWasm', 1}, {'__bp_priv__readLineWasm', 1}, {'__bp_priv__readOnlyWasm', 1}, {'__bp_priv__readWasm', 2}, {'__bp_priv__removeTreeWasm', 1}, {'__bp_priv__resolve', 1}, {'__bp_priv__rmWasm', 1}, {'__bp_priv__scratchDirWasm', 0}, {'__bp_priv__segmentMatches', 2}, {'__bp_priv__sizeWasm', 2}, {'__bp_priv__sortedStrings', 1}, {'__bp_priv__statOr', 1}, {'__bp_priv__statWasm', 1}, {'__bp_priv__stripEolWasm', 1}, {'__bp_priv__utf8OffsetWasm', 1}, {'__bp_priv__variantOf', 1}, {'__bp_priv__walkFixture', 1}, {'__bp_priv__walkFixtureFromCwd', 1}, {'__bp_priv__walkRefusal', 1}, {'__bp_priv__walkWasm', 1}, {'__bp_priv__wasiError', 1}, {'__bp_priv__wasiName', 1}, {'__bp_priv__wasiText', 1}, {'__bp_priv__withoutRoot', 1}, {'__bp_priv__workingDirWasm', 0}, {'__bp_priv__writeBytesWasm', 2}, {'__bp_priv__writeTextWasm', 2}, {'__bp_priv__writeWasm', 2}]}.
{attributes, []}.
{labels, 1974}.

{function, 'array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "std@io@fs.erl", 1}]}.
    {func_info, {atom, std@io@fs}, {atom, 'array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 194}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 195}}.
  {label, 194}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 196}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 197}}.
  {label, 196}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 199}}.
  {label, 197}.
  {label, 195}.
    {deallocate, 6}.
    return.

{function, 'array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "std@io@fs.erl", 2}]}.
    {func_info, {atom, std@io@fs}, {atom, 'array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 200}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 201}}.
  {label, 200}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 202}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 199}}.
    {jump, {f, 203}}.
  {label, 202}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 199}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 199}}.
  {label, 203}.
  {label, 201}.
    {deallocate, 6}.
    return.
%%% std/io/fs — the file system, cross-backend (decision 540).
%%% 
%%% Reference:
%%%   Rust     — https://doc.rust-lang.org/std/fs/ (`read`, `read_to_string`,
%%%              `File`, `io::ErrorKind`)
%%%   Java     — https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/nio/file/Files.html
%%%   Erlang   — https://www.erlang.org/doc/man/file.html
%%%   Node.js  — https://nodejs.org/api/fs.html
%%% 
%%% Every function that can fail answers `Result<…, FsError>`: the same OS error is
%%% the same `FsError` variant on every target (`ENOENT`, `enoent` → `NotFound`),
%%% and `Other.message` is the host's own text. The whole-file shortcuts
%%% (`readBytes`, `readText`, `writeBytes`, `writeText`, `appendText`), `stat`, and
%%% the directory functions (`exists`, `list`, `mkdir`, `mkdirRecursive`, `rm`,
%%% `removeTree`, `copy`, `walk`, `glob`) are followed by the handle: `open`
%%% and `create` answer a `File`, a `Closeable` closed by the writer with `defer`.
%%% 
%%% The host cells (`raw…`) write `result: true` (decisions 431, 490) and answer
%%% `Result<R, HostError>` — Node's `ENOENT: …`, erlang's `enoent` as its `message` —
%%% and `lift` reads that message as the `FsError` of the path the caller wrote
%%% (decision 486); no cell catches by hand. All operations are synchronous
%%% (`*Sync` on Node, blocking BIFs on Erlang, `wasi:filesystem` on wasm: the runner
%%% preopens the root and the working directory, decision 992), and a path is read as
%%% the process reads it — a relative one against the working directory — on every target.
% The error of every `io.fs` function (decision 540). `path` is the path the
% caller wrote (for `copy`, the source; for `walk`, the root).
% Read the whole file as bytes.
% Node: `readFileSync($0)` copied into a plain `Uint8Array`.
% Erlang: `file:read_file/1`.
% Write `contents` to `path`, creating or truncating.
% Node: `writeFileSync($0, $1)`. Erlang: `file:write_file/2`.
% Append `contents` to `path`, creating it when it is not there.
% Node: `appendFileSync($0, $1)`. Erlang: `file:write_file/3` with `append`.
% The offset of the first byte that starts a sequence that is not UTF-8 (a byte no sequence
% starts with, a sequence cut short, an overlong form, a surrogate, a code point past U+10FFFF),
% or -1 when every byte is part of a valid sequence — the same offset on every target.
% Node: a scan of the bytes. Erlang: `unicode:characters_to_binary/3`, whose `Good` prefix is the offset.
% `line` without its line terminator: one trailing `\n`, and the `\r` before it.
% Node: `subarray`. Erlang: `binary:part/3`.
% The handle of the file at `path`, open for reading. A directory is `isdir` on both hosts
% (Node opens one; the template refuses it). The handle is host-owned and opaque: a `{ fd,
% mem, pos, buf }` object on Node, an io device on Erlang (a stream reads it in its own process).
% The handle of the file at `path`, open for writing: created, or truncated.
% A handle over bytes held in memory — what an `Asset` opens as. The position is a field
% on Node and a `counters` cell on Erlang.
% The size of the file behind `handle`, in bytes. On Erlang it reads `path`.
% Up to `n` bytes (n > 0) from the handle's position; empty at the end.
% Every byte from the handle's position to the end.
% The next line, terminator included; empty at the end.
% The SHA-256 of the whole file behind the handle, lowercase hex — from its first byte,
% whatever the position, which it leaves where it was. On Erlang `file:pread` leaves the
% position undefined (OTP moves it), so the position is read first and restored.
% Write `bytes` at the handle's position; answers how many.
% Close the handle. A failure to close is not reported (a `Closeable`'s `close` answers nothing).
% Write `contents` to `path`, creating or truncating. Reds with the
% host's I/O error message.
% Node: `require('fs').writeFileSync($0, $1)`.
% Erlang: `file:write_file/2`.
% Whether a path exists, of any kind: a regular file, a directory, a
% character or block device (`/dev/null`), a FIFO or a socket. A symbolic
% link is followed — one whose target is missing is `false`, the answer
% every read through it would give.
% Node: `require('fs').existsSync($0)` (a `stat`).
% Erlang: `file:read_file_info/1` (a `stat`; `filelib:is_file/1`, which it
% replaces, answers only regular files and directories, so `/dev/null`
% was `false` on erlang and `true` on commonJS).

{function, exists, 1, 193}.
  {label, 192}.
    {line, [{location, "std@io@fs.erl", 4}]}.
    {func_info, {atom, std@io@fs}, {atom, exists}, 1}.
  {label, 193}.
    {call_only, 1, {f, 187}}.
% List the names of the directory entries at `path` (relative).
% Node: `require('fs').readdirSync($0)`.
% Erlang: `file:list_dir/1` returns `{ok, [string()]}`, in the directory's
% order: sorted here by bytes (`lists:sort` on binaries), as `readdirSync` and
% wasm's `listWasm` answer them, so every target lists one order (decision 992).
% Create directory at `path`. Use `mkdirRecursive` to create
% intermediate parents.
% Node: `require('fs').mkdirSync($0)`.
% Erlang: `file:make_dir/1`.
% Create the directory at `path` and every missing directory above it. A
% directory that is already there is `Ok` too; a path that exists as anything
% else (a file) is an `Error`. What the snapshot library (`snap`) makes the
% directory of a `.snap` with (decision 391).
% Node: `require('fs').mkdirSync($0, { recursive: true })`.
% Erlang: `filelib:ensure_path/1`.
% Delete the FILE at `path`. A directory — empty or not — is `IsDirectory` on
% both hosts (Node's `ERR_FS_EISDIR`; Erlang's `eperm` is read as `eisdir` after
% a `read_link_info`, so the variant is the same); `removeTree` removes one.
% Node: `require('fs').rmSync($0)`.
% Erlang: `file:delete/1`.
% Copy file from `src` to `dest`. Reds when `src` is missing or
% `dest` already exists (Node's default `copyFileSync` semantics).
% Node: `require('fs').copyFileSync($0, $1)`.
% Erlang: `file:copy/2` (returns `{ok, BytesCopied}` or `{error, _}`).
% File metadata. Returns a `FileStat { size, mtime, isDir }` on
% success. `mtime` is epoch milliseconds (matching `time.nowMillis()`);
% `size` is in bytes.
% Node: `statSync($0, { bigint: true })`, so `size` and the nanosecond
% `mtimeNs` arrive exact at any size; `mtime` is `mtimeNs` floored to whole
% seconds, × 1000, and both answer decision 319's canonical form (a `number`
% within ±(2^53 − 1), a `BigInt` beyond) — never a `number` rounded past 2^53.
% Erlang: `file:read_file_info/1` returns a `#file_info` record; the
% template projects the `size`, `mtime`, and `type` fields. Its `mtime` is
% whole seconds × 1000. One value on every target: whole seconds (decision 499).
% ── 1.0.10-beta front 01 additions ──────────────────────────────────────────
% Every REGULAR FILE under `root`, recursively, as paths relative to `root`
% with `/` separators, sorted — the same set on both targets (the two hosts
% walk in different orders, so the list is sorted rather than left as found),
% and the same paths however the root is spelled: `dir`, `dir/`, `dir/.`,
% `./dir`, `dir/sub/..`, absolute or relative to the working directory.
% Directories are not listed; a link is followed (a link to a file is listed
% under its own name, a link to a directory is walked). An `Error`: a missing
% or non-directory `root`, a directory under it that cannot be read, and a
% DANGLING link (decision 178) — `fs.walk: dangling link "<relative path>"`,
% the same text on both targets, naming the first one in sorted order.
% Node: `readdirSync(root, { recursive: true })` answers files AND directories
% relative to `root`; the template sorts them, keeps the entries `statSync`
% says are files, and answers the dangling-link `Error` for the first entry
% `statSync` cannot find (`throwIfNoEntry: false`).
% Erlang: the template walks `file:list_dir/1` itself and BUILDS each relative
% path from the names it descended through. It never cuts a prefix off a full
% path: `filelib:fold_files/5` answers full paths `filename:join/2` has
% normalised (`dir/.` + `app` is `dir/app`), so a prefix measured on the root
% as written cut two characters too many when the root ended in `/.`.
% The entries under `root` matching the glob `pattern`, as paths relative to
% `root` with `/` separators, sorted, each once. The pattern is read segment
% by segment, by ONE rule on both targets (decision 177 — the narrower of what
% the two hosts did):
%   - `**` is zero or more directories; a segment with `*`, `?`, `[…]` or
%     `{a,b}` matches the names of one directory; any other segment is a name.
%   - `*` and `**` (and `?`, `[…]`, `{…}`) do NOT match a name that starts
%     with `.` — a segment matches one only when the segment itself starts
%     with the dot (`.*`, `.config/*.json`).
%   - the walk does NOT descend through a link to a directory: `**` and a
%     wildcard segment continue into real directories only. The link is still
%     a NAME — `*` lists it — and a segment that names it (`linked/*.bp`) goes
%     through it, because the pattern wrote it.
%   - the last segment matches an entry of any kind (file, directory, link,
%     dangling or not); a final `**` is every entry at every depth; a trailing
%     `/` keeps real directories only.
% An alternative of `{a,b}` cannot hold a `/` (the pattern is split first). A
% root that does not exist answers `Ok([])`; so does a directory that cannot
% be read. Both cells are the same walk; only the match of ONE segment against
% ONE directory is the host's — `fs.globSync(segment, { cwd })` (Node 22+),
% `filelib:wildcard/2` — with the dot rule applied over its answer, since
% `filelib:wildcard` matches dot names and `globSync` matches `{.a,b}`.
% Remove `path` and everything under it: a file, a link (the link, never its
% target) or a directory tree. A path that is not there is `Ok` too — the
% caller wanted it gone. What a test fixture is cleared with, and what the
% snapshot engine's tests clear their scratch directories with (1.0.11-beta
% front 97).
% Node: `rmSync(path, { recursive: true, force: true })`.
% Erlang: `file:del_dir_r/1`.
% Internal, test scaffolding: a fresh, unique, empty directory under the
% host's tmpdir. Private — every `walk`/`glob` test makes its fixture tree in
% one of these and removes it with `removeTree`, so a run leaves nothing under
% the host's tmpdir.
% Internal, test scaffolding: the working directory (what a relative root is
% read against) and a symbolic link `link` → `target`.
% ── the typed error ──────────────────────────────────────────────────────────
% The `FsError` of `path` a host's failure is (decision 486), read from its code: Node's `ENOENT: …`, erlang's `enoent`.

{function, fsError, 2, 7}.
  {label, 6}.
    {line, [{location, "std@io@fs.erl", 5}]}.
    {func_info, {atom, std@io@fs}, {atom, fsError}, 2}.
  {label, 7}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 204}, [{x, 0}, 5, {atom, std@failure@@HostError}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 204}.
    {call_ext, 1, {extfunc, string, uppercase, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"ENOENT">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 206}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 207}}.
  {label, 206}.
    {move, {atom, true}, {x, 0}}.
  {label, 207}.
    {test, is_eq, {f, 205}, [{x, 0}, {atom, true}]}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@FsError__v__notfound}, {y, 0}]}}.
    {deallocate, 7}.
    return.
  {label, 205}.
    {move, {literal, <<"EACCES">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 209}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 210}}.
  {label, 209}.
    {move, {atom, true}, {x, 0}}.
  {label, 210}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 211}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"EPERM">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 213}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 214}}.
  {label, 213}.
    {move, {atom, true}, {x, 0}}.
  {label, 214}.
    {jump, {f, 212}}.
  {label, 211}.
    {move, {atom, true}, {x, 0}}.
  {label, 212}.
    {test, is_eq, {f, 208}, [{x, 0}, {atom, true}]}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@FsError__v__permissiondenied}, {y, 0}]}}.
    {deallocate, 7}.
    return.
  {label, 208}.
    {move, {literal, <<"EISDIR">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 216}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 217}}.
  {label, 216}.
    {move, {atom, true}, {x, 0}}.
  {label, 217}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 218}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"PATH IS A DIRECTORY">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 220}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 221}}.
  {label, 220}.
    {move, {atom, true}, {x, 0}}.
  {label, 221}.
    {jump, {f, 219}}.
  {label, 218}.
    {move, {atom, true}, {x, 0}}.
  {label, 219}.
    {test, is_eq, {f, 215}, [{x, 0}, {atom, true}]}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@FsError__v__isdirectory}, {y, 0}]}}.
    {deallocate, 7}.
    return.
  {label, 215}.
    {move, {literal, <<"ENOTDIR">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 223}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 224}}.
  {label, 223}.
    {move, {atom, true}, {x, 0}}.
  {label, 224}.
    {test, is_eq, {f, 222}, [{x, 0}, {atom, true}]}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@FsError__v__notdirectory}, {y, 0}]}}.
    {deallocate, 7}.
    return.
  {label, 222}.
    {move, {literal, <<"EEXIST">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 226}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 227}}.
  {label, 226}.
    {move, {atom, true}, {x, 0}}.
  {label, 227}.
    {test, is_eq, {f, 225}, [{x, 0}, {atom, true}]}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@FsError__v__alreadyexists}, {y, 0}]}}.
    {deallocate, 7}.
    return.
  {label, 225}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 228}, [{x, 0}, 5, {atom, std@failure@@HostError}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 228}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@FsError__v__other}, {y, 0}, {x, 0}]}}.
    {deallocate, 7}.
    return.
% A host cell's answer, its failure read as an `FsError` of `path`.

{function, lift, 2, 9}.
  {label, 8}.
    {line, [{location, "std@io@fs.erl", 6}]}.
    {func_info, {atom, std@io@fs}, {atom, lift}, 2}.
  {label, 9}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 230}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.
    {jump, {f, 229}}.
  {label, 230}.
    {test, is_tagged_tuple, {f, 231}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 4}.
    return.
    {jump, {f, 229}}.
  {label, 231}.
    {case_end, {x, 0}}.
  {label, 229}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
    return.
% `lift` for each answer type: the generic one is the wasm backend's to specialise, and a
% `bytes` or a handle it does not (decision 992).

{function, liftBytes, 2, 11}.
  {label, 10}.
    {line, [{location, "std@io@fs.erl", 7}]}.
    {func_info, {atom, std@io@fs}, {atom, liftBytes}, 2}.
  {label, 11}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 233}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.
    {jump, {f, 232}}.
  {label, 233}.
    {test, is_tagged_tuple, {f, 234}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 4}.
    return.
    {jump, {f, 232}}.
  {label, 234}.
    {case_end, {x, 0}}.
  {label, 232}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, liftI32, 2, 13}.
  {label, 12}.
    {line, [{location, "std@io@fs.erl", 8}]}.
    {func_info, {atom, std@io@fs}, {atom, liftI32}, 2}.
  {label, 13}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 236}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.
    {jump, {f, 235}}.
  {label, 236}.
    {test, is_tagged_tuple, {f, 237}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 4}.
    return.
    {jump, {f, 235}}.
  {label, 237}.
    {case_end, {x, 0}}.
  {label, 235}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, liftI64, 2, 15}.
  {label, 14}.
    {line, [{location, "std@io@fs.erl", 9}]}.
    {func_info, {atom, std@io@fs}, {atom, liftI64}, 2}.
  {label, 15}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 239}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.
    {jump, {f, 238}}.
  {label, 239}.
    {test, is_tagged_tuple, {f, 240}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 4}.
    return.
    {jump, {f, 238}}.
  {label, 240}.
    {case_end, {x, 0}}.
  {label, 238}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, liftString, 2, 17}.
  {label, 16}.
    {line, [{location, "std@io@fs.erl", 10}]}.
    {func_info, {atom, std@io@fs}, {atom, liftString}, 2}.
  {label, 17}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 242}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.
    {jump, {f, 241}}.
  {label, 242}.
    {test, is_tagged_tuple, {f, 243}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 4}.
    return.
    {jump, {f, 241}}.
  {label, 243}.
    {case_end, {x, 0}}.
  {label, 241}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, liftStrings, 2, 19}.
  {label, 18}.
    {line, [{location, "std@io@fs.erl", 11}]}.
    {func_info, {atom, std@io@fs}, {atom, liftStrings}, 2}.
  {label, 19}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 245}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.
    {jump, {f, 244}}.
  {label, 245}.
    {test, is_tagged_tuple, {f, 246}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 4}.
    return.
    {jump, {f, 244}}.
  {label, 246}.
    {case_end, {x, 0}}.
  {label, 244}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, liftStat, 2, 21}.
  {label, 20}.
    {line, [{location, "std@io@fs.erl", 12}]}.
    {func_info, {atom, std@io@fs}, {atom, liftStat}, 2}.
  {label, 21}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 248}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.
    {jump, {f, 247}}.
  {label, 248}.
    {test, is_tagged_tuple, {f, 249}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 4}.
    return.
    {jump, {f, 247}}.
  {label, 249}.
    {case_end, {x, 0}}.
  {label, 247}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, liftWalked, 2, 23}.
  {label, 22}.
    {line, [{location, "std@io@fs.erl", 13}]}.
    {func_info, {atom, std@io@fs}, {atom, liftWalked}, 2}.
  {label, 23}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 251}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.
    {jump, {f, 250}}.
  {label, 251}.
    {test, is_tagged_tuple, {f, 252}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 4}.
    return.
    {jump, {f, 250}}.
  {label, 252}.
    {case_end, {x, 0}}.
  {label, 250}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, liftHandle, 2, 25}.
  {label, 24}.
    {line, [{location, "std@io@fs.erl", 14}]}.
    {func_info, {atom, std@io@fs}, {atom, liftHandle}, 2}.
  {label, 25}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 254}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.
    {jump, {f, 253}}.
  {label, 254}.
    {test, is_tagged_tuple, {f, 255}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 4}.
    return.
    {jump, {f, 253}}.
  {label, 255}.
    {case_end, {x, 0}}.
  {label, 253}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
    return.
% The text of `b`, or `InvalidUtf8` at the first invalid byte.

{function, decode, 2, 27}.
  {label, 26}.
    {line, [{location, "std@io@fs.erl", 15}]}.
    {func_info, {atom, std@io@fs}, {atom, decode}, 2}.
  {label, 27}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 257}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_ge, {f, 269}, [{y, 2}, {integer, 0}]}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@FsError__v__invalidutf8}, {y, 0}, {y, 2}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 3}.
    return.
  {label, 269}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 273}}.
    {test, is_tagged_tuple, {f, 270}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 271}}.
  {label, 270}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 271}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.
% What `rawWalk` finds under a root: the regular files, and the links whose
% target is missing, both as paths relative to the root, sorted.
% Whether the handle is one over bytes held in memory (an `Asset`'s), which cannot be written.
% ── whole-file shortcuts ─────────────────────────────────────────────────────
% The file's bytes.

{function, readBytes, 1, 29}.
  {label, 28}.
    {line, [{location, "std@io@fs.erl", 16}]}.
    {func_info, {atom, std@io@fs}, {atom, readBytes}, 1}.
  {label, 29}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 284}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 11}}.
    {test, is_tagged_tuple, {f, 306}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 307}}.
  {label, 306}.
    {deallocate, 4}.
    return.
  {label, 307}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.
% The file as UTF-8 text. Bytes that are not UTF-8 are `InvalidUtf8` on every
% target — never node's silent U+FFFD nor erlang's unchecked binary.

{function, readText, 1, 31}.
  {label, 30}.
    {line, [{location, "std@io@fs.erl", 17}]}.
    {func_info, {atom, std@io@fs}, {atom, readText}, 1}.
  {label, 31}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 29}}.
    {test, is_tagged_tuple, {f, 308}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 309}}.
  {label, 308}.
    {deallocate, 3}.
    return.
  {label, 309}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 27}}.
    {test, is_tagged_tuple, {f, 310}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 311}}.
  {label, 310}.
    {deallocate, 3}.
    return.
  {label, 311}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.
% Write `contents` to `path`, creating or truncating.

{function, writeBytes, 2, 33}.
  {label, 32}.
    {line, [{location, "std@io@fs.erl", 18}]}.
    {func_info, {atom, std@io@fs}, {atom, writeBytes}, 2}.
  {label, 33}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 313}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 13}}.
    {test, is_tagged_tuple, {f, 335}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 336}}.
  {label, 335}.
    {deallocate, 5}.
    return.
  {label, 336}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 5}.
    return.

{function, writeText, 2, 35}.
  {label, 34}.
    {line, [{location, "std@io@fs.erl", 19}]}.
    {func_info, {atom, std@io@fs}, {atom, writeText}, 2}.
  {label, 35}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 313}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 13}}.
    {test, is_tagged_tuple, {f, 337}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 338}}.
  {label, 337}.
    {deallocate, 5}.
    return.
  {label, 338}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 5}.
    return.
% Append `contents`, creating the file when it is not there.

{function, appendText, 2, 37}.
  {label, 36}.
    {line, [{location, "std@io@fs.erl", 20}]}.
    {func_info, {atom, std@io@fs}, {atom, appendText}, 2}.
  {label, 37}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 340}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 13}}.
    {test, is_tagged_tuple, {f, 362}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 363}}.
  {label, 362}.
    {deallocate, 5}.
    return.
  {label, 363}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 5}.
    return.
% ── metadata and directories ─────────────────────────────────────────────────

{function, stat, 1, 39}.
  {label, 38}.
    {line, [{location, "std@io@fs.erl", 21}]}.
    {func_info, {atom, std@io@fs}, {atom, stat}, 1}.
  {label, 39}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 365}}.
    {move, {atom, std@io@fs@@FileStat}, {x, 1}}.
    {move, {literal, [size, mtime, isDir]}, {x, 2}}.
    {call, 3, {f, 388}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 21}}.
    {test, is_tagged_tuple, {f, 398}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 399}}.
  {label, 398}.
    {deallocate, 4}.
    return.
  {label, 399}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, list, 1, 41}.
  {label, 40}.
    {line, [{location, "std@io@fs.erl", 22}]}.
    {func_info, {atom, std@io@fs}, {atom, list}, 1}.
  {label, 41}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 401}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 19}}.
    {test, is_tagged_tuple, {f, 427}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 428}}.
  {label, 427}.
    {deallocate, 4}.
    return.
  {label, 428}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, mkdir, 1, 43}.
  {label, 42}.
    {line, [{location, "std@io@fs.erl", 23}]}.
    {func_info, {atom, std@io@fs}, {atom, mkdir}, 1}.
  {label, 43}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 430}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 13}}.
    {test, is_tagged_tuple, {f, 452}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 453}}.
  {label, 452}.
    {deallocate, 4}.
    return.
  {label, 453}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, mkdirRecursive, 1, 45}.
  {label, 44}.
    {line, [{location, "std@io@fs.erl", 24}]}.
    {func_info, {atom, std@io@fs}, {atom, mkdirRecursive}, 1}.
  {label, 45}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 455}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 13}}.
    {test, is_tagged_tuple, {f, 477}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 478}}.
  {label, 477}.
    {deallocate, 4}.
    return.
  {label, 478}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, rm, 1, 47}.
  {label, 46}.
    {line, [{location, "std@io@fs.erl", 25}]}.
    {func_info, {atom, std@io@fs}, {atom, rm}, 1}.
  {label, 47}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 480}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 13}}.
    {test, is_tagged_tuple, {f, 506}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 507}}.
  {label, 506}.
    {deallocate, 4}.
    return.
  {label, 507}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, removeTree, 1, 49}.
  {label, 48}.
    {line, [{location, "std@io@fs.erl", 26}]}.
    {func_info, {atom, std@io@fs}, {atom, removeTree}, 1}.
  {label, 49}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 509}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 13}}.
    {test, is_tagged_tuple, {f, 532}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 533}}.
  {label, 532}.
    {deallocate, 4}.
    return.
  {label, 533}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, copy, 2, 51}.
  {label, 50}.
    {line, [{location, "std@io@fs.erl", 27}]}.
    {func_info, {atom, std@io@fs}, {atom, copy}, 2}.
  {label, 51}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 535}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 13}}.
    {test, is_tagged_tuple, {f, 557}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 558}}.
  {label, 557}.
    {deallocate, 5}.
    return.
  {label, 558}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 5}.
    return.

{function, walk, 1, 53}.
  {label, 52}.
    {line, [{location, "std@io@fs.erl", 28}]}.
    {func_info, {atom, std@io@fs}, {atom, walk}, 1}.
  {label, 53}.
    {allocate, 10, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 560}}.
    {move, {atom, std@io@fs@@Walked}, {x, 1}}.
    {move, {literal, [files, dangling]}, {x, 2}}.
    {call, 3, {f, 388}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 23}}.
    {test, is_tagged_tuple, {f, 625}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 626}}.
  {label, 625}.
    {deallocate, 10}.
    return.
  {label, 626}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 628}, [{x, 0}, 3, {atom, std@io@fs@@Walked}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 628}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 627}, [{integer, 0}, {x, 0}]}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 630}, [{x, 0}, 3, {atom, std@io@fs@@Walked}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 630}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 629}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 635}}.
  {label, 629}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 635}.
    {move, {x, 0}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"\"">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"fs.walk: dangling link \"">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 637}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@FsError__v__other}, {y, 0}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 10}.
    return.
  {label, 627}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 670}, [{x, 0}, 3, {atom, std@io@fs@@Walked}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 670}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 10}.
    return.

{function, glob, 2, 55}.
  {label, 54}.
    {line, [{location, "std@io@fs.erl", 29}]}.
    {func_info, {atom, std@io@fs}, {atom, glob}, 2}.
  {label, 55}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 672}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.
% The host's handle over embedded bytes: read like a file, never closed on disk.
% ── the handle ───────────────────────────────────────────────────────────────
% An open file (decision 540 (3)). `location` is the path it was opened with and
% `handle` the host's — opaque, never read by a program. Closed by the writer:
% `val f = try fs.open(p); defer f.close();`.
% Open the file at `path` for reading. A directory is `IsDirectory` on every target.

{function, open, 1, 57}.
  {label, 56}.
    {line, [{location, "std@io@fs.erl", 40}]}.
    {func_info, {atom, std@io@fs}, {atom, open}, 1}.
  {label, 57}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 815}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 25}}.
    {test, is_tagged_tuple, {f, 837}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 838}}.
  {label, 837}.
    {deallocate, 4}.
    return.
  {label, 838}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@File}, {y, 0}, {y, 1}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.
% Open the file at `path` for writing: created, or truncated.

{function, create, 1, 59}.
  {label, 58}.
    {line, [{location, "std@io@fs.erl", 41}]}.
    {func_info, {atom, std@io@fs}, {atom, create}, 1}.
  {label, 59}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 840}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 25}}.
    {test, is_tagged_tuple, {f, 862}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 863}}.
  {label, 862}.
    {deallocate, 4}.
    return.
  {label, 863}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@File}, {y, 0}, {y, 1}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.
% An `Asset` (`@embed`, decisions 519, 538) as a `File`: the embedded bytes, read
% like a file on disk — no `Result`, the build proved the file exists — and
% closing it is a no-op.

{function, openAsset, 1, 61}.
  {label, 60}.
    {line, [{location, "std@io@fs.erl", 42}]}.
    {func_info, {atom, std@io@fs}, {atom, openAsset}, 1}.
  {label, 61}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, path}, {x, 1}}.
    {call, 2, {f, 865}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, bytes}, {x, 1}}.
    {call, 2, {f, 865}}.
    {call, 1, {f, 871}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@File}, {y, 1}, {x, 0}]}}.
    {deallocate, 3}.
    return.
% ── the wasm bodies (decision 992) ───────────────────────────────────────────
% `io.fs` on wasm answers what it answers on commonJS, erlang and beam: the same functions
% over the file system of the process, the same paths (a relative one is read against the
% working directory, an absolute one as it is), the same answers and the same errors. The
% host is `wasi:filesystem`, reached through std-wasm's leaves (`modules/std-wasm/wat/fs.wat`;
% the `wasi…` declarations below), which the runner serves with the root and the working
% directory preopened (`needs: [.Filesystem]`, no flag). A leaf answers a host failure as
% `-(1 + code)`, `code` the ordinal of `wasi:filesystem`'s `error-code`, or as the `Error`
% of a `Result<_, i32>` holding the code; `wasiError` writes it as Node's text
% (`ENOENT: …`), which `fsError` reads as it reads every target's.
% The POSIX name of the host's error `code`, and its text.

{function, wasiName, 1, 63}.
  {label, 62}.
    {line, [{location, "std@io@fs.erl", 43}]}.
    {func_info, {atom, std@io@fs}, {atom, wasiName}, 1}.
  {label, 63}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"EXDEV">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"ETXTBSY">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"ESPIPE">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"EROFS">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"EPIPE">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"EPERM">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"EOVERFLOW">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"ENXIO">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"ENOTTY">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"ENOTSUP">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"ENOTRECOVERABLE">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"ENOTEMPTY">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"ENOTDIR">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"ENOSPC">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"ENOMEM">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"ENOLCK">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"ENOENT">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"ENODEV">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"ENAMETOOLONG">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"EMSGSIZE">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"EMLINK">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"ELOOP">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"EISDIR">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"EIO">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"EINVAL">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"EINTR">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"EINPROGRESS">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"EILSEQ">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"EFBIG">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"EEXIST">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"EDQUOT">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"EDEADLK">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"EBUSY">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"EBADF">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"EALREADY">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"EAGAIN">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"EACCES">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 872}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 873}}.
  {label, 872}.
    {move, {literal, <<"EIO">>}, {x, 0}}.
  {label, 873}.
    {deallocate, 4}.
    return.

{function, wasiText, 1, 65}.
  {label, 64}.
    {line, [{location, "std@io@fs.erl", 44}]}.
    {func_info, {atom, std@io@fs}, {atom, wasiText}, 1}.
  {label, 65}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"cross-device link not permitted">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"text file busy">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"invalid seek">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"read-only file system">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"broken pipe">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"operation not permitted">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"value too large for defined data type">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"no such device or address">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"inappropriate ioctl for device">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"operation not supported">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"state not recoverable">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"directory not empty">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"not a directory">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"no space left on device">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"not enough memory">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"no locks available">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"no such file or directory">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"no such device">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"name too long">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"message too long">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"too many links">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"too many symbolic links encountered">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"illegal operation on a directory">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"i/o error">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"invalid argument">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"interrupted system call">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"operation in progress">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"illegal byte sequence">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"file too large">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"file already exists">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"disk quota exceeded">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"resource deadlock avoided">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"resource busy or locked">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"bad file descriptor">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"connection already in progress">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"resource temporarily unavailable">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"permission denied">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 874}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 875}}.
  {label, 874}.
    {move, {literal, <<"i/o error">>}, {x, 0}}.
  {label, 875}.
    {deallocate, 4}.
    return.
% The `HostError` of the host's error `code`: `ENOENT: no such file or directory`.

{function, wasiError, 1, 67}.
  {label, 66}.
    {line, [{location, "std@io@fs.erl", 45}]}.
    {func_info, {atom, std@io@fs}, {atom, wasiError}, 1}.
  {label, 67}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 65}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<": ">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 667}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"host">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {x, 0}}.
    {test_heap, 6, 3}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {x, 1}, {x, 2}, {x, 0}, {atom, undefined}]}}.
    {deallocate, 2}.
    return.
% The `Ok` of a leaf's answer, its `Error` the `HostError` of the code.

{function, okBytes, 1, 69}.
  {label, 68}.
    {line, [{location, "std@io@fs.erl", 46}]}.
    {func_info, {atom, std@io@fs}, {atom, okBytes}, 1}.
  {label, 69}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 877}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.
    {jump, {f, 876}}.
  {label, 877}.
    {test, is_tagged_tuple, {f, 878}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 3}.
    return.
    {jump, {f, 876}}.
  {label, 878}.
    {case_end, {x, 0}}.
  {label, 876}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, okStrings, 1, 71}.
  {label, 70}.
    {line, [{location, "std@io@fs.erl", 47}]}.
    {func_info, {atom, std@io@fs}, {atom, okStrings}, 1}.
  {label, 71}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 880}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.
    {jump, {f, 879}}.
  {label, 880}.
    {test, is_tagged_tuple, {f, 881}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 3}.
    return.
    {jump, {f, 879}}.
  {label, 881}.
    {case_end, {x, 0}}.
  {label, 879}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, okSize, 1, 73}.
  {label, 72}.
    {line, [{location, "std@io@fs.erl", 48}]}.
    {func_info, {atom, std@io@fs}, {atom, okSize}, 1}.
  {label, 73}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 883}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.
    {jump, {f, 882}}.
  {label, 883}.
    {test, is_tagged_tuple, {f, 884}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 3}.
    return.
    {jump, {f, 882}}.
  {label, 884}.
    {case_end, {x, 0}}.
  {label, 882}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.
% `path` without the slashes it begins with: the host reads a path relative to the root it preopens.

{function, withoutRoot, 1, 75}.
  {label, 74}.
    {line, [{location, "std@io@fs.erl", 49}]}.
    {func_info, {atom, std@io@fs}, {atom, withoutRoot}, 1}.
  {label, 75}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {line, [{location, "std@io@fs.erl", 50}]}.
  {label, 885}.
    {move, {literal, <<"/">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 887}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 888}}.
  {label, 887}.
    {move, {atom, true}, {x, 0}}.
  {label, 888}.
    {test, is_eq_exact, {f, 886}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, undefined}, {x, 2}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 3, {f, 890}}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 885}}.
  {label, 886}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
% `name` inside `dir`, `dir` empty being the root.

{function, joinPath, 2, 77}.
  {label, 76}.
    {line, [{location, "std@io@fs.erl", 50}]}.
    {func_info, {atom, std@io@fs}, {atom, joinPath}, 2}.
  {label, 77}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 891}, [{y, 0}, {x, 0}]}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 891}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"/">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 667}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 3}.
    return.
% `path` as the host reads it: absolute, as it is; relative, from the working directory. The empty
% path is no file (`ENOENT`), as it is on every target.

{function, resolve, 1, 79}.
  {label, 78}.
    {line, [{location, "std@io@fs.erl", 51}]}.
    {func_info, {atom, std@io@fs}, {atom, resolve}, 1}.
  {label, 79}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 892}, [{y, 0}, {x, 0}]}.
    {move, {integer, 20}, {x, 0}}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 3}.
    return.
  {label, 892}.
    {move, {literal, <<"/">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 894}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 895}}.
  {label, 894}.
    {move, {atom, true}, {x, 0}}.
  {label, 895}.
    {test, is_eq, {f, 893}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 75}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.
  {label, 893}.
    {call, 0, {f, 897}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 899}, [{y, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 900}}.
  {label, 899}.
    {move, {atom, false}, {x, 0}}.
  {label, 900}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 901}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"/">>}, {x, 0}}.
    {test, is_eq_exact, {f, 903}, [{y, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 904}}.
  {label, 903}.
    {move, {atom, false}, {x, 0}}.
  {label, 904}.
    {jump, {f, 902}}.
  {label, 901}.
    {move, {atom, true}, {x, 0}}.
  {label, 902}.
    {test, is_eq, {f, 898}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.
  {label, 898}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"/">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 667}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {call, 1, {f, 75}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.
% The file a handle holds: the handle block `rawOpen`, `rawCreate` and `memHandle` answered.

{function, blockOf, 1, 81}.
  {label, 80}.
    {line, [{location, "std@io@fs.erl", 52}]}.
    {func_info, {atom, std@io@fs}, {atom, blockOf}, 1}.
  {label, 81}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 909}, [{x, 0}]}.
    {jump, {f, 908}}.
  {label, 909}.
    {test, is_float, {f, 906}, [{x, 0}]}.
    {gc_bif, trunc, {f, 0}, 1, [{x, 0}], {x, 1}}.
    {test, is_eq, {f, 906}, [{x, 0}, {x, 1}]}.
  {label, 908}.
    {test, is_ge, {f, 906}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 906}, [{integer, 2147483647}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 907}}.
  {label, 906}.
    {move, {atom, false}, {x, 0}}.
  {label, 907}.
    {test, is_eq, {f, 905}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, trunc, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 910}}.
  {label, 905}.
  {label, 910}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 4}.
    return.
% Whether `a` sorts before `b` by the bytes of their UTF-8 (string `<` is not a wasm GC operation).

{function, bytesBefore, 2, 83}.
  {label, 82}.
    {line, [{location, "std@io@fs.erl", 53}]}.
    {func_info, {atom, std@io@fs}, {atom, bytesBefore}, 2}.
  {label, 83}.
    {allocate, 9, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 912}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 912}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call, 1, {f, 914}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 914}}.
    {move, {x, 0}, {y, 5}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {line, [{location, "std@io@fs.erl", 54}]}.
  {label, 915}.
    {test, is_lt, {f, 917}, [{y, 6}, {y, 4}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 918}}.
  {label, 917}.
    {move, {atom, false}, {x, 0}}.
  {label, 918}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 919}, [{x, 1}, {atom, true}]}.
    {test, is_lt, {f, 921}, [{y, 6}, {y, 5}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 922}}.
  {label, 921}.
    {move, {atom, false}, {x, 0}}.
  {label, 922}.
    {jump, {f, 920}}.
  {label, 919}.
    {move, {atom, false}, {x, 0}}.
  {label, 920}.
    {test, is_eq_exact, {f, 916}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call, 2, {f, 924}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call, 2, {f, 924}}.
    {move, {x, 0}, {y, 8}}.
    {test, is_ne_exact, {f, 925}, [{y, 7}, {y, 8}]}.
    {test, is_lt, {f, 926}, [{y, 7}, {y, 8}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 927}}.
  {label, 926}.
    {move, {atom, false}, {x, 0}}.
  {label, 927}.
    {deallocate, 9}.
    return.
  {label, 925}.
    {gc_bif, '+', {f, 0}, 0, [{y, 6}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 928}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 928}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 929}}.
  {label, 928}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:988:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 929}.
    {move, {x, 0}, {y, 6}}.
    {jump, {f, 915}}.
  {label, 916}.
    {test, is_lt, {f, 930}, [{y, 4}, {y, 5}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 931}}.
  {label, 930}.
    {move, {atom, false}, {x, 0}}.
  {label, 931}.
    {deallocate, 9}.
    return.
% The names sorted by the bytes of their UTF-8, none twice: what `readdirSync` answers on Node.

{function, sortedStrings, 1, 85}.
  {label, 84}.
    {line, [{location, "std@io@fs.erl", 54}]}.
    {func_info, {atom, std@io@fs}, {atom, sortedStrings}, 1}.
  {label, 85}.
    {allocate, 17, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {line, [{location, "std@io@fs.erl", 55}]}.
  {label, 932}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 933}, [{y, 2}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 934}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 935}}.
  {label, 934}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 935}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 936}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 936}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 937}}.
  {label, 936}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:999:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 937}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {line, [{location, "std@io@fs.erl", 55}]}.
  {label, 938}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 940}, [{y, 5}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 941}}.
  {label, 940}.
    {move, {atom, false}, {x, 0}}.
  {label, 941}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 942}, [{x, 1}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 944}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {jump, {f, 945}}.
  {label, 944}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 945}.
    {move, {y, 4}, {x, 1}}.
    {call, 2, {f, 83}}.
    {jump, {f, 943}}.
  {label, 942}.
    {move, {atom, false}, {x, 0}}.
  {label, 943}.
    {test, is_eq_exact, {f, 939}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 5}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 946}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 946}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 947}}.
  {label, 946}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1002:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 947}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 938}}.
  {label, 939}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 949}, [{y, 5}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 950}}.
  {label, 949}.
    {move, {atom, false}, {x, 0}}.
  {label, 950}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 951}, [{x, 1}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 953}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {jump, {f, 954}}.
  {label, 953}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 954}.
    {test, is_eq_exact, {f, 955}, [{x, 0}, {y, 4}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 956}}.
  {label, 955}.
    {move, {atom, false}, {x, 0}}.
  {label, 956}.
    {jump, {f, 952}}.
  {label, 951}.
    {move, {atom, false}, {x, 0}}.
  {label, 952}.
    {test, is_eq, {f, 948}, [{x, 0}, {atom, true}]}.
    {jump, {f, 932}}.
  {label, 948}.
    {test, is_ne_exact, {f, 957}, [{y, 5}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 0, [{integer, 0}, {integer, 1}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 5}, {integer, 0}], {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 958}}.
  {label, 957}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 958}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 8}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 932}}.
  {label, 933}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 17}.
    return.

{function, readBytesWasm, 1, 87}.
  {label, 86}.
    {line, [{location, "std@io@fs.erl", 55}]}.
    {func_info, {atom, std@io@fs}, {atom, readBytesWasm}, 1}.
  {label, 87}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 79}}.
    {test, is_tagged_tuple, {f, 959}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 960}}.
  {label, 959}.
    {deallocate, 5}.
    return.
  {label, 960}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 924}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_lt, {f, 961}, [{y, 2}, {integer, 0}]}.
    {gc_bif, '-', {f, 0}, 0, [{integer, -1}, {y, 2}], {x, 0}}.
    {test, is_ge, {f, 962}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 962}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 963}}.
  {label, 962}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1013:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 963}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 5}.
    return.
  {label, 961}.
    {move, {y, 2}, {x, 0}}.
    {call, 1, {f, 965}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call, 1, {f, 965}}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 69}}.
    {test, is_tagged_tuple, {f, 966}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 967}}.
  {label, 966}.
    {deallocate, 5}.
    return.
  {label, 967}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 5}.
    return.

{function, writeBytesWasm, 2, 89}.
  {label, 88}.
    {line, [{location, "std@io@fs.erl", 56}]}.
    {func_info, {atom, std@io@fs}, {atom, writeBytesWasm}, 2}.
  {label, 89}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 79}}.
    {test, is_tagged_tuple, {f, 968}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 969}}.
  {label, 968}.
    {deallocate, 5}.
    return.
  {label, 969}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 924}}.
    {move, {x, 0}, {y, 3}}.
    {test, is_lt, {f, 970}, [{y, 3}, {integer, 0}]}.
    {gc_bif, '-', {f, 0}, 0, [{integer, -1}, {y, 3}], {x, 0}}.
    {test, is_ge, {f, 971}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 971}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 972}}.
  {label, 971}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1023:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 972}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 5}.
    return.
  {label, 970}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 924}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 965}}.
    {test, is_lt, {f, 973}, [{y, 4}, {integer, 0}]}.
    {gc_bif, '-', {f, 0}, 0, [{integer, -1}, {y, 4}], {x, 0}}.
    {test, is_ge, {f, 974}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 974}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 975}}.
  {label, 974}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1026:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 975}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 5}.
    return.
  {label, 973}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 5}.
    return.

{function, writeTextWasm, 2, 91}.
  {label, 90}.
    {line, [{location, "std@io@fs.erl", 57}]}.
    {func_info, {atom, std@io@fs}, {atom, writeTextWasm}, 2}.
  {label, 91}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 912}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 89}}.
    {test, is_tagged_tuple, {f, 976}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 977}}.
  {label, 976}.
    {deallocate, 5}.
    return.
  {label, 977}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 5}.
    return.

{function, appendTextWasm, 2, 93}.
  {label, 92}.
    {line, [{location, "std@io@fs.erl", 58}]}.
    {func_info, {atom, std@io@fs}, {atom, appendTextWasm}, 2}.
  {label, 93}.
    {allocate, 8, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 79}}.
    {test, is_tagged_tuple, {f, 978}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 979}}.
  {label, 978}.
    {deallocate, 8}.
    return.
  {label, 979}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 2}, {x, 1}}.
    {call, 2, {f, 924}}.
    {move, {x, 0}, {y, 3}}.
    {test, is_lt, {f, 980}, [{y, 3}, {integer, 0}]}.
    {gc_bif, '-', {f, 0}, 0, [{integer, -1}, {y, 3}], {x, 0}}.
    {test, is_ge, {f, 981}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 981}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 982}}.
  {label, 981}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1038:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 982}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 8}.
    return.
  {label, 980}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 965}}.
    {move, {x, 0}, {y, 4}}.
    {test, is_lt, {f, 983}, [{y, 4}, {integer, 0}]}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 965}}.
    {move, {integer, 13}, {x, 0}}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 8}.
    return.
  {label, 983}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call, 2, {f, 924}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 912}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {call, 2, {f, 924}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 965}}.
    {test, is_lt, {f, 984}, [{y, 5}, {integer, 0}]}.
    {gc_bif, '-', {f, 0}, 0, [{integer, -1}, {y, 5}], {x, 0}}.
    {test, is_ge, {f, 985}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 985}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 986}}.
  {label, 985}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1047:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 986}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 8}.
    return.
  {label, 984}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 8}.
    return.
% The offset of the first byte that starts a sequence that is not UTF-8, `-1` when there is none.

{function, utf8OffsetWasm, 1, 95}.
  {label, 94}.
    {line, [{location, "std@io@fs.erl", 59}]}.
    {func_info, {atom, std@io@fs}, {atom, utf8OffsetWasm}, 1}.
  {label, 95}.
    {allocate, 10, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 914}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {line, [{location, "std@io@fs.erl", 60}]}.
  {label, 987}.
    {test, is_lt, {f, 988}, [{y, 2}, {y, 1}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 924}}.
    {move, {x, 0}, {y, 3}}.
    {test, is_lt, {f, 989}, [{y, 3}, {integer, 128}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 990}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 990}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 991}}.
  {label, 990}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1058:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 991}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 987}}.
  {label, 989}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {test, is_ge, {f, 993}, [{y, 3}, {integer, 194}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 994}}.
  {label, 993}.
    {move, {atom, false}, {x, 0}}.
  {label, 994}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 995}, [{x, 1}, {atom, true}]}.
    {test, is_ge, {f, 997}, [{integer, 223}, {y, 3}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 998}}.
  {label, 997}.
    {move, {atom, false}, {x, 0}}.
  {label, 998}.
    {jump, {f, 996}}.
  {label, 995}.
    {move, {atom, false}, {x, 0}}.
  {label, 996}.
    {test, is_eq, {f, 992}, [{x, 0}, {atom, true}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 999}}.
  {label, 992}.
    {test, is_ge, {f, 1001}, [{y, 3}, {integer, 224}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1002}}.
  {label, 1001}.
    {move, {atom, false}, {x, 0}}.
  {label, 1002}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 1003}, [{x, 1}, {atom, true}]}.
    {test, is_ge, {f, 1005}, [{integer, 239}, {y, 3}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1006}}.
  {label, 1005}.
    {move, {atom, false}, {x, 0}}.
  {label, 1006}.
    {jump, {f, 1004}}.
  {label, 1003}.
    {move, {atom, false}, {x, 0}}.
  {label, 1004}.
    {test, is_eq, {f, 1000}, [{x, 0}, {atom, true}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 1007}}.
  {label, 1000}.
    {test, is_ge, {f, 1009}, [{y, 3}, {integer, 240}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1010}}.
  {label, 1009}.
    {move, {atom, false}, {x, 0}}.
  {label, 1010}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 1011}, [{x, 1}, {atom, true}]}.
    {test, is_ge, {f, 1013}, [{integer, 244}, {y, 3}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1014}}.
  {label, 1013}.
    {move, {atom, false}, {x, 0}}.
  {label, 1014}.
    {jump, {f, 1012}}.
  {label, 1011}.
    {move, {atom, false}, {x, 0}}.
  {label, 1012}.
    {test, is_eq, {f, 1008}, [{x, 0}, {atom, true}]}.
    {move, {integer, 3}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 1015}}.
  {label, 1008}.
    {move, {y, 2}, {x, 0}}.
    {call_last, 1, {f, 1017}, 10}.
  {label, 1015}.
  {label, 1007}.
  {label, 999}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {y, 4}], {x, 0}}.
    {test, is_ge, {f, 1029}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1029}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1030}}.
  {label, 1029}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1071:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1030}.
    {test, is_ge, {f, 1028}, [{x, 0}, {y, 1}]}.
    {move, {y, 2}, {x, 0}}.
    {call_last, 1, {f, 1017}, 10}.
  {label, 1028}.
    {move, {integer, 128}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {integer, 191}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {test, is_eq_exact, {f, 1031}, [{y, 3}, {integer, 224}]}.
    {move, {integer, 160}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 1032}}.
  {label, 1031}.
    {test, is_eq_exact, {f, 1033}, [{y, 3}, {integer, 237}]}.
    {move, {integer, 159}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {jump, {f, 1034}}.
  {label, 1033}.
    {test, is_eq_exact, {f, 1035}, [{y, 3}, {integer, 240}]}.
    {move, {integer, 144}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 1036}}.
  {label, 1035}.
    {test, is_eq_exact, {f, 1037}, [{y, 3}, {integer, 244}]}.
    {move, {integer, 143}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {jump, {f, 1038}}.
  {label, 1037}.
  {label, 1038}.
  {label, 1036}.
  {label, 1034}.
  {label, 1032}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1039}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1039}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1040}}.
  {label, 1039}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1083:36">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1040}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 924}}.
    {move, {x, 0}, {y, 7}}.
    {test, is_lt, {f, 1042}, [{y, 7}, {y, 5}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1043}}.
  {label, 1042}.
    {move, {atom, false}, {x, 0}}.
  {label, 1043}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 1044}, [{x, 1}, {atom, true}]}.
    {test, is_lt, {f, 1046}, [{y, 6}, {y, 7}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1047}}.
  {label, 1046}.
    {move, {atom, false}, {x, 0}}.
  {label, 1047}.
    {jump, {f, 1045}}.
  {label, 1044}.
    {move, {atom, true}, {x, 0}}.
  {label, 1045}.
    {test, is_eq, {f, 1041}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {call_last, 1, {f, 1017}, 10}.
  {label, 1041}.
    {move, {integer, 2}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {line, [{location, "std@io@fs.erl", 60}]}.
  {label, 1048}.
    {test, is_ge, {f, 1049}, [{y, 4}, {y, 8}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {y, 8}], {x, 0}}.
    {test, is_ge, {f, 1050}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1050}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1051}}.
  {label, 1050}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1087:40">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1051}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 924}}.
    {move, {x, 0}, {y, 9}}.
    {test, is_lt, {f, 1053}, [{y, 9}, {integer, 128}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1054}}.
  {label, 1053}.
    {move, {atom, false}, {x, 0}}.
  {label, 1054}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 1055}, [{x, 1}, {atom, true}]}.
    {test, is_lt, {f, 1057}, [{integer, 191}, {y, 9}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1058}}.
  {label, 1057}.
    {move, {atom, false}, {x, 0}}.
  {label, 1058}.
    {jump, {f, 1056}}.
  {label, 1055}.
    {move, {atom, true}, {x, 0}}.
  {label, 1056}.
    {test, is_eq, {f, 1052}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {call_last, 1, {f, 1017}, 10}.
  {label, 1052}.
    {gc_bif, '+', {f, 0}, 0, [{y, 8}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1059}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1059}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1060}}.
  {label, 1059}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1089:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1060}.
    {move, {x, 0}, {y, 8}}.
    {jump, {f, 1048}}.
  {label, 1049}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {y, 4}], {x, 0}}.
    {test, is_ge, {f, 1061}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1061}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1062}}.
  {label, 1061}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1091:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1062}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1063}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1063}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1064}}.
  {label, 1063}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1091:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1064}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 987}}.
  {label, 988}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 10}.
    return.

{function, stripEolWasm, 1, 97}.
  {label, 96}.
    {line, [{location, "std@io@fs.erl", 60}]}.
    {func_info, {atom, std@io@fs}, {atom, stripEolWasm}, 1}.
  {label, 97}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 914}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_lt, {f, 1066}, [{integer, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1067}}.
  {label, 1066}.
    {move, {atom, false}, {x, 0}}.
  {label, 1067}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 1068}, [{x, 1}, {atom, true}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1070}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1070}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1071}}.
  {label, 1070}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1098:37">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1071}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 924}}.
    {test, is_eq_exact, {f, 1072}, [{x, 0}, {integer, 10}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1073}}.
  {label, 1072}.
    {move, {atom, false}, {x, 0}}.
  {label, 1073}.
    {jump, {f, 1069}}.
  {label, 1068}.
    {move, {atom, false}, {x, 0}}.
  {label, 1069}.
    {test, is_eq, {f, 1065}, [{x, 0}, {atom, true}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1074}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1074}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1075}}.
  {label, 1074}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1099:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1075}.
    {move, {x, 0}, {y, 1}}.
    {test, is_lt, {f, 1077}, [{integer, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1078}}.
  {label, 1077}.
    {move, {atom, false}, {x, 0}}.
  {label, 1078}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 1079}, [{x, 1}, {atom, true}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1081}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1081}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1082}}.
  {label, 1081}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1100:41">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1082}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 924}}.
    {test, is_eq_exact, {f, 1083}, [{x, 0}, {integer, 13}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1084}}.
  {label, 1083}.
    {move, {atom, false}, {x, 0}}.
  {label, 1084}.
    {jump, {f, 1080}}.
  {label, 1079}.
    {move, {atom, false}, {x, 0}}.
  {label, 1080}.
    {test, is_eq, {f, 1076}, [{x, 0}, {atom, true}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1085}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1085}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1086}}.
  {label, 1085}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1100:59">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1086}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 1087}}.
  {label, 1076}.
  {label, 1087}.
    {jump, {f, 1088}}.
  {label, 1065}.
  {label, 1088}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 2}}.
    {move, {integer, 0}, {x, 1}}.
    {call_last, 3, {f, 1090}, 6}.

{function, openWasm, 1, 99}.
  {label, 98}.
    {line, [{location, "std@io@fs.erl", 61}]}.
    {func_info, {atom, std@io@fs}, {atom, openWasm}, 1}.
  {label, 99}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 79}}.
    {test, is_tagged_tuple, {f, 1091}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 1092}}.
  {label, 1091}.
    {deallocate, 4}.
    return.
  {label, 1092}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 924}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_lt, {f, 1093}, [{y, 2}, {integer, 0}]}.
    {gc_bif, '-', {f, 0}, 0, [{integer, -1}, {y, 2}], {x, 0}}.
    {test, is_ge, {f, 1094}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1094}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1095}}.
  {label, 1094}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1108:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1095}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 4}.
    return.
  {label, 1093}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, createWasm, 1, 101}.
  {label, 100}.
    {line, [{location, "std@io@fs.erl", 62}]}.
    {func_info, {atom, std@io@fs}, {atom, createWasm}, 1}.
  {label, 101}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 79}}.
    {test, is_tagged_tuple, {f, 1096}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 1097}}.
  {label, 1096}.
    {deallocate, 4}.
    return.
  {label, 1097}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 924}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_lt, {f, 1098}, [{y, 2}, {integer, 0}]}.
    {gc_bif, '-', {f, 0}, 0, [{integer, -1}, {y, 2}], {x, 0}}.
    {test, is_ge, {f, 1099}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1099}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1100}}.
  {label, 1099}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1116:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1100}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 4}.
    return.
  {label, 1098}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, memHandleWasm, 1, 103}.
  {label, 102}.
    {line, [{location, "std@io@fs.erl", 63}]}.
    {func_info, {atom, std@io@fs}, {atom, memHandleWasm}, 1}.
  {label, 103}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 965}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, sizeWasm, 2, 105}.
  {label, 104}.
    {line, [{location, "std@io@fs.erl", 64}]}.
    {func_info, {atom, std@io@fs}, {atom, sizeWasm}, 2}.
  {label, 105}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 81}}.
    {call, 1, {f, 965}}.
    {call, 1, {f, 73}}.
    {test, is_tagged_tuple, {f, 1101}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 1102}}.
  {label, 1101}.
    {deallocate, 3}.
    return.
  {label, 1102}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.

{function, readWasm, 2, 107}.
  {label, 106}.
    {line, [{location, "std@io@fs.erl", 65}]}.
    {func_info, {atom, std@io@fs}, {atom, readWasm}, 2}.
  {label, 107}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 81}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 924}}.
    {call, 1, {f, 69}}.
    {test, is_tagged_tuple, {f, 1103}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 1104}}.
  {label, 1103}.
    {deallocate, 3}.
    return.
  {label, 1104}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.

{function, readAllWasm, 1, 109}.
  {label, 108}.
    {line, [{location, "std@io@fs.erl", 66}]}.
    {func_info, {atom, std@io@fs}, {atom, readAllWasm}, 1}.
  {label, 109}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 81}}.
    {call, 1, {f, 965}}.
    {call, 1, {f, 69}}.
    {test, is_tagged_tuple, {f, 1105}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 1106}}.
  {label, 1105}.
    {deallocate, 2}.
    return.
  {label, 1106}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.

{function, readLineWasm, 1, 111}.
  {label, 110}.
    {line, [{location, "std@io@fs.erl", 67}]}.
    {func_info, {atom, std@io@fs}, {atom, readLineWasm}, 1}.
  {label, 111}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 81}}.
    {call, 1, {f, 965}}.
    {call, 1, {f, 69}}.
    {test, is_tagged_tuple, {f, 1107}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 1108}}.
  {label, 1107}.
    {deallocate, 2}.
    return.
  {label, 1108}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.
% The SHA-256 of the whole file, the position where it was.

{function, hashWasm, 1, 113}.
  {label, 112}.
    {line, [{location, "std@io@fs.erl", 68}]}.
    {func_info, {atom, std@io@fs}, {atom, hashWasm}, 1}.
  {label, 113}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 81}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 965}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 924}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 965}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 924}}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 69}}.
    {test, is_tagged_tuple, {f, 1109}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 1110}}.
  {label, 1109}.
    {deallocate, 5}.
    return.
  {label, 1110}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call, 1, {f, 965}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 5}.
    return.

{function, writeWasm, 2, 115}.
  {label, 114}.
    {line, [{location, "std@io@fs.erl", 69}]}.
    {func_info, {atom, std@io@fs}, {atom, writeWasm}, 2}.
  {label, 115}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 81}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 924}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_lt, {f, 1111}, [{y, 2}, {integer, 0}]}.
    {gc_bif, '-', {f, 0}, 0, [{integer, -1}, {y, 2}], {x, 0}}.
    {test, is_ge, {f, 1112}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1112}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1113}}.
  {label, 1112}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1159:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1113}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 3}.
    return.
  {label, 1111}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.

{function, closeWasm, 1, 117}.
  {label, 116}.
    {line, [{location, "std@io@fs.erl", 70}]}.
    {func_info, {atom, std@io@fs}, {atom, closeWasm}, 1}.
  {label, 117}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 81}}.
    {call, 1, {f, 965}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.

{function, readOnlyWasm, 1, 119}.
  {label, 118}.
    {line, [{location, "std@io@fs.erl", 71}]}.
    {func_info, {atom, std@io@fs}, {atom, readOnlyWasm}, 1}.
  {label, 119}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 81}}.
    {call_last, 1, {f, 965}, 1}.

{function, existsWasm, 1, 121}.
  {label, 120}.
    {line, [{location, "std@io@fs.erl", 72}]}.
    {func_info, {atom, std@io@fs}, {atom, existsWasm}, 1}.
  {label, 121}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 79}}.
    {test, is_tagged_tuple, {f, 1115}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 924}}.
    {test, is_ge, {f, 1116}, [{x, 0}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1117}}.
  {label, 1116}.
    {move, {atom, false}, {x, 0}}.
  {label, 1117}.
    {jump, {f, 1114}}.
  {label, 1115}.
    {test, is_tagged_tuple, {f, 1118}, [{x, 0}, 2, {atom, error}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 1114}}.
  {label, 1118}.
    {case_end, {x, 0}}.
  {label, 1114}.
    {deallocate, 2}.
    return.

{function, listWasm, 1, 123}.
  {label, 122}.
    {line, [{location, "std@io@fs.erl", 73}]}.
    {func_info, {atom, std@io@fs}, {atom, listWasm}, 1}.
  {label, 123}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 79}}.
    {test, is_tagged_tuple, {f, 1119}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 1120}}.
  {label, 1119}.
    {deallocate, 3}.
    return.
  {label, 1120}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 965}}.
    {call, 1, {f, 71}}.
    {test, is_tagged_tuple, {f, 1121}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 1122}}.
  {label, 1121}.
    {deallocate, 3}.
    return.
  {label, 1122}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call, 1, {f, 85}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.

{function, mkdirWasm, 1, 125}.
  {label, 124}.
    {line, [{location, "std@io@fs.erl", 74}]}.
    {func_info, {atom, std@io@fs}, {atom, mkdirWasm}, 1}.
  {label, 125}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 79}}.
    {test, is_tagged_tuple, {f, 1123}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 1124}}.
  {label, 1123}.
    {deallocate, 3}.
    return.
  {label, 1124}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 965}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_lt, {f, 1125}, [{y, 2}, {integer, 0}]}.
    {gc_bif, '-', {f, 0}, 0, [{integer, -1}, {y, 2}], {x, 0}}.
    {test, is_ge, {f, 1126}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1126}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1127}}.
  {label, 1126}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1188:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1127}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 3}.
    return.
  {label, 1125}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.
% The directory and every missing one above it. One that is there is `Ok`; a file in the way is
% `EEXIST` when it is the directory asked for, `ENOTDIR` when it is above it.

{function, mkdirRecursiveWasm, 1, 127}.
  {label, 126}.
    {line, [{location, "std@io@fs.erl", 75}]}.
    {func_info, {atom, std@io@fs}, {atom, mkdirRecursiveWasm}, 1}.
  {label, 127}.
    {allocate, 15, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 79}}.
    {test, is_tagged_tuple, {f, 1128}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 1129}}.
  {label, 1128}.
    {deallocate, 15}.
    return.
  {label, 1129}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"/">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 1131}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {line, [{location, "std@io@fs.erl", 76}]}.
  {label, 1147}.
    {move, {y, 3}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 1148}, [{y, 4}, {x, 0}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1149}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {jump, {f, 1150}}.
  {label, 1149}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1150}.
    {move, {x, 0}, {y, 6}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1151}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1151}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1152}}.
  {label, 1151}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1201:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1152}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 1154}, [{y, 6}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1155}}.
  {label, 1154}.
    {move, {atom, false}, {x, 0}}.
  {label, 1155}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 1156}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<".">>}, {x, 0}}.
    {test, is_ne_exact, {f, 1158}, [{y, 6}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1159}}.
  {label, 1158}.
    {move, {atom, false}, {x, 0}}.
  {label, 1159}.
    {jump, {f, 1157}}.
  {label, 1156}.
    {move, {atom, false}, {x, 0}}.
  {label, 1157}.
    {test, is_eq, {f, 1153}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 1160}}.
  {label, 1153}.
  {label, 1160}.
    {jump, {f, 1147}}.
  {label, 1148}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {line, [{location, "std@io@fs.erl", 76}]}.
  {label, 1161}.
    {move, {y, 2}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 1162}, [{y, 9}, {x, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1163}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {jump, {f, 1164}}.
  {label, 1163}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1164}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 8}, {x, 0}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 8}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 9}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1165}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1165}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1166}}.
  {label, 1165}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1208:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1166}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 924}}.
    {move, {x, 0}, {y, 11}}.
    {test, is_eq_exact, {f, 1167}, [{y, 11}, {integer, 3}]}.
    {jump, {f, 1161}}.
  {label, 1167}.
    {test, is_ge, {f, 1168}, [{y, 11}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 1169}, [{y, 9}, {x, 0}]}.
    {move, {integer, 7}, {x, 0}}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 15}.
    return.
  {label, 1169}.
    {move, {integer, 24}, {x, 0}}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 15}.
    return.
  {label, 1168}.
    {move, {y, 8}, {x, 0}}.
    {call, 1, {f, 965}}.
    {move, {x, 0}, {y, 12}}.
    {test, is_lt, {f, 1170}, [{y, 12}, {integer, 0}]}.
    {gc_bif, '-', {f, 0}, 0, [{integer, -1}, {y, 12}], {x, 0}}.
    {test, is_ge, {f, 1171}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1171}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1172}}.
  {label, 1171}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1216:42">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1172}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 15}.
    return.
  {label, 1170}.
    {jump, {f, 1161}}.
  {label, 1162}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 15}.
    return.
% The FILE at `path`: a directory is `EISDIR`, whatever it holds.

{function, rmWasm, 1, 129}.
  {label, 128}.
    {line, [{location, "std@io@fs.erl", 76}]}.
    {func_info, {atom, std@io@fs}, {atom, rmWasm}, 1}.
  {label, 129}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 79}}.
    {test, is_tagged_tuple, {f, 1173}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 1174}}.
  {label, 1173}.
    {deallocate, 4}.
    return.
  {label, 1174}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 924}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_lt, {f, 1175}, [{y, 2}, {integer, 0}]}.
    {gc_bif, '-', {f, 0}, 0, [{integer, -1}, {y, 2}], {x, 0}}.
    {test, is_ge, {f, 1176}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1176}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1177}}.
  {label, 1176}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1225:38">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1177}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 4}.
    return.
  {label, 1175}.
    {test, is_eq_exact, {f, 1178}, [{y, 2}, {integer, 3}]}.
    {move, {integer, 14}, {x, 0}}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 4}.
    return.
  {label, 1178}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 965}}.
    {move, {x, 0}, {y, 3}}.
    {test, is_lt, {f, 1179}, [{y, 3}, {integer, 0}]}.
    {gc_bif, '-', {f, 0}, 0, [{integer, -1}, {y, 3}], {x, 0}}.
    {test, is_ge, {f, 1180}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1180}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1181}}.
  {label, 1180}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1228:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1181}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 4}.
    return.
  {label, 1179}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, copyWasm, 2, 131}.
  {label, 130}.
    {line, [{location, "std@io@fs.erl", 77}]}.
    {func_info, {atom, std@io@fs}, {atom, copyWasm}, 2}.
  {label, 131}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 87}}.
    {test, is_tagged_tuple, {f, 1182}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 1183}}.
  {label, 1182}.
    {deallocate, 4}.
    return.
  {label, 1183}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 89}}.
    {test, is_tagged_tuple, {f, 1184}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 1185}}.
  {label, 1184}.
    {deallocate, 4}.
    return.
  {label, 1185}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, statWasm, 1, 133}.
  {label, 132}.
    {line, [{location, "std@io@fs.erl", 78}]}.
    {func_info, {atom, std@io@fs}, {atom, statWasm}, 1}.
  {label, 133}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 79}}.
    {test, is_tagged_tuple, {f, 1186}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 1187}}.
  {label, 1186}.
    {deallocate, 5}.
    return.
  {label, 1187}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 924}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_lt, {f, 1188}, [{y, 2}, {integer, 0}]}.
    {gc_bif, '-', {f, 0}, 0, [{integer, -1}, {y, 2}], {x, 0}}.
    {test, is_ge, {f, 1189}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1189}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1190}}.
  {label, 1189}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1241:38">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1190}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 5}.
    return.
  {label, 1188}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 965}}.
    {call, 1, {f, 73}}.
    {test, is_tagged_tuple, {f, 1191}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 1192}}.
  {label, 1191}.
    {deallocate, 5}.
    return.
  {label, 1192}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 965}}.
    {call, 1, {f, 73}}.
    {test, is_tagged_tuple, {f, 1193}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 1194}}.
  {label, 1193}.
    {deallocate, 5}.
    return.
  {label, 1194}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 4}, {integer, 1000}], {x, 0}}.
    {test, is_ge, {f, 1195}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 1195}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 1196}}.
  {label, 1195}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i64 at src/io/fs.bp:1244:48">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1196}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq_exact, {f, 1197}, [{y, 2}, {integer, 3}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1198}}.
  {label, 1197}.
    {move, {atom, false}, {x, 0}}.
  {label, 1198}.
    {test_heap, 5, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@FileStat}, {y, 3}, {x, 1}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 5}.
    return.
% The regular files under `root` and the links whose target is missing, as paths relative to it, in
% directory order: a work list of directories, not a recursion (a recursive `try` is not lowered on wasm).

{function, walkWasm, 1, 135}.
  {label, 134}.
    {line, [{location, "std@io@fs.erl", 79}]}.
    {func_info, {atom, std@io@fs}, {atom, walkWasm}, 1}.
  {label, 135}.
    {allocate, 27, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 79}}.
    {test, is_tagged_tuple, {f, 1199}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 1200}}.
  {label, 1199}.
    {deallocate, 27}.
    return.
  {label, 1200}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 924}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_lt, {f, 1201}, [{y, 2}, {integer, 0}]}.
    {gc_bif, '-', {f, 0}, 0, [{integer, -1}, {y, 2}], {x, 0}}.
    {test, is_ge, {f, 1202}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1202}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1203}}.
  {label, 1202}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1252:38">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1203}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 27}.
    return.
  {label, 1201}.
    {test, is_ne_exact, {f, 1204}, [{y, 2}, {integer, 3}]}.
    {move, {integer, 24}, {x, 0}}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 27}.
    return.
  {label, 1204}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {line, [{location, "std@io@fs.erl", 80}]}.
  {label, 1205}.
    {move, {y, 4}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 1206}, [{y, 9}, {x, 0}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1207}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {jump, {f, 1208}}.
  {label, 1207}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1208}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1209}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {jump, {f, 1210}}.
  {label, 1209}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1210}.
    {move, {x, 0}, {y, 13}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 9}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1211}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1211}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1212}}.
  {label, 1211}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1262:21">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1212}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 11}, {x, 0}}.
    {call, 1, {f, 965}}.
    {call, 1, {f, 71}}.
    {test, is_tagged_tuple, {f, 1213}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 1214}}.
  {label, 1213}.
    {deallocate, 27}.
    return.
  {label, 1214}.
    {move, {x, 0}, {y, 14}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 15}}.
    {line, [{location, "std@io@fs.erl", 80}]}.
  {label, 1215}.
    {move, {y, 14}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 1216}, [{y, 15}, {x, 0}]}.
    {move, {y, 14}, {x, 0}}.
    {move, {y, 15}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1217}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {jump, {f, 1218}}.
  {label, 1217}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1218}.
    {move, {x, 0}, {y, 17}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 15}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1219}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1219}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1220}}.
  {label, 1219}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1267:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1220}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 11}, {x, 0}}.
    {move, {y, 17}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 18}}.
    {move, {y, 13}, {x, 0}}.
    {move, {y, 17}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 19}}.
    {move, {y, 18}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 924}}.
    {move, {x, 0}, {y, 20}}.
    {test, is_lt, {f, 1222}, [{y, 20}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1223}}.
  {label, 1222}.
    {move, {atom, false}, {x, 0}}.
  {label, 1223}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 1224}, [{x, 1}, {atom, true}]}.
    {test, is_ne_exact, {f, 1226}, [{y, 20}, {integer, -21}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1227}}.
  {label, 1226}.
    {move, {atom, false}, {x, 0}}.
  {label, 1227}.
    {jump, {f, 1225}}.
  {label, 1224}.
    {move, {atom, false}, {x, 0}}.
  {label, 1225}.
    {test, is_eq, {f, 1221}, [{x, 0}, {atom, true}]}.
    {gc_bif, '-', {f, 0}, 0, [{integer, -1}, {y, 20}], {x, 0}}.
    {test, is_ge, {f, 1228}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1228}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1229}}.
  {label, 1228}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1271:63">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1229}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 27}.
    return.
  {label, 1221}.
    {test, is_eq_exact, {f, 1230}, [{y, 20}, {integer, 3}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 21}}.
    {move, {y, 18}, {x, 0}}.
    {move, {y, 21}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 19}, {x, 0}}.
    {move, {y, 22}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 6}}.
    {jump, {f, 1231}}.
  {label, 1230}.
  {label, 1231}.
    {test, is_eq_exact, {f, 1232}, [{y, 20}, {integer, 6}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 23}}.
    {move, {y, 19}, {x, 0}}.
    {move, {y, 23}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 7}}.
    {jump, {f, 1233}}.
  {label, 1232}.
  {label, 1233}.
    {test, is_eq_exact, {f, 1234}, [{y, 20}, {integer, -21}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 24}}.
    {move, {y, 19}, {x, 0}}.
    {move, {y, 24}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 8}}.
    {jump, {f, 1235}}.
  {label, 1234}.
  {label, 1235}.
    {jump, {f, 1215}}.
  {label, 1216}.
    {jump, {f, 1205}}.
  {label, 1206}.
    {move, {y, 7}, {x, 0}}.
    {call, 1, {f, 85}}.
    {move, {x, 0}, {y, 25}}.
    {move, {y, 8}, {x, 0}}.
    {call, 1, {f, 85}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@Walked}, {y, 25}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 27}.
    return.
% Whether the segment holds a wildcard.

{function, isMagic, 1, 137}.
  {label, 136}.
    {line, [{location, "std@io@fs.erl", 80}]}.
    {func_info, {atom, std@io@fs}, {atom, isMagic}, 1}.
  {label, 137}.
    {allocate, 7, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"*">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {test, is_eq, {f, 1236}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 1237}}.
  {label, 1236}.
    {move, {atom, true}, {x, 0}}.
  {label, 1237}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 1238}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"?">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {test, is_eq, {f, 1240}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 1241}}.
  {label, 1240}.
    {move, {atom, true}, {x, 0}}.
  {label, 1241}.
    {jump, {f, 1239}}.
  {label, 1238}.
    {move, {atom, true}, {x, 0}}.
  {label, 1239}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 1242}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"[">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {test, is_eq, {f, 1244}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 1245}}.
  {label, 1244}.
    {move, {atom, true}, {x, 0}}.
  {label, 1245}.
    {jump, {f, 1243}}.
  {label, 1242}.
    {move, {atom, true}, {x, 0}}.
  {label, 1243}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 1246}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"{">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {test, is_eq, {f, 1248}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 1249}}.
  {label, 1248}.
    {move, {atom, true}, {x, 0}}.
  {label, 1249}.
    {jump, {f, 1247}}.
  {label, 1246}.
    {move, {atom, true}, {x, 0}}.
  {label, 1247}.
    {deallocate, 7}.
    return.
% A segment with its `{a,b}` alternatives written out, nested ones too; one that is never closed is a name.

{function, expandBraces, 1, 139}.
  {label, 138}.
    {line, [{location, "std@io@fs.erl", 81}]}.
    {func_info, {atom, std@io@fs}, {atom, expandBraces}, 1}.
  {label, 139}.
    {allocate, 31, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}, {y, 27}, {y, 28}, {y, 29}, {y, 30}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 1251}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, -1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {line, [{location, "std@io@fs.erl", 82}]}.
  {label, 1260}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 1261}, [{y, 3}, {x, 0}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1263}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {jump, {f, 1264}}.
  {label, 1263}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1264}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"{">>}, {x, 0}}.
    {test, is_eq_exact, {f, 1262}, [{x, 1}, {x, 0}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 1261}}.
  {label, 1262}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1265}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1265}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1266}}.
  {label, 1265}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1298:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1266}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 1260}}.
  {label, 1261}.
    {test, is_lt, {f, 1267}, [{y, 2}, {integer, 0}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 31}.
    return.
  {label, 1267}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {integer, -1}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {line, [{location, "std@io@fs.erl", 82}]}.
  {label, 1268}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 1270}, [{y, 9}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1271}}.
  {label, 1270}.
    {move, {atom, false}, {x, 0}}.
  {label, 1271}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 1272}, [{x, 1}, {atom, true}]}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq, {f, 1274}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 1275}}.
  {label, 1274}.
    {move, {atom, true}, {x, 0}}.
  {label, 1275}.
    {jump, {f, 1273}}.
  {label, 1272}.
    {move, {atom, false}, {x, 0}}.
  {label, 1273}.
    {test, is_eq_exact, {f, 1269}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1276}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {jump, {f, 1277}}.
  {label, 1276}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1277}.
    {move, {x, 0}, {y, 12}}.
    {move, {literal, <<"{">>}, {x, 0}}.
    {test, is_eq_exact, {f, 1278}, [{y, 12}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 6}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1279}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1279}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1280}}.
  {label, 1279}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1310:37">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1280}.
    {move, {x, 0}, {y, 6}}.
    {jump, {f, 1281}}.
  {label, 1278}.
  {label, 1281}.
    {move, {literal, <<"}">>}, {x, 0}}.
    {test, is_eq_exact, {f, 1282}, [{y, 12}, {x, 0}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 6}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1283}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1283}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1284}}.
  {label, 1283}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1311:37">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1284}.
    {move, {x, 0}, {y, 6}}.
    {jump, {f, 1285}}.
  {label, 1282}.
  {label, 1285}.
    {move, {literal, <<"}">>}, {x, 0}}.
    {test, is_eq_exact, {f, 1287}, [{y, 12}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1288}}.
  {label, 1287}.
    {move, {atom, false}, {x, 0}}.
  {label, 1288}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 1289}, [{x, 1}, {atom, true}]}.
    {test, is_eq_exact, {f, 1291}, [{y, 6}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1292}}.
  {label, 1291}.
    {move, {atom, false}, {x, 0}}.
  {label, 1292}.
    {jump, {f, 1290}}.
  {label, 1289}.
    {move, {atom, false}, {x, 0}}.
  {label, 1290}.
    {test, is_eq, {f, 1286}, [{x, 0}, {atom, true}]}.
    {move, {y, 9}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {atom, true}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {jump, {f, 1293}}.
  {label, 1286}.
  {label, 1293}.
    {move, {literal, <<",">>}, {x, 0}}.
    {test, is_eq_exact, {f, 1295}, [{y, 12}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1296}}.
  {label, 1295}.
    {move, {atom, false}, {x, 0}}.
  {label, 1296}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 1297}, [{x, 1}, {atom, true}]}.
    {test, is_eq_exact, {f, 1299}, [{y, 6}, {integer, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1300}}.
  {label, 1299}.
    {move, {atom, false}, {x, 0}}.
  {label, 1300}.
    {jump, {f, 1298}}.
  {label, 1297}.
    {move, {atom, false}, {x, 0}}.
  {label, 1298}.
    {test, is_eq, {f, 1294}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 9}, {x, 0}}.
    {move, {y, 13}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 8}}.
    {jump, {f, 1301}}.
  {label, 1294}.
  {label, 1301}.
    {gc_bif, '+', {f, 0}, 0, [{y, 9}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1302}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1302}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1303}}.
  {label, 1302}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1317:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1303}.
    {move, {x, 0}, {y, 9}}.
    {jump, {f, 1268}}.
  {label, 1269}.
    {test, is_lt, {f, 1304}, [{y, 7}, {integer, 0}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 14}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 31}.
    return.
  {label, 1304}.
    {test, is_ne_exact, {f, 1305}, [{y, 2}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 0, [{integer, 0}, {integer, 1}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 2}, {integer, 0}], {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 1306}}.
  {label, 1305}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 1306}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 637}}.
    {move, {x, 0}, {y, 15}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 7}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1307}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1307}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1308}}.
  {label, 1307}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1321:31">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1308}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 637}}.
    {move, {x, 0}, {y, 16}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 17}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1309}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1309}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1310}}.
  {label, 1309}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1323:22">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1310}.
    {move, {x, 0}, {y, 18}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 19}}.
    {line, [{location, "std@io@fs.erl", 82}]}.
  {label, 1311}.
    {move, {y, 8}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ge, {f, 1312}, [{x, 0}, {y, 19}]}.
    {move, {y, 7}, {x, 0}}.
    {move, {x, 0}, {y, 20}}.
    {move, {y, 8}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 1313}, [{y, 19}, {x, 0}]}.
    {move, {y, 8}, {x, 0}}.
    {move, {y, 19}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1314}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 21}}.
    {move, {y, 21}, {x, 0}}.
    {jump, {f, 1315}}.
  {label, 1314}.
    {move, {y, 7}, {x, 0}}.
  {label, 1315}.
    {move, {x, 0}, {y, 20}}.
    {jump, {f, 1316}}.
  {label, 1313}.
  {label, 1316}.
    {test, is_ne_exact, {f, 1317}, [{y, 20}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 18}, {integer, 1}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 20}, {y, 18}], {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 1318}}.
  {label, 1317}.
    {move, {y, 18}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 1318}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 637}}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 15}, {x, 0}}.
    {move, {y, 22}, {x, 1}}.
    {call, 2, {f, 1320}}.
    {move, {y, 16}, {x, 1}}.
    {call, 2, {f, 1320}}.
    {call, 1, {f, 139}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 17}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 17}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 20}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1322}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1322}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1323}}.
  {label, 1322}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1330:22">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1323}.
    {move, {x, 0}, {y, 18}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 19}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1324}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1324}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1325}}.
  {label, 1324}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1331:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1325}.
    {move, {x, 0}, {y, 19}}.
    {jump, {f, 1311}}.
  {label, 1312}.
    {move, {y, 17}, {x, 0}}.
    {deallocate, 31}.
    return.
% The `]` that closes the class opened at `at`, `-1` when there is none (the `[` is then a name).

{function, classEnd, 2, 141}.
  {label, 140}.
    {line, [{location, "std@io@fs.erl", 82}]}.
    {func_info, {atom, std@io@fs}, {atom, classEnd}, 2}.
  {label, 141}.
    {allocate, 13, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1326}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1326}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1327}}.
  {label, 1326}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1338:16">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1327}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 1329}, [{y, 2}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1330}}.
  {label, 1329}.
    {move, {atom, false}, {x, 0}}.
  {label, 1330}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 1331}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1333}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 1334}}.
  {label, 1333}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1334}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"!">>}, {x, 0}}.
    {test, is_eq_exact, {f, 1335}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1336}}.
  {label, 1335}.
    {move, {atom, false}, {x, 0}}.
  {label, 1336}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 1337}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1339}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {jump, {f, 1340}}.
  {label, 1339}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1340}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"^">>}, {x, 0}}.
    {test, is_eq_exact, {f, 1341}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1342}}.
  {label, 1341}.
    {move, {atom, false}, {x, 0}}.
  {label, 1342}.
    {jump, {f, 1338}}.
  {label, 1337}.
    {move, {atom, true}, {x, 0}}.
  {label, 1338}.
    {jump, {f, 1332}}.
  {label, 1331}.
    {move, {atom, false}, {x, 0}}.
  {label, 1332}.
    {test, is_eq, {f, 1328}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1343}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1343}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1344}}.
  {label, 1343}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1339:89">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1344}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 1345}}.
  {label, 1328}.
  {label, 1345}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 1347}, [{y, 2}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1348}}.
  {label, 1347}.
    {move, {atom, false}, {x, 0}}.
  {label, 1348}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 1349}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1351}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {jump, {f, 1352}}.
  {label, 1351}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1352}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"]">>}, {x, 0}}.
    {test, is_eq_exact, {f, 1353}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1354}}.
  {label, 1353}.
    {move, {atom, false}, {x, 0}}.
  {label, 1354}.
    {jump, {f, 1350}}.
  {label, 1349}.
    {move, {atom, false}, {x, 0}}.
  {label, 1350}.
    {test, is_eq, {f, 1346}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1355}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1355}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1356}}.
  {label, 1355}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1340:59">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1356}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 1357}}.
  {label, 1346}.
  {label, 1357}.
    {line, [{location, "std@io@fs.erl", 83}]}.
  {label, 1358}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 1359}, [{y, 2}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1361}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {jump, {f, 1362}}.
  {label, 1361}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1362}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"]">>}, {x, 0}}.
    {test, is_eq_exact, {f, 1360}, [{x, 1}, {x, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 13}.
    return.
  {label, 1360}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1363}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1363}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1364}}.
  {label, 1363}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1343:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1364}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 1358}}.
  {label, 1359}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 13}.
    return.
% Whether `ch` is in the class written between `first` and `stop` (`!` or `^` first negates it, `a-z` is a range).

{function, classHas, 4, 143}.
  {label, 142}.
    {line, [{location, "std@io@fs.erl", 83}]}.
    {func_info, {atom, std@io@fs}, {atom, classHas}, 4}.
  {label, 143}.
    {allocate, 25, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {test, is_lt, {f, 1366}, [{y, 4}, {y, 2}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1367}}.
  {label, 1366}.
    {move, {atom, false}, {x, 0}}.
  {label, 1367}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 1368}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1370}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {jump, {f, 1371}}.
  {label, 1370}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1371}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"!">>}, {x, 0}}.
    {test, is_eq_exact, {f, 1372}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1373}}.
  {label, 1372}.
    {move, {atom, false}, {x, 0}}.
  {label, 1373}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 1374}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1376}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {jump, {f, 1377}}.
  {label, 1376}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1377}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"^">>}, {x, 0}}.
    {test, is_eq_exact, {f, 1378}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1379}}.
  {label, 1378}.
    {move, {atom, false}, {x, 0}}.
  {label, 1379}.
    {jump, {f, 1375}}.
  {label, 1374}.
    {move, {atom, true}, {x, 0}}.
  {label, 1375}.
    {jump, {f, 1369}}.
  {label, 1368}.
    {move, {atom, false}, {x, 0}}.
  {label, 1369}.
    {test, is_eq, {f, 1365}, [{x, 0}, {atom, true}]}.
    {move, {atom, true}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1380}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1380}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1381}}.
  {label, 1380}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1354:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1381}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 1382}}.
  {label, 1365}.
  {label, 1382}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {line, [{location, "std@io@fs.erl", 84}]}.
  {label, 1383}.
    {test, is_lt, {f, 1384}, [{y, 4}, {y, 2}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1385}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {jump, {f, 1386}}.
  {label, 1385}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1386}.
    {move, {x, 0}, {y, 10}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 1388}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1388}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1389}}.
  {label, 1388}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1359:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1389}.
    {test, is_lt, {f, 1390}, [{x, 0}, {y, 2}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1391}}.
  {label, 1390}.
    {move, {atom, false}, {x, 0}}.
  {label, 1391}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 1392}, [{x, 1}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1395}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1395}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1396}}.
  {label, 1395}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1359:39">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1396}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1394}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {jump, {f, 1397}}.
  {label, 1394}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1397}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"-">>}, {x, 0}}.
    {test, is_eq_exact, {f, 1398}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1399}}.
  {label, 1398}.
    {move, {atom, false}, {x, 0}}.
  {label, 1399}.
    {jump, {f, 1393}}.
  {label, 1392}.
    {move, {atom, false}, {x, 0}}.
  {label, 1393}.
    {test, is_eq, {f, 1387}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 1401}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1401}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1402}}.
  {label, 1401}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1360:31">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1402}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1400}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {jump, {f, 1403}}.
  {label, 1400}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1403}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 1405}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 10}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 1405}}.
    {test, is_ge, {f, 1416}, [{y, 14}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1417}}.
  {label, 1416}.
    {move, {atom, false}, {x, 0}}.
  {label, 1417}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 1418}, [{x, 1}, {atom, true}]}.
    {move, {y, 13}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 1405}}.
    {test, is_ge, {f, 1420}, [{x, 0}, {y, 14}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1421}}.
  {label, 1420}.
    {move, {atom, false}, {x, 0}}.
  {label, 1421}.
    {jump, {f, 1419}}.
  {label, 1418}.
    {move, {atom, false}, {x, 0}}.
  {label, 1419}.
    {test, is_eq, {f, 1415}, [{x, 0}, {atom, true}]}.
    {move, {atom, true}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {jump, {f, 1422}}.
  {label, 1415}.
  {label, 1422}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 3}], {x, 0}}.
    {test, is_ge, {f, 1423}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1423}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1424}}.
  {label, 1423}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1365:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1424}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 1425}}.
  {label, 1387}.
    {test, is_eq_exact, {f, 1426}, [{y, 10}, {y, 3}]}.
    {move, {atom, true}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {jump, {f, 1427}}.
  {label, 1426}.
  {label, 1427}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1428}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1428}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1429}}.
  {label, 1428}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1368:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1429}.
    {move, {x, 0}, {y, 4}}.
  {label, 1425}.
    {jump, {f, 1383}}.
  {label, 1384}.
    {test, is_ne_exact, {f, 1430}, [{y, 8}, {y, 5}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1431}}.
  {label, 1430}.
    {move, {atom, false}, {x, 0}}.
  {label, 1431}.
    {deallocate, 25}.
    return.
% `name` against one pattern without braces: `*`, `?`, `[…]`.

{function, globMatch, 4, 145}.
  {label, 144}.
    {line, [{location, "std@io@fs.erl", 84}]}.
    {func_info, {atom, std@io@fs}, {atom, globMatch}, 4}.
  {label, 145}.
    {allocate, 15, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {line, [{location, "std@io@fs.erl", 85}]}.
  {label, 1432}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 1433}, [{y, 4}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1434}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {jump, {f, 1435}}.
  {label, 1434}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1435}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, <<"*">>}, {x, 0}}.
    {test, is_eq_exact, {f, 1436}, [{y, 7}, {x, 0}]}.
    {line, [{location, "std@io@fs.erl", 85}]}.
  {label, 1437}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 1439}, [{y, 4}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1440}}.
  {label, 1439}.
    {move, {atom, false}, {x, 0}}.
  {label, 1440}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 1441}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1443}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {jump, {f, 1444}}.
  {label, 1443}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1444}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"*">>}, {x, 0}}.
    {test, is_eq_exact, {f, 1445}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1446}}.
  {label, 1445}.
    {move, {atom, false}, {x, 0}}.
  {label, 1446}.
    {jump, {f, 1442}}.
  {label, 1441}.
    {move, {atom, false}, {x, 0}}.
  {label, 1442}.
    {test, is_eq_exact, {f, 1438}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1447}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1447}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1448}}.
  {label, 1447}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1382:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1448}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 1437}}.
  {label, 1438}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 1449}, [{y, 4}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {deallocate, 15}.
    return.
  {label, 1449}.
    {move, {y, 5}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {line, [{location, "std@io@fs.erl", 85}]}.
  {label, 1450}.
    {move, {y, 2}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ge, {f, 1451}, [{x, 0}, {y, 9}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 9}, {x, 3}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 4}, {x, 1}}.
    {call, 4, {f, 145}}.
    {test, is_eq, {f, 1452}, [{x, 0}, {atom, true}]}.
    {move, {atom, true}, {x, 0}}.
    {deallocate, 15}.
    return.
  {label, 1452}.
    {gc_bif, '+', {f, 0}, 0, [{y, 9}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1453}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1453}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1454}}.
  {label, 1453}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1388:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1454}.
    {move, {x, 0}, {y, 9}}.
    {jump, {f, 1450}}.
  {label, 1451}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 15}.
    return.
  {label, 1436}.
    {move, {y, 2}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ge, {f, 1455}, [{y, 5}, {x, 0}]}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 15}.
    return.
  {label, 1455}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1456}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {jump, {f, 1457}}.
  {label, 1456}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1457}.
    {move, {x, 0}, {y, 11}}.
    {move, {literal, <<"?">>}, {x, 0}}.
    {test, is_eq_exact, {f, 1458}, [{y, 7}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1459}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1459}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1460}}.
  {label, 1459}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1395:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1460}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 5}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1461}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1461}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1462}}.
  {label, 1461}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1396:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1462}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 1463}}.
  {label, 1458}.
    {move, {literal, <<"[">>}, {x, 0}}.
    {test, is_eq_exact, {f, 1464}, [{y, 7}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call, 2, {f, 141}}.
    {move, {x, 0}, {y, 12}}.
    {test, is_lt, {f, 1465}, [{y, 12}, {integer, 0}]}.
    {move, {literal, <<"[">>}, {x, 0}}.
    {test, is_ne_exact, {f, 1466}, [{y, 11}, {x, 0}]}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 15}.
    return.
  {label, 1466}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1467}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1467}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1468}}.
  {label, 1467}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1401:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1468}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 5}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1469}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1469}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1470}}.
  {label, 1469}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1402:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1470}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 1471}}.
  {label, 1465}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1473}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1473}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1474}}.
  {label, 1473}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1404:38">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1474}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 11}, {x, 3}}.
    {move, {y, 12}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 4, {f, 143}}.
    {test, is_eq, {f, 1475}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 1476}}.
  {label, 1475}.
    {move, {atom, true}, {x, 0}}.
  {label, 1476}.
    {test, is_eq, {f, 1472}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 15}.
    return.
  {label, 1472}.
    {gc_bif, '+', {f, 0}, 0, [{y, 12}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1477}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1477}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1478}}.
  {label, 1477}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1405:25">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1478}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 5}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1479}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1479}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1480}}.
  {label, 1479}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1406:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1480}.
    {move, {x, 0}, {y, 5}}.
  {label, 1471}.
    {jump, {f, 1481}}.
  {label, 1464}.
    {test, is_ne_exact, {f, 1482}, [{y, 7}, {y, 11}]}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 15}.
    return.
  {label, 1482}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1483}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1483}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1484}}.
  {label, 1483}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1410:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1484}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 5}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1485}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1485}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1486}}.
  {label, 1485}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1411:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1486}.
    {move, {x, 0}, {y, 5}}.
  {label, 1481}.
  {label, 1463}.
    {jump, {f, 1432}}.
  {label, 1433}.
    {move, {y, 2}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 1487}, [{y, 5}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1488}}.
  {label, 1487}.
    {move, {atom, false}, {x, 0}}.
  {label, 1488}.
    {deallocate, 15}.
    return.

{function, segmentMatches, 2, 147}.
  {label, 146}.
    {line, [{location, "std@io@fs.erl", 85}]}.
    {func_info, {atom, std@io@fs}, {atom, segmentMatches}, 2}.
  {label, 147}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 139}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 1251}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {line, [{location, "std@io@fs.erl", 86}]}.
  {label, 1489}.
    {move, {y, 2}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 1490}, [{y, 4}, {x, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1492}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {jump, {f, 1493}}.
  {label, 1492}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1493}.
    {call, 1, {f, 1251}}.
    {move, {integer, 0}, {x, 1}}.
    {move, {integer, 0}, {x, 3}}.
    {move, {y, 3}, {x, 2}}.
    {call, 4, {f, 145}}.
    {test, is_eq, {f, 1491}, [{x, 0}, {atom, true}]}.
    {move, {atom, true}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 1491}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1494}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1494}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1495}}.
  {label, 1494}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1423:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1495}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 1489}}.
  {label, 1490}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 7}.
    return.
% The names in `dir` the segment matches; a dot name only when the segment itself begins with the dot.

{function, globNames, 2, 149}.
  {label, 148}.
    {line, [{location, "std@io@fs.erl", 86}]}.
    {func_info, {atom, std@io@fs}, {atom, globNames}, 2}.
  {label, 149}.
    {allocate, 13, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 965}}.
    {test, is_tagged_tuple, {f, 1497}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 1496}}.
  {label, 1497}.
    {test, is_tagged_tuple, {f, 1498}, [{x, 0}, 2, {atom, error}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 1496}}.
  {label, 1498}.
    {case_end, {x, 0}}.
  {label, 1496}.
    {move, {x, 0}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {line, [{location, "std@io@fs.erl", 87}]}.
  {label, 1499}.
    {move, {y, 3}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 1500}, [{y, 5}, {x, 0}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1501}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {jump, {f, 1502}}.
  {label, 1501}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1502}.
    {move, {x, 0}, {y, 7}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 5}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1503}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1503}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1504}}.
  {label, 1503}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1438:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1504}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<".">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 1506}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 1507}}.
  {label, 1506}.
    {move, {atom, true}, {x, 0}}.
  {label, 1507}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 1508}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<".">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 1510}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 1511}}.
  {label, 1510}.
    {move, {atom, true}, {x, 0}}.
  {label, 1511}.
    {test, is_eq, {f, 1512}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 1513}}.
  {label, 1512}.
    {move, {atom, true}, {x, 0}}.
  {label, 1513}.
    {jump, {f, 1509}}.
  {label, 1508}.
    {move, {atom, false}, {x, 0}}.
  {label, 1509}.
    {test, is_eq, {f, 1505}, [{x, 0}, {atom, true}]}.
    {jump, {f, 1499}}.
  {label, 1505}.
    {move, {literal, <<"*">>}, {x, 0}}.
    {test, is_eq_exact, {f, 1515}, [{y, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1516}}.
  {label, 1515}.
    {move, {atom, false}, {x, 0}}.
  {label, 1516}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 1517}, [{x, 1}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call, 2, {f, 147}}.
    {jump, {f, 1518}}.
  {label, 1517}.
    {move, {atom, true}, {x, 0}}.
  {label, 1518}.
    {test, is_eq, {f, 1514}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 1519}}.
  {label, 1514}.
  {label, 1519}.
    {jump, {f, 1499}}.
  {label, 1500}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 13}.
    return.
% The entries `segs` from `i` match under `dir` (`rel` its path from the root of the glob), added to `out`. A
% wildcard continues into real directories only; a name goes through a link.

{function, globWalk, 5, 151}.
  {label, 150}.
    {line, [{location, "std@io@fs.erl", 87}]}.
    {func_info, {atom, std@io@fs}, {atom, globWalk}, 5}.
  {label, 151}.
    {allocate, 27, 5}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {x, 4}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 1520}, [{y, 1}, {x, 0}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 1521}, [{y, 3}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 1522}}.
  {label, 1521}.
  {label, 1522}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 27}.
    return.
  {label, 1520}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1523}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {jump, {f, 1524}}.
  {label, 1523}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1524}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1525}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1525}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1526}}.
  {label, 1525}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1454:33">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1526}.
    {test, is_eq_exact, {f, 1527}, [{y, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1528}}.
  {label, 1527}.
    {move, {atom, false}, {x, 0}}.
  {label, 1528}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, <<"**">>}, {x, 0}}.
    {test, is_eq_exact, {f, 1529}, [{y, 8}, {x, 0}]}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq, {f, 1531}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 1532}}.
  {label, 1531}.
    {move, {atom, true}, {x, 0}}.
  {label, 1532}.
    {test, is_eq, {f, 1530}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1533}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1533}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1534}}.
  {label, 1533}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1456:43">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1534}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 4}}.
    {move, {y, 3}, {x, 3}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 5, {f, 151}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 1535}}.
  {label, 1530}.
  {label, 1535}.
    {move, {literal, <<"*">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call, 2, {f, 149}}.
    {move, {x, 0}, {y, 10}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {line, [{location, "std@io@fs.erl", 88}]}.
  {label, 1536}.
    {move, {y, 10}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 1537}, [{y, 11}, {x, 0}]}.
    {move, {y, 10}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1538}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {jump, {f, 1539}}.
  {label, 1538}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1539}.
    {move, {x, 0}, {y, 13}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 11}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1540}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1540}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1541}}.
  {label, 1540}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1461:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1541}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 13}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 13}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq, {f, 1542}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 15}, {x, 0}}.
    {move, {y, 16}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 1543}}.
  {label, 1542}.
  {label, 1543}.
    {move, {y, 14}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 924}}.
    {test, is_eq_exact, {f, 1544}, [{x, 0}, {integer, 3}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 5}, {x, 4}}.
    {move, {y, 15}, {x, 3}}.
    {move, {y, 14}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call, 5, {f, 151}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 1545}}.
  {label, 1544}.
  {label, 1545}.
    {jump, {f, 1536}}.
  {label, 1537}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 27}.
    return.
  {label, 1529}.
    {move, {y, 8}, {x, 0}}.
    {call, 1, {f, 137}}.
    {test, is_eq, {f, 1547}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 1548}}.
  {label, 1547}.
    {move, {atom, true}, {x, 0}}.
  {label, 1548}.
    {test, is_eq, {f, 1546}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 17}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 18}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq, {f, 1549}, [{x, 0}, {atom, true}]}.
    {move, {y, 17}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 924}}.
    {test, is_ge, {f, 1550}, [{x, 0}, {integer, 0}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 19}}.
    {move, {y, 18}, {x, 0}}.
    {move, {y, 19}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 1551}}.
  {label, 1550}.
  {label, 1551}.
    {jump, {f, 1552}}.
  {label, 1549}.
    {move, {y, 17}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 924}}.
    {test, is_eq_exact, {f, 1553}, [{x, 0}, {integer, 3}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1554}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1554}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1555}}.
  {label, 1554}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1475:36">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1555}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 4}}.
    {move, {y, 18}, {x, 3}}.
    {move, {y, 17}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 5, {f, 151}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 1556}}.
  {label, 1553}.
  {label, 1556}.
  {label, 1552}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 27}.
    return.
  {label, 1546}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call, 2, {f, 149}}.
    {move, {x, 0}, {y, 20}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 21}}.
    {line, [{location, "std@io@fs.erl", 88}]}.
  {label, 1557}.
    {move, {y, 20}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 1558}, [{y, 21}, {x, 0}]}.
    {move, {y, 20}, {x, 0}}.
    {move, {y, 21}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1559}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 22}, {x, 0}}.
    {jump, {f, 1560}}.
  {label, 1559}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1560}.
    {move, {x, 0}, {y, 23}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 21}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1561}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1561}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1562}}.
  {label, 1561}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1483:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1562}.
    {move, {x, 0}, {y, 21}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 23}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 24}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 23}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 25}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq, {f, 1563}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 26}}.
    {move, {y, 25}, {x, 0}}.
    {move, {y, 26}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 1564}}.
  {label, 1563}.
    {move, {y, 24}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 924}}.
    {test, is_eq_exact, {f, 1565}, [{x, 0}, {integer, 3}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1566}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1566}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1567}}.
  {label, 1566}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1489:36">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1567}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 4}}.
    {move, {y, 25}, {x, 3}}.
    {move, {y, 24}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 5, {f, 151}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 1568}}.
  {label, 1565}.
  {label, 1568}.
  {label, 1564}.
    {jump, {f, 1557}}.
  {label, 1558}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 27}.
    return.

{function, globWasm, 2, 153}.
  {label, 152}.
    {line, [{location, "std@io@fs.erl", 88}]}.
    {func_info, {atom, std@io@fs}, {atom, globWasm}, 2}.
  {label, 153}.
    {allocate, 18, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 79}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1570}, [{x, 0}, 2, {atom, error}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1571}}.
  {label, 1570}.
    {move, {atom, false}, {x, 0}}.
  {label, 1571}.
    {test, is_eq, {f, 1569}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {deallocate, 18}.
    return.
  {label, 1569}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1572}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 1573}}.
  {label, 1572}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1573}.
    {move, {x, 0}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"/">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 1131}}.
    {move, {x, 0}, {y, 5}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {line, [{location, "std@io@fs.erl", 89}]}.
  {label, 1574}.
    {move, {y, 5}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 1575}, [{y, 6}, {x, 0}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1576}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {jump, {f, 1577}}.
  {label, 1576}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1577}.
    {move, {x, 0}, {y, 8}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 6}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1578}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1578}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1579}}.
  {label, 1578}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1504:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1579}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 1581}, [{y, 8}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1582}}.
  {label, 1581}.
    {move, {atom, false}, {x, 0}}.
  {label, 1582}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 1583}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<".">>}, {x, 0}}.
    {test, is_ne_exact, {f, 1585}, [{y, 8}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1586}}.
  {label, 1585}.
    {move, {atom, false}, {x, 0}}.
  {label, 1586}.
    {jump, {f, 1584}}.
  {label, 1583}.
    {move, {atom, false}, {x, 0}}.
  {label, 1584}.
    {test, is_eq, {f, 1580}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 1587}}.
  {label, 1580}.
  {label, 1587}.
    {jump, {f, 1574}}.
  {label, 1575}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {move, {x, 0}, {x, 4}}.
    {move, {x, 1}, {x, 3}}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 5, {f, 151}}.
    {move, {x, 0}, {y, 10}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {line, [{location, "std@io@fs.erl", 89}]}.
  {label, 1588}.
    {move, {y, 10}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 1589}, [{y, 12}, {x, 0}]}.
    {move, {y, 10}, {x, 0}}.
    {move, {y, 12}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1590}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {jump, {f, 1591}}.
  {label, 1590}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1591}.
    {move, {x, 0}, {y, 14}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 12}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1592}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1592}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1593}}.
  {label, 1592}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1512:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1593}.
    {move, {x, 0}, {y, 12}}.
    {move, {literal, <<"/">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 1596}}.
    {test, is_eq, {f, 1610}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 1611}}.
  {label, 1610}.
    {move, {atom, true}, {x, 0}}.
  {label, 1611}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 1612}, [{x, 1}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 14}, {x, 1}}.
    {call, 2, {f, 77}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 924}}.
    {test, is_eq_exact, {f, 1614}, [{x, 0}, {integer, 3}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1615}}.
  {label, 1614}.
    {move, {atom, false}, {x, 0}}.
  {label, 1615}.
    {jump, {f, 1613}}.
  {label, 1612}.
    {move, {atom, true}, {x, 0}}.
  {label, 1613}.
    {test, is_eq, {f, 1594}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 14}, {x, 0}}.
    {move, {y, 15}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 11}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 11}}.
    {jump, {f, 1616}}.
  {label, 1594}.
  {label, 1616}.
    {jump, {f, 1588}}.
  {label, 1589}.
    {move, {y, 11}, {x, 0}}.
    {call_last, 1, {f, 85}, 18}.
% A path that is not there is `Ok`: the caller wanted it gone. A link is removed, never followed. The
% directories are found first, then the files removed, then the directories from the deepest.

{function, removeTreeWasm, 1, 155}.
  {label, 154}.
    {line, [{location, "std@io@fs.erl", 89}]}.
    {func_info, {atom, std@io@fs}, {atom, removeTreeWasm}, 1}.
  {label, 155}.
    {allocate, 21, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 79}}.
    {test, is_tagged_tuple, {f, 1617}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 1618}}.
  {label, 1617}.
    {deallocate, 21}.
    return.
  {label, 1618}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 924}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_eq_exact, {f, 1619}, [{y, 2}, {integer, -21}]}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 21}.
    return.
  {label, 1619}.
    {test, is_lt, {f, 1620}, [{y, 2}, {integer, 0}]}.
    {gc_bif, '-', {f, 0}, 0, [{integer, -1}, {y, 2}], {x, 0}}.
    {test, is_ge, {f, 1621}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1621}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1622}}.
  {label, 1621}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1524:37">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1622}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 21}.
    return.
  {label, 1620}.
    {test, is_ne_exact, {f, 1623}, [{y, 2}, {integer, 3}]}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 965}}.
    {move, {x, 0}, {y, 3}}.
    {test, is_lt, {f, 1624}, [{y, 3}, {integer, 0}]}.
    {gc_bif, '-', {f, 0}, 0, [{integer, -1}, {y, 3}], {x, 0}}.
    {test, is_ge, {f, 1625}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1625}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1626}}.
  {label, 1625}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1527:39">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1626}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 21}.
    return.
  {label, 1624}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 21}.
    return.
  {label, 1623}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {line, [{location, "std@io@fs.erl", 90}]}.
  {label, 1627}.
    {move, {y, 5}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 1628}, [{y, 6}, {x, 0}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1629}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {jump, {f, 1630}}.
  {label, 1629}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1630}.
    {move, {x, 0}, {y, 8}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 6}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1631}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1631}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1632}}.
  {label, 1631}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1534:21">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1632}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 8}, {x, 0}}.
    {call, 1, {f, 965}}.
    {call, 1, {f, 71}}.
    {test, is_tagged_tuple, {f, 1633}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 1634}}.
  {label, 1633}.
    {deallocate, 21}.
    return.
  {label, 1634}.
    {move, {x, 0}, {y, 9}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {line, [{location, "std@io@fs.erl", 90}]}.
  {label, 1635}.
    {move, {y, 9}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 1636}, [{y, 10}, {x, 0}]}.
    {move, {y, 9}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1637}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {jump, {f, 1638}}.
  {label, 1637}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1638}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 8}, {x, 0}}.
    {call, 2, {f, 77}}.
    {move, {x, 0}, {y, 12}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 10}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1639}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1639}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1640}}.
  {label, 1639}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1539:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1640}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 12}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 924}}.
    {move, {x, 0}, {y, 13}}.
    {test, is_lt, {f, 1642}, [{y, 13}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1643}}.
  {label, 1642}.
    {move, {atom, false}, {x, 0}}.
  {label, 1643}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 1644}, [{x, 1}, {atom, true}]}.
    {test, is_ne_exact, {f, 1646}, [{y, 13}, {integer, -21}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1647}}.
  {label, 1646}.
    {move, {atom, false}, {x, 0}}.
  {label, 1647}.
    {jump, {f, 1645}}.
  {label, 1644}.
    {move, {atom, false}, {x, 0}}.
  {label, 1645}.
    {test, is_eq, {f, 1641}, [{x, 0}, {atom, true}]}.
    {gc_bif, '-', {f, 0}, 0, [{integer, -1}, {y, 13}], {x, 0}}.
    {test, is_ge, {f, 1648}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1648}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1649}}.
  {label, 1648}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1541:61">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1649}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 21}.
    return.
  {label, 1641}.
    {test, is_eq_exact, {f, 1650}, [{y, 13}, {integer, 3}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 12}, {x, 0}}.
    {move, {y, 14}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 1651}}.
  {label, 1650}.
  {label, 1651}.
    {test, is_ge, {f, 1653}, [{y, 13}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1654}}.
  {label, 1653}.
    {move, {atom, false}, {x, 0}}.
  {label, 1654}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 1655}, [{x, 1}, {atom, true}]}.
    {test, is_ne_exact, {f, 1657}, [{y, 13}, {integer, 3}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1658}}.
  {label, 1657}.
    {move, {atom, false}, {x, 0}}.
  {label, 1658}.
    {jump, {f, 1656}}.
  {label, 1655}.
    {move, {atom, false}, {x, 0}}.
  {label, 1656}.
    {test, is_eq, {f, 1652}, [{x, 0}, {atom, true}]}.
    {move, {y, 12}, {x, 0}}.
    {call, 1, {f, 965}}.
    {move, {x, 0}, {y, 15}}.
    {test, is_lt, {f, 1659}, [{y, 15}, {integer, 0}]}.
    {gc_bif, '-', {f, 0}, 0, [{integer, -1}, {y, 15}], {x, 0}}.
    {test, is_ge, {f, 1660}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1660}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1661}}.
  {label, 1660}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1545:47">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1661}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 21}.
    return.
  {label, 1659}.
    {jump, {f, 1662}}.
  {label, 1652}.
  {label, 1662}.
    {jump, {f, 1635}}.
  {label, 1636}.
    {jump, {f, 1627}}.
  {label, 1628}.
    {move, {y, 5}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 16}}.
    {line, [{location, "std@io@fs.erl", 90}]}.
  {label, 1663}.
    {test, is_lt, {f, 1664}, [{integer, 0}, {y, 16}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 16}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1665}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1665}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1666}}.
  {label, 1665}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1551:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1666}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 16}, {x, 1}}.
    {call, 2, {f, 632}}.
    {test, is_ne_exact, {f, 1667}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 17}}.
    {move, {y, 17}, {x, 0}}.
    {jump, {f, 1668}}.
  {label, 1667}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1668}.
    {call, 1, {f, 965}}.
    {move, {x, 0}, {y, 18}}.
    {test, is_lt, {f, 1669}, [{y, 18}, {integer, 0}]}.
    {gc_bif, '-', {f, 0}, 0, [{integer, -1}, {y, 18}], {x, 0}}.
    {test, is_ge, {f, 1670}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1670}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1671}}.
  {label, 1670}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1553:39">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1671}.
    {call, 1, {f, 67}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 21}.
    return.
  {label, 1669}.
    {jump, {f, 1663}}.
  {label, 1664}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 21}.
    return.
% A fresh, unique, empty directory under the host's temporary directory.

{function, scratchDirWasm, 0, 157}.
  {label, 156}.
    {line, [{location, "std@io@fs.erl", 90}]}.
    {func_info, {atom, std@io@fs}, {atom, scratchDirWasm}, 0}.
  {label, 157}.
    {allocate, 4, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {literal, <<"TMPDIR">>}, {x, 0}}.
    {call, 1, {f, 965}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 1672}, [{y, 0}, {x, 0}]}.
    {move, {literal, <<"/tmp">>}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {jump, {f, 1673}}.
  {label, 1672}.
  {label, 1673}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {line, [{location, "std@io@fs.erl", 91}]}.
  {label, 1674}.
    {test, is_lt, {f, 1675}, [{y, 1}, {integer, 100}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 6}, {x, 0}}.
    {call_ext, 1, {extfunc, std@io@random, randomBytes, 1}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"/bp-std-fs-">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 667}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 75}}.
    {call, 1, {f, 965}}.
    {test, is_eq_exact, {f, 1676}, [{x, 0}, {integer, 0}]}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 1676}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1677}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1677}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1678}}.
  {label, 1677}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:1566:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1678}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 1674}}.
  {label, 1675}.
    {move, {literal, <<"io.fs: no scratch directory could be made">>}, {x, 0}}.
    {call, 1, {f, 1680}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, workingDirWasm, 0, 159}.
  {label, 158}.
    {line, [{location, "std@io@fs.erl", 91}]}.
    {func_info, {atom, std@io@fs}, {atom, workingDirWasm}, 0}.
  {label, 159}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {call, 0, {f, 897}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 1681}, [{y, 0}, {x, 0}]}.
    {move, {literal, <<"/">>}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 1681}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, linkToWasm, 2, 161}.
  {label, 160}.
    {line, [{location, "std@io@fs.erl", 92}]}.
    {func_info, {atom, std@io@fs}, {atom, linkToWasm}, 2}.
  {label, 161}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 79}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1683}, [{x, 0}, 2, {atom, error}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1684}}.
  {label, 1683}.
    {move, {atom, false}, {x, 0}}.
  {label, 1684}.
    {test, is_eq, {f, 1682}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"io.fs: no link path">>}, {x, 0}}.
    {call, 1, {f, 1680}}.
    {jump, {f, 1685}}.
  {label, 1682}.
  {label, 1685}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1686}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 1687}}.
  {label, 1686}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 1687}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 924}}.
    {move, {x, 0}, {y, 3}}.
    {test, is_lt, {f, 1688}, [{y, 3}, {integer, 0}]}.
    {gc_bif, '-', {f, 0}, 0, [{integer, -1}, {y, 3}], {x, 0}}.
    {test, is_ge, {f, 1689}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1689}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1690}}.
  {label, 1689}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/io/fs.bp:1582:43">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1690}.
    {call, 1, {f, 67}}.
    {test, is_tagged_tuple, {f, 1691}, [{x, 0}, 5, {atom, std@failure@@HostError}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 1691}.
    {call, 1, {f, 1680}}.
    {jump, {f, 1692}}.
  {label, 1688}.
  {label, 1692}.
    {deallocate, 6}.
    return.
% A host without `chmod` denies this user nothing: the permission tests have nothing to check there.

{function, denyAllWasm, 1, 163}.
  {label, 162}.
    {line, [{location, "std@io@fs.erl", 93}]}.
    {func_info, {atom, std@io@fs}, {atom, denyAllWasm}, 1}.
  {label, 163}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, allowAllWasm, 1, 165}.
  {label, 164}.
    {line, [{location, "std@io@fs.erl", 94}]}.
    {func_info, {atom, std@io@fs}, {atom, allowAllWasm}, 1}.
  {label, 165}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {deallocate, 1}.
    return.
% ── tests ────────────────────────────────────────────────────────────────────
% (Inline tests are smoke-grade — they require the host filesystem to be
% writable at the host's `tmpdir()`. The lib-test harness runs each
% inline test as a separate process; the temp filenames are seeded with
% `time.nowMillis()` for cross-run uniqueness.)
% Internal, test scaffolding: `stat(p)`, or a stat no file has.

{function, statOr, 1, 167}.
  {label, 166}.
    {line, [{location, "std@io@fs.erl", 95}]}.
    {func_info, {atom, std@io@fs}, {atom, statOr}, 1}.
  {label, 167}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 39}}.
    {test, is_tagged_tuple, {f, 1694}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 1693}}.
  {label, 1694}.
    {test, is_tagged_tuple, {f, 1695}, [{x, 0}, 2, {atom, error}]}.
    {move, {atom, false}, {x, 0}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@FileStat}, {integer, -1}, {integer, -1}, {x, 0}]}}.
    {jump, {f, 1693}}.
  {label, 1695}.
    {case_end, {x, 0}}.
  {label, 1693}.
    {deallocate, 2}.
    return.
% Internal, test scaffolding: `<dir>/app/page.bp`, `<dir>/app/blog/page.bp`,
% `<dir>/app/blog/notes.md` — the fixture tree every walk/glob test reads.

{function, makeFixtureTree, 1, 169}.
  {label, 168}.
    {line, [{location, "std@io@fs.erl", 96}]}.
    {func_info, {atom, std@io@fs}, {atom, makeFixtureTree}, 1}.
  {label, 169}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"/app">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 637}}.
    {call, 1, {f, 43}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"/app/blog">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 637}}.
    {call, 1, {f, 43}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"/app/page.bp">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 637}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"root page">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 35}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"/app/blog/page.bp">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 637}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"blog page">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 35}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"/app/blog/notes.md">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 637}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"notes">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 35}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 6}.
    return.
% Internal, test scaffolding: what `walk` answers for the fixture tree when
% its root is spelled `<scratch dir><suffix>` — every spelling of one root has
% to answer the same three relative paths.

{function, walkFixture, 1, 171}.
  {label, 170}.
    {line, [{location, "std@io@fs.erl", 97}]}.
    {func_info, {atom, std@io@fs}, {atom, walkFixture}, 1}.
  {label, 171}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 1697}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 169}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 637}}.
    {call, 1, {f, 53}}.
    {test, is_tagged_tuple, {f, 1713}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 1714}}.
  {label, 1713}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"<error>">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
  {label, 1714}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 49}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call_last, 2, {f, 637}, 5}.
% Internal, test scaffolding: the same, with the root spelled relative to the
% working directory — `<prefix><path from the cwd to the fixture>`.

{function, walkFixtureFromCwd, 1, 173}.
  {label, 172}.
    {line, [{location, "std@io@fs.erl", 98}]}.
    {func_info, {atom, std@io@fs}, {atom, walkFixtureFromCwd}, 1}.
  {label, 173}.
    {allocate, 8, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 1697}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 169}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"/app">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {call, 0, {f, 1716}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, std@path, relative, 2}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 637}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 53}}.
    {test, is_tagged_tuple, {f, 1725}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 1726}}.
  {label, 1725}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"<error>">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
  {label, 1726}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 49}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_last, 2, {f, 637}, 8}.
% Internal, test scaffolding: the `Error` of `walk(root)`, `""` when it walked.

{function, walkRefusal, 1, 175}.
  {label, 174}.
    {line, [{location, "std@io@fs.erl", 99}]}.
    {func_info, {atom, std@io@fs}, {atom, walkRefusal}, 1}.
  {label, 175}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 53}}.
    {test, is_tagged_tuple, {f, 1728}, [{x, 0}, 2, {atom, ok}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {jump, {f, 1727}}.
  {label, 1728}.
    {test, is_tagged_tuple, {f, 1729}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 177}}.
    {jump, {f, 1727}}.
  {label, 1729}.
    {case_end, {x, 0}}.
  {label, 1727}.
    {deallocate, 2}.
    return.
% Internal, test scaffolding: an `FsError` as one line — the variant, the path
% and the message where it holds one (a dangling link is `Other`, decision 178).

{function, describe, 1, 177}.
  {label, 176}.
    {line, [{location, "std@io@fs.erl", 100}]}.
    {func_info, {atom, std@io@fs}, {atom, describe}, 1}.
  {label, 177}.
    {allocate, 16, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1731}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__notfound}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"NotFound ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 667}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 1730}}.
  {label, 1731}.
    {test, is_tagged_tuple, {f, 1732}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__permissiondenied}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"PermissionDenied ">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 667}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 1730}}.
  {label, 1732}.
    {test, is_tagged_tuple, {f, 1733}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__isdirectory}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 5}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"IsDirectory ">>}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 667}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 1730}}.
  {label, 1733}.
    {test, is_tagged_tuple, {f, 1734}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__notdirectory}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 7}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, <<"NotDirectory ">>}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 667}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 1730}}.
  {label, 1734}.
    {test, is_tagged_tuple, {f, 1735}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__alreadyexists}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 9}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 9}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, <<"AlreadyExists ">>}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 667}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 1730}}.
  {label, 1735}.
    {test, is_tagged_tuple, {f, 1736}, [{x, 0}, 3, {atom, std@io@fs@@FsError__v__invalidutf8}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 11}}.
    {get_tuple_element, {x, 0}, 2, {x, 1}}.
    {move, {x, 1}, {y, 12}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 12}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 13}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 13}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 11}, {x, 0}}.
    {move, {y, 13}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {literal, <<"InvalidUtf8 ">>}, {x, 0}}.
    {move, {y, 13}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 667}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 1730}}.
  {label, 1736}.
    {test, is_tagged_tuple, {f, 1737}, [{x, 0}, 3, {atom, std@io@fs@@FsError__v__other}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 14}}.
    {get_tuple_element, {x, 0}, 2, {x, 1}}.
    {move, {x, 1}, {y, 15}}.
    {move, {y, 15}, {x, 0}}.
    {jump, {f, 1730}}.
  {label, 1737}.
    {case_end, {x, 0}}.
  {label, 1730}.
    {deallocate, 16}.
    return.
% Internal, test scaffolding: the fixture tree plus the names decision 177 is
% about — a dot file and a dot directory, a link to a directory, a link to a
% file and a dangling link, all under `<dir>/app`.

{function, makeGlobTree, 1, 179}.
  {label, 178}.
    {line, [{location, "std@io@fs.erl", 101}]}.
    {func_info, {atom, std@io@fs}, {atom, makeGlobTree}, 1}.
  {label, 179}.
    {allocate, 14, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 169}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"/app/.cache">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 637}}.
    {call, 1, {f, 43}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"/app/.cache/page.bp">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 637}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cached">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 35}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"/app/.hidden.bp">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 637}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"hidden">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 35}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"/app/blog/.draft.md">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 637}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"draft">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 35}}.
    {move, {literal, <<"blog">>}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"/app/linked">>}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 637}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call, 2, {f, 1739}}.
    {move, {literal, <<"page.bp">>}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, <<"/app/alias.bp">>}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 637}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 7}, {x, 0}}.
    {call, 2, {f, 1739}}.
    {move, {literal, <<"missing.bp">>}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, <<"/app/gone.bp">>}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 637}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {call, 2, {f, 1739}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 14}.
    return.
% Internal, test scaffolding: what `glob(pattern, <dir>/app)` answers over
% `makeGlobTree`, joined by `,`.

{function, globbed, 1, 181}.
  {label, 180}.
    {line, [{location, "std@io@fs.erl", 102}]}.
    {func_info, {atom, std@io@fs}, {atom, globbed}, 1}.
  {label, 181}.
    {allocate, 7, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 1697}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 179}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"/app">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 637}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 55}}.
    {test, is_tagged_tuple, {f, 1748}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 1749}}.
  {label, 1748}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"<error>">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
  {label, 1749}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 49}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call_last, 2, {f, 637}, 7}.
% ── FsError, readText and the handle ─────────────────────────────────────────
% Internal, test scaffolding: the variant of an `Error`, `"ok"` for an `Ok`.

{function, variantOf, 1, 183}.
  {label, 182}.
    {line, [{location, "std@io@fs.erl", 103}]}.
    {func_info, {atom, std@io@fs}, {atom, variantOf}, 1}.
  {label, 183}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1751}, [{x, 0}, 2, {atom, ok}]}.
    {move, {literal, <<"ok">>}, {x, 0}}.
    {jump, {f, 1750}}.
  {label, 1751}.
    {test, is_tagged_tuple, {f, 1752}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 177}}.
    {jump, {f, 1750}}.
  {label, 1752}.
    {case_end, {x, 0}}.
  {label, 1750}.
    {deallocate, 2}.
    return.
% Internal, test scaffolding: the file a failed `open` falls back to.

{function, noFile, 0, 185}.
  {label, 184}.
    {line, [{location, "std@io@fs.erl", 104}]}.
    {func_info, {atom, std@io@fs}, {atom, noFile}, 0}.
  {label, 185}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {call, 1, {f, 912}}.
    {call, 1, {f, 871}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@File}, {y, 0}, {x, 0}]}}.
    {deallocate, 2}.
    return.
% Internal, test scaffolding: take every permission from `path`; whether that
% denies this user anything (root is denied nothing), and give them back.

{function, 'string_slice', 3, 890}.
  {label, 889}.
    {line, [{location, "std@io@fs.erl", 105}]}.
    {func_info, {atom, std@io@fs}, {atom, 'string_slice'}, 3}.
  {label, 890}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_ne_exact, {f, 1753}, [{y, 2}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 1755}, 3}.
  {label, 1753}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 1777}, 3}.

{function, 'bytes_slice', 3, 1090}.
  {label, 1089}.
    {line, [{location, "std@io@fs.erl", 106}]}.
    {func_info, {atom, std@io@fs}, {atom, 'bytes_slice'}, 3}.
  {label, 1090}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_ne_exact, {f, 1793}, [{y, 2}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 1795}, 3}.
  {label, 1793}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 1815}, 3}.

{function, '__bp_priv__array_range', 2, 1831}.
  {label, 1830}.
    {line, [{location, "std@io@fs.erl", 108}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__array_range'}, 2}.
  {label, 1831}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__array_repeat', 2, 1833}.
  {label, 1832}.
    {line, [{location, "std@io@fs.erl", 109}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__array_repeat'}, 2}.
  {label, 1833}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__bytes_slice', 3, 1835}.
  {label, 1834}.
    {line, [{location, "std@io@fs.erl", 110}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__bytes_slice'}, 3}.
  {label, 1835}.
    {call_only, 3, {f, 1090}}.

{function, '__bp_priv__string_slice', 3, 1837}.
  {label, 1836}.
    {line, [{location, "std@io@fs.erl", 111}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__string_slice'}, 3}.
  {label, 1837}.
    {call_only, 3, {f, 890}}.

{function, '__bp_priv__allowAllWasm', 1, 1839}.
  {label, 1838}.
    {line, [{location, "std@io@fs.erl", 112}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__allowAllWasm'}, 1}.
  {label, 1839}.
    {call_only, 1, {f, 165}}.

{function, '__bp_priv__appendTextWasm', 2, 1841}.
  {label, 1840}.
    {line, [{location, "std@io@fs.erl", 113}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__appendTextWasm'}, 2}.
  {label, 1841}.
    {call_only, 2, {f, 93}}.

{function, '__bp_priv__blockOf', 1, 1843}.
  {label, 1842}.
    {line, [{location, "std@io@fs.erl", 114}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__blockOf'}, 1}.
  {label, 1843}.
    {call_only, 1, {f, 81}}.

{function, '__bp_priv__bytesBefore', 2, 1845}.
  {label, 1844}.
    {line, [{location, "std@io@fs.erl", 115}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__bytesBefore'}, 2}.
  {label, 1845}.
    {call_only, 2, {f, 83}}.

{function, '__bp_priv__classEnd', 2, 1847}.
  {label, 1846}.
    {line, [{location, "std@io@fs.erl", 116}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__classEnd'}, 2}.
  {label, 1847}.
    {call_only, 2, {f, 141}}.

{function, '__bp_priv__classHas', 4, 1849}.
  {label, 1848}.
    {line, [{location, "std@io@fs.erl", 117}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__classHas'}, 4}.
  {label, 1849}.
    {call_only, 4, {f, 143}}.

{function, '__bp_priv__closeWasm', 1, 1851}.
  {label, 1850}.
    {line, [{location, "std@io@fs.erl", 118}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__closeWasm'}, 1}.
  {label, 1851}.
    {call_only, 1, {f, 117}}.

{function, '__bp_priv__copyWasm', 2, 1853}.
  {label, 1852}.
    {line, [{location, "std@io@fs.erl", 119}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__copyWasm'}, 2}.
  {label, 1853}.
    {call_only, 2, {f, 131}}.

{function, '__bp_priv__createWasm', 1, 1855}.
  {label, 1854}.
    {line, [{location, "std@io@fs.erl", 120}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__createWasm'}, 1}.
  {label, 1855}.
    {call_only, 1, {f, 101}}.

{function, '__bp_priv__denyAllWasm', 1, 1857}.
  {label, 1856}.
    {line, [{location, "std@io@fs.erl", 121}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__denyAllWasm'}, 1}.
  {label, 1857}.
    {call_only, 1, {f, 163}}.

{function, '__bp_priv__describe', 1, 1859}.
  {label, 1858}.
    {line, [{location, "std@io@fs.erl", 122}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__describe'}, 1}.
  {label, 1859}.
    {call_only, 1, {f, 177}}.

{function, '__bp_priv__existsWasm', 1, 1861}.
  {label, 1860}.
    {line, [{location, "std@io@fs.erl", 123}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__existsWasm'}, 1}.
  {label, 1861}.
    {call_only, 1, {f, 121}}.

{function, '__bp_priv__expandBraces', 1, 1863}.
  {label, 1862}.
    {line, [{location, "std@io@fs.erl", 124}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__expandBraces'}, 1}.
  {label, 1863}.
    {call_only, 1, {f, 139}}.

{function, '__bp_priv__fsError', 2, 1865}.
  {label, 1864}.
    {line, [{location, "std@io@fs.erl", 125}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__fsError'}, 2}.
  {label, 1865}.
    {call_only, 2, {f, 7}}.

{function, '__bp_priv__globMatch', 4, 1867}.
  {label, 1866}.
    {line, [{location, "std@io@fs.erl", 126}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__globMatch'}, 4}.
  {label, 1867}.
    {call_only, 4, {f, 145}}.

{function, '__bp_priv__globNames', 2, 1869}.
  {label, 1868}.
    {line, [{location, "std@io@fs.erl", 127}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__globNames'}, 2}.
  {label, 1869}.
    {call_only, 2, {f, 149}}.

{function, '__bp_priv__globWalk', 5, 1871}.
  {label, 1870}.
    {line, [{location, "std@io@fs.erl", 128}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__globWalk'}, 5}.
  {label, 1871}.
    {call_only, 5, {f, 151}}.

{function, '__bp_priv__globWasm', 2, 1873}.
  {label, 1872}.
    {line, [{location, "std@io@fs.erl", 129}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__globWasm'}, 2}.
  {label, 1873}.
    {call_only, 2, {f, 153}}.

{function, '__bp_priv__globbed', 1, 1875}.
  {label, 1874}.
    {line, [{location, "std@io@fs.erl", 130}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__globbed'}, 1}.
  {label, 1875}.
    {call_only, 1, {f, 181}}.

{function, '__bp_priv__hashWasm', 1, 1877}.
  {label, 1876}.
    {line, [{location, "std@io@fs.erl", 131}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__hashWasm'}, 1}.
  {label, 1877}.
    {call_only, 1, {f, 113}}.

{function, '__bp_priv__isMagic', 1, 1879}.
  {label, 1878}.
    {line, [{location, "std@io@fs.erl", 132}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__isMagic'}, 1}.
  {label, 1879}.
    {call_only, 1, {f, 137}}.

{function, '__bp_priv__joinPath', 2, 1881}.
  {label, 1880}.
    {line, [{location, "std@io@fs.erl", 133}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__joinPath'}, 2}.
  {label, 1881}.
    {call_only, 2, {f, 77}}.

{function, '__bp_priv__lift', 2, 1883}.
  {label, 1882}.
    {line, [{location, "std@io@fs.erl", 134}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__lift'}, 2}.
  {label, 1883}.
    {call_only, 2, {f, 9}}.

{function, '__bp_priv__liftHandle', 2, 1885}.
  {label, 1884}.
    {line, [{location, "std@io@fs.erl", 135}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__liftHandle'}, 2}.
  {label, 1885}.
    {call_only, 2, {f, 25}}.

{function, '__bp_priv__liftStat', 2, 1887}.
  {label, 1886}.
    {line, [{location, "std@io@fs.erl", 136}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__liftStat'}, 2}.
  {label, 1887}.
    {call_only, 2, {f, 21}}.

{function, '__bp_priv__liftStrings', 2, 1889}.
  {label, 1888}.
    {line, [{location, "std@io@fs.erl", 137}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__liftStrings'}, 2}.
  {label, 1889}.
    {call_only, 2, {f, 19}}.

{function, '__bp_priv__liftWalked', 2, 1891}.
  {label, 1890}.
    {line, [{location, "std@io@fs.erl", 138}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__liftWalked'}, 2}.
  {label, 1891}.
    {call_only, 2, {f, 23}}.

{function, '__bp_priv__linkToWasm', 2, 1893}.
  {label, 1892}.
    {line, [{location, "std@io@fs.erl", 139}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__linkToWasm'}, 2}.
  {label, 1893}.
    {call_only, 2, {f, 161}}.

{function, '__bp_priv__listWasm', 1, 1895}.
  {label, 1894}.
    {line, [{location, "std@io@fs.erl", 140}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__listWasm'}, 1}.
  {label, 1895}.
    {call_only, 1, {f, 123}}.

{function, '__bp_priv__makeFixtureTree', 1, 1897}.
  {label, 1896}.
    {line, [{location, "std@io@fs.erl", 141}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__makeFixtureTree'}, 1}.
  {label, 1897}.
    {call_only, 1, {f, 169}}.

{function, '__bp_priv__makeGlobTree', 1, 1899}.
  {label, 1898}.
    {line, [{location, "std@io@fs.erl", 142}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__makeGlobTree'}, 1}.
  {label, 1899}.
    {call_only, 1, {f, 179}}.

{function, '__bp_priv__memHandleWasm', 1, 1901}.
  {label, 1900}.
    {line, [{location, "std@io@fs.erl", 143}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__memHandleWasm'}, 1}.
  {label, 1901}.
    {call_only, 1, {f, 103}}.

{function, '__bp_priv__mkdirRecursiveWasm', 1, 1903}.
  {label, 1902}.
    {line, [{location, "std@io@fs.erl", 144}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__mkdirRecursiveWasm'}, 1}.
  {label, 1903}.
    {call_only, 1, {f, 127}}.

{function, '__bp_priv__mkdirWasm', 1, 1905}.
  {label, 1904}.
    {line, [{location, "std@io@fs.erl", 145}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__mkdirWasm'}, 1}.
  {label, 1905}.
    {call_only, 1, {f, 125}}.

{function, '__bp_priv__noFile', 0, 1907}.
  {label, 1906}.
    {line, [{location, "std@io@fs.erl", 146}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__noFile'}, 0}.
  {label, 1907}.
    {call_only, 0, {f, 185}}.

{function, '__bp_priv__okBytes', 1, 1909}.
  {label, 1908}.
    {line, [{location, "std@io@fs.erl", 147}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__okBytes'}, 1}.
  {label, 1909}.
    {call_only, 1, {f, 69}}.

{function, '__bp_priv__okSize', 1, 1911}.
  {label, 1910}.
    {line, [{location, "std@io@fs.erl", 148}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__okSize'}, 1}.
  {label, 1911}.
    {call_only, 1, {f, 73}}.

{function, '__bp_priv__okStrings', 1, 1913}.
  {label, 1912}.
    {line, [{location, "std@io@fs.erl", 149}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__okStrings'}, 1}.
  {label, 1913}.
    {call_only, 1, {f, 71}}.

{function, '__bp_priv__openWasm', 1, 1915}.
  {label, 1914}.
    {line, [{location, "std@io@fs.erl", 150}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__openWasm'}, 1}.
  {label, 1915}.
    {call_only, 1, {f, 99}}.

{function, '__bp_priv__readAllWasm', 1, 1917}.
  {label, 1916}.
    {line, [{location, "std@io@fs.erl", 151}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__readAllWasm'}, 1}.
  {label, 1917}.
    {call_only, 1, {f, 109}}.

{function, '__bp_priv__readBytesWasm', 1, 1919}.
  {label, 1918}.
    {line, [{location, "std@io@fs.erl", 152}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__readBytesWasm'}, 1}.
  {label, 1919}.
    {call_only, 1, {f, 87}}.

{function, '__bp_priv__readLineWasm', 1, 1921}.
  {label, 1920}.
    {line, [{location, "std@io@fs.erl", 153}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__readLineWasm'}, 1}.
  {label, 1921}.
    {call_only, 1, {f, 111}}.

{function, '__bp_priv__readOnlyWasm', 1, 1923}.
  {label, 1922}.
    {line, [{location, "std@io@fs.erl", 154}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__readOnlyWasm'}, 1}.
  {label, 1923}.
    {call_only, 1, {f, 119}}.

{function, '__bp_priv__readWasm', 2, 1925}.
  {label, 1924}.
    {line, [{location, "std@io@fs.erl", 155}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__readWasm'}, 2}.
  {label, 1925}.
    {call_only, 2, {f, 107}}.

{function, '__bp_priv__removeTreeWasm', 1, 1927}.
  {label, 1926}.
    {line, [{location, "std@io@fs.erl", 156}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__removeTreeWasm'}, 1}.
  {label, 1927}.
    {call_only, 1, {f, 155}}.

{function, '__bp_priv__resolve', 1, 1929}.
  {label, 1928}.
    {line, [{location, "std@io@fs.erl", 157}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__resolve'}, 1}.
  {label, 1929}.
    {call_only, 1, {f, 79}}.

{function, '__bp_priv__rmWasm', 1, 1931}.
  {label, 1930}.
    {line, [{location, "std@io@fs.erl", 158}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__rmWasm'}, 1}.
  {label, 1931}.
    {call_only, 1, {f, 129}}.

{function, '__bp_priv__scratchDirWasm', 0, 1933}.
  {label, 1932}.
    {line, [{location, "std@io@fs.erl", 159}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__scratchDirWasm'}, 0}.
  {label, 1933}.
    {call_only, 0, {f, 157}}.

{function, '__bp_priv__segmentMatches', 2, 1935}.
  {label, 1934}.
    {line, [{location, "std@io@fs.erl", 160}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__segmentMatches'}, 2}.
  {label, 1935}.
    {call_only, 2, {f, 147}}.

{function, '__bp_priv__sizeWasm', 2, 1937}.
  {label, 1936}.
    {line, [{location, "std@io@fs.erl", 161}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__sizeWasm'}, 2}.
  {label, 1937}.
    {call_only, 2, {f, 105}}.

{function, '__bp_priv__sortedStrings', 1, 1939}.
  {label, 1938}.
    {line, [{location, "std@io@fs.erl", 162}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__sortedStrings'}, 1}.
  {label, 1939}.
    {call_only, 1, {f, 85}}.

{function, '__bp_priv__statOr', 1, 1941}.
  {label, 1940}.
    {line, [{location, "std@io@fs.erl", 163}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__statOr'}, 1}.
  {label, 1941}.
    {call_only, 1, {f, 167}}.

{function, '__bp_priv__statWasm', 1, 1943}.
  {label, 1942}.
    {line, [{location, "std@io@fs.erl", 164}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__statWasm'}, 1}.
  {label, 1943}.
    {call_only, 1, {f, 133}}.

{function, '__bp_priv__stripEolWasm', 1, 1945}.
  {label, 1944}.
    {line, [{location, "std@io@fs.erl", 165}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__stripEolWasm'}, 1}.
  {label, 1945}.
    {call_only, 1, {f, 97}}.

{function, '__bp_priv__utf8OffsetWasm', 1, 1947}.
  {label, 1946}.
    {line, [{location, "std@io@fs.erl", 166}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__utf8OffsetWasm'}, 1}.
  {label, 1947}.
    {call_only, 1, {f, 95}}.

{function, '__bp_priv__variantOf', 1, 1949}.
  {label, 1948}.
    {line, [{location, "std@io@fs.erl", 167}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__variantOf'}, 1}.
  {label, 1949}.
    {call_only, 1, {f, 183}}.

{function, '__bp_priv__walkFixture', 1, 1951}.
  {label, 1950}.
    {line, [{location, "std@io@fs.erl", 168}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__walkFixture'}, 1}.
  {label, 1951}.
    {call_only, 1, {f, 171}}.

{function, '__bp_priv__walkFixtureFromCwd', 1, 1953}.
  {label, 1952}.
    {line, [{location, "std@io@fs.erl", 169}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__walkFixtureFromCwd'}, 1}.
  {label, 1953}.
    {call_only, 1, {f, 173}}.

{function, '__bp_priv__walkRefusal', 1, 1955}.
  {label, 1954}.
    {line, [{location, "std@io@fs.erl", 170}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__walkRefusal'}, 1}.
  {label, 1955}.
    {call_only, 1, {f, 175}}.

{function, '__bp_priv__walkWasm', 1, 1957}.
  {label, 1956}.
    {line, [{location, "std@io@fs.erl", 171}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__walkWasm'}, 1}.
  {label, 1957}.
    {call_only, 1, {f, 135}}.

{function, '__bp_priv__wasiError', 1, 1959}.
  {label, 1958}.
    {line, [{location, "std@io@fs.erl", 172}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__wasiError'}, 1}.
  {label, 1959}.
    {call_only, 1, {f, 67}}.

{function, '__bp_priv__wasiName', 1, 1961}.
  {label, 1960}.
    {line, [{location, "std@io@fs.erl", 173}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__wasiName'}, 1}.
  {label, 1961}.
    {call_only, 1, {f, 63}}.

{function, '__bp_priv__wasiText', 1, 1963}.
  {label, 1962}.
    {line, [{location, "std@io@fs.erl", 174}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__wasiText'}, 1}.
  {label, 1963}.
    {call_only, 1, {f, 65}}.

{function, '__bp_priv__withoutRoot', 1, 1965}.
  {label, 1964}.
    {line, [{location, "std@io@fs.erl", 175}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__withoutRoot'}, 1}.
  {label, 1965}.
    {call_only, 1, {f, 75}}.

{function, '__bp_priv__workingDirWasm', 0, 1967}.
  {label, 1966}.
    {line, [{location, "std@io@fs.erl", 176}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__workingDirWasm'}, 0}.
  {label, 1967}.
    {call_only, 0, {f, 159}}.

{function, '__bp_priv__writeBytesWasm', 2, 1969}.
  {label, 1968}.
    {line, [{location, "std@io@fs.erl", 177}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__writeBytesWasm'}, 2}.
  {label, 1969}.
    {call_only, 2, {f, 89}}.

{function, '__bp_priv__writeTextWasm', 2, 1971}.
  {label, 1970}.
    {line, [{location, "std@io@fs.erl", 178}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__writeTextWasm'}, 2}.
  {label, 1971}.
    {call_only, 2, {f, 91}}.

{function, '__bp_priv__writeWasm', 2, 1973}.
  {label, 1972}.
    {line, [{location, "std@io@fs.erl", 179}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_priv__writeWasm'}, 2}.
  {label, 1973}.
    {call_only, 2, {f, 115}}.

{function, '__bp_tpl_0', 1, 187}.
  {label, 186}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_0'}, 1}.
  {label, 187}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, file, read_file_info, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 191}, [{x, 0}]}.
    {test, test_arity, {f, 191}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 191}, [{x, 0}, {atom, ok}]}.
    {move, {atom, true}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 191}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_1-t/1-fun-0-', 1, 261}.
  {label, 260}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_1-t/1-fun-0-'}, 1}.
  {label, 261}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, utf8}, {x, 1}}.
    {move, {atom, utf8}, {x, 2}}.
    {call_ext, 3, {extfunc, unicode, characters_to_binary, 3}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 265}, [{x, 0}]}.
    {jump, {f, 266}}.
  {label, 266}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 265}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 267}, [{x, 0}]}.
    {test, test_arity, {f, 267}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 267}, [{x, 0}, {atom, error}]}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, byte_size, 1}, 5}.
  {label, 267}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 268}, [{x, 0}]}.
    {test, test_arity, {f, 268}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 268}, [{x, 0}, {atom, incomplete}]}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, byte_size, 1}, 5}.
  {label, 268}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_1', 1, 257}.
  {label, 256}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_1'}, 1}.
  {label, 257}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 261}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_2-t/1-fun-0-', 1, 277}.
  {label, 276}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_2-t/1-fun-0-'}, 1}.
  {label, 277}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 281}, [{x, 0}]}.
    {jump, {f, 282}}.
  {label, 282}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 281}.
    {move, {literal, {error, <<"bytes.toUtf8: not valid UTF-8">>}}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_2', 1, 273}.
  {label, 272}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_2'}, 1}.
  {label, 273}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 277}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_3-t/1-fun-0-', 1, 290}.
  {label, 289}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_3-t/1-fun-0-'}, 1}.
  {label, 290}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, file, read_file, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 294}, [{x, 0}]}.
    {test, test_arity, {f, 294}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 294}, [{x, 0}, {atom, ok}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 294}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 295}, [{x, 0}]}.
    {test, test_arity, {f, 295}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 295}, [{x, 0}, {atom, error}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 295}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_3', 1, 284}.
  {label, 283}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_3'}, 1}.
  {label, 284}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 287}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 290}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 297}, [{x, 0}]}.
    {test, test_arity, {f, 297}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 297}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 296}}.
  {label, 297}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 298}, [{x, 0}]}.
    {test, test_arity, {f, 298}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 298}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 296}}.
  {label, 298}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 296}}.
  {label, 296}.
    {jump, {f, 288}}.
  {label, 287}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 303}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 302}}.
  {label, 303}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 304}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 302}}.
  {label, 304}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 305}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 302}}.
  {label, 305}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 302}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 300}}.
  {label, 300}.
  {label, 288}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_tpl_4-t/2-fun-0-', 2, 319}.
  {label, 318}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_4-t/2-fun-0-'}, 2}.
  {label, 319}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, file, write_file, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 323}, [{x, 0}, {atom, ok}]}.
    {move, {literal, {ok, 0}}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 323}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 324}, [{x, 0}]}.
    {test, test_arity, {f, 324}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 324}, [{x, 0}, {atom, error}]}.
    {move, {y, 5}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 324}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_4', 2, 313}.
  {label, 312}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_4'}, 2}.
  {label, 313}.
    {allocate, 13, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {'try', {y, 12}, {f, 316}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 319}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {y, 6}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 7}}.
    {try_end, {y, 12}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 326}, [{x, 0}]}.
    {test, test_arity, {f, 326}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 326}, [{x, 0}, {atom, ok}]}.
    {move, {y, 9}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 5}}.
    {jump, {f, 325}}.
  {label, 326}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 327}, [{x, 0}]}.
    {test, test_arity, {f, 327}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 327}, [{x, 0}, {atom, error}]}.
    {move, {y, 9}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 10}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 10}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 5}}.
    {jump, {f, 325}}.
  {label, 327}.
    {move, {y, 7}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 5}}.
    {jump, {f, 325}}.
  {label, 325}.
    {jump, {f, 317}}.
  {label, 316}.
    {try_case, {y, 12}}.
    {move, {x, 0}, {y, 6}}.
    {move, {x, 1}, {y, 7}}.
    {move, {x, 2}, {y, 8}}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 8}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 332}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 10}}.
    {jump, {f, 331}}.
  {label, 332}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 333}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 10}}.
    {jump, {f, 331}}.
  {label, 333}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 334}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 10}}.
    {jump, {f, 331}}.
  {label, 334}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 331}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 11}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 5}}.
    {jump, {f, 329}}.
  {label, 329}.
  {label, 317}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 13}.
    return.

{function, '__bp_tpl_5-t/2-fun-0-', 2, 346}.
  {label, 345}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_5-t/2-fun-0-'}, 2}.
  {label, 346}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {literal, [append]}, {x, 2}}.
    {call_ext, 3, {extfunc, file, write_file, 3}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 350}, [{x, 0}, {atom, ok}]}.
    {move, {literal, {ok, 0}}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 350}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 351}, [{x, 0}]}.
    {test, test_arity, {f, 351}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 351}, [{x, 0}, {atom, error}]}.
    {move, {y, 5}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 351}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_5', 2, 340}.
  {label, 339}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_5'}, 2}.
  {label, 340}.
    {allocate, 13, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {'try', {y, 12}, {f, 343}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 346}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {y, 6}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 7}}.
    {try_end, {y, 12}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 353}, [{x, 0}]}.
    {test, test_arity, {f, 353}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 353}, [{x, 0}, {atom, ok}]}.
    {move, {y, 9}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 5}}.
    {jump, {f, 352}}.
  {label, 353}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 354}, [{x, 0}]}.
    {test, test_arity, {f, 354}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 354}, [{x, 0}, {atom, error}]}.
    {move, {y, 9}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 10}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 10}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 5}}.
    {jump, {f, 352}}.
  {label, 354}.
    {move, {y, 7}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 5}}.
    {jump, {f, 352}}.
  {label, 352}.
    {jump, {f, 344}}.
  {label, 343}.
    {try_case, {y, 12}}.
    {move, {x, 0}, {y, 6}}.
    {move, {x, 1}, {y, 7}}.
    {move, {x, 2}, {y, 8}}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 8}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 359}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 10}}.
    {jump, {f, 358}}.
  {label, 359}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 360}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 10}}.
    {jump, {f, 358}}.
  {label, 360}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 361}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 10}}.
    {jump, {f, 358}}.
  {label, 361}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 358}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 11}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 5}}.
    {jump, {f, 356}}.
  {label, 356}.
  {label, 344}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 13}.
    return.

{function, '__bp_tpl_6-t/1-fun-0-', 1, 371}.
  {label, 370}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_6-t/1-fun-0-'}, 1}.
  {label, 371}.
    {allocate, 13, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {literal, [{time, posix}]}, {x, 1}}.
    {call_ext, 2, {extfunc, file, read_file_info, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 375}, [{x, 0}]}.
    {test, test_arity, {f, 375}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 5}}.
    {get_tuple_element, {x, 0}, 1, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 375}, [{x, 0}, {atom, ok}]}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 375}, [{x, 0}]}.
    {test, test_arity, {f, 375}, [{x, 0}, 14]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {get_tuple_element, {x, 0}, 2, {y, 9}}.
    {get_tuple_element, {x, 0}, 5, {y, 10}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 375}, [{x, 0}, {atom, file_info}]}.
    {move, {y, 8}, {y, 0}}.
    {move, {y, 9}, {y, 1}}.
    {move, {y, 10}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1000}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '*', 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, directory}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 12}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, size}, {y, 0}, {atom, mtime}, {y, 11}, {atom, isDir}, {y, 12}]}}.
    {move, {x, 0}, {y, 11}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 11}]}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {deallocate, 13}.
    return.
  {label, 375}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 376}, [{x, 0}]}.
    {test, test_arity, {f, 376}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 5}}.
    {get_tuple_element, {x, 0}, 1, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 376}, [{x, 0}, {atom, error}]}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {deallocate, 13}.
    return.
  {label, 376}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_6', 1, 365}.
  {label, 364}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_6'}, 1}.
  {label, 365}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 368}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 371}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 378}, [{x, 0}]}.
    {test, test_arity, {f, 378}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 378}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 377}}.
  {label, 378}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 379}, [{x, 0}]}.
    {test, test_arity, {f, 379}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 379}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 377}}.
  {label, 379}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 377}}.
  {label, 377}.
    {jump, {f, 369}}.
  {label, 368}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 384}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 383}}.
  {label, 384}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 385}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 383}}.
  {label, 385}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 386}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 383}}.
  {label, 386}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 383}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 381}}.
  {label, 381}.
  {label, 369}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_adopt', 3, 388}.
  {label, 387}.
    {line, [{location, "std@io@fs.erl", 22}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_adopt'}, 3}.
  {label, 388}.
    {test, is_map, {f, 393}, [{x, 0}]}.
    {allocate, 1, 3}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 390}}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, {x, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, list_to_tuple, 1}, 1}.
  {label, 393}.
    {test, is_list, {f, 394}, [{x, 0}]}.
    {call_only, 3, {f, 392}}.
  {label, 394}.
    {test, is_tagged_tuple, {f, 395}, [{x, 0}, 2, {atom, ok}]}.
    {allocate, 0, 3}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {call, 3, {f, 388}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 0}]}}.
    {deallocate, 0}.
    return.
  {label, 395}.
    return.

{function, '-bp_adopt_fields-', 2, 390}.
  {label, 389}.
    {line, [{location, "std@io@fs.erl", 22}]}.
    {func_info, {atom, std@io@fs}, {atom, '-bp_adopt_fields-'}, 2}.
  {label, 390}.
    {test, is_nonempty_list, {f, 396}, [{x, 0}]}.
    {allocate, 2, 2}.
    {move, {x, 1}, {y, 1}}.
    {get_list, {x, 0}, {x, 0}, {y, 0}}.
    {move, {atom, undefined}, {x, 2}}.
    {call_ext, 3, {extfunc, maps, get, 3}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 390}}.
    {test_heap, 2, 1}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 396}.
    {move, nil, {x, 0}}.
    return.

{function, '-bp_adopt_each-', 3, 392}.
  {label, 391}.
    {line, [{location, "std@io@fs.erl", 22}]}.
    {func_info, {atom, std@io@fs}, {atom, '-bp_adopt_each-'}, 3}.
  {label, 392}.
    {test, is_nonempty_list, {f, 397}, [{x, 0}]}.
    {allocate, 3, 3}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {get_list, {x, 0}, {x, 0}, {y, 0}}.
    {call, 3, {f, 388}}.
    {move, {y, 0}, {x, 3}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call, 3, {f, 392}}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, {x, 0}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 397}.
    {move, nil, {x, 0}}.
    return.

{function, '__bp_tpl_7-t/1-fun-0-', 1, 407}.
  {label, 406}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_7-t/1-fun-0-'}, 1}.
  {label, 407}.
    {allocate, 9, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, file, list_dir, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 411}, [{x, 0}]}.
    {test, test_arity, {f, 411}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 411}, [{x, 0}, {atom, ok}]}.
    {move, {y, 4}, {y, 0}}.
    {move, nil, {y, 5}}.
    {move, {y, 0}, {y, 6}}.
  {label, 413}.
    {move, {y, 6}, {x, 0}}.
    {test, is_nonempty_list, {f, 414}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 7}, {y, 6}}.
    {move, {y, 7}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 2, 0}.
    {put_list, {y, 8}, {y, 5}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 413}}.
  {label, 414}.
    {move, {y, 6}, {x, 0}}.
    {test, is_nil, {f, 415}, [{x, 0}]}.
    {jump, {f, 412}}.
  {label, 415}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 6}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 412}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, sort, 1}}.
    {move, {x, 0}, {y, 5}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 5}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 411}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 416}, [{x, 0}]}.
    {test, test_arity, {f, 416}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 416}, [{x, 0}, {atom, error}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 416}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_7', 1, 401}.
  {label, 400}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_7'}, 1}.
  {label, 401}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 404}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 407}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 418}, [{x, 0}]}.
    {test, test_arity, {f, 418}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 418}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 417}}.
  {label, 418}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 419}, [{x, 0}]}.
    {test, test_arity, {f, 419}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 419}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 417}}.
  {label, 419}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 417}}.
  {label, 417}.
    {jump, {f, 405}}.
  {label, 404}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 424}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 423}}.
  {label, 424}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 425}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 423}}.
  {label, 425}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 426}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 423}}.
  {label, 426}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 423}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 421}}.
  {label, 421}.
  {label, 405}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_tpl_8-t/1-fun-0-', 1, 436}.
  {label, 435}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_8-t/1-fun-0-'}, 1}.
  {label, 436}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, file, make_dir, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 440}, [{x, 0}, {atom, ok}]}.
    {move, {literal, {ok, 0}}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 440}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 441}, [{x, 0}]}.
    {test, test_arity, {f, 441}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 441}, [{x, 0}, {atom, error}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 441}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_8', 1, 430}.
  {label, 429}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_8'}, 1}.
  {label, 430}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 433}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 436}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 443}, [{x, 0}]}.
    {test, test_arity, {f, 443}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 443}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 442}}.
  {label, 443}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 444}, [{x, 0}]}.
    {test, test_arity, {f, 444}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 444}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 442}}.
  {label, 444}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 442}}.
  {label, 442}.
    {jump, {f, 434}}.
  {label, 433}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 449}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 448}}.
  {label, 449}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 450}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 448}}.
  {label, 450}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 451}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 448}}.
  {label, 451}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 448}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 446}}.
  {label, 446}.
  {label, 434}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_tpl_9-t/1-fun-0-', 1, 461}.
  {label, 460}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_9-t/1-fun-0-'}, 1}.
  {label, 461}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, filelib, ensure_path, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 465}, [{x, 0}, {atom, ok}]}.
    {move, {literal, {ok, 0}}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 465}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 466}, [{x, 0}]}.
    {test, test_arity, {f, 466}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 466}, [{x, 0}, {atom, error}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 466}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_9', 1, 455}.
  {label, 454}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_9'}, 1}.
  {label, 455}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 458}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 461}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 468}, [{x, 0}]}.
    {test, test_arity, {f, 468}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 468}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 467}}.
  {label, 468}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 469}, [{x, 0}]}.
    {test, test_arity, {f, 469}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 469}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 467}}.
  {label, 469}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 467}}.
  {label, 467}.
    {jump, {f, 459}}.
  {label, 458}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 474}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 473}}.
  {label, 474}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 475}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 473}}.
  {label, 475}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 476}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 473}}.
  {label, 476}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 473}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 471}}.
  {label, 471}.
  {label, 459}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_tpl_10-t/1-fun-0-', 1, 486}.
  {label, 485}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_10-t/1-fun-0-'}, 1}.
  {label, 486}.
    {allocate, 7, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, file, read_link_info, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 490}, [{x, 0}]}.
    {test, test_arity, {f, 490}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 490}, [{x, 0}, {atom, ok}]}.
    {move, {y, 4}, {y, 0}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {bif, element, {f, 490}, [{x, 0}, {x, 1}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {move, {atom, directory}, {x, 1}}.
    {test, is_eq_exact, {f, 490}, [{x, 0}, {x, 1}]}.
    {jump, {f, 491}}.
  {label, 491}.
    {move, {literal, {error, eisdir}}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 490}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, file, delete, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 494}, [{x, 0}, {atom, ok}]}.
    {move, {literal, {ok, 0}}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 494}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 495}, [{x, 0}]}.
    {test, test_arity, {f, 495}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 495}, [{x, 0}, {atom, error}]}.
    {move, {y, 5}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 495}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_10', 1, 480}.
  {label, 479}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_10'}, 1}.
  {label, 480}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 483}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 486}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 497}, [{x, 0}]}.
    {test, test_arity, {f, 497}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 497}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 496}}.
  {label, 497}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 498}, [{x, 0}]}.
    {test, test_arity, {f, 498}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 498}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 496}}.
  {label, 498}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 496}}.
  {label, 496}.
    {jump, {f, 484}}.
  {label, 483}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 503}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 502}}.
  {label, 503}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 504}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 502}}.
  {label, 504}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 505}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 502}}.
  {label, 505}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 502}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 500}}.
  {label, 500}.
  {label, 484}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_tpl_11-t/1-fun-0-', 1, 515}.
  {label, 514}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_11-t/1-fun-0-'}, 1}.
  {label, 515}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, file, del_dir_r, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 519}, [{x, 0}, {atom, ok}]}.
    {move, {literal, {ok, 0}}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 519}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 520}, [{x, 0}, {literal, {error, enoent}}]}.
    {move, {literal, {ok, 0}}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 520}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 521}, [{x, 0}]}.
    {test, test_arity, {f, 521}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 521}, [{x, 0}, {atom, error}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 521}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_11', 1, 509}.
  {label, 508}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_11'}, 1}.
  {label, 509}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 512}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 515}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 523}, [{x, 0}]}.
    {test, test_arity, {f, 523}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 523}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 522}}.
  {label, 523}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 524}, [{x, 0}]}.
    {test, test_arity, {f, 524}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 524}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 522}}.
  {label, 524}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 522}}.
  {label, 522}.
    {jump, {f, 513}}.
  {label, 512}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 529}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 528}}.
  {label, 529}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 530}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 528}}.
  {label, 530}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 531}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 528}}.
  {label, 531}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 528}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 526}}.
  {label, 526}.
  {label, 513}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_tpl_12-t/2-fun-0-', 2, 541}.
  {label, 540}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_12-t/2-fun-0-'}, 2}.
  {label, 541}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, file, copy, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 545}, [{x, 0}]}.
    {test, test_arity, {f, 545}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 545}, [{x, 0}, {atom, ok}]}.
    {move, {literal, {ok, 0}}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 545}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 546}, [{x, 0}]}.
    {test, test_arity, {f, 546}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 546}, [{x, 0}, {atom, error}]}.
    {move, {y, 5}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 546}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_12', 2, 535}.
  {label, 534}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_12'}, 2}.
  {label, 535}.
    {allocate, 13, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {'try', {y, 12}, {f, 538}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 541}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {y, 6}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 7}}.
    {try_end, {y, 12}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 548}, [{x, 0}]}.
    {test, test_arity, {f, 548}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 548}, [{x, 0}, {atom, ok}]}.
    {move, {y, 9}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 5}}.
    {jump, {f, 547}}.
  {label, 548}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 549}, [{x, 0}]}.
    {test, test_arity, {f, 549}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 549}, [{x, 0}, {atom, error}]}.
    {move, {y, 9}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 10}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 10}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 5}}.
    {jump, {f, 547}}.
  {label, 549}.
    {move, {y, 7}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 5}}.
    {jump, {f, 547}}.
  {label, 547}.
    {jump, {f, 539}}.
  {label, 538}.
    {try_case, {y, 12}}.
    {move, {x, 0}, {y, 6}}.
    {move, {x, 1}, {y, 7}}.
    {move, {x, 2}, {y, 8}}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 8}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 554}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 10}}.
    {jump, {f, 553}}.
  {label, 554}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 555}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 10}}.
    {jump, {f, 553}}.
  {label, 555}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 556}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 10}}.
    {jump, {f, 553}}.
  {label, 556}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 553}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 11}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 5}}.
    {jump, {f, 551}}.
  {label, 551}.
  {label, 539}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 13}.
    return.

{function, '__bp_tpl_13---t/1-fun-0--fun-1--fun-2-', 5, 585}.
  {label, 584}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_13---t/1-fun-0--fun-1--fun-2-'}, 5}.
  {label, 585}.
    {allocate, 12, 5}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {x, 1}, {y, 7}}.
    {move, {x, 2}, {y, 0}}.
    {move, {x, 3}, {y, 1}}.
    {move, {x, 4}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 3}}.
    {jump, {f, 589}}.
  {label, 589}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 591}, [{x, 0}, nil]}.
    {move, {y, 6}, {y, 8}}.
    {jump, {f, 590}}.
  {label, 591}.
    {move, {literal, [47]}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 8}}.
    {jump, {f, 590}}.
  {label, 590}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 594}}.
  {label, 594}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, file, read_file_info, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 596}, [{x, 0}]}.
    {test, test_arity, {f, 596}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 596}, [{x, 0}, {atom, ok}]}.
    {move, {y, 10}, {y, 5}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {bif, element, {f, 596}, [{x, 0}, {x, 1}], {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {move, {atom, directory}, {x, 1}}.
    {test, is_eq_exact, {f, 596}, [{x, 0}, {x, 1}]}.
    {jump, {f, 597}}.
  {label, 597}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {y, 7}, {x, 2}}.
    {move, {y, 2}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 12}.
    return.
  {label, 596}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 598}, [{x, 0}]}.
    {test, test_arity, {f, 598}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 598}, [{x, 0}, {atom, ok}]}.
    {move, {y, 10}, {y, 5}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {bif, element, {f, 598}, [{x, 0}, {x, 1}], {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {move, {atom, regular}, {x, 1}}.
    {test, is_eq_exact, {f, 598}, [{x, 0}, {x, 1}]}.
    {jump, {f, 599}}.
  {label, 599}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 11}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, file}, {y, 11}]}}.
    {move, {x, 0}, {y, 11}}.
    {test_heap, 2, 0}.
    {put_list, {y, 11}, {y, 7}, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 598}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 600}, [{x, 0}]}.
    {test, test_arity, {f, 600}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 600}, [{x, 0}, {atom, ok}]}.
    {move, {y, 7}, {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 600}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 601}, [{x, 0}, {literal, {error, enoent}}]}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, dangling}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 2, 0}.
    {put_list, {y, 9}, {y, 7}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 601}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 602}, [{x, 0}]}.
    {test, test_arity, {f, 602}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 602}, [{x, 0}, {atom, error}]}.
    {move, {y, 10}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 12}.
  {label, 602}.
    {move, {y, 8}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_13--t/1-fun-0--fun-1-', 3, 578}.
  {label, 577}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_13--t/1-fun-0--fun-1-'}, 3}.
  {label, 578}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {x, 2}, {y, 4}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 578}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, file, list_dir, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 582}, [{x, 0}]}.
    {test, test_arity, {f, 582}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 582}, [{x, 0}, {atom, error}]}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 9}.
  {label, 582}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 583}, [{x, 0}]}.
    {test, test_arity, {f, 583}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 583}, [{x, 0}, {atom, ok}]}.
    {move, {y, 7}, {y, 1}}.
    {test_heap, {alloc, [{words, 3}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 585}, 1, 0, {x, 0}, {list, [{y, 2}, {y, 3}, {y, 0}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_ext_last, 3, {extfunc, lists, foldl, 3}, 9}.
  {label, 583}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_13-t/1-fun-0-', 1, 566}.
  {label, 565}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_13-t/1-fun-0-'}, 1}.
  {label, 566}.
    {allocate, 10, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 570}}.
  {label, 570}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, filelib, is_dir, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 572}, [{x, 0}, {atom, false}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, file, read_file_info, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 574}, [{x, 0}]}.
    {test, test_arity, {f, 574}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 574}, [{x, 0}, {atom, ok}]}.
    {move, {atom, enotdir}, {y, 5}}.
    {jump, {f, 573}}.
  {label, 574}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 575}, [{x, 0}]}.
    {test, test_arity, {f, 575}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 575}, [{x, 0}, {atom, error}]}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 1}, {y, 5}}.
    {jump, {f, 573}}.
  {label, 575}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 573}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 5}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 572}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 576}, [{x, 0}, {atom, true}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 578}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 604}}.
  {label, 604}.
    {move, {y, 0}, {x, 0}}.
    {move, nil, {x, 1}}.
    {move, nil, {x, 2}}.
    {move, {y, 1}, {x, 3}}.
    {call_fun, 3}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 606}}.
  {label, 606}.
    {move, nil, {y, 4}}.
    {move, {y, 0}, {y, 5}}.
  {label, 608}.
    {move, {y, 5}, {x, 0}}.
    {test, is_nonempty_list, {f, 609}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 6}, {y, 5}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 608}, [{x, 0}]}.
    {test, test_arity, {f, 608}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 608}, [{x, 0}, {atom, file}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, {y, 4}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 608}}.
  {label, 609}.
    {move, {y, 5}, {x, 0}}.
    {test, is_nil, {f, 610}, [{x, 0}]}.
    {jump, {f, 607}}.
  {label, 610}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 5}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 607}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, sort, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, nil, {y, 5}}.
    {move, {y, 0}, {y, 6}}.
  {label, 612}.
    {move, {y, 6}, {x, 0}}.
    {test, is_nonempty_list, {f, 613}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 7}, {y, 6}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 612}, [{x, 0}]}.
    {test, test_arity, {f, 612}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 612}, [{x, 0}, {atom, dangling}]}.
    {move, {y, 9}, {y, 0}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, {y, 5}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 612}}.
  {label, 613}.
    {move, {y, 6}, {x, 0}}.
    {test, is_nil, {f, 614}, [{x, 0}]}.
    {jump, {f, 611}}.
  {label, 614}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 6}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 611}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, sort, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, files}, {y, 4}, {atom, dangling}, {y, 5}]}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 4}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 576}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_13', 1, 560}.
  {label, 559}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_13'}, 1}.
  {label, 560}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 563}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 566}, 2, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 616}, [{x, 0}]}.
    {test, test_arity, {f, 616}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 616}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 615}}.
  {label, 616}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 617}, [{x, 0}]}.
    {test, test_arity, {f, 617}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 617}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 615}}.
  {label, 617}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 615}}.
  {label, 615}.
    {jump, {f, 564}}.
  {label, 563}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 622}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 621}}.
  {label, 622}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 623}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 621}}.
  {label, 623}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 624}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 621}}.
  {label, 624}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 621}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 619}}.
  {label, 619}.
  {label, 564}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '-bp_at-', 2, 632}.
  {label, 631}.
    {line, [{location, "std@io@fs.erl", 29}]}.
    {func_info, {atom, std@io@fs}, {atom, '-bp_at-'}, 2}.
  {label, 632}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 634}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 633}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 634}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 633}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 633}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_print', 1, 639}.
  {label, 638}.
    {line, [{location, "std@io@fs.erl", 29}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_print'}, 1}.
  {label, 639}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 643}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 643}.
  {label, 642}.
    {line, [{location, "std@io@fs.erl", 29}]}.
    {func_info, {atom, std@io@fs}, {atom, '-bp_show_top-'}, 1}.
  {label, 643}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 641}}.

{function, '-bp_show_elem-', 1, 645}.
  {label, 644}.
    {line, [{location, "std@io@fs.erl", 29}]}.
    {func_info, {atom, std@io@fs}, {atom, '-bp_show_elem-'}, 1}.
  {label, 645}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 641}}.

{function, '__bp_show', 2, 641}.
  {label, 640}.
    {line, [{location, "std@io@fs.erl", 29}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_show'}, 2}.
  {label, 641}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 653}, [{x, 0}]}.
    {test, is_eq, {f, 652}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 652}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 653}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 654}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 645}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 93}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 91}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 654}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 656}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 655}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 655}, [{x, 0}]}.
    {test, is_ne_exact, {f, 655}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 655}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 655}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 660}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 661}}.
  {label, 660}.
    {test, is_eq_exact, {f, 657}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 661}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 641}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 655}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 645}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 40}, {x, 0}, {x, 0}}.
    {put_list, {integer, 35}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 656}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 658}, [{x, 0}]}.
    {test, is_ne_exact, {f, 658}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 658}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 659}, [{x, 0}, {atom, undefined}]}.
  {label, 657}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 647}, 2}.
  {label, 658}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 659}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 647}.
  {label, 646}.
    {line, [{location, "std@io@fs.erl", 29}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tagged'}, 2}.
  {label, 647}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 662}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 662}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 662}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 663}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 649}, 3}.
  {label, 663}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 649}.
  {label, 648}.
    {line, [{location, "std@io@fs.erl", 29}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_render'}, 1}.
  {label, 649}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 664}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 664}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 665}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 665}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 651}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {y, 1}, {x, 1}, {x, 1}}.
    {put_list, {integer, 40}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_render_pair-', 1, 651}.
  {label, 650}.
    {line, [{location, "std@io@fs.erl", 29}]}.
    {func_info, {atom, std@io@fs}, {atom, '-bp_render_pair-'}, 1}.
  {label, 651}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 641}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 6, 1}.
    {put_list, {y, 1}, nil, {x, 1}}.
    {put_list, {literal, <<": ">>}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_stringify-', 1, 667}.
  {label, 666}.
    {line, [{location, "std@io@fs.erl", 29}]}.
    {func_info, {atom, std@io@fs}, {atom, '-bp_stringify-'}, 1}.
  {label, 667}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 668}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 668}.
    {test, is_integer, {f, 669}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 669}.
    {call, 1, {f, 643}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '-bp_join-', 2, 637}.
  {label, 636}.
    {line, [{location, "std@io@fs.erl", 29}]}.
    {func_info, {atom, std@io@fs}, {atom, '-bp_join-'}, 2}.
  {label, 637}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 667}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 1}.

{function, '__bp_tpl_14--t/2-fun-0--fun-1-', 1, 695}.
  {label, 694}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_14--t/2-fun-0--fun-1-'}, 1}.
  {label, 695}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, file, read_link_info, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 699}, [{x, 0}]}.
    {test, test_arity, {f, 699}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 699}, [{x, 0}, {atom, ok}]}.
    {move, {y, 4}, {y, 0}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {move, {atom, directory}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 699}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 6}.
    return.

{function, '__bp_tpl_14---t/2-fun-0--fun-2--fun-3-', 1, 708}.
  {label, 707}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_14---t/2-fun-0--fun-2--fun-3-'}, 1}.
  {label, 708}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {literal, [42, 63, 91, 123]}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, member, 2}, 1}.

{function, '__bp_tpl_14--t/2-fun-0--fun-2-', 1, 704}.
  {label, 703}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_14--t/2-fun-0--fun-2-'}, 1}.
  {label, 704}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 708}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, any, 2}, 2}.

{function, '__bp_tpl_14--t/2-fun-0--fun-4-', 2, 714}.
  {label, 713}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_14--t/2-fun-0--fun-4-'}, 2}.
  {label, 714}.
    {allocate, 9, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 718}, [{x, 0}, {literal, [42]}]}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, file, list_dir, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 720}, [{x, 0}]}.
    {test, test_arity, {f, 720}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 720}, [{x, 0}, {atom, ok}]}.
    {move, {y, 7}, {y, 0}}.
    {move, {y, 0}, {y, 5}}.
    {jump, {f, 719}}.
  {label, 720}.
    {move, nil, {y, 5}}.
    {jump, {f, 719}}.
  {label, 719}.
    {move, {y, 5}, {y, 3}}.
    {jump, {f, 717}}.
  {label, 718}.
    {'try', {y, 8}, {f, 723}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, filelib, wildcard, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 4}}.
    {try_end, {y, 8}}.
    {jump, {f, 724}}.
  {label, 723}.
    {try_case, {y, 8}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, nil, {y, 4}}.
    {jump, {f, 725}}.
  {label, 725}.
  {label, 724}.
    {move, {y, 4}, {y, 3}}.
    {jump, {f, 717}}.
  {label, 717}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 728}}.
  {label, 728}.
    {move, nil, {y, 3}}.
    {move, {y, 0}, {y, 4}}.
  {label, 730}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 731}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 4}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {bif, hd, {f, 730}, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 46}, {x, 1}}.
    {test, is_ne_exact, {f, 733}, [{x, 0}, {x, 1}]}.
    {jump, {f, 734}}.
  {label, 733}.
    {move, {y, 2}, {x, 0}}.
    {bif, hd, {f, 730}, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 46}, {x, 1}}.
    {test, is_eq_exact, {f, 730}, [{x, 0}, {x, 1}]}.
  {label, 734}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 730}}.
  {label, 731}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nil, {f, 732}, [{x, 0}]}.
    {jump, {f, 729}}.
  {label, 732}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 729}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 9}.
    return.

{function, '__bp_tpl_14--t/2-fun-0--fun-5-', 2, 738}.
  {label, 737}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_14--t/2-fun-0--fun-5-'}, 2}.
  {label, 738}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 740}, [{x, 0}, nil]}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 740}.
    {move, {literal, [47]}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_14---t/2-fun-0--fun-6--fun-7-', 7, 751}.
  {label, 750}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_14---t/2-fun-0--fun-6--fun-7-'}, 7}.
  {label, 751}.
    {allocate, 11, 7}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {x, 1}, {y, 8}}.
    {move, {x, 2}, {y, 0}}.
    {move, {x, 3}, {y, 1}}.
    {move, {x, 4}, {y, 2}}.
    {move, {x, 5}, {y, 3}}.
    {move, {x, 6}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 5}}.
    {jump, {f, 755}}.
  {label, 755}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 6}}.
    {jump, {f, 757}}.
  {label, 757}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 759}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 8}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [[42, 42]]}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {move, {y, 6}, {x, 2}}.
    {move, {y, 10}, {x, 3}}.
    {move, {y, 4}, {x, 4}}.
    {call_fun, 4}.
    {deallocate, 11}.
    return.
  {label, 759}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 760}, [{x, 0}, {atom, false}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 8}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 760}.
    {move, {y, 9}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_14---t/2-fun-0--fun-6--fun-8-', 8, 763}.
  {label, 762}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_14---t/2-fun-0--fun-6--fun-8-'}, 8}.
  {label, 763}.
    {allocate, 11, 8}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {x, 1}, {y, 8}}.
    {move, {x, 2}, {y, 0}}.
    {move, {x, 3}, {y, 1}}.
    {move, {x, 4}, {y, 2}}.
    {move, {x, 5}, {y, 3}}.
    {move, {x, 6}, {y, 4}}.
    {move, {x, 7}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 6}}.
    {jump, {f, 767}}.
  {label, 767}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 769}, [{x, 0}, {atom, true}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {move, {y, 4}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 10}, {x, 2}}.
    {move, {y, 8}, {x, 3}}.
    {move, {y, 2}, {x, 4}}.
    {call_fun, 4}.
    {deallocate, 11}.
    return.
  {label, 769}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 770}, [{x, 0}, {atom, false}]}.
    {move, {y, 8}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 770}.
    {move, {y, 9}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_14---t/2-fun-0--fun-6--fun-9-', 8, 789}.
  {label, 788}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_14---t/2-fun-0--fun-6--fun-9-'}, 8}.
  {label, 789}.
    {allocate, 11, 8}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {x, 1}, {y, 9}}.
    {move, {x, 2}, {y, 0}}.
    {move, {x, 3}, {y, 1}}.
    {move, {x, 4}, {y, 2}}.
    {move, {x, 5}, {y, 3}}.
    {move, {x, 6}, {y, 4}}.
    {move, {x, 7}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 6}}.
    {jump, {f, 793}}.
  {label, 793}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 7}}.
    {jump, {f, 795}}.
  {label, 795}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 797}, [{x, 0}, nil]}.
    {test_heap, 2, 0}.
    {put_list, {y, 7}, {y, 9}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 797}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq_exact, {f, 800}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 7}, {x, 2}}.
    {move, {y, 9}, {x, 3}}.
    {move, {y, 5}, {x, 4}}.
    {call_fun, 4}.
    {deallocate, 11}.
    return.
  {label, 800}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq_exact, {f, 801}, [{x, 0}, {atom, false}]}.
    {move, {y, 9}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 801}.
    {move, {y, 10}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_14--t/2-fun-0--fun-6-', 8, 745}.
  {label, 744}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_14--t/2-fun-0--fun-6-'}, 8}.
  {label, 745}.
    {allocate, 19, 8}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {x, 1}, {y, 10}}.
    {move, {x, 2}, {y, 11}}.
    {move, {x, 3}, {y, 12}}.
    {move, {x, 4}, {y, 0}}.
    {move, {x, 5}, {y, 1}}.
    {move, {x, 6}, {y, 2}}.
    {move, {x, 7}, {y, 3}}.
    {test_heap, {alloc, [{words, 4}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 745}, 1, 0, {x, 0}, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 747}, [{x, 0}, nil]}.
    {move, {y, 11}, {x, 0}}.
    {test, is_eq_exact, {f, 747}, [{x, 0}, nil]}.
    {move, {y, 12}, {x, 0}}.
    {deallocate, 19}.
    return.
  {label, 747}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 748}, [{x, 0}, nil]}.
    {test_heap, 2, 0}.
    {put_list, {y, 11}, {y, 12}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {deallocate, 19}.
    return.
  {label, 748}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 749}, [{x, 0}, {literal, [[42, 42]]}]}.
    {test_heap, {alloc, [{words, 5}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 751}, 2, 0, {x, 0}, {list, [{y, 10}, {y, 0}, {y, 11}, {y, 1}, {y, 4}]}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 10}, {x, 0}}.
    {move, {literal, [42]}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 13}, {x, 0}}.
    {move, {y, 12}, {x, 1}}.
    {move, {y, 14}, {x, 2}}.
    {call_ext_last, 3, {extfunc, lists, foldl, 3}, 19}.
  {label, 749}.
    {move, {y, 9}, {x, 0}}.
    {test, is_nonempty_list, {f, 761}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 13}, {y, 14}}.
    {move, {y, 13}, {x, 0}}.
    {test, is_eq_exact, {f, 761}, [{x, 0}, {literal, [42, 42]}]}.
    {move, {y, 14}, {y, 5}}.
    {move, {y, 9}, {y, 6}}.
    {test_heap, {alloc, [{words, 6}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 763}, 3, 0, {x, 0}, {list, [{y, 10}, {y, 1}, {y, 4}, {y, 6}, {y, 0}, {y, 11}]}}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {move, {y, 11}, {x, 2}}.
    {move, {y, 12}, {x, 3}}.
    {move, {y, 0}, {x, 4}}.
    {move, {y, 1}, {x, 5}}.
    {move, {y, 2}, {x, 6}}.
    {move, {y, 3}, {x, 7}}.
    {call, 8, {f, 745}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 10}, {x, 0}}.
    {move, {literal, [42]}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 17}}.
    {move, {y, 15}, {x, 0}}.
    {move, {y, 16}, {x, 1}}.
    {move, {y, 17}, {x, 2}}.
    {call_ext_last, 3, {extfunc, lists, foldl, 3}, 19}.
  {label, 761}.
    {move, {y, 9}, {x, 0}}.
    {test, is_nonempty_list, {f, 771}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 13}, {y, 14}}.
    {move, {y, 13}, {y, 6}}.
    {move, {y, 14}, {y, 5}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 15}, {x, 0}}.
    {test, is_eq_exact, {f, 773}, [{x, 0}, {atom, false}]}.
    {move, {y, 10}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {y, 7}}.
    {jump, {f, 775}}.
  {label, 775}.
    {move, {y, 11}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 0}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {y, 8}}.
    {jump, {f, 777}}.
  {label, 777}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 779}, [{x, 0}, nil]}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, file, read_link_info, 1}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {test, is_tuple, {f, 781}, [{x, 0}]}.
    {test, test_arity, {f, 781}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 17}}.
    {move, {y, 17}, {x, 0}}.
    {test, is_eq_exact, {f, 781}, [{x, 0}, {atom, ok}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 8}, {y, 12}, {x, 0}}.
    {move, {x, 0}, {y, 18}}.
    {move, {y, 18}, {x, 0}}.
    {deallocate, 19}.
    return.
  {label, 781}.
    {move, {y, 12}, {x, 0}}.
    {deallocate, 19}.
    return.
  {label, 779}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, filelib, is_dir, 1}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {test, is_eq_exact, {f, 785}, [{x, 0}, {atom, true}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {move, {y, 8}, {x, 2}}.
    {move, {y, 12}, {x, 3}}.
    {move, {y, 0}, {x, 4}}.
    {move, {y, 1}, {x, 5}}.
    {move, {y, 2}, {x, 6}}.
    {move, {y, 3}, {x, 7}}.
    {call_last, 8, {f, 745}, 19}.
  {label, 785}.
    {move, {y, 16}, {x, 0}}.
    {test, is_eq_exact, {f, 786}, [{x, 0}, {atom, false}]}.
    {move, {y, 12}, {x, 0}}.
    {deallocate, 19}.
    return.
  {label, 786}.
    {move, {y, 16}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 773}.
    {move, {y, 15}, {x, 0}}.
    {test, is_eq_exact, {f, 787}, [{x, 0}, {atom, true}]}.
    {test_heap, {alloc, [{words, 6}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 789}, 4, 0, {x, 0}, {list, [{y, 10}, {y, 0}, {y, 11}, {y, 5}, {y, 1}, {y, 4}]}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 10}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 17}}.
    {move, {y, 16}, {x, 0}}.
    {move, {y, 12}, {x, 1}}.
    {move, {y, 17}, {x, 2}}.
    {call_ext_last, 3, {extfunc, lists, foldl, 3}, 19}.
  {label, 787}.
    {move, {y, 15}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 771}.
    {move, {y, 9}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {move, {y, 11}, {x, 2}}.
    {move, {y, 12}, {x, 3}}.
    {move, {y, 0}, {x, 4}}.
    {move, {y, 1}, {x, 5}}.
    {move, {y, 2}, {x, 6}}.
    {move, {y, 3}, {x, 7}}.
    {deallocate, 19}.
    {jump, {f, 744}}.

{function, '__bp_tpl_14-t/2-fun-0-', 2, 676}.
  {label, 675}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_14-t/2-fun-0-'}, 2}.
  {label, 676}.
    {allocate, 16, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {x, 1}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 0}}.
    {jump, {f, 680}}.
  {label, 680}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 1}}.
    {jump, {f, 682}}.
  {label, 682}.
    {move, nil, {y, 9}}.
    {move, {y, 1}, {x, 0}}.
    {move, {literal, [47]}, {x, 1}}.
    {move, {atom, all}, {x, 2}}.
    {call_ext, 3, {extfunc, string, split, 3}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {y, 10}}.
  {label, 684}.
    {move, {y, 10}, {x, 0}}.
    {test, is_nonempty_list, {f, 685}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 12}, {y, 10}}.
    {move, {y, 12}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, nil, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {test, is_eq_exact, {f, 687}, [{x, 0}, {atom, true}]}.
    {jump, {f, 689}}.
  {label, 687}.
    {move, {y, 13}, {x, 0}}.
    {test, is_eq_exact, {f, 688}, [{x, 0}, {atom, false}]}.
    {jump, {f, 684}}.
  {label, 688}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_filter}, {y, 13}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 689}.
    {move, {y, 2}, {x, 0}}.
    {move, {literal, [46]}, {x, 1}}.
    {test, is_ne_exact, {f, 684}, [{x, 0}, {x, 1}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, {y, 9}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {jump, {f, 684}}.
  {label, 685}.
    {move, {y, 10}, {x, 0}}.
    {test, is_nil, {f, 686}, [{x, 0}]}.
    {jump, {f, 683}}.
  {label, 686}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 10}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 683}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 2}}.
    {jump, {f, 691}}.
  {label, 691}.
    {move, {literal, [47]}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, suffix, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 1}}.
    {jump, {f, 693}}.
  {label, 693}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 695}, 5, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 3}}.
    {jump, {f, 702}}.
  {label, 702}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 704}, 6, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 712}}.
  {label, 712}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 714}, 7, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 5}}.
    {jump, {f, 736}}.
  {label, 736}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 738}, 8, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 6}}.
    {jump, {f, 743}}.
  {label, 743}.
    {test_heap, {alloc, [{words, 4}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 745}, 1, 0, {x, 0}, {list, [{y, 6}, {y, 3}, {y, 5}, {y, 4}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 803}}.
  {label, 803}.
    {move, nil, {y, 9}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {move, nil, {x, 2}}.
    {move, nil, {x, 3}}.
    {move, {y, 4}, {x, 4}}.
    {call_fun, 4}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, usort, 1}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {y, 10}}.
  {label, 805}.
    {move, {y, 10}, {x, 0}}.
    {test, is_nonempty_list, {f, 806}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 12}, {y, 10}}.
    {move, {y, 12}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, 'not', 1}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {x, 0}}.
    {test, is_eq_exact, {f, 808}, [{x, 0}, {atom, false}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 15}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 15}, {y, 13}}.
    {jump, {f, 810}}.
  {label, 808}.
    {move, {y, 14}, {x, 0}}.
    {test, is_eq_exact, {f, 809}, [{x, 0}, {atom, true}]}.
    {move, {atom, true}, {y, 13}}.
    {jump, {f, 810}}.
  {label, 809}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 14}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 810}.
    {move, {y, 13}, {x, 0}}.
    {test, is_eq_exact, {f, 811}, [{x, 0}, {atom, true}]}.
    {jump, {f, 813}}.
  {label, 811}.
    {move, {y, 13}, {x, 0}}.
    {test, is_eq_exact, {f, 812}, [{x, 0}, {atom, false}]}.
    {jump, {f, 805}}.
  {label, 812}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_filter}, {y, 13}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 813}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 13}}.
    {test_heap, 2, 0}.
    {put_list, {y, 13}, {y, 9}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {jump, {f, 805}}.
  {label, 806}.
    {move, {y, 10}, {x, 0}}.
    {test, is_nil, {f, 807}, [{x, 0}]}.
    {jump, {f, 804}}.
  {label, 807}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 10}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 804}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {deallocate, 16}.
    return.

{function, '__bp_tpl_14', 2, 672}.
  {label, 671}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_14'}, 2}.
  {label, 672}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 676}, 9, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_15-t/1-fun-0-', 1, 821}.
  {label, 820}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_15-t/1-fun-0-'}, 1}.
  {label, 821}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {literal, [read, binary, read_ahead]}, {x, 1}}.
    {call_ext, 2, {extfunc, file, open, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 825}, [{x, 0}]}.
    {test, test_arity, {f, 825}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 825}, [{x, 0}, {atom, ok}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 825}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 826}, [{x, 0}]}.
    {test, test_arity, {f, 826}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 826}, [{x, 0}, {atom, error}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 826}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_15', 1, 815}.
  {label, 814}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_15'}, 1}.
  {label, 815}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 818}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 821}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 828}, [{x, 0}]}.
    {test, test_arity, {f, 828}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 828}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 827}}.
  {label, 828}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 829}, [{x, 0}]}.
    {test, test_arity, {f, 829}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 829}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 827}}.
  {label, 829}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 827}}.
  {label, 827}.
    {jump, {f, 819}}.
  {label, 818}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 834}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 833}}.
  {label, 834}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 835}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 833}}.
  {label, 835}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 836}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 833}}.
  {label, 836}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 833}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 831}}.
  {label, 831}.
  {label, 819}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_tpl_16-t/1-fun-0-', 1, 846}.
  {label, 845}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_16-t/1-fun-0-'}, 1}.
  {label, 846}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {literal, [write, binary, raw]}, {x, 1}}.
    {call_ext, 2, {extfunc, file, open, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 850}, [{x, 0}]}.
    {test, test_arity, {f, 850}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 850}, [{x, 0}, {atom, ok}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 850}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 851}, [{x, 0}]}.
    {test, test_arity, {f, 851}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 851}, [{x, 0}, {atom, error}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 851}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_16', 1, 840}.
  {label, 839}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_16'}, 1}.
  {label, 840}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 843}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 846}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 853}, [{x, 0}]}.
    {test, test_arity, {f, 853}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 853}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 852}}.
  {label, 853}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 854}, [{x, 0}]}.
    {test, test_arity, {f, 854}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 854}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 852}}.
  {label, 854}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 852}}.
  {label, 852}.
    {jump, {f, 844}}.
  {label, 843}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 859}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 858}}.
  {label, 859}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 860}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 858}}.
  {label, 860}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 861}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 858}}.
  {label, 861}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 858}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 856}}.
  {label, 856}.
  {label, 844}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '-bp_field-', 2, 865}.
  {label, 864}.
    {line, [{location, "std@io@fs.erl", 43}]}.
    {func_info, {atom, std@io@fs}, {atom, '-bp_field-'}, 2}.
  {label, 865}.
    {test, is_map, {f, 866}, [{x, 0}]}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    {move, {atom, undefined}, {x, 2}}.
    {call_ext_only, 3, {extfunc, maps, get, 3}}.
  {label, 866}.
    {test, is_tuple, {f, 867}, [{x, 0}]}.
    {bif, element, {f, 869}, [{integer, 1}, {x, 0}], {x, 2}}.
    {test, is_atom, {f, 869}, [{x, 2}]}.
    {test_heap, 4, 3}.
    {put_list, {x, 1}, nil, {x, 3}}.
    {put_list, {x, 0}, {x, 3}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {atom, '__bp_get'}, {x, 1}}.
    {move, {x, 3}, {x, 2}}.
    {call_ext_only, 3, {extfunc, erlang, apply, 3}}.
  {label, 867}.
    {test, is_eq_exact, {f, 869}, [{x, 1}, {atom, length}]}.
    {test, is_list, {f, 868}, [{x, 0}]}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    return.
  {label, 868}.
    {test, is_binary, {f, 869}, [{x, 0}]}.
    {allocate, 0, 1}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 869}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_tpl_17', 1, 871}.
  {label, 870}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_17'}, 1}.
  {label, 871}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, nil, {x, 1}}.
    {call_ext, 2, {extfunc, counters, new, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, mem}, {y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_18', 0, 897}.
  {label, 896}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_18'}, 0}.
  {label, 897}.
    {allocate, 0, 0}.
    {move, {atom, wasm_only}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 0}.

{function, '__bp_tpl_19', 1, 912}.
  {label, 911}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_19'}, 1}.
  {label, 912}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_20', 1, 914}.
  {label, 913}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_20'}, 1}.
  {label, 914}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, byte_size, 1}, 1}.

{function, '__bp_tpl_21', 2, 924}.
  {label, 923}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_21'}, 2}.
  {label, 924}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {atom, wasm_only}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.

{function, '__bp_tpl_22', 1, 965}.
  {label, 964}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_22'}, 1}.
  {label, 965}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, wasm_only}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 1}.

{function, '__bp_tpl_23-t/1-fun-0-', 1, 1021}.
  {label, 1020}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_23-t/1-fun-0-'}, 1}.
  {label, 1021}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, -9223372036854775807}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {gc_bif, '-', {f, 1023}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test, is_ge, {f, 1023}, [{x, 0}, {x, 1}]}.
    {move, {integer, 9223372036854775807}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test, is_ge, {f, 1023}, [{x, 0}, {x, 1}]}.
    {jump, {f, 1024}}.
  {label, 1024}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 1023}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 1026}, [{x, 0}]}.
    {test_heap, 6, 0}.
    {put_list, {literal, <<" does not fit i64">>}, nil, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"toI64: ">>}, {x, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 1027}}.
  {label, 1026}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1027}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, integer_overflow}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.

{function, '__bp_tpl_23', 1, 1017}.
  {label, 1016}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_23'}, 1}.
  {label, 1017}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 1021}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_24-t/2-fun-0-', 2, 1135}.
  {label, 1134}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_24-t/2-fun-0-'}, 2}.
  {label, 1135}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 1137}, [{x, 0}, {literal, <<"">>}]}.
    {move, nil, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {test, is_list, {f, 1139}, [{x, 0}]}.
    {jump, {f, 1140}}.
  {label, 1139}.
    {test, is_tuple, {f, 1141}, [{x, 0}]}.
    {test, test_arity, {f, 1141}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 1140}}.
  {label, 1141}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 1}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1140}.
    {move, {x, 0}, {y, 4}}.
  {label, 1142}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 1143}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 4}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 1145}, [{x, 0}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {test, is_binary, {f, 1145}, [{x, 0}]}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 1146}}.
  {label, 1145}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1146}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 1142}}.
  {label, 1143}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nil, {f, 1144}, [{x, 0}]}.
    {jump, {f, 1138}}.
  {label, 1144}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1138}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 1137}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {atom, all}, {x, 2}}.
    {call_ext_last, 3, {extfunc, string, split, 3}, 7}.

{function, '__bp_tpl_24', 2, 1131}.
  {label, 1130}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_24'}, 2}.
  {label, 1131}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 1135}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_25', 1, 1251}.
  {label, 1250}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_25'}, 1}.
  {label, 1251}.
    {allocate, 7, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, utf8}, {x, 1}}.
    {call_ext, 2, {extfunc, unicode, characters_to_list, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
  {label, 1255}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nonempty_list, {f, 1256}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 3}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 1258}, [{x, 0}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {test, is_binary, {f, 1258}, [{x, 0}]}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 1259}}.
  {label, 1258}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1259}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 2}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 1255}}.
  {label, 1256}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nil, {f, 1257}, [{x, 0}]}.
    {jump, {f, 1254}}.
  {label, 1257}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 3}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1254}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 7}.
    return.

{function, '__bp_add', 2, 1320}.
  {label, 1319}.
    {line, [{location, "std@io@fs.erl", 82}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_add'}, 2}.
  {label, 1320}.
    {test, is_binary, {f, 1321}, [{x, 0}]}.
    {test, is_binary, {f, 1321}, [{x, 1}]}.
    {test_heap, 4, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call_ext_only, 1, {extfunc, erlang, iolist_to_binary, 1}}.
  {label, 1321}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    return.

{function, '__bp_tpl_26-t/2-fun-0-', 2, 1409}.
  {label, 1408}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_26-t/2-fun-0-'}, 2}.
  {label, 1409}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, utf8}, {x, 1}}.
    {call_ext, 2, {extfunc, unicode, characters_to_list, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 1413}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test, is_lt, {f, 1413}, [{x, 0}, {x, 1}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {test, is_ge, {f, 1413}, [{x, 0}, {x, 1}]}.
    {jump, {f, 1414}}.
  {label, 1414}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 5}.
  {label, 1413}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '__bp_tpl_26', 2, 1405}.
  {label, 1404}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_26'}, 2}.
  {label, 1405}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 1409}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_27-t/2-fun-0-', 2, 1600}.
  {label, 1599}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_27-t/2-fun-0-'}, 2}.
  {label, 1600}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 1604}}.
  {label, 1604}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 1606}}.
  {label, 1606}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=<', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 1607}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, binary, part, 3}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 4}}.
    {jump, {f, 1609}}.
  {label, 1607}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 1608}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 4}}.
    {jump, {f, 1609}}.
  {label, 1608}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 5}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1609}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.

{function, '__bp_tpl_27', 2, 1596}.
  {label, 1595}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_27'}, 2}.
  {label, 1596}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 1600}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_28', 1, 1680}.
  {label, 1679}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_28'}, 1}.
  {label, 1680}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.

{function, '__bp_tpl_29-t/0-fun-0-', 0, 1701}.
  {label, 1700}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_29-t/0-fun-0-'}, 0}.
  {label, 1701}.
    {allocate, 3, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {literal, [84, 77, 80, 68, 73, 82]}, {x, 0}}.
    {call_ext, 1, {extfunc, os, getenv, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 1705}, [{x, 0}, {atom, false}]}.
    {move, {literal, [47, 116, 109, 112]}, {y, 2}}.
    {jump, {f, 1704}}.
  {label, 1705}.
    {move, {y, 1}, {y, 0}}.
    {move, {y, 0}, {y, 2}}.
    {jump, {f, 1704}}.
  {label, 1704}.
    {move, {y, 2}, {y, 0}}.
    {jump, {f, 1708}}.
  {label, 1708}.
    {move, {literal, [positive]}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, unique_integer, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, [98, 112, 45, 115, 116, 100, 45, 102, 115, 45]}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {y, 0}}.
    {jump, {f, 1710}}.
  {label, 1710}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, file, make_dir, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 1711}, [{x, 0}, {atom, ok}]}.
    {jump, {f, 1712}}.
  {label, 1711}.
    {move, {y, 1}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 1712}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 3}.

{function, '__bp_tpl_29', 0, 1697}.
  {label, 1696}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_29'}, 0}.
  {label, 1697}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 1701}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_30-t/0-fun-0-', 0, 1720}.
  {label, 1719}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_30-t/0-fun-0-'}, 0}.
  {label, 1720}.
    {allocate, 4, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {call_ext, 0, {extfunc, file, get_cwd, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 1723}, [{x, 0}]}.
    {test, test_arity, {f, 1723}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 2}}.
    {get_tuple_element, {x, 0}, 1, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 1723}, [{x, 0}, {atom, ok}]}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 1724}}.
  {label, 1723}.
    {move, {y, 1}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 1724}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 4}.

{function, '__bp_tpl_30', 0, 1716}.
  {label, 1715}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_30'}, 0}.
  {label, 1716}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 1720}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_31-t/2-fun-0-', 2, 1743}.
  {label, 1742}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_31-t/2-fun-0-'}, 2}.
  {label, 1743}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, file, make_symlink, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 1746}, [{x, 0}, {atom, ok}]}.
    {jump, {f, 1747}}.
  {label, 1746}.
    {move, {y, 2}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 1747}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_31', 2, 1739}.
  {label, 1738}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_31'}, 2}.
  {label, 1739}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 1743}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_32-t/3-fun-0-', 3, 1759}.
  {label, 1758}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_32-t/3-fun-0-'}, 3}.
  {label, 1759}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 1763}}.
  {label, 1763}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 1}}.
    {jump, {f, 1765}}.
  {label, 1765}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 1767}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 1766}}.
  {label, 1767}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 1768}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 1766}}.
  {label, 1768}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 1766}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 1770}}.
  {label, 1770}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 1772}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 1771}}.
  {label, 1772}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 1773}, [{x, 0}, {atom, false}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 1771}}.
  {label, 1773}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 1771}.
    {move, {y, 7}, {y, 1}}.
    {jump, {f, 1775}}.
  {label, 1775}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 7}, {x, 2}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 9}.

{function, '__bp_tpl_32', 3, 1755}.
  {label, 1754}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_32'}, 3}.
  {label, 1755}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 1759}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_33-t/2-fun-0-', 2, 1781}.
  {label, 1780}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_33-t/2-fun-0-'}, 2}.
  {label, 1781}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 1785}}.
  {label, 1785}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 1787}}.
  {label, 1787}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 1789}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 1788}}.
  {label, 1789}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 1790}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 1788}}.
  {label, 1790}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 1788}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 1792}}.
  {label, 1792}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 7}.

{function, '__bp_tpl_33', 2, 1777}.
  {label, 1776}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_33'}, 2}.
  {label, 1777}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 1781}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_34-t/3-fun-0-', 3, 1799}.
  {label, 1798}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_34-t/3-fun-0-'}, 3}.
  {label, 1799}.
    {allocate, 8, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {x, 2}, {y, 4}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 0}}.
    {jump, {f, 1803}}.
  {label, 1803}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 1805}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 6}}.
    {jump, {f, 1804}}.
  {label, 1805}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 1806}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 6}}.
    {jump, {f, 1804}}.
  {label, 1806}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 1804}.
    {move, {y, 6}, {y, 1}}.
    {jump, {f, 1808}}.
  {label, 1808}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 1810}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 6}}.
    {jump, {f, 1809}}.
  {label, 1810}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 1811}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 6}}.
    {jump, {f, 1809}}.
  {label, 1811}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 1809}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 1813}}.
  {label, 1813}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 5}, {x, 2}}.
    {call_ext_last, 3, {extfunc, binary, part, 3}, 8}.

{function, '__bp_tpl_34', 3, 1795}.
  {label, 1794}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_34'}, 3}.
  {label, 1795}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 1799}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_35-t/2-fun-0-', 2, 1819}.
  {label, 1818}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_35-t/2-fun-0-'}, 2}.
  {label, 1819}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 1823}}.
  {label, 1823}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 1825}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 1824}}.
  {label, 1825}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 1826}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 1824}}.
  {label, 1826}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 1824}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 1828}}.
  {label, 1828}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 4}, {x, 2}}.
    {call_ext_last, 3, {extfunc, binary, part, 3}, 7}.

{function, '__bp_tpl_35', 2, 1815}.
  {label, 1814}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_tpl_35'}, 2}.
  {label, 1815}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 1819}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_prim_append', 2, 199}.
  {label, 198}.
    {line, [{location, "std@io@fs.erl", 107}]}.
    {func_info, {atom, std@io@fs}, {atom, '__bp_prim_append'}, 2}.
  {label, 199}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 1829}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 1829}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@io@fs@@FsError.S
```erlang
{module, std@io@fs@@FsError}.
{exports, [{message, 1}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 53}.

{function, message, 1, 3}.
  {label, 2}.
    {line, [{location, "std@io@fs@@FsError.erl", 3}]}.
    {func_info, {atom, std@io@fs@@FsError}, {atom, message}, 1}.
  {label, 3}.
    {allocate, 17, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 5}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__notfound}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"not found: ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 4}}.
  {label, 5}.
    {test, is_tagged_tuple, {f, 38}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__permissiondenied}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"permission denied: ">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 4}}.
  {label, 38}.
    {test, is_tagged_tuple, {f, 39}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__isdirectory}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 5}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"is a directory: ">>}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 4}}.
  {label, 39}.
    {test, is_tagged_tuple, {f, 40}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__notdirectory}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 7}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, <<"not a directory: ">>}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 4}}.
  {label, 40}.
    {test, is_tagged_tuple, {f, 41}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__alreadyexists}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 9}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 9}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, <<"already exists: ">>}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 4}}.
  {label, 41}.
    {test, is_tagged_tuple, {f, 42}, [{x, 0}, 3, {atom, std@io@fs@@FsError__v__invalidutf8}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 11}}.
    {get_tuple_element, {x, 0}, 2, {x, 1}}.
    {move, {x, 1}, {y, 12}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 12}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 13}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {literal, <<" at byte ">>}, {x, 0}}.
    {move, {y, 13}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 11}, {x, 0}}.
    {move, {y, 13}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {literal, <<"not UTF-8: ">>}, {x, 0}}.
    {move, {y, 13}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 4}}.
  {label, 42}.
    {test, is_tagged_tuple, {f, 43}, [{x, 0}, 3, {atom, std@io@fs@@FsError__v__other}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 14}}.
    {get_tuple_element, {x, 0}, 2, {x, 1}}.
    {move, {x, 1}, {y, 15}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 15}, {x, 0}}.
    {move, {y, 16}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 16}}.
    {move, {literal, <<": ">>}, {x, 0}}.
    {move, {y, 16}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 14}, {x, 0}}.
    {move, {y, 16}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 4}}.
  {label, 43}.
    {case_end, {x, 0}}.
  {label, 4}.
    {deallocate, 17}.
    return.

{function, '__bp_format', 1, 45}.
  {label, 44}.
    {line, [{location, "std@io@fs@@FsError.erl", 4}]}.
    {func_info, {atom, std@io@fs@@FsError}, {atom, '__bp_format'}, 1}.
  {label, 45}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 46}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__notfound}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"path">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"FsError.NotFound">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 46}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 47}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__permissiondenied}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"path">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"FsError.PermissionDenied">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 47}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 48}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__isdirectory}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"path">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"FsError.IsDirectory">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 48}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 49}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__notdirectory}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"path">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"FsError.NotDirectory">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 49}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 50}, [{x, 0}, 2, {atom, std@io@fs@@FsError__v__alreadyexists}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"path">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"FsError.AlreadyExists">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 50}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 51}, [{x, 0}, 3, {atom, std@io@fs@@FsError__v__invalidutf8}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"offset">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"path">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"FsError.InvalidUtf8">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 51}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 52}, [{x, 0}, 3, {atom, std@io@fs@@FsError__v__other}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"message">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"path">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"FsError.Other">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 52}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"FsError">>}, nil]}}.
    {deallocate, 2}.
    return.

{function, '__bp_print', 1, 7}.
  {label, 6}.
    {line, [{location, "std@io@fs@@FsError.erl", 4}]}.
    {func_info, {atom, std@io@fs@@FsError}, {atom, '__bp_print'}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 11}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 11}.
  {label, 10}.
    {line, [{location, "std@io@fs@@FsError.erl", 4}]}.
    {func_info, {atom, std@io@fs@@FsError}, {atom, '-bp_show_top-'}, 1}.
  {label, 11}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 9}}.

{function, '-bp_show_elem-', 1, 13}.
  {label, 12}.
    {line, [{location, "std@io@fs@@FsError.erl", 4}]}.
    {func_info, {atom, std@io@fs@@FsError}, {atom, '-bp_show_elem-'}, 1}.
  {label, 13}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 9}}.

{function, '__bp_show', 2, 9}.
  {label, 8}.
    {line, [{location, "std@io@fs@@FsError.erl", 4}]}.
    {func_info, {atom, std@io@fs@@FsError}, {atom, '__bp_show'}, 2}.
  {label, 9}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 21}, [{x, 0}]}.
    {test, is_eq, {f, 20}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 20}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 21}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 22}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 13}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 93}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 91}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 22}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 24}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 23}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 23}, [{x, 0}]}.
    {test, is_ne_exact, {f, 23}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 23}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 23}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 28}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 29}}.
  {label, 28}.
    {test, is_eq_exact, {f, 25}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 29}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 9}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 23}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 13}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 40}, {x, 0}, {x, 0}}.
    {put_list, {integer, 35}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 24}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 26}, [{x, 0}]}.
    {test, is_ne_exact, {f, 26}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 26}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 27}, [{x, 0}, {atom, undefined}]}.
  {label, 25}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 15}, 2}.
  {label, 26}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 27}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 15}.
  {label, 14}.
    {line, [{location, "std@io@fs@@FsError.erl", 4}]}.
    {func_info, {atom, std@io@fs@@FsError}, {atom, '__bp_tagged'}, 2}.
  {label, 15}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 30}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 30}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 30}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 31}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 17}, 3}.
  {label, 31}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 17}.
  {label, 16}.
    {line, [{location, "std@io@fs@@FsError.erl", 4}]}.
    {func_info, {atom, std@io@fs@@FsError}, {atom, '__bp_render'}, 1}.
  {label, 17}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 32}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 33}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 33}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 19}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {y, 1}, {x, 1}, {x, 1}}.
    {put_list, {integer, 40}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_render_pair-', 1, 19}.
  {label, 18}.
    {line, [{location, "std@io@fs@@FsError.erl", 4}]}.
    {func_info, {atom, std@io@fs@@FsError}, {atom, '-bp_render_pair-'}, 1}.
  {label, 19}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 9}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 6, 1}.
    {put_list, {y, 1}, nil, {x, 1}}.
    {put_list, {literal, <<": ">>}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_stringify-', 1, 35}.
  {label, 34}.
    {line, [{location, "std@io@fs@@FsError.erl", 4}]}.
    {func_info, {atom, std@io@fs@@FsError}, {atom, '-bp_stringify-'}, 1}.
  {label, 35}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 36}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 36}.
    {test, is_integer, {f, 37}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 37}.
    {call, 1, {f, 11}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.
```

----- BEAM ASSEMBLY -- std@io@fs@@FileStat.S
```erlang
{module, std@io@fs@@FileStat}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 9}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "std@io@fs@@FileStat.erl", 4}]}.
    {func_info, {atom, std@io@fs@@FileStat}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, size}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {test, is_eq_exact, {f, 5}, [{x, 1}, {atom, mtime}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 5}.
    {test, is_eq_exact, {f, 6}, [{x, 1}, {atom, isDir}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 6}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 8}.
  {label, 7}.
    {line, [{location, "std@io@fs@@FileStat.erl", 4}]}.
    {func_info, {atom, std@io@fs@@FileStat}, {atom, '__bp_format'}, 1}.
  {label, 8}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"isDir">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"mtime">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"size">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"FileStat">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@io@fs@@Walked.S
```erlang
{module, std@io@fs@@Walked}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 8}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "std@io@fs@@Walked.erl", 16}]}.
    {func_info, {atom, std@io@fs@@Walked}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, files}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {test, is_eq_exact, {f, 5}, [{x, 1}, {atom, dangling}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 5}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 7}.
  {label, 6}.
    {line, [{location, "std@io@fs@@Walked.erl", 16}]}.
    {func_info, {atom, std@io@fs@@Walked}, {atom, '__bp_format'}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"dangling">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"files">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Walked">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@io@fs@@File.S
```erlang
{module, std@io@fs@@File}.
{exports, [{path, 1}, {size, 1}, {read, 2}, {bytes, 1}, {text, 1}, {chunks, 2}, {lines, 1}, {hash, 1}, {write, 2}, {close, 1}, {'__bp_get', 2}, {'__bp_format', 1}, {'__bp_behaviors', 0}]}.
{attributes, []}.
{labels, 495}.

{function, path, 1, 3}.
  {label, 2}.
    {line, [{location, "std@io@fs@@File.erl", 30}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, path}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 22}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 22}.
    {deallocate, 1}.
    return.

{function, size, 1, 5}.
  {label, 4}.
    {line, [{location, "std@io@fs@@File.erl", 31}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, size}, 1}.
  {label, 5}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 23}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 23}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 50}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 50}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 51}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 51}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 25}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, std@io@fs, liftI64, 2}}.
    {test, is_tagged_tuple, {f, 52}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 53}}.
  {label, 52}.
    {deallocate, 4}.
    return.
  {label, 53}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, read, 2, 7}.
  {label, 6}.
    {line, [{location, "std@io@fs@@File.erl", 32}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, read}, 2}.
  {label, 7}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 54}, [{integer, 0}, {y, 1}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {call, 1, {f, 56}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 5}.
    return.
  {label, 54}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 57}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 57}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 89}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 89}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 59}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, std@io@fs, liftBytes, 2}}.
    {test, is_tagged_tuple, {f, 90}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 91}}.
  {label, 90}.
    {deallocate, 5}.
    return.
  {label, 91}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 5}.
    return.

{function, bytes, 1, 9}.
  {label, 8}.
    {line, [{location, "std@io@fs@@File.erl", 33}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, bytes}, 1}.
  {label, 9}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 92}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 92}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 126}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 126}.
    {call, 1, {f, 94}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, std@io@fs, liftBytes, 2}}.
    {test, is_tagged_tuple, {f, 127}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 128}}.
  {label, 127}.
    {deallocate, 4}.
    return.
  {label, 128}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, text, 1, 11}.
  {label, 10}.
    {line, [{location, "std@io@fs@@File.erl", 34}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, text}, 1}.
  {label, 11}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 9}}.
    {test, is_tagged_tuple, {f, 129}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 130}}.
  {label, 129}.
    {deallocate, 3}.
    return.
  {label, 130}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 131}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 131}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, std@io@fs, decode, 2}}.
    {test, is_tagged_tuple, {f, 132}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 133}}.
  {label, 132}.
    {deallocate, 3}.
    return.
  {label, 133}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.

{function, chunks, 2, 13}.
  {label, 12}.
    {line, [{location, "std@io@fs@@File.erl", 35}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, chunks}, 2}.
  {label, 13}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 135}, 0, 0, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {call, 1, {f, 199}}.
    {deallocate, 4}.
    return.

{function, lines, 1, 15}.
  {label, 14}.
    {line, [{location, "std@io@fs@@File.erl", 36}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, lines}, 1}.
  {label, 15}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 270}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 199}}.
    {deallocate, 12}.
    return.

{function, hash, 1, 17}.
  {label, 16}.
    {line, [{location, "std@io@fs@@File.erl", 37}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, hash}, 1}.
  {label, 17}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 381}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 381}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 421}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 421}.
    {call, 1, {f, 383}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, std@io@fs, liftString, 2}}.
    {test, is_tagged_tuple, {f, 422}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 423}}.
  {label, 422}.
    {deallocate, 4}.
    return.
  {label, 423}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, write, 2, 19}.
  {label, 18}.
    {line, [{location, "std@io@fs@@File.erl", 38}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, write}, 2}.
  {label, 19}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 431}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 431}.
    {call, 1, {f, 426}}.
    {test, is_eq, {f, 424}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 432}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 432}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"the file is open for reading">>}, {x, 0}}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@FsError__v__other}, {x, 1}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 5}.
    return.
  {label, 424}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 433}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 433}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 457}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 457}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 435}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, std@io@fs, liftI32, 2}}.
    {test, is_tagged_tuple, {f, 458}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 459}}.
  {label, 458}.
    {deallocate, 5}.
    return.
  {label, 459}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 5}.
    return.

{function, close, 1, 21}.
  {label, 20}.
    {line, [{location, "std@io@fs@@File.erl", 39}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, close}, 1}.
  {label, 21}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 486}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 486}.
    {call, 1, {f, 461}}.
    {move, {x, 0}, {y, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_get', 2, 488}.
  {label, 487}.
    {line, [{location, "std@io@fs@@File.erl", 40}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_get'}, 2}.
  {label, 488}.
    {test, is_eq_exact, {f, 489}, [{x, 1}, {atom, location}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 489}.
    {test, is_eq_exact, {f, 490}, [{x, 1}, {atom, handle}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 490}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 492}.
  {label, 491}.
    {line, [{location, "std@io@fs@@File.erl", 40}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_format'}, 1}.
  {label, 492}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"handle">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"location">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"File">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '__bp_behaviors', 0, 494}.
  {label, 493}.
    {line, [{location, "std@io@fs@@File.erl", 40}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_behaviors'}, 0}.
  {label, 494}.
    {move, {literal, [std@primitives@@Closeable]}, {x, 0}}.
    return.

{function, '__bp_tpl_0-t/2-fun-0-', 2, 31}.
  {label, 30}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_0-t/2-fun-0-'}, 2}.
  {label, 31}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 35}, [{x, 0}]}.
    {test, test_arity, {f, 35}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 35}, [{x, 0}, {atom, mem}]}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 5}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 5}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 35}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, file, read_file_info, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 38}, [{x, 0}]}.
    {test, test_arity, {f, 38}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 38}, [{x, 0}, {atom, ok}]}.
    {move, {y, 5}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 6}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 38}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 39}, [{x, 0}]}.
    {test, test_arity, {f, 39}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 39}, [{x, 0}, {atom, error}]}.
    {move, {y, 5}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 39}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_0', 2, 25}.
  {label, 24}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_0'}, 2}.
  {label, 25}.
    {allocate, 13, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {'try', {y, 12}, {f, 28}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 31}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {y, 6}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 7}}.
    {try_end, {y, 12}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 41}, [{x, 0}]}.
    {test, test_arity, {f, 41}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 41}, [{x, 0}, {atom, ok}]}.
    {move, {y, 9}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 5}}.
    {jump, {f, 40}}.
  {label, 41}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 42}, [{x, 0}]}.
    {test, test_arity, {f, 42}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 42}, [{x, 0}, {atom, error}]}.
    {move, {y, 9}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 10}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 10}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 5}}.
    {jump, {f, 40}}.
  {label, 42}.
    {move, {y, 7}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 5}}.
    {jump, {f, 40}}.
  {label, 40}.
    {jump, {f, 29}}.
  {label, 28}.
    {try_case, {y, 12}}.
    {move, {x, 0}, {y, 6}}.
    {move, {x, 1}, {y, 7}}.
    {move, {x, 2}, {y, 8}}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 8}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 47}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 10}}.
    {jump, {f, 46}}.
  {label, 47}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 48}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 10}}.
    {jump, {f, 46}}.
  {label, 48}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 49}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 10}}.
    {jump, {f, 46}}.
  {label, 49}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 46}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 11}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 5}}.
    {jump, {f, 44}}.
  {label, 44}.
  {label, 29}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 13}.
    return.

{function, '__bp_tpl_1', 1, 56}.
  {label, 55}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_1'}, 1}.
  {label, 56}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_2-t/2-fun-0-', 2, 65}.
  {label, 64}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_2-t/2-fun-0-'}, 2}.
  {label, 65}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {x, 1}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 69}, [{x, 0}]}.
    {test, test_arity, {f, 69}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {y, 7}}.
    {get_tuple_element, {x, 0}, 2, {y, 8}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 69}, [{x, 0}, {atom, mem}]}.
    {move, {y, 7}, {y, 0}}.
    {move, {y, 8}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, counters, get, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 2}}.
    {jump, {f, 71}}.
  {label, 71}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 3}}.
    {jump, {f, 73}}.
  {label, 73}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {move, {y, 3}, {x, 2}}.
    {call_ext, 3, {extfunc, counters, add, 3}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {y, 3}, {x, 2}}.
    {call_ext, 3, {extfunc, binary, part, 3}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 69}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, file, read, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 76}, [{x, 0}]}.
    {test, test_arity, {f, 76}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 76}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 76}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 77}, [{x, 0}, {atom, eof}]}.
    {move, {literal, {ok, <<"">>}}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 77}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 78}, [{x, 0}]}.
    {test, test_arity, {f, 78}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 78}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 78}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_2', 2, 59}.
  {label, 58}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_2'}, 2}.
  {label, 59}.
    {allocate, 13, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {'try', {y, 12}, {f, 62}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 65}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {y, 6}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 7}}.
    {try_end, {y, 12}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 80}, [{x, 0}]}.
    {test, test_arity, {f, 80}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 80}, [{x, 0}, {atom, ok}]}.
    {move, {y, 9}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 5}}.
    {jump, {f, 79}}.
  {label, 80}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 81}, [{x, 0}]}.
    {test, test_arity, {f, 81}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 81}, [{x, 0}, {atom, error}]}.
    {move, {y, 9}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 10}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 10}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 5}}.
    {jump, {f, 79}}.
  {label, 81}.
    {move, {y, 7}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 5}}.
    {jump, {f, 79}}.
  {label, 79}.
    {jump, {f, 63}}.
  {label, 62}.
    {try_case, {y, 12}}.
    {move, {x, 0}, {y, 6}}.
    {move, {x, 1}, {y, 7}}.
    {move, {x, 2}, {y, 8}}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 8}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 86}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 10}}.
    {jump, {f, 85}}.
  {label, 86}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 87}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 10}}.
    {jump, {f, 85}}.
  {label, 87}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 88}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 10}}.
    {jump, {f, 85}}.
  {label, 88}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 85}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 11}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 5}}.
    {jump, {f, 83}}.
  {label, 83}.
  {label, 63}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 13}.
    return.

{function, '__bp_tpl_3--t/1-fun-0--fun-1-', 2, 109}.
  {label, 108}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_3--t/1-fun-0--fun-1-'}, 2}.
  {label, 109}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 109}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 65536}, {x, 1}}.
    {call_ext, 2, {extfunc, file, read, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 113}, [{x, 0}]}.
    {test, test_arity, {f, 113}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 113}, [{x, 0}, {atom, ok}]}.
    {move, {y, 5}, {y, 1}}.
    {test_heap, 4, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {put_list, {y, 2}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 109}, 7}.
  {label, 113}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 114}, [{x, 0}, {atom, eof}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 4}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 114}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 115}, [{x, 0}]}.
    {test, test_arity, {f, 115}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 115}, [{x, 0}, {atom, error}]}.
    {move, {y, 5}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 1}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 115}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_3-t/1-fun-0-', 1, 100}.
  {label, 99}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_3-t/1-fun-0-'}, 1}.
  {label, 100}.
    {allocate, 8, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 104}, [{x, 0}]}.
    {test, test_arity, {f, 104}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {get_tuple_element, {x, 0}, 2, {y, 6}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 104}, [{x, 0}, {atom, mem}]}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, counters, get, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 106}}.
  {label, 106}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {move, {y, 7}, {x, 2}}.
    {call_ext, 3, {extfunc, counters, add, 3}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {y, 7}, {x, 2}}.
    {call_ext, 3, {extfunc, binary, part, 3}}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 7}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 104}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 109}, 0, 0, {x, 0}, {list, [{y, 3}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, nil, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 8}.
    return.

{function, '__bp_tpl_3', 1, 94}.
  {label, 93}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_3'}, 1}.
  {label, 94}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 97}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 100}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 117}, [{x, 0}]}.
    {test, test_arity, {f, 117}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 117}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 116}}.
  {label, 117}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 118}, [{x, 0}]}.
    {test, test_arity, {f, 118}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 118}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 116}}.
  {label, 118}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 116}}.
  {label, 116}.
    {jump, {f, 98}}.
  {label, 97}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 123}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 122}}.
  {label, 123}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 124}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 122}}.
  {label, 124}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 125}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 122}}.
  {label, 125}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 122}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 120}}.
  {label, 120}.
  {label, 98}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_tpl_4--t/1-fun-0--fun-1-', 1, 150}.
  {label, 149}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_4--t/1-fun-0--fun-1-'}, 1}.
  {label, 150}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 152}, [{x, 0}]}.
    {test, test_arity, {f, 152}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_self'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 153}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_mon'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 3}}.
    {jump, {f, 155}}.
  {label, 153}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 154}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 3}}.
    {jump, {f, 155}}.
  {label, 154}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 155}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 152}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 6}.
    {jump, {f, 149}}.

{function, '__bp_tpl_4-t/1-fun-0-', 0, 146}.
  {label, 145}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_4-t/1-fun-0-'}, 0}.
  {label, 146}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 150}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {call_ext, 0, {extfunc, erlang, get, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, filter, 2}, 2}.

{function, '__bp_tpl_4--t/1-fun-2--fun-3-', 1, 167}.
  {label, 166}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_4--t/1-fun-2--fun-3-'}, 1}.
  {label, 167}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 169}, [{x, 0}]}.
    {test, test_arity, {f, 169}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {y, 0}}.
    {move, {y, 4}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.
  {label, 169}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 5}.
    {jump, {f, 166}}.

{function, '__bp_tpl_4-t/1-fun-2-', 1, 159}.
  {label, 158}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_4-t/1-fun-2-'}, 1}.
  {label, 159}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 163}}.
  {label, 163}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 165}}.
  {label, 165}.
    {call_ext, 0, {extfunc, erlang, erase, 0}}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 167}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 171}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {y, 3}}.
    {jump, {f, 170}}.
  {label, 171}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
    {jump, {f, 170}}.
  {label, 170}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 174}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 174}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.

{function, '__bp_tpl_4-t/1-fun-4-', 3, 179}.
  {label, 178}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_4-t/1-fun-4-'}, 3}.
  {label, 179}.
    {allocate, 15, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 2}, {y, 1}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 182}, [{x, 0}]}.
    {test, test_arity, {f, 182}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {move, {y, 9}, {y, 2}}.
    {move, {y, 10}, {y, 3}}.
    {jump, {f, 183}}.
  {label, 182}.
    {move, {y, 8}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 183}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 3}, {atom, item}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, send, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 2}}.
    {jump, {f, 185}}.
  {label, 185}.
  {label, 186}.
    {loop_rec, {f, 187}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 190}, [{x, 0}]}.
    {test, test_arity, {f, 190}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {get_tuple_element, {x, 0}, 2, {y, 11}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 190}, [{x, 0}, {atom, 'DOWN'}]}.
    {move, {y, 10}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test, is_eq_exact, {f, 190}, [{x, 0}, {x, 1}]}.
    {move, {y, 11}, {x, 0}}.
    {test, is_eq_exact, {f, 190}, [{x, 0}, {atom, process}]}.
    remove_message.
    {move, {atom, '__bp_gen_closed'}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, throw, 1}, 15}.
  {label, 190}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 191}, [{x, 0}]}.
    {test, test_arity, {f, 191}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {get_tuple_element, {x, 0}, 2, {y, 11}}.
    {get_tuple_element, {x, 0}, 3, {y, 12}}.
    {get_tuple_element, {x, 0}, 4, {y, 13}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 191}, [{x, 0}, {atom, '__bp_gen'}]}.
    {move, {y, 10}, {y, 6}}.
    {move, {y, 11}, {y, 5}}.
    {move, {y, 12}, {y, 3}}.
    {move, {y, 13}, {y, 4}}.
    remove_message.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 14}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 5}, {y, 3}]}}.
    {move, {x, 0}, {y, 14}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {move, {y, 14}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 193}, [{x, 0}, {atom, next}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 15}.
    return.
  {label, 193}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 194}, [{x, 0}, {atom, close}]}.
    {move, {atom, '__bp_gen_closed'}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, throw, 1}, 15}.
  {label, 194}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 191}.
    {move, nil, {y, 8}}.
    {move, nil, {y, 3}}.
    {move, nil, {y, 4}}.
    {move, nil, {y, 5}}.
    {move, nil, {y, 6}}.
    {move, nil, {y, 9}}.
    {move, nil, {y, 10}}.
    {move, nil, {y, 11}}.
    {move, nil, {y, 12}}.
    {move, nil, {y, 13}}.
    {move, nil, {y, 14}}.
    {loop_rec_end, {f, 186}}.
  {label, 187}.
    {wait, {f, 186}}.

{function, '__bp_tpl_4', 1, 142}.
  {label, 141}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_4'}, 1}.
  {label, 142}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 146}, 2, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 157}}.
  {label, 157}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 159}, 3, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 177}}.
  {label, 177}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 179}, 4, 0, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 196}}.
  {label, 196}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 4}.
    return.

{function, '-glob/2-gen-0-', 2, 135}.
  {label, 134}.
    {line, [{location, "std@io@fs@@File.erl", 36}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, '-glob/2-gen-0-'}, 2}.
  {label, 135}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {line, [{location, "std@io@fs@@File.erl", 36}]}.
  {label, 137}.
    {move, {atom, true}, {x, 0}}.
    {test, is_eq_exact, {f, 138}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 7}}.
    {test, is_tagged_tuple, {f, 139}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 140}}.
  {label, 139}.
    {call, 1, {f, 142}}.
    {jump, {f, 136}}.
  {label, 140}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {gc_bif, byte_size, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 197}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 138}}.
  {label, 197}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {call, 1, {f, 142}}.
    {jump, {f, 137}}.
  {label, 138}.
  {label, 136}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_5--t/1-fun-0--fun-1-', 1, 207}.
  {label, 206}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_5--t/1-fun-0--fun-1-'}, 1}.
  {label, 207}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 209}, [{x, 0}]}.
    {test, test_arity, {f, 209}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_self'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 210}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_mon'}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 3}}.
    {jump, {f, 212}}.
  {label, 210}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 211}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 3}}.
    {jump, {f, 212}}.
  {label, 211}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 212}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 209}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 6}.
    {jump, {f, 206}}.

{function, '__bp_tpl_5-t/1-fun-0-', 0, 203}.
  {label, 202}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_5-t/1-fun-0-'}, 0}.
  {label, 203}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 207}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {call_ext, 0, {extfunc, erlang, get, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, filter, 2}, 2}.

{function, '__bp_tpl_5--t/1-fun-2--fun-3-', 1, 224}.
  {label, 223}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_5--t/1-fun-2--fun-3-'}, 1}.
  {label, 224}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 226}, [{x, 0}]}.
    {test, test_arity, {f, 226}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {y, 0}}.
    {move, {y, 4}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.
  {label, 226}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 5}.
    {jump, {f, 223}}.

{function, '__bp_tpl_5-t/1-fun-2-', 1, 216}.
  {label, 215}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_5-t/1-fun-2-'}, 1}.
  {label, 216}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 220}}.
  {label, 220}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 222}}.
  {label, 222}.
    {call_ext, 0, {extfunc, erlang, erase, 0}}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 224}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 228}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {y, 3}}.
    {jump, {f, 227}}.
  {label, 228}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
    {jump, {f, 227}}.
  {label, 227}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 231}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 231}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, put, 2}, 5}.

{function, '__bp_tpl_5--t/1-fun-4--fun-5-', 4, 242}.
  {label, 241}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_5--t/1-fun-4--fun-5-'}, 4}.
  {label, 242}.
    {allocate, 33, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}, {y, 27}, {y, 28}, {y, 29}, {y, 30}, {y, 31}, {y, 32}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {atom, process}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, monitor, 2}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {y, 4}}.
    {jump, {f, 246}}.
  {label, 246}.
    {move, {atom, '__bp_gen_mon'}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 16}}.
  {label, 247}.
    {loop_rec, {f, 248}, {x, 0}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {test, is_tuple, {f, 251}, [{x, 0}]}.
    {test, test_arity, {f, 251}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 17}}.
    {get_tuple_element, {x, 0}, 1, {y, 18}}.
    {get_tuple_element, {x, 0}, 2, {y, 19}}.
    {move, {y, 17}, {x, 0}}.
    {test, is_eq_exact, {f, 251}, [{x, 0}, {atom, 'DOWN'}]}.
    {move, {y, 18}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test, is_eq_exact, {f, 251}, [{x, 0}, {x, 1}]}.
    {move, {y, 19}, {x, 0}}.
    {test, is_eq_exact, {f, 251}, [{x, 0}, {atom, process}]}.
    remove_message.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 33}.
    return.
  {label, 251}.
    {move, {y, 16}, {x, 0}}.
    {test, is_tuple, {f, 252}, [{x, 0}]}.
    {test, test_arity, {f, 252}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 17}}.
    {get_tuple_element, {x, 0}, 1, {y, 18}}.
    {get_tuple_element, {x, 0}, 2, {y, 19}}.
    {get_tuple_element, {x, 0}, 3, {y, 20}}.
    {get_tuple_element, {x, 0}, 4, {y, 21}}.
    {move, {y, 17}, {x, 0}}.
    {test, is_eq_exact, {f, 252}, [{x, 0}, {atom, '__bp_gen'}]}.
    {move, {y, 18}, {y, 6}}.
    {move, {y, 19}, {y, 5}}.
    {move, {y, 20}, {y, 7}}.
    {move, {y, 21}, {y, 8}}.
    remove_message.
    {move, {y, 8}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 22}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 5}, {y, 7}]}}.
    {move, {x, 0}, {y, 22}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {move, {y, 22}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 254}, [{x, 0}, {atom, close}]}.
    {move, {atom, ok}, {y, 22}}.
    {jump, {f, 253}}.
  {label, 254}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 255}, [{x, 0}, {atom, next}]}.
    {'try', {y, 32}, {f, 256}}.
    {move, {y, 2}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 24}}.
    {move, {y, 24}, {y, 23}}.
    {try_end, {y, 32}}.
    {jump, {f, 257}}.
  {label, 256}.
    {try_case, {y, 32}}.
    {move, {x, 0}, {y, 24}}.
    {move, {x, 1}, {y, 25}}.
    {move, {x, 2}, {y, 26}}.
    {move, {y, 24}, {x, 0}}.
    {test, is_eq_exact, {f, 259}, [{x, 0}, {atom, throw}]}.
    {move, {y, 25}, {x, 0}}.
    {test, is_eq_exact, {f, 259}, [{x, 0}, {atom, '__bp_gen_closed'}]}.
    {move, {atom, ok}, {y, 23}}.
    {jump, {f, 258}}.
  {label, 259}.
    {move, {y, 24}, {y, 9}}.
    {move, {y, 25}, {y, 10}}.
    {move, {y, 26}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 11}}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 27}}.
    {move, {y, 27}, {x, 0}}.
    {test, is_tuple, {f, 262}, [{x, 0}]}.
    {test, test_arity, {f, 262}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 29}}.
    {get_tuple_element, {x, 0}, 1, {y, 30}}.
    {move, {y, 29}, {y, 12}}.
    {move, {y, 30}, {y, 13}}.
    {move, {y, 3}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 31}}.
    {test_heap, 7, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 13}, {atom, raise}, {y, 9}, {y, 10}, {y, 11}, {y, 31}]}}.
    {move, {x, 0}, {y, 31}}.
    {move, {y, 12}, {x, 0}}.
    {move, {y, 31}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, send, 2}}.
    {move, {x, 0}, {y, 31}}.
    {move, {y, 31}, {y, 28}}.
    {jump, {f, 261}}.
  {label, 262}.
    {move, {y, 27}, {x, 0}}.
    {test, is_eq_exact, {f, 263}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {y, 28}}.
    {jump, {f, 261}}.
  {label, 263}.
    {move, {y, 27}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 261}.
    {move, {atom, normal}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, exit, 1}}.
  {label, 258}.
  {label, 257}.
    {move, {y, 23}, {y, 22}}.
    {jump, {f, 253}}.
  {label, 255}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 253}.
    {move, {atom, '__bp_gen_self'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 22}, {x, 0}}.
    {test, is_tuple, {f, 265}, [{x, 0}]}.
    {test, test_arity, {f, 265}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 23}}.
    {get_tuple_element, {x, 0}, 1, {y, 24}}.
    {move, {y, 23}, {y, 14}}.
    {move, {y, 24}, {y, 15}}.
    {move, {y, 3}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 25}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 15}, {atom, done}, {y, 25}]}}.
    {move, {x, 0}, {y, 25}}.
    {move, {y, 14}, {x, 0}}.
    {move, {y, 25}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, send, 2}, 33}.
  {label, 265}.
    {move, {y, 22}, {x, 0}}.
    {test, is_eq_exact, {f, 266}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 33}.
    return.
  {label, 266}.
    {move, {y, 22}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 252}.
    {move, nil, {y, 16}}.
    {move, nil, {y, 5}}.
    {move, nil, {y, 6}}.
    {move, nil, {y, 7}}.
    {move, nil, {y, 8}}.
    {move, nil, {y, 17}}.
    {move, nil, {y, 18}}.
    {move, nil, {y, 19}}.
    {move, nil, {y, 20}}.
    {move, nil, {y, 21}}.
    {move, nil, {y, 22}}.
    {move, nil, {y, 23}}.
    {move, nil, {y, 24}}.
    {move, nil, {y, 25}}.
    {move, nil, {y, 26}}.
    {move, nil, {y, 27}}.
    {move, nil, {y, 28}}.
    {move, nil, {y, 29}}.
    {move, nil, {y, 30}}.
    {move, nil, {y, 31}}.
    {loop_rec_end, {f, 247}}.
  {label, 248}.
    {wait, {f, 247}}.

{function, '__bp_tpl_5-t/1-fun-4-', 3, 236}.
  {label, 235}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_5-t/1-fun-4-'}, 3}.
  {label, 236}.
    {allocate, 5, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 2}, {y, 1}}.
    {call_ext, 0, {extfunc, erlang, self, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 2}}.
    {jump, {f, 240}}.
  {label, 240}.
    {test_heap, {alloc, [{words, 4}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 242}, 2, 0, {x, 0}, {list, [{y, 2}, {y, 0}, {y, 3}, {y, 1}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, spawn, 1}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_gen'}, {y, 4}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '__bp_tpl_5', 1, 199}.
  {label, 198}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_5'}, 1}.
  {label, 199}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 203}, 3, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 214}}.
  {label, 214}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 216}, 4, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 234}}.
  {label, 234}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 236}, 5, 0, {x, 0}, {list, [{y, 1}, {y, 0}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 268}}.
  {label, 268}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_6-t/1-fun-0-', 1, 282}.
  {label, 281}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_6-t/1-fun-0-'}, 1}.
  {label, 282}.
    {allocate, 10, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 286}, [{x, 0}]}.
    {test, test_arity, {f, 286}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {get_tuple_element, {x, 0}, 2, {y, 6}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 286}, [{x, 0}, {atom, mem}]}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, counters, get, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 288}}.
  {label, 288}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {y, 7}, {x, 2}}.
    {call_ext, 3, {extfunc, binary, part, 3}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 0}}.
    {jump, {f, 290}}.
  {label, 290}.
    {move, {y, 0}, {x, 0}}.
    {move, {literal, <<"\n">>}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 292}, [{x, 0}, {atom, nomatch}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {move, {y, 8}, {x, 2}}.
    {call_ext, 3, {extfunc, counters, add, 3}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 292}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 293}, [{x, 0}]}.
    {test, test_arity, {f, 293}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {move, {y, 8}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {move, {y, 9}, {x, 2}}.
    {call_ext, 3, {extfunc, counters, add, 3}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {move, {y, 9}, {x, 2}}.
    {call_ext, 3, {extfunc, binary, part, 3}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 293}.
    {move, {y, 7}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 286}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, file, read_line, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 296}, [{x, 0}]}.
    {test, test_arity, {f, 296}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 5}}.
    {get_tuple_element, {x, 0}, 1, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 296}, [{x, 0}, {atom, ok}]}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 296}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 297}, [{x, 0}, {atom, eof}]}.
    {move, {literal, {ok, <<"">>}}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 297}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 298}, [{x, 0}]}.
    {test, test_arity, {f, 298}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 5}}.
    {get_tuple_element, {x, 0}, 1, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 298}, [{x, 0}, {atom, error}]}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 298}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_6', 1, 276}.
  {label, 275}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_6'}, 1}.
  {label, 276}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 279}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 282}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 300}, [{x, 0}]}.
    {test, test_arity, {f, 300}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 300}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 299}}.
  {label, 300}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 301}, [{x, 0}]}.
    {test, test_arity, {f, 301}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 301}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 299}}.
  {label, 301}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 299}}.
  {label, 299}.
    {jump, {f, 280}}.
  {label, 279}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 306}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 305}}.
  {label, 306}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 307}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 305}}.
  {label, 307}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 308}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 305}}.
  {label, 308}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 305}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 303}}.
  {label, 303}.
  {label, 280}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_tpl_7-t/1-fun-0-', 1, 318}.
  {label, 317}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_7-t/1-fun-0-'}, 1}.
  {label, 318}.
    {allocate, 7, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {jump, {f, 322}}.
  {label, 322}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 2}, {x, 1}}.
    {test, is_ge, {f, 324}, [{x, 0}, {x, 1}]}.
    {jump, {f, 325}}.
  {label, 325}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {integer, 2}, {x, 2}}.
    {call_ext, 3, {extfunc, binary, part, 3}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 327}, [{x, 0}, {literal, <<"\r\n">>}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {move, {y, 3}, {x, 2}}.
    {call_ext_last, 3, {extfunc, binary, part, 3}, 7}.
  {label, 327}.
    {move, {y, 2}, {x, 0}}.
    {test, is_binary, {f, 328}, [{x, 0}]}.
    {gc_bif, byte_size, {f, 328}, 1, [{x, 0}], {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 328}, [{x, 0}, {integer, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, binary, decode_unsigned, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'bsr', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 255}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'band', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 328}, [{x, 0}, {integer, 10}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {move, {y, 6}, {x, 2}}.
    {call_ext_last, 3, {extfunc, binary, part, 3}, 7}.
  {label, 328}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 324}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {test, is_eq_exact, {f, 330}, [{x, 0}, {x, 1}]}.
    {jump, {f, 331}}.
  {label, 331}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 333}, [{x, 0}, {literal, <<"\n">>}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 333}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 330}.
    {jump, {f, 336}}.
  {label, 336}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 7}.
    return.

{function, '__bp_tpl_7', 1, 314}.
  {label, 313}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_7'}, 1}.
  {label, 314}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 318}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_8-t/1-fun-0-', 1, 342}.
  {label, 341}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_8-t/1-fun-0-'}, 1}.
  {label, 342}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, utf8}, {x, 1}}.
    {move, {atom, utf8}, {x, 2}}.
    {call_ext, 3, {extfunc, unicode, characters_to_binary, 3}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 346}, [{x, 0}]}.
    {jump, {f, 347}}.
  {label, 347}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 346}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 348}, [{x, 0}]}.
    {test, test_arity, {f, 348}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 348}, [{x, 0}, {atom, error}]}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, byte_size, 1}, 5}.
  {label, 348}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 349}, [{x, 0}]}.
    {test, test_arity, {f, 349}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 349}, [{x, 0}, {atom, incomplete}]}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, byte_size, 1}, 5}.
  {label, 349}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_8', 1, 338}.
  {label, 337}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_8'}, 1}.
  {label, 338}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 342}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_9-t/1-fun-0-', 1, 357}.
  {label, 356}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_9-t/1-fun-0-'}, 1}.
  {label, 357}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, -9223372036854775807}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {gc_bif, '-', {f, 359}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test, is_ge, {f, 359}, [{x, 0}, {x, 1}]}.
    {move, {integer, 9223372036854775807}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test, is_ge, {f, 359}, [{x, 0}, {x, 1}]}.
    {jump, {f, 360}}.
  {label, 360}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 359}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 362}, [{x, 0}]}.
    {test_heap, 6, 0}.
    {put_list, {literal, <<" does not fit i64">>}, nil, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"toI64: ">>}, {x, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 363}}.
  {label, 362}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 363}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, integer_overflow}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.

{function, '__bp_tpl_9', 1, 353}.
  {label, 352}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_9'}, 1}.
  {label, 353}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 357}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_10-t/1-fun-0-', 1, 375}.
  {label, 374}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_10-t/1-fun-0-'}, 1}.
  {label, 375}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 379}, [{x, 0}]}.
    {jump, {f, 380}}.
  {label, 380}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 379}.
    {move, {literal, {error, <<"bytes.toUtf8: not valid UTF-8">>}}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_10', 1, 371}.
  {label, 370}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_10'}, 1}.
  {label, 371}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 375}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '-glob/1-gen-1-', 1, 270}.
  {label, 269}.
    {line, [{location, "std@io@fs@@File.erl", 37}]}.
    {func_info, {atom, std@io@fs@@File}, {atom, '-glob/1-gen-1-'}, 1}.
  {label, 270}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {line, [{location, "std@io@fs@@File.erl", 37}]}.
  {label, 272}.
    {move, {atom, true}, {x, 0}}.
    {test, is_eq_exact, {f, 273}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 274}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 274}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 309}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 309}.
    {call, 1, {f, 276}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, std@io@fs, liftBytes, 2}}.
    {test, is_tagged_tuple, {f, 310}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 311}}.
  {label, 310}.
    {call, 1, {f, 142}}.
    {jump, {f, 271}}.
  {label, 311}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {gc_bif, byte_size, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 312}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 273}}.
  {label, 312}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 314}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call, 1, {f, 338}}.
    {move, {x, 0}, {y, 5}}.
    {test, is_ge, {f, 350}, [{y, 5}, {integer, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 351}, [{x, 0}, 3, {atom, std@io@fs@@File}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 351}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 353}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 5}], {x, 0}}.
    {test, is_ge, {f, 364}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 364}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 365}}.
  {label, 364}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i64 at src/io/fs.bp:653:21">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 365}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@fs@@FsError__v__invalidutf8}, {y, 6}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {call, 1, {f, 142}}.
    {jump, {f, 271}}.
  {label, 350}.
    {move, {y, 3}, {x, 0}}.
    {gc_bif, byte_size, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {y, 7}], {x, 0}}.
    {test, is_ge, {f, 366}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 366}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 367}}.
  {label, 366}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/fs.bp:655:33">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 367}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call, 1, {f, 371}}.
    {test, is_tagged_tuple, {f, 368}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 369}}.
  {label, 368}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 369}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {call, 1, {f, 142}}.
    {jump, {f, 272}}.
  {label, 273}.
  {label, 271}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_tpl_11--t/1-fun-0--fun-1-', 3, 398}.
  {label, 397}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_11--t/1-fun-0--fun-1-'}, 3}.
  {label, 398}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {x, 2}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 398}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {integer, 65536}, {x, 2}}.
    {call_ext, 3, {extfunc, file, pread, 3}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 402}, [{x, 0}]}.
    {test, test_arity, {f, 402}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 5}}.
    {get_tuple_element, {x, 0}, 1, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 402}, [{x, 0}, {atom, ok}]}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, crypto, hash_update, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {move, {y, 0}, {x, 2}}.
    {call_last, 3, {f, 398}, 9}.
  {label, 402}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 403}, [{x, 0}, {atom, eof}]}.
    {move, {y, 3}, {x, 0}}.
    {call_ext_last, 1, {extfunc, crypto, hash_final, 1}, 9}.
  {label, 403}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 404}, [{x, 0}]}.
    {test, test_arity, {f, 404}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 5}}.
    {get_tuple_element, {x, 0}, 1, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 404}, [{x, 0}, {atom, error}]}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 9}.
  {label, 404}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_11-t/1-fun-0-', 1, 389}.
  {label, 388}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_11-t/1-fun-0-'}, 1}.
  {label, 389}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 393}, [{x, 0}]}.
    {test, test_arity, {f, 393}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 393}, [{x, 0}, {atom, mem}]}.
    {move, {y, 4}, {y, 0}}.
    {move, {atom, sha256}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, crypto, hash, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, binary, encode_hex, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, string, lowercase, 1}}.
    {move, {x, 0}, {y, 5}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 5}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 393}.
    {move, {y, 2}, {x, 0}}.
    {move, {atom, cur}, {x, 1}}.
    {call_ext, 2, {extfunc, file, position, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 395}, [{x, 0}]}.
    {test, test_arity, {f, 395}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 395}, [{x, 0}, {atom, ok}]}.
    {move, {y, 5}, {y, 0}}.
    {jump, {f, 396}}.
  {label, 395}.
    {move, {y, 3}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 396}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 398}, 0, 0, {x, 0}, {list, [{y, 2}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 406}}.
  {label, 406}.
    {move, {atom, sha256}, {x, 0}}.
    {call_ext, 1, {extfunc, crypto, hash_init, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 408}}.
  {label, 408}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, file, position, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 409}, [{x, 0}]}.
    {test, test_arity, {f, 409}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 409}, [{x, 0}, {atom, ok}]}.
    {jump, {f, 410}}.
  {label, 409}.
    {move, {y, 3}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 410}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, binary, encode_hex, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, string, lowercase, 1}}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 3}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 6}.
    return.

{function, '__bp_tpl_11', 1, 383}.
  {label, 382}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_11'}, 1}.
  {label, 383}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 386}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 389}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 412}, [{x, 0}]}.
    {test, test_arity, {f, 412}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 412}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 411}}.
  {label, 412}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 413}, [{x, 0}]}.
    {test, test_arity, {f, 413}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 413}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 411}}.
  {label, 413}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 411}}.
  {label, 411}.
    {jump, {f, 387}}.
  {label, 386}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 418}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 417}}.
  {label, 418}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 419}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 417}}.
  {label, 419}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 420}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 417}}.
  {label, 420}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 417}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 415}}.
  {label, 415}.
  {label, 387}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_tpl_12', 1, 426}.
  {label, 425}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_12'}, 1}.
  {label, 426}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 430}, [{x, 0}]}.
    {test, test_arity, {f, 430}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 430}, [{x, 0}, {atom, mem}]}.
    {move, {atom, true}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 430}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_13-t/2-fun-0-', 2, 441}.
  {label, 440}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_13-t/2-fun-0-'}, 2}.
  {label, 441}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, file, write, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 445}, [{x, 0}, {atom, ok}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 4}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 445}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 446}, [{x, 0}]}.
    {test, test_arity, {f, 446}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 446}, [{x, 0}, {atom, error}]}.
    {move, {y, 5}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 446}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_13', 2, 435}.
  {label, 434}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_13'}, 2}.
  {label, 435}.
    {allocate, 13, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {'try', {y, 12}, {f, 438}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 441}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {y, 6}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 7}}.
    {try_end, {y, 12}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 448}, [{x, 0}]}.
    {test, test_arity, {f, 448}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 448}, [{x, 0}, {atom, ok}]}.
    {move, {y, 9}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 5}}.
    {jump, {f, 447}}.
  {label, 448}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 449}, [{x, 0}]}.
    {test, test_arity, {f, 449}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 449}, [{x, 0}, {atom, error}]}.
    {move, {y, 9}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 10}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 10}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 5}}.
    {jump, {f, 447}}.
  {label, 449}.
    {move, {y, 7}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 5}}.
    {jump, {f, 447}}.
  {label, 447}.
    {jump, {f, 439}}.
  {label, 438}.
    {try_case, {y, 12}}.
    {move, {x, 0}, {y, 6}}.
    {move, {x, 1}, {y, 7}}.
    {move, {x, 2}, {y, 8}}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 8}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 454}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 10}}.
    {jump, {f, 453}}.
  {label, 454}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 455}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 10}}.
    {jump, {f, 453}}.
  {label, 455}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 456}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 10}}.
    {jump, {f, 453}}.
  {label, 456}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 453}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 11}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 5}}.
    {jump, {f, 451}}.
  {label, 451}.
  {label, 439}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 13}.
    return.

{function, '__bp_tpl_14-t/1-fun-0-', 1, 467}.
  {label, 466}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_14-t/1-fun-0-'}, 1}.
  {label, 467}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 471}, [{x, 0}]}.
    {test, test_arity, {f, 471}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 471}, [{x, 0}, {atom, mem}]}.
    {move, {literal, {ok, 0}}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 471}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, file, close, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 474}, [{x, 0}, {atom, ok}]}.
    {move, {literal, {ok, 0}}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 474}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 475}, [{x, 0}]}.
    {test, test_arity, {f, 475}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 475}, [{x, 0}, {atom, error}]}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 475}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_14', 1, 461}.
  {label, 460}.
    {func_info, {atom, std@io@fs@@File}, {atom, '__bp_tpl_14'}, 1}.
  {label, 461}.
    {allocate, 12, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 11}, {f, 464}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 467}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 6}}.
    {try_end, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 477}, [{x, 0}]}.
    {test, test_arity, {f, 477}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 477}, [{x, 0}, {atom, ok}]}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 476}}.
  {label, 477}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 478}, [{x, 0}]}.
    {test, test_arity, {f, 478}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 478}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 4}}.
    {jump, {f, 476}}.
  {label, 478}.
    {move, {y, 6}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 4}}.
    {jump, {f, 476}}.
  {label, 476}.
    {jump, {f, 465}}.
  {label, 464}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 5}}.
    {move, {x, 1}, {y, 6}}.
    {move, {x, 2}, {y, 7}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 483}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 9}}.
    {jump, {f, 482}}.
  {label, 483}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 484}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 9}}.
    {jump, {f, 482}}.
  {label, 484}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 485}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 9}}.
    {jump, {f, 482}}.
  {label, 485}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 482}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 8}, {literal, <<"host">>}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 4}}.
    {jump, {f, 480}}.
  {label, 480}.
  {label, 465}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 12}.
    return.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- std/probe.bp
```botopink
import {path: {join}, io.fs.readText};

pub fn peek(p: string) -> string {
    return readText(join([p, "a"]));
}
```

----- COMPILE DIAGNOSTIC -- std/probe
```text
error: std-root-imports-io: std module `probe` is at the root of std, which is pure; `io.fs.readText` imports from `io/`
  ┌─ std/probe.bp:1:23
  │
1 │ import {path: {join}, io.fs.readText};
  │                       ^

  hint: Move the module under `io/` (it talks to the world), or take the value it needs as a parameter.
```

